@isTest
public class Codigo_nacimientoTest {   
@isTest
    public static void concatDireccionTest(){
        /* Cuenta requerida para la direccion */
        Account newAccount = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId(),
            Name = 'Test Account 1',
            ACC_Ciudad_de_nacimiento__c = 'SANTO DOMINGO DE GUZMÁN',
            ACC_RNC__c = '131000006',
            ACC_TipoIdentificacion__c = 'RNC',
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO'
        );
        insert newAccount;
        
        /* Se valida la nueva direccion */
        System.assertEquals('101', [Select Ciudad_Nacimiento_Codigo__c from Account where Id=: newAccount.Id].Ciudad_Nacimiento_Codigo__c);
        
    }
}
