@SuppressWarnings('PMD')
public with sharing class INT008_FSC {
  public class Response extends INTResponse {
    public final List<String> fieldList = new List<String>{ 'CIF' };
    public Map<String, String> valuesClient = new Map<String, String>{
      '[function_razonSocial]' => 'Name',
      '[function_nombreComercial]' => 'ACC_Nombre_Corto_Comercial__c',
      '[function_RNC]' => 'ACC_RNC__c',
      '[function_tipoOrganizacion]' => 'ACC_Tipo_Organizacion__c',
      '[function_fechaFundacion]' => 'ACC_Fecha_Fundacion__c',
      '[function_fechaCierreFiscal]' => 'ACC_Fecha_Cierre_Fiscal__c',
      '[function_Nacionalidad]' => 'ACC_Nacionalidad__c',
      '[function_GrupoGestion]' => '',
      '[function_BICSWIFT]' => '',
      '[function_Industria]' => 'Industry',
      '[function_ActividadEconomica]' => '',
      '[function_CodigoCIIU]' => '',
      '[function_TipoActividad]' => 'ACC_Tipo_Actividad__c',
      '[function_TipoSector]' => 'ACC_Tipo_Sector__c',
      '[function_TipoPersona]' => 'ACC_Codigo_Persona_PJ__c',
      //'[function_TipoCliente]' => 'ACC_Codigo_Persona_PJ__c',//OBLIGATORIO
      '[function_TipoCliente]' => 'ACC_Tipo_Cliente_PJ__c',
      '[function_FuenteInfo]' => 'ACC_Fuente_Informacion__c',
      '[function_FechaInfo]' => 'ACC_Fecha_Informacion__c',
      '[function_RelacionExt]' => 'ACC_Relacion_Exterior__c',
      '[function_TipoDepositante]' => 'ACC_Tipo_Depositante__c',
      '[function_TipoVinculacion]' => 'ACC_Tipo_Vinculacion__c',
      '[function_Condicion]' => 'ACC_Condicion__c',
      '[function_Estado]' => 'ACC_Estado__c',
      '[function_Subestado]' => 'ACC_SubEstado__c',
      '[function_Segmento]' => 'ACC_Segmento__c',
      '[function_UltimaSegmentacion]' => 'ACC_Ultima_Segmentacion__c',
      '[function_PuntoAtencion]' => 'ACC_NumOficina__c',
      '[function_Ejecutivo]' => 'ACC_Nombre_Ejecutivo__c',
      '[function_Zona]' => 'ACC_Zona__c',
      '[function_PuestoTrabajo]' => 'ACC_Nombre_Puesto__c',
      '[function_CategoriaRiesgo]' => 'ACC_Categoria_Riesgo_Cliente__c',
      '[function_TotalActivos]' => 'ACC_Total_Activos__c',
      '[function_MonedaActivos]' => 'ACC_Moneda__c',
      '[function_VolumenVentasAnual]' => 'ACC_Volumen_Ventas_Anual__c',
      '[function_Moneda]' => 'ACC_Moneda__c',
      '[function_NumEmpleados]' => 'ACC_NumEmpleados__c',
      '[function_anualExpenses]' => 'Gastos_anuales__c',
      '[function_heritage]' => 'ACC_Patrimonio_Num__c',
      '[function_heritageDesc]' => 'ACC_Patrimonio_Desc__c',
      '[function_InternetBanking]' => 'ACC_Internet_Banking__c',
      '[function_CuentaNomina]' => 'ACC_Cuenta_Nomina__c',
      '[function_ObjetoNegocio]' => 'ACC_Objeto_Negocio__c',
      '[function_CiudadFATCA]' => 'ACC_Ciudad_FATCA__c',
      '[function_CPFATCA]' => 'ACC_Codigo_Postal_FATCA__c',
      '[function_DireccionFATCA]' => 'ACC_Direccion_FATCA__c',
      '[function_EstadoFATCA]' => 'ACC_Estado_FATCA__c',
      '[function_TelefonoFATCA]' => 'ACC_Telefono_FATCA__c',
      '[function_InstitucionFinancieraFATCA]' => 'ACC_Es_Institucion_Financiera__c',
      '[function_TipoAcuerdoFATCA]' => 'ACC_Tipo_Acuerdo__c',
      '[function_NumAcuerdoFATCA]' => 'ACC_Num_Acuerdo__c',
      '[function_AcuerdoIRSFATCA]' => 'ACC_Posee_Acuerdo_IRS__c',
      '[function_SegmentoFATCA]' => 'ACC_Segmento_FATCA__c',
      '[function_TipoIngresoFATCA]' => 'ACC_Tipo_Ingreso__c',
      '[function_GIINFATCA]' => 'ACC_GIIN__c',
      '[function_TipoEmpresaFATCA]' => 'ACC_Tipo_Empresa__c',
      '[function_CodEmpleado]' => '', //Revisar por alicia
      '[function_CodOficina]' => '',
      '[function_CIF]' => 'ACC_CIF__c',
      '[function_ClienteConocido]' => 'ACC_Cliente_Conocido__c'
    };
    public Map<String, String> valuesAdresses = new Map<String, String>{
      '[function_addressId]' => 'Id',
      '[function_addressExternalIdBk]' => 'Id',
      '[function_addressIdentifier]' => 'Id',
      '[function_addressPrimary]' => 'isPrimary',
      '[function_addressType]' => 'AddressType',
      '[function_addressStreet]' => 'Street',
      '[function_addressNum]' => 'Street',
      '[function_addressBuilding]' => '',
      '[function_addressNumFloor]' => 'CPA_N_Apartamento__c',
      '[function_addressCountry]' => 'Country',
      '[function_addressProvince]' => 'State',
      '[function_addressMunicipality]' => 'CPA_Municipio__c',
      '[function_addressMunicipalDistrict]' => 'CPA_Distrito__c',
      '[function_addressSector]' => 'CPA_Sector__c',
      '[function_addressPostalCode]' => 'PostalCode',
      '[function_addressCityStatePC]' => 'City',
      '[function_addressPhone]' => '',
      '[function_addressPhoneEx]' => '',
      '[function_addressExtraPhone1]' => '',
      '[function_addressExtraPhone2]' => ''
    };
    public Map<String, String> valuesContactInfo = new Map<String, String>{
      '[function_contactInfoId]' => 'VIA_Id_Externo_Via__c',
      '[function_ViaIdExternoVia]' => 'VIA_Id_Externo_Via_bk__c',
      '[function_contactInfoIdentifier]' => 'VIA_Identificador__c',
      '[function_contactPrincipal]' => 'VIA_Principal__c',
      '[function_contactWayType]' => 'VIA_de_Contacto__c',
      '[function_contactWayCant]' => 'VIA_Numero_Correo__c',
      '[function_contactCompany]' => 'VIA_Telefonica__c',
      '[function_contactExRef]' => 'VIA_Id_Externo_Via__c'
    };
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

    public Map<String, String> valuesProducts = new Map<String, String>{ '[function_prodServName]' => 'Name' };

    public Map<String, String> valuesLargestCust = new Map<String, String>{
      '[function_largestCustName]' => 'Name',
      '[function_largestCustDocumentType]' => 'Tipo_de_identificacion__c',
      '[function_largestCustDocument]' => 'N_de_Identificacion__c'
    };
    public Map<String, String> valuesSupplier = new Map<String, String>{
      '[function_supplierName]' => 'Name',
      '[function_supplierDocumentType]' => 'Tipo_de_identificaci_n__c',
      '[function_supplierDocument]' => 'N_de_Identificacion__c'
    };
    public Map<String, String> valuesaffiliate = new Map<String, String>{
      '[function_affiliateName]' => 'Name',
      '[function_affiliateDocument]' => 'RNC__c',
      '[function_affiliateCountry]' => 'Pais_donde_opera__c',
      '[function_affiliateEcoGroup]' => 'Grupo_economico__c',
      '[function_affiliateFinGroup]' => 'Grupo_financiero__c'
    };
    public Map<String, String> valuesParticipantCcr = new Map<String, String>{
      '[function_participantType]' => 'CCR_Tipo__c',
      '[function_participantRole]' => 'CCR_Cargo__c',
      '[function_participantPosition]' => 'CCR_Cargo__c',
      '[function_participantPorcentage]' => 'CCR_Porcentaje__c'
    };

    public Map<String, String> valuesParticipantPFAcc = new Map<String, String>{
      '[function_participantDocumentType]' => 'ACC_TipoIdentificacion__c',
      '[function_participantDocument]' => 'ACC_NumIdentificacion__c',
      '[function_participantName]' => 'FirstName',
      '[function_participantLastName]' => 'LastName',
      '[function_participantSecondLastName]' => 'MiddleName',
      '[function_participantFatca]' => 'ACC_Aplica_FATCA__c',
      '[function_participantValidation]' => 'ACC_Resultado_Validacion__c'
    };

    public Map<String, String> valuesParticipantPJAcc = new Map<String, String>{
      '[function_participantDocumentType]' => 'ACC_TipoIdentificacion__c',
      '[function_participantDocument]' => 'ACC_RNC__c',
      '[function_participantName]' => 'Name',
      '[function_participantLastName]' => '',
      '[function_participantSecondLastName]' => '',
      '[function_participantFatca]' => 'ACC_Aplica_FATCA__c',
      '[function_participantValidation]' => 'ACC_Resultado_Validacion__c'
    };

    public Map<String, String> valuesAuthorized = new Map<String, String>{
      '[function_authorizedDocumentType]' => 'AUT_Tipoidentificacion__c',
      '[function_authorizedDocument]' => 'AUT_NumIdentificacion__c',
      '[function_authorizedName]' => 'AUT_Nombres__c',
      '[function_authorizedLastName]' => 'AUT_PrimerApellido__c',
      '[function_authorizedSecondLastName]' => 'AUT_SegundoApellido__c',
      '[function_authorizedPosition]' => 'ACC_CON_Puesto_Posicion__c',
      '[function_authorizedPhone]' => 'ACC_CON_Telefono__c'
    };
  }

  public static INT008_FSC.Response parse(String response) {
    INT008_FSC.Response r = new INT008_FSC.Response();

    r.errorCode = response.substringAfter('<ErrorCode>').substringBefore('</ErrorCode>');
    r.errorText = response.substringAfter('<ErrorText>').substringBefore('</ErrorText>');

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

  public static void updateClientCIF(INT008_FSC.Response responseServer, id idClient, String action, Boolean state) {
    Account accountUpdate = [SELECT id, ACC_CIF__c FROM Account WHERE id = :idClient];
    if (state) {
      System.debug('repsonseServer.values.get(CIF): ' + responseServer.values.get('CIF'));
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

  public static String fillXML(INT008_FSC.Response responseServer, Account client, String frame) {
    String detailClient = frame.substringBetween('<Function>', '</Function>');
    String addressesClient = '<Direcciones>' + frame.substringBetween('<Direcciones>', '</Direcciones>') + '</Direcciones>';
    String contactInfo = '<ViasContacto>' + frame.substringBetween('<ViasContacto>', '</ViasContacto>') + '</ViasContacto>';
    String references = '<Referencias>' + frame.substringBetween('<Referencias>', '</Referencias>') + '</Referencias>';
    String products = '<ProductosServicios>' + frame.substringBetween('<ProductosServicios>', '</ProductosServicios>') + '</ProductosServicios>';
    String customer = '<ClientesPrincipales>' + frame.substringBetween('<ClientesPrincipales>', '</ClientesPrincipales>') + '</ClientesPrincipales>';
    String supplier = '<Proveedores>' + frame.substringBetween('<Proveedores>', '</Proveedores>') + '</Proveedores>';
    String affiliate = '<Filiales>' + frame.substringBetween('<Filiales>', '</Filiales>') + '</Filiales>';
    String partcipant = '<Participantes>' + frame.substringBetween('<Participantes>', '</Participantes>') + '</Participantes>';
    String authorized = '<Autorizados>' + frame.substringBetween('<Autorizados>', '</Autorizados>') + '</Autorizados>';
    frame = frame.replace(detailClient, fillDetailClient(responseServer.valuesClient, client, detailClient));
    frame = frame.replace(addressesClient, fillAdressesClient(responseServer.valuesAdresses, client, addressesClient));
    frame = frame.replace(contactInfo, fillContactInfo(responseServer.valuesContactInfo, client, contactInfo));
    frame = frame.replace(references, fillReferences(responseServer.valuesReferences, client, references));
    frame = frame.replace(products, fillProducts(responseServer.valuesProducts, client, products));
    frame = frame.replace(customer, fillLargestCust(responseServer.valuesLargestCust, client, customer));
    frame = frame.replace(supplier, fillSupplier(responseServer.valuesSupplier, client, supplier));
    frame = frame.replace(affiliate, fillAffiliate(responseServer.valuesaffiliate, client, affiliate));
    frame = frame.replace(partcipant, fillParticipant(responseServer.valuesParticipantCcr, responseServer.valuesParticipantPFAcc, responseServer.valuesParticipantPJAcc, client, partcipant));
    frame = frame.replace(authorized, fillAuthorized(responseServer.valuesAuthorized, client, authorized));
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
      for (ContactPointAddress adress : adresses) {
        adressesXML += INTUtilities_FSC.fillCorrectType(valuesAdresses, adress, frame);
      }
    } else {
      adressesXML = INTUtilities_FSC.fillCorrectType(valuesAdresses, new ContactPointAddress(), frame);
    }

    return adressesXML;
  }

  public static String fillContactInfo(Map<String, String> valuesContInfo, SObject client, String frame) {
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

  public static String fillProducts(Map<String, String> valuesProducts, SObject client, String frame) {
    String productsXML = '';
    List<String> fields = new List<String>(Productos_y_Servicios__c.SObjectType.getDescribe().fields.getMap().keySet());
    String soql = '' + ' SELECT ' + String.join(fields, ',') + ' FROM Productos_y_Servicios__c' + ' WHERE Cliente__c=\'' + String.escapeSingleQuotes(client.id) + '\'';
    List<Productos_y_Servicios__c> products = Database.query(soql);
    if (products.size() > 0) {
      for (Productos_y_Servicios__c product : products) {
        productsXML += INTUtilities_FSC.fillCorrectType(valuesProducts, product, frame);
      }
    } else {
      productsXML = INTUtilities_FSC.fillCorrectType(valuesProducts, new Productos_y_Servicios__c(), frame);
    }
    return productsXML;
  }

  public static String fillLargestCust(Map<String, String> valuesCustomer, SObject client, String frame) {
    String customerXML = '';
    List<String> fields = new List<String>(Cliente_Principal__c.SObjectType.getDescribe().fields.getMap().keySet());
    String soql = '' + ' SELECT ' + String.join(fields, ',') + ' FROM Cliente_Principal__c' + ' WHERE Cliente__c=\'' + String.escapeSingleQuotes(client.id) + '\'';
    List<Cliente_Principal__c> customers = Database.query(soql);
    if (customers.size() > 0) {
      for (Cliente_Principal__c customer : customers) {
        customerXML += INTUtilities_FSC.fillCorrectType(valuesCustomer, customer, frame);
      }
    } else {
      customerXML = INTUtilities_FSC.fillCorrectType(valuesCustomer, new Cliente_Principal__c(), frame);
    }
    return customerXML;
  }

  public static String fillSupplier(Map<String, String> valuesSupplier, SObject client, String frame) {
    String suppliersXML = '';
    List<String> fields = new List<String>(Principal_Proveedor__c.SObjectType.getDescribe().fields.getMap().keySet());
    String soql = '' + ' SELECT ' + String.join(fields, ',') + ' FROM Principal_Proveedor__c' + ' WHERE Cliente__c=\'' + String.escapeSingleQuotes(client.id) + '\'';
    List<Principal_Proveedor__c> suppliers = Database.query(soql);
    if (suppliers.size() > 0) {
      for (Principal_Proveedor__c supplier : suppliers) {
        suppliersXML += INTUtilities_FSC.fillCorrectType(valuesSupplier, supplier, frame);
      }
    } else {
      suppliersXML = INTUtilities_FSC.fillCorrectType(valuesSupplier, new Principal_Proveedor__c(), frame);
    }
    return suppliersXML;
  }

  public static String fillAffiliate(Map<String, String> valuesAffiliate, SObject client, String frame) {
    String affiliatesXML = '';
    List<String> fields = new List<String>(Empresa_Filial__c.SObjectType.getDescribe().fields.getMap().keySet());
    String soql = '' + ' SELECT ' + String.join(fields, ',') + ' FROM Empresa_Filial__c' + ' WHERE Cliente__c=\'' + String.escapeSingleQuotes(client.id) + '\'';
    List<Empresa_Filial__c> affiliates = Database.query(soql);
    if (affiliates.size() > 0) {
      for (Empresa_Filial__c affiliate : affiliates) {
        affiliatesXML += INTUtilities_FSC.fillCorrectType(valuesAffiliate, affiliate, frame);
      }
    } else {
      affiliatesXML = INTUtilities_FSC.fillCorrectType(valuesAffiliate, new Empresa_Filial__c(), frame);
    }
    return affiliatesXML;
  }

  public static String fillParticipant(Map<String, String> valuesParticipantCcr, Map<String, String> valuesParticipantPFAcc, Map<String, String> valuesParticipantPJAcc, SObject client, String frame) {
    String participantXML = '';
    List<FinServ__ContactContactRelation__c> ccrs = [
      SELECT Id, CCR_Tipo__c, CCR_Cargo__c, CCR_Porcentaje__c, FinServ__Contact__r.AccountId, FinServ__RelatedContact__r.AccountId
      FROM FinServ__ContactContactRelation__c
      WHERE RecordType.Name = 'Participante' AND FinServ__Contact__r.AccountId = :client.Id
    ];
    if (ccrs.size() > 0) {
      for (FinServ__ContactContactRelation__c ccr : ccrs) {
        Account acc = [
          SELECT Id, ACC_TipoIdentificacion__c, ACC_NumIdentificacion__c, ACC_RNC__c, Name, FirstName, MiddleName, LastName, ACC_Aplica_FATCA__c, ACC_Resultado_Validacion__c, RecordType.Name
          FROM Account
          WHERE Id = :ccr.FinServ__RelatedContact__r.AccountId
          LIMIT 1
        ];
        String participantFrame = INTUtilities_FSC.fillCorrectType(valuesParticipantCcr, ccr, frame);
        if (acc.RecordType.Name == 'PersonAccount') {
          participantFrame = INTUtilities_FSC.fillCorrectType(valuesParticipantPFAcc, acc, participantFrame);
        } else {
          participantFrame = INTUtilities_FSC.fillCorrectType(valuesParticipantPJAcc, acc, participantFrame);
        }
        participantXML += participantFrame;
      }
    } else {
      String emptyFrame = INTUtilities_FSC.fillCorrectType(valuesParticipantCcr, new FinServ__ContactContactRelation__c(), frame);
      participantXML = INTUtilities_FSC.fillCorrectType(valuesParticipantPFAcc, new Account(), emptyFrame);
    }
    return participantXML;
  }

  public static String fillAuthorized(Map<String, String> valuesAuthorized, SObject client, String frame) {
    String authorithedXML = '';
    List<String> fields = new List<String>(AccountContactRelation.SObjectType.getDescribe().fields.getMap().keySet());
    String soql = '' + ' SELECT ' + String.join(fields, ',') + ' FROM AccountContactRelation' + ' WHERE AccountId=\'' + String.escapeSingleQuotes(client.id) + '\' AND ACC_CON_Autorizado__c = true';
    List<AccountContactRelation> authorizeds = Database.query(soql);
    if (authorizeds.size() > 0) {
      for (AccountContactRelation authorized : authorizeds) {
        authorithedXML += INTUtilities_FSC.fillCorrectType(valuesAuthorized, authorized, frame);
      }
    } else {
      authorithedXML = INTUtilities_FSC.fillCorrectType(valuesAuthorized, new AccountContactRelation(), frame);
    }
    return authorithedXML;
  }

  public static void creteClientJ(Id idClient) {
    createOrModifyPF(idClient, 'C');
  }

  @InvocableMethod
  public static void Cliente008_PJ(List<Id> recordId) {
    createOrModifyPF(recordId[0], 'M');
  }

  @future(callout=true)
  public static void createOrModifyPF(Id idClient, String action) {
    List<StaticResource> srList = [SELECT id, name, body FROM StaticResource WHERE name = 'INT008_request_frame'];
    List<AuthSession> authList = [SELECT id, SourceIP, Users.Name, LoginType, NumSecondsValid, CreatedDate FROM AuthSession WHERE UsersId = :UserInfo.getUserId() ORDER BY CreatedDate DESC LIMIT 1];

    List<String> fields = new List<String>(Account.SObjectType.getDescribe().fields.getMap().keySet());
    String soql = '' + ' SELECT ' + String.join(fields, ',') + ' FROM Account' + ' WHERE id=\'' + String.escapeSingleQuotes(idClient) + '\'';
    Account client = Database.query(soql);

    Account clientActividadEconomica = [
      SELECT Id, ACC_Actividad_Economica__r.DM_Codigo__c
      FROM Account
      WHERE Id = :idClient
      LIMIT 1
    ];

    String codigoActividadEconomica = clientActividadEconomica.ACC_Actividad_Economica__r != null &&
                                      clientActividadEconomica.ACC_Actividad_Economica__r.DM_Codigo__c != null
                                      ? clientActividadEconomica.ACC_Actividad_Economica__r.DM_Codigo__c
                                      : '';

    HttpRequest request = new HttpRequest();
    HttpResponse res;
    Http http = new Http();
    INT008_FSC.Response responseServer = new INT008_FSC.Response();
    String frame;

    if (!srList.isEmpty()) {
      request.setEndpoint(Label.EndpointWs);
      request.setMethod('POST');
      request.setTimeout(120000);
      request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
      request.setHeader('SoapAction', 'http://crmintegration.local/CreaPersonaJur');

      frame = srList[0].body.toString();

      frame = frame.replace('[ws_user]', Label.Int_Username);
      frame = frame.replace('[ws_password]', Label.Int_Password);

      frame = frame.replace('[function_username]', UserInfo.getUserName());
      frame = frame.replace('[function_requestdate]', System.now().format('dd/MM/yyyy'));
      frame = frame.replace('[function_requesttime]', System.now().format('hh:mm:ss'));
      frame = frame.replace('[function_terminal]', authList[0].SourceIp);
      frame = frame.replace('[function_action]', action);
      frame = frame.replace('[function_ActividadEconomica]', codigoActividadEconomica);

      frame = fillXML(responseServer, client, frame);

      System.debug('frame= ' + frame);
      request.setBody(frame);
      res = http.send(request);

      try {
        switch on (res.getStatusCode()) {
          when 200 {
            responseServer = parse(res.getBody());
            updateClientCIF(responseServer, idClient, action, true);
          }
          when else {
            System.debug('Error: ' + res.getStatusCode() + ' ' + res.getStatus());
            System.debug(res);
            updateClientCIF(responseServer, idClient, action, false);
          }
        }
      } catch (Exception e) {
        System.debug('Error Type :: ' + e);
        System.debug('Error: Message: ' + e.getMessage() + ', Cause: ' + e.getCause() + ', LineNumber: ' + e.getLineNumber());
        updateClientCIF(responseServer, idClient, action, false);
      } finally {
        INTLogger.INTLoggerResult result = INTLogger.logCallout('008', 'CreaPersonaJur', request, res);
      }
      responseServer.requestStatusCode = res.getStatusCode();
      responseServer.requestStatus = res.getStatus();
    } else {
      throw new XmlException('Static resource with the request template named "INT008_FSC_request_frame" could not be found.');
    }
  }
}