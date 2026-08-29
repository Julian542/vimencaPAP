public without sharing class ContactPointAccountSyncService {
  public static void syncPhones(Set<Id> parentIds) {
    System.debug('ContactPointAccountSyncService.syncPhones() parentIds=' + parentIds);

    Set<Id> accountIds = filterAccountIds(parentIds);

    if (accountIds.isEmpty()) {
      System.debug('ContactPointAccountSyncService.syncPhones() no accountIds.');
      return;
    }

    Map<Id, ContactPointPhone> primaryPhoneByAccountId = new Map<Id, ContactPointPhone>();

    for (ContactPointPhone cpp : [
      SELECT Id, ParentId, TelephoneNumber, IsPrimary, LastModifiedDate
      FROM ContactPointPhone
      WHERE ParentId IN :accountIds
      AND IsPrimary = true
      ORDER BY LastModifiedDate DESC
    ]) {
      if (cpp.ParentId != null && !primaryPhoneByAccountId.containsKey(cpp.ParentId)) {
        primaryPhoneByAccountId.put(cpp.ParentId, cpp);
      }
    }

    List<Account> accountsToUpdate = new List<Account>();

    for (Id accountId : accountIds) {
      Account acc = new Account(Id = accountId);

      if (primaryPhoneByAccountId.containsKey(accountId)) {
        acc.Phone = primaryPhoneByAccountId.get(accountId).TelephoneNumber;
      } else {
        acc.Phone = null;
      }

      accountsToUpdate.add(acc);
    }

    if (!accountsToUpdate.isEmpty()) {
      update accountsToUpdate;
    }
  }

  public static void syncEmails(Set<Id> parentIds) {
    System.debug('ContactPointAccountSyncService.syncEmails() parentIds=' + parentIds);

    Set<Id> accountIds = filterAccountIds(parentIds);

    if (accountIds.isEmpty()) {
        System.debug('ContactPointAccountSyncService.syncEmails() no accountIds.');
        return;
    }

    Map<Id, ContactPointEmail> primaryEmailByAccountId = new Map<Id, ContactPointEmail>();

    for (ContactPointEmail cpe : [
        SELECT Id, ParentId, EmailAddress, IsPrimary, LastModifiedDate
        FROM ContactPointEmail
        WHERE ParentId IN :accountIds
        AND IsPrimary = true
        ORDER BY LastModifiedDate DESC
    ]) {
        if (cpe.ParentId != null && !primaryEmailByAccountId.containsKey(cpe.ParentId)) {
        primaryEmailByAccountId.put(cpe.ParentId, cpe);
        }
    }

    Map<Id, Account> existingAccountsById = new Map<Id, Account>([
        SELECT Id, IsPersonAccount
        FROM Account
        WHERE Id IN :accountIds
    ]);

    Schema.DescribeSObjectResult dACC = Account.SObjectType.getDescribe();
    List<Account> accountsToUpdate = new List<Account>();

    for (Id accountId : accountIds) {
        Account existingAccount = existingAccountsById.get(accountId);

        if (existingAccount == null) {
        continue;
        }

        Account acc = new Account(Id = accountId);
        String emailValue = null;

        if (primaryEmailByAccountId.containsKey(accountId)) {
        emailValue = primaryEmailByAccountId.get(accountId).EmailAddress;
        }

        setIfAccountFieldExistsAndUpdateable(acc, dACC, 'Correo_Electronico_Cliente__c', emailValue);
        setIfAccountFieldExistsAndUpdateable(acc, dACC, 'ACC_Correo_Electronico_Cliente__c', emailValue);

        if (existingAccount.IsPersonAccount == true) {
        setIfAccountFieldExistsAndUpdateable(acc, dACC, 'PersonEmail', emailValue);
        }

        accountsToUpdate.add(acc);
    }

    if (!accountsToUpdate.isEmpty()) {
        update accountsToUpdate;
    }
  }

  public static void syncAddresses(Set<Id> parentIds) {
    System.debug('ContactPointAccountSyncService.syncAddresses() parentIds=' + parentIds);

    Set<Id> accountIds = filterAccountIds(parentIds);

    if (accountIds.isEmpty()) {
      System.debug('ContactPointAccountSyncService.syncAddresses() no accountIds.');
      return;
    }

    Map<Id, ContactPointAddress> primaryAddressByAccountId = new Map<Id, ContactPointAddress>();

    for (ContactPointAddress cpa : [
      SELECT Id, ParentId, Street, City, State, PostalCode, Country, IsPrimary, LastModifiedDate
      FROM ContactPointAddress
      WHERE ParentId IN :accountIds
      AND IsPrimary = true
      ORDER BY LastModifiedDate DESC
    ]) {
      if (cpa.ParentId != null && !primaryAddressByAccountId.containsKey(cpa.ParentId)) {
        primaryAddressByAccountId.put(cpa.ParentId, cpa);
      }
    }

    List<Account> accountsToUpdate = new List<Account>();

    for (Id accountId : accountIds) {
      Account acc = new Account(Id = accountId);

      if (primaryAddressByAccountId.containsKey(accountId)) {
        ContactPointAddress cpa = primaryAddressByAccountId.get(accountId);

        acc.BillingStreet = cpa.Street;
        acc.BillingCity = cpa.City;
        acc.BillingState = cpa.State;
        acc.BillingPostalCode = cpa.PostalCode;
        acc.BillingCountry = cpa.Country;
      } else {
        acc.BillingStreet = null;
        acc.BillingCity = null;
        acc.BillingState = null;
        acc.BillingPostalCode = null;
        acc.BillingCountry = null;
      }

      accountsToUpdate.add(acc);
    }

    if (!accountsToUpdate.isEmpty()) {
      update accountsToUpdate;
    }
  }

  private static Set<Id> filterAccountIds(Set<Id> parentIds) {
    System.debug('ContactPointAccountSyncService.filterAccountIds() parentIds=' + parentIds);

    Set<Id> accountIds = new Set<Id>();

    if (parentIds == null || parentIds.isEmpty()) {
      return accountIds;
    }

    for (Account acc : [
      SELECT Id
      FROM Account
      WHERE Id IN :parentIds
    ]) {
      accountIds.add(acc.Id);
    }

    System.debug('ContactPointAccountSyncService.filterAccountIds() accountIds=' + accountIds);

    return accountIds;
  }

  private static void setIfAccountFieldExistsAndUpdateable(SObject sob, Schema.DescribeSObjectResult d, String fieldApi, Object value) {
    try {
      if (sob == null || d == null || String.isBlank(fieldApi)) {
        return;
      }

      Map<String, Schema.SObjectField> fieldsMap = d.fields.getMap();

      if (fieldsMap != null && fieldsMap.containsKey(fieldApi) && fieldsMap.get(fieldApi).getDescribe().isUpdateable()) {
        sob.put(fieldApi, value);
      }
    } catch (Exception e) {
      System.debug('ContactPointAccountSyncService.setIfAccountFieldExistsAndUpdateable() ERROR field=' + fieldApi + ', value=' + value + ', msg=' + e.getMessage());
    }
  }
}