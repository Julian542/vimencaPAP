/*************************
* @Class Name:- FSCWlthManageStndInstrHelperFuncTest
* @Description:- Test class for FSCWlthManageStndInstrHelperFunction
*                Which handles Case creation and service catalog request and 
*                extended attribute creation based on input parameter. 
**************************/
@IsTest
public with sharing class FSCWlthManageStndInstrHelperFuncTest {
    
    @IsTest 
    static void testCaseCreationCancelSI() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        Map<String, Object> standingInstructionToCancel = new Map<String, Object>();
        
        input.put('accountId', 'AccountId');
        input.put('svcCatalogItemDefApiName', 'ManageStandingInstructions');
        input.put('caseSubject', 'Mansge Standing Instructions Service Request');
        input.put('isCommunitySite', 'false');
        input.put('financialAccNumber', 'XXXX-2345');
        input.put('financialAccName', 'TestAccountName');
        input.put('standingInstructionType', 'Cancel');
        standingInstructionToCancel.put('StandingOrderId', 'SO783');
        standingInstructionToCancel.put('PayeeName', 'Payee name1');
        standingInstructionToCancel.put('PaymentMode', 'EFT');
        standingInstructionToCancel.put('Bank Account Number', '566777228');
        input.put('cancelStandingInstructions', standingInstructionToCancel);
        args.put('input', input);
        args.put('output', output);
        Callable callableMethod = (Callable)Type.forName('FSCWlthManageStndInstrHelperFunction').newInstance();
        Object createCaseApiObj = callableMethod.call('callCreateCaseApi', args);
        System.assertEquals('{apiResponse={}}', String.valueOf(createCaseApiObj));
    }
    
    @IsTest(SeeAllData=true) 
    static void testCaseCreationAddSI() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        Map<String, Object> standingInstructionToAdd = new Map<String, Object>();
        
        input.put('accountId', 'AccountId');
        input.put('svcCatalogItemDefApiName', 'ManageStandingInstructions');
        input.put('caseSubject', 'Mansge Standing Instructions Service Request');
        input.put('isCommunitySite', 'false');
        input.put('financialAccNumber', 'XXXX-2345');
        input.put('financialAccName', 'TestAccountName');
        input.put('standingInstructionType', 'Add');
        standingInstructionToAdd.put('BankName', 'SO783');
        standingInstructionToAdd.put('AccountNumber', 'Payee name1');
        standingInstructionToAdd.put('Mode', 'Wire Transfer');
        standingInstructionToAdd.put('RoutingNumber', '566777228');
        standingInstructionToAdd.put('Details', 'Savings Account');
        standingInstructionToAdd.put('AccountType', 'XXXX-9876');
        standingInstructionToAdd.put('PayeeAddress', 'RONO9876');
        standingInstructionToAdd.put('PayeeCity', 'ACCNO9876');
        standingInstructionToAdd.put('PayeeState', 'USD');
        standingInstructionToAdd.put('PayeeZipcode', 'Monthly');
        standingInstructionToAdd.put('PayeeCountry', 'Remarks added for testing');
        standingInstructionToAdd.put('Prefix', 'Add');
        standingInstructionToAdd.put('Memo', '77.88');
        standingInstructionToAdd.put('CheckStubInformation', '7');
        standingInstructionToAdd.put('PayeeName', 'PayeeName');
        standingInstructionToAdd.put('TransferType', '1st Praty Transfer');
        standingInstructionToAdd.put('TransferAmount', 23);
        standingInstructionToAdd.put('Currency', 'USD');
        input.put('addStandingInstructions', standingInstructionToAdd);
        args.put('input', input);
        args.put('output', output);
        Callable callableMethod = (Callable)Type.forName('FSCWlthManageStndInstrHelperFunction').newInstance();
        Object createCaseApiObj = callableMethod.call('callCreateCaseApi', args);
        System.assertEquals('{apiResponse={}}', String.valueOf(createCaseApiObj));
    }
    
    @IsTest(SeeAllData=true) 
    static void testCaseCreationAddSIModeCheckDisbursement() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        Map<String, Object> standingInstructionToAdd = new Map<String, Object>();
        
        input.put('accountId', 'AccountId');
        input.put('svcCatalogItemDefApiName', 'ManageStandingInstructions');
        input.put('caseSubject', 'Mansge Standing Instructions Service Request');
        input.put('isCommunitySite', 'false');
        input.put('financialAccNumber', 'XXXX-2345');
        input.put('financialAccName', 'TestAccountName');
        input.put('standingInstructionType', 'Add');
        standingInstructionToAdd.put('BankName', 'SO783');
        standingInstructionToAdd.put('AccountNumber', 'Payee name1');
        standingInstructionToAdd.put('Mode', 'Check');
        standingInstructionToAdd.put('RoutingNumber', '566777228');
        standingInstructionToAdd.put('Details', 'Savings Account');
        standingInstructionToAdd.put('AccountType', 'XXXX-9876');
        standingInstructionToAdd.put('PayeeAddress', 'RONO9876');
        standingInstructionToAdd.put('PayeeCity', 'ACCNO9876');
        standingInstructionToAdd.put('PayeeState', 'USD');
        standingInstructionToAdd.put('PayeeZipcode', 'Monthly');
        standingInstructionToAdd.put('PayeeCountry', 'Remarks added for testing');
        standingInstructionToAdd.put('Prefix', 'Add');
        standingInstructionToAdd.put('Memo', '77.88');
        standingInstructionToAdd.put('CheckStubInformation', '7');
        standingInstructionToAdd.put('PayeeName', '03/03/2023');
        standingInstructionToAdd.put('TransferType', '05/05/2023');
        standingInstructionToAdd.put('TransferAmount', 23);
        standingInstructionToAdd.put('Currency', 'USD');
        input.put('addStandingInstructions', standingInstructionToAdd);
        args.put('input', input);
        args.put('output', output);
        Callable callableMethod = (Callable)Type.forName('FSCWlthManageStndInstrHelperFunction').newInstance();
        Object createCaseApiObj = callableMethod.call('callCreateCaseApi', args);
        System.assertEquals('{apiResponse={}}', String.valueOf(createCaseApiObj));
    }
    
    @IsTest(SeeAllData=true) 
    static void testCaseCreationAddSIModeEFT() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        Map<String, Object> standingInstructionToAdd = new Map<String, Object>();
        Map<String, Object> docs = new Map<String, Object>();
        
        input.put('accountId', 'AccountId');
        input.put('svcCatalogItemDefApiName', 'ManageStandingInstructions');
        input.put('caseSubject', 'Mansge Standing Instructions Service Request');
        input.put('isCommunitySite', 'false');
        input.put('financialAccNumber', 'XXXX-2345');
        input.put('financialAccName', 'TestAccountName');
        input.put('standingInstructionType', 'Add');
        //set uploadedDocuments details
        docs.put('id', 'DocId');
        docs.put('typeId', 'typeId');
        docs.put('name', 'Doc name1');
        standingInstructionToAdd.put('BankName', 'SO783');
        standingInstructionToAdd.put('AccountNumber', 'Payee name1');
        standingInstructionToAdd.put('Mode', 'EFT');
        standingInstructionToAdd.put('RoutingNumber', '566777228');
        standingInstructionToAdd.put('Details', 'Savings Account');
        standingInstructionToAdd.put('TransferType', '1st Party Transfer');
        standingInstructionToAdd.put('TransferAmount', 23);
        standingInstructionToAdd.put('Currency', 'USD');
        standingInstructionToAdd.put('Files','test=2345678,demo');
        input.put('addStandingInstructions', standingInstructionToAdd);
        args.put('input', input);
        args.put('output', output);
        args.put('documentInfo', docs);
        Callable callableMethod = (Callable)Type.forName('FSCWlthManageStndInstrHelperFunction').newInstance();
        Object createCaseApiObj = callableMethod.call('callCreateCaseApi', args);
        System.assertEquals('{apiResponse={}}', String.valueOf(createCaseApiObj));
    }
}