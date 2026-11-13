public without sharing class FSC_GenerarContratoPDF {
    
    /*public static void generarContrato(ResidentialLoanApplication rla) {
        ResidentialLoanApplication rlaUpdate = [SELECT Id, FSC_Subestado__c, FSC_Contrato_Generado__c 
        FROM ResidentialLoanApplication WHERE Id =: rla.Id LIMIT 1];
        // TO DO: Generar contrato en clase queueable y si el contrato se genera bien actualizar la sig variables:
        // rlaUpdate.FSC_Contrato_Generado__c = true;
        // update rlaUpdate;
        rlaUpdate.FSC_Subestado__c = 'Gestionar firmas';
        rlaUpdate.FSC_Contrato_Generado__c = true;
        update rlaUpdate;
    }*/
    public static void enqueueGeneration(Set<Id> residentialLoanApplicationIds) {
        if (residentialLoanApplicationIds == null || residentialLoanApplicationIds.isEmpty()) {
            return;
        }

        System.enqueueJob(
            new FSC_GenerarContratoPDFQueueable(
                new List<Id>(residentialLoanApplicationIds)
            )
        );
    }
}