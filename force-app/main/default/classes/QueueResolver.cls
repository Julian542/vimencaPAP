public with sharing class QueueResolver {

    /**
     * Caché en memoria para evitar queries repetidas dentro de la misma transacción.
     * Key   = DeveloperName de la cola
     * Value = Id del Group (Queue)
     */
    private static Map<String, Id> queueIdByDeveloperName = new Map<String, Id>();

    /**
     * Obtiene el Id de una cola a partir de su DeveloperName.
     */
    public static Id getQueueIdByDeveloperName(String queueDeveloperName) {
        System.debug(LoggingLevel.DEBUG,
            'QueueResolver.getQueueIdByDeveloperName() queueDeveloperName=' + queueDeveloperName
        );

        try {
            String normalizedQueueDeveloperName = normalizeValue(queueDeveloperName);

            if (String.isBlank(normalizedQueueDeveloperName)) {
                System.debug(LoggingLevel.DEBUG,
                    'QueueResolver.getQueueIdByDeveloperName() DeveloperName vacío o nulo.'
                );
                return null;
            }

            if (queueIdByDeveloperName.containsKey(normalizedQueueDeveloperName)) {
                System.debug(LoggingLevel.DEBUG,
                    'QueueResolver.getQueueIdByDeveloperName() valor obtenido desde caché. Id=' +
                    queueIdByDeveloperName.get(normalizedQueueDeveloperName)
                );
                return queueIdByDeveloperName.get(normalizedQueueDeveloperName);
            }

            loadQueuesByDeveloperNames(new Set<String>{ normalizedQueueDeveloperName });

            System.debug(LoggingLevel.DEBUG,
                'QueueResolver.getQueueIdByDeveloperName() valor después de carga. Id=' +
                queueIdByDeveloperName.get(normalizedQueueDeveloperName)
            );

            return queueIdByDeveloperName.get(normalizedQueueDeveloperName);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en QueueResolver.getQueueIdByDeveloperName(): ' + e.getMessage()
            );
            return null;
        }
    }

    /**
     * Obtiene varios Ids de cola de una sola vez.
     * Devuelve un Map<DeveloperName, Id>.
     */
    public static Map<String, Id> getQueueIdsByDeveloperNames(Set<String> queueDeveloperNames) {
        System.debug(LoggingLevel.DEBUG,
            'QueueResolver.getQueueIdsByDeveloperNames() queueDeveloperNames=' + queueDeveloperNames
        );

        Map<String, Id> result = new Map<String, Id>();

        try {
            Set<String> normalizedNames = new Set<String>();

            if (queueDeveloperNames != null) {
                for (String queueDevName : queueDeveloperNames) {
                    String normalizedValue = normalizeValue(queueDevName);
                    if (!String.isBlank(normalizedValue)) {
                        normalizedNames.add(normalizedValue);
                    }
                }
            }

            if (normalizedNames.isEmpty()) {
                System.debug(LoggingLevel.DEBUG,
                    'QueueResolver.getQueueIdsByDeveloperNames() no hay nombres válidos para consultar.'
                );
                return result;
            }

            loadQueuesByDeveloperNames(normalizedNames);

            for (String devName : normalizedNames) {
                if (queueIdByDeveloperName.containsKey(devName)) {
                    result.put(devName, queueIdByDeveloperName.get(devName));
                }
            }

            System.debug(LoggingLevel.DEBUG,
                'QueueResolver.getQueueIdsByDeveloperNames() result=' + result
            );

            return result;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en QueueResolver.getQueueIdsByDeveloperNames(): ' + e.getMessage()
            );
            return result;
        }
    }

    /**
     * Carga en caché las colas faltantes.
     */
    private static void loadQueuesByDeveloperNames(Set<String> queueDeveloperNames) {
        System.debug(LoggingLevel.DEBUG,
            'QueueResolver.loadQueuesByDeveloperNames() queueDeveloperNames=' + queueDeveloperNames
        );

        try {
            Set<String> namesToQuery = new Set<String>();

            for (String devName : queueDeveloperNames) {
                if (!queueIdByDeveloperName.containsKey(devName)) {
                    namesToQuery.add(devName);
                }
            }

            if (namesToQuery.isEmpty()) {
                System.debug(LoggingLevel.DEBUG,
                    'QueueResolver.loadQueuesByDeveloperNames() no hay colas pendientes por consultar.'
                );
                return;
            }

            List<Group> queueGroups = [
                SELECT Id, Name, DeveloperName, Type
                FROM Group
                WHERE Type = 'Queue'
                  AND DeveloperName IN :namesToQuery
            ];

            System.debug(LoggingLevel.DEBUG,
                'QueueResolver.loadQueuesByDeveloperNames() query size=' + queueGroups.size()
            );

            for (Group queueGroup : queueGroups) {
                String normalizedDeveloperName = normalizeValue(queueGroup.DeveloperName);

                System.debug(LoggingLevel.DEBUG,
                    'QueueResolver.loadQueuesByDeveloperNames() ' +
                    'DeveloperName=' + queueGroup.DeveloperName +
                    ', Id=' + queueGroup.Id
                );

                queueIdByDeveloperName.put(normalizedDeveloperName, queueGroup.Id);
            }

            // Para evitar volver a consultar colas inexistentes en la misma transacción,
            // marcamos también los nombres no encontrados con null.
            for (String devName : namesToQuery) {
                if (!queueIdByDeveloperName.containsKey(devName)) {
                    System.debug(LoggingLevel.DEBUG,
                        'QueueResolver.loadQueuesByDeveloperNames() cola no encontrada: ' + devName
                    );
                    queueIdByDeveloperName.put(devName, null);
                }
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en QueueResolver.loadQueuesByDeveloperNames(): ' + e.getMessage()
            );
        }
    }

    /**
     * Limpia la caché. Útil para pruebas unitarias o reintentos controlados.
     */
    public static void clearCache() {
        System.debug(LoggingLevel.DEBUG, 'QueueResolver.clearCache()');

        try {
            queueIdByDeveloperName.clear();
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en QueueResolver.clearCache(): ' + e.getMessage()
            );
        }
    }

    /**
     * Normaliza valores para compararlos de forma consistente.
     */
    private static String normalizeValue(String value) {
        System.debug(LoggingLevel.DEBUG,
            'QueueResolver.normalizeValue() value=' + value
        );

        try {
            if (String.isBlank(value)) {
                return null;
            }

            return value.trim().toUpperCase();

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en QueueResolver.normalizeValue(): ' + e.getMessage()
            );
            return null;
        }
    }
}