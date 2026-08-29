/*************************
* @Class Name:- FSCWlthInitAutomatedAcctTfrHelperTst
* @Description:- Test class for FSCWlthInitAutomatedAccountTfrHelper
*                 Which handles Case creation and service catalog request and 
*                 extended attribute creation based on input parameter. 
**************************/
@IsTest
public with sharing class FSCWlthInitAutomatedAcctTfrHelperTst {
    // Set input values
    @IsTest 
    static void testBrokerageTransferCaseCreation() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        Map<String, Object> financialSecurityToAdd = new Map<String, Object>();
        input.put('svcCatalogItemDefApiName', 'FSCWealth_AutomatedCustomerAccountTransfer');
        input.put('caseSubject', 'Phil Dunphy - Automated Customer Account Transfer Service Request');
        input.put('isCommunitySite', 'false');
        input.put('accountId', '4455vfggg7uikn');
        input.put('financialAccName', 'FA Name');
        input.put('financialAccNumber', '24566CGGG556');
        input.put('financialAccId', 'vffe4567yffagg');
        input.put('transferAction', 'Standard');
        input.put('extnAccountNumber', 'EXTNum4566');
        input.put('extnAccountType', 'Checking');
        input.put('extnAccountOwner', 'Self');
        input.put('transFirmName', 'Trans Firm Name');
        input.put('transFirmAddress', 'Address1,Address2,street');
        input.put('transFirmCity', 'City');
        input.put('transFirmState', 'State');
        input.put('transFirmCountry', 'Country');
        input.put('transFirmZipCode', '345678');
        input.put('transFirmPhone', '+913456789');
        input.put('transferType', 'Brokerage or Trust Company Transfer');
        input.put('transferEntireAccount', 'No');
        input.put('cash', 'Yes');
        input.put('security', 'Yes');
        input.put('amount', 666);
        input.put('currencyCode', 'USD');
        input.put('amountMode', 'Custom');
        input.put('mode', 'Full Annuity Surrender, dated');
        input.put('maturityAnnuityDate', '24/02/2000');
        //set financialSecurityToAdd details
        financialSecurityToAdd.put('HoldingsName', 'Ben1');
        financialSecurityToAdd.put('SecurityQuantity', 'Custom');
        financialSecurityToAdd.put('SecuritiesNumberOfUnits', 30);
        input.put('brokerageTrustCompanyTransfer', financialSecurityToAdd);
        args.put('input', input);
        args.put('output', output);
        Callable cllableMethod = (Callable)Type.forName('FSCWlthInitAutomatedAccountTfrHelper').newInstance();
        Object caseCreateApiObj = cllableMethod.call('callCreateCaseApi', args);  
        System.assertEquals('{apiResponse={}}', String.valueOf(caseCreateApiObj));
    }
    
    @IsTest(SeeAllData=true) 
    static void testMutualFundTransferCaseCreation() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        Map<String, Object> financialSecurityToAdd = new Map<String, Object>();
        input.put('transferType', 'Mutual Fund Company Account Transfer');
        input.put('transferEntireAccount', 'No');
        input.put('mode', 'Transfer the following number of whole shares');
        input.put('numOfShares', 67);
        //set financialSecurityToAdd details
        financialSecurityToAdd.put('FundName', 'Ben1');
        financialSecurityToAdd.put('MutualFundQuantity', 'Custom');
        financialSecurityToAdd.put('MutualFundAccountNumber', '4567g7788');
        financialSecurityToAdd.put('FundQuantity', 30);
        financialSecurityToAdd.put('TransferOptions','In Kind');
        input.put('mutualFundCompanyTransfer', financialSecurityToAdd);
        args.put('input', input);
        args.put('output', output);
        Callable cllableMethod = (Callable)Type.forName('FSCWlthInitAutomatedAccountTfrHelper').newInstance();
        Object caseCreateApiObj = cllableMethod.call('callCreateCaseApi', args);  
        System.assertEquals('{apiResponse={}}', String.valueOf(caseCreateApiObj));
    }
    
}