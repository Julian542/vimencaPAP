public with sharing class FSC_RLATriggerHandler {

    private static final String ACTO_NUMERO_PAGARE_FIELD = 'FSC_ActoNumeroPagare__c';
    private static final String NUMERO_FOLIO_PAGARE_FIELD = 'FSC_NumeroFolioPagare__c';
    private static final String SUBESTADO_PENDIENTE_PLANILLA_DESEMBOLSO = 'Pendiente planilla de desembolso';

    public static void beforeInsert(List<ResidentialLoanApplication> newRLA) {
        validateUniquePagareFields(newRLA, null);
    }

    public static void beforeUpdate(
        List<ResidentialLoanApplication> newRLA,
        Map<Id, ResidentialLoanApplication> oldRLA
    ) {
        validateUniquePagareFields(newRLA, oldRLA);
    }

    public static void afterUpdate(List<ResidentialLoanApplication> newRLA, Map<Id, ResidentialLoanApplication> oldRLA) {
        Set<Id> contractGenerationIds = new Set<Id>();
        Set<Id> residentialLoanApplicationIds = new Set<Id>();
        Set<Id> solicitudCreditoRegenerationIds = new Set<Id>();
        Set<Id> planillaDesembolsoCompletedIds = new Set<Id>();
        Set<Id> gestionarFirmasIds = new Set<Id>();

        for (ResidentialLoanApplication rla : newRLA) {
            ResidentialLoanApplication oldRecord = oldRLA.get(rla.Id);
            if (oldRecord == null) {
                continue;
            }

            if (oldRecord.FSC_Subestado__c != rla.FSC_Subestado__c) {
                if (rla.FSC_Subestado__c == 'Generación de contrato') {
                    contractGenerationIds.add(rla.Id);
                } else if (rla.FSC_Subestado__c == 'En Motor Buró') {
                    residentialLoanApplicationIds.add(rla.Id);
                } else if (rla.FSC_Subestado__c == 'Gestionar firmas') {
                    gestionarFirmasIds.add(rla.Id);
                }
            }

            if (FSC_RegenerarSolicitudCreditoService.shouldRegenerateSolicitudCredito(rla, oldRecord)) {
                solicitudCreditoRegenerationIds.add(rla.Id);
            }

            if (
                oldRecord.FSC_Desembolso_Realizado__c != true &&
                rla.FSC_Desembolso_Realizado__c == true &&
                oldRecord.FSC_Subestado__c == SUBESTADO_PENDIENTE_PLANILLA_DESEMBOLSO
            ) {
                planillaDesembolsoCompletedIds.add(rla.Id);
            }
        }

        if (!contractGenerationIds.isEmpty()) {
            generacionContrato(contractGenerationIds);
        }

        if (!residentialLoanApplicationIds.isEmpty()) {
            callToResidentialLoanApplication(residentialLoanApplicationIds);
        }

        if (!solicitudCreditoRegenerationIds.isEmpty()) {
            FSC_RegenerarSolicitudCreditoService.enqueueRegeneration(solicitudCreditoRegenerationIds);
        }

        if (!planillaDesembolsoCompletedIds.isEmpty()) {
            System.enqueueJob(new FSC_AutoApproveGestionPlanillasQueueable(planillaDesembolsoCompletedIds));
        }

        if (!gestionarFirmasIds.isEmpty()) {
            FSC_ConfiguracionFirmaDocumentosService.marcarFirmasFisicasCompletasSiNoAplican(gestionarFirmasIds);
        }
    }

    public static void generacionContrato(Set<Id> residentialLoanApplicationIds) {
        FSC_GenerarContratoPDF.enqueueGeneration(residentialLoanApplicationIds);
    }

    public static void desembolsoDeCredito(ResidentialLoanApplication rla) {
        FSC_DesembolsoDeCredito.desembolso(rla);
    }

    public static void callToResidentialLoanApplication(Set<Id> residentialLoanApplicationIds) {
        System.enqueueJob(new FSC_LoanDecisionAPIQueueable(new List<Id>(residentialLoanApplicationIds)));
    }

    private static void validateUniquePagareFields(
        List<ResidentialLoanApplication> newRLA,
        Map<Id, ResidentialLoanApplication> oldRLA
    ) {
        if (newRLA == null || newRLA.isEmpty()) {
            return;
        }

        Set<Id> currentRecordIds = new Set<Id>();
        Set<String> actoNumeroValues = new Set<String>();
        Set<String> numeroFolioValues = new Set<String>();

        Map<String, List<ResidentialLoanApplication>> recordsByActoNumero = new Map<String, List<ResidentialLoanApplication>>();
        Map<String, List<ResidentialLoanApplication>> recordsByNumeroFolio = new Map<String, List<ResidentialLoanApplication>>();
        Map<String, List<ResidentialLoanApplication>> allRecordsByActoNumero = new Map<String, List<ResidentialLoanApplication>>();
        Map<String, List<ResidentialLoanApplication>> allRecordsByNumeroFolio = new Map<String, List<ResidentialLoanApplication>>();

        for (ResidentialLoanApplication rla : newRLA) {
            if (rla == null) {
                continue;
            }

            if (rla.Id != null) {
                currentRecordIds.add(rla.Id);
            }

            ResidentialLoanApplication oldRecord = oldRLA == null ? null : oldRLA.get(rla.Id);

            String actoNumero = normalizeUniqueValue(rla.get(ACTO_NUMERO_PAGARE_FIELD));
            if (!String.isBlank(actoNumero)) {
                addRecordByValue(allRecordsByActoNumero, actoNumero, rla);
            }
            String oldActoNumero = oldRecord == null ? null : normalizeUniqueValue(oldRecord.get(ACTO_NUMERO_PAGARE_FIELD));
            if (shouldValidateUniqueValue(actoNumero, oldActoNumero)) {
                actoNumeroValues.add(actoNumero);
                addRecordByValue(recordsByActoNumero, actoNumero, rla);
            }

            String numeroFolio = normalizeUniqueValue(rla.get(NUMERO_FOLIO_PAGARE_FIELD));
            if (!String.isBlank(numeroFolio)) {
                addRecordByValue(allRecordsByNumeroFolio, numeroFolio, rla);
            }
            String oldNumeroFolio = oldRecord == null ? null : normalizeUniqueValue(oldRecord.get(NUMERO_FOLIO_PAGARE_FIELD));
            if (shouldValidateUniqueValue(numeroFolio, oldNumeroFolio)) {
                numeroFolioValues.add(numeroFolio);
                addRecordByValue(recordsByNumeroFolio, numeroFolio, rla);
            }
        }

        if (recordsByActoNumero.isEmpty() && recordsByNumeroFolio.isEmpty()) {
            return;
        }

        Map<String, Id> existingByActoNumero = getExistingRecordsByActoNumero(actoNumeroValues, currentRecordIds);
        Map<String, Id> existingByNumeroFolio = getExistingRecordsByNumeroFolio(numeroFolioValues, currentRecordIds);

        addDuplicateErrors(
            recordsByActoNumero,
            allRecordsByActoNumero,
            existingByActoNumero,
            'El Acto número pagaré ya existe en otra solicitud.'
        );
        addDuplicateErrors(
            recordsByNumeroFolio,
            allRecordsByNumeroFolio,
            existingByNumeroFolio,
            'El Número de folio ya existe en otra solicitud.'
        );
    }

    private static void addRecordByValue(
        Map<String, List<ResidentialLoanApplication>> recordsByValue,
        String value,
        ResidentialLoanApplication rla
    ) {
        if (String.isBlank(value) || rla == null) {
            return;
        }

        if (!recordsByValue.containsKey(value)) {
            recordsByValue.put(value, new List<ResidentialLoanApplication>());
        }

        recordsByValue.get(value).add(rla);
    }

    private static Boolean shouldValidateUniqueValue(String newValue, String oldValue) {
        return !String.isBlank(newValue) && newValue != oldValue;
    }

    private static String normalizeUniqueValue(Object value) {
        if (value == null) {
            return null;
        }

        String normalized = String.valueOf(value).trim();
        return String.isBlank(normalized) ? null : normalized;
    }

    private static void addDuplicateErrors(
        Map<String, List<ResidentialLoanApplication>> recordsByValue,
        Map<String, List<ResidentialLoanApplication>> allRecordsByValue,
        Map<String, Id> existingByValue,
        String errorMessage
    ) {
        for (String value : recordsByValue.keySet()) {
            List<ResidentialLoanApplication> records = recordsByValue.get(value);
            List<ResidentialLoanApplication> allRecords = allRecordsByValue.get(value);
            Boolean existsInCurrentTransaction = allRecords != null && allRecords.size() > 1;
            Boolean existsInDatabase = existingByValue.containsKey(value);

            if (!existsInCurrentTransaction && !existsInDatabase) {
                continue;
            }

            for (ResidentialLoanApplication rla : records) {
                rla.addError(errorMessage);
            }
        }
    }

    private static Map<String, Id> getExistingRecordsByActoNumero(Set<String> values, Set<Id> currentRecordIds) {
        Map<String, Id> existingByValue = new Map<String, Id>();
        if (values == null || values.isEmpty()) {
            return existingByValue;
        }

        for (ResidentialLoanApplication existingRecord : [
            SELECT Id, FSC_ActoNumeroPagare__c
            FROM ResidentialLoanApplication
            WHERE FSC_ActoNumeroPagare__c IN :values
              AND Id NOT IN :currentRecordIds
        ]) {
            String value = normalizeUniqueValue(existingRecord.get(ACTO_NUMERO_PAGARE_FIELD));
            if (!String.isBlank(value) && !existingByValue.containsKey(value)) {
                existingByValue.put(value, existingRecord.Id);
            }
        }

        return existingByValue;
    }

    private static Map<String, Id> getExistingRecordsByNumeroFolio(Set<String> values, Set<Id> currentRecordIds) {
        Map<String, Id> existingByValue = new Map<String, Id>();
        if (values == null || values.isEmpty()) {
            return existingByValue;
        }

        Schema.DescribeFieldResult folioFieldDescribe =
            ResidentialLoanApplication.SObjectType.getDescribe().fields.getMap().get(NUMERO_FOLIO_PAGARE_FIELD).getDescribe();

        Schema.DisplayType folioFieldType = folioFieldDescribe.getType();

        if (
            folioFieldType == Schema.DisplayType.Currency ||
            folioFieldType == Schema.DisplayType.Double ||
            folioFieldType == Schema.DisplayType.Integer ||
            folioFieldType == Schema.DisplayType.Percent
        ) {
            Set<Decimal> decimalValues = new Set<Decimal>();
            for (String value : values) {
                try {
                    decimalValues.add(Decimal.valueOf(value));
                } catch (Exception e) {
                    // Si no se puede convertir, igual se ignora en la consulta y se mantiene la validacion local.
                }
            }

            if (decimalValues.isEmpty()) {
                return existingByValue;
            }

            for (ResidentialLoanApplication existingRecord : Database.query(
                'SELECT Id, ' + NUMERO_FOLIO_PAGARE_FIELD +
                ' FROM ResidentialLoanApplication' +
                ' WHERE ' + NUMERO_FOLIO_PAGARE_FIELD + ' IN :decimalValues' +
                ' AND Id NOT IN :currentRecordIds'
            )) {
                String value = normalizeUniqueValue(existingRecord.get(NUMERO_FOLIO_PAGARE_FIELD));
                if (!String.isBlank(value) && !existingByValue.containsKey(value)) {
                    existingByValue.put(value, existingRecord.Id);
                }
            }

            return existingByValue;
        }

        for (ResidentialLoanApplication existingRecord : Database.query(
            'SELECT Id, ' + NUMERO_FOLIO_PAGARE_FIELD +
            ' FROM ResidentialLoanApplication' +
            ' WHERE ' + NUMERO_FOLIO_PAGARE_FIELD + ' IN :values' +
            ' AND Id NOT IN :currentRecordIds'
        )) {
            String value = normalizeUniqueValue(existingRecord.get(NUMERO_FOLIO_PAGARE_FIELD));
            if (!String.isBlank(value) && !existingByValue.containsKey(value)) {
                existingByValue.put(value, existingRecord.Id);
            }
        }

        return existingByValue;
    }
}