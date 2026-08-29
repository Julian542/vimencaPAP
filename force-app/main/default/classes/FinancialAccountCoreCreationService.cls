/**
 * @description       : Servicio orquestador para creación automática de productos financieros en CORE.
 *                      Valida previamente la cuenta financiera y, si todo está correcto, invoca wsCreacionProd_FSC.
 * @author            : Jhonny Peroza / Keystone Advisors
 * @last modified on  : 18-05-2026
**/
@SuppressWarnings('PMD')
public with sharing class FinancialAccountCoreCreationService {

    public static void process(Id financialAccountId) {
        System.debug('FinancialAccountCoreCreationService.process | financialAccountId=' + financialAccountId);

        try {
            if (financialAccountId == null) {
                System.debug('FinancialAccountCoreCreationService.process | financialAccountId vacío');
                return;
            }

            FinancialAccountCoreValidationService.ValidationResult validationResult =
                FinancialAccountCoreValidationService.validate(financialAccountId);

            if (validationResult == null) {
                updateFinancialAccountResult(
                    financialAccountId,
                    'Ha ocurrido un error validando la información requerida para crear el producto financiero en el CORE.'
                );
                return;
            }

            if (!validationResult.isValid) {
                updateFinancialAccountResult(financialAccountId, validationResult.message);
                return;
            }

            System.debug('FinancialAccountCoreCreationService.process | Validación correcta. Se invoca wsCreacionProd_FSC.creacionProdCA_CC_CF');

            String integrationResult = wsCreacionProd_FSC.creacionProdCA_CC_CF(financialAccountId);

            System.debug('FinancialAccountCoreCreationService.process | integrationResult=' + integrationResult);

        } catch (Exception e) {
            System.debug('FinancialAccountCoreCreationService.process | Error=' + e.getMessage());
            System.debug('FinancialAccountCoreCreationService.process | StackTrace=' + e.getStackTraceString());

            updateFinancialAccountResult(
                financialAccountId,
                'Ha ocurrido un error no controlado intentando crear el producto financiero en el CORE: ' + e.getMessage()
            );
        }
    }

    private static void updateFinancialAccountResult(Id financialAccountId, String message) {
        System.debug('FinancialAccountCoreCreationService.updateFinancialAccountResult | financialAccountId=' + financialAccountId + ' | message=' + message);

        try {
            if (financialAccountId == null) {
                return;
            }

            update new FinServ__FinancialAccount__c(
                Id = financialAccountId,
                FIN_Res_Creacion__c = message
            );

        } catch (Exception e) {
            System.debug('FinancialAccountCoreCreationService.updateFinancialAccountResult | Error=' + e.getMessage());
            System.debug('FinancialAccountCoreCreationService.updateFinancialAccountResult | StackTrace=' + e.getStackTraceString());
        }
    }
}