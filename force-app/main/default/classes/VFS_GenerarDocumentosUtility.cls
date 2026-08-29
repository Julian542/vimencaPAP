/*********************************************************************************************
 * Nombre de clase Apex   :   VFS_GenerarDocumentosUtility
 * Versión                :   1.2
 * Fecha de creación      :   12/06/2025
 * Función                :   Utilidad para generar un ContentDocument PDF a partir de un Visualforce Page y un Id
 * Clase Test             :   VFS_GenerarDocumentosUtilityTest
 *
 * Registro de modificaciones:
 * ---------------------------------------------------------------------------------------------------
 * Desarrollador                        Fecha           Descripción
 * Edgar H. Luna                        12/06/2025      Versión original
 *********************************************************************************************/
public without sharing class VFS_GenerarDocumentosUtility {

    public class VFS_GenerarDocumentosUtilityException extends Exception {}

    @AuraEnabled(cacheable=false)
    public static Id generarPDFyContentDocument(String vfpName, Id recordId, String fileName) {
        System.debug('on VFS_GenerarDocumentosUtility.generarPDFyContentDocument()');
        System.debug('Parámetros recibidos - vfpName: ' + vfpName + ', recordId: ' + recordId + ', fileName: ' + fileName);

        try {
            if (String.isBlank(vfpName)) {
                throw new VFS_GenerarDocumentosUtilityException('El nombre de la página Visualforce no puede estar vacío. Se requiere especificar una página válida para generar el PDF.');
            }
            if (recordId == null) {
                throw new VFS_GenerarDocumentosUtilityException('El ID del registro no puede estar vacío. Se requiere un registro válido para generar el PDF.');
            }
            if (String.isBlank(fileName)) {
                throw new VFS_GenerarDocumentosUtilityException('El nombre del archivo no puede estar vacío. Se requiere especificar un nombre para el documento PDF.');
            }

            System.debug('Iniciando generación de PDF para Visualforce: ' + vfpName + ', recordId: ' + recordId + ', fileName: ' + fileName);

            PageReference pageRef = new PageReference('/apex/' + vfpName);
            pageRef.getParameters().put('id', String.valueOf(recordId));
            pageRef.getParameters().put('pdf', '1');
            pageRef.setRedirect(false);

            System.debug('PageReference creada: ' + pageRef);
            System.debug('pageRef URL: ' + pageRef.getUrl());

            Blob pdfBlob;
            try {
                if (Test.isRunningTest() && vfpName == 'FORCE_PDF_ERROR') {
                    throw new System.CalloutException('Error simulado al renderizar PDF');
                }

                System.debug('ANTES getContentAsPDF');
                pdfBlob = Test.isRunningTest() ? Blob.valueOf('Unit.Test') : pageRef.getContentAsPDF();
                System.debug('DESPUES getContentAsPDF');

                System.debug('pdfBlob null? ' + (pdfBlob == null));
                System.debug('pdfBlob size: ' + (pdfBlob == null ? 0 : pdfBlob.size()));

                if (pdfBlob == null || pdfBlob.size() == 0) {
                    throw new VFS_GenerarDocumentosUtilityException('La generación del PDF devolvió un archivo vacío para "' + vfpName + '".');
                }
                System.debug('PDF generado OK. Size(bytes): ' + pdfBlob.size());
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'ERROR en bloque getContentAsPDF');
                System.debug(LoggingLevel.ERROR, 'Tipo excepción: ' + e.getTypeName());
                System.debug(LoggingLevel.ERROR, 'Mensaje excepción: ' + e.getMessage());
                System.debug(LoggingLevel.ERROR, 'StackTrace: ' + e.getStackTraceString());

                throw new VFS_GenerarDocumentosUtilityException(
                    'Error al renderizar la página Visualforce "' + vfpName + '" como PDF: ' + e.getMessage() +
                    '. Verifique que la página existe, tiene acceso a los datos y que el contenido del PDF no es excesivo.'
                );
            }

            System.debug('Query existingLinks - LinkedEntityId: ' + recordId + ', Title: ' + fileName);
            List<ContentDocumentLink> existingLinks = [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :recordId
                AND ContentDocument.Title = :fileName
                LIMIT 1
            ];
            System.debug('existingLinks size: ' + existingLinks.size());

            ContentDocumentLink existingLink = existingLinks.isEmpty() ? null : existingLinks[0];
            System.debug('existingLink encontrado? ' + (existingLink != null));
            if (existingLink != null) {
                System.debug('existingLink.ContentDocumentId: ' + existingLink.ContentDocumentId);
            }

            ContentVersion cv = new ContentVersion(
                Title = fileName,
                PathOnClient = fileName + '.pdf',
                VersionData = pdfBlob,
                IsMajorVersion = true
            );
            System.debug('ContentVersion preparada. Title: ' + cv.Title + ', PathOnClient: ' + cv.PathOnClient);

            if (existingLink != null) {
                cv.ContentDocumentId = existingLink.ContentDocumentId;
                System.debug('Se actualizará documento existente. cv.ContentDocumentId: ' + cv.ContentDocumentId);

                if (Test.isRunningTest() && fileName == 'FORCE_UPDATE_ERROR') {
                    throw new DmlException('Error simulado al actualizar documento');
                }

                System.debug('ANTES insert ContentVersion (update)');
                insert cv;
                System.debug('DESPUES insert ContentVersion (update). cv.Id: ' + cv.Id + ', cv.ContentDocumentId: ' + cv.ContentDocumentId);

                return cv.ContentDocumentId;
            }

            if (Test.isRunningTest() && fileName == 'FORCE_CREATE_ERROR') {
                throw new DmlException('Error simulado al crear documento');
            }

            System.debug('ANTES insert ContentVersion (create)');
            insert cv;
            System.debug('DESPUES insert ContentVersion (create). cv.Id: ' + cv.Id + ', cv.ContentDocumentId: ' + cv.ContentDocumentId);

            Id contentDocumentId = cv.ContentDocumentId;
            System.debug('contentDocumentId inicial desde cv: ' + contentDocumentId);

            if (contentDocumentId == null) {
                System.debug('contentDocumentId viene null. Se consultará ContentVersion por Id: ' + cv.Id);
                contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
                System.debug('contentDocumentId recuperado por query: ' + contentDocumentId);
            }

            ContentDocumentLink cdl = new ContentDocumentLink(
                ContentDocumentId = contentDocumentId,
                LinkedEntityId = recordId,
                ShareType = 'V',
                Visibility = 'AllUsers'
            );
            System.debug('ContentDocumentLink preparado. ContentDocumentId: ' + cdl.ContentDocumentId + ', LinkedEntityId: ' + cdl.LinkedEntityId);

            System.debug('ANTES insert ContentDocumentLink');
            insert cdl;
            System.debug('DESPUES insert ContentDocumentLink. cdl.Id: ' + cdl.Id);

            System.debug('Retornando contentDocumentId: ' + contentDocumentId);
            return contentDocumentId;

        } catch (VFS_GenerarDocumentosUtilityException e) {
            System.debug(LoggingLevel.ERROR, 'VFS_GenerarDocumentosUtilityException en generarPDFyContentDocument');
            System.debug(LoggingLevel.ERROR, 'Mensaje: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'StackTrace: ' + e.getStackTraceString());

            String errorMessage = e.getMessage();
            Exception auraEx = new AuraHandledException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception inesperada en generarPDFyContentDocument');
            System.debug(LoggingLevel.ERROR, 'Tipo excepción: ' + e.getTypeName());
            System.debug(LoggingLevel.ERROR, 'Mensaje: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'StackTrace: ' + e.getStackTraceString());

            String errorMessage = 'Error inesperado al generar el documento PDF. Por favor, contacte al administrador del sistema.';
            Exception auraEx = new AuraHandledException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        }
    }

    @AuraEnabled(cacheable=false)
    public static Id generarPDFDesdeDefinicion(String name, Id recordId) {
        System.debug('on VFS_GenerarDocumentosUtility.generarPDFDesdeDefinicion()');
        System.debug('Parámetros recibidos - name: ' + name + ', recordId: ' + recordId);

        try {
            if (String.isBlank(name)) {
                throw new VFS_GenerarDocumentosUtilityException('El nombre de la definición de documento no puede estar vacío. Se requiere especificar una definición válida.');
            }
            
            if (recordId == null) {
                throw new VFS_GenerarDocumentosUtilityException('El ID del registro no puede estar vacío. Se requiere un registro válido para generar el PDF.');
            }
            
            System.debug('Iniciando generación de PDF desde definición: ' + name + ', recordId: ' + recordId);
            List<SObject> defs;
            try {
                if (Test.isRunningTest() && name == 'FORCE_QUERY_ERROR') {
                    throw new QueryException('Error simulado en consulta de definición');
                }

                System.debug('Ejecutando query de definición para name: ' + name);
                defs = Database.query('SELECT VFS_Visualforce__c, VFS_NombreDocumento__c FROM VFS_DefinicionDocumentos__c WHERE VFS_NombreDocumento__c = :name LIMIT 1');
                System.debug('defs: ' + defs);
                System.debug('defs size: ' + defs.size());
            
            } catch (QueryException e) {
                System.debug(LoggingLevel.ERROR, 'QueryException en consulta de definición');
                System.debug(LoggingLevel.ERROR, 'Mensaje: ' + e.getMessage());
                System.debug(LoggingLevel.ERROR, 'StackTrace: ' + e.getStackTraceString());

                throw new VFS_GenerarDocumentosUtilityException('Error al consultar la definición de documento "' + name + '": ' + e.getMessage() + '. Verifique que el objeto VFS_DefinicionDocumentos__c existe y tiene los permisos apropiados.');
            }
            
            if (defs.isEmpty()) {
                throw new VFS_GenerarDocumentosUtilityException('No se encontró ninguna definición de documento con el nombre "' + name + '". Verifique que la definición existe y está configurada correctamente.');
            }
            
            SObject def = defs[0];
            String vfpName = (String)def.get('VFS_Visualforce__c');
            String fileName = (String)def.get('VFS_NombreDocumento__c');

            System.debug('vfpName obtenido desde definición: ' + vfpName);
            System.debug('fileName obtenido desde definición: ' + fileName);
            
            Id docid = generarPDFyContentDocument(vfpName, recordId, fileName);
            System.debug('ContentDocumentId generado: ' + docid);
            return docid;
            
        } catch (VFS_GenerarDocumentosUtilityException e) {
            System.debug(LoggingLevel.ERROR, 'VFS_GenerarDocumentosUtilityException en generarPDFDesdeDefinicion');
            System.debug(LoggingLevel.ERROR, 'Mensaje: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'StackTrace: ' + e.getStackTraceString());

            String errorMessage = e.getMessage();
            Exception auraEx = new AuraHandledException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        } catch (AuraHandledException e) {
            System.debug(LoggingLevel.ERROR, 'AuraHandledException re-lanzada en generarPDFDesdeDefinicion');
            System.debug(LoggingLevel.ERROR, 'Mensaje: ' + e.getMessage());
            throw e;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception inesperada en generarPDFDesdeDefinicion');
            System.debug(LoggingLevel.ERROR, 'Tipo excepción: ' + e.getTypeName());
            System.debug(LoggingLevel.ERROR, 'Mensaje: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'StackTrace: ' + e.getStackTraceString());

            String errorMessage = 'Error inesperado al generar PDF desde la definición de documento. Por favor, contacte al administrador del sistema.';
            Exception auraEx = new AuraHandledException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        }
    }

    @AuraEnabled(cacheable=true)
    public static Id obtenerContentDocumentId(String titulo, Id recordId) {
        System.debug('on VFS_GenerarDocumentosUtility.obtenerContentDocumentId()');
        System.debug('Parámetros recibidos - titulo: ' + titulo + ', recordId: ' + recordId);

        try {
            System.debug('Buscando ContentDocumentId para título: ' + titulo + ', recordId: ' + recordId);

            if (String.isBlank(titulo) || recordId == null) {
                System.debug('obtenerContentDocumentId | título o recordId vacío. Retornando null.');
                return null;
            }
            
            List<ContentDocumentLink> links;
            try {
                if (Test.isRunningTest() && titulo == 'FORCE_LINK_QUERY_ERROR') {
                    throw new QueryException('Error simulado en consulta de ContentDocumentLink');
                }

                System.debug('Ejecutando query ContentDocumentLink por título y recordId');
                links = [
                    SELECT ContentDocumentId
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId = :recordId
                      AND ContentDocument.Title = :titulo
                    LIMIT 1
                ];
                System.debug('links size: ' + links.size());

            } catch (QueryException e) {
                System.debug(LoggingLevel.ERROR, 'QueryException en obtenerContentDocumentId');
                System.debug(LoggingLevel.ERROR, 'Mensaje: ' + e.getMessage());
                System.debug(LoggingLevel.ERROR, 'StackTrace: ' + e.getStackTraceString());

                throw new VFS_GenerarDocumentosUtilityException('Error al buscar el documento "' + titulo + '" vinculado al registro: ' + e.getMessage());
            }
            
            if (links.isEmpty()) {
                System.debug('No se encontraron links para el título: ' + titulo);
                return null; 
            }
            
            System.debug('ContentDocumentId encontrado: ' + links[0].ContentDocumentId);
            return links[0].ContentDocumentId; 
            
        } catch (VFS_GenerarDocumentosUtilityException e) {
            System.debug(LoggingLevel.ERROR, 'VFS_GenerarDocumentosUtilityException en obtenerContentDocumentId');
            System.debug(LoggingLevel.ERROR, 'Mensaje: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'StackTrace: ' + e.getStackTraceString());

            String errorMessage = e.getMessage();
            Exception auraEx = new AuraHandledException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception inesperada en obtenerContentDocumentId');
            System.debug(LoggingLevel.ERROR, 'Tipo excepción: ' + e.getTypeName());
            System.debug(LoggingLevel.ERROR, 'Mensaje: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'StackTrace: ' + e.getStackTraceString());

            String errorMessage = 'Error inesperado al obtener el documento. Por favor, contacte al administrador del sistema.';
            Exception auraEx = new AuraHandledException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String GenerarURl(String contentDocumentId) {
        System.debug('on VFS_GenerarDocumentosUtility.GenerarURl()');
        System.debug('Parámetro recibido - contentDocumentId: ' + contentDocumentId);

        try {
            if (String.isBlank(contentDocumentId)) {
                System.debug('GenerarURl | contentDocumentId vacío. Retornando null.');
                return null;
            }
            
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            String url = baseUrl + '/' + contentDocumentId;
            System.debug('URL generada: ' + url);
            return url;
            
        } catch (VFS_GenerarDocumentosUtilityException e) {
            System.debug(LoggingLevel.ERROR, 'VFS_GenerarDocumentosUtilityException en GenerarURl');
            System.debug(LoggingLevel.ERROR, 'Mensaje: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'StackTrace: ' + e.getStackTraceString());

            String errorMessage = e.getMessage();
            Exception auraEx = new AuraHandledException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception inesperada en GenerarURl');
            System.debug(LoggingLevel.ERROR, 'Tipo excepción: ' + e.getTypeName());
            System.debug(LoggingLevel.ERROR, 'Mensaje: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'StackTrace: ' + e.getStackTraceString());

            String errorMessage = 'Error inesperado al generar la URL del documento. Por favor, contacte al administrador del sistema.';
            Exception auraEx = new AuraHandledException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        }
    }

    @AuraEnabled(cacheable=false)
    public static String GetTitulo(String ButtonName){
        System.debug('on VFS_GenerarDocumentosUtility.GetTitulo()');
        System.debug('Parámetro recibido - ButtonName: ' + ButtonName);

        try {
            if (String.isBlank(ButtonName)) {
                throw new VFS_GenerarDocumentosUtilityException('El nombre del botón no puede estar vacío. Se requiere especificar el tipo de proceso para obtener el título correspondiente.');
            }
            
            String titulo = '';
            if (ButtonName == 'Firmar_documento_KYCF') {
                titulo = 'Conozca su cliente persona física';
            } else if (ButtonName == 'Firmar_documento_KYCJ') {
                titulo = 'Conozca su cliente persona jurídica';
            } else if (ButtonName == 'VFS_FirmaAperturaCuenta') {
                titulo = 'Apertura de cuenta de ahorro';
            } else if (ButtonName == 'VFS_FirmarContratoUnico') {
                titulo = 'Contrato Único';
            } else if (ButtonName.contains('Resumen Convenio Único')) {
                titulo = ButtonName.trim();
            } else {
                throw new VFS_GenerarDocumentosUtilityException('Tipo de proceso no reconocido: "' + ButtonName + '". Los tipos válidos son: Firmar_documento_KYCF, Firmar_documento_KYCJ, VFS_FirmaAperturaCuenta, VFS_FirmarContratoUnico y Resumen Convenio Único.');
            }
            
            System.debug('Título retornado: ' + titulo);
            return titulo;
            
        } catch (VFS_GenerarDocumentosUtilityException e) {
            System.debug(LoggingLevel.ERROR, 'VFS_GenerarDocumentosUtilityException en GetTitulo');
            System.debug(LoggingLevel.ERROR, 'Mensaje: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'StackTrace: ' + e.getStackTraceString());

            String errorMessage = e.getMessage();
            Exception auraEx = new AuraHandledException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception inesperada en GetTitulo');
            System.debug(LoggingLevel.ERROR, 'Tipo excepción: ' + e.getTypeName());
            System.debug(LoggingLevel.ERROR, 'Mensaje: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'StackTrace: ' + e.getStackTraceString());

            String errorMessage = 'Error inesperado al obtener el título del documento. Por favor, contacte al administrador del sistema.';
            Exception auraEx = new AuraHandledException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        }
    }

    @AuraEnabled(cacheable=true)
    public static Boolean obtenerContratoFirmadoERP(Id accountId) {
        System.debug('on VFS_GenerarDocumentosUtility.obtenerContratoFirmadoERP()');
        System.debug('Parámetro recibido - accountId: ' + accountId);

        try {
            if (accountId == null) {
                throw new VFS_GenerarDocumentosUtilityException('El ID de la cuenta no puede estar vacío. Se requiere un ID válido de Account para consultar el estado del contrato.');
            }
            
            Account acc;
            try {
                if (Test.isRunningTest() && String.valueOf(accountId).endsWith('FORCE_ACCOUNT_QUERY_ERROR')) {
                    throw new QueryException('Error simulado en consulta de Account');
                }

                System.debug('Ejecutando query Account para obtener VFS_ContratoFirmadoERP__c. accountId: ' + accountId);
                acc = [SELECT VFS_ContratoFirmadoERP__c FROM Account WHERE Id = :accountId LIMIT 1];
                System.debug('Valor VFS_ContratoFirmadoERP__c: ' + acc.VFS_ContratoFirmadoERP__c);

            } catch (QueryException e) {
                System.debug(LoggingLevel.ERROR, 'QueryException en obtenerContratoFirmadoERP');
                System.debug(LoggingLevel.ERROR, 'Mensaje: ' + e.getMessage());
                System.debug(LoggingLevel.ERROR, 'StackTrace: ' + e.getStackTraceString());

                throw new VFS_GenerarDocumentosUtilityException('Error al consultar la cuenta: ' + e.getMessage() + '. Verifique que el ID de cuenta es válido y que tiene permisos de acceso.');
            }
            
            return acc.VFS_ContratoFirmadoERP__c;
            
        } catch (VFS_GenerarDocumentosUtilityException e) {
            System.debug(LoggingLevel.ERROR, 'VFS_GenerarDocumentosUtilityException en obtenerContratoFirmadoERP');
            System.debug(LoggingLevel.ERROR, 'Mensaje: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'StackTrace: ' + e.getStackTraceString());

            String errorMessage = e.getMessage();
            Exception auraEx = new AuraHandledException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception inesperada en obtenerContratoFirmadoERP');
            System.debug(LoggingLevel.ERROR, 'Tipo excepción: ' + e.getTypeName());
            System.debug(LoggingLevel.ERROR, 'Mensaje: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'StackTrace: ' + e.getStackTraceString());

            String errorMessage = 'Error inesperado al consultar el estado del contrato firmado. Por favor, contacte al administrador del sistema.';
            Exception auraEx = new AuraHandledException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        }
    }
}