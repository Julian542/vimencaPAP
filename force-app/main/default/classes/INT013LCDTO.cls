public class INT013LCDTO {
    public class Result {
        @AuraEnabled public String ErrorCode;
        @AuraEnabled public String ErrorText;
        public Map<String, String> valuesXML = new Map<String, String>{
            'NumCuenta' => 'Name',
                'AliasCuenta' => 'ASE_Alias_de_la_cuenta__c',
                'Estado' => 'ASE_Estado__c',
                'TipoProducto' => 'ASE_Linea_de_producto__c',
               // 'Producto' => 'ASE_Codigo_de_producto__c',//Campo no editable
                'FechaApertura' => 'ASE_Fecha_de_apertura__c',
                'FechaReapertura' => 'ASE_Fecha_de_reapertura__c',
                'FechaCierre' => 'ASE_Fecha_de_cierre_cancelacion__c',
                'TipoVinculacion' => 'ASE_Tipo_de_vinculacion__c',
                //'EjecutivoNombre' => 'ASE_Ejecutivo__c',// previus field 'EjecutivoNombre'
                'EjecutivoNombre' => 'ASE_Ejecutivo_int__c', // new field 'EjecutivoNombre'
                //'PuntoAtencion' => 'ASE_Oficina_Ejecutivo__c',// previus field 'PuntoAtencion'
                'PuntoAtencion' => 'ASE_Oficina_Ejecutivo_int__c', // new field 'PuntoAtencion'
                'CuentaRegional' => 'ASE_Cuenta_regional__c',
                'FechaUltAct' => 'ASE_Fecha_de_la_ultima_actividad__c',
                'Titulares' => 'ASE_Titular_de_la_cuenta__c',
                'MontoDisponible' => 'ASE_Monto_disponible__c',
                'MontoUtilizado' => 'ASE_Monto_utilizado__c',
                'MontoAprobado' => 'ASE_Monto_aprobado__c',
                'Moneda' => 'ASE_Moneda__c',
                'FechaDecision' => 'ASE_Fecha_de_decision__c',
                'ModoVencimiento' => 'ASE_Modo_de_vencimiento__c',
                'FechaVencimiento' => 'ASE_Fecha_de_vencimiento__c',
                'FechaUltRenovacion' => 'ASE_Fecha_ultima_renovacion__c',
                'NumRenovaciones' => 'ASE_N_Renovaciones__c',
                'FechaUltProrroga' => 'ASE_Fecha_ultima_prorroga__c',
                'NumProrrogas' => 'ASE_N_de_prorrogas__c',
                'DiasProrroga' => 'ASE_Dias_de_prorroga__c',
                'NumSistemaViejo' => 'ASE_N_Sistema_viejo__c',
                'NumUltimaActa' => 'ASE_N_Ultima_acta__c',
                'OrigenFondos' => 'ASE_Origen_fondos__c',
                'FechaProxRevision' => 'ASE_Fecha_proxima_revision__c',
                'SenalOperacionUnica' => 'ASE_Senal_operacion_unica__c',
                'TipoCliente' => 'ASE_Tipo_de_cliente__c',
                'TipoRiesgo' => 'ASE_Tipo_de_riesgo__c'                
                };
    }
    
    public class Producto {
        public List<String> fields = new List<String> {'NumCuenta','AliasCuenta','Estado','TipoProducto','Producto','FechaApertura','FechaReapertura','FechaCierre','TipoVinculacion','EjecutivoNombre','PuntoAtencion','CuentaRegional','FechaUltAct','Titulares'};
        @AuraEnabled public Map<String, String> values;
        
        public Producto() {
            values = new Map<String, String>();
        }
    }
    
    public class Detalle {
        public List<String> fields = new List<String> {'MontoDisponible','MontoUtilizado','MontoAprobado','Moneda','FechaDecision','ModoVencimiento','FechaVencimiento','FechaUltRenovacion','NumRenovaciones','FechaUltProrroga','NumProrrogas','DiasProrroga','NumSistemaViejo','NumUltimaActa','OrigenFondos','FechaProxRevision','SenalOperacionUnica','TipoCliente','TipoRiesgo'};
        @AuraEnabled public Map<String, String> values;
        
        public Detalle() {
            values = new Map<String, String>();
        }
    }
    
    @AuraEnabled public Result result;
    @AuraEnabled public Producto producto;
    @AuraEnabled public Detalle detalle;
    
    public INT013LCDTO() {
        result = new Result();
        producto = new Producto();
        detalle = new Detalle();
    }
    
    public void parse(String response) {
        String productoString, detalleString;
        
        // Parse request result.
        this.result.ErrorCode = response.substringAfter('<ErrorCode>').substringBefore('</ErrorCode>');
        this.result.ErrorText = response.substringAfter('<ErrorText>').substringBefore('</ErrorText>');
        
        if(this.result.errorCode == '000') { 
            // Extract producto & detalle nodes.
            productoString = response.substringAfter('<Producto>').substringBefore('<Detalle>');
            detalleString = response.substringAfter('<Detalle>').substringBefore('</Detalle>');
            
            productoString.replace(detalleString, '');            
            
            for(String field: this.producto.fields) {
                this.producto.values.put(field, productoString.substringAfter('<'+field+'>').substringBefore('</'+field+'>'));
            }
            
            for(String field: this.detalle.fields) {
                this.detalle.values.put(field, detalleString.substringAfter('<'+field+'>').substringBefore('</'+field+'>'));
            }
        }
    }
}