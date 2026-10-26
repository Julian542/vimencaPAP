@IsTest
private class FSC_CoberturaFacilLote3Test {
    @TestSetup
    static void setupData() {
        FSC_FabricaDatosDocumentosAnalisisTest.crearDatosBase();
        ResidentialLoanApplication approved = FSC_FabricaDatosDocumentosAnalisisTest.crearSolicitud(
            FSC_FabricaDatosDocumentosAnalisisTest.obtenerCuentaBase().Id,
            'FSC_Solicitud_Credito_PYME',
            'En proceso',
            'Análisis de crédito',
            500000,
            false
        );
        approved.FSC_SolicitudAprobadaPorComite__c = true;
        insert approved;
    }

    private static User createNonAdminUser() {
        Profile profile = [
            SELECT Id
            FROM Profile
            WHERE PermissionsModifyAllData = false
            LIMIT 1
        ];
        String uniqueKey = String.valueOf(System.now().getTime());
        User userRecord;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            userRecord = new User(
                Alias = 'cvrlck',
                CommunityNickname = 'cvrlck' + uniqueKey,
                Email = 'cobertura.lock@example.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Cobertura Lock',
                LanguageLocaleKey = 'es',
                LocaleSidKey = 'es_AR',
                ProfileId = profile.Id,
                TimeZoneSidKey = 'America/Santo_Domingo',
                Username = 'cobertura.lock.' + uniqueKey + '@example.com'
            );
            completarCamposObligatoriosUsuario(userRecord);
            insert userRecord;
        }
        return userRecord;
    }

    @IsTest
    static void regeneratesExistingComplementaryPagare() {
        Account account = FSC_FabricaDatosDocumentosAnalisisTest.obtenerCuentaBase();
        ResidentialLoanApplication rla = FSC_FabricaDatosDocumentosAnalisisTest.crearSolicitud(
            account.Id,
            'FSC_Solicitud_Credito_PYME',
            'En proceso',
            'Gestionar firmas',
            500000,
            false
        );
        rla.FSC_NumeroPrestamoAbanks__c = '54321';
        rla.FSC_RequiereContratoPagareNotarial__c = false;
        insert rla;

        insert new ContentVersion(
            Title = 'Pagaré Complementario anterior',
            PathOnClient = 'pagare-anterior.pdf',
            VersionData = Blob.valueOf('PDF ANTERIOR'),
            FirstPublishLocationId = rla.Id
        );

        FSC_RegenerarPagareComplementarioQbl.enqueueIfExists(null);
        FSC_RegenerarPagareComplementarioQbl.enqueueIfExists(new Set<Id>());
        new FSC_RegenerarPagareComplementarioQbl(null).execute(null);

        Test.startTest();
        FSC_RegenerarPagareComplementarioQbl.enqueueIfExists(new Set<Id>{ rla.Id });
        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT ContentDocument.Title
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :rla.Id
        ];
        System.assertEquals(1, links.size());
        System.assert(links[0].ContentDocument.Title.startsWith('Pagare Complementario'));
    }

    @IsTest
    static void coversApprovedCreditLocks() {
        ResidentialLoanApplication approved = [
            SELECT Id, FSC_SolicitudAprobadaPorComite__c
            FROM ResidentialLoanApplication
            WHERE FSC_SolicitudAprobadaPorComite__c = true
            LIMIT 1
        ];
        User nonAdmin = createNonAdminUser();

        System.runAs(nonAdmin) {
            LoanApplicant applicant = new LoanApplicant(LoanApplicationId = approved.Id);
            LoanApplicationAsset asset = new LoanApplicationAsset(LoanApplicationId = approved.Id);
            FSC_Facilidades_De_Credito__c facility = new FSC_Facilidades_De_Credito__c(
                FSC_Residential_Loan_Application__c = approved.Id
            );
            FSC_Seguro__c insurance = new FSC_Seguro__c(
                FSC_Residential_Loan_Application__c = approved.Id
            );

            FSC_CreditoAprobadoLockService.validarParticipantes(new List<LoanApplicant>{ applicant });
            FSC_CreditoAprobadoLockService.validarActivosSolicitud(new List<LoanApplicationAsset>{ asset });
            FSC_CreditoAprobadoLockService.validarFacilidades(
                new List<FSC_Facilidades_De_Credito__c>{ facility }
            );
            FSC_CreditoAprobadoLockService.validarSeguros(new List<FSC_Seguro__c>{ insurance });
            System.assertEquals(1, applicant.getErrors().size());
            System.assertEquals(1, asset.getErrors().size());
            System.assertEquals(1, facility.getErrors().size());
            System.assertEquals(1, insurance.getErrors().size());

            FSC_Garantia__c newGuarantee = new FSC_Garantia__c(
                FSC_Residential_Loan_Application__c = approved.Id,
                Name = 'Garantía bloqueada'
            );
            FSC_CreditoAprobadoLockService.validarGarantias(
                new List<FSC_Garantia__c>{ newGuarantee },
                null,
                false
            );
            System.assertEquals(1, newGuarantee.getErrors().size());

            Id guaranteeId = (Id) (FSC_Garantia__c.SObjectType.getDescribe().getKeyPrefix() + '000000000001');
            FSC_Garantia__c previousGuarantee = new FSC_Garantia__c(
                Id = guaranteeId,
                FSC_Residential_Loan_Application__c = approved.Id,
                Name = 'Garantía existente',
                FSC_EsTasadorExterno__c = false
            );
            FSC_Garantia__c tasadorOnlyChange = previousGuarantee.clone(true, false, false, false);
            tasadorOnlyChange.FSC_EsTasadorExterno__c = true;
            FSC_CreditoAprobadoLockService.validarGarantias(
                new List<FSC_Garantia__c>{ tasadorOnlyChange },
                new Map<Id, FSC_Garantia__c>{ guaranteeId => previousGuarantee },
                true
            );
            ResidentialLoanApplication previousRla = new ResidentialLoanApplication(
                Id = approved.Id,
                FSC_SolicitudAprobadaPorComite__c = true,
                FSC_Monto__c = 500000
            );
            ResidentialLoanApplication changedRla = previousRla.clone(true, false, false, false);
            changedRla.FSC_Monto__c = 600000;
            FSC_CreditoAprobadoLockService.validarCamposCriticosSolicitud(
                new List<ResidentialLoanApplication>{ changedRla },
                new Map<Id, ResidentialLoanApplication>{ approved.Id => previousRla }
            );
            System.assertEquals(1, changedRla.getErrors().size());

            FSC_CreditoAprobadoLockService.iniciarDecisionComite();
            ResidentialLoanApplication committeeChange = previousRla.clone(true, false, false, false);
            committeeChange.FSC_Monto__c = 700000;
            FSC_CreditoAprobadoLockService.validarCamposCriticosSolicitud(
                new List<ResidentialLoanApplication>{ committeeChange },
                new Map<Id, ResidentialLoanApplication>{ approved.Id => previousRla }
            );
            FSC_CreditoAprobadoLockService.finalizarDecisionComite();
            System.assertEquals(0, committeeChange.getErrors().size());

            FSC_CreditoAprobadoLockService.iniciarPlanillaDesembolso();
            ResidentialLoanApplication planillaCompleta = previousRla.clone(true, false, false, false);
            planillaCompleta.FSC_TipoCredito__c = '06 - MIPYMES';
            ResidentialLoanApplication planillaCambia = previousRla.clone(true, false, false, false);
            planillaCambia.FSC_Monto__c = 800000;
            FSC_CreditoAprobadoLockService.validarCamposCriticosSolicitud(
                new List<ResidentialLoanApplication>{ planillaCompleta },
                new Map<Id, ResidentialLoanApplication>{ approved.Id => previousRla }
            );
            FSC_CreditoAprobadoLockService.validarCamposCriticosSolicitud(
                new List<ResidentialLoanApplication>{ planillaCambia },
                new Map<Id, ResidentialLoanApplication>{ approved.Id => previousRla }
            );
            FSC_CreditoAprobadoLockService.finalizarPlanillaDesembolso();
            System.assertEquals(0, planillaCompleta.getErrors().size(), 'La planilla puede completar campos críticos vacíos.');
            System.assertEquals(1, planillaCambia.getErrors().size(), 'La planilla no puede cambiar valores aprobados.');

            FSC_Garantia__c garantiaContrato = previousGuarantee.clone(true, false, false, false);
            garantiaContrato.FSC_Numero_Titulo__c = 'T-100';
            garantiaContrato.FSC_Valor_Vehiculo__c = 900000;
            FSC_Garantia__c garantiaFueraContrato = previousGuarantee.clone(true, false, false, false);
            garantiaFueraContrato.Name = 'Otra garantía';

            Id assetId = (Id) (LoanApplicationAsset.SObjectType.getDescribe().getKeyPrefix() + '000000000001');
            LoanApplicationAsset activoAnterior = new LoanApplicationAsset(Id = assetId, LoanApplicationId = approved.Id, CashOrMarketValue = 1000);
            LoanApplicationAsset activoContrato = activoAnterior.clone(true, false, false, false);
            activoContrato.FSC_Numero_Titulo_Contrato__c = 'T-200';
            LoanApplicationAsset activoMonto = activoAnterior.clone(true, false, false, false);
            activoMonto.CashOrMarketValue = 2000;

            Id seguroId = (Id) (FSC_Seguro__c.SObjectType.getDescribe().getKeyPrefix() + '000000000001');
            FSC_Seguro__c seguroAnterior = new FSC_Seguro__c(Id = seguroId, FSC_Residential_Loan_Application__c = approved.Id);
            FSC_Seguro__c seguroContrato = seguroAnterior.clone(true, false, false, false);
            seguroContrato.FSC_Numero_Poliza_Contrato__c = 'P-1';
            FSC_Seguro__c seguroNuevo = new FSC_Seguro__c(FSC_Residential_Loan_Application__c = approved.Id);

            FSC_CreditoAprobadoLockService.iniciarDatosContrato();
            FSC_CreditoAprobadoLockService.validarGarantias(
                new List<FSC_Garantia__c>{ garantiaContrato, garantiaFueraContrato },
                new Map<Id, FSC_Garantia__c>{ guaranteeId => previousGuarantee },
                true
            );
            FSC_CreditoAprobadoLockService.validarActivosSolicitud(
                new List<LoanApplicationAsset>{ activoContrato },
                new Map<Id, LoanApplicationAsset>{ assetId => activoAnterior }
            );
            FSC_CreditoAprobadoLockService.validarActivosSolicitud(
                new List<LoanApplicationAsset>{ activoMonto },
                new Map<Id, LoanApplicationAsset>{ assetId => activoAnterior }
            );
            FSC_CreditoAprobadoLockService.validarSeguros(
                new List<FSC_Seguro__c>{ seguroContrato },
                new Map<Id, FSC_Seguro__c>{ seguroId => seguroAnterior },
                false
            );
            FSC_CreditoAprobadoLockService.validarSeguros(new List<FSC_Seguro__c>{ seguroNuevo }, null, true);
            FSC_CreditoAprobadoLockService.finalizarDatosContrato();

            System.assertEquals(0, garantiaContrato.getErrors().size(), 'El contrato completa datos del título y montos vacíos.');
            System.assertEquals(1, garantiaFueraContrato.getErrors().size(), 'El contrato no edita otros campos de la garantía.');
            System.assertEquals(0, activoContrato.getErrors().size(), 'El contrato completa los campos de contrato del activo.');
            System.assertEquals(1, activoMonto.getErrors().size(), 'El contrato no cambia un monto ya informado.');
            System.assertEquals(0, seguroContrato.getErrors().size(), 'El contrato completa la póliza.');
            System.assertEquals(0, seguroNuevo.getErrors().size(), 'El contrato puede crear el seguro.');

            FSC_Garantia__c garantiaFormalizada = previousGuarantee.clone(true, false, false, false);
            garantiaFormalizada.FSC_Garantia_Constituida__c = 'Sí';
            garantiaFormalizada.FSC_Fecha_Constitucion_Garantia__c = Date.today();
            FSC_CreditoAprobadoLockService.validarGarantias(
                new List<FSC_Garantia__c>{ garantiaFormalizada },
                new Map<Id, FSC_Garantia__c>{ guaranteeId => previousGuarantee },
                true
            );
            System.assertEquals(0, garantiaFormalizada.getErrors().size(), 'La formalización de la garantía se permite tras la aprobación.');

            FSC_Seguro__c seguroSinContrato = new FSC_Seguro__c(FSC_Residential_Loan_Application__c = approved.Id);
            FSC_CreditoAprobadoLockService.validarSeguros(new List<FSC_Seguro__c>{ seguroSinContrato }, null, true);
            System.assertEquals(1, seguroSinContrato.getErrors().size(), 'Fuera del contrato el seguro sigue bloqueado.');
        }
    }

    // La org exige Oficina, Codigo y Canal de Atencion en todo usuario (regla Validar_Campos_Obligatorios_Usuario).
    private static void completarCamposObligatoriosUsuario(User usuario) {
        Map<String, Schema.SObjectField> campos = Schema.SObjectType.User.fields.getMap();
        for (String campo : new List<String>{ 'USE_Oficina__c', 'Canal_Atencion__c' }) {
            if (!campos.containsKey(campo)) {
                continue;
            }
            for (Schema.PicklistEntry valor : campos.get(campo).getDescribe().getPicklistValues()) {
                if (valor.isActive()) {
                    usuario.put(campo, valor.getValue());
                    break;
                }
            }
        }
        if (campos.containsKey('USE_Codigo__c')) {
            usuario.put('USE_Codigo__c', 'TEST');
        }
        if (campos.containsKey('USE_Oficina__c')) {
            asegurarOficinaEnDatosMaestros((String) usuario.get('USE_Oficina__c'));
        }
    }

    // El flow "Información usuario" busca la oficina del usuario en Datos_Maestros__c y falla si no existe.
    private static void asegurarOficinaEnDatosMaestros(String oficina) {
        if (String.isBlank(oficina) || [SELECT COUNT() FROM Datos_Maestros__c WHERE DM_Codigo_Oficina__c = :oficina AND DM_Tipo__c = 'Oficina'] > 0) {
            return;
        }
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert new Datos_Maestros__c(Name = 'Oficina test ' + oficina, DM_Codigo_Oficina__c = oficina, DM_Tipo__c = 'Oficina');
        }
    }
}