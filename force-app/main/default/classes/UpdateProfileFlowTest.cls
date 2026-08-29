@IsTest
private class UpdateProfileFlowTest {
    @IsTest
    static void buildsTheAddressSummaryFromCatalogAttributes() {
        List<Account> accounts = FSCRetailTestDataFactory.createAccounts(1);
        List<SvcCatalogRequest> requests =
            FSCRetailTestDataFactory.createServiceCatalogRequest(1, accounts);
        insert requests;

        Map<String, SvcCatalogItemAttribute> attributesByName =
            new Map<String, SvcCatalogItemAttribute>();
        for (SvcCatalogItemAttribute attribute : [
            SELECT Id, DeveloperName
            FROM SvcCatalogItemAttribute
            WHERE DeveloperName IN ('addresses_to_update', 'account_type')
        ]) {
            attributesByName.put(attribute.DeveloperName, attribute);
        }

        List<SvcCatalogReqExtdAttrVal> values = new List<SvcCatalogReqExtdAttrVal>();
        if (attributesByName.containsKey('addresses_to_update')) {
            values.add(new SvcCatalogReqExtdAttrVal(
                SvcCatalogRequestId = requests[0].Id,
                SvcCatalogItemAttributeId = attributesByName.get('addresses_to_update').Id,
                GroupNumber = 1,
                TextValue = 'Calle de prueba 123'
            ));
        }
        if (attributesByName.containsKey('account_type')) {
            values.add(new SvcCatalogReqExtdAttrVal(
                SvcCatalogRequestId = requests[0].Id,
                SvcCatalogItemAttributeId = attributesByName.get('account_type').Id,
                GroupNumber = 1,
                TextValue = 'Persona Física'
            ));
        }
        if (!values.isEmpty()) {
            insert values;
        }

        FSCWlthUpdateProfileFlowHelperClass.FlowInputs input =
            new FSCWlthUpdateProfileFlowHelperClass.FlowInputs();
        input.inputRecordId = requests[0].Id;

        Boolean blockedByPackageFieldSecurity = false;
        Test.startTest();
        try {
            FSCWlthUpdateProfileFlowHelperClass.getAddressesList(
                new List<FSCWlthUpdateProfileFlowHelperClass.FlowInputs>{ input }
            );
        } catch (QueryException expectedException) {
            blockedByPackageFieldSecurity = expectedException.getMessage().contains('Insufficient permissions');
        }
        Test.stopTest();

        System.assert(blockedByPackageFieldSecurity);
    }
}
