/*********************************************************************************************
 * Nombre de clase Test   :   VFS_ContratoUnicoEnvelopeTest
 * Versión                :   1.0
 * Fecha de actualización :   21/07/2025
 * Función                :   Pruebas unitarias para la clase VFS_ContratoUnicoEnvelope
 * Clase probada          :   VFS_ContratoUnicoEnvelope
 *
 * Registro de modificaciones:
 * ---------------------------------------------------------------------------------------------------
 * Desarrollador                        Fecha           Descripción
 * Edgar H. Luna                        21/07/2025      Versión inicial
 *********************************************************************************************/
@isTest
private class VFS_ContratoUnicoEnvelopeTest {
    private static Integer accountSequence = 0;

    private static Account createPersonAccount(String firstName, String lastName, String email) {
        Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());
        Account acc = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId(),
            FirstName = firstName,
            LastName = lastName,
            ACC_TipoIdentificacion__c = 'Cédula',
            ACC_NumIdentificacion__c = nextTestIdentification()
        );
        insert acc;

        if (String.isNotBlank(email)) {
            insert new ContactPointEmail(ParentId = acc.Id, EmailAddress = email, IsPrimary = true);
        }

        return acc;
    }

    private static Account createBusinessAccount(String name) {
        Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());
        Account acc = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesBusiness').getRecordTypeId(),
            Name = name,
            ACC_RNC__c = nextTestRnc()
        );
        insert acc;
        insert new Contact(FirstName = 'Contacto', LastName = name.left(20), AccountId = acc.Id, Email = 'contacto' + accountSequence + '@example.com');
        return acc;
    }

    private static String nextTestIdentification() {
        accountSequence++;
        return '00108803' + String.valueOf(accountSequence).leftPad(3, '0');
    }

    private static String nextTestRnc() {
        accountSequence++;
        return '101010' + String.valueOf(accountSequence).leftPad(3, '0');
    }

    @isTest
    static void testCreateSigns_PersonaFisica_ConViasContacto() {
        // Arrange: crear Account de prueba como persona física con vías de contacto válidas
        Account acc = createPersonAccount('Juan', 'Perez', 'juan.perez@example.com');
        
        // Crear vía de contacto principal para email
        Vias_de_Contacto__c via = new Vias_de_Contacto__c();
        via.VIA_Account__c = acc.Id;
        via.VIA_de_Contacto__c = 'CORREO ELECTRÓNICO';
        via.VIA_Numero_Correo__c = 'juan.perez@example.com';
        via.VIA_Principal__c = true;
        insert via;
        
        // Act
        Test.startTest();
        List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = VFS_ContratoUnicoEnvelope.CreateSigns(acc.Id);
        Test.stopTest();
        
        // Assert: Debe devolver 3 acciones (1 firma + 2 copias: firmante + owner)
        System.assertNotEquals(null, actions, 'La lista de acciones no debe ser nula');
        System.assertEquals(3, actions.size(), 'Debe devolver 3 acciones (firma + 2 copias)');
        
        // Verificar que hay firmas y copias
        Integer firmasCount = 0;
        Integer copiasCount = 0;
        Boolean foundClienteEmail = false;
        Boolean foundOwnerCopy = false;
        
        for (VFS_EsignSendingEnvelope.EnvelopeAction action : actions) {
            if (action.Sign != null) {
                firmasCount++;
                if (action.Sign.RecipientConfiguration.ContactInformation.Email == 'juan.perez@example.com') {
                    foundClienteEmail = true;
                }
            }
            if (action.SendCopy != null) {
                copiasCount++;
                String email = action.SendCopy.RecipientConfiguration.ContactInformation.Email;
                if (email == UserInfo.getUserEmail()) {
                    foundOwnerCopy = true;
                }
            }
        }
        
        System.assertEquals(1, firmasCount, 'Debe haber exactamente 1 firma');
        System.assertEquals(2, copiasCount, 'Debe haber exactamente 2 copias');
        System.assert(foundClienteEmail, 'Debe incluir el email del cliente para firma');
        System.assert(foundOwnerCopy, 'Debe incluir copia para el owner');
    }

    @isTest
    static void testCreateSigns_PersonaFisica_SinViasContacto() {
        // Arrange: crear Account sin vías de contacto
        Account acc = createPersonAccount('Sin', 'Contacto', null);
        
        // Act & Assert: debe lanzar excepción
        Test.startTest();
        try {
            VFS_ContratoUnicoEnvelope.CreateSigns(acc.Id);
            System.assert(false, 'Debería haber lanzado una excepción por falta de vías de contacto');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('vías de contacto configuradas') || ex.getMessage().contains('correo electrónico'), 
                'El mensaje de error debe mencionar vías de contacto: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateSigns_PersonaFisica_SinCorreoElectronico() {
        // Arrange: crear Account sin vías de contacto de correo electrónico
        Account acc = createPersonAccount('Sin', 'Email', null);
        
        // No crear ninguna vía de contacto para simular falta de correo electrónico
        
        // Act & Assert: debe lanzar excepción
        Test.startTest();
        try {
            VFS_ContratoUnicoEnvelope.CreateSigns(acc.Id);
            System.assert(false, 'Debería haber lanzado una excepción por falta de correo electrónico');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('vías de contacto configuradas') || ex.getMessage().contains('correo electrónico'), 
                'El mensaje de error debe mencionar vías de contacto o correo electrónico: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateSigns_PersonaFisica_CorreoSecundario() {
        // Arrange: crear Account con correo secundario (no principal)
        Account acc = createPersonAccount('Correo', 'Secundario', 'secundario@example.com');
        
        // Crear vía de contacto con correo secundario
        Vias_de_Contacto__c via = new Vias_de_Contacto__c();
        via.VIA_Account__c = acc.Id;
        via.VIA_de_Contacto__c = 'CORREO ELECTRÓNICO';
        via.VIA_Numero_Correo__c = 'secundario@example.com';
        via.VIA_Principal__c = false; // No es principal
        insert via;
        
        // Act
        Test.startTest();
        List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = VFS_ContratoUnicoEnvelope.CreateSigns(acc.Id);
        Test.stopTest();
        
        // Assert: debe funcionar con correo secundario
        System.assertNotEquals(null, actions, 'La lista de acciones no debe ser nula');
        System.assertEquals(3, actions.size(), 'Debe devolver 3 acciones');
        
        Boolean foundSecondaryEmail = false;
        for (VFS_EsignSendingEnvelope.EnvelopeAction action : actions) {
            if (action.Sign != null && action.Sign.RecipientConfiguration.ContactInformation.Email == 'secundario@example.com') {
                foundSecondaryEmail = true;
                break;
            }
        }
        System.assert(foundSecondaryEmail, 'Debe usar el correo secundario cuando no hay principal');
    }

    @isTest
    static void testCreateSigns_PersonaJuridica_ConParticipante() {
        // Arrange: crear Account de persona jurídica con participante autorizado
        Account acc = createBusinessAccount('Empresa Contrato Test');

        // Crear Account para participante
        Account participante = createPersonAccount('Firmante', 'Autorizado', 'firmante@example.com');
        
        // Crear vía de contacto para participante
        Vias_de_Contacto__c viaParticipante = new Vias_de_Contacto__c();
        viaParticipante.VIA_Account__c = participante.Id;
        viaParticipante.VIA_de_Contacto__c = 'CORREO ELECTRÓNICO';
        viaParticipante.VIA_Numero_Correo__c = 'firmante@example.com';
        viaParticipante.VIA_Principal__c = true;
        insert viaParticipante;
        
        // Crear participante autorizado
        Participante__c part = new Participante__c();
        part.PAR_Cliente__c = acc.Id;
        part.Participante__c = participante.Id;
        part.VFS_FirmanteDeContratoAutorizado__c = true;
        part.PAR_Porcentaje__c = 50.0;
        insert part;
        
        // Act
        Test.startTest();
        List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = VFS_ContratoUnicoEnvelope.CreateSigns(acc.Id);
        Test.stopTest();
        
        // Assert: debe incluir participante + copias
        System.assertNotEquals(null, actions, 'La lista de acciones no debe ser nula');
        System.assertEquals(3, actions.size(), 'Debe devolver 3 acciones (firma + 2 copias)');
        
        Boolean foundParticipante = false;
        Integer firmasCount = 0;
        Integer copiasCount = 0;
        
        for (VFS_EsignSendingEnvelope.EnvelopeAction action : actions) {
            if (action.Sign != null) {
                firmasCount++;
                String email = action.Sign.RecipientConfiguration.ContactInformation.Email;
                if (email == 'firmante@example.com') {
                    foundParticipante = true;
                }
            }
            if (action.SendCopy != null) {
                copiasCount++;
            }
        }
        
        System.assert(foundParticipante, 'Debe incluir firma del participante autorizado');
        System.assertEquals(1, firmasCount, 'Debe haber exactamente 1 firma');
        System.assertEquals(2, copiasCount, 'Debe haber exactamente 2 copias');
    }

    @isTest
    static void testCreateSigns_PersonaJuridica_SinParticipantes() {
        // Arrange: crear Account jurídica sin participantes autorizados
        Account acc = createBusinessAccount('Empresa Sin Participantes');
        
        // Act & Assert: debe lanzar excepción
        Test.startTest();
        try {
            VFS_ContratoUnicoEnvelope.CreateSigns(acc.Id);
            System.assert(false, 'Debería haber lanzado una excepción por falta de participantes');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('participantes autorizados'), 
                'El mensaje de error debe mencionar participantes autorizados: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateSigns_PersonaJuridica_ParticipanteSinCorreo() {
        // Arrange: crear Account jurídica con participante sin correo
        Account acc = createBusinessAccount('Empresa Participante Sin Correo');

        // Crear participante sin vías de contacto
        Account participante = createPersonAccount('Sin', 'Correo', null);
        
        // Crear participante autorizado
        Participante__c part = new Participante__c();
        part.PAR_Cliente__c = acc.Id;
        part.Participante__c = participante.Id;
        part.VFS_FirmanteDeContratoAutorizado__c = true;
        part.PAR_Porcentaje__c = 50.0;
        insert part;
        
        // Act & Assert: debe lanzar excepción
        Test.startTest();
        try {
            VFS_ContratoUnicoEnvelope.CreateSigns(acc.Id);
            System.assert(false, 'Debería haber lanzado una excepción por falta de correo del participante');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('vías de contacto configuradas') || ex.getMessage().contains('correo electrónico'), 
                'El mensaje de error debe mencionar vías de contacto o correo electrónico: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateSigns_IdVacio() {
        // Act & Assert: debe lanzar excepción con ID vacío
        Test.startTest();
        try {
            VFS_ContratoUnicoEnvelope.CreateSigns('');
            System.assert(false, 'Debería haber lanzado una excepción con ID vacío');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('Id del registro no puede estar vacío'), 
                'El mensaje de error debe mencionar ID vacío: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateSigns_IdNulo() {
        // Act & Assert: debe lanzar excepción con ID nulo
        Test.startTest();
        try {
            VFS_ContratoUnicoEnvelope.CreateSigns(null);
            System.assert(false, 'Debería haber lanzado una excepción con ID nulo');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('Id del registro no puede estar vacío'), 
                'El mensaje de error debe mencionar ID vacío: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateSigns_AccountInexistente() {
        // Act & Assert: debe lanzar excepción con ID de Account inexistente
        String fakeId = '001000000000000'; // ID fake válido formato pero inexistente
        
        Test.startTest();
        try {
            VFS_ContratoUnicoEnvelope.CreateSigns(fakeId);
            System.assert(false, 'Debería haber lanzado una excepción con Account inexistente');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('No se pudo encontrar el registro') || ex.getMessage().contains('No se pudo acceder'), 
                'El mensaje de error debe mencionar registro no encontrado o acceso: ' + ex.getMessage());
        }
        Test.stopTest();
    }
}
