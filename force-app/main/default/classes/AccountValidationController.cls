public with sharing class AccountValidationController {
    
    @AuraEnabled(cacheable=true)
    public static ValidationResult getAccountValidation(Id accountId) {
        if (accountId == null) {
            return new ValidationResult();
        }
        
        ValidationResult result = new ValidationResult();
        
        try {
            // Validar ContactPointPhone (al menos 1)
            Integer phoneCount = [
                SELECT COUNT() 
                FROM ContactPointPhone 
                WHERE ParentId = :accountId
            ];
            result.hasContactPoints = phoneCount >= 1;
            
            // Validar ContactPointAddress (al menos 1)
            Integer addressCount = [
                SELECT COUNT() 
                FROM ContactPointAddress 
                WHERE ParentId = :accountId
            ];
            result.hasAddresses = addressCount >= 1;
            
            // Validar Información Financiera (al menos 1)
            Integer financialCount = [
                SELECT COUNT() 
                FROM Informacion_Financiera__c 
                WHERE INF_Cuenta__c = :accountId 
            ];
            result.hasFinancialInfo = financialCount >= 1;
            
            // Validar Referencias (al menos 1 ContactContactRelation)
            Integer referenceCount = 0;
            
            // Primero obtenemos los Contacts relacionados a esta Account
            List<Contact> contacts = [
                SELECT Id 
                FROM Contact 
                WHERE AccountId = :accountId 
                LIMIT 1
            ];
            
            if (!contacts.isEmpty()) {
                referenceCount = [
                    SELECT COUNT() 
                    FROM FinServ__ContactContactRelation__c 
                    WHERE FinServ__Contact__c = :contacts[0].Id
                ];
            }
            result.hasReferences = referenceCount >= 1;
            
            // Obtener campos de validación existentes
            Account acc = [
                SELECT ACC_Resultado_Validacion__c, 
                       ACC_Validacion_FATCA__c, 
                       ACC_Persona_PEP__c,
                       ACC_Datos_financieros__c,
                       FinServ__Status__c,
                       ACC_Estado__c
                       FROM Account 
                WHERE Id = :accountId 
                LIMIT 1
            ];
            
            result.resultadoValidacion = acc.ACC_Resultado_Validacion__c;
            result.validacionFATCA = acc.ACC_Validacion_FATCA__c;
            result.validacionPEP = acc.ACC_Persona_PEP__c;
            result.datosFinancieros = acc.ACC_Datos_financieros__c;
            //result.clientStatus = acc.ACC_Estado__c;
            result.clientStatus = acc.FinServ__Status__c;
            
        } catch (Exception e) {
            System.debug('Error in getAccountValidation: ' + e.getMessage());
        }
        
        return result;
    }
    
    public class ValidationResult {
        @AuraEnabled public Boolean hasContactPoints { get; set; }
        @AuraEnabled public Boolean hasAddresses { get; set; }
        @AuraEnabled public Boolean hasFinancialInfo { get; set; }
        @AuraEnabled public Boolean hasReferences { get; set; }
        @AuraEnabled public String resultadoValidacion { get; set; }
        @AuraEnabled public Boolean validacionFATCA { get; set; }
        @AuraEnabled public String validacionPEP { get; set; }
        @AuraEnabled public Decimal datosFinancieros { get; set; }
        @AuraEnabled public String clientStatus { get; set; }

        public ValidationResult() {
            this.hasContactPoints = false;
            this.hasAddresses = false;
            this.hasFinancialInfo = false;
            this.hasReferences = false;
        }
    }
}