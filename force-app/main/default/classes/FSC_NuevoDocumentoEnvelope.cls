public with sharing class FSC_NuevoDocumentoEnvelope {
	private static final String PROCESO_CREDITO = 'CREDITO_PYME';
	private static final String PROCESO_PAGARE = 'PAGARE';
	private static final String PROCESO_CONTRATO = 'CONTRATO';
	private static final String ELEMENTO_FIRMA_SOLICITANTE = 'FIRMASOLICITANTE';
	private static final String ELEMENTO_FIRMA_OFICIAL = 'FIRMAOFICIALNEGOCIO';
	@TestVisible
	private static Boolean permitirMarcadoresEnTest = false;

	@AuraEnabled
	public static List<VFS_EsignSendingEnvelope.EnvelopeAction> crearFirmas(String recordId, String proceso) {
		return crearFirmas(recordId, proceso, null);
	}

	public static List<VFS_EsignSendingEnvelope.EnvelopeAction> crearFirmas(
		String recordId,
		String proceso,
		List<VFS_EsignSendingEnvelope.EnvelopeDocument> documents
	) {
		ResidentialLoanApplication rla = obtenerSolicitud(recordId);
		Map<String, FirmaConfig> firmasPorElemento = getFirmaConfigs(proceso, documents);
		FirmaConfig firma = requireFirma(firmasPorElemento, ELEMENTO_FIRMA_SOLICITANTE);

		List<VFS_FirmarDocumentoUtility.SignatureParams> signatures = new List<VFS_FirmarDocumentoUtility.SignatureParams>{
			buildSignature('sig_nuevo_documento', firma.documentNumber, firma.pageNumber, firma.x, firma.y, firma.width, firma.height)
		};

		List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = new List<VFS_EsignSendingEnvelope.EnvelopeAction>{
			accionArmarFirmas(rla.Account.ACC_Correo_Electronico_Cliente__c, rla.Account.FirstName, rla.Account.LastName, 'firmante', signatures)
		};

		if ((proceso == PROCESO_CREDITO || proceso == PROCESO_PAGARE || proceso == PROCESO_CONTRATO) && shouldUsePreparedDocuments(documents)) {
			for (FSC_LoanApplicantFirmanteService.Firmante firmante : FSC_LoanApplicantFirmanteService.queryFirmantesConEmail((Id) recordId)) {
				if (String.isBlank(firmante.email)) {
					continue;
				}

				FirmaConfig firmaLoanApplicant = requireFirma(firmasPorElemento, firmante.firmaElementId);
				actions.add(
					accionArmarFirmas(
						firmante.email,
						firmante.firstName,
						firmante.lastName,
						'firmante_' + firmante.index,
						new List<VFS_FirmarDocumentoUtility.SignatureParams>{
							buildSignature(
								'sig_' + firmante.firmaElementId.toLowerCase(),
								firmaLoanApplicant.documentNumber,
								firmaLoanApplicant.pageNumber,
								firmaLoanApplicant.x,
								firmaLoanApplicant.y,
								firmaLoanApplicant.width,
								firmaLoanApplicant.height
							)
						}
					)
				);
			}
		}

		if (proceso == PROCESO_CREDITO) {
			FirmaConfig firmaOficial = shouldUsePreparedDocuments(documents)
				? requireFirma(firmasPorElemento, ELEMENTO_FIRMA_OFICIAL)
				: new FirmaConfig(firma.documentNumber, firma.pageNumber, firma.x, firma.y + 70, firma.width, firma.height);
			actions.add(
				accionArmarFirmas(
					rla.CreatedBy.Email,
					firstNonBlank(rla.CreatedBy.FirstName, rla.CreatedBy.Name, 'Oficial'),
					firstNonBlank(rla.CreatedBy.LastName, rla.CreatedBy.Name, 'Negocio'),
					'oficial_negocio',
					new List<VFS_FirmarDocumentoUtility.SignatureParams>{
						buildSignature(
							'sig_oficial_negocio',
							firmaOficial.documentNumber,
							firmaOficial.pageNumber,
							firmaOficial.x,
							firmaOficial.y,
							firmaOficial.width,
							firmaOficial.height
						)
					}
				)
			);
		}

		return actions;
	}

	private static ResidentialLoanApplication obtenerSolicitud(String recordId) {
		ResidentialLoanApplication rla = [
			SELECT
				Id,
				Account.FirstName,
				Account.LastName,
				Account.ACC_Correo_Electronico_Cliente__c,
				CreatedBy.Email,
				CreatedBy.FirstName,
				CreatedBy.LastName,
				CreatedBy.Name
			FROM ResidentialLoanApplication
			WHERE Id = :recordId
			LIMIT 1
		];

		if (rla.Account == null) {
			throw new CalloutException('La solicitud no tiene cuenta relacionada.');
		}

		if (String.isBlank(rla.Account.ACC_Correo_Electronico_Cliente__c)) {
			throw new CalloutException('La cuenta no tiene correo electrónico.');
		}
		if (String.isBlank(rla.CreatedBy.Email)) {
			throw new CalloutException('El oficial de negocio no tiene correo electrónico.');
		}

		return rla;
	}

	private static Map<String, FirmaConfig> getFirmaConfigs(String proceso, List<VFS_EsignSendingEnvelope.EnvelopeDocument> documents) {
		FirmaConfig defaultFirma = getDefaultFirma(proceso);
		if (!shouldUsePreparedDocuments(documents)) {
			return buildDefaultFirmaConfigs(defaultFirma);
		}

		return obtenerFirmasDesdeMarcadores(documents[0]);
	}

	private static Boolean shouldUsePreparedDocuments(List<VFS_EsignSendingEnvelope.EnvelopeDocument> documents) {
		return documents != null && !documents.isEmpty() && (!Test.isRunningTest() || permitirMarcadoresEnTest);
	}

	private static FirmaConfig getDefaultFirma(String proceso) {
		if (proceso == PROCESO_CREDITO) {
			return new FirmaConfig(1, 3, 238, 160, 120, 40);
		}
		if (proceso == PROCESO_PAGARE) {
			return new FirmaConfig(1, 3, 235, 370, 160, 60);
		}
		if (proceso == PROCESO_CONTRATO) {
			return new FirmaConfig(1, 3, 235, 370, 160, 60);
		}

		throw new CalloutException('No existe configuración de firma para el proceso "' + proceso + '".');
	}

	private static Map<String, FirmaConfig> buildDefaultFirmaConfigs(FirmaConfig firma) {
		Map<String, FirmaConfig> out = new Map<String, FirmaConfig>();
		out.put(ELEMENTO_FIRMA_SOLICITANTE, firma);
		return out;
	}

	private static Map<String, FirmaConfig> obtenerFirmasDesdeMarcadores(VFS_EsignSendingEnvelope.EnvelopeDocument document) {
		if (document == null || String.isBlank(document.FileId)) {
			throw new CalloutException('No se pudo preparar la firma: el documento no tiene FileId.');
		}

		Map<String, Object> requestBody = new Map<String, Object>{
			'FileIds' => new List<String>{ document.FileId },
			'ClearAdvancedDocumentTags' => true,
			'ClearFieldMarkupString' => true,
			'SigStringConfigurations' => new List<Object>{
				new Map<String, Object>{ 'StartPattern' => '[[', 'EndPattern' => ']]', 'ClearSigString' => true, 'SearchEntireWordOnly' => false }
			}
		};

		HttpRequest req = new HttpRequest();
		req.setEndpoint('callout:VFS_Esignanywhere/Api/v6/file/prepare');
		req.setMethod('POST');
		req.setHeader('Content-Type', 'application/json');
		req.setBody(JSON.serialize(requestBody));

		HttpResponse res = new Http().send(req);
		if (res.getStatusCode() < 200 || res.getStatusCode() > 299) {
			throw new CalloutException('No se pudo preparar el documento para ubicar la firma. HTTP ' + res.getStatusCode() + ': ' + res.getBody());
		}

		Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
		return extraerFirmasPreparadas(responseBody, document.DocumentNumber);
	}

	private static Map<String, FirmaConfig> extraerFirmasPreparadas(Map<String, Object> responseBody, Integer defaultDocumentNumber) {
		Map<String, FirmaConfig> out = new Map<String, FirmaConfig>();
		if (responseBody == null || !responseBody.containsKey('Activities'))
			return out;

		List<Object> activities = (List<Object>) responseBody.get('Activities');
		for (Object activityObj : activities) {
			Map<String, Object> activity = asMap(activityObj);
			Map<String, Object> action = asMap(activity.get('Action'));
			Map<String, Object> sign = asMap(action.get('Sign'));
			Map<String, Object> elements = asMap(sign.get('Elements'));
			List<Object> signatures = (List<Object>) elements.get('Signatures');
			if (signatures == null)
				continue;

			for (Object signatureObj : signatures) {
				Map<String, Object> signature = asMap(signatureObj);
				String preparedElementId = stringValue(firstPopulated(signature, 'ElementId', 'Id'));
				if (String.isBlank(preparedElementId))
					continue;

				Map<String, Object> fieldDefinition = asMap(signature.get('FieldDefinition'));
				Map<String, Object> position = asMap(fieldDefinition.get('Position'));
				Map<String, Object> size = asMap(fieldDefinition.get('Size'));

				out.put(
					preparedElementId,
					new FirmaConfig(
						integerValue(firstPopulated(signature, 'DocumentNumber', null), defaultDocumentNumber),
						integerValue(position.get('PageNumber'), null),
						integerValue(position.get('X'), null),
						integerValue(position.get('Y'), null),
						integerValue(size.get('Width'), null),
						integerValue(size.get('Height'), null)
					)
				);
			}
		}

		return out;
	}

	private static FirmaConfig requireFirma(Map<String, FirmaConfig> firmasPorElemento, String elementId) {
		if (firmasPorElemento != null && firmasPorElemento.containsKey(elementId)) {
			return firmasPorElemento.get(elementId);
		}

		throw new CalloutException('No se encontró el marcador de firma "' + elementId + '" en el documento preparado.');
	}

	private static VFS_FirmarDocumentoUtility.SignatureParams buildSignature(
		String elementId,
		Integer documentNumber,
		Integer pageNumber,
		Integer x,
		Integer y,
		Integer width,
		Integer height
	) {
		VFS_FirmarDocumentoUtility.SignatureParams sig = new VFS_FirmarDocumentoUtility.SignatureParams();
		sig.ElementId = elementId;
		sig.DocumentNumber = documentNumber;
		sig.PageNumber = pageNumber;
		sig.X = x;
		sig.Y = y;
		sig.Width = width;
		sig.Height = height;
		return sig;
	}

	private static VFS_EsignSendingEnvelope.EnvelopeAction accionArmarFirmas(
		String email,
		String givenName,
		String surname,
		String signingGroup,
		List<VFS_FirmarDocumentoUtility.SignatureParams> signatures
	) {
		VFS_EsignSendingEnvelope.EnvelopeContactInformation contact = new VFS_EsignSendingEnvelope.EnvelopeContactInformation();
		contact.Email = email;
		contact.GivenName = givenName;
		contact.Surname = surname;
		contact.LanguageCode = 'EN';

		VFS_EsignSendingEnvelope.EnvelopeRecipientConfiguration recipient = new VFS_EsignSendingEnvelope.EnvelopeRecipientConfiguration();
		recipient.ContactInformation = contact;

		List<VFS_EsignSendingEnvelope.EnvelopeSignature> sigList = new List<VFS_EsignSendingEnvelope.EnvelopeSignature>();

		for (VFS_FirmarDocumentoUtility.SignatureParams sp : signatures) {
			VFS_EsignSendingEnvelope.EnvelopeClickToSign clickToSign = new VFS_EsignSendingEnvelope.EnvelopeClickToSign();

			VFS_EsignSendingEnvelope.EnvelopeAllowedSignatureTypes allowedTypes = new VFS_EsignSendingEnvelope.EnvelopeAllowedSignatureTypes();
			allowedTypes.ClickToSign = clickToSign;

			VFS_EsignSendingEnvelope.EnvelopePosition pos = new VFS_EsignSendingEnvelope.EnvelopePosition();
			pos.PageNumber = sp.PageNumber;
			pos.X = sp.X;
			pos.Y = sp.Y;

			VFS_EsignSendingEnvelope.EnvelopeSize size = new VFS_EsignSendingEnvelope.EnvelopeSize();
			size.Width = sp.Width;
			size.Height = sp.Height;

			VFS_EsignSendingEnvelope.EnvelopeFieldDefinition fieldDef = new VFS_EsignSendingEnvelope.EnvelopeFieldDefinition();
			fieldDef.Position = pos;
			fieldDef.Size = size;

			VFS_EsignSendingEnvelope.EnvelopeSignature sigEnv = new VFS_EsignSendingEnvelope.EnvelopeSignature();
			sigEnv.ElementId = sp.ElementId;
			sigEnv.Required = true;
			sigEnv.DocumentNumber = sp.DocumentNumber;
			sigEnv.DisplayName = 'Firma aquí';
			sigEnv.AllowedSignatureTypes = allowedTypes;
			sigEnv.FieldDefinition = fieldDef;

			sigList.add(sigEnv);
		}

		VFS_EsignSendingEnvelope.EnvelopeElements elements = new VFS_EsignSendingEnvelope.EnvelopeElements();
		elements.Signatures = sigList;

		VFS_EsignSendingEnvelope.EnvelopeSign sign = new VFS_EsignSendingEnvelope.EnvelopeSign();
		sign.RecipientConfiguration = recipient;
		sign.Elements = elements;
		sign.SigningGroup = signingGroup;

		VFS_EsignSendingEnvelope.EnvelopeAction action = new VFS_EsignSendingEnvelope.EnvelopeAction();
		action.Sign = sign;
		action.SendCopy = null;

		return action;
	}

	private static Map<String, Object> asMap(Object value) {
		if (value == null)
			return new Map<String, Object>();
		return (Map<String, Object>) value;
	}

	private static Object firstPopulated(Map<String, Object> source, String preferredKey, String fallbackKey) {
		if (source == null)
			return null;
		Object preferred = source.get(preferredKey);
		if (preferred != null)
			return preferred;
		return String.isBlank(fallbackKey) ? null : source.get(fallbackKey);
	}

	private static String stringValue(Object value) {
		return value == null ? '' : String.valueOf(value);
	}

	private static Integer integerValue(Object value, Integer defaultValue) {
		if (value == null)
			return defaultValue;
		return Decimal.valueOf(String.valueOf(value)).intValue();
	}

	private static String firstNonBlank(String firstValue, String secondValue, String thirdValue) {
		if (!String.isBlank(firstValue)) {
			return firstValue;
		}
		if (!String.isBlank(secondValue)) {
			return secondValue;
		}
		return thirdValue;
	}

	private class FirmaConfig {
		public Integer documentNumber;
		public Integer pageNumber;
		public Integer x;
		public Integer y;
		public Integer width;
		public Integer height;

		public FirmaConfig(Integer documentNumber, Integer pageNumber, Integer x, Integer y, Integer width, Integer height) {
			this.documentNumber = documentNumber;
			this.pageNumber = pageNumber;
			this.x = x;
			this.y = y;
			this.width = width;
			this.height = height;
		}
	}
}