public without sharing class FSC_LoanApplicantEmploymentWriter {
    public static void save(Id accountId, FinServ__Employment__c employment) {
        Id userId = UserInfo.getUserId();
        List<UserRecordAccess> accountAccess = [
            SELECT RecordId, HasEditAccess
            FROM UserRecordAccess
            WHERE UserId = :userId AND RecordId = :accountId
            LIMIT 1
        ];
        if (accountAccess.isEmpty() || !accountAccess[0].HasEditAccess) {
            throw new AuraHandledException('No tiene permiso para editar la cuenta del Deudor.');
        }

        Schema.DescribeSObjectResult employmentAccess = FinServ__Employment__c.SObjectType.getDescribe();
        if (employment.Id == null) {
            if (!employmentAccess.isCreateable() || employment.Cliente__c != accountId) {
                throw new AuraHandledException('No tiene permiso para crear este empleo.');
            }
        } else {
            if (!employmentAccess.isUpdateable()) {
                throw new AuraHandledException('No tiene permiso para editar este empleo.');
            }
            List<FinServ__Employment__c> existing = [
                SELECT Cliente__c
                FROM FinServ__Employment__c
                WHERE Id = :employment.Id
                LIMIT 1
            ];
            if (existing.isEmpty() || existing[0].Cliente__c != accountId) {
                throw new AuraHandledException('El empleo no pertenece a la cuenta del Deudor.');
            }
        }

        // Permite actualizar el empleo vinculado a una cuenta editable.
        upsert employment;
    }
}