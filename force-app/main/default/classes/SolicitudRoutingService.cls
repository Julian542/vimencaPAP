public with sharing class SolicitudRoutingService {

    private static final String FIELD_CODIGO_SOLICITUD     = 'Type';
    private static final String FIELD_CANAL                = 'CAS_Canal_distribucion__c';
    private static final String FIELD_PRODUCTO             = 'CAS_Codigo_de_producto__c';
    private static final String FIELD_NIVEL_RESOLUTOR      = 'CAS_Nivel_Resolutor__c';
    private static final String FIELD_GRUPO_RESOLUTOR      = 'Grupo_Resolutor_Actual__c';
    private static final String FIELD_ESCALAR_A_N3         = 'CAS_Escalar_A_N3__c';
    private static final String FIELD_MOTIVO_DEVOLUCION    = 'CAS_Motivo_Devolucion__c';
    private static final String FIELD_DEVOLVER_AL_ORIGEN   = 'CAS_Devolver_Al_Origen__c';
    private static final String FIELD_ORIGEN_OWNER_ID      = 'CAS_Origen_OwnerId__c';

    private static final String FALLBACK_QUEUE_DEV_NAME = 'Casos_Asignacion_Manual_Solicitudes';

    private static Map<String, Id> recordTypeIdByDeveloperName = new Map<String, Id>();
    private static String currentUserCanalAtencion;

    public static void applyInitialRouting(List<Case> newCases) {
        System.debug(LoggingLevel.DEBUG,
            'SolicitudRoutingService.applyInitialRouting() newCases.size()=' +
            (newCases != null ? newCases.size() : 0)
        );

        try {
            if (newCases == null || newCases.isEmpty()) {
                return;
            }

            preloadRecordTypes(newCases);

            for (Case caseRecord : newCases) {
                try {
                    if (!shouldRouteCase(caseRecord)) {
                        continue;
                    }

                    applyInitialRoutingToSingleCase(caseRecord);

                } catch (Exception innerEx) {
                    System.debug(LoggingLevel.ERROR,
                        'Error procesando un Case en applyInitialRouting(): ' + innerEx.getMessage()
                    );

                    assignFallbackQueue(caseRecord);
                }
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingService.applyInitialRouting(): ' + e.getMessage()
            );
        }
    }

    public static void applyUpdateRouting(List<Case> newCases, Map<Id, Case> oldMap) {
        System.debug(LoggingLevel.ERROR,
            'DEBUG SOL APPLY UPDATE | newCases.size=' + (newCases != null ? newCases.size() : 0)
        );

        try {
            if (newCases == null || newCases.isEmpty() || oldMap == null || oldMap.isEmpty()) {
                System.debug(LoggingLevel.ERROR,
                    'DEBUG SOL APPLY UPDATE | Sin datos para procesar.'
                );
                return;
            }

            for (Case caseRecord : newCases) {
                try {
                    System.debug(LoggingLevel.ERROR,
                        'DEBUG SOL APPLY UPDATE CASE | CaseId=' + caseRecord.Id +
                        ' | Type=' + caseRecord.Type +
                        ' | Status=' + caseRecord.Status +
                        ' | RecordTypeId=' + caseRecord.RecordTypeId +
                        ' | OwnerId=' + caseRecord.OwnerId
                    );

                    if (!shouldRouteCase(caseRecord)) {
                        System.debug(LoggingLevel.ERROR,
                            'DEBUG SOL APPLY UPDATE CASE | No califica shouldRouteCase. CaseId=' + caseRecord.Id
                        );
                        continue;
                    }

                    Case oldCase = oldMap.get(caseRecord.Id);

                    if (oldCase == null) {
                        System.debug(LoggingLevel.ERROR,
                            'DEBUG SOL APPLY UPDATE CASE | oldCase null. CaseId=' + caseRecord.Id
                        );
                        continue;
                    }

                    if (!shouldEvaluateUpdate(caseRecord, oldCase)) {
                        System.debug(LoggingLevel.ERROR,
                            'DEBUG SOL APPLY UPDATE CASE | No califica shouldEvaluateUpdate. CaseId=' + caseRecord.Id +
                            ' | oldStatus=' + oldCase.Status +
                            ' | newStatus=' + caseRecord.Status +
                            ' | oldOwner=' + oldCase.OwnerId +
                            ' | newOwner=' + caseRecord.OwnerId
                        );
                        continue;
                    }

                    applyUpdateRoutingToSingleCase(caseRecord, oldCase);

                } catch (Exception innerEx) {
                    System.debug(LoggingLevel.ERROR,
                        'Error procesando un Case en applyUpdateRouting(): ' + innerEx.getMessage()
                    );
                }
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingService.applyUpdateRouting(): ' + e.getMessage()
            );
        }
    }

    private static void applyInitialRoutingToSingleCase(Case caseRecord) {
        System.debug(LoggingLevel.DEBUG,
            'SolicitudRoutingService.applyInitialRoutingToSingleCase() caseRecord=' + caseRecord
        );

        try {
            Case routingCase = buildCaseForRouting(caseRecord);

            SolicitudRoutingConfigService.RoutingRuleResult routingResult =
                getMatchingRuleForCase(routingCase, false);

            System.debug(LoggingLevel.ERROR,
                'DEBUG SOL INITIAL ROUTING RESULT | CaseId=' + caseRecord.Id +
                ' | Type=' + caseRecord.Type +
                ' | CanalCase=' + getStringFieldValue(caseRecord, FIELD_CANAL) +
                ' | CanalRouting=' + getStringFieldValue(routingCase, FIELD_CANAL) +
                ' | foundRule=' + (routingResult != null ? routingResult.foundRule : null) +
                ' | message=' + (routingResult != null ? routingResult.message : null) +
                ' | rule=' + (routingResult != null && routingResult.rule != null ? routingResult.rule.DeveloperName : null)
            );

            if (routingResult == null || !routingResult.foundRule || routingResult.rule == null) {
                assignFallbackQueue(caseRecord);
                return;
            }

            Solicitud_Routing_Config__mdt rule = routingResult.rule;

            captureOriginOwner(caseRecord);
            assignRecordType(caseRecord, rule);
            assignInitialStatus(caseRecord, rule);
            assignInitialQueue(caseRecord, rule);
            assignInitialResolutionData(caseRecord, rule);

            FSC_SolicitudSLAService.assignEntitlementFromRule(caseRecord, rule);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingService.applyInitialRoutingToSingleCase(): ' + e.getMessage()
            );
            assignFallbackQueue(caseRecord);
        }
    }

    private static void applyUpdateRoutingToSingleCase(Case caseRecord, Case oldCase) {
        System.debug(LoggingLevel.ERROR,
            'DEBUG SOL UPDATE SINGLE START | CaseId=' + caseRecord.Id +
            ' | Type=' + caseRecord.Type +
            ' | oldStatus=' + oldCase.Status +
            ' | newStatus=' + caseRecord.Status +
            ' | oldOwner=' + oldCase.OwnerId +
            ' | newOwner=' + caseRecord.OwnerId
        );

        try {
            clearN3FlagIfOwnerChanged(caseRecord, oldCase);

            String normalizedStatus = normalizeValue(caseRecord.Status);
            Boolean explicitN3Request = hasExplicitN3Request(caseRecord, oldCase);

            Boolean useProduct = isN2Status(normalizedStatus) || explicitN3Request;

            Case routingCase = buildCaseForRouting(caseRecord);

            SolicitudRoutingConfigService.RoutingRuleResult routingResult =
                getMatchingRuleForCase(routingCase, useProduct);

            System.debug(LoggingLevel.ERROR,
                'DEBUG SOL ROUTING RESULT | CaseId=' + caseRecord.Id +
                ' | Type=' + caseRecord.Type +
                ' | CanalCase=' + getStringFieldValue(caseRecord, FIELD_CANAL) +
                ' | CanalRouting=' + getStringFieldValue(routingCase, FIELD_CANAL) +
                ' | Status=' + caseRecord.Status +
                ' | normalizedStatus=' + normalizedStatus +
                ' | useProduct=' + useProduct +
                ' | foundRule=' + (routingResult != null ? routingResult.foundRule : null) +
                ' | message=' + (routingResult != null ? routingResult.message : null) +
                ' | rule=' + (routingResult != null && routingResult.rule != null ? routingResult.rule.DeveloperName : null)
            );

            if (routingResult == null || !routingResult.foundRule || routingResult.rule == null) {
                return;
            }

            Solicitud_Routing_Config__mdt rule = routingResult.rule;

            System.debug(LoggingLevel.ERROR,
                'DEBUG SOL RULE DATA | CaseId=' + caseRecord.Id +
                ' | Rule=' + rule.DeveloperName +
                ' | QueueN1=' + rule.Queue_N1_DeveloperName__c +
                ' | QueueN2=' + rule.Queue_N2_DeveloperName__c +
                ' | QueueN3=' + rule.Queue_N3_DeveloperName__c +
                ' | QueueN4=' + rule.Queue_N4_DeveloperName__c +
                ' | GrupoN1=' + rule.Grupo_Resolutor_N1__c +
                ' | GrupoN2=' + rule.Grupo_Resolutor_N2__c +
                ' | GrupoN3=' + rule.Grupo_Resolutor_N3__c +
                ' | GrupoN4=' + rule.Grupo_Resolutor_N4__c
            );

            if (shouldApplyDevolucion(caseRecord, oldCase, rule)) {
                System.debug(LoggingLevel.ERROR,
                    'DEBUG SOL DEVOLUCION | ENTRA | CaseId=' + caseRecord.Id +
                    ' | StatusAntes=' + caseRecord.Status +
                    ' | OwnerAntes=' + caseRecord.OwnerId +
                    ' | NivelAntes=' + getStringFieldValue(caseRecord, FIELD_NIVEL_RESOLUTOR) +
                    ' | GrupoAntes=' + getStringFieldValue(caseRecord, FIELD_GRUPO_RESOLUTOR) +
                    ' | StatusInicialCMDT=' + rule.Status_Inicial__c +
                    ' | NivelInicialCMDT=' + rule.Nivel_Inicial__c
                );

                applyDevolucionRouting(caseRecord, rule);
                assignInitialQueue(caseRecord, rule);
                assignInitialResolutionData(caseRecord, rule);
                clearN3FlagIfOwnerChanged(caseRecord, oldCase);

                System.debug(LoggingLevel.ERROR,
                    'DEBUG SOL DEVOLUCION | SALE | CaseId=' + caseRecord.Id +
                    ' | StatusDespues=' + caseRecord.Status +
                    ' | OwnerDespues=' + caseRecord.OwnerId +
                    ' | NivelDespues=' + getStringFieldValue(caseRecord, FIELD_NIVEL_RESOLUTOR) +
                    ' | GrupoDespues=' + getStringFieldValue(caseRecord, FIELD_GRUPO_RESOLUTOR) +
                    ' | DevolverDespues=' + getBooleanFieldValue(caseRecord, FIELD_DEVOLVER_AL_ORIGEN) +
                    ' | EscalarN3Despues=' + getBooleanFieldValue(caseRecord, FIELD_ESCALAR_A_N3)
                );

                return;
            }

            if (explicitN3Request) {
                if (!String.isBlank(rule.Queue_N3_DeveloperName__c)) {
                    assignQueueAndResolution(
                        caseRecord,
                        rule.Queue_N3_DeveloperName__c,
                        rule.Grupo_Resolutor_N3__c,
                        'N3'
                    );
                    clearN3FlagIfOwnerChanged(caseRecord, oldCase);
                }

                return;
            }

            if (isInitialStatus(caseRecord.Status, rule)) {
                System.debug(LoggingLevel.ERROR,
                    'DEBUG SOL ROUTING INITIAL STATUS | CaseId=' + caseRecord.Id +
                    ' | Status=' + caseRecord.Status +
                    ' | NivelInicial=' + rule.Nivel_Inicial__c +
                    ' | QueueN0=' + rule.Queue_N0_DeveloperName__c
                );

                assignInitialQueue(caseRecord, rule);
                assignInitialResolutionData(caseRecord, rule);
                clearN3FlagIfOwnerChanged(caseRecord, oldCase);
                return;
            }

            if (isN4Status(normalizedStatus)) {
                System.debug(LoggingLevel.ERROR,
                    'DEBUG SOL ROUTING N4 | CaseId=' + caseRecord.Id +
                    ' | QueueN4=' + rule.Queue_N4_DeveloperName__c
                );

                assignQueueAndResolution(caseRecord, rule.Queue_N4_DeveloperName__c, rule.Grupo_Resolutor_N4__c, 'N4');
                clearN3FlagIfOwnerChanged(caseRecord, oldCase);
                return;
            }

            if (isAutomaticN3Status(normalizedStatus)) {
                System.debug(LoggingLevel.ERROR,
                    'DEBUG SOL ROUTING N3 | CaseId=' + caseRecord.Id +
                    ' | QueueN3=' + rule.Queue_N3_DeveloperName__c
                );

                assignQueueAndResolution(caseRecord, rule.Queue_N3_DeveloperName__c, rule.Grupo_Resolutor_N3__c, 'N3');
                clearN3FlagIfOwnerChanged(caseRecord, oldCase);
                return;
            }

            if (isN2Status(normalizedStatus)) {
                System.debug(LoggingLevel.ERROR,
                    'DEBUG SOL ROUTING N2 | CaseId=' + caseRecord.Id +
                    ' | Status=' + caseRecord.Status +
                    ' | normalizedStatus=' + normalizedStatus +
                    ' | QueueN2=' + rule.Queue_N2_DeveloperName__c +
                    ' | GrupoN2=' + rule.Grupo_Resolutor_N2__c
                );

                assignQueueAndResolution(caseRecord, rule.Queue_N2_DeveloperName__c, rule.Grupo_Resolutor_N2__c, 'N2');
                clearN3FlagIfOwnerChanged(caseRecord, oldCase);
                return;
            }

            if (isN1Status(normalizedStatus)) {
                System.debug(LoggingLevel.ERROR,
                    'DEBUG SOL ROUTING N1 | CaseId=' + caseRecord.Id +
                    ' | QueueN1=' + rule.Queue_N1_DeveloperName__c
                );

                assignQueueAndResolution(caseRecord, rule.Queue_N1_DeveloperName__c, rule.Grupo_Resolutor_N1__c, 'N1');
                clearN3FlagIfOwnerChanged(caseRecord, oldCase);
                return;
            }

            System.debug(LoggingLevel.ERROR,
                'DEBUG SOL ROUTING NO STATUS MATCH | CaseId=' + caseRecord.Id +
                ' | Status=' + caseRecord.Status +
                ' | normalizedStatus=' + normalizedStatus
            );

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingService.applyUpdateRoutingToSingleCase(): ' + e.getMessage()
            );
        }
    }

    private static Case buildCaseForRouting(Case caseRecord) {
        try {
            if (caseRecord == null) {
                return null;
            }

            Case routingCase = caseRecord.clone(false, true, false, false);

            String canalActual = getStringFieldValue(routingCase, FIELD_CANAL);

            if (String.isBlank(canalActual)) {
                String canalUsuario = getCurrentUserCanalAtencion();

                if (!String.isBlank(canalUsuario)) {
                    routingCase.put(FIELD_CANAL, canalUsuario);
                }
            }

            System.debug(LoggingLevel.ERROR,
                'DEBUG SOL BUILD ROUTING CASE | CaseId=' + caseRecord.Id +
                ' | CanalCase=' + getStringFieldValue(caseRecord, FIELD_CANAL) +
                ' | CanalRouting=' + getStringFieldValue(routingCase, FIELD_CANAL)
            );

            return routingCase;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingService.buildCaseForRouting(): ' + e.getMessage()
            );
            return caseRecord;
        }
    }

    private static String getCurrentUserCanalAtencion() {
        try {
            if (currentUserCanalAtencion != null) {
                return currentUserCanalAtencion;
            }

            currentUserCanalAtencion = '';

            User currentUser = [
                SELECT Canal_Atencion__c
                FROM User
                WHERE Id = :UserInfo.getUserId()
                LIMIT 1
            ];

            if (currentUser != null && !String.isBlank(currentUser.Canal_Atencion__c)) {
                currentUserCanalAtencion = currentUser.Canal_Atencion__c;
            }

            return currentUserCanalAtencion;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingService.getCurrentUserCanalAtencion(): ' + e.getMessage()
            );
            currentUserCanalAtencion = '';
            return currentUserCanalAtencion;
        }
    }

    private static SolicitudRoutingConfigService.RoutingRuleResult getMatchingRuleForCase(
        Case caseRecord,
        Boolean useProduct
    ) {
        try {
            return SolicitudRoutingConfigService.getMatchingRuleFromCase(
                caseRecord,
                FIELD_CODIGO_SOLICITUD,
                FIELD_CANAL,
                useProduct ? FIELD_PRODUCTO : null
            );
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingService.getMatchingRuleForCase(): ' + e.getMessage()
            );
            return new SolicitudRoutingConfigService.RoutingRuleResult();
        }
    }

    private static Boolean shouldRouteCase(Case caseRecord) {
        try {
            if (caseRecord == null) {
                return false;
            }

            String codigoSolicitud = getStringFieldValue(caseRecord, FIELD_CODIGO_SOLICITUD);

            return !String.isBlank(codigoSolicitud);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingService.shouldRouteCase(): ' + e.getMessage()
            );
            return false;
        }
    }

    private static Boolean shouldEvaluateUpdate(Case caseRecord, Case oldCase) {
        try {
            if (caseRecord == null || oldCase == null) {
                return false;
            }

            Boolean statusChanged = caseRecord.Status != oldCase.Status;
            Boolean devolverChanged = getBooleanFieldValue(caseRecord, FIELD_DEVOLVER_AL_ORIGEN) !=
                                      getBooleanFieldValue(oldCase, FIELD_DEVOLVER_AL_ORIGEN);
            Boolean escalarChanged = getBooleanFieldValue(caseRecord, FIELD_ESCALAR_A_N3) !=
                                     getBooleanFieldValue(oldCase, FIELD_ESCALAR_A_N3);
            Boolean ownerChanged = caseRecord.OwnerId != oldCase.OwnerId;
            Boolean devolverSolicitado = getBooleanFieldValue(caseRecord, FIELD_DEVOLVER_AL_ORIGEN) == true;

            System.debug(LoggingLevel.ERROR,
                'DEBUG SOL SHOULD EVALUATE | CaseId=' + caseRecord.Id +
                ' | statusChanged=' + statusChanged +
                ' | devolverChanged=' + devolverChanged +
                ' | devolverSolicitado=' + devolverSolicitado +
                ' | escalarChanged=' + escalarChanged +
                ' | ownerChanged=' + ownerChanged +
                ' | oldStatus=' + oldCase.Status +
                ' | newStatus=' + caseRecord.Status +
                ' | oldDevolver=' + getBooleanFieldValue(oldCase, FIELD_DEVOLVER_AL_ORIGEN) +
                ' | newDevolver=' + getBooleanFieldValue(caseRecord, FIELD_DEVOLVER_AL_ORIGEN)
            );

            return statusChanged || devolverChanged || devolverSolicitado || escalarChanged || ownerChanged;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingService.shouldEvaluateUpdate(): ' + e.getMessage()
            );
            return false;
        }
    }

    private static void assignRecordType(Case caseRecord, Solicitud_Routing_Config__mdt rule) {
        try {
            if (caseRecord == null || rule == null) {
                return;
            }

            String rtDeveloperName = normalizeValue(rule.RecordType_DeveloperName__c);

            if (String.isBlank(rtDeveloperName)) {
                return;
            }

            Id recordTypeId = getRecordTypeIdByDeveloperName(rtDeveloperName);

            if (recordTypeId != null) {
                caseRecord.RecordTypeId = recordTypeId;
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingService.assignRecordType(): ' + e.getMessage()
            );
        }
    }

    private static void assignInitialStatus(Case caseRecord, Solicitud_Routing_Config__mdt rule) {
        try {
            if (caseRecord == null || rule == null) {
                return;
            }

            if (!String.isBlank(rule.Status_Inicial__c)) {
                caseRecord.Status = rule.Status_Inicial__c;
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingService.assignInitialStatus(): ' + e.getMessage()
            );
        }
    }

    private static void assignInitialQueue(Case caseRecord, Solicitud_Routing_Config__mdt rule) {
        try {
            if (caseRecord == null || rule == null) {
                return;
            }

            String nivelInicial = normalizeValue(rule.Nivel_Inicial__c);
            String queueDeveloperName;

            if (nivelInicial == 'N0') {
                queueDeveloperName = rule.Queue_N0_DeveloperName__c;
            } else if (nivelInicial == 'N2') {
                queueDeveloperName = rule.Queue_N2_DeveloperName__c;
            } else if (nivelInicial == 'N3') {
                queueDeveloperName = rule.Queue_N3_DeveloperName__c;
            } else if (nivelInicial == 'N4') {
                queueDeveloperName = rule.Queue_N4_DeveloperName__c;
            } else {
                queueDeveloperName = rule.Queue_N1_DeveloperName__c;
            }

            Id queueId = QueueResolver.getQueueIdByDeveloperName(queueDeveloperName);

            System.debug(LoggingLevel.ERROR,
                'DEBUG SOL INITIAL QUEUE | CaseId=' + caseRecord.Id +
                ' | nivelInicial=' + nivelInicial +
                ' | queueDeveloperName=' + queueDeveloperName +
                ' | queueId=' + queueId
            );

            if (queueId != null) {
                caseRecord.OwnerId = queueId;
            } else {
                assignFallbackQueue(caseRecord);
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingService.assignInitialQueue(): ' + e.getMessage()
            );
            assignFallbackQueue(caseRecord);
        }
    }

    private static void assignInitialResolutionData(Case caseRecord, Solicitud_Routing_Config__mdt rule) {
        try {
            if (caseRecord == null || rule == null) {
                return;
            }

            String nivelInicial = normalizeValue(rule.Nivel_Inicial__c);
            String grupoResolutorActual;

            if (!String.isBlank(rule.Nivel_Inicial__c)) {
                caseRecord.put(FIELD_NIVEL_RESOLUTOR, rule.Nivel_Inicial__c);
            }

            if (nivelInicial == 'N0') {
                grupoResolutorActual = rule.Grupo_Resolutor_N0__c;
            } else if (nivelInicial == 'N2') {
                grupoResolutorActual = rule.Grupo_Resolutor_N2__c;
            } else if (nivelInicial == 'N3') {
                grupoResolutorActual = rule.Grupo_Resolutor_N3__c;
            } else if (nivelInicial == 'N4') {
                grupoResolutorActual = rule.Grupo_Resolutor_N4__c;
            } else {
                grupoResolutorActual = rule.Grupo_Resolutor_N1__c;
            }

            if (!String.isBlank(grupoResolutorActual)) {
                caseRecord.put(FIELD_GRUPO_RESOLUTOR, grupoResolutorActual);
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingService.assignInitialResolutionData(): ' + e.getMessage()
            );
        }
    }

    private static void assignQueueAndResolution(
        Case caseRecord,
        String queueDeveloperName,
        String grupoResolutor,
        String nivelResolutor
    ) {
        try {
            if (caseRecord == null) {
                return;
            }

            Id queueId = QueueResolver.getQueueIdByDeveloperName(queueDeveloperName);

            System.debug(LoggingLevel.ERROR,
                'DEBUG SOL ASSIGN QUEUE | CaseId=' + caseRecord.Id +
                ' | queueDeveloperName=' + queueDeveloperName +
                ' | queueId=' + queueId +
                ' | ownerBefore=' + caseRecord.OwnerId +
                ' | nivelResolutor=' + nivelResolutor +
                ' | grupoResolutor=' + grupoResolutor
            );

            if (queueId != null) {
                caseRecord.OwnerId = queueId;

                System.debug(LoggingLevel.ERROR,
                    'DEBUG SOL ASSIGN QUEUE OK | CaseId=' + caseRecord.Id +
                    ' | ownerAfter=' + caseRecord.OwnerId
                );
            } else {
                assignFallbackQueue(caseRecord);
            }

            if (!String.isBlank(nivelResolutor)) {
                caseRecord.put(FIELD_NIVEL_RESOLUTOR, nivelResolutor);
            }

            if (!String.isBlank(grupoResolutor)) {
                caseRecord.put(FIELD_GRUPO_RESOLUTOR, grupoResolutor);
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingService.assignQueueAndResolution(): ' + e.getMessage()
            );
        }
    }

    private static Boolean shouldApplyDevolucion(
        Case caseRecord,
        Case oldCase,
        Solicitud_Routing_Config__mdt rule
    ) {
        try {
            if (caseRecord == null || oldCase == null || rule == null) {
                System.debug(LoggingLevel.ERROR,
                    'DEBUG SOL DEVOLUCION CHECK | Datos insuficientes.'
                );
                return false;
            }

            Boolean newDevolver = getBooleanFieldValue(caseRecord, FIELD_DEVOLVER_AL_ORIGEN);
            Boolean oldDevolver = getBooleanFieldValue(oldCase, FIELD_DEVOLVER_AL_ORIGEN);
            String motivo = getStringFieldValue(caseRecord, FIELD_MOTIVO_DEVOLUCION);

            System.debug(LoggingLevel.ERROR,
                'DEBUG SOL DEVOLUCION CHECK | CaseId=' + caseRecord.Id +
                ' | PermiteDevolucion=' + rule.Permite_Devolucion__c +
                ' | oldDevolver=' + oldDevolver +
                ' | newDevolver=' + newDevolver +
                ' | motivo=' + motivo +
                ' | oldStatus=' + oldCase.Status +
                ' | newStatus=' + caseRecord.Status +
                ' | statusInicialCMDT=' + rule.Status_Inicial__c
            );

            if (!rule.Permite_Devolucion__c) {
                return false;
            }

            if (newDevolver == true && String.isBlank(motivo)) {
                caseRecord.addError('Debe indicar el motivo de devolución.');
                return false;
            }

            return newDevolver == true;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingService.shouldApplyDevolucion(): ' + e.getMessage()
            );
            return false;
        }
    }

    private static void applyDevolucionRouting(Case caseRecord, Solicitud_Routing_Config__mdt rule) {
        try {
            if (caseRecord == null) {
                return;
            }

            String statusInicial = rule != null && !String.isBlank(rule.Status_Inicial__c)
                ? rule.Status_Inicial__c
                : 'Crear Solicitud';

            System.debug(LoggingLevel.ERROR,
                'DEBUG SOL APPLY DEVOLUCION | CaseId=' + caseRecord.Id +
                ' | StatusAntes=' + caseRecord.Status +
                ' | StatusInicial=' + statusInicial +
                ' | DevolverAntes=' + getBooleanFieldValue(caseRecord, FIELD_DEVOLVER_AL_ORIGEN) +
                ' | EscalarN3Antes=' + getBooleanFieldValue(caseRecord, FIELD_ESCALAR_A_N3)
            );

            caseRecord.Status = statusInicial;
            caseRecord.put(FIELD_DEVOLVER_AL_ORIGEN, false);
            caseRecord.put(FIELD_ESCALAR_A_N3, false);

            System.debug(LoggingLevel.ERROR,
                'DEBUG SOL APPLY DEVOLUCION RESULT | CaseId=' + caseRecord.Id +
                ' | StatusDespues=' + caseRecord.Status +
                ' | DevolverDespues=' + getBooleanFieldValue(caseRecord, FIELD_DEVOLVER_AL_ORIGEN) +
                ' | EscalarN3Despues=' + getBooleanFieldValue(caseRecord, FIELD_ESCALAR_A_N3)
            );

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingService.applyDevolucionRouting(): ' + e.getMessage()
            );
        }
    }

    private static Boolean hasExplicitN3Request(Case caseRecord, Case oldCase) {
        try {
            if (caseRecord == null || oldCase == null) {
                return false;
            }

            Boolean newValue = getBooleanFieldValue(caseRecord, FIELD_ESCALAR_A_N3);
            Boolean oldValue = getBooleanFieldValue(oldCase, FIELD_ESCALAR_A_N3);

            return newValue == true && oldValue != true;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingService.hasExplicitN3Request(): ' + e.getMessage()
            );
            return false;
        }
    }

    private static void clearN3FlagIfOwnerChanged(Case caseRecord, Case oldCase) {
        try {
            if (caseRecord == null || oldCase == null) {
                return;
            }

            Boolean n3Flag = getBooleanFieldValue(caseRecord, FIELD_ESCALAR_A_N3);
            Boolean ownerChanged = caseRecord.OwnerId != oldCase.OwnerId;

            if (n3Flag == true && ownerChanged) {
                caseRecord.put(FIELD_ESCALAR_A_N3, false);
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingService.clearN3FlagIfOwnerChanged(): ' + e.getMessage()
            );
        }
    }

    private static Boolean isInitialStatus(String status, Solicitud_Routing_Config__mdt rule) {
        try {
            if (String.isBlank(status)) {
                return false;
            }

            String normalizedStatus = normalizeValue(status);
            String normalizedInitialStatus = rule != null
                ? normalizeValue(rule.Status_Inicial__c)
                : null;

            if (!String.isBlank(normalizedInitialStatus)) {
                return normalizedStatus == normalizedInitialStatus;
            }

            return normalizedStatus == 'CREAR SOLICITUD';

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingService.isInitialStatus(): ' + e.getMessage()
            );
            return false;
        }
    }

    private static Boolean isN1Status(String normalizedStatus) {
        try {
            Set<String> n1Statuses = new Set<String>{
                'VALIDACION',
                'VALIDACIÓN',
                'VERIFICACION DEL CASO',
                'VERIFICACIÓN DEL CASO'
            };

            return !String.isBlank(normalizedStatus) && n1Statuses.contains(normalizedStatus);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingService.isN1Status(): ' + e.getMessage()
            );
            return false;
        }
    }

    private static Boolean isN2Status(String normalizedStatus) {
        try {
            Set<String> n2Statuses = new Set<String>{
                'ANALISIS',
                'ANÁLISIS',
                'ANALISIS DEL CASO',
                'ANÁLISIS DEL CASO'
            };

            return !String.isBlank(normalizedStatus) && n2Statuses.contains(normalizedStatus);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingService.isN2Status(): ' + e.getMessage()
            );
            return false;
        }
    }

    private static Boolean isAutomaticN3Status(String normalizedStatus) {
        try {
            Set<String> n3Statuses = new Set<String>{
                'PROCESAMIENTO',
                'PROCESAMIENTO DEL CASO',
                'ACTUALIZACION DE DATA CREDITO',
                'ACTUALIZACIÓN DE DATA CRÉDITO'
            };

            return !String.isBlank(normalizedStatus) && n3Statuses.contains(normalizedStatus);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingService.isAutomaticN3Status(): ' + e.getMessage()
            );
            return false;
        }
    }

    private static Boolean isN4Status(String normalizedStatus) {
        try {
            Set<String> n4Statuses = new Set<String>{
                'RESOLUCION Y CIERRE',
                'RESOLUCIÓN Y CIERRE',
                'RESOLUCION',
                'RESOLUCIÓN',
                'CIERRE'
            };

            return !String.isBlank(normalizedStatus) && n4Statuses.contains(normalizedStatus);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingService.isN4Status(): ' + e.getMessage()
            );
            return false;
        }
    }

    private static void assignFallbackQueue(Case caseRecord) {
        try {
            if (caseRecord == null) {
                return;
            }

            Id fallbackQueueId = QueueResolver.getQueueIdByDeveloperName(FALLBACK_QUEUE_DEV_NAME);

            System.debug(LoggingLevel.ERROR,
                'DEBUG SOL FALLBACK QUEUE | CaseId=' + caseRecord.Id +
                ' | fallbackQueue=' + FALLBACK_QUEUE_DEV_NAME +
                ' | fallbackQueueId=' + fallbackQueueId
            );

            if (fallbackQueueId != null) {
                caseRecord.OwnerId = fallbackQueueId;
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingService.assignFallbackQueue(): ' + e.getMessage()
            );
        }
    }

    private static void captureOriginOwner(Case caseRecord) {
        try {
            if (caseRecord == null) {
                return;
            }

            String origenOwnerId = getStringFieldValue(caseRecord, FIELD_ORIGEN_OWNER_ID);

            if (!String.isBlank(origenOwnerId)) {
                return;
            }

            Id ownerToSave = caseRecord.OwnerId;

            if (ownerToSave == null) {
                ownerToSave = UserInfo.getUserId();
            }

            if (ownerToSave != null) {
                caseRecord.put(FIELD_ORIGEN_OWNER_ID, String.valueOf(ownerToSave));
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingService.captureOriginOwner(): ' + e.getMessage()
            );
        }
    }

    private static void preloadRecordTypes(List<Case> newCases) {
        try {
            if (newCases == null || newCases.isEmpty()) {
                return;
            }

            Set<String> solicitudValues = new Set<String>();

            for (Case c : newCases) {
                String codigo = getStringFieldValue(c, FIELD_CODIGO_SOLICITUD);
                String normalizedCodigo = normalizeValue(codigo);

                if (!String.isBlank(normalizedCodigo)) {
                    solicitudValues.add(normalizedCodigo);
                }
            }

            if (solicitudValues.isEmpty()) {
                return;
            }

            List<Solicitud_Routing_Config__mdt> configs = [
                SELECT Codigo_Solicitud__c, Descripcion_Solicitud__c, RecordType_DeveloperName__c
                FROM Solicitud_Routing_Config__mdt
                WHERE Activo__c = true
            ];

            Set<String> rtDeveloperNames = new Set<String>();

            for (Solicitud_Routing_Config__mdt cfg : configs) {
                String codigoCfg = normalizeValue(cfg.Codigo_Solicitud__c);
                String descripcionCfg = normalizeValue(cfg.Descripcion_Solicitud__c);

                if (solicitudValues.contains(codigoCfg) || solicitudValues.contains(descripcionCfg)) {
                    String rtName = normalizeValue(cfg.RecordType_DeveloperName__c);

                    if (!String.isBlank(rtName)) {
                        rtDeveloperNames.add(rtName);
                    }
                }
            }

            if (rtDeveloperNames.isEmpty()) {
                return;
            }

            List<RecordType> recordTypes = [
                SELECT Id, DeveloperName
                FROM RecordType
                WHERE SObjectType = 'Case'
                  AND DeveloperName IN :rtDeveloperNames
            ];

            for (RecordType rt : recordTypes) {
                recordTypeIdByDeveloperName.put(normalizeValue(rt.DeveloperName), rt.Id);
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingService.preloadRecordTypes(): ' + e.getMessage()
            );
        }
    }

    private static Id getRecordTypeIdByDeveloperName(String developerName) {
        try {
            String normalizedDeveloperName = normalizeValue(developerName);

            if (String.isBlank(normalizedDeveloperName)) {
                return null;
            }

            if (recordTypeIdByDeveloperName.containsKey(normalizedDeveloperName)) {
                return recordTypeIdByDeveloperName.get(normalizedDeveloperName);
            }

            List<RecordType> recordTypes = [
                SELECT Id, DeveloperName
                FROM RecordType
                WHERE SObjectType = 'Case'
                  AND DeveloperName = :normalizedDeveloperName
                LIMIT 1
            ];

            if (!recordTypes.isEmpty()) {
                recordTypeIdByDeveloperName.put(normalizedDeveloperName, recordTypes[0].Id);
                return recordTypes[0].Id;
            }

            recordTypeIdByDeveloperName.put(normalizedDeveloperName, null);
            return null;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingService.getRecordTypeIdByDeveloperName(): ' + e.getMessage()
            );
            return null;
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
                'Error en SolicitudRoutingService.getStringFieldValue(): ' + e.getMessage()
            );
            return null;
        }
    }

    private static Boolean getBooleanFieldValue(SObject sobj, String fieldApiName) {
        try {
            if (sobj == null || String.isBlank(fieldApiName)) {
                return false;
            }

            Object rawValue = sobj.get(fieldApiName);

            if (rawValue == null) {
                return false;
            }

            if (rawValue instanceof Boolean) {
                return (Boolean) rawValue;
            }

            return String.valueOf(rawValue).toLowerCase() == 'true';

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingService.getBooleanFieldValue(): ' + e.getMessage()
            );
            return false;
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
                'Error en SolicitudRoutingService.normalizeValue(): ' + e.getMessage()
            );
            return null;
        }
    }

    public static void clearCache() {
        try {
            recordTypeIdByDeveloperName.clear();
            currentUserCanalAtencion = null;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en SolicitudRoutingService.clearCache(): ' + e.getMessage()
            );
        }
    }
}