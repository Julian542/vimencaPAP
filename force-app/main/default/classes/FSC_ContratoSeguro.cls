/**
 * Datos de una póliza tal como se redactan en el contrato. Si la póliza tiene fecha de endoso se usa la versión
 * "endosada" del artículo; si no, la versión de póliza colectiva de EL BANCO (prima mensual).
 */
public without sharing class FSC_ContratoSeguro {
    public static final String TIPO_VIDA = 'VIDA';
    public static final String TIPO_INCENDIO = 'INCENDIO';
    public static final String TIPO_VEHICULO = 'VEHICULO';

    public String tipo { get; private set; }
    public Boolean aplica { get; private set; }
    public Boolean endosado { get; private set; }
    public String poliza { get; private set; }
    public String aseguradora { get; private set; }
    public String direccion { get; private set; }
    public String fechaEndoso { get; private set; }
    public String montoLetras { get; private set; }
    public String montoNumero { get; private set; }
    public String primaLetras { get; private set; }
    public String primaNumero { get; private set; }
    public String cuotasLetras { get; private set; }
    public String cuotasNumero { get; private set; }
    public String simboloMoneda { get; private set; }

    public Boolean esVida {
        get { return tipo == TIPO_VIDA; }
    }
    public Boolean esIncendio {
        get { return tipo == TIPO_INCENDIO; }
    }
    public Boolean esVehiculo {
        get { return tipo == TIPO_VEHICULO; }
    }

    public static FSC_ContratoSeguro noAplica(String tipo) {
        FSC_ContratoSeguro seguro = new FSC_ContratoSeguro();
        seguro.tipo = tipo;
        seguro.aplica = false;
        seguro.endosado = false;
        return seguro;
    }

    public static FSC_ContratoSeguro crear(
        String tipo,
        String poliza,
        String aseguradora,
        String direccion,
        Date fechaEndoso,
        Decimal monto,
        Decimal prima,
        Integer cuotas,
        String moneda
    ) {
        FSC_ContratoSeguro seguro = noAplica(tipo);
        seguro.aplica = true;
        seguro.endosado = fechaEndoso != null;
        seguro.poliza = poliza;
        seguro.aseguradora = aseguradora;
        seguro.direccion = direccion;
        seguro.fechaEndoso = FSC_ContratoFormatoService.fechaCortaEnLetras(fechaEndoso);
        seguro.montoLetras = FSC_ContratoFormatoService.montoEnLetras(monto, moneda);
        seguro.montoNumero = FSC_ContratoFormatoService.formatearMonto(monto);
        seguro.primaLetras = FSC_ContratoFormatoService.montoEnLetras(prima, moneda);
        seguro.primaNumero = FSC_ContratoFormatoService.formatearMonto(prima);
        seguro.cuotasLetras = cuotas == null ? '' : FSC_ContratoFormatoService.numeroMasculinoEnLetras(cuotas).toLowerCase();
        seguro.cuotasNumero = cuotas == null ? '' : String.valueOf(cuotas);
        seguro.simboloMoneda = FSC_ContratoFormatoService.simboloMoneda(moneda);
        return seguro;
    }
}