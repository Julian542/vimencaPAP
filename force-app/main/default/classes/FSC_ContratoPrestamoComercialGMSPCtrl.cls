public without sharing class FSC_ContratoPrestamoComercialGMSPCtrl extends FSC_ContratoPrestamoComercialBaseCtrl {
    public FSC_ContratoPrestamoComercialGMSPCtrl(ApexPages.StandardController standardController) {
        super(standardController, FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_MOBILIARIA_SIN_POSESION, 103);
    }

    @TestVisible
    private static String formatDateForTest(Date inputDate) {
        return inputDate == null ? '' : inputDate.day() + '/' + inputDate.month() + '/' + inputDate.year();
    }
}