public class INT055 {
    
    public class Response extends INTResponse {
        public final List<String> fieldList = new List<String> { 'NumeroCuenta', 'NombreProducto', 'Balance', 'TieneRestriccion' };
            public List<Map<String, String>> responseList = new List<Map<String, String>>();
        
        @InvocableVariable public Boolean ivSuccess;
        @InvocableVariable public String ivMessage;
        @InvocableVariable public String idAccount;
        @InvocableVariable public List<WS_Response> ivResponseList;
    }
    
    public class WS_Response {
        @InvocableVariable public String NumeroCuenta;
        @InvocableVariable public String NombreProducto;
        @InvocableVariable public Double Balance;
        @InvocableVariable public Boolean TieneRestriccion;
    }
    
    public static INT055.Response parse(String response) {
        INT055.Response r = new INT055.Response();
        Map<String, String> result;
        
        // Retrieve Result Status.
        r.errorCode = response.substringAfter('<ErrorCode>').substringBefore('</ErrorCode>');
        r.errorText = response.substringAfter('<ErrorText>').substringBefore('</ErrorText>');
        
        // If status is successful, retrieve fields.
        if(r.errorCode == '000') {
            while(response.contains('</Response>')) {
                result = new Map<String, String>();
                
                for(String field: r.fieldList) {
                    result.put(field, response.substringAfter('<'+field+'>').substringBefore('</'+field+'>'));
                }
                r.responseList.add(result);
                response = response.substringAfter('</Response>');
            }
        }
        return r;
    }
    
    private static String generateLinkedString(Asset asset, List<Vinculado__c> linkedList) {
        String linkedString = '';
        System.debug('Name Asset ::'+asset.account.RecordType.name);
        if(asset.account.RecordType.name =='Personas Jurídicas'){            
             linkedString += '<Vinculado>';
            linkedString += '<TipoIdentificacionVinculado>' +'RNC' + '</TipoIdentificacionVinculado>';
            linkedString += '<IdentificacionVinculado>' + asset.account.ACC_RNC__c + '</IdentificacionVinculado>';
            linkedString += '</Vinculado>';
        }else{
           linkedString += '<Vinculado>';
            linkedString += '<TipoIdentificacionVinculado>' + asset.account.ACC_TipoIdentificacion__c + '</TipoIdentificacionVinculado>';
            linkedString += '<IdentificacionVinculado>' + asset.account.ACC_NumIdentificacion__c + '</IdentificacionVinculado>';
            linkedString += '</Vinculado>'; 
        }
        for(Vinculado__c v: linkedList) {
            linkedString += '<Vinculado>';
            linkedString += '<TipoIdentificacionVinculado>' + v.VIN_Tipo_identificacion_vinculado__c + '</TipoIdentificacionVinculado>';
            linkedString += '<IdentificacionVinculado>' + v.VIN_N_identificacion_vinculado__c + '</IdentificacionVinculado>';
            linkedString += '</Vinculado>'; 
        }
        
        return linkedString;
    }
    
    private static INT055.Response createInvocableVariableResponseList(INT055.Response res) {
        res.ivResponseList = new List<WS_Response>();
        
        System.debug('create temp data');
        for(Map<String, String> r: res.responseList){
            WS_Response wsr = new WS_Response();
            wsr.NumeroCuenta = r.get('NumeroCuenta');
            wsr.NombreProducto = r.get('NombreProducto');
            wsr.Balance = Double.valueOf(r.get('Balance'));
            wsr.TieneRestriccion = Boolean.valueOf(r.get('TieneRestriccion'));
            res.ivResponseList.add(wsr);
        }
        List<Datos_Temporales__c> temp_Data =new List<Datos_Temporales__c>();
        
        
        for(Map<String, String> r: res.responseList){
            Datos_Temporales__c dato = new Datos_Temporales__c();
            dato.DAT_Numero_Cuenta__c = r.get('NumeroCuenta');
            dato.DAT_Producto__c = r.get('NombreProducto');
            dato.DAT_Balance__c = Double.valueOf(r.get('Balance'));
            dato.DAT_Tipo_Restriccion__c = Boolean.valueOf(r.get('TieneRestriccion'));
            dato.DAT_Cliente__c = res.idAccount;
            dato.name = r.get('NumeroCuenta')+' - '+r.get('NombreProducto');
            temp_Data.add(dato); 
            //insert temp_Data;           
        }
        insert temp_Data;
        return res;
    }
    
    public static INT055.Response checkCommonLinkedAccounts(Asset asset, List<Vinculado__c> linkedList) {
        List<StaticResource> srList = [SELECT id, name, body FROM StaticResource WHERE name = 'INT055_request_frame'];
        List<AuthSession> authList = [Select id, SourceIP, Users.Name, LoginType, NumSecondsValid, CreatedDate From AuthSession WHERE UsersId =: UserInfo.getUserId() Order By CreatedDate DESC LIMIT 1];
        HttpRequest request = new HttpRequest();
        HttpResponse res;
        Http http = new Http();
        INT055.Response r = new INT055.Response();
        String frame;
        
        // If parameters are not specified, throw exception.
        if(String.isEmpty(asset.ASE_Moneda__c)) throw new IllegalArgumentException('asset.ASE_Moneda__c argument cannot be blank or null.');
        if(String.isEmpty(asset.ASE_Tipo_de_vinculacion__c)) throw new IllegalArgumentException('asset.ASE_Tipo_de_vinculacion__c argument cannot be blank or null.');
       // System.debug('sdsad ::'+asset.account.RecordType.name);
        if(asset.account.RecordType.name =='Candidato Persona Física'){//Verificar nombre del tipo de cliente en el entorno al que se vaya a pasar.
            if(String.isEmpty(asset.account.ACC_TipoIdentificacion__c)) throw new IllegalArgumentException('Account.ACC_TipoIdentificacion__c argument cannot be blank or null.');
            if(String.isEmpty(asset.account.ACC_NumIdentificacion__c)) throw new IllegalArgumentException('Account.ACC_NumIdentificacion__c argument cannot be blank or null.');
        }else if (asset.account.RecordType.name =='Candidato Persona Jurídica'){
            if(String.isEmpty(asset.account.ACC_RNC__c)) throw new IllegalArgumentException('Account.ACC_RNC__c argument cannot be blank or null.');
        }
        // If static resource with the frame to be sent exists, replaces fields and sends it.
        if(!srList.isEmpty()) {
            // Setup request
            request.setEndpoint(Label.EndpointWs);
            request.setMethod('POST');
            request.setTimeout(120000);
            request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
            request.setHeader('SoapAction','http://crmintegration.local/CtaComunVinc');
            frame = srList[0].body.toString();
            
            // Set WebService credentials.
            frame = frame.replace('[ws_user]', Label.Int_Username);
            frame = frame.replace('[ws_password]', Label.Int_Password);
            
            // Set Callout parameters.
            frame = frame.replace('[function_username]', UserInfo.getUserName());
            frame = frame.replace('[function_requestdate]', System.now().format('dd/MM/yyyy'));
            frame = frame.replace('[function_requesttime]', System.now().format('hh:mm:ss'));
            frame = frame.replace('[function_terminal]', authList[0].SourceIp);
            
            frame = frame.replace('[function_vinculationtype]', asset.ASE_Tipo_de_vinculacion__c);
            frame = frame.replace('[function_currency]', asset.ASE_Moneda__c);
            
            // Generar lista de vinculados en XML
            
            frame = frame.replace('[function_linkedlist]', generateLinkedString(asset, linkedList));
            
            
            request.setBody(frame);
            
            res = http.send(request);
            
            //Record result and request
            INTLogger.INTLoggerResult result = INTLogger.logCallout('055', 'CtaComunVinc', request, res);
            switch on (res.getStatusCode()) {
                when 200 {
                    r = parse(res.getBody());
                }
                when else {
                    // On Error
                }
            } 
            r.requestStatusCode = res.getStatusCode();
            r.requestStatus = res.getStatus();
            
        } else {
            throw new XmlException('Static resource with the request template named "INT055_request_frame" could not be found.');
        }
        
        return r;
    }
    
    @InvocableMethod
    public static List<INT055.Response> checkCommonLinkedAccounts(List<Id> assetId) {
        INT055.Response res = new INT055.Response();
        List<Asset> assetList = [SELECT id, ASE_Moneda__c, ASE_Tipo_de_vinculacion__c, account.ACC_TipoIdentificacion__c, account.ACC_NumIdentificacion__c,account.RecordType.name, account.ACC_RNC__c FROM asset WHERE id =: assetId[0] ];
        
        List<Vinculado__c> linkedList = [SELECT id, VIN_Tipo_identificacion_vinculado__c, VIN_N_identificacion_vinculado__c FROM Vinculado__c WHERE VIN_Cuenta_financiera__c =: assetId[0] AND VIN_Tipo_identificacion_vinculado__c <> NULL AND VIN_N_identificacion_vinculado__c <> NULL];
        
        if(!assetList.isEmpty()) {
            try {
                System.debug(assetList[0].AccountId);
                res.idAccount = assetList[0].AccountId;
                res = checkCommonLinkedAccounts(assetList[0] , linkedList);
                res = createInvocableVariableResponseList(res);
                
                res.ivSuccess = true;
                
            } catch(Exception e) {
                res.ivSuccess = false;
                res.ivMessage = e.getMessage();
                //System.debug('ERROR NO CONTROLADO :: '+e.getMessage());
            }
        } else {
            res.ivSuccess = false;
            res.ivMessage = '[INT055-IM] There is no record with specified accountId in Account object table.';
        }
        return new List<INT055.Response> {res};
            }
}