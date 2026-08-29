public with sharing class ReclamacionRoutingConfigService {

    public class RoutingRuleResult {
        public Boolean foundRule;
        public String message;
        public Reclamacion_Routing_Config__mdt rule;

        public RoutingRuleResult() {
            this.foundRule = false;
            this.message = null;
            this.rule = null;
        }
    }

    public static RoutingRuleResult getMatchingRuleFromCase(
        Case caseRecord,
        String codigoFieldApi,
        String canalFieldApi,
        String productoFieldApi
    ) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingConfigService.getMatchingRuleFromCase() ' +
            'caseRecord=' + caseRecord +
            ', codigoFieldApi=' + codigoFieldApi +
            ', canalFieldApi=' + canalFieldApi +
            ', productoFieldApi=' + productoFieldApi
        );

        RoutingRuleResult result = new RoutingRuleResult();

        try {
            if (caseRecord == null) {
                result.message = 'El Case recibido es nulo.';
                return result;
            }

            String codigo = getStringFieldValue(caseRecord, codigoFieldApi);
            String canal = getStringFieldValue(caseRecord, canalFieldApi);
            String producto = getStringFieldValue(caseRecord, productoFieldApi);

            System.debug(LoggingLevel.DEBUG,
                'ReclamacionRoutingConfigService.getMatchingRuleFromCase() ' +
                'codigo=' + codigo +
                ', canalUsuario=' + canal +
                ', producto=' + producto
            );

            return getMatchingRule(codigo, canal, producto);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingConfigService.getMatchingRuleFromCase(): ' + e.getMessage()
            );
            result.message = 'Error obteniendo regla desde Case: ' + e.getMessage();
            return result;
        }
    }

    public static RoutingRuleResult getMatchingRule(
        String codigoReclamacion,
        String canal,
        String producto
    ) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingConfigService.getMatchingRule() ' +
            'codigoReclamacion=' + codigoReclamacion +
            ', canalUsuario=' + canal +
            ', producto=' + producto
        );

        RoutingRuleResult result = new RoutingRuleResult();

        try {
            String normalizedCodigo = normalizeValue(codigoReclamacion);
            String normalizedCanal = normalizeValue(canal);
            String normalizedProducto = normalizeValue(producto);

            if (String.isBlank(normalizedCodigo)) {
                result.message = 'No se recibió código de reclamación para buscar la regla.';
                return result;
            }

            List<Reclamacion_Routing_Config__mdt> candidateRules = getCandidateRules(normalizedCodigo);

            System.debug(LoggingLevel.DEBUG,
                'ReclamacionRoutingConfigService.getMatchingRule() candidateRules.size()=' + candidateRules.size()
            );

            if (candidateRules.isEmpty()) {
                result.message = 'No existen reglas activas para el código de reclamación: ' + normalizedCodigo;
                return result;
            }

            Reclamacion_Routing_Config__mdt bestRule = selectBestRule(
                candidateRules,
                normalizedCanal,
                normalizedProducto
            );

            if (bestRule == null) {
                result.message =
                    'No se encontró una regla aplicable para código=' + normalizedCodigo +
                    ', canalUsuario=' + normalizedCanal +
                    ', producto=' + normalizedProducto;
                return result;
            }

            result.foundRule = true;
            result.rule = bestRule;
            result.message = 'Regla encontrada correctamente.';

            System.debug(LoggingLevel.DEBUG,
                'ReclamacionRoutingConfigService.getMatchingRule() ' +
                'bestRule.DeveloperName=' + bestRule.DeveloperName +
                ', Grupo_Canal_Reclamacion__c=' + bestRule.Grupo_Canal_Reclamacion__c +
                ', Queue_Canal_Reclamacion_DeveloperName__c=' + bestRule.Queue_Canal_Reclamacion_DeveloperName__c
            );

            return result;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingConfigService.getMatchingRule(): ' + e.getMessage()
            );
            result.message = 'Error buscando regla de ruteo: ' + e.getMessage();
            return result;
        }
    }

    private static List<Reclamacion_Routing_Config__mdt> getCandidateRules(String codigoReclamacion) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingConfigService.getCandidateRules() codigoReclamacion=' + codigoReclamacion
        );

        try {
            List<Reclamacion_Routing_Config__mdt> rules = [
                SELECT
                    DeveloperName,
                    MasterLabel,
                    Activo__c,
                    Codigo_Reclamacion__c,
                    Descripcion_Reclamacion__c,
                    Canal__c,
                    Producto__c,
                    Flujo_Etapas__c,
                    RecordType_DeveloperName__c,
                    Support_Process__c,
                    Status_Inicial__c,
                    Nivel_Inicial__c,

                    Grupo_Canal_Reclamacion__c,
                    Queue_Canal_Reclamacion_DeveloperName__c,
                    Status_Canal_Reclamacion__c,

                    Grupo_Resolutor_N1__c,
                    Grupo_Resolutor_N2__c,
                    Grupo_Resolutor_N3__c,
                    Queue_N1_DeveloperName__c,
                    Queue_N2_DeveloperName__c,
                    Queue_N3_DeveloperName__c,
                    Permite_Devolucion__c,
                    Queue_Devolucion_DeveloperName__c,
                    Orden_Prioridad__c,
                    Entitlement_Name__c
                FROM Reclamacion_Routing_Config__mdt
                WHERE Activo__c = true
                  AND Codigo_Reclamacion__c = :codigoReclamacion
                ORDER BY Orden_Prioridad__c ASC, DeveloperName ASC
            ];

            System.debug(LoggingLevel.DEBUG,
                'ReclamacionRoutingConfigService.getCandidateRules() query size=' + rules.size()
            );

            return rules;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingConfigService.getCandidateRules(): ' + e.getMessage()
            );
            return new List<Reclamacion_Routing_Config__mdt>();
        }
    }

    private static Reclamacion_Routing_Config__mdt selectBestRule(
        List<Reclamacion_Routing_Config__mdt> candidateRules,
        String canal,
        String producto
    ) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingConfigService.selectBestRule() ' +
            'candidateRules.size()=' + candidateRules.size() +
            ', canalUsuario=' + canal +
            ', producto=' + producto
        );

        try {
            Reclamacion_Routing_Config__mdt bestRule;
            Integer bestScore = -1;
            Decimal bestPriority = 999999;

            for (Reclamacion_Routing_Config__mdt rule : candidateRules) {
                Integer currentScore = calculateSpecificityScore(rule, canal, producto);

                System.debug(LoggingLevel.DEBUG,
                    'ReclamacionRoutingConfigService.selectBestRule() ' +
                    'rule=' + rule.DeveloperName +
                    ', Grupo_Canal_Reclamacion__c=' + rule.Grupo_Canal_Reclamacion__c +
                    ', currentScore=' + currentScore +
                    ', ordenPrioridad=' + rule.Orden_Prioridad__c
                );

                if (currentScore < 0) {
                    continue;
                }

                Decimal currentPriority = (rule.Orden_Prioridad__c == null) ? 999999 : rule.Orden_Prioridad__c;

                if (bestRule == null ||
                    currentScore > bestScore ||
                    (currentScore == bestScore && currentPriority < bestPriority)) {

                    bestRule = rule;
                    bestScore = currentScore;
                    bestPriority = currentPriority;
                }
            }

            System.debug(LoggingLevel.DEBUG,
                'ReclamacionRoutingConfigService.selectBestRule() ' +
                'bestRule=' + (bestRule != null ? bestRule.DeveloperName : null) +
                ', bestScore=' + bestScore +
                ', bestPriority=' + bestPriority
            );

            return bestRule;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingConfigService.selectBestRule(): ' + e.getMessage()
            );
            return null;
        }
    }

    private static Integer calculateSpecificityScore(
        Reclamacion_Routing_Config__mdt rule,
        String canal,
        String producto
    ) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingConfigService.calculateSpecificityScore() ' +
            'rule=' + (rule != null ? rule.DeveloperName : null) +
            ', canalUsuario=' + canal +
            ', producto=' + producto
        );

        try {
            if (rule == null) {
                return -1;
            }

            /*
             * IMPORTANTE:
             * En Reclamaciones, el canal del usuario NO se compara contra Canal__c.
             * Canal__c conserva su lógica funcional anterior, por ejemplo VE,CA,SA.
             * El canal del usuario se compara contra Grupo_Canal_Reclamacion__c.
             */
            Integer canalScore = getMatchScore(rule.Grupo_Canal_Reclamacion__c, canal);
            Integer productoScore = String.isBlank(producto) ? 0 : getMatchScore(rule.Producto__c, producto);

            System.debug(LoggingLevel.DEBUG,
                'ReclamacionRoutingConfigService.calculateSpecificityScore() ' +
                'rule=' + rule.DeveloperName +
                ', Grupo_Canal_Reclamacion__c=' + rule.Grupo_Canal_Reclamacion__c +
                ', canalScore=' + canalScore +
                ', productoScore=' + productoScore
            );

            if (canalScore < 0) {
                return -1;
            }

            if (!String.isBlank(producto) && productoScore < 0) {
                return -1;
            }

            return canalScore + productoScore;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingConfigService.calculateSpecificityScore(): ' + e.getMessage()
            );
            return -1;
        }
    }

    private static Boolean isMatch(String ruleValue, String inputValue) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingConfigService.isMatch() ' +
            'ruleValue=' + ruleValue +
            ', inputValue=' + inputValue
        );

        try {
            return getMatchScore(ruleValue, inputValue) > -1;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingConfigService.isMatch(): ' + e.getMessage()
            );
            return false;
        }
    }

    private static String getStringFieldValue(SObject sobj, String fieldApiName) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingConfigService.getStringFieldValue() fieldApiName=' + fieldApiName
        );

        try {
            if (sobj == null || String.isBlank(fieldApiName)) {
                return null;
            }

            Object rawValue = sobj.get(fieldApiName);

            return rawValue == null ? null : String.valueOf(rawValue);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingConfigService.getStringFieldValue(): ' + e.getMessage()
            );
            return null;
        }
    }

    private static String normalizeValue(String value) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingConfigService.normalizeValue() value=' + value
        );

        try {
            if (String.isBlank(value)) {
                return null;
            }

            return value.trim().toUpperCase();

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingConfigService.normalizeValue(): ' + e.getMessage()
            );
            return null;
        }
    }

    private static Integer getMatchScore(String ruleValue, String inputValue) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingConfigService.getMatchScore() ' +
            'ruleValue=' + ruleValue +
            ', inputValue=' + inputValue
        );

        try {
            String normalizedRule = normalizeValue(ruleValue);
            String normalizedInput = normalizeValue(inputValue);

            if (String.isBlank(normalizedRule) || String.isBlank(normalizedInput)) {
                return -1;
            }

            if (normalizedRule == 'ALL') {
                return 1;
            }

            if (normalizedRule == normalizedInput) {
                return 2;
            }

            List<String> tokens = normalizedRule.split(',');

            for (String token : tokens) {
                String normalizedToken = normalizeValue(token);

                if (normalizedToken == normalizedInput) {
                    return 2;
                }
            }

            return -1;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingConfigService.getMatchScore(): ' + e.getMessage()
            );
            return -1;
        }
    }
}