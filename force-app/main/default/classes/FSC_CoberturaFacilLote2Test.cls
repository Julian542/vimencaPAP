@IsTest
private class FSC_CoberturaFacilLote2Test {
    @TestSetup
    static void asignarPermisosAdministrador() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            PermissionSet permiso = [SELECT Id FROM PermissionSet WHERE Name = 'FSC_PS_Administrador' LIMIT 1];
            // El usuario que ejecuta los tests puede tener ya el permission set asignado.
            if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetId = :permiso.Id] == 0) {
                insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permiso.Id);
            }
        }
    }

    private static Id recordTypeId(String developerName) {
        return ResidentialLoanApplication.SObjectType.getDescribe()
            .getRecordTypeInfosByDeveloperName().get(developerName).getRecordTypeId();
    }

    private static Account createAccount(String suffix) {
        Account account = new Account(
            LastName = 'Cliente cobertura ' + suffix,
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Fisica').getRecordTypeId(),
            ACC_NumIdentificacion__c = '0010000' + suffix.leftPad(4, '0'),
            ACC_TipoIdentificacion__c = 'Cédula',
            ACC_RNC__c = '101' + suffix.leftPad(6, '0'),
            VFS_RegistroMercantil__c = 'RM-' + suffix,
            BillingStreet = 'Calle prueba',
            BillingCity = 'Santo Domingo',
            BillingCountry = 'República Dominicana'
        );
        insert account;
        return account;
    }

    private static ResidentialLoanApplication createRla(String suffix, String recordTypeDeveloperName) {
        Account account = createAccount(suffix);
        ResidentialLoanApplication rla = new ResidentialLoanApplication(
            Name = 'RLA cobertura ' + suffix,
            AccountId = account.Id,
            RecordTypeId = recordTypeId(recordTypeDeveloperName),
            Status = 'En proceso',
            FSC_Subestado__c = 'Análisis de crédito',
            FSC_TipoSolicitud__c = 'BPR',
            FSC_Monto__c = 500000,
            FSC_MontoAprobado__c = 450000,
            FSC_Moneda__c = '1',
            FSC_TasaInteres__c = 12,
            FSC_Plazo_meses__c = '24',
            FSC_Fecha_Contrato__c = Date.today(),
            FSC_Tipo_de_Garantia__c = 'Sin Garantía',
            FSC_UsuarioPagaresYContratos__c = UserInfo.getUserId(),
            FSC_lineaFinanciera__c = '32',
            FSC_subAplicacion__c = '401'
        );
        insert rla;
        return rla;
    }

    private static FSC_Garantia__c createDepositGuarantee(Id rlaId) {
        FSC_Garantia__c guarantee = new FSC_Garantia__c(
            Name = 'Certificado cobertura',
            FSC_Residential_Loan_Application__c = rlaId,
            FSC_Clase_de_Garantia__c = 'CERTIFICADOS DEPOSITOS BANCO VIMENCA',
            FSC_Tipo_de_Garantia__c = 'Certificado de depósito',
            FSC_Numero_Certificado_Deposito__c = 'CD-123',
            FSC_Titular_Certificado_Deposito__c = 'Titular cobertura',
            FSC_Monto_Certificado_Deposito__c = 600000,
            FSC_Moneda_Certificado_Deposito__c = 'Pesos Dominicanos'
        );
        insert guarantee;
        return guarantee;
    }

    @IsTest
    static void productosCubreEntradasYRespuestas() {
        List<Object> products = new List<Object>{
            new Map<String, Object>{
                'CLAVE_PRODUCTO' => 44,
                'NOMBRE' => 'Producto activo',
                'CODIGO_LINEA_FINANCIERA' => '32',
                'CODIGO_SUB_APLICACION' => 401
            },
            new Map<String, Object>{
                'CLAVE_PRODUCTO' => 45,
                'NOMBRE' => 'Producto sin uso',
                'CODIGO_LINEA_FINANCIERA' => '32',
                'CODIGO_SUB_APLICACION' => 401
            }
        };
        FSC_APIPrestamoProductos.mockIpResponse = new Map<String, Object>{
            'success' => true,
            'productos' => products
        };

        FSC_APIPrestamoProductos.Input byCodes = new FSC_APIPrestamoProductos.Input();
        byCodes.lineaFinanciera = '32 - Línea';
        byCodes.subAplicacion = '401';
        FSC_APIPrestamoProductos.Input byKey = new FSC_APIPrestamoProductos.Input();
        byKey.claveProducto = '44.0';
        FSC_APIPrestamoProductos.Input invalidInput = new FSC_APIPrestamoProductos.Input();

        List<FSC_APIPrestamoProductos.Output> outputs = FSC_APIPrestamoProductos.run(
            new List<FSC_APIPrestamoProductos.Input>{ byCodes, byKey, invalidInput, null }
        );
        System.assertEquals(4, outputs.size());
        System.assertEquals(true, outputs[0].success);
        System.assertEquals(true, outputs[1].success);
        System.assertEquals(false, outputs[2].success);

        System.assertEquals(0, FSC_APIPrestamoProductos.run(null).size());
        System.assertEquals(0, FSC_APIPrestamoProductos.extractProductos(' ').size());
        System.assertEquals(2, FSC_APIPrestamoProductos.extractProductos(JSON.serialize(products)).size());
        System.assertEquals(
            0,
            FSC_APIPrestamoProductos.extractProductos(new Map<String, Object>{ 'success' => true }).size()
        );

        try {
            FSC_APIPrestamoProductos.extractProductos(
                new Map<String, Object>{ 'success' => false, 'error' => 'error controlado' }
            );
            System.assert(false, 'Debió lanzar CalloutException.');
        } catch (CalloutException expected) {
            System.assert(expected.getMessage().contains('error controlado'));
        }
    }

    @IsTest
    static void participantesYConsultasSimples() {
        ResidentialLoanApplication rla = createRla('101', 'FSC_Solicitud_Credito_Consumo');

        FSC_ContratoParticipanteService.ParticipantesContrato participants =
            FSC_ContratoParticipanteService.getParticipantes('SOLIDARIO');
        System.assertNotEquals(null, participants.representanteBanco1);
        System.assertNotEquals(null, participants.representanteBanco2);
        System.assertNotEquals(null, participants.notario);

        System.assertNotEquals(null, FSC_ConsultaDocumentosAnalisisCredito.seleccionarSolicitud(rla.Id));
        System.assertNotEquals(null, FSC_ConsultaDocumentosAnalisisCredito.seleccionarCuenta(rla.AccountId));
        System.assertEquals(0, FSC_ConsultaDocumentosAnalisisCredito.seleccionarParticipantes(rla.Id).size());
        System.assertEquals(0, FSC_ConsultaDocumentosAnalisisCredito.seleccionarIngresos(rla.Id).size());
        System.assertEquals(0, FSC_ConsultaDocumentosAnalisisCredito.seleccionarDeudas(rla.Id).size());
        System.assertEquals(0, FSC_ConsultaDocumentosAnalisisCredito.seleccionarActivos(rla.Id).size());
        System.assertEquals(0, FSC_ConsultaDocumentosAnalisisCredito.seleccionarGarantias(rla.Id).size());
        System.assertEquals(0, FSC_ConsultaDocumentosAnalisisCredito.seleccionarFacilidadesCredito(rla.Id).size());
        System.assertEquals(null, FSC_ConsultaDocumentosAnalisisCredito.seleccionarHistorialPago(rla.Id));

        FSC_ChecklistDocumentos__c document = new FSC_ChecklistDocumentos__c(
            FSC_TipoDeSolicitudDeCredito__c = 'Solicitud de crédito consumo',
            FSC_CategoriaDelDocumento__c = 'Documentos para análisis',
            FSC_NroDeDocumento__c = 90,
            FSC_NombreDelDocumento__c = 'Documento general'
        );
        insert document;
        FSC_SolicitudDeCreditoYChecklistDeDocs__c joinRecord =
            new FSC_SolicitudDeCreditoYChecklistDeDocs__c(
                FSC_SolicitudDeCredito__c = rla.Id,
                FSC_Documento__c = document.Id,
                FSC_NoAplica__c = false
            );
        insert joinRecord;
        insert new List<ContentVersion>{
            new ContentVersion(
                Title = 'Carta laboral cobertura',
                PathOnClient = 'carta-laboral.pdf',
                VersionData = Blob.valueOf('PDF'),
                FirstPublishLocationId = joinRecord.Id
            ),
            new ContentVersion(
                Title = 'Volante de pago cobertura',
                PathOnClient = 'volante-pago.pdf',
                VersionData = Blob.valueOf('PDF'),
                FirstPublishLocationId = joinRecord.Id
            )
        };
        System.assertEquals(2, FSC_ConsultaDocumentosAnalisisCredito.seleccionarEvidenciasIngresos(rla.Id).size());
        System.assertEquals(0, FSC_ConsultaDocumentosAnalisisCredito.seleccionarExcepciones(rla.Id).size());
        FSC_ConsultaDocumentosAnalisisCredito.seleccionarTasaCambioActual();

        System.assertEquals(null, FSC_ConsultaDocumentosAnalisisCredito.seleccionarSolicitud(null));
        System.assertEquals(null, FSC_ConsultaDocumentosAnalisisCredito.seleccionarCuenta(null));
        System.assertEquals(null, FSC_ConsultaDocumentosAnalisisCredito.seleccionarEmpleo(null));
        System.assertEquals(0, FSC_ConsultaDocumentosAnalisisCredito.seleccionarFacilidadesExternas(null).size());
        System.assertEquals(0, FSC_ConsultaDocumentosAnalisisCredito.seleccionarEvidenciasIngresos(null).size());
    }

    @IsTest
    static void resolverConsumoYControladorPignoracion() {
        ResidentialLoanApplication noGuarantee = createRla('201', 'FSC_Solicitud_Credito_Consumo');
        FSC_ConsumoDocumentoResolver.ResolucionDocumento simple = FSC_ConsumoDocumentoResolver.resolve(noGuarantee.Id);
        System.assertEquals(FSC_ConsumoDocumentoResolver.PAGARE_SIMPLE, simple.codigoPagare);

        ResidentialLoanApplication highAmount = createRla('202', 'FSC_Solicitud_Credito_Consumo');
        update new ResidentialLoanApplication(Id = highAmount.Id, FSC_Monto__c = 3000000, FSC_MontoAprobado__c = null);
        System.assertEquals(
            FSC_ConsumoDocumentoResolver.PAGARE_NOTARIAL,
            FSC_ConsumoDocumentoResolver.resolve(highAmount.Id).codigoPagare
        );

        ResidentialLoanApplication cdRla = createRla('203', 'FSC_Solicitud_Credito_Consumo');
        update new ResidentialLoanApplication(
            Id = cdRla.Id,
            FSC_Tipo_de_Garantia__c = 'Garantía Prendaria y/o Mobiliaria',
            FSC_Relacion_Propietario_CD__c = 'Persona distinta',
            FSC_Identificacion_Propietario_CD__c = '00100000203',
            FSC_Numero_Fisico_CD__c = 'FIS-203',
            FSC_Lugar_Pignoracion_CD__c = 'Santo Domingo'
        );
        FSC_Garantia__c guarantee = createDepositGuarantee(cdRla.Id);
        FSC_ConsumoDocumentoResolver.ResolucionDocumento cd = FSC_ConsumoDocumentoResolver.resolve(cdRla.Id);
        System.assertEquals(guarantee.Id, cd.garantiaId);
        System.assertEquals(FSC_ConsumoDocumentoResolver.PAGARE_COMPLEMENTARIO, cd.codigoPagare);

        ApexPages.currentPage().getParameters().put('fechaDocumento', String.valueOf(Date.today()));
        FSC_PignoracionCertificadoConsumoCtrl controller =
            new FSC_PignoracionCertificadoConsumoCtrl(new ApexPages.StandardController(cdRla));
        System.assertEquals('CD-123', controller.numeroCertificado);
        System.assertEquals(true, controller.propietarioDistinto);

        ResidentialLoanApplication pyme = createRla('204', 'FSC_Solicitud_Credito_PYME');
        System.assertEquals(false, FSC_ConsumoDocumentoResolver.resolve(pyme.Id).aplicaConsumo);
    }

    @IsTest
    static void resolverPlantillasExplicitasYSolicitudes() {
        Id anyId = UserInfo.getUserId();
        List<String> templates = new List<String>{
            FSC_RLAContractTemplateResolver.TEMPLATE_SOLA_FIRMA,
            FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_MOBILIARIA_CON_POSESION,
            FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_HIPOTECARIA,
            FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_MOBILIARIA_SIN_POSESION,
            FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_SOLIDARIA,
            FSC_RLAContractTemplateResolver.TEMPLATE_CONSUMO_GARANTIA_HIPOTECARIA,
            FSC_RLAContractTemplateResolver.TEMPLATE_CONSUMO_GARANTIA_MOBILIARIA
        };
        for (String templateCode : templates) {
            System.assertNotEquals(null, FSC_RLAContractTemplateResolver.getMetadataContractType(templateCode));
            System.assertNotEquals(null, FSC_RLAContractTemplateResolver.resolvePageReference(anyId, templateCode));
        }
        System.assertEquals(null, FSC_RLAContractTemplateResolver.getMetadataContractType('NO_EXISTE'));
        try {
            FSC_RLAContractTemplateResolver.resolvePageReference(anyId, 'NO_EXISTE');
            System.assert(false, 'Debió rechazar una plantilla desconocida.');
        } catch (FSC_RLAContractTemplateResolver.FSC_RLAContractTemplateResolverException expected) {
            System.assertNotEquals(null, expected);
        }

        ResidentialLoanApplication consumption = createRla('301', 'FSC_Solicitud_Credito_Consumo');
        System.assertEquals(false, FSC_RLAContractTemplateResolver.resolve(consumption.Id).aplicaContrato);

        ResidentialLoanApplication pyme = createRla('302', 'FSC_Solicitud_Credito_PYME');
        FSC_RLAContractTemplateResolver.ContractResolution resolution =
            FSC_RLAContractTemplateResolver.resolve(pyme.Id);
        System.assertEquals(FSC_RLAContractTemplateResolver.TEMPLATE_SOLA_FIRMA, resolution.templateCode);
        System.assertNotEquals(null, FSC_RLAContractTemplateResolver.resolvePageReference(pyme.Id));

        ResidentialLoanApplication mortgage = createRla('303', 'FSC_Solicitud_Credito_PYME');
        update new ResidentialLoanApplication(Id = mortgage.Id, FSC_Tipo_de_Garantia__c = 'Garantía Real');
        insert new LoanApplicationAsset(
            Name = 'Inmueble cobertura',
            LoanApplicationId = mortgage.Id,
            AssetClass = 'Bienes inmuebles',
            AssetType = 'Otro',
            FSC_Descripcion_de_la_Garantia__c = '3'
        );
        System.assertEquals(
            FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_HIPOTECARIA,
            FSC_RLAContractTemplateResolver.resolve(mortgage.Id).templateCode
        );

        ResidentialLoanApplication vehicle = createRla('304', 'FSC_Solicitud_Credito_PYME');
        update new ResidentialLoanApplication(Id = vehicle.Id, FSC_Tipo_de_Garantia__c = 'Garantía Prendaria y/o Mobiliaria');
        insert new LoanApplicationAsset(
            Name = 'Vehículo cobertura',
            LoanApplicationId = vehicle.Id,
            AssetClass = 'Otro',
            AssetType = 'Otro',
            FSC_Descripcion_de_la_Garantia__c = '28'
        );
        System.assertEquals(
            FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_MOBILIARIA_SIN_POSESION,
            FSC_RLAContractTemplateResolver.resolve(vehicle.Id).templateCode
        );

        ResidentialLoanApplication certificate = createRla('305', 'FSC_Solicitud_Credito_PYME');
        update new ResidentialLoanApplication(Id = certificate.Id, FSC_Tipo_de_Garantia__c = 'Garantía Prendaria y/o Mobiliaria');
        insert new LoanApplicationAsset(
            Name = 'Certificado cobertura',
            LoanApplicationId = certificate.Id,
            AssetClass = 'Financiero',
            AccountType = 'Certificado de depósito',
            FSC_Descripcion_de_la_Garantia__c = '31'
        );
        System.assertEquals(
            FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_MOBILIARIA_CON_POSESION,
            FSC_RLAContractTemplateResolver.resolve(certificate.Id).templateCode
        );
    }

    @IsTest
    static void asincronosConEntradasMinimas() {
        FSC_CreacionDesembolsoAsync.enqueue(null);
        FSC_CreacionDesembolsoAsync.Input invalidDisbursement = new FSC_CreacionDesembolsoAsync.Input();
        FSC_CreacionDesembolsoAsync.enqueue(new List<FSC_CreacionDesembolsoAsync.Input>{ null, invalidDisbursement });
        new FSC_CreacionDesembolsoAsync(new List<FSC_CreacionDesembolsoAsync.Input>()).execute(null);

        String prefix = ResidentialLoanApplication.SObjectType.getDescribe().getKeyPrefix();
        FSC_CreacionDesembolsoAsync.Input validDisbursement = new FSC_CreacionDesembolsoAsync.Input();
        validDisbursement.residentialLoanApplicationId = (Id) (prefix + '000000000001');

        ResidentialLoanApplication rla = createRla('401', 'FSC_Solicitud_Credito_Consumo');
        FSC_CreacionPrestamoAsync.Input loanInput = new FSC_CreacionPrestamoAsync.Input();
        loanInput.residentialLoanApplicationId = rla.Id;
        loanInput.codigoUsuario = 'USR';
        loanInput.codigoAgencia = '001';
        FSC_APIPrestamoProductos.mockIpResponse = new List<Object>();
        FSC_CreacionPrestamoAsync.enqueue(null);
        FSC_CreacionPrestamoAsync.enqueue(
            new List<FSC_CreacionPrestamoAsync.Input>{ null, new FSC_CreacionPrestamoAsync.Input() }
        );

        Test.startTest();
        FSC_CreacionDesembolsoAsync.enqueue(new List<FSC_CreacionDesembolsoAsync.Input>{ validDisbursement });
        FSC_CreacionPrestamoAsync.enqueue(new List<FSC_CreacionPrestamoAsync.Input>{ loanInput });
        new FSC_CreacionPrestamoAsync(new List<FSC_CreacionPrestamoAsync.Input>{ loanInput }).execute(null);
        Test.stopTest();

        ResidentialLoanApplication updated = [
            SELECT FSC_FlagErrorAPIPrestamos__c FROM ResidentialLoanApplication WHERE Id = :rla.Id
        ];
        System.assertEquals(true, updated.FSC_FlagErrorAPIPrestamos__c);
    }

    @IsTest
    static void servicioAprobacionRamasSinProceso() {
        System.assertEquals(false, FSC_ExcepcionApprovalService.canCurrentUserAct((ProcessInstanceWorkitem) null));
        System.assertEquals(false, FSC_ExcepcionApprovalService.canCurrentUserAct(new List<ProcessInstanceWorkitem>()));
        System.assertEquals(false, FSC_ExcepcionApprovalService.hasActiveWorkItem(null));
        System.assertEquals(0, FSC_ExcepcionApprovalService.getActionableTargetIds(null).size());

        ProcessInstanceWorkitem currentUserItem = new ProcessInstanceWorkitem(ActorId = UserInfo.getUserId());
        System.assertEquals(true, FSC_ExcepcionApprovalService.canCurrentUserAct(currentUserItem));
        Map<Id, List<ProcessInstanceWorkitem>> byTarget = new Map<Id, List<ProcessInstanceWorkitem>>{
            UserInfo.getUserId() => new List<ProcessInstanceWorkitem>{ currentUserItem }
        };
        System.assertEquals(1, FSC_ExcepcionApprovalService.getActionableTargetIds(byTarget).size());

        FSC_ExcepcionApprovalService.testForceAuthorized = true;
        ProcessInstanceWorkitem arbitraryItem = new ProcessInstanceWorkitem(ActorId = UserInfo.getUserId());
        System.assertEquals(true, FSC_ExcepcionApprovalService.canCurrentUserAct(arbitraryItem));

        try {
            FSC_ExcepcionApprovalService.assertCurrentUserCanAct(null);
            System.assert(false, 'Debió validar el Id requerido.');
        } catch (AuraHandledException expected) {
            System.assertNotEquals(null, expected);
        }
    }

    @IsTest
    static void actoGarantiaControladorYGeneracion() {
        ResidentialLoanApplication rla = createRla('501', 'FSC_Solicitud_Credito_PYME');
        update new ResidentialLoanApplication(
            Id = rla.Id,
            FSC_Tipo_de_Garantia__c = 'Garantía Solidaria',
            FSC_Requiere_Acto_Garantia__c = true,
            FSC_Acto_Garantia_Generado__c = false,
            FSC_Documento_Base_Acto_Garantia__c = 'Documento base',
            FSC_Forma_Pago_Acto_Garantia__c = 'Cuotas mensuales',
            FSC_Generales_Fiadores_Acto__c = 'Generales del fiador',
            FSC_Nombre_del_negocio__c = 'Negocio prueba'
        );
        insert new LoanApplicant(
            Name = 'Fiador cobertura',
            LoanApplicationId = rla.Id,
            FSC_TipoSolicitante__c = 'Garante',
            FSC_TipoIdentificacion__c = 'Cédula',
            FSC_NumIdentificacion__c = '00100000501',
            FSC_Nombre__c = 'Ana',
            FSC_PrimerApellido__c = 'Prueba'
        );

        ApexPages.currentPage().getParameters().put('fechaActo', String.valueOf(Date.today()));
        FSC_ActoGarantiaSolidariaCtrl controller =
            new FSC_ActoGarantiaSolidariaCtrl(new ApexPages.StandardController(rla));
        System.assertEquals(1, controller.fiadores.size());
        System.assert(controller.nombresComparecientes.contains('Ana'));

        Test.startTest();
        Id contentVersionId = FSC_GenerarActoGarantiaSolidaria.generar(rla.Id);
        Test.stopTest();
        System.assertNotEquals(null, contentVersionId);
    }
}