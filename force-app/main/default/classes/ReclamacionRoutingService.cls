public with sharing class ReclamacionRoutingService {

    private static final String FIELD_CODIGO_RECLAMACION   = 'Type';
    private static final String FIELD_CANAL                = 'CAS_Canal_distribucion__c';
    private static final String FIELD_PRODUCTO             = 'CAS_Producto_a_Reclamar__c';
    private static final String FIELD_NIVEL_RESOLUTOR      = 'CAS_Nivel_Resolutor__c';
    private static final String FIELD_GRUPO_RESOLUTOR      = 'Grupo_Resolutor_Actual__c';
    private static final String FIELD_ESCALAR_A_N3         = 'CAS_Escalar_A_N3__c';
    private static final String FIELD_MOTIVO_DEVOLUCION    = 'CAS_Motivo_Devolucion__c';
    private static final String FIELD_DEVOLVER_AL_ORIGEN   = 'CAS_Devolver_Al_Origen__c';
    private static final String FIELD_ORIGEN_OWNER_ID      = 'CAS_Origen_OwnerId__c';

    private static final String NIVEL_CANAL_RECLAMACION    = 'CANAL_RECLAMACION';

    private static final String FALLBACK_QUEUE_DEV_NAME = 'Casos_Asignacion_Manual_Reclamaciones';

    private static Map<String, Id> recordTypeIdByDeveloperName = new Map<String, Id>();
    private static String currentUserCanalAtencion;

    public static void applyInitialRouting(List<Case> newCases) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingService.applyInitialRouting() newCases.size()=' +
            (newCases != null ? newCases.size() : 0)
        );

        try {
            if (newCases == null || newCases.isEmpty()) {
                System.debug(LoggingLevel.DEBUG,
                    'ReclamacionRoutingService.applyInitialRouting() no hay casos para procesar.'
                );
                return;
            }

            preloadRecordTypes(newCases);

            for (Case caseRecord : newCases) {
                System.debug(LoggingLevel.DEBUG,
                    'ReclamacionRoutingService.applyInitialRouting() procesando Case=' + caseRecord
                );

                try {
                    if (!shouldRouteCase(caseRecord)) {
                        System.debug(LoggingLevel.DEBUG,
                            'ReclamacionRoutingService.applyInitialRouting() el caso no califica para ruteo.'
                        );
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
                'Error en ReclamacionRoutingService.applyInitialRouting(): ' + e.getMessage()
            );
        }
    }

    public static void applyUpdateRouting(List<Case> newCases, Map<Id, Case> oldMap) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingService.applyUpdateRouting() newCases.size()=' +
            (newCases != null ? newCases.size() : 0)
        );

        try {
            if (newCases == null || newCases.isEmpty() || oldMap == null || oldMap.isEmpty()) {
                System.debug(LoggingLevel.DEBUG,
                    'ReclamacionRoutingService.applyUpdateRouting() no hay datos para procesar.'
                );
                return;
            }

            for (Case caseRecord : newCases) {
                System.debug(LoggingLevel.DEBUG,
                    'ReclamacionRoutingService.applyUpdateRouting() procesando Case=' + caseRecord
                );

                try {
                    if (!shouldRouteCase(caseRecord)) {
                        continue;
                    }

                    Case oldCase = oldMap.get(caseRecord.Id);

                    if (oldCase == null) {
                        continue;
                    }

                    if (!shouldEvaluateUpdate(caseRecord, oldCase)) {
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
                'Error en ReclamacionRoutingService.applyUpdateRouting(): ' + e.getMessage()
            );
        }
    }

    private static void applyInitialRoutingToSingleCase(Case caseRecord) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingService.applyInitialRoutingToSingleCase() caseRecord=' + caseRecord
        );

        try {
            ReclamacionRoutingConfigService.RoutingRuleResult routingResult =
                getMatchingRuleForCase(caseRecord, false);

            System.debug(LoggingLevel.DEBUG,
                'ReclamacionRoutingService.applyInitialRoutingToSingleCase() ' +
                'foundRule=' + (routingResult != null ? routingResult.foundRule : null) +
                ', message=' + (routingResult != null ? routingResult.message : null) +
                ', rule=' + (routingResult != null && routingResult.rule != null ? routingResult.rule.DeveloperName : null)
            );

            if (routingResult == null || !routingResult.foundRule || routingResult.rule == null) {
                assignFallbackQueue(caseRecord);
                return;
            }

            System.debug(LoggingLevel.DEBUG,
                'SLA 1 ' + caseRecord
            );

            Reclamacion_Routing_Config__mdt rule = routingResult.rule;

            System.debug(LoggingLevel.DEBUG,
                'SLA 2 ' + rule
            );

            FSC_SolicitudSLAService.assignReclamacionEntitlementFromRule(caseRecord, rule);

            captureOriginOwner(caseRecord);
            assignRecordType(caseRecord, rule);
            assignInitialStatus(caseRecord, rule);
            assignInitialQueue(caseRecord, rule);
            assignInitialResolutionData(caseRecord, rule);

            

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingService.applyInitialRoutingToSingleCase(): ' + e.getMessage()
            );
            assignFallbackQueue(caseRecord);
        }
    }

    private static void applyUpdateRoutingToSingleCase(Case caseRecord, Case oldCase) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingService.applyUpdateRoutingToSingleCase() caseRecord=' + caseRecord +
            ', oldCase=' + oldCase
        );

        try {
            clearN3FlagIfOwnerChanged(caseRecord, oldCase);

            String normalizedStatus = normalizeValue(caseRecord.Status);
            Boolean explicitN3Request = hasExplicitN3Request(caseRecord, oldCase);

            String currentNivelResolutor = normalizeValue(
                getStringFieldValue(caseRecord, FIELD_NIVEL_RESOLUTOR)
            );

            System.debug(LoggingLevel.DEBUG,
                'ReclamacionRoutingService.applyUpdateRoutingToSingleCase() currentNivelResolutor=' +
                currentNivelResolutor
            );

            Boolean useProduct = isN2Status(normalizedStatus) || explicitN3Request;

            ReclamacionRoutingConfigService.RoutingRuleResult routingResult =
                getMatchingRuleForCase(caseRecord, useProduct);

            System.debug(LoggingLevel.DEBUG,
                'ReclamacionRoutingService.applyUpdateRoutingToSingleCase() ' +
                'useProduct=' + useProduct +
                ', explicitN3Request=' + explicitN3Request +
                ', foundRule=' + (routingResult != null ? routingResult.foundRule : null) +
                ', message=' + (routingResult != null ? routingResult.message : null) +
                ', rule=' + (routingResult != null && routingResult.rule != null ? routingResult.rule.DeveloperName : null)
            );

            if (routingResult == null || !routingResult.foundRule || routingResult.rule == null) {
                System.debug(LoggingLevel.DEBUG,
                    'ReclamacionRoutingService.applyUpdateRoutingToSingleCase() sin regla. No se aplica ruteo.'
                );
                return;
            }

            Reclamacion_Routing_Config__mdt rule = routingResult.rule;

            if (shouldApplyDevolucion(caseRecord, oldCase, rule)) {
                System.debug(LoggingLevel.ERROR,
                    'DEBUG REC DEVOLUCION | ENTRA | CaseId=' + caseRecord.Id +
                    ' | StatusAntes=' + caseRecord.Status +
                    ' | OwnerAntes=' + caseRecord.OwnerId +
                    ' | NivelAntes=' + getStringFieldValue(caseRecord, FIELD_NIVEL_RESOLUTOR) +
                    ' | GrupoAntes=' + getStringFieldValue(caseRecord, FIELD_GRUPO_RESOLUTOR) +
                    ' | StatusInicialCMDT=' + rule.Status_Inicial__c +
                    ' | NivelInicialCMDT=' + rule.Nivel_Inicial__c +
                    ' | StatusCanalReclamacionCMDT=' + rule.Status_Canal_Reclamacion__c
                );

                applyDevolucionRouting(caseRecord, rule);
                assignInitialQueue(caseRecord, rule);
                assignInitialResolutionData(caseRecord, rule);
                clearN3FlagIfOwnerChanged(caseRecord, oldCase);

                System.debug(LoggingLevel.ERROR,
                    'DEBUG REC DEVOLUCION | SALE | CaseId=' + caseRecord.Id +
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
                if (!String.isBlank(rule.Queue_N3_DeveloperName__c) && currentNivelResolutor != 'N3') {
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
                    'DEBUG REC ROUTING INITIAL STATUS | CaseId=' + caseRecord.Id +
                    ' | Status=' + caseRecord.Status +
                    ' | NivelInicial=' + rule.Nivel_Inicial__c +
                    ' | StatusCanalReclamacion=' + rule.Status_Canal_Reclamacion__c
                );

                assignInitialQueue(caseRecord, rule);
                assignInitialResolutionData(caseRecord, rule);
                clearN3FlagIfOwnerChanged(caseRecord, oldCase);
                return;
            }

            System.debug(LoggingLevel.DEBUG,
                'ReclamacionRoutingService.applyUpdateRoutingToSingleCase() normalizedStatus=' + normalizedStatus
            );

            if (isAutomaticN3Status(normalizedStatus)) {
                if (currentNivelResolutor != 'N3') {
                    assignQueueAndResolution(
                        caseRecord,
                        rule.Queue_N3_DeveloperName__c,
                        rule.Grupo_Resolutor_N3__c,
                        'N3'
                    );
                }

                clearN3FlagIfOwnerChanged(caseRecord, oldCase);
                return;
            }

            if (isN2Status(normalizedStatus)) {
                if (currentNivelResolutor != 'N2') {
                    assignQueueAndResolution(
                        caseRecord,
                        rule.Queue_N2_DeveloperName__c,
                        rule.Grupo_Resolutor_N2__c,
                        'N2'
                    );
                }

                clearN3FlagIfOwnerChanged(caseRecord, oldCase);
                return;
            }

            if (isN1Status(normalizedStatus)) {
                if (currentNivelResolutor != 'N1') {
                    assignQueueAndResolution(
                        caseRecord,
                        rule.Queue_N1_DeveloperName__c,
                        rule.Grupo_Resolutor_N1__c,
                        'N1'
                    );
                }

                clearN3FlagIfOwnerChanged(caseRecord, oldCase);
                return;
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingService.applyUpdateRoutingToSingleCase(): ' + e.getMessage()
            );
        }
    }

    private static ReclamacionRoutingConfigService.RoutingRuleResult getMatchingRuleForCase(
        Case caseRecord,
        Boolean useProduct
    ) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingService.getMatchingRuleForCase() caseRecord=' + caseRecord +
            ', useProduct=' + useProduct
        );

        try {
            String codigoReclamacion = getStringFieldValue(caseRecord, FIELD_CODIGO_RECLAMACION);
            String grupoCanalReclamacion = getCurrentUserCanalAtencion();
            String producto = useProduct ? getStringFieldValue(caseRecord, FIELD_PRODUCTO) : null;

            System.debug(LoggingLevel.ERROR,
                'DEBUG REC MATCH INPUT | CaseId=' + caseRecord.Id +
                ' | Type=' + codigoReclamacion +
                ' | GrupoCanalReclamacion(User.Canal_Atencion__c)=' + grupoCanalReclamacion +
                ' | Case.CAS_Canal_distribucion__c=' + getStringFieldValue(caseRecord, FIELD_CANAL) +
                ' | Producto=' + producto +
                ' | useProduct=' + useProduct
            );

            return ReclamacionRoutingConfigService.getMatchingRule(
                codigoReclamacion,
                grupoCanalReclamacion,
                producto
            );

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingService.getMatchingRuleForCase(): ' + e.getMessage()
            );
            return new ReclamacionRoutingConfigService.RoutingRuleResult();
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
                'Error en ReclamacionRoutingService.getCurrentUserCanalAtencion(): ' + e.getMessage()
            );
            currentUserCanalAtencion = '';
            return currentUserCanalAtencion;
        }
    }

    private static Boolean shouldRouteCase(Case caseRecord) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingService.shouldRouteCase() caseRecord=' + caseRecord
        );

        try {
            if (caseRecord == null) {
                return false;
            }

            String codigoReclamacion = getStringFieldValue(caseRecord, FIELD_CODIGO_RECLAMACION);

            System.debug(LoggingLevel.DEBUG,
                'ReclamacionRoutingService.shouldRouteCase() codigoReclamacion=' + codigoReclamacion
            );

            return !String.isBlank(codigoReclamacion);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingService.shouldRouteCase(): ' + e.getMessage()
            );
            return false;
        }
    }

    private static Boolean shouldEvaluateUpdate(Case caseRecord, Case oldCase) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingService.shouldEvaluateUpdate() caseRecord=' + caseRecord +
            ', oldCase=' + oldCase
        );

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
                'DEBUG REC SHOULD EVALUATE | CaseId=' + caseRecord.Id +
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
                'Error en ReclamacionRoutingService.shouldEvaluateUpdate(): ' + e.getMessage()
            );
            return false;
        }
    }

    private static void assignRecordType(Case caseRecord, Reclamacion_Routing_Config__mdt rule) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingService.assignRecordType() rule=' +
            (rule != null ? rule.DeveloperName : null)
        );

        try {
            if (caseRecord == null || rule == null) {
                return;
            }

            String rtDeveloperName = rule.RecordType_DeveloperName__c;

            if (String.isBlank(rtDeveloperName)) {
                System.debug(LoggingLevel.DEBUG,
                    'ReclamacionRoutingService.assignRecordType() RecordType_DeveloperName__c vacío.'
                );
                return;
            }

            rtDeveloperName = rtDeveloperName.trim();

            Id recordTypeId = getRecordTypeIdByDeveloperName(rtDeveloperName);

            System.debug(LoggingLevel.ERROR,
                'DEBUG REC ASSIGN RT | Rule=' + rule.DeveloperName +
                ' | rtDeveloperName=' + rtDeveloperName +
                ' | recordTypeId=' + recordTypeId
            );

            if (recordTypeId != null) {
                caseRecord.RecordTypeId = recordTypeId;
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingService.assignRecordType(): ' + e.getMessage()
            );
        }
    }

    private static void assignInitialStatus(Case caseRecord, Reclamacion_Routing_Config__mdt rule) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingService.assignInitialStatus() rule=' +
            (rule != null ? rule.DeveloperName : null)
        );

        try {
            if (caseRecord == null || rule == null) {
                return;
            }

            String nivelInicial = normalizeValue(rule.Nivel_Inicial__c);
            String statusToAssign;

            if (nivelInicial == NIVEL_CANAL_RECLAMACION && !String.isBlank(rule.Status_Canal_Reclamacion__c)) {
                statusToAssign = rule.Status_Canal_Reclamacion__c;
            } else {
                statusToAssign = rule.Status_Inicial__c;
            }

            if (!String.isBlank(statusToAssign)) {
                caseRecord.Status = statusToAssign;
            }

            System.debug(LoggingLevel.ERROR,
                'DEBUG REC INITIAL STATUS | CaseId=' + caseRecord.Id +
                ' | NivelInicial=' + nivelInicial +
                ' | StatusCanalReclamacion=' + rule.Status_Canal_Reclamacion__c +
                ' | StatusInicial=' + rule.Status_Inicial__c +
                ' | StatusAsignado=' + caseRecord.Status
            );

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingService.assignInitialStatus(): ' + e.getMessage()
            );
        }
    }

    private static void assignInitialQueue(Case caseRecord, Reclamacion_Routing_Config__mdt rule) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingService.assignInitialQueue() rule=' +
            (rule != null ? rule.DeveloperName : null)
        );

        try {
            if (caseRecord == null || rule == null) {
                return;
            }

            String nivelInicial = normalizeValue(rule.Nivel_Inicial__c);
            String queueDeveloperName;

            if (nivelInicial == NIVEL_CANAL_RECLAMACION) {
                queueDeveloperName = rule.Queue_Canal_Reclamacion_DeveloperName__c;
            } else if (nivelInicial == 'N2') {
                queueDeveloperName = rule.Queue_N2_DeveloperName__c;
            } else if (nivelInicial == 'N3') {
                queueDeveloperName = rule.Queue_N3_DeveloperName__c;
            } else {
                queueDeveloperName = rule.Queue_N1_DeveloperName__c;
            }

            Id queueId = QueueResolver.getQueueIdByDeveloperName(queueDeveloperName);

            System.debug(LoggingLevel.DEBUG,
                'ReclamacionRoutingService.assignInitialQueue() ' +
                'nivelInicial=' + nivelInicial +
                ', queueDeveloperName=' + queueDeveloperName +
                ', queueId=' + queueId
            );

            if (queueId != null) {
                caseRecord.OwnerId = queueId;
            } else {
                assignFallbackQueue(caseRecord);
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingService.assignInitialQueue(): ' + e.getMessage()
            );
            assignFallbackQueue(caseRecord);
        }
    }

    private static void assignInitialResolutionData(Case caseRecord, Reclamacion_Routing_Config__mdt rule) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingService.assignInitialResolutionData() rule=' +
            (rule != null ? rule.DeveloperName : null)
        );

        try {
            if (caseRecord == null || rule == null) {
                return;
            }

            String nivelInicial = normalizeValue(rule.Nivel_Inicial__c);
            String grupoResolutorActual;

            if (!String.isBlank(rule.Nivel_Inicial__c)) {
                caseRecord.put(FIELD_NIVEL_RESOLUTOR, rule.Nivel_Inicial__c);
            }

            if (nivelInicial == NIVEL_CANAL_RECLAMACION) {
                grupoResolutorActual = rule.Grupo_Canal_Reclamacion__c;
            } else if (nivelInicial == 'N2') {
                grupoResolutorActual = rule.Grupo_Resolutor_N2__c;
            } else if (nivelInicial == 'N3') {
                grupoResolutorActual = rule.Grupo_Resolutor_N3__c;
            } else {
                grupoResolutorActual = rule.Grupo_Resolutor_N1__c;
            }

            if (!String.isBlank(grupoResolutorActual)) {
                caseRecord.put(FIELD_GRUPO_RESOLUTOR, grupoResolutorActual);
            }

            System.debug(LoggingLevel.DEBUG,
                'ReclamacionRoutingService.assignInitialResolutionData() ' +
                'Nivel=' + caseRecord.get(FIELD_NIVEL_RESOLUTOR) +
                ', Grupo=' + caseRecord.get(FIELD_GRUPO_RESOLUTOR)
            );

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingService.assignInitialResolutionData(): ' + e.getMessage()
            );
        }
    }

    private static void assignQueueAndResolution(
        Case caseRecord,
        String queueDeveloperName,
        String grupoResolutor,
        String nivelResolutor
    ) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingService.assignQueueAndResolution() ' +
            'queueDeveloperName=' + queueDeveloperName +
            ', grupoResolutor=' + grupoResolutor +
            ', nivelResolutor=' + nivelResolutor
        );

        try {
            if (caseRecord == null) {
                return;
            }

            Id queueId = QueueResolver.getQueueIdByDeveloperName(queueDeveloperName);

            System.debug(LoggingLevel.DEBUG,
                'ReclamacionRoutingService.assignQueueAndResolution() queueId=' + queueId
            );

            if (queueId != null) {
                caseRecord.OwnerId = queueId;
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
                'Error en ReclamacionRoutingService.assignQueueAndResolution(): ' + e.getMessage()
            );
        }
    }

    private static Boolean shouldApplyDevolucion(
        Case caseRecord,
        Case oldCase,
        Reclamacion_Routing_Config__mdt rule
    ) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingService.shouldApplyDevolucion() caseRecord=' + caseRecord +
            ', oldCase=' + oldCase +
            ', rule=' + (rule != null ? rule.DeveloperName : null)
        );

        try {
            if (caseRecord == null || oldCase == null || rule == null) {
                System.debug(LoggingLevel.ERROR,
                    'DEBUG REC DEVOLUCION CHECK | Datos insuficientes.'
                );
                return false;
            }

            Boolean newDevolver = getBooleanFieldValue(caseRecord, FIELD_DEVOLVER_AL_ORIGEN);
            Boolean oldDevolver = getBooleanFieldValue(oldCase, FIELD_DEVOLVER_AL_ORIGEN);
            String motivo = getStringFieldValue(caseRecord, FIELD_MOTIVO_DEVOLUCION);

            System.debug(LoggingLevel.ERROR,
                'DEBUG REC DEVOLUCION CHECK | CaseId=' + caseRecord.Id +
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
                'Error en ReclamacionRoutingService.shouldApplyDevolucion(): ' + e.getMessage()
            );
            return false;
        }
    }

    private static void applyDevolucionRouting(Case caseRecord, Reclamacion_Routing_Config__mdt rule) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingService.applyDevolucionRouting() caseRecord=' + caseRecord
        );

        try {
            if (caseRecord == null) {
                return;
            }

            String statusInicial;

            String nivelInicial = rule != null ? normalizeValue(rule.Nivel_Inicial__c) : null;

            if (rule != null &&
                nivelInicial == NIVEL_CANAL_RECLAMACION &&
                !String.isBlank(rule.Status_Canal_Reclamacion__c)) {
                statusInicial = rule.Status_Canal_Reclamacion__c;
            } else if (rule != null && !String.isBlank(rule.Status_Inicial__c)) {
                statusInicial = rule.Status_Inicial__c;
            } else {
                statusInicial = 'Crear Reclamación';
            }

            System.debug(LoggingLevel.ERROR,
                'DEBUG REC APPLY DEVOLUCION | CaseId=' + caseRecord.Id +
                ' | StatusAntes=' + caseRecord.Status +
                ' | NivelInicial=' + nivelInicial +
                ' | StatusCanalReclamacion=' + (rule != null ? rule.Status_Canal_Reclamacion__c : null) +
                ' | StatusInicial=' + (rule != null ? rule.Status_Inicial__c : null) +
                ' | StatusAsignado=' + statusInicial +
                ' | DevolverAntes=' + getBooleanFieldValue(caseRecord, FIELD_DEVOLVER_AL_ORIGEN) +
                ' | EscalarN3Antes=' + getBooleanFieldValue(caseRecord, FIELD_ESCALAR_A_N3)
            );

            caseRecord.Status = statusInicial;
            caseRecord.put(FIELD_DEVOLVER_AL_ORIGEN, false);
            caseRecord.put(FIELD_ESCALAR_A_N3, false);

            System.debug(LoggingLevel.ERROR,
                'DEBUG REC APPLY DEVOLUCION RESULT | CaseId=' + caseRecord.Id +
                ' | StatusDespues=' + caseRecord.Status +
                ' | DevolverDespues=' + getBooleanFieldValue(caseRecord, FIELD_DEVOLVER_AL_ORIGEN) +
                ' | EscalarN3Despues=' + getBooleanFieldValue(caseRecord, FIELD_ESCALAR_A_N3)
            );

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingService.applyDevolucionRouting(): ' + e.getMessage()
            );
        }
    }

    private static Boolean shouldEscalateToN3(
        Case caseRecord,
        Case oldCase,
        Reclamacion_Routing_Config__mdt rule
    ) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingService.shouldEscalateToN3() caseRecord=' + caseRecord +
            ', oldCase=' + oldCase +
            ', rule=' + (rule != null ? rule.DeveloperName : null)
        );

        try {
            if (caseRecord == null || oldCase == null || rule == null) {
                return false;
            }

            Boolean newValue = getBooleanFieldValue(caseRecord, FIELD_ESCALAR_A_N3);
            Boolean oldValue = getBooleanFieldValue(oldCase, FIELD_ESCALAR_A_N3);

            System.debug(LoggingLevel.DEBUG,
                'ReclamacionRoutingService.shouldEscalateToN3() newValue=' + newValue +
                ', oldValue=' + oldValue
            );

            if (newValue != true || oldValue == true) {
                return false;
            }

            return !String.isBlank(rule.Queue_N3_DeveloperName__c);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingService.shouldEscalateToN3(): ' + e.getMessage()
            );
            return false;
        }
    }

    private static Boolean hasExplicitN3Request(Case caseRecord, Case oldCase) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingService.hasExplicitN3Request() caseRecord=' + caseRecord +
            ', oldCase=' + oldCase
        );

        try {
            if (caseRecord == null || oldCase == null) {
                return false;
            }

            Boolean newValue = getBooleanFieldValue(caseRecord, FIELD_ESCALAR_A_N3);
            Boolean oldValue = getBooleanFieldValue(oldCase, FIELD_ESCALAR_A_N3);

            System.debug(LoggingLevel.DEBUG,
                'ReclamacionRoutingService.hasExplicitN3Request() newValue=' + newValue +
                ', oldValue=' + oldValue
            );

            return newValue == true && oldValue != true;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingService.hasExplicitN3Request(): ' + e.getMessage()
            );
            return false;
        }
    }

    private static void clearN3FlagIfOwnerChanged(Case caseRecord, Case oldCase) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingService.clearN3FlagIfOwnerChanged() caseRecord=' + caseRecord +
            ', oldCase=' + oldCase
        );

        try {
            if (caseRecord == null || oldCase == null) {
                return;
            }

            Boolean n3Flag = getBooleanFieldValue(caseRecord, FIELD_ESCALAR_A_N3);
            Boolean ownerChanged = caseRecord.OwnerId != oldCase.OwnerId;

            System.debug(LoggingLevel.DEBUG,
                'ReclamacionRoutingService.clearN3FlagIfOwnerChanged() ' +
                'n3Flag=' + n3Flag +
                ', ownerChanged=' + ownerChanged
            );

            if (n3Flag == true && ownerChanged) {
                caseRecord.put(FIELD_ESCALAR_A_N3, false);
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingService.clearN3FlagIfOwnerChanged(): ' + e.getMessage()
            );
        }
    }

    private static Boolean isInitialStatus(String status, Reclamacion_Routing_Config__mdt rule) {
        try {
            if (String.isBlank(status)) {
                return false;
            }

            String normalizedStatus = normalizeValue(status);
            String normalizedInitialStatus = rule != null
                ? normalizeValue(rule.Status_Inicial__c)
                : null;
            String normalizedCanalStatus = rule != null
                ? normalizeValue(rule.Status_Canal_Reclamacion__c)
                : null;

            if (!String.isBlank(normalizedCanalStatus) && normalizedStatus == normalizedCanalStatus) {
                return true;
            }

            if (!String.isBlank(normalizedInitialStatus)) {
                return normalizedStatus == normalizedInitialStatus;
            }

            return normalizedStatus == 'CREAR RECLAMACION' ||
                   normalizedStatus == 'CREAR RECLAMACIÓN';

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingService.isInitialStatus(): ' + e.getMessage()
            );
            return false;
        }
    }

    private static Boolean isN1Status(String normalizedStatus) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingService.isN1Status() normalizedStatus=' + normalizedStatus
        );

        try {
            Set<String> n1Statuses = new Set<String>{
                'VERIFICACIÓN DEL CASO',
                'VERIFICACION DEL CASO'
            };

            return !String.isBlank(normalizedStatus) && n1Statuses.contains(normalizedStatus);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingService.isN1Status(): ' + e.getMessage()
            );
            return false;
        }
    }

    private static Boolean isN2Status(String normalizedStatus) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingService.isN2Status() normalizedStatus=' + normalizedStatus
        );

        try {
            Set<String> n2Statuses = new Set<String>{
                'ANÁLISIS DEL CASO',
                'ANALISIS DEL CASO',
                'GESTIÓN / INVESTIGACIÓN',
                'GESTION / INVESTIGACION',
                'GESTIÓN DE CONTRACARGO',
                'GESTION DE CONTRACARGO',
                'RESULTADO DEL CONTRACARGO'
            };

            return !String.isBlank(normalizedStatus) && n2Statuses.contains(normalizedStatus);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingService.isN2Status(): ' + e.getMessage()
            );
            return false;
        }
    }

    private static Boolean isAutomaticN3Status(String normalizedStatus) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingService.isAutomaticN3Status() normalizedStatus=' + normalizedStatus
        );

        try {
            Set<String> n3Statuses = new Set<String>{
                'ACTUALIZACIÓN DE DATA CRÉDITO',
                'ACTUALIZACION DE DATA CREDITO'
            };

            return !String.isBlank(normalizedStatus) && n3Statuses.contains(normalizedStatus);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingService.isAutomaticN3Status(): ' + e.getMessage()
            );
            return false;
        }
    }

    private static void assignFallbackQueue(Case caseRecord) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingService.assignFallbackQueue() caseRecord=' + caseRecord
        );

        try {
            if (caseRecord == null) {
                return;
            }

            Id fallbackQueueId = QueueResolver.getQueueIdByDeveloperName(FALLBACK_QUEUE_DEV_NAME);

            System.debug(LoggingLevel.DEBUG,
                'ReclamacionRoutingService.assignFallbackQueue() ' +
                'FALLBACK_QUEUE_DEV_NAME=' + FALLBACK_QUEUE_DEV_NAME +
                ', fallbackQueueId=' + fallbackQueueId
            );

            if (fallbackQueueId != null) {
                caseRecord.OwnerId = fallbackQueueId;
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingService.assignFallbackQueue(): ' + e.getMessage()
            );
        }
    }

    private static void captureOriginOwner(Case caseRecord) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingService.captureOriginOwner() caseRecord=' + caseRecord
        );

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

            System.debug(LoggingLevel.DEBUG,
                'ReclamacionRoutingService.captureOriginOwner() ownerToSave=' + ownerToSave
            );

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingService.captureOriginOwner(): ' + e.getMessage()
            );
        }
    }

    private static void preloadRecordTypes(List<Case> newCases) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingService.preloadRecordTypes() newCases.size()=' +
            (newCases != null ? newCases.size() : 0)
        );

        try {
            if (newCases == null || newCases.isEmpty()) {
                return;
            }

            Set<String> codigoSet = new Set<String>();

            for (Case c : newCases) {
                String codigo = getStringFieldValue(c, FIELD_CODIGO_RECLAMACION);
                if (!String.isBlank(codigo)) {
                    codigoSet.add(codigo.trim().toUpperCase());
                }
            }

            if (codigoSet.isEmpty()) {
                return;
            }

            List<Reclamacion_Routing_Config__mdt> configs = [
                SELECT RecordType_DeveloperName__c
                FROM Reclamacion_Routing_Config__mdt
                WHERE Activo__c = true
                  AND Codigo_Reclamacion__c IN :codigoSet
            ];

            Set<String> rtDeveloperNames = new Set<String>();

            for (Reclamacion_Routing_Config__mdt cfg : configs) {
                String rtName = cfg.RecordType_DeveloperName__c;

                if (!String.isBlank(rtName)) {
                    rtDeveloperNames.add(rtName.trim());
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

            System.debug(LoggingLevel.DEBUG,
                'ReclamacionRoutingService.preloadRecordTypes() query size=' + recordTypes.size()
            );

            for (RecordType rt : recordTypes) {
                recordTypeIdByDeveloperName.put(rt.DeveloperName, rt.Id);
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingService.preloadRecordTypes(): ' + e.getMessage()
            );
        }
    }

    private static Id getRecordTypeIdByDeveloperName(String developerName) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingService.getRecordTypeIdByDeveloperName() developerName=' + developerName
        );

        try {
            if (String.isBlank(developerName)) {
                return null;
            }

            String cleanDeveloperName = developerName.trim();

            if (recordTypeIdByDeveloperName.containsKey(cleanDeveloperName)) {
                return recordTypeIdByDeveloperName.get(cleanDeveloperName);
            }

            List<RecordType> recordTypes = [
                SELECT Id, DeveloperName
                FROM RecordType
                WHERE SObjectType = 'Case'
                  AND DeveloperName = :cleanDeveloperName
                LIMIT 1
            ];

            System.debug(LoggingLevel.ERROR,
                'DEBUG REC RT LOOKUP | developerName=' + cleanDeveloperName +
                ' | found=' + recordTypes.size()
            );

            if (!recordTypes.isEmpty()) {
                recordTypeIdByDeveloperName.put(cleanDeveloperName, recordTypes[0].Id);
                return recordTypes[0].Id;
            }

            recordTypeIdByDeveloperName.put(cleanDeveloperName, null);
            return null;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingService.getRecordTypeIdByDeveloperName(): ' + e.getMessage()
            );
            return null;
        }
    }

    private static String getStringFieldValue(SObject sobj, String fieldApiName) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingService.getStringFieldValue() fieldApiName=' + fieldApiName
        );

        try {
            if (sobj == null || String.isBlank(fieldApiName)) {
                return null;
            }

            Object rawValue = sobj.get(fieldApiName);
            return rawValue == null ? null : String.valueOf(rawValue);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingService.getStringFieldValue(): ' + e.getMessage()
            );
            return null;
        }
    }

    private static Boolean getBooleanFieldValue(SObject sobj, String fieldApiName) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingService.getBooleanFieldValue() fieldApiName=' + fieldApiName
        );

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
                'Error en ReclamacionRoutingService.getBooleanFieldValue(): ' + e.getMessage()
            );
            return false;
        }
    }

    private static String normalizeValue(String value) {
        System.debug(LoggingLevel.DEBUG,
            'ReclamacionRoutingService.normalizeValue() value=' + value
        );

        try {
            if (String.isBlank(value)) {
                return null;
            }

            return value.trim().toUpperCase();

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingService.normalizeValue(): ' + e.getMessage()
            );
            return null;
        }
    }

    public static void clearCache() {
        System.debug(LoggingLevel.DEBUG, 'ReclamacionRoutingService.clearCache()');

        try {
            recordTypeIdByDeveloperName.clear();
            currentUserCanalAtencion = null;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en ReclamacionRoutingService.clearCache(): ' + e.getMessage()
            );
        }
    }
}