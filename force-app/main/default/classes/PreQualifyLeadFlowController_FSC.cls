public class PreQualifyLeadFlowController_FSC {
  public class FlowInputs {
    @InvocableVariable
    public Lead lead;
    @InvocableVariable
    public Participante__c accionista;
    @InvocableVariable
    public Participante__c representante;
  }

  public class FlowOutputs {
    @InvocableVariable
    public Id leadId;
    @InvocableVariable
    public String clientRating;
  }

  @InvocableMethod(label='PrequalifyLead' description='allows us to qualify the prospect before linking it as a client')
  public static List<FlowOutputs> prequalify(FlowInputs[] toPrequalify) {
    System.debug('PreQualifyLeadFlowController_FSC.prequalify - Inicio');
    System.debug('PreQualifyLeadFlowController_FSC.prequalify - Cantidad de registros recibidos: ' + (toPrequalify != null ? toPrequalify.size() : 0));

    try {
      FlowOutputs[] responses = new List<FlowOutputs>();

      for (FlowInputs record : toPrequalify) {
        System.debug('PreQualifyLeadFlowController_FSC.prequalify - Procesando registro de entrada');

        System.debug('PreQualifyLeadFlowController_FSC.prequalify - Lead viene nulo: ' + (record == null || record.lead == null));
        System.debug('PreQualifyLeadFlowController_FSC.prequalify - Lead Id: ' + (record != null && record.lead != null ? record.lead.Id : null));
        System.debug('PreQualifyLeadFlowController_FSC.prequalify - Lead Name: ' + (record != null && record.lead != null ? record.lead.Name : null));
        System.debug('PreQualifyLeadFlowController_FSC.prequalify - Lead RecordTypeId: ' + (record != null && record.lead != null ? record.lead.RecordTypeId : null));
        System.debug('PreQualifyLeadFlowController_FSC.prequalify - Lead Tipo Persona: ' + (record != null && record.lead != null ? record.lead.LEA_INT_TipoPersona__c : null));
        System.debug('PreQualifyLeadFlowController_FSC.prequalify - Lead Tipo Identificación: ' + (record != null && record.lead != null ? record.lead.LEA_TipoIdentificacion__c : null));
        System.debug('PreQualifyLeadFlowController_FSC.prequalify - Lead Número Identificación: ' + (record != null && record.lead != null ? record.lead.LEA_NumIdentificacion__c : null));
        System.debug('PreQualifyLeadFlowController_FSC.prequalify - Accionista Id: ' + (record != null && record.accionista != null ? record.accionista.Id : null));
        System.debug('PreQualifyLeadFlowController_FSC.prequalify - Representante Id: ' + (record != null && record.representante != null ? record.representante.Id : null));

        System.debug('PreQualifyLeadFlowController_FSC.prequalify - Invocando PreQualifyLeadFlowHandler_FSC.createBody');
        PreQualifyFlowModel body = PreQualifyLeadFlowHandler_FSC.createBody(record.lead, record.accionista, record.representante);

        System.debug('PreQualifyLeadFlowController_FSC.prequalify - Body generado: ' + JSON.serialize(body));
        System.debug('PreQualifyLeadFlowController_FSC.prequalify - Body Header: ' + JSON.serialize(body != null ? body.Header : null));
        System.debug('PreQualifyLeadFlowController_FSC.prequalify - Body Fields: ' + JSON.serialize(body != null ? body.Fields : null));

        System.debug('PreQualifyLeadFlowController_FSC.prequalify - Invocando PreQualifyLeadFlowHandler_FSC.prequalifyClient');
        String clientRating = PreQualifyLeadFlowHandler_FSC.prequalifyClient(body);

        System.debug('PreQualifyLeadFlowController_FSC.prequalify - clientRating recibido desde handler: ' + clientRating);
        System.debug('PreQualifyLeadFlowController_FSC.prequalify - clientRating viene nulo: ' + (clientRating == null));

        FlowOutputs response = new FlowOutputs();
        response.leadId = record.lead.Id;
        response.clientRating = clientRating;

        System.debug('PreQualifyLeadFlowController_FSC.prequalify - FlowOutputs.leadId: ' + response.leadId);
        System.debug('PreQualifyLeadFlowController_FSC.prequalify - FlowOutputs.clientRating: ' + response.clientRating);

        responses.add(response);
      }

      System.debug('PreQualifyLeadFlowController_FSC.prequalify - Cantidad de respuestas retornadas al Flow: ' + responses.size());
      System.debug('PreQualifyLeadFlowController_FSC.prequalify - Respuestas retornadas al Flow: ' + JSON.serialize(responses));
      System.debug('PreQualifyLeadFlowController_FSC.prequalify - Fin');

      return responses;
    } catch (System.FlowException e) {
      System.debug('PreQualifyLeadFlowController_FSC.prequalify - FlowException: ' + e.getMessage());
      System.debug('PreQualifyLeadFlowController_FSC.prequalify - FlowException StackTrace: ' + e.getStackTraceString());
      throw new HandledException(e.getMessage());
    } catch (Exception e) {
      System.debug('PreQualifyLeadFlowController_FSC.prequalify - Exception: ' + e.getMessage());
      System.debug('PreQualifyLeadFlowController_FSC.prequalify - Exception Type: ' + e.getTypeName());
      System.debug('PreQualifyLeadFlowController_FSC.prequalify - Exception StackTrace: ' + e.getStackTraceString());
      throw e;
    }
  }
}