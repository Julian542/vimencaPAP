public class CrearSolicitudHelper {
    
    public static final string Cedula = 'Cédula';
    public static final string RNC = 'RNC';
    public static final string Pasaporte = 'Pasaporte';
    
    public class Input {
        public Account account;
        public Opportunity opportunity;
        public User user;
        public Matriz_de_producto__c facilidad;
    }
    
    public class Output {
        public Integer processRadNumber;
        public string errorMessage;
        //public string errorCode;
    }
    
    public static boolean isNull(String value){
        return value == null;
    }
    
    public static boolean isNull(Decimal value){
        return value == null;
    }
    
    public static List<string> validar(Input data){
        
        Map<String,Schema.SObjectField> mapAccfields = Schema.Account.SObjectType.getDescribe().fields.getMap();
        Map<String,Schema.SObjectField> mapOppfields = Schema.Opportunity.SObjectType.getDescribe().fields.getMap();
        Map<String,Schema.SObjectField> mapProfields = Schema.Matriz_de_producto__c.SObjectType.getDescribe().fields.getMap();
        
        List<String> requeridos = new List<String>();
        
        // Opportunity fields
        if (isNull(data.opportunity.Plazo__c)) {
            requeridos.add(mapOppfields.get('Plazo__c').getDescribe().getLabel());
        }
        if (isNull(data.opportunity.Tasa__c)) {
            requeridos.add(mapOppfields.get('Tasa__c').getDescribe().getLabel());
        }
        if (isNull(data.opportunity.Monto__c)) {
            requeridos.add(mapOppfields.get('Monto__c').getDescribe().getLabel());
        }
        if (isNull(data.opportunity.Tipo_Solicitud__c)) {
            requeridos.add(mapOppfields.get('Tipo_Solicitud__c').getDescribe().getLabel());
        }
        if (isNull(data.opportunity.Forma_de_pago__c)) {
            requeridos.add(mapOppfields.get('Forma_de_pago__c').getDescribe().getLabel());
        }
        if (isNull(data.opportunity.opp_xcore__c)) {
            requeridos.add(mapOppfields.get('opp_xcore__c').getDescribe().getLabel());
        }
        if (isNull(data.opportunity.Razon_Decision__c)) {
            requeridos.add(mapOppfields.get('Razon_Decision__c').getDescribe().getLabel());
        }
        if (isNull(data.opportunity.Dictamen__c)) {
            requeridos.add(mapOppfields.get('Dictamen__c').getDescribe().getLabel());
        }
        
        // Account fields
        if (isNull(data.account.ACC_NumIdentificacion__c)) {
            requeridos.add(mapAccfields.get('ACC_NumIdentificacion__c').getDescribe().getLabel());
        }
        if (isNull(data.account.ACC_TipoIdentificacion__c)) {
            requeridos.add(mapAccfields.get('ACC_TipoIdentificacion__c').getDescribe().getLabel());
        }
        if (isNull(data.account.Lastname)) {
            requeridos.add(mapAccfields.get('Lastname').getDescribe().getLabel());
        }
        if (isNull(data.account.FirstName) && isNull(data.account.MiddleName)) {
            requeridos.add(mapAccfields.get('FirstName').getDescribe().getLabel());
        }
        return requeridos;
    }
    
    public static Output crearSolicitud(Input data) {
        try {
            String body = createBody(data);
            Output o = REST_WebService.crearSolicitud(body);
            return o;
        } catch (Exception e) { throw e; }
    }
    
    public static String createBody(Input input){
        
        try {
            Boolean isSandbox = [SELECT IsSandbox FROM Organization]?.IsSandbox;
            
            msolicitanteSolicitud msolicitanteSolicitud = new msolicitanteSolicitud();
            msolicitanteSolicitud.numeroIdentificacion = input.account.ACC_NumIdentificacion__c;
            if (Cedula.equals(input.account.ACC_TipoIdentificacion__c)) {
                msolicitanteSolicitud.tipoIdentificacion = 1;    
            }else if (RNC.equals(input.account.ACC_TipoIdentificacion__c)) {
                msolicitanteSolicitud.tipoIdentificacion = 2;    
            }else if (Pasaporte.equals(input.account.ACC_TipoIdentificacion__c)) {
                msolicitanteSolicitud.tipoIdentificacion = 3;    
            }
            msolicitanteSolicitud.tipoSolicitante = 1; // 1 - Deudor || 2 - Co-deudor || 3 - Garante
            
            solicitanteSolicitud solicitanteSolicitud = new solicitanteSolicitud();
            solicitanteSolicitud.msolicitanteSolicitud = new List<msolicitanteSolicitud>{msolicitanteSolicitud};
                
                decisionBuro decisionBuro = new decisionBuro();
            decisionBuro.descripcionDesicion = input.opportunity.Dictamen__c;
            
            tipoIdentificacion tipoIdentificacion = new tipoIdentificacion();
            if (Cedula.equals(input.account.ACC_TipoIdentificacion__c)) {
                tipoIdentificacion.codigoDescripcion = 'C';    
            }else if (RNC.equals(input.account.ACC_TipoIdentificacion__c)) {
                tipoIdentificacion.codigoDescripcion = 'R';    
            }else if (Pasaporte.equals(input.account.ACC_TipoIdentificacion__c)) {
                tipoIdentificacion.codigoDescripcion = 'P';
            }
            
            tipoSolicitante tipoSolicitante = new tipoSolicitante();
            tipoSolicitante.codigo = '1'; // 1 - Deudor || 2 - Co-deudor || 3 - Garante
            
            solicitantesBuro solicitantesBuro = new solicitantesBuro();
            solicitantesBuro.apellidos = input.account.Lastname;
            solicitantesBuro.fecha = Datetime.now();
            solicitantesBuro.identificacion = input.account.ACC_NumIdentificacion__c;
            solicitantesBuro.mensaje = input.opportunity.Razon_Decision__c;
            solicitantesBuro.nombres = input.account.FirstName;
            solicitantesBuro.score = input.opportunity.opp_xcore__c;
            solicitantesBuro.decisionBuro = decisionBuro;
            solicitantesBuro.tipoIdentificacion = tipoIdentificacion;
            solicitantesBuro.tipoSolicitante = tipoSolicitante;
            
            solicitantesBuros solicitantesBuros = new solicitantesBuros();
            solicitantesBuros.solicitantesBuro = solicitantesBuro;
            
            formaPago formaPago = new formaPago();
            formaPago.codigo = input.opportunity.Forma_de_pago__c;
            
            facilidad facilidad = new facilidad();
            facilidad.codigoAplicacion = input.opportunity.Tipo_Solicitud__c;
            facilidad.codigoSubAplicacion = input.facilidad.PRO_Codigo_de_producto__c;
            
            tipoFacilidad tipoFacilidad = new tipoFacilidad();
            tipoFacilidad.codigoAplicacion = input.opportunity.Tipo_Solicitud__c;
            
            mfacilidadSolicitud mfacilidadSolicitud = new mfacilidadSolicitud();
            mfacilidadSolicitud.facilidad = facilidad;
            mfacilidadSolicitud.formaPago = formaPago;
            mfacilidadSolicitud.tipoFacilidad = tipoFacilidad;
            mfacilidadSolicitud.montoSolicitado = input.opportunity.Monto__c;
            mfacilidadSolicitud.plazo = input.opportunity.Plazo__c;
            mfacilidadSolicitud.tasaInteresNueva = input.opportunity.Tasa__c;
            mfacilidadSolicitud.tasaInteres = input.opportunity.Tasa__c;
            
            productosSolicitud productosSolicitud = new productosSolicitud();
            productosSolicitud.mfacilidadSolicitud = mfacilidadSolicitud;
            
            solicitudDeCredito solicitudDeCredito = new solicitudDeCredito();
            solicitudDeCredito.origenEnSalesforce = true;
            solicitudDeCredito.precalificacionCliente = input.opportunity.opp_xcore__c != null ? true:false;
            solicitudDeCredito.productosSolicitud = productosSolicitud;
            solicitudDeCredito.solicitantesBuros = solicitantesBuros;
            solicitudDeCredito.solicitanteSolicitud = solicitanteSolicitud;
            
            entities entities = new entities();
            entities.solicitudDeCredito = solicitudDeCredito;
            
            Cxse Cxse = new Cxse();
            Cxse.entities = entities;
            Cxse.process = 'SolicitudDeCredito';
            
            Cases Cases = new Cases();
            Cases.Cxse = new List<Cxse>{Cxse};
                
                bizAgiWSParam bizAgiWSParam = new bizAgiWSParam();        
            bizAgiWSParam.domain = isSandbox ? 'domain' : 'bvimenca';
            bizAgiWSParam.userName = isSandbox ?  'OficialdeNegocio' : input.user.UsuarioBizagi__c;
            bizAgiWSParam.Cases = Cases;
            
            caseInfo caseInfo = new caseInfo();
            caseInfo.bizAgiWSParam = bizAgiWSParam;
            
            wsCrearCaso body = new wsCrearCaso();
            body.caseInfo = caseInfo;
            
            string strBody = JSON.serialize(body);
            return strBody.replace('Cxse','Case');    
        } catch (Exception e) {
            throw e;
        }
    }
    
    public class msolicitanteSolicitud{
        public Integer tipoSolicitante;
        public Integer tipoIdentificacion;
        public String numeroIdentificacion;
    }
    public class solicitanteSolicitud{
        public List<msolicitanteSolicitud> msolicitanteSolicitud;
    }
    
    public class decisionBuro{
        public string descripcionDesicion;
    }
    public class tipoIdentificacion{
        public string codigoDescripcion;
    }
    public class tipoSolicitante{
        public String codigo;
    }
    
    public class solicitantesBuro{
        public string apellidos;
        public Datetime fecha;
        public string identificacion;
        public string mensaje;
        public string nombres;
        public Decimal score;
        
        public decisionBuro decisionBuro;
        public tipoIdentificacion tipoIdentificacion;
        public tipoSolicitante tipoSolicitante;
    }
    public class solicitantesBuros{
        public solicitantesBuro solicitantesBuro;
    }
    
    public class formaPago{
        public String codigo;
    }
    public class facilidad{
        public String codigoAplicacion;
        public String codigoSubAplicacion;
    }
    public class tipoFacilidad{
        public String codigoAplicacion;
    }
    public class mfacilidadSolicitud{
        public Decimal montoSolicitado;
        public Decimal plazo;
        public Decimal tasaInteresNueva;
        public Decimal tasaInteres;
        
        public formaPago formaPago;
        public facilidad facilidad;
        public tipoFacilidad tipoFacilidad;
    }
    public class productosSolicitud{
        public mfacilidadSolicitud mfacilidadSolicitud;
    }
    
    public class solicitudDeCredito{
        public boolean origenEnSalesforce;
        public boolean precalificacionCliente;
        public productosSolicitud productosSolicitud;
        public solicitantesBuros solicitantesBuros;
        public solicitanteSolicitud solicitanteSolicitud;
    }
    
    public class entities{
        public solicitudDeCredito solicitudDeCredito;
    }
    
    public class Cxse{
        public string process;
        public entities entities;
    }
    
    public class Cases{
        public List<Cxse> Cxse;
    }
    
    public class bizAgiWSParam{
        public string domain;
        public string userName;
        public Cases Cases;
    }
    
    public class caseInfo{
        public bizAgiWSParam bizAgiWSParam;
    }
    
    public class wsCrearCaso{
        public caseInfo caseInfo; 
    }
}