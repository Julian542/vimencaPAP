public without sharing class FSC_GenerarContratoPDFQueueable implements Queueable, Database.AllowsCallouts {

    @TestVisible
    private static Set<Id> forcedGenerationErrorLoanApplicationIds = new Set<Id>();

    private static final String SUBESTADO_GENERACION_CONTRATO = 'Generación de contrato';
    private static final String SUBESTADO_GESTIONAR_FIRMAS = 'Gestionar firmas';
    private static final String ERROR_LOG_SEPARATOR = '\n--------------------\n';
    private static final String ERROR_LOG_TIMESTAMP_FORMAT = 'yyyy-MM-dd HH:mm:ss';
    private static final Integer ERROR_LOG_MESSAGE_MAX_LENGTH = 255;
    private static final String TIPO_ARCHIVO_CONTRATO = 'CONTRATO';
    private static final String TIPO_ARCHIVO_PIGNORACION = 'PIGNORACION';

    private List<Id> residentialLoanApplicationIds;
    private Boolean conservarSubestado = false;

    public FSC_GenerarContratoPDFQueueable(List<Id> residentialLoanApplicationIds) {
        this.residentialLoanApplicationIds = residentialLoanApplicationIds == null
            ? new List<Id>()
            : new List<Id>(new Set<Id>(residentialLoanApplicationIds));
    }

    public FSC_GenerarContratoPDFQueueable(List<Id> ids, Boolean conservarSubestado) {
        this(ids);
        this.conservarSubestado = conservarSubestado == true;
    }

    private String subestadoDestino() {
        return conservarSubestado ? FSC_DocumentoLegalService.ETAPA : SUBESTADO_GESTIONAR_FIRMAS;
    }

    public void execute(QueueableContext context) {
        if (residentialLoanApplicationIds.isEmpty()) {
            return;
        }

        List<ResidentialLoanApplication> loanApplications = [
            SELECT Id, RecordType.DeveloperName, FSC_Subestado__c, FSC_Contrato_Generado__c,
                FSC_LogErrores__c, FSC_RequiereContratoPagareNotarial__c,
                FSC_Excepcion_Contrato_Notarial__c, FSC_Pignoracion_Generada__c,
                FSC_Relacion_Propietario_CD__c, FSC_Fecha_Contrato__c, FSC_Pagares_y_Plantillas_Generados__c
            FROM ResidentialLoanApplication
            WHERE Id IN :residentialLoanApplicationIds
        ];

        Map<Id, String> currentErrorLogsByLoanApplicationId = new Map<Id, String>();
        for (ResidentialLoanApplication loanApplication : loanApplications) {
            currentErrorLogsByLoanApplicationId.put(loanApplication.Id, loanApplication.FSC_LogErrores__c);
        }

        Map<Id, String> pendingErrorLogsByLoanApplicationId = new Map<Id, String>();
        List<ContentVersion> filesToInsert = new List<ContentVersion>();
        List<Id> fileLoanApplicationIds = new List<Id>();
        List<String> fileTypes = new List<String>();
        Set<Id> loanApplicationsToAdvanceWithoutFile = new Set<Id>();

        for (ResidentialLoanApplication loanApplication : loanApplications) {
            if (conservarSubestado
                ? loanApplication.FSC_Subestado__c != FSC_DocumentoLegalService.ETAPA || loanApplication.FSC_Pagares_y_Plantillas_Generados__c != true
                : loanApplication.FSC_Subestado__c != SUBESTADO_GENERACION_CONTRATO) {
                continue;
            }

            try {
                if (Test.isRunningTest() && forcedGenerationErrorLoanApplicationIds.contains(loanApplication.Id)) {
                    throw new FSC_GenerarContratoPDFQueueableException('Error de generación forzado para prueba.');
                }

                Boolean esPyme = loanApplication.RecordType.DeveloperName == 'FSC_Solicitud_Credito_PYME';
                Boolean esConsumo = loanApplication.RecordType.DeveloperName == 'FSC_Solicitud_Credito_Consumo';
                Boolean esVehiculo = loanApplication.RecordType.DeveloperName == 'FSC_Solicitud_Credito_Vehiculo';
                Boolean esHipotecario = loanApplication.RecordType.DeveloperName == 'FSC_Solicitud_Credito_Hipotecario';
                FSC_ConsumoDocumentoResolver.ResolucionDocumento consumo = esConsumo
                    ? FSC_ConsumoDocumentoResolver.resolve(loanApplication.Id)
                    : null;
                FSC_VehiculoDocumentoResolver.ResolucionDocumento vehiculo = esVehiculo
                    ? FSC_VehiculoDocumentoResolver.resolve(loanApplication.Id)
                    : null;
                FSC_HipotecarioDocumentoResolver.ResolucionDocumento hipotecario = esHipotecario
                    ? FSC_HipotecarioDocumentoResolver.resolve(loanApplication.Id)
                    : null;
                Boolean requierePignoracion = esConsumo &&
                    consumo.codigoPagare == FSC_ConsumoDocumentoResolver.PAGARE_COMPLEMENTARIO &&
                    consumo.tipoGarantia == FSC_ConsumoDocumentoResolver.GARANTIA_CD;

                if (requierePignoracion) {
                    if (loanApplication.FSC_Pignoracion_Generada__c == true) {
                        loanApplicationsToAdvanceWithoutFile.add(loanApplication.Id);
                        continue;
                    }

                    PageReference pignorationPage = Page.FSC_PignoracionCertificadoConsumoPDF;
                    pignorationPage.getParameters().put('id', String.valueOf(loanApplication.Id));
                    pignorationPage.getParameters().put('fechaDocumento', String.valueOf(Date.today()));
                    Blob pignorationBlob = Test.isRunningTest()
                        ? Blob.valueOf('TEST PDF CONTENT')
                        : pignorationPage.getContentAsPDF();
                    if (pignorationBlob == null || pignorationBlob.size() == 0) {
                        throw new FSC_GenerarContratoPDFQueueableException('El PDF de pignoración se generó vacío.');
                    }

                    String titlePrefix = loanApplication.FSC_Relacion_Propietario_CD__c == 'Persona distinta'
                        ? 'MODELO DE PIGNORACION DE CERTIFICADO PARA PRESTAMO OTORGADO A UNA PERSONA DISTINTA AL DUENO DEL CD'
                        : 'MODELO DE PIGNORACION DE CERTIFICADO PARA PRESTAMO OTORGADO AL DUENO DEL CD';
                    String pignorationTitle = titlePrefix + ' ' + String.valueOf(loanApplication.Id);
                    filesToInsert.add(new ContentVersion(
                        Title = pignorationTitle,
                        PathOnClient = pignorationTitle + '.pdf',
                        VersionData = pignorationBlob,
                        FSC_ContenidoLegal__c = FSC_DocumentoLegalService.capturar(pignorationPage, FSC_DocumentoLegalService.PIGNORACION),
                        FirstPublishLocationId = loanApplication.Id,
                        FSC_EnviarDocumento__c = true
                    ));
                    fileLoanApplicationIds.add(loanApplication.Id);
                    fileTypes.add(TIPO_ARCHIVO_PIGNORACION);
                    continue;
                }

                if (loanApplication.FSC_Contrato_Generado__c == true) {
                    loanApplicationsToAdvanceWithoutFile.add(loanApplication.Id);
                    continue;
                }

                Boolean usaPagareNotarial = esConsumo
                    ? consumo.codigoPagare == FSC_ConsumoDocumentoResolver.PAGARE_NOTARIAL
                    : esVehiculo
                        ? vehiculo.codigoPagare == FSC_ConsumoDocumentoResolver.PAGARE_NOTARIAL
                        : esHipotecario
                            ? hipotecario.codigoPagare == FSC_ConsumoDocumentoResolver.PAGARE_NOTARIAL
                        : esPyme && loanApplication.FSC_RequiereContratoPagareNotarial__c == true;
                if (!esHipotecario && usaPagareNotarial && loanApplication.FSC_Excepcion_Contrato_Notarial__c != true) {
                    loanApplicationsToAdvanceWithoutFile.add(loanApplication.Id);
                    continue;
                }

                FSC_RLAContractTemplateResolver.ContractResolution resolution =
                    FSC_RLAContractTemplateResolver.resolve(loanApplication.Id);
                if (!resolution.aplicaContrato) {
                    loanApplicationsToAdvanceWithoutFile.add(loanApplication.Id);
                    continue;
                }

                PageReference contractPage = FSC_RLAContractTemplateResolver.resolvePageReference(
                    loanApplication.Id,
                    resolution.templateCode
                );
                Date contractDate = loanApplication.FSC_Fecha_Contrato__c == null
                    ? Date.today()
                    : loanApplication.FSC_Fecha_Contrato__c;
                contractPage.getParameters().put('fechaContrato', String.valueOf(contractDate));

                Blob pdfBlob = Test.isRunningTest()
                    ? Blob.valueOf('TEST PDF CONTENT')
                    : contractPage.getContentAsPDF();

                if (pdfBlob == null || pdfBlob.size() == 0) {
                    throw new FSC_GenerarContratoPDFQueueableException('El PDF se generó vacío.');
                }

                String fileTitle = resolution.tituloArchivo + ' ' + String.valueOf(loanApplication.Id);

                filesToInsert.add(new ContentVersion(
                    Title = fileTitle,
                    PathOnClient = fileTitle + '.pdf',
                    VersionData = pdfBlob,
                    FSC_ContenidoLegal__c = FSC_DocumentoLegalService.capturar(contractPage, FSC_DocumentoLegalService.CONTRATO),
                    FirstPublishLocationId = loanApplication.Id,
                    FSC_EnviarDocumento__c = true
                ));
                fileLoanApplicationIds.add(loanApplication.Id);
                fileTypes.add(TIPO_ARCHIVO_CONTRATO);
            } catch (Exception e) {
                registerError(
                    currentErrorLogsByLoanApplicationId,
                    pendingErrorLogsByLoanApplicationId,
                    loanApplication.Id,
                    'Error generando documento PDF: ' + trimForLog(e.getMessage(), ERROR_LOG_MESSAGE_MAX_LENGTH)
                );

                System.debug(
                    LoggingLevel.ERROR,
                    'Error generando contrato PDF para RLA ' + loanApplication.Id + ': ' + e.getMessage()
                );
            }
        }

        Set<Id> successfulContractLoanApplicationIds = new Set<Id>();
        Set<Id> successfulPignorationLoanApplicationIds = new Set<Id>();

        if (!filesToInsert.isEmpty()) {
            Map<Id, ResidentialLoanApplication> lockedLoanApplications = new Map<Id, ResidentialLoanApplication>([
                SELECT Id, FSC_Contrato_Generado__c, FSC_Pignoracion_Generada__c, FSC_Subestado__c
                FROM ResidentialLoanApplication
                WHERE Id IN :fileLoanApplicationIds
                FOR UPDATE
            ]);
            List<ContentVersion> filteredFiles = new List<ContentVersion>();
            List<Id> filteredFileLoanApplicationIds = new List<Id>();
            List<String> filteredFileTypes = new List<String>();
            for (Integer i = 0; i < filesToInsert.size(); i++) {
                ResidentialLoanApplication lockedRla = lockedLoanApplications.get(fileLoanApplicationIds[i]);
                if (conservarSubestado && lockedRla != null && lockedRla.FSC_Subestado__c != FSC_DocumentoLegalService.ETAPA) continue;
                Boolean alreadyGenerated = lockedRla != null &&
                    (fileTypes[i] == TIPO_ARCHIVO_PIGNORACION
                        ? lockedRla.FSC_Pignoracion_Generada__c == true
                        : lockedRla.FSC_Contrato_Generado__c == true);
                if (lockedRla != null && !alreadyGenerated) {
                    filteredFiles.add(filesToInsert[i]);
                    filteredFileLoanApplicationIds.add(fileLoanApplicationIds[i]);
                    filteredFileTypes.add(fileTypes[i]);
                } else if (lockedRla != null) {
                    loanApplicationsToAdvanceWithoutFile.add(fileLoanApplicationIds[i]);
                }
            }
            filesToInsert = filteredFiles;
            fileLoanApplicationIds = filteredFileLoanApplicationIds;
            fileTypes = filteredFileTypes;
        }

        if (!filesToInsert.isEmpty()) {
            Database.SaveResult[] saveResults = Database.insert(filesToInsert, false);

            for (Integer i = 0; i < saveResults.size(); i++) {
                if (saveResults[i].isSuccess()) {
                    if (fileTypes[i] == TIPO_ARCHIVO_PIGNORACION) {
                        successfulPignorationLoanApplicationIds.add(fileLoanApplicationIds[i]);
                    } else {
                        successfulContractLoanApplicationIds.add(fileLoanApplicationIds[i]);
                    }
                } else {
                    String insertErrorMessage = buildDatabaseErrorMessage(saveResults[i].getErrors());
                    registerError(
                        currentErrorLogsByLoanApplicationId,
                        pendingErrorLogsByLoanApplicationId,
                        fileLoanApplicationIds[i],
                        'Error guardando documento PDF: ' + insertErrorMessage
                    );

                    System.debug(
                        LoggingLevel.ERROR,
                        'Error guardando PDF para RLA ' + fileLoanApplicationIds[i] + ': ' + insertErrorMessage
                    );
                }
            }
        }

        if (!successfulContractLoanApplicationIds.isEmpty() ||
            !successfulPignorationLoanApplicationIds.isEmpty() ||
            !loanApplicationsToAdvanceWithoutFile.isEmpty()) {
            List<ResidentialLoanApplication> loanApplicationsToUpdate = new List<ResidentialLoanApplication>();
            List<Id> updateLoanApplicationIds = new List<Id>();

            for (Id loanApplicationId : successfulContractLoanApplicationIds) {
                loanApplicationsToUpdate.add(new ResidentialLoanApplication(
                    Id = loanApplicationId,
                    FSC_Subestado__c = subestadoDestino(),
                    FSC_Contrato_Generado__c = true,
                    FSC_Fecha_Contrato__c = contractDateFor(loanApplications, loanApplicationId)
                ));
                updateLoanApplicationIds.add(loanApplicationId);
            }

            for (Id loanApplicationId : successfulPignorationLoanApplicationIds) {
                loanApplicationsToUpdate.add(new ResidentialLoanApplication(
                    Id = loanApplicationId,
                    FSC_Subestado__c = subestadoDestino(),
                    FSC_Pignoracion_Generada__c = true
                ));
                updateLoanApplicationIds.add(loanApplicationId);
            }

            for (Id loanApplicationId : loanApplicationsToAdvanceWithoutFile) {
                if (conservarSubestado) continue;
                loanApplicationsToUpdate.add(new ResidentialLoanApplication(
                    Id = loanApplicationId,
                    FSC_Subestado__c = subestadoDestino()
                ));
                updateLoanApplicationIds.add(loanApplicationId);
            }

            Database.SaveResult[] updateResults = Database.update(loanApplicationsToUpdate, false);

            for (Integer i = 0; i < updateResults.size(); i++) {
                if (!updateResults[i].isSuccess()) {
                    String updateErrorMessage = buildDatabaseErrorMessage(updateResults[i].getErrors());
                    registerError(
                        currentErrorLogsByLoanApplicationId,
                        pendingErrorLogsByLoanApplicationId,
                        updateLoanApplicationIds[i],
                        'Error actualizando ResidentialLoanApplication luego de generar documento PDF: ' + updateErrorMessage
                    );

                    System.debug(
                        LoggingLevel.ERROR,
                        'Error actualizando RLA ' + updateLoanApplicationIds[i] + ' luego de generar PDF: ' + updateErrorMessage
                    );
                }
            }
        }

        if (!pendingErrorLogsByLoanApplicationId.isEmpty()) {
            List<ResidentialLoanApplication> logUpdates = new List<ResidentialLoanApplication>();

            for (Id loanApplicationId : pendingErrorLogsByLoanApplicationId.keySet()) {
                logUpdates.add(new ResidentialLoanApplication(
                    Id = loanApplicationId,
                    FSC_LogErrores__c = pendingErrorLogsByLoanApplicationId.get(loanApplicationId)
                ));
            }

            Database.update(logUpdates, false);
        }
    }

    private static void registerError(
        Map<Id, String> currentErrorLogsByLoanApplicationId,
        Map<Id, String> pendingErrorLogsByLoanApplicationId,
        Id loanApplicationId,
        String message
    ) {
        String baseLog = pendingErrorLogsByLoanApplicationId.containsKey(loanApplicationId)
            ? pendingErrorLogsByLoanApplicationId.get(loanApplicationId)
            : currentErrorLogsByLoanApplicationId.get(loanApplicationId);

        pendingErrorLogsByLoanApplicationId.put(
            loanApplicationId,
            appendErrorLog(baseLog, buildErrorLogEntry(message))
        );
    }

    private static Date contractDateFor(List<ResidentialLoanApplication> loanApplications, Id loanApplicationId) {
        for (ResidentialLoanApplication loanApplication : loanApplications) {
            if (loanApplication.Id == loanApplicationId && loanApplication.FSC_Fecha_Contrato__c != null) {
                return loanApplication.FSC_Fecha_Contrato__c;
            }
        }
        return Date.today();
    }

    private static String buildDatabaseErrorMessage(Database.Error[] errors) {
        if (errors == null || errors.isEmpty()) {
            return 'Error desconocido.';
        }

        List<String> messages = new List<String>();
        for (Database.Error errorItem : errors) {
            messages.add(trimForLog(errorItem.getMessage(), ERROR_LOG_MESSAGE_MAX_LENGTH));
        }

        return String.join(messages, ' | ');
    }

    private static String buildErrorLogEntry(String message) {
        return Datetime.now().format(ERROR_LOG_TIMESTAMP_FORMAT) + ' | ' + message;
    }

    private static String appendErrorLog(String currentLog, String newEntry) {
        if (String.isBlank(newEntry)) {
            return currentLog;
        }
        if (String.isBlank(currentLog)) {
            return newEntry;
        }

        return currentLog + ERROR_LOG_SEPARATOR + newEntry;
    }

    private static String trimForLog(String value, Integer maxLength) {
        if (String.isBlank(value) || maxLength == null || value.length() <= maxLength) {
            return value;
        }

        return value.substring(0, maxLength) + '...';
    }

    public class FSC_GenerarContratoPDFQueueableException extends Exception {}
}