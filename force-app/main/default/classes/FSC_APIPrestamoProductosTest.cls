@IsTest
private class FSC_APIPrestamoProductosTest {
	@IsTest
	static void testRun_WithProductos() {
		FSC_APIPrestamoProductos.mockIpResponse = new Map<String, Object>{ 'productos' => buildProductos() };
		FSC_APIPrestamoProductos.Input input = buildInput('32', '401');

		Test.startTest();
		List<FSC_APIPrestamoProductos.Output> result = FSC_APIPrestamoProductos.run(new List<FSC_APIPrestamoProductos.Input>{ input });
		Test.stopTest();

		System.assertEquals(1, result.size());
		System.assertEquals(true, result[0].success);
		System.assertEquals(true, result[0].found);
		System.assert(result[0].productoJson.contains('"CLAVE_PRODUCTO":44'));
		System.assert(result[0].productoJson.contains('-EMPLEADOS REMESAS VIMENCA'));
		System.assert(!result[0].productoJson.contains('-EMPLEADOS DATA-VIMENCA'));
	}

	@IsTest
	static void testRun_NoMatch() {
		FSC_APIPrestamoProductos.mockIpResponse = new Map<String, Object>{ 'productos' => buildProductos() };
		FSC_APIPrestamoProductos.Input input = buildInput('99', '401');

		Test.startTest();
		List<FSC_APIPrestamoProductos.Output> result = FSC_APIPrestamoProductos.run(new List<FSC_APIPrestamoProductos.Input>{ input });
		Test.stopTest();

		System.assertEquals(1, result.size());
		System.assertEquals(true, result[0].success);
		System.assertEquals(false, result[0].found);
		System.assertEquals(null, result[0].productoJson);
	}

	@IsTest
	static void testRun_MissingFilters() {
		FSC_APIPrestamoProductos.Input input = new FSC_APIPrestamoProductos.Input();
		input.lineaFinanciera = '32';

		Test.startTest();
		List<FSC_APIPrestamoProductos.Output> result = FSC_APIPrestamoProductos.run(new List<FSC_APIPrestamoProductos.Input>{ input });
		Test.stopTest();

		System.assertEquals(1, result.size());
		System.assertEquals(false, result[0].success);
		System.assertEquals(false, result[0].found);
		System.assertEquals(null, result[0].productoJson);
		System.assertEquals('lineaFinanciera y subAplicacion son requeridos.', result[0].message);
	}

	@IsTest
	static void testExtractProductos_FromJsonString() {
		String responseJson = JSON.serialize(new Map<String, Object>{ 'productos' => buildProductos() });

		Test.startTest();
		List<Object> productos = FSC_APIPrestamoProductos.extractProductos(responseJson);
		Test.stopTest();

		System.assertEquals(2, productos.size());
	}

	@IsTest
	static void testExtractProductos_NullAndMissingKey() {
		Test.startTest();
		List<Object> nullResult = FSC_APIPrestamoProductos.extractProductos(null);
		List<Object> missingKeyResult = FSC_APIPrestamoProductos.extractProductos(new Map<String, Object>());
		Test.stopTest();

		System.assertEquals(0, nullResult.size());
		System.assertEquals(0, missingKeyResult.size());
	}

	private static FSC_APIPrestamoProductos.Input buildInput(String lineaFinanciera, String subAplicacion) {
		FSC_APIPrestamoProductos.Input input = new FSC_APIPrestamoProductos.Input();
		input.lineaFinanciera = lineaFinanciera;
		input.subAplicacion = subAplicacion;
		return input;
	}

	private static List<Object> buildProductos() {
		return new List<Object>{
			new Map<String, Object>{
				'CLAVE_PRODUCTO' => 44,
				'NOMBRE' => '-EMPLEADOS REMESAS VIMENCA',
				'CODIGO_SUB_APLICACION' => 401,
				'CODIGO_LINEA_FINANCIERA' => '32',
				'CODIGO_VALOR_TASA_CARTERA' => 40,
				'CODIGO_VALOR_TASA_CARTERA_MORA' => 40
			},
			new Map<String, Object>{
				'CLAVE_PRODUCTO' => 45,
				'NOMBRE' => '-EMPLEADOS DATA-VIMENCA',
				'CODIGO_SUB_APLICACION' => 401,
				'CODIGO_LINEA_FINANCIERA' => '34',
				'CODIGO_VALOR_TASA_CARTERA' => 40,
				'CODIGO_VALOR_TASA_CARTERA_MORA' => 40
			}
		};
	}
}