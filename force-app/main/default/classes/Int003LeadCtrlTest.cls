@IsTest
private class Int003LeadCtrlTest {
    private static Lead createQualifiedLead() {
        Datos_Maestros__c activity = new Datos_Maestros__c(
            Name = 'INT003 coverage activity',
            DM_Direccion__c = 'INT003-' + String.valueOf(System.now().getTime()).right(8)
        );
        insert activity;

        Lead candidate = new Lead(
            FirstName = 'INT003',
            LastName = 'Coverage',
            Company = 'INT003 Coverage',
            Status = 'Calificado',
            LEA_NumIdentificacion__c = '00108803903',
            LEA_TipoIdentificacion__c = 'Cédula',
            LEA_Nacionalidad__c = 'REPUBLICA DOMINICANA',
            LEA_PersonBirthdate__c = Date.today().addYears(-30),
            LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
            LEA_Actividad_Economica__c = activity.Id,
            LEA_Tipo_Sector__c = 'PRIVADO'
        );
        insert candidate;
        return candidate;
    }

    @IsTest
    static void returnsFunctionalAndHttpFailuresFromTheService() {
        Lead candidate = createQualifiedLead();

        Test.setMock(HttpCalloutMock.class, new INT003_LEAD_FSC_TestMock('ERROR'));
        INT003_ValidarContraLista_Controller_FSC.Response functionalError =
            INT003_LEAD_ValidarContraList_Controller.validatePF(candidate.Id);

        Test.setMock(HttpCalloutMock.class, new INT003_LEAD_FSC_TestMock('HTTP_ERROR'));
        List<INT003_ValidarContraLista_Controller_FSC.Response> httpErrors =
            INT003_LEAD_ValidarContraList_Controller.validatePFFlow(
                new List<Id>{ candidate.Id }
        );

        System.assertEquals(false, functionalError.updateSuccess);
        System.assertNotEquals(null, functionalError.errorText);
        System.assertEquals(false, httpErrors[0].updateSuccess);
        System.assertNotEquals(null, httpErrors[0].errorText);
    }
}
