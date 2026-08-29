/*************************
* @Class Name:- FSCRetailTestDataFactory
* @Description:- This file includes test data for test classes.
**************************/
@IsTest
public with sharing class FSCRetailTestDataFactory {
    
    //Method to create Accounts
    public static List<Account> createAccounts(Integer intNumber) {
        List<Account> listAccounts = new List<Account>();
        List<Account> listAccountsCreated = new List<Account>();
        Id accountRecordType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        
        for (Integer numVal = 0; numVal < intNumber; numVal++) {
            Account objAccount = new Account(FirstName = 'Test', LastName = 'Account'+ numVal, FinServ__SourceSystemId__c = '234' + numVal, PersonMobilePhone ='6545645646' + numVal, RecordTypeId = accountRecordType);
            listAccounts.add(objAccount);
        }
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        insert listAccounts;
        listAccountsCreated = [SELECT Id, FinServ__SourceSystemId__c FROM Account WHERE Id != null];
        return listAccountsCreated;
    }
    
    //Method to create Financial Accounts
    public static List<FinServ__FinancialAccount__c> createFinancialAccounts(Integer intNumber, List<Account> listAccounts) {
        List<FinServ__FinancialAccount__c> listFinAccountsCreated = new List<FinServ__FinancialAccount__c>();
        List<FinServ__FinancialAccount__c> listFinAccounts = new List<FinServ__FinancialAccount__c>();
        Id finAccountRecordType = Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName().get('CheckingAccount').getRecordTypeId();
        
        for (Integer numVal = 0; numVal < intNumber; numVal++) {
            FinServ__FinancialAccount__c objFinAccount = new FinServ__FinancialAccount__c(Name = 'Financial Account ' + numVal, FinServ__FinancialAccountNumber__c = '6542564621' + numVal, 
                                                                                          FinServ__SourceSystemId__c = '23445433' + numVal, RecordTypeId = finAccountRecordType, FinServ__PrimaryOwner__c = listAccounts[numVal].Id);
            listFinAccounts.add(objFinAccount);
        }
        insert listFinAccounts;
        listFinAccountsCreated = [SELECT Id FROM FinServ__FinancialAccount__c WHERE Id != null];
        return listFinAccountsCreated;
    }
    
    //Method to create Cases
    public static List<Case> createCase(Integer intNumber, List<Account> accList) {
        List<Case> listCases = new List<Case>();
        List<Case> listCaseCreated = new List<Case>();
        for (Integer numVal = 0; numVal < intNumber; numVal++) {
            Case objCase = new Case(AccountId = accList[numVal].Id);
            listCases.add(objCase);
        }  
        insert listCases;
        listCaseCreated = [SELECT Id,AccountId FROM Case WHERE AccountId != null];
        return listCaseCreated;
    }
    
    //Method to create Service Catalog Request
    public static List<SvcCatalogRequest> createServiceCatalogRequest(Integer intNumber, List<Account> accList) {
        List<SvcCatalogRequest> listServiceCatalogReq = new List<SvcCatalogRequest>();
        List<Case> listCases = FSCRetailTestDataFactory.createCase(intNumber, accList);
        
        for (Integer numVal = 0; numVal < intNumber; numVal++) {
            SvcCatalogRequest objServiceCatalogReq = new SvcCatalogRequest(CaseId = listCases[numVal].Id, CatalogItemName = 'TestCatalog' + numVal);
            listServiceCatalogReq.add(objServiceCatalogReq);
        }
        return listServiceCatalogReq;
    }
    
    //Method to create Financial Account Role
    public static List<FinServ__FinancialAccountRole__c> createFinancialAccRole (Integer intNumber, List<Account> accList, List<FinServ__FinancialAccount__c> finAcc) {
        List<FinServ__FinancialAccountRole__c> listFinAccRoleCreated = new List<FinServ__FinancialAccountRole__c>();
        List<FinServ__FinancialAccountRole__c> listFinAccRole = new List<FinServ__FinancialAccountRole__c>();
        
        FinServ__FinancialAccountRole__c objFinAccRole = new FinServ__FinancialAccountRole__c();
        objFinAccRole.FinServ__Role__c = 'Beneficiary';
        objFinAccRole.FinServ__SourceSystemId__c = '23445433';
        objFinAccRole.FinServ__RelatedAccount__c = accList[0].Id;
        objFinAccRole.FinServ__FinancialAccount__c = finAcc[0].Id;
        listFinAccRole.add(objFinAccRole);
        insert listFinAccRole;
        listFinAccRoleCreated = [SELECT Id, FinServ__SourceSystemId__c, FinServ__Role__c,FinServ__FinancialAccount__c,FinServ__FinancialAccount__r.FinServ__SourceSystemId__c, FinServ__RelatedAccount__c, FinServ__RelatedAccount__r.Name, FinServ__RelatedAccount__r.PersonMobilePhone FROM FinServ__FinancialAccountRole__c WHERE Id != null AND FinServ__Role__c =: 'Beneficiary'];
        return listFinAccRoleCreated;
    }
    
    //Method to create Cards
    public static List<FinServ__Card__c> createCards(List<Account> listAccounts) {
        List<FinServ__FinancialAccount__c> listFinAccounts = FSCRetailTestDataFactory.createFinancialAccounts(1, listAccounts);
        List<FinServ__Card__c> listCards = new List<FinServ__Card__c>();
        List<FinServ__Card__c> listCardsCreated = new List<FinServ__Card__c>();
        
        FinServ__Card__c  cardData = new FinServ__Card__c ();
        cardData.Name = 'Test Card 1';
        cardData.FinServ__FinancialAccount__c = listFinAccounts[0].Id;
        cardData.FinServ__SourceSystemId__c  = '12345';
        cardData.FinServ__AccountHolder__c = listAccounts[0].Id;
        cardData.Card_Number__c  = Decimal.valueof('355646766382');
        cardData.FinServ__ValidUntil__c = Date.newInstance(2025, 06, 08);
        listCards.add(cardData);
        insert listCards;
        listCardsCreated = [SELECT Id, Card_Number__c, FinServ__ValidUntil__c, FinServ__AccountHolder__c, FinServ__SourceSystemId__c FROM FinServ__Card__c WHERE Id != null];
        return listCardsCreated;
    }
}
