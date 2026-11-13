/*********************************************************************************************
 * Nombre de clase Apex   :   VFS_EsignUploadDocument
 * Versión                :   1.0
 * Fecha de creación      :   10/06/2025
 * Función                :   Clase para cargar documentos PDF a EsignAnywhere
 * Clase Test             :   VFS_EsignUploadDocumentTest
 *
 * Registro de modificaciones:
 * ---------------------------------------------------------------------------------------------------
 * Desarrollador                        Fecha           Descripción
 * Edgar H. Luna                        10/06/2025      Versión original
 *********************************************************************************************/
@SuppressWarnings('PMD')
public with sharing class VFS_EsignUploadDocument {

    @AuraEnabled(cacheable=false)
    public static UploadResult uploadDocument(String ContentDocumentId) {
        UploadResult result = new UploadResult();
        try {
            ContentVersion cv = [
                SELECT VersionData, ContentDocument.Title
                FROM ContentVersion
                WHERE ContentDocumentId = :ContentDocumentId AND IsLatest = true
                LIMIT 1
            ];
            Blob pdfBody = cv.VersionData;
            System.debug('Blob size: ' + pdfBody.size());
            System.debug('cv.VersionData size: ' + cv.VersionData.size());

            // Generar multipart/form-data
            String boundary = '--------------------------' + String.valueOf(DateTime.now().getTime());
            String CRLF = '\r\n';

            String headerString =
                '--' + boundary + CRLF +
                'Content-Disposition: form-data; name="file"; filename="' + cv.ContentDocument.Title + '.pdf"' + CRLF +
                'Content-Type: application/pdf' + CRLF + CRLF;

            String footerString = CRLF + '--' + boundary + '--' + CRLF;

            Blob headerBlob = Blob.valueOf(headerString);
            Blob footerBlob = Blob.valueOf(footerString);

            // Concatenar blobs de forma segura sin exceder límites
            Blob fullBody = safeConcatenate(new List<Blob>{ headerBlob, pdfBody, footerBlob });

            // Preparar HTTP request
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:VFS_Esignanywhere/Api/v6/file/upload');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'multipart/form-data; boundary=' + boundary);
            req.setBodyAsBlob(fullBody);

            HttpResponse res;
            try {
                res = new Http().send(req);

                if (res.getStatusCode() == 200) {
                    Map<String, Object> respMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    if (respMap.containsKey('FileId')) {
                        result.success = true;
                        result.fileId = (String) respMap.get('FileId');
                    }
                } else {
                    result.success = false;
                    result.message = 'Error HTTP: ' + res.getStatus() + ' - ' + res.getBody();
                }

            } catch (Exception e) {
                result.success = false;
                result.message = 'Excepción al enviar el documento: ' + e.getMessage();
            }

        } catch (QueryException qe) {
            result.success = false;
            result.message = 'Excepción al consultar el documento: ' + qe.getMessage();
            return result;
        } catch (Exception e) {
            result.success = false;
            result.message = 'Excepción al enviar el documento: ' + e.getMessage();
            return result;
        }
        return result;
    }

    // Método auxiliar para concatenar Blobs sin exceder límites de String
    private static Blob safeConcatenate(List<Blob> parts) {
        List<String> hexParts = new List<String>();
        for (Blob b : parts) {
            hexParts.add(EncodingUtil.convertToHex(b));
        }
        String combinedHex = String.join(hexParts, '');
        return EncodingUtil.convertFromHex(combinedHex);
    }

    // Clase wrapper para devolver el resultado
    public class UploadResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String fileId;
        @AuraEnabled public String errorId;
        @AuraEnabled public String message;
        @AuraEnabled public String traceId;
    }
}