/*****************************************************************************************************
* Nombre de clase apex   :   VFS_KYCFisica_Controller
* Versión                :   1.0
* Fecha de creación      :   10/04/2025
* Función                :   Controlador para visualforce VFS_ContratoUnico.
* Clase de pruebas       :    VFS_KYCFisica_ControllerTest
*
* Registro de modificaciones    
* ---------------------------------------------------------------------------------------------------
* Desarrollador                          Fecha                          Descripción
*  
* Carlos Ventura                         14-07-2025                 Versión original
******************************************************************************************************/
public with sharing class VFS_KYCFisica_Controller {
    public Id accountId { get; set; }
    public Account cuenta { get; set; }
    public Account contactorel { get; set; }
    public Referencia__c referencia { get; set; }
    public List<Referencia__c> lstReferenciasBancarias { get; set; }    
    public List<Referencia__c> lstReferenciasComerciales { get; set; }
    public List<Referencia__c> lstReferenciasPersonales { get; set; }
    public List<Empresa_Filial__c> lstEmpresasFiliales { get; set; }
    public List<Productos_y_Servicios__c> lstPrincipalesProductosServicios { get; set; }
    public List<Cliente_Principal__c> lstPrincipalesClientes { get; set; }
    public List<Principal_Proveedor__c> lstPrincipalesProveedores { get; set; }
    public List<Participante__c> lstParticipantes { get; set; }
    public List<Vias_de_Contacto__c> lstViasRepresentantes { get; set; }
    public List<Participante__c> lstAccionistas { get; set; }
    public List<Participante__c> lstMiembros { get; set; }
    public List<Participante__c> lstFuncionarios { get; set; }
    public List<Participante__c> lstSociosExtranjeros { get; set; }
    public List<AccountContactRelation> familiares { get; set; }
    public Direccion__c direccion { get; set; }
    public Direccion__c dirEmpresarial { get; set; }
    public Direccion__c dirResidencia { get; set; }
    public Direccion__c dirResidenciaFATCA { get; set; }
    public Historial_laboral__c historial { get; set; }
    public Vias_de_Contacto__c viaTelefonoResidencial { get; set; }
    public Vias_de_Contacto__c viaTelefonoMovil { get; set; }
    public Vias_de_Contacto__c viaCorreoElectronico { get; set; }
    public Vias_de_Contacto__c viaTelefonoEmpresa { get; set; }
    public Vias_de_Contacto__c viaFaxEmpresa { get; set; }
    public Vias_de_Contacto__c viaCorreoEmpresa { get; set; }
    public Vias_de_Contacto__c viaTelefonoContacto { get; set; }
    public Vias_de_Contacto__c viaCorreoContacto { get; set; }
    public Informacion_Financiera__c infoFinanciera { get; set; }
    public List<Informacion_Financiera__c> lstInfosFinanciera { get; set; }
    public AccountContactRelation conyuge { get; set; }
    public Account accConyuge { get; set; }
    public boolean isFisica { get; set; }
    public List<VFS_KYCWrapperRepVias> lstRepVias { get; set; }
    public List<VFS_KYCWrapperRepVias> lstAutorizados { get; set; }
    public Participante__c ParticipantePEP { get; set; }

    public VFS_KYCFisica_Controller(ApexPages.StandardController std) {

        Boolean isPdf = (ApexPages.currentPage() != null
            && ApexPages.currentPage().getParameters() != null
            && ApexPages.currentPage().getParameters().get('pdf') == '1');
        System.debug('isPdf: ' + isPdf);

        lstReferenciasBancarias = new List<Referencia__c>();
        lstReferenciasComerciales = new List<Referencia__c>();
        lstReferenciasPersonales = new List<Referencia__c>();
        lstEmpresasFiliales = new List<Empresa_Filial__c>();
        lstPrincipalesProductosServicios = new List<Productos_y_Servicios__c>();
        lstPrincipalesClientes = new List<Cliente_Principal__c>();
        familiares = new List<AccountContactRelation>();
        lstPrincipalesProveedores = new List<Principal_Proveedor__c>();
        lstRepVias = new List<VFS_KYCWrapperRepVias>();
        lstAutorizados = new List<VFS_KYCWrapperRepVias>();

        lstParticipantes = new List<Participante__c>();
        lstViasRepresentantes = new List<Vias_de_Contacto__c>();
        lstAccionistas = new List<Participante__c>();
        lstMiembros = new List<Participante__c>();
        lstFuncionarios = new List<Participante__c>();
        lstSociosExtranjeros = new List<Participante__c>();
        isFisica = true;

        accountId = std.getId();

        cuenta = [
            SELECT Id, RecordType.DeveloperName, PersonContactId, MiddleName, Name,
                   ACC_NumOficina__c, ACC_CIF__c, OwnerId, Owner.Name,
                   VFS_ActividadEconomica__c, VFS_EspecifiqueOtro__c
            FROM Account
            WHERE Id = :accountId
        ];

        if (cuenta.RecordType.DeveloperName == 'PersonAccount') {
            isFisica = true;
        } else {
            isFisica = false;
        }

        contactorel = new Account();

        Account relacionado;
        try {
            relacionado = [
                SELECT Id, PersonContactId,
                       PersonContact.FirstName, PersonContact.LastName, PersonContact.Suffix, PersonContact.Name
                FROM Account
                WHERE Id = :accountId
                LIMIT 1
            ];
        } catch (QueryException qe) {
            System.debug('No se encontró la cuenta: ' + qe.getMessage());
            relacionado = null;
        }

        if (relacionado != null && relacionado.PersonContactId != null) {
            contactorel = new Account();
            contactorel.FirstName = relacionado.PersonContact.FirstName;
            contactorel.LastName  = relacionado.PersonContact.LastName;
            contactorel.Suffix    = relacionado.PersonContact.Suffix;
        } else {
            contactorel = new Account();
        }

        List<Referencia__c> refList = [
            SELECT Id, REF_Tipo__c, Tipo_de_cuenta__c, Name, Banco__c, Pais__c, Account__r.LastName, Moneda__c,
                   N_de_cuenta__c, VFS_RNC__c, REF_Nombre__c, REF_Telefono__c, REF_Direccion__c
            FROM Referencia__c
            WHERE Account__c = :accountId
        ];
        if (!refList.isEmpty()) {
            referencia = refList[0];
        } else {
            referencia = new Referencia__c();
        }
        System.debug(referencia);

        for (Referencia__c ref : refList) {
            if (ref.REF_Tipo__c == 'Bancaria') {
                lstReferenciasBancarias.add(ref);
            } else if (ref.REF_Tipo__c == 'Personal') {
                lstReferenciasPersonales.add(ref);
            } else if (ref.REF_Tipo__c == 'Comercial') {
                lstReferenciasComerciales.add(ref);
            }
        }

        if (!isPdf) {
            while (lstReferenciasBancarias.size() < 3) lstReferenciasBancarias.add(new Referencia__c());
            while (lstReferenciasPersonales.size() < 3) lstReferenciasPersonales.add(new Referencia__c());
            while (lstReferenciasComerciales.size() < 3) lstReferenciasComerciales.add(new Referencia__c());
        }

        List<Direccion__c> dirResidenciales = [
            SELECT DIR_Account__c, DIR_N_Telefono__c, DIR_Estado_Ciudad__c, DIR_Direccion_Traduccion__c,
                   DIR_N_Apartamento__c, DIR_Distrito_texto__c, DIR_Municipio_texto__c, DIR_Provincia_texto__c,
                   DIR_Pais_Texto__c, DIR_Pais__c, DIR_Calle__c, DIR_Numero__c, DIR_Edificio__c, DIR_Sector__r.Name
            FROM Direccion__c
            WHERE DIR_Account__c = :accountId
            AND DIR_Tipo_Direccion__c = 'RESIDENCIA'
            ORDER BY CreatedDate desc
        ];

        dirResidenciaFATCA = new Direccion__c();

        for (Direccion__c dir : dirResidenciales) {
            System.debug('Direcciones residenciales: ' + dirResidenciales);
            if (dir.DIR_Pais__c == 'US') {
                dirResidenciaFATCA = dir;
            }
        }

        if (dirResidenciales.isEmpty()) {
            dirResidencia = new Direccion__c();
        } else {
            dirResidencia = dirResidenciales[0];
            dirResidencia.DIR_Direccion_Traduccion__c = formatearDireccion(dirResidencia);
        }
        System.debug(dirResidencia);

        List<Direccion__c> directions = [
            SELECT DIR_Account__c, DIR_Estado_Ciudad__c, DIR_Direccion_Traduccion__c, DIR_N_Apartamento__c,
                   DIR_Distrito_texto__c, DIR_Municipio_texto__c, DIR_Provincia_texto__c, DIR_Pais_Texto__c,
                   DIR_Pais__c, DIR_Calle__c, DIR_Numero__c, DIR_Edificio__c, DIR_Sector__r.Name
            FROM Direccion__c
            WHERE DIR_Account__c = :accountId
            AND DIR_Tipo_Direccion__c = 'LABORAL'
            ORDER BY CreatedDate desc
            LIMIT 1
        ];
        if (!directions.isEmpty()) {
            direccion = directions[0];
            direccion.DIR_Direccion_Traduccion__c = formatearDireccion(direccion);
        } else {
            direccion = new Direccion__c();
        }
        System.debug(direccion);

        List<Direccion__c> directions2 = [
            SELECT DIR_Account__c, DIR_Estado_Ciudad__c, DIR_Direccion_Traduccion__c, DIR_N_Apartamento__c,
                   DIR_Distrito_texto__c, DIR_Municipio_texto__c, DIR_Provincia_texto__c, DIR_Pais_Texto__c,
                   DIR_Pais__c, DIR_Calle__c, DIR_Numero__c, DIR_Edificio__c, Direccion__c.DIR_Sector__r.Name
            FROM Direccion__c
            WHERE DIR_Account__c = :accountId
            AND DIR_Tipo_Direccion__c = 'EMPRESARIAL'
            ORDER BY CreatedDate desc
            LIMIT 1
        ];
        if (!directions2.isEmpty()) {
            dirEmpresarial = directions2[0];
            dirEmpresarial.DIR_Direccion_Traduccion__c = formatearDireccion(dirEmpresarial);
        } else {
            dirEmpresarial = new Direccion__c();
        }
        System.debug(dirEmpresarial);

        Id cuentaHistorial = isFisica ? accountId : (contactorel != null && contactorel.Id != null ? contactorel.Id : accountId);
        List<Historial_laboral__c> historiales = [
            SELECT Salario__c, Telefono_de_empresa__r.VIA_de_Contacto__c, Telefono_de_empresa__r.VIA_Numero_Correo__c,
                   HIS_Principal__c, HIS_Ocupacion__c, Tipo_de_empleado__c, HIS_Empresa__c, Tiempo_de_empresa__c, HIS_Puesto_de_trabajo__c
            FROM Historial_laboral__c
            WHERE HIS_Cuenta__c = :cuentaHistorial
            AND HIS_Principal__c = true
            LIMIT 1
        ];
        if (!historiales.isEmpty()) historial = historiales[0];
        else historial = new Historial_laboral__c();
        System.debug(historial);

        List<Vias_de_Contacto__c> todasLasVias = [
            SELECT VIA_Numero_Correo__c, VIA_de_Contacto__c, VIA_Principal__c
            FROM Vias_de_Contacto__c
            WHERE VIA_Account__c = :accountId
            AND (VIA_de_Contacto__c = 'TELÉFONO FIJO'
                 OR VIA_de_Contacto__c = 'TELÉFONO MÓVIL'
                 OR VIA_de_Contacto__c = 'TELÉFONO FAX'
                 OR VIA_de_Contacto__c LIKE '%CORREO%'
                 OR VIA_Principal__c = true)
            ORDER BY VIA_Principal__c DESC, CreatedDate DESC
        ];

        viaTelefonoResidencial = new Vias_de_Contacto__c();
        viaTelefonoMovil = new Vias_de_Contacto__c();
        viaCorreoElectronico = new Vias_de_Contacto__c();
        viaTelefonoEmpresa = new Vias_de_Contacto__c();
        viaFaxEmpresa = new Vias_de_Contacto__c();
        viaCorreoEmpresa = new Vias_de_Contacto__c();
        viaTelefonoContacto = new Vias_de_Contacto__c();
        viaCorreoContacto = new Vias_de_Contacto__c();

        if (isFisica) {
            for (Vias_de_Contacto__c viaActual : todasLasVias) {
                if (viaActual.VIA_de_Contacto__c == 'TELÉFONO FIJO' && viaTelefonoResidencial.VIA_de_Contacto__c == null) {
                    viaTelefonoResidencial = viaActual;
                }
                if (viaActual.VIA_de_Contacto__c == 'TELÉFONO MÓVIL' && viaTelefonoMovil.VIA_de_Contacto__c == null) {
                    viaTelefonoMovil = viaActual;
                }
                if (viaActual.VIA_de_Contacto__c != null && viaActual.VIA_de_Contacto__c.contains('CORREO') && viaCorreoElectronico.VIA_de_Contacto__c == null) {
                    viaCorreoElectronico = viaActual;
                }
            }
        }

        if (!isFisica) {
            System.debug('Lista de vías de contacto: ' + todasLasVias);
            for (Vias_de_Contacto__c viaActual : todasLasVias) {
                System.debug('Vía actual: ' + viaActual);
                if (viaActual.VIA_de_Contacto__c == 'TELÉFONO FIJO' && viaTelefonoEmpresa.VIA_de_Contacto__c == null) {
                    viaTelefonoEmpresa = viaActual;
                }
                if (viaActual.VIA_de_Contacto__c == 'TELÉFONO FAX' && viaFaxEmpresa.VIA_de_Contacto__c == null) {
                    viaFaxEmpresa = viaActual;
                }
                if (viaActual.VIA_de_Contacto__c != null && viaActual.VIA_de_Contacto__c.contains('CORREO') && viaCorreoEmpresa.VIA_de_Contacto__c == null) {
                    viaCorreoEmpresa = viaActual;
                }
            }

            if (contactorel != null && contactorel.Id != null) {
                System.debug('Contact ID: ' + contactorel.Id);
                List<Vias_de_Contacto__c> viasContactoJuridico = [
                    SELECT VIA_Numero_Correo__c, VIA_de_Contacto__c, VIA_Principal__c
                    FROM Vias_de_Contacto__c
                    WHERE VIA_Account__c = :contactorel.Id
                    AND (VIA_de_Contacto__c = 'TELÉFONO FIJO'
                         OR VIA_de_Contacto__c = 'TELÉFONO MÓVIL'
                         OR VIA_de_Contacto__c LIKE '%CORREO%')
                    ORDER BY VIA_Principal__c DESC, CreatedDate DESC
                ];

                for (Vias_de_Contacto__c viaContactoActual : viasContactoJuridico) {
                    if (viaContactoActual.VIA_de_Contacto__c == 'TELÉFONO FIJO' && viaTelefonoResidencial.VIA_de_Contacto__c == null) {
                        viaTelefonoResidencial = viaContactoActual;
                    }
                    if (viaContactoActual.VIA_de_Contacto__c == 'TELÉFONO MÓVIL' && viaTelefonoMovil.VIA_de_Contacto__c == null) {
                        viaTelefonoMovil = viaContactoActual;
                    }
                    if (viaContactoActual.VIA_de_Contacto__c != null && viaContactoActual.VIA_de_Contacto__c.contains('CORREO') && viaCorreoElectronico.VIA_de_Contacto__c == null) {
                        viaCorreoElectronico = viaContactoActual;
                    }
                }
            }

            if (contactorel != null && contactorel.Id != null) {
                List<Vias_de_Contacto__c> viasContacto = [
                    SELECT VIA_Numero_Correo__c, VIA_de_Contacto__c, VIA_Principal__c
                    FROM Vias_de_Contacto__c
                    WHERE VIA_Account__c = :contactorel.Id
                    AND (VIA_de_Contacto__c LIKE '%TELÉFONO%' OR VIA_de_Contacto__c LIKE '%CORREO%')
                    ORDER BY VIA_Principal__c DESC, CreatedDate DESC
                ];

                for (Vias_de_Contacto__c viaContactoActual : viasContacto) {
                    if (viaContactoActual.VIA_de_Contacto__c != null && viaContactoActual.VIA_de_Contacto__c.contains('TELÉFONO') && viaTelefonoContacto.VIA_de_Contacto__c == null) {
                        viaTelefonoContacto = viaContactoActual;
                    }
                    if (viaContactoActual.VIA_de_Contacto__c != null && viaContactoActual.VIA_de_Contacto__c.contains('CORREO') && viaCorreoContacto.VIA_de_Contacto__c == null) {
                        viaCorreoContacto = viaContactoActual;
                    }
                }
            }
        }

        System.debug('Via Telefono Residencial: ' + viaTelefonoResidencial);
        System.debug('Via Telefono Movil: ' + viaTelefonoMovil);
        System.debug('Via Correo Electronico: ' + viaCorreoElectronico);
        System.debug('Via Telefono Empresa: ' + viaTelefonoEmpresa);
        System.debug('Via Fax Empresa: ' + viaFaxEmpresa);
        System.debug('Via Correo Empresa: ' + viaCorreoEmpresa);
        System.debug('Via Telefono Contacto: ' + viaTelefonoContacto);
        System.debug('Via Correo Contacto: ' + viaCorreoContacto);

        List<Informacion_Financiera__c> infos = [
            SELECT Otros_Ingresos__c, INF_Fuente_de_ingresos__c
            FROM Informacion_Financiera__c
            WHERE INF_Cuenta__c = :accountId
            ORDER BY CreatedDate desc
            LIMIT 3
        ];
        if (!infos.isEmpty()) {
            infoFinanciera = infos[0];
            lstInfosFinanciera = infos;

            if (!isPdf) {
                while (lstInfosFinanciera.size() < 3) lstInfosFinanciera.add(new Informacion_Financiera__c());
            }
        } else {
            infoFinanciera = new Informacion_Financiera__c();
            lstInfosFinanciera = new List<Informacion_Financiera__c>();
            if (!isPdf) {
                for (Integer i = 0; i < 3; i++) lstInfosFinanciera.add(new Informacion_Financiera__c());
            }
        }

        familiares = [
            SELECT Id, AccountId, ContactId, Account.Name, Parentesco__c
            FROM AccountContactRelation
            WHERE (AccountId = :accountId OR ContactId = :cuenta.PersonContactId)
            AND Parentesco__c = 'Cónyuge'
            LIMIT 1
        ];
        System.debug(familiares);

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
                           ACC_Nacionalidad__c, ACC_Nacionalidad_FATCA__c, ACC_TipoIdentificacion__c, ACC_NumIdentificacion__c, VFS_NumeroSegundaIdentificacion__c,
                           (SELECT DIR_Calle__c, DIR_Numero__c, DIR_Edificio__c, DIR_N_Apartamento__c, DIR_Direccion_Traduccion__c
                            FROM Direcciones__r
                            WHERE DIR_Tipo_Direccion__c = 'LABORAL' LIMIT 1),
                           (SELECT HIS_Ocupacion__c, Salario__c
                            FROM Historial_laboral__r LIMIT 1)
                    FROM Account
                    WHERE (Id = :idConyuge OR PersonContactId = :idConyuge)
                    LIMIT 1
                ];
                if (!lstConyuge.isEmpty()) {
                    if (!lstConyuge[0].Direcciones__r.isEmpty()) {
                        Direccion__c dirConyuge = lstConyuge[0].Direcciones__r[0];
                        dirConyuge.DIR_Direccion_Traduccion__c = formatearDireccion(dirConyuge);
                    }
                    accConyuge = lstConyuge[0];
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

        // Bloque jurídico SOLO si no es persona física
        if (!isFisica) {

            List<Productos_y_Servicios__c> ProductsPrincipal = [
                SELECT Name
                FROM Productos_y_Servicios__c
                WHERE Cliente__c = :accountId
                ORDER BY CreatedDate desc
                LIMIT 3
            ];
            if (!ProductsPrincipal.isEmpty()) {
                lstPrincipalesProductosServicios = ProductsPrincipal;
                if (!isPdf) {
                    while (lstPrincipalesProductosServicios.size() < 3) lstPrincipalesProductosServicios.add(new Productos_y_Servicios__c());
                }
            } else if (!isPdf) {
                for (Integer i = 0; i < 3; i++) lstPrincipalesProductosServicios.add(new Productos_y_Servicios__c());
            }
            System.debug('Productos y servicios principales ' + lstPrincipalesProductosServicios);

            List<Cliente_Principal__c> principalClients = [
                SELECT Name, Tipo_de_identificacion__c, N_de_Identificacion__c
                FROM Cliente_Principal__c
                WHERE Cliente__c = :accountId
                AND Tipo_de_identificacion__c = 'RNC'
                ORDER BY CreatedDate desc
                LIMIT 3
            ];
            if (!principalClients.isEmpty()) {
                lstPrincipalesClientes = principalClients;
                if (!isPdf) {
                    while (lstPrincipalesClientes.size() < 3) lstPrincipalesClientes.add(new Cliente_Principal__c());
                }
            } else if (!isPdf) {
                for (Integer i = 0; i < 3; i++) lstPrincipalesClientes.add(new Cliente_Principal__c());
            }
            System.debug('Clientes principales ' + lstPrincipalesClientes);

            List<Principal_Proveedor__c> Proveedores = [
                SELECT Name, Tipo_de_identificaci_n__c, N_de_Identificacion__c
                FROM Principal_Proveedor__c
                WHERE Cliente__c = :accountId
                AND Tipo_de_identificaci_n__c = 'RNC'
                ORDER BY CreatedDate desc
                LIMIT 3
            ];
            if (!Proveedores.isEmpty()) {
                lstPrincipalesProveedores = Proveedores;
                if (!isPdf) {
                    while (lstPrincipalesProveedores.size() < 3) lstPrincipalesProveedores.add(new Principal_Proveedor__c());
                }
            } else if (!isPdf) {
                for (Integer i = 0; i < 3; i++) lstPrincipalesProveedores.add(new Principal_Proveedor__c());
            }
            System.debug('Proveedores principales ' + lstPrincipalesProveedores);

            List<Participante__c> RepresentantesLegales = [
                SELECT Name, VFS_FirmanteConozcaCliente__c, PAR_Cargo__c, VFS_FirmanteAutorizado__c, PAR_Cliente__c, Cargo__c,
                       Participante__r.Lugar_de_nacimiento_Padron_Electoral__c, Participante__r.ACC_NumIdentificacion__c, Participante__r.Name,
                       PAR_Porcentaje__c, PAR_Numero_Identificacion__c
                FROM Participante__c
                WHERE PAR_Cliente__c = :Accountid
                ORDER BY PAR_Porcentaje__c DESC
            ];

            if (!RepresentantesLegales.isEmpty()) {
                for (Participante__c rep : RepresentantesLegales) {
                    if (rep.VFS_FirmanteConozcaCliente__c == true) {
                        lstParticipantes.add(rep);
                    }
                }

                if (!isPdf) {
                    while (lstParticipantes.size() < 12) lstParticipantes.add(new Participante__c());
                }
            } else if (!isPdf) {
                for (Integer i = 0; i < 12; i++) lstParticipantes.add(new Participante__c());
            }
            System.debug('RepresentantesLegales ' + lstParticipantes);

            Set<Id> accountIds = new Set<Id>();
            for (Participante__c p : RepresentantesLegales) {
                if (p.Participante__c != null) accountIds.add(p.Participante__c);
            }

            Map<Id, List<Vias_de_Contacto__c>> viasPorAccount = new Map<Id, List<Vias_de_Contacto__c>>();
            if (!accountIds.isEmpty()) {
                for (Vias_de_Contacto__c v : [
                    SELECT VIA_Account__c, VIA_de_Contacto__c, VIA_Numero_Correo__c
                    FROM Vias_de_Contacto__c
                    WHERE VIA_Account__c IN :accountIds
                ]) {
                    if (!viasPorAccount.containsKey(v.VIA_Account__c)) {
                        viasPorAccount.put(v.VIA_Account__c, new List<Vias_de_Contacto__c>());
                    }
                    viasPorAccount.get(v.VIA_Account__c).add(v);
                }
            }

            for (Participante__c p : RepresentantesLegales) {
                String telefono = '';
                String correo = '';

                if (viasPorAccount.containsKey(p.Participante__c)) {
                    for (Vias_de_Contacto__c v : viasPorAccount.get(p.Participante__c)) {
                        if (v.VIA_de_Contacto__c == 'TELÉFONO FIJO' && telefono == '') telefono = v.VIA_Numero_Correo__c;
                        if (v.VIA_de_Contacto__c == 'CORREO ELECTRÓNICO' && correo == '') correo = v.VIA_Numero_Correo__c;
                    }
                }

                if (p.PAR_Cargo__c == 'Representante legal') {
                    lstRepVias.add(new VFS_KYCWrapperRepVias(
                        p.Participante__r.Name,
                        p.Participante__r.ACC_NumIdentificacion__c,
                        telefono,
                        correo
                    ));
                }

                if (p.VFS_FirmanteAutorizado__c) {
                    lstAutorizados.add(new VFS_KYCWrapperRepVias(
                        p.Participante__r.Name,
                        p.Participante__r.ACC_NumIdentificacion__c,
                        telefono,
                        correo
                    ));
                }
            }

            if (!isPdf) {
                while (lstRepVias.size() < 5) lstRepVias.add(new VFS_KYCWrapperRepVias('', '', '', ''));
                while (lstAutorizados.size() < 12) lstAutorizados.add(new VFS_KYCWrapperRepVias('', '', '', ''));
            }

            obtenerAccionistasMiembors(Accountid);

            List<Participante__c> Funcionarios = [
                SELECT Name, PAR_Cargo__c,
                       Participante__r.Lugar_de_nacimiento_Padron_Electoral__c,
                       Participante__r.ACC_NumIdentificacion__c,
                       Participante__r.Name,
                       PAR_Porcentaje__c,
                       PAR_Numero_Identificacion__c
                FROM Participante__c
                WHERE PAR_Cliente__c = :Accountid
                AND PAR_Cargo__c IN ('Funcionario')
                ORDER BY PAR_Porcentaje__c DESC
                LIMIT 5
            ];
            if (!Funcionarios.isEmpty()) {
                lstFuncionarios = Funcionarios;
                if (!isPdf) {
                    while (lstFuncionarios.size() < 8) lstFuncionarios.add(new Participante__c());
                }
            } else if (!isPdf) {
                for (Integer i = 0; i < 8; i++) lstFuncionarios.add(new Participante__c());
            }
            System.debug('Funcionarios ' + lstFuncionarios);

            List<Empresa_Filial__c> Filiales = [
                SELECT Name, RNC__c, Pais_donde_opera__c, Grupo_economico__c, Grupo_financiero__c
                FROM Empresa_Filial__c
                WHERE Cliente__c = :AccountId
                LIMIT 4
            ];
            if (!Filiales.isEmpty()) {
                lstEmpresasFiliales = Filiales;
                if (!isPdf) {
                    while (lstEmpresasFiliales.size() < 4) lstEmpresasFiliales.add(new Empresa_Filial__c());
                }
            } else if (!isPdf) {
                for (Integer i = 0; i < 4; i++) lstEmpresasFiliales.add(new Empresa_Filial__c());
            }
            System.debug('Empresas Filiales ' + lstEmpresasFiliales);

            List<Participante__c> Extranjeros = [
                SELECT Participante__r.Name, Participante__r.ACC_SSN_FATCA__c, Participante__r.ACC_N_Pasaporte_FATCA__c,
                       Participante__r.ACC_Nacionalidad_FATCA__c, Participante__r.ACC_Pais_Residencia_Legal__c
                FROM Participante__c
                WHERE PAR_Cliente__c = :accountId
                AND (Participante__r.ACC_Nacionalidad_FATCA__c = 'ESTADOS UNIDOS'
                     OR Participante__r.ACC_Pais_Residencia_Legal__c = 'ESTADOS UNIDOS')
                AND PAR_Cargo__c IN ('Accionista','Miembro')
            ];
            if (!Extranjeros.isEmpty()) {
                lstSociosExtranjeros = Extranjeros;
                if (!isPdf) {
                    while (lstSociosExtranjeros.size() < 4) lstSociosExtranjeros.add(new Participante__c());
                }
            } else if (!isPdf) {
                for (Integer i = 0; i < 4; i++) lstSociosExtranjeros.add(new Participante__c());
            }
            System.debug('Socios Extranjeros ' + lstSociosExtranjeros);
        }
    }

    public void obtenerAccionistasMiembors(String accountId) {
        List<Participante__c> Accionistas = [
            SELECT Name, PAR_Cargo__c, Cargo__c, Participante__c,
                   Participante__r.Lugar_de_nacimiento_Padron_Electoral__c, Participante__r.ACC_NumIdentificacion__c,
                   Participante__r.IsPersonAccount, Participante__r.ACC_RNC__c, Participante__r.ACC_Nacionalidad__c,
                   Participante__r.Name, Participante__r.ACC_Persona_PEP__c, Participante__r.ACC_Fecha_Decreto_PEP__c,
                   Participante__r.ACC_Institucion_Trabajo_PEP__c, PAR_Porcentaje__c, Participante__r.ACC_Puesto_Cargo_PEP__c,
                   PAR_Numero_Identificacion__c
            FROM Participante__c
            WHERE PAR_Cliente__c = :accountId
            AND PAR_Cargo__c IN ('Miembro', 'Accionista')
            ORDER BY PAR_Porcentaje__c DESC
            LIMIT 8
        ];

        Set<String> setIdsAccionistasMorales = new Set<String>();
        for (Participante__c oneParticipante : Accionistas) {
            if (oneParticipante.Participante__r.IsPersonAccount == false && oneParticipante.PAR_Cargo__c == 'Accionista') {
                setIdsAccionistasMorales.add(oneParticipante.Participante__c);
            }
        }

        List<Participante__c> lstRepresentantesDeAccionistas = new List<Participante__c>();
        if (!setIdsAccionistasMorales.isEmpty()) {
            lstRepresentantesDeAccionistas = [
                SELECT Name, Participante__c, Participante__r.Name, Participante__r.ACC_NumIdentificacion__c, PAR_Cliente__c
                FROM Participante__c
                WHERE PAR_Cliente__c IN :setIdsAccionistasMorales
                AND VFS_RepresentanteLegal__c = true
            ];
        }

        for (Participante__c oneParticipante : Accionistas) {
            if (oneParticipante.PAR_Cargo__c == 'Accionista') {
                oneParticipante.Participante__r.ACC_Ejecutivo__c = '';
                oneParticipante.Participante__r.ACC_N_Identificacion_Anterior__c = '';
                if (oneParticipante.Participante__r.IsPersonAccount == false) {
                    oneParticipante.Participante__r.ACC_NumIdentificacion__c = oneParticipante.Participante__r.ACC_RNC__c;
                    oneParticipante.Participante__r.Lugar_de_nacimiento_Padron_Electoral__c = oneParticipante.Participante__r.ACC_Nacionalidad__c;
                    for (Participante__c oneRepresentante : lstRepresentantesDeAccionistas) {
                        if (oneParticipante.Participante__c == oneRepresentante.PAR_Cliente__c) {
                            oneParticipante.Participante__r.ACC_Ejecutivo__c = oneRepresentante.Participante__r.Name;
                            oneParticipante.Participante__r.ACC_N_Identificacion_Anterior__c = oneRepresentante.Participante__r.ACC_NumIdentificacion__c;
                        }
                    }
                }
                lstAccionistas.add(oneParticipante);
            } else if (oneParticipante.PAR_Cargo__c == 'Miembro') {
                lstMiembros.add(oneParticipante);
            }
        }

        while (lstAccionistas.size() < 8) lstAccionistas.add(new Participante__c());
        System.debug('Accionistas ' + lstAccionistas);

        while (lstMiembros.size() < 8) lstMiembros.add(new Participante__c());
        System.debug('Accionistas ' + lstMiembros);

        for (Participante__c acc : Accionistas) {
            if (acc.Participante__r.ACC_Persona_PEP__c == 'SI' || acc.Participante__r.ACC_Persona_PEP__c == 'VÍNCULO/PARENTESCO') {
                ParticipantePEP = acc;
                break;
            } else {
                ParticipantePEP = new Participante__c();
            }
        }
    }

    public String formatearDireccion(Direccion__c dir) {
        if (dir == null) return '';

        List<String> partes = new List<String>();
        if (!String.isBlank(dir.DIR_Calle__c)) {
            String calle = 'Calle ' + dir.DIR_Calle__c;
            if (!String.isBlank(dir.DIR_Numero__c)) calle += ' No. ' + dir.DIR_Numero__c;
            partes.add(calle);
        } else if (!String.isBlank(dir.DIR_Numero__c)) {
            partes.add('No. ' + dir.DIR_Numero__c);
        }
        if (!String.isBlank(dir.DIR_Edificio__c)) partes.add('Edif. ' + dir.DIR_Edificio__c);
        if (!String.isBlank(dir.DIR_N_Apartamento__c)) partes.add('Apt. ' + dir.DIR_N_Apartamento__c);
        return String.join(partes, ', ');
    }
}