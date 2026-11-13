global with sharing class FSC_GenerarPDF implements omnistudio.VlocityOpenInterface, Callable {
	private static final String RT_CREDITO_PYME = 'FSC_Solicitud_Credito_PYME';
	private static final String RT_CREDITO_CONSUMO = 'FSC_Solicitud_Credito_Consumo';
	private static final String RT_CREDITO_VEHICULO = 'FSC_Solicitud_Credito_Vehiculo';
	private static final String RT_CREDITO_HIPOTECARIO = 'FSC_Solicitud_Credito_Hipotecario';
	private static final String DOC_TIPO_PYME = 'PyMe';
	private static final String DOC_TIPO_CONSUMO = 'Consumo';
	private static final String DOC_TIPO_VEHICULO = 'Vehiculo';
	private static final String DOC_TIPO_HIPOTECARIO = 'Hipotecario';
	private static final Map<String, String> CREDIT_LABELS = new Map<String, String>{
		RT_CREDITO_PYME => DOC_TIPO_PYME,
		RT_CREDITO_CONSUMO => DOC_TIPO_CONSUMO,
		RT_CREDITO_VEHICULO => DOC_TIPO_VEHICULO,
		RT_CREDITO_HIPOTECARIO => DOC_TIPO_HIPOTECARIO
	};
	private static final String DOC_PREFIX_CREDITO = 'Crédito ';
	private static final String TITLE_PREFIX_CREDITO_PYME_NORMALIZED = 'credito pyme - ';
	private static final String TITLE_PREFIX_CREDITO_CONSUMO_NORMALIZED = 'credito consumo - ';
	private static final String TITLE_PREFIX_CREDITO_VEHICULO_NORMALIZED = 'credito vehiculo - ';
	private static final String TITLE_PREFIX_CREDITO_VEHICULAR_NORMALIZED = 'credito vehicular - ';
	private static final String TITLE_PREFIX_CREDITO_HIPOTECARIO_NORMALIZED = 'credito hipotecario - ';
	private static final String LEGACY_TITLE_SOLICITUD_CONSUMO_NORMALIZED = 'solicitud de credito consumo';
	private static final String METHOD_GENERAR_PDF_PLANILLA_DESEMBOLSO = 'generarPDFPlanillaDesembolso';
	private static final String METHOD_GENERAR_PDF_SOLICITUD_PYME = 'generarPDFSolicitudPYME';
	private static final String METHOD_GENERAR_PDF_SOLICITUD_CONSUMO = 'generarPDFSolicitudConsumo';
	private static final String METHOD_REGENERAR_PDF_SOLICITUD_CREDITO = 'regenerarPDFSolicitudCredito';

	global Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
		try {
			if (String.isBlank(methodName)) {
				throw new AuraHandledException('methodName is required.');
			}

			if (methodName == METHOD_GENERAR_PDF_PLANILLA_DESEMBOLSO) {
				generarPDFPlanillaDesembolso(inputMap, outputMap);
				return true;
			} else if (methodName == METHOD_GENERAR_PDF_SOLICITUD_PYME) {
				generarPDFSolicitudPYME(inputMap, outputMap);
				return true;
			} else if (methodName == METHOD_GENERAR_PDF_SOLICITUD_CONSUMO) {
				generarPDFSolicitudConsumo(inputMap, outputMap);
				return true;
			} else if (methodName == METHOD_REGENERAR_PDF_SOLICITUD_CREDITO) {
				regenerarPDFSolicitudCredito(inputMap, outputMap);
				return true;
			}

			outputMap.put('success', false);
			outputMap.put('message', 'Unknown methodName: ' + methodName);
			return false;
		} catch (Exception e) {
			outputMap.put('success', false);
			outputMap.put('message', e.getMessage());
			outputMap.put('exceptionType', String.valueOf(e.getTypeName()));
			return false;
		}
	}

	public Object call(String action, Map<String, Object> args) {
		Map<String, Object> input = (Map<String, Object>) args.get('input');
		Map<String, Object> output = (Map<String, Object>) args.get('output');
		Map<String, Object> options = (Map<String, Object>) args.get('options');
		invokeMethod(action, input, output, options);
		return output;
	}

	private class GenerateResult {
		public Id contentDocumentId;
		public Id contentVersionId;
		public Id contentDocumentLinkId;
		public String title;
	}

	private static void generarPDFPlanillaDesembolso(Map<String, Object> inputMap, Map<String, Object> outputMap) {
		if (inputMap == null)
			inputMap = new Map<String, Object>();

		Id loanAppId = (Id) inputMap.get('Id');
		if (loanAppId == null) {
			throw new AuraHandledException('Missing residencialLoanApplicationId (or recordId).');
		}

		hydratePlanillaDesembolsoDefaults(inputMap, loanAppId);

		PageReference pr = Page.FSC_GenerarPDFDesembolso;
		for (String k : inputMap.keySet()) {
			Object v = inputMap.get(k);
			if (v == null)
				continue;

			if (
				v instanceof Datetime ||
				v instanceof Boolean ||
				v instanceof Integer ||
				v instanceof Long ||
				v instanceof Decimal ||
				v instanceof Double ||
				v instanceof Date ||
				v instanceof String
			) {
				pr.getParameters().put(k, String.valueOf(v));
			}
		}

		Blob pdfBlob;
		if (Test.isRunningTest()) {
			pdfBlob = Blob.valueOf('PDF generation is disabled in tests.');
		} else {
			pdfBlob = pr.getContentAsPDF();
		}
		String title = 'Hoja de desembolso - ' + ((String) inputMap.get('FormulaCedula')) + ' - ' + DateTime.now().format('dd-MM-yyyy HH:mm');
		String fileName = title.toLowerCase().endsWith('.pdf') ? title : (title + '.pdf');

		ContentVersion cv = new ContentVersion();
		cv.Title = title;
		cv.PathOnClient = fileName;
		cv.VersionData = pdfBlob;

		insert cv;

		cv = [
			SELECT Id, ContentDocumentId
			FROM ContentVersion
			WHERE Id = :cv.Id
			LIMIT 1
		];

		ContentDocumentLink cdl = new ContentDocumentLink();
		cdl.ContentDocumentId = cv.ContentDocumentId;
		cdl.LinkedEntityId = loanAppId;

		cdl.ShareType = 'V';
		cdl.Visibility = 'InternalUsers';

		insert cdl;

		FSC_PlanillaDesembolsoSaver.save(loanAppId, inputMap);

		outputMap.put('success', true);
		outputMap.put('contentDocumentId', cv.ContentDocumentId);
		outputMap.put('contentVersionId', cv.Id);
		outputMap.put('contentDocumentLinkId', cdl.Id);
		outputMap.put('title', title);
	}

	private static void hydratePlanillaDesembolsoDefaults(Map<String, Object> inputMap, Id loanAppId) {
		Boolean missingTasaFijaPor = !hasUsableInputValue(inputMap, 'FSC_TasaFijaPorMeses__c');
		Boolean missingTasaInteres = !hasUsableInputValue(inputMap, 'FSC_TasaInteres__c');

		if (
			inputMap == null ||
			(!missingTasaFijaPor && !missingTasaInteres) ||
			loanAppId.getSObjectType() != ResidentialLoanApplication.SObjectType
		) {
			return;
		}

		ResidentialLoanApplication rla = [
			SELECT FSC_TasaFijaPorMeses__c, FSC_TasaInteres__c
			FROM ResidentialLoanApplication
			WHERE Id = :loanAppId
			LIMIT 1
		];

		if (missingTasaFijaPor && rla.FSC_TasaFijaPorMeses__c != null) {
			inputMap.put('FSC_TasaFijaPorMeses__c', rla.FSC_TasaFijaPorMeses__c);
		}

		if (missingTasaInteres && rla.FSC_TasaInteres__c != null) {
			inputMap.put('FSC_TasaInteres__c', rla.FSC_TasaInteres__c);
		}
	}

	private static Boolean hasUsableInputValue(Map<String, Object> inputMap, String key) {
		if (inputMap == null || !inputMap.containsKey(key)) {
			return false;
		}

		Object value = inputMap.get(key);
		return value != null && !String.isBlank(String.valueOf(value));
	}

	private static void generarPDFSolicitudPYME(Map<String, Object> inputMap, Map<String, Object> outputMap) {
		generarPDFSolicitudCredito(inputMap, outputMap);
	}

	private static void generarPDFSolicitudConsumo(Map<String, Object> inputMap, Map<String, Object> outputMap) {
		generarPDFSolicitudCredito(inputMap, outputMap);
	}

	private static void regenerarPDFSolicitudCredito(Map<String, Object> inputMap, Map<String, Object> outputMap) {
		generarPDFSolicitudCredito(inputMap, outputMap);
	}

	private static void generarPDFSolicitudCredito(Map<String, Object> inputMap, Map<String, Object> outputMap) {
		Id rlaId = inputMap == null ? null : (Id) inputMap.get('Id');
		if (rlaId == null) {
			throw new AuraHandledException('Se requiere el Id de la solicitud de credito.');
		}
		validateGenerationPermissions();
		ResidentialLoanApplication rla = selectSolicitudCredito(rlaId);
		String recordTypeDeveloperName = rla.RecordType != null ? rla.RecordType.DeveloperName : null;
		String title = buildSolicitudCreditoTitle(rla, recordTypeDeveloperName);
		PageReference pr = recordTypeDeveloperName == RT_CREDITO_PYME ? Page.FSC_PYMESolicitudPDF : Page.FSC_ConsumoSolicitudPDF;
		pr.getParameters().put('id', String.valueOf(rlaId));

		Blob pdfBody;
		if (Test.isRunningTest()) {
			pdfBody = Blob.valueOf('TEST_PDF');
		} else {
			pdfBody = pr.getContentAsPDF();
		}
		if (pdfBody == null || pdfBody.size() == 0) {
			throw new AuraHandledException('No se pudo generar el PDF de la solicitud.');
		}
		lockSolicitudCredito(rla, title);
		Savepoint checkpoint = Database.setSavepoint();
		try {
			Integer deletedDocumentCount = deleteSolicitudCreditoDocument(rlaId);
			guardarPDFSolicitudCredito(rlaId, title, pdfBody, outputMap);
			outputMap.put('deletedDocumentCount', deletedDocumentCount);
		} catch (Exception error) {
			Database.rollback(checkpoint);
			throw error;
		}
	}

	private static void guardarPDFSolicitudCredito(Id rlaId, String title, Blob pdfBody, Map<String, Object> outputMap) {
		ContentVersion cv = new ContentVersion();
		cv.Title = title;
		cv.PathOnClient = title + '.pdf';
		cv.VersionData = pdfBody;
		cv.FSC_EnviarDocumento__c = true;
		cv.FSC_ClaveTecnicaPrecarga__c = FSC_ChecklistDocsPrecargaService.SOLICITUD_CREDITO;
		Database.insert(cv, AccessLevel.SYSTEM_MODE);
		ContentVersion cv2 = [
			SELECT Id, ContentDocumentId
			FROM ContentVersion
			WHERE Id = :cv.Id
			WITH USER_MODE
			LIMIT 1
		];
		ContentDocumentLink cdl = new ContentDocumentLink();
		cdl.LinkedEntityId = rlaId;
		cdl.ContentDocumentId = cv2.ContentDocumentId;
		cdl.ShareType = 'V';
		cdl.Visibility = 'AllUsers';
		Database.insert(cdl, AccessLevel.USER_MODE);
		outputMap.put('success', true);
		outputMap.put('ContentVersionId', cv2.Id);
		outputMap.put('ContentDocumentId', cv2.ContentDocumentId);
		outputMap.put('LinkedEntityId', rlaId);
		outputMap.put('title', title);
	}

	private static ResidentialLoanApplication selectSolicitudCredito(Id rlaId) {
		return [
			SELECT
				Id,
				AccountId,
				RecordTypeId,
				RecordType.DeveloperName,
				Account.Name,
				Account.FirstName,
				Account.LastName,
				Account.ACC_NumIdentificacion__c
			FROM ResidentialLoanApplication
			WHERE Id = :rlaId
			WITH USER_MODE
			LIMIT 1
		];
	}

	private static void lockSolicitudCredito(ResidentialLoanApplication rla, String title) {
		ResidentialLoanApplication lockedRla = [
			SELECT Id, AccountId, RecordTypeId
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
			WITH USER_MODE
			FOR UPDATE
		];
		// La cuenta puede estar siendo actualizada por las integraciones.
		Account currentAccount = [SELECT Id FROM Account WHERE Id = :rla.AccountId WITH USER_MODE];
		ResidentialLoanApplication currentRla = selectSolicitudCredito(rla.Id);
		if (
			lockedRla.AccountId != currentAccount.Id ||
			lockedRla.RecordTypeId != rla.RecordTypeId ||
			!title.equals(buildSolicitudCreditoTitle(currentRla, currentRla.RecordType.DeveloperName))
		) {
			throw new AuraHandledException('La cuenta cambio durante la generacion. Regenera la solicitud.');
		}
	}

	private static void validateGenerationPermissions() {
		if (
			!Schema.sObjectType.ContentVersion.isCreateable() ||
			!Schema.sObjectType.ContentVersion.fields.Title.isCreateable() ||
			!Schema.sObjectType.ContentVersion.fields.PathOnClient.isCreateable() ||
			!Schema.sObjectType.ContentVersion.fields.VersionData.isCreateable() ||
			!Schema.sObjectType.ContentDocumentLink.isCreateable()
		) {
			throw new AuraHandledException('No tienes permisos para generar la solicitud de credito.');
		}
	}

	private static String buildSolicitudCreditoTitle(ResidentialLoanApplication rla, String recordTypeDeveloperName) {
		if (rla == null) {
			throw new AuraHandledException('No se encontro la solicitud de credito.');
		}
		String tipoCredito = CREDIT_LABELS.get(recordTypeDeveloperName);
		if (tipoCredito == null) {
			throw new AuraHandledException('La solicitud de credito no pertenece a un RecordType soportado.');
		}
		List<String> accountNameParts = new List<String>();
		if (rla.Account != null) {
			if (!String.isBlank(rla.Account.FirstName)) {
				accountNameParts.add(rla.Account.FirstName);
			}
			if (!String.isBlank(rla.Account.LastName)) {
				accountNameParts.add(rla.Account.LastName);
			}
		}
		String accountFullName = String.join(accountNameParts, ' ');
		if (String.isBlank(accountFullName) && rla.Account != null) {
			accountFullName = rla.Account.Name;
		}
		String documentNumber = rla.Account != null ? rla.Account.ACC_NumIdentificacion__c : null;
		if (String.isBlank(accountFullName) || String.isBlank(documentNumber)) {
			throw new AuraHandledException('La Account del RLA debe tener nombre y numero de identificacion.');
		}
		return DOC_PREFIX_CREDITO + tipoCredito + ' - ' + accountFullName + ' - ' + documentNumber;
	}

	private static Integer deleteSolicitudCreditoDocument(Id rlaId) {
		Set<Id> contentDocumentIds = new Set<Id>();
		List<ContentDocumentLink> files = selectSolicitudFiles(new Set<Id>{ rlaId }).get(rlaId);
		for (ContentDocumentLink link : files) {
			contentDocumentIds.add(link.ContentDocumentId);
		}
		if (contentDocumentIds.isEmpty()) {
			return 0;
		}
		List<ContentDocumentLink> sharedLinks = [
			SELECT LinkedEntityId
			FROM ContentDocumentLink
			WHERE ContentDocumentId IN :contentDocumentIds
			WITH USER_MODE
		];
		for (ContentDocumentLink link : sharedLinks) {
			if (link.LinkedEntityId.getSObjectType() == ResidentialLoanApplication.SObjectType && link.LinkedEntityId != rlaId) {
				throw new AuraHandledException('Una planilla esta vinculada a otra solicitud. Corrige sus vinculos antes de regenerar.');
			}
		}
		List<ContentDocument> documentsToDelete = [SELECT Id FROM ContentDocument WHERE Id IN :contentDocumentIds WITH USER_MODE];
		Database.delete(documentsToDelete, true, AccessLevel.USER_MODE);
		return contentDocumentIds.size();
	}

	@TestVisible
	private static Boolean isSolicitudCreditoFile(String title, String technicalKey) {
		if (technicalKey == FSC_ChecklistDocsPrecargaService.SOLICITUD_CREDITO) {
			return true;
		}
		if (String.isBlank(title)) {
			return false;
		}
		String normalized = title.trim().toLowerCase().replace('é', 'e');
		if (normalized.startsWith('(')) {
			normalized = normalized.substring(1);
		}
		return normalized.startsWith(TITLE_PREFIX_CREDITO_PYME_NORMALIZED) ||
			normalized.startsWith(TITLE_PREFIX_CREDITO_CONSUMO_NORMALIZED) ||
			normalized.startsWith(TITLE_PREFIX_CREDITO_VEHICULO_NORMALIZED) ||
			normalized.startsWith(TITLE_PREFIX_CREDITO_VEHICULAR_NORMALIZED) ||
			normalized.startsWith(TITLE_PREFIX_CREDITO_HIPOTECARIO_NORMALIZED) ||
			normalized == LEGACY_TITLE_SOLICITUD_CONSUMO_NORMALIZED;
	}

	private static Map<Id, List<ContentDocumentLink>> selectSolicitudFiles(Set<Id> rlaIds) {
		Map<Id, List<ContentDocumentLink>> files = new Map<Id, List<ContentDocumentLink>>();
		for (Id rlaId : rlaIds) {
			files.put(rlaId, new List<ContentDocumentLink>());
		}
		List<ContentDocumentLink> links = [
			SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.Title
			FROM ContentDocumentLink
			WHERE LinkedEntityId IN :rlaIds
			WITH USER_MODE
		];
		Set<Id> documentIds = new Set<Id>();
		for (ContentDocumentLink link : links) {
			documentIds.add(link.ContentDocumentId);
		}
		Map<Id, String> keysByDocument = new Map<Id, String>();
		if (!documentIds.isEmpty()) {
			if (!Schema.sObjectType.ContentVersion.isAccessible()) {
				throw new AuraHandledException('No tienes permisos para consultar los archivos de la solicitud.');
			}
			List<ContentVersion> latestVersions = [
				SELECT ContentDocumentId, FSC_ClaveTecnicaPrecarga__c
				FROM ContentVersion
				WHERE ContentDocumentId IN :documentIds AND IsLatest = TRUE
				WITH SYSTEM_MODE
			];
			for (ContentVersion version : latestVersions) {
				keysByDocument.put(version.ContentDocumentId, version.FSC_ClaveTecnicaPrecarga__c);
			}
		}
		for (ContentDocumentLink link : links) {
			if (isSolicitudCreditoFile(link.ContentDocument.Title, keysByDocument.get(link.ContentDocumentId))) {
				files.get(link.LinkedEntityId).add(link);
			}
		}
		return files;
	}

	public static void validarSolicitudParaFirma(Id rlaId) {
		if (rlaId == null) {
			throw new AuraHandledException('Se requiere el Id de la solicitud de credito.');
		}
		List<ContentDocumentLink> files = selectSolicitudFiles(new Set<Id>{ rlaId }).get(rlaId);
		if (files.isEmpty()) {
			return;
		}
		ResidentialLoanApplication rla = selectSolicitudCredito(rlaId);
		String expectedTitle = buildSolicitudCreditoTitle(rla, rla.RecordType.DeveloperName);
		if (files.size() != 1 || !expectedTitle.equals(files[0].ContentDocument.Title)) {
			throw new AuraHandledException(
				'Regenera la solicitud de credito: debe existir una sola planilla con la identificacion actual de la Account.'
			);
		}
	}
}