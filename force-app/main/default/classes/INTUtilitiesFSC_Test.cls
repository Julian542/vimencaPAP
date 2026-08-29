@isTest
public class INTUtilitiesFSC_Test {
  public static Map<String, String> valuesClient = new Map<String, String>{
    '[function_document]' => 'ACC_NumIdentificacion__c', //principal fields
    '[function_documentType]' => 'ACC_TipoIdentificacion__c',
    '[function_firstName]' => 'FirstName',
    '[function_lastName]' => 'LastName',
    '[function_midleName]' => 'MiddleName',
    '[function_sufijo]' => 'Suffix',
    '[function_gender]' => 'ACC_Genero__c',
    '[function_maritalStatus]' => 'ACC_Estado_Civil__c',
    '[function_birthDate]' => 'PersonBirthdate',
    '[function_nacionality]' => 'ACC_Nacionalidad__c',
    '[function_clientType]' => 'ACC_Tipo_Cliente_PF__c',
    '[function_laboralSector]' => 'ACC_Tipo_Sector__c',
    '[function_ActivityType]' => 'ACC_Tipo_Actividad__c',
    '[function_segment]' => 'ACC_Segmento__c',
    '[function_totalAssets]' => 'ACC_Total_Activos__c',
    '[function_numEmployees]' => 'ACC_NumEmpleados__c',
    '[function_otherCountryRes]' => 'ACC_Posee_Resid_Otro_Pais__c'
  };

  public static Map<String, String> valuesAdresses = new Map<String, String>{
    '[function_addressId]' => 'Id',
    '[function_addressExternalIdBk]' => 'Id',
    '[function_addressIdentifier]' => 'Id',
    '[function_addressPrimary]' => 'isPrimary',
    '[function_addressType]' => 'AddressType',
    '[function_addressStreet]' => 'Street',
    '[function_addressNum]' => 'Street',
    '[function_addressBuilding]' => '',
    '[function_addressMunicipality]' => 'CPA_Municipio__c',
    '[function_addressNumFloor]' => 'CPA_N_Apartamento__c',
    '[function_addressCountry]' => 'Country',
    '[function_addressProvince]' => 'State',
    '[function_addressMunicipalDistrict]' => 'CPA_Distrito__c',
    '[function_addressSector]' => 'CPA_Sector__c',
    '[function_addressPostalCode]' => 'postalCode',
    '[function_addressCityStatePC]' => 'City',
    '[function_addressPhone]' => '',
    '[function_addressPhoneEx]' => '',
    '[function_addressExtraPhone1]' => '',
    '[function_addressExtraPhone2]' => ''
  };

  public static Map<String, String> valuesContactInfo = new Map<String, String>{
    '[function_contactInfoId]' => 'VIA_Id_Externo_Via__c',
    '[function_ViaIdExternoVia]' => 'VIA_Id_Externo_Via_bk__c', //Este fue el nuevo campo agregado
    '[function_contactInfoIdentifier]' => 'VIA_Identificador__c',
    '[function_contactPrincipal]' => 'VIA_Principal__c',
    '[function_contactWayType]' => 'VIA_de_Contacto__c',
    '[function_contactWayCant]' => 'VIA_Numero_Correo__c',
    '[function_contactCompany]' => 'VIA_Telefonica__c',
    '[function_contactSMS]' => 'VIA_Envio_SMS__c',
    '[function_contactExRef]' => 'VIA_Id_Externo_Via__c'
  };

  @isTest
  static void INTUtilitiesFSC_Test() {
    List<Account> accList = TestDataFactory.createPersonAccounts(2);

    Test.setMock(HttpCalloutMock.class, new INT007TestMock('PJ'));
    accList[0].lastname = 'Test Person Account ';

    accList[0].ACC_RNC__c = 'RNC';
    accList[0].ACC_CIF__c = 'TESTCIF';
    accList[0].ACC_Condicion__c = 'PROSPECTO';
    accList[0].ACC_Estado__c = 'CONVERTIR';
    accList[0].ACC_TipoIdentificacion__c = 'Cédula';
    accList[0].ACC_NumEmpleados__c = 150;
    accList[0].ACC_Volumen_Ventas_Anual__c = 1500000000;
    //accList[0].ACC_Actividad_Economica__c = maestro[0].id;
    accList[0].PersonBirthdate = date.today();
    accList[0].ACC_Total_Activos__c = 1500000000;

    Test.startTest();
    INTUtilities_FSC.fillCorrectType(INTUtilitiesTest.valuesClient, accList[0], 'prova');
    Test.stopTest();
  }

  @isTest
  static void addressValuesNameTest() {
    List<Account> accList = TestDataFactory.createPersonAccounts(2);
    List<Direccion__c> direcciones = TestDataFactory.createDirecciones(accList);

    Test.setMock(HttpCalloutMock.class, new INT007TestMock('PJ'));
    Test.startTest();
    INTUtilities_FSC.fillCorrectType(INTUtilitiesTest.valuesAdresses, direcciones[0], 'prova');
    Test.stopTest();
  }

  @isTest
  static void addressValuesIdentificadorTest() {
    List<Account> accList = TestDataFactory.createPersonAccounts(2);
    List<Direccion__c> direcciones = TestDataFactory.createDirecciones(accList);

    direcciones[0].DIR_Identificador__c = 'Test Identificador';

    Test.setMock(HttpCalloutMock.class, new INT007TestMock('PJ'));
    Test.startTest();
    INTUtilities_FSC.fillCorrectType(INTUtilitiesTest.valuesAdresses, direcciones[0], 'prova');
    Test.stopTest();
  }

  @isTest
  static void addressValuesNOIdentificadorTest() {
    List<Account> accList = TestDataFactory.createPersonAccounts(2);
    List<Direccion__c> direcciones = TestDataFactory.createDirecciones(accList);

    direcciones[0].DIR_Id_Externo_Direccion__c = 'Test Identificador';

    Test.setMock(HttpCalloutMock.class, new INT007TestMock('PJ'));
    Test.startTest();
    INTUtilities_FSC.fillCorrectType(INTUtilitiesTest.valuesAdresses, direcciones[0], 'prova');
    Test.stopTest();
  }

  @isTest
  static void addressValuesDatosMaestrosTest() {
    List<Account> accList = TestDataFactory.createPersonAccounts(2);
    List<Direccion__c> direcciones = TestDataFactory.createDirecciones(accList);

    Datos_Maestros__c datos = new Datos_Maestros__c();
    datos.Name = 'Test datos Maestros';
    insert datos;

    direcciones[0].DIR_Sector__c = datos.Id;

    Test.setMock(HttpCalloutMock.class, new INT007TestMock('PJ'));
    Test.startTest();
    INTUtilities_FSC.fillCorrectType(INTUtilitiesTest.valuesAdresses, direcciones[0], 'prova');
    Test.stopTest();
  }

  @isTest
  static void contactWaysValuesNameTest() {
    List<Account> accList = TestDataFactory.createPersonAccounts(2);
    List<Direccion__c> direcciones = TestDataFactory.createDirecciones(accList);
    List<Vias_de_Contacto__c> viasList = TestDataFactory.createViasDeContacto(accList);

    Test.setMock(HttpCalloutMock.class, new INT007TestMock('PJ'));
    Test.startTest();
    INTUtilities_FSC.fillCorrectType(INTUtilitiesTest.valuesContactInfo, viasList[0], 'prova');
    Test.stopTest();
  }

  @isTest
  static void contactWaysIdentificadorValuesTest() {
    List<Account> accList = TestDataFactory.createPersonAccounts(2);
    List<Direccion__c> direcciones = TestDataFactory.createDirecciones(accList);
    List<Vias_de_Contacto__c> viasList = TestDataFactory.createViasDeContacto(accList);

    viasList[0].VIA_Identificador__c = 'Test Identificador';

    Test.setMock(HttpCalloutMock.class, new INT007TestMock('PJ'));
    Test.startTest();
    INTUtilities_FSC.fillCorrectType(INTUtilitiesTest.valuesContactInfo, viasList[0], 'prova');
    Test.stopTest();
  }

  @isTest
  static void contactWaysNOIdentificadorValuesTest() {
    List<Account> accList = TestDataFactory.createPersonAccounts(2);
    List<Direccion__c> direcciones = TestDataFactory.createDirecciones(accList);
    List<Vias_de_Contacto__c> viasList = TestDataFactory.createViasDeContacto(accList);

    viasList[0].VIA_Id_Externo_Via__c = 'Test Identificador';

    Test.setMock(HttpCalloutMock.class, new INT007TestMock('PJ'));
    Test.startTest();
    INTUtilities_FSC.fillCorrectType(INTUtilitiesTest.valuesContactInfo, viasList[0], 'prova');
    Test.stopTest();
  }

  @isTest
  static void fillCorrectTypeActividadEconomicaDireccionTest() {
    List<Account> accList = TestDataFactory.createPersonAccounts(2);

    Datos_Maestros__c datos = new Datos_Maestros__c();
    datos.Name = 'Test Actividad';
    datos.DM_Direccion__c = 'Test Direccion';
    insert datos;

    accList[0].ACC_Actividad_Economica__c = datos.Id;

    Map<String, String> valuesActEcon = new Map<String, String>{ '[function_ActividadEconomica]' => 'ACC_Actividad_Economica__c' };

    Test.setMock(HttpCalloutMock.class, new INT007TestMock('PJ'));
    Test.startTest();
    INTUtilities_FSC.fillCorrectType(valuesActEcon, accList[0], '[function_ActividadEconomica]');
    Test.stopTest();
  }

  @isTest
  static void fillCorrectTypeActividadEconomicaNameTest() {
    List<Account> accList = TestDataFactory.createPersonAccounts(2);

    Datos_Maestros__c datos = new Datos_Maestros__c();
    datos.Name = 'Test Actividad';
    datos.DM_Direccion__c = 'Test Direccion';
    insert datos;

    accList[0].ACC_Actividad_Economica__c = datos.Id;

    Map<String, String> valuesActEcon = new Map<String, String>{ '[function_otherKey]' => 'ACC_Actividad_Economica__c' };

    Test.setMock(HttpCalloutMock.class, new INT007TestMock('PJ'));
    Test.startTest();
    INTUtilities_FSC.fillCorrectType(valuesActEcon, accList[0], '[function_otherKey]');
    Test.stopTest();
  }

  @isTest
  static void addressStreetAndNumTest() {
    List<Account> accList = TestDataFactory.createPersonAccounts(2);
    List<ContactPointAddress> direcciones = TestDataFactory_FSC.createDirecciones(accList);

    direcciones[0].Street = 'AVENIDA PRINCIPAL 123';
    update direcciones;

    Map<String, String> valuesStreet = new Map<String, String>{ '[function_addressStreet]' => 'Street', '[function_addressNum]' => 'Street' };

    Test.setMock(HttpCalloutMock.class, new INT007TestMock('PJ'));
    Test.startTest();
    INTUtilities_FSC.fillCorrectType(valuesStreet, direcciones[0], '[function_addressStreet] [function_addressNum]');
    Test.stopTest();
  }
}