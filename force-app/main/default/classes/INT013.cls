public class INT013 {
    public class Response {
        @AuraEnabled public INT013CADTO caResponse;
        @AuraEnabled public INT013CCDTO ccResponse;
        @AuraEnabled public INT013CFDTO cfResponse;
        @AuraEnabled public INT013LCDTO lcResponse;
        @AuraEnabled public INT013PRDTO prResponse;
        @AuraEnabled public INT013TCDTO tcResponse;
        @AuraEnabled public INT013TPDTO tpResponse;
        @AuraEnabled public id idFinanAccount;
        @AuraEnabled public String ErrorCode = '';
        @AuraEnabled public String ErrorText = '';
        public Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        public Schema.SObjectType leadSchema = schemaMap.get('Asset');
        public Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
        public Map<String, String> fuctionsXML = new Map<String, String>{
            'cuentas de ahorro' => 'ConsultaCAhorro',
                'cuentas corrientes' => 'ConsultaCCorriente',
                'certificados financieros' => 'ConsultaCertFin',
                'líneas de crédito' => 'ConsultaLineaCred',
                'préstamos' => 'ConsultaPrestamo',
                'tarjetas de crédito' => 'ConsultaTC',
                'tarjetas prepago' => 'ConsultaPrepago'
                };        
                    public Response() {            
                        
                    }
        
        public void parse(String functionName, String response) {
            System.debug(functionName.toLowerCase());
            switch on(functionName.toLowerCase()) {
                when ('cuentas de ahorro') {
                    caResponse = new INT013CADTO();
                    caResponse.parse(response);
                    updateFinanAccount(caResponse.Result.valuesXML, caResponse.Producto.values,caResponse.Detalle.values,caResponse.result.ErrorCode,caResponse.result.ErrorText);                	
                }
                
                when ('cuentas corrientes') {
                    ccResponse = new INT013CCDTO();
                    ccResponse.parse(response);
                    updateFinanAccount(ccResponse.Result.valuesXML, ccResponse.Producto.values,ccResponse.Detalle.values,ccResponse.result.ErrorCode,ccResponse.result.ErrorText);
                }                
                when ('certificados financieros') {
                    cfResponse = new INT013CFDTO();
                    cfResponse.parse(response);
                    updateFinanAccount(cfResponse.Result.valuesXML, cfResponse.Producto.values, cfResponse.Detalle.values,cfResponse.result.ErrorCode,cfResponse.result.ErrorText);
                }                
                when ('líneas de crédito') {
                    lcResponse = new INT013LCDTO();
                    lcResponse.parse(response);                    
                    updateFinanAccount(lcResponse.Result.valuesXML, lcResponse.Producto.values, lcResponse.Detalle.values,lcResponse.result.ErrorCode,lcResponse.result.ErrorText);
                }                
                when ('préstamos') {
                    prResponse = new INT013PRDTO();
                    prResponse.parse(response);
                    updateFinanAccount(prResponse.Result.valuesXML, prResponse.Producto.values, prResponse.Detalle.values,prResponse.result.ErrorCode,prResponse.result.ErrorText);                  
                }                
                when ('tarjetas de crédito') {
                    tcResponse = new INT013TCDTO();
                    tcResponse.parse(response);
                    updateFinanAccount(tcResponse.Result.valuesXML, tcResponse.Producto.values, tcResponse.Detalle.values,tcResponse.result.ErrorCode,tcResponse.result.ErrorText);
                }    
                when ('tarjetas prepago') {
                    tpResponse = new INT013TPDTO();
                    tpResponse.parse(response);
                    updateFinanAccount(tpResponse.Result.valuesXML, tpResponse.Producto.values, tpResponse.Detalle.values,tpResponse.result.ErrorCode,tpResponse.result.ErrorText);
                }
            }
        }
        
        public void updateFinanAccount(Map<String,String> valuesXML,Map<String,String> parceProduct,Map<String,String> parceDetail, String ErrorCode,String ErrorText){     
            List<String> fields = new List<String>(Asset.SObjectType.getDescribe().fields.getMap().keySet());
            String soql = ''
                + ' SELECT ' + String.join(fields, ',')
                + ' FROM Asset'
                + ' WHERE id=\''+String.escapeSingleQuotes(idFinanAccount)+'\'';
            Asset updateFinan = Database.query(soql);
            for(String key:parceProduct.keySet()){
                if(valuesXML.get(key)!=null && parceProduct.get(key)!='' && parceProduct.get(key)!=null){                    
                    updateFinan = checkField(updateFinan,valuesXML.get(key),parceProduct.get(key));
                    System.debug('Field: '+key +' FieldQuery: '+valuesXML.get(key) +' Content: ' +parceProduct.get(key));
                }                              
            }
            
            for(String key:parceDetail.keySet()){
                if(valuesXML.get(key)!=null && parceDetail.get(key)!='' && parceDetail.get(key)!=null){
                    updateFinan = checkField(updateFinan,valuesXML.get(key),parceDetail.get(key));
                    System.debug('Field: '+key +' FieldQuery: '+valuesXML.get(key) +' Content: ' +parceDetail.get(key));
                }                
            }
            this.ErrorCode = ErrorCode;
            this.ErrorText = ErrorText;
            update updateFinan; 
        }
        
        public Asset checkField(Asset checkRecord,String field,String value){            
            try{
                Schema.DisplayType fielddataType = fieldMap.get(field).getDescribe().getType();                
                if(fielddataType == Schema.DisplayType.DATE){
                    String[] dateSpl = value.split('/');
                    Date dateField = Date.newInstance(integer.valueof(dateSpl[2]),integer.valueof(dateSpl[0]),integer.valueof(dateSpl[1]));
                    checkRecord.put(field,dateField);
                    system.debug('Field: '+field+' Data: '+value );
                    system.debug('Data: '+dateField );
                }else if(fielddataType == Schema.DisplayType.DATETIME){
                    Datetime dateField = datetime.parse(value);
                    checkRecord.put(field,dateField);
                    system.debug('Field: '+field+' Data: '+value );
                }else if(fielddataType == Schema.DisplayType.INTEGER || fielddataType == Schema.DisplayType.DOUBLE || fielddataType == Schema.DisplayType.PERCENT || fielddataType == Schema.DisplayType.CURRENCY){
                    Decimal datavalue= decimal.valueOf(value);
                    checkRecord.put(field,datavalue);
                    system.debug('Field: '+field+' Data: '+value);
                }else if(fielddataType == Schema.DisplayType.STRING || fielddataType == Schema.DisplayType.ID ||  fielddataType == Schema.DisplayType.EMAIL || fielddataType == Schema.DisplayType.TEXTAREA || fielddataType == Schema.DisplayType.PICKLIST){
                    value=(field=='ASE_Linea_de_producto__c' && value=='Lineas de credito') ? 'Líneas de crédito' : value;
                    checkRecord.put(field,value);
                    system.debug('Field: '+field+' Data: '+value);
                    
                }else if(fielddataType == Schema.DisplayType.BOOLEAN){
                    if(value.toLowerCase()=='s' || value.toLowerCase()=='y'){
                        checkRecord.put(field,true);
                    }else{
                        checkRecord.put(field,false);
                    }
                    system.debug('Field: '+field+' Data: '+value);
                }else if(field=='ASE_Ejecutivo__c'){
                    User user=[SELECT id FROM user WHERE Name=:value];
                    checkRecord.put(field,user.id);
                    system.debug('Field: '+field+' Data: '+value);
                }
            }catch(Exception e){
                System.debug('Error Type :: '+ e+' Field: '+field+' Data: '+value );
            }
            system.debug(value);
            return checkRecord;            
        }
        
    }
    
    public static INT013.Response checkFinancialProductDetailputInfo(id idFinanAccount){
        Asset finanAccount=[SELECT id,name, ASE_N_de_cuenta__c, ASE_Moneda__c, ASE_Linea_de_producto__c FROM Asset WHERE id =:idFinanAccount];             
        return checkFinancialProductDetail(finanAccount.name, finanAccount.ASE_Linea_de_producto__c,finanAccount.ASE_Moneda__c,idFinanAccount);
    }
    
    public static INT013.Response checkFinancialProductDetail(String accountNumber, String productLine, String requestedCurrency,id idFinanAccount) {
        List<StaticResource> srList = [SELECT id, name, body FROM StaticResource WHERE name = 'INT013_request_frame'];
        List<AuthSession> authList = [Select id, SourceIP, Users.Name, LoginType, NumSecondsValid, CreatedDate From AuthSession WHERE UsersId =: UserInfo.getUserId() Order By CreatedDate DESC LIMIT 1];
        HttpRequest request = new HttpRequest();
        HttpResponse res;
        Http http = new Http();
        INT013.Response r = new INT013.Response();
        String frame;
        
        // If parameters are not specified, throw exception.
        if(String.isEmpty(accountNumber)) throw new IllegalArgumentException('accountNumber argument cannot be blank or null.');
        if(String.isEmpty(productLine)) throw new IllegalArgumentException('productLine argument cannot be blank or null.');
        if(String.isEmpty(requestedCurrency)) throw new IllegalArgumentException('requestedCurrency argument cannot be blank or null.');
        
        System.debug(r.fuctionsXML.get(productLine.toLowerCase()));
        
        // If static resource with the frame to be sent exists, replaces fields and sends it.
        if(!srList.isEmpty()) {
            // Setup request
            request.setEndpoint(Label.EndpointWs);
            request.setMethod('POST');
            request.setTimeout(120000);
            request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
            SYstem.debug('Soap :' + r.fuctionsXML.get(productLine.toLowerCase()));
            request.setHeader('SoapAction','http://crmintegration.local/'+r.fuctionsXML.get(productLine.toLowerCase()));
            //request.setHeader('SoapAction','http://crmintegration.local/ConsultaLineaCred');
            frame = srList[0].body.toString();
            // Set WebService credentials.
            frame = frame.replace('[ws_user]', Label.Int_Username);
            frame = frame.replace('[ws_password]', Label.Int_Password);
            // Set Callout parameters.
            frame = frame.replace('[function_processIntegration]',r.fuctionsXML.get(productLine.toLowerCase()));
            //frame = frame.replace('[function_processIntegration]','ConsultaLineaCred');
            frame = frame.replace('[function_username]', UserInfo.getUserName());
            frame = frame.replace('[function_requestdate]', System.now().format('dd/MM/yyyy'));
            frame = frame.replace('[function_requesttime]', System.now().format('hh:mm:ss'));
            frame = frame.replace('[function_terminal]', authList[0].SourceIp);
            
            frame = frame.replace('[function_accountnumber]', accountNumber);
            frame = frame.replace('[function_productline]', productLine);
            frame = frame.replace('[function_currency]', requestedCurrency);
            
            request.setBody(frame);
            res = http.send(request);            
            try {
                switch on (res.getStatusCode()) {
                    when 200 {
                        r.idFinanAccount=idFinanAccount;
                        r.parse(productLine, res.getBody());
                        System.debug('response body: '+res.getBody());
                    }
                    when else {
                        // On Error
                    }
                }
            }catch(Exception e){
                System.debug('Error Type :: '+ e );
            }finally{
                INTLogger.INTLoggerResult result = INTLogger.logCallout('013', productLine, request, res);            
            }
        } else {
            throw new XmlException('Static resource with the request template named "INT013_request_frame" could not be found.');
        }        
        return r;
    }
}