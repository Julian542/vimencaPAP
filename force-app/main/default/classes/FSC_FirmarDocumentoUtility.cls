public without sharing class FSC_FirmarDocumentoUtility {
	public class FSC_FirmarDocumentoUtilityException extends Exception {
	}

	private static final String BTN_GESTIONAR_FIRMAS = 'Gestionar firmas';
	private static final String PROCESO_CREDITO = 'CREDITO_PYME';
	private static final Set<String> PROCESOS_CREDITO = new Set<String>{
		'CREDITO',
		'CREDITO_PYME',
		'CREDITO_CONSUMO',
		'CREDITO_VEHICULO',
		'CREDITO_HIPOTECARIO'
	};
	private static final String PROCESO_PAGARE = 'PAGARE';
	private static final String PROCESO_CONTRATO = 'CONTRATO';
	private static final String DISPLAYED_EMAIL_SENDER = 'Banco Vimenca';
	private static final String RT_CREDITO_PYME = 'FSC_Solicitud_Credito_PYME';
	private static final String RT_CREDITO_CONSUMO = 'FSC_Solicitud_Credito_Consumo';
	private static final String RT_CREDITO_VEHICULO = 'FSC_Solicitud_Credito_Vehiculo';
	private static final String RT_CREDITO_HIPOTECARIO = 'FSC_Solicitud_Credito_Hipotecario';
	private static final String RT_LEGACY_CONSUMO = 'Consumo';
	private static final String RT_LEGACY_VEHICULO = 'Vehiculo';
	private static final String RT_LEGACY_HIPOTECARIO = 'Hipotecario';
	private static final Set<String> ADMIN_PROFILE_NAMES = new Set<String>{
		'Administrador del sistema',
		'System Administrator'
	};

	@AuraEnabled(cacheable=false)
	public static SendDocumentsResult enviarDocumentosFirmar(String buttonName, String recordId) {
		validarEntrada(buttonName, recordId);

		if (buttonName != BTN_GESTIONAR_FIRMAS) {
			throw new CalloutException('Tipo de proceso no reconocido: "' + buttonName + '".');
		}

		SendDocumentsResult response = new SendDocumentsResult();
		response.creditoSent = false;
		response.pagareSent = false;
		response.contratoSent = false;
		response.documentsSent = false;
		response.physicalOnly = false;
		response.success = false;
		List<String> queuedProcesses = new List<String>();
		List<String> skippedProcesses = new List<String>();
		List<String> queuedProcessCodes = new List<String>();

		ResidentialLoanApplication rla = [
			SELECT Id, OwnerId, Owner.Name, FSC_EnviadoAFirmar__c, RecordType.DeveloperName
			FROM ResidentialLoanApplication
			WHERE Id = :recordId
			LIMIT 1
			FOR UPDATE
		];

		validarUsuarioPuedeEnviarAFirmar(rla);

		if (rla.FSC_EnviadoAFirmar__c == true) {
			response.message = 'La solicitud ya fue enviada a firmar.';
			return response;
		}

		String recordTypeDeveloperName = rla.RecordType != null ? rla.RecordType.DeveloperName : null;
		List<ConfigProceso> digitalProcesses = getConfiguredDigitalProcesses(recordTypeDeveloperName, recordId);
		for (ConfigProceso config : digitalProcesses) {
			if (tieneArchivosPendientes(config, recordId)) {
				queuedProcesses.add(config.processLabel);
				queuedProcessCodes.add(config.proceso);
				if (config.proceso == PROCESO_CREDITO) {
					response.creditoSent = true;
				} else if (config.proceso == PROCESO_PAGARE) {
					response.pagareSent = true;
				} else if (config.proceso == PROCESO_CONTRATO) {
					response.contratoSent = true;
				}
			} else {
				skippedProcesses.add(config.processLabel);
			}
		}

		response.documentsSent = !queuedProcesses.isEmpty();
		response.physicalOnly = !response.documentsSent &&
			digitalProcesses.isEmpty() &&
			FSC_ConfiguracionFirmaDocumentosService.hasDocumentosFirmaFisica(recordTypeDeveloperName);
		response.success = response.documentsSent || response.physicalOnly;
		response.message = buildSendDocumentsMessage(queuedProcesses, skippedProcesses);
		if (response.physicalOnly) {
			response.message = 'Todos los documentos de esta solicitud estan configurados para firma fisica.';
		}

		if (response.documentsSent) {
			rla.FSC_EnviadoAFirmar__c = true;
			update rla;
			for (String queuedProcessCode : queuedProcessCodes) {
				System.enqueueJob(new FSC_EnviarEnvelopeQueueable(queuedProcessCode, recordId, false));
			}
		}

		return response;
	}

	public static EnvelopeStatus obtenerEstadoEnvelope(String envelopeId) {
		EnvelopeStatus result = new EnvelopeStatus();
		HttpRequest req = new HttpRequest();
		req.setEndpoint('callout:VFS_Esignanywhere/Api/v6/envelope/' + envelopeId);
		req.setMethod('GET');
		req.setHeader('Content-Type', 'application/json');
		HttpResponse res;
		Exception caughtException;
		try {
			Http http = new Http();
			res = http.send(req);
			caughtException = null;
			Map<String, Object> respMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
			if (respMap.containsKey('EnvelopeStatus')) {
				result.success = true;
				result.envelopeStatus = (String) respMap.get('EnvelopeStatus');
				result.debugInfo = 'StatusCode: ' + res.getStatusCode() + '\nBody: ' + res.getBody();
				List<Object> activities = (List<Object>) respMap.get('Activities');
				if (activities != null && !activities.isEmpty()) {
					for (Object activityObj : activities) {
						Map<String, Object> activity = (Map<String, Object>) activityObj;

						String status = (String) activity.get('Status');
						String finishedDate = (String) activity.get('FinishedDate');

						if (status == 'Completed' && !String.isBlank(finishedDate)) {
							result.envelopeFinishedDate = finishedDate;
							break;
						}
					}
				}
			} else {
				result.success = false;
				result.errorId = (String) respMap.get('ErrorId');
				result.message = (String) respMap.get('Message');
				result.traceId = (String) respMap.get('TraceId');
				result.debugInfo = 'StatusCode: ' + res.getStatusCode() + '\nBody: ' + res.getBody();
			}
		} catch (Exception e) {
			res = new HttpResponse();
			caughtException = e;
			result.success = false;
			result.message = 'Error al consumir el servicio: ' + e.getMessage();
			result.debugInfo = 'Excepcion: ' + e.getMessage();
		}

		INTLogger.INTLoggerResult logResult = INTLogger.logCallout('VFS_Esignanywhere', 'envelopeStatus', req, res);
		if (!logResult.success) {
			System.debug('Error guardando log: ' + logResult.message);
		}

		return result;
	}

	public static List<SignedEnvelopeFile> obtenerArchivosFirmadosEnvelope(String envelopeId) {
		if (String.isBlank(envelopeId)) {
			throw new FSC_FirmarDocumentoUtilityException('EnvelopeId requerido para descargar archivos firmados.');
		}

		HttpRequest req = new HttpRequest();
		req.setEndpoint('callout:VFS_Esignanywhere/Api/v6/envelope/' + EncodingUtil.urlEncode(envelopeId, 'UTF-8') + '/files');
		req.setMethod('GET');
		req.setHeader('Accept', 'application/pdf, application/zip, application/json');
		HttpResponse res;

		try {
			Http http = new Http();
			res = http.send(req);

			if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
				throw new FSC_FirmarDocumentoUtilityException(
					'No se pudieron descargar los archivos firmados. StatusCode: ' + res.getStatusCode()
				);
			}

			List<SignedEnvelopeFile> files = parseSignedEnvelopeFiles(envelopeId, res);
			if (files.isEmpty()) {
				throw new FSC_FirmarDocumentoUtilityException('La descarga del envelope no devolvio archivos firmados.');
			}

			INTLogger.INTLoggerResult logResult = INTLogger.logCallout('VFS_Esignanywhere', 'envelopeFiles', req, res);
			if (!logResult.success) {
				System.debug('Error guardando log: ' + logResult.message);
			}

			return files;
		} catch (FSC_FirmarDocumentoUtilityException e) {
			if (res == null) {
				res = new HttpResponse();
			}
			INTLogger.INTLoggerResult logResult = INTLogger.logCallout('VFS_Esignanywhere', 'envelopeFiles', req, res);
			if (!logResult.success) {
				System.debug('Error guardando log: ' + logResult.message);
			}
			throw e;
		} catch (Exception e) {
			if (res == null) {
				res = new HttpResponse();
			}
			INTLogger.INTLoggerResult logResult = INTLogger.logCallout('VFS_Esignanywhere', 'envelopeFiles', req, res);
			if (!logResult.success) {
				System.debug('Error guardando log: ' + logResult.message);
			}
			throw new FSC_FirmarDocumentoUtilityException('Error al descargar archivos firmados: ' + e.getMessage());
		}
	}

	public static VFS_EsignSendingEnvelope.EnvelopeResult enviarPorProceso(String proceso, String recordId) {
		try {
			ConfigProceso config = getConfigProceso(proceso, recordId);
			String recordTypeDeveloperName = getRecordTypeDeveloperName(recordId);

			if (!FSC_ConfiguracionFirmaDocumentosService.isFirmaDigital(recordTypeDeveloperName, config.documentName)) {
				VFS_EsignSendingEnvelope.EnvelopeResult result = new VFS_EsignSendingEnvelope.EnvelopeResult();
				result.success = false;
				result.message = 'El documento "' + config.processLabel + '" esta configurado para firma fisica.';
				return result;
			}

			List<ContentVersion> files = obtenerArchivosPendientes(recordId, config.titleLike);
			if (files.isEmpty()) {
				VFS_EsignSendingEnvelope.EnvelopeResult result = new VFS_EsignSendingEnvelope.EnvelopeResult();
				result.success = false;
				result.message = 'No se encontraron archivos pendientes para "' + config.buttonName + '".';
				return result;
			}

			List<VFS_EsignSendingEnvelope.EnvelopeDocument> documents = construirDocuments(files);
			List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = FSC_NuevoDocumentoEnvelope.crearFirmas(
				recordId,
				config.signatureProcess,
				documents
			);

			if (actions == null || actions.isEmpty()) {
				throw new FSC_FirmarDocumentoUtilityException(
					'No se pudieron generar acciones de firma para el proceso "' + config.buttonName + '".'
				);
			}

			VFS_EsignSendingEnvelope.EnvelopeRequest req = new VFS_EsignSendingEnvelope.EnvelopeRequest();
			req.Name = cleanButtonName(config.buttonName);
			req.EmailSubject = buildEmailSubject(config);
			req.EmailBody = buildEmailBody(config);
			req.DisplayedEmailSender = DISPLAYED_EMAIL_SENDER;
			req.Documents = documents;
			req.Activities = construirActivities(actions);

			VFS_EsignSendingEnvelope.EnvelopeResult result = VFS_EsignSendingEnvelope.sendEnvelope(req);

			if (result != null && result.success) {
				marcarComoEnviado(files, result.envelopeId);
			}

			return result;
		} catch (FSC_FirmarDocumentoUtilityException e) {
			throw new CalloutException(e.getMessage());
		} catch (CalloutException e) {
			throw e;
		} catch (Exception e) {
			throw new CalloutException('Error al enviar el proceso "' + proceso + '": ' + e.getMessage());
		}
	}

	private static void validarEntrada(String buttonName, String recordId) {
		if (String.isBlank(buttonName)) {
			throw new CalloutException('El nombre del boton no puede estar vacio.');
		}
		if (String.isBlank(recordId)) {
			throw new CalloutException('El ID del registro no puede estar vacio.');
		}
	}

	private static void validarUsuarioPuedeEnviarAFirmar(ResidentialLoanApplication rla) {
		Profile currentProfile = [
			SELECT Name
			FROM Profile
			WHERE Id = :UserInfo.getProfileId()
			LIMIT 1
		];

		if (rla.OwnerId != UserInfo.getUserId() && !ADMIN_PROFILE_NAMES.contains(currentProfile.Name)) {
			throw new AuraHandledException(
				'Solo el dueño del registro puede enviar a firmar la solicitud de crédito: ' + rla.Owner.Name
			);
		}
	}

	private static ConfigProceso getConfigProceso(String proceso, String recordId) {
		if (PROCESOS_CREDITO.contains(proceso)) {
			String recordTypeDeveloperName = getRecordTypeDeveloperName(recordId);
			String emailCreditLabel = getEmailCreditLabel(recordTypeDeveloperName);
			String titleCreditLabel = getTitleCreditLabel(recordTypeDeveloperName);

			return new ConfigProceso(
				'Firmar Credito ' + emailCreditLabel,
				'Crédito ' + titleCreditLabel + ' - %',
				'Credito ' + emailCreditLabel,
				emailCreditLabel,
				PROCESO_CREDITO,
				false,
				FSC_ConfiguracionFirmaDocumentosService.DOCUMENTO_PLANILLA
			);
		}
		if (proceso == PROCESO_PAGARE) {
			return new ConfigProceso(
				'Firmar Pagare',
				'Pagare %',
				'Pagare',
				null,
				PROCESO_PAGARE,
				true,
				FSC_ConfiguracionFirmaDocumentosService.DOCUMENTO_PAGARE
			);
		}
		if (proceso == PROCESO_CONTRATO) {
			return new ConfigProceso(
				'Firmar Contrato',
				null,
				'Contrato',
				null,
				PROCESO_CONTRATO,
				false,
				FSC_ConfiguracionFirmaDocumentosService.DOCUMENTO_CONTRATO
			);
		}

		throw new FSC_FirmarDocumentoUtilityException('No existe configuracion para el proceso "' + proceso + '".');
	}

	public static Boolean tieneArchivosPendientes(String proceso, String recordId) {
		ConfigProceso config = getConfigProceso(proceso, recordId);
		return tieneArchivosPendientes(config, recordId);
	}

	private static Boolean tieneArchivosPendientes(ConfigProceso config, String recordId) {
		return !obtenerArchivosPendientes(recordId, config.titleLike).isEmpty();
	}

	private static List<ConfigProceso> getConfiguredDigitalProcesses(String recordTypeDeveloperName, String recordId) {
		List<ConfigProceso> configs = new List<ConfigProceso>();
		for (String processCode : new List<String>{ PROCESO_CREDITO, PROCESO_PAGARE, PROCESO_CONTRATO }) {
			ConfigProceso config = getConfigProceso(processCode, recordId);
			if (FSC_ConfiguracionFirmaDocumentosService.isFirmaDigital(recordTypeDeveloperName, config.documentName)) {
				configs.add(config);
			}
		}
		return configs;
	}

	private static String getRecordTypeDeveloperName(String recordId) {
		ResidentialLoanApplication rla = [
			SELECT RecordType.DeveloperName
			FROM ResidentialLoanApplication
			WHERE Id = :recordId
			LIMIT 1
		];

		return rla.RecordType != null ? rla.RecordType.DeveloperName : null;
	}

	private static String getEmailCreditLabel(String recordTypeDeveloperName) {
		if (recordTypeDeveloperName == RT_CREDITO_PYME) {
			return 'PYME';
		}
		if (recordTypeDeveloperName == RT_CREDITO_CONSUMO || recordTypeDeveloperName == RT_LEGACY_CONSUMO) {
			return 'Consumo';
		}
		if (recordTypeDeveloperName == RT_CREDITO_VEHICULO || recordTypeDeveloperName == RT_LEGACY_VEHICULO) {
			return 'Vehiculo';
		}
		if (recordTypeDeveloperName == RT_CREDITO_HIPOTECARIO || recordTypeDeveloperName == RT_LEGACY_HIPOTECARIO) {
			return 'Hipotecario';
		}

		throw new FSC_FirmarDocumentoUtilityException('RecordType no soportado para firmar documentos de credito: ' + recordTypeDeveloperName);
	}

	private static String getTitleCreditLabel(String recordTypeDeveloperName) {
		if (recordTypeDeveloperName == RT_CREDITO_PYME) {
			return 'PyMe';
		}

		return getEmailCreditLabel(recordTypeDeveloperName);
	}

	private static List<ContentVersion> obtenerArchivosPendientes(String recordId, String titleLike) {
		Set<Id> contentDocumentIds = new Set<Id>();

		for (ContentDocumentLink cdl : [
			SELECT ContentDocumentId
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :recordId
		]) {
			contentDocumentIds.add(cdl.ContentDocumentId);
		}

		if (contentDocumentIds.isEmpty()) {
			return new List<ContentVersion>();
		}

		if (String.isBlank(titleLike)) {
			return obtenerContratosPendientes(recordId, contentDocumentIds);
		}

		return [
			SELECT Id, ContentDocumentId, Title, FSC_FechaEnvioFirma__c
			FROM ContentVersion
			WHERE
				ContentDocumentId IN :contentDocumentIds
				AND FSC_EnviarDocumento__c = TRUE
				AND FSC_FechaEnvioFirma__c = NULL
				AND Title LIKE :titleLike
			ORDER BY Title
		];
	}

	private static List<ContentVersion> obtenerContratosPendientes(String recordId, Set<Id> contentDocumentIds) {
		String recordIdText = String.valueOf(recordId).toLowerCase();
		String recordId15 = recordIdText.length() > 15 ? recordIdText.substring(0, 15) : recordIdText;
		List<ContentVersion> pendingContracts = new List<ContentVersion>();

		for (ContentVersion cv : [
			SELECT Id, ContentDocumentId, Title, FSC_FechaEnvioFirma__c
			FROM ContentVersion
			WHERE ContentDocumentId IN :contentDocumentIds
			AND IsLatest = TRUE
			AND FSC_FechaEnvioFirma__c = NULL
			ORDER BY Title
		]) {
			String title = cv.Title == null ? '' : cv.Title.toLowerCase();
			if (title.contains('contrato') && (title.contains(recordIdText) || title.contains(recordId15))) {
				pendingContracts.add(cv);
			}
		}

		return pendingContracts;
	}

	private static List<VFS_EsignSendingEnvelope.EnvelopeDocument> construirDocuments(List<ContentVersion> files) {
		List<VFS_EsignSendingEnvelope.EnvelopeDocument> documents = new List<VFS_EsignSendingEnvelope.EnvelopeDocument>();

		Integer documentNumber = 1;
		for (ContentVersion file : files) {
			VFS_EsignUploadDocument.UploadResult uploadResult = VFS_EsignUploadDocument.uploadDocument(file.ContentDocumentId);

			if (uploadResult == null) {
				throw new FSC_FirmarDocumentoUtilityException('La carga del archivo "' + file.Title + '" no devolvio respuesta.');
			}

			if (!uploadResult.success || String.isBlank(uploadResult.fileId)) {
				throw new FSC_FirmarDocumentoUtilityException(
					'No se pudo obtener FileId al subir el archivo "' + file.Title + '". Detalle: ' + uploadResult.message
				);
			}

			VFS_EsignSendingEnvelope.EnvelopeDocument doc = new VFS_EsignSendingEnvelope.EnvelopeDocument();
			doc.FileId = uploadResult.fileId;
			doc.DocumentNumber = documentNumber++;
			documents.add(doc);
		}

		return documents;
	}

	private static List<VFS_EsignSendingEnvelope.EnvelopeActivity> construirActivities(List<VFS_EsignSendingEnvelope.EnvelopeAction> actions) {
		List<VFS_EsignSendingEnvelope.EnvelopeActivity> activities = new List<VFS_EsignSendingEnvelope.EnvelopeActivity>();

		for (VFS_EsignSendingEnvelope.EnvelopeAction action : actions) {
			VFS_EsignSendingEnvelope.EnvelopeActivity activity = new VFS_EsignSendingEnvelope.EnvelopeActivity();
			activity.Action = action;
			activities.add(activity);
		}

		return activities;
	}

	private static void marcarComoEnviado(List<ContentVersion> files, String envelopeId) {
		System.debug('files: ' + JSON.serializePretty(files));
		System.debug('envelopeId: ' + envelopeId);
		for (ContentVersion file : files) {
			file.FSC_FechaEnvioFirma__c = System.now();
			file.FSC_EnvelopeId__c = envelopeId;
		}
		update files;
	}

	private static List<SignedEnvelopeFile> parseSignedEnvelopeFiles(String envelopeId, HttpResponse res) {
		String contentType = res.getHeader('Content-Type');
		String body = res.getBody();
		String trimmedBody = body == null ? '' : body.trim();
		Boolean looksJson = !String.isBlank(trimmedBody) && (trimmedBody.startsWith('{') || trimmedBody.startsWith('['));

		if ((contentType != null && contentType.toLowerCase().contains('json')) || looksJson) {
			return parseSignedEnvelopeFilesFromJson(envelopeId, trimmedBody);
		}

		Blob bodyBlob = res.getBodyAsBlob();
		if (bodyBlob == null || bodyBlob.size() == 0) {
			return new List<SignedEnvelopeFile>();
		}

		return new List<SignedEnvelopeFile>{
			new SignedEnvelopeFile(envelopeId + '.pdf', bodyBlob)
		};
	}

	private static List<SignedEnvelopeFile> parseSignedEnvelopeFilesFromJson(String envelopeId, String body) {
		List<SignedEnvelopeFile> result = new List<SignedEnvelopeFile>();
		Object payload = JSON.deserializeUntyped(body);

		if (payload instanceof List<Object>) {
			for (Object item : (List<Object>) payload) {
				addSignedEnvelopeFileFromMap(result, item);
			}
			return result;
		}

		if (!(payload instanceof Map<String, Object>)) {
			return result;
		}

		Map<String, Object> payloadMap = (Map<String, Object>) payload;
		for (String listKey : new List<String>{ 'Files', 'files', 'Documents', 'documents' }) {
			if (payloadMap.containsKey(listKey) && payloadMap.get(listKey) instanceof List<Object>) {
				for (Object item : (List<Object>) payloadMap.get(listKey)) {
					addSignedEnvelopeFileFromMap(result, item);
				}
			}
		}

		addSignedEnvelopeFileFromMap(result, payloadMap);

		if (result.isEmpty() && payloadMap.containsKey('Base64Content')) {
			String base64Content = (String) payloadMap.get('Base64Content');
			if (!String.isBlank(base64Content)) {
				result.add(new SignedEnvelopeFile(envelopeId + '.pdf', EncodingUtil.base64Decode(base64Content)));
			}
		}

		return result;
	}

	private static void addSignedEnvelopeFileFromMap(List<SignedEnvelopeFile> result, Object item) {
		if (!(item instanceof Map<String, Object>)) {
			return;
		}

		Map<String, Object> fileMap = (Map<String, Object>) item;
		String base64Content = firstNonBlankString(
			fileMap,
			new List<String>{ 'Content', 'content', 'Data', 'data', 'FileContent', 'fileContent', 'Base64Content', 'base64Content' }
		);

		String fileName = firstNonBlankString(
			fileMap,
			new List<String>{ 'FileName', 'fileName', 'Filename', 'filename', 'Name', 'name', 'Title', 'title' }
		);

		if (!String.isBlank(base64Content)) {
			result.add(new SignedEnvelopeFile(fileName, EncodingUtil.base64Decode(base64Content)));
			return;
		}

		String fileId = firstNonBlankString(fileMap, new List<String>{ 'FileId', 'fileId', 'Id', 'id' });
		if (!String.isBlank(fileId)) {
			result.add(new SignedEnvelopeFile(fileName, descargarArchivoFirmadoPorFileId(fileId)));
		}
	}

	private static Blob descargarArchivoFirmadoPorFileId(String fileId) {
		HttpRequest req = new HttpRequest();
		req.setEndpoint('callout:VFS_Esignanywhere/Api/v6/file/' + EncodingUtil.urlEncode(fileId, 'UTF-8'));
		req.setMethod('GET');
		req.setHeader('Accept', 'application/pdf, application/octet-stream');

		HttpResponse res = new Http().send(req);
		if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
			throw new FSC_FirmarDocumentoUtilityException(
				'No se pudo descargar el archivo firmado. FileId: ' + fileId + '. StatusCode: ' + res.getStatusCode()
			);
		}

		Blob body = res.getBodyAsBlob();
		if (body == null || body.size() == 0) {
			throw new FSC_FirmarDocumentoUtilityException('La descarga del archivo firmado vino vacia. FileId: ' + fileId);
		}

		return body;
	}

	private static String firstNonBlankString(Map<String, Object> values, List<String> keys) {
		for (String key : keys) {
			if (values.containsKey(key) && values.get(key) != null) {
				String value = String.valueOf(values.get(key));
				if (!String.isBlank(value)) {
					return value;
				}
			}
		}

		return null;
	}

	private static String cleanButtonName(String buttonName) {
		return buttonName != null && buttonName.startsWith('Firmar ') ? buttonName.substring(7) : buttonName;
	}

	private static String buildSendDocumentsMessage(List<String> queuedProcesses, List<String> skippedProcesses) {
		List<String> parts = new List<String>();

		if (!queuedProcesses.isEmpty()) {
			parts.add('Se inicio el envio para: ' + String.join(queuedProcesses, ', ') + '.');
		}

		if (!skippedProcesses.isEmpty()) {
			parts.add('Sin documentos pendientes para: ' + String.join(skippedProcesses, ', ') + '.');
		}

		if (parts.isEmpty()) {
			return 'No se encontraron documentos para enviar a firma.';
		}

		return String.join(parts, ' ');
	}

	public static void marcarSolicitudComoEnviada(String recordId) {
		update new ResidentialLoanApplication(Id = recordId, FSC_EnviadoAFirmar__c = true);
	}

	@TestVisible
	private static String buildEmailSubject(String proceso, String recordId) {
		return buildEmailSubject(getConfigProceso(proceso, recordId));
	}

	private static String buildEmailSubject(ConfigProceso config) {
		if (config.documentName == FSC_ConfiguracionFirmaDocumentosService.DOCUMENTO_PLANILLA) {
			return 'Firma requerida: Solicitud de Crédito ' + config.emailCreditLabel;
		}
		if (config.signatureProcess == PROCESO_PAGARE) {
			return 'Firma requerida: Pagaré';
		}
		if (config.signatureProcess == PROCESO_CONTRATO) {
			return 'Firma requerida: Contrato';
		}
		return 'Documento pendiente de firma';
	}

	@TestVisible
	private static String buildEmailBody(String proceso, String recordId) {
		return buildEmailBody(getConfigProceso(proceso, recordId));
	}

	private static String buildEmailBody(ConfigProceso config) {
		String pendingSignatureText;
		if (config.documentName == FSC_ConfiguracionFirmaDocumentosService.DOCUMENTO_PLANILLA) {
			pendingSignatureText = 'Tiene pendiente la firma de la solicitud de crédito ' + config.emailCreditLabel + '.\n';
		} else if (config.documentName == FSC_ConfiguracionFirmaDocumentosService.DOCUMENTO_PAGARE) {
			pendingSignatureText = 'Tiene pendiente la firma del pagaré.\n';
		} else {
			pendingSignatureText = 'Tiene pendiente la firma del contrato.\n';
		}
		return 'Estimado cliente,\n\n' +
			pendingSignatureText +
			'Por favor, revise el enlace del sobre y complete el proceso.\n\n' +
			'Atentamente,\n' +
			DISPLAYED_EMAIL_SENDER;
	}

	public class EnvelopeStatus {
		@AuraEnabled
		public Boolean success;
		@AuraEnabled
		public String envelopeStatus;
		@AuraEnabled
		public String envelopeFinishedDate;
		@AuraEnabled
		public String errorId;
		@AuraEnabled
		public String message;
		@AuraEnabled
		public String traceId;
		@AuraEnabled
		public String debugInfo;
	}

	public class SendDocumentsResult {
		@AuraEnabled
		public Boolean success;
		@AuraEnabled
		public Boolean documentsSent;
		@AuraEnabled
		public Boolean physicalOnly;
		@AuraEnabled
		public Boolean creditoSent;
		@AuraEnabled
		public Boolean pagareSent;
		@AuraEnabled
		public Boolean contratoSent;
		@AuraEnabled
		public String creditoEnvelopeId;
		@AuraEnabled
		public String pagareEnvelopeId;
		@AuraEnabled
		public String message;
	}

	public class SignedEnvelopeFile {
		public String fileName;
		public Blob body;

		public SignedEnvelopeFile(String fileName, Blob body) {
			this.fileName = fileName;
			this.body = body;
		}
	}

	private class ConfigProceso {
		public String proceso;
		public String buttonName;
		public String titleLike;
		public String processLabel;
		public String emailCreditLabel;
		public String signatureProcess;
		public Boolean isPagare;
		public String documentName;

		public ConfigProceso(
			String buttonName,
			String titleLike,
			String processLabel,
			String emailCreditLabel,
			String signatureProcess,
			Boolean isPagare,
			String documentName
		) {
			this.proceso = signatureProcess;
			this.buttonName = buttonName;
			this.titleLike = titleLike;
			this.processLabel = processLabel;
			this.emailCreditLabel = emailCreditLabel;
			this.signatureProcess = signatureProcess;
			this.isPagare = isPagare;
			this.documentName = documentName;
		}
	}
}