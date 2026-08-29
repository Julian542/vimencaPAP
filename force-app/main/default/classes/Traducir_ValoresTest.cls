@isTest
public class Traducir_ValoresTest {
    
    @isTest
    public static void concatDireccionTest(){
        /* Cuenta requerida para la direccion */
        Account newAccount = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId(),
            Name = 'Test Account 1',
            ACC_RNC__c = '131000007',
            ACC_TipoIdentificacion__c = 'RNC',
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO'
        );
        insert newAccount;
        
        /* Dirección con la que realizar los test */
        Direccion__c concatTestDirec = new Direccion__c(
            DIR_Calle__c = 'El Sol',
            DIR_Numero__c = '59',
            DIR_Pais__c = 'DO',
            DIR_Provincia__c = '02',
            DIR_Municipio__c = '0210',
            DIR_Distrito__c = '021001',
            DIR_Account__c = newAccount.Id
        );
        insert concatTestDirec;

        Direccion__c translatedAddress = [
            SELECT DIR_Direccion_Traduccion__c,
                DIR_Pais_Texto__c,
                DIR_Provincia_texto__c,
                DIR_Municipio_texto__c,
                DIR_Distrito_texto__c
            FROM Direccion__c
            WHERE Id = :concatTestDirec.Id
        ];
        String country = picklistLabel(Direccion__c.DIR_Pais__c.getDescribe(), 'DO');
        String province = picklistLabel(Direccion__c.DIR_Provincia__c.getDescribe(), '02');
        String municipality = picklistLabel(Direccion__c.DIR_Municipio__c.getDescribe(), '0210');
        String district = picklistLabel(Direccion__c.DIR_Distrito__c.getDescribe(), '021001');

        /* Se validan las labels configuradas que el trigger debe traducir. */
        System.assertEquals(
            'El Sol - 59 - ' + country + ' - ' + province + ' - ' + municipality + ' - ' + district,
            translatedAddress.DIR_Direccion_Traduccion__c
        );
        System.assertEquals(country, translatedAddress.DIR_Pais_Texto__c);
        System.assertEquals(province, translatedAddress.DIR_Provincia_texto__c);
        System.assertEquals(municipality, translatedAddress.DIR_Municipio_texto__c);
        System.assertEquals(district, translatedAddress.DIR_Distrito_texto__c);
    }

    private static String picklistLabel(Schema.DescribeFieldResult fieldDescribe, String value) {
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            if (entry.getValue() == value) {
                return entry.getLabel();
            }
        }

        return value;
    }
}
