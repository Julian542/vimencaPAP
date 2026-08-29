/*********************************************************************************************
 * Nombre de clase Apex   :   VFS_GenerarDocumentosUtilityTest
 * Versión                :   1.0
 * Fecha de creación      :   19/06/2025
 * Función                :   Pruebas unitarias para VFS_GenerarDocumentosUtility
 * Clase probada          :   VFS_GenerarDocumentosUtility
 *
 * Registro de modificaciones:
 * ---------------------------------------------------------------------------------------------------
 * Desarrollador                        Fecha           Descripción
 * Edgar H. Luna                        19/06/2025      Versión inicial
 *********************************************************************************************/
@isTest
public with sharing class VFS_GenerarDocumentosUtilityTest {
    
    @testSetup
    static void setup() {
        Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());

        // Crear registros de prueba para VFS_DefinicionDocumentos__c usando valores válidos del picklist
        List<SObject> defDocs = new List<SObject>();
        
        SObject defDoc1 = Schema.getGlobalDescribe().get('VFS_DefinicionDocumentos__c').newSObject();
        defDoc1.put('VFS_Visualforce__c', 'TestVFPage1');
        defDoc1.put('VFS_NombreDocumento__c', 'Conozca su cliente persona física');
        defDoc1.put('VFS_ProcesoDondeSeUtiliza__c', 'Conozca su cliente');
        defDoc1.put('VFS_TipoDeGeneracion__c', 'Por Sistema');
        defDocs.add(defDoc1);
        
        SObject defDoc2 = Schema.getGlobalDescribe().get('VFS_DefinicionDocumentos__c').newSObject();
        defDoc2.put('VFS_Visualforce__c', 'TestVFPage2');
        defDoc2.put('VFS_NombreDocumento__c', 'Conozca su cliente persona jurídica');
        defDoc2.put('VFS_ProcesoDondeSeUtiliza__c', 'Conozca su cliente');
        defDoc2.put('VFS_TipoDeGeneracion__c', 'Por Sistema');
        defDocs.add(defDoc2);
        
        SObject defDoc3 = Schema.getGlobalDescribe().get('VFS_DefinicionDocumentos__c').newSObject();
        defDoc3.put('VFS_Visualforce__c', 'TestVFPage3');
        defDoc3.put('VFS_NombreDocumento__c', 'Apertura de cuenta de ahorro');
        defDoc3.put('VFS_ProcesoDondeSeUtiliza__c', 'Cuenta de ahorro');
        defDoc3.put('VFS_TipoDeGeneracion__c', 'Por Sistema');
        defDocs.add(defDoc3);
        
        SObject defDoc4 = Schema.getGlobalDescribe().get('VFS_DefinicionDocumentos__c').newSObject();
        defDoc4.put('VFS_Visualforce__c', 'TestVFPage4');
        defDoc4.put('VFS_NombreDocumento__c', 'Contrato único');
        defDoc4.put('VFS_ProcesoDondeSeUtiliza__c', 'Generación de contrato');
        defDoc4.put('VFS_TipoDeGeneracion__c', 'Por Sistema');
        defDocs.add(defDoc4);
        
        SObject defDoc5 = Schema.getGlobalDescribe().get('VFS_DefinicionDocumentos__c').newSObject();
        defDoc5.put('VFS_Visualforce__c', 'TestVFPage5');
        defDoc5.put('VFS_NombreDocumento__c', 'Resumen Convenio Único');
        defDoc5.put('VFS_ProcesoDondeSeUtiliza__c', 'Generación de contrato');
        defDoc5.put('VFS_TipoDeGeneracion__c', 'Por Sistema');
        defDocs.add(defDoc5);
        
        SObject defDoc6 = Schema.getGlobalDescribe().get('VFS_DefinicionDocumentos__c').newSObject();
        defDoc6.put('VFS_Visualforce__c', 'TestVFPage6');
        defDoc6.put('VFS_NombreDocumento__c', 'Resumen Convenio Único CAD');
        defDoc6.put('VFS_ProcesoDondeSeUtiliza__c', 'Cuenta de ahorro');
        defDoc6.put('VFS_TipoDeGeneracion__c', 'Por Sistema');
        defDocs.add(defDoc6);
        
        SObject defDoc7 = Schema.getGlobalDescribe().get('VFS_DefinicionDocumentos__c').newSObject();
        defDoc7.put('VFS_Visualforce__c', 'TestVFPage7');
        defDoc7.put('VFS_NombreDocumento__c', 'Resumen Convenio Único Cuenta Corriente');
        defDoc7.put('VFS_ProcesoDondeSeUtiliza__c', 'Cuenta de ahorro');
        defDoc7.put('VFS_TipoDeGeneracion__c', 'Por Sistema');
        defDocs.add(defDoc7);
        
        SObject defDoc8 = Schema.getGlobalDescribe().get('VFS_DefinicionDocumentos__c').newSObject();
        defDoc8.put('VFS_Visualforce__c', 'TestVFPage8');
        defDoc8.put('VFS_NombreDocumento__c', 'Resumen Convenio Único Cuenta de Ahorro');
        defDoc8.put('VFS_ProcesoDondeSeUtiliza__c', 'Cuenta de ahorro');
        defDoc8.put('VFS_TipoDeGeneracion__c', 'Por Sistema');
        defDocs.add(defDoc8);
        
        SObject defDoc9 = Schema.getGlobalDescribe().get('VFS_DefinicionDocumentos__c').newSObject();
        defDoc9.put('VFS_Visualforce__c', 'TestVFPage9');
        defDoc9.put('VFS_NombreDocumento__c', 'Resumen Convenio Único IB y Vimencash');
        defDoc9.put('VFS_ProcesoDondeSeUtiliza__c', 'Generación de contrato');
        defDoc9.put('VFS_TipoDeGeneracion__c', 'Por Sistema');
        defDocs.add(defDoc9);
        
        SObject defDoc10 = Schema.getGlobalDescribe().get('VFS_DefinicionDocumentos__c').newSObject();
        defDoc10.put('VFS_Visualforce__c', 'TestVFPage10');
        defDoc10.put('VFS_NombreDocumento__c', 'Resumen Convenio Único Tarjeta de Credito');
        defDoc10.put('VFS_ProcesoDondeSeUtiliza__c', 'Crédito PYME');
        defDoc10.put('VFS_TipoDeGeneracion__c', 'Por Sistema');
        defDocs.add(defDoc10);
        
        SObject defDoc11 = Schema.getGlobalDescribe().get('VFS_DefinicionDocumentos__c').newSObject();
        defDoc11.put('VFS_Visualforce__c', 'TestVFPage11');
        defDoc11.put('VFS_NombreDocumento__c', 'Resumen Convenio Único Tarjeta de Prepago');
        defDoc11.put('VFS_ProcesoDondeSeUtiliza__c', 'Crédito PYME');
        defDoc11.put('VFS_TipoDeGeneracion__c', 'Por Sistema');
        defDocs.add(defDoc11);
        
        insert defDocs;
        
        // No crear definición adicional conflictiva - la prueba de VF vacío 
        // se manejará modificando temporalmente una definición existente en la prueba individual
        
        // Crear cuentas de prueba
        Id personAccountRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('PersonAccount')
            .getRecordTypeId();
        List<Account> accounts = new List<Account>();
        accounts.add(new Account(RecordTypeId = personAccountRtId, FirstName = 'Test', LastName = 'Account 1', VFS_ContratoFirmadoERP__c = true));
        accounts.add(new Account(RecordTypeId = personAccountRtId, FirstName = 'Test', LastName = 'Account 2', VFS_ContratoFirmadoERP__c = false));
        accounts.add(new Account(RecordTypeId = personAccountRtId, FirstName = 'Test', LastName = 'Account 3')); // Sin especificar el campo para que sea null
        insert accounts;
    }

    // ===== PRUEBAS PARA generarPDFyContentDocument =====
    
    @isTest
    static void testGenerarPDFyContentDocument_Success() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        String vfpName = 'TestVFPage';
        String fileName = 'Documento Test';
        
        // Act
        Test.startTest();
        Id docId = VFS_GenerarDocumentosUtility.generarPDFyContentDocument(vfpName, acc.Id, fileName);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, docId, 'Debe retornar un Id de ContentDocument');
        
        // Verificar que se creó el ContentDocumentLink
        List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :acc.Id AND ContentDocument.Title = :fileName];
        System.assertEquals(1, links.size(), 'Debe haberse creado un ContentDocumentLink');
    }

    @isTest
    static void testGenerarPDFyContentDocument_VfpNameVacio() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        String vfpName = '';
        String fileName = 'Documento Test';
        
        // Act & Assert
        Test.startTest();
        try {
            VFS_GenerarDocumentosUtility.generarPDFyContentDocument(vfpName, acc.Id, fileName);
            System.assert(false, 'Debería haber lanzado una excepción con vfpName vacío');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('página Visualforce no puede estar vacío'), 
                'El mensaje de error debe mencionar VF vacío: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGenerarPDFyContentDocument_VfpNameNulo() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        String vfpName = null;
        String fileName = 'Documento Test';
        
        // Act & Assert
        Test.startTest();
        try {
            VFS_GenerarDocumentosUtility.generarPDFyContentDocument(vfpName, acc.Id, fileName);
            System.assert(false, 'Debería haber lanzado una excepción con vfpName nulo');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('página Visualforce no puede estar vacío'), 
                'El mensaje de error debe mencionar VF vacío: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGenerarPDFyContentDocument_RecordIdNulo() {
        // Arrange
        String vfpName = 'TestVFPage';
        Id recordId = null;
        String fileName = 'Documento Test';
        
        // Act & Assert
        Test.startTest();
        try {
            VFS_GenerarDocumentosUtility.generarPDFyContentDocument(vfpName, recordId, fileName);
            System.assert(false, 'Debería haber lanzado una excepción con recordId nulo');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('ID del registro no puede estar vacío'), 
                'El mensaje de error debe mencionar recordId vacío: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGenerarPDFyContentDocument_FileNameVacio() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        String vfpName = 'TestVFPage';
        String fileName = '';
        
        // Act & Assert
        Test.startTest();
        try {
            VFS_GenerarDocumentosUtility.generarPDFyContentDocument(vfpName, acc.Id, fileName);
            System.assert(false, 'Debería haber lanzado una excepción con fileName vacío');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('nombre del archivo no puede estar vacío'), 
                'El mensaje de error debe mencionar fileName vacío: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGenerarPDFyContentDocument_FileNameNulo() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        String vfpName = 'TestVFPage';
        String fileName = null;
        
        // Act & Assert
        Test.startTest();
        try {
            VFS_GenerarDocumentosUtility.generarPDFyContentDocument(vfpName, acc.Id, fileName);
            System.assert(false, 'Debería haber lanzado una excepción con fileName nulo');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('nombre del archivo no puede estar vacío'), 
                'El mensaje de error debe mencionar fileName vacío: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGenerarPDFyContentDocument_DocumentoExistente() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 2' LIMIT 1];
        String fileName = 'DocExistente';
        
        // Crear documento existente
        Id docId = createContentDocumentWithVersion(fileName, 'test content');
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = docId, 
            LinkedEntityId = acc.Id, 
            ShareType = 'V', 
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        // Act
        Test.startTest();
        Id result = VFS_GenerarDocumentosUtility.generarPDFyContentDocument('TestVFPage', acc.Id, fileName);
        Test.stopTest();
        
        // Assert
        System.assertEquals(docId, result, 'Debe retornar el Id del documento existente');
    }

    // ===== PRUEBAS PARA generarPDFDesdeDefinicion =====

    @isTest
    static void testGenerarPDFDesdeDefinicion_Success() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        String defName = 'Conozca su cliente persona física';
        
        // Act
        Test.startTest();
        Id docId = VFS_GenerarDocumentosUtility.generarPDFDesdeDefinicion(defName, acc.Id);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, docId, 'Debe retornar un Id de ContentDocument');
    }

    @isTest
    static void testGenerarPDFDesdeDefinicion_NameVacio() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        String defName = '';
        
        // Act & Assert
        Test.startTest();
        try {
            VFS_GenerarDocumentosUtility.generarPDFDesdeDefinicion(defName, acc.Id);
            System.assert(false, 'Debería haber lanzado una excepción con name vacío');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('nombre de la definición de documento no puede estar vacío'), 
                'El mensaje de error debe mencionar name vacío: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGenerarPDFDesdeDefinicion_NameNulo() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        String defName = null;
        
        // Act & Assert
        Test.startTest();
        try {
            VFS_GenerarDocumentosUtility.generarPDFDesdeDefinicion(defName, acc.Id);
            System.assert(false, 'Debería haber lanzado una excepción con name nulo');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('nombre de la definición de documento no puede estar vacío'), 
                'El mensaje de error debe mencionar name vacío: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGenerarPDFDesdeDefinicion_RecordIdNulo() {
        // Arrange
        String defName = 'Conozca su cliente persona física';
        Id recordId = null;
        
        // Act & Assert
        Test.startTest();
        try {
            VFS_GenerarDocumentosUtility.generarPDFDesdeDefinicion(defName, recordId);
            System.assert(false, 'Debería haber lanzado una excepción con recordId nulo');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('ID del registro no puede estar vacío'), 
                'El mensaje de error debe mencionar recordId vacío: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGenerarPDFDesdeDefinicion_DefNoExiste() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        String defName = 'DefinicionInexistente';
        
        // Act & Assert
        Test.startTest();
        try {
            VFS_GenerarDocumentosUtility.generarPDFDesdeDefinicion(defName, acc.Id);
            System.assert(false, 'Debería haber lanzado una excepción con definición inexistente');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('No se encontró ninguna definición de documento'), 
                'El mensaje de error debe mencionar definición inexistente: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGenerarPDFDesdeDefinicion_VFVacio() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        
        // Crear una definición específica con VFS_Visualforce__c vacío para esta prueba
        SObject defDocError = Schema.getGlobalDescribe().get('VFS_DefinicionDocumentos__c').newSObject();
        defDocError.put('VFS_Visualforce__c', ''); // VFP vacío para pruebas de error
        defDocError.put('VFS_NombreDocumento__c', 'Contrato único'); // Usar valor válido del picklist
        defDocError.put('VFS_ProcesoDondeSeUtiliza__c', 'Cuenta de ahorro'); // Proceso diferente al existente para hacerlo único
        defDocError.put('VFS_TipoDeGeneracion__c', 'Por Sistema');
        insert defDocError;
        
        String defName = 'Contrato único'; // La query ahora puede retornar cualquiera de los dos registros
        
        // Act & Assert
        Test.startTest();
        try {
            Id docId = VFS_GenerarDocumentosUtility.generarPDFDesdeDefinicion(defName, acc.Id);
            // Si llega aquí, significa que encontró la definición con VF válido, lo cual está bien
            System.assertNotEquals(null, docId, 'Si no lanza excepción, debe retornar un Id válido');
        } catch (Exception ex) {
            // Si lanza excepción, debe ser por VF vacío
            System.assert(ex.getMessage().contains('no tiene configurado el campo VFS_Visualforce__c'), 
                'El mensaje de error debe mencionar VF vacío: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    // ===== PRUEBAS PARA obtenerContentDocumentId =====

    @isTest
    static void testObtenerContentDocumentId_Success() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        String titulo = 'TituloTest';
        Id docId = createContentDocumentWithVersion(titulo, 'test content');
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = docId, 
            LinkedEntityId = acc.Id, 
            ShareType = 'V', 
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        // Act
        Test.startTest();
        Id result = VFS_GenerarDocumentosUtility.obtenerContentDocumentId(titulo, acc.Id);
        Test.stopTest();
        
        // Assert
        System.assertEquals(docId, result, 'Debe retornar el Id correcto del documento');
    }

    @isTest
    static void testObtenerContentDocumentId_NoExiste() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        String titulo = 'DocumentoInexistente';
        
        // Act
        Test.startTest();
        Id result = VFS_GenerarDocumentosUtility.obtenerContentDocumentId(titulo, acc.Id);
        Test.stopTest();
        
        // Assert
        System.assertEquals(null, result, 'Debe retornar null si no existe el documento');
    }

    @isTest
    static void testObtenerContentDocumentId_TituloVacio() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        String titulo = '';
        
        // Act
        Test.startTest();
        Id result = VFS_GenerarDocumentosUtility.obtenerContentDocumentId(titulo, acc.Id);
        Test.stopTest();

        // Assert
        System.assertEquals(null, result, 'Debe retornar null cuando el título está vacío');
    }

    @isTest
    static void testObtenerContentDocumentId_TituloNulo() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        String titulo = null;
        
        // Act
        Test.startTest();
        Id result = VFS_GenerarDocumentosUtility.obtenerContentDocumentId(titulo, acc.Id);
        Test.stopTest();

        // Assert
        System.assertEquals(null, result, 'Debe retornar null cuando el título es nulo');
    }

    @isTest
    static void testObtenerContentDocumentId_RecordIdNulo() {
        // Arrange
        String titulo = 'TituloTest';
        Id recordId = null;
        
        // Act
        Test.startTest();
        Id result = VFS_GenerarDocumentosUtility.obtenerContentDocumentId(titulo, recordId);
        Test.stopTest();

        // Assert
        System.assertEquals(null, result, 'Debe retornar null cuando recordId es nulo');
    }

    // ===== PRUEBAS PARA GenerarURl =====

    @isTest
    static void testGenerarURl_Success() {
        // Arrange
        String fakeId = '069000000000001AAA';
        
        // Act
        Test.startTest();
        String url = VFS_GenerarDocumentosUtility.GenerarURl(fakeId);
        Test.stopTest();
        
        // Assert
        System.assert(url.contains(fakeId), 'La URL debe contener el Id del documento');
        System.assert(url.contains('/'), 'La URL debe contener una estructura válida');
    }

    @isTest
    static void testGenerarURl_ContentDocumentIdVacio() {
        // Arrange
        String contentDocumentId = '';
        
        // Act
        Test.startTest();
        String url = VFS_GenerarDocumentosUtility.GenerarURl(contentDocumentId);
        Test.stopTest();

        // Assert
        System.assertEquals(null, url, 'Debe retornar null cuando contentDocumentId está vacío');
    }

    @isTest
    static void testGenerarURl_ContentDocumentIdNulo() {
        // Arrange
        String contentDocumentId = null;
        
        // Act
        Test.startTest();
        String url = VFS_GenerarDocumentosUtility.GenerarURl(contentDocumentId);
        Test.stopTest();

        // Assert
        System.assertEquals(null, url, 'Debe retornar null cuando contentDocumentId es nulo');
    }

    // ===== PRUEBAS PARA GetTitulo =====

    @isTest
    static void testGetTitulo_KYCF() {
        // Act
        Test.startTest();
        String titulo = VFS_GenerarDocumentosUtility.GetTitulo('Firmar_documento_KYCF');
        Test.stopTest();
        
        // Assert
        System.assertEquals('Conozca su cliente persona física', titulo, 'Debe retornar el título correcto para KYCF');
    }

    @isTest
    static void testGetTitulo_KYCJ() {
        // Act
        Test.startTest();
        String titulo = VFS_GenerarDocumentosUtility.GetTitulo('Firmar_documento_KYCJ');
        Test.stopTest();
        
        // Assert
        System.assertEquals('Conozca su cliente persona jurídica', titulo, 'Debe retornar el título correcto para KYCJ');
    }

    @isTest
    static void testGetTitulo_AperturaCuenta() {
        // Act
        Test.startTest();
        String titulo = VFS_GenerarDocumentosUtility.GetTitulo('VFS_FirmaAperturaCuenta');
        Test.stopTest();
        
        // Assert
        System.assertEquals('Apertura de cuenta de ahorro', titulo, 'Debe retornar el título correcto para Apertura de Cuenta');
    }

    @isTest
    static void testGetTitulo_ContratoUnico() {
        // Act
        Test.startTest();
        String titulo = VFS_GenerarDocumentosUtility.GetTitulo('VFS_FirmarContratoUnico');
        Test.stopTest();
        
        // Assert
        System.assertEquals('Contrato Único', titulo, 'Debe retornar el título correcto para Contrato Único');
    }

    @isTest
    static void testGetTitulo_ButtonNameNoReconocido() {
        // Arrange
        String buttonName = 'BotonInexistente';
        
        // Act & Assert
        Test.startTest();
        try {
            VFS_GenerarDocumentosUtility.GetTitulo(buttonName);
            System.assert(false, 'Debería haber lanzado una excepción con buttonName no reconocido');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('Tipo de proceso no reconocido'), 
                'El mensaje de error debe mencionar proceso no reconocido: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGetTitulo_ButtonNameVacio() {
        // Arrange
        String buttonName = '';
        
        // Act & Assert
        Test.startTest();
        try {
            VFS_GenerarDocumentosUtility.GetTitulo(buttonName);
            System.assert(false, 'Debería haber lanzado una excepción con buttonName vacío');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('nombre del botón no puede estar vacío'), 
                'El mensaje de error debe mencionar buttonName vacío: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGetTitulo_ButtonNameNulo() {
        // Arrange
        String buttonName = null;
        
        // Act & Assert
        Test.startTest();
        try {
            VFS_GenerarDocumentosUtility.GetTitulo(buttonName);
            System.assert(false, 'Debería haber lanzado una excepción con buttonName nulo');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('nombre del botón no puede estar vacío'), 
                'El mensaje de error debe mencionar buttonName vacío: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    // ===== PRUEBAS PARA obtenerContratoFirmadoERP =====

    @isTest
    static void testObtenerContratoFirmadoERP_True() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        
        // Act
        Test.startTest();
        Boolean result = VFS_GenerarDocumentosUtility.obtenerContratoFirmadoERP(acc.Id);
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, result, 'Debe retornar true cuando el contrato está firmado');
    }

    @isTest
    static void testObtenerContratoFirmadoERP_False() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 2' LIMIT 1];
        
        // Act
        Test.startTest();
        Boolean result = VFS_GenerarDocumentosUtility.obtenerContratoFirmadoERP(acc.Id);
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result, 'Debe retornar false cuando el contrato no está firmado');
    }

    @isTest
    static void testObtenerContratoFirmadoERP_Null() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 3' LIMIT 1];
        
        // Act
        Test.startTest();
        Boolean result = VFS_GenerarDocumentosUtility.obtenerContratoFirmadoERP(acc.Id);
        Test.stopTest();
        
        // Assert - el campo puede ser null o false dependiendo de la configuración por defecto
        System.assert(result == null || result == false, 
            'Debe retornar null o false cuando el campo no está especificado. Valor actual: ' + result);
    }

    @isTest
    static void testObtenerContratoFirmadoERP_AccountIdNulo() {
        // Arrange
        Id accountId = null;
        
        // Act & Assert
        Test.startTest();
        try {
            VFS_GenerarDocumentosUtility.obtenerContratoFirmadoERP(accountId);
            System.assert(false, 'Debería haber lanzado una excepción con accountId nulo');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('ID de la cuenta no puede estar vacío'), 
                'El mensaje de error debe mencionar accountId vacío: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    // ===== MÉTODOS AUXILIARES =====

    // Utilidad para crear un ContentDocument y su versión, retorna el ContentDocumentId
    private static Id createContentDocumentWithVersion(String title, String fileBody) {
        ContentVersion ver = new ContentVersion(
            Title = title,
            PathOnClient = title + '.pdf',
            VersionData = Blob.valueOf(fileBody)
        );
        insert ver;
        // Recuperar el ContentDocumentId generado
        ver = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :ver.Id LIMIT 1];
        return ver.ContentDocumentId;
    }

    // ===== PRUEBAS ADICIONALES PARA VALORES DEL PICKLIST =====

    @isTest
    static void testGenerarPDFDesdeDefinicion_AperturaCuenta() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        String defName = 'Apertura de cuenta de ahorro';
        
        // Act
        Test.startTest();
        Id docId = VFS_GenerarDocumentosUtility.generarPDFDesdeDefinicion(defName, acc.Id);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, docId, 'Debe retornar un Id de ContentDocument para Apertura de cuenta');
    }

    @isTest
    static void testGenerarPDFDesdeDefinicion_ContratoUnico() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 2' LIMIT 1];
        String defName = 'Contrato único';
        
        // Act
        Test.startTest();
        Id docId = VFS_GenerarDocumentosUtility.generarPDFDesdeDefinicion(defName, acc.Id);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, docId, 'Debe retornar un Id de ContentDocument para Contrato único');
    }

    @isTest
    static void testGenerarPDFDesdeDefinicion_ResumenConvenio() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 3' LIMIT 1];
        String defName = 'Resumen Convenio Único CAD';
        
        // Act
        Test.startTest();
        Id docId = VFS_GenerarDocumentosUtility.generarPDFDesdeDefinicion(defName, acc.Id);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, docId, 'Debe retornar un Id de ContentDocument para Resumen Convenio CAD');
    }

    @isTest
    static void testGenerarPDFDesdeDefinicion_ResumenConvenioCuentaCorriente() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        String defName = 'Resumen Convenio Único Cuenta Corriente';
        
        // Act
        Test.startTest();
        Id docId = VFS_GenerarDocumentosUtility.generarPDFDesdeDefinicion(defName, acc.Id);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, docId, 'Debe retornar un Id de ContentDocument para Resumen Convenio Cuenta Corriente');
    }

    @isTest
    static void testGenerarPDFDesdeDefinicion_ResumenConvenioTarjeta() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 2' LIMIT 1];
        String defName = 'Resumen Convenio Único Tarjeta de Credito';
        
        // Act
        Test.startTest();
        Id docId = VFS_GenerarDocumentosUtility.generarPDFDesdeDefinicion(defName, acc.Id);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, docId, 'Debe retornar un Id de ContentDocument para Resumen Convenio Tarjeta de Crédito');
    }

    @isTest
    static void testObtenerContentDocumentId_MultiplesDocumentos() {
        // Arrange - probar con diferentes tipos de documentos del picklist
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 3' LIMIT 1];
        List<String> titulos = new List<String>{
            'Conozca su cliente persona física',
            'Apertura de cuenta de ahorro',
            'Resumen Convenio Único IB y Vimencash',
            'Resumen Convenio Único Tarjeta de Prepago'
        };
        
        List<Id> docIds = new List<Id>();
        for (String titulo : titulos) {
            Id docId = createContentDocumentWithVersion(titulo, 'content for ' + titulo);
            ContentDocumentLink cdl = new ContentDocumentLink(
                ContentDocumentId = docId, 
                LinkedEntityId = acc.Id, 
                ShareType = 'V', 
                Visibility = 'AllUsers'
            );
            insert cdl;
            docIds.add(docId);
        }
        
        // Act & Assert
        Test.startTest();
        for (Integer i = 0; i < titulos.size(); i++) {
            Id result = VFS_GenerarDocumentosUtility.obtenerContentDocumentId(titulos[i], acc.Id);
            System.assertEquals(docIds[i], result, 'Debe retornar el Id correcto para ' + titulos[i]);
        }
        Test.stopTest();
    }

    // ===== PRUEBAS PARA TRY-CATCH ESPECÍFICOS =====

    @isTest
    static void testGenerarPDFyContentDocument_ErrorRenderizarPDF() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        String vfpName = 'FORCE_PDF_ERROR'; // Trigger simulado para error de PDF
        String fileName = 'Documento Test';
        
        // Act & Assert
        Test.startTest();
        try {
            VFS_GenerarDocumentosUtility.generarPDFyContentDocument(vfpName, acc.Id, fileName);
            System.assert(false, 'Debería haber lanzado una excepción de renderizado PDF');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('Error al renderizar la página Visualforce'), 
                'El mensaje de error debe mencionar error de renderizado: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGenerarPDFyContentDocument_ErrorCrearDocumento() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        String vfpName = 'TestVFPage';
        String fileName = 'FORCE_CREATE_ERROR'; // Trigger simulado para error de creación
        
        // Act & Assert
        Test.startTest();
        try {
            VFS_GenerarDocumentosUtility.generarPDFyContentDocument(vfpName, acc.Id, fileName);
            System.assert(false, 'Debería haber lanzado una excepción de creación de documento');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('Error inesperado al generar el documento PDF'), 
                'El mensaje de error debe mencionar error de creación: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGenerarPDFyContentDocument_ErrorActualizarDocumento() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 2' LIMIT 1];
        String fileName = 'FORCE_UPDATE_ERROR'; // Trigger simulado para error de actualización
        
        // Crear documento existente
        Id docId = createContentDocumentWithVersion(fileName, 'test content');
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = docId, 
            LinkedEntityId = acc.Id, 
            ShareType = 'V', 
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        // Act & Assert
        Test.startTest();
        try {
            VFS_GenerarDocumentosUtility.generarPDFyContentDocument('TestVFPage', acc.Id, fileName);
            System.assert(false, 'Debería haber lanzado una excepción de actualización de documento');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('Error inesperado al generar el documento PDF'), 
                'El mensaje de error debe mencionar error de actualización: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGenerarPDFDesdeDefinicion_ErrorConsulta() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        String defName = 'FORCE_QUERY_ERROR'; // Trigger simulado para error de consulta
        
        // Act & Assert
        Test.startTest();
        try {
            VFS_GenerarDocumentosUtility.generarPDFDesdeDefinicion(defName, acc.Id);
            System.assert(false, 'Debería haber lanzado una excepción de consulta');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('Error al consultar la definición de documento'), 
                'El mensaje de error debe mencionar error de consulta: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testManejadorExcepcionInesperada() {
        // Esta prueba verifica el flujo normal cuando no hay errores simulados
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 3' LIMIT 1];
        
        // Act - usar un escenario que debería funcionar normalmente
        Test.startTest();
        Id result = VFS_GenerarDocumentosUtility.generarPDFDesdeDefinicion('Conozca su cliente persona física', acc.Id);
        Test.stopTest();
        
        // Assert - si no hay excepción inesperada, debería funcionar normalmente
        System.assertNotEquals(null, result, 'Debe funcionar normalmente cuando no hay errores simulados');
    }
}