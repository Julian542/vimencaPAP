/* Esta clase es un controlador de Visualforce para generar/mostrar el documento “KYC” con datos del cliente en el modelo FSC.
 * 
 * @author: Jhonny Peroza
 * @last updated: 27-01-26
 */
public with sharing class VFS_nKYCFisica_Controller {

    // Id del registro Account que abre la página VF (viene desde std.getId()).
    public Id accountId { get; set; }

    // Cuenta principal (cliente) sobre la que se construye el KYC.
    public Account cuenta { get; set; }

    // "Contacto relacionado" (cuando el cliente es jurídico y existe un ACR tipo 'Relacionado').
    // Se modela como Person Account (Account con PersonContactId) para poder colgar Contact Points.
    public Account contactorel { get; set; }

    // Referencia "cualquiera" (primer registro encontrado); las listas son las que realmente se usan en VF.
    public FinServ__ContactContactRelation__c referencia { get; set; }

    public String dirResidenciaFATCATxt { get; set; }
    public String telefonoUSATxt { get; set; }

    // Referencias del cliente (por tipo).
    public List<FinServ__ContactContactRelation__c> lstReferenciasBancarias { get; set; }
    public List<FinServ__ContactContactRelation__c> lstReferenciasComerciales { get; set; }
    public List<FinServ__ContactContactRelation__c> lstReferenciasPersonales { get; set; }

    // Listas de secciones KYC (objetos custom).
    public List<FinServ__AccountAccountRelation__c> lstEmpresasFiliales { get; set; }
    public List<Productos_y_Servicios__c> lstPrincipalesProductosServicios { get; set; }
    public List<FinServ__AccountAccountRelation__c> lstPrincipalesClientes { get; set; }
    public List<FinServ__AccountAccountRelation__c> lstPrincipalesProveedores { get; set; }

    // Participantes / roles en empresa (se llenan desde AccountContactRelation y se completan con placeholders).
    public List<Account> lstParticipantes { get; set; }
    public List<ContactPointEmail> lstViasRepresentantesEmail { get; set; }
    public List<ContactPointPhone> lstViasRepresentantesPhone { get; set; }

    public List<Account> lstAccionistas { get; set; }

    // lstMiembros ahora es AAR (AccountAccountRelation) para calzar con el componente VF
    public List<FinServ__AccountAccountRelation__c> lstMiembros { get; set; }

    public List<Account> lstFuncionarios { get; set; }
    public List<Account> lstSociosExtranjeros { get; set; }

    // Relación familiar (ej: cónyuge) consultada desde AccountContactRelation.
    public List<AccountContactRelation> familiares { get; set; }

    // Direcciones del cliente (ContactPointAddress) según tipo.
    public ContactPointAddress direccion { get; set; }
    public ContactPointAddress dirEmpresarial { get; set; }
    public ContactPointAddress dirResidencia { get; set; }
    public ContactPointAddress dirResidenciaFATCA { get; set; }

    // Historial laboral (Employment) del cliente (principal).
    public FinServ__Employment__c historial { get; set; }

    // Vías de contacto del cliente (tel/correo) cuando es persona física.
    public ContactPointPhone viaTelefonoResidencial { get; set; }
    public ContactPointPhone viaTelefonoMovil { get; set; }
    public ContactPointEmail viaCorreoElectronico { get; set; }

    // Vías de contacto de empresa (tel/fax/correo) cuando es jurídico.
    public ContactPointPhone viaTelefonoEmpresa { get; set; }
    public ContactPointPhone viaFaxEmpresa { get; set; }
    public ContactPointEmail viaCorreoEmpresa { get; set; }

    // Vías de contacto del "contacto relacionado" (jurídico).
    public ContactPointPhone viaTelefonoContacto { get; set; }
    public ContactPointEmail viaCorreoContacto { get; set; }

    // Cónyuge (relación ACR) + Account del cónyuge.
    public AccountContactRelation conyuge { get; set; }
    public Account accConyuge { get; set; }

    // Datos del cónyuge.
    public ContactPointAddress dirConyugeLaboral { get; set; }
    public FinServ__Employment__c historialConyuge { get; set; }

    // Bandera para diferenciar lógica de KYC (física vs jurídica).
    public Boolean isFisica { get; set; }

    // Wrappers para mostrar representante legal y autorizados en VF con sus vías (tel/correo).
    public List<VFS_KYCWrapperRepVias> lstRepVias { get; set; }
    public List<VFS_KYCWrapperRepVias> lstAutorizados { get; set; }

    // Primer participante marcado como PEP (según ACC_Persona_PEP__c).
    public Account ParticipantePEP { get; set; }

    // Se mantiene compatibilidad con el VF anterior: un registro "principal" (Informacion_Financiera__c)
    // y una lista de máximo 3 (lstInfosFinanciera) con placeholders para que la tabla siempre renderice.
    public Informacion_Financiera__c infoFinanciera { get; set; }
    public List<Informacion_Financiera__c> lstInfosFinanciera { get; set; }

    // Dirección empresarial formateada para componentes VF que esperan String.
    public String dirEmpresarialTxt { get; set; }

    public VFS_nKYCFisica_Controller(ApexPages.StandardController std) {

        // Inicialización de listas (para evitar null pointers en VF).
        lstReferenciasBancarias = new List<FinServ__ContactContactRelation__c>();
        lstReferenciasComerciales = new List<FinServ__ContactContactRelation__c>();
        lstReferenciasPersonales = new List<FinServ__ContactContactRelation__c>();
        lstEmpresasFiliales = new List<FinServ__AccountAccountRelation__c>();
        lstPrincipalesProductosServicios = new List<Productos_y_Servicios__c>();
        lstPrincipalesClientes = new List<FinServ__AccountAccountRelation__c>();
        lstPrincipalesProveedores = new List<FinServ__AccountAccountRelation__c>();
        familiares = new List<AccountContactRelation>();
        lstRepVias = new List<VFS_KYCWrapperRepVias>();
        lstAutorizados = new List<VFS_KYCWrapperRepVias>();

        lstParticipantes = new List<Account>();
        lstViasRepresentantesPhone = new List<ContactPointPhone>();
        lstViasRepresentantesEmail = new List<ContactPointEmail>();
        lstAccionistas = new List<Account>();

        // inicialización como AAR
        lstMiembros = new List<FinServ__AccountAccountRelation__c>();

        lstFuncionarios = new List<Account>();
        lstSociosExtranjeros = new List<Account>();
        isFisica = true;

        // Inicialización de strings
        dirResidenciaFATCATxt = '';
        telefonoUSATxt = '';

        // Inicialización de Contact Points (para evitar null pointers en VF).
        viaTelefonoResidencial = new ContactPointPhone();
        viaTelefonoMovil = new ContactPointPhone();
        viaCorreoElectronico = new ContactPointEmail();

        viaTelefonoEmpresa = new ContactPointPhone();
        viaFaxEmpresa = new ContactPointPhone();
        viaCorreoEmpresa = new ContactPointEmail();

        viaTelefonoContacto = new ContactPointPhone();
        viaCorreoContacto = new ContactPointEmail();

        // Inicialización de direcciones (para evitar null pointers en VF).
        dirResidencia = new ContactPointAddress();
        dirResidenciaFATCA = new ContactPointAddress();
        direccion = new ContactPointAddress();
        dirEmpresarial = new ContactPointAddress();
        dirConyugeLaboral = new ContactPointAddress();

        // Inicialización de employment (para evitar null pointers en VF).
        historial = new FinServ__Employment__c();
        historialConyuge = new FinServ__Employment__c();

        ParticipantePEP = new Account();

        infoFinanciera = new Informacion_Financiera__c();
        lstInfosFinanciera = new List<Informacion_Financiera__c>();

        // Id de Account tomado desde el StandardController (registro actual).
        accountId = std.getId();

        // Carga de datos base del cliente (Account).
        cuenta = [
            SELECT Id, IsPersonAccount, RecordType.DeveloperName, PersonContactId, MiddleName, Name,
                   ACC_NumOficina__c, ACC_CIF__c, OwnerId, Owner.Name,
                   VFS_ActividadEconomica__c, VFS_EspecifiqueOtro__c
            FROM Account
            WHERE Id = :accountId
        ];

        // Person Account = persona física; Business Account = persona jurídica.
        isFisica = cuenta.IsPersonAccount;

        // Inicializa el "contacto relacionado" (para jurídico).
        contactorel = new Account();

        // Busca un AccountContactRelation de tipo "Relacionado" (si existe), para traer el contacto principal asociado a la empresa.
        List<AccountContactRelation> relacionados = [
            SELECT Id, AccountId, ContactId, Contact.Name, Contact.FirstName, Contact.LastName, Parentesco__c, Contact.Suffix, Tipo_de_relacion__c, Roles
            FROM AccountContactRelation
            WHERE AccountId = :accountId
            AND Tipo_de_relacion__c = 'Relacionado'
            LIMIT 1
        ];
        System.debug('Relacionados: ' + relacionados);

        // Si existe, intenta resolver el Person Account que corresponde a ese ContactId (por PersonContactId).
        if (relacionados != null && !relacionados.isEmpty()) {
            List<Account> contactoAccount = [
                SELECT Id, FirstName, LastName, Suffix, PersonContactId
                FROM Account
                WHERE PersonContactId = :relacionados[0].ContactId
                LIMIT 1
            ];

            // Si existe Person Account, se usa para consultar Contact Points del contacto relacionado.
            if (!contactoAccount.isEmpty()) {
                contactorel = contactoAccount[0];
            } else {
                // Si no existe Person Account, se crea un "placeholder" con nombre para que VF no falle.
                contactorel = new Account();
                contactorel.FirstName = relacionados[0].Contact.FirstName;
                contactorel.LastName = relacionados[0].Contact.LastName;
            }
        } else {
            System.debug('No se encontraron contactos relacionados');
            contactorel = new Account();
        }

        // Contact principal del cliente (para Person Account).
        Id contactId = cuenta.PersonContactId;

        // Trae referencias desde FinServ__ContactContactRelation__c para el Contact principal.
        List<FinServ__ContactContactRelation__c> refList = [
            SELECT Id,
                   CCR_Tipo__c,
                   CCR_Tipo_de_cuenta__c,
                   CCR_Banco__c,
                   CCR_Moneda__c,
                   CCR_N_de_cuenta__c,
                   VFS_RNC__c,
                   CCR_Porcentaje__c,
                   CCR_Cargo__c,
                   CCR_Ejecutivo__c,
                   CCR_FirmanteConozcaCliente__c,
                   CCR_firmante_autorizado__c,
                   CCR_LimiteFirmantesKYC__c,
                   CCR_FirmanteDeContratoAutorizado__c,
                   CCR_LimiteFirmantesContratos__c,
                   CCR_RepresentanteLegal__c,
                   CCR_Codigo_Participante__c,
                   FinServ__RelatedContact__c,
                   FinServ__RelatedContact__r.Id,
                   FinServ__RelatedContact__r.Name,
                   FinServ__RelatedContact__r.FirstName,
                   FinServ__RelatedContact__r.LastName,
                   FinServ__RelatedContact__r.Phone,
                   FinServ__RelatedContact__r.MobilePhone,
                   FinServ__RelatedContact__r.Email,
                   FinServ__RelatedContact__r.MailingStreet,
                   FinServ__RelatedContact__r.MailingCity,
                   FinServ__RelatedContact__r.MailingState,
                   FinServ__RelatedContact__r.MailingCountry,
                   FinServ__RelatedContact__r.MailingPostalCode
            FROM FinServ__ContactContactRelation__c
            WHERE FinServ__Contact__c = :contactId
        ];

        // Setea "referencia" como primer registro (si existe) solo para no dejarlo null.
        if (!refList.isEmpty()) {
            referencia = refList[0];
        } else {
            referencia = new FinServ__ContactContactRelation__c();
        }
        System.debug(referencia);

        // Separa referencias por tipo (BANCARIA / PERSONAL / COMERCIAL).
        for (FinServ__ContactContactRelation__c ref : refList) {
            if (ref.CCR_Tipo__c == 'BANCARIA') {
                lstReferenciasBancarias.add(ref);
            } else if (ref.CCR_Tipo__c == 'PERSONAL') {
                lstReferenciasPersonales.add(ref);
            } else if (ref.CCR_Tipo__c == 'COMERCIAL') {
                lstReferenciasComerciales.add(ref);
            }
        }

        // Completa listas a tamaño fijo para que VF muestre siempre la grilla (placeholders).
        while (lstReferenciasBancarias.size() < 3) lstReferenciasBancarias.add(new FinServ__ContactContactRelation__c());
        while (lstReferenciasPersonales.size() < 3) lstReferenciasPersonales.add(new FinServ__ContactContactRelation__c());
        while (lstReferenciasComerciales.size() < 3) lstReferenciasComerciales.add(new FinServ__ContactContactRelation__c());

        // Direcciones de residencia del cliente (todas), para identificar residencia FATCA si es USA.
        List<ContactPointAddress> dirResidenciales = [
            SELECT Id, Address, Street, City, State, Country, PostalCode, AddressType, CreatedDate
            FROM ContactPointAddress
            WHERE ParentId = :accountId AND AddressType = 'RESIDENCIA'
            ORDER BY CreatedDate DESC
        ];

        // Selecciona la primera dirección de residencia que tenga país USA (variantes).
        for (ContactPointAddress dir : dirResidenciales) {
            Address a = (dir != null) ? (Address)dir.get('Address') : null;
            String c = (a != null) ? a.country : null;

            if (dir != null && (c == 'Estado Unidos' || c == 'United States' || c == 'US' || c == 'USA')) {
                dirResidenciaFATCA = dir;
                break;
            }
        }

        // Dirección de residencia "principal" usada en VF (primera por CreatedDate desc).
        if (!dirResidenciales.isEmpty()) {
            dirResidencia = dirResidenciales[0];
        } else {
            dirResidencia = new ContactPointAddress();
        }
        System.debug(dirResidencia);

        // Dirección laboral del cliente.
        List<ContactPointAddress> directions = [
            SELECT Id, Address, Street, City, State, Country, PostalCode, AddressType, CreatedDate
            FROM ContactPointAddress
            WHERE ParentId = :accountId AND AddressType = 'LABORAL'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (!directions.isEmpty()) {
            direccion = directions[0];
        } else {
            direccion = new ContactPointAddress();
        }
        System.debug(direccion);

        // Dirección empresarial del cliente.
        List<ContactPointAddress> directions2 = [
            SELECT Id, Address, Street, City, State, Country, PostalCode, AddressType, CreatedDate
            FROM ContactPointAddress
            WHERE ParentId = :accountId AND AddressType = 'EMPRESARIAL'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (!directions2.isEmpty()) {
            dirEmpresarial = directions2[0];
        } else {
            dirEmpresarial = new ContactPointAddress();
        }
        System.debug(dirEmpresarial);

        // se transforma ContactPointAddress -> String para pasarlo a componentes VF legacy.
        dirEmpresarialTxt = formatearDireccion(dirEmpresarial);

        // Historial laboral principal del cliente (Employment).
        List<FinServ__Employment__c> historiales = queryEmployment(contactId);
        if (!historiales.isEmpty()) {
            historial = historiales[0];
        } else {
            historial = new FinServ__Employment__c();
        }
        System.debug(historial);

        // Trae todos los teléfonos del cliente (priorizando primarios y tipos relevantes).
        List<ContactPointPhone> todosLosTelefonos = [
            SELECT Id, ParentId, TelephoneNumber, IsPrimary, CreatedDate, CPP_Tipo__c
            FROM ContactPointPhone
            WHERE ParentId = :accountId
            AND (IsPrimary = true OR CPP_Tipo__c IN ('TELÉFONO FIJO', 'TELÉFONO MÓVIL', 'TELÉFONO FAX', 'TELÉFONO TRABAJO', 'TELÉFONO EN EL EXTERIOR', 'MÓVIL EN EL EXTERIOR'))
            ORDER BY IsPrimary DESC, CreatedDate DESC
        ];

        // Trae todos los correos del cliente (priorizando primarios y no nulos).
        List<ContactPointEmail> todosLosCorreos = [
            SELECT Id, ParentId, EmailAddress, IsPrimary, CreatedDate
            FROM ContactPointEmail
            WHERE ParentId = :accountId
            AND (IsPrimary = true OR EmailAddress != null)
            ORDER BY IsPrimary DESC, CreatedDate DESC
        ];

        // Si el cliente es físico: toma fijo/móvil y el primer correo disponible.
        if (isFisica) {
            for (ContactPointPhone tel : todosLosTelefonos) {
                if (viaTelefonoResidencial.Id == null && tel.CPP_Tipo__c == 'TELÉFONO FIJO') {
                    viaTelefonoResidencial = tel;
                }
                if (viaTelefonoMovil.Id == null && tel.CPP_Tipo__c == 'TELÉFONO MÓVIL') {
                    viaTelefonoMovil = tel;
                }
            }

            for (ContactPointEmail em : todosLosCorreos) {
                if (viaCorreoElectronico.Id == null && String.isNotBlank(em.EmailAddress)) {
                    viaCorreoElectronico = em;
                }
            }
        }

        // Si el cliente es jurídico: toma teléfonos/correos de empresa y (si existe) del contacto relacionado.
        if (!isFisica) {
            System.debug('Telefonos Empresa: ' + todosLosTelefonos);
            System.debug('Correos Empresa: ' + todosLosCorreos);

            for (ContactPointPhone telEmp : todosLosTelefonos) {
                if (viaTelefonoEmpresa.Id == null && telEmp.CPP_Tipo__c == 'TELÉFONO FIJO') {
                    viaTelefonoEmpresa = telEmp;
                }
                if (viaFaxEmpresa.Id == null && telEmp.CPP_Tipo__c == 'TELÉFONO FAX') {
                    viaFaxEmpresa = telEmp;
                }
            }

            for (ContactPointEmail emEmp : todosLosCorreos) {
                if (viaCorreoEmpresa.Id == null && String.isNotBlank(emEmp.EmailAddress)) {
                    viaCorreoEmpresa = emEmp;
                }
            }

            // Si hay contacto relacionado (Person Account), consulta sus Contact Points.
            if (contactorel != null && contactorel.Id != null) {
                System.debug('Contact ID: ' + contactorel.Id);

                List<ContactPointPhone> telefonosContacto = [
                    SELECT Id, ParentId, TelephoneNumber, IsPrimary, CreatedDate, CPP_Tipo__c
                    FROM ContactPointPhone
                    WHERE ParentId = :contactorel.Id
                    AND (IsPrimary = true OR CPP_Tipo__c IN ('TELÉFONO FIJO', 'TELÉFONO MÓVIL', 'TELÉFONO FAX', 'TELÉFONO TRABAJO', 'TELÉFONO EN EL EXTERIOR', 'MÓVIL EN EL EXTERIOR'))
                    ORDER BY IsPrimary DESC, CreatedDate DESC
                ];

                List<ContactPointEmail> correosContacto = [
                    SELECT Id, ParentId, EmailAddress, IsPrimary, CreatedDate
                    FROM ContactPointEmail
                    WHERE ParentId = :contactorel.Id
                    AND (IsPrimary = true OR EmailAddress != null)
                    ORDER BY IsPrimary DESC, CreatedDate DESC
                ];

                System.debug('Telefonos Contacto Juridico: ' + telefonosContacto);
                System.debug('Correos Contacto Juridico: ' + correosContacto);

                // Reutiliza fijo/móvil/correo si no se habían llenado.
                for (ContactPointPhone telCon : telefonosContacto) {
                    if (viaTelefonoResidencial.Id == null && telCon.CPP_Tipo__c == 'TELÉFONO FIJO') {
                        viaTelefonoResidencial = telCon;
                    }
                    if (viaTelefonoMovil.Id == null && telCon.CPP_Tipo__c == 'TELÉFONO MÓVIL') {
                        viaTelefonoMovil = telCon;
                    }
                }

                for (ContactPointEmail emCon : correosContacto) {
                    if (viaCorreoElectronico.Id == null && String.isNotBlank(emCon.EmailAddress)) {
                        viaCorreoElectronico = emCon;
                    }
                }

                // Guarda el primer teléfono/correo del contacto relacionado para mostrar en VF.
                if (!telefonosContacto.isEmpty()) {
                    viaTelefonoContacto = telefonosContacto[0];
                }
                if (!correosContacto.isEmpty()) {
                    viaCorreoContacto = correosContacto[0];
                }
            }
        }

        // Debug de vías seleccionadas.
        System.debug('Via Telefono Residencial: ' + viaTelefonoResidencial);
        System.debug('Via Telefono Movil: ' + viaTelefonoMovil);
        System.debug('Via Correo Electronico: ' + viaCorreoElectronico);
        System.debug('Via Telefono Empresa: ' + viaTelefonoEmpresa);
        System.debug('Via Fax Empresa: ' + viaFaxEmpresa);
        System.debug('Via Correo Empresa: ' + viaCorreoEmpresa);
        System.debug('Via Telefono Contacto: ' + viaTelefonoContacto);
        System.debug('Via Correo Contacto: ' + viaCorreoContacto);

        // Trae hasta 3 registros del objeto Informacion_Financiera__c relacionados a la cuenta.
        List<Informacion_Financiera__c> infos = [
            SELECT Otros_Ingresos__c, INF_Fuente_de_ingresos__c
            FROM Informacion_Financiera__c
            WHERE INF_Cuenta__c = :accountId
            ORDER BY CreatedDate DESC
            LIMIT 3
        ];
        if (!infos.isEmpty()) {
            infoFinanciera = infos[0];
            lstInfosFinanciera = infos;

            while (lstInfosFinanciera.size() < 3) {
                lstInfosFinanciera.add(new Informacion_Financiera__c());
            }
        } else {
            infoFinanciera = new Informacion_Financiera__c();
            lstInfosFinanciera = new List<Informacion_Financiera__c>();

            for (Integer i = 0; i < 3; i++) {
                lstInfosFinanciera.add(new Informacion_Financiera__c());
            }
        }

        // Busca cónyuge en ACR (por AccountId o por ContactId de la PersonAccount).
        familiares = [
            SELECT Id, AccountId, ContactId, Account.Name, Parentesco__c, Tipo_de_relacion__c, Roles
            FROM AccountContactRelation
            WHERE (AccountId = :accountId OR ContactId = :cuenta.PersonContactId)
            AND Parentesco__c = 'Cónyuge'
            LIMIT 1
        ];
        System.debug(familiares);

        // Si existe cónyuge, resuelve su Account (por Id o PersonContactId) y trae su dirección laboral + employment.
        if (familiares != null && !familiares.isEmpty()) {
            AccountContactRelation relacion = familiares[0];
            Id idConyuge;

            if (relacion.AccountId != accountId) {
                idConyuge = relacion.AccountId;
            } else if (relacion.ContactId != cuenta.PersonContactId) {
                idConyuge = relacion.ContactId;
            }
            System.debug(idConyuge);

            if (idConyuge != null) {
                List<Account> lstConyuge = [
                    SELECT Id, PersonContactId, PersonBirthdate, FirstName, LastName, Suffix, Lugar_de_nacimiento_Padron_Electoral__c,
                           ACC_Nacionalidad__c, ACC_Nacionalidad_FATCA__c, ACC_TipoIdentificacion__c, ACC_NumIdentificacion__c, VFS_NumeroSegundaIdentificacion__c
                    FROM Account
                    WHERE (Id = :idConyuge OR PersonContactId = :idConyuge)
                    LIMIT 1
                ];

                if (!lstConyuge.isEmpty()) {
                    accConyuge = lstConyuge[0];

                    if (accConyuge != null && accConyuge.Id != null) {
                        List<ContactPointAddress> dirsConyuge = [
                            SELECT Id, Address, Street, City, State, Country, PostalCode, AddressType, CreatedDate
                            FROM ContactPointAddress
                            WHERE ParentId = :accConyuge.Id AND AddressType = 'LABORAL'
                            ORDER BY CreatedDate DESC
                            LIMIT 1
                        ];
                        if (!dirsConyuge.isEmpty()) {
                            dirConyugeLaboral = dirsConyuge[0];
                        } else {
                            dirConyugeLaboral = new ContactPointAddress();
                        }

                        List<FinServ__Employment__c> empConyuge = queryEmployment(accConyuge.PersonContactId);
                        if (!empConyuge.isEmpty()) {
                            historialConyuge = empConyuge[0];
                        } else {
                            historialConyuge = new FinServ__Employment__c();
                        }
                    }
                } else {
                    accConyuge = new Account();
                }
            } else {
                accConyuge = new Account();
            }
        } else {
            System.debug('Familiares esta vacio');
            accConyuge = new Account();
        }

        // Productos y servicios principales (máximo 3; completa placeholders).
        List<Productos_y_Servicios__c> ProductsPrincipal = [
            SELECT Name
            FROM Productos_y_Servicios__c
            WHERE Cliente__c = :accountId
            ORDER BY CreatedDate DESC
            LIMIT 3
        ];
        if (!ProductsPrincipal.isEmpty()) {
            lstPrincipalesProductosServicios = ProductsPrincipal;
            while (lstPrincipalesProductosServicios.size() < 3) lstPrincipalesProductosServicios.add(new Productos_y_Servicios__c());
        } else {
            for (Integer i = 0; i < 3; i++) lstPrincipalesProductosServicios.add(new Productos_y_Servicios__c());
        }
        System.debug('Productos y servicios principales ' + lstPrincipalesProductosServicios);

        // Clientes principales (máximo 3; completa placeholders).
        List<FinServ__AccountAccountRelation__c> principalClients = [
            SELECT Id, FinServ__RelatedAccount__c, FinServ__RelatedAccount__r.Name,
                   FinServ__RelatedAccount__r.ACC_RNC__c,
                   AAR_Tipo__c
            FROM FinServ__AccountAccountRelation__c
            WHERE FinServ__RelatedAccount__c = :accountId
              AND AAR_Tipo__c = 'Cliente Principal'
            ORDER BY CreatedDate DESC
            LIMIT 3
        ];
        if (!principalClients.isEmpty()) {
            lstPrincipalesClientes = principalClients;
            while (lstPrincipalesClientes.size() < 3) lstPrincipalesClientes.add(new FinServ__AccountAccountRelation__c());
        } else {
            for (Integer i = 0; i < 3; i++) lstPrincipalesClientes.add(new FinServ__AccountAccountRelation__c());
        }
        System.debug('Clientes principales ' + lstPrincipalesClientes);

        // Proveedores principales (máximo 3; completa placeholders).
        List<FinServ__AccountAccountRelation__c> proveedoresRel = [
            SELECT Id, FinServ__RelatedAccount__c, FinServ__RelatedAccount__r.Name,
                   FinServ__RelatedAccount__r.ACC_RNC__c,
                   AAR_Tipo__c
            FROM FinServ__AccountAccountRelation__c
            WHERE FinServ__RelatedAccount__c = :accountId
              AND AAR_Tipo__c = 'Principal Proveedor'
            ORDER BY CreatedDate DESC
            LIMIT 3
        ];
        lstPrincipalesProveedores.clear();
        if (!proveedoresRel.isEmpty()) {
            lstPrincipalesProveedores = proveedoresRel;
            while (lstPrincipalesProveedores.size() < 3) lstPrincipalesProveedores.add(new FinServ__AccountAccountRelation__c());
        } else {
            for (Integer i = 0; i < 3; i++) lstPrincipalesProveedores.add(new FinServ__AccountAccountRelation__c());
        }
        System.debug('Proveedores principales ' + lstPrincipalesProveedores);

        // Resuelve accionistas/miembros/funcionarios/firmantes y arma wrappers con vías.
        obtenerAccionistasMiembors((String)accountId);

        // Empresas filiales (máximo 4; completa placeholders).
        List<FinServ__AccountAccountRelation__c> filialesRel = [
            SELECT Id, FinServ__RelatedAccount__c,
                   FinServ__RelatedAccount__r.Name, FinServ__RelatedAccount__r.ACC_RNC__c,
                   AAR_Tipo__c, AAR_Grupo_economico__c, AAR_Grupo_financiero__c, AAR_Pais_donde_opera__c
            FROM FinServ__AccountAccountRelation__c
            WHERE FinServ__RelatedAccount__c = :accountId
              AND AAR_Tipo__c = 'Empresa Filial'
            ORDER BY CreatedDate DESC
            LIMIT 4
        ];

        lstEmpresasFiliales.clear();
        if (!filialesRel.isEmpty()) {
            lstEmpresasFiliales = filialesRel;
            while (lstEmpresasFiliales.size() < 4) lstEmpresasFiliales.add(new FinServ__AccountAccountRelation__c());
        } else {
            for (Integer i = 0; i < 4; i++) lstEmpresasFiliales.add(new FinServ__AccountAccountRelation__c());
        }
        System.debug('Empresas Filiales ' + lstEmpresasFiliales);

        // CAMBIO: estos valores deben calcularse al final, cuando ya se cargaron direcciones y teléfonos.
        dirResidenciaFATCATxt = formatearDireccion(dirResidenciaFATCA);
        telefonoUSATxt = (viaTelefonoMovil != null && String.isNotBlank(viaTelefonoMovil.TelephoneNumber))
            ? viaTelefonoMovil.TelephoneNumber
            : '';
    }

    // Calcula listas de participantes/accionistas/miembros/funcionarios, detecta PEP y arma wrappers con vías.
    public void obtenerAccionistasMiembors(String accountIdParam){
        Id accId = (Id)accountIdParam;

        // Miembros del Consejo desde AAR (AccountAccountRelation) para calzar con VF
        lstMiembros.clear();

        List<FinServ__AccountAccountRelation__c> miembrosAAR = [
            SELECT Id,
                   FinServ__RelatedAccount__c,
                   FinServ__RelatedAccount__r.Name,
                   FinServ__RelatedAccount__r.ACC_NumIdentificacion__c,
                   FinServ__RelatedAccount__r.Lugar_de_nacimiento_Padron_Electoral__c,
                   AAR_Tipo__c, AAR_Cargo__c
            FROM FinServ__AccountAccountRelation__c
            WHERE FinServ__RelatedAccount__c = :accId
              AND AAR_Tipo__c = 'Miembro'
            ORDER BY CreatedDate DESC
            LIMIT 8
        ];

        if (!miembrosAAR.isEmpty()) {
            lstMiembros.addAll(miembrosAAR);
        }

        while (lstMiembros.size() < 8) {
            lstMiembros.add(new FinServ__AccountAccountRelation__c());
        }

        // Trae todas las relaciones ACR de la cuenta (para inferir roles).
        List<AccountContactRelation> rels = [
            SELECT Id, AccountId, ContactId, Parentesco__c, Tipo_de_relacion__c, Roles,
                   Contact.FirstName, Contact.LastName, Contact.Name
            FROM AccountContactRelation
            WHERE AccountId = :accId
        ];

        // Recolecta ContactIds para resolver Person Accounts (por PersonContactId).
        Set<Id> contactIds = new Set<Id>();
        for (AccountContactRelation r : rels) {
            if (r.ContactId != null) contactIds.add(r.ContactId);
        }

        // Map ContactId -> Person Account.
        Map<Id, Account> accByContact = new Map<Id, Account>();
        if (!contactIds.isEmpty()) {
            for (Account a : [
                SELECT Id, Name, PersonContactId, ACC_NumIdentificacion__c, ACC_Persona_PEP__c,
                       ACC_Nacionalidad_FATCA__c, ACC_Pais_Residencia_Legal__c
                FROM Account
                WHERE PersonContactId IN :contactIds
            ]) {
                accByContact.put(a.PersonContactId, a);
            }
        }

        // Recolecta AccountIds relacionados para consultar Contact Points en bulk.
        Set<Id> relatedAccIds = new Set<Id>();
        for (Id cId : accByContact.keySet()) {
            relatedAccIds.add(accByContact.get(cId).Id);
        }

        Map<Id, List<ContactPointPhone>> phonesByAcc = new Map<Id, List<ContactPointPhone>>();
        Map<Id, List<ContactPointEmail>> emailsByAcc = new Map<Id, List<ContactPointEmail>>();

        // Carga teléfonos/correos por Account (bulk) para luego buscar el primer valor no vacío.
        if (!relatedAccIds.isEmpty()) {
            for (ContactPointPhone p : [
                SELECT Id, ParentId, TelephoneNumber, IsPrimary, CreatedDate, CPP_Tipo__c
                FROM ContactPointPhone
                WHERE ParentId IN :relatedAccIds
                ORDER BY IsPrimary DESC, CreatedDate DESC
            ]) {
                if (!phonesByAcc.containsKey(p.ParentId)) phonesByAcc.put(p.ParentId, new List<ContactPointPhone>());
                phonesByAcc.get(p.ParentId).add(p);
            }

            for (ContactPointEmail e : [
                SELECT Id, ParentId, EmailAddress, IsPrimary, CreatedDate
                FROM ContactPointEmail
                WHERE ParentId IN :relatedAccIds
                ORDER BY IsPrimary DESC, CreatedDate DESC
            ]) {
                if (!emailsByAcc.containsKey(e.ParentId)) emailsByAcc.put(e.ParentId, new List<ContactPointEmail>());
                emailsByAcc.get(e.ParentId).add(e);
            }
        }

        // Limpia listas para recalcular desde cero.
        lstParticipantes.clear();
        lstAccionistas.clear();
        lstFuncionarios.clear();
        lstSociosExtranjeros.clear();
        lstRepVias.clear();
        lstAutorizados.clear();
        ParticipantePEP = new Account();

        // Clasifica cada ACR por "rol" (texto) y agrega a listas.
        for (AccountContactRelation r : rels) {
            String tipo = String.isBlank(r.Tipo_de_relacion__c) ? '' : r.Tipo_de_relacion__c;
            String parentesco = String.isBlank(r.Parentesco__c) ? '' : r.Parentesco__c;
            String roles = String.isBlank(r.Roles) ? '' : r.Roles;

            String rol = (tipo + ' ' + parentesco + ' ' + roles).trim().toLowerCase();

            Account aRel = (r.ContactId != null && accByContact.containsKey(r.ContactId)) ? accByContact.get(r.ContactId) : null;
            if (aRel == null) continue;

            if (rol.contains('firmante')) {
                lstParticipantes.add(aRel);
            }

            if (rol.contains('accionista')) {
                lstAccionistas.add(aRel);
            } else if (rol.contains('funcionario')) {
                lstFuncionarios.add(aRel);
            }

            // FATCA: socios extranjeros si nacionalidad o residencia legal = Estados Unidos y rol relevante.
            if ((aRel.ACC_Nacionalidad_FATCA__c == 'ESTADOS UNIDOS' || aRel.ACC_Pais_Residencia_Legal__c == 'ESTADOS UNIDOS')
                && (rol.contains('accionista') || rol.contains('miembro'))) {
                lstSociosExtranjeros.add(aRel);
            }

            // Primer PEP detectado (SI o VÍNCULO/PARENTESCO).
            if ((aRel.ACC_Persona_PEP__c == 'SI' || aRel.ACC_Persona_PEP__c == 'VÍNCULO/PARENTESCO') && (ParticipantePEP == null || ParticipantePEP.Id == null)) {
                ParticipantePEP = aRel;
            }

            // Resuelve teléfono y correo (primer valor no vacío) desde maps.
            String telefono = '';
            String correo = '';

            if (phonesByAcc.containsKey(aRel.Id) && !phonesByAcc.get(aRel.Id).isEmpty()) {
                for (ContactPointPhone p : phonesByAcc.get(aRel.Id)) {
                    if (String.isNotBlank(p.TelephoneNumber)) {
                        telefono = p.TelephoneNumber;
                        break;
                    }
                }
            }

            if (emailsByAcc.containsKey(aRel.Id) && !emailsByAcc.get(aRel.Id).isEmpty()) {
                for (ContactPointEmail e : emailsByAcc.get(aRel.Id)) {
                    if (String.isNotBlank(e.EmailAddress)) {
                        correo = e.EmailAddress;
                        break;
                    }
                }
            }

            // Wrapper para representante legal.
            if (rol.contains('representante') && rol.contains('legal')) {
                lstRepVias.add(new VFS_KYCWrapperRepVias(aRel.Name, aRel.ACC_NumIdentificacion__c, telefono, correo));
            }

            // Wrapper para autorizados / firmantes autorizados.
            if (rol.contains('autorizado') || (rol.contains('firmante') && rol.contains('autoriz'))) {
                lstAutorizados.add(new VFS_KYCWrapperRepVias(aRel.Name, aRel.ACC_NumIdentificacion__c, telefono, correo));
            }
        }

        // Completa tamaños fijos para render en VF.
        while (lstParticipantes.size() < 12) lstParticipantes.add(new Account());
        while (lstAccionistas.size() < 8) lstAccionistas.add(new Account());
        while (lstFuncionarios.size() < 8) lstFuncionarios.add(new Account());
        while (lstSociosExtranjeros.size() < 4) lstSociosExtranjeros.add(new Account());

        while (lstRepVias.size() < 5) lstRepVias.add(new VFS_KYCWrapperRepVias('', '', '', ''));
        while (lstAutorizados.size() < 12) lstAutorizados.add(new VFS_KYCWrapperRepVias('', '', '', ''));

        System.debug('RepresentantesLegales ' + lstParticipantes);
        System.debug('Accionistas ' + lstAccionistas);
        System.debug('Miembros (AAR) ' + lstMiembros);
        System.debug('Funcionarios ' + lstFuncionarios);
        System.debug('Socios Extranjeros ' + lstSociosExtranjeros);
        System.debug('lstRepVias' + lstRepVias);
    }

    // Consulta dinámica de Employment (solo campos que existan), filtrando principal si aplica.
    @TestVisible
    private static List<FinServ__Employment__c> queryEmployment(Id contactId) {
        if (contactId == null) return new List<FinServ__Employment__c>();

        Schema.SObjectType t = Schema.getGlobalDescribe().get('FinServ__Employment__c');

        List<String> fields = new List<String>{ 'Id', 'Name' };
        if (t != null && t.getDescribe().fields.getMap().containsKey('FinServ__Contact__c')) fields.add('FinServ__Contact__c');
        if (t != null && t.getDescribe().fields.getMap().containsKey('FinServ__AnnualIncome__c')) fields.add('FinServ__AnnualIncome__c');
        if (t != null && t.getDescribe().fields.getMap().containsKey('FinServ__EmployerPhoneNumber__c')) fields.add('FinServ__EmployerPhoneNumber__c');
        if (t != null && t.getDescribe().fields.getMap().containsKey('FinServ__EmployerAddress__c')) fields.add('FinServ__EmployerAddress__c');
        if (t != null && t.getDescribe().fields.getMap().containsKey('FinServ__Occupation__c')) fields.add('FinServ__Occupation__c');
        if (t != null && t.getDescribe().fields.getMap().containsKey('EMP_Tipo_de_empleado__c')) fields.add('EMP_Tipo_de_empleado__c');
        if (t != null && t.getDescribe().fields.getMap().containsKey('FinServ__LengthOfEmployment__c')) fields.add('FinServ__LengthOfEmployment__c');
        if (t != null && t.getDescribe().fields.getMap().containsKey('FinServ__Position__c')) fields.add('FinServ__Position__c');
        if (t != null && t.getDescribe().fields.getMap().containsKey('HIS_Principal__c')) fields.add('HIS_Principal__c');

        String whereClause = ' WHERE FinServ__Contact__c = :contactId';
        if (t != null && t.getDescribe().fields.getMap().containsKey('HIS_Principal__c')) {
            whereClause += ' AND HIS_Principal__c = true';
        }

        String soql = 'SELECT ' + String.join(fields, ',') +
                      ' FROM FinServ__Employment__c' +
                      whereClause +
                      ' ORDER BY CreatedDate DESC' +
                      ' LIMIT 1';

        return (List<FinServ__Employment__c>) Database.query(soql);
    }

    // Arma un string de dirección en formato "Street, City, State, PostalCode, Country".
    public String formatearDireccion(ContactPointAddress dir) {
        if (dir == null) return '';

        Address a = (Address) dir.get('Address');
        if (a == null) return '';

        List<String> partes = new List<String>();
        if (!String.isBlank(a.street)) partes.add(a.street);
        if (!String.isBlank(a.city)) partes.add(a.city);
        if (!String.isBlank(a.state)) partes.add(a.state);
        if (!String.isBlank(a.postalCode)) partes.add(a.postalCode);
        if (!String.isBlank(a.country)) partes.add(a.country);

        return String.join(partes, ', ');
    }
}