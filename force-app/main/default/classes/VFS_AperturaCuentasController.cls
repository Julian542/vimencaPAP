/*********************************************************************************************
 * Nombre de clase Apex   :   VFS_AperturaCuentasController
 * Versión                :   1.0
 * Fecha de creación      :   27/06/2025
 * Función                :   Controlador Apex para la gestión de apertura de cuentas, manejo de datos de titulares y firmas conjuntas, y obtención de información relacionada.
 * Clase Test             :   VFS_AperturaCuentasTest
 *
 * Registro de modificaciones:
 * ---------------------------------------------------------------------------------------------------
 * Desarrollador                        Fecha           Descripción
 * Edgar                              27/06/2025        Versión original
 * Carlos Bolívar                     16/07/2025      Se modifica la clase para obtener información adicional como el tipo de firma, firmantes autorizados y el verificado por.
 *********************************************************************************************/

public with sharing class VFS_AperturaCuentasController {
    public Boolean isFisica { get; set; }
    public Account accountTitular { get; set; }
    public List<Account> lstAccountFirmaConjunta { get; set; }
    public String tipoFirma { get; set; }   // Tipo de firma (Conjunta Y, Conjunta O, Por poder, etc.)
    public List<Account> lstFirmantesAutorizados {get;set;}  // Lista de firmantes autorizados para el formulario de apertura de cuenta persona juridica
    public String verificadoPor {get;set;} //Nombre de la persona que verifica para colocar en la última sección del documento PDF
    public static INT026.Response testResponse;

    public VFS_AperturaCuentasController(ApexPages.StandardController stdController) {
        Id assetId = stdController.getId();
        Asset asset = [SELECT Id, AccountId, Account.PersonContactId, OwnerId FROM Asset WHERE Id = :assetId LIMIT 1];
        accountTitular = asset != null && asset.AccountId != null ? [SELECT Id, Name, PersonContactId, ACC_NumIdentificacion__c, ACC_TipoIdentificacion__c FROM Account WHERE Id = :asset.AccountId LIMIT 1] : null;
        isFisica = asset != null && asset.Account != null && asset.Account.PersonContactId != null;
        lstAccountFirmaConjunta = new List<Account>(); // Inicializar la lista

        User ownerUser = [SELECT USE_Codigo__c FROM User WHERE Id = :asset.OwnerId LIMIT 1];
        if (!String.isBlank(ownerUser.USE_Codigo__c)) {
            List<Datos_Maestros__c> lstDatosMaestro = [SELECT VFS_GerenteOficina__c, VFS_CorreoGerente__c FROM Datos_Maestros__c WHERE DM_Codigo_Oficina__c = :ownerUser.USE_Codigo__c LIMIT 1];
            verificadoPor = !lstDatosMaestro.isEmpty() ? lstDatosMaestro[0].VFS_GerenteOficina__c : '';
        } else {
            verificadoPor = '';
        }
    }

    public void consultarVinculadoAprobado() {
        Id assetId = null;
        try {
            assetId = ApexPages.currentPage().getParameters().get('id');
        } catch (Exception e) {}
        if (assetId == null) {
            lstAccountFirmaConjunta.clear(); // Limpiar la lista
            return;
        }
        obtenerFirmantesAutorizados(assetId);
    }

    public void obtenerFirmantesAutorizados(Id assetId){
        INT026.Response resp = Test.isRunningTest() && testResponse != null ? testResponse : INT026.consultVin(assetId);
        Set<String> lstNumerosDocumentos = new Set<String>();
        Set<String> nombresCompletos = new Set<String>();
        Set<String> numerosDocumentosAutorizados = new Set<String>();
        tipoFirma = null;
        lstAccountFirmaConjunta.clear(); // Limpiar la lista antes de llenarla
        
        // Primera pasada: recopilar todos los datos necesarios
        Map<String, String> documentoToVinculo = new Map<String, String>(); // Mapear número de documento a tipo de vínculo
        for (Map<String, Object> vinculado : resp.responseList) {
            String vinculo = String.valueOf(vinculado.get('Vinculo'));
            String numeroDocumento = String.valueOf(vinculado.get('NumeroDocumento'));
            String nombreCompleto = String.valueOf(vinculado.get('NombreCompleto'));
            
            // Guardar el vínculo para cada número de documento
            if (!String.isBlank(numeroDocumento)) {
                documentoToVinculo.put(numeroDocumento, vinculo);
            }
            
            if (vinculo.equalsIgnoreCase('AUTORIZADO')) {
                if (!String.isBlank(nombreCompleto)) nombresCompletos.add(nombreCompleto);
                if (!String.isBlank(numeroDocumento)) numerosDocumentosAutorizados.add(numeroDocumento);
            }
            if (String.valueOf(vinculado.get('DarGarantia')).equalsIgnoreCase('Y')) {
                tipoFirma = 'Conjunta Y';
                // Solo agregar el número de documento si no es del titular
                if (!String.isBlank(numeroDocumento)) {
                    // Verificar que el número de documento no sea del titular
                    if (accountTitular == null || accountTitular.ACC_NumIdentificacion__c != numeroDocumento) {
                        lstNumerosDocumentos.add(numeroDocumento);
                    }
                }
            }
            if (vinculo.equalsIgnoreCase('APODERADO')) tipoFirma = 'Por poder';
        }
        
        // Realizar una sola consulta para todos los accounts autorizados
        if (!nombresCompletos.isEmpty() || !numerosDocumentosAutorizados.isEmpty()) {
            List<String> whereConditions = new List<String>();
            if (!nombresCompletos.isEmpty()) {
                whereConditions.add('Name IN :nombresCompletos');
            }
            if (!numerosDocumentosAutorizados.isEmpty()) {
                whereConditions.add('ACC_NumIdentificacion__c IN :numerosDocumentosAutorizados');
            }
            
            String query = 'SELECT Id, Name, PersonBirthdate, ACC_Nacionalidad__c, ACC_Genero__c, ACC_NumIdentificacion__c,ACC_TipoIdentificacion__c FROM Account WHERE (' + String.join(whereConditions, ' OR ') + ')';
            List<Account> allAuthorizedAccounts = Database.query(query);
            
            // Filtrar y agregar solo los que no sean el titular
            for (Account acc : allAuthorizedAccounts) {
                if (accountTitular != null && acc.Id != accountTitular.Id) {
                    // Asignar el tipo de vínculo al campo ACC_Ejecutivo__c basado en el número de identificación
                    if (!String.isBlank(acc.ACC_NumIdentificacion__c) && documentoToVinculo.containsKey(acc.ACC_NumIdentificacion__c)) {
                        String vinculo = documentoToVinculo.get(acc.ACC_NumIdentificacion__c);
                        acc.ACC_Ejecutivo__c = vinculo.equalsIgnoreCase('AUTORIZADO') ? 'Autorizado' : vinculo;
                    }
                    lstAccountFirmaConjunta.add(acc);
                }
            }
        }
        
        if (String.isBlank(tipoFirma)) tipoFirma = 'Titular unico';
        if (!lstNumerosDocumentos.isEmpty()) {
            lstFirmantesAutorizados = [SELECT Id, Name, PersonBirthdate, ACC_TipoIdentificacion__c, ACC_Nacionalidad__c, ACC_Genero__c, ACC_NumIdentificacion__c, ACC_Correo_Electronico_Cliente__c, Phone, (SELECT VIA_Numero_Correo__c, VIA_de_Contacto__c,createdDate, VIA_Principal__c FROM Vias_de_Contacto__r) FROM Account WHERE ACC_NumIdentificacion__c IN :lstNumerosDocumentos LIMIT 12];
            for (Account firmante : lstFirmantesAutorizados) {
                // Asignar el tipo de vínculo al campo ACC_Ejecutivo__c basado en el número de identificación
                if (!String.isBlank(firmante.ACC_NumIdentificacion__c) && documentoToVinculo.containsKey(firmante.ACC_NumIdentificacion__c)) {
                    String vinculo = documentoToVinculo.get(firmante.ACC_NumIdentificacion__c);
                    firmante.ACC_Ejecutivo__c = vinculo.equalsIgnoreCase('AUTORIZADO') ? 'Autorizado' : vinculo;
                }
                asignarViasDeContactoAFirmante(firmante);
            }
            while (lstFirmantesAutorizados.size() < 12) lstFirmantesAutorizados.add(new Account());
        }
    }

    private void asignarViasDeContactoAFirmante(Account firmante) {
        String correoElectronico = '';
        String telefono = '';
        Boolean correoPrincipal = false;
        Boolean telefonoPrincipal = false;
        for (Vias_de_Contacto__c via : firmante.Vias_de_Contacto__r) {
            if (via.VIA_de_Contacto__c == 'CORREO ELECTRÓNICO') {
                if (via.VIA_Principal__c) {
                    correoElectronico = via.VIA_Numero_Correo__c;
                    correoPrincipal = true;
                } else if (!correoPrincipal && String.isBlank(correoElectronico)) {
                    correoElectronico = via.VIA_Numero_Correo__c;
                }
            } else if (via.VIA_de_Contacto__c != null && via.VIA_de_Contacto__c.contains('TELÉFONO')) {
                if (via.VIA_Principal__c) {
                    telefono = via.VIA_Numero_Correo__c;
                    telefonoPrincipal = true;
                } else if (!telefonoPrincipal && String.isBlank(telefono)) {
                    telefono = via.VIA_Numero_Correo__c;
                }
            }
        }
        firmante.ACC_Correo_Electronico_Cliente__c = agregarEspacioCada10Caracteres(correoElectronico);
        firmante.Phone = telefono;
    }

    private Direccion__c obtenerDireccion(Account acc, String tipoDireccion) {
        if (acc == null) return null;
        List<Direccion__c> direcciones = [
            SELECT DIR_Tipo_Direccion__c, DIR_Account__c, DIR_Calle__c, DIR_Numero__c, DIR_Edificio__c, DIR_N_Apartamento__c, DIR_Sector__c, DIR_Sector__r.Name, DIR_Provincia_texto__c
            FROM Direccion__c
            WHERE DIR_Account__c = :acc.Id AND DIR_Tipo_Direccion__c = :tipoDireccion
            LIMIT 1
        ];
        return direcciones.isEmpty() ? null : direcciones[0];
    }

    public String getDireccionesTitular() {
        Direccion__c dir = obtenerDireccion(accountTitular, 'RESIDENCIA');
        return formatearDireccion(dir);
    }
    public String getDireccionesFirmaConjunta() {
        // Método para retrocompatibilidad - devuelve la primera firma conjunta
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
        // Método para retrocompatibilidad - devuelve la primera firma conjunta
        return getViasOrdenadasFirmaConjunta(0);
    }
    
    public List<String> getViasOrdenadasFirmaConjunta(Integer index) {
        if (lstAccountFirmaConjunta == null || lstAccountFirmaConjunta.size() <= index || index < 0) {
            return new List<String>{' ', ' ', ' ', ' '}; // Retornar lista vacía con espacios
        }
        return cargarViasDeContacto(lstAccountFirmaConjunta[index]);
    }
    
    public Historial_laboral__c getHistorialLaboralFirmaConjunta() {
        // Método para retrocompatibilidad - devuelve la primera firma conjunta
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
    
    // Métodos específicos para obtener información de firma conjunta por índice
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
    
    // Métodos específicos para la segunda firma conjunta (índice 1)
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
        List<String> ordenVias = new List<String>{
            'TELÉFONO FIJO',
            'TELÉFONO TRABAJO',
            'TELÉFONO MÓVIL',
            'CORREO ELECTRÓNICO'
        };
        List<String> viasOrdenadas = new List<String>();
        if (acc != null) {
            List<Vias_de_Contacto__c> vias = [
                SELECT VIA_de_Contacto__c, VIA_Numero_Correo__c, VIA_Principal__c
                FROM Vias_de_Contacto__c
                WHERE VIA_Account__c = :acc.Id
                    AND VIA_de_Contacto__c IN :ordenVias
                ORDER BY VIA_Principal__c DESC, CreatedDate DESC
            ];
            // Agrupar por tipo
            Map<String, List<Vias_de_Contacto__c>> viasPorTipo = new Map<String, List<Vias_de_Contacto__c>>();
            for (String tipo : ordenVias) {
                viasPorTipo.put(tipo, new List<Vias_de_Contacto__c>());
            }
            for (Vias_de_Contacto__c via : vias) {
                if (viasPorTipo.containsKey(via.VIA_de_Contacto__c)) {
                    viasPorTipo.get(via.VIA_de_Contacto__c).add(via);
                }
            }
            for (String tipo : ordenVias) {
                if (tipo == 'TELÉFONO TRABAJO') {
                    List<Vias_de_Contacto__c> viasOficina = viasPorTipo.get(tipo);
                    if (isFisica) {
                        // Persona física: solo mostrar el principal o el primero disponible
                        String telefonoTrabajo = ' ';
                        for (Vias_de_Contacto__c via : viasOficina) {
                            if (via.VIA_Principal__c && !String.isBlank(via.VIA_Numero_Correo__c)) {
                                telefonoTrabajo = via.VIA_Numero_Correo__c;
                                break;
                            }
                        }
                        if (telefonoTrabajo == ' ' && !viasOficina.isEmpty()) {
                            for (Vias_de_Contacto__c via : viasOficina) {
                                if (!String.isBlank(via.VIA_Numero_Correo__c)) {
                                    telefonoTrabajo = via.VIA_Numero_Correo__c;
                                    break;
                                }
                            }
                        }
                        viasOrdenadas.add(telefonoTrabajo);
                    } else {
                        // No persona física: concatenar hasta 3 teléfonos de oficina, priorizando los principales
                        List<String> telefonosOficina = new List<String>();
                        Integer count = 0;
                        for (Vias_de_Contacto__c via : viasOficina) {
                            if (via.VIA_Principal__c && !String.isBlank(via.VIA_Numero_Correo__c)) {
                                telefonosOficina.add(via.VIA_Numero_Correo__c);
                                count++;
                                if (count == 3) break;
                            }
                        }
                        if (count < 3) {
                            for (Vias_de_Contacto__c via : viasOficina) {
                                if (!via.VIA_Principal__c && !String.isBlank(via.VIA_Numero_Correo__c) && !telefonosOficina.contains(via.VIA_Numero_Correo__c)) {
                                    telefonosOficina.add(via.VIA_Numero_Correo__c);
                                    count++;
                                    if (count == 3) break;
                                }
                            }
                        }
                        viasOrdenadas.add(telefonosOficina.isEmpty() ? ' ' : String.join(telefonosOficina, ', '));
                    }
                } else {
                    // Para los demás tipos, solo uno, priorizando el principal
                    List<Vias_de_Contacto__c> viasTipo = viasPorTipo.get(tipo);
                    String valor = ' ';
                    for (Vias_de_Contacto__c via : viasTipo) {
                        if (via.VIA_Principal__c && !String.isBlank(via.VIA_Numero_Correo__c)) {
                            valor = via.VIA_Numero_Correo__c;
                            break;
                        }
                    }
                    if (valor == ' ' && !viasTipo.isEmpty()) {
                        for (Vias_de_Contacto__c via : viasTipo) {
                            if (!String.isBlank(via.VIA_Numero_Correo__c)) {
                                valor = via.VIA_Numero_Correo__c;
                                break;
                            }
                        }
                    }
                    viasOrdenadas.add(valor);
                }
            }
        } else {
            for (Integer i = 0; i < ordenVias.size(); i++) {
                viasOrdenadas.add(' ');
            }
        }
        return viasOrdenadas;
    }

    private Historial_laboral__c cargarHistorialLaboral(Account acc) {
        List<Historial_laboral__c> historial = new List<Historial_laboral__c>();
        if (acc != null) {
             historial = [
                SELECT HIS_Empresa__c, Tiempo_de_empresa__c
                FROM Historial_laboral__c
                WHERE HIS_Empleo__c = 'Actual' AND HIS_Cuenta__c = :acc.Id
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
                SELECT Id, REF_Tipo__c, Tipo_de_cuenta__c, Name, Banco__c, N_de_cuenta__c, REF_Telefono__c,REF_Nombre__c
                FROM Referencia__c
                WHERE Account__c = :acc.Id AND REF_Tipo__c = :tipo LIMIT 3
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
    
    // Función para agregar un espacio cada 10 caracteres
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
}