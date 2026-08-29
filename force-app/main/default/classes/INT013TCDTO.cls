public class INT013TCDTO {
    public class Result {
        @AuraEnabled public String ErrorCode;
        @AuraEnabled public String ErrorText;
        public Map<String, String> valuesXML = new Map<String, String>{
            'NumCuenta' => 'Name',
                'AliasCuenta' => 'ASE_Alias_de_la_cuenta__c',
                'TitularesCuenta' => 'ASE_Titular_de_la_cuenta__c',
                'Estado' => 'ASE_Estado__c',
                'TipoProducto' => 'ASE_Linea_de_producto__c',
                'Producto' => 'ASE_Codigo_de_producto__c',
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
                'NumTarjetaAnterior' => 'ASE_N_Tarjeta_anterior__c',
                'TarjetaAdicional' => 'ASE_Es_tarjeta_adicional__c',
                'MotivoCancelacion' => 'ASE_Motivo_de_cancelacion__c',
                'CodMotivoBloqueo' => 'ASE_Cod_Motivo_de_bloqueo__c',
                'Bloqueo' => 'ASE_Bloqueo__c',
                'MotivoBloqueo' => 'ASE_Motivo_del_bloqueo__c',
                'Segmento' => 'ASE_Segmento__c',
                'AutorizacionesPend' => 'ASE_Autorizaciones_pendientes__c',
                'PagosTransitoUSD' => 'ASE_Consumos_en_transito_US__c',
                'PagosTransitoRDP' => 'ASE_Consumos_en_transito_RD__c',
                'PagoMinimoUSD' => 'ASE_Pago_minimo_US__c',
                'PagoMinimoRDP' => 'ASE_Pago_minimo_RD__c',
                'OficinaGestora' => 'ASE_Oficina_gestora__c',
                'OficinaDestino' => 'ASE_Oficina_destino__c',
                'UltTransaccion' => 'ASE_Ultima_transaccion__c',
                'CicloFacturacion' => 'ASE_Ciclo_de_facturacion__c',
                'BalanceCorteRDP' => 'ASE_Balance_al_corte_RD__c',
                'BalanceCorteUSD' => 'ASE_Balance_al_corte_US__c',
                'BalanceDisponibleRDP' => 'ASE_Balance_disponible_RD__c',
                'BalanceDisponibleUSD' => 'ASE_Balance_disponible_US__c',
                'BalanceFechaRDP' => 'ASE_Balance_a_la_fecha_RD__c',
                'BalanceFechaUSD' => 'ASE_Balance_a_la_fecha_US__c',
                'BalanceVencidoRDP' => 'ASE_Balance_vencido_RD__c',
                'BalanceVencidoUSD' => 'ASE_Balance_vencido_US__c',
                'MontoUltPagoRDP' => 'ASE_Monto_ltimo_pago_RD__c',
                'MontoUltPagoUSD' => 'ASE_Monto_Ultimo_pago_US__c',
                'UltimoPago' => 'ASE_Ultimo_pago__c',
                'DiasAtraso' => 'ASE_Dias_de_atraso__c',
                'LimiteRDP' => 'ASE_Limite_en_pesos_RD__c',
                'LimiteUSD' => 'ASE_Limite_en_dolares_US__c',
                'FechaCorte' => 'ASE_Fecha_de_corte__c',
                'NombrePlastico' => 'ASE_Nombre_en_plastico__c',
                'NombreEmpresa' => 'ASE_Compania__c',
                'RNC' => 'ASE_R_N_C__c',
                'NombreCorporacion' => 'ASE_Nombre_de_la_corporacion__c',
                'SaldoTarjetaInd' => 'ASE_Saldo_tarjeta_individual__c',
                'SaldoCorporacion' => 'ASE_Saldo_de_la_corporacion__c',
                'PuntosVencidos' => 'ASE_Puntos_vencidos__c',
                'PuntosVencer' => 'ASE_Puntos_por_vencer__c',
                'PuntosGenerados' => 'ASE_Puntos_generados__c',
                'PuntosCanjeados' => 'ASE_Puntos_canjeados__c',
                'PuntosAcumulados' => 'ASE_Puntos_acumulados__c',
                'FechaExpiracion' => 'ASE_Fecha_de_expiracion__c',
                'TasaInteres' => 'ASE_Tasa_de_interes__c',
                'Email' => 'ASE_Correo_electronico__c',
                'FechaActualDesde' => 'ASE_Fecha_de_inicio_de_vigencia_Plas_act__c',
                'FechaActuaHasta' => 'ASE_Fecha_d_fin_de_vigencia_del_pla_act__c',
                'FechaRenovacionDesde' => 'ASE_Fecha_de_inicio_de_vigencia_nuevopla__c',
                'FechaRenovacionHasta' => 'ASE_Fecha_de_fin_de_vigencia_delnuevopla__c',
                'FechaEmision' => 'ASE_Fecha_de_emision_de_la_tarjeta__c'             
                };
                    }
    
    public class Producto {
        public List<String> fields = new List<String> {'NumCuenta','AliasCuenta','TitularesCuenta','Estado','TipoProducto','Producto','FechaApertura','FechaReapertura','FechaCierre','TipoVinculacion','EjecutivoNombre','PuntoAtencion','CuentaRegional','FechaUltAct'};
            @AuraEnabled public Map<String, String> values;
        
        public Producto() {
            values = new Map<String, String>();
        }
    }
    
    public class Detalle {
        public List<String> fields = new List<String> {'NumTarjetaAnterior','TarjetaAdicional','MotivoCancelacion','CodMotivoBloqueo','Bloqueo','MotivoBloqueo','Segmento','AutorizacionesPend','PagosTransitoUSD','PagosTransitoRDP','PagoMinimoUSD','PagoMinimoRDP','OficinaGestora','OficinaDestino','UltTransaccion','CicloFacturacion','BalanceCorteRDP','BalanceCorteUSD','BalanceDisponibleRDP','BalanceDisponibleUSD','BalanceFechaRDP','BalanceFechaUSD','BalanceVencidoRDP','BalanceVencidoUSD','MontoUltPagoRDP','MontoUltPagoUSD','UltimoPago','DiasAtraso','LimiteRDP','LimiteUSD','FechaCorte','NombrePlastico','NombreEmpresa','RNC','NombreCorporacion','SaldoTarjetaInd','SaldoCorporacion','PuntosVencidos','PuntosVencer','PuntosGenerados','PuntosCanjeados','PuntosAcumulados','FechaExpiracion','TasaInteres','Email','FechaActualDesde','FechaActuaHasta','FechaRenovacionDesde','FechaRenovacionHasta','FechaEmision'};
            @AuraEnabled public Map<String, String> values;
        
        public Detalle() {
            values = new Map<String, String>();
        }
    }
    
    @AuraEnabled public Result result;
    @AuraEnabled public Producto producto;
    @AuraEnabled public Detalle detalle;
    
    public INT013TCDTO() {
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