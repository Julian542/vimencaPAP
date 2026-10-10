public without sharing class FSC_ContratoPrestamoComercialGCDCtrl extends FSC_ContratoPrestamoComercialBaseCtrl {
    public FSC_ContratoPrestamoComercialGCDCtrl(ApexPages.StandardController standardController) {
        super(standardController, FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_MOBILIARIA_CON_POSESION, 83);
    }

    @TestVisible
    private static String formatDateForTest(Date inputDate) {
        return inputDate == null ? '' : inputDate.day() + '/' + inputDate.month() + '/' + inputDate.year();
    }
}