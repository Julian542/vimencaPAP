@IsTest
private class FSC_ProcesamientoAbanksTest {
    @TestSetup
    static void permisos() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            PermissionSet permiso = [SELECT Id FROM PermissionSet WHERE Name = 'FSC_PS_Administrador' LIMIT 1];
            if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetId = :permiso.Id] == 0) {
                insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permiso.Id);
            }
        }
    }

    private static ResidentialLoanApplication solicitud() {
        return solicitud(null);
    }

    private static ResidentialLoanApplication solicitud(String numeroPrestamo) {
        Account cliente = new Account(Name = 'Cliente modo Abanks');
        insert cliente;
        ResidentialLoanApplication rla = new ResidentialLoanApplication(
            Name = 'Solicitud modo Abanks', AccountId = cliente.Id, Status = 'En proceso',
            RecordTypeId = ResidentialLoanApplication.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName()
                .get('FSC_Solicitud_Credito_Consumo').getRecordTypeId(),
            FSC_Subestado__c = 'Creación de crédito', FSC_FormaDeDesembolso__c = 'Cuenta de ahorro',
            FSC_NumeroPrestamoAbanks__c = numeroPrestamo,
            FSC_UsuarioCaptura__c = UserInfo.getUserId(), FSC_UsuarioOperaciones__c = UserInfo.getUserId(),
            FSC_NumeroCuentaDesembolso__c = '123456', FSC_TipoSolicitud__c = 'BPR'
        );
        insert rla;
        return rla;
    }

    @IsTest
    static void conservaCircuitoManualAlEncender() {
        FSC_ProcesamientoAbanks.automatizacionTest = false;
        FSC_CapturaOperacionesService.testBypassPermissions = true;
        ResidentialLoanApplication rla = solicitud();
        Test.startTest();
        FSC_RlaAccionesController.guardarCapturaAbanks(rla.Id, '12345', true, true, true);
        FSC_ProcesamientoAbanks.automatizacionTest = true;
        Map<String, Object> contexto = FSC_RlaAccionesController.getCapturaOperacionesContext(rla.Id);
        List<ContentVersion> archivos = new List<ContentVersion>{
            new ContentVersion(Title = 'Amortización', PathOnClient = 'amortizacion.pdf', VersionData = Blob.valueOf('tabla'), FirstPublishLocationId = UserInfo.getUserId()),
            new ContentVersion(Title = 'Recibo', PathOnClient = 'recibo.pdf', VersionData = Blob.valueOf('recibo'), FirstPublishLocationId = UserInfo.getUserId())
        };
        insert archivos;
        Map<Id, ContentVersion> documentos = new Map<Id, ContentVersion>([SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :archivos]);
        FSC_RlaAccionesController.confirmarDesembolsoManual(rla.Id,
            new List<Id>{documentos.get(archivos[0].Id).ContentDocumentId}, new List<Id>{documentos.get(archivos[1].Id).ContentDocumentId});
        Test.stopTest();
        ResidentialLoanApplication resultado = [SELECT FSC_Subestado__c, FSC_FormaDeDesembolso__c, FSC_ProcesamientoAbanksManual__c, FSC_Desembolso_Realizado__c FROM ResidentialLoanApplication WHERE Id = :rla.Id];
        System.assertEquals(false, contexto.get('automatizacionHabilitada'));
        System.assertEquals('Cuenta de ahorro', resultado.FSC_FormaDeDesembolso__c);
        System.assert(resultado.FSC_ProcesamientoAbanksManual__c && resultado.FSC_Desembolso_Realizado__c && resultado.FSC_Subestado__c == 'Archivo y custodia');
    }

    @IsTest
    static void apagaApisYTrabajosPendientes() {
        FSC_ProcesamientoAbanks.automatizacionTest = true;
        ResidentialLoanApplication rla = solicitud();
        FSC_ProcesamientoAbanks.automatizacionTest = false;
        FSC_APIPrestamoPrestamos.Input prestamo = new FSC_APIPrestamoPrestamos.Input();
        prestamo.residentialLoanApplicationId = rla.Id;
        FSC_APIPrestamoDesembolso.Input desembolso = new FSC_APIPrestamoDesembolso.Input();
        desembolso.residentialLoanApplicationId = rla.Id;
        FSC_CreacionPrestamoAsync.Input asyncPrestamo = new FSC_CreacionPrestamoAsync.Input();
        asyncPrestamo.residentialLoanApplicationId = rla.Id;
        FSC_CreacionDesembolsoAsync.Input asyncDesembolso = new FSC_CreacionDesembolsoAsync.Input();
        asyncDesembolso.residentialLoanApplicationId = rla.Id;
        Test.startTest();
        List<FSC_APIPrestamoPrestamos.Output> prestamos = FSC_APIPrestamoPrestamos.run(new List<FSC_APIPrestamoPrestamos.Input>{prestamo});
        List<FSC_APIPrestamoDesembolso.Output> desembolsos = FSC_APIPrestamoDesembolso.run(new List<FSC_APIPrestamoDesembolso.Input>{desembolso});
        new FSC_CreacionPrestamoAsync(new List<FSC_CreacionPrestamoAsync.Input>{asyncPrestamo}).execute(null);
        new FSC_CreacionDesembolsoAsync(new List<FSC_CreacionDesembolsoAsync.Input>{asyncDesembolso}).execute(null);
        Test.stopTest();
        System.assert(prestamos[0].message.contains('deshabilitada') && desembolsos[0].message.contains('deshabilitada'));
        System.assertEquals(null, FSC_APIPrestamoPrestamos.lastIpInput);
        System.assertEquals(null, FSC_APIPrestamoDesembolso.lastIpInput);
    }

    @IsTest
    static void bloqueaReintentosManuales() {
        FSC_ProcesamientoAbanks.automatizacionTest = false;
        ResidentialLoanApplication rla = solicitud();
        Test.startTest();
        Integer bloqueados = 0;
        try { FSC_RlaAccionesController.reintentarCreacionPrestamo(rla.Id); }
        catch (AuraHandledException esperado) { bloqueados++; }
        update new ResidentialLoanApplication(Id = rla.Id, FSC_Subestado__c = 'Desembolso', FSC_FlagErrorAPIDesembolso__c = true);
        try { FSC_RlaAccionesController.reintentarDesembolso(rla.Id); }
        catch (AuraHandledException esperado) { bloqueados++; }
        FSC_ProcesamientoAbanks.automatizacionTest = true;
        System.assert(FSC_ProcesamientoAbanks.habilitadas(new Set<Id>{rla.Id}).isEmpty());
        FSC_ProcesamientoAbanks.habilitadas(null);
        Test.stopTest();
        System.assertEquals(2, bloqueados);
    }

    @IsTest
    static void conservaNumeroExistente() {
        FSC_ProcesamientoAbanks.automatizacionTest = false;
        FSC_CapturaOperacionesService.testBypassPermissions = true;
        // El número se carga al crear para no disparar el flow de validación (solo update) si en la org sigue activa una versión anterior.
        ResidentialLoanApplication rla = solicitud('12345');
        Test.startTest();
        Boolean rechazado = false;
        try { FSC_CapturaOperacionesService.guardarCaptura(rla.Id, '99999', true, true, true); }
        catch (AuraHandledException esperado) { rechazado = true; }
        FSC_CapturaOperacionesService.guardarCaptura(rla.Id, '12345', true, true, true);
        Test.stopTest();
        System.assert(rechazado);
        System.assertEquals('12345', [SELECT FSC_NumeroPrestamoAbanks__c FROM ResidentialLoanApplication WHERE Id = :rla.Id].FSC_NumeroPrestamoAbanks__c);
    }

    @IsTest
    static void respetaValidacionPendienteAlApagar() {
        FSC_ProcesamientoAbanks.automatizacionTest = true;
        FSC_CapturaOperacionesService.testBypassPermissions = true;
        ResidentialLoanApplication rla = solicitud('12345');
        // Se representa una aprobación iniciada antes del apagado.
        Approval.ProcessSubmitRequest peticion = new Approval.ProcessSubmitRequest();
        peticion.setObjectId(rla.Id);
        peticion.setProcessDefinitionNameOrId('FSC_ValidacionEnAbanks');
        peticion.setSkipEntryCriteria(true);
        peticion.setNextApproverIds(new List<Id>{UserInfo.getUserId()});
        Approval.process(peticion);
        FSC_ProcesamientoAbanks.automatizacionTest = false;
        Test.startTest();
        Map<String, Object> contexto = FSC_CapturaOperacionesService.contexto(rla.Id);
        Boolean rechazado = false;
        try { FSC_CapturaOperacionesService.guardarCaptura(rla.Id, '12345', true, true, true); }
        catch (AuraHandledException esperado) { rechazado = true; }
        FSC_RlaAccionesController.validarCreacionEnAbanks(rla.Id);
        Test.stopTest();
        System.assertEquals(false, contexto.get('puedeActuar'));
        System.assert(rechazado);
        System.assertEquals('Desembolso', [SELECT FSC_Subestado__c FROM ResidentialLoanApplication WHERE Id = :rla.Id].FSC_Subestado__c);
    }

    @IsTest
    static void configuracionYAsignacionAnterior() {
        System.assertEquals(true, FSC_ProcesamientoAbanks.habilitado());
        FSC_ProcesamientoAbanks.automatizacionTest = true;
        ResidentialLoanApplication rla = solicitud();
        FSC_ProcesamientoAbanks.automatizacionTest = false;
        Test.startTest();
        FSC_RlaAccionesController.prepararProcesamientoManual(rla.Id);
        FSC_RlaAccionesController.prepararProcesamientoManual(rla.Id);
        Map<String, Integer> inicializacion = FSC_CapturaOperacionesService.inicializarSolicitudesExistentes();
        Test.stopTest();
        System.assert(inicializacion.containsKey('procesadas'));
        System.assertEquals(true, [SELECT FSC_ProcesamientoAbanksManual__c FROM ResidentialLoanApplication WHERE Id = :rla.Id].FSC_ProcesamientoAbanksManual__c);
    }

    @IsTest
    static void impideReactivarSolicitudManual() {
        FSC_ProcesamientoAbanks.automatizacionTest = false;
        ResidentialLoanApplication rla = solicitud();
        FSC_ProcesamientoAbanks.automatizacionTest = true;
        Test.startTest();
        Database.SaveResult resultado = Database.update(new ResidentialLoanApplication(Id = rla.Id, FSC_ProcesamientoAbanksManual__c = false), false);
        Test.stopTest();
        System.assertEquals(false, resultado.isSuccess());
    }

    @IsTest
    static void ejecutaTrabajoHabilitadoSinRepetirEtapas() {
        FSC_ProcesamientoAbanks.automatizacionTest = true;
        ResidentialLoanApplication rla = solicitud();
        FSC_CreacionDesembolsoAsync.Input entrada = new FSC_CreacionDesembolsoAsync.Input();
        entrada.residentialLoanApplicationId = rla.Id;
        entrada.codigoUsuario = 'TEST';
        entrada.codigoAgencia = '1';
        Test.startTest();
        new FSC_CreacionDesembolsoAsync(new List<FSC_CreacionDesembolsoAsync.Input>{entrada}).execute(null);
        Test.stopTest();
        System.assertEquals(null, FSC_APIPrestamoDesembolso.lastIpInput);
    }
}