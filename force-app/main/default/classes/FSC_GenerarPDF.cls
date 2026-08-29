global with sharing class FSC_GenerarPDF implements omnistudio.VlocityOpenInterface, Callable {
	private static final String RT_CREDITO_PYME = 'FSC_Solicitud_Credito_PYME';
	private static final String RT_CREDITO_CONSUMO = 'FSC_Solicitud_Credito_Consumo';
	private static final String DOC_PREFIX_CREDITO = 'Crédito ';
	private static final String DOC_TIPO_PYME = 'PyMe';
	private static final String DOC_TIPO_CONSUMO = 'Consumo';
	private static final String LEGACY_DOC_PREFIX_CREDITO_PYME = '(Crédito PyMe - ';

	global Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
		try {
			if (String.isBlank(methodName)) {
				throw new AuraHandledException('methodName is required.');
			}

			if (methodName == 'generarPDFPlanillaDesembolso') {
				generarPDFPlanillaDesembolso(inputMap, outputMap);
				return true;
			} else if (methodName == 'generarPDFSolicitudPYME') {
				generarPDFSolicitudPYME(inputMap, outputMap);
				return true;
			} else if (methodName == 'generarPDFSolicitudConsumo') {
				generarPDFSolicitudConsumo(inputMap, outputMap);
				return true;
			} else if (methodName == 'regenerarPDFSolicitudCredito') {
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

		// Guarda la planilla aunque el DataRaptor respete permisos del perfil.
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
		Id rlaId = (Id) String.valueOf(inputMap.get('Id'));
		String title = (String) String.valueOf(inputMap.get('Title'));

		PageReference pr = Page.FSC_PYMESolicitudPDF;
		pr.getParameters().put('id', String.valueOf(rlaId));

		Blob pdfBody;
		if (Test.isRunningTest()) {
			pdfBody = Blob.valueOf('TEST_PDF');
		} else {
			pdfBody = pr.getContentAsPDF();
		}

		ContentVersion cv = new ContentVersion();
		cv.Title = title;
		cv.PathOnClient = title + '.pdf';
		cv.VersionData = pdfBody;
		cv.FSC_EnviarDocumento__c = true;
		insert cv;

		ContentVersion cv2 = [
			SELECT Id, ContentDocumentId
			FROM ContentVersion
			WHERE Id = :cv.Id
			LIMIT 1
		];

		ContentDocumentLink cdl = new ContentDocumentLink();
		cdl.LinkedEntityId = rlaId;
		cdl.ContentDocumentId = cv2.ContentDocumentId;
		cdl.ShareType = 'V';
		cdl.Visibility = 'AllUsers';
		insert cdl;

		outputMap.put('success', true);
		outputMap.put('ContentVersionId', cv2.Id);
		outputMap.put('ContentDocumentId', cv2.ContentDocumentId);
		outputMap.put('LinkedEntityId', rlaId);
	}

	private static void generarPDFSolicitudConsumo(Map<String, Object> inputMap, Map<String, Object> outputMap) {
		Id rlaId = (Id) String.valueOf(inputMap.get('Id'));
		String title = String.valueOf(inputMap.get('Title'));
		if (String.isBlank(title)) {
			title = 'Solicitud de credito consumo';
		}

		PageReference pr = Page.FSC_ConsumoSolicitudPDF;
		pr.getParameters().put('id', String.valueOf(rlaId));

		Blob pdfBody;
		if (Test.isRunningTest()) {
			pdfBody = Blob.valueOf('TEST_PDF_CONSUMO');
		} else {
			pdfBody = pr.getContentAsPDF();
		}

		ContentVersion cv = new ContentVersion();
		cv.Title = title;
		cv.PathOnClient = title + '.pdf';
		cv.VersionData = pdfBody;
		cv.FSC_EnviarDocumento__c = true;
		insert cv;

		ContentVersion cv2 = [
			SELECT Id, ContentDocumentId
			FROM ContentVersion
			WHERE Id = :cv.Id
			LIMIT 1
		];

		ContentDocumentLink cdl = new ContentDocumentLink();
		cdl.LinkedEntityId = rlaId;
		cdl.ContentDocumentId = cv2.ContentDocumentId;
		cdl.ShareType = 'V';
		cdl.Visibility = 'AllUsers';
		insert cdl;

		outputMap.put('success', true);
		outputMap.put('ContentVersionId', cv2.Id);
		outputMap.put('ContentDocumentId', cv2.ContentDocumentId);
		outputMap.put('LinkedEntityId', rlaId);
		outputMap.put('title', title);
	}

	private static void regenerarPDFSolicitudCredito(Map<String, Object> inputMap, Map<String, Object> outputMap) {
		if (inputMap == null) {
			inputMap = new Map<String, Object>();
		}

		Id rlaId = (Id) String.valueOf(inputMap.get('Id'));
		if (rlaId == null) {
			throw new AuraHandledException('Missing residencialLoanApplicationId (or recordId).');
		}

		ResidentialLoanApplication rla = [
			SELECT Id, RecordType.DeveloperName, Account.FirstName, Account.LastName, Account.ACC_NumIdentificacion__c
			FROM ResidentialLoanApplication
			WHERE Id = :rlaId
			LIMIT 1
		];

		String recordTypeDeveloperName = rla.RecordType != null ? rla.RecordType.DeveloperName : null;
		String title = buildSolicitudCreditoTitle(rla, recordTypeDeveloperName);
		Integer deletedDocumentCount = deleteSolicitudCreditoDocument(rlaId, title, recordTypeDeveloperName);

		Map<String, Object> generationInput = new Map<String, Object>(inputMap);
		generationInput.put('Id', rlaId);
		generationInput.put('Title', title);

		if (recordTypeDeveloperName == RT_CREDITO_PYME) {
			generarPDFSolicitudPYME(generationInput, outputMap);
		} else if (recordTypeDeveloperName == RT_CREDITO_CONSUMO) {
			generarPDFSolicitudConsumo(generationInput, outputMap);
		} else {
			throw new AuraHandledException('RecordType no soportado para regenerar la solicitud de credito: ' + recordTypeDeveloperName);
		}

		outputMap.put('deletedDocumentCount', deletedDocumentCount);
		outputMap.put('title', title);
	}

	private static String buildSolicitudCreditoTitle(ResidentialLoanApplication rla, String recordTypeDeveloperName) {
		if (rla == null) {
			throw new AuraHandledException('No se encontro la solicitud de credito.');
		}

		if (recordTypeDeveloperName != RT_CREDITO_PYME && recordTypeDeveloperName != RT_CREDITO_CONSUMO) {
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
		if (String.isBlank(accountFullName)) {
			throw new AuraHandledException('La solicitud de credito no tiene FirstName y LastName en la cuenta asociada.');
		}

		String documentNumber = rla.Account != null ? rla.Account.ACC_NumIdentificacion__c : null;
		if (String.isBlank(documentNumber)) {
			throw new AuraHandledException('La cuenta asociada no tiene ACC_NumIdentificacion__c para regenerar el PDF.');
		}

		String tipoCredito = recordTypeDeveloperName == RT_CREDITO_PYME ? DOC_TIPO_PYME : DOC_TIPO_CONSUMO;
		return DOC_PREFIX_CREDITO + tipoCredito + ' - ' + accountFullName + ' - ' + documentNumber;
	}

	private static Integer deleteSolicitudCreditoDocument(Id rlaId, String title, String recordTypeDeveloperName) {
		Set<Id> contentDocumentIds = new Set<Id>();
		for (ContentDocumentLink link : [
			SELECT ContentDocumentId
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :rlaId AND ContentDocument.Title = :title
		]) {
			contentDocumentIds.add(link.ContentDocumentId);
		}

		if (contentDocumentIds.isEmpty() && recordTypeDeveloperName == RT_CREDITO_PYME) {
			for (ContentDocumentLink link : [
				SELECT ContentDocumentId, ContentDocument.Title
				FROM ContentDocumentLink
				WHERE LinkedEntityId = :rlaId
			]) {
				String documentTitle = link.ContentDocument != null ? link.ContentDocument.Title : null;
				if (!String.isBlank(documentTitle) && documentTitle.contains('(' + DOC_PREFIX_CREDITO + DOC_TIPO_PYME + ' - ')) {
					contentDocumentIds.add(link.ContentDocumentId);
				}
			}
		}

		if (contentDocumentIds.isEmpty()) {
			return 0;
		}

		delete [
			SELECT Id
			FROM ContentDocument
			WHERE Id IN :contentDocumentIds
		];

		return contentDocumentIds.size();
	}
}