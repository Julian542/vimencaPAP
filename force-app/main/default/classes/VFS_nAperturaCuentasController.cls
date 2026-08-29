public with sharing class VFS_nAperturaCuentasController {
    public Boolean isFisica { get; set; }
    public Account accountTitular { get; set; }
    public List<Account> lstAccountFirmaConjunta { get; set; }
    public String tipoFirma { get; set; }
    public List<Account> lstFirmantesAutorizados { get; set; }
    public String verificadoPor { get; set; }
    public FinServ__FinancialAccount__c financialAccount { get; set; }

    public String getInstruccionesEspeciales() {
        return financialAccount != null ? financialAccount.FIN_InstruccionesEspeciales__c : '';
    }

    public String getUnidadNegocioNumeroCuenta() {
        if (financialAccount == null) {
            return '';
        }

        if (String.isNotBlank(financialAccount.Name)) {
            return financialAccount.Name;
        }

        return financialAccount.FIN_N_de_cuenta__c;
    }

    public String getUnidadNegocioNumeroCliente() {
        if (financialAccount != null &&
            financialAccount.FinServ__PrimaryOwner__r != null) {
            return financialAccount.FinServ__PrimaryOwner__r.ACC_CIF__c;
        }
        return '';
    }

    public String getUnidadNegocioTasa() {
        if (financialAccount != null &&
            financialAccount.FIN_Producto__r != null &&
            financialAccount.FIN_Producto__r.PRO_Tasas__c != null) {
            return String.valueOf(financialAccount.FIN_Producto__r.PRO_Tasas__c);
        }
        return '';
    }

    public String getUnidadNegocioCodigoOficial() {
        if (financialAccount != null &&
            financialAccount.FinServ__PrimaryOwner__r != null &&
            financialAccount.FinServ__PrimaryOwner__r.Owner != null) {
            return financialAccount.FinServ__PrimaryOwner__r.Owner.Alias;
        }
        return '';
    }

    public String getUnidadNegocioElaboradoPor() {
        if (financialAccount != null &&
            financialAccount.FinServ__PrimaryOwner__r != null &&
            financialAccount.FinServ__PrimaryOwner__r.LastModifiedBy != null) {
            return financialAccount.FinServ__PrimaryOwner__r.LastModifiedBy.Name;
        }
        return '';
    }

    public String getUnidadNegocioVerificadoPor() {
        if (String.isNotBlank(verificadoPor)) {
            return verificadoPor;
        }

        if (financialAccount != null &&
            financialAccount.FinServ__PrimaryOwner__r != null &&
            financialAccount.FinServ__PrimaryOwner__r.Owner != null) {
            return financialAccount.FinServ__PrimaryOwner__r.Owner.Name;
        }

        return '';
    }

    public static INT026_FSC.Response testResponse;

    public VFS_nAperturaCuentasController(ApexPages.StandardController stdController) {
        Id financialAccountId = stdController.getId();

        financialAccount = [
            SELECT Id,
                   Name,
                   OwnerId,
                   FinServ__PrimaryOwner__c,
                   FinServ__PrimaryOwner__r.Id,
                   FinServ__PrimaryOwner__r.Name,
                   FinServ__PrimaryOwner__r.PersonContactId,
                   FinServ__PrimaryOwner__r.ACC_NumIdentificacion__c,
                   FinServ__PrimaryOwner__r.ACC_TipoIdentificacion__c,
                   FinServ__PrimaryOwner__r.ACC_NumOficina__c,
                   FinServ__PrimaryOwner__r.ACC_CIF__c,
                   FinServ__PrimaryOwner__r.Owner.Name,
                   FinServ__PrimaryOwner__r.Owner.Alias,
                   FinServ__PrimaryOwner__r.LastModifiedBy.Name,
                   FIN_InstruccionesEspeciales__c,
                   FIN_Linea_de_producto__c,
                   FIN_Moneda__c,
                   FIN_N_de_cuenta__c,
                   FIN_Producto__r.PRO_Tasas__c
            FROM FinServ__FinancialAccount__c
            WHERE Id = :financialAccountId
            LIMIT 1
        ];

        accountTitular = financialAccount != null && financialAccount.FinServ__PrimaryOwner__c != null
            ? [
                SELECT Id,
                       Name,
                       PersonContactId,
                       ACC_NumIdentificacion__c,
                       ACC_TipoIdentificacion__c,
                       ACC_NumOficina__c
                FROM Account
                WHERE Id = :financialAccount.FinServ__PrimaryOwner__c
                LIMIT 1
            ]
            : null;

        isFisica = accountTitular != null && accountTitular.PersonContactId != null;
        lstAccountFirmaConjunta = new List<Account>();
        lstFirmantesAutorizados = new List<Account>();

        if (financialAccount != null && financialAccount.OwnerId != null) {
            User ownerUser = [
                SELECT USE_Codigo__c
                FROM User
                WHERE Id = :financialAccount.OwnerId
                LIMIT 1
            ];

            if (String.isNotBlank(ownerUser.USE_Codigo__c)) {
                List<Datos_Maestros__c> lstDatosMaestro = [
                    SELECT VFS_GerenteOficina__c, VFS_CorreoGerente__c
                    FROM Datos_Maestros__c
                    WHERE DM_Codigo_Oficina__c = :ownerUser.USE_Codigo__c
                    LIMIT 1
                ];
                verificadoPor = !lstDatosMaestro.isEmpty() ? lstDatosMaestro[0].VFS_GerenteOficina__c : '';
            } else {
                verificadoPor = '';
            }
        } else {
            verificadoPor = '';
        }
    }

    public void consultarVinculadoAprobado() {
        Id financialAccountId = null;
        try {
            financialAccountId = ApexPages.currentPage().getParameters().get('id');
        } catch (Exception e) {
        }

        if (financialAccountId == null) {
            lstAccountFirmaConjunta.clear();
            lstFirmantesAutorizados.clear();
            return;
        }

        obtenerFirmantesAutorizados(financialAccountId);
    }

    public void obtenerFirmantesAutorizados(Id financialAccountId) {
        INT026_FSC.Response resp = Test.isRunningTest() && testResponse != null
            ? testResponse
            : INT026_FSC.consultVin(financialAccountId);

        Set<String> lstNumerosDocumentos = new Set<String>();
        Set<String> nombresCompletos = new Set<String>();
        Set<String> numerosDocumentosAutorizados = new Set<String>();

        tipoFirma = null;
        lstAccountFirmaConjunta.clear();
        lstFirmantesAutorizados.clear();

        Map<String, String> documentoToVinculo = new Map<String, String>();

        for (Map<String, Object> vinculado : resp.responseList) {
            String vinculo = String.valueOf(vinculado.get('Vinculo'));
            String numeroDocumento = String.valueOf(vinculado.get('NumeroDocumento'));
            String nombreCompleto = String.valueOf(vinculado.get('NombreCompleto'));

            if (!String.isBlank(numeroDocumento)) {
                documentoToVinculo.put(numeroDocumento, vinculo);
            }

            if (vinculo.equalsIgnoreCase('AUTORIZADO')) {
                if (!String.isBlank(nombreCompleto)) {
                    nombresCompletos.add(nombreCompleto);
                }
                if (!String.isBlank(numeroDocumento)) {
                    numerosDocumentosAutorizados.add(numeroDocumento);
                }
            }

            if (String.valueOf(vinculado.get('DarGarantia')).equalsIgnoreCase('Y')) {
                tipoFirma = 'Conjunta Y';
                if (!String.isBlank(numeroDocumento)) {
                    if (accountTitular == null || accountTitular.ACC_NumIdentificacion__c != numeroDocumento) {
                        lstNumerosDocumentos.add(numeroDocumento);
                    }
                }
            }

            if (vinculo.equalsIgnoreCase('APODERADO')) {
                tipoFirma = 'Por poder';
            }
        }

        if (!nombresCompletos.isEmpty() || !numerosDocumentosAutorizados.isEmpty()) {
            List<String> whereConditions = new List<String>();

            if (!nombresCompletos.isEmpty()) {
                whereConditions.add('Name IN :nombresCompletos');
            }
            if (!numerosDocumentosAutorizados.isEmpty()) {
                whereConditions.add('ACC_NumIdentificacion__c IN :numerosDocumentosAutorizados');
            }

            String query =
                'SELECT Id, Name, PersonContactId, PersonBirthdate, ACC_Nacionalidad__c, ACC_Genero__c, ACC_NumIdentificacion__c, ACC_TipoIdentificacion__c ' +
                'FROM Account WHERE (' + String.join(whereConditions, ' OR ') + ')';

            List<Account> allAuthorizedAccounts = Database.query(query);

            for (Account acc : allAuthorizedAccounts) {
                if (accountTitular != null && acc.Id != accountTitular.Id) {
                    if (!String.isBlank(acc.ACC_NumIdentificacion__c) && documentoToVinculo.containsKey(acc.ACC_NumIdentificacion__c)) {
                        String vinculo = documentoToVinculo.get(acc.ACC_NumIdentificacion__c);
                        acc.ACC_Ejecutivo__c = vinculo.equalsIgnoreCase('AUTORIZADO') ? 'Autorizado' : vinculo;
                    }
                    lstAccountFirmaConjunta.add(acc);
                }
            }
        }

        if (String.isBlank(tipoFirma)) {
            tipoFirma = 'Titular unico';
        }

        if (!lstNumerosDocumentos.isEmpty()) {
            lstFirmantesAutorizados = [
                SELECT Id,
                       Name,
                       PersonContactId,
                       PersonBirthdate,
                       ACC_TipoIdentificacion__c,
                       ACC_Nacionalidad__c,
                       ACC_Genero__c,
                       ACC_NumIdentificacion__c,
                       ACC_Correo_Electronico_Cliente__c,
                       Phone
                FROM Account
                WHERE ACC_NumIdentificacion__c IN :lstNumerosDocumentos
                LIMIT 12
            ];

            for (Account firmante : lstFirmantesAutorizados) {
                if (!String.isBlank(firmante.ACC_NumIdentificacion__c) && documentoToVinculo.containsKey(firmante.ACC_NumIdentificacion__c)) {
                    String vinculo = documentoToVinculo.get(firmante.ACC_NumIdentificacion__c);
                    firmante.ACC_Ejecutivo__c = vinculo.equalsIgnoreCase('AUTORIZADO') ? 'Autorizado' : vinculo;
                }
                asignarContactPointsAFirmante(firmante);
            }

            while (lstFirmantesAutorizados.size() < 12) {
                lstFirmantesAutorizados.add(new Account());
            }
        }
    }

    private void asignarContactPointsAFirmante(Account firmante) {
        String correoElectronico = obtenerCorreoPrincipal(firmante);
        String telefonoPrincipal = obtenerTelefonoPrincipal(firmante);

        firmante.ACC_Correo_Electronico_Cliente__c = agregarEspacioCada10Caracteres(correoElectronico);
        firmante.Phone = telefonoPrincipal;
    }

    private Direccion__c obtenerDireccion(Account acc, String tipoDireccion) {
        if (acc == null) {
            return null;
        }

        List<Direccion__c> direcciones = [
            SELECT DIR_Tipo_Direccion__c,
                   DIR_Account__c,
                   DIR_Calle__c,
                   DIR_Numero__c,
                   DIR_Edificio__c,
                   DIR_N_Apartamento__c,
                   DIR_Sector__c,
                   DIR_Sector__r.Name,
                   DIR_Provincia_texto__c
            FROM Direccion__c
            WHERE DIR_Account__c = :acc.Id
              AND DIR_Tipo_Direccion__c = :tipoDireccion
            LIMIT 1
        ];

        return direcciones.isEmpty() ? null : direcciones[0];
    }

    public String getDireccionesTitular() {
        Direccion__c dir = obtenerDireccion(accountTitular, 'RESIDENCIA');
        return formatearDireccion(dir);
    }

    public String getDireccionesFirmaConjunta() {
        return getDireccionesFirmaConjunta(0);
    }

    public String getDireccionesFirmaConjunta(Integer index) {
        if (lstAccountFirmaConjunta == null || lstAccountFirmaConjunta.size() <= index || index < 0) {
            return '';
        }
        Direccion__c dir = obtenerDireccion(lstAccountFirmaConjunta[index], 'LABORAL');
        return formatearDireccion(dir);
    }

    public String getDireccionesJuridica() {
        Direccion__c dir = obtenerDireccion(accountTitular, 'EMPRESARIAL');
        return formatearDireccion(dir);
    }

    public String formatearDireccion(Direccion__c dir) {
        if (dir == null) {
            return '';
        }

        List<String> partes = new List<String>();

        if (!String.isBlank(dir.DIR_Calle__c)) {
            String calle = 'Calle ' + dir.DIR_Calle__c;
            if (!String.isBlank(dir.DIR_Numero__c)) {
                calle += ' No. ' + dir.DIR_Numero__c;
            }
            partes.add(calle);
        } else if (!String.isBlank(dir.DIR_Numero__c)) {
            partes.add('No. ' + dir.DIR_Numero__c);
        }

        if (!String.isBlank(dir.DIR_Edificio__c)) {
            partes.add('Edif. ' + dir.DIR_Edificio__c);
        }
        if (!String.isBlank(dir.DIR_N_Apartamento__c)) {
            partes.add('Apt. ' + dir.DIR_N_Apartamento__c);
        }
        if (dir.DIR_Sector__r != null && !String.isBlank(dir.DIR_Sector__r.Name)) {
            partes.add(dir.DIR_Sector__r.Name);
        }
        if (!String.isBlank(dir.DIR_Provincia_texto__c)) {
            partes.add(dir.DIR_Provincia_texto__c);
        }

        return String.join(partes, ', ');
    }

    public List<String> getViasOrdenadasTitular() {
        return cargarViasDeContacto(accountTitular);
    }

    public List<String> getViasOrdenadasFirmaConjunta() {
        return getViasOrdenadasFirmaConjunta(0);
    }

    public List<String> getViasOrdenadasFirmaConjunta(Integer index) {
        if (lstAccountFirmaConjunta == null || lstAccountFirmaConjunta.size() <= index || index < 0) {
            return new List<String>{ ' ', ' ', ' ', ' ' };
        }
        return cargarViasDeContacto(lstAccountFirmaConjunta[index]);
    }

    public Historial_laboral__c getHistorialLaboralFirmaConjunta() {
        return getHistorialLaboralFirmaConjunta(0);
    }

    public Historial_laboral__c getHistorialLaboralFirmaConjunta(Integer index) {
        if (lstAccountFirmaConjunta == null || lstAccountFirmaConjunta.size() <= index || index < 0) {
            return null;
        }
        return cargarHistorialLaboral(lstAccountFirmaConjunta[index]);
    }

    public Historial_laboral__c getHistorialLaboralTitular() {
        return cargarHistorialLaboral(accountTitular);
    }

    public Account getPrimeraFirmaConjunta() {
        if (lstAccountFirmaConjunta == null || lstAccountFirmaConjunta.size() <= 0) {
            return null;
        }
        return lstAccountFirmaConjunta[0];
    }

    public Account getSegundaFirmaConjunta() {
        if (lstAccountFirmaConjunta == null || lstAccountFirmaConjunta.size() <= 1) {
            return null;
        }
        return lstAccountFirmaConjunta[1];
    }

    public List<String> getViasOrdenadasSegundaFirmaConjunta() {
        return getViasOrdenadasFirmaConjunta(1);
    }

    public Historial_laboral__c getHistorialLaboralSegundaFirmaConjunta() {
        return getHistorialLaboralFirmaConjunta(1);
    }

    public String getDireccionesSegundaFirmaConjunta() {
        return getDireccionesFirmaConjunta(1);
    }

    public List<Referencia__c> getLstReferenciasBancarias() {
        return cargarReferencias(accountTitular, 'Bancaria');
    }

    public List<Referencia__c> getLstReferenciasComerciales() {
        return cargarReferencias(accountTitular, 'Comercial');
    }

    private List<String> cargarViasDeContacto(Account acc) {
        List<String> viasOrdenadas = new List<String>{ ' ', ' ', ' ', ' ' };

        if (acc == null) {
            return viasOrdenadas;
        }

        List<ContactPointPhoneWrapper> phones = cargarTelefonos(acc);
        String email = obtenerCorreoPrincipal(acc);

        String telefonoFijo = ' ';
        String telefonoTrabajo = ' ';
        String telefonoMovil = ' ';

        List<String> workPhones = new List<String>();
        List<String> otrosTelefonos = new List<String>();

        for (ContactPointPhoneWrapper phoneWrap : phones) {
            String tipo = phoneWrap.tipo;
            String numero = phoneWrap.numero;

            if (String.isBlank(numero)) {
                continue;
            }

            if (tipo.contains('WORK') || tipo.contains('LABOR') || tipo.contains('OFIC')) {
                workPhones.add(numero);
            } else if (tipo.contains('MOBILE') || tipo.contains('MOVIL') || tipo.contains('CEL')) {
                if (telefonoMovil == ' ') {
                    telefonoMovil = numero;
                }
            } else if (tipo.contains('HOME') || tipo.contains('FIJO') || tipo.contains('RESID')) {
                if (telefonoFijo == ' ') {
                    telefonoFijo = numero;
                }
            } else {
                otrosTelefonos.add(numero);
            }
        }

        if (telefonoFijo == ' ' && !otrosTelefonos.isEmpty()) {
            telefonoFijo = otrosTelefonos.remove(0);
        }

        if (isFisica) {
            if (!workPhones.isEmpty()) {
                telefonoTrabajo = workPhones[0];
            } else if (!otrosTelefonos.isEmpty()) {
                telefonoTrabajo = otrosTelefonos.remove(0);
            }
        } else {
            if (!workPhones.isEmpty()) {
                List<String> temp = obtenerPrimerosTelefonos(workPhones, 3);
                telefonoTrabajo = String.join(temp, ', ');
            } else if (!otrosTelefonos.isEmpty()) {
                List<String> temp = obtenerPrimerosTelefonos(otrosTelefonos, 3);
                telefonoTrabajo = String.join(temp, ', ');
            }
        }

        if (telefonoMovil == ' ' && !otrosTelefonos.isEmpty()) {
            telefonoMovil = otrosTelefonos.remove(0);
        }

        viasOrdenadas[0] = telefonoFijo;
        viasOrdenadas[1] = telefonoTrabajo;
        viasOrdenadas[2] = telefonoMovil;
        viasOrdenadas[3] = String.isBlank(email) ? ' ' : email;

        return viasOrdenadas;
    }

    private Historial_laboral__c cargarHistorialLaboral(Account acc) {
        List<Historial_laboral__c> historial = new List<Historial_laboral__c>();
        if (acc != null) {
            historial = [
                SELECT HIS_Empresa__c, Tiempo_de_empresa__c
                FROM Historial_laboral__c
                WHERE HIS_Empleo__c = 'Actual'
                  AND HIS_Cuenta__c = :acc.Id
                LIMIT 1
            ];
            if (historial != null && !historial.isEmpty()) {
                return historial[0];
            }
        }
        return null;
    }

    private List<Referencia__c> cargarReferencias(Account acc, String tipo) {
        List<Referencia__c> referencias = new List<Referencia__c>();
        if (acc != null) {
            List<Referencia__c> refList = [
                SELECT Id, REF_Tipo__c, Tipo_de_cuenta__c, Name, Banco__c, N_de_cuenta__c, REF_Telefono__c, REF_Nombre__c
                FROM Referencia__c
                WHERE Account__c = :acc.Id
                  AND REF_Tipo__c = :tipo
                LIMIT 3
            ];
            referencias.addAll(refList);
            while (referencias.size() < 3) {
                referencias.add(new Referencia__c());
            }
        } else {
            for (Integer i = 0; i < 3; i++) {
                referencias.add(new Referencia__c());
            }
        }
        return referencias;
    }

    private Set<Id> getParentIds(Account acc) {
        Set<Id> parentIds = new Set<Id>();
        if (acc != null) {
            parentIds.add(acc.Id);
            if (acc.PersonContactId != null) {
                parentIds.add(acc.PersonContactId);
            }
        }
        return parentIds;
    }

    private String obtenerCorreoPrincipal(Account acc) {
        if (acc == null) {
            return '';
        }

        Set<Id> parentIds = getParentIds(acc);

        List<ContactPointEmail> emails = [
            SELECT Id, ParentId, EmailAddress, IsPrimary, CreatedDate
            FROM ContactPointEmail
            WHERE ParentId IN :parentIds
              AND EmailAddress != null
            ORDER BY IsPrimary DESC, CreatedDate DESC
        ];

        for (ContactPointEmail email : emails) {
            if (email.IsPrimary && String.isNotBlank(email.EmailAddress)) {
                return email.EmailAddress;
            }
        }

        for (ContactPointEmail email : emails) {
            if (String.isNotBlank(email.EmailAddress)) {
                return email.EmailAddress;
            }
        }

        return '';
    }

    private String obtenerTelefonoPrincipal(Account acc) {
        List<ContactPointPhoneWrapper> phones = cargarTelefonos(acc);
        return phones.isEmpty() ? '' : phones[0].numero;
    }

    private List<ContactPointPhoneWrapper> cargarTelefonos(Account acc) {
        List<ContactPointPhoneWrapper> result = new List<ContactPointPhoneWrapper>();

        if (acc == null) {
            return result;
        }

        Set<Id> parentIds = getParentIds(acc);
        if (parentIds.isEmpty()) {
            return result;
        }

        Map<String, Schema.SObjectField> phoneFieldMap = Schema.SObjectType.ContactPointPhone.fields.getMap();

        String numberField = phoneFieldMap.containsKey('TelephoneNumber')
            ? 'TelephoneNumber'
            : (phoneFieldMap.containsKey('PhoneNumber') ? 'PhoneNumber' : null);

        if (numberField == null) {
            return result;
        }

        String typeField = null;
        if (phoneFieldMap.containsKey('TelephoneType')) {
            typeField = 'TelephoneType';
        } else if (phoneFieldMap.containsKey('PhoneType')) {
            typeField = 'PhoneType';
        } else if (phoneFieldMap.containsKey('UsageType')) {
            typeField = 'UsageType';
        }

        String soql =
            'SELECT Id, ParentId, IsPrimary, CreatedDate, ' + numberField +
            (typeField != null ? ', ' + typeField : '') +
            ' FROM ContactPointPhone WHERE ParentId IN :parentIds AND ' + numberField + ' != null' +
            ' ORDER BY IsPrimary DESC, CreatedDate DESC';

        for (SObject row : Database.query(soql)) {
            String numero = String.valueOf(row.get(numberField));
            String tipo = typeField != null && row.get(typeField) != null ? String.valueOf(row.get(typeField)).toUpperCase() : '';

            if (String.isNotBlank(numero)) {
                result.add(new ContactPointPhoneWrapper(numero, tipo));
            }
        }

        return result;
    }

    public class ContactPointPhoneWrapper {
        public String numero;
        public String tipo;

        public ContactPointPhoneWrapper(String numero, String tipo) {
            this.numero = numero;
            this.tipo = tipo == null ? '' : tipo;
        }
    }

    private String agregarEspacioCada10Caracteres(String texto) {
        if (String.isBlank(texto)) return texto;

        String resultado = '';
        Integer longitud = texto.length();

        for (Integer i = 0; i < longitud; i += 10) {
            Integer fin = Math.min(i + 10, longitud);
            resultado += texto.substring(i, fin);
            if (fin < longitud) resultado += ' ';
        }

        return resultado;
    }

    private static List<String> obtenerPrimerosTelefonos(List<String> telefonos, Integer maxCantidad) {
        List<String> resultado = new List<String>();

        if (telefonos == null || telefonos.isEmpty() || maxCantidad == null || maxCantidad <= 0) {
            return resultado;
        }

        Integer limite = telefonos.size() < maxCantidad ? telefonos.size() : maxCantidad;

        for (Integer i = 0; i < limite; i++) {
            resultado.add(telefonos[i]);
        }

        return resultado;
    }
}