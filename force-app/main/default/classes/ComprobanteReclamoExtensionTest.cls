@isTest
public class ComprobanteReclamoExtensionTest {
    @isTest
    public static void ExtensionTestgets(){
        
        /* Record Types de los casos */
        List<Id> RecordTypes = new List<Id>();
        recordTypes.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Reclamaciones').getRecordTypeId());
		recordTypes.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('RT_Soporte_1').getRecordTypeId());
        recordTypes.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('RT_Soporte_2').getRecordTypeId());
      	recordTypes.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('RT_Soporte_3').getRecordTypeId());
        recordTypes.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('RT_Soporte_4').getRecordTypeId());
        recordTypes.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('RT_Soporte_5').getRecordTypeId());
        recordTypes.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('RT_Soporte_6').getRecordTypeId());
        recordTypes.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('RT_Soporte_7').getRecordTypeId());
        recordTypes.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('RT_Soporte_8').getRecordTypeId());
        
        /* Se crea una cuenta a asociar al caso */
        ID rt_pj  = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Personas_Juridicas').getRecordTypeId();
        Account auxAccount = new Account(Name = 'Test extension ComprobanteReclamo Account', RecordTypeId=rt_pj);
        insert auxAccount;
        
        /* Se crea un asset a asociar al caso */
        ID rt_asset  = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Cuentas_de_ahorro').getRecordTypeId();
        Asset auxAsset = new Asset(Name = 'Test Asset ComprobanteReclamo Account', ASE_N_de_cuenta__c = '1234567890', AccountId = auxAccount.Id, RecordTypeId=rt_asset);
        insert auxAsset;
        
        /* Se crea un usuario a asociar al caso */
        User auxUser = new User(Username='testComprobante@test.com', LastName='Test', Email = 'test@testmail.com', Alias='Tester', TimeZoneSidKey = 'America/Puerto_Rico', LocaleSidKey = 'es_DO',
                               EmailEncodingKey = 'ISO-8859-1', ProfileId = '00e3i000001RR1qAAG', LanguageLocaleKey = 'es', USE_Codigo__c = 'VISEO');
        insert auxUser;
        /* Se crea un casos de prueba */	
        List<Case> casos = new List <Case>();
        for(Id idRecordType: RecordTypes)
            casos.add(new Case(RecordTypeId=idRecordType, AccountId = auxAccount.Id, AssetId = auxAsset.Id, Asignado_a__c = auxUser.Id, CreatedDate = Date.today()));
        insert casos;
        
        /* Se inicializa la extension */
        Apexpages.StandardController sc = new Apexpages.standardController(casos[0]);        
        ComprobanteReclamoExtension extvf = new ComprobanteReclamoExtension(sc);
        
        /* Test funcion getReclamoCreatedDate */
        System.assertEquals(generalUtils.getDate(casos[0].CreatedDate.Date()), extvf.getReclamoCreatedDate());
        
        /* Test funcion getReclamoCreatedDateTime */
        System.assertEquals(generalUtils.getDateTime(casos[0].CreatedDate), extvf.getReclamoCreatedDateTime());
        
        /* Test funcion getOficina */
        //System.assertEquals(generalUtils.pickListGetLabel(user.USE_Oficina__c.getDescribe(), casos[0].Asignado_a__r.USE_Oficina__c), extvf.getOficina());
        
        /* Test funcion getTipoReclamo */
        System.assertEquals(generalUtils.pickListGetLabel(Case.Type.getDescribe(), casos[0].Type), extvf.getTipoReclamo());
        
        /* Test funcion getSLA */
        for (integer i = 0; i < casos.size(); i++){
            sc = new Apexpages.standardController(casos[i]);
            extvf = new ComprobanteReclamoExtension(sc);
            if(casos[i].recordTypeId == recordTypes[1]){
                //System.assertEquals(generalUtils.getDate(casos[i].CreatedDate.Date().addDays(42)), extvf.getSLA());
            }
            else if(casos[i].recordTypeId == recordTypes[2]){
                //System.assertEquals(generalUtils.getDate(casos[i].CreatedDate.Date().addDays(31)), extvf.getSLA());
            }
            else if(casos[i].recordTypeId == recordTypes[3] || casos[i].recordTypeId == recordTypes[4]){
                //System.assertEquals(generalUtils.getDate(casos[i].CreatedDate.Date().addDays(32)), extvf.getSLA());
            }
            else if(casos[i].recordTypeId == recordTypes[5] || casos[i].recordTypeId == recordTypes[6] || casos[i].recordTypeId == recordTypes[7] || casos[i].recordTypeId == recordTypes[8]){
                //System.assertEquals(generalUtils.getDate(casos[i].CreatedDate.Date().addDays(3)), extvf.getSLA());
            }
            else{
                System.assertEquals('', extvf.getSLA());
            }
        }
    }
}