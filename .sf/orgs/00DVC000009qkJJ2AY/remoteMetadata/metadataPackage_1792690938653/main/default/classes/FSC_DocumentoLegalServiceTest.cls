@IsTest
private class FSC_DocumentoLegalServiceTest {
  private static Integer secuencia = 0;
  private static final String HTML =
    '<html><head><style>@page{size:letter;margin:20mm}body{font-family:Arial;font-size:11pt}.strong{font-weight:bold}</style></head>' +
    '<body><img src="/resource/logo" width="100"/><h2>CONTRATO</h2><p>Primera cláusula &amp; condiciones.</p>' +
    '<p><span class="strong">SEGUNDA:</span> Texto de la segunda cláusula.</p>' +
    '<div>Firma <span class="sig-marker">[[!FIRMASOLICITANTE:signer1:signature]]</span></div>' +
    '<div>Préstamo: <span class="blank-field" data-legal-field="numeroPrestamo"></span></div>' +
    '<div>Vencimiento: <span class="blank-field" data-legal-field="fechaVencimiento"></span></div>' +
    '<img src="/resource/anexo"/></body></html>';

  private static ResidentialLoanApplication crear(String rt, Boolean generado) {
    // Estos datos no prueban la política de crédito; sus límites se prueban en FSC_CreditPolicyGuardTest.
    FSC_CreditPolicyGuard.bypassInTests = true;
    FSC_DocumentoLegalService.bypassAuthorization = true;
    FSC_RoleAuthorizationService.testAdministratorPermission = true;
    Account cuenta = new Account(Name = 'Edición legal ' + secuencia++);
    insert cuenta;
    ResidentialLoanApplication rla = new ResidentialLoanApplication(
      Name = cuenta.Name,
      AccountId = cuenta.Id,
      Status = 'En proceso',
      FSC_Subestado__c = FSC_DocumentoLegalService.ETAPA,
      RecordTypeId = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName()
        .get(rt)
        .getRecordTypeId(),
      FSC_Pagares_y_Plantillas_Generados__c = generado,
      FSC_UsuarioPagaresYContratos__c = UserInfo.getUserId(),
      FSC_Monto__c = 100000,
      FSC_MontoAprobado__c = 100000,
      FSC_Plazo_meses__c = '12',
      FSC_PlazoMesesAprobado__c = rt.endsWith('Vehiculo') ? null : 12,
      FSC_TasaInteres__c = 10,
      FSC_Moneda__c = '1',
      FSC_lineaFinanciera__c = '32',
      FSC_subAplicacion__c = '401'
    );
    insert rla;
    if (rt.endsWith('Vehiculo')) {
      insert new FSC_Garantia__c(
        Name = 'Vehículo prueba',
        FSC_Residential_Loan_Application__c = rla.Id,
        FSC_Clase_de_Garantia__c = 'VEHICULOS USADOS-P2',
        FSC_Tipo_de_Garantia__c = 'Vehículo',
        FSC_Ano_Vehiculo__c = Date.today().year()
      );
    }
    return rla;
  }

  private static String fuente(String tipo) {
    FSC_DocumentoLegalService.Fuente f = new FSC_DocumentoLegalService.Fuente();
    f.tipo = tipo;
    f.plantilla = '/apex/Plantilla';
    f.html = HTML;
    return FSC_DocumentoLegalService.serializar(f);
  }

  private static ContentVersion archivo(Id rlaId, String tipo) {
    ContentVersion cv = new ContentVersion(
      Title = tipo == 'PAGARE' ? 'Pagare Complementario Test' : 'Contrato Test',
      PathOnClient = 'Documento.pdf',
      VersionData = Blob.valueOf('PDF ORIGINAL'),
      FirstPublishLocationId = rlaId,
      FSC_EnviarDocumento__c = true,
      FSC_ContenidoLegal__c = fuente(tipo)
    );
    insert cv;
    return [
      SELECT Id, ContentDocumentId, FSC_ContenidoLegal__c
      FROM ContentVersion
      WHERE Id = :cv.Id
    ];
  }

  @IsTest
  static void textosMantienenDisenoEImagenes() {
    List<FSC_DocumentoLegalService.Bloque> bloques = FSC_DocumentoLegalService.bloques(
      HTML
    );
    System.assertEquals('CONTRATO', bloques[0].texto);
    System.assertEquals('Primera cláusula & condiciones.', bloques[1].texto);
    for (FSC_DocumentoLegalService.Bloque b : bloques) {
      System.assert(!b.texto.contains('font-family'));
      System.assert(!b.texto.contains('FIRMASOLICITANTE'));
    }
    String editado = FSC_DocumentoLegalService.aplicarCambios(
      HTML,
      '{"t1":"Cláusula nueva <img src=malicioso> & texto\\nSegundo renglón"}'
    );
    System.assert(editado.contains('&lt;img src=malicioso&gt;'));
    System.assert(editado.unescapeHtml4().contains('<br/>Segundo renglón'));
    System.assert(editado.contains('<img src="/resource/logo" width="100"/>'));
    System.assert(editado.contains('<img src="/resource/anexo"/>'));
    System.assert(editado.contains('@page{size:letter;margin:20mm}'));
    System.assert(editado.contains('<span class="strong">SEGUNDA:</span>'));
    System.assert(editado.contains('[[!FIRMASOLICITANTE:signer1:signature]]'));
    String normalizado = FSC_DocumentoLegalService.normalizarHtml(
      HTML.replace(
        '<body>',
        '<body><script>alert(1)</script><!-- comentario -->'
      )
    );
    System.assert(!normalizado.contains('<script'));
    System.assert(!normalizado.contains('comentario'));
    System.assert(
      normalizado.contains(
        URL.getOrgDomainUrl().toExternalForm() + '/resource/logo'
      )
    );
  }

  @IsTest
  static void rechazaCambiosDeEstructuraYFuentesInvalidas() {
    for (
      String json : new List<String>{
        '[]',
        'no-json',
        '{}',
        '{"imagen":"modificada"}',
        '{"t1":42}'
      }
    ) {
      try {
        FSC_DocumentoLegalService.aplicarCambios(HTML, json);
        System.assert(false, 'Debe rechazar ' + json);
      } catch (AuraHandledException esperado) {
        System.assertNotEquals(null, esperado);
      }
    }
    for (
      String json : new List<String>{
        null,
        'no-json',
        '{}',
        '{"tipo":"OTRO","html":"texto"}'
      }
    ) {
      try {
        FSC_DocumentoLegalService.leerFuente(json);
        System.assert(false);
      } catch (AuraHandledException esperado) {
        System.assertNotEquals(null, esperado);
      }
    }
    FSC_DocumentoLegalService.Fuente f = FSC_DocumentoLegalService.leerFuente(
      fuente('PAGARE')
    );
    f.html = 'a'.repeat(131073);
    try {
      FSC_DocumentoLegalService.serializar(f);
      System.assert(false);
    } catch (AuraHandledException esperado) {
      System.assertNotEquals(null, esperado);
    }
    try {
      FSC_DocumentoLegalService.aplicarCambios(
        HTML,
        JSON.serialize(new Map<String, String>{ 't1' => 'a'.repeat(20001) })
      );
      System.assert(false);
    } catch (AuraHandledException esperado) {
      System.assertNotEquals(null, esperado);
    }
  }

  @IsTest
  static void editarReemplazaSoloArchivoYPersisteTexto() {
    ResidentialLoanApplication rla = crear(
      'FSC_Solicitud_Credito_Consumo',
      true
    );
    ContentVersion anterior = archivo(rla.Id, 'PAGARE');
    Map<String, Object> documento = FSC_RlaAccionesController.getDocumentoLegalEditable(
      rla.Id,
      anterior.Id
    );
    System.assert(
      ((List<FSC_DocumentoLegalService.Bloque>) documento.get('bloques'))
        .size() > 5
    );
    Id nuevoId = FSC_RlaAccionesController.guardarDocumentoLegalEditado(
      rla.Id,
      anterior.Id,
      '{"t1":"Cláusula modificada por el usuario"}'
    );
    ContentVersion nuevo = [
      SELECT ContentDocumentId, FSC_ContenidoLegal__c, FSC_EnviarDocumento__c
      FROM ContentVersion
      WHERE Id = :nuevoId
    ];
    System.assertNotEquals(anterior.ContentDocumentId, nuevo.ContentDocumentId);
    System.assertEquals(
      0,
      [
        SELECT COUNT()
        FROM ContentDocument
        WHERE Id = :anterior.ContentDocumentId
      ]
    );
    System.assertEquals(
      1,
      [
        SELECT COUNT()
        FROM ContentDocumentLink
        WHERE
          LinkedEntityId = :rla.Id
          AND ContentDocumentId = :nuevo.ContentDocumentId
      ]
    );
    System.assert(
      FSC_DocumentoLegalService.leerFuente(nuevo.FSC_ContenidoLegal__c)
        .html.unescapeHtml4()
        .contains('Cláusula modificada por el usuario')
    );
    System.assertEquals(true, nuevo.FSC_EnviarDocumento__c);
    ResidentialLoanApplication despues = [
      SELECT
        FSC_Subestado__c,
        FSC_Monto__c,
        FSC_Pagares_y_Plantillas_Generados__c
      FROM ResidentialLoanApplication
      WHERE Id = :rla.Id
    ];
    System.assertEquals(
      FSC_DocumentoLegalService.ETAPA,
      despues.FSC_Subestado__c
    );
    System.assertEquals(rla.FSC_Monto__c, despues.FSC_Monto__c);
    System.assertEquals(true, despues.FSC_Pagares_y_Plantillas_Generados__c);
    System.assertNotEquals(
      null,
      FSC_RlaAccionesController.getDocumentoLegalEditable(rla.Id, nuevoId)
    );
    try {
      FSC_RlaAccionesController.guardarDocumentoLegalEditado(
        rla.Id,
        anterior.Id,
        '{"t1":"desactualizado"}'
      );
      System.assert(false);
    } catch (AuraHandledException esperado) {
      System.assertNotEquals(null, esperado);
    }
  }

  @IsTest
  static void validadoAvanzaSoloConDocumentosListos() {
    ResidentialLoanApplication rla = crear(
      'FSC_Solicitud_Credito_Consumo',
      true
    );
    System.assertEquals(
      false,
      FSC_RlaAccionesController.getRevisionDocumentosLegales(rla.Id)
        .get('listo')
    );
    try {
      FSC_RlaAccionesController.validarDocumentosLegales(rla.Id);
      System.assert(false);
    } catch (AuraHandledException esperado) {
      System.assertNotEquals(null, esperado);
    }
    archivo(rla.Id, 'PAGARE');
    System.assertEquals(
      true,
      FSC_RlaAccionesController.getRevisionDocumentosLegales(rla.Id)
        .get('listo')
    );
    FSC_RlaAccionesController.validarDocumentosLegales(rla.Id);
    System.assertEquals(
      'Gestionar firmas',
      [
        SELECT FSC_Subestado__c
        FROM ResidentialLoanApplication
        WHERE Id = :rla.Id
      ]
      .FSC_Subestado__c
    );
    try {
      FSC_DocumentoLegalService.contexto(rla.Id);
      System.assert(false);
    } catch (AuraHandledException esperado) {
      System.assertNotEquals(null, esperado);
    }
  }

  @IsTest
  static void contratoPymeYReintentoConservanEtapa() {
    ResidentialLoanApplication rla = crear('FSC_Solicitud_Credito_PYME', true);
    archivo(rla.Id, 'PAGARE');
    System.assertEquals(
      false,
      FSC_DocumentoLegalService.contexto(rla.Id).get('listo')
    );
    Test.startTest();
    FSC_RlaAccionesController.reintentarDocumentosLegales(rla.Id);
    Test.stopTest();
    System.assertEquals(
      FSC_DocumentoLegalService.ETAPA,
      [
        SELECT FSC_Subestado__c
        FROM ResidentialLoanApplication
        WHERE Id = :rla.Id
      ]
      .FSC_Subestado__c
    );
    Map<String, Object> contexto = FSC_DocumentoLegalService.contexto(rla.Id);
    System.assertEquals(true, contexto.get('listo'));
    System.assertNotEquals(null, contexto.get('contratoId'));
    Id contratoId = (Id) contexto.get('contratoId');
    FSC_DocumentoLegalService.guardar(
      rla.Id,
      contratoId,
      '{"t0":"Contrato editado"}'
    );
    FSC_DocumentoLegalService.validar(rla.Id);
  }

  private static void generarTipo(String rt) {
    FSC_GenerarPagarePDF_Action.testBypassValidation = true;
    ResidentialLoanApplication rla = crear(
      'FSC_Solicitud_Credito_' + rt,
      false
    );
    update new ResidentialLoanApplication(
      Id = rla.Id,
      FSC_ActoNumeroPagare__c = String.valueOf(1000 + secuencia),
      FSC_NumeroFolioPagare__c = 1000 + secuencia,
      FSC_RequiereContratoPagareNotarial__c = rt == 'Vehiculo'
    );
    Test.startTest();
    FSC_RlaAccionesController.generarPagare(rla.Id);
    System.assertEquals(
      FSC_DocumentoLegalService.ETAPA,
      [
        SELECT FSC_Subestado__c
        FROM ResidentialLoanApplication
        WHERE Id = :rla.Id
      ]
      .FSC_Subestado__c
    );
    Test.stopTest();
    System.assertEquals(
      FSC_DocumentoLegalService.ETAPA,
      [
        SELECT FSC_Subestado__c
        FROM ResidentialLoanApplication
        WHERE Id = :rla.Id
      ]
      .FSC_Subestado__c
    );
    System.assertNotEquals(
      null,
      FSC_DocumentoLegalService.contexto(rla.Id).get('pagareId')
    );
    if (rt == 'Vehiculo') {
      Map<String, Object> revision = FSC_DocumentoLegalService.contexto(rla.Id);
      System.assertEquals(true, revision.get('requiereAdicional'));
      System.assertNotEquals(null, revision.get('contratoId'));
      System.assertEquals(true, revision.get('listo'));
    }
  }

  @IsTest
  static void generaConsumoSinAvanzar() {
    generarTipo('Consumo');
  }
  @IsTest
  static void generaPymeSinAvanzar() {
    generarTipo('PYME');
  }
  @IsTest
  static void generaVehiculoSinAvanzar() {
    generarTipo('Vehiculo');
  }
  @IsTest
  static void generaHipotecarioSinAvanzar() {
    generarTipo('Hipotecario');
  }

  @IsTest
  static void pignoracionSeRevisaYEditaComoDocumentoAdicional() {
    ResidentialLoanApplication rla = crear(
      'FSC_Solicitud_Credito_Consumo',
      true
    );
    insert new FSC_Garantia__c(
      Name = 'CD',
      FSC_Residential_Loan_Application__c = rla.Id,
      FSC_Clase_de_Garantia__c = 'CERTIFICADOS DEPOSITOS BANCO VIMENCA',
      FSC_Tipo_de_Garantia__c = 'Certificado de depósito',
      FSC_Numero_Certificado_Deposito__c = 'CD-01',
      FSC_Monto_Certificado_Deposito__c = 100000
    );
    archivo(rla.Id, 'PAGARE');
    System.assertEquals(
      false,
      FSC_DocumentoLegalService.contexto(rla.Id).get('listo')
    );
    Test.startTest();
    FSC_DocumentoLegalService.reintentar(rla.Id);
    Test.stopTest();
    Map<String, Object> contexto = FSC_DocumentoLegalService.contexto(rla.Id);
    System.assertEquals(true, contexto.get('listo'));
    System.assertNotEquals(null, contexto.get('contratoId'));
    System.assertEquals(
      FSC_DocumentoLegalService.ETAPA,
      [
        SELECT FSC_Subestado__c
        FROM ResidentialLoanApplication
        WHERE Id = :rla.Id
      ]
      .FSC_Subestado__c
    );
    FSC_DocumentoLegalService.guardar(
      rla.Id,
      (Id) contexto.get('contratoId'),
      '{"t0":"Pignoración revisada"}'
    );
  }

  @IsTest
  static void accesosFirmaYDocumentoAjenoSeRechazan() {
    ResidentialLoanApplication rla = crear(
      'FSC_Solicitud_Credito_Consumo',
      true
    );
    ResidentialLoanApplication otra = crear(
      'FSC_Solicitud_Credito_Consumo',
      true
    );
    ContentVersion version = archivo(rla.Id, 'PAGARE');
    try {
      FSC_DocumentoLegalService.obtenerDocumento(otra.Id, version.Id);
      System.assert(false);
    } catch (AuraHandledException esperado) {
      System.assertNotEquals(null, esperado);
    }
    update new ContentVersion(
      Id = version.Id,
      FSC_FechaEnvioFirma__c = System.now()
    );
    try {
      FSC_DocumentoLegalService.obtenerDocumento(rla.Id, version.Id);
      System.assert(false);
    } catch (AuraHandledException esperado) {
      System.assertNotEquals(null, esperado);
    }
    try {
      FSC_DocumentoLegalService.obtenerDocumento(rla.Id, null);
      System.assert(false);
    } catch (AuraHandledException esperado) {
      System.assertNotEquals(null, esperado);
    }
    try {
      FSC_DocumentoLegalService.contexto(null);
      System.assert(false);
    } catch (AuraHandledException esperado) {
      System.assertNotEquals(null, esperado);
    }
    FSC_DocumentoLegalService.bypassAuthorization = false;
    FSC_RoleAuthorizationService.testAdministratorPermission = false;
    FSC_RoleAuthorizationService.testPagaresPermission = false;
    try {
      FSC_DocumentoLegalService.contexto(rla.Id);
      System.assert(false);
    } catch (AuraHandledException esperado) {
      System.assertNotEquals(null, esperado);
    }
  }

  @IsTest
  static void abanksConservaClausulasEditadasYCompletaCampos() {
    ResidentialLoanApplication rla = crear('FSC_Solicitud_Credito_PYME', true);
    ContentVersion original = archivo(rla.Id, 'PAGARE');
    Id nuevaId = FSC_DocumentoLegalService.guardar(
      rla.Id,
      original.Id,
      '{"t1":"Cláusula editada antes de ABANKS"}'
    );
    ContentVersion nueva = [
      SELECT FSC_ContenidoLegal__c
      FROM ContentVersion
      WHERE Id = :nuevaId
    ];
    rla.FSC_NumeroPrestamoAbanks__c = 'AB-123';
    rla.FSC_FechaVencimiento__c = Date.today().addYears(1);
    rla.FSC_Fecha_Contrato__c = Date.today();
    String completada = FSC_DocumentoLegalService.completarComplementario(
      nueva.FSC_ContenidoLegal__c,
      rla
    );
    System.assert(
      completada.unescapeHtml4().contains('Cláusula editada antes de ABANKS')
    );
    System.assert(completada.contains('AB-123'));
    System.assert(completada.contains('fechaVencimiento'));
    update new ResidentialLoanApplication(
      Id = rla.Id,
      FSC_NumeroPrestamoAbanks__c = 'AB-123'
    );
    Test.startTest();
    new FSC_RegenerarPagareComplementarioQbl(new List<Id>{ rla.Id })
      .execute(null);
    Test.stopTest();
    ContentVersion finalVersion = [
      SELECT FSC_ContenidoLegal__c
      FROM ContentVersion
      WHERE IsLatest = TRUE AND Title LIKE 'Pagare Complementario%'
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    System.assert(
      FSC_DocumentoLegalService.leerFuente(finalVersion.FSC_ContenidoLegal__c)
        .html.unescapeHtml4()
        .contains('Cláusula editada antes de ABANKS')
    );
  }

  @IsTest
  static void editorAnalisisPymeSigueGuardandoSoloCambiosDelPdf() {
    ResidentialLoanApplication rla = crear('FSC_Solicitud_Credito_PYME', false);
    update new ResidentialLoanApplication(
      Id = rla.Id,
      FSC_Subestado__c = 'Análisis de crédito',
      FSC_Resultado_Buro__c = 'Referido',
      FSC_Doc_Completa_Analisis__c = true,
      FSC_DocumentacionValidadaAnalista__c = true,
      FSC_DebeRevisarComite__c = false,
      FSC_DebeRevisarSupervisor__c = false,
      FSC_Aprobado_con_Condiciones__c = false
    );
    insert new ContentVersion(
      Title = 'Informe de Crédito - ' + rla.Name,
      PathOnClient = 'Informe.pdf',
      VersionData = Blob.valueOf('PDF'),
      FirstPublishLocationId = rla.Id
    );
    FSC_RlaAccionesController.testPermitirEdicionDocumentosAnalisis = true;
    Map<String, Object> cambios = new Map<String, Object>{
      'montoSolicitado' => new Map<String, Object>{
        'value' => '100000',
        'format' => 'money'
      },
      'valorGarantia' => new Map<String, Object>{
        'value' => '200000',
        'format' => 'money'
      },
      'compromisosBalances' => new Map<String, Object>{
        'value' => '1000\n2000',
        'format' => 'text'
      },
      'compromisosCuotas' => new Map<String, Object>{
        'value' => '100\n200',
        'format' => 'text'
      },
      'disponibilidadBalancePromedio' => new Map<String, Object>{
        'value' => '3000',
        'format' => 'money'
      },
      'disponibilidadFlujoPromedio' => new Map<String, Object>{
        'value' => '6000',
        'format' => 'money'
      }
    };
    Test.startTest();
    System.assertNotEquals(
      null,
      FSC_RlaAccionesController.getDatosDocumentoAnalisis(rla.Id, 'INFORME')
    );
    FSC_RlaAccionesController.guardarYRegenerarDocumentoAnalisis(
      rla.Id,
      'INFORME',
      JSON.serialize(cambios)
    );
    Test.stopTest();
    ContentVersion editado = [
      SELECT FSC_DatosEditadosAnalisis__c
      FROM ContentVersion
      WHERE Title LIKE 'Informe de Crédito%' AND IsLatest = TRUE
      LIMIT 1
    ];
    Map<String, Object> ajustes = (Map<String, Object>) JSON.deserializeUntyped(
      editado.FSC_DatosEditadosAnalisis__c
    );
    System.assertEquals('200%', ajustes.get('cobertura'));
    System.assertNotEquals(null, ajustes.get('compromisosTotalCuotas'));
    System.assertEquals(
      rla.FSC_Monto__c,
      [SELECT FSC_Monto__c FROM ResidentialLoanApplication WHERE Id = :rla.Id]
      .FSC_Monto__c
    );
  }
}