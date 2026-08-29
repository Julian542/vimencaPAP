declare module "@salesforce/apex/FSC_CaseWrapUpController.getWrapUpData" {
  export default function getWrapUpData(param: {caseId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_CaseWrapUpController.closeCase" {
  export default function closeCase(param: {caseId: any, outcome: any, closeReason: any, resolutionSummary: any, sendEmail: any, emailTo: any, emailSubject: any, emailBody: any, minFilesRequired: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_CaseWrapUpController.sendAditionalInformationEmail" {
  export default function sendAditionalInformationEmail(param: {aditionalInformation: any, recordId: any}): Promise<any>;
}
