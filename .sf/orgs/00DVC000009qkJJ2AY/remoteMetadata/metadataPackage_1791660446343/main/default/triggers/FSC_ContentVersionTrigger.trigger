trigger FSC_ContentVersionTrigger on ContentVersion (after update) {
    Set<Id> rlaList = new Set<Id>();

    if (Trigger.isAfter && Trigger.isUpdate) {
        for (ContentVersion record : Trigger.new) {
            ContentVersion oldRecord = Trigger.oldMap.get(record.Id);

            if (record.FSC_Firmado__c == true &&
                oldRecord.FSC_Firmado__c != record.FSC_Firmado__c) {

                Id rlaId = FSC_ContentVersionTriggerHandler.validacionDocumentosFirmados(record);
                if (rlaId != null) {
                    rlaList.add(rlaId);
                }
            }
        }
    }

    if (!rlaList.isEmpty()) {
        FSC_ContentVersionTriggerHandler.actualizarRLAs(rlaList);
    }
}