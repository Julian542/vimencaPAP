/*********************************************************************************************
 * Nombre de clase Apex   :   VFS_GenerarDocumentosUtility
 * Versión                :   1.2
 * Fecha de creación      :   12/06/2025
 * Función                :   Utilidad para generar un ContentDocument PDF a partir de un Visualforce Page y un Id
 * Clase Test             :   VFS_GenerarDocumentosUtilityTest
 *
 * Registro de modificaciones:
 * ---------------------------------------------------------------------------------------------------
 * Desarrollador                        Fecha           Descripción
 * Edgar H. Luna                        12/06/2025      Versión original
 *********************************************************************************************/
public without sharing class VFS_GenerarDocumentosUtility {

    public class VFS_GenerarDocumentosUtilityException extends Exception {}

    @AuraEnabled(cacheable=false)
    public static Id generarPDFyContentDocument(String vfpName, Id recordId, String fileName) {
        try {
            // Validación de parámetros de entrada
            if (String.isBlank(vfpName)) {
                throw new VFS_GenerarDocumentosUtilityException('El nombre de la página Visualforce no puede estar vacío. Se requiere especificar una página válida para generar el PDF.');
            }
            
            if (recordId == null) {
                throw new VFS_GenerarDocumentosUtilityException('El ID del registro no puede estar vacío. Se requiere un registro válido para generar el PDF.');
            }
            
            if (String.isBlank(fileName)) {
                throw new VFS_GenerarDocumentosUtilityException('El nombre del archivo no puede estar vacío. Se requiere especificar un nombre para el documento PDF.');
            }
            
            // Obtener la referencia a la página Visualforce
            System.debug('Iniciando generación de PDF para Visualforce: ' + vfpName + ', recordId: ' + recordId + ', fileName: ' + fileName);
            PageReference pageRef = new PageReference('/apex/' + vfpName);
            pageRef.getParameters().put('id', String.valueOf(recordId));
            System.debug('PageReference creada: ' + pageRef);
            
            // Renderizar la página como PDF
            Blob pdfBlob;
            try {
                // Punto de falla simulado para testing
                if (Test.isRunningTest() && vfpName == 'FORCE_PDF_ERROR') {
                    throw new System.CalloutException('Error simulado al renderizar PDF');
                }
                pdfBlob = Test.isRunningTest() ? Blob.valueOf('Unit.Test') : pageRef.getContentAsPDF();
            } catch (Exception e) {
                throw new VFS_GenerarDocumentosUtilityException('Error al renderizar la página Visualforce "' + vfpName + '" como PDF: ' + e.getMessage() + '. Verifique que la página existe y tiene acceso a los datos del registro.');
            }
            
            ContentDocumentLink existingLink;
            try {
                existingLink = [
                    SELECT ContentDocumentId
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId = :recordId
                      AND ContentDocument.Title = :fileName
                    LIMIT 1
                ];
            } catch (QueryException e) {
                existingLink = null;
            }

            ContentVersion cv = new ContentVersion(
                Title = fileName,
                PathOnClient = fileName + '.pdf',
                VersionData = pdfBlob,
                IsMajorVersion = true,
                FSC_ClaveTecnicaPrecarga__c = FSC_ChecklistDocsPrecargaService.resolveGeneratedKey(fileName)
            );

            if (existingLink != null) {
                cv.ContentDocumentId = existingLink.ContentDocumentId;
                try {
                    // Punto de falla simulado para testing - actualización de documento
                    if (Test.isRunningTest() && fileName == 'FORCE_UPDATE_ERROR') {
                        throw new DmlException('Error simulado al actualizar documento');
                    }
                    insert cv;
                } catch (DmlException e) {
                    throw new VFS_GenerarDocumentosUtilityException('Error al actualizar el documento existente "' + fileName + '": ' + e.getMessage());
                }
                return cv.ContentDocumentId;
            } else {
                try {
                    // Punto de falla simulado para testing - creación de documento
                    if (Test.isRunningTest() && fileName == 'FORCE_CREATE_ERROR') {
                        throw new DmlException('Error simulado al crear documento');
                    }
                    insert cv;
                } catch (DmlException e) {
                    throw new VFS_GenerarDocumentosUtilityException('Error al crear el documento "' + fileName + '": ' + e.getMessage());
                }
                
                // Obtener el ContentDocumentId del ContentVersion recién insertado
                Id contentDocumentId;
                try {
                    contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
                } catch (QueryException e) {
                    throw new VFS_GenerarDocumentosUtilityException('Error al obtener el ID del documento creado: ' + e.getMessage());
                }
                
                // Crear el ContentDocumentLink
                ContentDocumentLink cdl = new ContentDocumentLink(
                    ContentDocumentId = contentDocumentId,
                    LinkedEntityId = recordId,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                );
                try {
                    insert cdl;
                } catch (DmlException e) {
                    throw new VFS_GenerarDocumentosUtilityException('Error al vincular el documento "' + fileName + '" con el registro: ' + e.getMessage());
                }
                return contentDocumentId;
            }
            
        } catch (VFS_GenerarDocumentosUtilityException e) {
            // Convertir excepción personalizada a AuraHandledException para LWC
            String errorMessage = e.getMessage();
            Exception auraEx = new AuraHandledException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        } catch (Exception e) { // Manejar cualquier otra excepción inesperada
            String errorMessage = 'Error inesperado al generar el documento PDF. Por favor, contacte al administrador del sistema.';
            Exception auraEx = new AuraHandledException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        }
}

    @AuraEnabled(cacheable=false)
    public static Id generarPDFDesdeDefinicion(String name, Id recordId) {
        try {
            // Validación de parámetros de entrada
            if (String.isBlank(name)) {
                throw new VFS_GenerarDocumentosUtilityException('El nombre de la definición de documento no puede estar vacío. Se requiere especificar una definición válida.');
            }
            
            if (recordId == null) {
                throw new VFS_GenerarDocumentosUtilityException('El ID del registro no puede estar vacío. Se requiere un registro válido para generar el PDF.');
            }
            
            // Consultar la definición de documento usando SObject genérico para evitar errores de tipo
            System.debug('Iniciando generación de PDF desde definición: ' + name + ', recordId: ' + recordId);
            List<SObject> defs;
            try {
                // Punto de falla simulado para testing - error en consulta
                if (Test.isRunningTest() && name == 'FORCE_QUERY_ERROR') {
                    throw new QueryException('Error simulado en consulta de definición');
                }
                defs = Database.query('SELECT VFS_Visualforce__c, VFS_NombreDocumento__c FROM VFS_DefinicionDocumentos__c WHERE VFS_NombreDocumento__c = :name LIMIT 1');
            } catch (QueryException e) { throw new VFS_GenerarDocumentosUtilityException('Error al consultar la definición de documento "' + name + '": ' + e.getMessage() + '. Verifique que el objeto VFS_DefinicionDocumentos__c existe y tiene los permisos apropiados.');
            }
            
            if (defs.isEmpty()) {
                throw new VFS_GenerarDocumentosUtilityException('No se encontró ninguna definición de documento con el nombre "' + name + '". Verifique que la definición existe y está configurada correctamente.');
            }
            
            SObject def = defs[0];
            String vfpName = (String)def.get('VFS_Visualforce__c');
            String fileName = (String)def.get('VFS_NombreDocumento__c');
            
            Id docid = generarPDFyContentDocument(vfpName, recordId, fileName);
            System.debug('ContentDocumentId generado: ' + docid);
            return docid;
            
        } catch (VFS_GenerarDocumentosUtilityException e) {
            // Convertir excepción personalizada a AuraHandledException para LWC
            String errorMessage = e.getMessage();
            Exception auraEx = new AuraHandledException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        } catch (AuraHandledException e) { // Re-lanzar excepciones que ya vienen del método generarPDFyContentDocument
            throw e;
        } catch (Exception e) { // Manejar cualquier otra excepción inesperada
            String errorMessage = 'Error inesperado al generar PDF desde la definición de documento. Por favor, contacte al administrador del sistema.';
            Exception auraEx = new AuraHandledException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        }
    }

    // Método que se llama desde LWC para obtener el contentDocumentId buscando por título y id relacionado
    @AuraEnabled(cacheable=true)
    public static Id obtenerContentDocumentId(String titulo, Id recordId) {
        try {
            system.debug('Buscando ContentDocumentId para título: ' + titulo + ', recordId: ' + recordId);
            // Validación de parámetros de entrada
            if (String.isBlank(titulo)) {
                throw new VFS_GenerarDocumentosUtilityException('El título del documento no puede estar vacío. Se requiere especificar un título válido para buscar el documento.');
            }
            
            if (recordId == null) {
                throw new VFS_GenerarDocumentosUtilityException('El ID del registro no puede estar vacío. Se requiere un registro válido para buscar documentos vinculados.');
            }
            
            // Consultar el ContentDocumentLink por título y Id relacionado
            List<ContentDocumentLink> links;
            try {
                // Punto de falla simulado para testing - error en consulta ContentDocumentLink
                if (Test.isRunningTest() && titulo == 'FORCE_LINK_QUERY_ERROR') {
                    throw new QueryException('Error simulado en consulta de ContentDocumentLink');
                }
                links = [
                    SELECT ContentDocumentId
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId = :recordId
                      AND ContentDocument.Title = :titulo
                    LIMIT 1
                ];
            } catch (QueryException e) { throw new VFS_GenerarDocumentosUtilityException('Error al buscar el documento "' + titulo + '" vinculado al registro: ' + e.getMessage());
            }
            
            if (links.isEmpty()) {
                return null; 
            }
            
            return links[0].ContentDocumentId; 
            
        } catch (VFS_GenerarDocumentosUtilityException e) {
            // Convertir excepción personalizada a AuraHandledException para LWC
            String errorMessage = e.getMessage();
            Exception auraEx = new AuraHandledException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        } catch (Exception e) { // Manejar cualquier otra excepción inesperada
            String errorMessage = 'Error inesperado al obtener el documento. Por favor, contacte al administrador del sistema.';
            Exception auraEx = new AuraHandledException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static string GenerarURl(String contentDocumentId) {
        try {
            // Validación de parámetro de entrada
            if (String.isBlank(contentDocumentId)) {
                throw new VFS_GenerarDocumentosUtilityException('El ID del documento no puede estar vacío. Se requiere un ContentDocumentId válido para generar la URL.');
            }
            
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            String url = baseUrl+'/' + contentDocumentId;
            return url;
            
        } catch (VFS_GenerarDocumentosUtilityException e) {
            // Convertir excepción personalizada a AuraHandledException para LWC
            String errorMessage = e.getMessage();
            Exception auraEx = new AuraHandledException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        } catch (Exception e) { // Manejar cualquier otra excepción inesperada
            String errorMessage = 'Error inesperado al generar la URL del documento. Por favor, contacte al administrador del sistema.';
            Exception auraEx = new AuraHandledException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        }
    }
    @AuraEnabled(cacheable=false)
    public static String GetTitulo(String ButtonName){
        try {
            // Validación de parámetro de entrada
            if (String.isBlank(ButtonName)) {
                throw new VFS_GenerarDocumentosUtilityException('El nombre del botón no puede estar vacío. Se requiere especificar el tipo de proceso para obtener el título correspondiente.');
            }
            
            String titulo = '';
            if( ButtonName == 'Firmar_documento_KYCF') {
                titulo = 'Conozca su cliente persona física';
            } else if (ButtonName == 'Firmar_documento_KYCJ'){
                titulo = 'Conozca su cliente persona jurídica';
            }
            else if (ButtonName == 'VFS_FirmaAperturaCuenta') {
                titulo = 'Apertura de cuenta de ahorro';
            }else if(ButtonName == 'VFS_FirmarContratoUnico'){
                titulo = 'Contrato Único';
            } else {
                // Si no se encuentra el ButtonName, devolver error descriptivo
                throw new VFS_GenerarDocumentosUtilityException('Tipo de proceso no reconocido: "' + ButtonName + '". Los tipos válidos son: Firmar_documento_KYCF, Firmar_documento_KYCJ, VFS_FirmaAperturaCuenta, VFS_FirmarContratoUnico.');
            }
            
            return titulo;
            
        } catch (VFS_GenerarDocumentosUtilityException e) {
            // Convertir excepción personalizada a AuraHandledException para LWC
            String errorMessage = e.getMessage();
            Exception auraEx = new AuraHandledException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        } catch (Exception e) { // Manejar cualquier otra excepción inesperada
            String errorMessage = 'Error inesperado al obtener el título del documento. Por favor, contacte al administrador del sistema.';
            Exception auraEx = new AuraHandledException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        }
    }
    @AuraEnabled(cacheable=true)
    public static Boolean obtenerContratoFirmadoERP(Id accountId) {
        try {
            // Validación de parámetro de entrada
            if (accountId == null) {
                throw new VFS_GenerarDocumentosUtilityException('El ID de la cuenta no puede estar vacío. Se requiere un ID válido de Account para consultar el estado del contrato.');
            }
            
            Account acc;
            try {
                // Punto de falla simulado para testing - error en consulta Account
                if (Test.isRunningTest() && String.valueOf(accountId).endsWith('FORCE_ACCOUNT_QUERY_ERROR')) {
                    throw new QueryException('Error simulado en consulta de Account');
                }
                acc = [SELECT VFS_ContratoFirmadoERP__c FROM Account WHERE Id = :accountId LIMIT 1];
            } catch (QueryException e) { throw new VFS_GenerarDocumentosUtilityException('Error al consultar la cuenta: ' + e.getMessage() + '. Verifique que el ID de cuenta es válido y que tiene permisos de acceso.');
            }
            
            return acc.VFS_ContratoFirmadoERP__c;
            
        } catch (VFS_GenerarDocumentosUtilityException e) {
            // Convertir excepción personalizada a AuraHandledException para LWC
            String errorMessage = e.getMessage();
            Exception auraEx = new AuraHandledException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        } catch (Exception e) { // Manejar cualquier otra excepción inesperada
            String errorMessage = 'Error inesperado al consultar el estado del contrato firmado. Por favor, contacte al administrador del sistema.';
            Exception auraEx = new AuraHandledException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        }
    }
}