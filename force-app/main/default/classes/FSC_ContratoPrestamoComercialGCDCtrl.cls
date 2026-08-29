public with sharing class FSC_ContratoPrestamoComercialGCDCtrl {
    private static final Integer PLACEHOLDER_COUNT = 83;
    private static final String ANNEX_RESOURCE_NAME = 'FSC_ContratoPrestamoComercial_Anexo';

    public ResidentialLoanApplication loanApplication { get; private set; }
    public Map<String, String> mergeFields { get; private set; }
    public Boolean hasAnnexImage { get; private set; }
    public String annexImageUrl { get; private set; }

    public FSC_ContratoPrestamoComercialGCDCtrl(ApexPages.StandardController stdController) {
        Id residentialLoanApplicationId = getResidentialLoanApplicationId(stdController);
        loadLoanApplication(residentialLoanApplicationId);
        initializeMergeFields();
        applyBusinessMappings();
        initializeAnnexImage();
    }

    private static Id getResidentialLoanApplicationId(ApexPages.StandardController stdController) {
        if (stdController != null && stdController.getId() != null) {
            return stdController.getId();
        }

        String idParam = ApexPages.currentPage() != null
            ? ApexPages.currentPage().getParameters().get('id')
            : null;

        if (String.isBlank(idParam)) {
            return null;
        }

        try {
            return (Id) idParam;
        } catch (Exception e) {
            return null;
        }
    }

    private void loadLoanApplication(Id residentialLoanApplicationId) {
        if (residentialLoanApplicationId == null) {
            return;
        }

        loanApplication = [
            SELECT Id
            FROM ResidentialLoanApplication
            WHERE Id = :residentialLoanApplicationId
            LIMIT 1
        ];
    }

    private void initializeMergeFields() {
        mergeFields = new Map<String, String>();

        for (Integer i = 1; i <= PLACEHOLDER_COUNT; i++) {
            String placeholderKey = 'p' + String.valueOf(i).leftPad(3, '0');
            mergeFields.put(placeholderKey, '[' + placeholderKey + ']');
        }
    }

    private void applyBusinessMappings() {
        // TODO:
        // Reemplazar estos valores genéricos por los campos reales del ResidentialLoanApplication
        // y de los objetos relacionados cuando el negocio confirme el mapping.
        //
        // Ejemplos:
        // mergeFields.put('p001', formatDate(Date.today()));
        // mergeFields.put('p002', applicantFullName);
        // mergeFields.put('p003', principalAmountFormatted);
        // mergeFields.put('p083', notaryFullName);
    }

    private void initializeAnnexImage() {
        annexImageUrl = '/resource/' + ANNEX_RESOURCE_NAME;
        hasAnnexImage = true;
    }

    public String getPlaceholderValue(String key) {
        return mergeFields != null && mergeFields.containsKey(key)
            ? mergeFields.get(key)
            : '';
    }

    private static String formatDate(Date inputDate) {
        if (inputDate == null) {
            return '';
        }

        return String.valueOf(inputDate.day()) + '/' +
            String.valueOf(inputDate.month()) + '/' +
            String.valueOf(inputDate.year());
    }

    @TestVisible
    private static String formatDateForTest(Date inputDate) {
        return formatDate(inputDate);
    }
}