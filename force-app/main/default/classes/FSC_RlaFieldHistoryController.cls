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

            Set<String> excludedFields = new Set<String>{
                'Locked', 'Unlocked', 'locked', 'unlocked'
            };

            for (SObject sob : histories) {

                String fieldName = String.valueOf(sob.get('Field'));

                if (excludedFields.contains(fieldName)) {
                    continue;
                }

                HistoryRow item = new HistoryRow();

                item.historyId = (Id) sob.get('Id');
                item.fieldApiName = fieldName;
                item.oldValue = stringifyHistoryValue(sob.get('OldValue'));
                item.newValue = stringifyHistoryValue(sob.get('NewValue'));
                item.createdDate = (Datetime) sob.get('CreatedDate');

                SObject createdBy = sob.getSObject('CreatedBy');
                item.createdByName = createdBy != null ? String.valueOf(createdBy.get('Name')) : '';

                if (fieldMap.containsKey(item.fieldApiName)) {
                    item.fieldLabel = fieldMap.get(item.fieldApiName).getDescribe().getLabel();
                } else {
                    item.fieldLabel = item.fieldApiName;
                }

                item.hasChanged = item.oldValue != item.newValue;

                response.add(item);
            }

            return response;

        } catch (Exception e) {
            throw new AuraHandledException('Error obteniendo historial: ' + e.getMessage());
        }
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