public class INT013CCDTO {
    public class Result {
        @AuraEnabled public String ErrorCode;
        @AuraEnabled public String ErrorText;
        public Map<String, String> valuesXML = new Map<String, String>{
            'NumCuenta' => 'Name',
                'AliasCuenta' => 'ASE_Alias_de_la_cuenta__c',
                'Estado' => 'ASE_Estado__c',
                'TipoProducto' => 'ASE_Linea_de_producto__c',
                'Producto' => 'ASE_Codigo_de_producto__c',//Campo no editable
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
                'Transito1Dia' => 'ASE_Transitos_1_dia__c',
                'Transito2Dia' => 'ASE_Transitos_2_dias__c',
                'Transito3Dia' => 'ASE_Transitos_3_dias__c',
                'Transito4Dia' => 'ASE_Transitos_4_dias__c',
                'Transito5DiaMas' => 'ASE_Transitos_5_dias_o_mas__c',
                'TieneRestriccion' => 'ASE_Restricciones__c',
                'FrecuenciaEmision' => 'ASS_Frecuencia_de_emision__c',
                'MetodoEDC' => 'ASS_Metodo_de_entrega__c',
                'DireccionEDC' => 'ASE_Direccion_de_entrega__c',
                'EmailEDC' => 'ASS_Correo_electronico_de_entrega__c',
                'RetencionEDC' => 'ASS_Retencion_de_estados__c',
                'UltimoEnvioEDC' => 'ASS_Estado_ultimo_envio__c',
                'OficinaEntregaEDC' => 'ASS_Oficina_de_entrega__c',
                'MontoReservado' => 'ASE_Monto_reservado__c',
                'MontoFianzas' => 'ASE_Monto_fianzas__c',
                'MontoEmbargado' => 'ASE_Monto_embargado__c',
                'MontoBloqueado' => 'ASE_Monto_bloqueado__c',
                'MontoAprobadoLE' => 'ASE_Monto_aprobado__c',
                'MontoDisponibleLE' => 'ASE_Monto_disponible__c',
                'FechaVencimientoLE' => 'ASE_Fecha_de_vencimiento__c',
                'EstadoLE' => 'ASS_Estado_de_linea__c',
                'SGVencido' => 'ASE_Sobregiro_vencido__c',
                'DiasSGVencido' => 'ASE_Dias_de_sobregiro_vencido__c',
                'InteresesPendSGVencido' => 'ASE_Interesespendientes_sobregirovencido__c',
                'ComisionesPendSG' => 'ASE_Comisiones_pendientes__c',
                'TotalSG' => 'ASE_Total_de_sobregiro__c',
                'SaldoTransitoTR' => 'ASE_Saldo_en_transito__c',
                'SaldoTotalHoy' => 'ASE_Saldo_total_hoy__c',
                'SaldoTotalAyer' => 'ASE_Saldo_total_ayer__c',
                'SaldoEfectivoHoy' => 'ASE_Saldo_efectivo_hoy__c',
                'SaldoUtilizadoTR' => 'ASE_Saldo_utilizado__c',
                'ComisionesPendTR' => 'ASE_Comisiones_pendientes_div__c',
                'PuntosGenerados' => 'ASE_Puntos_generados__c',
                'PuntosAcumulados' => 'ASE_Puntos_acumulados__c',
                'PuntosCanjeados' => 'ASE_Puntos_canjeados__c',
                'PuntosVencer' => 'ASE_Puntos_por_vencer__c',
                'PuntosVencidos' => 'ASE_Puntos_vencidos__c',
                'Moneda' => 'ASE_Moneda__c',
                'SuspensionesPagos' => 'ASS_Suspensiones_de_pago_flg__c',
                'ComisionesPend' => 'ASE_Comisiones_pendientes__c',
                'ComisionSG' => 'ASE_Comisiones_pendientes_div__c',
                'InteresSG' => 'ASE_Intereses_por_sobregiro__c',
                'NotasDebitoEnGeneralFlag' => 'ASE_Debito__c',
                'NotasCreditoEnGeneralFlag' => 'ASE_Debito_y_Credito__c',
                'CargoRetencionEstadosFlag' => 'ASS_Retencion_de_estados__c'
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
        public List<String> fields = new List<String> {'NumCuenta','FechaCorte','MotivoCancelacion','BalanceTotal','Transito1Dia','Transito2Dia','Transito3Dia','Transito4Dia','Transito5DiaMas','TieneRestriccion','FrecuenciaEmision','MetodoEDC','DireccionEDC','EmailEDC','RetencionEDC','UltimoEnvioEDC','OficinaEntregaEDC','MontoReservado','MontoFianzas','MontoEmbargado','MontoBloqueado','MontoAprobadoLE','MontoDisponibleLE','FechaVencimientoLE','EstadoLE','SGVencido','DiasSGVencido','InteresesPendSGVencido','ComisionesPendSG','TotalSG','SaldoTransitoTR','SaldoTotalHoy','SaldoTotalAyer','SaldoEfectivoHoy','SaldoUtilizadoTR','ComisionesPendTR','PuntosGenerados','PuntosAcumulados','PuntosCanjeados','PuntosVencer','PuntosVencidos','Moneda','SuspensionesPagos','ComisionesPend','ComisionSG','InteresSG','NotasDebitoEnGeneralFlag','NotasCreditoEnGeneralFlag','CargoRetencionEstadosFlag'};
            @AuraEnabled public Map<String, String> values;
        
        public Detalle() {
            values = new Map<String, String>();
        }
    }
    
    @AuraEnabled public Result result;
    @AuraEnabled public Producto producto;
    @AuraEnabled public Detalle detalle;
    
    public INT013CCDTO() {
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