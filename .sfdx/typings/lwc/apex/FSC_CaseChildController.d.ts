declare module "@salesforce/apex/FSC_CaseChildController.getParentCase" {
  export default function getParentCase(param: {parentCaseId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_CaseChildController.createChildCase" {
  export default function createChildCase(param: {parentCaseId: any, subject: any, description: any}): Promise<any>;
}
