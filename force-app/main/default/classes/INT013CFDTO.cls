public class INT013CFDTO {
    public class Result {
        @AuraEnabled public String ErrorCode;
        @AuraEnabled public String ErrorText;
        public Map<String, String> valuesXML = new Map<String, String>{
            'NumCuenta' => 'Name',
                'AliasCuenta' => 'ASE_Alias_de_la_cuenta__c',
                'Titulares' => 'ASE_Titular_de_la_cuenta__c',
                'Estado' => 'ASE_Estado__c',
                'TipoProducto' => 'ASE_Linea_de_producto__c',
                'Producto' => 'ASE_Codigo_de_producto__c',
                'FechaApertura' => 'ASE_Fecha_de_apertura__c',
                'FechaReapertura' => 'ASE_Fecha_de_reapertura__c',
                'FechaCierre' => 'ASE_Fecha_de_cierre_cancelacion__c',
                'TipoVinculacion' => 'ASE_Tipo_de_vinculacion__c',
                //'EjecutivoNombre' => 'ASE_Ejecutivo__c',// previus field 'EjecutivoNombre'
                'EjecutivoNombre' => 'ASE_Ejecutivo_int__c', // new field 'EjecutivoNombre'
                'Saldo' => 'ASE_Balance_disponible__c',
                //'PuntoAtencion' => 'ASE_Oficina_Ejecutivo__c',// previus field 'PuntoAtencion'
                'PuntoAtencion' => 'ASE_Oficina_Ejecutivo_int__c', // new field 'PuntoAtencion'
                'CuentaRegional' => 'ASE_Cuenta_regional__c',
                'FechaUltAct' => 'ASE_Fecha_de_la_ultima_actividad__c',
                'NumCuenta' => 'ASE_N_de_cuenta__c',
                'FormaPagoIntereses' => 'ASE_Forma_de_pago_intereses__c',
                'CuentaAcreditar' => 'ASE_Cuenta_a_acreditar__c',
                'FechaPignoracion' => 'ASE_Fecha_pignoracion__c',
                'FechaDespignoracion' => 'ASE_Fecha_despignoracion__c',
                'FechaPagoIntereses' => 'ASE_Fecha_de_pago_intereses__c',
                'MontoActual' => 'ASE_Monto_actual__c',
                'MontoRetenido' => 'ASE_Monto_Retenido__c',
                'MontoCancelacion' => 'ASE_Monto_cancelacion__c',
                'PenalidadCancelacion' => 'ASE_Penalidad_por_cancelacion_anticipada__c',
                'MontoApertura' => 'ASE_Monto_original_monto_de_apertura__c',
                'InteresesPagados' => 'ASE_Interes_total_pagado__c',
                'TasaInteres' => 'ASE_Tasa_de_interes__c',
                'Renovaciones' => 'ASE_N_Renovaciones__c',
                'FechaRenovacion' => 'ASE_Fecha_de_renovacion__c',
                'TasaCancelacion' => 'ASE_Tasa_de_cancelacion__c',
                'FechaRevisionTasa' => 'ASE_Fecha_de_revision_tasa__c',
                'UltModificacionTasa' => 'ASE_Ultima_modificacion_tasa__c',
                'PlazoCertificado' => 'ASE_Plazo_del_certificado__c',
                'InteresesGenerados' => 'ASE_Intereses_generados_del_periodo__c',
                'NumDocumento' => 'ASE_N_de_documento__c',
                'FechaVencimiento' => 'ASE_Fecha_de_vencimiento__c',
                'TieneBloqueos' => 'ASE_Tipo_bloqueos__c',
                'MontoFianzas' => 'ASE_Monto_fianzas__c',
                'MontoEmbargado' => 'ASE_Monto_embargado__c',
                'MontoTransito' => 'ASE_Monto_en_transito__c',
                'InteresesMes' => 'ASE_Del_mes__c',
                'InteresesMesAnt' => 'ASE_Mes_anterior__c',
                'InteresesAcumulados' => 'ASE_Acumulados__c',
                'InteresesPorPagar' => 'ASE_Por_pagar__c',
                'InteresesCapital' => 'ASE_Capitalizados__c',
                'InteresesNoCapital' => 'ASE_No_capitalizados__c',
                'InteresesPeriodo' => 'ASE_Del_periodo__c',
                'Moneda' => 'ASE_Moneda__c',
                'CuentaCatalogo' => 'ASE_Cuenta_catalogo__c',
                'TipoCuenta' => 'ASE_Tipo_de_Cuenta__c',
                'TieneRestriccion' => 'ASE_Tiene_restriccion__c'
                };
    }
    
    public class Producto {
        public List<String> fields = new List<String> {'NumCuenta','AliasCuenta','Titulares','Estado','TipoProducto','Producto','FechaApertura','FechaReapertura','FechaCierre','TipoVinculacion','EjecutivoNombre','Saldo','PuntoAtencion','CuentaRegional','FechaUltAct'};
        @AuraEnabled public Map<String, String> values;
        
        public Producto() {
            values = new Map<String, String>();
        }
    }
    
    public class Detalle {
        public List<String> fields = new List<String> {'NumCuenta','FormaPagoIntereses','CuentaAcreditar','FechaPignoracion','FechaDespignoracion','FechaPagoIntereses','MontoActual','MontoRetenido','MontoCancelacion','PenalidadCancelacion','MontoApertura','InteresesPagados','TasaInteres','Renovaciones','FechaRenovacion','TasaCancelacion','FechaRevisionTasa','UltModificacionTasa','PlazoCertificado','InteresesGenerados','NumDocumento','FechaVencimiento','TieneBloqueos','MontoFianzas','MontoEmbargado','MontoTransito','InteresesMes','InteresesMesAnt','InteresesAcumulados','InteresesPorPagar','InteresesCapital','InteresesNoCapital','InteresesPeriodo','Moneda','CuentaCatalogo','TipoCuenta','TieneRestriccion'};
        @AuraEnabled public Map<String, String> values;
        
        public Detalle() {
            values = new Map<String, String>();
        }
    }
    
    @AuraEnabled public Result result;
    @AuraEnabled public Producto producto;
    @AuraEnabled public Detalle detalle;
    
    public INT013CFDTO() {
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