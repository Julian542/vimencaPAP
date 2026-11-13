public without sharing class FSC_CapturaOperacionesService {
    @TestVisible private static Boolean testBypassPermissions = false;
    private static final String CAPTURA = 'Creación de crédito';
    private static final String OPERACIONES = 'Desembolso';
    private static final String PERMISO_ADMIN = 'FSC_CP_Administrador';
    private static final Set<String> FORMAS_MANUALES = new Set<String>{
        'Cheque de administracion', 'Cuenta de ahorro y Cheque de administración'
    };
    private static final Set<String> EXTENSIONES = new Set<String>{'pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png'};
    private static Map<String, List<User>> usuariosPorEtapa = new Map<String, List<User>>();

    public static Boolean esEtapaManual(ResidentialLoanApplication rla) {
        return !desembolsoApiExitoso(rla) && rla.Status == 'En proceso' && (FORMAS_MANUALES.contains(rla.FSC_FormaDeDesembolso__c) || FSC_ProcesamientoAbanks.esCuentaManual(rla)) &&
            (rla.FSC_Subestado__c == CAPTURA || rla.FSC_Subestado__c == OPERACIONES);
    }

    private static Boolean desembolsoApiExitoso(ResidentialLoanApplication rla) {
        return rla.getPopulatedFieldsAsMap().get('FSC_DesembolsoAPIExitoso__c') == true;
    }

    private static Boolean requiereEvidenciasApi(ResidentialLoanApplication rla) {
        return rla.Status == 'En proceso' && rla.FSC_Subestado__c == OPERACIONES && desembolsoApiExitoso(rla) &&
            rla.getPopulatedFieldsAsMap().get('FSC_EvidenciasDesembolsoCargadas__c') != true;
    }

    private static String campoUsuario(String etapa) {
        return etapa == CAPTURA ? 'FSC_UsuarioCaptura__c' : 'FSC_UsuarioOperaciones__c';
    }

    private static String permiso(String etapa) {
        return etapa == CAPTURA ? 'FSC_CP_Captura' : 'FSC_CP_EjecucionOperaciones';
    }

    // Conserva el responsable al volver a una etapa y completa solicitudes anteriores en su próxima edición.
    public static void asignarResponsables(List<ResidentialLoanApplication> solicitudes) {
        for (ResidentialLoanApplication rla : solicitudes) {
            if (!desembolsoApiExitoso(rla)) FSC_ProcesamientoAbanks.fijarModoManual(rla);
            if ((!esEtapaManual(rla) && !requiereEvidenciasApi(rla)) || rla.get(campoUsuario(rla.FSC_Subestado__c)) != null) continue;
            List<User> candidatos = usuariosElegibles(rla.FSC_Subestado__c);
            if (candidatos.isEmpty()) continue;
            Long aleatorio = Crypto.getRandomInteger();
            if (aleatorio < 0) aleatorio = -aleatorio;
            rla.put(campoUsuario(rla.FSC_Subestado__c), candidatos[(Integer) Math.mod(aleatorio, candidatos.size())].Id);
        }
    }

    // Inicialización administrativa; no se expone a Lightning.
    public static Map<String, Integer> inicializarSolicitudesExistentes() {
        Set<String> formas = new Set<String>(FORMAS_MANUALES);
        formas.add('Cuenta de ahorro');
        String filtro = ' FROM ResidentialLoanApplication WHERE Status = \'En proceso\' ' +
            'AND FSC_FormaDeDesembolso__c IN :formas AND FSC_AbanksAutomatico__c = false ' +
            'AND ((FSC_Subestado__c = :CAPTURA AND FSC_UsuarioCaptura__c = null) ' +
            'OR (FSC_Subestado__c = :OPERACIONES AND FSC_UsuarioOperaciones__c = null))';
        List<ResidentialLoanApplication> solicitudes = Database.query('SELECT Id' + filtro + ' LIMIT 200');
        update solicitudes;
        return new Map<String, Integer>{
            'procesadas' => solicitudes.size(),
            'pendientes' => Database.countQuery('SELECT COUNT()' + filtro)
        };
    }

    private static List<User> usuariosElegibles(String etapa) {
        if (usuariosPorEtapa.containsKey(etapa)) return usuariosPorEtapa.get(etapa);
        String cola = etapa == CAPTURA ? 'FSC_ColaCaptura' : 'FSC_ColaOperaciones';
        String conjunto = etapa == CAPTURA ? 'FSC_PS_Captura' : 'FSC_PS_EjecucionOperaciones';
        Set<Id> gruposPendientes = new Map<Id, Group>([
            SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :cola
        ]).keySet();
        Set<Id> gruposVisitados = new Set<Id>();
        Set<Id> miembros = new Set<Id>();
        while (!gruposPendientes.isEmpty()) {
            gruposVisitados.addAll(gruposPendientes);
            Set<Id> siguientes = new Set<Id>();
            for (GroupMember miembro : [SELECT UserOrGroupId FROM GroupMember WHERE GroupId IN :gruposPendientes]) {
                if (miembro.UserOrGroupId.getSObjectType() == User.SObjectType) {
                    miembros.add(miembro.UserOrGroupId);
                } else if (!gruposVisitados.contains(miembro.UserOrGroupId)) {
                    siguientes.add(miembro.UserOrGroupId);
                }
            }
            gruposPendientes = siguientes;
        }
        Set<Id> habilitados = new Set<Id>();
        for (PermissionSetAssignment asignacion : [
            SELECT AssigneeId FROM PermissionSetAssignment
            WHERE PermissionSet.Name = :conjunto AND AssigneeId IN :miembros
            AND Assignee.IsActive = true AND (ExpirationDate = null OR ExpirationDate > :System.now())
        ]) habilitados.add(asignacion.AssigneeId);
        List<User> usuarios = [SELECT Id, Name FROM User WHERE Id IN :habilitados ORDER BY Name];
        usuariosPorEtapa.put(etapa, usuarios);
        return usuarios;
    }

    // El lookup no comparte el registro por sí mismo; el propietario se mantiene.
    public static void compartirSolicitudes(List<ResidentialLoanApplication> solicitudes, Map<Id, ResidentialLoanApplication> anteriores) {
        Map<Id, Set<Id>> destinatarios = new Map<Id, Set<Id>>();
        for (ResidentialLoanApplication rla : solicitudes) {
            ResidentialLoanApplication anterior = anteriores == null ? null : anteriores.get(rla.Id);
            if (anterior != null && anterior.OwnerId == rla.OwnerId &&
                anterior.FSC_UsuarioCaptura__c == rla.FSC_UsuarioCaptura__c &&
                anterior.FSC_UsuarioOperaciones__c == rla.FSC_UsuarioOperaciones__c) continue;
            Set<Id> responsables = new Set<Id>{rla.FSC_UsuarioCaptura__c, rla.FSC_UsuarioOperaciones__c};
            responsables.remove(null);
            if (!responsables.isEmpty()) destinatarios.put(rla.Id, responsables);
        }
        if (destinatarios.isEmpty()) return;
        compartirRegistros('ResidentialLoanApplicationShare', destinatarios);
        Set<Id> solicitudesIds = destinatarios.keySet();
        compartirHijos('LoanApplicantShare', [SELECT Id, LoanApplicationId FROM LoanApplicant WHERE LoanApplicationId IN :solicitudesIds], destinatarios);
        compartirHijos('LoanApplicationAssetShare', [SELECT Id, LoanApplicationId FROM LoanApplicationAsset WHERE LoanApplicationId IN :solicitudesIds], destinatarios);
    }

    public static void compartirRelacionados(List<SObject> registros, String objetoShare) {
        Set<Id> solicitudesIds = new Set<Id>();
        for (SObject registro : registros) solicitudesIds.add((Id) registro.get('LoanApplicationId'));
        solicitudesIds.remove(null);
        if (solicitudesIds.isEmpty()) return;
        Map<Id, Set<Id>> destinatarios = new Map<Id, Set<Id>>();
        for (ResidentialLoanApplication rla : [SELECT Id, FSC_UsuarioCaptura__c, FSC_UsuarioOperaciones__c FROM ResidentialLoanApplication WHERE Id IN :solicitudesIds]) {
            Set<Id> responsables = new Set<Id>{rla.FSC_UsuarioCaptura__c, rla.FSC_UsuarioOperaciones__c};
            responsables.remove(null);
            if (!responsables.isEmpty()) destinatarios.put(rla.Id, responsables);
        }
        compartirHijos(objetoShare, registros, destinatarios);
    }

    private static void compartirHijos(String objetoShare, List<SObject> registros, Map<Id, Set<Id>> destinatarios) {
        Map<Id, Set<Id>> destinatariosHijos = new Map<Id, Set<Id>>();
        for (SObject registro : registros) {
            Set<Id> responsables = destinatarios.get((Id) registro.get('LoanApplicationId'));
            if (responsables != null) destinatariosHijos.put(registro.Id, responsables);
        }
        compartirRegistros(objetoShare, destinatariosHijos);
    }

    private static void compartirRegistros(String objetoShare, Map<Id, Set<Id>> destinatarios) {
        if (destinatarios.isEmpty()) return;
        Set<Id> registrosIds = destinatarios.keySet();
        Set<Id> usuarios = new Set<Id>();
        for (Set<Id> responsables : destinatarios.values()) usuarios.addAll(responsables);
        Set<String> existentes = new Set<String>();
        for (SObject acceso : Database.query('SELECT ParentId, UserOrGroupId FROM ' + objetoShare +
            ' WHERE ParentId IN :registrosIds AND UserOrGroupId IN :usuarios')) {
            existentes.add(String.valueOf(acceso.get('ParentId')) + ':' + String.valueOf(acceso.get('UserOrGroupId')));
        }
        List<SObject> accesos = new List<SObject>();
        Schema.SObjectType tipoShare = Schema.getGlobalDescribe().get(objetoShare);
        for (Id registroId : registrosIds) {
            for (Id usuarioId : destinatarios.get(registroId)) {
                if (existentes.contains(String.valueOf(registroId) + ':' + String.valueOf(usuarioId))) continue;
                SObject acceso = tipoShare.newSObject();
                acceso.put('ParentId', registroId);
                acceso.put('UserOrGroupId', usuarioId);
                acceso.put('AccessLevel', 'Read');
                acceso.put('RowCause', 'Manual');
                accesos.add(acceso);
            }
        }
        if (accesos.isEmpty()) return;
        Database.SaveResult[] resultados = Database.insert(accesos, false);
        Map<Id, Set<Id>> verificarLectura = new Map<Id, Set<Id>>();
        for (Integer i = 0; i < resultados.size(); i++) {
            if (resultados[i].isSuccess()) continue;
            Database.Error error = resultados[i].getErrors()[0];
            if (error.getStatusCode() != StatusCode.INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY &&
                error.getStatusCode() != StatusCode.FIELD_INTEGRITY_EXCEPTION) {
                throw new AuraHandledException('No se pudo compartir el registro: ' + error.getMessage());
            }
            Id usuarioId = (Id) accesos[i].get('UserOrGroupId');
            if (!verificarLectura.containsKey(usuarioId)) verificarLectura.put(usuarioId, new Set<Id>());
            verificarLectura.get(usuarioId).add((Id) accesos[i].get('ParentId'));
        }
        // FSC puede rechazar un share redundante aunque el usuario ya tenga lectura.
        for (Id usuarioId : verificarLectura.keySet()) {
            List<Id> pendientes = new List<Id>(verificarLectura.get(usuarioId));
            for (Integer inicio = 0; inicio < pendientes.size(); inicio += 200) {
                Set<Id> lote = new Set<Id>();
                for (Integer i = inicio; i < Math.min(inicio + 200, pendientes.size()); i++) lote.add(pendientes[i]);
                Set<Id> legibles = new Set<Id>();
                for (UserRecordAccess acceso : [SELECT RecordId, HasReadAccess FROM UserRecordAccess WHERE UserId = :usuarioId AND RecordId IN :lote]) {
                    if (acceso.HasReadAccess) legibles.add(acceso.RecordId);
                }
                if (legibles.size() != lote.size()) throw new AuraHandledException('No se pudo dar acceso de lectura al responsable asignado.');
            }
        }
    }

    private static ResidentialLoanApplication obtenerSolicitud(Id solicitudId, Boolean bloquear) {
        if (solicitudId == null) throw new AuraHandledException('Solicitud requerida.');
        String consulta = 'SELECT Id, Status, FSC_Subestado__c, FSC_FormaDeDesembolso__c, ' +
            'FSC_UsuarioCaptura__c, FSC_UsuarioCaptura__r.Name, FSC_UsuarioOperaciones__c, FSC_UsuarioOperaciones__r.Name, ' +
            'FSC_NumeroPrestamoAbanks__c, FSC_ProcesamientoAbanksManual__c, FSC_DesembolsoAPIExitoso__c, ' +
            'FSC_EvidenciasDesembolsoCargadas__c, FSC_FlagErrorAPIDesembolso__c FROM ResidentialLoanApplication WHERE Id = :solicitudId';
        if (bloquear) consulta += ' FOR UPDATE';
        List<ResidentialLoanApplication> solicitudes = Database.query(consulta);
        if (solicitudes.isEmpty()) throw new AuraHandledException('No se encontró la solicitud.');
        return solicitudes[0];
    }

    private static Boolean puedeActuar(ResidentialLoanApplication rla) {
        return testBypassPermissions || FeatureManagement.checkPermission(PERMISO_ADMIN) ||
            (FeatureManagement.checkPermission(permiso(rla.FSC_Subestado__c)) &&
             rla.get(campoUsuario(rla.FSC_Subestado__c)) == UserInfo.getUserId());
    }

    private static ResidentialLoanApplication validarAccion(Id solicitudId, String etapa) {
        ResidentialLoanApplication rla = obtenerSolicitud(solicitudId, true);
        if ((!esEtapaManual(rla) && !(etapa == OPERACIONES && requiereEvidenciasApi(rla))) || rla.FSC_Subestado__c != etapa) {
            throw new AuraHandledException('La solicitud ya no está en la etapa correspondiente a esta acción.');
        }
        if (!puedeActuar(rla)) throw new AuraHandledException('Solo el usuario asignado con el permiso correspondiente o un administrador puede realizar esta acción.');
        if (tieneAprobacionPendiente(solicitudId)) {
            throw new AuraHandledException('Complete la aprobación pendiente antes de continuar con la operación manual.');
        }
        return rla;
    }

    private static Boolean tieneAprobacionPendiente(Id solicitudId) {
        return ![SELECT Id FROM ProcessInstance WHERE TargetObjectId = :solicitudId AND Status = 'Pending' LIMIT 1].isEmpty();
    }

    public static Map<String, Object> contexto(Id solicitudId) {
        ResidentialLoanApplication rla = obtenerSolicitud(solicitudId, false);
        Boolean manual = esEtapaManual(rla);
        Boolean evidencias = requiereEvidenciasApi(rla);
        Boolean aprobacionPendiente = (manual || evidencias) && tieneAprobacionPendiente(solicitudId);
        // La lectura del contexto respeta el acceso al registro de quien abrió la página.
        List<UserRecordAccess> accesos = [SELECT RecordId, HasReadAccess FROM UserRecordAccess WHERE UserId = :UserInfo.getUserId() AND RecordId = :solicitudId];
        if (accesos.isEmpty() || !accesos[0].HasReadAccess) throw new AuraHandledException('No tiene acceso a esta solicitud.');
        return new Map<String, Object>{
            'etapaManual' => (manual || evidencias) && !aprobacionPendiente,
            'etapa' => rla.FSC_Subestado__c,
            'puedeActuar' => manual && puedeActuar(rla) && !aprobacionPendiente,
            'requiereArchivosDesembolso' => evidencias && !aprobacionPendiente,
            'puedeCargarArchivosDesembolso' => evidencias && puedeActuar(rla) && !aprobacionPendiente,
            'desembolsoApiExitoso' => desembolsoApiExitoso(rla),
            'errorAPIDesembolso' => rla.FSC_FlagErrorAPIDesembolso__c,
            'requiereInicializacionManual' => manual && rla.FSC_FormaDeDesembolso__c == 'Cuenta de ahorro' &&
                rla.FSC_ProcesamientoAbanksManual__c != true && !aprobacionPendiente,
            'automatizacionHabilitada' => FSC_ProcesamientoAbanks.habilitadas(new Set<Id>{solicitudId}).contains(solicitudId),
            'responsable' => rla.FSC_Subestado__c == CAPTURA ? rla.FSC_UsuarioCaptura__r.Name : rla.FSC_UsuarioOperaciones__r.Name,
            'numeroPrestamo' => rla.FSC_NumeroPrestamoAbanks__c,
            'requiereGarantias' => manual && rla.FSC_Subestado__c == CAPTURA && tieneGarantias(solicitudId),
            'requiereSeguros' => manual && rla.FSC_Subestado__c == CAPTURA && tieneSeguros(solicitudId)
        };
    }

    public static void prepararProcesamientoManual(Id solicitudId) {
        Map<String, Object> datos = contexto(solicitudId);
        if (datos.get('requiereInicializacionManual') != true) return;
        ResidentialLoanApplication rla = obtenerSolicitud(solicitudId, true);
        if (!esEtapaManual(rla) || tieneAprobacionPendiente(solicitudId)) return;
        // La primera apertura incorpora también solicitudes que estaban esperando la API.
        update new ResidentialLoanApplication(Id = solicitudId, FSC_ProcesamientoAbanksManual__c = true);
    }

    private static Boolean tieneGarantias(Id solicitudId) {
        return ![SELECT Id FROM LoanApplicationAsset WHERE LoanApplicationId = :solicitudId LIMIT 1].isEmpty() ||
            ![SELECT Id FROM FSC_Garantia__c WHERE FSC_Residential_Loan_Application__c = :solicitudId LIMIT 1].isEmpty();
    }

    private static Boolean tieneSeguros(Id solicitudId) {
        return ![SELECT Id FROM FSC_Seguro__c WHERE FSC_Residential_Loan_Application__c = :solicitudId LIMIT 1].isEmpty();
    }

    public static void guardarCaptura(Id solicitudId, String numeroPrestamo, Boolean credito, Boolean garantias, Boolean seguros) {
        ResidentialLoanApplication rla = validarAccion(solicitudId, CAPTURA);
        if (credito != true || (tieneGarantias(solicitudId) && garantias != true) || (tieneSeguros(solicitudId) && seguros != true)) {
            throw new AuraHandledException('Debe marcar todas las confirmaciones que correspondan a la solicitud.');
        }
        if (String.isBlank(numeroPrestamo) || numeroPrestamo.trim().length() > 255) {
            throw new AuraHandledException('Ingrese el número de crédito en Abanks (máximo 255 caracteres).');
        }
        if (rla.FSC_FormaDeDesembolso__c == 'Cuenta de ahorro' && String.isNotBlank(rla.FSC_NumeroPrestamoAbanks__c) && rla.FSC_NumeroPrestamoAbanks__c != numeroPrestamo.trim()) {
            throw new AuraHandledException('La solicitud ya tiene un préstamo en Abanks. Conserve ese número para evitar duplicados.');
        }
        update new ResidentialLoanApplication(Id = solicitudId, FSC_NumeroPrestamoAbanks__c = numeroPrestamo.trim(),
            FSC_ProcesamientoAbanksManual__c = rla.FSC_FormaDeDesembolso__c == 'Cuenta de ahorro' || rla.FSC_ProcesamientoAbanksManual__c,
            FSC_Subestado__c = OPERACIONES);
    }

    public static List<Map<String, String>> opcionesReasignacion(Id solicitudId) {
        if (!testBypassPermissions && !FeatureManagement.checkPermission(PERMISO_ADMIN)) throw new AuraHandledException('Solo un administrador puede reasignar.');
        ResidentialLoanApplication rla = obtenerSolicitud(solicitudId, false);
        if (!esEtapaManual(rla) && !requiereEvidenciasApi(rla)) throw new AuraHandledException('La solicitud no está en una etapa de captura u operaciones.');
        List<Map<String, String>> opciones = new List<Map<String, String>>();
        for (User usuario : usuariosElegibles(rla.FSC_Subestado__c)) opciones.add(new Map<String, String>{'label' => usuario.Name, 'value' => usuario.Id});
        return opciones;
    }

    public static void reasignar(Id solicitudId, Id usuarioId, String etapa) {
        if (!FeatureManagement.checkPermission(PERMISO_ADMIN)) throw new AuraHandledException('Solo un administrador puede reasignar.');
        ResidentialLoanApplication rla = validarAccion(solicitudId, etapa);
        Boolean encontrado = false;
        for (User usuario : usuariosElegibles(etapa)) if (usuario.Id == usuarioId) encontrado = true;
        if (!encontrado) throw new AuraHandledException('Seleccione un usuario activo de la cola con el permiso correspondiente.');
        ResidentialLoanApplication cambio = new ResidentialLoanApplication(Id = rla.Id);
        cambio.put(campoUsuario(etapa), usuarioId);
        update cambio;
    }

    public static void confirmarDesembolso(Id solicitudId, List<Id> amortizacion, List<Id> recibos) {
        ResidentialLoanApplication rla = validarAccion(solicitudId, OPERACIONES);
        if (String.isBlank(rla.FSC_NumeroPrestamoAbanks__c)) throw new AuraHandledException('Registre el número de préstamo en Abanks antes de confirmar el desembolso.');
        if (amortizacion == null || amortizacion.isEmpty() || recibos == null || recibos.isEmpty()) {
            throw new AuraHandledException('Debe cargar al menos un archivo de amortización y un recibo de desembolso.');
        }
        Set<Id> documentosIds = new Set<Id>(amortizacion);
        for (Id reciboId : recibos) {
            if (documentosIds.contains(reciboId)) throw new AuraHandledException('Cargue archivos distintos para cada sección.');
        }
        documentosIds.addAll(recibos);
        List<ContentDocument> documentos = archivosPrivados(documentosIds);
        List<ContentDocumentLink> enlaces = new List<ContentDocumentLink>();
        for (ContentDocument documento : documentos) {
            if (String.isBlank(documento.FileExtension) || !EXTENSIONES.contains(documento.FileExtension.toLowerCase())) throw new AuraHandledException('Solo se permiten archivos Word, PDF, Excel, JPG y PNG.');
            enlaces.add(new ContentDocumentLink(ContentDocumentId = documento.Id, LinkedEntityId = solicitudId, ShareType = 'V', Visibility = 'InternalUsers'));
        }
        // Los archivos y el avance se confirman en la misma transacción.
        insert enlaces;
        update new ResidentialLoanApplication(Id = solicitudId, FSC_Subestado__c = 'Archivo y custodia',
            FSC_Desembolso_Realizado__c = true, FSC_EvidenciasDesembolsoCargadas__c = true);
    }

    private static List<ContentDocument> archivosPrivados(Set<Id> documentosIds) {
        List<ContentDocument> documentos = [SELECT Id, FileExtension FROM ContentDocument WHERE Id IN :documentosIds AND OwnerId = :UserInfo.getUserId() AND CreatedById = :UserInfo.getUserId()];
        if (documentos.size() != documentosIds.size()) throw new AuraHandledException('No se pudieron validar los archivos cargados.');
        for (ContentDocumentLink enlace : [SELECT LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN :documentosIds]) {
            if (enlace.LinkedEntityId != UserInfo.getUserId()) throw new AuraHandledException('Uno de los archivos ya está vinculado. Actualice la solicitud.');
        }
        return documentos;
    }

    public static void descartarArchivos(List<Id> documentosIds) {
        if (documentosIds == null || documentosIds.isEmpty()) return;
        if (!testBypassPermissions && !FeatureManagement.checkPermission(PERMISO_ADMIN) && !FeatureManagement.checkPermission('FSC_CP_EjecucionOperaciones')) {
            throw new AuraHandledException('No tiene permiso para descartar estos archivos.');
        }
        delete archivosPrivados(new Set<Id>(documentosIds));
    }
}