// Panel de formalización de garantías en la página de la solicitud (fsc_RlaFormalizacionGarantias).
// with sharing: el usuario debe ver la solicitud; las validaciones de actor y escrituras están en el servicio.
public with sharing class FSC_FormalizacionGarantiasController {
	@AuraEnabled
	public static FSC_FormalizacionGarantiasService.Contexto getContexto(Id residentialLoanApplicationId) {
		validarAcceso(residentialLoanApplicationId);
		return FSC_FormalizacionGarantiasService.obtenerContexto(residentialLoanApplicationId);
	}

	@AuraEnabled
	public static void ejecutarAccion(Id residentialLoanApplicationId, String accion, Map<String, Object> datos) {
		validarAcceso(residentialLoanApplicationId);
		try {
			FSC_FormalizacionGarantiasService.ejecutar(residentialLoanApplicationId, accion, datos);
		} catch (DmlException e) {
			throw new AuraHandledException(e.getDmlMessage(0));
		}
	}

	@AuraEnabled
	public static void descartarArchivos(List<Id> documentosIds) {
		FSC_FormalizacionGarantiasService.descartarArchivos(documentosIds);
	}

	@AuraEnabled
	public static Map<String, Object> getDatosDocumento(Id residentialLoanApplicationId, String tipo) {
		validarAcceso(residentialLoanApplicationId);
		return FSC_FormalizacionDocumentosController.datosIniciales(residentialLoanApplicationId, tipo);
	}

	@AuraEnabled
	public static Id generarDocumento(Id residentialLoanApplicationId, String tipo, String datosJson) {
		validarAcceso(residentialLoanApplicationId);
		return FSC_FormalizacionDocumentosController.generar(residentialLoanApplicationId, tipo, datosJson);
	}

	private static void validarAcceso(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}
		if ([SELECT COUNT() FROM ResidentialLoanApplication WHERE Id = :residentialLoanApplicationId] == 0) {
			throw new AuraHandledException('No se encontró la solicitud o no tiene acceso a ella.');
		}
	}
}