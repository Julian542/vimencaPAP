declare module "@salesforce/apex/LeadDocumentsController.searchDocTypes" {
  export default function searchDocTypes(param: {leadId: any, searchKey: any}): Promise<any>;
}
declare module "@salesforce/apex/LeadDocumentsController.getDocuments" {
  export default function getDocuments(param: {leadId: any}): Promise<any>;
}
declare module "@salesforce/apex/LeadDocumentsController.getDocumentModalFields" {
  export default function getDocumentModalFields(): Promise<any>;
}
declare module "@salesforce/apex/LeadDocumentsController.createDocumentFromCatalogAfterUpload" {
  export default function createDocumentFromCatalogAfterUpload(param: {leadId: any, docTypeId: any, contentDocumentId: any, fieldsJson: any}): Promise<any>;
}
declare module "@salesforce/apex/LeadDocumentsController.updateDocumentAfterUpload" {
  export default function updateDocumentAfterUpload(param: {documentacionLegalId: any, contentDocumentId: any, fieldsJson: any}): Promise<any>;
}
declare module "@salesforce/apex/LeadDocumentsController.updateDocumentFieldsOnly" {
  export default function updateDocumentFieldsOnly(param: {documentacionLegalId: any, fieldsJson: any}): Promise<any>;
}
declare module "@salesforce/apex/LeadDocumentsController.approveDocuments" {
  export default function approveDocuments(param: {documentacionLegalIds: any}): Promise<any>;
}
declare module "@salesforce/apex/LeadDocumentsController.deleteDocumentWithFiles" {
  export default function deleteDocumentWithFiles(param: {documentacionLegalId: any}): Promise<any>;
}
