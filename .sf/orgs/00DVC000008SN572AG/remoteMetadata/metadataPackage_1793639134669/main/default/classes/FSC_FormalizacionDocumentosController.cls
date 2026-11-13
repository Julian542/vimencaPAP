// Documentos de formalización generados desde el modal del panel: los datos no se guardan en objetos,
// viajan como JSON a la página Visualforce y el PDF queda en los Archivos de la solicitud.
public with sharing class FSC_FormalizacionDocumentosController {
	public static final String TIPO_INVENTARIO = 'inventario';
	public static final String TIPO_AUTORIZACION = 'autorizacion';
	private static final String TELEFONO_FORMALIZACION = '809-532-9797';
	private static final String CORREO_FORMALIZACION = 'formalizacionlegal@bv.com.do';
	private static final String CIUDAD = 'Santo Domingo de Guzmán, D. N.';
	private static final String DOMICILIO_AUTORIZADO = 'esta ciudad de Santo Domingo, Distrito Nacional, capital de la República Dominicana';
	private static final Integer TEXTO_MAXIMO = 2000;
	private static final List<String> DOCUMENTOS_INVENTARIO = new List<String>{
		'Original de Contrato de préstamo',
		'Original de recibo de pago del 3% por transferencia inmobiliaria',
		'Original de recibo de pago del 2% por inscripción de hipoteca',
		'Original de certificado de título',
		'Original de certificación de propiedad inmobiliaria',
		'Original de poder especial de representación',
		'Original certificación de registro de acreedor',
		'Original de cancelación de hipoteca',
		'Copia certificada del acta de asamblea',
		'Registro mercantil',
		'Certificación virtual de RNC',
		'Copia del documento de identidad de las partes'
	};
	private static final Map<String, Decimal> TASAS_INVENTARIO = new Map<String, Decimal>{
		'Tasa por servicio por emisión de certificación de registro de acreedor' => 1000,
		'Tasa por servicio por depósito remoto local' => 300,
		'Tasa por servicio por depósito remoto' => 800,
		'Tasa por servicio por el colegio de notario ley 140-15' => 130,
		'Sello del colegio de abogado ley 03-19' => 50,
		'Recibo ley 33-91' => 10
	};

	public Inventario inventario { get; private set; }
	public Autorizacion autorizacion { get; private set; }

	// Visualforce: los datos llegan ya validados por generar().
	public FSC_FormalizacionDocumentosController() {
		String datos = ApexPages.currentPage().getParameters().get('datos');
		String tipo = ApexPages.currentPage().getParameters().get('tipo');
		if (String.isBlank(datos)) {
			return;
		}
		if (tipo == TIPO_INVENTARIO) {
			inventario = (Inventario) JSON.deserialize(datos, Inventario.class);
		} else if (tipo == TIPO_AUTORIZACION) {
			autorizacion = (Autorizacion) JSON.deserialize(datos, Autorizacion.class);
		}
	}

	// ===== Datos iniciales del modal =====

	public static Map<String, Object> datosIniciales(Id solicitudId, String tipo) {
		FSC_FormalizacionGarantiasService.validarActorFormalizacion(solicitudId);
		ResidentialLoanApplication rla = consultarSolicitud(solicitudId);
		FSC_Garantia__c garantia = FSC_FormalizacionGarantiasService.consultarGarantiaPrincipal(solicitudId);
		if (garantia == null) {
			throw new AuraHandledException('La solicitud no tiene una garantía para formalizar.');
		}
		Map<String, Object> datos = new Map<String, Object>();
		if (tipo == TIPO_INVENTARIO) {
			List<Map<String, Object>> documentos = new List<Map<String, Object>>();
			for (String concepto : DOCUMENTOS_INVENTARIO) {
				documentos.add(new Map<String, Object>{ 'concepto' => concepto, 'cantidad' => null });
			}
			List<Map<String, Object>> tasas = new List<Map<String, Object>>();
			for (String concepto : TASAS_INVENTARIO.keySet()) {
				tasas.add(new Map<String, Object>{ 'concepto' => concepto, 'cantidad' => null, 'valor' => TASAS_INVENTARIO.get(concepto) });
			}
			datos.put('nombreCliente', rla.Account?.Name);
			datos.put('telefono', TELEFONO_FORMALIZACION);
			datos.put('correo', CORREO_FORMALIZACION);
			datos.put('fecha', String.valueOf(Date.today()));
			datos.put('montoContrato', rla.FSC_MontoAprobado__c);
			datos.put('moneda', rla.FSC_Moneda__c);
			datos.put('descripcionInmueble', descripcionInmueble(garantia));
			datos.put('documentos', documentos);
			datos.put('tasas', tasas);
		} else if (tipo == TIPO_AUTORIZACION) {
			datos.put('fechaDocumento', String.valueOf(Date.today()));
			datos.put('tipoContrato', rla.RecordType?.DeveloperName == 'FSC_Solicitud_Credito_PYME'
				? 'Préstamo Comercial con Garantía Mobiliaria'
				: 'Préstamo con Garantía Mobiliaria');
			datos.put('fechaContrato', rla.FSC_Fecha_Contrato__c == null ? null : String.valueOf(rla.FSC_Fecha_Contrato__c));
			datos.put('tipoVehiculo', garantia.FSC_Tipo_Vehiculo__c);
			datos.put('marca', garantia.FSC_Marca_Vehiculo__c);
			datos.put('modelo', garantia.FSC_Modelo_Vehiculo__c);
			datos.put('anio', garantia.FSC_Ano_Vehiculo__c == null ? null : String.valueOf(garantia.FSC_Ano_Vehiculo__c.intValue()));
			datos.put('color', garantia.FSC_Color_Vehiculo__c);
			datos.put('chasis', garantia.FSC_Numero_Chasis_Vehiculo__c);
			datos.put('placa', garantia.FSC_Numero_Placa_Vehiculo__c);
			datos.put('motor', garantia.FSC_Serial_Motor_Vehiculo__c);
			datos.put('matricula', garantia.FSC_Numero_Matricula__c);
			datos.put('tratamientoPropietario', rla.Account?.IsPersonAccount == true ? 'del señor' : 'de la empresa');
			datos.put('nombrePropietario', rla.Account?.Name);
			datos.put('sexoAutorizado', 'Masculino');
			datos.put('nacionalidadAutorizado', 'dominicano');
			datos.put('domicilioAutorizado', DOMICILIO_AUTORIZADO);
		} else {
			throw new AuraHandledException('Tipo de documento no válido.');
		}
		return datos;
	}

	// ===== Generación =====

	public static Id generar(Id solicitudId, String tipo, String datosJson) {
		FSC_FormalizacionGarantiasService.validarActorFormalizacion(solicitudId);
		Map<String, Object> entrada;
		try {
			entrada = String.isBlank(datosJson) ? new Map<String, Object>() : (Map<String, Object>) JSON.deserializeUntyped(datosJson);
		} catch (Exception e) {
			throw new AuraHandledException('Los datos del documento no son válidos.');
		}
		ResidentialLoanApplication rla = consultarSolicitud(solicitudId);

		PageReference pagina;
		String titulo;
		if (tipo == TIPO_INVENTARIO) {
			pagina = Page.FSC_InventarioRegistroTitulos;
			pagina.getParameters().put('datos', JSON.serialize(armarInventario(entrada)));
			titulo = 'Inventario para registro de títulos - ' + rla.Name;
		} else if (tipo == TIPO_AUTORIZACION) {
			pagina = Page.FSC_AutorizacionOposicionMatricula;
			pagina.getParameters().put('datos', JSON.serialize(armarAutorizacion(entrada)));
			titulo = 'Autorización de oposición y entrega de matrícula - ' + rla.Name;
		} else {
			throw new AuraHandledException('Tipo de documento no válido.');
		}
		pagina.getParameters().put('tipo', tipo);
		pagina.setRedirect(false);
		Blob pdf = Test.isRunningTest() ? Blob.valueOf('TEST PDF') : pagina.getContentAsPDF();
		if (pdf == null || pdf.size() == 0) {
			throw new AuraHandledException('El documento se generó vacío.');
		}
		return FSC_FormalizacionGarantiasService.adjuntarDocumento(solicitudId, titulo, pdf);
	}

	@TestVisible
	private static Inventario armarInventario(Map<String, Object> entrada) {
		Inventario inv = new Inventario();
		inv.nombreCliente = texto(entrada, 'nombreCliente', true, 'El nombre del cliente');
		inv.telefono = texto(entrada, 'telefono', false, 'El teléfono');
		inv.correo = texto(entrada, 'correo', false, 'El correo electrónico');
		Date fechaInventario = fecha(entrada, 'fecha', true, 'La fecha');
		inv.fecha = fechaInventario.format();
		Decimal monto = decimalDe(entrada.get('montoContrato'));
		String moneda = texto(entrada, 'moneda', false, 'La moneda');
		inv.montoContrato = monto == null ? '' : FSC_ContratoFormatoService.simboloMoneda(moneda) + ' ' + FSC_ContratoFormatoService.formatearMonto(monto);
		inv.descripcionInmueble = texto(entrada, 'descripcionInmueble', true, 'La descripción del inmueble');

		inv.documentos = new List<Fila>();
		for (Object item : lista(entrada, 'documentos')) {
			Map<String, Object> fila = (Map<String, Object>) item;
			String concepto = texto(fila, 'concepto', true, 'El concepto');
			Decimal cantidad = decimalDe(fila.get('cantidad'));
			inv.documentos.add(new Fila(concepto, cantidad, null));
		}

		Decimal total = 0;
		inv.tasas = new List<Fila>();
		for (Object item : lista(entrada, 'tasas')) {
			Map<String, Object> fila = (Map<String, Object>) item;
			String concepto = texto(fila, 'concepto', true, 'El concepto');
			Decimal cantidad = decimalDe(fila.get('cantidad'));
			Decimal valor = decimalDe(fila.get('valor'));
			Fila tasa = new Fila(concepto, cantidad, valor);
			total += tasa.precioNumero;
			inv.tasas.add(tasa);
		}
		inv.total = FSC_ContratoFormatoService.formatearMonto(total);
		return inv;
	}

	@TestVisible
	private static Autorizacion armarAutorizacion(Map<String, Object> entrada) {
		Autorizacion aut = new Autorizacion();
		Date fechaDocumento = fecha(entrada, 'fechaDocumento', true, 'La fecha del documento');
		aut.fechaDocumento = fechaDocumento.day() + ' de ' + FSC_ContratoFormatoService.mes(fechaDocumento.month()) + ' del año ' + fechaDocumento.year();
		aut.ciudad = CIUDAD;
		aut.tipoContrato = texto(entrada, 'tipoContrato', true, 'El tipo de contrato');
		aut.fechaContrato = FSC_ContratoFormatoService.fechaCortaEnLetras(fecha(entrada, 'fechaContrato', true, 'La fecha del contrato'));

		List<String> partes = new List<String>();
		agregarParte(partes, 'Tipo de Vehículo', texto(entrada, 'tipoVehiculo', true, 'El tipo de vehículo'));
		agregarParte(partes, 'Marca', texto(entrada, 'marca', true, 'La marca'));
		agregarParte(partes, 'Modelo', texto(entrada, 'modelo', true, 'El modelo'));
		agregarParte(partes, 'Año', texto(entrada, 'anio', true, 'El año'));
		agregarParte(partes, 'Color', texto(entrada, 'color', true, 'El color'));
		agregarParte(partes, 'Chasis No.', texto(entrada, 'chasis', true, 'El chasis'));
		agregarParte(partes, 'Registro y Placa No.', texto(entrada, 'placa', true, 'La placa'));
		agregarParte(partes, 'Motor o No. de Serie', texto(entrada, 'motor', false, 'El motor'));
		agregarParte(partes, 'Matrícula No.', texto(entrada, 'matricula', true, 'La matrícula'));
		String tratamientoPropietario = texto(entrada, 'tratamientoPropietario', true, 'El tratamiento del propietario');
		String nombrePropietario = texto(entrada, 'nombrePropietario', true, 'El nombre del propietario');
		aut.vehiculo = String.join(partes, ', ') + ', a nombre ' + tratamientoPropietario + ' ' + nombrePropietario.toUpperCase() + '.';

		Boolean femenino = texto(entrada, 'sexoAutorizado', true, 'El sexo de la persona autorizada') == 'Femenino';
		String nombreAutorizado = texto(entrada, 'nombreAutorizado', true, 'El nombre de la persona autorizada');
		String nacionalidad = texto(entrada, 'nacionalidadAutorizado', true, 'La nacionalidad');
		String estadoCivil = texto(entrada, 'estadoCivilAutorizado', true, 'El estado civil');
		String cedula = texto(entrada, 'cedulaAutorizado', true, 'La cédula');
		String domicilio = texto(entrada, 'domicilioAutorizado', true, 'El domicilio');
		aut.autorizado =
			(femenino ? 'a la señora ' : 'al señor ') +
			nombreAutorizado +
			', ' +
			nacionalidad +
			', mayor de edad, ' +
			estadoCivil +
			(femenino ? ', portadora' : ', portador') +
			' de la cédula de identidad y electoral No. ' +
			cedula +
			(femenino ? ', domiciliada y residente en ' : ', domiciliado y residente en ') +
			domicilio +
			'.';
		aut.firmante = System.Label.FSC_FirmanteAutorizacionMatricula;
		return aut;
	}

	// ===== Utilidades =====

	private static ResidentialLoanApplication consultarSolicitud(Id solicitudId) {
		List<ResidentialLoanApplication> solicitudes = [
			SELECT Id, Name, FSC_MontoAprobado__c, FSC_Moneda__c, FSC_Fecha_Contrato__c, RecordType.DeveloperName, Account.Name, Account.IsPersonAccount
			FROM ResidentialLoanApplication
			WHERE Id = :solicitudId
			LIMIT 1
		];
		if (solicitudes.isEmpty()) {
			throw new AuraHandledException('No se encontró la solicitud o no tiene acceso a ella.');
		}
		return solicitudes[0];
	}

	private static String descripcionInmueble(FSC_Garantia__c garantia) {
		List<String> partes = new List<String>();
		if (!String.isBlank(garantia.FSC_Descripcion_de_la_Garantia__c)) {
			partes.add(garantia.FSC_Descripcion_de_la_Garantia__c);
		}
		if (!String.isBlank(garantia.FSC_Numero_Titulo__c)) {
			partes.add('Título No. ' + garantia.FSC_Numero_Titulo__c);
		}
		if (!String.isBlank(garantia.FSC_Ubicacion__c)) {
			partes.add('Ubicación: ' + garantia.FSC_Ubicacion__c);
		}
		return String.join(partes, '. ').left(TEXTO_MAXIMO);
	}

	private static void agregarParte(List<String> partes, String etiqueta, String valor) {
		if (!String.isBlank(valor)) {
			partes.add(etiqueta + ' ' + valor);
		}
	}

	private static String texto(Map<String, Object> datos, String clave, Boolean requerido, String nombre) {
		Object valor = datos.get(clave);
		String resultado = valor == null ? null : String.valueOf(valor).trim();
		if (String.isBlank(resultado)) {
			if (requerido) {
				throw new AuraHandledException(nombre + ' es requerido.');
			}
			return null;
		}
		if (resultado.length() > TEXTO_MAXIMO) {
			throw new AuraHandledException(nombre + ' no puede superar 2.000 caracteres.');
		}
		return resultado;
	}

	private static Date fecha(Map<String, Object> datos, String clave, Boolean requerido, String nombre) {
		String valor = texto(datos, clave, requerido, nombre);
		if (valor == null) {
			return null;
		}
		try {
			return Date.valueOf(valor.left(10));
		} catch (Exception e) {
			throw new AuraHandledException(nombre + ' no es válida.');
		}
	}

	private static Decimal decimalDe(Object valor) {
		if (valor == null || String.isBlank(String.valueOf(valor))) {
			return null;
		}
		try {
			Decimal numero = Decimal.valueOf(String.valueOf(valor));
			if (numero < 0) {
				throw new AuraHandledException('Las cantidades y valores no pueden ser negativos.');
			}
			return numero;
		} catch (TypeException e) {
			throw new AuraHandledException('Las cantidades y valores deben ser numéricos.');
		}
	}

	private static List<Object> lista(Map<String, Object> datos, String clave) {
		Object valor = datos.get(clave);
		return valor instanceof List<Object> ? (List<Object>) valor : new List<Object>();
	}

	// ===== Tipos =====

	public class Inventario {
		public String nombreCliente { get; set; }
		public String telefono { get; set; }
		public String correo { get; set; }
		public String fecha { get; set; }
		public String montoContrato { get; set; }
		public String descripcionInmueble { get; set; }
		public List<Fila> documentos { get; set; }
		public List<Fila> tasas { get; set; }
		public String total { get; set; }
	}

	public class Fila {
		public String concepto { get; set; }
		public String cantidad { get; set; }
		public String valor { get; set; }
		public String precio { get; set; }
		public Decimal precioNumero { get; set; }

		public Fila() {
		}

		public Fila(String concepto, Decimal cantidad, Decimal valor) {
			this.concepto = concepto;
			this.cantidad = cantidad == null || cantidad == 0 ? '' : String.valueOf(cantidad.stripTrailingZeros().toPlainString());
			this.valor = valor == null ? '' : FSC_ContratoFormatoService.formatearMonto(valor);
			this.precioNumero = cantidad == null || valor == null ? 0 : cantidad * valor;
			this.precio = valor == null ? '' : FSC_ContratoFormatoService.formatearMonto(this.precioNumero);
		}
	}

	public class Autorizacion {
		public String fechaDocumento { get; set; }
		public String ciudad { get; set; }
		public String tipoContrato { get; set; }
		public String fechaContrato { get; set; }
		public String vehiculo { get; set; }
		public String autorizado { get; set; }
		public String firmante { get; set; }
	}
}