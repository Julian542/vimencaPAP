/**
 * @description       :
 * @author            :
 * @group             :
 * @last modified on  : 08-12-2025
 * @last modified by  : Luisina Platino (lplatino@keystoneadvisors.cl)
**/
@isTest
public class PreQualifyFlowHandlertest {

    @isTest
    public static void TestprequalifyClient(){

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

        PreQualifyFlowHandler.prequalifyClient(model);
    }

    @isTest
    public static void TestCreateBodyPJ(){
        List<Account> cuenta = TestDataFactoryPreQualifyFlow.crearBasicCandidatoPJ(1);
        List<Informacion_Financiera__c> info = TestDataFactoryPreQualifyFlow.createInfoFinan(cuenta);
        List<Participante__c> accionista = TestDataFactoryPreQualifyFlow.createBasicAcionista(cuenta);
        List<Participante__c> representante = TestDataFactoryPreQualifyFlow.createBasicRepresentante(cuenta);
        PreQualifyFlowHandler.createBody(cuenta[0], info[0], accionista[0], representante[0], null);
    }

    @isTest
    public static void TestCreateBodyPF(){
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        List<Account> cuenta = TestDataFactoryPreQualifyFlow.crearCandidatoPF(1);
        List<Informacion_Financiera__c> info = TestDataFactoryPreQualifyFlow.createInfoFinan(cuenta);
        List<Historial_laboral__c> his = TestDataFactoryPreQualifyFlow.createHistorial(cuenta);
        PreQualifyFlowHandler.createBody(cuenta[0], info[0], null, null, his[0]);
    }
}
