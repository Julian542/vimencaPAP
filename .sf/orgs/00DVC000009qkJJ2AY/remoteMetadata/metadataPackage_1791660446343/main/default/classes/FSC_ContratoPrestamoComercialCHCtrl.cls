public without sharing class FSC_ContratoPrestamoComercialCHCtrl extends FSC_ContratoPrestamoComercialBaseCtrl {
    public FSC_ContratoPrestamoComercialCHCtrl(ApexPages.StandardController standardController) {
        super(standardController, FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_HIPOTECARIA, 82);
    }

    @TestVisible
    private static String formatDateForTest(Date inputDate) {
        return inputDate == null ? '' : inputDate.day() + '/' + inputDate.month() + '/' + inputDate.year();
    }
}