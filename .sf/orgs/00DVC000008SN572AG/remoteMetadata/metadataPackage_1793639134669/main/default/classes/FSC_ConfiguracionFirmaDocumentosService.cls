public with sharing class FSC_ConfiguracionFirmaDocumentosService {
	public static final String DOCUMENTO_PLANILLA = 'Planilla';
	public static final String DOCUMENTO_PAGARE = 'Pagare';
	public static final String DOCUMENTO_CONTRATO = 'Contrato';

	public static Boolean isFirmaDigital(String recordTypeDeveloperName, String nombreDocumento) {
		FSC_ConfiguracionFirmaDocumentos__mdt config = getConfig(recordTypeDeveloperName, nombreDocumento);
		return config != null && config.FSC_FirmaDigital__c == true;
	}

	public static Boolean hasDocumentosFirmaFisica(String recordTypeDeveloperName) {
		if (String.isBlank(recordTypeDeveloperName)) {
			return true;
		}

		for (FSC_ConfiguracionFirmaDocumentos__mdt config : FSC_ConfiguracionFirmaDocumentos__mdt.getAll().values()) {
			if (config.FSC_TipoCredito__c == recordTypeDeveloperName && config.FSC_FirmaDigital__c != true) {
				return true;
			}
		}

		return false;
	}

	public static Boolean hasDocumentosFirmaDigital(String recordTypeDeveloperName) {
		if (String.isBlank(recordTypeDeveloperName)) {
			return false;
		}

		for (FSC_ConfiguracionFirmaDocumentos__mdt config : FSC_ConfiguracionFirmaDocumentos__mdt.getAll().values()) {
			if (config.FSC_TipoCredito__c == recordTypeDeveloperName && config.FSC_FirmaDigital__c == true) {
				return true;
			}
		}

		return false;
	}

	public static void marcarFirmasFisicasCompletasSiNoAplican(Set<Id> residentialLoanApplicationIds) {
		if (residentialLoanApplicationIds == null || residentialLoanApplicationIds.isEmpty()) {
			return;
		}

		List<ResidentialLoanApplication> updates = new List<ResidentialLoanApplication>();
		for (ResidentialLoanApplication rla : [
			SELECT Id, RecordType.DeveloperName, FSC_DocumentosFirmadosFis__c
			FROM ResidentialLoanApplication
			WHERE Id IN :residentialLoanApplicationIds
		]) {
			String recordTypeDeveloperName = rla.RecordType != null ? rla.RecordType.DeveloperName : null;
			if (rla.FSC_DocumentosFirmadosFis__c != true && !hasDocumentosFirmaFisica(recordTypeDeveloperName)) {
				updates.add(new ResidentialLoanApplication(Id = rla.Id, FSC_DocumentosFirmadosFis__c = true));
			}
		}

		if (!updates.isEmpty()) {
			update updates;
		}
	}

	private static FSC_ConfiguracionFirmaDocumentos__mdt getConfig(String recordTypeDeveloperName, String nombreDocumento) {
		if (String.isBlank(recordTypeDeveloperName) || String.isBlank(nombreDocumento)) {
			return null;
		}

		String normalizedDocumentName = normalize(nombreDocumento);
		for (FSC_ConfiguracionFirmaDocumentos__mdt config : FSC_ConfiguracionFirmaDocumentos__mdt.getAll().values()) {
			if (config.FSC_TipoCredito__c == recordTypeDeveloperName && normalize(config.FSC_NombreDocumento__c) == normalizedDocumentName) {
				return config;
			}
		}

		return null;
	}

	private static String normalize(String value) {
		return String.isBlank(value) ? '' : value.trim().toLowerCase();
	}
}