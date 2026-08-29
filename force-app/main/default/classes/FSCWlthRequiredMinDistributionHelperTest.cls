/*************************
* @Class Name:- FSCWlthRequiredMinDistributionHelperTest
* @Description:- Test class for FSCWlthRequiredMinimumDistributionHelper
*                 Which handles Case creation and service catalog request and 
*                 extended attribute creation based on input parameter. 
**************************/
@IsTest
public with sharing class FSCWlthRequiredMinDistributionHelperTest {
    // Set input values
    @IsTest
    static void testAutomatedNewEFTCaseCreation() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        Map<String, Object> docs = new Map<String, Object>();
        input.put('svcCatalogItemDefApiName', 'FSCWlth_SetupRequiredMinimumDistribution');
        input.put('caseSubject', 'Phil Dunphy - Setup Required Minimum Distribution Service Request');
        input.put('isCommunitySite', 'false');
        input.put('accountId', '4455vfggg7uikn');
        input.put('financialAccName', 'FA Name');
        input.put('financialAccNumber', '24566CGGG556');
        input.put('financialAccId', 'vffe4567yffagg');
        input.put('paymentSchedule', 'Automated RMD');
        input.put('automatedRMDOption', 'Annual');
        input.put('automatedRMDDate', '12/12/2012');
        input.put('taxYear', '2022');
        input.put('amountOption', 'Enter withdrawal amount');
        input.put('currencyCode', 'USD');
        input.put('amount', 100);
        input.put('paymentOption', 'New EFT Account');
        input.put('bankAccountNumber', '35645678');
        input.put('bankRoutingNumber', '913456789');
        input.put('bankAccHolderName', 'Acc Holder 1');
        input.put('bankAccountType', 'Savings');
        input.put('bankName', 'BANK');
        input.put('bankAddress', 'Address line 1, address line 2');
        input.put('bankZipcode', '23456');
        input.put('bankCity', 'City');
        input.put('bankState', 'NY');
        input.put('bankCountry', 'USA');
        input.put('taxWithholdOption', 'Elect to have federal and state');
        input.put('state', 10);
        input.put('fedral', 10);
        input.put('ownersState', 'State');
        //set uploadedDocuments details
        docs.put('id', 'DocId');
        docs.put('typeId', 'typeId');
        docs.put('name', 'Doc name1');
        args.put('input', input);
        args.put('output', output);
        args.put('documentInfo', docs);
        Callable cllableMethod = (Callable)Type.forName('FSCWlthRequiredMinimumDistributionHelper').newInstance();
        Object caseCreateApiObj = cllableMethod.call('callCreateCaseApi', args);  
        System.assertEquals('{apiResponse={}}', String.valueOf(caseCreateApiObj));
    } 
    
}