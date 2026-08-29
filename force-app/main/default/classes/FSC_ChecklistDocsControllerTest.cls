@IsTest
private class FSC_ChecklistDocsControllerTest {
	private static final String RT_PYME = 'FSC_Solicitud_Credito_PYME';
	private static final String TIPO_SOLICITUD_PYME = 'Solicitud de crédito pyme';
	private static Integer accountSequence = 0;

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
		Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());
		Account acc = new Account(
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId(),
			FirstName = 'Cuenta',
			LastName = 'Checklist ' + System.now().getTime(),
			ACC_TipoIdentificacion__c = 'Cédula',
			ACC_NumIdentificacion__c = nextTestIdentification()
		);
		insert acc;
		return acc;
	}

	private static String nextTestIdentification() {
		accountSequence++;
		return '00108803' + String.valueOf(accountSequence).leftPad(3, '0');
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
		ContentVersion cv = new ContentVersion(
			Title = fileName,
			PathOnClient = fileName + '.pdf',
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

	private static Profile getProfileByName(String profileName) {
		List<Profile> profiles = [
			SELECT Id, Name
			FROM Profile
			WHERE Name = :profileName
			LIMIT 1
		];
		return profiles.isEmpty() ? null : profiles[0];
	}

	private static User createUserWithProfile(String profileName, String uniqueKey) {
		Profile p = getProfileByName(profileName);
		System.assertNotEquals(null, p, 'No existe el perfil requerido en la org: ' + profileName);

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
			ProfileId = p.Id
		);
		insert u;
		return u;
	}

	private static User createUserWithAnyDisallowedProfile(String uniqueKey) {
		List<Profile> profiles = [
			SELECT Id, Name
			FROM Profile
			WHERE Name NOT IN ('Recepción y control de documentos', 'System Administrator', 'Administrador del sistema', 'Oficial de negocio')
			LIMIT 1
		];

		System.assert(!profiles.isEmpty(), 'No se encontró un perfil no permitido para la prueba.');

		Profile p = profiles[0];

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
			ProfileId = p.Id
		);
		insert u;
		return u;
	}

	// =========================
	// Tests initAndGetRows
	// =========================

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

		User standardUser = createUserWithAnyDisallowedProfile('stdusr1');

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

		User reviewerUser = createUserWithProfile('Recepción y control de documentos', 'review01');

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

		User reviewerUser = createUserWithProfile('Recepción y control de documentos', 'review02');

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

		User reviewerUser = createUserWithProfile('Recepción y control de documentos', 'review03');

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

		User officialUser = createUserWithProfile('Oficial de negocio', 'oficial1');

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

		User officialUser = createUserWithProfile('Oficial de negocio', 'oficial2');

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
	static void testSaveRows_Admin_NoPuedeModificarComentarioOficialAprobado() {
		Id pymeRtId = getRecordTypeId(RT_PYME);
		if (pymeRtId == null) {
			System.assert(true);
			return;
		}

		ResidentialLoanApplication rla = createRla(RT_PYME);
		List<FSC_ChecklistDocumentos__c> docs = createChecklistDocs(1);
		FSC_SolicitudDeCreditoYChecklistDeDocs__c joinRec = createJoin(rla.Id, docs[0].Id, false, 'comentario', 'Aprobado');

		Boolean thrown = false;

		try {
			FSC_ChecklistDocsController.saveRows(
				new List<Id>{ joinRec.Id },
				new List<Boolean>{ null },
				new List<String>{ null },
				new List<String>{ 'comentario oficial bloqueado' },
				new List<String>{ null }
			);
		} catch (AuraHandledException e) {
			thrown = true;
		}

		System.assertEquals(true, thrown);
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

		User officialUser = createUserWithProfile('Oficial de negocio', 'oficial3');

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

		User standardUser = createUserWithAnyDisallowedProfile('stdusr2');

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

		User officialUser = createUserWithProfile('Oficial de negocio', 'oficial4');

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
}
