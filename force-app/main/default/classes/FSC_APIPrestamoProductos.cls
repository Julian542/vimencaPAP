public with sharing class FSC_APIPrestamoProductos {
	private static final String INTEGRATION_PROCEDURE_NAME = 'FSC_APIProductos';

	@TestVisible
	private static Object mockIpResponse;

	public class Input {
		@InvocableVariable(label='FSC_lineaFinanciera__c' required=true)
		public String lineaFinanciera;

		@InvocableVariable(label='FSC_subAplicacion__c' required=true)
		public String subAplicacion;
	}

	public class Output {
		@InvocableVariable
		public Boolean success;

		@InvocableVariable
		public Boolean found;

		@InvocableVariable
		public String message;

		@InvocableVariable
		public String productoJson;
	}

	@InvocableMethod(
		label='FSC - Consultar productos de prestamo'
		description='Invoca IP FSC_APIProductos y devuelve el producto filtrado por linea financiera y sub aplicacion.'
	)
	public static List<Output> run(List<Input> inputs) {
		List<Output> outputs = new List<Output>();
		if (inputs == null || inputs.isEmpty()) {
			return outputs;
		}

		List<Object> productos = new List<Object>();
		Output ipError;
		if (hasValidInput(inputs)) {
			try {
				productos = callProductosIp();
			} catch (Exception e) {
				ipError = buildErrorOutput('Error: ' + e.getMessage());
			}
		}

		for (Input inputItem : inputs) {
			if (!isValidInput(inputItem)) {
				outputs.add(buildErrorOutput('lineaFinanciera y subAplicacion son requeridos.'));
			} else if (ipError != null) {
				outputs.add(ipError);
			} else {
				outputs.add(buildFilteredOutput(productos, inputItem));
			}
		}

		return outputs;
	}

	public static List<Object> callProductosIp() {
		Object rawResponse;

		if (Test.isRunningTest() && mockIpResponse != null) {
			rawResponse = mockIpResponse;
		} else {
			rawResponse = omnistudio.IntegrationProcedureService.runIntegrationService(
				INTEGRATION_PROCEDURE_NAME,
				new Map<String, Object>(),
				new Map<String, Object>()
			);
		}

		return extractProductos(rawResponse);
	}

	public static List<Object> extractProductos(Object response) {
		if (response == null) {
			return new List<Object>();
		}

		Object normalizedResponse = normalizeResponse(response);

		if (normalizedResponse instanceof List<Object>) {
			return (List<Object>) normalizedResponse;
		}

		if (normalizedResponse instanceof Map<String, Object>) {
			Map<String, Object> responseMap = (Map<String, Object>) normalizedResponse;
			if (!responseMap.containsKey('productos')) {
				return new List<Object>();
			}

			return extractProductos(responseMap.get('productos'));
		}

		return new List<Object>();
	}

	@TestVisible
	private static Map<String, Object> findProducto(List<Object> productos, String lineaFinanciera, String subAplicacion) {
		if (productos == null) {
			return null;
		}

		String targetLineaFinanciera = normalizeFilterValue(lineaFinanciera);
		String targetSubAplicacion = normalizeFilterValue(subAplicacion);

		for (Object productoItem : productos) {
			Map<String, Object> productoMap = toMap(productoItem);
			if (productoMap == null) {
				continue;
			}

			String codigoLineaFinanciera = normalizeFilterValue(productoMap.get('CODIGO_LINEA_FINANCIERA'));
			String codigoSubAplicacion = normalizeFilterValue(productoMap.get('CODIGO_SUB_APLICACION'));

			if (codigoLineaFinanciera == targetLineaFinanciera && codigoSubAplicacion == targetSubAplicacion) {
				return productoMap;
			}
		}

		return null;
	}

	private static Output buildFilteredOutput(List<Object> productos, Input inputItem) {
		Output outputItem = new Output();
		Map<String, Object> producto = findProducto(productos, inputItem.lineaFinanciera, inputItem.subAplicacion);

		if (producto == null) {
			outputItem.success = true;
			outputItem.found = false;
			outputItem.message = 'No se encontro producto para la linea financiera y sub aplicacion indicadas.';
			return outputItem;
		}

		outputItem.success = true;
		outputItem.found = true;
		outputItem.message = 'Producto encontrado.';
		outputItem.productoJson = JSON.serialize(producto);
		return outputItem;
	}

	private static Output buildErrorOutput(String message) {
		Output outputItem = new Output();
		outputItem.success = false;
		outputItem.found = false;
		outputItem.message = message;
		return outputItem;
	}

	private static Boolean hasValidInput(List<Input> inputs) {
		for (Input inputItem : inputs) {
			if (isValidInput(inputItem)) {
				return true;
			}
		}

		return false;
	}

	private static Boolean isValidInput(Input inputItem) {
		return inputItem != null && !String.isBlank(inputItem.lineaFinanciera) && !String.isBlank(inputItem.subAplicacion);
	}

	private static String normalizeFilterValue(Object value) {
		if (value == null) {
			return null;
		}

		String normalizedValue = String.valueOf(value).trim();
		if (normalizedValue.endsWith('.0')) {
			normalizedValue = normalizedValue.substring(0, normalizedValue.length() - 2);
		}

		return normalizedValue;
	}

	private static Map<String, Object> toMap(Object value) {
		if (value == null) {
			return null;
		}

		if (value instanceof Map<String, Object>) {
			return (Map<String, Object>) value;
		}

		Object normalizedValue = JSON.deserializeUntyped(JSON.serialize(value));
		if (normalizedValue instanceof Map<String, Object>) {
			return (Map<String, Object>) normalizedValue;
		}

		return null;
	}

	private static Object normalizeResponse(Object response) {
		if (response instanceof String) {
			String responseText = (String) response;
			if (String.isBlank(responseText)) {
				return null;
			}

			return JSON.deserializeUntyped(responseText);
		}

		if (response instanceof List<Object> || response instanceof Map<String, Object>) {
			return response;
		}

		return JSON.deserializeUntyped(JSON.serialize(response));
	}
}