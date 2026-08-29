/**
 * @description       : Queueable para ejecutar la creación de productos financieros en CORE.
 *                      Procesa un registro por transacción para evitar problemas de callout + DML.
 * @author            : Jhonny Peroza / Keystone Advisors
 * @last modified on  : 18-05-2026
**/
@SuppressWarnings('PMD')
public with sharing class FinancialAccountCoreCreationQueueable implements Queueable, Database.AllowsCallouts {

    private List<Id> financialAccountIds;

    public FinancialAccountCoreCreationQueueable(List<Id> financialAccountIds) {
        System.debug('FinancialAccountCoreCreationQueueable.constructor | financialAccountIds=' + financialAccountIds);
        this.financialAccountIds = financialAccountIds == null ? new List<Id>() : financialAccountIds;
    }

    public void execute(QueueableContext context) {
        System.debug('FinancialAccountCoreCreationQueueable.execute | financialAccountIds=' + financialAccountIds);

        try {
            if (financialAccountIds == null || financialAccountIds.isEmpty()) {
                System.debug('FinancialAccountCoreCreationQueueable.execute | No hay registros para procesar');
                return;
            }

            Id currentFinancialAccountId = financialAccountIds.remove(0);

            System.debug('FinancialAccountCoreCreationQueueable.execute | currentFinancialAccountId=' + currentFinancialAccountId);

            FinancialAccountCoreCreationService.process(currentFinancialAccountId);

            if (!financialAccountIds.isEmpty()) {
                System.debug('FinancialAccountCoreCreationQueueable.execute | Se encadena siguiente Queueable con ids restantes=' + financialAccountIds);
                System.enqueueJob(new FinancialAccountCoreCreationQueueable(financialAccountIds));
            }

        } catch (Exception e) {
            System.debug('FinancialAccountCoreCreationQueueable.execute | Error=' + e.getMessage());
            System.debug('FinancialAccountCoreCreationQueueable.execute | StackTrace=' + e.getStackTraceString());
        }
    }
}