/*********************************************************************************************
 * Nombre de clase Test   :   VFS_KYCEnvelopeTest
 * Versión                :   1.0
 * Fecha de actualización :   15/07/2025
 * Función                :   Pruebas unitarias para la clase VFS_KYCEnvelope
 * Clase probada          :   VFS_KYCEnvelope
 *
 * Registro de modificaciones:
 * ---------------------------------------------------------------------------------------------------
 * Desarrollador                        Fecha           Descripción
 * Edgar H. Luna                        15/07/2025      Versión inicial
 *********************************************************************************************/

@isTest
private class VFS_KYCEnvelopeTest {
    private static Account createJuridicAccount(String name) {
        Account acc = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Candidato_Persona_Juridica')
                .getRecordTypeId(),
            Name = name,
            ACC_RNC__c = 'KYC' + String.valueOf(System.now().getTime()).right(6),
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO',
            ACC_TipoIdentificacion__c = 'RNC'
        );
        insert acc;
        return acc;
    }


    @isTest
    static void testCreateSignsFisica_ConViasContacto() {
        // Arrange: crear Account de persona física con vías de contacto válidas
        Id rtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Candidato Persona Física').getRecordTypeId();
        Account acc = new Account();
        acc.FirstName = 'Juan';
        acc.LastName = 'Pérez';
        acc.RecordTypeId = rtId;
        insert acc;
        
        // Crear vía de contacto con correo principal
        Vias_de_Contacto__c via = new Vias_de_Contacto__c();
        via.VIA_Account__c = acc.Id;
        via.VIA_de_Contacto__c = 'CORREO ELECTRÓNICO';
        via.VIA_Numero_Correo__c = 'juan.perez@example.com';
        via.VIA_Principal__c = true;
        insert via;
        
        // Act
        Test.startTest();
        List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = VFS_KYCEnvelope.CreateSigns(acc.Id);
        Test.stopTest();
        
        // Assert: Debe devolver 6 acciones (3 firmas + 3 copias)
        System.assertNotEquals(null, actions, 'La lista de acciones no debe ser nula');
        System.assertEquals(6, actions.size(), 'Debe devolver exactamente 6 acciones para persona física');
        
        // Verificar que hay firmas y copias
        Integer firmasCount = 0;
        Integer copiasCount = 0;
        Boolean foundClienteEmail = false;
        
        for (VFS_EsignSendingEnvelope.EnvelopeAction action : actions) {
            if (action.Sign != null) {
                firmasCount++;
                if (action.Sign.RecipientConfiguration.ContactInformation.Email == 'juan.perez@example.com') {
                    foundClienteEmail = true;
                }
            }
            if (action.SendCopy != null) {
                copiasCount++;
            }
        }
        
        System.assertEquals(3, firmasCount, 'Debe haber exactamente 3 firmas');
        System.assertEquals(3, copiasCount, 'Debe haber exactamente 3 copias');
        System.assert(foundClienteEmail, 'Debe incluir el email del cliente');
    }

    @isTest
    static void testCreateSignsFisica_SinViasContacto() {
        // Arrange: crear Account sin vías de contacto
        Id rtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Candidato Persona Física').getRecordTypeId();
        Account acc = new Account();
        acc.FirstName = 'Sin';
        acc.LastName = 'Contacto';
        acc.RecordTypeId = rtId;
        insert acc;
        
        // Act & Assert: debe lanzar excepción
        Test.startTest();
        try {
            VFS_KYCEnvelope.CreateSigns(acc.Id);
            System.assert(false, 'Debería haber lanzado una excepción por falta de vías de contacto');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('vías de contacto configuradas'), 
                'El mensaje de error debe mencionar vías de contacto: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateSignsFisica_SinCorreoElectronico() {
        // Arrange: crear Account sin vías de contacto de correo electrónico
        Id rtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Candidato Persona Física').getRecordTypeId();
        Account acc = new Account();
        acc.FirstName = 'Sin';
        acc.LastName = 'Email';
        acc.RecordTypeId = rtId;
        insert acc;
        
        // No crear ninguna vía de contacto para simular falta de correo electrónico
        
        // Act & Assert: debe lanzar excepción
        Test.startTest();
        try {
            VFS_KYCEnvelope.CreateSigns(acc.Id);
            System.assert(false, 'Debería haber lanzado una excepción por falta de correo electrónico');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('vías de contacto configuradas') || ex.getMessage().contains('correo electrónico'), 
                'El mensaje de error debe mencionar vías de contacto o correo electrónico: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateSignsFisica_CorreoSecundario() {
        // Arrange: crear Account con correo secundario (no principal)
        Id rtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Candidato Persona Física').getRecordTypeId();
        Account acc = new Account();
        acc.FirstName = 'Correo';
        acc.LastName = 'Secundario';
        acc.RecordTypeId = rtId;
        insert acc;
        
        // Crear vía de contacto con correo secundario
        Vias_de_Contacto__c via = new Vias_de_Contacto__c();
        via.VIA_Account__c = acc.Id;
        via.VIA_de_Contacto__c = 'CORREO ELECTRÓNICO';
        via.VIA_Numero_Correo__c = 'secundario@example.com';
        via.VIA_Principal__c = false; // No es principal
        insert via;
        
        // Act
        Test.startTest();
        List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = VFS_KYCEnvelope.CreateSigns(acc.Id);
        Test.stopTest();
        
        // Assert: debe funcionar con correo secundario
        System.assertNotEquals(null, actions, 'La lista de acciones no debe ser nula');
        System.assertEquals(6, actions.size(), 'Debe devolver 6 acciones');
        
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
    static void testCreateSignsJuridica_ConAccionistas() {
        // Arrange: crear Account de persona jurídica con accionistas
        Account acc = createJuridicAccount('Empresa KYC Test');
        
        // Crear Account para accionista
        Id rtPersona = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Candidato Persona Física').getRecordTypeId();
        Account accionista1 = new Account();
        accionista1.FirstName = 'Accionista';
        accionista1.LastName = 'Uno';
        accionista1.RecordTypeId = rtPersona;
        insert accionista1;
        
        // Crear vía de contacto para accionista
        Vias_de_Contacto__c viaAccionista = new Vias_de_Contacto__c();
        viaAccionista.VIA_Account__c = accionista1.Id;
        viaAccionista.VIA_de_Contacto__c = 'CORREO ELECTRÓNICO';
        viaAccionista.VIA_Numero_Correo__c = 'accionista1@example.com';
        viaAccionista.VIA_Principal__c = true;
        insert viaAccionista;
        
        // Crear participante
        Participante__c participante = new Participante__c();
        participante.PAR_Cliente__c = acc.Id;
        participante.Participante__c = accionista1.Id;
        participante.VFS_FirmanteConozcaCliente__c = true;
        participante.PAR_Porcentaje__c = 50.0;
        insert participante;
        
        // Act
        Test.startTest();
        List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = VFS_KYCEnvelope.CreateSigns(acc.Id);
        Test.stopTest();
        
        // Assert: debe incluir accionista + ejecutivo + verificador + copias
        System.assertNotEquals(null, actions, 'La lista de acciones no debe ser nula');
        System.assert(actions.size() >= 5, 'Debe devolver al menos 5 acciones para persona jurídica');
        
        Boolean foundAccionista = false;
        Boolean foundEjecutivo = false;
        Boolean foundVerificador = false;
        Integer firmasCount = 0;
        Integer copiasCount = 0;
        
        for (VFS_EsignSendingEnvelope.EnvelopeAction action : actions) {
            if (action.Sign != null) {
                firmasCount++;
                String email = action.Sign.RecipientConfiguration.ContactInformation.Email;
                if (email == 'accionista1@example.com') {
                    foundAccionista = true;
                } else if (email == UserInfo.getUserEmail()) {
                    // Simplemente marcamos que encontramos firmas del usuario actual
                    foundEjecutivo = true;
                    foundVerificador = true;
                }
            }
            if (action.SendCopy != null) {
                copiasCount++;
            }
        }
        
        System.assert(foundAccionista, 'Debe incluir firma del accionista');
        System.assert(foundEjecutivo, 'Debe incluir firma del ejecutivo');
        System.assert(foundVerificador, 'Debe incluir firma del verificador');
        System.assert(firmasCount >= 3, 'Debe haber al menos 3 firmas');
        System.assert(copiasCount >= 3, 'Debe haber al menos 3 copias');
    }

    @isTest
    static void testCreateSignsJuridica_MultipleAccionistas() {
        // Arrange: crear Account jurídica con múltiples accionistas
        Account acc = createJuridicAccount('Empresa Multiple KYC');
        
        Id rtPersona = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Candidato Persona Física').getRecordTypeId();
        
        // Crear múltiples accionistas
        List<Account> accionistas = new List<Account>();
        List<Vias_de_Contacto__c> vias = new List<Vias_de_Contacto__c>();
        List<Participante__c> participantes = new List<Participante__c>();
        
        for (Integer i = 0; i < 2; i++) {
            Account accionista = new Account();
            accionista.FirstName = 'Accionista';
            accionista.LastName = 'Numero' + i;
            accionista.RecordTypeId = rtPersona;
            accionistas.add(accionista);
        }
        insert accionistas;
        
        for (Integer i = 0; i < accionistas.size(); i++) {
            Vias_de_Contacto__c via = new Vias_de_Contacto__c();
            via.VIA_Account__c = accionistas[i].Id;
            via.VIA_de_Contacto__c = 'CORREO ELECTRÓNICO';
            via.VIA_Numero_Correo__c = 'accionista' + i + '@example.com';
            via.VIA_Principal__c = true;
            vias.add(via);
            
            Participante__c participante = new Participante__c();
            participante.PAR_Cliente__c = acc.Id;
            participante.Participante__c = accionistas[i].Id;
            participante.VFS_FirmanteConozcaCliente__c = true;
            participante.PAR_Porcentaje__c = 50.0 - (i * 10);
            participantes.add(participante);
        }
        insert vias;
        insert participantes;
        
        // Act
        Test.startTest();
        List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = VFS_KYCEnvelope.CreateSigns(acc.Id);
        Test.stopTest();
        
        // Assert: debe incluir múltiples accionistas
        System.assertNotEquals(null, actions, 'La lista de acciones no debe ser nula');
        System.assert(actions.size() >= 6, 'Debe devolver al menos 6 acciones');
        
        Set<String> emailsAccionistas = new Set<String>();
        for (VFS_EsignSendingEnvelope.EnvelopeAction action : actions) {
            if (action.Sign != null) {
                String email = action.Sign.RecipientConfiguration.ContactInformation.Email;
                if (email.contains('accionista') && email.contains('@example.com')) {
                    emailsAccionistas.add(email);
                }
            }
        }
        
        System.assertEquals(2, emailsAccionistas.size(), 'Debe incluir los 2 accionistas');
        System.assert(emailsAccionistas.contains('accionista0@example.com'), 'Debe incluir accionista0');
        System.assert(emailsAccionistas.contains('accionista1@example.com'), 'Debe incluir accionista1');
    }

    @isTest
    static void testCreateSignsJuridica_SinAccionistas() {
        // Arrange: crear Account jurídica sin accionistas autorizados
        Account acc = createJuridicAccount('Empresa Sin Accionistas');
        
        // Act & Assert: debe lanzar excepción
        Test.startTest();
        try {
            VFS_KYCEnvelope.CreateSigns(acc.Id);
            System.assert(false, 'Debería haber lanzado una excepción por falta de accionistas');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('firmantes autorizados'), 
                'El mensaje de error debe mencionar firmantes autorizados: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateSignsJuridica_AccionistaSinCorreo() {
        // Arrange: crear Account jurídica con accionista sin correo
        Account acc = createJuridicAccount('Empresa Accionista Sin Correo');
        
        // Crear accionista sin vías de contacto
        Id rtPersona = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Candidato Persona Física').getRecordTypeId();
        Account accionista = new Account();
        accionista.FirstName = 'Sin';
        accionista.LastName = 'Correo';
        accionista.RecordTypeId = rtPersona;
        insert accionista;
        
        // Crear participante
        Participante__c participante = new Participante__c();
        participante.PAR_Cliente__c = acc.Id;
        participante.Participante__c = accionista.Id;
        participante.VFS_FirmanteConozcaCliente__c = true;
        participante.PAR_Porcentaje__c = 50.0;
        insert participante;
        
        // Act & Assert: debe lanzar excepción
        Test.startTest();
        try {
            VFS_KYCEnvelope.CreateSigns(acc.Id);
            System.assert(false, 'Debería haber lanzado una excepción por falta de correo del accionista');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('correo electrónico válida'), 
                'El mensaje de error debe mencionar correo electrónico: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateSigns_IdVacio() {
        // Act & Assert: debe lanzar excepción con ID vacío
        Test.startTest();
        try {
            VFS_KYCEnvelope.CreateSigns('');
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
            VFS_KYCEnvelope.CreateSigns(null);
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
            VFS_KYCEnvelope.CreateSigns(fakeId);
            System.assert(false, 'Debería haber lanzado una excepción con Account inexistente');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('No se pudo encontrar el registro'), 
                'El mensaje de error debe mencionar registro no encontrado: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateSignsFisica_CorreoElectronicoVacio() {
        // Arrange: crear Account con correo electrónico vacío
        Id rtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Candidato Persona Física').getRecordTypeId();
        Account acc = new Account();
        acc.FirstName = 'Correo';
        acc.LastName = 'Vacio';
        acc.RecordTypeId = rtId;
        insert acc;
        
        // Crear vía de contacto con correo vacío
        Vias_de_Contacto__c via = new Vias_de_Contacto__c();
        via.VIA_Account__c = acc.Id;
        via.VIA_de_Contacto__c = 'CORREO ELECTRÓNICO';
        via.VIA_Numero_Correo__c = ''; // Correo vacío
        via.VIA_Principal__c = true;
        insert via;
        
        // Act & Assert: debe lanzar excepción
        Test.startTest();
        try {
            VFS_KYCEnvelope.CreateSigns(acc.Id);
            System.assert(false, 'Debería haber lanzado una excepción por correo vacío');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('correo electrónico válida'), 
                'El mensaje de error debe mencionar correo electrónico: ' + ex.getMessage());
        }
        Test.stopTest();
    }
}
