/**
 * @description       :
 * @author            : Kevin Vega H
 * @group             :
 * @last modified on  : 27-05-2026
 * @last modified by  : Nahuel De Leon
 **/
public with sharing class CaseTriggerHandler {

    private static Set<Id> reclamacionRecordTypeIds;
    private static Set<Id> solicitudRecordTypeIds;

    private static String normalizeText(String text) {
        System.debug(LoggingLevel.DEBUG, 'CaseTriggerHandler.normalizeText() text=' + text);

        try {
            if (text == null) {
                return null;
            }

            text = text.normalizeSpace();
            return text;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error en CaseTriggerHandler.normalizeText(): ' + e.getMessage());
            return text;
        }
    }

    
    /**
     * @description Allows us to add the correct format for the fields.
     * @author Kevin Vega H | 01-21-2023
     * @param record
     **/
    public static void formatFields(Case record) {
        System.debug(LoggingLevel.DEBUG, 'CaseTriggerHandler.formatFields() record=' + record);

        try {
            record.Description = (String.isNotBlank(record.Description))
                ? normalizeText(record.Description)
                : null;

            record.CAS_Solucion_de_Reclamacion__c = String.isNotBlank(record.CAS_Solucion_de_Reclamacion__c)
                ? normalizeText(record.CAS_Solucion_de_Reclamacion__c)
                : null;

            record.TXT_Descripcion_corta__c = String.isNotBlank(record.Description) &&
                record.Description.length() > 150
                ? record.Description.subString(0, 150)
                : record.Description;

            record.TXT_Resultado_de_la_Reclamacion_corta__c = String.isNotBlank(record.CAS_Solucion_de_Reclamacion__c) &&
                record.CAS_Solucion_de_Reclamacion__c.length() > 150
                ? record.CAS_Solucion_de_Reclamacion__c.subString(0, 150)
                : record.CAS_Solucion_de_Reclamacion__c;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error en CaseTriggerHandler.formatFields(): ' + e.getMessage());
        }
    }

    /**
     * @description Allows us to get the value of the Type Picklist by API Name
     * @author Kevin Vega H | 01-21-2023
     * @param record
     **/
    public static void setLabelToTypeField(Case record) {
        System.debug(LoggingLevel.DEBUG, 'CaseTriggerHandler.setLabelToTypeField() record=' + record);

        try {
            List<Schema.PicklistEntry> values = Case.Type.getDescribe().getPicklistValues();

            String apiName = record.Type;
            for (Schema.PicklistEntry sp : values) {
                if (sp.getValue() == apiName) {
                    record.Type__c = sp.getLabel();
                    break;
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error en CaseTriggerHandler.setLabelToTypeField(): ' + e.getMessage());
        }
    }

    /**
     * @description Ejecuta el ruteo inicial de Solicitudes al crear el caso.
     **/
    public static void routeSolicitudesBeforeInsert(List<Case> newCases) {
        System.debug(
            LoggingLevel.DEBUG,
            'CaseTriggerHandler.routeSolicitudesBeforeInsert() newCases.size()=' +
            (newCases != null ? newCases.size() : 0)
        );

        try {
            if (newCases == null || newCases.isEmpty()) {
                return;
            }

            for (Case c : newCases) {
                System.debug(
                    LoggingLevel.DEBUG,
                    'routeSolicitudesBeforeInsert campos caso - Id=' + c.Id +
                    ', CAS_Canal_distribucion__c=' + c.CAS_Canal_distribucion__c +
                    ', FinServ__FinancialAccount__c=' + c.FinServ__FinancialAccount__c
                );
            }

            SolicitudRoutingService.applyInitialRouting(newCases);

        } catch (Exception e) {
            System.debug(
                LoggingLevel.ERROR,
                'Error en CaseTriggerHandler.routeSolicitudesBeforeInsert(): ' + e.getMessage()
            );
        }
    }


    /**
     * @description Ejecuta el ruteo inicial de reclamaciones al crear el caso.
     **/
    public static void routeReclamacionesBeforeInsert(List<Case> newCases) {
        System.debug(
            LoggingLevel.DEBUG,
            'CaseTriggerHandler.routeReclamacionesBeforeInsert() newCases.size()=' +
            (newCases != null ? newCases.size() : 0)
        );

        try {
            if (newCases == null || newCases.isEmpty()) {
                return;
            }

            for (Case c : newCases) {
                System.debug(
                    LoggingLevel.DEBUG,
                    'routeReclamacionesBeforeInsert campos caso - Id=' + c.Id +
                    ', AS_Codigo_Reclamacion__c=' + c.CAS_Codigo_Reclamacion__c +
                    ', CAS_Canal_distribucion__c=' + c.CAS_Canal_distribucion__c +
                    ', CAS_Producto_a_Reclamar__c=' + c.CAS_Producto_a_Reclamar__c
                );
            }

            ReclamacionRoutingService.applyInitialRouting(newCases);

        } catch (Exception e) {
            System.debug(
                LoggingLevel.ERROR,
                'Error en CaseTriggerHandler.routeReclamacionesBeforeInsert(): ' + e.getMessage()
            );
        }
    }

    /**
     * @description Ejecuta el ruteo de Solicitudes al actualizar el caso.
     **/
    public static void routeSolicitudesBeforeUpdate(List<Case> newCases, Map<Id, Case> oldMap) {
        System.debug(
            LoggingLevel.DEBUG,
            'CaseTriggerHandler.routeSolicitudesBeforeUpdate() newCases.size()=' +
            (newCases != null ? newCases.size() : 0)
        );

        try {
            if (newCases == null || newCases.isEmpty() || oldMap == null || oldMap.isEmpty()) {
                return;
            }

            for (Case c : newCases) {
                System.debug(
                    LoggingLevel.DEBUG,
                    'routeSolicitudesBeforeUpdate NEW campos caso - Id=' + c.Id +
                    ', CAS_Canal_distribucion__c=' + c.CAS_Canal_distribucion__c +
                    ', FinServ__FinancialAccount__c=' + c.FinServ__FinancialAccount__c
                );

                if (oldMap.containsKey(c.Id)) {
                    Case oldCase = oldMap.get(c.Id);
                    System.debug(
                        LoggingLevel.DEBUG,
                        'routeSolicitudesBeforeUpdate OLD campos caso - Id=' + oldCase.Id +
                        ', CAS_Canal_distribucion__c=' + oldCase.CAS_Canal_distribucion__c +
                        ', FinServ__FinancialAccount__c=' + oldCase.FinServ__FinancialAccount__c
                    );
                }
            }

            SolicitudRoutingService.applyUpdateRouting(newCases, oldMap);

            FSC_SolicitudSLAService.completeMilestonesOnCaseClose(newCases, oldMap);
            

        } catch (Exception e) {
            System.debug(
                LoggingLevel.ERROR,
                'Error en CaseTriggerHandler.routeReclamacionesBeforeUpdate(): ' + e.getMessage()
            );
        }
    }

    /**
     * @description Ejecuta el ruteo de reclamaciones al actualizar el caso.
     **/
    public static void routeReclamacionesBeforeUpdate(List<Case> newCases, Map<Id, Case> oldMap) {
        System.debug(
            LoggingLevel.DEBUG,
            'CaseTriggerHandler.routeReclamacionesBeforeUpdate() newCases.size()=' +
            (newCases != null ? newCases.size() : 0)
        );

        try {
            if (newCases == null || newCases.isEmpty() || oldMap == null || oldMap.isEmpty()) {
                return;
            }

            for (Case c : newCases) {
                System.debug(
                    LoggingLevel.DEBUG,
                    'routeReclamacionesBeforeUpdate NEW campos caso - Id=' + c.Id +
                    ', AS_Codigo_Reclamacion__c=' + c.CAS_Codigo_Reclamacion__c +
                    ', CAS_Canal_distribucion__c=' + c.CAS_Canal_distribucion__c +
                    ', CAS_Producto_a_Reclamar__c=' + c.CAS_Producto_a_Reclamar__c
                );

                if (oldMap.containsKey(c.Id)) {
                    Case oldCase = oldMap.get(c.Id);
                    System.debug(
                        LoggingLevel.DEBUG,
                        'routeReclamacionesBeforeUpdate OLD campos caso - Id=' + oldCase.Id +
                        ', AS_Codigo_Reclamacion__c=' + oldCase.CAS_Codigo_Reclamacion__c +
                        ', CAS_Canal_distribucion__c=' + oldCase.CAS_Canal_distribucion__c +
                        ', CAS_Producto_a_Reclamar__c=' + oldCase.CAS_Producto_a_Reclamar__c
                    );
                }
            }

            ReclamacionRoutingService.applyUpdateRouting(newCases, oldMap);

            // FSC_SolicitudSLAService.completeMilestonesOnCaseClose(newCases, oldMap);


        } catch (Exception e) {
            System.debug(
                LoggingLevel.ERROR,
                'Error en CaseTriggerHandler.routeReclamacionesBeforeUpdate(): ' + e.getMessage()
            );
        }
    }

    /**
     * @description Obtiene los Record Types que participan en reclamaciones.
     * Se consulta por SOQL para evitar errores con Describe.
     **/
    private static Set<Id> getReclamacionRecordTypeIds() {
        System.debug(LoggingLevel.DEBUG, 'CaseTriggerHandler.getReclamacionRecordTypeIds()');

        try {
            if (reclamacionRecordTypeIds != null) {
                return reclamacionRecordTypeIds;
            }

            reclamacionRecordTypeIds = new Set<Id>();

            List<String> reclamacionRtDevNames = new List<String>{
                'Reclamaciones',
                'Reclamo_Estandar',
                'Reclamo_Contracargo',
                'Reclamo_Investigacion_Contracargo',
                'Reclamo_Contracargo_Investigacion',
                'Reclamo_Data_Credito'
            };

            System.debug(
                LoggingLevel.DEBUG,
                'Query RecordType en getReclamacionRecordTypeIds(). reclamacionRtDevNames=' + reclamacionRtDevNames
            );

            for (RecordType rt : [
                SELECT Id, DeveloperName
                FROM RecordType
                WHERE SObjectType = 'Case'
                AND DeveloperName IN :reclamacionRtDevNames
            ]) {
                reclamacionRecordTypeIds.add(rt.Id);
            }

            System.debug(
                LoggingLevel.DEBUG,
                'CaseTriggerHandler.getReclamacionRecordTypeIds() reclamacionRecordTypeIds=' +
                reclamacionRecordTypeIds
            );

            return reclamacionRecordTypeIds;

        } catch (Exception e) {
            System.debug(
                LoggingLevel.ERROR,
                'Error en CaseTriggerHandler.getReclamacionRecordTypeIds(): ' + e.getMessage()
            );
            return new Set<Id>();
        }
    }

    /**
     * @description Determina si el caso pertenece al flujo de reclamaciones.
     **/
    private static Boolean isReclamacionCase(Case c) {
        System.debug(LoggingLevel.DEBUG, 'CaseTriggerHandler.isReclamacionCase() case=' + c);

        try {
            if (c == null || c.RecordTypeId == null) {
                return false;
            }

            return getReclamacionRecordTypeIds().contains(c.RecordTypeId);

        } catch (Exception e) {
            System.debug(
                LoggingLevel.ERROR,
                'Error en CaseTriggerHandler.isReclamacionCase(): ' + e.getMessage()
            );
            return false;
        }
    }

    /**
     * @description Obtiene los Record Types que participan en solicitudes.
     * Se consulta por SOQL para evitar errores con Describe.
     **/
    private static Set<Id> getSolicitudRecordTypeIds() {
        System.debug(LoggingLevel.DEBUG, 'CaseTriggerHandler.getSolicitudRecordTypeIds()');

        try {
            if (solicitudRecordTypeIds != null) {
                return solicitudRecordTypeIds;
            }

            solicitudRecordTypeIds = new Set<Id>();

            List<String> solicitudRtDevNames = new List<String>{
                'Solicitudes',
                'Solicitud_Analisis_5_Etapas',
                'Solicitud_Evaluacion_5_Etapas',
                'Solicitud_Procesamiento_Directo',
                'Solicitud_Validacion_Doble',
                'Solicitud_Seis_Etapas',
                'Solicitud_Activacion_Tarjeta'
            };

            System.debug(
                LoggingLevel.DEBUG,
                'Query RecordType en getSolicitudRecordTypeIds(). solicitudRtDevNames=' + solicitudRtDevNames
            );

            for (RecordType rt : [
                SELECT Id, DeveloperName
                FROM RecordType
                WHERE SObjectType = 'Case'
                AND DeveloperName IN :solicitudRtDevNames
            ]) {
                solicitudRecordTypeIds.add(rt.Id);
            }

            System.debug(
                LoggingLevel.DEBUG,
                'CaseTriggerHandler.getSolicitudRecordTypeIds() solicitudRecordTypeIds=' +
                solicitudRecordTypeIds
            );

            return solicitudRecordTypeIds;

        } catch (Exception e) {
            System.debug(
                LoggingLevel.ERROR,
                'Error en CaseTriggerHandler.getSolicitudRecordTypeIds(): ' + e.getMessage()
            );
            return new Set<Id>();
        }
    }

    /**
     * @description Determina si el caso pertenece al flujo de solicitudes.
     **/
    private static Boolean isSolicitudCase(Case c) {
        System.debug(LoggingLevel.DEBUG, 'CaseTriggerHandler.isSolicitudCase() case=' + c);

        try {
            if (c == null || c.RecordTypeId == null) {
                return false;
            }

            return getSolicitudRecordTypeIds().contains(c.RecordTypeId);

        } catch (Exception e) {
            System.debug(
                LoggingLevel.ERROR,
                'Error en CaseTriggerHandler.isSolicitudCase(): ' + e.getMessage()
            );
            return false;
        }
    }

    // Agregado por Jhonny Peroza
    // Lógica para asignar sucursal y cola según el Account
    public static void assignBranchAndQueue(
        List<Case> newCases,
        Map<Id, Case> oldMap,
        Boolean isInsert,
        Boolean isUpdate
    ) {
        System.debug(
            LoggingLevel.DEBUG,
            'CaseTriggerHandler.assignBranchAndQueue() ' +
            'newCases.size()=' + (newCases != null ? newCases.size() : 0) +
            ', isInsert=' + isInsert +
            ', isUpdate=' + isUpdate
        );

        try {
            Set<Id> accountIds = new Set<Id>();

            for (Case c : newCases) {
                if (isReclamacionCase(c) || isSolicitudCase(c)) {
                    System.debug(
                        LoggingLevel.DEBUG,
                        'CaseTriggerHandler.assignBranchAndQueue() se omite por ser reclamación o solicitud. RecordTypeId=' +
                        c.RecordTypeId
                    );
                    continue;
                }

                if (c.AccountId != null) {
                    accountIds.add(c.AccountId);
                }
            }

            if (accountIds.isEmpty()) {
                System.debug(LoggingLevel.DEBUG, 'CaseTriggerHandler.assignBranchAndQueue() no hay accountIds.');
                return;
            }

            System.debug(LoggingLevel.DEBUG, 'Query Account en assignBranchAndQueue(). accountIds=' + accountIds);

            Map<Id, Account> accountMap = new Map<Id, Account>([
                SELECT Id, ACC_Branch__c
                FROM Account
                WHERE Id IN :accountIds
            ]);

            Set<Id> branchIds = new Set<Id>();

            for (Account acc : accountMap.values()) {
                if (acc.ACC_Branch__c != null) {
                    branchIds.add(acc.ACC_Branch__c);
                }
            }

            if (branchIds.isEmpty()) {
                System.debug(LoggingLevel.DEBUG, 'CaseTriggerHandler.assignBranchAndQueue() no hay branchIds.');
                return;
            }

            System.debug(LoggingLevel.DEBUG, 'Query Sucursal__c en assignBranchAndQueue(). branchIds=' + branchIds);

            Map<Id, Sucursal__c> branchMap = new Map<Id, Sucursal__c>([
                SELECT Id, SUC_Queue__c
                FROM Sucursal__c
                WHERE Id IN :branchIds
            ]);

            Set<String> queueNames = new Set<String>();

            for (Sucursal__c branch : branchMap.values()) {
                if (!String.isBlank(branch.SUC_Queue__c)) {
                    queueNames.add(branch.SUC_Queue__c.trim());
                }
            }

            Map<String, Id> queueByDeveloperName = new Map<String, Id>();

            if (!queueNames.isEmpty()) {
                System.debug(LoggingLevel.DEBUG, 'Query Group en assignBranchAndQueue(). queueNames=' + queueNames);

                for (Group g : [
                    SELECT Id, DeveloperName
                    FROM Group
                    WHERE Type = 'Queue'
                    AND DeveloperName IN :queueNames
                ]) {
                    queueByDeveloperName.put(g.DeveloperName, g.Id);
                }
            }

            for (Case c : newCases) {
                if (isReclamacionCase(c) || isSolicitudCase(c)) {
                    System.debug(
                        LoggingLevel.DEBUG,
                        'CaseTriggerHandler.assignBranchAndQueue() se omite asignación final por ser reclamación o solicitud. RecordTypeId=' +
                        c.RecordTypeId
                    );
                    continue;
                }

                if (c.AccountId == null) {
                    continue;
                }

                Account acc = accountMap.get(c.AccountId);

                if (acc == null || acc.ACC_Branch__c == null) {
                    continue;
                }

                Case oldCase = (isUpdate && oldMap != null) ? oldMap.get(c.Id) : null;

                Boolean shouldAssign = false;

                if (isInsert) {
                    shouldAssign = true;
                } else if (isUpdate) {
                    if (
                        oldCase != null &&
                        (
                            oldCase.AccountId != c.AccountId ||
                            oldCase.CAS_Branch__c != c.CAS_Branch__c ||
                            c.OwnerId == null
                        )
                    ) {
                        shouldAssign = true;
                    }
                }

                if (!shouldAssign) {
                    continue;
                }

                if (c.CAS_Branch__c == null) {
                    c.CAS_Branch__c = acc.ACC_Branch__c;
                }

                Sucursal__c branch = branchMap.get(c.CAS_Branch__c);

                if (branch == null || String.isBlank(branch.SUC_Queue__c)) {
                    continue;
                }

                Id queueId = queueByDeveloperName.get(branch.SUC_Queue__c.trim());

                if (queueId != null) {
                    c.OwnerId = queueId;
                }
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error en CaseTriggerHandler.assignBranchAndQueue(): ' + e.getMessage());
        }
    }

    /**
     * @description Asigna el Subject del caso usando el label del campo Type.
     **/
    public static void setSubjectFromTypeLabel(Case record) {
        System.debug(LoggingLevel.DEBUG, 'CaseTriggerHandler.setSubjectFromTypeLabel() record=' + record);

        try {
            if (record == null) {
                return;
            }

            if (String.isBlank(record.Type)) {
                return;
            }

            List<Schema.PicklistEntry> values = Case.Type.getDescribe().getPicklistValues();

            String apiName = record.Type;

            for (Schema.PicklistEntry sp : values) {
                if (sp.getValue() == apiName) {
                    record.Subject = sp.getLabel();
                    break;
                }
            }

            System.debug(
                LoggingLevel.DEBUG,
                'CaseTriggerHandler.setSubjectFromTypeLabel() Subject final=' + record.Subject
            );

        } catch (Exception e) {
            System.debug(
                LoggingLevel.ERROR,
                'Error en CaseTriggerHandler.setSubjectFromTypeLabel(): ' + e.getMessage()
            );
        }
    }

}