public class REST_Wrappers {

    // Estructura de Response Datacredito
    public class Mensajes{
        public List<String> Evaluacion;
    }
    public class Generales{
        public String Dictamen;
        public Integer Xcore;
        // public String Mensajes;
        public Mensajes Mensajes;
    }
    public class ErrorHandling{
        public String Description;
        public Integer Id;
    }
    public class FiltroBcoVimencaPre{
        public Generales Generales;
    }
    public class DCR{
        public FiltroBcoVimencaPre Filtro_BcoVimencaPre;
        public ErrorHandling ErrorHandling;
    }
    public class responseDatacredito_WS {
        public DCR DCR;
    }

    // Estructura de Response Monto cuota
    public class responseMonto_WS {
        public Decimal montoCuotas;
        public string responseCode;
        public string message;
    }

    // Estructura Sincronizar Solicitud
    public class ConsultarEstadoSolBizagiResult {
        public integer CodigoEstado;
        public string DescripcionEstado;
    }
    public class responseSyncSolicitud_WS {
        public ConsultarEstadoSolBizagiResult ConsultarEstadoSolBizagiResult;
    }

    
    // Estructura de Response Creación de Solicitud
    // public class Entities {
    //     public String Path;
    //     public String Atrib;
    //     public String Value;
    //     public String ErrorMessage;
    // }
    // public class errorMessage{
    //     public Entities Entities;
    // }
    public class processError{
        //public integer errorCode;
        public String errorMessage;
    }
    public class responseCrearSolicitud_WS {
        // public Integer processId;
        public Integer processRadNumber;
        public processError processError;
    }
    
}