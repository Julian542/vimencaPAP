public without sharing class FSC_DesembolsoDeCredito {
    public static void desembolso(ResidentialLoanApplication rla) {
        ResidentialLoanApplication rlaUpdate = [SELECT Id, FSC_Subestado__c, FSC_Contrato_Generado__c 
        FROM ResidentialLoanApplication WHERE Id =: rla.Id LIMIT 1];
        rlaUpdate.FSC_Subestado__c = 'Archivo y custodia';
        update rlaUpdate;
    }
}