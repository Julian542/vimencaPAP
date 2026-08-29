public class INT013TPDTO {
    public class Result {
        @AuraEnabled public String ErrorCode;
        @AuraEnabled public String ErrorText;
        public Map<String, String> valuesXML = new Map<String, String>{
            'NumCuenta' => 'Name',
                'AliasCuenta' => 'ASE_Alias_de_la_cuenta__c',
                'TitularesCuenta' => 'ASE_Titular_de_la_cuenta__c',
                'NumCuenta' => 'ASE_N_de_cuenta__c',
                'Estado' => 'ASE_Estado__c',
                'TipoProducto' => 'ASE_Linea_de_producto__c',
                //'Producto' => 'ASE_Codigo_de_producto__c',//Campo no editable
                'FechaApertura' => 'ASE_Fecha_de_apertura__c',
                'FechaReapertura' => 'ASE_Fecha_de_reapertura__c',
                'FechaCierre' => 'ASE_Fecha_de_cierre_cancelacion__c',
                'TipoVinculacion' => 'ASE_Tipo_de_vinculacion__c',
                //'PuntoAtencion' => 'ASE_Oficina_Ejecutivo__c',// previus field 'PuntoAtencion'
                'EjecutivoNombre' => 'ASE_Ejecutivo_int__c',
                'CuentaRegional' => 'ASE_Cuenta_regional__c',
                'FechaUltAct' => 'ASE_Fecha_de_la_ultima_actividad__c',
                'MotivoCancelacion' => 'ASE_Motivo_de_rechazo_cancelacion__c',
                'PagosTransitoUSD' => 'ASE_Consumos_en_transito_US__c',
                'PagosTransitoRDP' => 'ASE_Consumos_en_transito_RD__c',
                'BalanceDisponibleRDP' => 'ASE_Balance_disponible_RD__c',
                'BalanceDisponibleUSD' => 'ASE_Balance_disponible_US__c',
                'BalanceFechaRDP' => 'ASE_Balance_a_la_fecha_RD__c',
                'BalanceFechaUSD' => 'ASE_Balance_a_la_fecha_US__c',
                'LimiteRDP' => 'ASE_Balance_Maximo__c',
                'FechaCorte' => 'ASE_Fecha_de_corte__c',
                'PuntosVencidos' => 'ASE_Puntos_vencidos__c',
                'PuntosVencer' => 'ASE_Puntos_por_vencer__c',
                'PuntosGenerados' => 'ASE_Puntos_generados__c',
                'PuntosCanjeados' => 'ASE_Puntos_canjeados__c',
                'PuntosAcumulados' => 'ASE_Puntos_acumulados__c',
                'FechaExpiracion' => 'ASE_Fecha_de_expiracion__c',
                'TasaInteres' => 'ASE_Tasa_de_interes__c',
                'NumeroTarjeta' => 'ASE_Numero_Tarjeta__c'
                };
                    }
    
    public class Producto {
        public List<String> fields = new List<String> {'NumCuenta', 'AliasCuenta', 'TitularesCuenta', 'Estado', 'TipoProducto', 'Producto', 'FechaApertura', 'FechaReapertura', 'FechaCierre', 'TipoVinculacion', 'PuntoAtencion', 'EjecutivoNombre', 'CuentaRegional', 'FechaUltAct', 'MotivoCancelacion', 'PagosTransitoUSD', 'PagosTransitoRDP', 'BalanceDisponibleRDP', 'BalanceDisponibleUSD', 'BalanceFechaRDP', 'BalanceFechaUSD', 'LimiteRDP', 'FechaCorte', 'PuntosVencidos', 'PuntosVencer', 'PuntosGenerados', 'PuntosCanjeados', 'PuntosAcumulados', 'FechaExpiracion', 'TasaInteres', 'NumeroTarjeta'};
            @AuraEnabled public Map<String, String> values;
        
        public Producto() {
            values = new Map<String, String>();
        }
    }
    
    public class Detalle {
        public List<String> fields = new List<String> {'NumCuenta', 'AliasCuenta', 'TitularesCuenta', 'Estado', 'TipoProducto', 'Producto', 'FechaApertura', 'FechaReapertura', 'FechaCierre', 'TipoVinculacion', 'PuntoAtencion', 'EjecutivoNombre', 'CuentaRegional', 'FechaUltAct', 'MotivoCancelacion', 'PagosTransitoUSD', 'PagosTransitoRDP', 'BalanceDisponibleRDP', 'BalanceDisponibleUSD', 'BalanceFechaRDP', 'BalanceFechaUSD', 'LimiteRDP', 'FechaCorte', 'PuntosVencidos', 'PuntosVencer', 'PuntosGenerados', 'PuntosCanjeados', 'PuntosAcumulados', 'FechaExpiracion', 'TasaInteres', 'NumeroTarjeta'};
        @AuraEnabled public Map<String, String> values;
        
        public Detalle() {
            values = new Map<String, String>();
        }
    }
    
    @AuraEnabled public Result result;
    @AuraEnabled public Producto producto;
    @AuraEnabled public Detalle detalle;
    
    public INT013TPDTO() {
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