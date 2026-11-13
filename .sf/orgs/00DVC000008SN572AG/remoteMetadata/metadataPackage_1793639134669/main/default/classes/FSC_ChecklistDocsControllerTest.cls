@IsTest
private class FSC_ChecklistDocsControllerTest {
    @TestSetup
    static void asignarPermisosAdministrador() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            PermissionSet permiso = [SELECT Id FROM PermissionSet WHERE Name = 'FSC_PS_Administrador' LIMIT 1];
            // El usuario que ejecuta los tests puede tener ya el permission set asignado.
            if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetId = :permiso.Id] == 0) {
                insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permiso.Id);
            }
        }
    }

	private static final String RT_PYME = 'FSC_Solicitud_Credito_PYME';
	private static final String TIPO_SOLICITUD_PYME = 'Solicitud de crédito pyme';

	// =========================
	// Helpers
	// =========================

	private static Id getRecordTypeId(String developerName) {
		Map<String, Schema.RecordTypeInfo> rtMap = ResidentialLoanApplication.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();

		if (rtMap != null && rtMap.containsKey(developerName)) {
			return rtMap.get(developerName).getRecordTypeId();
		}
		return null;
	}

	private static Account createAccount() {
		Account acc = new Account(Name = 'Cuenta Test Checklist ' + System.now().getTime());
		insert acc;
		return acc;
	}

	private static ResidentialLoanApplication createRla(String recordTypeDeveloperName) {
		Account acc = createAccount();

		ResidentialLoanApplication rla = new ResidentialLoanApplication();
		rla.AccountId = acc.Id;

		Id rtId = recordTypeDeveloperName != null ? getRecordTypeId(recordTypeDeveloperName) : null;
		if (rtId != null) {
			rla.RecordTypeId = rtId;
		}
		rla.Name = 'Test';
		rla.Status = 'En proceso';
		rla.FSC_Subestado__c = 'Recepción de documentos – Análisis';
		insert rla;
		return rla;
	}

	private static List<FSC_ChecklistDocumentos__c> createChecklistDocs(Integer cantidad) {
		List<FSC_ChecklistDocumentos__c> docs = new List<FSC_ChecklistDocumentos__c>();

		for (Integer i = 1; i <= cantidad; i++) {
			docs.add(
				new FSC_ChecklistDocumentos__c(
					FSC_TipoDeSolicitudDeCredito__c = TIPO_SOLICITUD_PYME,
					FSC_CategoriaDelDocumento__c = 'Documentos para análisis',
					FSC_NroDeDocumento__c = i,
					FSC_NombreDelDocumento__c = 'Documento ' + i
				)
			);
		}

		insert docs;
		return docs;
	}

	private static FSC_SolicitudDeCreditoYChecklistDeDocs__c createJoin(
		Id rlaId,
		Id docId,
		Boolean noAplica,
		String comentario,
		String estadoRevision
	) {
		FSC_SolicitudDeCreditoYChecklistDeDocs__c joinRec = new FSC_SolicitudDeCreditoYChecklistDeDocs__c(
			FSC_SolicitudDeCredito__c = rlaId,
			FSC_Documento__c = docId,
			FSC_NoAplica__c = noAplica,
			FSC_Comentario__c = comentario,
			FSC_EstadoRevision__c = estadoRevision
		);
		insert joinRec;
		return joinRec;
	}

	private static Id uploadFile(Id linkedEntityId, String fileName) {
		return uploadFileWithExtension(linkedEntityId, fileName, 'pdf');
	}

	private static Id uploadFileWithExtension(Id linkedEntityId, String fileName, String extension) {
		String pathOnClient = String.isBlank(extension) ? fileName : fileName + '.' + extension;
		ContentVersion cv = new ContentVersion(
			Title = fileName,
			PathOnClient = pathOnClient,
			VersionData = Blob.valueOf('archivo test ' + fileName),
			FirstPublishLocationId = linkedEntityId
		);
		insert cv;

		ContentVersion insertedCv = [
			SELECT Id, ContentDocumentId
			FROM ContentVersion
			WHERE Id = :cv.Id
			LIMIT 1
		];

		return insertedCv.ContentDocumentId;
	}

	private static Id uploadPreloadFile(Id linkedEntityId, String fileName, String technicalKey) {
		ContentVersion version = new ContentVersion(
			Title = fileName,
			PathOnClient = fileName + '.pdf',
			VersionData = Blob.valueOf('archivo precarga'),
			FirstPublishLocationId = linkedEntityId,
			FSC_ClaveTecnicaPrecarga__c = technicalKey
		);
		insert version;
		return [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version.Id].ContentDocumentId;
	}

	private static User createUser(String uniqueKey) {
		Profile baseProfile = [
			SELECT Id
			FROM Profile
			WHERE UserType = 'Standard' AND UserLicense.Name = 'Salesforce' AND PermissionsModifyAllData = false
			ORDER BY Name
			LIMIT 1
		];
		User u = new User(
			FirstName = 'Test',
			LastName = uniqueKey,
			Alias = uniqueKey.length() > 8 ? uniqueKey.substring(0, 8) : uniqueKey,
			Email = uniqueKey + '@test.com',
			Username = uniqueKey + '.' + System.now().getTime() + '@test.com',
			CommunityNickname = uniqueKey + String.valueOf(Math.mod(System.now().getTime(), 100000)),
			TimeZoneSidKey = 'America/Argentina/Buenos_Aires',
			LocaleSidKey = 'es_AR',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'es',
			ProfileId = baseProfile.Id
		);
		completarCamposObligatoriosUsuario(u);
		insert u;
		return u;
	}

	private static User createUserWithPermissionSet(String permissionSetName, String uniqueKey) {
		User u;
		System.runAs(new User(Id = UserInfo.getUserId())) {
			u = createUser(uniqueKey);
			List<PermissionSetLicenseAssign> licenseAssignments = new List<PermissionSetLicenseAssign>();
			for (PermissionSetLicense permissionSetLicense : [
				SELECT Id
				FROM PermissionSetLicense
				WHERE DeveloperName IN ('FSCServicePsl', 'FinServ_FinancialServicesCloudStandardPsl')
			]) {
				licenseAssignments.add(
					new PermissionSetLicenseAssign(
						AssigneeId = u.Id,
						PermissionSetLicenseId = permissionSetLicense.Id
					)
				);
			}
			if (!licenseAssignments.isEmpty()) {
				insert licenseAssignments;
			}
			PermissionSet permissionSet = [
				SELECT Id
				FROM PermissionSet
				WHERE Name = :permissionSetName AND IsOwnedByProfile = false
				LIMIT 1
			];
			insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = permissionSet.Id);
		}
		return u;
	}

	// =========================
	// Tests initAndGetRows
	// =========================

	@IsTest
	static void testPrecargaSincronizaArchivos() {
		ResidentialLoanApplication rla = createRla(null);
		List<String> labels = new List<String>{
			'Capacidad de pago',
			'Conozca su cliente',
			'Pagaré',
			'Pagaré complementario',
			'Contratos debidamente firmados',
			'Certificación de ingresos',
			'Registro mercantil',
			'Estatutos sociales',
			'Acta de asamblea general constitutiva',
			'Declaratoria de condominio',
			'Poder de autorización',
			'Autorización para contratación de préstamos',
			'Acta designando funcionarios y firmas',
			'Tarjeta de firmas',
			'Nómina de presencia',
			'RNC',
			'Cédula de firmantes',
			'Cédula de accionistas',
			'Documento de identidad del solicitante'
		};
		List<FSC_ChecklistDocumentos__c> documents = new List<FSC_ChecklistDocumentos__c>();
		for (Integer index = 0; index < labels.size(); index++) {
			documents.add(new FSC_ChecklistDocumentos__c(
				FSC_TipoDeSolicitudDeCredito__c = TIPO_SOLICITUD_PYME,
				FSC_CategoriaDelDocumento__c = 'Documentos para análisis',
				FSC_NroDeDocumento__c = 20 + index,
				FSC_NombreDelDocumento__c = labels[index]
			));
		}
		insert documents;

		List<FSC_SolicitudDeCreditoYChecklistDeDocs__c> rows = new List<FSC_SolicitudDeCreditoYChecklistDeDocs__c>();
		for (FSC_ChecklistDocumentos__c document : documents) {
			rows.add(new FSC_SolicitudDeCreditoYChecklistDeDocs__c(
				FSC_SolicitudDeCredito__c = rla.Id,
				FSC_Documento__c = document.Id,
				FSC_NoAplica__c = false,
				FSC_EstadoRevision__c = 'Pendiente'
			));
		}
		insert rows;

		Map<Id, FSC_SolicitudDeCreditoYChecklistDeDocs__c> rowsByDocument =
			new Map<Id, FSC_SolicitudDeCreditoYChecklistDeDocs__c>();
		for (FSC_SolicitudDeCreditoYChecklistDeDocs__c row : rows) {
			rowsByDocument.put(row.FSC_Documento__c, row);
		}

		uploadPreloadFile(rla.AccountId, 'Conozca su cliente generado', 'KYC');
		uploadPreloadFile(rla.AccountId, 'Carta laboral vigente', 'CARTA_LABORAL');
		uploadPreloadFile(rla.AccountId, 'Comprobante de ingresos', 'COMPROBANTE_INGRESOS');
		uploadPreloadFile(rla.Id, 'Pagare firmado', null);
		uploadPreloadFile(rla.Id, 'Pagare complementario firmado', null);
		uploadPreloadFile(rla.Id, 'Contrato de prestamo firmado', null);

		Test.startTest();
		FSC_ChecklistDocsPrecargaService.sincronizar(null, rla.AccountId, documents, rowsByDocument);
		FSC_ChecklistDocsPrecargaService.sincronizar(rla.Id, rla.AccountId, null, rowsByDocument);
		FSC_ChecklistDocsPrecargaService.sincronizar(rla.Id, rla.AccountId, documents, rowsByDocument);
		// La segunda ejecución comprueba que no se dupliquen enlaces.
		FSC_ChecklistDocsPrecargaService.sincronizar(rla.Id, rla.AccountId, documents, rowsByDocument);
		Test.stopTest();

		Set<Id> rowIds = new Map<Id, FSC_SolicitudDeCreditoYChecklistDeDocs__c>(rows).keySet();
		Integer linkedRows = [
			SELECT COUNT()
			FROM ContentDocumentLink
			WHERE LinkedEntityId IN :rowIds
		];
		System.assert(linkedRows >= 6, 'Debe precargar los archivos compatibles.');
	}

	@IsTest
	static void testPrecargaResuelveTitulosGenerados() {
		List<String> titles = new List<String>{
			'Informe de crédito 001',
			'Capacidad de pago 001',
			'Crédito pyme 001',
			'Crédito consumo 001',
			'Crédito vehicular 001',
			'Crédito hipotecario 001',
			'Solicitud de crédito consumo',
			'Conozca su cliente 001',
			'Contrato único 001',
			'Pagaré complementario firmado',
			'Pagaré firmado',
			'Contrato vehicular firmado',
			'Título desconocido',
			null
		};
		Integer resolved = 0;
		for (String title : titles) {
			if (FSC_ChecklistDocsPrecargaService.resolveGeneratedKey(title) != null) {
				resolved++;
			}
		}
		System.assertEquals(12, resolved, 'Debe reconocer los títulos generados soportados.');
	}

	@IsTest
	static void testInitAndGetRows_NullId() {
		Boolean thrown = false;

		try {
			FSC_ChecklistDocsController.initAndGetRows(null);
		} catch (AuraHandledException e) {
			thrown = true;
		}

		System.assertEquals(true, thrown);
	}

	@IsTest
	static void testInitAndGetRows_CreaJoinsYDevuelveRows() {
		Id pymeRtId = getRecordTypeId(RT_PYME);
		if (pymeRtId == null) {
			System.assert(true);
			return;
		}

		ResidentialLoanApplication rla = createRla(RT_PYME);
		List<FSC_ChecklistDocumentos__c> docs = createChecklistDocs(3);

		Test.startTest();
		List<FSC_ChecklistDocsController.RowDTO> rows = FSC_ChecklistDocsController.initAndGetRows(rla.Id);
		Test.stopTest();

		System.assertEquals(3, rows.size());

		List<FSC_SolicitudDeCreditoYChecklistDeDocs__c> joins = [
			SELECT Id, FSC_Documento__c, FSC_NoAplica__c, FSC_Comentario__c, FSC_EstadoRevision__c
			FROM FSC_SolicitudDeCreditoYChecklistDeDocs__c
			WHERE FSC_SolicitudDeCredito__c = :rla.Id
		];
		System.assertEquals(3, joins.size());

		for (FSC_ChecklistDocsController.RowDTO row : rows) {
			System.assertNotEquals(null, row.checklistId);
			System.assertNotEquals(null, row.joinId);
			System.assertEquals(false, row.noAplica);
			System.assertEquals('Pendiente', row.estadoRevision);
			System.assertNotEquals(null, row.files);
			System.assertEquals(0, row.files.size());
		}

		System.assertEquals(1, rows[0].nroDocumento);
		System.assertEquals(2, rows[1].nroDocumento);
		System.assertEquals(3, rows[2].nroDocumento);
	}

	@IsTest
	static void testInitAndGetRows_UsaJoinExistenteYTraeArchivos() {
		Id pymeRtId = getRecordTypeId(RT_PYME);
		if (pymeRtId == null) {
			System.assert(true);
			return;
		}

		ResidentialLoanApplication rla = createRla(RT_PYME);
		List<FSC_ChecklistDocumentos__c> docs = createChecklistDocs(2);

		FSC_SolicitudDeCreditoYChecklistDeDocs__c joinRec = createJoin(rla.Id, docs[0].Id, true, 'Comentario inicial', 'Observado');

		Id cdId = uploadFile(joinRec.Id, 'archivo_join_1');
		System.assertNotEquals(null, cdId);

		Test.startTest();
		List<FSC_ChecklistDocsController.RowDTO> rows = FSC_ChecklistDocsController.initAndGetRows(rla.Id);
		Test.stopTest();

		System.assertEquals(2, rows.size());

		FSC_ChecklistDocsController.RowDTO firstRow = rows[0];
		System.assertEquals(docs[0].Id, firstRow.checklistId);
		System.assertEquals(joinRec.Id, firstRow.joinId);
		System.assertEquals(true, firstRow.noAplica);
		System.assertEquals('Comentario inicial', firstRow.comentario);
		System.assertEquals('Observado', firstRow.estadoRevision);
		System.assertEquals(1, firstRow.files.size());
		System.assertEquals('archivo_join_1', firstRow.files[0].title);
		System.assertEquals(true, firstRow.files[0].eliminable, 'Un archivo subido en la fila debe poder eliminarse');

		Integer totalJoins = [
			SELECT COUNT()
			FROM FSC_SolicitudDeCreditoYChecklistDeDocs__c
			WHERE FSC_SolicitudDeCredito__c = :rla.Id
		];
		System.assertEquals(2, totalJoins);
	}

	@IsTest
	static void testInitAndGetRows_SinDocsDevuelveVacio() {
		Id pymeRtId = getRecordTypeId(RT_PYME);
		if (pymeRtId == null) {
			System.assert(true);
			return;
		}

		ResidentialLoanApplication rla = createRla(RT_PYME);

		Test.startTest();
		List<FSC_ChecklistDocsController.RowDTO> rows = FSC_ChecklistDocsController.initAndGetRows(rla.Id);
		Test.stopTest();

		System.assertEquals(0, rows.size());
	}

	// =========================
	// Tests saveRows
	// =========================

	@IsTest
	static void testSaveRows_ParametrosInconsistentes() {
		Boolean thrown = false;

		try {
			FSC_ChecklistDocsController.saveRows(
				new List<Id>{ UserInfo.getUserId() },
				new List<Boolean>{ true },
				new List<String>{ 'comentario' },
				new List<String>{ 'comentario oficial' },
				new List<String>{ 'Pendiente', 'Aprobado' }
			);
		} catch (AuraHandledException e) {
			thrown = true;
		}

		System.assertEquals(true, thrown);
	}

	@IsTest
	static void testSaveRows_SinPermisos() {
		Id pymeRtId = getRecordTypeId(RT_PYME);
		if (pymeRtId == null) {
			System.assert(true);
			return;
		}

		User standardUser = createUser('stdusr1');

		ResidentialLoanApplication rla = createRla(RT_PYME);
		List<FSC_ChecklistDocumentos__c> docs = createChecklistDocs(1);
		FSC_SolicitudDeCreditoYChecklistDeDocs__c joinRec = createJoin(rla.Id, docs[0].Id, false, null, 'Pendiente');

		System.runAs(standardUser) {
			Boolean thrown = false;

			try {
				FSC_ChecklistDocsController.saveRows(
					new List<Id>{ joinRec.Id },
					new List<Boolean>{ true },
					new List<String>{ 'comentario x' },
					new List<String>{ 'comentario oficial x' },
					new List<String>{ 'Observado' }
				);
			} catch (AuraHandledException e) {
				thrown = true;
			}

			System.assertEquals(true, thrown);
		}
	}

	@IsTest
	static void testSaveRows_Reviewer_ActualizaEstadoYComentario() {
		Id pymeRtId = getRecordTypeId(RT_PYME);
		if (pymeRtId == null) {
			System.assert(true);
			return;
		}

		User reviewerUser = createUserWithPermissionSet('FSC_PS_Recepcion_Control_Documentos', 'review01');

		ResidentialLoanApplication rla = createRla(RT_PYME);
		List<FSC_ChecklistDocumentos__c> docs = createChecklistDocs(1);
		FSC_SolicitudDeCreditoYChecklistDeDocs__c joinRec = createJoin(rla.Id, docs[0].Id, false, null, 'Pendiente');

		System.runAs(reviewerUser) {
			Test.startTest();
			FSC_ChecklistDocsController.saveRows(
				new List<Id>{ joinRec.Id },
				new List<Boolean>{ true }, // reviewer no usa esto
				new List<String>{ 'Comentario reviewer' },
				new List<String>{ 'Comentario oficial ignorado' },
				new List<String>{ 'Observado' }
			);
			Test.stopTest();
		}

		FSC_SolicitudDeCreditoYChecklistDeDocs__c updatedJoin = [
			SELECT FSC_NoAplica__c, FSC_Comentario__c, FSC_ComentarioOficialNegocio__c, FSC_EstadoRevision__c
			FROM FSC_SolicitudDeCreditoYChecklistDeDocs__c
			WHERE Id = :joinRec.Id
		];

		System.assertEquals(false, updatedJoin.FSC_NoAplica__c);
		System.assertEquals('Comentario reviewer', updatedJoin.FSC_Comentario__c);
		System.assertEquals(null, updatedJoin.FSC_ComentarioOficialNegocio__c);
		System.assertEquals('Observado', updatedJoin.FSC_EstadoRevision__c);
	}

	@IsTest
	static void testSaveRows_Reviewer_ObservadoSinComentario() {
		Id pymeRtId = getRecordTypeId(RT_PYME);
		if (pymeRtId == null) {
			System.assert(true);
			return;
		}

		User reviewerUser = createUserWithPermissionSet('FSC_PS_Recepcion_Control_Documentos', 'review02');

		ResidentialLoanApplication rla = createRla(RT_PYME);
		List<FSC_ChecklistDocumentos__c> docs = createChecklistDocs(1);
		FSC_SolicitudDeCreditoYChecklistDeDocs__c joinRec = createJoin(rla.Id, docs[0].Id, false, null, 'Pendiente');

		System.runAs(reviewerUser) {
			Boolean thrown = false;

			try {
				FSC_ChecklistDocsController.saveRows(
					new List<Id>{ joinRec.Id },
					new List<Boolean>{ false },
					new List<String>{ '' },
					new List<String>{ null },
					new List<String>{ 'Observado' }
				);
			} catch (AuraHandledException e) {
				thrown = true;
			}

			System.assertEquals(true, thrown);
		}
	}

	@IsTest
	static void testSaveRows_Reviewer_PuedeComentarAprobado() {
		Id pymeRtId = getRecordTypeId(RT_PYME);
		if (pymeRtId == null) {
			System.assert(true);
			return;
		}

		User reviewerUser = createUserWithPermissionSet('FSC_PS_Recepcion_Control_Documentos', 'review03');

		ResidentialLoanApplication rla = createRla(RT_PYME);
		List<FSC_ChecklistDocumentos__c> docs = createChecklistDocs(1);
		FSC_SolicitudDeCreditoYChecklistDeDocs__c joinRec = createJoin(rla.Id, docs[0].Id, false, null, 'Aprobado');

		System.runAs(reviewerUser) {
			Test.startTest();
			FSC_ChecklistDocsController.saveRows(
				new List<Id>{ joinRec.Id },
				new List<Boolean>{ null },
				new List<String>{ 'Comentario opcional aprobado' },
				new List<String>{ null },
				new List<String>{ null }
			);
			Test.stopTest();
		}

		FSC_SolicitudDeCreditoYChecklistDeDocs__c updatedJoin = [
			SELECT FSC_NoAplica__c, FSC_Comentario__c, FSC_EstadoRevision__c
			FROM FSC_SolicitudDeCreditoYChecklistDeDocs__c
			WHERE Id = :joinRec.Id
		];

		System.assertEquals(false, updatedJoin.FSC_NoAplica__c);
		System.assertEquals('Comentario opcional aprobado', updatedJoin.FSC_Comentario__c);
		System.assertEquals('Aprobado', updatedJoin.FSC_EstadoRevision__c);
	}

	@IsTest
	static void testSaveRows_Official_ActualizaNoAplicaYReseteaPendiente() {
		Id pymeRtId = getRecordTypeId(RT_PYME);
		if (pymeRtId == null) {
			System.assert(true);
			return;
		}

		User officialUser = createUserWithPermissionSet('FSC_PS_Oficial_Negocio', 'oficial1');

		ResidentialLoanApplication rla = createRla(RT_PYME);
		List<FSC_ChecklistDocumentos__c> docs = createChecklistDocs(1);
		FSC_SolicitudDeCreditoYChecklistDeDocs__c joinRec = createJoin(rla.Id, docs[0].Id, false, 'comentario previo', 'Observado');

		System.runAs(officialUser) {
			Test.startTest();
			FSC_ChecklistDocsController.saveRows(
				new List<Id>{ joinRec.Id },
				new List<Boolean>{ true },
				new List<String>{ 'esto no debería pisar comentario' },
				new List<String>{ 'Comentario oficial del oficial' },
				new List<String>{ 'Aprobado' }
			);
			Test.stopTest();
		}

		FSC_SolicitudDeCreditoYChecklistDeDocs__c updatedJoin = [
			SELECT FSC_NoAplica__c, FSC_Comentario__c, FSC_ComentarioOficialNegocio__c, FSC_EstadoRevision__c
			FROM FSC_SolicitudDeCreditoYChecklistDeDocs__c
			WHERE Id = :joinRec.Id
		];

		System.assertEquals(true, updatedJoin.FSC_NoAplica__c);
		System.assertEquals('comentario previo', updatedJoin.FSC_Comentario__c);
		System.assertEquals('Comentario oficial del oficial', updatedJoin.FSC_ComentarioOficialNegocio__c);
		System.assertEquals('Pendiente', updatedJoin.FSC_EstadoRevision__c);
	}

	@IsTest
	static void testSaveRows_Official_NoPuedeModificarAprobado() {
		Id pymeRtId = getRecordTypeId(RT_PYME);
		if (pymeRtId == null) {
			System.assert(true);
			return;
		}

		User officialUser = createUserWithPermissionSet('FSC_PS_Oficial_Negocio', 'oficial2');

		ResidentialLoanApplication rla = createRla(RT_PYME);
		List<FSC_ChecklistDocumentos__c> docs = createChecklistDocs(1);
		FSC_SolicitudDeCreditoYChecklistDeDocs__c joinRec = createJoin(rla.Id, docs[0].Id, false, 'comentario', 'Aprobado');

		System.runAs(officialUser) {
			Boolean thrown = false;

			try {
				FSC_ChecklistDocsController.saveRows(
					new List<Id>{ joinRec.Id },
					new List<Boolean>{ true },
					new List<String>{ 'comentario nuevo' },
					new List<String>{ 'comentario oficial nuevo' },
					new List<String>{ 'Pendiente' }
				);
			} catch (AuraHandledException e) {
				thrown = true;
			}

			System.assertEquals(true, thrown);
		}
	}

	@IsTest
	static void testSaveRows_Admin_PuedeModificarComentarioOficialAprobado() {
		FSC_ChecklistDocsController.testBypassPermissions = true;
		Id pymeRtId = getRecordTypeId(RT_PYME);
		if (pymeRtId == null) {
			System.assert(true);
			return;
		}

		ResidentialLoanApplication rla = createRla(RT_PYME);
		List<FSC_ChecklistDocumentos__c> docs = createChecklistDocs(1);
		FSC_SolicitudDeCreditoYChecklistDeDocs__c joinRec = createJoin(rla.Id, docs[0].Id, false, 'comentario', 'Aprobado');

		FSC_ChecklistDocsController.saveRows(
			new List<Id>{ joinRec.Id },
			new List<Boolean>{ null },
			new List<String>{ null },
			new List<String>{ 'comentario oficial actualizado' },
			new List<String>{ null }
		);

		FSC_SolicitudDeCreditoYChecklistDeDocs__c updatedJoin = [
			SELECT FSC_ComentarioOficialNegocio__c, FSC_EstadoRevision__c
			FROM FSC_SolicitudDeCreditoYChecklistDeDocs__c
			WHERE Id = :joinRec.Id
		];
		System.assertEquals('comentario oficial actualizado', updatedJoin.FSC_ComentarioOficialNegocio__c);
		System.assertEquals('Aprobado', updatedJoin.FSC_EstadoRevision__c);
	}

	@IsTest
	static void testSaveRows_JoinIdsVacio_NoHaceNada() {
		Test.startTest();
		FSC_ChecklistDocsController.saveRows(new List<Id>(), new List<Boolean>(), new List<String>(), new List<String>(), new List<String>());
		Test.stopTest();

		System.assert(true);
	}

	// =========================
	// Tests markDocumentAsPending
	// =========================

	@IsTest
	static void testMarkDocumentAsPending_Success() {
		Id pymeRtId = getRecordTypeId(RT_PYME);
		if (pymeRtId == null) {
			System.assert(true);
			return;
		}

		User officialUser = createUserWithPermissionSet('FSC_PS_Oficial_Negocio', 'oficial3');

		ResidentialLoanApplication rla = createRla(RT_PYME);
		List<FSC_ChecklistDocumentos__c> docs = createChecklistDocs(1);
		FSC_SolicitudDeCreditoYChecklistDeDocs__c joinRec = createJoin(rla.Id, docs[0].Id, false, 'comentario', 'Observado');

		System.runAs(officialUser) {
			Test.startTest();
			FSC_ChecklistDocsController.markDocumentAsPending(joinRec.Id);
			Test.stopTest();
		}

		FSC_SolicitudDeCreditoYChecklistDeDocs__c updatedJoin = [
			SELECT FSC_EstadoRevision__c
			FROM FSC_SolicitudDeCreditoYChecklistDeDocs__c
			WHERE Id = :joinRec.Id
		];

		System.assertEquals('Pendiente', updatedJoin.FSC_EstadoRevision__c);
	}

	@IsTest
	static void testMarkDocumentAsPending_NoPermisos() {
		Id pymeRtId = getRecordTypeId(RT_PYME);
		if (pymeRtId == null) {
			System.assert(true);
			return;
		}

		User standardUser = createUser('stdusr2');

		ResidentialLoanApplication rla = createRla(RT_PYME);
		List<FSC_ChecklistDocumentos__c> docs = createChecklistDocs(1);
		FSC_SolicitudDeCreditoYChecklistDeDocs__c joinRec = createJoin(rla.Id, docs[0].Id, false, 'comentario', 'Observado');

		System.runAs(standardUser) {
			Boolean thrown = false;

			try {
				FSC_ChecklistDocsController.markDocumentAsPending(joinRec.Id);
			} catch (AuraHandledException e) {
				thrown = true;
			}

			System.assertEquals(true, thrown);
		}
	}

	@IsTest
	static void testMarkDocumentAsPending_NoPuedeModificarAprobado() {
		Id pymeRtId = getRecordTypeId(RT_PYME);
		if (pymeRtId == null) {
			System.assert(true);
			return;
		}

		User officialUser = createUserWithPermissionSet('FSC_PS_Oficial_Negocio', 'oficial4');

		ResidentialLoanApplication rla = createRla(RT_PYME);
		List<FSC_ChecklistDocumentos__c> docs = createChecklistDocs(1);
		FSC_SolicitudDeCreditoYChecklistDeDocs__c joinRec = createJoin(rla.Id, docs[0].Id, false, 'comentario', 'Aprobado');

		System.runAs(officialUser) {
			Boolean thrown = false;

			try {
				FSC_ChecklistDocsController.markDocumentAsPending(joinRec.Id);
			} catch (AuraHandledException e) {
				thrown = true;
			}

			System.assertEquals(true, thrown);
		}
	}

	@IsTest
	static void testMarkDocumentAsPending_JoinIdNull() {
		Test.startTest();
		FSC_ChecklistDocsController.markDocumentAsPending(null);
		Test.stopTest();

		System.assert(true);
	}

	// =========================
	// Tests enforceSingleFileOnJoin
	// =========================

	@IsTest
	static void testEnforceSingleFileOnJoin_EliminaLosDemas() {
		FSC_ChecklistDocsController.testBypassPermissions = true;
		Id pymeRtId = getRecordTypeId(RT_PYME);
		if (pymeRtId == null) {
			System.assert(true);
			return;
		}

		ResidentialLoanApplication rla = createRla(RT_PYME);
		List<FSC_ChecklistDocumentos__c> docs = createChecklistDocs(1);
		FSC_SolicitudDeCreditoYChecklistDeDocs__c joinRec = createJoin(rla.Id, docs[0].Id, false, null, 'Pendiente');

		Id keepDocId = uploadFile(joinRec.Id, 'keep_file');
		Id deleteDocId = uploadFile(joinRec.Id, 'delete_file');

		Integer beforeCount = [
			SELECT COUNT()
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :joinRec.Id
		];
		System.assertEquals(2, beforeCount);

		Test.startTest();
		FSC_ChecklistDocsController.enforceSingleFileOnJoin(joinRec.Id, keepDocId);
		Test.stopTest();

		List<ContentDocumentLink> remaining = [
			SELECT Id, ContentDocumentId
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :joinRec.Id
		];

		System.assertEquals(1, remaining.size());
		System.assertEquals(keepDocId, remaining[0].ContentDocumentId);
	}

	@IsTest
	static void testEnforceSingleFileOnJoin_NullParams() {
		Test.startTest();
		FSC_ChecklistDocsController.enforceSingleFileOnJoin(null, null);
		FSC_ChecklistDocsController.enforceSingleFileOnJoin(UserInfo.getUserId(), null);
		FSC_ChecklistDocsController.enforceSingleFileOnJoin(null, UserInfo.getUserId());
		Test.stopTest();

		System.assert(true);
	}

	// =========================
	// Tests processUploadedFiles
	// =========================

	@IsTest
	static void testProcessUploadedFiles_PermiteMultiplesYConservaEstado() {
		FSC_ChecklistDocsController.testBypassPermissions = true;
		Id pymeRtId = getRecordTypeId(RT_PYME);
		if (pymeRtId == null) {
			System.assert(true);
			return;
		}

		ResidentialLoanApplication rla = createRla(RT_PYME);
		List<FSC_ChecklistDocumentos__c> docs = createChecklistDocs(1);
		FSC_SolicitudDeCreditoYChecklistDeDocs__c joinRec = createJoin(rla.Id, docs[0].Id, false, 'Debe conservarse', 'Observado');

		Id pdfId = uploadFileWithExtension(joinRec.Id, 'documento_pdf', 'pdf');
		Id imageId = uploadFileWithExtension(joinRec.Id, 'documento_imagen', 'jpg');
		Id wordId = uploadFileWithExtension(joinRec.Id, 'documento_word', 'docx');

		Test.startTest();
		FSC_ChecklistDocsController.UploadResultDTO result = FSC_ChecklistDocsController.processUploadedFiles(
			rla.Id,
			joinRec.Id,
			new List<Id>{ pdfId, imageId, wordId }
		);
		Test.stopTest();

		System.assertEquals(3, result.acceptedContentDocumentIds.size());
		System.assertEquals(0, result.rejectedFileNames.size());
		System.assertEquals(
			3,
			[SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :joinRec.Id],
			'La fila debe conservar todos los archivos cargados'
		);
		System.assertEquals(
			3,
			[SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :rla.Id],
			'Todos los archivos válidos deben quedar asociados también a la solicitud'
		);

		FSC_SolicitudDeCreditoYChecklistDeDocs__c unchangedJoin = [
			SELECT FSC_EstadoRevision__c, FSC_Comentario__c
			FROM FSC_SolicitudDeCreditoYChecklistDeDocs__c
			WHERE Id = :joinRec.Id
		];
		System.assertEquals('Observado', unchangedJoin.FSC_EstadoRevision__c);
		System.assertEquals('Debe conservarse', unchangedJoin.FSC_Comentario__c);
	}

	@IsTest
	static void testProcessUploadedFiles_RechazaFormatosInvalidosYSinExtension() {
		FSC_ChecklistDocsController.testBypassPermissions = true;
		Id pymeRtId = getRecordTypeId(RT_PYME);
		if (pymeRtId == null) {
			System.assert(true);
			return;
		}

		ResidentialLoanApplication rla = createRla(RT_PYME);
		List<FSC_ChecklistDocumentos__c> docs = createChecklistDocs(1);
		FSC_SolicitudDeCreditoYChecklistDeDocs__c joinRec = createJoin(rla.Id, docs[0].Id, false, null, 'Pendiente');

		Id validId = uploadFileWithExtension(joinRec.Id, 'documento_valido', 'pdf');
		Id mp4Id = uploadFileWithExtension(joinRec.Id, 'video_no_valido', 'mp4');
		Id wavId = uploadFileWithExtension(joinRec.Id, 'audio_no_valido', 'wav');
		Id dllId = uploadFileWithExtension(joinRec.Id, 'ejecutable_no_valido', 'dll');
		Id noExtensionId = uploadFileWithExtension(joinRec.Id, 'archivo_sin_extension', null);

		Test.startTest();
		FSC_ChecklistDocsController.UploadResultDTO result = FSC_ChecklistDocsController.processUploadedFiles(
			rla.Id,
			joinRec.Id,
			new List<Id>{ validId, mp4Id, wavId, dllId, noExtensionId }
		);
		Test.stopTest();

		System.assertEquals(new Set<Id>{ validId }, new Set<Id>(result.acceptedContentDocumentIds));
		System.assertEquals(4, result.rejectedFileNames.size());

		List<ContentDocumentLink> remainingJoinLinks = [
			SELECT ContentDocumentId
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :joinRec.Id
		];
		System.assertEquals(1, remainingJoinLinks.size());
		System.assertEquals(validId, remainingJoinLinks[0].ContentDocumentId);

		List<ContentDocumentLink> rlaLinks = [
			SELECT ContentDocumentId
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :rla.Id
		];
		System.assertEquals(1, rlaLinks.size());
		System.assertEquals(validId, rlaLinks[0].ContentDocumentId);

		FSC_SolicitudDeCreditoYChecklistDeDocs__c unchangedJoin = [
			SELECT FSC_EstadoRevision__c
			FROM FSC_SolicitudDeCreditoYChecklistDeDocs__c
			WHERE Id = :joinRec.Id
		];
		System.assertEquals('Pendiente', unchangedJoin.FSC_EstadoRevision__c);
	}

	@IsTest
	static void testProcessUploadedFiles_ValidaRelacionEntreFilaYSolicitud() {
		Id pymeRtId = getRecordTypeId(RT_PYME);
		if (pymeRtId == null) {
			System.assert(true);
			return;
		}

		ResidentialLoanApplication rla = createRla(RT_PYME);
		ResidentialLoanApplication anotherRla = createRla(RT_PYME);
		List<FSC_ChecklistDocumentos__c> docs = createChecklistDocs(1);
		FSC_SolicitudDeCreditoYChecklistDeDocs__c joinRec = createJoin(rla.Id, docs[0].Id, false, null, 'Pendiente');
		Id fileId = uploadFile(joinRec.Id, 'documento_relacion');

		Boolean thrown = false;
		try {
			FSC_ChecklistDocsController.processUploadedFiles(anotherRla.Id, joinRec.Id, new List<Id>{ fileId });
		} catch (AuraHandledException e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);
	}

	// =========================
	// Tests deleteUploadedFile
	// =========================

	@IsTest
	static void testDeleteUploadedFile_OficialEliminaArchivoDeOtroUsuario() {
		Id pymeRtId = getRecordTypeId(RT_PYME);
		if (pymeRtId == null) {
			System.assert(true);
			return;
		}

		ResidentialLoanApplication rla = createRla(RT_PYME);
		List<FSC_ChecklistDocumentos__c> docs = createChecklistDocs(1);
		// Observado y con "No aplica" marcado: igual se puede eliminar.
		FSC_SolicitudDeCreditoYChecklistDeDocs__c joinRec = createJoin(rla.Id, docs[0].Id, true, 'Revisar', 'Observado');
		Id cdId = uploadFile(joinRec.Id, 'archivo_a_eliminar');
		FSC_ChecklistDocsController.linkUploadedFilesToRla(rla.Id, new List<Id>{ cdId });
		User officialUser = createUserWithPermissionSet('FSC_PS_Oficial_Negocio', 'ofidel01');

		Test.startTest();
		System.runAs(officialUser) {
			FSC_ChecklistDocsController.deleteUploadedFile(joinRec.Id, cdId);
		}
		Test.stopTest();

		System.assertEquals(0, [SELECT COUNT() FROM ContentDocument WHERE Id = :cdId], 'El archivo debe eliminarse');
		System.assertEquals(0, [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :rla.Id], 'El archivo no debe quedar en la solicitud');
	}

	@IsTest
	static void testDeleteUploadedFile_NoEliminaPrecargado() {
		FSC_ChecklistDocsController.testBypassPermissions = true;
		Id pymeRtId = getRecordTypeId(RT_PYME);
		if (pymeRtId == null) {
			System.assert(true);
			return;
		}

		ResidentialLoanApplication rla = createRla(RT_PYME);
		List<FSC_ChecklistDocumentos__c> docs = createChecklistDocs(1);
		FSC_SolicitudDeCreditoYChecklistDeDocs__c joinRec = createJoin(rla.Id, docs[0].Id, false, null, 'Pendiente');
		Id cdId = uploadFile(rla.AccountId, 'archivo_cuenta');
		insert new ContentDocumentLink(LinkedEntityId = joinRec.Id, ContentDocumentId = cdId, ShareType = 'V', Visibility = 'AllUsers');

		List<FSC_ChecklistDocsController.RowDTO> rows = FSC_ChecklistDocsController.initAndGetRows(rla.Id);
		System.assertEquals(1, rows[0].files.size());
		System.assertEquals(false, rows[0].files[0].eliminable, 'Un archivo precargado no debe poder eliminarse');

		Boolean thrown = false;
		Test.startTest();
		try {
			FSC_ChecklistDocsController.deleteUploadedFile(joinRec.Id, cdId);
		} catch (AuraHandledException e) {
			thrown = true;
		}
		Test.stopTest();

		System.assertEquals(true, thrown);
		System.assertEquals(1, [SELECT COUNT() FROM ContentDocument WHERE Id = :cdId], 'El archivo original debe conservarse');
	}

	@IsTest
	static void testDeleteUploadedFile_NoEliminaAprobado() {
		FSC_ChecklistDocsController.testBypassPermissions = true;
		Id pymeRtId = getRecordTypeId(RT_PYME);
		if (pymeRtId == null) {
			System.assert(true);
			return;
		}

		ResidentialLoanApplication rla = createRla(RT_PYME);
		List<FSC_ChecklistDocumentos__c> docs = createChecklistDocs(1);
		FSC_SolicitudDeCreditoYChecklistDeDocs__c joinRec = createJoin(rla.Id, docs[0].Id, false, null, 'Aprobado');
		Id cdId = uploadFile(joinRec.Id, 'archivo_aprobado');

		Boolean thrown = false;
		Test.startTest();
		try {
			FSC_ChecklistDocsController.deleteUploadedFile(joinRec.Id, cdId);
		} catch (AuraHandledException e) {
			thrown = true;
		}
		Test.stopTest();

		System.assertEquals(true, thrown);
		System.assertEquals(1, [SELECT COUNT() FROM ContentDocument WHERE Id = :cdId]);
	}

	@IsTest
	static void testDeleteUploadedFile_ParametrosNulos() {
		Boolean thrown = false;
		try {
			FSC_ChecklistDocsController.deleteUploadedFile(null, null);
		} catch (AuraHandledException e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);
	}

	// =========================
	// Tests linkUploadedFilesToRla
	// =========================

	@IsTest
	static void testLinkUploadedFilesToRla_CreaSoloLinksFaltantes() {
		Id pymeRtId = getRecordTypeId(RT_PYME);
		if (pymeRtId == null) {
			System.assert(true);
			return;
		}

		ResidentialLoanApplication rla = createRla(RT_PYME);

		// Creamos 2 archivos sobre Account para luego enlazarlos al RLA
		Account tempAcc = createAccount();
		Id cd1 = uploadFile(tempAcc.Id, 'file_rla_1');
		Id cd2 = uploadFile(tempAcc.Id, 'file_rla_2');

		// Insertamos manualmente uno de los links al RLA
		insert new ContentDocumentLink(LinkedEntityId = rla.Id, ContentDocumentId = cd1, ShareType = 'V', Visibility = 'AllUsers');

		Test.startTest();
		FSC_ChecklistDocsController.linkUploadedFilesToRla(rla.Id, new List<Id>{ cd1, cd2 });
		Test.stopTest();

		List<ContentDocumentLink> links = [
			SELECT Id, ContentDocumentId
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :rla.Id
			ORDER BY ContentDocumentId
		];

		System.assertEquals(2, links.size());

		Set<Id> linkedDocIds = new Set<Id>();
		for (ContentDocumentLink l : links) {
			linkedDocIds.add(l.ContentDocumentId);
		}

		System.assert(linkedDocIds.contains(cd1));
		System.assert(linkedDocIds.contains(cd2));
	}

	@IsTest
	static void testLinkUploadedFilesToRla_NullOVacio_NoHaceNada() {
		Id pymeRtId = getRecordTypeId(RT_PYME);
		if (pymeRtId == null) {
			System.assert(true);
			return;
		}

		ResidentialLoanApplication rla = createRla(RT_PYME);

		Test.startTest();
		FSC_ChecklistDocsController.linkUploadedFilesToRla(null, new List<Id>{});
		FSC_ChecklistDocsController.linkUploadedFilesToRla(rla.Id, null);
		FSC_ChecklistDocsController.linkUploadedFilesToRla(rla.Id, new List<Id>());
		Test.stopTest();

		System.assert(true);
	}

	// La org exige Oficina, Codigo y Canal de Atencion en todo usuario (regla Validar_Campos_Obligatorios_Usuario).
	private static void completarCamposObligatoriosUsuario(User usuario) {
		Map<String, Schema.SObjectField> campos = Schema.SObjectType.User.fields.getMap();
		for (String campo : new List<String>{ 'USE_Oficina__c', 'Canal_Atencion__c' }) {
			if (!campos.containsKey(campo)) {
				continue;
			}
			for (Schema.PicklistEntry valor : campos.get(campo).getDescribe().getPicklistValues()) {
				if (valor.isActive()) {
					usuario.put(campo, valor.getValue());
					break;
				}
			}
		}
		if (campos.containsKey('USE_Codigo__c')) {
			usuario.put('USE_Codigo__c', 'TEST');
		}
		if (campos.containsKey('USE_Oficina__c')) {
			asegurarOficinaEnDatosMaestros((String) usuario.get('USE_Oficina__c'));
		}
	}

	// El flow "Información usuario" busca la oficina del usuario en Datos_Maestros__c y falla si no existe.
	private static void asegurarOficinaEnDatosMaestros(String oficina) {
		if (String.isBlank(oficina) || [SELECT COUNT() FROM Datos_Maestros__c WHERE DM_Codigo_Oficina__c = :oficina AND DM_Tipo__c = 'Oficina'] > 0) {
			return;
		}
		System.runAs(new User(Id = UserInfo.getUserId())) {
			insert new Datos_Maestros__c(Name = 'Oficina test ' + oficina, DM_Codigo_Oficina__c = oficina, DM_Tipo__c = 'Oficina');
		}
	}
}