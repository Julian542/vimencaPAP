public class VimencashModel {

    // Carga de Error Común
    public class ApiError {
        public Integer status;
        public String message;
        public String traceId;
        public String details;
    }

    public class ApiMessage {
        public String codigo;
        public String descripcion;
        public ApiMessage() {}
        public ApiMessage(String c, String d){ codigo = c; descripcion = d; }
    }

    // GET CaseTypes
    public class CaseTypeItem {
        public String tipoCaso;
        public List<String> subtipos;
    }

    // GET ProductTypes (solo label)
    public class ProductTypeItem {
        public String label;  // RecordType.Name
    }

    // POST ValidateStatus
    public class ValidateStatusRequest {
        public String tipoProducto;
        public String idProducto;
        public String tipoCliente; 
        public String idCliente;
        public String tipoCaso;
        public String tipo; 
    }

    public class ValidateStatusResponse {
        public Boolean aptoParaCancelacion;
        public List<ApiMessage> mensajes;
        public Integer casosPendientes;
    }

    // POST CaseRequest
    public class CaseRequest {
        public String tipoProducto;
        public String idProducto;
        public String tipoCliente; 
        public String idCliente;
        public String motivocreacion;
        public String tipoCaso;
        public String tipo; 
    }

    public class CaseResponse {
        public String numeroCaso;
        public String fecha; // dd-MM-yyyy
        public String hora;  // HH:mm:ss
        public String motivocreacion;
        public String statusSolicitud;
        public String transaccionId;
        public String canalOrigen; // App Vimencash
        public String fechaEstimadaResolucion; // dd-MM-yyyy
    }

    public static String newTraceId(){
        return String.valueOf(Crypto.getRandomLong()) + '-' + String.valueOf(Datetime.now().getTime());
    }

    public static void respondError(Integer httpStatus, String message, String details){
        ApiError err = new ApiError();
        err.status = httpStatus;
        err.message = message;
        err.details = details;
        if (httpStatus == 500) {
            err.traceId = newTraceId();
        }

        RestContext.response.statusCode = httpStatus;
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(err));
    }

    public static Boolean isBlank(String s){
        return String.isBlank(s);
    }
}