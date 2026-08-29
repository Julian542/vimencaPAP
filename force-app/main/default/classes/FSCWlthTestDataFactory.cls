/*************************
* @Class Name:- FSCWlthTestDataFactory
* @Description:- This file includes test data for test classes.
**************************/
@IsTest
public with sharing class FSCWlthTestDataFactory {
    
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
        List<Case> listCases = FSCWlthTestDataFactory.createCase(intNumber, accList);
        
        for (Integer numVal = 0; numVal < intNumber; numVal++) {
            SvcCatalogRequest objServiceCatalogReq = new SvcCatalogRequest(CaseId = listCases[numVal].Id, CatalogItemName = 'TestCatalog' + numVal);
            listServiceCatalogReq.add(objServiceCatalogReq);
        }
        return listServiceCatalogReq;
    }
}
