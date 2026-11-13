public without sharing class FSC_ContratoPrestamoComercialGSCtrl extends FSC_ContratoPrestamoComercialBaseCtrl {
    public FSC_ContratoPrestamoComercialGSCtrl(ApexPages.StandardController standardController) {
        super(standardController, FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_SOLIDARIA, 76);
    }

    @TestVisible
    private static String formatDateForTest(Date inputDate) {
        return inputDate == null ? '' : inputDate.day() + '/' + inputDate.month() + '/' + inputDate.year();
    }
}