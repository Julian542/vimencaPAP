public without sharing class FSC_GenerarPagarePDF_Action {

    private static String normalizeFieldValue(Object value) {
        return value == null ? null : String.valueOf(value).trim();
    }

    public class Input {
        @InvocableVariable(required=true)
        public Id residentialLoanApplicationId;
    }

    public class Output {
        @InvocableVariable
        public Id contentVersionId;

        @InvocableVariable
        public Id contentDocumentId;

        @InvocableVariable
        public String status;

        @InvocableVariable
        public String message;
    }

    @InvocableMethod(label='Generar Pagaré PDF (Visualforce)' description='Genera el PDF desde VF y lo adjunta como File al ResidentialLoanApplication')
    public static List<Output> run(List<Input> inputs) {
        List<Output> results = new List<Output>();
        List<Id> listId = new List<Id>();
        for (Input variable : inputs) {
            if (variable != null && variable.residentialLoanApplicationId != null) {
                listId.add(variable.residentialLoanApplicationId);
            }
        }

        Map<Id, ResidentialLoanApplication> rlaMap = new Map<Id, ResidentialLoanApplication>();
        if (!listId.isEmpty()) {
            rlaMap = new Map<Id, ResidentialLoanApplication>([
                SELECT Id, Account.Name
                FROM ResidentialLoanApplication
                WHERE Id IN :listId
            ]);
        }
        for (Input i : inputs) {
            Output o = new Output();
            Savepoint sp = Database.setSavepoint();
            try {
                if (i == null || i.residentialLoanApplicationId == null) {
                    o.status = 'ERROR';
                    o.message = 'residentialLoanApplicationId es requerido';
                    results.add(o);
                    continue;
                }

                ResidentialLoanApplication rla = [
                    SELECT Id,
                           CreatedDate,
                           FSC_Pagares_y_Plantillas_Generados__c,
                           FSC_ActoNumeroPagare__c,
                           FSC_NumeroFolioPagare__c,
                           FSC_Subestado__c,
                           FSC_Monto__c,
                           FSC_MontoAprobado__c,
                           FSC_Plazo_meses__c,
                           FSC_PlazoMesesAprobado__c,
                           FSC_TasaInteres__c,
                           FSC_TasaInteresAprobada__c,
                           FSC_Aprobado_con_Condiciones__c
                    FROM ResidentialLoanApplication
                    WHERE Id = :i.residentialLoanApplicationId
                    LIMIT 1
                ];

                String actoNumeroPagare = normalizeFieldValue(rla.FSC_ActoNumeroPagare__c);
                String numeroFolioPagare = normalizeFieldValue(rla.get('FSC_NumeroFolioPagare__c'));

                if (String.isBlank(actoNumeroPagare) || String.isBlank(numeroFolioPagare)) {
                    o.status = 'ERROR';
                    o.message = 'Debe completar los campos Acto número pagaré y Número de folio antes de generar el pagaré.';
                    results.add(o);
                    continue;
                }

                if (rla.FSC_Pagares_y_Plantillas_Generados__c == true) {
                    o.status = 'ERROR';
                    o.message = 'El pagare ya fue generado para esta solicitud.';
                    results.add(o);
                    continue;
                }

                ResidentialLoanApplication rlaHeader = rlaMap.get(i.residentialLoanApplicationId);
                String accountName = (rlaHeader != null && rlaHeader.Account != null)
                    ? rlaHeader.Account.Name
                    : 'Sin Nombre';

                String finalName = 'Pagare ' + accountName + ' ' + System.now().format('yyyy-MM-dd-HH-mm-ss') + '.pdf';

                PageReference pr = Page.FSC_PagarePDF;
                pr.getParameters().put('id', String.valueOf(i.residentialLoanApplicationId));

                Blob pdfBlob;
                if (Test.isRunningTest()) {
                    pdfBlob = Blob.valueOf('TEST PDF');
                } else {
                    pdfBlob = pr.getContentAsPDF();
                }

                ContentVersion cv = new ContentVersion();
                cv.Title = finalName.replace('.pdf','');
                cv.PathOnClient = finalName;
                cv.VersionData = pdfBlob;
                cv.FSC_EnviarDocumento__c = true;
                insert cv;

                cv = [
                    SELECT Id, ContentDocumentId
                    FROM ContentVersion
                    WHERE Id = :cv.Id
                    LIMIT 1
                ];

                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.LinkedEntityId = i.residentialLoanApplicationId;
                cdl.ContentDocumentId = cv.ContentDocumentId;
                cdl.ShareType = 'V';
                cdl.Visibility = 'AllUsers';
                insert cdl;

                Boolean aprobadoConCondiciones = rla.FSC_Aprobado_con_Condiciones__c == true;

                if (!aprobadoConCondiciones) {
                    rla.FSC_MontoAprobado__c = rla.FSC_Monto__c;
                    rla.FSC_PlazoMesesAprobado__c = (rla.FSC_Plazo_meses__c == null)
                        ? null
                        : Integer.valueOf(rla.FSC_Plazo_meses__c);
                    rla.FSC_TasaInteresAprobada__c = rla.FSC_TasaInteres__c;
                }

                rla.FSC_Pagares_y_Plantillas_Generados__c = true;
                rla.FSC_Subestado__c = 'Generación de contrato';
                update rla;

                o.status = 'OK';
                o.message = 'PDF generado y adjuntado como File.';
                o.contentVersionId = cv.Id;
                o.contentDocumentId = cv.ContentDocumentId;

            } catch (Exception e) {
                Database.rollback(sp);
                o.status = 'ERROR';
                o.message = e.getMessage();
            }
            results.add(o);
        }
        return results;
    }
}