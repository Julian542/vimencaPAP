/*************************
* @Class Name:- ManageBeneficiariesHelperFunctionsTest
* @Description:- Test class for ManageBeneficiariesHelperFunctions
*                 Which handles Case creation and service catalog request and 
*                 extended attribute creation based on input parameter. 
**************************/
@IsTest
public with sharing class ManageBeneficiariesHelperFunctionsTest {
    // Set input values
    @IsTest(SeeAllData=true) 
    static void testAddBeneficiaryCaseCreation() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        Map<String, Object> beneficiaryToAdd = new Map<String, Object>();
        input.put('svcCatalogItemDefApiName', 'ManageBeneficiaries');
        input.put('caseSubject', 'Phil Dunphy - Manage Beneficiaries Service Request');
        input.put('isCommunitySite', 'false');
        input.put('accountNumber', 'XXXX-5345');
        input.put('accountType', 'Checking');
        input.put('financialAccountName', 'Test FA1');
        input.put('action', 'Add');
        beneficiaryToAdd.put('BeneficiaryName', 'tetet');
        beneficiaryToAdd.put('BeneficiaryBirthDate', '6/28/2023');
        beneficiaryToAdd.put('BeneficiaryEmail', 'test@gmail.com');
        beneficiaryToAdd.put('BeneficiarySSN', '123-456-2345');
        beneficiaryToAdd.put('RelationshipWithAccountHolder', 'Brother-in-Law');
        beneficiaryToAdd.put('BeneficiaryMobileNumber', '7875875867');
        beneficiaryToAdd.put('AddressLine1', '4547 18th Street');
        beneficiaryToAdd.put('AddressLine2', '7888');
        beneficiaryToAdd.put('State', 'United States');
        beneficiaryToAdd.put('City', 'San Francisco');
        beneficiaryToAdd.put('Country', 'United States');
        beneficiaryToAdd.put('PostalCode', '45454');
        beneficiaryToAdd.put('SelectBeneficiaryMinorStatus', 'Yes');
        beneficiaryToAdd.put('IsGuardianAddressSameAsBeneficiary', 'No');
        beneficiaryToAdd.put('GuardianName', 'Test 1');
        beneficiaryToAdd.put('GuardianMobileNumber', '65764765747');
        beneficiaryToAdd.put('RelationshipWithBeneficiary', 'Sister');
        beneficiaryToAdd.put('GuardianSSN', '123-456-2341');
        beneficiaryToAdd.put('GuardianAddressLine1', '2435 HighSt');
        beneficiaryToAdd.put('GuardianAddressLine2', 'test');
        beneficiaryToAdd.put('GuardianCity', 'San Francisco');
        beneficiaryToAdd.put('GuardianState', 'United States');
        beneficiaryToAdd.put('GuardianCountry', 'United States');
        beneficiaryToAdd.put('GuardianPostalCode', '23345');
        input.put('selectedBeneficiariesToAdd', beneficiaryToAdd);
        args.put('input', input);
        args.put('output', output);
        Callable cllableMethod = (Callable)Type.forName('ManageBeneficiariesHelperFunctions').newInstance();
        Object caseCreateApiObj = cllableMethod.call('callCreateCaseApi', args);  
        System.assertEquals('{apiResponse={}}', String.valueOf(caseCreateApiObj));
    }
    
    @IsTest
    static void testDeleteBeneficiaryCaseCreation() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        Map<String, Object> beneficiaryToDelete = new Map<String, Object>();
        input.put('svcCatalogItemDefApiName', 'ManageBeneficiaries');
        input.put('caseSubject', 'Phil Dunphy - Manage Beneficiaries Service Request');
        input.put('isCommunitySite', 'true');
        input.put('accountNumber', 'XXXX-5345');
        input.put('accountType', 'Checking');
        input.put('action', 'Delete');
        
        beneficiaryToDelete.put('BeneficiaryName', 'Test123');
        beneficiaryToDelete.put('Mobile', '+91233434343');
        input.put('selectedBeneficiariesToDelete', beneficiaryToDelete);
        args.put('input', input);
        args.put('output', output);
        Callable cllableMethod = (Callable)Type.forName('ManageBeneficiariesHelperFunctions').newInstance();
        Object caseCreateApiObj = cllableMethod.call('callCreateCaseApi', args);  
        System.assertEquals('{apiResponse={}}', String.valueOf(caseCreateApiObj));
    }
    
    @IsTest(SeeAllData=true) 
    static void testAddBeneficiaryWithSameAddress() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        Map<String, Object> beneficiaryToAdd = new Map<String, Object>();
        input.put('svcCatalogItemDefApiName', 'ManageBeneficiaries');
        input.put('caseSubject', 'Phil Dunphy - Manage Beneficiaries Service Request');
        input.put('isCommunitySite', 'false');
        input.put('accountNumber', 'XXXX-5345');
        input.put('accountType', 'Checking');
        input.put('action', 'Add');
        beneficiaryToAdd.put('BeneficiaryName', 'tetet');
        beneficiaryToAdd.put('BeneficiaryBirthDate', '6/28/2023');
        beneficiaryToAdd.put('BeneficiaryEmail', 'test@gmail.com');
        beneficiaryToAdd.put('BeneficiarySSN', '123-456-2345');
        beneficiaryToAdd.put('RelationshipWithAccountHolder', 'Brother-in-Law');
        beneficiaryToAdd.put('BeneficiaryMobileNumber', '7875875867');
        beneficiaryToAdd.put('AddressLine1', '4547 18th Street');
        beneficiaryToAdd.put('AddressLine2', '7888');
        beneficiaryToAdd.put('State', 'United States');
        beneficiaryToAdd.put('City', 'San Francisco');
        beneficiaryToAdd.put('Country', 'United States');
        beneficiaryToAdd.put('PostalCode', '45454');
        beneficiaryToAdd.put('SelectBeneficiaryMinorStatus', 'Yes');
        beneficiaryToAdd.put('IsGuardianAddressSameAsBeneficiary', 'Yes');
        beneficiaryToAdd.put('GuardianName', 'Test 1');
        beneficiaryToAdd.put('GuardianMobileNumber', '65764765747');
        beneficiaryToAdd.put('RelationshipWithBeneficiary', 'Sister');
        input.put('selectedBeneficiariesToAdd', beneficiaryToAdd);
        args.put('input', input);
        args.put('output', output);
        Callable cllableMethod = (Callable)Type.forName('ManageBeneficiariesHelperFunctions').newInstance();
        Object caseCreateApiObj = cllableMethod.call('callCreateCaseApi', args);  
        System.assertEquals('{apiResponse={}}', String.valueOf(caseCreateApiObj));
    }
}