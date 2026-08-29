/**
 * Invocable desde Flow.
 * - Input: Id de ResidentialLoanApplication
 * - Obtiene RecordType.DeveloperName
 * - Switch por recordType
 * - Llama Integration Procedure pasando el Id de ResidentialLoanApplication y nombre del IP
 * - Actualiza FSC_Subestado__c según respuesta
 *
*/
public with sharing class FSC_APIBuroCredito {

    public class Input {
        @InvocableVariable(required=true)
        public Id residentialLoanApplicationId;
    }

    public class Output {
        @InvocableVariable
        public Boolean success;

        @InvocableVariable
        public String recordTypeDeveloperName;

        @InvocableVariable
        public String ipResult; // valor interpretado (ej: "Referido")

        @InvocableVariable
        public String message;
    }

    @InvocableMethod(label='FSC - Consultar Buró Crédito' description='Invoca IP y actualiza FSC_Subestado__c.')
    public static List<Output> run(List<Input> inputs) {
        List<Output> outputs = new List<Output>();
        if (inputs == null || inputs.isEmpty()) return outputs;

        // Normalmente Flow manda 1, pero soportamos bulk.
        Set<Id> rlaIds = new Set<Id>();
        for (Input i : inputs) {
            if (i != null && i.residentialLoanApplicationId != null) {
                rlaIds.add(i.residentialLoanApplicationId);
            }
        }

        Map<Id, ResidentialLoanApplication> rlaById = new Map<Id, ResidentialLoanApplication>([
            SELECT Id, Status, FSC_Subestado__c, RecordType.DeveloperName
            FROM ResidentialLoanApplication
            WHERE Id IN :rlaIds
        ]);

        List<ResidentialLoanApplication> toUpdate = new List<ResidentialLoanApplication>();

        for (Input i : inputs) {
            Output o = new Output();
            o.success = false;

            try {
                if (i == null || i.residentialLoanApplicationId == null) {
                    o.message = 'residentialLoanApplicationId requerido.';
                    outputs.add(o);
                    continue;
                }

                ResidentialLoanApplication rla = rlaById.get(i.residentialLoanApplicationId);
                if (rla == null) {
                    o.message = 'No se encontró ResidentialLoanApplication para el Id provisto.';
                    outputs.add(o);
                    continue;
                }

                String rtDevName = rla.RecordType != null ? rla.RecordType.DeveloperName : null;
                o.recordTypeDeveloperName = rtDevName;

                // Switch por RecordType DeveloperName
                Map<String,String> ipInterpretedResult;
                switch on rtDevName {
                    when 'FSC_Solicitud_Credito_PYME' {
                        ipInterpretedResult = callBuroCreditoIp(rla.Id, 'FSC_APIBuroCreditoPyme');
                    }
                    when else {
                        continue;
                    }
                }

                o.ipResult = String.valueOf(ipInterpretedResult.get('Status'));

                if (o.ipResult == 'Referido') {
                    toUpdate.add(new ResidentialLoanApplication(
                        Id = rla.Id,
                        FSC_Resultado_Buro__c = o.ipResult,
                        FSC_Subestado__c = 'Recepción de documentos – Análisis'
                    ));
                    o.message = 'IP devolvió Referido. Status actualizado.';
                } else if (o.ipResult == 'Rechazado') {
                    // toUpdate.add(new ResidentialLoanApplication(
                    //     Id = rla.Id,
                    //     FSC_Resultado_Buro__c = o.ipResult,
                    //     FSC_Motivo_Rechazo__c = String.valueOf(ipInterpretedResult.get('RejectionReasonCode')),
                    //     FSC_Subestado__c = 'Rechazado por Buró'
                    // ));
                    // o.message = 'IP devolvió Rechazado. FSC_Subestado__c actualizado.';                
                } else if (o.ipResult == 'Aprobado') {
                    // toUpdate.add(new ResidentialLoanApplication(
                    //     Id = rla.Id,
                    //     FSC_Resultado_Buro__c = o.ipResult,
                    //     FSC_Subestado__c = 'En proceso - Generación de firma y contratos'
                    // ));
                    // o.message = 'IP devolvió Aprobado. FSC_Subestado__c actualizado.';   
                } else {
                    o.message = 'IP devolvió: ' + o.ipResult + '. No se actualiza FSC_Subestado__c.';
                }

                o.success = true;
            } catch (Exception e) {
                o.success = false;
                o.message = 'Error: ' + e.getMessage();
            }

            outputs.add(o);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }

        return outputs;
    }

    /**
     * Invoca Integration Procedure pasando:
     *  - residentialLoanApplicationId
     * Retorna un Map de String,String con Status y RejectionReasonCode
     */
    public static Map<String,String> callBuroCreditoIp(Id rlaId, String integrationProcedureName) {
        // OmniStudio IP invoker
        Map<String, Object> inputMap = new Map<String, Object>{
            'residentialLoanApplicationId' => (String)rlaId
        };

        Map<String, Object> options = new Map<String, Object>();

        Object rawResponse;

        rawResponse = omnistudio.IntegrationProcedureService.runIntegrationService(
            integrationProcedureName,
            inputMap,
            options
        );

        if (rawResponse == null) return null;

        if (rawResponse instanceof Map<String, Object>) {
            return extractResultado((Map<String, Object>) rawResponse);
        }

        return null;
    }

    /**
     * Extrae el resultado del IP desde un Map.
     */
    public static Map<String, String> extractResultado(Map<String, Object> resp) {
        if (resp == null) return null;

        Map<String, String> result = new Map<String, String>();

        if (resp.containsKey('Status')) {
            result.put('Status', String.valueOf(resp.get('Status')));
        }

        if (resp.containsKey('RejectionReasonCode')) {
            result.put('RejectionReasonCode', String.valueOf(resp.get('RejectionReasonCode')));
        }

        return result;
    }
}