@IsTest
private class LeadAutoQualificationQueueTest {
    @IsTest
    static void enqueuesOnlyEligiblePersonAndPassportCandidates() {
        Map<String, Schema.RecordTypeInfo> recordTypes =
            Lead.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
        String leadPrefix = Lead.SObjectType.getDescribe().getKeyPrefix();

        Lead personCandidate = new Lead(
            Id = Id.valueOf(leadPrefix + '000000000011'),
            RecordTypeId = recordTypes.get('Candidato_Persona_Natural').getRecordTypeId(),
            LEA_TipoIdentificacion__c = 'Cédula',
            LEA_NumIdentificacion__c = '00108804001'
        );
        Lead passportCandidate = new Lead(
            Id = Id.valueOf(leadPrefix + '000000000012'),
            RecordTypeId = recordTypes.get('Candidato_Persona_Natural').getRecordTypeId(),
            LEA_TipoIdentificacion__c = 'Pasaporte',
            LEA_NumIdentificacion__c = 'PA04002'
        );
        Lead ignoredCandidate = new Lead(
            Id = Id.valueOf(leadPrefix + '000000000013'),
            RecordTypeId = recordTypes.get('Candidato_Persona_Natural').getRecordTypeId(),
            LEA_TipoIdentificacion__c = 'Cédula'
        );

        Test.startTest();
        LeadAutoQualificationQueue.enqueueEligibleLeads(null);
        LeadAutoQualificationQueue.enqueueEligibleLeads(new List<Lead>());
        LeadAutoQualificationQueue.enqueueEligibleLeads(
            new List<Lead>{ null, personCandidate, passportCandidate, ignoredCandidate }
        );
        System.assertEquals(2, Limits.getQueueableJobs());
        Test.stopTest();
    }
}
