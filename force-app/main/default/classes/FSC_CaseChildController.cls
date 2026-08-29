public with sharing class FSC_CaseChildController {

    public class ParentInfo {
        @AuraEnabled public Id id;
        @AuraEnabled public String caseNumber;
        @AuraEnabled public String subject;
        @AuraEnabled public Boolean isClosed;

        @AuraEnabled public Id accountId;
        @AuraEnabled public Id contactId;
        @AuraEnabled public Id recordTypeId;

        @AuraEnabled public String origin;
    }

    public class CreateChildRequest {
        @AuraEnabled public Id parentCaseId;

        @AuraEnabled public String subject;
        @AuraEnabled public String description;
    }

    public class CreateChildResponse {
        @AuraEnabled public Id childCaseId;
    }

    @AuraEnabled(cacheable=true)
    public static ParentInfo getParentCase(Id parentCaseId) {
        if (parentCaseId == null) {
            throw new AuraHandledException('parentCaseId es requerido.');
        }

        Case c = [
            SELECT Id, CaseNumber, Subject, IsClosed,
                   AccountId, ContactId, RecordTypeId,
                   Origin, Type, Priority
            FROM Case
            WHERE Id = :parentCaseId
            LIMIT 1
        ];

        ParentInfo info = new ParentInfo();
        info.id = c.Id;
        info.caseNumber = c.CaseNumber;
        info.subject = c.Subject;
        info.isClosed = c.IsClosed;

        info.accountId = c.AccountId;
        info.contactId = c.ContactId;
        info.recordTypeId = c.RecordTypeId;

        info.origin = c.Origin;

        return info;
    }

    @AuraEnabled
    public static CreateChildResponse createChildCase(String parentCaseId, String subject, String description) {
        if (parentCaseId == null) {
            throw new AuraHandledException('Debe indicar el Caso padre.');
        }
        if (String.isBlank(subject)) {
            throw new AuraHandledException('El Subject es obligatorio.');
        }

        Case parentC = [
            SELECT Id, IsClosed, AccountId, ContactId, RecordTypeId, Origin, Type, Priority, CAS_Correo_Electronico_Cliente__c
            FROM Case
            WHERE Id = :parentCaseId
            LIMIT 1
        ];

        if (!parentC.IsClosed) {
            throw new AuraHandledException('Solo puedes crear un Caso Hijo desde un Caso cerrado.');
        }

        Case childC = new Case();
        childC.ParentId = parentC.Id;
        childC.AccountId = parentC.AccountId;
        childC.ContactId = parentC.ContactId;
        childC.RecordTypeId = parentC.RecordTypeId;
        childC.Origin = parentC.Origin;
        childC.Subject = subject;
        childC.Description = description;

        childC.Type = parentC.Type;
        childC.CAS_Correo_Electronico_Cliente__c = parentC.CAS_Correo_Electronico_Cliente__c;

        insert childC;

        CreateChildResponse res = new CreateChildResponse();
        res.childCaseId = childC.Id;
        return res;
    }
}