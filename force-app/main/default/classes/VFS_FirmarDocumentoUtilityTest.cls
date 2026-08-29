/*********************************************************************************************
 * Nombre de clase Apex   :   VFS_FirmarDocumentoUtilityTest
 * Versión                :   2.0
 * Fecha de creación      :   20/06/2025
 * Función                :   Pruebas unitarias para VFS_FirmarDocumentoUtility
 * Clase probada          :   VFS_FirmarDocumentoUtility
 *
 * Registro de modificaciones:
 * ---------------------------------------------------------------------------------------------------
 * Desarrollador                        Fecha           Descripción
 * Edgar H. Luna                        20/06/2025      Versión inicial
 *********************************************************************************************/
@isTest
private class VFS_FirmarDocumentoUtilityTest {

    private static void assertExpectedError(Exception ex, List<String> expectedFragments, String assertMessage) {
        String message = ex.getMessage();
        Boolean matchesExpectedMessage = false;

        for (String expectedFragment : expectedFragments) {
            matchesExpectedMessage = matchesExpectedMessage || message.contains(expectedFragment);
        }

        System.assert(
            matchesExpectedMessage || message == 'Script-thrown exception',
            assertMessage + ': ' + message
        );
    }

    @isTest
    static void testSendEnvelope_KYCF_Success() {
        // Arrange
        String fileId = '069000000000001AAA';
        String buttonName = 'Firmar_documento_KYCF';
        String recordId = '001000000000001AAA';
        
        // Act
        Test.startTest();
        VFS_EsignSendingEnvelope.EnvelopeResult result = VFS_FirmarDocumentoUtility.sendEnvelope(fileId, buttonName, recordId);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'El resultado no debe ser null');
        System.assert(result.success, 'El resultado debe ser exitoso en modo test');
        System.assertEquals('Test', result.message, 'El mensaje debe ser Test en modo test');
    }

    @isTest
    static void testSendEnvelope_KYCJ_Success() {
        // Arrange
        String fileId = '069000000000002BBB';
        String buttonName = 'Firmar_documento_KYCJ';
        String recordId = '001000000000002BBB';
        
        // Act
        Test.startTest();
        VFS_EsignSendingEnvelope.EnvelopeResult result = VFS_FirmarDocumentoUtility.sendEnvelope(fileId, buttonName, recordId);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'El resultado no debe ser null');
        System.assert(result.success, 'El resultado debe ser exitoso en modo test');
        System.assertEquals('Test', result.message, 'El mensaje debe ser Test en modo test');
    }

    @isTest
    static void testSendEnvelope_AperturaCuenta_Success() {
        // Arrange
        String fileId = '069000000000003CCC';
        String buttonName = 'VFS_FirmaAperturaCuenta';
        String recordId = '001000000000003CCC';
        
        // Act
        Test.startTest();
        VFS_EsignSendingEnvelope.EnvelopeResult result = VFS_FirmarDocumentoUtility.sendEnvelope(fileId, buttonName, recordId);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'El resultado no debe ser null');
        System.assert(result.success, 'El resultado debe ser exitoso en modo test');
        System.assertEquals('Test', result.message, 'El mensaje debe ser Test en modo test');
    }

    @isTest
    static void testSendEnvelope_ContratoUnico_Success() {
        // Arrange
        String fileId = '069000000000004DDD';
        String buttonName = 'VFS_FirmarContratoUnico';
        String recordId = '001000000000004DDD';
        
        // Act
        Test.startTest();
        VFS_EsignSendingEnvelope.EnvelopeResult result = VFS_FirmarDocumentoUtility.sendEnvelope(fileId, buttonName, recordId);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'El resultado no debe ser null');
        System.assert(result.success, 'El resultado debe ser exitoso en modo test');
        System.assertEquals('Test', result.message, 'El mensaje debe ser Test en modo test');
    }

    @isTest
    static void testSendEnvelope_ResumenConvenio_Success() {
        // Arrange
        String fileId = '069000000000005EEE';
        String buttonName = 'Resumen Convenio Único Cuenta de Ahorro';
        String recordId = '001000000000005EEE';
        
        // Act
        Test.startTest();
        VFS_EsignSendingEnvelope.EnvelopeResult result = VFS_FirmarDocumentoUtility.sendEnvelope(fileId, buttonName, recordId);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'El resultado no debe ser null');
        System.assert(result.success, 'El resultado debe ser exitoso en modo test');
        System.assertEquals('Test', result.message, 'El mensaje debe ser Test en modo test');
    }

    @isTest
    static void testSendEnvelope_FileIdVacio() {
        // Arrange
        String fileId = '';
        String buttonName = 'Firmar_documento_KYCF';
        String recordId = '001000000000001AAA';
        
        // Act & Assert
        Test.startTest();
        try {
            VFS_FirmarDocumentoUtility.sendEnvelope(fileId, buttonName, recordId);
            System.assert(false, 'Debería haber lanzado una excepción con fileId vacío');
        } catch (Exception ex) {
            assertExpectedError(ex, new List<String>{ 'ID del archivo no puede estar vacío' }, 'El mensaje de error debe mencionar fileId vacío');
        }
        Test.stopTest();
    }

    @isTest
    static void testSendEnvelope_FileIdNulo() {
        // Arrange
        String fileId = null;
        String buttonName = 'Firmar_documento_KYCF';
        String recordId = '001000000000001AAA';
        
        // Act & Assert
        Test.startTest();
        try {
            VFS_FirmarDocumentoUtility.sendEnvelope(fileId, buttonName, recordId);
            System.assert(false, 'Debería haber lanzado una excepción con fileId nulo');
        } catch (Exception ex) {
            assertExpectedError(ex, new List<String>{ 'ID del archivo no puede estar vacío' }, 'El mensaje de error debe mencionar fileId vacío');
        }
        Test.stopTest();
    }

    @isTest
    static void testSendEnvelope_ButtonNameVacio() {
        // Arrange
        String fileId = '069000000000001AAA';
        String buttonName = '';
        String recordId = '001000000000001AAA';
        
        // Act & Assert
        Test.startTest();
        try {
            VFS_FirmarDocumentoUtility.sendEnvelope(fileId, buttonName, recordId);
            System.assert(false, 'Debería haber lanzado una excepción con buttonName vacío');
        } catch (Exception ex) {
            assertExpectedError(ex, new List<String>{ 'nombre del botón', 'no puede estar vacío' }, 'El mensaje de error debe mencionar buttonName vacío');
        }
        Test.stopTest();
    }

    @isTest
    static void testSendEnvelope_ButtonNameNulo() {
        // Arrange
        String fileId = '069000000000001AAA';
        String buttonName = null;
        String recordId = '001000000000001AAA';
        
        // Act & Assert
        Test.startTest();
        try {
            VFS_FirmarDocumentoUtility.sendEnvelope(fileId, buttonName, recordId);
            System.assert(false, 'Debería haber lanzado una excepción con buttonName nulo');
        } catch (Exception ex) {
            assertExpectedError(ex, new List<String>{ 'nombre del botón', 'no puede estar vacío' }, 'El mensaje de error debe mencionar buttonName vacío');
        }
        Test.stopTest();
    }

    @isTest
    static void testSendEnvelope_RecordIdVacio() {
        // Arrange
        String fileId = '069000000000001AAA';
        String buttonName = 'Firmar_documento_KYCF';
        String recordId = '';
        
        // Act & Assert
        Test.startTest();
        try {
            VFS_FirmarDocumentoUtility.sendEnvelope(fileId, buttonName, recordId);
            System.assert(false, 'Debería haber lanzado una excepción con recordId vacío');
        } catch (Exception ex) {
            assertExpectedError(ex, new List<String>{ 'ID del registro no puede estar vacío' }, 'El mensaje de error debe mencionar recordId vacío');
        }
        Test.stopTest();
    }

    @isTest
    static void testSendEnvelope_RecordIdNulo() {
        // Arrange
        String fileId = '069000000000001AAA';
        String buttonName = 'Firmar_documento_KYCF';
        String recordId = null;
        
        // Act & Assert
        Test.startTest();
        try {
            VFS_FirmarDocumentoUtility.sendEnvelope(fileId, buttonName, recordId);
            System.assert(false, 'Debería haber lanzado una excepción con recordId nulo');
        } catch (Exception ex) {
            assertExpectedError(ex, new List<String>{ 'ID del registro no puede estar vacío' }, 'El mensaje de error debe mencionar recordId vacío');
        }
        Test.stopTest();
    }

    @isTest
    static void testSendEnvelope_ButtonNameNoReconocido() {
        // Arrange
        String fileId = '069000000000002BBB';
        String buttonName = 'Boton_Desconocido_Invalido';
        String recordId = '001000000000002BBB';
        
        // Act & Assert
        Test.startTest();
        try {
            VFS_FirmarDocumentoUtility.sendEnvelope(fileId, buttonName, recordId);
            System.assert(false, 'Debería haber lanzado una excepción con buttonName no reconocido');
        } catch (Exception ex) {
            assertExpectedError(ex, new List<String>{ 'Tipo de proceso no reconocido' }, 'El mensaje de error debe mencionar proceso no reconocido');
        }
        Test.stopTest();
    }

    @isTest
    static void testSendEnvelope_MultipleResumenConvenio() {
        // Arrange: probar diferentes variantes de Resumen Convenio
        String fileId = '069000000000006FFF';
        String recordId = '001000000000006FFF';
        List<String> buttonNames = new List<String>{
            'Resumen Convenio Único Cuenta Corriente',
            'Resumen Convenio Único Tarjeta de Credito',
            'Resumen Convenio Único CAD'
        };
        
        Test.startTest();
        for (String buttonName : buttonNames) {
            // Act
            VFS_EsignSendingEnvelope.EnvelopeResult result = VFS_FirmarDocumentoUtility.sendEnvelope(fileId, buttonName, recordId);
            
            // Assert
            System.assertNotEquals(null, result, 'El resultado no debe ser null para: ' + buttonName);
            System.assert(result.success, 'El resultado debe ser exitoso para: ' + buttonName);
            System.assertEquals('Test', result.message, 'El mensaje debe ser Test para: ' + buttonName);
        }
        Test.stopTest();
    }

    @isTest
    static void testBuildSignAction_Success() {
        // Arrange
        String email = 'test@example.com';
        String givenName = 'Test';
        String surname = 'User';
        String signingGroup = 'Grupo1';
        
        List<VFS_FirmarDocumentoUtility.SignatureParams> signatures = new List<VFS_FirmarDocumentoUtility.SignatureParams>();
        VFS_FirmarDocumentoUtility.SignatureParams param = new VFS_FirmarDocumentoUtility.SignatureParams();
        param.ElementId = 'sig1';
        param.DocumentNumber = 1;
        param.PageNumber = 1;
        param.X = 100;
        param.Y = 200;
        param.Width = 150;
        param.Height = 50;
        param.DisplayName = 'Firma aquí';
        signatures.add(param);
        
        // Act
        Test.startTest();
        VFS_EsignSendingEnvelope.EnvelopeAction action = VFS_FirmarDocumentoUtility.buildSignAction(email, givenName, surname, signingGroup, signatures);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, action, 'La acción no debe ser null');
        System.assertNotEquals(null, action.Sign, 'Debe contener un objeto Sign');
        System.assertEquals(null, action.SendCopy, 'No debe contener SendCopy para acción de firma');
        System.assertEquals(signingGroup, action.Sign.SigningGroup, 'El grupo de firma debe coincidir');
        System.assertEquals(email, action.Sign.RecipientConfiguration.ContactInformation.Email, 'El email debe coincidir');
        System.assertEquals(givenName, action.Sign.RecipientConfiguration.ContactInformation.GivenName, 'El nombre debe coincidir');
        System.assertEquals(surname, action.Sign.RecipientConfiguration.ContactInformation.Surname, 'El apellido debe coincidir');
        
        // Verificar detalles de la firma
        System.assertEquals(1, action.Sign.Elements.Signatures.size(), 'Debe haber exactamente 1 firma');
        VFS_EsignSendingEnvelope.EnvelopeSignature sig = action.Sign.Elements.Signatures[0];
        System.assertEquals('sig1', sig.ElementId, 'El ElementId debe coincidir');
        System.assertEquals(true, sig.Required, 'La firma debe ser requerida');
        System.assertEquals(1, sig.DocumentNumber, 'El número de documento debe coincidir');
        System.assertEquals('Firma aquí', sig.DisplayName, 'El display name debe ser "Firma aquí"');
        
        // Verificar posición y tamaño
        System.assertEquals(1, sig.FieldDefinition.Position.PageNumber, 'El número de página debe coincidir');
        System.assertEquals(100, sig.FieldDefinition.Position.X, 'La coordenada X debe coincidir');
        System.assertEquals(200, sig.FieldDefinition.Position.Y, 'La coordenada Y debe coincidir');
        System.assertEquals(150, sig.FieldDefinition.Size.Width, 'El ancho debe coincidir');
        System.assertEquals(50, sig.FieldDefinition.Size.Height, 'La altura debe coincidir');
        
        // Verificar tipos de firma permitidos
        System.assertNotEquals(null, sig.AllowedSignatureTypes, 'Debe tener tipos de firma permitidos');
        System.assertNotEquals(null, sig.AllowedSignatureTypes.ClickToSign, 'Debe permitir ClickToSign');
    }

    @isTest
    static void testBuildSignAction_EmptySignatures() {
        // Arrange
        String email = 'empty@example.com';
        String givenName = 'Empty';
        String surname = 'Signatures';
        String signingGroup = 'GrupoVacio';
        List<VFS_FirmarDocumentoUtility.SignatureParams> signatures = new List<VFS_FirmarDocumentoUtility.SignatureParams>();
        
        // Act
        Test.startTest();
        VFS_EsignSendingEnvelope.EnvelopeAction action = VFS_FirmarDocumentoUtility.buildSignAction(email, givenName, surname, signingGroup, signatures);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, action, 'La acción no debe ser null');
        System.assertNotEquals(null, action.Sign, 'Debe contener un objeto Sign');
        System.assertEquals(0, action.Sign.Elements.Signatures.size(), 'No debe haber firmas');
        System.assertEquals(email, action.Sign.RecipientConfiguration.ContactInformation.Email, 'El email debe coincidir');
    }

    @isTest
    static void testBuildSignAction_MultipleSignatures() {
        // Arrange
        String email = 'multiple@example.com';
        String givenName = 'Multiple';
        String surname = 'Signatures';
        String signingGroup = 'GrupoMultiple';
        
        List<VFS_FirmarDocumentoUtility.SignatureParams> signatures = new List<VFS_FirmarDocumentoUtility.SignatureParams>();
        
        // Crear múltiples firmas
        for (Integer i = 1; i <= 3; i++) {
            VFS_FirmarDocumentoUtility.SignatureParams param = new VFS_FirmarDocumentoUtility.SignatureParams();
            param.ElementId = 'sig' + i;
            param.DocumentNumber = 1;
            param.PageNumber = i;
            param.X = 100 * i;
            param.Y = 200 * i;
            param.Width = 150;
            param.Height = 50;
            signatures.add(param);
        }
        
        // Act
        Test.startTest();
        VFS_EsignSendingEnvelope.EnvelopeAction action = VFS_FirmarDocumentoUtility.buildSignAction(email, givenName, surname, signingGroup, signatures);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, action, 'La acción no debe ser null');
        System.assertNotEquals(null, action.Sign, 'Debe contener un objeto Sign');
        System.assertEquals(3, action.Sign.Elements.Signatures.size(), 'Debe haber exactamente 3 firmas');
        
        // Verificar cada firma
        for (Integer i = 0; i < 3; i++) {
            VFS_EsignSendingEnvelope.EnvelopeSignature sig = action.Sign.Elements.Signatures[i];
            System.assertEquals('sig' + (i + 1), sig.ElementId, 'El ElementId debe coincidir para firma ' + (i + 1));
            System.assertEquals((i + 1), sig.FieldDefinition.Position.PageNumber, 'El número de página debe coincidir para firma ' + (i + 1));
            System.assertEquals(100 * (i + 1), sig.FieldDefinition.Position.X, 'La coordenada X debe coincidir para firma ' + (i + 1));
            System.assertEquals(200 * (i + 1), sig.FieldDefinition.Position.Y, 'La coordenada Y debe coincidir para firma ' + (i + 1));
        }
    }

    @isTest
    static void testBuildSignAction_NullValues() {
        // Arrange
        VFS_FirmarDocumentoUtility.SignatureParams param = new VFS_FirmarDocumentoUtility.SignatureParams();
        // No se asignan valores (quedan null)
        List<VFS_FirmarDocumentoUtility.SignatureParams> signatures = new List<VFS_FirmarDocumentoUtility.SignatureParams>{param};
        
        // Act
        Test.startTest();
        VFS_EsignSendingEnvelope.EnvelopeAction action = VFS_FirmarDocumentoUtility.buildSignAction(null, null, null, null, signatures);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, action, 'La acción no debe ser null');
        System.assertNotEquals(null, action.Sign, 'Debe contener un objeto Sign');
        System.assertEquals(null, action.Sign.RecipientConfiguration.ContactInformation.Email, 'El email debe ser null');
        System.assertEquals(null, action.Sign.RecipientConfiguration.ContactInformation.GivenName, 'El nombre debe ser null');
        System.assertEquals(null, action.Sign.RecipientConfiguration.ContactInformation.Surname, 'El apellido debe ser null');
        System.assertEquals(null, action.Sign.SigningGroup, 'El grupo de firma debe ser null');
        System.assertEquals('Firma aquí', action.Sign.Elements.Signatures[0].DisplayName, 'El display name debe ser "Firma aquí"');
    }

    @isTest
    static void testCleanButtonName_ConPrefijo() {
        // Arrange
        String buttonNameConPrefijo = 'VFS_FirmaAperturaCuenta';
        
        // Act
        Test.startTest();
        String result = VFS_FirmarDocumentoUtility.cleanButtonName(buttonNameConPrefijo);
        Test.stopTest();
        
        // Assert
        System.assertEquals('FirmaAperturaCuenta', result, 'Debe remover el prefijo VFS_');
    }

    @isTest
    static void testCleanButtonName_SinPrefijo() {
        // Arrange
        String buttonNameSinPrefijo = 'Firmar_documento_KYCF';
        
        // Act
        Test.startTest();
        String result = VFS_FirmarDocumentoUtility.cleanButtonName(buttonNameSinPrefijo);
        Test.stopTest();
        
        // Assert
        System.assertEquals('Firmar_documento_KYCF', result, 'Debe devolver el mismo nombre si no tiene prefijo VFS_');
    }

    @isTest
    static void testCleanButtonName_Null() {
        // Arrange
        String buttonNameNull = null;
        
        // Act
        Test.startTest();
        String result = VFS_FirmarDocumentoUtility.cleanButtonName(buttonNameNull);
        Test.stopTest();
        
        // Assert
        System.assertEquals(null, result, 'Debe devolver null si el input es null');
    }

    @isTest
    static void testCleanButtonName_Vacio() {
        // Arrange
        String buttonNameVacio = '';
        
        // Act
        Test.startTest();
        String result = VFS_FirmarDocumentoUtility.cleanButtonName(buttonNameVacio);
        Test.stopTest();
        
        // Assert
        System.assertEquals('', result, 'Debe devolver cadena vacía si el input está vacío');
    }

    @isTest
    static void testCleanButtonName_SoloPrefijo() {
        // Arrange
        String buttonNameSoloPrefijo = 'VFS_';
        
        // Act
        Test.startTest();
        String result = VFS_FirmarDocumentoUtility.cleanButtonName(buttonNameSoloPrefijo);
        Test.stopTest();
        
        // Assert
        System.assertEquals('', result, 'Debe devolver cadena vacía si solo contiene el prefijo VFS_');
    }

    @isTest
    static void testSignatureParams_PropiedadesCompletas() {
        // Arrange & Act
        Test.startTest();
        VFS_FirmarDocumentoUtility.SignatureParams param = new VFS_FirmarDocumentoUtility.SignatureParams();
        param.ElementId = 'test_element';
        param.DocumentNumber = 2;
        param.PageNumber = 3;
        param.X = 400;
        param.Y = 500;
        param.Width = 200;
        param.Height = 80;
        param.DisplayName = 'Firma de Prueba';
        Test.stopTest();
        
        // Assert
        System.assertEquals('test_element', param.ElementId, 'ElementId debe coincidir');
        System.assertEquals(2, param.DocumentNumber, 'DocumentNumber debe coincidir');
        System.assertEquals(3, param.PageNumber, 'PageNumber debe coincidir');
        System.assertEquals(400, param.X, 'X debe coincidir');
        System.assertEquals(500, param.Y, 'Y debe coincidir');
        System.assertEquals(200, param.Width, 'Width debe coincidir');
        System.assertEquals(80, param.Height, 'Height debe coincidir');
        System.assertEquals('Firma de Prueba', param.DisplayName, 'DisplayName debe coincidir');
    }
}
