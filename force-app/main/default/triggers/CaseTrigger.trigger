/**
 * @description       :
 * @author            : Kevin Vega H
 * @group             :
 * @last modified on  : 04-06-2026
 * @last modified by  : Jhonny Peroza
 **/
trigger CaseTrigger on Case(before insert, before update) {

    Map<String, Schema.RecordTypeInfo> caseRecordTypesByDeveloperName =
        Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName();

    Set<Id> reclamacionesRecordTypeIds = new Set<Id>();
    Set<Id> solicitudesRecordTypeIds = new Set<Id>();

    List<String> reclamacionRecordTypeDeveloperNames = new List<String>{
        'Reclamaciones',
        'Reclamo_Estandar',
        'Reclamo_Contracargo',
        'Reclamo_Investigacion_Contracargo',
        'Reclamo_Contracargo_Investigacion',
        'Reclamo_Data_Credito'
    };

    List<String> solicitudRecordTypeDeveloperNames = new List<String>{
        'Solicitudes',
        'Solicitud_Analisis_5_Etapas',
        'Solicitud_Evaluacion_5_Etapas',
        'Solicitud_Procesamiento_Directo',
        'Solicitud_Validacion_Doble',
        'Solicitud_Seis_Etapas',
        'Solicitud_Activacion_Tarjeta'
    };

    for (String developerName : reclamacionRecordTypeDeveloperNames) {
        if (caseRecordTypesByDeveloperName.containsKey(developerName)) {
            reclamacionesRecordTypeIds.add(
                caseRecordTypesByDeveloperName.get(developerName).getRecordTypeId()
            );
        }
    }

    for (String developerName : solicitudRecordTypeDeveloperNames) {
        if (caseRecordTypesByDeveloperName.containsKey(developerName)) {
            solicitudesRecordTypeIds.add(
                caseRecordTypesByDeveloperName.get(developerName).getRecordTypeId()
            );
        }
    }

    List<Case> casosReclamaciones = new List<Case>();
    List<Case> casosSolicitudes = new List<Case>();
    List<Case> casosParaBranchAndQueue = new List<Case>();

    if (Trigger.isBefore) {

        if (Trigger.isInsert || Trigger.isUpdate) {
            for (Case record : Trigger.new) {

                System.debug(LoggingLevel.DEBUG,
                    '> CaseTrigger campos caso - Id=' + record.Id +
                    ', CAS_Codigo_Reclamacion__c=' + record.CAS_Codigo_Reclamacion__c +
                    ', Type=' + record.Type +
                    ', CAS_Canal_distribucion__c=' + record.CAS_Canal_distribucion__c +
                    ', CAS_Producto_a_Reclamar__c=' + record.CAS_Producto_a_Reclamar__c +
                    ', CAS_MatrizProducto__c=' + record.CAS_MatrizProducto__c
                );

                if (Trigger.isUpdate && Trigger.oldMap != null && Trigger.oldMap.containsKey(record.Id)) {
                    Case oldRecord = Trigger.oldMap.get(record.Id);

                    System.debug(LoggingLevel.DEBUG,
                        '> CaseTrigger OLD campos caso - Id=' + oldRecord.Id +
                        ', CAS_Codigo_Reclamacion__c=' + oldRecord.CAS_Codigo_Reclamacion__c +
                        ', Type=' + oldRecord.Type +
                        ', CAS_Canal_distribucion__c=' + oldRecord.CAS_Canal_distribucion__c +
                        ', CAS_Producto_a_Reclamar__c=' + oldRecord.CAS_Producto_a_Reclamar__c +
                        ', CAS_MatrizProducto__c=' + oldRecord.CAS_MatrizProducto__c
                    );
                }

                Boolean esReclamacion = reclamacionesRecordTypeIds.contains(record.RecordTypeId);
                Boolean esSolicitud = solicitudesRecordTypeIds.contains(record.RecordTypeId);

                if (esReclamacion) {
                    casosReclamaciones.add(record);
                }

                if (esSolicitud) {
                    casosSolicitudes.add(record);
                }

                if (!esReclamacion && !esSolicitud) {
                    casosParaBranchAndQueue.add(record);
                }

                CaseTriggerHandler.formatFields(record);
                CaseTriggerHandler.setLabelToTypeField(record);

                if (esSolicitud) {
                    CaseTriggerHandler.setSubjectFromTypeLabel(record);
                }
            }
        }

        if (Trigger.isInsert && !casosReclamaciones.isEmpty()) {
            CaseTriggerHandler.routeReclamacionesBeforeInsert(casosReclamaciones);
        }

        if (Trigger.isUpdate && !casosReclamaciones.isEmpty()) {
            CaseTriggerHandler.routeReclamacionesBeforeUpdate(
                casosReclamaciones,
                Trigger.oldMap
            );
        }

        if (Trigger.isInsert && !casosSolicitudes.isEmpty()) {
            CaseTriggerHandler.routeSolicitudesBeforeInsert(casosSolicitudes);
        }

        if (Trigger.isUpdate && !casosSolicitudes.isEmpty()) {
            CaseTriggerHandler.routeSolicitudesBeforeUpdate(
                casosSolicitudes,
                Trigger.oldMap
            );
        }

        if (!casosParaBranchAndQueue.isEmpty()) {
            CaseTriggerHandler.assignBranchAndQueue(
                casosParaBranchAndQueue,
                Trigger.oldMap,
                Trigger.isInsert,
                Trigger.isUpdate
            );
        }

        CaseRoundRobin.assignRandomOwnerFromQueue(Trigger.new);
    }
}