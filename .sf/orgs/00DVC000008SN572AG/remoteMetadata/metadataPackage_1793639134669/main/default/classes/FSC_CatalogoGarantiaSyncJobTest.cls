@IsTest
private class FSC_CatalogoGarantiaSyncJobTest {
	private class CatalogoMock implements HttpCalloutMock {
		private Map<String, Object> respuestasPorRuta;
		private Integer statusCode;

		private CatalogoMock(Map<String, Object> respuestasPorRuta, Integer statusCode) {
			this.respuestasPorRuta = respuestasPorRuta;
			this.statusCode = statusCode;
		}

		public HttpResponse respond(HttpRequest request) {
			Assert.areEqual('GET', request.getMethod(), 'Los catalogos se consultan con GET.');
			Assert.isFalse(String.isBlank(request.getHeader('X-API-KEY')), 'Toda llamada debe enviar la API key.');
			String ruta = request.getEndpoint().substringAfterLast('/');
			HttpResponse response = new HttpResponse();
			response.setStatusCode(statusCode);
			response.setBody(JSON.serialize(respuestasPorRuta.containsKey(ruta) ? respuestasPorRuta.get(ruta) : new List<Object>()));
			return response;
		}
	}

	private static Map<String, Object> respuestasCompletas() {
		return new Map<String, Object>{
			'clases' => new List<Object>{
				new Map<String, Object>{ 'CODIGO_CLASE_GARANTIA' => 1, 'DESCRIPCION' => 'BIENES INMUEBLES' },
				new Map<String, Object>{ 'CODIGO_CLASE_GARANTIA' => 17, 'DESCRIPCION' => 'VEHICULOS NUEVOS -P2' }
			},
			'tipos' => new List<Object>{
				new Map<String, Object>{ 'CODIGO_TIPO_GARANTIA' => 76, 'DESCRIPCION' => 'EDIFICIOS RESIDENCIALES (RD$)-I3', 'CODIGO_MONEDA' => 1 },
				new Map<String, Object>{ 'CODIGO_TIPO_GARANTIA' => 15, 'DESCRIPCION' => 'VEHICULOS 3-5 ANOS RD$ (P3)', 'CODIGO_MONEDA' => 1 },
				new Map<String, Object>{ 'CODIGO_TIPO_GARANTIA' => 99, 'DESCRIPCION' => 'TIPO SIN CLASE', 'CODIGO_MONEDA' => 1 }
			},
			'clases-por-tipo' => new List<Object>{
				new Map<String, Object>{ 'CODIGO_CLASE_GARANTIA' => 1, 'CODIGO_TIPO_GARANTIA' => 76 },
				new Map<String, Object>{ 'CODIGO_CLASE_GARANTIA' => 17, 'CODIGO_TIPO_GARANTIA' => 15 }
			},
			'marcas-auto' => new List<Object>{ new Map<String, Object>{ 'CODIGO_MARCA' => 5, 'DESCRIPCION' => 'TOYOTA' } },
			'modelos-auto' => new List<Object>{
				new Map<String, Object>{ 'CODIGO_MODELO' => 7, 'CODIGO_MARCA' => 5, 'DESCRIPCION' => 'COROLLA' },
				new Map<String, Object>{ 'CODIGO_MODELO' => 8, 'CODIGO_MARCA' => 5, 'DESCRIPCION' => 'HILUX' }
			}
		};
	}

	@IsTest
	static void sincronizar_creaRegistrosPorCatalogo() {
		Test.setMock(HttpCalloutMock.class, new CatalogoMock(respuestasCompletas(), 200));

		Test.startTest();
		FSC_CatalogoGarantiaSyncJob.Resultado resultado = FSC_CatalogoGarantiaSyncJob.sincronizar();
		Test.stopTest();

		Assert.isTrue(resultado.exito, resultado.mensaje);
		Assert.areEqual(7, resultado.registrosActualizados, 'Debe crear 2 clases, 2 tipos con clase, 1 marca y 2 modelos.');
		FSC_CatalogoGarantia__c tipo = [
			SELECT FSC_Codigo__c, FSC_Codigo_Padre__c, FSC_Codigo_Moneda__c, FSC_Activo__c
			FROM FSC_CatalogoGarantia__c
			WHERE FSC_Clave__c = 'TIPO-1-76' WITH SYSTEM_MODE
		];
		Assert.areEqual(76, tipo.FSC_Codigo__c, 'Debe guardar el codigo del tipo.');
		Assert.areEqual(1, tipo.FSC_Codigo_Padre__c, 'El padre del tipo es su clase.');
		Assert.areEqual(1, tipo.FSC_Codigo_Moneda__c, 'Debe guardar la moneda del tipo.');
		Assert.areEqual(0, [SELECT COUNT() FROM FSC_CatalogoGarantia__c WHERE FSC_Codigo__c = 99 WITH SYSTEM_MODE], 'Un tipo sin clase no se muestra en ninguna clase.');
		Assert.areEqual(1, [SELECT COUNT() FROM INT_Request__c WHERE Integraci_n__c = 'FSC_CatalogoGarantiaSyncJob'], 'Debe registrar el log.');
	}

	@IsTest
	static void sincronizar_desactivaLoQueYaNoViene() {
		Test.setMock(HttpCalloutMock.class, new CatalogoMock(respuestasCompletas(), 200));
		FSC_CatalogoGarantiaSyncJob.sincronizar();

		Map<String, Object> respuestas = respuestasCompletas();
		((List<Object>) respuestas.get('modelos-auto')).remove(1);
		Test.setMock(HttpCalloutMock.class, new CatalogoMock(respuestas, 200));

		Test.startTest();
		FSC_CatalogoGarantiaSyncJob.Resultado resultado = FSC_CatalogoGarantiaSyncJob.sincronizar();
		Test.stopTest();

		Assert.isTrue(resultado.exito, resultado.mensaje);
		Assert.areEqual(1, resultado.registrosDesactivados, 'El modelo que dejo de venir debe desactivarse.');
		FSC_CatalogoGarantia__c hilux = [SELECT FSC_Activo__c FROM FSC_CatalogoGarantia__c WHERE FSC_Clave__c = 'MODELO-5-8' WITH SYSTEM_MODE];
		Assert.isFalse(hilux.FSC_Activo__c, 'Nunca se borra: se marca inactivo.');
	}

	@IsTest
	static void sincronizar_conservaCatalogoSiElApiFalla() {
		Test.setMock(HttpCalloutMock.class, new CatalogoMock(respuestasCompletas(), 200));
		FSC_CatalogoGarantiaSyncJob.sincronizar();
		Test.setMock(HttpCalloutMock.class, new CatalogoMock(respuestasCompletas(), 500));

		Test.startTest();
		FSC_CatalogoGarantiaSyncJob.Resultado resultado = FSC_CatalogoGarantiaSyncJob.sincronizar();
		Test.stopTest();

		Assert.isFalse(resultado.exito, 'Un error HTTP no debe actualizar el catalogo.');
		Assert.areEqual(7, [SELECT COUNT() FROM FSC_CatalogoGarantia__c WHERE FSC_Activo__c = TRUE WITH SYSTEM_MODE], 'El catalogo anterior queda intacto.');
		Assert.areEqual(
			1,
			[SELECT COUNT() FROM INT_Response__c WHERE INT_Request__r.Integraci_n__c = 'FSC_CatalogoGarantiaSyncJob' AND Status__c = 'ERROR'],
			'El error debe quedar registrado.'
		);
	}

	@IsTest
	static void sincronizar_rechazaCatalogoVacio() {
		Test.setMock(HttpCalloutMock.class, new CatalogoMock(respuestasCompletas(), 200));
		FSC_CatalogoGarantiaSyncJob.sincronizar();
		Map<String, Object> respuestasVacias = respuestasCompletas();
		respuestasVacias.put('marcas-auto', new List<Object>());

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new CatalogoMock(respuestasVacias, 200));
		FSC_CatalogoGarantiaSyncJob.Resultado vacio = FSC_CatalogoGarantiaSyncJob.sincronizar();
		Test.stopTest();

		Assert.isFalse(vacio.exito, 'Un catalogo vacio se considera una respuesta invalida.');
		Assert.areEqual(7, [SELECT COUNT() FROM FSC_CatalogoGarantia__c WHERE FSC_Activo__c = TRUE WITH SYSTEM_MODE], 'Debe conservarse el catalogo vigente.');
	}

	@IsTest
	static void validarCompletitud_rechazaMenosDeLaMitad() {
		Test.setMock(HttpCalloutMock.class, new CatalogoMock(respuestasCompletas(), 200));
		FSC_CatalogoGarantiaSyncJob.sincronizar();
		List<FSC_CatalogoGarantia__c> extras = new List<FSC_CatalogoGarantia__c>();
		for (Integer index = 100; index < 110; index++) {
			extras.add(
				new FSC_CatalogoGarantia__c(
					Name = 'MODELO ' + index,
					FSC_Clave__c = 'MODELO-5-' + index,
					FSC_Tipo_Catalogo__c = 'Modelo',
					FSC_Codigo__c = index,
					FSC_Codigo_Padre__c = 5,
					FSC_Descripcion__c = 'MODELO ' + index,
					FSC_Activo__c = true
				)
			);
		}
		Database.insert(extras, AccessLevel.SYSTEM_MODE);

		Test.startTest();
		FSC_CatalogoGarantiaSyncJob.Resultado resultado = FSC_CatalogoGarantiaSyncJob.sincronizar();
		Test.stopTest();

		Assert.isFalse(resultado.exito, 'Recibir 2 de 12 modelos activos indica una respuesta parcial.');
		Assert.areEqual(12, [SELECT COUNT() FROM FSC_CatalogoGarantia__c WHERE FSC_Tipo_Catalogo__c = 'Modelo' AND FSC_Activo__c = TRUE WITH SYSTEM_MODE], 'No debe desactivar modelos.');
	}

	@IsTest
	static void programacion_encolaLaSincronizacion() {
		Test.setMock(HttpCalloutMock.class, new CatalogoMock(respuestasCompletas(), 200));

		FSC_CatalogoGarantiaSyncScheduler.nombreProgramacion = 'FSC Sincronizacion Catalogo Garantias TEST';

		Test.startTest();
		Id jobId = FSC_CatalogoGarantiaSyncScheduler.programarDiario();
		new FSC_CatalogoGarantiaSyncScheduler().execute((SchedulableContext) null);
		Test.stopTest();

		Assert.isNotNull(jobId, 'Debe quedar programado el job diario.');
		Assert.areEqual(7, [SELECT COUNT() FROM FSC_CatalogoGarantia__c WITH SYSTEM_MODE], 'El Queueable debe ejecutar la sincronizacion.');
		Assert.areEqual('CLASE-1', FSC_CatalogoGarantiaSyncJob.construirClave('Clase', null, 1), 'La clave sin padre no lleva guion extra.');
	}
}