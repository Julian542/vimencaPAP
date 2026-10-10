// Acceso de solo lectura al catalogo de garantias sincronizado desde el API de Prestamos.
// El catalogo no es informacion sensible y el trigger debe resolver codigos para cualquier usuario.
public without sharing class FSC_CatalogoGarantiaService {
	public static final String CATALOGO_CLASE = 'Clase';
	public static final String CATALOGO_TIPO = 'Tipo';
	public static final String CATALOGO_MARCA = 'Marca';
	public static final String CATALOGO_MODELO = 'Modelo';
	public static final String GRUPO_GENERAL = 'general';

	private static Map<String, List<FSC_CatalogoGarantia__c>> registrosPorCatalogo;
	private static Map<String, String> grupoPorClave;
	private static Map<Integer, String> grupoPorCodigo;

	public static String normalizarClave(String valor) {
		if (String.isBlank(valor)) {
			return '';
		}
		return valor.toUpperCase()
			.replace('Á', 'A')
			.replace('É', 'E')
			.replace('Í', 'I')
			.replace('Ó', 'O')
			.replace('Ú', 'U')
			.replace('Ü', 'U')
			.replace('Ñ', 'N')
			.replaceAll('[^A-Z0-9]', '');
	}

	public static Boolean tieneCatalogo() {
		return !getActivos(CATALOGO_CLASE).isEmpty();
	}

	public static List<FSC_CatalogoGarantia__c> getActivos(String catalogo) {
		List<FSC_CatalogoGarantia__c> activos = new List<FSC_CatalogoGarantia__c>();
		for (FSC_CatalogoGarantia__c registro : getRegistros(catalogo)) {
			if (registro.FSC_Activo__c) {
				activos.add(registro);
			}
		}
		return activos;
	}

	// Incluye el grupo de la descripcion actual del API y de los textos historicos del CMT.
	public static Map<String, String> getGrupoPorClase() {
		if (grupoPorClave != null) {
			return grupoPorClave;
		}
		grupoPorClave = new Map<String, String>();
		for (FSC_ClaseGarantia__mdt configuracion : FSC_ClaseGarantia__mdt.getAll().values()) {
			if (!String.isBlank(configuracion.FSC_Valor__c) && !String.isBlank(configuracion.FSC_Grupo__c)) {
				grupoPorClave.put(normalizarClave(configuracion.FSC_Valor__c), configuracion.FSC_Grupo__c);
			}
		}
		Map<Integer, String> gruposPorCodigo = getGrupoPorCodigo();
		for (FSC_CatalogoGarantia__c clase : getRegistros(CATALOGO_CLASE)) {
			Integer codigo = toInteger(clase.FSC_Codigo__c);
			String clave = normalizarClave(clase.FSC_Descripcion__c);
			if (gruposPorCodigo.containsKey(codigo) && !grupoPorClave.containsKey(clave)) {
				grupoPorClave.put(clave, gruposPorCodigo.get(codigo));
			}
		}
		return grupoPorClave;
	}

	public static Map<Integer, String> getGrupoPorCodigo() {
		if (grupoPorCodigo != null) {
			return grupoPorCodigo;
		}
		grupoPorCodigo = new Map<Integer, String>();
		for (FSC_ClaseGarantia__mdt configuracion : FSC_ClaseGarantia__mdt.getAll().values()) {
			if (configuracion.FSC_Codigo__c != null && !String.isBlank(configuracion.FSC_Grupo__c)) {
				grupoPorCodigo.put(configuracion.FSC_Codigo__c.intValue(), configuracion.FSC_Grupo__c);
			}
		}
		return grupoPorCodigo;
	}

	public static String getGrupo(String clase) {
		return getGrupoPorClase().get(normalizarClave(clase));
	}

	// La clase define la categoria de la garantia. Los tipos del core pueden traer palabras de otra
	// categoria (ej. "CALENTADORES SOLARES" en maquinarias), por eso solo se usan si no hay clase.
	public static String getTextoClasificacion(String clase, String tipo) {
		return String.isBlank(clase) ? String.valueOf(clase) + ' ' + tipo : clase;
	}

	// Solo recalcula el codigo cuyo texto cambio, para no alterar garantias de creditos aprobados.
	public static void resolverCodigos(List<FSC_Garantia__c> registros, Map<Id, FSC_Garantia__c> anteriores) {
		List<FSC_Garantia__c> pendientes = new List<FSC_Garantia__c>();
		for (FSC_Garantia__c registro : registros) {
			FSC_Garantia__c anterior = anteriores == null ? null : anteriores.get(registro.Id);
			if (anterior == null || cambioAlgunTexto(registro, anterior)) {
				pendientes.add(registro);
			}
		}
		if (pendientes.isEmpty()) {
			return;
		}

		Indice indice = new Indice();
		for (FSC_Garantia__c registro : pendientes) {
			FSC_Garantia__c anterior = anteriores == null ? null : anteriores.get(registro.Id);
			Boolean cambioClase = anterior == null || registro.FSC_Clase_de_Garantia__c != anterior.FSC_Clase_de_Garantia__c;
			Boolean cambioTipo = cambioClase || registro.FSC_Tipo_de_Garantia__c != anterior.FSC_Tipo_de_Garantia__c;
			Boolean cambioMarca = anterior == null || registro.FSC_Marca_Vehiculo__c != anterior.FSC_Marca_Vehiculo__c;
			Boolean cambioModelo = cambioMarca || registro.FSC_Modelo_Vehiculo__c != anterior.FSC_Modelo_Vehiculo__c;

			Integer codigoClase = indice.clases.get(normalizarClave(registro.FSC_Clase_de_Garantia__c));
			if (cambioClase) {
				registro.FSC_Codigo_Clase_Garantia__c = codigoClase;
			}
			if (cambioTipo) {
				registro.FSC_Codigo_Tipo_Garantia__c = codigoClase == null
					? null
					: indice.tipos.get(codigoClase + '|' + normalizarClave(registro.FSC_Tipo_de_Garantia__c));
			}
			Integer codigoMarca = indice.marcas.get(normalizarClave(registro.FSC_Marca_Vehiculo__c));
			if (cambioMarca) {
				registro.FSC_Codigo_Marca_Vehiculo__c = codigoMarca;
			}
			if (cambioModelo) {
				registro.FSC_Codigo_Modelo_Vehiculo__c = codigoMarca == null
					? null
					: indice.modelos.get(codigoMarca + '|' + normalizarClave(registro.FSC_Modelo_Vehiculo__c));
			}
		}
	}

	private static Boolean cambioAlgunTexto(FSC_Garantia__c registro, FSC_Garantia__c anterior) {
		return registro.FSC_Clase_de_Garantia__c != anterior.FSC_Clase_de_Garantia__c ||
			registro.FSC_Tipo_de_Garantia__c != anterior.FSC_Tipo_de_Garantia__c ||
			registro.FSC_Marca_Vehiculo__c != anterior.FSC_Marca_Vehiculo__c ||
			registro.FSC_Modelo_Vehiculo__c != anterior.FSC_Modelo_Vehiculo__c;
	}

	private static List<FSC_CatalogoGarantia__c> getRegistros(String catalogo) {
		if (registrosPorCatalogo == null) {
			registrosPorCatalogo = new Map<String, List<FSC_CatalogoGarantia__c>>();
			for (FSC_CatalogoGarantia__c registro : [
				SELECT FSC_Tipo_Catalogo__c, FSC_Codigo__c, FSC_Codigo_Padre__c, FSC_Codigo_Moneda__c, FSC_Descripcion__c, FSC_Activo__c
				FROM FSC_CatalogoGarantia__c
				WHERE FSC_Descripcion__c != NULL AND FSC_Codigo__c != NULL
				WITH SYSTEM_MODE
				ORDER BY FSC_Activo__c DESC, FSC_Descripcion__c ASC, FSC_Codigo__c ASC
			]) {
				if (!registrosPorCatalogo.containsKey(registro.FSC_Tipo_Catalogo__c)) {
					registrosPorCatalogo.put(registro.FSC_Tipo_Catalogo__c, new List<FSC_CatalogoGarantia__c>());
				}
				registrosPorCatalogo.get(registro.FSC_Tipo_Catalogo__c).add(registro);
			}
		}
		return registrosPorCatalogo.containsKey(catalogo) ? registrosPorCatalogo.get(catalogo) : new List<FSC_CatalogoGarantia__c>();
	}

	@TestVisible
	private static void limpiarCache() {
		registrosPorCatalogo = null;
		grupoPorClave = null;
		grupoPorCodigo = null;
	}

	private static Integer toInteger(Decimal valor) {
		return valor == null ? null : valor.intValue();
	}

	// Los registros activos se cargan primero, por lo que ganan ante descripciones repetidas.
	private class Indice {
		private Map<String, Integer> clases = new Map<String, Integer>();
		private Map<String, Integer> tipos = new Map<String, Integer>();
		private Map<String, Integer> marcas = new Map<String, Integer>();
		private Map<String, Integer> modelos = new Map<String, Integer>();

		private Indice() {
			for (FSC_CatalogoGarantia__c clase : getRegistros(CATALOGO_CLASE)) {
				putIfAbsent(clases, normalizarClave(clase.FSC_Descripcion__c), toInteger(clase.FSC_Codigo__c));
			}
			// Los textos historicos del CMT siguen resolviendo su codigo.
			for (FSC_ClaseGarantia__mdt configuracion : FSC_ClaseGarantia__mdt.getAll().values()) {
				if (configuracion.FSC_Codigo__c != null) {
					putIfAbsent(clases, normalizarClave(configuracion.FSC_Valor__c), configuracion.FSC_Codigo__c.intValue());
				}
			}
			for (FSC_CatalogoGarantia__c tipo : getRegistros(CATALOGO_TIPO)) {
				putIfAbsent(tipos, toInteger(tipo.FSC_Codigo_Padre__c) + '|' + normalizarClave(tipo.FSC_Descripcion__c), toInteger(tipo.FSC_Codigo__c));
			}
			for (FSC_CatalogoGarantia__c marca : getRegistros(CATALOGO_MARCA)) {
				putIfAbsent(marcas, normalizarClave(marca.FSC_Descripcion__c), toInteger(marca.FSC_Codigo__c));
			}
			for (FSC_CatalogoGarantia__c modelo : getRegistros(CATALOGO_MODELO)) {
				putIfAbsent(
					modelos,
					toInteger(modelo.FSC_Codigo_Padre__c) + '|' + normalizarClave(modelo.FSC_Descripcion__c),
					toInteger(modelo.FSC_Codigo__c)
				);
			}
		}

		private void putIfAbsent(Map<String, Integer> valores, String clave, Integer codigo) {
			if (!String.isBlank(clave) && codigo != null && !valores.containsKey(clave)) {
				valores.put(clave, codigo);
			}
		}
	}
}