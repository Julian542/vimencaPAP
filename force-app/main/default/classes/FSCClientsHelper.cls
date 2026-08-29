public with sharing class FSCClientsHelper {
  public void createCIF(Account account) {
    if (account.RecordTypeID == Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId()) {
      INT007_FSC.creteClient(account.Id);
    } else if (account.RecordTypeID == Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesBusiness').getRecordTypeId()) {
      INT008_FSC.creteClientJ(account.Id);
    }
  }

  public void updateCIF(Account account) {
    if (account.RecordTypeID == Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId()) {
      if (System.IsBatch() == false && System.isFuture() == false && !Test.isRunningTest()) {
        INT007_FSC.modifiClient(account.Id, 'M');
      }
    }
  }
}