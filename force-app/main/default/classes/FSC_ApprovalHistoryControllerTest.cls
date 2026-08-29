@IsTest
private class FSC_ApprovalHistoryControllerTest {

    private static Id getRecordTypeId(String developerName) {
        Map<String, Schema.RecordTypeInfo> rtMap =
            ResidentialLoanApplication.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
        return rtMap != null && rtMap.containsKey(developerName)
            ? rtMap.get(developerName).getRecordTypeId()
            : null;
    }

    private static Account createNeutralAccount(String name) {
        Account acc = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId(),
            Name = name,
            ACC_RNC__c = String.valueOf(Math.abs(Crypto.getRandomInteger())).leftPad(9, '0').substring(0, 9),
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO',
            ACC_TipoIdentificacion__c = 'RNC'
        );
        insert acc;
        return acc;
    }

    private static ResidentialLoanApplication createRlaForApprovalHistory() {
        Account acc = createNeutralAccount('Cuenta Approval History ' + System.now().getTime());

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
        Account acc = createNeutralAccount('Cuenta Sin Proceso');

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
