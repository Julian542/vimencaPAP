/**
 * @description       :
 * @author            : Kevin Vega H
 * @group             :
 * @last modified on  : 12-04-2023
 * @last modified by  : Luis Naranjo
 **/
public class PreQualifyFlowController {
  public class FlowInputs {
    @InvocableVariable
    public Account account;
    @InvocableVariable
    public Historial_laboral__c history;
    @InvocableVariable
    public Participante__c accionista;
    @InvocableVariable
    public Participante__c representante;
    @InvocableVariable
    public Informacion_Financiera__c infoFinanciera;
  }

  public class FlowOutputs {
    @InvocableVariable
    public Id accountId;
    @InvocableVariable
    public String clientRating;
  }

  @InvocableMethod(
    label='Prequalify'
    description='allows us to qualify the prospect before linking it as a client'
  )
  public static List<FlowOutputs> prequalify(FlowInputs[] toPrequalify) {
    try {
      FlowOutputs[] responses = new List<FlowOutputs>();
      for (FlowInputs record : toPrequalify) {
        PreQualifyFlowModel body = PreQualifyFlowHandler.createBody(
          record.account,
          record.infoFinanciera,
          record.accionista,
          record.representante,
          record.history
        );
        System.debug(body);
        String clientRating = PreQualifyFlowHandler.prequalifyClient(body);

        FlowOutputs response = new FlowOutputs();
        response.accountId = record.account.Id;
        response.clientRating = clientRating;
        responses.add(response);
      }
      return responses;
    } catch (System.FlowException e) {
      throw new HandledException(e.getMessage());
    }
  }
}