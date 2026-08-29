/**
 * Name: OpportunityTCPPrequalificationQueue
 * Description: Ejecuta precalificación (mock/callout) y actualiza OTCP_State__c / OTCP_SubState__c.
 * Last modified: 2026-01-03
 */
public with sharing class OpportunityTCPPrequalificationQueue implements Queueable, Database.AllowsCallouts {

    private List<Id> oppIds;

    public OpportunityTCPPrequalificationQueue(List<Id> oppIds) {
        this.oppIds = (oppIds == null) ? new List<Id>() : oppIds;
    }

    public void execute(QueueableContext qc) {
        System.debug('>>> on OpportunityTCPPrequalificationQueue.execute. oppIds size: ' + oppIds.size());
		Integer CURRENCY_CODE = 2;
        
        if (oppIds.isEmpty()) return;
        
        Id currentOppId = oppIds[0];
        List<Id> remainingOppIds = new List<Id>();
        for (Integer i = 1; i < oppIds.size(); i++) {
            remainingOppIds.add(oppIds[i]);
        }

        List<OpportunityTCP__c> opps;
        try {
            opps = [
                SELECT Id, Name,
                       //Disparadores
                       OTCP_State__c,
                       OTCP_SubState__c,

                       //Account para el request
                       OTCP_Account__r.ACC_NumIdentificacion__c,
                       OTCP_Account__r.ACC_TipoIdentificacion__c,

                       //OpportunityTCP para el request
                	   OTCP_TimeWorked__c,
                       OTCP_MonthlyIncome__c,
                       OTCP_Salaried__c
                FROM OpportunityTCP__c
                WHERE Id = :currentOppId
            ];
            System.debug('>>> Query OpportunityTCP__c rows: ' + opps.size());
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '>>> Error querying OpportunityTCP__c: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
            return;
        }

        List<OpportunityTCP__c> toUpdate = new List<OpportunityTCP__c>();
		Decimal tasa = ExchangeRateService.getTasaCambio(CURRENCY_CODE);
        system.debug('tasa de cambio: '+tasa);

        try {
            
            if (opps.isEmpty()) {
                return;
            }
            
            OpportunityTCP__c opp = opps[0];
            System.debug('>>> Processing opp: ' + opp.Id + ' / ' + opp.Name);
            System.debug('VALIDACION QUEUEABLE State=' + opp.OTCP_State__c);
            System.debug('VALIDACION QUEUEABLE SubState=' + opp.OTCP_SubState__c);
            
            // Revalidación: solo procesar si aún está en el punto esperado
            if (opp.OTCP_State__c != 'Validado' || opp.OTCP_SubState__c != 'Pendiente Precalificacion') {
                System.debug('>>> Skipping (no longer matches condition). OTCP_Status=' + opp.OTCP_State__c + ' OTCP_SubStatus=' + opp.OTCP_SubState__c);
                return;
            }
            
            // Validaciones mínimas de datos
            if (opp.OTCP_Account__c == null || opp.OTCP_Account__r == null) {
                System.debug(LoggingLevel.WARN, '>>> Skipping: OTCP_Account__c missing. oppId=' + opp.Id);
                return;
            }
            
            // Armado del input para el service
            TCP_PrequalificationService.Input input = new TCP_PrequalificationService.Input();
            
            // Account
            input.numIdentificacion  = opp.OTCP_Account__r.ACC_NumIdentificacion__c;
            input.tipoIdentificacion = opp.OTCP_Account__r.ACC_TipoIdentificacion__c;
            
            // Opportunity
            input.tiempoLaborando  = opp.OTCP_TimeWorked__c;                                   //expresado en meses
            input.salario          = opp.OTCP_MonthlyIncome__c;
            input.tipoCliente      = (String.valueOf(opp.OTCP_Salaried__c) == 'SI') ? 1 : 2;  //1=Asalariado, 2= Independiente
            input.tasaCambio       = tasa;                                                    //La tasa se consume con API, al registrar la solicitud se guarda para saber con que valor se ejecuto
            
            System.debug('>>> OpportunityTCPPrequalificationQueue - input para prequalifyTCP =' + JSON.serialize(input));
            
            // Llamada al servicio
            TCP_PrequalificationService.Result result = TCP_PrequalificationService.prequalifyTCP(input);
            System.debug('RESULTADO PRECALIFICAR TC = ' + JSON.serializePretty(result));
            
            if (result == null || String.isBlank(result.dictamen)) {
                System.debug(LoggingLevel.WARN, '>>> No devolivió dictamen. Se marca como Referido. oppId=' + opp.Id);
                result = (result == null) ? new TCP_PrequalificationService.Result() : result;
                result.dictamen = 'Referido';
            }
            
            // Update del registro según dictamen
            OpportunityTCP__c upd = new OpportunityTCP__c(Id = opp.Id);
            
            if (result.dictamen == 'Aprobado') {
                upd.OTCP_State__c = 'Aprobada';
                upd.OTCP_SubState__c = 'Pendiente Agregar datos de Tarjeta';
                upd.OTCP_PreQualificationApproved__c = 'SI';
                
            } else if (result.dictamen == 'Rechazado') {
                upd.OTCP_State__c = 'Cerrada Perdida';
                upd.OTCP_SubState__c = 'Precalificacion Rechazada';
                upd.OTCP_PreQualificationApproved__c = 'NO';
                
            } else if (result.dictamen == 'Referido') {
                upd.OTCP_State__c = 'Analisis de Credito';
                upd.OTCP_SubState__c = 'Pendiente Analisis de credito';
                
            } else {
                System.debug(LoggingLevel.WARN, '>>> dictamen inesperado =' + result.dictamen
                             + '. Alternativa Referido. oppId=' + opp.Id);
                
                upd.OTCP_State__c = 'Analisis de Credito';
                upd.OTCP_SubState__c = 'Pendiente Analisis de credito';
            }

            upd.OTCP_dictamen__c = result.dictamen;
            upd.OTCP_xcore__c = result.xcore;
            upd.OTCP_limiteSugeridoDOP__c = result.limiteSugeridoDop;
            upd.OTCP_limiteSugeridoUSD__c = result.limiteSugeridoUsd;
            upd.OTCP_mensajeRespuesta__c = (result.mensajes != null) ? String.join(result.mensajes, ' | ') : null;
            upd.OTCP_tasaCambio__c = tasa;
            toUpdate.add(upd);

            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '>>> Error procesando oppId=' + opps[0].Id + ': ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
            return;
        }
        try {
            INTLogger.logCallout('tasaCambio','ExchangeRateService',ExchangeRateService.lastRequestToLog,ExchangeRateService.lastResponseToLog);
        } catch (Exception logEx) {
            System.debug(LoggingLevel.ERROR, '>>> Error INTLogger tasaCambio: ' + logEx.getMessage());
            System.debug(LoggingLevel.ERROR, logEx.getStackTraceString());
        } finally {
            ExchangeRateService.lastRequestToLog = null;
            ExchangeRateService.lastResponseToLog = null;
        }

        if (!toUpdate.isEmpty()) {
            System.debug('>>> Actualizando registro OpportunityTCP: ' + toUpdate.size());
            try {
                update toUpdate;
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, '>>> DML error al actualizar OpportunityTCP: ' + e.getMessage());
                System.debug(LoggingLevel.ERROR, e.getStackTraceString());
            }
  
        } else {
            System.debug('>>> No hay registros para actualizar');
        }
        
        if (!remainingOppIds.isEmpty()) {
            System.enqueueJob(new OpportunityTCPPrequalificationQueue(remainingOppIds));
        }
    }
}