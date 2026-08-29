/*************************
* @Class Name:- FSCWlthManageBeneficiariesHelperFuncTest
* @Description:- Test class for FSCWlthManageBeneficiariesHelperFunction
*                 Which handles Case creation and service catalog request and 
*                 extended attribute creation based on input parameter. 
**************************/
@IsTest
public with sharing class FSCWlthManageBeneficiariesHelperFuncTest {
    // Set input values
    @IsTest 
    static void testAddBeneficiaryCaseCreation() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        Map<String, Object> primaryBeneficiaryToAdd = new Map<String, Object>();
        Map<String, Object> contingentBeneficiaryToAdd = new Map<String, Object>();
        Map<String, Object> financialAccountToAdd = new Map<String, Object>();
        input.put('svcCatalogItemDefApiName', 'FSCWealth_ManageBeneficiary');
        input.put('caseSubject', 'Phil Dunphy - Manage Beneficiaries Service Request');
        input.put('isCommunitySite', 'false');
        input.put('accountId', '4455vfggg7uikn');
        input.put('addContingentBeneficiary', 'Yes');
        //set primary beneficiaries details
        primaryBeneficiaryToAdd.put('BeneficiaryName', 'Ben1');
        primaryBeneficiaryToAdd.put('BeneficiaryType', 'Individual');
        primaryBeneficiaryToAdd.put('RelationshipType', 'Son');
        primaryBeneficiaryToAdd.put('FullSSN', '123-456-2345');
        primaryBeneficiaryToAdd.put('Birth Date', '6/28/2023');
        primaryBeneficiaryToAdd.put('NewShare', '100');
        primaryBeneficiaryToAdd.put('AddressLine1', '4547 18th Street');
        primaryBeneficiaryToAdd.put('AddressLine2', '7888');
        primaryBeneficiaryToAdd.put('State', 'United States');
        primaryBeneficiaryToAdd.put('City', 'San Francisco');
        primaryBeneficiaryToAdd.put('CountryCode', 'United States');
        primaryBeneficiaryToAdd.put('PostalCode', '45454');
        primaryBeneficiaryToAdd.put('perStirpes', 'Yes');
        primaryBeneficiaryToAdd.put('Mobile Number', '345677898');
        primaryBeneficiaryToAdd.put('Email', 'Test@test.com');
        //set contingent beneficiaries
        contingentBeneficiaryToAdd.put('ContingentBeneficiaryName', 'Con1');
        contingentBeneficiaryToAdd.put('ContingentBeneficiaryType', 'Individual');
        contingentBeneficiaryToAdd.put('ContingentBeneficiaryRelationshipType', 'Son');
        contingentBeneficiaryToAdd.put('ContingentBeneficiaryBirthDate', '02/23/2000');
        contingentBeneficiaryToAdd.put('ContingentBeneficiarySSN', '123-456-2341');
        contingentBeneficiaryToAdd.put('NewShare', '100');
        contingentBeneficiaryToAdd.put('perStirpes', 'Yes');
        contingentBeneficiaryToAdd.put('ContingentBeneficiaryMobile', 'United States');
        contingentBeneficiaryToAdd.put('ContingentBeneficiaryEmail', '23345');
        contingentBeneficiaryToAdd.put('ContingentBeneficiaryAddressLine1', 'test');
        contingentBeneficiaryToAdd.put('ContingentBeneficiaryAddressLine2', 'San Francisco');
        contingentBeneficiaryToAdd.put('ContingentBeneficiaryCity', 'City1');
        contingentBeneficiaryToAdd.put('ContingentBeneficiaryState', 'United States');
        contingentBeneficiaryToAdd.put('ContingentBeneficiaryCountry', 'United States');
        contingentBeneficiaryToAdd.put('ContingentBeneficiaryPostalCode', '23345');
        //set financial account details
        financialAccountToAdd.put('Name', 'Account 1');
        financialAccountToAdd.put('AccountNumber', 'XXXXX-2344');
        financialAccountToAdd.put('OwnershipType', 'Joint');
        input.put('primaryBeneficiaries', primaryBeneficiaryToAdd);
        input.put('contingentBeneficiaries', contingentBeneficiaryToAdd);
        input.put('financialAccounts', financialAccountToAdd);
        args.put('input', input);
        args.put('output', output);
        Callable cllableMethod = (Callable)Type.forName('FSCWlthManageBeneficiariesHelperFunction').newInstance();
        Object caseCreateApiObj = cllableMethod.call('callCreateCaseApi', args);  
        System.assertEquals('{apiResponse={}}', String.valueOf(caseCreateApiObj));
    }
    
}