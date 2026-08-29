public with sharing class FSC_RlaGarantiasTablaController {

    public class GarantiaRow {
        @AuraEnabled public Id id;
        @AuraEnabled public String numeroFacilidad;
        @AuraEnabled public String descripcionGarantia;
        @AuraEnabled public Decimal valor;
        @AuraEnabled public Decimal porcentajeAdmisibilidad;
    }

    @AuraEnabled(cacheable=true)
    public static List<GarantiaRow> getGarantias(Id residentialLoanApplicationId) {
        List<GarantiaRow> rows = new List<GarantiaRow>();

        if (residentialLoanApplicationId == null) {
            return rows;
        }

        for (LoanApplicationAsset asset : [
            SELECT Id,
                   FSC_Numero_Facilidades__c,
                   FSC_Descripcion_de_la_Garantia__c,
                   CashOrMarketValue,
                   FSC_Porcentaje_Admisibilidad__c
            FROM LoanApplicationAsset
            WHERE LoanApplicationId = :residentialLoanApplicationId
            ORDER BY FSC_Numero_Facilidades__c ASC NULLS LAST, CreatedDate ASC
        ]) {
            GarantiaRow row = new GarantiaRow();
            row.id = asset.Id;
            row.numeroFacilidad = asset.FSC_Numero_Facilidades__c == null
                ? ''
                : String.valueOf(asset.FSC_Numero_Facilidades__c);
            row.descripcionGarantia = asset.FSC_Descripcion_de_la_Garantia__c;
            row.valor = asset.CashOrMarketValue;
            row.porcentajeAdmisibilidad = asset.FSC_Porcentaje_Admisibilidad__c;
            rows.add(row);
        }

        return rows;
    }
}