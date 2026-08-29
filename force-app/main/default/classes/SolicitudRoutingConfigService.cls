public with sharing class SolicitudRoutingConfigService {

    public class RoutingRuleResult {
        public Boolean foundRule;
        public String message;
        public Solicitud_Routing_Config__mdt rule;

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
        RoutingRuleResult result = new RoutingRuleResult();

        try {
            if (caseRecord == null) {
                result.message = 'El Case recibido es nulo.';
                return result;
            }

            String codigo = getStringFieldValue(caseRecord, codigoFieldApi);
            String canal = getStringFieldValue(caseRecord, canalFieldApi);
            String producto = getStringFieldValue(caseRecord, productoFieldApi);

            System.debug(LoggingLevel.ERROR,
                'DEBUG CONFIG FROM CASE | CaseId=' + caseRecord.Id +
                ' | codigo=' + codigo +
                ' | canal=' + canal +
                ' | producto=' + producto
            );

            return getMatchingRule(codigo, canal, producto);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingConfigService.getMatchingRuleFromCase(): ' + e.getMessage()
            );
            result.message = 'Error obteniendo regla desde Case: ' + e.getMessage();
            return result;
        }
    }

    public static RoutingRuleResult getMatchingRule(
        String codigoSolicitud,
        String canal,
        String producto
    ) {
        RoutingRuleResult result = new RoutingRuleResult();

        try {
            String normalizedCodigo = normalizeValue(codigoSolicitud);
            String normalizedCanal = normalizeValue(canal);
            String normalizedProducto = normalizeValue(producto);

            System.debug(LoggingLevel.ERROR,
                'DEBUG CONFIG MATCH START | codigoSolicitud=' + codigoSolicitud +
                ' | normalizedCodigo=' + normalizedCodigo +
                ' | canal=' + canal +
                ' | normalizedCanal=' + normalizedCanal +
                ' | producto=' + producto +
                ' | normalizedProducto=' + normalizedProducto
            );

            if (String.isBlank(normalizedCodigo)) {
                result.message = 'No se recibió código o descripción de Solicitud para buscar la regla.';
                return result;
            }

            List<Solicitud_Routing_Config__mdt> candidateRules = getCandidateRules(normalizedCodigo);

            System.debug(LoggingLevel.ERROR,
                'DEBUG CONFIG CANDIDATES | normalizedCodigo=' + normalizedCodigo +
                ' | candidateRules.size=' + candidateRules.size()
            );

            if (candidateRules.isEmpty()) {
                result.message = 'No existen reglas activas para la Solicitud: ' + normalizedCodigo;
                return result;
            }

            Solicitud_Routing_Config__mdt bestRule = selectBestRule(
                candidateRules,
                normalizedCanal,
                normalizedProducto
            );

            if (bestRule == null) {
                result.message =
                    'No se encontró una regla aplicable para solicitud=' + normalizedCodigo +
                    ', canal=' + normalizedCanal +
                    ', producto=' + normalizedProducto;
                return result;
            }

            result.foundRule = true;
            result.rule = bestRule;
            result.message = 'Regla encontrada correctamente.';

            System.debug(LoggingLevel.ERROR,
                'DEBUG CONFIG BEST RULE | bestRule=' + bestRule.DeveloperName
            );

            return result;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingConfigService.getMatchingRule(): ' + e.getMessage()
            );
            result.message = 'Error buscando regla de ruteo: ' + e.getMessage();
            return result;
        }
    }

    private static List<Solicitud_Routing_Config__mdt> getCandidateRules(String codigoSolicitud) {
        try {
            List<Solicitud_Routing_Config__mdt> allRules = [
                SELECT
                    DeveloperName,
                    MasterLabel,
                    Activo__c,
                    Codigo_Solicitud__c,
                    Descripcion_Solicitud__c,
                    Canal__c,
                    Producto__c,
                    Flujo_Etapas__c,
                    RecordType_DeveloperName__c,
                    Support_Process__c,
                    Status_Inicial__c,
                    Nivel_Inicial__c,
                    Grupo_Resolutor_N1__c,
                    Grupo_Resolutor_N2__c,
                    Grupo_Resolutor_N3__c,
                    Grupo_Resolutor_N4__c,
                    Queue_N0_DeveloperName__c,
                    Queue_N1_DeveloperName__c,
                    Queue_N2_DeveloperName__c,
                    Queue_N3_DeveloperName__c,
                    Queue_N4_DeveloperName__c,
                    Permite_Devolucion__c,
                    Queue_Devolucion_DeveloperName__c,
                    Orden_Prioridad__c,
                    Entitlement_Name__c
                FROM Solicitud_Routing_Config__mdt
                WHERE Activo__c = true
                ORDER BY Orden_Prioridad__c ASC, DeveloperName ASC
            ];

            List<Solicitud_Routing_Config__mdt> rules = new List<Solicitud_Routing_Config__mdt>();

            for (Solicitud_Routing_Config__mdt rule : allRules) {
                String normalizedCodigoRule = normalizeValue(rule.Codigo_Solicitud__c);
                String normalizedDescripcionRule = normalizeValue(rule.Descripcion_Solicitud__c);

                if (
                    normalizedCodigoRule == codigoSolicitud ||
                    normalizedDescripcionRule == codigoSolicitud
                ) {
                    rules.add(rule);

                    System.debug(LoggingLevel.ERROR,
                        'DEBUG CONFIG CANDIDATE FOUND | rule=' + rule.DeveloperName +
                        ' | codigo=' + rule.Codigo_Solicitud__c +
                        ' | descripcion=' + rule.Descripcion_Solicitud__c +
                        ' | producto=' + rule.Producto__c +
                        ' | queueN2=' + rule.Queue_N2_DeveloperName__c
                    );
                }
            }

            return rules;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingConfigService.getCandidateRules(): ' + e.getMessage()
            );
            return new List<Solicitud_Routing_Config__mdt>();
        }
    }

    private static Solicitud_Routing_Config__mdt selectBestRule(
        List<Solicitud_Routing_Config__mdt> candidateRules,
        String canal,
        String producto
    ) {
        try {
            Solicitud_Routing_Config__mdt bestRule;
            Integer bestScore = -1;
            Decimal bestPriority = 999999;

            for (Solicitud_Routing_Config__mdt rule : candidateRules) {
                Integer currentScore = calculateSpecificityScore(rule, canal, producto);

                System.debug(LoggingLevel.ERROR,
                    'DEBUG CONFIG SCORE | rule=' + rule.DeveloperName +
                    ' | canal=' + canal +
                    ' | producto=' + producto +
                    ' | currentScore=' + currentScore +
                    ' | ordenPrioridad=' + rule.Orden_Prioridad__c
                );

                if (currentScore < 0) {
                    continue;
                }

                Decimal currentPriority = (rule.Orden_Prioridad__c == null) ? 999999 : rule.Orden_Prioridad__c;

                if (
                    bestRule == null ||
                    currentScore > bestScore ||
                    (currentScore == bestScore && currentPriority < bestPriority)
                ) {
                    bestRule = rule;
                    bestScore = currentScore;
                    bestPriority = currentPriority;
                }
            }

            System.debug(LoggingLevel.ERROR,
                'DEBUG CONFIG SELECTED | bestRule=' + (bestRule != null ? bestRule.DeveloperName : null) +
                ' | bestScore=' + bestScore +
                ' | bestPriority=' + bestPriority
            );

            return bestRule;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingConfigService.selectBestRule(): ' + e.getMessage()
            );
            return null;
        }
    }

    private static Integer calculateSpecificityScore(
        Solicitud_Routing_Config__mdt rule,
        String canal,
        String producto
    ) {
        try {
            if (rule == null) {
                return -1;
            }

            Integer canalScore = String.isBlank(canal) ? 0 : getMatchScore(rule.Canal__c, canal);
            Integer productoScore = String.isBlank(producto) ? 0 : getMatchScore(rule.Producto__c, producto);

            if (!String.isBlank(canal) && canalScore < 0) {
                return -1;
            }

            if (!String.isBlank(producto) && productoScore < 0) {
                return -1;
            }

            return canalScore + productoScore;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingConfigService.calculateSpecificityScore(): ' + e.getMessage()
            );
            return -1;
        }
    }

    private static Boolean isMatch(String ruleValue, String inputValue) {
        try {
            return getMatchScore(ruleValue, inputValue) > -1;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingConfigService.isMatch(): ' + e.getMessage()
            );
            return false;
        }
    }

    private static String getStringFieldValue(SObject sobj, String fieldApiName) {
        try {
            if (sobj == null || String.isBlank(fieldApiName)) {
                return null;
            }

            Object rawValue = sobj.get(fieldApiName);

            return rawValue == null ? null : String.valueOf(rawValue);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingConfigService.getStringFieldValue(): ' + e.getMessage()
            );
            return null;
        }
    }

    private static String normalizeValue(String value) {
        try {
            if (String.isBlank(value)) {
                return null;
            }

            String normalized = value.trim().toUpperCase();

            normalized = normalized.replace('Á', 'A');
            normalized = normalized.replace('É', 'E');
            normalized = normalized.replace('Í', 'I');
            normalized = normalized.replace('Ó', 'O');
            normalized = normalized.replace('Ú', 'U');
            normalized = normalized.replace('Ü', 'U');
            normalized = normalized.replace('Ñ', 'N');

            return normalized;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingConfigService.normalizeValue(): ' + e.getMessage()
            );
            return null;
        }
    }

    private static Integer getMatchScore(String ruleValue, String inputValue) {
        try {
            String normalizedRule = normalizeValue(ruleValue);
            String normalizedInput = normalizeValue(inputValue);

            if (String.isBlank(normalizedRule)) {
                return -1;
            }

            if (
                normalizedRule == 'ALL' ||
                normalizedRule == 'TODOS' ||
                normalizedRule == 'TODOS LOS PRODUCTOS' ||
                normalizedRule == 'TODOS LOS PRODUCTOS O SIN PRODUCTO' ||
                normalizedRule == 'SIN PRODUCTO'
            ) {
                return 1;
            }

            if (String.isBlank(normalizedInput)) {
                return -1;
            }

            if (normalizedRule == normalizedInput) {
                return 2;
            }

            List<String> tokens = normalizedRule.split(',');

            for (String token : tokens) {
                String normalizedToken = normalizeValue(token);

                if (
                    normalizedToken == 'ALL' ||
                    normalizedToken == 'TODOS' ||
                    normalizedToken == 'TODOS LOS PRODUCTOS' ||
                    normalizedToken == 'TODOS LOS PRODUCTOS O SIN PRODUCTO' ||
                    normalizedToken == 'SIN PRODUCTO'
                ) {
                    return 1;
                }

                if (normalizedToken == normalizedInput) {
                    return 2;
                }
            }

            return -1;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingConfigService.getMatchScore(): ' + e.getMessage()
            );
            return -1;
        }
    }
}