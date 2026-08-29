/**
 * Name: AccountLookupController
 * Description:
 *  - Búsqueda type-ahead de candidatos y clientes
 *  - Modal fields via FieldSet Participante__c.Lead_Participant_Modal
 *  - Crear Lead candidato participante persona / persona jurídica
 *  - Crear Participante__c anexado al Lead principal por PAR_Candidato__c = Lead.Id
 *  - El participante puede venir desde Lead o Account
 *  - Si el participante viene desde Lead, se crea/reutiliza Account NoCustomer para llenar Participante__c
 *  - Si el participante viene desde Lead, también se guarda en PAR_Participante_Candidato__c
 *  - Catálogo de participantes asociados al Lead principal
 *  - Editar y eliminar participantes
 *  - Mostrar estado del candidato participante sin permitir editarlo desde este componente
 * @lastModified: 2026-05-22
 */
public with sharing class AccountLookupController {
  private static final String PARENT_LEAD_FIELD = 'PAR_Candidato__c';
  private static final String PARTICIPANT_CANDIDATE_FIELD = 'PAR_Participante_Candidato__c';
  private static final String PARENT_LEAD_TEXT_FIELD = 'PAR_leadId__c';
  private static final String ACCOUNT_PARTICIPANT_FIELD = 'Participante__c';
  private static final String NO_CUSTOMER_RECORD_TYPE_DEV_NAME = 'NoCustomer';

  private static final List<String> ACCOUNT_STATUS_FIELDS = new List<String>{
    'ACC_Estado__c',
    'Estado__c',
    'Status__c',
    'FSC_Status__c',
    'FinServ__Status__c'
  };

  private static final String LEAD_TIPO_IDENTIFICACION_FIELD = 'LEA_TipoIdentificacion__c';
  private static final String LEAD_ES_PARTICIPANTE_FIELD = 'LEA_Es_Participante__c';
  private static final String LEAD_SUBESTADO_FIELD = 'LEA_SubEstado__c';
  private static final String LEAD_SUBESTADO_VALIDACION_LEGAL = 'EN VALIDACION POR LEGAL';
  private static final String LEGAL_QUEUE_DEV_NAME = 'FSC_Legal';

  private static final Set<String> LEAD_JURIDICO_RECORD_TYPE_DEV_NAMES = new Set<String>{
    'Candidato_Persona_Juridica',
    'CandidatoPersonaJuridica',
    'Persona_Juridica',
    'PersonaJuridica'
  };

  private static final List<String> LEAD_TIPO_VINCULACION_FIELDS = new List<String>{
    'LEA_Tipo_Vinculacion__c',
    'LEA_Tipo_de_Vinculacion__c',
    'LEA_TipoVinculacion__c',
    'Tipo_de_Vinculacion__c',
    'Tipo_Vinculacion__c'
  };

  private static final List<String> LEAD_TIPO_SECTOR_FIELDS = new List<String>{
    'LEA_Tipo_Sector__c',
    'LEA_Tipo_de_Sector__c',
    'LEA_TipoSector__c',
    'Tipo_de_Sector__c',
    'Tipo_Sector__c'
  };

  public class SearchResultDTO {
    @AuraEnabled public Id id;
    @AuraEnabled public String name;
    @AuraEnabled public String type;
    @AuraEnabled public String typeLabel;

    public SearchResultDTO(Id id, String name, String type, String typeLabel) {
      this.id = id;
      this.name = name;
      this.type = type;
      this.typeLabel = typeLabel;
    }
  }

  public class CandidateDTO {
    @AuraEnabled public Id id;
    @AuraEnabled public String name;

    public CandidateDTO(Lead l) {
      id = l.Id;
      name = l.Name;
    }
  }

  public class AccountDTO {
    @AuraEnabled public Id id;
    @AuraEnabled public String name;

    public AccountDTO(Account a) {
      id = a.Id;
      name = a.Name;
    }
  }

  public class ParticipantDTO {
    @AuraEnabled public Id id;
    @AuraEnabled public Id accountId;
    @AuraEnabled public String accountName;
    @AuraEnabled public String tipoRegistro;
    @AuraEnabled public String estado;
    @AuraEnabled public String tipo;
    @AuraEnabled public String cargo;
    @AuraEnabled public String miembro;
    @AuraEnabled public String tipoAccionista;
    @AuraEnabled public Decimal porcentaje;
    @AuraEnabled public String resultadoValidacion;
    @AuraEnabled public Boolean aplicaFatca;
    @AuraEnabled public Boolean firmanteKyc;
    @AuraEnabled public Boolean firmanteContrato;
    @AuraEnabled public Boolean firmanteAutorizado;
    @AuraEnabled public Boolean representanteLegal;
    @AuraEnabled public String candidateLink;
    @AuraEnabled public String recordLink;
    @AuraEnabled public String recordLinkLabel;

    public ParticipantDTO(Participante__c p, Map<Id, Lead> participantLeadById) {
      id = p.Id;

      Id participantCandidateId = (Id) safeGet(p, PARTICIPANT_CANDIDATE_FIELD);
      Id accountParticipantId = (Id) safeGet(p, ACCOUNT_PARTICIPANT_FIELD);

      if (participantCandidateId != null && participantLeadById != null && participantLeadById.containsKey(participantCandidateId)) {
        accountId = participantCandidateId;
        accountName = participantLeadById.get(participantCandidateId).Name;
        tipoRegistro = 'Candidato';
        estado = participantLeadById.get(participantCandidateId).Status;
        recordLink = '/lightning/r/Lead/' + String.valueOf(participantCandidateId) + '/view';
        recordLinkLabel = 'Ver candidato';
        candidateLink = recordLink;
      } else if (accountParticipantId != null) {
        accountId = accountParticipantId;
        accountName = safeGetStringRelationshipName(p, 'Participante__r');
        tipoRegistro = 'Cliente';
        estado = safeGetFirstStringRelationshipField(p, 'Participante__r', ACCOUNT_STATUS_FIELDS);
        recordLink = '/lightning/r/Account/' + String.valueOf(accountParticipantId) + '/view';
        recordLinkLabel = 'Ver cliente';
        candidateLink = null;
      } else {
        accountId = null;
        accountName = null;
        tipoRegistro = null;
        estado = null;
        candidateLink = null;
        recordLink = null;
        recordLinkLabel = null;
      }

      tipo = (String) safeGet(p, 'PAR_Tipo__c');
      cargo = (String) safeGet(p, 'PAR_Cargo__c');
      miembro = (String) safeGet(p, 'PAR_Miembro__c');

      tipoAccionista = (String) safeGet(p, 'PAR_Tipo_Accionista__c');
      if (String.isBlank(tipoAccionista)) {
        tipoAccionista = (String) safeGet(p, 'PAR_Tipo_Accionista_Miembro__c');
      }

      porcentaje = (Decimal) safeGet(p, 'PAR_Porcentaje__c');
      resultadoValidacion = (String) safeGet(p, 'PAR_Resultado_Validacion__c');

      aplicaFatca = getBooleanSafe(p, 'PAR_Aplica_FATCA__c');
      if (aplicaFatca == null) aplicaFatca = getBooleanSafe(p, 'Aplica_FATCA__c');

      firmanteKyc = getBooleanSafe(p, 'PAR_Firmante_Conozca_Su_Cliente__c');
      if (firmanteKyc == null) firmanteKyc = getBooleanSafe(p, 'VFS_FirmanteConozcaCliente__c');

      firmanteContrato = getBooleanSafe(p, 'PAR_Firmante_Contrato_Autorizado__c');
      if (firmanteContrato == null) firmanteContrato = getBooleanSafe(p, 'VFS_FirmanteDeContratoAutorizado__c');

      firmanteAutorizado = getBooleanSafe(p, 'PAR_Firmante_Autorizado__c');
      if (firmanteAutorizado == null) firmanteAutorizado = getBooleanSafe(p, 'VFS_FirmanteAutorizado__c');

      representanteLegal = getBooleanSafe(p, 'PAR_Representante_Legal__c');
      if (representanteLegal == null) representanteLegal = getBooleanSafe(p, 'VFS_RepresentanteLegal__c');
    }
  }

  public class FieldInfoDTO {
    @AuraEnabled public String apiName;
    @AuraEnabled public String label;
    @AuraEnabled public Boolean required;

    public FieldInfoDTO(String apiName, String label, Boolean required) {
      this.apiName = apiName;
      this.label = label;
      this.required = required;
    }
  }

  public class ParticipantEditDTO {
    @AuraEnabled public Id id;
    @AuraEnabled public Id relatedRecordId;
    @AuraEnabled public String relatedRecordName;
    @AuraEnabled public String relatedRecordType;
    @AuraEnabled public String estado;
    @AuraEnabled public Map<String, Object> fieldValues;
  }

  @AuraEnabled(cacheable=true)
  public static List<SearchResultDTO> searchParticipantsSource(String searchKey) {
    System.debug('searchParticipantsSource | searchKey=' + searchKey);

    List<SearchResultDTO> out = new List<SearchResultDTO>();

    if (String.isBlank(searchKey) || searchKey.trim().length() < 2) {
      return out;
    }

    String likeKey = '%' + String.escapeSingleQuotes(searchKey.trim()) + '%';

    List<Lead> leads = [
      SELECT Id, Name
      FROM Lead
      WHERE IsConverted = false
      AND (
        FirstName LIKE :likeKey
        OR LastName LIKE :likeKey
        OR Company LIKE :likeKey
        OR Name LIKE :likeKey
      )
      ORDER BY Name
      LIMIT 10
    ];

    for (Lead l : leads) {
      out.add(new SearchResultDTO(l.Id, l.Name, 'LEAD', 'Candidato'));
    }

    List<Account> accounts = [
      SELECT Id, Name, RecordType.DeveloperName
      FROM Account
      WHERE Name LIKE :likeKey
      AND RecordType.DeveloperName != :NO_CUSTOMER_RECORD_TYPE_DEV_NAME
      ORDER BY Name
      LIMIT 10
    ];

    for (Account a : accounts) {
      out.add(new SearchResultDTO(a.Id, a.Name, 'ACCOUNT', 'Cliente'));
    }

    return out;
  }

  @AuraEnabled(cacheable=true)
  public static List<CandidateDTO> searchCandidates(String searchKey) {
    System.debug('searchCandidates | searchKey=' + searchKey);

    List<CandidateDTO> out = new List<CandidateDTO>();

    if (String.isBlank(searchKey) || searchKey.trim().length() < 2) {
      return out;
    }

    String likeKey = '%' + String.escapeSingleQuotes(searchKey.trim()) + '%';

    List<Lead> leads = [
      SELECT Id, Name
      FROM Lead
      WHERE IsConverted = false
      AND (
        FirstName LIKE :likeKey
        OR LastName LIKE :likeKey
        OR Company LIKE :likeKey
        OR Name LIKE :likeKey
      )
      ORDER BY Name
      LIMIT 10
    ];

    for (Lead l : leads) {
      out.add(new CandidateDTO(l));
    }

    return out;
  }

  @AuraEnabled(cacheable=true)
  public static List<AccountDTO> searchAccounts(String searchKey) {
    System.debug('searchAccounts | searchKey=' + searchKey);

    List<AccountDTO> out = new List<AccountDTO>();

    if (String.isBlank(searchKey) || searchKey.trim().length() < 2) {
      return out;
    }

    String likeKey = '%' + String.escapeSingleQuotes(searchKey.trim()) + '%';

    List<Account> accs = [
      SELECT Id, Name, RecordType.DeveloperName
      FROM Account
      WHERE Name LIKE :likeKey
      AND RecordType.DeveloperName != :NO_CUSTOMER_RECORD_TYPE_DEV_NAME
      ORDER BY Name
      LIMIT 10
    ];

    for (Account a : accs) {
      out.add(new AccountDTO(a));
    }

    return out;
  }

  @AuraEnabled
  public static Lead createParticipantCandidate(
    String participantType,
    String identificationType,
    String firstName,
    String lastName,
    String companyName,
    String identificationNumber
  ) {
    System.debug(
      'createParticipantCandidate | participantType=' + participantType +
      ' | identificationType=' + identificationType +
      ' | firstName=' + firstName +
      ' | lastName=' + lastName +
      ' | companyName=' + companyName +
      ' | identificationNumber=' + identificationNumber
    );

    try {
      Boolean isCompany = String.valueOf(participantType).trim().toUpperCase() == 'EMPRESA';

      if (String.isBlank(identificationType)) {
        throw new AuraHandledException('Debe ingresar el tipo de identificación.');
      }

      if (isCompany) {
        if (String.isBlank(companyName)) {
          throw new AuraHandledException('Debe ingresar la razón social.');
        }
      } else {
        if (String.isBlank(firstName)) {
          throw new AuraHandledException('Debe ingresar el nombre.');
        }

        if (String.isBlank(lastName)) {
          throw new AuraHandledException('Debe ingresar el apellido.');
        }
      }

      if (String.isBlank(identificationNumber)) {
        throw new AuraHandledException('Debe ingresar el número de identificación.');
      }

      Lead l = new Lead();

      Id rtId = getLeadRecordTypeId(isCompany);
      if (rtId != null) {
        l.RecordTypeId = rtId;
      }

      if (isCompany) {
        l.Company = companyName.trim();
        l.LastName = companyName.trim();
      } else {
        l.FirstName = firstName.trim();
        l.LastName = lastName.trim();
        l.Company = firstName.trim() + ' ' + lastName.trim();
      }

      Map<String, Schema.SObjectField> leadFields = Schema.SObjectType.Lead.fields.getMap();

      putFirstCreateableOrFail(l, leadFields, LEAD_TIPO_VINCULACION_FIELDS, 'SIN DEFINIR', 'Tipo de vinculación');
      putFirstCreateableOrFail(l, leadFields, LEAD_TIPO_SECTOR_FIELDS, 'NO DISPONIBLE', 'Tipo de sector');
      putIfCreateable(l, leadFields, LEAD_TIPO_IDENTIFICACION_FIELD, identificationType.trim());

      if (isCompany || identificationType.trim().toUpperCase() == 'RNC') {
        putIfCreateable(l, leadFields, 'LEA_RNC__c', identificationNumber.trim());
        putIfCreateable(l, leadFields, 'LEA_NumIdentificacion__c', identificationNumber.trim());
      } else {
        putIfCreateable(l, leadFields, 'LEA_NumIdentificacion__c', identificationNumber.trim());
      }

      if (leadFields.containsKey('Status') && leadFields.get('Status').getDescribe().isCreateable()) {
        Schema.DescribeFieldResult statusDescribe = leadFields.get('Status').getDescribe();
        List<Schema.PicklistEntry> statuses = statusDescribe.getPicklistValues();

        if (String.isBlank(l.Status) && statuses != null && !statuses.isEmpty()) {
          for (Schema.PicklistEntry pe : statuses) {
            if (pe.isActive() && pe.isDefaultValue()) {
              l.Status = pe.getValue();
              break;
            }
          }

          if (String.isBlank(l.Status)) {
            for (Schema.PicklistEntry pe : statuses) {
              if (pe.isActive()) {
                l.Status = pe.getValue();
                break;
              }
            }
          }
        }
      }

      insert l;

      System.debug('createParticipantCandidate | Lead creado=' + l.Id);

      return [
        SELECT Id, Name
        FROM Lead
        WHERE Id = :l.Id
        LIMIT 1
      ];

    } catch (AuraHandledException ahe) {
      System.debug(LoggingLevel.WARN, 'AURA ERROR createParticipantCandidate: ' + ahe.getMessage());
      throw ahe;

    } catch (DmlException dmle) {
      System.debug(LoggingLevel.ERROR, 'DML ERROR createParticipantCandidate: ' + dmle.getMessage() + ' | ' + dmle.getStackTraceString());

      String msg = (dmle.getNumDml() > 0) ? dmle.getDmlMessage(0) : dmle.getMessage();

      if (!String.isBlank(msg)) {
        msg = msg.replace('FIELD_CUSTOM_VALIDATION_EXCEPTION,', '').trim();

        if (msg.endsWith(': []')) {
          msg = msg.substring(0, msg.length() - 4).trim();
        }
      } else {
        msg = 'Error de validación al crear el candidato participante.';
      }

      throw new AuraHandledException(msg);

    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, 'ERROR createParticipantCandidate: ' + e.getMessage() + ' | ' + e.getStackTraceString());

      String msg = String.isBlank(e.getMessage())
        ? 'No se pudo crear el candidato participante. Revisa logs.'
        : e.getMessage();

      throw new AuraHandledException(msg);
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<FieldInfoDTO> getParticipantModalFields() {
    System.debug('getParticipantModalFields');

    List<FieldInfoDTO> out = new List<FieldInfoDTO>();

    try {
      Schema.SObjectType sobType = Schema.getGlobalDescribe().get('Participante__c');
      if (sobType == null) {
        return fallbackModalFields();
      }

      Schema.DescribeSObjectResult d = sobType.getDescribe();
      Map<String, Schema.FieldSet> fsMap = d.fieldSets.getMap();

      if (fsMap != null && fsMap.containsKey('Lead_Participant_Modal')) {
        Schema.FieldSet fs = fsMap.get('Lead_Participant_Modal');
        for (Schema.FieldSetMember m : fs.getFields()) {
          out.add(new FieldInfoDTO(m.getFieldPath(), m.getLabel(), m.getRequired()));
        }
        return out;
      }

      return fallbackModalFields();

    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, 'ERROR getParticipantModalFields: ' + e.getMessage());
      return fallbackModalFields();
    }
  }

  private static List<FieldInfoDTO> fallbackModalFields() {
    List<FieldInfoDTO> out = new List<FieldInfoDTO>();
    out.add(new FieldInfoDTO('PAR_Tipo__c', 'Tipo', false));
    out.add(new FieldInfoDTO('PAR_Cargo__c', 'Cargo', false));
    return out;
  }

  @AuraEnabled
  public static Id addParticipant(Id leadId, Id participantRecordId, String participantRecordType, String fieldsJson) {
    System.debug(
      'addParticipant | leadId=' + leadId +
      ' | participantRecordId=' + participantRecordId +
      ' | participantRecordType=' + participantRecordType +
      ' | fieldsJson=' + fieldsJson
    );

    try {
      if (leadId == null || participantRecordId == null || String.isBlank(participantRecordType)) {
        throw new AuraHandledException('Lead principal y registro participante son obligatorios.');
      }

      String normalizedType = participantRecordType.trim().toUpperCase();

      if (normalizedType != 'LEAD' && normalizedType != 'ACCOUNT') {
        throw new AuraHandledException('El tipo de participante debe ser LEAD o ACCOUNT.');
      }

      Map<String, Schema.SObjectField> fMap = Schema.SObjectType.Participante__c.fields.getMap();

      if (!fMap.containsKey(PARENT_LEAD_FIELD)) {
        throw new AuraHandledException('Debe existir el campo ' + PARENT_LEAD_FIELD + ' en Participante__c apuntando al Lead principal.');
      }

      if (!fMap.containsKey(ACCOUNT_PARTICIPANT_FIELD)) {
        throw new AuraHandledException('Debe existir el campo ' + ACCOUNT_PARTICIPANT_FIELD + ' en Participante__c apuntando a Account.');
      }

      if (normalizedType == 'LEAD' && !fMap.containsKey(PARTICIPANT_CANDIDATE_FIELD)) {
        throw new AuraHandledException('Debe existir el campo ' + PARTICIPANT_CANDIDATE_FIELD + ' en Participante__c apuntando al Lead participante.');
      }

      Id accountIdToUse;

      if (normalizedType == 'LEAD') {
        accountIdToUse = getOrCreateNoCustomerAccountFromLead(participantRecordId);
        System.debug('addParticipant | participante tipo Lead, Account NoCustomer usada=' + accountIdToUse);
      } else {
        accountIdToUse = participantRecordId;
        System.debug('addParticipant | participante tipo Account, Account usada=' + accountIdToUse);
      }

      String existingQuery =
        'SELECT Id ' +
        'FROM Participante__c ' +
        'WHERE ' + PARENT_LEAD_FIELD + ' = :leadId ' +
        'AND ' + ACCOUNT_PARTICIPANT_FIELD + ' = :accountIdToUse ' +
        'LIMIT 1';

      System.debug('addParticipant | existingQuery=' + existingQuery);

      List<Participante__c> existing = Database.query(existingQuery);

      if (!existing.isEmpty()) {
        if (normalizedType == 'LEAD') {
          submitLegalApprovalForParticipantLeadIfRequired(participantRecordId);
        }

        ParticipanteTotalsService.recalcularPorCandidatosPrincipales(new Set<Id>{ leadId });

        return existing[0].Id;
      }

      Participante__c p = new Participante__c();

      if (fMap.get(PARENT_LEAD_FIELD).getDescribe().isCreateable()) {
        p.put(PARENT_LEAD_FIELD, leadId);
      }

      if (fMap.get(ACCOUNT_PARTICIPANT_FIELD).getDescribe().isCreateable()) {
        p.put(ACCOUNT_PARTICIPANT_FIELD, accountIdToUse);
      }

      if (normalizedType == 'LEAD' && fMap.get(PARTICIPANT_CANDIDATE_FIELD).getDescribe().isCreateable()) {
        p.put(PARTICIPANT_CANDIDATE_FIELD, participantRecordId);
      }

      if (fMap.containsKey(PARENT_LEAD_TEXT_FIELD) && fMap.get(PARENT_LEAD_TEXT_FIELD).getDescribe().isCreateable()) {
        p.put(PARENT_LEAD_TEXT_FIELD, String.valueOf(leadId));
      }

      applyParticipantFields(p, fieldsJson, true);

      insert p;

      ParticipanteTotalsService.recalcularPorCandidatosPrincipales(new Set<Id>{ leadId });

      if (normalizedType == 'LEAD') {
        submitLegalApprovalForParticipantLeadIfRequired(participantRecordId);
        ParticipanteTotalsService.recalcularPorCandidatosPrincipales(new Set<Id>{ leadId });
      }

      return p.Id;

    } catch (AuraHandledException ahe) {
      System.debug(LoggingLevel.WARN, 'AURA ERROR addParticipant: ' + ahe.getMessage());
      throw ahe;

    } catch (DmlException dmle) {
      System.debug(LoggingLevel.ERROR, 'DML ERROR addParticipant: ' + dmle.getMessage() + ' | ' + dmle.getStackTraceString());

      String msg = (dmle.getNumDml() > 0) ? dmle.getDmlMessage(0) : dmle.getMessage();

      if (!String.isBlank(msg)) {
        msg = msg.replace('FIELD_CUSTOM_VALIDATION_EXCEPTION,', '').trim();

        if (msg.endsWith(': []')) {
          msg = msg.substring(0, msg.length() - 4).trim();
        }
      } else {
        msg = 'Error de validación al guardar el participante.';
      }

      throw new AuraHandledException(msg);

    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, 'ERROR addParticipant: ' + e.getMessage() + ' | ' + e.getStackTraceString());

      String msg = String.isBlank(e.getMessage())
        ? 'No se pudo crear el participante. Revisa logs.'
        : e.getMessage();

      throw new AuraHandledException(msg);
    }
  }

  @AuraEnabled
  public static ParticipantEditDTO getParticipantForEdit(Id participantId) {
    System.debug('getParticipantForEdit | participantId=' + participantId);

    try {
      if (participantId == null) {
        throw new AuraHandledException('Debe indicar el participante a editar.');
      }

      Map<String, Schema.SObjectField> fMap = Schema.SObjectType.Participante__c.fields.getMap();

      List<String> selectFields = new List<String>();
      addFieldIfExists(selectFields, fMap, 'Id');
      addFieldIfExists(selectFields, fMap, ACCOUNT_PARTICIPANT_FIELD);
      addFieldIfExists(selectFields, fMap, PARENT_LEAD_FIELD);
      addFieldIfExists(selectFields, fMap, PARTICIPANT_CANDIDATE_FIELD);
      addFieldIfExists(selectFields, fMap, PARENT_LEAD_TEXT_FIELD);

      if (fMap.containsKey(ACCOUNT_PARTICIPANT_FIELD)) {
        addFieldIfNotExists(selectFields, 'Participante__r.Name');

        Map<String, Schema.SObjectField> accountFields = Schema.SObjectType.Account.fields.getMap();
        for (String statusField : ACCOUNT_STATUS_FIELDS) {
          if (accountFields.containsKey(statusField)) {
            addFieldIfNotExists(selectFields, 'Participante__r.' + statusField);
          }
        }
      }

      List<FieldInfoDTO> modalFields = getParticipantModalFields();

      for (FieldInfoDTO fieldInfo : modalFields) {
        if (fieldInfo == null || String.isBlank(fieldInfo.apiName)) {
          continue;
        }

        if (isBlockedParticipantField(fieldInfo.apiName)) {
          continue;
        }

        addFieldIfExists(selectFields, fMap, fieldInfo.apiName);
      }

      String query =
        'SELECT ' + String.join(selectFields, ',') +
        ' FROM Participante__c' +
        ' WHERE Id = :participantId' +
        ' LIMIT 1';

      System.debug('getParticipantForEdit | query=' + query);

      List<Participante__c> rows = Database.query(query);

      if (rows.isEmpty()) {
        throw new AuraHandledException('No se encontró el participante.');
      }

      Participante__c p = rows[0];

      ParticipantEditDTO dto = new ParticipantEditDTO();
      dto.id = p.Id;
      dto.fieldValues = new Map<String, Object>();

      Id participantCandidateId = (Id) safeGet(p, PARTICIPANT_CANDIDATE_FIELD);
      Id accountId = (Id) safeGet(p, ACCOUNT_PARTICIPANT_FIELD);

      if (participantCandidateId != null) {
        List<Lead> leads = [
          SELECT Id, Name, Status
          FROM Lead
          WHERE Id = :participantCandidateId
          LIMIT 1
        ];

        if (!leads.isEmpty()) {
          dto.relatedRecordId = leads[0].Id;
          dto.relatedRecordName = leads[0].Name;
          dto.relatedRecordType = 'LEAD';
          dto.estado = leads[0].Status;
        }

      } else if (accountId != null) {
        dto.relatedRecordId = accountId;
        dto.relatedRecordName = safeGetStringRelationshipName(p, 'Participante__r');
        dto.relatedRecordType = 'ACCOUNT';
        dto.estado = safeGetFirstStringRelationshipField(p, 'Participante__r', ACCOUNT_STATUS_FIELDS);
      }

      for (FieldInfoDTO fieldInfo : modalFields) {
        if (fieldInfo == null || String.isBlank(fieldInfo.apiName)) {
          continue;
        }

        if (isBlockedParticipantField(fieldInfo.apiName)) {
          continue;
        }

        dto.fieldValues.put(fieldInfo.apiName, safeGet(p, fieldInfo.apiName));
      }

      return dto;

    } catch (AuraHandledException ahe) {
      System.debug(LoggingLevel.WARN, 'AURA ERROR getParticipantForEdit: ' + ahe.getMessage());
      throw ahe;

    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, 'ERROR getParticipantForEdit: ' + e.getMessage() + ' | ' + e.getStackTraceString());
      throw new AuraHandledException('No se pudo cargar el participante para edición. Revisa logs.');
    }
  }

  @AuraEnabled
  public static Id updateParticipant(Id participantId, String fieldsJson) {
    System.debug('updateParticipant | participantId=' + participantId + ' | fieldsJson=' + fieldsJson);

    try {
      if (participantId == null) {
        throw new AuraHandledException('Debe indicar el participante a actualizar.');
      }

      Participante__c p = new Participante__c();
      p.Id = participantId;

      applyParticipantFields(p, fieldsJson, false);

      update p;

      return p.Id;

    } catch (AuraHandledException ahe) {
      System.debug(LoggingLevel.WARN, 'AURA ERROR updateParticipant: ' + ahe.getMessage());
      throw ahe;

    } catch (DmlException dmle) {
      System.debug(LoggingLevel.ERROR, 'DML ERROR updateParticipant: ' + dmle.getMessage() + ' | ' + dmle.getStackTraceString());

      String msg = (dmle.getNumDml() > 0) ? dmle.getDmlMessage(0) : dmle.getMessage();

      if (!String.isBlank(msg)) {
        msg = msg.replace('FIELD_CUSTOM_VALIDATION_EXCEPTION,', '').trim();

        if (msg.endsWith(': []')) {
          msg = msg.substring(0, msg.length() - 4).trim();
        }
      } else {
        msg = 'Error de validación al actualizar el participante.';
      }

      throw new AuraHandledException(msg);

    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, 'ERROR updateParticipant: ' + e.getMessage() + ' | ' + e.getStackTraceString());

      String msg = String.isBlank(e.getMessage())
        ? 'No se pudo actualizar el participante. Revisa logs.'
        : e.getMessage();

      throw new AuraHandledException(msg);
    }
  }

  @AuraEnabled
  public static void deleteParticipant(Id participantId) {
    System.debug('deleteParticipant | participantId=' + participantId);

    try {
      if (participantId == null) {
        throw new AuraHandledException('Debe indicar el participante a eliminar.');
      }

      List<Participante__c> rows = [
        SELECT Id, PAR_Candidato__c
        FROM Participante__c
        WHERE Id = :participantId
        LIMIT 1
      ];

      if (rows.isEmpty()) {
        throw new AuraHandledException('No se encontró el participante a eliminar.');
      }

      Id leadId = rows[0].PAR_Candidato__c;

      delete rows[0];

      if (leadId != null) {
        ParticipanteTotalsService.recalcularPorCandidatosPrincipales(new Set<Id>{ leadId });
      }

    } catch (AuraHandledException ahe) {
      System.debug(LoggingLevel.WARN, 'AURA ERROR deleteParticipant: ' + ahe.getMessage());
      throw ahe;

    } catch (DmlException dmle) {
      System.debug(LoggingLevel.ERROR, 'DML ERROR deleteParticipant: ' + dmle.getMessage() + ' | ' + dmle.getStackTraceString());

      String msg = (dmle.getNumDml() > 0) ? dmle.getDmlMessage(0) : dmle.getMessage();

      if (!String.isBlank(msg)) {
        msg = msg.replace('FIELD_CUSTOM_VALIDATION_EXCEPTION,', '').trim();

        if (msg.endsWith(': []')) {
          msg = msg.substring(0, msg.length() - 4).trim();
        }
      } else {
        msg = 'Error al eliminar el participante.';
      }

      throw new AuraHandledException(msg);

    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, 'ERROR deleteParticipant: ' + e.getMessage() + ' | ' + e.getStackTraceString());

      String msg = String.isBlank(e.getMessage())
        ? 'No se pudo eliminar el participante. Revisa logs.'
        : e.getMessage();

      throw new AuraHandledException(msg);
    }
  }

  @AuraEnabled
  public static List<ParticipantDTO> getParticipants(Id leadId) {
    System.debug('getParticipants | leadId=' + leadId);

    try {
      if (leadId == null) {
        return new List<ParticipantDTO>();
      }

      Map<String, Schema.SObjectField> fMap = Schema.SObjectType.Participante__c.fields.getMap();
      List<String> selectFields = new List<String>();

      addFieldIfExists(selectFields, fMap, 'Id');
      addFieldIfExists(selectFields, fMap, ACCOUNT_PARTICIPANT_FIELD);
      addFieldIfExists(selectFields, fMap, PARENT_LEAD_FIELD);
      addFieldIfExists(selectFields, fMap, PARTICIPANT_CANDIDATE_FIELD);
      addFieldIfExists(selectFields, fMap, PARENT_LEAD_TEXT_FIELD);
      addFieldIfExists(selectFields, fMap, 'PAR_Tipo__c');
      addFieldIfExists(selectFields, fMap, 'PAR_Cargo__c');
      addFieldIfExists(selectFields, fMap, 'PAR_Tipo_Accionista__c');
      addFieldIfExists(selectFields, fMap, 'PAR_Tipo_Accionista_Miembro__c');
      addFieldIfExists(selectFields, fMap, 'PAR_Miembro__c');
      addFieldIfExists(selectFields, fMap, 'PAR_Porcentaje__c');
      addFieldIfExists(selectFields, fMap, 'PAR_Resultado_Validacion__c');
      addFieldIfExists(selectFields, fMap, 'PAR_Aplica_FATCA__c');
      addFieldIfExists(selectFields, fMap, 'Aplica_FATCA__c');
      addFieldIfExists(selectFields, fMap, 'PAR_Firmante_Conozca_Su_Cliente__c');
      addFieldIfExists(selectFields, fMap, 'VFS_FirmanteConozcaCliente__c');
      addFieldIfExists(selectFields, fMap, 'PAR_Firmante_Contrato_Autorizado__c');
      addFieldIfExists(selectFields, fMap, 'VFS_FirmanteDeContratoAutorizado__c');
      addFieldIfExists(selectFields, fMap, 'PAR_Firmante_Autorizado__c');
      addFieldIfExists(selectFields, fMap, 'VFS_FirmanteAutorizado__c');
      addFieldIfExists(selectFields, fMap, 'PAR_Representante_Legal__c');
      addFieldIfExists(selectFields, fMap, 'VFS_RepresentanteLegal__c');

      if (fMap.containsKey(ACCOUNT_PARTICIPANT_FIELD)) {
        addFieldIfNotExists(selectFields, 'Participante__r.Name');

        Map<String, Schema.SObjectField> accountFields = Schema.SObjectType.Account.fields.getMap();
        for (String statusField : ACCOUNT_STATUS_FIELDS) {
          if (accountFields.containsKey(statusField)) {
            addFieldIfNotExists(selectFields, 'Participante__r.' + statusField);
          }
        }
      }

      String query =
        'SELECT ' + String.join(selectFields, ',') +
        ' FROM Participante__c' +
        ' WHERE ' + PARENT_LEAD_FIELD + ' = :leadId' +
        ' ORDER BY CreatedDate DESC' +
        ' LIMIT 200';

      System.debug('getParticipants | query=' + query);

      List<Participante__c> parts = Database.query(query);

      Set<Id> participantCandidateIds = new Set<Id>();
      for (Participante__c p : parts) {
        Id participantCandidateId = (Id) safeGet(p, PARTICIPANT_CANDIDATE_FIELD);
        if (participantCandidateId != null) {
          participantCandidateIds.add(participantCandidateId);
        }
      }

      Map<Id, Lead> participantLeadById = new Map<Id, Lead>();
      if (!participantCandidateIds.isEmpty()) {
        participantLeadById = new Map<Id, Lead>([
          SELECT Id, Name, Status
          FROM Lead
          WHERE Id IN :participantCandidateIds
        ]);
      }

      List<ParticipantDTO> out = new List<ParticipantDTO>();
      for (Participante__c p : parts) {
        out.add(new ParticipantDTO(p, participantLeadById));
      }

      return out;

    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, 'ERROR getParticipants: ' + e.getMessage() + ' | ' + e.getStackTraceString());
      throw new AuraHandledException('Error consultando participantes. Revisa logs.');
    }
  }

  private static void submitLegalApprovalForParticipantLeadIfRequired(Id participantLeadId) {
    System.debug('submitLegalApprovalForParticipantLeadIfRequired | participantLeadId=' + participantLeadId);

    if (participantLeadId == null) {
      return;
    }

    Map<String, Schema.SObjectField> leadFields = Schema.SObjectType.Lead.fields.getMap();

    if (!leadFields.containsKey(LEAD_ES_PARTICIPANTE_FIELD)) {
      throw new AuraHandledException('Debe existir el campo ' + LEAD_ES_PARTICIPANTE_FIELD + ' en Lead.');
    }

    if (!leadFields.containsKey(LEAD_SUBESTADO_FIELD)) {
      throw new AuraHandledException('Debe existir el campo ' + LEAD_SUBESTADO_FIELD + ' en Lead.');
    }

    List<Lead> leads = [
      SELECT Id, Name, OwnerId, RecordType.DeveloperName, RecordType.Name, LEA_Es_Participante__c, LEA_SubEstado__c
      FROM Lead
      WHERE Id = :participantLeadId
      LIMIT 1
    ];

    if (leads.isEmpty()) {
      throw new AuraHandledException('No se encontró el candidato participante.');
    }

    Lead participantLead = leads[0];

    if (!isJuridicalLead(participantLead)) {
      System.debug('submitLegalApprovalForParticipantLeadIfRequired | No aplica porque el Lead no es jurídico. leadId=' + participantLead.Id);
      return;
    }

    List<ProcessInstance> pendingApprovals = [
      SELECT Id
      FROM ProcessInstance
      WHERE TargetObjectId = :participantLead.Id
      AND Status = 'Pending'
      LIMIT 1
    ];

    if (!pendingApprovals.isEmpty()) {
      System.debug('submitLegalApprovalForParticipantLeadIfRequired | Ya existe aprobación pendiente para leadId=' + participantLead.Id);
      return;
    }

    Id legalQueueId = getQueueIdByDeveloperName(LEGAL_QUEUE_DEV_NAME);

    Lead leadToUpdate = new Lead();
    leadToUpdate.Id = participantLead.Id;

    if (leadFields.get(LEAD_ES_PARTICIPANTE_FIELD).getDescribe().isUpdateable()) {
      leadToUpdate.put(LEAD_ES_PARTICIPANTE_FIELD, true);
    }

    if (leadFields.get(LEAD_SUBESTADO_FIELD).getDescribe().isUpdateable()) {
      leadToUpdate.put(LEAD_SUBESTADO_FIELD, LEAD_SUBESTADO_VALIDACION_LEGAL);
    }

    leadToUpdate.OwnerId = legalQueueId;

    update leadToUpdate;

    System.debug(
      'submitLegalApprovalForParticipantLeadIfRequired | Lead actualizado para legal. leadId=' + participantLead.Id +
      ' | ownerId=' + legalQueueId +
      ' | subestado=' + LEAD_SUBESTADO_VALIDACION_LEGAL
    );

    Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
    req.setObjectId(participantLead.Id);
    req.setComments('Participante jurídico enviado a validación por Legal.');

    Approval.ProcessResult result = Approval.process(req);

    if (!result.isSuccess()) {
      throw new AuraHandledException('No se pudo enviar el participante jurídico al proceso de aprobación legal.');
    }

    System.debug('submitLegalApprovalForParticipantLeadIfRequired | Approval enviado correctamente. leadId=' + participantLead.Id);
  }

  private static Boolean isJuridicalLead(Lead participantLead) {
    System.debug('isJuridicalLead | leadId=' + (participantLead != null ? participantLead.Id : null));

    if (participantLead == null || participantLead.RecordType == null) {
      return false;
    }

    String devName = participantLead.RecordType.DeveloperName;
    String rtName = participantLead.RecordType.Name;

    if (!String.isBlank(devName) && LEAD_JURIDICO_RECORD_TYPE_DEV_NAMES.contains(devName)) {
      return true;
    }

    if (!String.isBlank(rtName)) {
      String normalizedName = rtName.toLowerCase();
      if (normalizedName.contains('jur') || normalizedName.contains('empresa')) {
        return true;
      }
    }

    return false;
  }

  private static Id getQueueIdByDeveloperName(String developerName) {
    System.debug('getQueueIdByDeveloperName | developerName=' + developerName);

    if (String.isBlank(developerName)) {
      throw new AuraHandledException('Debe indicar el DeveloperName de la cola.');
    }

    List<Group> queues = [
      SELECT Id, DeveloperName, Name
      FROM Group
      WHERE Type = 'Queue'
      AND DeveloperName = :developerName
      LIMIT 1
    ];

    if (queues.isEmpty()) {
      throw new AuraHandledException('No se encontró la cola ' + developerName + '.');
    }

    return queues[0].Id;
  }

  private static void applyParticipantFields(Participante__c p, String fieldsJson, Boolean isCreate) {
    System.debug('applyParticipantFields | participanteId=' + p.Id + ' | isCreate=' + isCreate + ' | fieldsJson=' + fieldsJson);

    if (p == null || String.isBlank(fieldsJson)) {
      return;
    }

    Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(fieldsJson);

    if (data == null) {
      return;
    }

    Map<String, Schema.SObjectField> fMap = Schema.SObjectType.Participante__c.fields.getMap();

    for (String key : data.keySet()) {
      if (String.isBlank(key)) {
        continue;
      }

      if (isBlockedParticipantField(key)) {
        System.debug(LoggingLevel.WARN, 'Campo ignorado porque no debe editarse desde el componente: ' + key);
        continue;
      }

      if (!fMap.containsKey(key)) {
        System.debug(LoggingLevel.WARN, 'Campo ignorado porque no existe: ' + key);
        continue;
      }

      Schema.DescribeFieldResult dfr = fMap.get(key).getDescribe();

      if (isCreate && !dfr.isCreateable()) {
        System.debug(LoggingLevel.WARN, 'Campo ignorado porque no es creable: ' + key);
        continue;
      }

      if (!isCreate && !dfr.isUpdateable()) {
        System.debug(LoggingLevel.WARN, 'Campo ignorado porque no es editable: ' + key);
        continue;
      }

      Object rawVal = data.get(key);
      Object coerced = rawVal == null ? null : coerceValue(rawVal, dfr, key);

      p.put(key, coerced);
    }
  }

  private static Boolean isBlockedParticipantField(String fieldApi) {
    if (String.isBlank(fieldApi)) {
      return true;
    }

    return fieldApi == ACCOUNT_PARTICIPANT_FIELD ||
      fieldApi == PARENT_LEAD_FIELD ||
      fieldApi == PARENT_LEAD_TEXT_FIELD ||
      fieldApi == PARTICIPANT_CANDIDATE_FIELD ||
      fieldApi == 'Status' ||
      fieldApi == 'Estado__c' ||
      fieldApi == 'PAR_Estado__c';
  }

  private static Id getOrCreateNoCustomerAccountFromLead(Id leadId) {
    System.debug('getOrCreateNoCustomerAccountFromLead | leadId=' + leadId);

    if (leadId == null) {
      throw new AuraHandledException('No se recibió el candidato para crear la cuenta No Cliente.');
    }

    Map<String, Schema.SObjectField> leadFields = Schema.SObjectType.Lead.fields.getMap();

    List<String> leadSelectFields = new List<String>{ 'Id', 'Name', 'FirstName', 'LastName', 'Company' };

    if (leadFields.containsKey('LEA_NumIdentificacion__c')) {
      leadSelectFields.add('LEA_NumIdentificacion__c');
    }

    if (leadFields.containsKey('LEA_RNC__c')) {
      leadSelectFields.add('LEA_RNC__c');
    }

    String leadQuery =
      'SELECT ' + String.join(leadSelectFields, ',') +
      ' FROM Lead WHERE Id = :leadId LIMIT 1';

    System.debug('getOrCreateNoCustomerAccountFromLead | leadQuery=' + leadQuery);

    List<Lead> leads = Database.query(leadQuery);

    if (leads.isEmpty()) {
      throw new AuraHandledException('No se encontró el candidato seleccionado.');
    }

    Lead candidate = leads[0];

    String identificationNumber = getLeadIdentification(candidate);
    String firstName = String.isBlank(candidate.FirstName) ? '' : candidate.FirstName.trim();
    String lastName = String.isBlank(candidate.LastName) ? candidate.Name : candidate.LastName.trim();
    String accountName = buildNoCustomerAccountName(candidate);

    System.debug(
      'getOrCreateNoCustomerAccountFromLead | candidateName=' + candidate.Name +
      ' | identificationNumber=' + identificationNumber +
      ' | accountName=' + accountName
    );

    List<RecordType> recordTypes = [
      SELECT Id, DeveloperName, IsPersonType
      FROM RecordType
      WHERE SObjectType = 'Account'
      AND DeveloperName = :NO_CUSTOMER_RECORD_TYPE_DEV_NAME
      AND IsActive = true
      LIMIT 1
    ];

    if (recordTypes.isEmpty()) {
      throw new AuraHandledException('No se encontró el tipo de registro No Cliente para Account: ' + NO_CUSTOMER_RECORD_TYPE_DEV_NAME);
    }

    RecordType rtNoCliente = recordTypes[0];

    Map<String, Schema.SObjectField> accountFields = Schema.SObjectType.Account.fields.getMap();

    if (!String.isBlank(identificationNumber) && accountFields.containsKey('ACC_NumIdentificacion__c')) {
      List<Account> existingByIdentification = [
        SELECT Id, Name
        FROM Account
        WHERE RecordTypeId = :rtNoCliente.Id
        AND ACC_NumIdentificacion__c = :identificationNumber
        LIMIT 1
      ];

      if (!existingByIdentification.isEmpty()) {
        System.debug('getOrCreateNoCustomerAccountFromLead | Account NoCustomer existente por identificación=' + existingByIdentification[0].Id);
        return existingByIdentification[0].Id;
      }
    }

    List<Account> existingByName = [
      SELECT Id, Name
      FROM Account
      WHERE RecordTypeId = :rtNoCliente.Id
      AND Name = :accountName
      LIMIT 1
    ];

    if (!existingByName.isEmpty()) {
      System.debug('getOrCreateNoCustomerAccountFromLead | Account NoCustomer existente por nombre=' + existingByName[0].Id);
      return existingByName[0].Id;
    }

    Account acc = new Account();
    acc.RecordTypeId = rtNoCliente.Id;

    if (rtNoCliente.IsPersonType) {
      acc.FirstName = String.isBlank(firstName) ? 'Participante' : firstName;
      acc.LastName = String.isBlank(lastName) ? candidate.Name : lastName;
    } else {
      acc.Name = accountName;
    }

    if (
      !String.isBlank(identificationNumber) &&
      accountFields.containsKey('ACC_NumIdentificacion__c') &&
      accountFields.get('ACC_NumIdentificacion__c').getDescribe().isCreateable()
    ) {
      acc.put('ACC_NumIdentificacion__c', identificationNumber);
    } else {
      System.debug(LoggingLevel.WARN, 'getOrCreateNoCustomerAccountFromLead | ACC_NumIdentificacion__c no existe, no es creable o identificación vacía.');
    }

    insert acc;

    System.debug('getOrCreateNoCustomerAccountFromLead | Account NoCustomer creada=' + acc.Id);

    if (!rtNoCliente.IsPersonType) {
      createContactForNoCustomerAccount(acc.Id, candidate, identificationNumber);
    }

    return acc.Id;
  }

  private static void createContactForNoCustomerAccount(Id accountId, Lead candidate, String identificationNumber) {
    System.debug('createContactForNoCustomerAccount | accountId=' + accountId + ' | candidateId=' + candidate.Id);

    try {
      if (accountId == null || candidate == null) {
        return;
      }

      Contact con = new Contact();
      con.AccountId = accountId;
      con.FirstName = String.isBlank(candidate.FirstName) ? null : candidate.FirstName.trim();
      con.LastName = String.isBlank(candidate.LastName) ? candidate.Name : candidate.LastName.trim();

      Map<String, Schema.SObjectField> contactFields = Schema.SObjectType.Contact.fields.getMap();

      if (
        !String.isBlank(identificationNumber) &&
        contactFields.containsKey('CON_NumIdentificacion__c') &&
        contactFields.get('CON_NumIdentificacion__c').getDescribe().isCreateable()
      ) {
        con.put('CON_NumIdentificacion__c', identificationNumber);
      } else {
        System.debug(LoggingLevel.WARN, 'createContactForNoCustomerAccount | CON_NumIdentificacion__c no existe, no es creable o identificación vacía.');
      }

      insert con;

      System.debug('createContactForNoCustomerAccount | Contact creado=' + con.Id);

    } catch (Exception e) {
      System.debug(LoggingLevel.WARN, 'createContactForNoCustomerAccount | No se pudo crear contacto: ' + e.getMessage());
    }
  }

  private static String getLeadIdentification(Lead candidate) {
    System.debug('getLeadIdentification | candidateId=' + (candidate != null ? candidate.Id : null));

    if (candidate == null) {
      return null;
    }

    String identificationNumber = null;

    try {
      Object rncValue = safeGet(candidate, 'LEA_RNC__c');
      if (rncValue != null && !String.isBlank(String.valueOf(rncValue))) {
        identificationNumber = String.valueOf(rncValue).trim();
      }
    } catch (Exception e) {
      System.debug(LoggingLevel.WARN, 'getLeadIdentification | No se pudo leer LEA_RNC__c: ' + e.getMessage());
    }

    if (String.isBlank(identificationNumber)) {
      try {
        Object numValue = safeGet(candidate, 'LEA_NumIdentificacion__c');
        if (numValue != null && !String.isBlank(String.valueOf(numValue))) {
          identificationNumber = String.valueOf(numValue).trim();
        }
      } catch (Exception e) {
        System.debug(LoggingLevel.WARN, 'getLeadIdentification | No se pudo leer LEA_NumIdentificacion__c: ' + e.getMessage());
      }
    }

    return identificationNumber;
  }

  private static String buildNoCustomerAccountName(Lead candidate) {
    System.debug('buildNoCustomerAccountName | candidateId=' + (candidate != null ? candidate.Id : null));

    if (candidate == null) {
      return 'Participante No Cliente';
    }

    if (!String.isBlank(candidate.Company) && candidate.Company != '[Not Provided]') {
      return candidate.Company.trim();
    }

    if (!String.isBlank(candidate.Name)) {
      return candidate.Name.trim();
    }

    String firstName = String.isBlank(candidate.FirstName) ? '' : candidate.FirstName.trim();
    String lastName = String.isBlank(candidate.LastName) ? '' : candidate.LastName.trim();
    String fullName = (firstName + ' ' + lastName).trim();

    return String.isBlank(fullName) ? 'Participante No Cliente' : fullName;
  }

  private static Id getLeadRecordTypeId(Boolean isCompany) {
    System.debug('getLeadRecordTypeId | isCompany=' + isCompany);

    List<RecordType> recordTypes = [
      SELECT Id, DeveloperName, Name
      FROM RecordType
      WHERE SObjectType = 'Lead'
      AND IsActive = true
    ];

    List<String> preferredDeveloperNames = isCompany
      ? new List<String>{ 'Candidato_Persona_Juridica', 'CandidatoPersonaJuridica', 'Persona_Juridica', 'PersonaJuridica' }
      : new List<String>{ 'Candidato_Persona', 'CandidatoPersona', 'Persona_Natural', 'PersonaFisica', 'Persona_Fisica' };

    for (String devName : preferredDeveloperNames) {
      for (RecordType rt : recordTypes) {
        if (rt.DeveloperName == devName) {
          System.debug('getLeadRecordTypeId | seleccionado por DeveloperName=' + rt.DeveloperName + ' | Id=' + rt.Id);
          return rt.Id;
        }
      }
    }

    for (RecordType rt : recordTypes) {
      String rtName = String.valueOf(rt.Name).toLowerCase();

      if (isCompany && (rtName.contains('jur') || rtName.contains('empresa'))) {
        System.debug('getLeadRecordTypeId | seleccionado por Name=' + rt.Name + ' | Id=' + rt.Id);
        return rt.Id;
      }

      if (!isCompany && rtName.contains('persona') && !rtName.contains('jur') && !rtName.contains('empresa')) {
        System.debug('getLeadRecordTypeId | seleccionado por Name=' + rt.Name + ' | Id=' + rt.Id);
        return rt.Id;
      }
    }

    System.debug(LoggingLevel.WARN, 'getLeadRecordTypeId | No se encontró RecordType específico. Se usará el default del usuario.');
    return null;
  }

  private static void putIfCreateable(SObject record, Map<String, Schema.SObjectField> fieldsMap, String fieldApi, Object value) {
    if (record == null || fieldsMap == null || String.isBlank(fieldApi) || value == null) {
      return;
    }

    if (fieldsMap.containsKey(fieldApi) && fieldsMap.get(fieldApi).getDescribe().isCreateable()) {
      record.put(fieldApi, value);
    } else {
      System.debug(LoggingLevel.WARN, 'putIfCreateable | Campo no existe o no es creable: ' + fieldApi);
    }
  }

  private static void putFirstCreateableOrFail(
    SObject record,
    Map<String, Schema.SObjectField> fieldsMap,
    List<String> possibleFieldApis,
    Object value,
    String fieldLabel
  ) {
    System.debug(
      'putFirstCreateableOrFail | fieldLabel=' + fieldLabel +
      ' | value=' + value +
      ' | possibleFieldApis=' + possibleFieldApis
    );

    if (record == null || fieldsMap == null || possibleFieldApis == null || possibleFieldApis.isEmpty()) {
      throw new AuraHandledException('No se pudo validar el campo obligatorio: ' + fieldLabel);
    }

    for (String fieldApi : possibleFieldApis) {
      if (String.isBlank(fieldApi)) {
        continue;
      }

      if (fieldsMap.containsKey(fieldApi)) {
        Schema.DescribeFieldResult dfr = fieldsMap.get(fieldApi).getDescribe();

        if (dfr.isCreateable()) {
          record.put(fieldApi, value);
          System.debug('putFirstCreateableOrFail | Campo asignado: ' + fieldApi + ' = ' + value);
          return;
        }

        System.debug(LoggingLevel.WARN, 'putFirstCreateableOrFail | Campo existe pero no es creable: ' + fieldApi);
      }
    }

    throw new AuraHandledException('No se encontró un campo creable para ' + fieldLabel + '. Revisa el API Name real del campo en Lead.');
  }

  private static void addFieldIfExists(List<String> selectFields, Map<String, Schema.SObjectField> fMap, String apiName) {
    if (selectFields == null || fMap == null || String.isBlank(apiName)) {
      return;
    }

    if ((apiName == 'Id' || fMap.containsKey(apiName)) && !selectFields.contains(apiName)) {
      selectFields.add(apiName);
    }
  }

  private static void addFieldIfNotExists(List<String> selectFields, String apiName) {
    if (selectFields == null || String.isBlank(apiName)) {
      return;
    }

    if (!selectFields.contains(apiName)) {
      selectFields.add(apiName);
    }
  }

  private static Object safeGet(SObject s, String fieldApi) {
    try {
      return (s != null && !String.isBlank(fieldApi)) ? s.get(fieldApi) : null;
    } catch (Exception e) {
      return null;
    }
  }

  private static Boolean getBooleanSafe(SObject s, String fieldApi) {
    try {
      Object val = safeGet(s, fieldApi);
      return val == null ? null : (Boolean) val;
    } catch (Exception e) {
      return null;
    }
  }

  private static String safeGetStringRelationshipName(SObject s, String relationshipName) {
    try {
      SObject rel = s.getSObject(relationshipName);
      return rel != null ? String.valueOf(rel.get('Name')) : null;
    } catch (Exception e) {
      return null;
    }
  }

  private static String safeGetFirstStringRelationshipField(SObject s, String relationshipName, List<String> fieldApis) {
    try {
      if (s == null || String.isBlank(relationshipName) || fieldApis == null || fieldApis.isEmpty()) {
        return null;
      }

      SObject rel = s.getSObject(relationshipName);
      if (rel == null) {
        return null;
      }

      for (String fieldApi : fieldApis) {
        if (String.isBlank(fieldApi)) {
          continue;
        }

        try {
          Object value = rel.get(fieldApi);
          if (value != null && !String.isBlank(String.valueOf(value))) {
            return String.valueOf(value);
          }
        } catch (Exception ignored) {
        }
      }

      return null;

    } catch (Exception e) {
      return null;
    }
  }

  private static Object coerceValue(Object rawVal, Schema.DescribeFieldResult dfr, String apiName) {
    try {
      Schema.DisplayType t = dfr.getType();

      if (t == Schema.DisplayType.Boolean && rawVal instanceof Boolean) return rawVal;
      if ((t == Schema.DisplayType.Double || t == Schema.DisplayType.Currency || t == Schema.DisplayType.Percent) && (rawVal instanceof Decimal)) return rawVal;
      if (t == Schema.DisplayType.Integer && rawVal instanceof Integer) return rawVal;
      if (t == Schema.DisplayType.Date && rawVal instanceof Date) return rawVal;
      if (t == Schema.DisplayType.DateTime && rawVal instanceof Datetime) return rawVal;

      if (t == Schema.DisplayType.Boolean) {
        String s = String.valueOf(rawVal).trim().toLowerCase();
        if (s == 'true' || s == '1' || s == 'yes' || s == 'si') return true;
        if (s == 'false' || s == '0' || s == 'no') return false;
        return null;
      }

      if (t == Schema.DisplayType.Integer) {
        String s = stripNonNumeric(String.valueOf(rawVal).trim());
        if (String.isBlank(s)) return null;
        return Integer.valueOf(s);
      }

      if (t == Schema.DisplayType.Double || t == Schema.DisplayType.Currency || t == Schema.DisplayType.Percent) {
        String s = String.valueOf(rawVal).trim();
        s = s.replace('%', '');
        s = stripNonNumericDecimal(s);
        if (String.isBlank(s)) return null;
        return Decimal.valueOf(s);
      }

      if (t == Schema.DisplayType.Date) {
        String s = String.valueOf(rawVal).trim();
        if (String.isBlank(s)) return null;
        return Date.valueOf(s);
      }

      if (t == Schema.DisplayType.DateTime) {
        String s = String.valueOf(rawVal).trim();
        if (String.isBlank(s)) return null;
        return (Datetime) JSON.deserialize('"' + s.replace('"', '') + '"', Datetime.class);
      }

      return rawVal;

    } catch (Exception ex) {
      System.debug(LoggingLevel.WARN, 'No se pudo convertir ' + apiName + ' | raw=' + String.valueOf(rawVal) + ' | err=' + ex.getMessage());
      return null;
    }
  }

  private static String stripNonNumeric(String s) {
    String out = '';

    for (Integer i = 0; i < s.length(); i++) {
      String c = s.substring(i, i + 1);
      if ((c >= '0' && c <= '9') || c == '-') {
        out += c;
      }
    }

    return out;
  }

  private static String stripNonNumericDecimal(String s) {
    s = s.replace(',', '.');
    String out = '';

    for (Integer i = 0; i < s.length(); i++) {
      String c = s.substring(i, i + 1);
      if ((c >= '0' && c <= '9') || c == '-' || c == '.') {
        out += c;
      }
    }

    return out;
  }
}