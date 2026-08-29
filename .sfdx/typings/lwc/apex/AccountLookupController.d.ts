declare module "@salesforce/apex/AccountLookupController.searchParticipantsSource" {
  export default function searchParticipantsSource(param: {searchKey: any}): Promise<any>;
}
declare module "@salesforce/apex/AccountLookupController.searchCandidates" {
  export default function searchCandidates(param: {searchKey: any}): Promise<any>;
}
declare module "@salesforce/apex/AccountLookupController.searchAccounts" {
  export default function searchAccounts(param: {searchKey: any}): Promise<any>;
}
declare module "@salesforce/apex/AccountLookupController.createParticipantCandidate" {
  export default function createParticipantCandidate(param: {participantType: any, identificationType: any, firstName: any, lastName: any, companyName: any, identificationNumber: any}): Promise<any>;
}
declare module "@salesforce/apex/AccountLookupController.getParticipantModalFields" {
  export default function getParticipantModalFields(): Promise<any>;
}
declare module "@salesforce/apex/AccountLookupController.addParticipant" {
  export default function addParticipant(param: {leadId: any, participantRecordId: any, participantRecordType: any, fieldsJson: any}): Promise<any>;
}
declare module "@salesforce/apex/AccountLookupController.getParticipantForEdit" {
  export default function getParticipantForEdit(param: {participantId: any}): Promise<any>;
}
declare module "@salesforce/apex/AccountLookupController.updateParticipant" {
  export default function updateParticipant(param: {participantId: any, fieldsJson: any}): Promise<any>;
}
declare module "@salesforce/apex/AccountLookupController.deleteParticipant" {
  export default function deleteParticipant(param: {participantId: any}): Promise<any>;
}
declare module "@salesforce/apex/AccountLookupController.getParticipants" {
  export default function getParticipants(param: {leadId: any}): Promise<any>;
}
