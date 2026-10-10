public inherited sharing class FSC_LoanApplicantFirmanteService {
	private static final String ELEMENT_ID_PREFIX = 'FIRMALOANAPPLICANT';

	public class Firmante {
		public Id applicantId { get; private set; }
		public Integer index { get; private set; }
		public String name { get; private set; }
		public String tipoSolicitante { get; private set; }
		public String firmaElementId { get; private set; }
		public String email { get; set; }
		public String firstName { get; private set; }
		public String lastName { get; private set; }

		private Firmante(LoanApplicant applicant, Integer index) {
			this.applicantId = applicant.Id;
			this.index = index;
			this.name = normalizeTextValue(applicant.Name);
			this.tipoSolicitante = normalizeTextValue(applicant.FSC_TipoSolicitante__c);
			this.firmaElementId = ELEMENT_ID_PREFIX + index;
			this.firstName = firstNonBlank(applicant.Contact == null ? null : applicant.Contact.FirstName, applicant.FSC_Nombre__c, applicant.Name);
			this.lastName = firstNonBlank(
				applicant.Contact == null ? null : applicant.Contact.LastName,
				buildLastName(applicant),
				applicant.FSC_TipoSolicitante__c
			);
		}
	}

	public static List<Firmante> queryFirmantes(Id rlaId) {
		return queryFirmantes(rlaId, false);
	}

	public static List<Firmante> queryFirmantesConEmail(Id rlaId) {
		return queryFirmantes(rlaId, true);
	}

	private static List<Firmante> queryFirmantes(Id rlaId, Boolean includeEmail) {
		List<Firmante> firmantes = new List<Firmante>();
		if (rlaId == null || !Schema.getGlobalDescribe().containsKey('LoanApplicant')) {
			return firmantes;
		}

		List<LoanApplicant> applicants = [
			SELECT Id, Name, Contact.FirstName, Contact.LastName, FSC_TipoSolicitante__c, FSC_Nombre__c, FSC_PrimerApellido__c, FSC_SegundoApellido__c
			FROM LoanApplicant
			WHERE LoanApplicationId = :rlaId AND FSC_TipoSolicitante__c != 'Deudor'
			ORDER BY CreatedDate, Id
		];

		Integer index = 1;
		for (LoanApplicant applicant : orderApplicantsBySignerType(applicants)) {
			if (!isCoDeudorOGarante(applicant.FSC_TipoSolicitante__c)) {
				continue;
			}

			firmantes.add(new Firmante(applicant, index++));
		}

		if (includeEmail) {
			hydrateEmails(firmantes);
		}

		return firmantes;
	}

	private static List<LoanApplicant> orderApplicantsBySignerType(List<LoanApplicant> applicants) {
		List<LoanApplicant> ordered = new List<LoanApplicant>();
		for (Integer rank = 1; rank <= 4; rank++) {
			for (LoanApplicant applicant : applicants) {
				if (signerTypeRank(applicant.FSC_TipoSolicitante__c) == rank) {
					ordered.add(applicant);
				}
			}
		}
		return ordered;
	}

	private static void hydrateEmails(List<Firmante> firmantes) {
		if (firmantes.isEmpty() || !Schema.getGlobalDescribe().containsKey('ContactPointEmail')) {
			return;
		}

		Set<Id> applicantIds = new Set<Id>();
		for (Firmante firmante : firmantes) {
			applicantIds.add(firmante.applicantId);
		}

		Map<Id, String> emailByApplicantId = new Map<Id, String>();
		for (ContactPointEmail emailRecord : [
			SELECT FSC_Solicitante__c, EmailAddress
			FROM ContactPointEmail
			WHERE FSC_Solicitante__c IN :applicantIds
			ORDER BY CreatedDate DESC, Id DESC
		]) {
			if (!emailByApplicantId.containsKey(emailRecord.FSC_Solicitante__c)) {
				emailByApplicantId.put(emailRecord.FSC_Solicitante__c, emailRecord.EmailAddress);
			}
		}

		for (Firmante firmante : firmantes) {
			firmante.email = emailByApplicantId.get(firmante.applicantId);
		}
	}

	private static Boolean isCoDeudorOGarante(String tipoSolicitante) {
		String tipo = normalizeTextValue(tipoSolicitante).toLowerCase();
		return tipo.contains('co') || tipo.contains('garante');
	}

	private static Integer signerTypeRank(String tipoSolicitante) {
		String tipo = normalizeTextValue(tipoSolicitante).toLowerCase();
		if (tipo.contains('co')) {
			return 1;
		}
		if (tipo.contains('garante')) {
			return 2;
		}
		return 3;
	}

	private static String normalizeTextValue(Object value) {
		return value == null ? '' : String.valueOf(value).trim();
	}

	private static String firstNonBlank(String firstValue, String secondValue, String thirdValue) {
		if (!String.isBlank(firstValue)) {
			return firstValue;
		}
		if (!String.isBlank(secondValue)) {
			return secondValue;
		}
		if (!String.isBlank(thirdValue)) {
			return thirdValue;
		}
		return 'Firmante';
	}

	private static String buildLastName(LoanApplicant applicant) {
		List<String> parts = new List<String>();
		if (!String.isBlank(applicant.FSC_PrimerApellido__c)) {
			parts.add(applicant.FSC_PrimerApellido__c);
		}
		if (!String.isBlank(applicant.FSC_SegundoApellido__c)) {
			parts.add(applicant.FSC_SegundoApellido__c);
		}
		return String.join(parts, ' ');
	}
}