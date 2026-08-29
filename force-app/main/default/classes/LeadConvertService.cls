/**
 * Name: LeadConvertService
 * Description:
 *  Servicio Apex para convertir Leads SIN usar el wizard estándar.
 *  - Ejecuta Database.convertLead()
 *  - Si falla por Validation Rules (u otras reglas), devuelve el mensaje NATIVO
 *    para que el LWC lo muestre en pantalla.
 *  - Usa Savepoint/Rollback para no dejar Account pre-creada si la conversión falla.
 *
 *  No crea Opportunity.
 *
 * Last modified: 2026-01-19
 * Autor: Jhonny Peroza
 */
@SuppressWarnings('PMD')
public with sharing class LeadConvertService {
  public class ConvertResponse {
    @AuraEnabled
    public Boolean success;
    @AuraEnabled
    public String message;

    @AuraEnabled
    public Id leadId;
    @AuraEnabled
    public Id accountId;
    @AuraEnabled
    public Id contactId;
    @AuraEnabled
    public Id opportunityId;

    @AuraEnabled
    public String errorType;
    @AuraEnabled
    public String errorDetail;
  }

  @AuraEnabled
  public static ConvertResponse convertOne(Id leadId) {
    System.debug('on LeadConvertService.convertOne(leadId=' + leadId + ')');

    ConvertResponse resp = new ConvertResponse();
    resp.leadId = leadId;

    Savepoint sp;

    if (leadId == null) {
      resp.success = false;
      resp.message = 'leadId es requerido.';
      return resp;
    }

    sp = Database.setSavepoint();

    Lead l = [
      SELECT Id, IsConverted, RecordType.DeveloperName, FirstName, LastName, Company
      FROM Lead
      WHERE Id = :leadId
      LIMIT 1
    ];

    if (l.IsConverted) {
      resp.success = true;
      resp.message = 'El Lead ya está convertido.';
      return resp;
    }

    LeadStatus ls = [
      SELECT MasterLabel
      FROM LeadStatus
      WHERE IsConverted = TRUE
      LIMIT 1
    ];
    String convertedStatus = ls.MasterLabel;

    String leadRt = (l.RecordType != null) ? l.RecordType.DeveloperName : null;

    Boolean isNatural = (leadRt == 'Candidato_Persona_Natural');
    Boolean isJuridica = (leadRt == 'Candidato_Persona_Juridica');

    if (!isNatural && !isJuridica) {
      resp.success = false;
      resp.message = 'RecordType del Lead no soportado para conversión controlada: ' + leadRt;
      return resp;
    }

    String targetAccRtDevName = isNatural ? 'PersonAccount' : 'IndustriesBusiness';

    RecordType accRt = [
      SELECT Id, DeveloperName, IsPersonType
      FROM RecordType
      WHERE SObjectType = 'Account' AND DeveloperName = :targetAccRtDevName
      LIMIT 1
    ];

    Account acc = new Account();
    acc.RecordTypeId = accRt.Id;

    if (isNatural) {
      String ln = (l.LastName != null) ? l.LastName.trim() : null;
      if (String.isBlank(ln))
        ln = 'Sin Apellido';
      acc.put('LastName', (ln.length() > 80) ? ln.substring(0, 80) : ln);

      if (l.FirstName != null) {
        String fn = l.FirstName.trim();
        if (!String.isBlank(fn)) {
          acc.put('FirstName', (fn.length() > 40) ? fn.substring(0, 40) : fn);
        }
      }
    } else {
      String ln = (l.LastName != null) ? l.LastName.trim() : null;
      if (String.isBlank(ln))
        ln = '';

      String fn = (l.FirstName != null) ? l.FirstName.trim() : null;
      if (String.isBlank(fn))
        fn = '';

      String name = fn + ' ' + ln;
      name = name.trim();
      acc.put('Name', (name.length() > 80) ? name.substring(0, 80) : name);
    }

    insert acc;

    System.debug('RT del Candidato=' + leadRt + ', RT del Cliente=' + targetAccRtDevName + ', Account pre-creada Id=' + acc.Id + ', Estado de Conversión=' + convertedStatus);

    Database.LeadConvert lc = new Database.LeadConvert();
    lc.setLeadId(l.Id);
    lc.setConvertedStatus(convertedStatus);
    lc.setDoNotCreateOpportunity(true);
    lc.setAccountId(acc.Id);

    Database.LeadConvertResult r;

    try {
      r = Database.convertLead(lc);
    } catch (DmlException dmle) {
      String msg = (dmle.getNumDml() > 0) ? dmle.getDmlMessage(0) : dmle.getMessage();

      System.debug(dmle.getStackTraceString());

      Database.rollback(sp);
      msg = msg.stripHtmlTags();
      resp.success = false;
      resp.message = msg;
      resp.errorType = dmle.getTypeName();
      resp.errorDetail = msg;
      return resp;
    } catch (Exception ex) {
      System.debug('convertLead Exception: ' + ex.getMessage());
      System.debug(ex.getStackTraceString());

      Database.rollback(sp);

      resp.success = false;
      resp.message = ex.getMessage();
      resp.errorType = ex.getTypeName();
      resp.errorDetail = ex.getMessage();
      return resp;
    }

    if (!r.isSuccess()) {
      System.debug('convertLead Result: ' + r);
      String errMsg = 'No se pudo convertir el Lead.';
      if (r.getErrors() != null && !r.getErrors().isEmpty()) {
        errMsg = r.getErrors()[0].getMessage();
      }

      Database.rollback(sp);

      resp.success = false;
      resp.message = errMsg;
      resp.errorType = 'CONVERT_ERROR';
      resp.errorDetail = errMsg;
      return resp;
    }

    resp.success = true;
    resp.message = 'Conversión Exitosa';
    resp.accountId = r.getAccountId();
    resp.contactId = r.getContactId();
    resp.opportunityId = r.getOpportunityId();

    System.debug('Conversión OK -> Account Id=' + resp.accountId + ' Contact Id=' + resp.contactId);

    return resp;
  }
}