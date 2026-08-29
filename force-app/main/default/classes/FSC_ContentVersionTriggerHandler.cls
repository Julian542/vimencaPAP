public with sharing class FSC_ContentVersionTriggerHandler {

    public static Id validacionDocumentosFirmados(ContentVersion record) {
        if (record == null || record.ContentDocumentId == null) {
            return null;
        }

        List<ContentDocumentLink> currentLinks = [
            SELECT Id, LinkedEntityId, ContentDocumentId
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :record.ContentDocumentId
        ];

        if (currentLinks.isEmpty()) {
            return null;
        }

        Id linkedEntityId;
        for (ContentDocumentLink cdl : currentLinks) {
            if (cdl.LinkedEntityId != null &&
                cdl.LinkedEntityId.getSObjectType() == ResidentialLoanApplication.SObjectType) {
                linkedEntityId = cdl.LinkedEntityId;
                break;
            }
        }

        if (linkedEntityId == null) {
            return null;
        }

        List<ContentDocumentLink> allLinks = [
            SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :linkedEntityId
            AND ContentDocument.LatestPublishedVersion.FSC_EnviarDocumento__c = true
            AND ContentDocument.LatestPublishedVersion.FSC_FechaEnvioFirma__c != null
        ];

        if (allLinks.isEmpty()) {
            return null;
        }

        Set<Id> contentVersionIds = new Set<Id>();
        for (ContentDocumentLink cdl : allLinks) {
            if (cdl.ContentDocument.LatestPublishedVersionId != null) {
                contentVersionIds.add(cdl.ContentDocument.LatestPublishedVersionId);
            }
        }

        if (contentVersionIds.isEmpty()) {
            return null;
        }

        List<ContentVersion> versions = [
            SELECT Id, Title, ContentDocumentId, FSC_EnviarDocumento__c, FSC_Firmado__c
            FROM ContentVersion
            WHERE Id IN :contentVersionIds
        ];

        Integer documentosEnviados = versions.size();
        Integer documentosEnviadosYFirmados = 0;

        for (ContentVersion cv : versions) {
            if (cv.FSC_Firmado__c == true) {
                documentosEnviadosYFirmados++;
            }
        }

        if (documentosEnviados > 0 && documentosEnviados == documentosEnviadosYFirmados) {
            return linkedEntityId;
        }

        return null;
    }

    public static void actualizarRLAs(Set<Id> rlaIds) {
        actualizarSiFirmasCompletas(rlaIds);
    }

    public static void actualizarSiFirmasCompletas(Set<Id> rlaIds) {
        if (rlaIds == null || rlaIds.isEmpty()) {
            return;
        }

        Set<Id> rlaIdsConFirmasDigitalesCompletas = new Set<Id>();
        for (Id rlaId : rlaIds) {
            if (tieneFirmasDigitalesCompletas(rlaId)) {
                rlaIdsConFirmasDigitalesCompletas.add(rlaId);
            }
        }

        if (rlaIdsConFirmasDigitalesCompletas.isEmpty()) {
            return;
        }

        List<ResidentialLoanApplication> rlasToCheck = [
            SELECT Id, FSC_Firma_completada__c, FSC_Subestado__c, FSC_DocumentosFirmadosFis__c
            FROM ResidentialLoanApplication
            WHERE Id IN :rlaIdsConFirmasDigitalesCompletas
        ];

        List<ResidentialLoanApplication> rlasToUpdate = new List<ResidentialLoanApplication>();
        for (ResidentialLoanApplication rla : rlasToCheck) {
            if (rla.FSC_DocumentosFirmadosFis__c != true) {
                continue;
            }
            rlasToUpdate.add(new ResidentialLoanApplication(
                Id = rla.Id,
                FSC_Firma_completada__c = true,
                FSC_Subestado__c = 'Documentación para desembolso y firmas'
            ));
        }

        if (!rlasToUpdate.isEmpty()) {
            update rlasToUpdate;
        }
    }

    private static Boolean tieneFirmasDigitalesCompletas(Id rlaId) {
        if (rlaId == null) {
            return false;
        }

        List<ContentDocumentLink> allLinks = [
            SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :rlaId
        ];

        if (allLinks.isEmpty()) {
            return false;
        }

        Set<Id> contentVersionIds = new Set<Id>();
        for (ContentDocumentLink cdl : allLinks) {
            if (cdl.ContentDocument.LatestPublishedVersionId != null) {
                contentVersionIds.add(cdl.ContentDocument.LatestPublishedVersionId);
            }
        }

        if (contentVersionIds.isEmpty()) {
            return false;
        }

        Integer documentosDigitalesEnviados = 0;
        Boolean tieneArchivoFirmadoDescargado = false;

        for (ContentVersion version : [
            SELECT Id, Title, FSC_EnviarDocumento__c, FSC_FechaEnvioFirma__c, FSC_Firmado__c
            FROM ContentVersion
            WHERE Id IN :contentVersionIds
        ]) {
            if (isDocumentoDigitalEnviado(version)) {
                documentosDigitalesEnviados++;
                if (version.FSC_Firmado__c != true) {
                    return false;
                }
            }

            if (isArchivoFirmadoDescargado(version)) {
                tieneArchivoFirmadoDescargado = true;
            }
        }

        if (documentosDigitalesEnviados > 0) {
            return true;
        }

        return tieneArchivoFirmadoDescargado;
    }

    private static Boolean isDocumentoDigitalEnviado(ContentVersion version) {
        return version != null &&
            version.FSC_EnviarDocumento__c == true &&
            version.FSC_FechaEnvioFirma__c != null;
    }

    private static Boolean isArchivoFirmadoDescargado(ContentVersion version) {
        if (version == null || version.FSC_Firmado__c != true || String.isBlank(version.Title)) {
            return false;
        }

        return version.Title.trim().toLowerCase().endsWith('_firmado');
    }
}