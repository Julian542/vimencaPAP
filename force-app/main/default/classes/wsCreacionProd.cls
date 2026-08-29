public class wsCreacionProd {
    public static HttpRequest requestLoguer; 
 	/* Funcion que realiza el envío de las nuevas cuentas financieras al CORE por POST */
     public static HttpResponse creacionProdCA_CC_CF_Post(String body, String Action) {
         
        /* Clase encargada del envio y recepcion*/ 
        Http http = new Http();
         
        /* Nueva petición HTTP -> Se rellenan las cabezeras necesárias y el cuerpo pasado por parametro */ 
        HttpRequest request = new HttpRequest();
        request.setEndpoint(Label.EndpointWs);
        request.setMethod('POST');
        request.setHeader('SoapAction','http://crmintegration.local/' + Action);
        request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
        request.setBody(body);
        requestLoguer = request;
        /* Se envía y recoje la petición */
        HttpResponse response = http.send(request);

        /* Se devuelve la respuesta cual sea */
        return response;
    }
    
    /* Funcion que genera el XML de envio */
	public static DOM.Document parserToWsXML(Asset cf, List <String> Parameters){

        /* Fecha cuando se realiza la integración */
        Datetime actualTime = Datetime.now();
        
        /* Datos del usuario que lanza la integración */
        User user = [Select Id, Username, USE_Codigo__c, USE_Oficina__c from User where ID =:UserInfo.getUserId()];
        
        /* Se obtienen los vinculados de la cuenta */
        List<Vinculado__c> vinculados = [Select Id, VIN_N_identificacion_vinculado__c, VIN_Tipo_de_vinculo__c, VIN_Tipo_identificacion_vinculado__c, VIN_CIF_Vinculado__c from Vinculado__c where VIN_Cuenta_financiera__c = :cf.Id];
        
        /* Se el objeto DOM del XML a enviar */
		DOM.Document doc = new DOM.Document();
        
        /* Se crea la estructura inicial 
           <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
               <SOAP-ENV:Header>
                  <wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
                     <wsse:UsernameToken wsu:Id="UsernameToken-XXDARIO">
                        <wsse:Username>[USUARIO]</wsse:Username>
                        <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">[PASSWORD]</wsse:Password>
                     </wsse:UsernameToken>
                  </wsse:Security>
               </SOAP-ENV:Header>
               <SOAP-ENV:Body>
                  <HTTPSleepTime xmlns="http://crmintegration.local/">30000</HTTPSleepTime>
                  <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20Crear%20Cta%20Ahorro%20XML%20IO">
                     <Function>
                        <FunctionName>CrearCtaAhorro</FunctionName>
                        <UserName>DESA01</UserName>
                        <RequestDate>22/02/2018</RequestDate>
                        <RequestTime>11:25:36</RequestTime>
                        <Terminal>0.0.0.0</Terminal>
                        <Channel>SIEBEL</Channel>
                        <Version>1</Version>
                        <NumeroCuenta/>
                        <NombreTitular>ILIANA</NombreTitular>
                        <ApellidosTitular>PADILLA DE LUNA</ApellidosTitular>
                        <TipoIdentificacion>Cedula</TipoIdentificacion>
                        <Identificacion>40223588902</Identificacion>
                        <Subtitulo>Cuenta Ahorro Prueba trama</Subtitulo>
                        <IdDireccion>1-2PKU-1637</IdDireccion>
                        <IdViaContacto1>1-2PGZ-1684</IdViaContacto1>
                        <IdViaContacto2/>
                        <IdViaContacto3/>
                        <TipoCuenta>PERSONAL</TipoCuenta>
                        <CodigoProducto>256</CodigoProducto>
                        <CodPeriodicidadEstado>3</CodPeriodicidadEstado>
                        <CodigoEjecutivo/>
                        <CodigoCreador/>
                        <CentroAtencionCreador>2</CentroAtencionCreador>
                        <CodigoCuentaCatalogo/>
                        <SenalLibreta>N</SenalLibreta>
                        <NumeroLibreta/>
                        <Mancomunada>N</Mancomunada>
                        <CentroAtencion>2</CentroAtencion>
                        <CodigoEmpleado/>
                        <CIF>6789001</CIF>
                        <Producto>C/AHORRO AGENTES DE CAMBIO Y REMESAS</Producto>
                        <Vinculados>
                           <TipoIdentificacionVinculado>Cédula menor</TipoIdentificacionVinculado>
                           <IdentificacionVinculado>11111111111</IdentificacionVinculado>
                           <Vinculo>Menor</Vinculo>
                           <CIF>291837</CIF>
                        </Vinculados>
                        <Direcciones>
                           <Principal>Y</Principal>
                           <TipoDir>RESIDENCIA</TipoDir>
                           <Calle>MANZANA BAJA</Calle>
                           <Numero>22</Numero>
                           <Apartamento>VILLA</Apartamento>
                           <Edificio>1</Edificio>
                           <Pais>REPUBLICA DOMINICANA</Pais>
                           <Provincia>SANTIAGO</Provincia>
                           <Municipio>SANTIAGO</Municipio>
                           <DM>SANTIAGO</DM>
                           <Sector>SECTOR_10010101101010</Sector>
                           <CP/>
                        </Direcciones>
                        <Vias>
                           <AsociadoEDC>Y</AsociadoEDC>
                           <ViaContacto>TELÉFONO FIJO</ViaContacto>
                           <Telefonica>Viva</Telefonica>
                           <NumeroCorreo>8498540359</NumeroCorreo>
                        </Vias>
                     </Function>
                  </ListOfBREAIFuncionGeneral>
               </SOAP-ENV:Body>
            </SOAP-ENV:Envelope>
		*/
        
        /* BASE */
        dom.XmlNode Envelope = doc.createRootElement('SOAP-ENV:Envelope', null, null);
        Envelope.setNamespace('SOAP-ENV', 'http://schemas.xmlsoap.org/soap/envelope/');
        Envelope.setNamespace('xsi', 'http://www.w3.org/2001/XMLSchema-instance');
        Envelope.setNamespace('xsd', 'http://www.w3.org/2001/XMLSchema');
        
        /* HEADER */
        dom.XmlNode Header = Envelope.addChildElement('SOAP-ENV:Header', null, null);
        	dom.XmlNode Security = Header.addChildElement('wsse:Security', null, null);
        	Security.setNamespace('wsse','http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd');
        	Security.setNamespace('wsu','http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd');	
        		dom.XmlNode UsernameToken = Security.addChildElement('wsse:UsernameToken', null, null);
        		UsernameToken.setAttribute('wsu:Id','UsernameToken-XXDARIO');
        			dom.XmlNode Username = UsernameToken.addChildElement('wsse:Username', null, null).addTextNode(Label.Int_Username);
        			dom.XmlNode Password = UsernameToken.addChildElement('wsse:Password', null, null);
        			Password.setAttribute('Type','http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText');
        			Password.addTextNode(Label.Int_Password);
       
        /* BODY */
        dom.XmlNode Body = Envelope.addChildElement('SOAP-ENV:Body', null, null);
        	dom.XmlNode HTTPSleepTime = Body.addChildElement('HTTPSleepTime', null, null);
        	HTTPSleepTime.setNamespace('', 'http://crmintegration.local/');
        	dom.XmlNode ListOfBREAIFuncionGeneral = Body.addChildElement('ListOfBREAIFuncionGeneral', null, null);
        
                /* Cuenta de ahorro */
                if (cf.RecordTypeId == Parameters[0]) ListOfBREAIFuncionGeneral.setNamespace('', 'http://www.siebel.com/xml/BR%20Crear%20Cta%20Ahorro%20XML%20IO');
                /* Cuenta corriente */
                else if(cf.RecordTypeId == Parameters[1]) ListOfBREAIFuncionGeneral.setNamespace('', 'http://www.siebel.com/xml/BR%20Crear%20Cta%20Corriente%20XML%20IO');
                /* Certificado financiero */
                else if(cf.RecordTypeId == Parameters[2]) ListOfBREAIFuncionGeneral.setNamespace('', 'http://www.siebel.com/xml/BR%20Crear%20Cert%20Financiero%20XML%20IO');
        
        		dom.XmlNode Function = ListOfBREAIFuncionGeneral.addChildElement('Function', null, null);
                    /* Se rellena el nodo con los datos de la cuenta */
                    Function.addChildElement('FunctionName', null, null).addTextNode(Parameters[5]);
                    Function.addChildElement('UserName', null, null).addTextNode(user.Username);
                    Function.addChildElement('RequestDate', null, null).addTextNode(((actualTime.day() < 10)? '0' : '') + actualTime.day() + '/' + ((actualTime.month() < 10)? '0' : '') + actualTime.month() + '/' + actualTime.year());
                    Function.addChildElement('RequestTime', null, null).addTextNode(((actualTime.hour() < 10)? '0' : '') + actualTime.hour() + ':' + ((actualTime.minute() < 10)? '0' : '') + actualTime.minute() + ':' + ((actualTime.second() < 10)? '0' : '') + actualTime.second());
                    Function.addChildElement('Terminal', null, null).addTextNode('0.0.0.0'/*(Parameters[4] == NULL ? '' : Parameters[4]) REVISAR*/);
                    Function.addChildElement('Channel', null, null).addTextNode('SALESFORCE');
                    Function.addChildElement('Version', null, null).addTextNode('1');
        
        			/* Si es un certificado financiero, va con número de certificado */
        			if(cf.RecordTypeId != Parameters[2])
                        Function.addChildElement('NumeroCuenta', null, null).addTextNode(cf.ASE_N_de_cuenta__c == NULL ? '' : cf.ASE_N_de_cuenta__c);
        			else
                        Function.addChildElement('NumeroCertificado', null, null).addTextNode(cf.ASE_N_de_cuenta__c == NULL ? '' : cf.ASE_N_de_cuenta__c);
        
                    /* ApellidosTitular, NombreTitular, TipoIdentificacion, Identificacion  solo si es PF */
        			/* PJ */
        			if(cf.Account.RecordTypeId == Parameters[3]){
                        Function.addChildElement('ApellidosTitular', null, null).addTextNode('');
                        Function.addChildElement('NombreTitular', null, null).addTextNode(cf.Account.Name == NULL ? '' : cf.Account.Name);
                        Function.addChildElement('TipoIdentificacion', null, null).addTextNode('RNC');
                        Function.addChildElement('Identificacion', null, null).addTextNode(cf.Account.ACC_RNC__c == NULL ? '' : cf.Account.ACC_RNC__c);
                    }
                    /* PF */
        			else if (cf.Account.RecordTypeId == Parameters[4]){
                        /* Apellidos solo en PF */
                        Function.addChildElement('ApellidosTitular', null, null).addTextNode(cf.Account.LastName == NULL ? (cf.Account.Suffix == NULL ? '' : cf.Account.Suffix) : (cf.Account.Suffix == NULL ? cf.Account.LastName : cf.Account.LastName + ' ' + cf.Account.Suffix)); 
                        Function.addChildElement('NombreTitular', null, null).addTextNode(cf.Account.FirstName == NULL ? (cf.Account.MiddleName == NULL ? '' : cf.Account.MiddleName) : (cf.Account.MiddleName == NULL ? cf.Account.FirstName : cf.Account.FirstName + ' ' + cf.Account.MiddleName));
        				Function.addChildElement('TipoIdentificacion', null, null).addTextNode(cf.Account.ACC_TipoIdentificacion__c == NULL ? '' : cf.Account.ACC_TipoIdentificacion__c.Equals('Cédula')? 'Cedula' : cf.Account.ACC_TipoIdentificacion__c);
                    	Function.addChildElement('Identificacion', null, null).addTextNode(cf.Account.ACC_NumIdentificacion__c == NULL ? '' : cf.Account.ACC_NumIdentificacion__c);
                    }
        
        			Function.addChildElement('Subtitulo', null, null).addTextNode(cf.ASE_Alias_de_la_cuenta__c == NULL ? '' : cf.ASE_Alias_de_la_cuenta__c);
                    Function.addChildElement('IdDireccion', null, null).addTextNode(cf.ASE_Direccion__r.DIR_Identificador__c == NULL ? '' : cf.ASE_Direccion__r.DIR_Identificador__c);
                    Function.addChildElement('IdViaContacto1', null, null).addTextNode(cf.ASE_Via_de_Contacto__r.VIA_Identificador__c == NULL ? '' : cf.ASE_Via_de_Contacto__r.VIA_Identificador__c);
                    Function.addChildElement('IdViaContacto2', null, null).addTextNode(''); /* NO SE ENVIAN */
                    Function.addChildElement('IdViaContacto3', null, null).addTextNode(''); /* NO SE ENVIAN */
                    Function.addChildElement('TipoCuenta', null, null).addTextNode(cf.ASE_Tipo_de_Cuenta__c == NULL ? '' : cf.ASE_Tipo_de_Cuenta__c);
                    Function.addChildElement('CodigoProducto', null, null).addTextNode(cf.ASE_Producto__r.PRO_Codigo_de_producto__c == NULL ? '' :  cf.ASE_Producto__r.PRO_Codigo_de_producto__c);
        			
        			/* Si es cuenta de ahorro siempre va el valor 3 - (TRIMESTRAL) */
                    if(cf.RecordTypeId == Parameters[0])
        				Function.addChildElement('CodPeriodicidadEstado', null, null).addTextNode('3');
        			/* Si es cuenta corriente, puede ir 'Día 15' (Per Física) o  'Día 30' (Per Juridica) */
                    /* REVISAR */ else if (cf.RecordTypeId == Parameters[1]){
                        /* PJ */
                        if(cf.Account.RecordTypeId == Parameters[3])
                            Function.addChildElement('CodPeriodicidadEstado', null, null).addTextNode('2'/*'Día 30'*/);
                        /* PF */
                        else if (cf.Account.RecordTypeId == Parameters[4])
                            Function.addChildElement('CodPeriodicidadEstado', null, null).addTextNode('1'/*'Día 15'*/);
                    }
        	System.debug('Alias :: '+ cf.ASE_Ejecutivo__r.alias);
        System.debug('Owner :: '+ cf.Owner.alias);
        			//Function.addChildElement('CodigoEjecutivo', null, null).addTextNode(cf.ASE_Ejecutivo__r.USE_Codigo__c == NULL ? '' : cf.ASE_Ejecutivo__r.USE_Codigo__c);
                    //Function.addChildElement('CodigoCreador', null, null).addTextNode(cf.Owner.USE_Codigo__c == NULL ? '' : cf.Owner.USE_Codigo__c);
        			Function.addChildElement('CodigoEjecutivo', null, null).addTextNode(cf.ASE_Ejecutivo__r.alias == NULL ? '' : cf.ASE_Ejecutivo__r.alias);
                    Function.addChildElement('CodigoCreador', null, null).addTextNode(cf.Owner.alias == NULL ? '' : cf.Owner.alias);
                    Function.addChildElement('CentroAtencionCreador', null, null).addTextNode(cf.Owner.USE_Oficina__c == NULL? '' : cf.Owner.USE_Oficina__c);
        
        			/* Los certificados utilizan otra etiqueta (Código del produto) */
        			if(cf.RecordTypeId == Parameters[2])
                    	Function.addChildElement('CuentaCatalogo', null, null).addTextNode(cf.ASE_Producto__r.PRO_Codigo_de_producto__c == NULL ? '' :  cf.ASE_Producto__r.PRO_Codigo_de_producto__c); /* br cUENTA CATALOGO */
        			else 
                        Function.addChildElement('CodigoCuentaCatalogo', null, null).addTextNode(cf.ASE_Producto__r.PRO_Codigo_de_producto__c == NULL ? '' :  cf.ASE_Producto__r.PRO_Codigo_de_producto__c);
        
                    Function.addChildElement('Mancomunada', null, null).addTextNode(vinculados.size() > 0 ? 'Y':'N');
                    Function.addChildElement('CentroAtencion', null, null).addTextNode(user.USE_Oficina__c == NULL ? '' : user.USE_Oficina__c);
                    Function.addChildElement('CodigoEmpleado', null, null).addTextNode(user.USE_Codigo__c == NULL ? '' : user.USE_Codigo__c);
                    Function.addChildElement('CIF', null, null).addTextNode(cf.Account.ACC_CIF__c == NULL ? '' : cf.Account.ACC_CIF__c);
        			
        			/* Campos especificos de la cuenta de ahorro */
        			if(cf.RecordTypeId == Parameters[0]){
                        Function.addChildElement('SenalLibreta', null, null).addTextNode(cf.ASE_Producto__r.PRO_Requiere_libreta_PF_PJ__c ? 'Y' : 'N');
                        Function.addChildElement('NumeroLibreta', null, null).addTextNode(cf.ASE_N_de_libreta__c == NULL ? '' : cf.ASE_N_de_libreta__c);
                        Function.addChildElement('Producto', null, null).addTextNode(cf.ASE_Producto__r.Name == NULL ? '' : cf.ASE_Producto__r.Name);
    				}
        			/* Campos especificos de la cuenta corriente */
                    else if(cf.RecordTypeId == Parameters[1]){
                        Function.addChildElement('AgenciaApertura', null, null).addTextNode(user.USE_Oficina__c == NULL ? '' : user.USE_Oficina__c);
                        Function.addChildElement('TipoDeposito', null, null).addTextNode(cf.ASE_Tipo_de_deposito__c == NULL ? '' : cf.ASE_Tipo_de_deposito__c);
                        Function.addChildElement('OficinaRetencionEstado', null, null).addTextNode(cf.ASE_Oficina_retencion_de_estado__c == NULL ? '' : cf.ASE_Oficina_retencion_de_estado__c);
                        Function.addChildElement('MetodoEntregaEstado', null, null).addTextNode(cf.ASE_Metodo_de_entrega_de_estado__c == NULL ? '' : cf.ASE_Metodo_de_entrega_de_estado__c);
                    	/* REVISAR */ Function.addChildElement('ClaseCuenta', null, null).addTextNode(''); 
                    }
        			/* Campos especificos del certificado financiero */
        			else if (cf.RecordTypeId == Parameters[2]){
            			Function.addChildElement('Accion', null, null).addTextNode('SQL');
                        Function.addChildElement('MontoDeposito', null, null).addTextNode(cf.ASE_Monto_del_deposito__c == NULL ? '0' : string.valueOf(cf.ASE_Monto_del_deposito__c));
                        Function.addChildElement('PlazoDias', null, null).addTextNode(cf.ASE_Plazo_meses__c == NULL ? '' : cf.ASE_Plazo_meses__c);
                        Function.addChildElement('FechaVencimiento', null, null).addTextNode(cf.ASE_Fecha_de_vencimiento__c == NULL ? '' : (cf.ASE_Fecha_de_vencimiento__c.month() < 10? '0' :  '') + cf.ASE_Fecha_de_vencimiento__c.month() + '/' + (cf.ASE_Fecha_de_vencimiento__c.day() < 10? '0' :  '') + cf.ASE_Fecha_de_vencimiento__c.day() + '/' + cf.ASE_Fecha_de_vencimiento__c.year());
                        //Function.addChildElement('Tasa', null, null).addTextNode(cf.ASE_Tasa_de_interes__c == NULL ? '0' : string.valueOf(cf.ASE_Tasa_de_interes__c));
                        Function.addChildElement('Tasa', null, null).addTextNode(cf.ASE_Tasa__c == NULL ? '0' : string.valueOf(cf.ASE_Tasa__c));
                        Function.addChildElement('Documento', null, null).addTextNode(cf.ASE_Documento__c ==  NULL ? '' : cf.ASE_Documento__c);
                        Function.addChildElement('FormaPago', null, null).addTextNode(cf.ASE_Forma_de_pago__c == NULL ? '' : cf.ASE_Forma_de_pago__c);
                        Function.addChildElement('CuentaAcreditar', null, null).addTextNode(cf.ASE_Cuenta_a_acreditar__c == NULL ? '' : cf.ASE_Cuenta_a_acreditar__c);
                        Function.addChildElement('NumeroCuentaAcreditar', null, null).addTextNode(cf.ASE_Numero_de_cuenta_a_acreditar__c == NULL ? '' : cf.ASE_Numero_de_cuenta_a_acreditar__c);
                        Function.addChildElement('OficinaDestino', null, null).addTextNode(cf.ASE_Oficina_destino__c == NULL ? '' : cf.ASE_Oficina_destino__c);
                        Function.addChildElement('FormaPagoApertura', null, null).addTextNode(cf.ASE_Forma_de_pago_de_apertura__c == NULL ? '' : cf.ASE_Forma_de_pago_de_apertura__c);
                        Function.addChildElement('TipoCuentaDebitar', null, null).addTextNode(cf.ASE_Cuenta_a_debitar__c == NULL ? '' : cf.ASE_Cuenta_a_debitar__c);
                        Function.addChildElement('NumeroCuentaDebitar', null, null).addTextNode(cf.ASE_Numero_de_cuenta_a_debitar__c == NULL ? '' : cf.ASE_Numero_de_cuenta_a_debitar__c);
                        Function.addChildElement('Moneda', null, null).addTextNode(cf.ASE_Moneda__c == NULL ? '' : cf.ASE_Moneda__c);
        			}
        
        			/* Se rellenan los vinculados */
                    for(vinculado__c auxVin : vinculados){
                        dom.XmlNode Vinculado =  Function.addChildElement('Vinculados', null, null);
                        Vinculado.addChildElement('TipoIdentificacionVinculado', null, null).addTextNode(auxVin.VIN_Tipo_identificacion_vinculado__c == NULL ? '' : auxVin.VIN_Tipo_identificacion_vinculado__c.Equals('Cédula')? 'Cedula' : auxVin.VIN_Tipo_identificacion_vinculado__c);
                        Vinculado.addChildElement('IdentificacionVinculado', null, null).addTextNode(auxVin.VIN_N_identificacion_vinculado__c == NULL ? '' : auxVin.VIN_N_identificacion_vinculado__c);
                        /* REVISAR */ Vinculado.addChildElement('Vinculo', null, null).addTextNode(auxVin.VIN_Tipo_de_vinculo__c == NULL ? '' : auxVin.VIN_Tipo_de_vinculo__c);
                        Vinculado.addChildElement('CIF', null, null).addTextNode(auxVin.VIN_CIF_Vinculado__c == NULL ? '' : auxVin.VIN_CIF_Vinculado__c);
                    }
        
        			/* Se añaden las direcciones de la cuenta */
        			dom.XmlNode Direcciones = Function.addChildElement('Direcciones', null, null);
        			Direcciones.addChildElement('Principal', null, null).addTextNode('Y');
        			Direcciones.addChildElement('TipoDir', null, null).addTextNode(cf.ASE_Direccion__r.DIR_Tipo_Direccion__c == NULL ? '' : cf.ASE_Direccion__r.DIR_Tipo_Direccion__c);
        			Direcciones.addChildElement('Calle', null, null).addTextNode(cf.ASE_Direccion__r.DIR_Calle__c == NULL ? '' : cf.ASE_Direccion__r.DIR_Calle__c);
        			Direcciones.addChildElement('Numero', null, null).addTextNode(cf.ASE_Direccion__r.DIR_Numero__c == NULL ? '' : cf.ASE_Direccion__r.DIR_Numero__c);
        			Direcciones.addChildElement('Apartamento', null, null).addTextNode(cf.ASE_Direccion__r.DIR_N_Apartamento__c == NULL ? '' : cf.ASE_Direccion__r.DIR_N_Apartamento__c);
        			Direcciones.addChildElement('Edificio', null, null).addTextNode(cf.ASE_Direccion__r.DIR_Edificio__c == NULL ? '' : cf.ASE_Direccion__r.DIR_Edificio__c);
        			Direcciones.addChildElement('Pais', null, null).addTextNode(cf.ASE_Direccion__r.DIR_Pais__c == NULL ? '' : generalUtils.pickListGetLabel(Direccion__c.DIR_Pais__c.getDescribe(),cf.ASE_Direccion__r.DIR_Pais__c));
        			Direcciones.addChildElement('Provincia', null, null).addTextNode(cf.ASE_Direccion__r.DIR_Provincia__c == NULL ? '' : generalUtils.pickListGetLabel(Direccion__c.DIR_Provincia__c.getDescribe(),cf.ASE_Direccion__r.DIR_Provincia__c));
        			Direcciones.addChildElement('Municipio', null, null).addTextNode(cf.ASE_Direccion__r.DIR_Municipio__c == NULL ? '' : generalUtils.pickListGetLabel(Direccion__c.DIR_Municipio__c.getDescribe(),cf.ASE_Direccion__r.DIR_Municipio__c));
        			//Direcciones.addChildElement('DM', null, null).addTextNode(cf.ASE_Direccion__r.DIR_Distrito__c == NULL ? '' : generalUtils.pickListGetLabel(Direccion__c.DIR_Distrito__c.getDescribe(),cf.ASE_Direccion__r.DIR_Distrito__c));
        			Direcciones.addChildElement('Sector', null, null).addTextNode(cf.ASE_Direccion__r.DIR_Sector__r.DM_Direccion__c == NULL ? '' : cf.ASE_Direccion__r.DIR_Sector__r.DM_Direccion__c);
        			Direcciones.addChildElement('CP', null, null).addTextNode(cf.ASE_Direccion__r.DIR_Apartado_postal__c == NULL ? '' : cf.ASE_Direccion__r.DIR_Apartado_postal__c);
        
        			/* Se añaden las vias de la cuenta */
					dom.XmlNode Vias = Function.addChildElement('Vias', null, null);
        			Vias.addChildElement('AsociadoEDC', null, null).addTextNode('Y');
        			Vias.addChildElement('ViaContacto', null, null).addTextNode(cf.ASE_Via_de_Contacto__r.VIA_de_Contacto__c == NULL ? '' : cf.ASE_Via_de_Contacto__r.VIA_de_Contacto__c);
        			Vias.addChildElement('Telefonica', null, null).addTextNode(cf.ASE_Via_de_Contacto__r.VIA_Telefonica__c == NULL ? '' : cf.ASE_Via_de_Contacto__r.VIA_Telefonica__c);
        			Vias.addChildElement('NumeroCorreo', null, null).addTextNode(cf.ASE_Via_de_Contacto__r.VIA_Numero_Correo__c == NULL ? '' : cf.ASE_Via_de_Contacto__r.VIA_Numero_Correo__c);
        
        /* Debug log esta limitado, se divide en porciones de 300 caracteres */
      	String ALL_XML= doc.toXmlString().remove('<?xml version="1.0" encoding="UTF-8"?>');
        for (Integer i = 0; i < ALL_XML.length(); i=i+300) {
            Integer iEffectiveEnd = (i+300 > (ALL_XML.length()) ? ALL_XML.length() : i+300);
            System.debug(ALL_XML.substring(i,iEffectiveEnd));
    	}
        
		/* Se devuelve la variable DOM con los datos a enviar */
        return doc;
    }

	/* Metodo encargado de hacer el Callout y recoger la información necesaria*/ 
    public static String creacionProdCA_CC_CF(Id id_cf){  
     	/* Cuenta Personal o juridica, de la que se van a enviar los datos */
        Asset cf;
        /* Se almacena en un String la integración que se va a lanzar, para los mensajes de error */
        String integracion;
        
        /* Se consulta que exista una cuenta con el Id recibido */
        try{
            cf = [Select 
                          
                  Id, ASE_N_de_cuenta__c, ASE_Tipo_de_Cuenta__c, ASE_Alias_de_la_cuenta__c, RecordTypeId, ASE_Res_Creacion__c,
                  ASE_Ejecutivo_int__c,ASE_Codigo_creador__c,
                  /* Cuenta de ahorro */
                  ASE_N_de_libreta__c, 
                  
                  /* Cuenta corriente */
                  ASE_Tipo_de_deposito__c, ASE_Oficina_retencion_de_estado__c, ASE_Metodo_de_entrega_de_estado__c, /*BR Clase Cuenta */
                  
                  /* Certificado financiero */
                  ASE_Monto_del_deposito__c, ASE_Plazo_meses__c, ASE_Fecha_de_vencimiento__c, ASE_Tasa_de_interes__c, ASE_Tasa__c, ASE_Documento__c,
                  ASE_Forma_de_pago__c, ASE_Cuenta_a_acreditar__c, ASE_Oficina_destino__c, ASE_Forma_de_pago_de_apertura__c, ASE_Numero_de_cuenta_a_acreditar__c, ASE_Cuenta_a_debitar__c, ASE_Numero_de_cuenta_a_debitar__c, ASE_Moneda__c,
                  
                  Account.Name, Account.FirstName, Account.LastName, Account.MiddleName, Account.Suffix, Account.ACC_TipoIdentificacion__c, Account.ACC_NumIdentificacion__c, Account.ACC_RNC__c, Account.ACC_CIF__c, Account.RecordTypeId,
                  
                  ASE_Direccion__r.Id, ASE_Direccion__r.DIR_Tipo_Direccion__c, ASE_Direccion__r.DIR_Calle__c, ASE_Direccion__r.DIR_Numero__c, ASE_Direccion__r.DIR_N_Apartamento__c,
                  //ASE_Direccion__r.DIR_Edificio__c, ASE_Direccion__r.DIR_Pais__c, ASE_Direccion__r.DIR_Provincia__c, ASE_Direccion__r.DIR_Municipio__c, ASE_Direccion__r.DIR_Distrito__c,
                  //ASE_Direccion__r.DIR_Sector__c,ASE_Direccion__r.DIR_Sector__r.DM_Direccion__c, ASE_Direccion__r.DIR_Apartado_postal__c,ASE_Direccion__r.DIR_Identificador__c,
                  
                  ASE_Via_de_Contacto__r.Id, ASE_Via_de_Contacto__r.VIA_Numero_Correo__c, ASE_Via_de_Contacto__r.VIA_Identificador__c, ASE_Via_de_Contacto__r.VIA_de_Contacto__c, ASE_Via_de_Contacto__r.VIA_Telefonica__c,
                  
                  ASE_Producto__r.PRO_Codigo_de_producto__c, ASE_Producto__r.Name, ASE_Producto__r.PRO_Requiere_libreta_PF_PJ__c,
                  
                  ASE_Ejecutivo__r.USE_Codigo__c, ASE_Ejecutivo__r.USE_Oficina__c, ASE_Ejecutivo__r.alias, Owner.USE_Codigo__c , Owner.alias, Owner.USE_Oficina__c from Asset where Id =:id_cf
                 ];
        }
        catch (exception e){
            System.debug('La persona cuenta financiera no existe en la aplicación: \n' + e.getMessage()); 
            return 'La persona cuenta financiera no existe en la aplicación: \n'+ e.getMessage();
        }
        
        /* Lista de parametros del XML */
        List <String> Parameters = new List<String>();
        
        /* Variable que almacena la peticion en un XML */
        string requestXML;
        
        /* Se obtienen los IDs de los recordTypes de 'Cuentas de Ahorro', 'Cuentas corrientes' y 'Certificados financieros' */
        Parameters.add(Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Cuentas_de_ahorro').getRecordTypeId());
        Parameters.add(Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Cuentas_corrientes').getRecordTypeId());
      	Parameters.add(Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Certificados_financieros').getRecordTypeId());
        Parameters.add(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Personas_Juridicas').getRecordTypeId());
        Parameters.add(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId());
        
        /* Variables para almacenar la respuesta recibida por el WS */
        HttpResponse respuesta;
        DOM.Document respuestaXML;
        Dom.XMLNode return_value;

        /* Si es una cuenta de ahorro */
        if(cf.RecordTypeId == Parameters[0]){
           Parameters.add('CrearCtaAhorro'); 
           integracion = 'Cuentas de Ahorro';
        } 
        
        /* Si es una cuenta corriente */
        else if(cf.RecordTypeId == Parameters[1]){
            Parameters.add('CrearCtaCorriente');
            integracion = 'Cuentas corrientes';
        } 
        
        /* Si es una certificado financiero */
        else if(cf.RecordTypeId == Parameters[2]){
           Parameters.add('CrearCertFin');
           integracion = 'Certificados financieros';
        } 

        /* Se obtiene el XML de envío */
        requestXML = parserToWsXML(cf, Parameters).toXmlString().remove('<?xml version="1.0" encoding="UTF-8"?>');
        
        /* Se realiza el envío de la petición */
        try{
            
            /* Se realiza la llamada al WS de consulta de productos*/
			respuesta = creacionProdCA_CC_CF_Post(requestXML, Parameters[5]);
            
            String ALL_XML= respuesta.getBodyDocument().toXmlString();
            for (Integer i = 0; i < ALL_XML.length(); i=i+300) {
                Integer iEffectiveEnd = (i+300 > (ALL_XML.length()) ? ALL_XML.length() : i+300);
                System.debug(ALL_XML.substring(i,iEffectiveEnd));
            }
			   
            
            /*	<soap:Envelope
                    xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                    xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                    xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing"
                    xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
                    xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
                    <soap:Header>
                        <wsa:Action>http://crmintegration.local/ConsultaBloqueosResponse</wsa:Action>
                        <wsa:MessageID>urn:uuid:d5b0a21a-99c4-4ab7-a1fb-e5a9dd3950d4</wsa:MessageID>
                        <wsa:RelatesTo>urn:uuid:2be7cdcf-26b9-45b9-87ff-98b946126430</wsa:RelatesTo>
                        <wsa:To>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:To>
                        <wsse:Security>
                            <wsu:Timestampwsu:Id="Timestamp-793a80d5-9786-4ac8-b2a3-a0897133d18e">
                                <wsu:Created>2018-02-23T10:49:00Z</wsu:Created>
                                <wsu:Expires>2018-02-23T10:54:00Z</wsu:Expires>
                            </wsu:Timestamp>
                        </wsse:Security>
                    </soap:Header>
                    <soap:Body>
                        <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Crear%20Cuenta%20Response%20IO">
                            <Result>
                                <ErrorCode>000</ErrorCode>
                                <ErrorText>TRANSACCION PORCESADA</ErrorText>
                                <Producto>
                                    <NumCuenta>1100433455</NumCuenta>
                                </Producto>
                            </Result>
                        </ListOfBREAIFuncionGeneral>
                    </soap:Body>
                </soap:Envelope>
            */
            /* Si el 'Status' es 200, no ha sucedido ningún error*/
            if(respuesta.getStatusCode() == 200){
                //Namespace comun que se utiliza en todo el xml de respuesta*/
                String namespace = 'http://www.siebel.com/xml/BR%20EAI%20Crear%20Cuenta%20Response%20IO';
                
                /* Solo se procesa el cuerpo de la petición, la cabezera se ignora */
                respuestaXML = respuesta.getBodyDocument();
                return_value = respuestaXML.getRootElement();
                return_value = return_value.getChildElement('Body','http://schemas.xmlsoap.org/soap/envelope/');
                return_value = return_value.getChildElement('ListOfBREAIFuncionGeneral',namespace);
                
                /* Se accede hasta el apartado de result */
                return_value = return_value.getChildElement('Result', namespace);
                
                /* Se almacena el ErroCorde, ErrorText y los datos de los Assets a crear */
               	String ErrorCode = return_value.getChildElement('ErrorCode', namespace).getText();
                String ErrorText = return_value.getChildElement('ErrorText', namespace).getText();
                
                /* Si se ha devuelto un código de error o mensaje no controlado, no se continua procesando */
                if(!ErrorCode.Equals('000') || !ErrorText.Equals('TRANSACCION PROCESADA')){
                	System.debug('Ha sucedido un error en la integración de creación de ' + integracion + ' : ' + 'Code: ' + ErrorCode + ' | Text: ' + ErrorText);
                    cf.ASE_Res_Creacion__c = 'Ha sucedido un error en lla integración de creación de ' + integracion + ' : ' + '\nCode: ' + ErrorCode + '\nText: ' + ErrorText;
                    upsert cf;
                    INTLogger.INTLoggerResult result = INTLogger.logCallout('052',Parameters[5], requestLoguer, respuesta);            
                    return 'Ha sucedido un error en lla integración de creación de ' + integracion + ' : ' + '\nCode: ' + ErrorCode + '\nText: ' + ErrorText;
                }
                /* Si no hay error, se procesa la respuesta del producto */
                else{
                	return_value = return_value.getChildElement('Producto', namespace);
                    cf.ASE_N_de_cuenta__c = return_value.getChildElement('NumCuenta', namespace).getText();
                    /* Se comprueba que el numero de cuenta no esta vacio */
                	if(cf.ASE_N_de_cuenta__c == NULL){
                        System.debug('La integración de creación de ' + integracion + ' : No se ha devuelto un número de cuenta válido');
                        cf.ASE_Res_Creacion__c = 'La integración de creación de ' + integracion + ' : No se ha devuelto un número de cuenta válido';
                        upsert cf;
                        return 'La integración de creación de ' + integracion + ' : No se ha devuelto un número de cuenta válido';
                    }
                    /* Si no esta vacio, se actualiza la cuenta con el numero de cuenta devuelto en la integracion */
                    else{
                        cf.Name = cf.ASE_N_de_cuenta__c;
                        cf.ASE_Res_Creacion__c = 'Cuenta de tipo \'' + integracion + '\' creada de forma correcta';
                        upsert cf;
                        system.debug('Cuenta de tipo \'' + integracion + '\' creada de forma correcta');
                    	return 'Cuenta de tipo \'' + integracion + '\' creada de forma correcta' ;   
                    }   
                }
            }
            /* Si ha sucedido algún error */
            else{
                System.debug('Ha sucedido un error durante la integración de creación de ' + integracion + ' : ' + 'Code: ' + respuesta.getStatusCode() + ' |Mensagge: ' + respuesta.getBody());
                cf.ASE_Res_Creacion__c = 'Ha sucedido un error durante la integración de creación de ' + integracion + ' : ' + '\nCode: ' + respuesta.getStatusCode() +  '\nMensagge: ' + respuesta.getBody();
                upsert cf;
                return 'Ha sucedido un error durante la integración de creación de ' + integracion + ' : ' + '\nCode: ' + respuesta.getStatusCode() +  '\nMensagge: ' + respuesta.getBody();
            }
           
            
        }
        catch(exception e){
            System.debug('Ha sucedido un error no controlado durante la integración de creación de ' + integracion + ' : ' + e.getMessage() + ' ' + e.getStackTraceString());
            cf.ASE_Res_Creacion__c = 'Ha sucedido un error no controlado durante la integración de creación de ' + integracion + ' : ' + e.getMessage();
            upsert cf;
            return 'Ha sucedido un error no controlado durante la integración de creación de ' + integracion + ' : ' + e.getMessage();
        }finally{
            INTLogger.INTLoggerResult result = INTLogger.logCallout('052',Parameters[5], requestLoguer, respuesta);            
        }
        
    }
    
    /* Metodos para llamar a la integración de creación de: 'Cuentas de Ahorro', 'Cuentas Corrientes' y 'Cuentas Financieras' de forma ASINCRONA */
    @future(callout=true)
    public static void Future_creacionProdCA_CC_CF(Id id_cf){
        creacionProdCA_CC_CF(id_cf);
    }
    
    @InvocableMethod
    public static void Invocable_creacionProdCA_CC_CF(List<Id> id_cf){
        if(id_cf.size() > 0)
        	Future_creacionProdCA_CC_CF(id_cf[0]);
    }
    
}