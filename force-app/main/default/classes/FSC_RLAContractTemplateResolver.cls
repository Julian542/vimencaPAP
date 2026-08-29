public with sharing class FSC_RLAContractTemplateResolver {

    public static final String TEMPLATE_GARANTIA_MOBILIARIA_CON_POSESION = 'GARANTIA_MOBILIARIA_CON_POSESION';
    public static final String TEMPLATE_GARANTIA_HIPOTECARIA = 'GARANTIA_HIPOTECARIA';
    public static final String TEMPLATE_GARANTIA_MOBILIARIA_SIN_POSESION = 'GARANTIA_MOBILIARIA_SIN_POSESION';
    public static final String TEMPLATE_GARANTIA_SOLIDARIA = 'GARANTIA_SOLIDARIA';

    public static PageReference resolvePageReference(Id residentialLoanApplicationId) {
        if (residentialLoanApplicationId == null) {
            throw new FSC_RLAContractTemplateResolverException(
                'Se requiere el Id de ResidentialLoanApplication para resolver el template.'
            );
        }

        String templateCode = resolveTemplateCode(residentialLoanApplicationId);
        return buildPageReference(templateCode, residentialLoanApplicationId);
    }

    public static PageReference resolvePageReference(Id residentialLoanApplicationId, String templateCode) {
        if (residentialLoanApplicationId == null) {
            throw new FSC_RLAContractTemplateResolverException(
                'Se requiere el Id de ResidentialLoanApplication para resolver el template.'
            );
        }

        if (String.isBlank(templateCode)) {
            throw new FSC_RLAContractTemplateResolverException(
                'Se requiere el código de template para resolver la Visualforce Page.'
            );
        }

        return buildPageReference(templateCode, residentialLoanApplicationId);
    }

    private static String resolveTemplateCode(Id residentialLoanApplicationId) {
        // TODO:
        // Cuando existan múltiples contratos, aquí se evaluarán los criterios de negocio
        // para elegir qué Visualforce Page corresponde generar.
        //
        // Ejemplos de criterios futuros:
        // - Tipo de garantía
        // - Producto financiero
        // - País / región
        // - Condición específica del préstamo
        //
        // Por el momento se deja un default para no romper el flujo actual.

        return TEMPLATE_GARANTIA_MOBILIARIA_CON_POSESION;
    }

    private static PageReference buildPageReference(String templateCode, Id residentialLoanApplicationId) {
        PageReference contractPage;

        //Opcion 1: CONTRATO DE PRESTAMO COMERCIAL A CUOTAS CON GARANTIA MOBILIARIA CON POSESION
        if (templateCode == TEMPLATE_GARANTIA_MOBILIARIA_CON_POSESION) {
            contractPage = Page.FSC_ContratoPrestamoComercialGarantiaCD;

        //Opcion 2: CONTRATO DE PRESTAMO COMERCIAL A CUOTAS CON GARANTIA HIPOTECARIA
        } else if (templateCode == TEMPLATE_GARANTIA_HIPOTECARIA) {
            contractPage = Page.FSC_ContratoPrestamoComercialCH;

        //Opcion 3: CONTRATO DE PRÉSTAMO COMERCIAL A CUOTAS CON GARANTIA MOBILIARIA SIN POSESION
        } else if (templateCode == TEMPLATE_GARANTIA_MOBILIARIA_SIN_POSESION) {
            contractPage = Page.FSC_ContratoPrestamoComercialGMSP;

        //Opcion 4: CONTRATO DE PRÉSTAMO COMERCIAL A CUOTAS CON GARANTÍA SOLIDARIA
        } else if (templateCode == TEMPLATE_GARANTIA_SOLIDARIA) {
            contractPage = Page.FSC_ContratoPrestamoComercialGS;

        } else {
            throw new FSC_RLAContractTemplateResolverException(
                'No existe una Visualforce Page configurada para el template: ' + templateCode
            );
        }

        contractPage.getParameters().put('id', String.valueOf(residentialLoanApplicationId));
        return contractPage;
    }

    public class FSC_RLAContractTemplateResolverException extends Exception {}
}