/** Edición de texto sobre una copia del HTML impreso. El diseño nunca proviene del navegador. */
public with sharing class FSC_DocumentoLegalService {
  public static final String ETAPA = 'Generación de pagarés y plantillas';
  public static final String PAGARE = 'PAGARE';
  public static final String CONTRATO = 'CONTRATO';
  public static final String PIGNORACION = 'PIGNORACION';
  private static final Integer MAX_SOURCE = 131072;
  @TestVisible
  private static Boolean bypassAuthorization = false;

  public class Bloque {
    @AuraEnabled
    public String clave;
    @AuraEnabled
    public String texto;
    @AuraEnabled
    public Integer parrafo;
    public String campo;
    public Integer inicio;
    public Integer fin;
    public String original;
    public Bloque(
      String clave,
      String texto,
      Integer parrafo,
      Integer inicio,
      Integer fin,
      String original
    ) {
      this.clave = clave;
      this.texto = texto;
      this.parrafo = parrafo;
      this.inicio = inicio;
      this.fin = fin;
      this.original = original;
    }
  }

  public class Fuente {
    public String tipo;
    public String plantilla;
    public String html;
    public Set<String> camposManuales = new Set<String>();
  }

  public static String capturar(PageReference pagina, String tipo) {
    Fuente fuente = new Fuente();
    fuente.tipo = tipo;
    fuente.plantilla = pagina.getUrl().substringBefore('?');
    if (Test.isRunningTest()) {
      fuente.html = '<html><head><style>body{font-family:Arial;font-size:11pt}</style></head><body><p>Documento de prueba</p></body></html>';
    } else {
      pagina.getParameters().put('legalHtml', 'true');
      try {
        fuente.html = pagina.getContent().toString();
      } finally {
        pagina.getParameters().remove('legalHtml');
      }
      fuente.html = normalizarHtml(fuente.html);
    }
    return serializar(fuente);
  }

  @TestVisible
  private static String normalizarHtml(String html) {
    // Visualforce agrega scripts al modo HTML. No forman parte del documento impreso.
    html = html.replaceAll('(?is)<script\\b[^>]*>.*?</script\\s*>', '');
    html = html.replaceAll('(?s)<!--.*?-->', '');
    String domain = URL.getOrgDomainUrl().toExternalForm();
    // Blob.toPDF utiliza el mismo motor de Visualforce; las imágenes requieren una URL absoluta.
    html = html.replace('src="/resource/', 'src="' + domain + '/resource/');
    html = html.replace('src=\'/resource/', 'src=\'' + domain + '/resource/');
    return html;
  }

  public static Fuente leerFuente(String jsonFuente) {
    if (String.isBlank(jsonFuente)) {
      throw new AuraHandledException(
        'Este archivo no contiene una copia editable. Genere los documentos con el nuevo proceso antes de editarlos.'
      );
    }
    Fuente fuente;
    try {
      fuente = (Fuente) JSON.deserialize(jsonFuente, Fuente.class);
    } catch (Exception error) {
      throw new AuraHandledException(
        'La copia editable del documento no es válida.'
      );
    }
    if (
      fuente == null ||
      String.isBlank(fuente.html) ||
      !new Set<String>{ PAGARE, CONTRATO, PIGNORACION }.contains(fuente.tipo)
    ) {
      throw new AuraHandledException(
        'La copia editable del documento no es válida.'
      );
    }
    return fuente;
  }

  public static String serializar(Fuente fuente) {
    String jsonFuente = JSON.serialize(fuente);
    if (jsonFuente.length() > MAX_SOURCE) {
      throw new AuraHandledException(
        'El texto del documento excede el tamaño permitido. Reduzca su extensión antes de guardar.'
      );
    }
    return jsonFuente;
  }

  /** Solo devuelve nodos de texto del body. CSS, atributos, imágenes y estructura quedan inaccesibles. */
  public static List<Bloque> bloques(String html) {
    List<Bloque> resultado = new List<Bloque>();
    Matcher tokens = Pattern.compile('(?s)<!--.*?-->|<[^>]+>|[^<]+')
      .matcher(html);
    Boolean enBody = false;
    Boolean ignorar = false;
    Integer parrafo = 0;
    String campoActual;
    Boolean campoConTexto = false;
    while (tokens.find()) {
      String token = tokens.group();
      if (token.startsWith('<')) {
        String lower = token.toLowerCase();
        if (lower.startsWith('<body'))
          enBody = true;
        if (lower.startsWith('</body'))
          enBody = false;
        if (lower.startsWith('<script') || lower.startsWith('<style'))
          ignorar = true;
        if (lower.startsWith('</script') || lower.startsWith('</style'))
          ignorar = false;
        if (enBody && lower.startsWith('<span')) {
          Matcher campo = Pattern.compile('data-legal-field="([a-zA-Z]+)"')
            .matcher(token);
          if (campo.find()) {
            campoActual = campo.group(1);
            campoConTexto = false;
          }
        }
        if (lower.startsWith('</span') && campoActual != null) {
          if (!campoConTexto) {
            Bloque vacio = new Bloque(
              't' + resultado.size(),
              '',
              parrafo,
              tokens.start(),
              tokens.start(),
              ''
            );
            vacio.campo = campoActual;
            resultado.add(vacio);
          }
          campoActual = null;
        }
        if (
          enBody &&
          Pattern.matches('(?s)<(?:p|div|td|th|h[1-6])(?:\\s[^>]*)?>', lower)
        )
          parrafo++;
        continue;
      }
      if (!enBody || ignorar)
        continue;
      String texto = token.unescapeHtml4().replaceAll('\\s+', ' ').trim();
      // Los marcadores invisibles de firma electrónica son parte del diseño técnico.
      if (String.isBlank(texto) || texto.startsWith('[[!'))
        continue;
      Bloque bloque = new Bloque(
        't' + resultado.size(),
        texto,
        parrafo,
        tokens.start(),
        tokens.end(),
        token
      );
      bloque.campo = campoActual;
      if (campoActual != null)
        campoConTexto = true;
      resultado.add(bloque);
    }
    return resultado;
  }

  @TestVisible
  private static String aplicarCambios(String html, String cambiosJson) {
    Map<String, Object> cambios;
    try {
      cambios = (Map<String, Object>) JSON.deserializeUntyped(cambiosJson);
    } catch (Exception error) {
      throw new AuraHandledException(
        'Los cambios enviados no tienen un formato válido.'
      );
    }
    if (cambios == null || cambios.isEmpty())
      throw new AuraHandledException('No se modificó ningún texto.');
    List<Bloque> textos = bloques(html);
    Set<String> claves = new Set<String>();
    for (Bloque bloque : textos)
      claves.add(bloque.clave);
    for (String clave : cambios.keySet()) {
      if (!claves.contains(clave) || !(cambios.get(clave) instanceof String)) {
        throw new AuraHandledException(
          'Solo puede modificar los bloques de texto del documento.'
        );
      }
      if (((String) cambios.get(clave)).length() > 20000)
        throw new AuraHandledException(
          'Un bloque de texto supera los 20.000 caracteres.'
        );
    }
    List<String> partes = new List<String>();
    Integer posicion = 0;
    for (Bloque bloque : textos) {
      if (!cambios.containsKey(bloque.clave))
        continue;
      partes.add(html.substring(posicion, bloque.inicio));
      String texto = (String) cambios.get(bloque.clave);
      // El texto se escapa: escribir HTML nunca modifica el diseño ni incorpora imágenes.
      Matcher inicio = Pattern.compile('^\\s*').matcher(bloque.original);
      Matcher fin = Pattern.compile('\\s*$').matcher(bloque.original);
      inicio.find();
      fin.find();
      partes.add(
        inicio.group() +
          texto.escapeHtml4().replace('\r\n', '\n').replace('\n', '<br/>') +
          fin.group()
      );
      posicion = bloque.fin;
    }
    partes.add(html.substring(posicion));
    return String.join(partes, '');
  }

  private static ResidentialLoanApplication solicitud(
    Id solicitudId,
    Boolean bloquear
  ) {
    if (solicitudId == null)
      throw new AuraHandledException('Solicitud requerida.');
    String consulta =
      'SELECT Id, Status, RecordType.DeveloperName, FSC_Subestado__c, FSC_UsuarioPagaresYContratos__c, ' +
      'FSC_Pagares_y_Plantillas_Generados__c, FSC_Contrato_Generado__c, FSC_Pignoracion_Generada__c, ' +
      'FSC_RequiereContratoPagareNotarial__c, FSC_Excepcion_Contrato_Notarial__c, ' +
      'FSC_Requiere_Acto_Garantia__c, FSC_Acto_Garantia_Generado__c ' +
      'FROM ResidentialLoanApplication WHERE Id = :solicitudId';
    if (bloquear)
      consulta += ' FOR UPDATE';
    List<ResidentialLoanApplication> solicitudes = Database.query(consulta);
    if (solicitudes.isEmpty())
      throw new AuraHandledException('No tiene acceso a la solicitud.');
    ResidentialLoanApplication rla = solicitudes[0];
    if (
      !(Test.isRunningTest() && bypassAuthorization) &&
      !FSC_RoleAuthorizationService.canManagePagares(
        rla.FSC_UsuarioPagaresYContratos__c
      )
    ) {
      throw new AuraHandledException(
        'Solo el responsable de pagarés y contratos o un administrador puede realizar esta acción.'
      );
    }
    if (
      rla.Status != 'En proceso' ||
      rla.FSC_Subestado__c != ETAPA ||
      !rla.FSC_Pagares_y_Plantillas_Generados__c
    ) {
      throw new AuraHandledException(
        'La revisión solo está disponible después de generar los documentos y antes de validar.'
      );
    }
    return rla;
  }

  /** Replica las reglas actuales que deciden si se necesita un segundo documento. */
  public static String documentoAdicional(ResidentialLoanApplication rla) {
    String rt = rla.RecordType.DeveloperName;
    if (rt == 'FSC_Solicitud_Credito_Consumo') {
      FSC_ConsumoDocumentoResolver.ResolucionDocumento consumo = FSC_ConsumoDocumentoResolver.resolve(
        rla.Id
      );
      if (
        consumo.codigoPagare ==
        FSC_ConsumoDocumentoResolver.PAGARE_COMPLEMENTARIO &&
        consumo.tipoGarantia == FSC_ConsumoDocumentoResolver.GARANTIA_CD
      )
        return PIGNORACION;
      if (
        consumo.codigoPagare == FSC_ConsumoDocumentoResolver.PAGARE_SIMPLE ||
        consumo.codigoPagare ==
        FSC_ConsumoDocumentoResolver.PAGARE_SIMPLE_FIADOR
      )
        return null;
      if (
        consumo.codigoPagare == FSC_ConsumoDocumentoResolver.PAGARE_NOTARIAL &&
        rla.FSC_Excepcion_Contrato_Notarial__c != true
      )
        return null;
    }
    if (
      rt == 'FSC_Solicitud_Credito_PYME' &&
      rla.FSC_RequiereContratoPagareNotarial__c == true &&
      rla.FSC_Excepcion_Contrato_Notarial__c != true
    )
      return null;
    return FSC_RLAContractTemplateResolver.resolve(rla.Id).aplicaContrato
      ? CONTRATO
      : null;
  }

  private static Map<String, ContentVersion> archivos(Id solicitudId) {
    Map<String, ContentVersion> resultado = new Map<String, ContentVersion>();
    Set<Id> ids = new Set<Id>();
    for (ContentDocumentLink enlace : [
      SELECT ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :solicitudId
    ])
      ids.add(enlace.ContentDocumentId);
    if (ids.isEmpty())
      return resultado;
    for (ContentVersion version : [
      SELECT
        Id,
        ContentDocumentId,
        Title,
        PathOnClient,
        FSC_ContenidoLegal__c,
        FSC_EnviarDocumento__c,
        FSC_FechaEnvioFirma__c,
        FSC_Firmado__c,
        Description,
        SharingPrivacy,
        SharingOption
      FROM ContentVersion
      WHERE ContentDocumentId IN :ids AND IsLatest = TRUE
      ORDER BY CreatedDate DESC
    ]) {
      String tipo;
      if (!String.isBlank(version.FSC_ContenidoLegal__c)) {
        tipo = leerFuente(version.FSC_ContenidoLegal__c).tipo;
      } else {
        String titulo = version.Title.toLowerCase().replace('é', 'e');
        if (titulo.startsWith('pagare '))
          tipo = PAGARE;
        else if (titulo.startsWith('contrato '))
          tipo = CONTRATO;
        else if (titulo.startsWith('modelo de pignoracion'))
          tipo = PIGNORACION;
      }
      if (tipo != null && !resultado.containsKey(tipo))
        resultado.put(tipo, version);
    }
    return resultado;
  }

  public static Map<String, Object> contexto(Id solicitudId) {
    ResidentialLoanApplication rla = solicitud(solicitudId, false);
    Map<String, ContentVersion> documentos = archivos(solicitudId);
    String adicional = documentoAdicional(rla);
    Boolean listo =
      documentos.containsKey(PAGARE) &&
      (adicional == null || documentos.containsKey(adicional)) &&
      (rla.FSC_Requiere_Acto_Garantia__c != true ||
      rla.FSC_Acto_Garantia_Generado__c == true);
    return new Map<String, Object>{
      'pagareId' => documentos.get(PAGARE)?.Id,
      'contratoId' => documentos.get(
          adicional == PIGNORACION ? PIGNORACION : CONTRATO
        )
        ?.Id,
      'listo' => listo,
      'requiereAdicional' => adicional != null,
      'mensajePendiente' => listo
        ? ''
        : 'Espere la generación de todos los documentos requeridos. Puede actualizar su disponibilidad o reintentar la generación.'
    };
  }

  private static ContentVersion versionEditable(Id solicitudId, Id versionId) {
    if (versionId == null)
      throw new AuraHandledException('Documento requerido.');
    for (ContentVersion version : archivos(solicitudId).values()) {
      if (version.Id == versionId) {
        if (
          version.FSC_FechaEnvioFirma__c != null ||
          version.FSC_Firmado__c == true
        ) {
          throw new AuraHandledException(
            'No se puede editar un documento enviado a firma o firmado.'
          );
        }
        return version;
      }
    }
    throw new AuraHandledException(
      'El documento cambió o no pertenece a esta solicitud. Cierre y vuelva a abrir el editor.'
    );
  }

  public static Map<String, Object> obtenerDocumento(
    Id solicitudId,
    Id versionId
  ) {
    solicitud(solicitudId, false);
    ContentVersion version = versionEditable(solicitudId, versionId);
    Fuente fuente = leerFuente(version.FSC_ContenidoLegal__c);
    return new Map<String, Object>{
      'titulo' => version.Title,
      'bloques' => bloques(fuente.html)
    };
  }

  public static Id guardar(Id solicitudId, Id versionId, String cambiosJson) {
    solicitud(solicitudId, false);
    ContentVersion anterior = versionEditable(solicitudId, versionId);
    Fuente fuente = leerFuente(anterior.FSC_ContenidoLegal__c);
    Map<String, Object> cambios;
    try {
      cambios = (Map<String, Object>) JSON.deserializeUntyped(cambiosJson);
    } catch (Exception error) {
      throw new AuraHandledException(
        'Los cambios enviados no tienen un formato válido.'
      );
    }
    if (fuente.camposManuales == null)
      fuente.camposManuales = new Set<String>();
    for (Bloque bloque : bloques(fuente.html)) {
      if (
        bloque.campo != null &&
        cambios != null &&
        cambios.containsKey(bloque.clave)
      )
        fuente.camposManuales.add(bloque.campo);
    }
    fuente.html = aplicarCambios(fuente.html, cambiosJson);
    String fuenteJson = serializar(fuente);
    // Renderizar antes del DML permite mantener intacto el anterior ante cualquier error.
    Blob pdf = Test.isRunningTest()
      ? Blob.valueOf('PDF EDITADO')
      : Blob.toPDF(fuente.html);
    if (pdf == null || pdf.size() == 0)
      throw new AuraHandledException('No fue posible generar el PDF editado.');
    solicitud(solicitudId, true);
    versionEditable(solicitudId, versionId);
    return new ArchivosAutorizados().reemplazar(anterior, fuenteJson, pdf);
  }

  // La autorización y el acceso a la solicitud se verifican antes de entrar aquí.
  // Permite reemplazar archivos creados por otro responsable después de una reasignación.
  private without sharing class ArchivosAutorizados {
    public Id reemplazar(ContentVersion anterior, String fuenteJson, Blob pdf) {
      List<ContentDocumentLink> enlaces = [
        SELECT LinkedEntityId, ShareType, Visibility
        FROM ContentDocumentLink
        WHERE ContentDocumentId = :anterior.ContentDocumentId
      ];
      Savepoint punto = Database.setSavepoint();
      try {
        ContentVersion nueva = new ContentVersion(
          Title = anterior.Title,
          PathOnClient = anterior.PathOnClient,
          VersionData = pdf,
          FSC_ContenidoLegal__c = fuenteJson,
          FSC_EnviarDocumento__c = anterior.FSC_EnviarDocumento__c,
          Description = anterior.Description,
          SharingPrivacy = anterior.SharingPrivacy,
          SharingOption = anterior.SharingOption
        );
        insert nueva;
        nueva = [
          SELECT Id, ContentDocumentId
          FROM ContentVersion
          WHERE Id = :nueva.Id
        ];
        List<ContentDocumentLink> nuevosEnlaces = new List<ContentDocumentLink>();
        for (ContentDocumentLink enlace : enlaces) {
          if (enlace.LinkedEntityId == UserInfo.getUserId())
            continue;
          nuevosEnlaces.add(
            new ContentDocumentLink(
              ContentDocumentId = nueva.ContentDocumentId,
              LinkedEntityId = enlace.LinkedEntityId,
              ShareType = enlace.ShareType == 'I' ? 'V' : enlace.ShareType,
              Visibility = enlace.Visibility
            )
          );
        }
        insert nuevosEnlaces;
        delete new ContentDocument(Id = anterior.ContentDocumentId);
        return nueva.Id;
      } catch (Exception error) {
        Database.rollback(punto);
        throw new AuraHandledException(
          'No se pudo reemplazar el documento. El archivo anterior se conserva. ' +
          error.getMessage()
        );
      }
    }
  }

  public static void validar(Id solicitudId) {
    solicitud(solicitudId, true);
    if (contexto(solicitudId).get('listo') != true)
      throw new AuraHandledException(
        'Debe esperar a que se generen todos los documentos requeridos antes de validar.'
      );
    update new ResidentialLoanApplication(
      Id = solicitudId,
      FSC_Subestado__c = 'Gestionar firmas'
    );
  }

  public static void reintentar(Id solicitudId) {
    solicitud(solicitudId, true);
    System.enqueueJob(
      new FSC_GenerarContratoPDFQueueable(new List<Id>{ solicitudId }, true)
    );
  }

  /** ABANKS completa sus dos campos sin reconstruir ni sobrescribir las cláusulas editadas. */
  public static String completarComplementario(
    String fuenteJson,
    ResidentialLoanApplication rla
  ) {
    Fuente fuente = leerFuente(fuenteJson);
    Date fecha = rla.FSC_FechaVencimiento__c;
    if (fecha == null) {
      Date inicio = rla.FSC_Fecha_Contrato__c == null
        ? Date.today()
        : rla.FSC_Fecha_Contrato__c;
      fecha = inicio.addMonths(
        rla.FSC_PlazoMesesAprobado__c == null
          ? 0
          : Integer.valueOf(rla.FSC_PlazoMesesAprobado__c)
      );
    }
    actualizarCampo(
      fuente,
      'numeroPrestamo',
      rla.FSC_NumeroPrestamoAbanks__c.trim()
    );
    actualizarCampo(
      fuente,
      'fechaVencimiento',
      FSC_ContratoFormatoService.fechaCortaEnLetras(fecha)
    );
    return serializar(fuente);
  }

  private static void actualizarCampo(
    Fuente fuente,
    String campo,
    String valor
  ) {
    if (fuente.camposManuales != null && fuente.camposManuales.contains(campo))
      return;
    Matcher contenido = Pattern.compile(
        '(?s)<span\\b[^>]*data-legal-field="' + campo + '"[^>]*>(.*?)</span>'
      )
      .matcher(fuente.html);
    if (contenido.find())
      fuente.html =
        fuente.html.substring(0, contenido.start(1)) +
        valor.escapeHtml4() +
        fuente.html.substring(contenido.end(1));
  }
}