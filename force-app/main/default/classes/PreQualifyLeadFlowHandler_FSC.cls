@SuppressWarnings('PMD')
public with sharing class PreQualifyLeadFlowHandler_FSC {
  private static final string DEVELOPERNAME_METADATA = 'Precalificar';
  private static final Map<Id, RecordType> RECORD_TYPE_CACHE = new Map<Id, RecordType>();

  @TestVisible
  private static Precalificar_Setting__mdt TEST_METADATA;

  @TestVisible
  private static String TEST_RATING;

  @TestVisible
  private static HttpResponse TEST_RESPONSE;

  public static string prequalifyClient(PreQualifyFlowModel body) {
    System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - Inicio');
    System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - Body recibido: ' + JSON.serialize(body));

    if (Test.isRunningTest() && TEST_RATING != null) {
      System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - Retornando TEST_RATING: ' + TEST_RATING);
      return TEST_RATING;
    }

    HttpRequest request = new HttpRequest();
    HttpResponse response;
    String precalificacion;

    Map<String, String> precalificacionMap = new Map<String, String>();
    precalificacionMap.put('BAJO', 'BAJO');
    precalificacionMap.put('MEDIO', 'MEDIO');
    precalificacionMap.put('ALTO', 'ALTO');

    try {
      Http http = new Http();

      System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - Construyendo HttpRequest');
      request = postHttpRequest(DEVELOPERNAME_METADATA);
      request.setBody(JSON.serialize(body));

      System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - Endpoint: ' + request.getEndpoint());
      System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - Method: ' + request.getMethod());
      System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - Header Content-Type: ' + request.getHeader('Content-Type'));
      System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - Header Id tiene valor: ' + !String.isBlank(request.getHeader('Id')));
      System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - Header Sign tiene valor: ' + !String.isBlank(request.getHeader('Sign')));
      System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - Request body enviado: ' + request.getBody());

      if (Test.isRunningTest() && TEST_RESPONSE != null) {
        System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - Usando TEST_RESPONSE');
        response = TEST_RESPONSE;
      } else {
        System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - Ejecutando callout real');
        response = http.send(request);
      }

      System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - Response es nulo: ' + (response == null));

      if (response != null) {
        System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - Response status code: ' + response.getStatusCode());
        System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - Response status: ' + response.getStatus());
        System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - Response body: ' + response.getBody());
      }

      if (response != null && response.getStatusCode() == 200) {
        System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - Status 200 recibido, deserializando respuesta');

        ResponseOK res = (ResponseOK) JSON.deserialize(response.getBody(), ResponseOK.class);

        System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - Response deserializado: ' + JSON.serialize(res));
        System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - res es nulo: ' + (res == null));
        System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - res.data es nulo: ' + (res != null ? res.data == null : true));

        if (res != null && res.data != null) {
          System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - res.data.id: ' + res.data.id);
          System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - res.data.message: ' + res.data.message);

          precalificacion = res.data.message;
        } else {
          System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - No existe res.data.message');
        }
      } else {
        System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - No se deserializa porque el status no es 200');
      }
    } catch (Exception e) {
      System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - Error: ' + e.getMessage());
      System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - Tipo error: ' + e.getTypeName());
      System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - StackTrace: ' + e.getStackTraceString());
    } finally {
      System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - Registrando INTLogger');
      INTLogger.INTLoggerResult result = INTLogger.logCallout('Prequalify', 'PreQualifyLeadFlowHandler_FSC.prequalifyClient', request, response);
      System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - INTLogger result: ' + JSON.serialize(result));
      System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - Nota: INTLogger success no significa que la precalificación fue exitosa');
    }

    System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - Precalificación obtenida antes de validar: ' + precalificacion);
    System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - Valores válidos esperados: ' + precalificacionMap.keySet());

    Boolean precalificacionValida = precalificacion != null && precalificacionMap.containsKey(precalificacion.toUpperCase());

    System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - Precalificación válida: ' + precalificacionValida);

    String resultado = precalificacionValida ? precalificacion.toUpperCase() : null;

    System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - Resultado retornado al Flow clientRating: ' + resultado);
    System.debug('PreQualifyLeadFlowHandler_FSC.prequalifyClient - Fin');

    return resultado;
  }

  public static PreQualifyFlowModel createBody(Lead lead, Participante__c accionista, Participante__c representante) {
    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Inicio');
    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Lead es nulo: ' + (lead == null));
    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Lead Id: ' + (lead != null ? lead.Id : null));
    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Lead Name: ' + (lead != null ? lead.Name : null));
    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Lead RecordTypeId: ' + (lead != null ? lead.RecordTypeId : null));
    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Lead RecordType Name recibido: ' + (lead != null && lead.RecordType != null ? lead.RecordType.Name : null));
    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - LEA_INT_TipoPersona__c: ' + (lead != null ? lead.LEA_INT_TipoPersona__c : null));
    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - LEA_TipoIdentificacion__c: ' + (lead != null ? lead.LEA_TipoIdentificacion__c : null));
    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - LEA_INT_Tipo_de_identificacion__c: ' + (lead != null ? lead.LEA_INT_Tipo_de_identificacion__c : null));
    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - LEA_NumIdentificacion__c: ' + (lead != null ? lead.LEA_NumIdentificacion__c : null));
    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - LEA_RNC__c: ' + (lead != null ? lead.LEA_RNC__c : null));
    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Accionista Id recibido: ' + (accionista != null ? accionista.Id : null));
    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Representante Id recibido: ' + (representante != null ? representante.Id : null));

    PreQualifyFlowModel body = new PreQualifyFlowModel();

    Precalificar_Setting__mdt config = getMetadata(DEVELOPERNAME_METADATA);

    String rtind = config.rtind__c;
    String event = config.Event__c;
    String user = config.User__c;

    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Metadata rtind__c: ' + rtind);
    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Metadata Event__c: ' + event);
    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Metadata User__c: ' + user);

    Map<String, String> headerMap = new Map<String, String>();
    headerMap.put('RTInd', rtind);
    headerMap.put('date', convertToDateFormat2(Date.today()));
    headerMap.put('time', convertToTimeFormat(Datetime.now()));
    headerMap.put('EVENT', event);
    headerMap.put('USER', user);
    body.Header = headerMap;

    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Header generado: ' + JSON.serialize(headerMap));

    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Consultando Lead toLabel. Lead Id: ' + lead.Id);

    Lead candidatoTrama = [
      SELECT
        tolabel(LEA_INT_Canales_a_utilizar__c),
        tolabel(LEA_INT_Nacionalidad__c),
        tolabel(LEA_INT_Otra_Nacionalidad__c),
        tolabel(LEA_INT_Pais_Nacimiento__c),
        tolabel(LEA_INT_Pais_Residencia_Legal__c),
        tolabel(LEA_INT_Tipo_de_identificacion__c),
        tolabel(LEA_INT_Tipo_Estructura_Juridica__c),
        tolabel(LEA_INT_Tipo_Relacion_PEP__c),
        tolabel(LEA_INT_NoIndicaTipoMonedaProdTrans__c),
        tolabel(LEA_INT_Origen_de_los_recursos__c)
      FROM Lead
      WHERE Id = :lead.Id
    ];

    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - candidatoTrama: ' + JSON.serialize(candidatoTrama));
    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - candidatoTrama.LEA_INT_Tipo_de_identificacion__c: ' + candidatoTrama.LEA_INT_Tipo_de_identificacion__c);

    PreQualifyFlowModel.FieldsModel fieldsObj = new PreQualifyFlowModel.FieldsModel();

    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Consultando actividad económica. LEA_Actividad_Economica__c: ' + lead.LEA_Actividad_Economica__c);

    String activityCode = [SELECT DM_Direccion__c FROM Datos_Maestros__c WHERE Id = :lead.LEA_Actividad_Economica__c]?.DM_Direccion__c;

    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - activityCode: ' + activityCode);

    Boolean esPersonaFisica = isPF(lead);

    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Resultado isPF: ' + esPersonaFisica);
    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Tipo identificación usado: ' + candidatoTrama.LEA_INT_Tipo_de_identificacion__c);
    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Número identificación Lead usado para PF: ' + lead.LEA_NumIdentificacion__c);
    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - RNC Lead usado para PJ: ' + lead.LEA_RNC__c);

    fieldsObj.typeIdIdentificationNumber = esPersonaFisica
      ? candidatoTrama.LEA_INT_Tipo_de_identificacion__c + '' + lead.LEA_NumIdentificacion__c
      : candidatoTrama.LEA_INT_Tipo_de_identificacion__c + '' + lead.LEA_RNC__c;

    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - typeIdIdentificationNumber generado: ' + fieldsObj.typeIdIdentificationNumber);

    fieldsObj.handleCash = validarVacio(convertBooleanToString(lead.LEA_DeclaracionSiProyectaManejarEfectivo__c));
    fieldsObj.internationalOperations = validarVacio(convertBooleanToString(lead.LEA_DeclaracionSiManejaOpInternacionales__c));
    fieldsObj.customerCode = validarVacio(lead.LEA_CIF__c);
    fieldsObj.processDate = validarVacio(convertToDateFormat(Date.today()));
    fieldsObj.accountId = lead.Id;

    if (lead.LEA_INT_TipoPersona__c == 'N' && lead.LEA_PersonBirthdate__c != null) {
      fieldsObj.dateOfBirthIncorporation = validarEntero(convertToDateFormat(lead.LEA_PersonBirthdate__c));
    } else if (lead.LEA_INT_TipoPersona__c == 'J' && lead.LEA_Fecha_Fundacion__c != null) {
      fieldsObj.dateOfBirthIncorporation = validarEntero(convertToDateFormat(lead.LEA_Fecha_Fundacion__c));
    }

    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - dateOfBirthIncorporation: ' + fieldsObj.dateOfBirthIncorporation);

    fieldsObj.nationalityConstitution = validarVacio(candidatoTrama.LEA_INT_Nacionalidad__c);
    fieldsObj.branchOpening = validarVacio(lead.LEA_INT_NumOficina__c);
    fieldsObj.executiveCodeOfficial = validarVacio(lead.LEA_Owner_Alias__c);
    fieldsObj.averageMonthlyIncome = validarVacio(lead.LEA_Total_Activos__c);
    fieldsObj.averageMonthlySales = validarVacio(lead.LEA_Ventas_Ingresos_Anuales__c);
    fieldsObj.personTypeNJ = validarVacio(lead.LEA_INT_TipoPersona__c);

    List<String> productos = procesarMultipicklist(lead.LEA_ProductosASolicitar__c);

    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - LEA_ProductosASolicitar__c: ' + lead.LEA_ProductosASolicitar__c);
    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Productos procesados: ' + productos);

    if (productos.size() > 0) {
      fieldsObj.productCode01 = productos.size() > 0 ? productos[0] : '';
      fieldsObj.productCode02 = productos.size() > 1 ? productos[1] : '';
      fieldsObj.productCode03 = productos.size() > 2 ? productos[2] : '';
      fieldsObj.productCode04 = productos.size() > 3 ? productos[3] : '';
      fieldsObj.productCode05 = productos.size() > 4 ? productos[4] : '';
      fieldsObj.productChosenCount = String.valueOf(productos.size());
    }

    fieldsObj.economicActivityCode = validarVacio(activityCode);
    fieldsObj.originOfResources = validarVacio(candidatoTrama.LEA_INT_Origen_de_los_recursos__c);

    Double monthlyVolume = lead.LEA_IndicarVolMensualEstimadoTransaccion__c != null ? lead.LEA_IndicarVolMensualEstimadoTransaccion__c : 0.0;
    fieldsObj.monthlyVolume = validarDecimal(String.valueOf(monthlyVolume.format()));
    fieldsObj.monthlyTrx = validarVacio(lead.LEA_Rango_de_Transacciones_estimadas__c);

    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - economicActivityCode: ' + fieldsObj.economicActivityCode);
    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - originOfResources: ' + fieldsObj.originOfResources);
    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - monthlyVolume: ' + fieldsObj.monthlyVolume);
    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - monthlyTrx: ' + fieldsObj.monthlyTrx);

    List<String> servicios = procesarMultipicklist(lead.LEA_Servicios_a_solicitar__c);

    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - LEA_Servicios_a_solicitar__c: ' + lead.LEA_Servicios_a_solicitar__c);
    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Servicios procesados: ' + servicios);

    if (servicios.size() > 0) {
      fieldsObj.serviceCode01 = servicios.size() > 0 ? servicios[0] : '';
      fieldsObj.serviceCode02 = servicios.size() > 1 ? servicios[1] : '';
      fieldsObj.serviceCode03 = servicios.size() > 2 ? servicios[2] : '';
      fieldsObj.serviceCode04 = servicios.size() > 3 ? servicios[3] : '';
      fieldsObj.serviceCode05 = servicios.size() > 4 ? servicios[4] : '';
    }

    List<String> canales = procesarMultipicklist(candidatoTrama.LEA_INT_Canales_a_utilizar__c);

    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Canales desde candidatoTrama: ' + canales);
    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - LEA_INT_Canales_a_utilizar__c original Lead: ' + lead.LEA_INT_Canales_a_utilizar__c);

    if ((canales == null || canales.isEmpty()) && !String.isBlank(lead.LEA_INT_Canales_a_utilizar__c)) {
      canales = procesarMultipicklist(lead.LEA_INT_Canales_a_utilizar__c);
      System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Canales usando fallback Lead: ' + canales);
    }

    if (canales != null && canales.size() > 0) {
      fieldsObj.channel01 = canales.size() > 0 ? canales[0] : '';
      fieldsObj.channel02 = canales.size() > 1 ? canales[1] : '';
      fieldsObj.channel03 = canales.size() > 2 ? canales[2] : '';
      fieldsObj.channel04 = canales.size() > 3 ? canales[3] : '';
      fieldsObj.channel05 = canales.size() > 4 ? canales[4] : '';
    }

    fieldsObj.beneficiaryType = validarVacio(lead.LEA_Tipo_beneficio_final__c);
    fieldsObj.dignitaryRelationship = validarVacio(lead.LEA_Relacion_de_dignatarios__c);
    fieldsObj.relationshipWithHighRisk = validarVacio(String.valueOf(lead.LEA_Relacion_ent_alto_riesgo__c));
    fieldsObj.currentType = validarVacio(candidatoTrama.LEA_INT_NoIndicaTipoMonedaProdTrans__c);

    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Campos comunes generados: ' + JSON.serialize(fieldsObj));

    if (esPersonaFisica) {
      System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Entró a bloque Persona Física');

      fieldsObj.firstName = validarVacio(lead.firstName);
      fieldsObj.middleName = validarVacio(lead.middleName);
      fieldsObj.firstSurname = validarVacio(lead.LastName);
      fieldsObj.secondSurname = validarVacio(lead.Suffix);
      fieldsObj.hasNationalityConstitution2 = validarVacio(String.valueOf(lead.LEA_Posee_Otra_Nacionalidad__c));
      fieldsObj.nationalityConstitution2 = validarVacio(candidatoTrama.LEA_INT_Otra_Nacionalidad__c);
      fieldsObj.countryOfBirth = validarVacio(candidatoTrama.LEA_INT_Pais_Nacimiento__c);
      fieldsObj.occupation = validarVacio(lead.LEA_Ocupacion__c);
      fieldsObj.countryOfResidence = validarVacio(candidatoTrama.LEA_INT_Pais_Residencia_Legal__c);
      fieldsObj.pepPublicServer = validarVacio(lead.LEA_Persona_PEP__c);
      fieldsObj.pepFamily = validarVacio(convertBooleanToString(lead.LEA_Familiar_PEP__c));
      fieldsObj.pepCollaborator = validarVacio(convertBooleanToString(lead.LEA_Colaborador_de_PEP__c));
      fieldsObj.pepRelationType = validarVacio(candidatoTrama.LEA_INT_Tipo_Relacion_PEP__c);

      System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Campos Persona Física generados: ' + JSON.serialize(fieldsObj));
    } else {
      System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Entró a bloque Persona Jurídica');

      if (accionista == null) {
        System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Accionista vino nulo, se instancia vacío');
        accionista = new Participante__c();
      }

      if (representante == null) {
        System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Representante vino nulo, se instancia vacío');
        representante = new Participante__c();
      }

      Participante__c accionistaTrama;

      if (accionista.Id != null) {
        System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Consultando accionistaTrama. Id: ' + accionista.Id);

        accionistaTrama = [
          SELECT tolabel(PAR_Candidato__r.LEA_INT_Tipo_de_identificacion__c), tolabel(PAR_Candidato__r.LEA_INT_Nacionalidad__c)
          FROM Participante__c
          WHERE Id = :accionista.Id
        ];
      } else {
        accionistaTrama = new Participante__c();
      }

      Participante__c repLegalTrama;

      if (representante.Id != null) {
        System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Consultando repLegalTrama. Id: ' + representante.Id);

        repLegalTrama = [
          SELECT tolabel(PAR_Candidato__r.LEA_INT_Tipo_de_identificacion__c), tolabel(PAR_Candidato__r.LEA_INT_Nacionalidad__c)
          FROM Participante__c
          WHERE Id = :representante.Id
        ];
      } else {
        repLegalTrama = new Participante__c();
      }

      System.debug('PreQualifyLeadFlowHandler_FSC.createBody - accionistaTrama: ' + JSON.serialize(accionistaTrama));
      System.debug('PreQualifyLeadFlowHandler_FSC.createBody - repLegalTrama: ' + JSON.serialize(repLegalTrama));

      fieldsObj.personNameBusinessName = validarVacio(Lead.LEA_Nombre_Corto_Comercial__c);
      fieldsObj.shareholder01 = validarVacio(accionista.PAR_Nombres__c);
      fieldsObj.typeIdIdentificationShareholder1 = validarVacio(accionistaTrama.PAR_Candidato__r.LEA_INT_Tipo_de_identificacion__c) + validarVacio(accionista.PAR_Numero_Identificacion__c);
      fieldsObj.nationalityShareholder1 = validarVacio(accionistaTrama.PAR_Candidato__r.LEA_INT_Nacionalidad__c);
      fieldsObj.dateOfBirthShareholder1 = validarEntero(String.valueOf(accionista.PAR_FechaNacimiento__c));
      fieldsObj.participationPercentageShareholder1 = validarVacio(String.valueOf((Integer) accionista.PAR_Porcentaje__c));
      fieldsObj.firstNameShareholder1 = validarVacio(accionista.PAR_PrimerNombre__c);
      fieldsObj.middleNameShareholder1 = validarVacio(accionista.PAR_SegundoNombre__c);
      fieldsObj.firstSurnameShareholder1 = validarVacio(accionista.PAR_PrimerApellido__c);
      fieldsObj.secondSurnameShareholder1 = validarVacio(accionista.PAR_SegundoApellido__c);
      fieldsObj.representative01 = validarVacio(representante.PAR_Nombres__c);
      fieldsObj.typeIdIdentificationRepresentative1 = validarVacio(repLegalTrama.PAR_Candidato__r.LEA_INT_Tipo_de_identificacion__c) + validarVacio(representante.PAR_Numero_Identificacion__c);
      fieldsObj.nationalityRepresentative1 = validarVacio(repLegalTrama.PAR_Candidato__r.LEA_INT_Nacionalidad__c);
      fieldsObj.dateOfBirthRepresentative1 = validarEntero(String.valueOf(representante.PAR_FechaNacimiento__c));
      fieldsObj.firstNameRepresentative1 = validarVacio(representante.PAR_PrimerNombre__c);
      fieldsObj.middleNameRepresentative1 = validarVacio(representante.PAR_SegundoNombre__c);
      fieldsObj.firstSurnameRepresentative1 = validarVacio(representante.PAR_PrimerApellido__c);
      fieldsObj.secondSurnameRepresentative1 = validarVacio(representante.PAR_SegundoApellido__c);
      fieldsObj.legalStructureType = validarVacio(candidatoTrama.LEA_INT_Tipo_Estructura_Juridica__c);

      System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Campos Persona Jurídica generados: ' + JSON.serialize(fieldsObj));
    }

    body.Fields = fieldsObj;

    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Body final generado: ' + JSON.serialize(body));
    System.debug('PreQualifyLeadFlowHandler_FSC.createBody - Fin');

    return body;
  }

  private static Precalificar_Setting__mdt getMetadata(String nombreServicio) {
    System.debug('PreQualifyLeadFlowHandler_FSC.getMetadata - Inicio');
    System.debug('PreQualifyLeadFlowHandler_FSC.getMetadata - Nombre servicio: ' + nombreServicio);

    if (Test.isRunningTest() && TEST_METADATA != null) {
      System.debug('PreQualifyLeadFlowHandler_FSC.getMetadata - Retornando TEST_METADATA');
      return TEST_METADATA;
    }

    Boolean isSandbox = [SELECT IsSandbox FROM Organization].IsSandbox;

    System.debug('PreQualifyLeadFlowHandler_FSC.getMetadata - IsSandbox: ' + isSandbox);

    Precalificar_Setting__mdt config = [
      SELECT Named_Credential__c, Metodo__c, Sign__c, rtind__c, Id__c, Event__c, User__c
      FROM Precalificar_Setting__mdt
      WHERE DeveloperName = :nombreServicio AND Is_sandbox__c = :isSandbox
      LIMIT 1
    ];

    System.debug('PreQualifyLeadFlowHandler_FSC.getMetadata - Metadata encontrada. Named Credential: ' + config.Named_Credential__c);
    System.debug('PreQualifyLeadFlowHandler_FSC.getMetadata - Método: ' + config.Metodo__c);
    System.debug('PreQualifyLeadFlowHandler_FSC.getMetadata - rtind__c: ' + config.rtind__c);
    System.debug('PreQualifyLeadFlowHandler_FSC.getMetadata - Event__c: ' + config.Event__c);
    System.debug('PreQualifyLeadFlowHandler_FSC.getMetadata - User__c: ' + config.User__c);
    System.debug('PreQualifyLeadFlowHandler_FSC.getMetadata - Id__c tiene valor: ' + !String.isBlank(config.Id__c));
    System.debug('PreQualifyLeadFlowHandler_FSC.getMetadata - Sign__c tiene valor: ' + !String.isBlank(config.Sign__c));

    return config;
  }

  @TestVisible
  static void setTestMetadata(Precalificar_Setting__mdt metadata) {
    TEST_METADATA = metadata;
  }

  public static HttpRequest postHttpRequest(String nombreServicio) {
    System.debug('PreQualifyLeadFlowHandler_FSC.postHttpRequest - Inicio');
    System.debug('PreQualifyLeadFlowHandler_FSC.postHttpRequest - Nombre servicio: ' + nombreServicio);

    Precalificar_Setting__mdt config = getMetadata(nombreServicio);

    String namedCredential = config.Named_Credential__c;
    String metodo = config.Metodo__c;
    String Id = config.Id__c;
    String Sign = config.Sign__c;

    System.debug('PreQualifyLeadFlowHandler_FSC.postHttpRequest - Named Credential: ' + namedCredential);
    System.debug('PreQualifyLeadFlowHandler_FSC.postHttpRequest - Método metadata: ' + metodo);
    System.debug('PreQualifyLeadFlowHandler_FSC.postHttpRequest - Header Id tiene valor: ' + !String.isBlank(Id));
    System.debug('PreQualifyLeadFlowHandler_FSC.postHttpRequest - Header Sign tiene valor: ' + !String.isBlank(Sign));

    HttpRequest req = new HttpRequest();

    if (Test.isRunningTest()) {
      req.setEndpoint('https://mock.test' + metodo);
    } else {
      req.setEndpoint('callout:' + namedCredential + metodo);
    }

    req.setMethod('POST');
    req.setTimeout(120000);
    req.setHeader('Content-Type', 'application/json');
    req.setHeader('Sign', Sign);
    req.setHeader('Id', Id);

    System.debug('PreQualifyLeadFlowHandler_FSC.postHttpRequest - Endpoint final: ' + req.getEndpoint());
    System.debug('PreQualifyLeadFlowHandler_FSC.postHttpRequest - Fin');

    return req;
  }

  private static String convertBooleanToString(Boolean value) {
    return (value) ? 'true' : 'false';
  }

  private static String convertToDateFormat(Date d) {
    if (d != null) {
      String month = String.valueOf(d.month()).leftPad(2, '0');
      String day = String.valueOf(d.day()).leftPad(2, '0');
      return d.year() + month + day;
    }
    return null;
  }

  private static String convertToDateFormat2(Date d) {
    if (d != null) {
      String month = String.valueOf(d.month()).leftPad(2, '0');
      String day = String.valueOf(d.day()).leftPad(2, '0');
      return day + month + d.year();
    }
    return null;
  }

  public static String convertToTimeFormat(Datetime dt) {
    if (dt != null) {
      String hours = String.valueOf(dt.hour()).leftPad(2, '0');
      String minutes = String.valueOf(dt.minute()).leftPad(2, '0');
      return hours + minutes;
    }
    return null;
  }

  private static List<String> procesarMultipicklist(String cadena) {
    List<String> values = new List<String>();
    if (cadena != null) {
      values.addAll(cadena.split(';'));
    }
    return values;
  }

  private static string validarVacio(string value) {
    return value != null ? value : '';
  }

  private static string validarVacio(decimal value) {
    return String.valueOf(value) != null ? value.toPlainString() : '';
  }

  private static string validarDecimal(string value) {
    return value != null ? value : '0.0';
  }

  private static string validarEntero(string value) {
    return value != null ? value : '0';
  }

  private static Boolean isPF(Lead l) {
    System.debug('PreQualifyLeadFlowHandler_FSC.isPF - Inicio');
    System.debug('PreQualifyLeadFlowHandler_FSC.isPF - Lead es nulo: ' + (l == null));

    if (l == null) {
      System.debug('PreQualifyLeadFlowHandler_FSC.isPF - Retorna false porque Lead es nulo');
      return false;
    }

    String recordtypeName = resolveRecordTypeName(l);

    System.debug('PreQualifyLeadFlowHandler_FSC.isPF - RecordType Name resuelto: ' + recordtypeName);

    Boolean result = String.isNotBlank(recordtypeName) && recordtypeName.equalsIgnoreCase('Candidato Persona Física');

    System.debug('PreQualifyLeadFlowHandler_FSC.isPF - Resultado: ' + result);

    return result;
  }

  private static String resolveRecordTypeName(Lead l) {
    System.debug('PreQualifyLeadFlowHandler_FSC.resolveRecordTypeName - Inicio');
    System.debug('PreQualifyLeadFlowHandler_FSC.resolveRecordTypeName - Lead Id: ' + (l != null ? l.Id : null));
    System.debug('PreQualifyLeadFlowHandler_FSC.resolveRecordTypeName - RecordTypeId: ' + (l != null ? l.RecordTypeId : null));
    System.debug('PreQualifyLeadFlowHandler_FSC.resolveRecordTypeName - RecordType recibido: ' + (l != null && l.RecordType != null ? l.RecordType.Name : null));

    if (l.RecordType != null && String.isNotBlank(l.RecordType.Name)) {
      System.debug('PreQualifyLeadFlowHandler_FSC.resolveRecordTypeName - Retorna RecordType.Name recibido: ' + l.RecordType.Name);
      return l.RecordType.Name;
    }

    if (String.isNotBlank(l.RecordTypeId)) {
      if (!RECORD_TYPE_CACHE.containsKey(l.RecordTypeId)) {
        System.debug('PreQualifyLeadFlowHandler_FSC.resolveRecordTypeName - Consultando RecordType por Id: ' + l.RecordTypeId);
        RECORD_TYPE_CACHE.put(l.RecordTypeId, [SELECT Name FROM RecordType WHERE Id = :l.RecordTypeId LIMIT 1]);
      }

      RecordType rt = RECORD_TYPE_CACHE.get(l.RecordTypeId);
      System.debug('PreQualifyLeadFlowHandler_FSC.resolveRecordTypeName - RecordType desde cache/query: ' + (rt != null ? rt.Name : null));

      return rt != null ? rt.Name : null;
    }

    if (String.isNotBlank(l.Id)) {
      System.debug('PreQualifyLeadFlowHandler_FSC.resolveRecordTypeName - Consultando Lead fresco por Id: ' + l.Id);

      Lead fresh = [SELECT RecordType.Name, RecordTypeId FROM Lead WHERE Id = :l.Id LIMIT 1];

      if (fresh.RecordType != null) {
        RECORD_TYPE_CACHE.put(fresh.RecordTypeId, fresh.RecordType);
        System.debug('PreQualifyLeadFlowHandler_FSC.resolveRecordTypeName - RecordType desde Lead fresco: ' + fresh.RecordType.Name);
        return fresh.RecordType.Name;
      }
    }

    System.debug('PreQualifyLeadFlowHandler_FSC.resolveRecordTypeName - No se pudo resolver RecordType Name');
    return null;
  }

  public class ResponseData {
    public string id;
    public string message;
  }

  public class ResponseOK {
    public string status;
    public ResponseData data;
  }
}