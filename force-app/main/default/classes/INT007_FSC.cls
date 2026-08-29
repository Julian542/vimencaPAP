/**
 * @description       :
 * @author            : lplatino@keystoneadvisors.cl
 * @group             :
 * @last modified on  : 29-01-2026
 * @last modified by  : lplatino@keystoneadvisors.cl
 **/
@SuppressWarnings('PMD')
public with sharing class INT007_FSC {
  public class Response extends INTResponse {
    public final List<String> fieldList = new List<String>{ 'CIF' };
    //Account => Pasar a Lead lo de Account
    public Map<String, String> valuesClient = new Map<String, String>{
      '[function_document]' => 'ACC_NumIdentificacion__c',
      '[function_documentType]' => 'ACC_TipoIdentificacion__c',
      '[function_firstName]' => 'FirstName',
      '[function_secondName]' => 'MiddleName',
      '[function_lastName]' => 'LastName',
      '[function_secondlastName]' => 'Suffix',
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
      '[function_MonedaActivos]' => 'ACC_Moneda__c',
      '[function_anualSales]' => 'ACC_Ventas_Ingresos_Anuales__c',
      '[function_numEmployees]' => 'ACC_NumEmpleados__c',
      '[function_lastDocument]' => 'ACC_N_Identificacion_Anterior__c',
      '[function_lastDocumentType]' => 'ACC_Tipo_Identificacion_Anterior__c',
      '[function_typePerson]' => 'ACC_Tipo_Persona_PF__c',
      '[function_actEconSIB]' => 'Actividad_Economica_Name__c',
      '[function_codActEconSIB]' => '',
      '[function_secondNationality]' => 'ACC_Otra_Nacionalidad__c',
      '[function_bornCountry]' => 'ACC_Pais_Nacimiento__c',
      '[function_bornProvince]' => 'ACC_Provincia_Nacimiento__c',
      '[function_bornCityDes]' => 'ACC_Ciudad_de_nacimiento__c',
      '[function_bornCity]' => 'Ciudad_Nacimiento_Codigo__c',
      '[function_vinculationType]' => 'ACC_Tipo_Vinculacion__c',
      '[function_jobPlace]' => 'ACC_Nombre_Puesto__c',
      '[function_Executive]' => 'ACC_Nombre_Ejecutivo__c',
      '[function_attentionPoint]' => 'ACC_NumOficina__c',
      '[function_zone]' => 'ACC_Zona__c',
      '[function_residenciaRepDom]' => 'ACC_Residencia_Rep_Dom__c',
      '[function_otherCountryRes]' => 'ACC_Posee_Resid_Otro_Pais__c',
      '[function_housingtype]' => 'Tipo_de_vivienda__c',
      '[function_depositorType]' => 'ACC_Tipo_Depositante__c',
      '[function_exRelation]' => 'ACC_Relacion_Exterior__c',
      '[function_currency]' => 'ACC_Moneda__c',
      '[function_infoFont]' => 'ACC_Fuente_Informacion__c',
      '[function_codFuenteInfo]' => 'ACC_Fuente_Informacion__c',
      '[function_dateInfo]' => 'ACC_Fecha_Informacion__c',
      '[function_heritage]' => 'ACC_Patrimonio_Num__c',
      '[function_heritageDesc]' => 'ACC_Patrimonio_Desc__c',
      '[function_personPEP]' => 'ACC_Persona_PEP__c',
      '[function_firstNamePEP]' => 'ACC_Primer_Nombre_PEP__c',
      '[function_lastNamePEP]' => 'ACC_Segundo_Nombre_PEP__c',
      '[function_relationPEP]' => 'ACC_Tipo_Relacion_PEP__c',
      '[function_ocupationPEP]' => 'ACC_Ocupacion_PEP__c',
      '[function_instiNamePEP]' => 'ACC_Institucion_Trabajo_PEP__c',
      '[function_addresInstiPEP]' => 'ACC_Direccion_Trabajo_PEP__c',
      '[function_documentTypePEP]' => 'ACC_Tipo_Identif_PEP__c',
      '[function_documentPEP]' => 'ACC_N_Identificacion_PEP__c',
      '[function_formFATCA]' => 'ACC_Aplica_FATCA__c',
      '[function_nameAltFATCA]' => 'ACC_Nombre_FATCA__c',
      '[function_lastNameAltFATCA]' => 'ACC_Apellido_FATCA__c',
      '[function_passaportNumFATCA]' => 'ACC_N_Pasaporte_FATCA__c',
      '[function_dateExpFATCA]' => 'ACC_Fecha_Expiracion_FATCA__c',
      '[function_tinFATCA]' => 'ACC_TIN_FATCA__c',
      '[function_SSNFATCA]' => 'ACC_SSN_FATCA__c',
      '[function_seconfNatioFATCA]' => 'ACC_Nacionalidad_FATCA__c',
      '[function_addressFATCA]' => 'ACC_Direccion_FATCA__c',
      '[function_cityFATCA]' => 'ACC_Ciudad_FATCA__c',
      '[function_stateFATCA]' => 'ACC_Estado_FATCA__c',
      '[function_postalCodeFATCA]' => 'ACC_Codigo_Postal_FATCA__c',
      '[function_phoneFATCA]' => 'ACC_Telefono_FATCA__c',
      '[function_adultAge]' => 'ACC_Es_Mayor_de_Edad__c',
      '[function_officeCode]' => 'ACC_NumOficina__c',
      '[function_employeeCode]' => 'Owner_Alias__c',
      '[function_CIF]' => 'ACC_CIF__c',
      '[function_knowClient]' => 'ACC_Cliente_Conocido__c',
      '[function_isEmployee]' => 'ACC_Es_Empleado_Vimenca__c'
    };
    //ContactPointAddress y campos de ContactPointPhone
    public Map<String, String> valuesAdresses = new Map<String, String>{
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

    // use as example but used another object
    public Map<String, String> valuesContactPoint = new Map<String, String>{
      '[function_contactInfoId]' => 'VIA_Id_Externo_Via__c',
      '[function_ViaIdExternoVia]' => 'VIA_Id_Externo_Via_bk__c',
      '[function_contactInfoIdentifier]' => 'VIA_Identificador__c',
      '[function_contactPrincipal]' => 'isPrimary',
      '[function_contactWayType]' => 'VIA_de_Contacto__c',
      '[function_contactWayCant]' => 'VIA_Numero_Correo__c',
      '[function_contactCompany]' => 'VIA_Telefonica__c',
      '[function_contactSMS]' => 'VIA_Envio_SMS__c',
      '[function_contactExRef]' => 'VIA_Id_Externo_Via__c'
    };

    //FinServ__ContactContactRelation__c y campos de Contact (FinServ__RelatedContact__c)
    public Map<String, String> valuesReferences = new Map<String, String>{
      '[function_referenceType]' => 'CCR_Tipo__c',
      '[function_referenceName]' => '',
      '[function_referencePhone]' => '',
      '[function_referenceAddress]' => '',
      '[function_referenceCountry]' => '',
      '[function_referenceBank]' => 'CCR_Banco__c',
      '[function_referenceAccountType]' => 'CCR_Tipo_de_cuenta__c',
      '[function_referenceCurrency]' => 'CCR_Moneda__c',
      '[function_referenceAccountNum]' => 'CCR_N_de_cuenta__c'
    };
    //Informacion Financiera se mantiene tal cual
    public Map<String, String> finanData = new Map<String, String>{
      '[function_finanDataFont]' => 'INF_Fuente_de_ingresos__c', //Finance Data
      '[function_finanDataRange]' => 'INF_Ingresos__c',
      '[function_finanDataPeriod]' => 'INF_Periodo__c'
    };

    //FinServ__Employment__c
    public Map<String, String> laboral = new Map<String, String>{
      '[function_laboralJob]' => 'EMP_Empleo__c',
      '[function_laboralCompany]' => 'Name',
      '[function_laboralEmployeeType]' => 'EMP_Tipo_de_empleado__c',
      '[function_laboralCompanyTime]' => 'FinServ__LengthOfEmployment__c',
      '[function_laboralPosition]' => 'FinServ__Position__c',
      '[function_laboralFunction]' => 'FinServ__Occupation__c',
      '[function_laboralSalary]' => 'FinServ__AnnualIncome__c',
      '[function_laboralStartDate]' => 'FinServ__StartDate__c',
      '[function_laboralEndDate]' => 'FinServ__EndDate__c',
      '[function_laboralAddress]' => 'FinServ__EmployerAddress__c',
      '[function_laboralPhone]' => 'FinServ__EmployerPhoneNumber__c',
      '[function_laboralMail]' => ''
    };

    //Contacto
    public Map<String, String> conyuge = new Map<String, String>{ //Finance Data
      '[function_partnerSecondLastName]' => 'Suffix',
      '[function_partnerLastName]' => 'LastName',
      '[function_partnerFirstName]' => 'FirstName',
      '[function_partnerSecondName]' => 'MiddleName',
      '[function_partnerBirthDate]' => 'PersonBirthdate',
      '[function_partnerBornCountry]' => 'ACC_Pais_Nacimiento__c',
      '[function_partnerDocument]' => 'ACC_NumIdentificacion__c',
      '[function_partnerDocumentType]' => 'ACC_TipoIdentificacion__c',
      '[function_partnerBornState]' => 'ACC_Provincia_Nacimiento__c',
      '[function_partnerBornCityDes]' => 'ACC_Ciudad_de_nacimiento__c',
      '[function_partnerBornCity]' => 'Ciudad_Nacimiento_Codigo__c'
    };

    //FinServ__Employment__c
    public Map<String, String> conyugeLab = new Map<String, String>{
      '[function_partnerLaboralCompany]' => 'Name',
      '[function_partnerLaboralPosition]' => 'FinServ__Position__c',
      '[function_partnerLaboralFunction]' => 'FinServ__Occupation__c',
      '[function_partnerLaboralSalary]' => 'FinServ__AnnualIncome__c',
      '[function_partnerLaboralAddress]' => 'FinServ__EmployerAddress__c',
      '[function_partnerLaboralPhone]' => 'FinServ__EmployerPhoneNumber__c' //,
      //'[function_partnerLaboralMail]'     => 'Correo_laboral_valor__c'// TODO Eliminado en el file
    };
  }

  public static INT007_FSC.Response parse(String response) {
    INT007_FSC.Response r = new INT007_FSC.Response();

    // Retrieve Result Status.
    r.errorCode = response.substringAfter('<ErrorCode>').substringBefore('</ErrorCode>');
    r.errorText = response.substringAfter('<ErrorText>').substringBefore('</ErrorText>');
    // If status is successful, retrieve fields.
    if (r.errorCode == '000') {
      for (String field : r.fieldList) {
        String textValue = response.substringAfter('<' + field + '>').substringBefore('</' + field + '>');
        textValue = textValue.replace('Yamp;', '&');
        r.values.put(field, textValue);
      }
      System.debug(r);
    }
    return r;
  }

  public static void updateClientCIF(INT007_FSC.Response responseServer, id idClient, String action, Boolean estate) {
    System.debug('Entrando en updateClientCIF');
    Account accountUpdate = [SELECT id, ACC_CIF__c FROM Account WHERE id = :idClient];
    if (estate) {
      System.debug('responseServer.values: ' + responseServer.values);
      if (responseServer.values.get('CIF') != null) {
        accountUpdate.ACC_CIF__c = responseServer.values.get('CIF').toString();
        accountUpdate.Resultado_de_la_Integracion__c = 'Registro creado correctamente en el core.';
      } else {
        accountUpdate.Resultado_de_la_Integracion__c = 'Integracion fallida, no se obtuvo CIF del core. Revisar con un administrador.';
      }
    } else {
      accountUpdate.Resultado_de_la_Integracion__c = 'Integracion fallida Error code: ' + responseServer.errorCode + ' Texo de error : ' + responseServer.errorText;
    }
    try {
      update accountUpdate;
    } catch (DmlException e) {
      System.debug('Exception :: ' + e);
    }
  }

  public static String fillXML(INT007_FSC.Response responseServer, Account client, String frame) {
    String detailClient = frame.substringBetween('<Function>', '</Function>');
    String addressesClient = '<Direcciones>' + frame.substringBetween('<Direcciones>', '</Direcciones>') + '</Direcciones>';
    String valuesContactPoint = '<ViasContacto>' + frame.substringBetween('<ViasContacto>', '</ViasContacto>') + '</ViasContacto>';
    String references = '<Referencias>' + frame.substringBetween('<Referencias>', '</Referencias>') + '</Referencias>';
    String finanData = '<DatosFinancieros>' + frame.substringBetween('<DatosFinancieros>', '</DatosFinancieros>') + '</DatosFinancieros>';
    String laboral = '<HistorialLaboral>' + frame.substringBetween('<HistorialLaboral>', '</HistorialLaboral>') + '</HistorialLaboral>';
    String conyuge = '<Conyuge>' + frame.substringBetween('<Conyuge>', '</Conyuge>') + '</Conyuge>';
    String conyugeLab = '<EmpleoActual>' + frame.substringBetween('<EmpleoActual>', '</EmpleoActual>') + '</EmpleoActual>';
    frame = frame.replace(detailClient, fillDetailClient(responseServer.valuesClient, client, detailClient));
    frame = frame.replace(addressesClient, fillAdressesClient(responseServer.valuesAdresses, client, addressesClient));
    frame = frame.replace(valuesContactPoint, fillContactPointInfo(responseServer.valuesContactPoint, client, valuesContactPoint));
    frame = frame.replace(references, fillReferences(responseServer.valuesReferences, client, references));
    frame = frame.replace(finanData, fillFinanData(responseServer.finanData, client, finanData));
    frame = frame.replace(laboral, fillLaboral(responseServer.laboral, client, laboral));
    frame = frame.replace(conyuge, fillConyuge(responseServer.conyuge, client, conyuge));
    frame = frame.replace(conyugeLab, fillConyugeLab(responseServer.conyugeLab, client, conyugeLab));
    return frame;
  }

  public static String fillDetailClient(Map<String, String> valuesClient, SObject client, String frame) {
    frame = INTUtilities_FSC.fillCorrectType(valuesClient, client, frame);
    return frame;
  }

  public static String fillAdressesClient(Map<String, String> valuesAdresses, SObject client, String frame) {
    String adressesXML = '';
    List<String> fields = new List<String>(ContactPointAddress.SObjectType.getDescribe().fields.getMap().keySet());
    String soql = '' + ' SELECT ' + String.join(fields, ',') + ' FROM ContactPointAddress' + ' WHERE ParentId=\'' + String.escapeSingleQuotes(client.id) + '\'';

    List<ContactPointAddress> adresses = Database.query(soql);

    if (adresses.size() > 0) {
      for (ContactPointAddress cpa : adresses) {
        adressesXML += INTUtilities_FSC.fillCorrectType(valuesAdresses, cpa, frame);
      }
    } else {
      adressesXML = INTUtilities_FSC.fillCorrectType(valuesAdresses, new ContactPointAddress(), frame);
    }
    return adressesXML;
  }

  public static String fillContactPointInfo(Map<String, String> valuesContInfo, SObject client, String frame) {
    List<ContactPointPhone> cpp = [
      SELECT Id, TelephoneNumber, ExtensionNumber, isPrimary, CPP_Tipo__c, CPP_Telefonica__c, AreaCode
      FROM ContactPointPhone
      WHERE ParentId = :client.id
    ];
    List<ContactPointEmail> cpe = [
      SELECT Id, isPrimary, EmailAddress, CPE_Tipo__c
      FROM ContactPointEmail
      WHERE ParentId = :client.id
    ];

    String contactInfoXML = '';

    if (cpp.size() > 0 || cpe.size() > 0) {
      for (ContactPointPhone p : cpp) {
        String contactFrame = frame;
        String idStr = p.Id != null ? String.valueOf(p.Id) : '';
        String num = p.AreaCode != null && p.TelephoneNumber != null ? String.valueOf(p.AreaCode) + String.valueOf(p.TelephoneNumber) : '';
        contactFrame = contactFrame.replace('[function_contactInfoId]', idStr);
        contactFrame = contactFrame.replace('[function_contactExRef]', idStr);
        contactFrame = contactFrame.replace('[function_ViaIdExternoVia]', idStr);
        contactFrame = contactFrame.replace('[function_contactInfoIdentifier]', idStr);
        contactFrame = contactFrame.replace('[function_contactPrincipal]', p.isPrimary == true ? 'Y' : 'N');
        contactFrame = contactFrame.replace('[function_contactWayType]', String.valueOf(p.CPP_Tipo__c != null ? p.CPP_Tipo__c : ''));
        contactFrame = contactFrame.replace('[function_contactWayCant]', num);
        contactFrame = contactFrame.replace('[function_contactCompany]', String.valueOf(p.CPP_Telefonica__c != null ? p.CPP_Telefonica__c : ''));
        contactInfoXML += contactFrame;
      }
      for (ContactPointEmail e : cpe) {
        String contactFrame = frame;
        String idStr = e.Id != null ? String.valueOf(e.Id) : '';
        contactFrame = contactFrame.replace('[function_contactInfoId]', idStr);
        contactFrame = contactFrame.replace('[function_contactExRef]', idStr);
        contactFrame = contactFrame.replace('[function_ViaIdExternoVia]', idStr);
        contactFrame = contactFrame.replace('[function_contactInfoIdentifier]', idStr);
        contactFrame = contactFrame.replace('[function_contactPrincipal]', e.isPrimary == true ? 'Y' : 'N');
        contactFrame = contactFrame.replace('[function_contactWayType]', String.valueOf(e.CPE_Tipo__c != null ? e.CPE_Tipo__c : ''));
        contactFrame = contactFrame.replace('[function_contactWayCant]', String.valueOf(e.EmailAddress != null ? e.EmailAddress : ''));
        contactFrame = contactFrame.replace('[function_contactCompany]', '');
        contactInfoXML += contactFrame;
      }
    } else {
      contactInfoXML = frame;
      contactInfoXML = contactInfoXML.replace('[function_contactInfoId]', '');
      contactInfoXML = contactInfoXML.replace('[function_contactExRef]', '');
      contactInfoXML = contactInfoXML.replace('[function_ViaIdExternoVia]', '');
      contactInfoXML = contactInfoXML.replace('[function_contactPrincipal]', '');
      contactInfoXML = contactInfoXML.replace('[function_contactWayType]', '');
      contactInfoXML = contactInfoXML.replace('[function_contactWayCant]', '');
      contactInfoXML = contactInfoXML.replace('[function_contactCompany]', '');
      contactInfoXML = contactInfoXML.replace('[function_contactInfoIdentifier]', '');
    }

    return contactInfoXML;
  }

  public static String fillReferences(Map<String, String> valuesReferences, SObject client, String frame) {
    List<Contact> contactList = [SELECT Id FROM Contact WHERE AccountId = :client.Id LIMIT 1];
    Id contactId = contactList[0].Id;
    String fillReferencesXML = '';

    List<FinServ__ContactContactRelation__c> references = [
      SELECT CCR_Tipo__c, FinServ__RelatedContact__c, CCR_Banco__c, CCR_Tipo_de_cuenta__c, CCR_Moneda__c, CCR_N_de_cuenta__c
      FROM FinServ__ContactContactRelation__c
      WHERE FinServ__Contact__c = :contactId AND RecordType.DeveloperName = 'Referencia'
    ];

    Set<Id> contactIds = new Set<Id>();
    for (FinServ__ContactContactRelation__c ccr : references) {
      if (ccr.FinServ__RelatedContact__c != null) {
        contactIds.add(ccr.FinServ__RelatedContact__c);
      }
    }

    Map<Id, Contact> contactMap = new Map<Id, Contact>();
    if (!contactIds.isEmpty()) {
      contactMap = new Map<Id, Contact>(
        [
          SELECT Id, Name, Phone, MailingStreet
          FROM Contact
          WHERE Id IN :contactIds
        ]
      );
    }

    if (references.size() > 0) {
      for (FinServ__ContactContactRelation__c ccr : references) {
        Contact relatedContact = contactMap.get(ccr.FinServ__RelatedContact__c);
        String refName = relatedContact != null && relatedContact.Name != null ? relatedContact.Name : '';
        String refPhone = relatedContact != null && relatedContact.Phone != null ? relatedContact.Phone : '';
        String refAddress = relatedContact != null && relatedContact.MailingStreet != null ? relatedContact.MailingStreet : '';

        String refFrame = frame.replace('[function_referenceName]', refName);
        refFrame = refFrame.replace('[function_referencePhone]', refPhone);
        refFrame = refFrame.replace('[function_referenceAddress]', refAddress);
        fillReferencesXML += INTUtilities_FSC.fillCorrectType(valuesReferences, ccr, refFrame);
      }
    } else {
      fillReferencesXML = INTUtilities_FSC.fillCorrectType(valuesReferences, new FinServ__ContactContactRelation__c(), frame);
    }
    return fillReferencesXML;
  }

  public static String fillFinanData(Map<String, String> valuesContInfo, SObject client, String frame) {
    String fillFinanDataXML = '';
    List<String> fields = new List<String>(Informacion_Financiera__c.SObjectType.getDescribe().fields.getMap().keySet());
    String soql = '' + ' SELECT ' + String.join(fields, ',') + ' FROM Informacion_Financiera__c' + ' WHERE INF_Cuenta__c=\'' + String.escapeSingleQuotes(client.id) + '\'';
    List<Informacion_Financiera__c> contactWays = Database.query(soql);
    if (contactWays.size() > 0) {
      for (Informacion_Financiera__c contact : contactWays) {
        fillFinanDataXML += INTUtilities_FSC.fillCorrectType(valuesContInfo, contact, frame);
      }
    } else {
      fillFinanDataXML = INTUtilities_FSC.fillCorrectType(valuesContInfo, new Informacion_Financiera__c(), frame);
    }
    return fillFinanDataXML;
  }

  public static String fillLaboral(Map<String, String> valuesLaboral, SObject client, String frame) {
    String fillLaboralXML = '';
    List<String> fields = new List<String>(FinServ__Employment__c.SObjectType.getDescribe().fields.getMap().keySet());

    String soql = '' + ' SELECT ' + String.join(fields, ',') + ' FROM FinServ__Employment__c' + ' WHERE Cliente__c=\'' + String.escapeSingleQuotes(client.id) + '\'';
    List<FinServ__Employment__c> laboralHis = Database.query(soql);

    if (laboralHis.size() > 0) {
      for (FinServ__Employment__c h : laboralHis) {
        fillLaboralXML += INTUtilities_FSC.fillCorrectType(valuesLaboral, h, frame);
      }
    } else {
      fillLaboralXML = INTUtilities_FSC.fillCorrectType(valuesLaboral, new FinServ__Employment__c(), frame);
    }
    return fillLaboralXML;
  }

  public static String fillConyuge(Map<String, String> valuesConyuge, SObject client, String frame) {
    String fillConyugeXML = '';

    //String contactId = [SELECT PersonContactId FROM Account WHERE Id =: client.Id Limit 1].PersonContactId;
    List<Account> contactList = [SELECT PersonContactId FROM Account WHERE Id = :client.Id LIMIT 1];
    string contactId = contactList.size() > 0 ? contactList[0].PersonContactId : null;
    string conyugeId = null;

    if (contactId != null) {
      List<FinServ__ContactContactRelation__c> accList = [
        SELECT FinServ__RelatedContact__c
        FROM FinServ__ContactContactRelation__c
        WHERE FinServ__Contact__c = :contactId AND FinServ__Role__r.Name = 'Cónyuge'
        LIMIT 1
      ];

      conyugeId = !accList.isEmpty() ? accList[0].FinServ__RelatedContact__c : null;
      if (conyugeId != null) {
        List<String> fields = new List<String>(Account.SObjectType.getDescribe().fields.getMap().keySet());
        String soql = '' + ' SELECT toLabel(ACC_Fuente_Informacion__c) FuenteInformacion, ' + String.join(fields, ',') + ' FROM Account' + ' WHERE id=\'' + String.escapeSingleQuotes(conyugeId) + '\'';

        List<Account> personAccount = Database.query(soql);

        for (Account acc : personAccount) {
          fillConyugeXML = INTUtilities_FSC.fillCorrectType(valuesConyuge, acc, frame);
        }
      }
    }

    if (contactId == null || conyugeId == null) {
      fillConyugeXML = INTUtilities_FSC.fillCorrectType(valuesConyuge, new Account(), frame);
    }

    return fillConyugeXML;
  }

  public static String fillConyugeLab(Map<String, String> valuesConyugeLab, SObject client, String frame) {
    String fillConyugeLabXML = '';
    List<Account> accList = [SELECT PersonContactId FROM Account WHERE Id = :client.Id LIMIT 1];
    string contactId = !accList.isEmpty() ? accList[0].PersonContactId : null;
    string conyugeId = null;

    if (contactId != null) {
      List<FinServ__ContactContactRelation__c> accConList = [
        SELECT FinServ__RelatedContact__c
        FROM FinServ__ContactContactRelation__c
        WHERE FinServ__Contact__c = :contactId AND FinServ__Role__r.Name = 'Cónyuge'
        LIMIT 1
      ];

      conyugeId = !accConList.isEmpty() ? accConList[0].FinServ__RelatedContact__c : null;
      if (conyugeId != null) {
        List<FinServ__Employment__c> hl = [
          SELECT
            FinServ__EmploymentStatus__c,
            Name,
            EMP_Tipo_de_empleado__c,
            FinServ__LengthOfEmployment__c,
            FinServ__Position__c,
            FinServ__Occupation__c,
            FinServ__AnnualIncome__c,
            FinServ__StartDate__c,
            FinServ__EndDate__c,
            FinServ__EmployerAddress__c,
            FinServ__EmployerPhoneNumber__c
          FROM FinServ__Employment__c
          WHERE Cliente__c = :conyugeId
        ];

        if (hl.size() > 0) {
          for (FinServ__Employment__c h : hl) {
            String employmentLength = '';
            if (h.FinServ__LengthOfEmployment__c != null) {
              employmentLength = String.valueOf(h.FinServ__LengthOfEmployment__c);
            }

            String employmentStart = '';
            if (h.FinServ__StartDate__c != null) {
              employmentStart = String.valueOf(h.FinServ__StartDate__c);
            }

            String employmentEnd = '';
            if (h.FinServ__EndDate__c != null) {
              employmentEnd = String.valueOf(h.FinServ__EndDate__c);
            }

            String employmentSalary = '';
            if (h.FinServ__AnnualIncome__c != null) {
              employmentSalary = String.valueOf(h.FinServ__AnnualIncome__c);
            }

            frame = frame.replace('[function_laboralJob]', String.valueOf(h.FinServ__EmploymentStatus__c != null ? h.FinServ__EmploymentStatus__c : ''));
            frame = frame.replace('[function_laboralCompany]', String.valueOf(h.Name != null ? h.Name : ''));
            frame = frame.replace('[function_laboralEmployeeType]', String.valueOf(h.EMP_Tipo_de_empleado__c != null ? h.EMP_Tipo_de_empleado__c : ''));
            frame = frame.replace('[function_laboralCompanyTime]', employmentLength);
            frame = frame.replace('[function_laboralPosition]', String.valueOf(h.FinServ__Position__c != null ? h.FinServ__Position__c : ''));
            frame = frame.replace('[function_laboralFunction]', String.valueOf(h.FinServ__Occupation__c != null ? h.FinServ__Occupation__c : ''));
            frame = frame.replace('[function_laboralSalary]', employmentSalary);
            frame = frame.replace('[function_laboralStartDate]', employmentStart);
            frame = frame.replace('[function_laboralEndDate]', employmentEnd);
            frame = frame.replace('[function_laboralAddress]', String.valueOf(h.FinServ__EmployerAddress__c != null ? h.FinServ__EmployerAddress__c : ''));
            frame = frame.replace('[function_laboralPhone]', String.valueOf(h.FinServ__EmployerPhoneNumber__c != null ? h.FinServ__EmployerPhoneNumber__c : ''));
            frame = frame.replace('[function_laboralMail]', '');
            frame = frame.replace('[function_partnerLaboralCompany]', '');
            frame = frame.replace('[function_partnerLaboralPosition]', '');
            frame = frame.replace('[function_partnerLaboralFunction]', '');
            frame = frame.replace('[function_partnerLaboralSalary]', '');
            frame = frame.replace('[function_partnerLaboralAddress]', '');
            frame = frame.replace('[function_partnerLaboralPhone]', '');
            frame = frame.replace('[function_partnerLaboralMail]', '');
          }
        } else {
          //fillLaboralXML=INTUtilities.fillCorrectType(valuesLaboral,new Historial_laboral__c(),frame);
          frame = frame.replace('[function_laboralJob]', '');
          frame = frame.replace('[function_laboralCompany]', '');
          frame = frame.replace('[function_laboralEmployeeType]', '');
          frame = frame.replace('[function_laboralCompanyTime]', '');
          frame = frame.replace('[function_laboralPosition]', '');
          frame = frame.replace('[function_laboralFunction]', '');
          frame = frame.replace('[function_laboralSalary]', '');
          frame = frame.replace('[function_laboralStartDate]', '');
          frame = frame.replace('[function_laboralEndDate]', '');
          frame = frame.replace('[function_laboralAddress]', '');
          frame = frame.replace('[function_laboralPhone]', '');
          frame = frame.replace('[function_laboralMail]', '');
          frame = frame.replace('[function_partnerLaboralCompany]', '');
          frame = frame.replace('[function_partnerLaboralPosition]', '');
          frame = frame.replace('[function_partnerLaboralFunction]', '');
          frame = frame.replace('[function_partnerLaboralSalary]', '');
          frame = frame.replace('[function_partnerLaboralAddress]', '');
          frame = frame.replace('[function_partnerLaboralPhone]', '');
          frame = frame.replace('[function_partnerLaboralMail]', '');
        }
        return frame;
      } else {
        frame = frame.replace('[function_laboralJob]', '');
        frame = frame.replace('[function_laboralCompany]', '');
        frame = frame.replace('[function_laboralEmployeeType]', '');
        frame = frame.replace('[function_laboralCompanyTime]', '');
        frame = frame.replace('[function_laboralPosition]', '');
        frame = frame.replace('[function_laboralFunction]', '');
        frame = frame.replace('[function_laboralSalary]', '');
        frame = frame.replace('[function_laboralStartDate]', '');
        frame = frame.replace('[function_laboralEndDate]', '');
        frame = frame.replace('[function_laboralAddress]', '');
        frame = frame.replace('[function_laboralPhone]', '');
        frame = frame.replace('[function_laboralMail]', '');
        frame = frame.replace('[function_partnerLaboralCompany]', '');
        frame = frame.replace('[function_partnerLaboralPosition]', '');
        frame = frame.replace('[function_partnerLaboralFunction]', '');
        frame = frame.replace('[function_partnerLaboralSalary]', '');
        frame = frame.replace('[function_partnerLaboralAddress]', '');
        frame = frame.replace('[function_partnerLaboralPhone]', '');
        frame = frame.replace('[function_partnerLaboralMail]', '');
      }
    } else {
      frame = frame.replace('[function_laboralJob]', '');
      frame = frame.replace('[function_laboralCompany]', '');
      frame = frame.replace('[function_laboralEmployeeType]', '');
      frame = frame.replace('[function_laboralCompanyTime]', '');
      frame = frame.replace('[function_laboralPosition]', '');
      frame = frame.replace('[function_laboralFunction]', '');
      frame = frame.replace('[function_laboralSalary]', '');
      frame = frame.replace('[function_laboralStartDate]', '');
      frame = frame.replace('[function_laboralEndDate]', '');
      frame = frame.replace('[function_laboralAddress]', '');
      frame = frame.replace('[function_laboralPhone]', '');
      frame = frame.replace('[function_laboralMail]', '');
      frame = frame.replace('[function_partnerLaboralCompany]', '');
      frame = frame.replace('[function_partnerLaboralPosition]', '');
      frame = frame.replace('[function_partnerLaboralFunction]', '');
      frame = frame.replace('[function_partnerLaboralSalary]', '');
      frame = frame.replace('[function_partnerLaboralAddress]', '');
      frame = frame.replace('[function_partnerLaboralPhone]', '');
      frame = frame.replace('[function_partnerLaboralMail]', '');
    }

    return frame;
  }

  public static void creteClient(Id idClient) {
    createOrModifyPF(idClient, 'C');
  }

  public static void modifiClient(Id idClient, String action) {
    createOrModifyPF(idClient, action);
  }

  @InvocableMethod
  public static void Cliente007_PF(List<Id> recordId) {
    modifiClient(recordId[0], 'M');
    // createOrModifyPF(recordId[0],'M');
  }

  @future(callout=true)
  public static void createOrModifyPF(Id idClient, String action) {
    List<StaticResource> srList = [SELECT id, name, body FROM StaticResource WHERE name = 'INT007_request_frame'];
    List<AuthSession> authList = [
      SELECT id, SourceIP, Users.Name, LoginType, NumSecondsValid, CreatedDate
      FROM AuthSession
      WHERE UsersId = :UserInfo.getUserId()
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];

    List<String> fields = new List<String>(Account.SObjectType.getDescribe().fields.getMap().keySet());
    String soql = '' + ' SELECT toLabel(ACC_Fuente_Informacion__c) FuenteInformacion' + String.join(fields, ',') + ' FROM Account' + ' WHERE id=\'' + String.escapeSingleQuotes(idClient) + '\'';
    Account client = Database.query(soql);

    Account clientActividadEconomica = [
      SELECT Id, ACC_Actividad_Economica__r.DM_Codigo__c
      FROM Account
      WHERE Id = :idClient
      LIMIT 1
    ];

    String codigoActividadEconomica = clientActividadEconomica.ACC_Actividad_Economica__r != null &&
                                      clientActividadEconomica.ACC_Actividad_Economica__r.DM_Codigo__c != null
                                      ? String.valueOf(clientActividadEconomica.ACC_Actividad_Economica__r.DM_Codigo__c)
                                      : '';

    HttpRequest request = new HttpRequest();
    HttpResponse res;
    Http http = new Http();
    System.debug('Peticion INT007_FSC lanzada');
    INT007_FSC.Response responseServer = new INT007_FSC.Response();
    String frame;

    // If parameters are not specified, throw exception.

    // If static resource with the frame to be sent exists, replaces fields and sends it.
    if (!srList.isEmpty()) {
      // Setup request
      request.setEndpoint(Label.EndpointWs);
      request.setMethod('POST');
      request.setTimeout(120000);
      request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
      request.setHeader('SoapAction', 'http://crmintegration.local/CreaPersonaFis');

      frame = srList[0].body.toString();

      // Set WebService credentials.
      frame = frame.replace('[ws_user]', Label.Int_Username);
      //frame = frame.replace('[ws_user]', 'crmuser');
      frame = frame.replace('[ws_password]', Label.Int_Password);
      //frame = frame.replace('[ws_password]', 'Crm!user0001');
      // Set Callout parameters.

      frame = frame.replace('[function_username]', UserInfo.getUserName());
      frame = frame.replace('[function_requestdate]', System.now().format('dd/MM/yyyy'));
      frame = frame.replace('[function_requesttime]', System.now().format('hh:mm:ss'));
      frame = frame.replace('[function_terminal]', authList[0].SourceIp);
      frame = frame.replace('[function_action]', action);
      frame = frame.replace('[function_codActEconSIB]', codigoActividadEconomica);

      frame = fillXML(responseServer, client, frame);

      request.setBody(frame);
      // request.setBody(frame2);
      res = http.send(request);

      try {
        switch on (res.getStatusCode()) {
          when 200 {
            responseServer = parse(res.getBody());
            updateClientCIF(responseServer, idClient, action, true);
          }
          when else {
            responseServer.errorCode = '500';
            responseServer.errorText = 'Error en el servidor';
            updateClientCIF(responseServer, idClient, action, false);
            system.debug(res);
          }
        }
      } catch (Exception e) {
        System.debug('Exception on response parsing');
        System.debug('Error Type :: ' + e);
        updateClientCIF(responseServer, idClient, action, false);
      } finally {
        //Record result and request
        INTLogger.INTLoggerResult result = INTLogger.logCallout('007', 'CreaPersonaFis', request, res);
      }
      responseServer.requestStatusCode = res.getStatusCode();
      responseServer.requestStatus = res.getStatus();
    } else {
      throw new XmlException('Static resource with the request template named "INT007_request_frame" could not be found.');
    }
  }
}