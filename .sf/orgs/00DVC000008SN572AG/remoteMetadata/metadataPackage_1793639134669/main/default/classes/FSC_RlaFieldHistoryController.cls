public with sharing class FSC_RlaFieldHistoryController {

    public class HistoryRow {
        @AuraEnabled public Id historyId;
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public String fieldLabel;
        @AuraEnabled public String oldValue;
        @AuraEnabled public String newValue;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public String createdByName;
        @AuraEnabled public Boolean hasChanged;
    }

    @AuraEnabled(cacheable=true)
    public static List<HistoryRow> getHistory(Id recordId, Integer limitRows) {
        if (recordId == null) {
            throw new AuraHandledException('recordId es requerido.');
        }

        Integer safeLimit = (limitRows == null || limitRows <= 0) ? 200 : limitRows;
        if (safeLimit > 500) {
            safeLimit = 500;
        }

        List<HistoryRow> response = new List<HistoryRow>();

        try {
            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

            if (!globalDescribe.containsKey('ResidentialLoanApplication')) {
                throw new AuraHandledException('No existe el objeto ResidentialLoanApplication en esta org.');
            }

            Schema.DescribeSObjectResult rlaDescribe =
                globalDescribe.get('ResidentialLoanApplication').getDescribe();

            Map<String, Schema.SObjectField> fieldMap = rlaDescribe.fields.getMap();

            List<ResidentialLoanApplication> rows = [
                SELECT Id,
                    (
                        SELECT Id, Field, OldValue, NewValue, CreatedDate, CreatedBy.Name
                        FROM Histories
                        ORDER BY CreatedDate DESC
                        LIMIT :safeLimit
                    )
                FROM ResidentialLoanApplication
                WHERE Id = :recordId
                LIMIT 1
            ];

            if (rows.isEmpty()) {
                return response;
            }

            List<SObject> histories = rows[0].getSObjects('Histories');
            if (histories == null || histories.isEmpty()) {
                return response;
            }

            return buildHistoryRows(toHistorySources(histories), fieldMap);

        } catch (Exception e) {
            throw new AuraHandledException('Error obteniendo historial: ' + e.getMessage());
        }
    }

    @TestVisible
    private class HistorySource {
        private Id historyId;
        private String fieldName;
        private Object oldValue;
        private Object newValue;
        private Datetime createdDate;
        private String createdByName;

        @TestVisible
        private HistorySource(
            Id historyId,
            String fieldName,
            Object oldValue,
            Object newValue,
            Datetime createdDate,
            String createdByName
        ) {
            this.historyId = historyId;
            this.fieldName = fieldName;
            this.oldValue = oldValue;
            this.newValue = newValue;
            this.createdDate = createdDate;
            this.createdByName = createdByName;
        }
    }

    private static List<HistorySource> toHistorySources(List<SObject> histories) {
        List<HistorySource> sources = new List<HistorySource>();
        for (SObject sob : histories) {
            SObject createdBy = sob.getSObject('CreatedBy');
            sources.add(new HistorySource(
                (Id) sob.get('Id'),
                String.valueOf(sob.get('Field')),
                sob.get('OldValue'),
                sob.get('NewValue'),
                (Datetime) sob.get('CreatedDate'),
                createdBy != null ? String.valueOf(createdBy.get('Name')) : ''
            ));
        }
        return sources;
    }

    @TestVisible
    private static List<HistoryRow> buildHistoryRows(
        List<HistorySource> histories,
        Map<String, Schema.SObjectField> fieldMap
    ) {
        List<HistoryRow> response = new List<HistoryRow>();
        Set<String> excludedFields = new Set<String>{ 'Locked', 'Unlocked', 'locked', 'unlocked' };

        for (HistorySource source : histories) {
            if (excludedFields.contains(source.fieldName)) {
                continue;
            }

            response.add(buildHistoryRow(
                source.historyId,
                source.fieldName,
                source.oldValue,
                source.newValue,
                source.createdDate,
                source.createdByName,
                fieldMap
            ));
        }
        return response;
    }

    @TestVisible
    private static HistoryRow buildHistoryRow(
        Id historyId,
        String fieldName,
        Object oldValue,
        Object newValue,
        Datetime createdDate,
        String createdByName,
        Map<String, Schema.SObjectField> fieldMap
    ) {
        HistoryRow item = new HistoryRow();
        item.historyId = historyId;
        item.fieldApiName = fieldName;
        item.oldValue = stringifyHistoryValue(oldValue);
        item.newValue = stringifyHistoryValue(newValue);
        item.createdDate = createdDate;
        item.createdByName = createdByName == null ? '' : createdByName;
        item.fieldLabel = fieldMap.containsKey(fieldName)
            ? fieldMap.get(fieldName).getDescribe().getLabel()
            : fieldName;
        item.hasChanged = item.oldValue != item.newValue;
        return item;
    }

    private static String stringifyHistoryValue(Object value) {
        if (value == null) {
            return '';
        }

        if (value instanceof Datetime) {
            return ((Datetime) value).format('dd/MM/yyyy HH:mm');
        }

        if (value instanceof Date) {
            return ((Date) value).format();
        }

        if (value instanceof Time) {
            return String.valueOf(value);
        }

        return String.valueOf(value);
    }
}