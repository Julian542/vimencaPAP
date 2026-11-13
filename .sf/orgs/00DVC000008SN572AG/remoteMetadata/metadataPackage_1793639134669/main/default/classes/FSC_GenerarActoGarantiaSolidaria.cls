public without sharing class FSC_GenerarActoGarantiaSolidaria {
    @AuraEnabled
    public static Id generar(Id residentialLoanApplicationId) {
        if (residentialLoanApplicationId == null) {
            throw new AuraHandledException('Solicitud requerida.');
        }

        Map<String, Object> permissionContext =
            FSC_RlaAccionesController.getPagaresContext(residentialLoanApplicationId);
        if (permissionContext.get('canGeneratePagare') != true) {
            throw new AuraHandledException('No tiene autorización para generar documentos de esta solicitud.');
        }

        ResidentialLoanApplication rla = [
            SELECT Id, Account.Name, RecordType.DeveloperName, FSC_Requiere_Acto_Garantia__c,
                FSC_Acto_Garantia_Generado__c, FSC_Subestado__c
            FROM ResidentialLoanApplication
            WHERE Id = :residentialLoanApplicationId
            LIMIT 1
            FOR UPDATE
        ];
        if (rla.FSC_Subestado__c == FSC_DocumentacionContratosService.SUBESTADO_CARGA) {
            throw new AuraHandledException('Debe enviar y aprobar la documentación para contratos antes de generar documentos.');
        }
        if (rla.FSC_Subestado__c == FSC_DocumentacionContratosService.SUBESTADO_GENERACION) {
            FSC_DocumentacionContratosService.validarGeneracion(residentialLoanApplicationId);
        }
        if (rla.RecordType.DeveloperName != 'FSC_Solicitud_Credito_PYME') {
            throw new AuraHandledException('El acto de garantía solidaria solo aplica a créditos PYME.');
        }
        if (rla.FSC_Requiere_Acto_Garantia__c != true) {
            throw new AuraHandledException('Análisis no indicó que se debe generar el acto de garantía solidaria.');
        }
        if (rla.FSC_Acto_Garantia_Generado__c == true) {
            throw new AuraHandledException('El acto de garantía solidaria ya fue generado.');
        }

        PageReference pageReference = Page.FSC_ActoGarantiaSolidariaPDF;
        pageReference.getParameters().put('id', String.valueOf(residentialLoanApplicationId));
        pageReference.getParameters().put('fechaActo', String.valueOf(Date.today()));
        Blob pdfBlob = Test.isRunningTest() ? Blob.valueOf('TEST PDF') : pageReference.getContentAsPDF();
        if (pdfBlob == null || pdfBlob.size() == 0) {
            throw new AuraHandledException('El acto de garantía solidaria se generó vacío.');
        }

        String title = 'CONTRATO DE SOLIDARIDAD - ACTO DE GARANTIA SOLIDARIA ' +
            rla.Account.Name + ' ' + String.valueOf(rla.Id);
        ContentVersion file = new ContentVersion(
            Title = title,
            PathOnClient = title + '.pdf',
            VersionData = pdfBlob,
            FirstPublishLocationId = rla.Id,
            FSC_EnviarDocumento__c = true
        );
        insert file;

        update new ResidentialLoanApplication(
            Id = rla.Id,
            FSC_Acto_Garantia_Generado__c = true,
            FSC_EnviadoAFirmar__c = false
        );
        return file.Id;
    }
}