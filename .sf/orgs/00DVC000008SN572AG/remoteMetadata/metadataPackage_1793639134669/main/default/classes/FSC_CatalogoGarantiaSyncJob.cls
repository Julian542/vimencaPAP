// Sincroniza el catalogo de garantias desde el API de Prestamos. Lo encola FSC_CatalogoGarantiaSyncScheduler.
// Corre sin sharing y en modo sistema: el catalogo no es sensible y lo mantiene un proceso, no un usuario.
public without sharing class FSC_CatalogoGarantiaSyncJob implements Queueable, Database.AllowsCallouts {
	private static final String BASE_ENDPOINT = 'callout:FSC_APIPrestamo/api/prestamo/garantias/';
	private static final String RUTA_CLASES = 'clases';
	private static final String RUTA_TIPOS = 'tipos';
	private static final String RUTA_CLASES_POR_TIPO = 'clases-por-tipo';
	private static final String RUTA_MARCAS = 'marcas-auto';
	private static final String RUTA_MODELOS = 'modelos-auto';
	private static final String API_KEY_HEADER = 'X-API-KEY';
	private static final String API_KEY_CONFIG = 'Default';
	private static final Integer HTTP_TIMEOUT = 120000;
	// Una respuesta con menos de la mitad de los registros activos se considera incompleta.
	private static final Decimal MINIMO_PROPORCION_REGISTROS = 0.5;
	private static final Integer NOMBRE_MAX_LENGTH = 80;
	private static final Integer LOG_TEXT_MAX_LENGTH = 255;
	private static final Integer LOG_BODY_MAX_LENGTH = 131072;
	private static final String LOG_INTEGRATION_NAME = 'FSC_CatalogoGarantiaSyncJob';
	private static final String LOG_FUNCTION_NAME = 'sincronizar';

	public class Resultado {
		public Boolean exito = false;
		public String mensaje;
		public Integer registrosActualizados = 0;
		public Integer registrosDesactivados = 0;
	}

	public void execute(QueueableContext context) {
		sincronizar();
	}

	public static Resultado sincronizar() {
		Resultado resultado = new Resultado();
		List<String> trazas = new List<String>();
		Integer ultimoStatus = 0;
		Map<String, List<Map<String, Object>>> filasPorRuta = new Map<String, List<Map<String, Object>>>();

		try {
			String apiKey = getApiKey();
			for (String ruta : new List<String>{ RUTA_CLASES, RUTA_TIPOS, RUTA_CLASES_POR_TIPO, RUTA_MARCAS, RUTA_MODELOS }) {
				HttpResponse response = llamar(ruta, apiKey);
				ultimoStatus = response.getStatusCode();
				if (ultimoStatus < 200 || ultimoStatus >= 300) {
					throw new CalloutException('El catalogo ' + ruta + ' respondio HTTP ' + ultimoStatus + '.');
				}
				List<Map<String, Object>> filas = parsear(response.getBody(), ruta);
				if (filas.isEmpty()) {
					throw new CalloutException('El catalogo ' + ruta + ' llego vacio.');
				}
				filasPorRuta.put(ruta, filas);
				trazas.add(ruta + '=' + filas.size());
			}

			Map<String, FSC_CatalogoGarantia__c> registrosPorClave = construirRegistros(filasPorRuta);
			validarCompletitud(registrosPorClave.values());

			Savepoint savepoint = Database.setSavepoint();
			try {
				Database.upsert(registrosPorClave.values(), FSC_CatalogoGarantia__c.FSC_Clave__c, true, AccessLevel.SYSTEM_MODE);
				resultado.registrosActualizados = registrosPorClave.size();
				resultado.registrosDesactivados = desactivarAusentes(registrosPorClave.keySet());
			} catch (Exception e) {
				Database.rollback(savepoint);
				throw e;
			}
			resultado.exito = true;
			resultado.mensaje =
				'Catalogo sincronizado. Registros: ' + resultado.registrosActualizados + '. Desactivados: ' + resultado.registrosDesactivados + '.';
		} catch (Exception e) {
			resultado.exito = false;
			resultado.mensaje = 'No se actualizo el catalogo: ' + e.getMessage();
			System.debug(LoggingLevel.ERROR, resultado.mensaje);
		}

		registrarLog(String.join(trazas, ', '), resultado, ultimoStatus);
		return resultado;
	}

	private static HttpResponse llamar(String ruta, String apiKey) {
		HttpRequest request = new HttpRequest();
		request.setEndpoint(BASE_ENDPOINT + ruta);
		request.setMethod('GET');
		request.setTimeout(HTTP_TIMEOUT);
		request.setHeader('Accept', 'application/json');
		request.setHeader(API_KEY_HEADER, apiKey);
		return new Http().send(request);
	}

	private static List<Map<String, Object>> parsear(String body, String ruta) {
		List<Map<String, Object>> filas = new List<Map<String, Object>>();
		Object parsed = String.isBlank(body) ? null : JSON.deserializeUntyped(body);
		if (!(parsed instanceof List<Object>)) {
			throw new CalloutException('El catalogo ' + ruta + ' no devolvio una lista.');
		}
		for (Object fila : (List<Object>) parsed) {
			if (fila instanceof Map<String, Object>) {
				filas.add((Map<String, Object>) fila);
			}
		}
		return filas;
	}

	private static Map<String, FSC_CatalogoGarantia__c> construirRegistros(Map<String, List<Map<String, Object>>> filasPorRuta) {
		Datetime ahora = Datetime.now();
		Map<String, FSC_CatalogoGarantia__c> registros = new Map<String, FSC_CatalogoGarantia__c>();

		for (Map<String, Object> fila : filasPorRuta.get(RUTA_CLASES)) {
			agregar(registros, FSC_CatalogoGarantiaService.CATALOGO_CLASE, entero(fila, 'CODIGO_CLASE_GARANTIA'), null, texto(fila, 'DESCRIPCION'), null, ahora);
		}

		Map<Integer, Map<String, Object>> tiposPorCodigo = new Map<Integer, Map<String, Object>>();
		for (Map<String, Object> fila : filasPorRuta.get(RUTA_TIPOS)) {
			Integer codigo = entero(fila, 'CODIGO_TIPO_GARANTIA');
			if (codigo != null) {
				tiposPorCodigo.put(codigo, fila);
			}
		}
		// Un tipo puede pertenecer a varias clases; se guarda una fila por cada relacion.
		for (Map<String, Object> relacion : filasPorRuta.get(RUTA_CLASES_POR_TIPO)) {
			Integer codigoClase = entero(relacion, 'CODIGO_CLASE_GARANTIA');
			Map<String, Object> tipo = tiposPorCodigo.get(entero(relacion, 'CODIGO_TIPO_GARANTIA'));
			if (codigoClase == null || tipo == null) {
				continue;
			}
			agregar(
				registros,
				FSC_CatalogoGarantiaService.CATALOGO_TIPO,
				entero(tipo, 'CODIGO_TIPO_GARANTIA'),
				codigoClase,
				texto(tipo, 'DESCRIPCION'),
				entero(tipo, 'CODIGO_MONEDA'),
				ahora
			);
		}

		for (Map<String, Object> fila : filasPorRuta.get(RUTA_MARCAS)) {
			agregar(registros, FSC_CatalogoGarantiaService.CATALOGO_MARCA, entero(fila, 'CODIGO_MARCA'), null, texto(fila, 'DESCRIPCION'), null, ahora);
		}
		for (Map<String, Object> fila : filasPorRuta.get(RUTA_MODELOS)) {
			agregar(
				registros,
				FSC_CatalogoGarantiaService.CATALOGO_MODELO,
				entero(fila, 'CODIGO_MODELO'),
				entero(fila, 'CODIGO_MARCA'),
				texto(fila, 'DESCRIPCION'),
				null,
				ahora
			);
		}
		return registros;
	}

	private static void agregar(
		Map<String, FSC_CatalogoGarantia__c> registros,
		String catalogo,
		Integer codigo,
		Integer codigoPadre,
		String descripcion,
		Integer codigoMoneda,
		Datetime ahora
	) {
		if (codigo == null || String.isBlank(descripcion)) {
			return;
		}
		String clave = construirClave(catalogo, codigoPadre, codigo);
		registros.put(
			clave,
			new FSC_CatalogoGarantia__c(
				Name = descripcion.left(NOMBRE_MAX_LENGTH),
				FSC_Clave__c = clave,
				FSC_Tipo_Catalogo__c = catalogo,
				FSC_Codigo__c = codigo,
				FSC_Codigo_Padre__c = codigoPadre,
				FSC_Codigo_Moneda__c = codigoMoneda,
				FSC_Descripcion__c = descripcion.trim().left(255),
				FSC_Activo__c = true,
				FSC_Fecha_Sincronizacion__c = ahora
			)
		);
	}

	@TestVisible
	private static String construirClave(String catalogo, Integer codigoPadre, Integer codigo) {
		return catalogo.toUpperCase() + '-' + (codigoPadre == null ? '' : codigoPadre + '-') + codigo;
	}

	// Evita desactivar media parametria si el API devolvio una respuesta parcial.
	private static void validarCompletitud(List<FSC_CatalogoGarantia__c> nuevos) {
		Map<String, Integer> nuevosPorCatalogo = new Map<String, Integer>();
		for (FSC_CatalogoGarantia__c registro : nuevos) {
			Integer actual = nuevosPorCatalogo.containsKey(registro.FSC_Tipo_Catalogo__c) ? nuevosPorCatalogo.get(registro.FSC_Tipo_Catalogo__c) : 0;
			nuevosPorCatalogo.put(registro.FSC_Tipo_Catalogo__c, actual + 1);
		}
		for (AggregateResult fila : [
			SELECT FSC_Tipo_Catalogo__c catalogo, COUNT(Id) total
			FROM FSC_CatalogoGarantia__c
			WHERE FSC_Activo__c = TRUE
			WITH SYSTEM_MODE
			GROUP BY FSC_Tipo_Catalogo__c
		]) {
			String catalogo = (String) fila.get('catalogo');
			Integer activos = (Integer) fila.get('total');
			Integer recibidos = nuevosPorCatalogo.containsKey(catalogo) ? nuevosPorCatalogo.get(catalogo) : 0;
			if (activos > 0 && recibidos < activos * MINIMO_PROPORCION_REGISTROS) {
				throw new CalloutException(
					'El catalogo ' + catalogo + ' trajo ' + recibidos + ' registros y hay ' + activos + ' activos; se conserva el catalogo actual.'
				);
			}
		}
	}

	private static Integer desactivarAusentes(Set<String> clavesVigentes) {
		List<FSC_CatalogoGarantia__c> ausentes = new List<FSC_CatalogoGarantia__c>();
		for (FSC_CatalogoGarantia__c registro : [
			SELECT Id
			FROM FSC_CatalogoGarantia__c
			WHERE FSC_Activo__c = TRUE AND FSC_Clave__c NOT IN :clavesVigentes
			WITH SYSTEM_MODE
		]) {
			ausentes.add(new FSC_CatalogoGarantia__c(Id = registro.Id, FSC_Activo__c = false));
		}
		if (!ausentes.isEmpty()) {
			Database.update(ausentes, true, AccessLevel.SYSTEM_MODE);
		}
		return ausentes.size();
	}

	private static String getApiKey() {
		FSC_APIPrestamoConfig__mdt config = FSC_APIPrestamoConfig__mdt.getInstance(API_KEY_CONFIG);
		if (config == null || String.isBlank(config.FSC_ApiKey__c)) {
			throw new CalloutException('Falta configurar FSC_APIPrestamoConfig__mdt.' + API_KEY_CONFIG + '.FSC_ApiKey__c.');
		}
		return config.FSC_ApiKey__c;
	}

	private static Integer entero(Map<String, Object> fila, String campo) {
		Object valor = fila.get(campo);
		if (valor == null || String.isBlank(String.valueOf(valor))) {
			return null;
		}
		try {
			return Decimal.valueOf(String.valueOf(valor).trim()).intValue();
		} catch (Exception e) {
			return null;
		}
	}

	private static String texto(Map<String, Object> fila, String campo) {
		Object valor = fila.get(campo);
		return valor == null ? null : String.valueOf(valor);
	}

	@SuppressWarnings('PMD.ApexCRUDViolation')
	private static void registrarLog(String solicitud, Resultado resultado, Integer statusCode) {
		// Un fallo del log no debe ocultar el resultado de la sincronizacion.
		Savepoint savepoint = Database.setSavepoint();
		try {
			INT_Request__c request = new INT_Request__c(
				Trama_de_env_o__c = ('GET ' + BASE_ENDPOINT + ' ' + solicitud).left(LOG_BODY_MAX_LENGTH),
				Integraci_n__c = LOG_INTEGRATION_NAME,
				Funci_n__c = LOG_FUNCTION_NAME
			);
			Database.insert(request, AccessLevel.SYSTEM_MODE);
			INT_Response__c response = new INT_Response__c(
				INT_Request__c = request.Id,
				Trama_de_respuesta__c = resultado.mensaje == null ? null : resultado.mensaje.left(LOG_BODY_MAX_LENGTH),
				Http_Status_Code__c = statusCode,
				Status__c = (resultado.exito ? 'OK' : 'ERROR').left(LOG_TEXT_MAX_LENGTH)
			);
			Database.insert(response, AccessLevel.SYSTEM_MODE);
		} catch (Exception e) {
			Database.rollback(savepoint);
			System.debug(LoggingLevel.ERROR, 'No se pudo registrar el log de sincronizacion: ' + e.getMessage());
		}
	}
}