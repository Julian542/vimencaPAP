declare module "@salesforce/apex/CaseFinancialTransactionController.getTransactionsByCase" {
  export default function getTransactionsByCase(param: {caseId: any, filters: any}): Promise<any>;
}
declare module "@salesforce/apex/CaseFinancialTransactionController.linkTransactionsToCase" {
  export default function linkTransactionsToCase(param: {caseId: any, transactionIds: any}): Promise<any>;
}
