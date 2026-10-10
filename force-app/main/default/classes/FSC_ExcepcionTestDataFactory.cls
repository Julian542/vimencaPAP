@IsTest
public class FSC_ExcepcionTestDataFactory {
	public static Account createAccount(String suffix, Boolean insertRecord) {
		String normalized = String.isBlank(suffix) ? '0001' : suffix.replaceAll('[^0-9]', '').left(4).leftPad(4, '0');
		Account account = new Account(Name = 'Cuenta prueba excepciones ' + suffix, ACC_NumIdentificacion__c = '0010880' + normalized);
		if (insertRecord) {
			insert account;
		}
		return account;
	}

	public static ResidentialLoanApplication createSolicitud(Id accountId, String name, String subestado, Decimal monto, Boolean insertRecord) {
		Id recordTypeId = Schema.SObjectType.ResidentialLoanApplication
			.getRecordTypeInfosByDeveloperName()
			.get('FSC_Solicitud_Credito_Consumo')
			.getRecordTypeId();
		String actoNumero = ('A' + String.valueOf(name.hashCode()).replace('-', '')).left(10);
		ResidentialLoanApplication solicitud = new ResidentialLoanApplication(
			Name = name,
			AccountId = accountId,
			RecordTypeId = recordTypeId,
			Status = 'En proceso',
			FSC_Subestado__c = subestado,
			FSC_Monto__c = monto,
			FSC_Aplica_Garantia__c = false,
			FSC_ActoNumeroPagare__c = actoNumero,
			FSC_Pagares_y_Plantillas_Generados__c = false,
			FSC_Plazo_meses__c = '24',
			FSC_TasaInteres__c = 14,
			FSC_Aprobado_con_Condiciones__c = false,
			FSC_lineaFinanciera__c = '32',
			FSC_subAplicacion__c = '401'
		);
		if (insertRecord) {
			insert solicitud;
		}
		return solicitud;
	}

	public static List<ResidentialLoanApplication> createSolicitudes(Id accountId, Integer count, Boolean insertRecords) {
		List<ResidentialLoanApplication> solicitudes = new List<ResidentialLoanApplication>();
		for (Integer index = 0; index < count; index++) {
			solicitudes.add(createSolicitud(accountId, 'RLA Bulk Excepción ' + index, 'En Motor Buró', 1000, false));
		}
		if (insertRecords) {
			insert solicitudes;
		}
		return solicitudes;
	}

	public static FSC_Excepcion__c buildExcepcion(Id solicitudId, Integer sequence, String estado, String condicion) {
		return new FSC_Excepcion__c(
			FSC_Solicitud_Prestamo__c = solicitudId,
			FSC_Tipo__c = 'Excepciones de Negocios',
			FSC_Detalle__c = 'Detalle de prueba ' + sequence,
			FSC_Motivo__c = 'Motivo de prueba ' + sequence,
			FSC_Estado__c = estado,
			FSC_Condicion__c = condicion
		);
	}
}