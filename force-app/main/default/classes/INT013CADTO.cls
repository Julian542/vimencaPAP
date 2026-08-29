public class INT013CADTO {
    public class Result {
        @AuraEnabled public String ErrorCode;
        @AuraEnabled public String ErrorText;
    	public Map<String, String> valuesXML = new Map<String, String>{
            'NumCuenta' => 'Name',
                'AliasCuenta' => 'ASE_Alias_de_la_cuenta__c',
                'Estado' => 'ASE_Estado__c',
                'TipoProducto' => 'ASE_Linea_de_producto__c',
                //'Producto' => 'ASE_Codigo_de_producto__c',//Campo no editable
                'FechaApertura' => 'ASE_Fecha_de_apertura__c',
                'FechaReapertura' => 'ASE_Fecha_de_reapertura__c',
                'FechaCierre' => 'ASE_Fecha_de_cierre_cancelacion__c',
                'TipoVinculacion' => 'ASE_Tipo_de_vinculacion__c',
                //'EjecutivoNombre' => 'ASE_Ejecutivo__c',// previus field 'EjecutivoNombre'
                'EjecutivoNombre' => 'ASE_Ejecutivo_int__c', // new field 'EjecutivoNombre'
                'Saldo' => 'ASE_Saldo_disponible__c',                
                //'PuntoAtencion' => 'ASE_Oficina_Ejecutivo__c',// previus field 'PuntoAtencion'
                'PuntoAtencion' => 'ASE_Oficina_Ejecutivo_int__c', // new field 'PuntoAtencion'
                'CuentaRegional' => 'ASE_Cuenta_regional__c',
                'FechaUltAct' => 'ASE_Fecha_de_la_ultima_actividad__c',
                'Titulares' => 'ASE_Titular_de_la_cuenta__c',
                'NumCuenta' => 'ASE_N_de_cuenta__c',
                'FechaCorte' => 'ASE_Fecha_de_corte__c',
                'MotivoCancelacion' => 'ASE_Motivo_de_rechazo_cancelacion__c',
                'BalanceTotal' => 'ASE_Balance_total__c',
                'TieneRestriccion' => 'ASE_Tiene_restriccion__c',
                'DireccionEntrega' => 'ASE_Direccion_de_entrega__c',
                //'RetencionEstados' => 'ASE_Oficina_retencion_de_estado__c',
                'SaldoTransito' => 'ASE_Saldo_en_transito__c',
                'SaldoUtilizado' => 'ASE_Saldo_utilizado__c',
                'ComisionesPendientes' => 'ASE_Comisiones_pendientes_div__c',
                'PuntosGenerados' => 'ASE_Puntos_generados__c',
                'PuntosAcumulados' => 'ASE_Puntos_acumulados__c',
                'PuntosCanjeados' => 'ASE_Puntos_canjeados__c',
                'PuntosVencer' => 'ASE_Puntos_por_vencer__c',
                'PuntosVencidos' => 'ASE_Puntos_vencidos__c',
                'MontoFianzas' => 'ASE_Monto_fianzas__c',
                'MontoEmbargado' => 'ASE_Monto_embargado__c',
                'MontoBloqueado' => 'ASE_Monto_bloqueado__c',
                'MontoReservado' => 'ASE_Monto_reservado__c',
                'Moneda' => 'ASE_Moneda__c',
                'Transito1Dia' => 'ASE_Transitos_1_dia__c',
                'Transito2Dia' => 'ASE_Transitos_2_dias__c',
                'Transito3Dia' => 'ASE_Transitos_3_dias__c',
                'Transito4Dia' => 'ASE_Transitos_4_dias__c',
                'Transito5DiaMas' => 'ASE_Transitos_5_dias_o_mas__c',
                'DepositoChequesHoy' => 'ASE_Depositos_cheques_hoy__c',
                'SaldoTotalHoy' => 'ASE_Saldo_total_hoy__c',
                'SaldoTotalAyer' => 'ASE_Saldo_total_ayer__c',
                'SaldoEfectivoHoy' => 'ASE_Saldo_efectivo_hoy__c',
                'PagaInteres' => 'ASE_Paga_interes__c',
                'NumLibreta' => 'ASE_N_de_libreta__c',
                'ComisionesPendFlg' => 'ASE_Comisiones_pendientes__c'
                };
    }
    
    public class Producto {
        public List<String> fields = new List<String> {'NumCuenta','AliasCuenta','Estado','TipoProducto','Producto','FechaApertura','FechaReapertura','FechaCierre','TipoVinculacion','EjecutivoNombre','Saldo','PuntoAtencion','CuentaRegional','FechaUltAct','Titulares'};
        @AuraEnabled public Map<String, String> values;
        
        public Producto() {
            values = new Map<String, String>();
        }
    }
    
    public class Detalle {
        public List<String> fields = new List<String> {'NumCuenta','FechaCorte','MotivoCancelacion','BalanceTotal','TieneRestriccion','DireccionEntrega','RetencionEstados','SaldoTransito','SaldoUtilizado','ComisionesPendientes','PuntosGenerados','PuntosAcumulados','PuntosCanjeados','PuntosVencer','PuntosVencidos','MontoFianzas','MontoEmbargado','MontoBloqueado','MontoReservado','Moneda','Transito1Dia','Transito2Dia','Transito3Dia','Transito4Dia','Transito5DiaMas','DepositoChequesHoy','SaldoTotalHoy','SaldoTotalAyer','SaldoEfectivoHoy','PagaInteres','NumLibreta','ComisionesPendFlg'};
        @AuraEnabled public Map<String, String> values;
        
        public Detalle() {
            values = new Map<String, String>();
        }
    }
    
    @AuraEnabled public Result result;
    @AuraEnabled public Producto producto;
    @AuraEnabled public Detalle detalle;
    
    public INT013CADTO() {
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