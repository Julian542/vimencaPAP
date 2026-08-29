/****
* Test class for TransferFundsToOwnAccHelperFunctions
* Which handles Case creation and service catalog request and 
* extended attribute creation based on input parameter. 
* ****/
@IsTest
public with sharing class TransferFundsToOwnAccHelperFunctionsTest {
    
    @IsTest(SeeAllData=true) 
    static void testCaseCreation() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        
        input.put('accountId', '001RO000004adwaYAA');
        input.put('svcCatalogItemDefApiName', 'TransferFundsToOwnAccount');
        input.put('caseSubject', 'Transfer Funds To own Account Service Request');
        input.put('isCommunitySite', 'false');
        input.put('transferFromAccountName', 'FromAccountName');
        input.put('transferFromAccountNumber', 'XXXX-9872');
        input.put('transferFromAccountType', 'Savings Account');
        input.put('transferToAccountName', 'ToAccountName');
        input.put('transferToAccountNumber', 'XXXX-9876');
        input.put('transferToAccountType', 'Loan Account');
        input.put('currencyCode', 'USD');
        input.put('frequency', 'Monthly');
        input.put('remarks', 'Remarks added for testing');
        input.put('paymentType', 'Recurring');
        input.put('amount', 'USD 77.88');
        input.put('instalment', '7');
        input.put('startDate', '03/03/2023');
        input.put('endDate', '05/05/2023');
        input.put('transferDate', '03/03/2023');
        input.put('recurringPaymentOption','Custom');
        args.put('input', input);
        args.put('output', output);
        Callable callableMethod = (Callable)Type.forName('TransferFundsToOwnAccountHelperFunctions').newInstance();
        Object createCaseApiObj = callableMethod.call('callCreateCaseApi', args);
        system.assertEquals('{}', String.valueOf(createCaseApiObj));
    }
    
}