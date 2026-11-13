@IsTest
private class FSC_ApprovalHistoryControllerTest {

    private static Id getRecordTypeId(String developerName) {
        Map<String, Schema.RecordTypeInfo> rtMap =
            ResidentialLoanApplication.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
        return rtMap != null && rtMap.containsKey(developerName)
            ? rtMap.get(developerName).getRecordTypeId()
            : null;
    }

    private static ResidentialLoanApplication createRlaForApprovalHistory() {
        Account acc = new Account(Name = 'Cuenta Approval History ' + System.now().getTime());
        insert acc;

        ResidentialLoanApplication rla = new ResidentialLoanApplication(
            Name = 'RLA Approval History',
            AccountId = acc.Id,
            RecordTypeId = getRecordTypeId('FSC_Solicitud_Credito_PYME')
        );
        insert rla;
        return rla;
    }

    private static Approval.ProcessResult submitToAnalistaApproval(Id recordId, Id approverId) {
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(recordId);
        req.setProcessDefinitionNameOrId('FSC_AnalistasDeCredito');
        req.setSkipEntryCriteria(true);
        req.setNextApproverIds(new Id[] { approverId });
        return Approval.process(req);
    }

    @IsTest
    static void testGetApprovalHistory_RecordIdNull() {
        Boolean thrown = false;

        try {
            FSC_ApprovalHistoryController.getApprovalHistory(null);
        } catch (AuraHandledException e) {
            thrown = true;
        }

        System.assertEquals(true, thrown);
    }

    @IsTest
    static void testGetApprovalHistory_SinProceso() {
        Account acc = new Account(Name = 'Cuenta Sin Proceso');
        insert acc;

        ResidentialLoanApplication rla = new ResidentialLoanApplication(Name = 'RLA Sin Proceso', AccountId = acc.Id);
        insert rla;

        List<FSC_ApprovalHistoryController.ApprovalHistoryItem> items =
            FSC_ApprovalHistoryController.getApprovalHistory(rla.Id);

        System.assertEquals(0, items.size());
    }

    @IsTest
    static void testGetApprovalHistory_ConProcesoPendiente() {
        ResidentialLoanApplication rla = createRlaForApprovalHistory();

        Test.startTest();
        Approval.ProcessResult submitResult = submitToAnalistaApproval(rla.Id, UserInfo.getUserId());
        Test.stopTest();

        System.assertEquals(true, submitResult.isSuccess(), 'La solicitud debe entrar en aprobación.');

        List<FSC_ApprovalHistoryController.ApprovalHistoryItem> items =
            FSC_ApprovalHistoryController.getApprovalHistory(rla.Id);

        System.assert(items.size() > 0, 'Debe retornar historial de aprobación.');

        Boolean hasPendingOrSubmitted = false;
        for (FSC_ApprovalHistoryController.ApprovalHistoryItem item : items) {
            if (item.status == 'Pending' || item.status == 'Submitted') {
                hasPendingOrSubmitted = true;
            }
            System.assertNotEquals(null, item.createdDateFormatted);
        }

        System.assertEquals(true, hasPendingOrSubmitted);
    }

    @IsTest
    static void testGetApprovalHistory_AccountCustomHistory() {
        Account acc = new Account(
            Name = 'Comercializadora Caribe SRL',
            ACC_Estado__c = 'VALIDADO',
            ACC_SubEstado__c = 'EN REVISIÓN',
            ACC_Resultado_Validacion__c = 'En Revisión Legal'
        );
        insert acc;

        // Tarea de solicitud de revisión
        Task t1 = new Task(
            WhatId = acc.Id,
            Subject = 'PLA / Legal: Solicitud de Revisión de Cliente (Modificación en Estructura y Composición Accionaria)',
            Description = 'Motivo / Comentarios:\nCambio de socios mayoritarios.',
            Status = 'Completed',
            ActivityDate = Date.today()
        );
        insert t1;

        // Tarea de requerimiento de información
        Task t2 = new Task(
            WhatId = acc.Id,
            Subject = 'Legal: Requerimiento de Información y Recaudos (Comercializadora Caribe SRL)',
            Description = 'Comentarios adicionales:\nFavor adjuntar nómina de accionistas actualizada.',
            Status = 'Open',
            ActivityDate = Date.today().addDays(1)
        );
        insert t2;

        // Tarea de devolución
        Task t3 = new Task(
            WhatId = acc.Id,
            Subject = 'Legal: Cliente Devuelto - Comercializadora Caribe SRL',
            Description = 'El área Legal ha dictaminado DEVOLUCIÓN para el cliente.\n\nMotivo / Comentarios:\nFalta firma en asamblea.',
            Status = 'Open',
            ActivityDate = Date.today().addDays(1)
        );
        insert t3;

        Test.startTest();
        List<FSC_ApprovalHistoryController.ApprovalHistoryItem> items =
            FSC_ApprovalHistoryController.getApprovalHistory(acc.Id);
        Test.stopTest();

        System.assert(items.size() >= 3, 'Debe contener el estado pendiente y las tareas de auditoría de la cuenta.');
        
        Boolean foundDevuelto = false;
        Boolean foundPending = false;
        for (FSC_ApprovalHistoryController.ApprovalHistoryItem item : items) {
            if (item.status == 'Devuelto') {
                foundDevuelto = true;
            }
            if (item.status == 'Pending') {
                foundPending = true;
            }
        }
        System.assertEquals(true, foundDevuelto, 'Debe reconocer el dictamen de devolución.');
        System.assertEquals(true, foundPending, 'Debe reconocer el estado activo en revisión legal.');
    }

    @IsTest
    static void testApprovalHistoryItemSorter_CubreComparaciones() {
        Datetime nowDt = System.now();

        FSC_ApprovalHistoryController.ApprovalHistoryItem a =
            new FSC_ApprovalHistoryController.ApprovalHistoryItem();
        FSC_ApprovalHistoryController.ApprovalHistoryItem b =
            new FSC_ApprovalHistoryController.ApprovalHistoryItem();
        FSC_ApprovalHistoryController.ApprovalHistoryItem c =
            new FSC_ApprovalHistoryController.ApprovalHistoryItem();

        a.createdDate = nowDt;
        b.createdDate = nowDt.addMinutes(-1);
        c.createdDate = null;

        FSC_ApprovalHistoryController.ApprovalHistoryItemSorter sorter =
            new FSC_ApprovalHistoryController.ApprovalHistoryItemSorter();

        System.assertEquals(-1, sorter.compare(a, b));
        System.assertEquals(1, sorter.compare(c, a));
        System.assertEquals(0, sorter.compare(a, a));
    }

    @IsTest
    static void testResolveAssignedTo_prefiereActorUsuario() {
        String assignedTo = FSC_ApprovalHistoryController.resolveAssignedTo(
            'Joel Valenti',
            'User',
            'Cola comité I',
            'Queue'
        );

        System.assertEquals('Joel Valenti', assignedTo);
    }

    @IsTest
    static void testResolveAssignedTo_usaOriginalActorSiEsUsuario() {
        String assignedTo = FSC_ApprovalHistoryController.resolveAssignedTo(
            'Cola supervisores',
            'Queue',
            'Prueba Perfiles',
            'User'
        );

        System.assertEquals('Prueba Perfiles', assignedTo);
    }

    @IsTest
    static void testResolveAssignedTo_dejaColaComoFallback() {
        String assignedTo = FSC_ApprovalHistoryController.resolveAssignedTo(
            'Cola analistas',
            'Queue',
            '',
            ''
        );

        System.assertEquals('Cola analistas', assignedTo);
    }
}