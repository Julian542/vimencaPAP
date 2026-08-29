/**
 * @description       : 
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 02-01-2026
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
@isTest
private with sharing class PreQualifyFlowHandler_FSC_Test {

    @isTest
    private static void TestprequalifyClient(){

        Test.setMock(HttpCalloutMock.class, new RESTMockPreQualifyFlow());

        Map<String,String> headerMap = new Map<String,String>();
        headerMap.put('RTInd', 'N');
        headerMap.put('date', '04062018');
        headerMap.put('time', '2210');
        headerMap.put('EVENT', '00308');
        headerMap.put('USER', 'ViniRobert');

        PreQualifyFlowModel.FieldsModel fModel = new PreQualifyFlowModel.FieldsModel();
        fModel.averageMonthlyIncome                 = '1';
        fModel.averageMonthlyIncomeRange            = '1';
        fModel.averageMonthlySales                  = '1';
        fModel.averageMonthlySalesRange             = '1';
        fModel.beneficiaryType                      = '1';
        fModel.branchOpening                        = '1';
        fModel.channel01                            = '1';
        fModel.channel02                            = '2';
        fModel.channel03                            = '3';
        fModel.channel04                            = '4';
        fModel.channel05                            = '5';
        fModel.companyCode                          = '1';
        fModel.countryOfBirth                       = 'DR';
        fModel.countryOfResidence                   = '1';
        fModel.customerCode                         = '1';
        fModel.dateOfBirthIncorporation             = '1';
        fModel.dateOfBirthRepresentative1           = '1';
        fModel.dateOfBirthShareholder1              = '1';
        fModel.dignitaryRelationship                = '1';
        fModel.economicActivityCode                 = '1';
        fModel.executiveCodeOfficial                = '1';
        fModel.firstName                            = '1';
        fModel.firstNameRepresentative1             = '1';
        fModel.firstNameShareholder1                = '1';
        fModel.firstSurname                         = '1';
        fModel.firstSurnameRepresentative1          = '1';
        fModel.handleCash                           = '1';
        fModel.internationalOperations              = '1';
        fModel.legalStructureType                   = '1';
        fModel.middleName                           = '1';
        fModel.middleNameRepresentative1            = '1';
        fModel.middleNameShareholder1               = '1';
        fModel.nationalityConstitution              = '1';
        fModel.nationalityRepresentative1           = '1';
        fModel.nationalityShareholder1              = '1';
        fModel.occupation                           = '1';
        fModel.originOfResources                    = '1';
        fModel.participationPercentageShareholder1  = '1';
        fModel.pepCollaborator                      = '1';
        fModel.pepFamily                            = '1';
        fModel.pepPublicServer                      = '1';
        fModel.pepRelationType                      = '1';
        fModel.personNameBusinessName               = '1';
        fModel.personTypeNJ                         = '1';
        fModel.processDate                          = '1';
        fModel.productCode01                        = '1';
        fModel.productCode02                        = '1';
        fModel.productCode03                        = '1';
        fModel.productCode04                        = '1';
        fModel.productCode05                        = '1';
        fModel.relationshipWithTheInstitution       = '1';
        fModel.representative01                     = '1';
        fModel.secondSurname                        = '1';
        fModel.secondSurnameRepresentative1         = '1';
        fModel.secondSurnameShareholder1            = '1';
        fModel.serviceCode01                        = '1';
        fModel.serviceCode02                        = '1';
        fModel.serviceCode03                        = '1';
        fModel.serviceCode04                        = '1';
        fModel.serviceCode05                        = '1';
        fModel.shareholder01                        = '1';
        fModel.typeIdIdentificationNumber           = '1';
        fModel.typeIdIdentificationRepresentative1  = '1';
        fModel.typeIdIdentificationShareholder1     = '1';

        PreQualifyFlowModel model = new PreQualifyFlowModel();
        model.Header = headerMap;
        model.Fields = fModel;

        PreQualifyFlowHandler_FSC.prequalifyClient(model);
    }

    @isTest
    private static void TestCreateBodyPJ(){
        List<Account> cuenta = TestDataFactoryPreQualifyFlow_FSC.crearBasicCandidatoPJ(1);
        List<Informacion_Financiera__c> info = TestDataFactoryPreQualifyFlow_FSC.createInfoFinan(cuenta);
        //List<FinServ__FinancialAccountRole__c> accionista = TestDataFactoryPreQualifyFlow_FSC.createBasicAcionista(cuenta);
        //List<FinServ__FinancialAccountRole__c> representante = TestDataFactoryPreQualifyFlow_FSC.createBasicRepresentante(cuenta);
        //PreQualifyFlowHandler_FSC.createBody(cuenta[0], info[0], accionista[0], representante[0], null);
    }

    @isTest
    private static void TestCreateBodyPF(){
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        List<Account> cuenta = TestDataFactoryPreQualifyFlow_FSC.crearCandidatoPF(1);
        List<Informacion_Financiera__c> info = TestDataFactoryPreQualifyFlow_FSC.createInfoFinan(cuenta);
        List<FinServ__Employment__c> his = TestDataFactoryPreQualifyFlow_FSC.createHistorial(cuenta);
        PreQualifyFlowHandler_FSC.createBody(cuenta[0], info[0], null, null, his[0]);
    }

    @IsTest
    private static void coversAlternativePreQualifyDataBuilders(){
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));

        List<Account> juridicalCandidates =
            TestDataFactoryPreQualifyFlow_FSC.crearBasicCandidatoPJ(1);
        List<Account> physicalCandidates =
            TestDataFactoryPreQualifyFlow_FSC.crearBasicCandidatoPF(1);
        List<Informacion_Financiera__c> financialInformation =
            TestDataFactoryPreQualifyFlow_FSC.createBasicInfoFinan(juridicalCandidates);
        List<FinServ__Employment__c> employments =
            TestDataFactoryPreQualifyFlow_FSC.createBasicHistorial(physicalCandidates);

        List<Profile> profiles = TestDataFactoryPreQualifyFlow_FSC.createProfile();
        List<Account> emptyAccounts = TestDataFactoryPreQualifyFlow_FSC.createAccounts(0);

        System.assertEquals(1, juridicalCandidates.size());
        System.assertEquals(1, physicalCandidates.size());
        System.assertEquals(1, financialInformation.size());
        System.assertEquals(1, employments.size());
        System.assertNotEquals(null, profiles);
        System.assertEquals(0, emptyAccounts.size());
    }
}
