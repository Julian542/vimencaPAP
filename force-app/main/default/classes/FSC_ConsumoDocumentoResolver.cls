public without sharing class FSC_ConsumoDocumentoResolver {
	public static final String PAGARE_NOTARIAL = 'NOTARIAL';
	public static final String PAGARE_COMPLEMENTARIO = 'COMPLEMENTARIO';
	public static final String PAGARE_SIMPLE = 'SIMPLE';
	public static final String PAGARE_SIMPLE_FIADOR = 'SIMPLE_FIADOR';

	public static final String GARANTIA_VEHICULO = 'VEHICULO';
	public static final String GARANTIA_HIPOTECARIA = 'HIPOTECARIA';
	public static final String GARANTIA_CD = 'CERTIFICADO_DEPOSITO';
	public static final String GARANTIA_SOLIDARIA = 'SOLIDARIA';
	public static final String SIN_GARANTIA = 'SIN_GARANTIA';

	private static final String RECORD_TYPE_CONSUMO = 'FSC_Solicitud_Credito_Consumo';
	private static final Decimal MONTO_PAGARE_NOTARIAL = 2000000;

	public class ResolucionDocumento {
		public Boolean aplicaConsumo { get; set; }
		public String codigoPagare { get; set; }
		public String nombrePagare { get; set; }
		public String tipoGarantia { get; set; }
		public Id garantiaId { get; set; }
		public Boolean tieneGarante { get; set; }
	}

	public static ResolucionDocumento resolve(Id rlaId) {
		ResidentialLoanApplication rla = [
			SELECT Id, RecordTypeId, FSC_RequiereContratoPagareNotarial__c, FSC_Monto__c, FSC_MontoAprobado__c, FSC_Tipo_de_Garantia__c
			FROM ResidentialLoanApplication
			WHERE Id = :rlaId
			WITH USER_MODE
			LIMIT 1
		];
		ResolucionDocumento result = resolveAll(new List<ResidentialLoanApplication>{ rla }).get(rla.Id);
		if (result.aplicaConsumo && result.codigoPagare == null) {
			throw new FSC_ConsumoDocumentoResolverException(
				'La garantía de Consumo no corresponde a vehículo, inmueble, certificado de depósito ni garantía solidaria.'
			);
		}
		return result;
	}

	public static Map<Id, ResolucionDocumento> resolveAll(List<ResidentialLoanApplication> applications) {
		Map<Id, ResolucionDocumento> results = new Map<Id, ResolucionDocumento>();
		if (applications == null || applications.isEmpty())
			return results;
		Set<Id> consumptionIds = new Set<Id>();
		Map<Id, Schema.RecordTypeInfo> recordTypes = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosById();
		for (ResidentialLoanApplication application : applications) {
			Schema.RecordTypeInfo recordType = recordTypes.get(application.RecordTypeId);
			if (recordType != null && recordType.getDeveloperName() == RECORD_TYPE_CONSUMO)
				consumptionIds.add(application.Id);
		}
		Map<Id, FSC_Garantia__c> firstGuarantees = new Map<Id, FSC_Garantia__c>();
		Set<Id> guarantorIds = new Set<Id>();
		if (!consumptionIds.isEmpty()) {
			for (ResidentialLoanApplication application : [
				SELECT
					Id,
					(
						SELECT Id, FSC_Clase_de_Garantia__c, FSC_Tipo_de_Garantia__c
						FROM FSC_Garantias__r
						ORDER BY CreatedDate ASC, Id ASC
						LIMIT 1
					)
				FROM ResidentialLoanApplication
				WHERE Id IN :consumptionIds
				WITH USER_MODE
			]) {
				if (!application.FSC_Garantias__r.isEmpty())
					firstGuarantees.put(application.Id, application.FSC_Garantias__r[0]);
			}
			for (AggregateResult applicant : [
				SELECT LoanApplicationId
				FROM LoanApplicant
				WHERE LoanApplicationId IN :consumptionIds AND FSC_TipoSolicitante__c = 'Garante'
				WITH USER_MODE
				GROUP BY LoanApplicationId
			])
				guarantorIds.add((Id) applicant.get('LoanApplicationId'));
		}
		for (ResidentialLoanApplication application : applications) {
			ResolucionDocumento result = new ResolucionDocumento();
			result.aplicaConsumo = consumptionIds.contains(application.Id);
			if (result.aplicaConsumo)
				resolveConsumption(application, firstGuarantees.get(application.Id), guarantorIds.contains(application.Id), result);
			results.put(application.Id, result);
		}
		return results;
	}

	public static Boolean isSimpleWithoutContract(ResolucionDocumento document) {
		// Ambas variantes simples de Consumo están excluidas por el resolver de contratos.
		return document != null &&
			document.aplicaConsumo == true &&
			(document.codigoPagare == PAGARE_SIMPLE ||
			document.codigoPagare == PAGARE_SIMPLE_FIADOR);
	}

	private static void resolveConsumption(
		ResidentialLoanApplication rla,
		FSC_Garantia__c firstGuarantee,
		Boolean hasGuarantor,
		ResolucionDocumento result
	) {
		result.tieneGarante = hasGuarantor;
		if (firstGuarantee != null) {
			result.garantiaId = firstGuarantee.Id;
			result.tipoGarantia = classifyGuarantee(
				FSC_CatalogoGarantiaService.getTextoClasificacion(firstGuarantee.FSC_Clase_de_Garantia__c, firstGuarantee.FSC_Tipo_de_Garantia__c)
			);
		} else {
			result.tipoGarantia = classifyGuarantee(rla.FSC_Tipo_de_Garantia__c);
		}

		Boolean solidary = result.tieneGarante && normalize(rla.FSC_Tipo_de_Garantia__c).contains('SOLIDARIA');
		Decimal amount = rla.FSC_Monto__c;
		Boolean notarial =
			rla.FSC_RequiereContratoPagareNotarial__c == true ||
			(amount != null &&
			amount > MONTO_PAGARE_NOTARIAL) ||
			result.tipoGarantia == GARANTIA_VEHICULO ||
			result.tipoGarantia == GARANTIA_HIPOTECARIA;

		if (notarial) {
			result.codigoPagare = PAGARE_NOTARIAL;
			result.nombrePagare = 'Pagaré notarial';
		} else if (solidary) {
			result.codigoPagare = PAGARE_SIMPLE_FIADOR;
			result.nombrePagare = 'Pagaré comercial individual con fiador';
		} else if (result.tipoGarantia == GARANTIA_VEHICULO || result.tipoGarantia == GARANTIA_HIPOTECARIA || result.tipoGarantia == GARANTIA_CD) {
			result.codigoPagare = PAGARE_COMPLEMENTARIO;
			result.nombrePagare = 'Pagaré complementario';
		} else if (result.tipoGarantia == SIN_GARANTIA || result.tipoGarantia == GARANTIA_SOLIDARIA) {
			result.codigoPagare = PAGARE_SIMPLE;
			result.nombrePagare = 'Pagaré comercial individual';
		}
	}

	private static String classifyGuarantee(String rawValue) {
		String value = normalize(rawValue);
		if (String.isBlank(value) || value.contains('SIN GARANTIA'))
			return SIN_GARANTIA;
		if (value.contains('VEHICULO'))
			return GARANTIA_VEHICULO;
		if (
			value.contains('INMUEBLE') ||
			value.contains('HIPOTEC') ||
			value.contains('SOLAR') ||
			value.contains('TERRENO') ||
			value.contains('VIVIENDA') ||
			value.contains('APARTAMENTO')
		) {
			return GARANTIA_HIPOTECARIA;
		}
		if (value.contains('CERTIFICADO') || value.contains('DEPOSITO A PLAZO'))
			return GARANTIA_CD;
		if (value.contains('SOLIDARIA') || value.contains('FIRMA SOLIDARIA'))
			return GARANTIA_SOLIDARIA;
		return 'OTRA_GARANTIA';
	}

	private static String normalize(String value) {
		String normalized = String.isBlank(value) ? '' : value.trim().toUpperCase();
		return normalized.replace('Á', 'A').replace('É', 'E').replace('Í', 'I').replace('Ó', 'O').replace('Ú', 'U').replace('Ü', 'U');
	}

	public class FSC_ConsumoDocumentoResolverException extends Exception {
	}
}