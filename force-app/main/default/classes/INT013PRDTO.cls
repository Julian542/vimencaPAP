public class INT013PRDTO {
    public class Result {
        @AuraEnabled public String ErrorCode;
        @AuraEnabled public String ErrorText;
        public Map<String, String> valuesXML = new Map<String, String>{
            'NumCuenta' => 'Name',
                'AliasCuenta' => 'ASE_Alias_de_la_cuenta__c',
                'Estado' => 'ASE_Estado__c',
                'TipoProducto' => 'ASE_Linea_de_producto__c',
              //  'Producto' => 'ASE_Codigo_de_producto__c',
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
                'FechaDesembolso' => 'ASE_Fecha_de_desembolso__c',
                'FechaUltimoPago' => 'ASE_Ultimo_pago__c',
                'FechaPago' => 'ASE_Fecha_de_pago__c',
                'MontoDesembolso' => 'ASE_Monto_de_desembolso__c',
                'CuotaFija' => 'ASE_Cuota_fija__c',
                'FacturaVencida' => 'ASE_Factura_vencida__c',
                'FacturaNoVencida' => 'ASE_Fectura_no_vencida__c',
                'MontoAdeudado' => 'ASE_Capital_adeudado__c',
                'MontoFecha' => 'ASE_Monto_a_la_fecha__c',
                'MontoAprobado' => 'ASE_Monto_aprobado__c',
                'CuotasVencidas' => 'ASE_N_Cuotas_vencidas__c',
                'Segmento' => 'ASE_Segmento__c',
                'Moneda' => 'ASE_Moneda__c',
                'FechaVencimiento' => 'ASE_Fecha_de_vencimiento__c',
                'FechaRevisionTasa' => 'ASE_Fecha_de_revision_tasa__c',
                'UltimaModificacionTasa' => 'ASE_Ultima_modificacion_tasa__c',
                'FormulaPago' => 'ASE_Formula_de_pago__c',
                'ClasificacionRiesgo' => 'ASE_Clasificacion_de_riesgo__c',
                'UltimaProrroga' => 'ASE_Ultima_prorroga__c',
                'TipoGarantia' => 'ASE_Tipo_de_garantia__c',
                'TasaMora' => 'ASE_Tasa_mora__c',
                'TasaInteresAnual' => 'ASE_Tasa_interes_anual__c',
                'TasaInteres' => 'ASE_Tasa_de_interes__c',
                'SectorPrestamo' => 'ASE_Sector_del_prestamo__c',
                'SaldoTeorico' => 'ASE_Saldo_teorico__c',
                'ProximoRecibo' => 'ASE_Proximo_recibo__c',
                'UltimaRenovacion' => 'ASE_Ultima_renovacion__c',
                'FrecuenciaPago' => 'ASE_Frecuencia_de_pago__c',
                'Garantia' => 'ASE_Garantia__c',
                'DiaPago' => 'ASE_Dia_de_pago__c',
                'CuentaCIIU' => 'ASE_Cuenta_CIIU__c',
                'CuentaCatalogo' => 'ASE_Cuenta_catalogo__c',
                'CuentaDestinoSIB' => 'ASE_Cuenta_destino_SIB__c',
                'CuentaRelacionada' => 'ASE_Cuenta_relacionada__c',
                'Cuotas' => 'ASE_N_Cuotas_pendientes__c',
                'ValorCuota' => 'ASE_Valor_de_cuota__c',
                'LineaCredito' => 'ASE_Linea_de_credito__c',
                'InteresAdeudado' => 'ASE_Interes_adeudado__c',
                'CapitalFactVencido' => 'ASE_Capital_Fac__c',
                'CapitalFactNoVencido' => 'ASE_Capital_Facnv__c',
                'CapitalDevenNoFact' => 'ASE_Capital_Dev__c',
                'CapitalTotal' => 'ASE_Capital_Tot__c',
                'InteresFactVencido' => 'ASE_Interes_Fac__c',
                'InteresFactNoVencido' => 'ASE_Interes_Facnv__c',
                'InteresDevenNoFact' => 'ASE_Interes_Dev__c',
                'InteresTotal' => 'ASE_Interes_Tot__c',
                'ComisionFactVencido' => 'ASE_Comision_Fac__c',
                'ComisionFactNoVencido' => 'ASE_Comision_Facnv__c',
                'ComisionDevenNoFact' => 'ASE_Comision_Dev__c',
                'ComisionTotal' => 'ASE_Comision_Tot__c',
                'GastosFactVencido' => 'ASE_Gastos_Fac__c',
                'GastosFactNoVencido' => 'ASE_Gastos_Facnv__c',
                'GastosDevenNoFact' => 'ASE_Gastos_Dev__c',
                'GastosTotal' => 'ASE_Gastos_Tot__c',
                'MoraFactVencido' => 'ASE_Mora_Fac__c',
                'MoraFactNoVencido' => 'ASE_Mora_Facnv__c',
                'MoraDevenNoFact' => 'ASE_Mora_Dev__c',
                'MoraTotal' => 'ASE_Mora_Tot__c',
                'TotalFactVencido' => 'ASE_Total_Fac__c',
                'TotalFactNoVencido' => 'ASE_Total_Facnv__c',
                'TotalDevenNoFact' => 'ASE_Total_Dev__c',
                'Total' => 'ASE_Total_Tot__c'               
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
        public List<String> fields = new List<String> {'FechaDesembolso','FechaUltimoPago','FechaPago','MontoDesembolso','CuotaFija','FacturaVencida','FacturaNoVencida','MontoAdeudado','MontoFecha','MontoAprobado','CuotasVencidas','Segmento','Moneda','FechaVencimiento','FechaRevisionTasa','UltimaModificacionTasa','FormulaPago','ClasificacionRiesgo','UltimaProrroga','TipoGarantia','TasaMora','TasaInteresAnual','TasaInteres','SectorPrestamo','SaldoTeorico','ProximoRecibo','UltimaRenovacion','FrecuenciaPago','Garantia','DiaPago','CuentaCIIU','CuentaCatalogo','CuentaDestinoSIB','CuentaRelacionada','Cuotas','ValorCuota','LineaCredito','InteresAdeudado','CapitalFactVencido','CapitalFactNoVencido','CapitalDevenNoFact','CapitalTotal','InteresFactVencido','InteresFactNoVencido','InteresDevenNoFact','InteresTotal','ComisionFactVencido','ComisionFactNoVencido','ComisionDevenNoFact','ComisionTotal','GastosFactVencido','GastosFactNoVencido','GastosDevenNoFact','GastosTotal','MoraFactVencido','MoraFactNoVencido','MoraDevenNoFact','MoraTotal','TotalFactVencido','TotalFactNoVencido','TotalDevenNoFact','Total'};
        @AuraEnabled public Map<String, String> values;
        
        public Detalle() {
            values = new Map<String, String>();
        }
    }
    
    @AuraEnabled public Result result;
    @AuraEnabled public Producto producto;
    @AuraEnabled public Detalle detalle;
    
    public INT013PRDTO() {
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
              /*  if(field=='EjecutivoNombre'){
                    System.debug('Ejecutivo: '+productoString.substringAfter('<'+field+'>').substringBefore('</'+field+'>')); 
                }
                if(field=='PuntoAtencion'){
                    System.debug('Numc: '+productoString.substringAfter('<'+field+'>').substringBefore('</'+field+'>')); 
                }*/
            }
            
            for(String field: this.detalle.fields) {
                this.detalle.values.put(field, detalleString.substringAfter('<'+field+'>').substringBefore('</'+field+'>'));
            }
        }
    }
}