declare module "@salesforce/apex/FSC_ChecklistDocsController.initAndGetRows" {
  export default function initAndGetRows(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_ChecklistDocsController.saveRows" {
  export default function saveRows(param: {joinIds: any, noAplicaList: any, comentarioList: any, comentarioOficialList: any, estadoRevisionList: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_ChecklistDocsController.markDocumentAsPending" {
  export default function markDocumentAsPending(param: {joinId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_ChecklistDocsController.enforceSingleFileOnJoin" {
  export default function enforceSingleFileOnJoin(param: {joinId: any, keepContentDocumentId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_ChecklistDocsController.linkUploadedFilesToRla" {
  export default function linkUploadedFilesToRla(param: {residentialLoanApplicationId: any, contentDocumentIds: any}): Promise<any>;
}
