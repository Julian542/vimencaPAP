public class INT008 {
public class Response extends INTResponse {
        public final List<String> fieldList = new List<String>{'CIF'};   
        public Map<String, String> valuesClient = new Map<String, String>{
            '[function_razonSocial]' => 'Name',
                '[function_nombreComercial]' => 'ACC_Nombre_Corto_Comercial__c',
                '[function_RNC]' => 'ACC_RNC__c',
                '[function_tipoOrganizacion]' => 'ACC_Tipo_Organizacion__c',
                '[function_fechaFundacion]' => 'ACC_Fecha_Fundacion__c',
                '[function_fechaCierreFiscal]' => 'ACC_Fecha_Cierre_Fiscal__c',
                '[function_Nacionalidad]' => 'ACC_Nacionalidad__c',
                '[function_GrupoGestion]' => '',                                               
                '[function_BICSWIFT]' => '',                                                           
                '[function_Industria]' => 'Industry',
                '[function_ActividadEconomica]' => 'ACC_Actividad_Economica__c',
                '[function_CodigoCIIU]' => '',                                                     
                '[function_TipoActividad]' => 'ACC_Tipo_Actividad__c',
                '[function_TipoSector]' => 'ACC_Tipo_Sector__c',
                '[function_TipoPersona]' => 'ACC_Codigo_Persona_PJ__c',
               	//'[function_TipoCliente]' => 'ACC_Codigo_Persona_PJ__c',//OBLIGATORIO
               	'[function_TipoCliente]' => 'ACC_Tipo_Cliente_PJ__c',
                '[function_FuenteInfo]' => 'ACC_Fuente_Informacion__c',
                '[function_FechaInfo]' => 'ACC_Fecha_Informacion__c',
                '[function_RelacionExt]' => 'ACC_Relacion_Exterior__c',
                '[function_TipoDepositante]' => 'ACC_Tipo_Depositante__c',
                '[function_TipoVinculacion]' => 'ACC_Tipo_Vinculacion__c',
                '[function_Condicion]' => 'ACC_Condicion__c',
                '[function_Estado]' => 'ACC_Estado__c',
                '[function_Subestado]' => 'ACC_SubEstado__c',
                '[function_Segmento]' => 'ACC_Segmento__c',
                '[function_UltimaSegmentacion]' => 'ACC_Ultima_Segmentacion__c',
                '[function_PuntoAtencion]' => 'ACC_NumOficina__c',                                            
                '[function_Ejecutivo]' => 'ACC_Nombre_Ejecutivo__c',
                '[function_Zona]' => 'ACC_Zona__c',                                                                       
                '[function_PuestoTrabajo]' => 'ACC_Nombre_Puesto__c',
                '[function_CategoriaRiesgo]' => 'ACC_Categoria_Riesgo_Cliente__c',
                '[function_TotalActivos]' => 'ACC_Total_Activos__c',
                '[function_MonedaActivos]' => 'ACC_Moneda__c',                                            
                '[function_VolumenVentasAnual]' => 'ACC_Volumen_Ventas_Anual__c',
                '[function_Moneda]' => 'ACC_Moneda__c',
                '[function_NumEmpleados]' => 'ACC_NumEmpleados__c',
                '[function_anualExpenses]' => 'Gastos_anuales__c',
                '[function_heritage]' => 'ACC_Patrimonio_Num__c',
                '[function_heritageDesc]' => 'ACC_Patrimonio_Desc__c',
                '[function_InternetBanking]' => 'ACC_Internet_Banking__c',
                '[function_CuentaNomina]' => 'ACC_Cuenta_Nomina__c',
                '[function_ObjetoNegocio]' => 'ACC_Objeto_Negocio__c',
                '[function_CiudadFATCA]' => 'ACC_Ciudad_FATCA__c',
                '[function_CPFATCA]' => 'ACC_Codigo_Postal_FATCA__c',                                                              
                '[function_DireccionFATCA]' => 'ACC_Direccion_FATCA__c',
                '[function_EstadoFATCA]' => 'ACC_Estado_FATCA__c',
                '[function_TelefonoFATCA]' => 'ACC_Telefono_FATCA__c',
                '[function_InstitucionFinancieraFATCA]' => 'ACC_Es_Institucion_Financiera__c',     
                '[function_TipoAcuerdoFATCA]' => 'ACC_Tipo_Acuerdo__c',                                   
                '[function_NumAcuerdoFATCA]' => 'ACC_Num_Acuerdo__c',                                      
                '[function_AcuerdoIRSFATCA]' => 'ACC_Posee_Acuerdo_IRS__c',                                      
                '[function_SegmentoFATCA]' => 'ACC_Segmento_FATCA__c',
                '[function_TipoIngresoFATCA]' => 'ACC_Tipo_Ingreso__c',                                   
                '[function_GIINFATCA]' => 'ACC_GIIN__c',                                                        
                '[function_TipoEmpresaFATCA]' => 'ACC_Tipo_Empresa__c',                                   
                '[function_CodEmpleado]' => '',  //Revisar por alicia                                                
                '[function_CodOficina]' => '',                                                     
                '[function_CIF]' => 'ACC_CIF__c',
                '[function_ClienteConocido]' => 'ACC_Cliente_Conocido__c'
                };
        public Map<String, String> valuesAdresses = new Map<String, String>{
            '[function_addressId]' => 'DIR_Id_Externo_Direccion__c',
                '[function_addressExternalIdBk]' => 'DIR_Id_Externo_Direccion_bk__c', //Este fue el nuevo campo agregado
                '[function_addressIdentifier]' => 'DIR_Identificador__c',
                '[function_addressPrimary]' => 'DIR_Principal__c',
                '[function_addressType]' => 'DIR_Tipo_Direccion__c',
                '[function_addressStreet]' => 'DIR_Calle__c',
                //'[function_addressNum]' => 'DIR_Numero__c',
                '[function_addressNum]' => '',
                '[function_addressBuilding]' => 'DIR_Edificio__c',
                '[function_addressNumFloor]' => 'DIR_N_Apartamento__c',
                '[function_addressCountry]' => 'DIR_Pais_Texto__c',
                '[function_addressProvince]' => 'DIR_Provincia__c',
                '[function_addressMunicipality]' => 'DIR_Municipio__c',
                '[function_addressMunicipalDistrict]' => 'DIR_Distrito__c',
                '[function_addressSector]' => 'DIR_Sector__c',
                '[function_addressPostalCode]' => 'DIR_Apartado_postal__c',
                '[function_addressCityStatePC]' => 'DIR_Estado_Ciudad__c',
                '[function_addressPhone]' => 'DIR_N_Telefono__c',
                '[function_addressPhoneEx]' => 'DIR_Extension__c',
                '[function_addressExtraPhone1]' => 'DIR_Telefono_adicional__c',
                '[function_addressExtraPhone2]' => 'DIR_Telef_Adicional__c'
                                };
        public Map<String, String> valuesContactInfo = new Map<String, String>{
            '[function_contactInfoId]' => 'VIA_Id_Externo_Via__c',
                '[function_ViaIdExternoVia]' => 'VIA_Id_Externo_Via_bk__c', //Este fue el nuevo campo agregado
                '[function_contactInfoIdentifier]' => 'VIA_Identificador__c',
                '[function_contactPrincipal]' => 'VIA_Principal__c',
                '[function_contactWayType]' => 'VIA_de_Contacto__c',
                '[function_contactWayCant]' => 'VIA_Numero_Correo__c',
                '[function_contactCompany]' => 'VIA_Telefonica__c',
                '[function_contactExRef]' => 'VIA_Id_Externo_Via__c'
                                            };
        public Map<String, String> valuesReferences = new Map<String, String>{
            '[function_referenceType]' => 'REF_Tipo__c',
                '[function_referenceName]' => 'REF_Nombre__c',
                '[function_referencePhone]' => 'REF_Telefono__c',
                '[function_referenceAddress]' => 'REF_Direccion__c',
                '[function_referenceCountry]' => 'Pais__c',
                '[function_referenceBank]' => 'Banco__c',
                '[function_referenceAccountType]' => 'Tipo_de_cuenta__c',
                '[function_referenceCurrency]' => 'Moneda__c',
                '[function_referenceAccountNum]' => 'N_de_cuenta__c'
                                            };
                                    
    	public Map<String, String> valuesProducts = new Map<String, String>{
            '[function_prodServName]' => 'Name'
                                            };
       
        public Map<String, String> valuesLargestCust = new Map<String, String>{
            '[function_largestCustName]' => 'Name',
                '[function_largestCustDocumentType]' => 'Tipo_de_identificacion__c',
                '[function_largestCustDocument]' => 'N_de_Identificacion__c'
                                            };  
		public Map<String, String> valuesSupplier = new Map<String, String>{
            '[function_supplierName]' => 'Name',
                '[function_supplierDocumentType]' => 'Tipo_de_identificaci_n__c',
                '[function_supplierDocument]' => 'N_de_Identificacion__c'
                                            };  
		public Map<String, String> valuesaffiliate = new Map<String, String>{
            '[function_affiliateName]' => 'Name',
                '[function_affiliateDocument]' => 'RNC__c',
                '[function_affiliateCountry]' => 'Pais_donde_opera__c',
                '[function_affiliateEcoGroup]' => 'Grupo_economico__c',
                '[function_affiliateFinGroup]' => 'Grupo_financiero__c'
                                            };  
		public Map<String, String> valuesParticipant = new Map<String, String>{
            '[function_participantType]' => 'PAR_Tipo__c',
                '[function_participantRole]' => 'PAR_Cargo__c',
                '[function_participantDocumentType]' => 'PAR_Tipo_Identificacion__c',
                '[function_participantDocument]' => 'PAR_Numero_Identificacion__c',
                '[function_participantName]' => 'PAR_Nombres__c',
                '[function_participantLastName]' => 'PAR_PrimerApellido__c',
                '[function_participantSecondLastName]' => 'PAR_SegundoApellido__c',
                '[function_participantFatca]' => 'Aplica_FATCA__c',
                '[function_participantPosition]' => 'Cargo__c',
                '[function_participantPorcentage]' => 'PAR_Porcentaje__c',
                '[function_participantValidation]' => 'PAR_Resultado_Validacion__c'
                                            };
                                                
		public Map<String, String> valuesAuthorized = new Map<String, String>{
            '[function_authorizedDocumentType]' => 'AUT_Tipoidentificacion__c',
                '[function_authorizedDocument]' => 'AUT_NumIdentificacion__c',
                '[function_authorizedName]' => 'AUT_Nombres__c',
                '[function_authorizedLastName]' => 'AUT_PrimerApellido__c',
                '[function_authorizedSecondLastName]' => 'AUT_SegundoApellido__c',
                '[function_authorizedPosition]' => 'ACC_CON_Puesto_Posicion__c',
                '[function_authorizedPhone]' => 'ACC_CON_Telefono__c'
                                            };
    }
    
    public static INT008.Response parse(String response) {
        INT008.Response r = new INT008.Response();
        
        // Retrieve Result Status.
        r.errorCode = response.substringAfter('<ErrorCode>').substringBefore('</ErrorCode>');
        r.errorText = response.substringAfter('<ErrorText>').substringBefore('</ErrorText>');
        // If status is successful, retrieve fields.
        if(r.errorCode == '000') {            
            //   System.debug( response.substringAfter('<Result>').substringBefore('</Result>'));
            for(String field: r.fieldList) {
                String textValue=  response.substringAfter('<'+field+'>').substringBefore('</'+field+'>');
                textValue = textValue.replace('Yamp;', '&');
                r.values.put(field, textValue);
                // System.debug(response.substringAfter('<'+field+'>').substringBefore('</'+field+'>'));
            }
            System.debug(r);
        }
        return r;
    }
    
    public static void updateClientCIF(INT008.Response responseServer, id idClient,String action, Boolean state) {
        Account accountUpdate =[SELECT id, ACC_CIF__c From Account WHERE id=:idClient ];
        if(state){            
            accountUpdate.ACC_CIF__c = responseServer.values.get('CIF').toString();
            accountUpdate.Resultado_de_la_Integracion__c = 'Registro creado correctamente en el core.';
        }else{
            accountUpdate.Resultado_de_la_Integracion__c = 'Integracion fallida Error code: ' + responseServer.errorCode + ' Texo de error : '+ responseServer.errorText;
            if(action=='C'){ 
                accountUpdate.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId();
                accountUpdate.ACC_Condicion__c ='PROSPECTO';
                accountUpdate.ACC_Estado__c ='APROBADO';  
            }
        } 
        
        try {
            update accountUpdate;
        } catch (DmlException e) {
            System.debug('Exception :: ' + e); 
        }
        //  Insert newListElements;
    }
    public static String fillXML(INT008.Response responseServer, Account client, String frame){
        String detailClient =  frame.substringBetween('<Function>', '</Function>');
        String addressesClient ='<Direcciones>'+frame.substringBetween('<Direcciones>', '</Direcciones>')+'</Direcciones>';
        String contactInfo ='<ViasContacto>'+frame.substringBetween('<ViasContacto>', '</ViasContacto>')+'</ViasContacto>';
        String references ='<Referencias>'+frame.substringBetween('<Referencias>', '</Referencias>')+'</Referencias>';
        String products ='<ProductosServicios>'+frame.substringBetween('<ProductosServicios>', '</ProductosServicios>')+'</ProductosServicios>';
        String customer ='<ClientesPrincipales>'+frame.substringBetween('<ClientesPrincipales>', '</ClientesPrincipales>')+'</ClientesPrincipales>';
        String supplier ='<Proveedores>'+frame.substringBetween('<Proveedores>', '</Proveedores>')+'</Proveedores>';
        String affiliate ='<Filiales>'+frame.substringBetween('<Filiales>', '</Filiales>')+'</Filiales>';
        String partcipant ='<Participantes>'+frame.substringBetween('<Participantes>', '</Participantes>')+'</Participantes>';
        String authorized ='<Autorizados>'+frame.substringBetween('<Autorizados>', '</Autorizados>')+'</Autorizados>';
        frame = frame.replace(detailClient, fillDetailClient(responseServer.valuesClient,client,detailClient));
        frame = frame.replace(addressesClient,fillAdressesClient(responseServer.valuesAdresses,client,addressesClient));
        frame = frame.replace(contactInfo,fillContactInfo(responseServer.valuesContactInfo,client,contactInfo));
        frame = frame.replace(references,fillReferences(responseServer.valuesReferences,client,references));
        frame = frame.replace(products,fillProducts(responseServer.valuesProducts,client,products));
        frame = frame.replace(customer,fillLargestCust(responseServer.valuesLargestCust,client,customer));
        frame = frame.replace(supplier,fillSupplier(responseServer.valuesSupplier,client,supplier));
        frame = frame.replace(affiliate,fillAffiliate(responseServer.valuesaffiliate,client,affiliate));
        frame = frame.replace(partcipant,fillParticipant(responseServer.valuesParticipant,client,partcipant));
        frame = frame.replace(authorized,fillAuthorized(responseServer.valuesAuthorized,client,authorized));
        return frame;        
    }
    
    public static String fillDetailClient(Map<String, String> valuesClient, SObject client, String frame){
        frame = INTUtilities.fillCorrectType(valuesClient,client,frame);
        return frame;
    }
    public static String fillAdressesClient(Map<String, String> valuesAdresses, SObject client, String frame){
        String adressesXML='';
        List<String> fields = new List<String>(Direccion__c.SObjectType.getDescribe().fields.getMap().keySet());
        String soql = ''
            + ' SELECT ' + String.join(fields, ',')
            + ' FROM Direccion__c'
            + ' WHERE DIR_Account__c=\''+String.escapeSingleQuotes(client.id)+'\'';
        List<Direccion__c> adresses = Database.query(soql);
        
        if(adresses.size()>0){
            for(Direccion__c adress:adresses){
                adressesXML+= INTUtilities.fillCorrectType(valuesAdresses,adress,frame);
            }
        }else{
            adressesXML=INTUtilities.fillCorrectType(valuesAdresses,new Direccion__c(),frame);
        }          
        
        return adressesXML;
    }
    public static String fillContactInfo(Map<String, String> valuesContInfo, SObject client, String frame){
        String contactWaysXML='';
        List<String> fields = new List<String>(Vias_de_Contacto__c.SObjectType.getDescribe().fields.getMap().keySet());
        String soql = ''
            + ' SELECT ' + String.join(fields, ',')
            + ' FROM Vias_de_Contacto__c'
            + ' WHERE VIA_Account__c=\''+String.escapeSingleQuotes(client.id)+'\'';
        List<Vias_de_Contacto__c> contactWays = Database.query(soql);
        System.debug('client.id: '+client.id);
        if(contactWays.size()>0){
            for(Vias_de_Contacto__c contact:contactWays){
                contactWaysXML+= INTUtilities.fillCorrectType(valuesContInfo,contact,frame);
            }
        }else{
            contactWaysXML=INTUtilities.fillCorrectType(valuesContInfo,new Vias_de_Contacto__c(),frame);
        }        
        
        return contactWaysXML;
    }
    public static String fillReferences(Map<String, String> valuesReferences, SObject client, String frame){
        String referencesXML='';
        List<String> fields = new List<String>(Referencia__c.SObjectType.getDescribe().fields.getMap().keySet());
        String soql = ''
            + ' SELECT ' + String.join(fields, ',')
            + ' FROM Referencia__c'
            + ' WHERE Account__c=\''+String.escapeSingleQuotes(client.id)+'\'';
        List<Referencia__c> references = Database.query(soql);
        if(references.size()>0){
            for(Referencia__c reference:references){
            referencesXML+= INTUtilities.fillCorrectType(valuesReferences,reference,frame);
        } 
        }else{
            referencesXML=INTUtilities.fillCorrectType(valuesReferences,new Referencia__c(),frame);
        }                 
        return referencesXML;
    } 
            
    public static String fillProducts(Map<String, String> valuesProducts, SObject client, String frame){
        String productsXML='';
        List<String> fields = new List<String>(Productos_y_Servicios__c.SObjectType.getDescribe().fields.getMap().keySet());
        String soql = ''
            + ' SELECT ' + String.join(fields, ',')
            + ' FROM Productos_y_Servicios__c'
            + ' WHERE Cliente__c=\''+String.escapeSingleQuotes(client.id)+'\'';
        List<Productos_y_Servicios__c> products = Database.query(soql);
        if(products.size()>0){
            for(Productos_y_Servicios__c product:products){
            productsXML+= INTUtilities.fillCorrectType(valuesProducts,product,frame);
        } 
        }else{
            productsXML=INTUtilities.fillCorrectType(valuesProducts,new Productos_y_Servicios__c(),frame);
        }                 
        return productsXML;
    } 
   
    public static String fillLargestCust(Map<String, String> valuesCustomer, SObject client, String frame){
        String customerXML='';
        List<String> fields = new List<String>(Cliente_Principal__c.SObjectType.getDescribe().fields.getMap().keySet());
        String soql = ''
            + ' SELECT ' + String.join(fields, ',')
            + ' FROM Cliente_Principal__c'
            + ' WHERE Cliente__c=\''+String.escapeSingleQuotes(client.id)+'\'';
        List<Cliente_Principal__c> customers = Database.query(soql);
        if(customers.size()>0){
            for(Cliente_Principal__c customer:customers){
            customerXML+= INTUtilities.fillCorrectType(valuesCustomer,customer,frame);
        } 
        }else{
            customerXML=INTUtilities.fillCorrectType(valuesCustomer,new Cliente_Principal__c(),frame);
        }                 
        return customerXML;
    } 
    
    public static String fillSupplier(Map<String, String> valuesSupplier, SObject client, String frame){
        String suppliersXML='';
        List<String> fields = new List<String>(Principal_Proveedor__c.SObjectType.getDescribe().fields.getMap().keySet());
        String soql = ''
            + ' SELECT ' + String.join(fields, ',')
            + ' FROM Principal_Proveedor__c'
            + ' WHERE Cliente__c=\''+String.escapeSingleQuotes(client.id)+'\'';
        List<Principal_Proveedor__c> suppliers = Database.query(soql);
        if(suppliers.size()>0){
            for(Principal_Proveedor__c supplier:suppliers){
            suppliersXML+= INTUtilities.fillCorrectType(valuesSupplier,supplier,frame);
        } 
        }else{
            suppliersXML=INTUtilities.fillCorrectType(valuesSupplier,new Principal_Proveedor__c(),frame);
        }                 
        return suppliersXML;
    } 
    
    public static String fillAffiliate(Map<String, String> valuesAffiliate, SObject client, String frame){
        String affiliatesXML='';
        List<String> fields = new List<String>(Empresa_Filial__c.SObjectType.getDescribe().fields.getMap().keySet());
        String soql = ''
            + ' SELECT ' + String.join(fields, ',')
            + ' FROM Empresa_Filial__c'
            + ' WHERE Cliente__c=\''+String.escapeSingleQuotes(client.id)+'\'';
        List<Empresa_Filial__c> affiliates = Database.query(soql);
        if(affiliates.size()>0){
            for(Empresa_Filial__c affiliate:affiliates){
            affiliatesXML+= INTUtilities.fillCorrectType(valuesAffiliate,affiliate,frame);
        } 
        }else{
            affiliatesXML=INTUtilities.fillCorrectType(valuesAffiliate,new Empresa_Filial__c(),frame);
        }                 
        return affiliatesXML;
    } 
    
    public static String fillParticipant(Map<String, String> valuesParticipant, SObject client, String frame){
        String participantXML='';
        List<String> fields = new List<String>(Participante__c.SObjectType.getDescribe().fields.getMap().keySet());
        String soql = ''
            + ' SELECT ' + String.join(fields, ',')
            + ' FROM Participante__c'
            + ' WHERE PAR_Cliente__c=\''+String.escapeSingleQuotes(client.id)+'\'';
        List<Participante__c> participants = Database.query(soql);
        if(participants.size()>0){
            for(Participante__c participant:participants){
            participantXML+= INTUtilities.fillCorrectType(valuesParticipant,participant,frame);
        } 
        }else{
            participantXML=INTUtilities.fillCorrectType(valuesParticipant,new Participante__c(),frame);
        }                 
        return participantXML;
    } 
    
    public static String fillAuthorized(Map<String, String> valuesAuthorized, SObject client, String frame){
        String authorithedXML='';
        List<String> fields = new List<String>(AccountContactRelation.SObjectType.getDescribe().fields.getMap().keySet());
        String soql = ''
            + ' SELECT ' + String.join(fields, ',')
            + ' FROM AccountContactRelation'
            + ' WHERE AccountId=\''+String.escapeSingleQuotes(client.id)+'\' AND ACC_CON_Autorizado__c = true';
        List<AccountContactRelation> authorizeds = Database.query(soql);
        if(authorizeds.size()>0){
            for(AccountContactRelation authorized:authorizeds){
            authorithedXML+= INTUtilities.fillCorrectType(valuesAuthorized,authorized,frame);
        } 
        }else{
            authorithedXML=INTUtilities.fillCorrectType(valuesAuthorized,new AccountContactRelation(),frame);
        }                 
        return authorithedXML;
    } 
    public static void creteClientJ(Id idClient) {  
          createOrModifyPF(idClient,'C');
    }
    
    @InvocableMethod
    public static void Cliente008_PJ(List<Id> recordId) {
        createOrModifyPF(recordId[0],'M');
    }
    @future(callout=true) 
    public static void createOrModifyPF(Id idClient, String action) {  
        List<StaticResource> srList = [SELECT id, name, body FROM StaticResource WHERE name = 'INT008_request_frame'];
        List<AuthSession> authList = [Select id, SourceIP, Users.Name, LoginType, NumSecondsValid, CreatedDate From AuthSession WHERE UsersId =: UserInfo.getUserId() Order By CreatedDate DESC LIMIT 1];
        
        List<String> fields = new List<String>(Account.SObjectType.getDescribe().fields.getMap().keySet());
        String soql = ''
            + ' SELECT ' + String.join(fields, ',')
            + ' FROM Account'
            + ' WHERE id=\''+String.escapeSingleQuotes(idClient)+'\'';
        Account client = Database.query(soql);
        
        HttpRequest request = new HttpRequest();
        HttpResponse res;
        Http http = new Http();
        INT008.Response responseServer = new INT008.Response();
        String frame;
        
        // If parameters are not specified, throw exception.
        
        // If static resource with the frame to be sent exists, replaces fields and sends it.
        if(!srList.isEmpty()) {
            // Setup request
            request.setEndpoint(Label.EndpointWs);
            request.setMethod('POST');
            request.setTimeout(120000);
            request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
            request.setHeader('SoapAction','http://crmintegration.local/CreaPersonaJur');
            
            frame = srList[0].body.toString();
            
            // Set WebService credentials.
            frame = frame.replace('[ws_user]', Label.Int_Username);
            //frame = frame.replace('[ws_user]', 'crmuser');
            frame = frame.replace('[ws_password]', Label.Int_Password);
            //frame = frame.replace('[ws_password]', 'Crm!user0001');
            // Set Callout parameters.
            
            frame = frame.replace('[function_username]', UserInfo.getUserName());
            frame = frame.replace('[function_requestdate]', System.now().format('dd/MM/yyyy'));
            frame = frame.replace('[function_requesttime]', System.now().format('hh:mm:ss'));
            frame = frame.replace('[function_terminal]', authList[0].SourceIp);
            frame = frame.replace('[function_action]', action);
            
            frame = fillXML(responseServer,client,frame);                                
            
         //  String frame2='<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"> <SOAP-ENV:Header> <wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"> <wsse:UsernameToken wsu:Id="UsernameToken-XXDARIO"> <wsse:Username>crmuser</wsse:Username> <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">Crm!user0001</wsse:Password> </wsse:UsernameToken> </wsse:Security> </SOAP-ENV:Header> <SOAP-ENV:Body> <HTTPSleepTime xmlns="http://crmintegration.local/">30000</HTTPSleepTime> <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Account%20IO"> <Function> <FunctionName>CreaPersonaJur</FunctionName> <UserName>DESA01</UserName> <Channel>SIEBEL</Channel> <RequestDate>15/02/2018</RequestDate> <RequestTime>11:02:36</RequestTime> <Terminal>192.168.70.4</Terminal> <Version>1</Version> <Accion>C</Accion> <RazonSocial>MH COMPANY RESORT 090909</RazonSocial> <NombreComercial>MH COMPANY RESORT 09</NombreComercial> <RNC>898888890</RNC> <TipoOrganizacion>INSTITUCIONES DEL SECTOR PÚBLICO FINANCIERO: BNV Y BANCO AGRICOLA</TipoOrganizacion> <FechaFundacion>08/01/2000</FechaFundacion> <FechaCierreFiscal>08/22/2017</FechaCierreFiscal> <Nacionalidad>ANDORRA</Nacionalidad> <GrupoGestion>GRUPO</GrupoGestion> <BICSWIFT>QUABDOS1-QUEZADA AGENTE DE CAMBIO, S.A.</BICSWIFT> <Industria/> <ActividadEconomica>923100</ActividadEconomica> <CodigoCIIU/> <TipoActividad>COMERCIO AL POR MENOR</TipoActividad> <TipoSector>PRIVADO</TipoSector> <TipoPersona>E1NF</TipoPersona> <TipoCliente>707</TipoCliente> <FuenteInfo>N</FuenteInfo> <FechaInfo>08/22/2017</FechaInfo> <RelacionExt/> <TipoDepositante/> <TipoVinculacion>DEUDOR O EMISOR NO VINCULADO</TipoVinculacion> <Condicion>PROSPECTO</Condicion> <Estado>APROBADO</Estado> <Subestado/> <Segmento>99</Segmento> <UltimaSegmentacion/> <PuntoAtencion>Default Organization</PuntoAtencion> <Ejecutivo>Desarrollo 4</Ejecutivo> <Zona/> <PuestoTrabajo>99999</PuestoTrabajo> <CategoriaRiesgo/> <TotalActivos>8</TotalActivos> <MonedaActivos>DOP</MonedaActivos> <VolumenVentasAnual>250000000</VolumenVentasAnual> <Moneda>DOP</Moneda> <NumEmpleados>23</NumEmpleados> <InternetBanking>N</InternetBanking> <CuentaNomina/> <ObjetoNegocio/> <CiudadFATCA/> <CPFATCA/> <DireccionFATCA/> <EstadoFATCA/> <TelefonoFATCA/> <InstitucionFinancieraFATCA>N</InstitucionFinancieraFATCA> <TipoAcuerdoFATCA/> <NumAcuerdoFATCA/> <AcuerdoIRSFATCA>N</AcuerdoIRSFATCA> <SegmentoFATCA>COMPAÑÍA</SegmentoFATCA> <TipoIngresoFATCA>ACTIVA</TipoIngresoFATCA> <GIINFATCA/> <TipoEmpresaFATCA>NACIONAL</TipoEmpresaFATCA> <CodEmpleado/> <CodOficina>2</CodOficina> <CIF/> <ClienteConocido/> <ViasContacto> <Identificador>1-R9NOD</Identificador> <PrincipalFlag>N</PrincipalFlag> <Telefonica/> <TipoVia>CORREO ELECTRÓNICO</TipoVia> <ViaContacto>MHCOMPANY@mail.com</ViaContacto> <RefExterna>1-R9NOD</RefExterna> </ViasContacto> <ViasContacto> <Identificador>1-O8O2F</Identificador> <PrincipalFlag>Y</PrincipalFlag> <Telefonica>Altice</Telefonica> <TipoVia>TELÉFONO MÓVIL</TipoVia> <ViaContacto>8097766554</ViaContacto> <RefExterna>1-O8O2F</RefExterna> </ViasContacto> <Direcciones> <Principal>Y</Principal> <Identificador>1-O8O15</Identificador> <TipoDir>EMPRESARIAL</TipoDir> <Calle>a</Calle> <Numero>a</Numero> <Edificio>a</Edificio> <NumApart>a</NumApart> <Pais>REPUBLICA DOMINICANA</Pais> <Provincia>04</Provincia> <Municipio>0401</Municipio> <DistritoMunicipal>040101</DistritoMunicipal> <Sector>SAVICA</Sector> <CodPostal/> <EstadoCiudadCP/> <Telefono/> <ExtTelefono/> <TelefonoAdic1/> <TelefonoAdic2/> </Direcciones> <Referencias> <Nombre>ESTHER</Nombre> <Telefono>8097656765</Telefono> <Tipo>PERSONAL</Tipo> <Direccion>Calle 4</Direccion> </Referencias> <Referencias> <Nombre>diana</Nombre> <Telefono>8097665666</Telefono> <Tipo>PERSONAL</Tipo> <Direccion>Calle 5</Direccion> </Referencias> </Function> </ListOfBREAIFuncionGeneral> </SOAP-ENV:Body> </SOAP-ENV:Envelope>';
        //string frame2 = '<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"> <SOAP-ENV:Header> <wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"> <wsse:UsernameToken wsu:Id="UsernameToken-XXDARIO"> <wsse:Username>crmuser</wsse:Username> <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">Crm!user0001</wsse:Password> </wsse:UsernameToken> </wsse:Security> </SOAP-ENV:Header> <SOAP-ENV:Body> <HTTPSleepTime xmlns="http://crmintegration.local/">30000</HTTPSleepTime> <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Account%20IO"> <Function> <FunctionName>CreaPersonaJur</FunctionName> <UserName>vimenca.viseo@force.com.calidad</UserName> <Channel>SIEBEL</Channel> <RequestDate>07/02/2020</RequestDate> <RequestTime>03:55:22</RequestTime> <Terminal>77.225.103.117</Terminal> <Version>1</Version> <Accion>C</Accion> <RazonSocial>RESTAURANT DOMINICO TROPICOCO DE LAS ISLAS C POR A</RazonSocial> <NombreComercial>RESTAURANT DOMINICO TROPICOCO DE LAS ISLAS C POR A</NombreComercial> <RNC>105055791</RNC> <TipoOrganizacion>EMPRESA INDIVIDUAL DE RESPONSABILIDAD LIMITADA (E.I.R.L.)</TipoOrganizacion> <FechaFundacion>02/05/2000</FechaFundacion> <FechaCierreFiscal>02/01/2020</FechaCierreFiscal> <Nacionalidad>REPUBLICA DOMINICANA</Nacionalidad> <GrupoGestion /> <BICSWIFT /> <Industria /> <ActividadEconomica>923100</ActividadEconomica> <CodigoCIIU /> <TipoActividad>RESTAURANTES</TipoActividad> <TipoSector>PRIVADO</TipoSector> <TipoPersona /> <TipoCliente>371</TipoCliente> <FuenteInfo>P</FuenteInfo> <FechaInfo>02/05/2020</FechaInfo> <RelacionExt /> <TipoDepositante /> <TipoVinculacion>DEUDOR O EMISOR NO VINCULADO</TipoVinculacion> <Condicion>PROSPECTO</Condicion> <Estado>CALIFICADO</Estado> <Subestado /> <Segmento>9</Segmento> <UltimaSegmentacion /> <PuntoAtencion>1 - AGENCIA PRINCIPAL</PuntoAtencion> <Ejecutivo /> <Zona /> <PuestoTrabajo /> <CategoriaRiesgo>A</CategoriaRiesgo> <TotalActivos>400</TotalActivos> <MonedaActivos>DOP</MonedaActivos> <VolumenVentasAnual>1000000</VolumenVentasAnual> <Moneda>DOP</Moneda> <NumEmpleados>566</NumEmpleados> <InternetBanking>N</InternetBanking> <CuentaNomina /> <ObjetoNegocio /> <CiudadFATCA /> <CPFATCA /> <DireccionFATCA /> <EstadoFATCA /> <TelefonoFATCA /> <InstitucionFinancieraFATCA>N</InstitucionFinancieraFATCA> <TipoAcuerdoFATCA /> <NumAcuerdoFATCA /> <AcuerdoIRSFATCA>N</AcuerdoIRSFATCA> <SegmentoFATCA /> <TipoIngresoFATCA /> <GIINFATCA /> <TipoEmpresaFATCA>NACIONAL</TipoEmpresaFATCA> <CodEmpleado /> <CodOficina /> <CIF /> <ClienteConocido>N</ClienteConocido> <ViasContacto> <Identificador /> <PrincipalFlag/> <Telefonica/> <TipoVia/> <ViaContacto/> <RefExterna /> </ViasContacto> <Direcciones> <Principal/> <Identificador /> <TipoDir/> <Calle/> <Numero/> <Edificio /> <NumApart /> <Pais/> <Provincia/> <Municipio/> <DistritoMunicipal/> <Sector/> <CodPostal /> <EstadoCiudadCP /> <Telefono /> <ExtTelefono /> <TelefonoAdic1 /> <TelefonoAdic2 /> </Direcciones> <Referencias> <Nombre/> <Telefono/> <Tipo/> <Direccion/> </Referencias> </Function> </ListOfBREAIFuncionGeneral> </SOAP-ENV:Body> </SOAP-ENV:Envelope>';   
          	request.setBody(frame);
          //  request.setBody(frame2);
            res = http.send(request);
            //System.debug(res.getBody());                      
            
            try{
                switch on (res.getStatusCode()) {
                    when 200 {
                        responseServer = parse(res.getBody());
                        updateClientCIF(responseServer, idClient,action,true);
                        //Operacion exitosa                  
                    }
                    when else {                    
                        // On Error
                        system.debug(res);
                    }
                }
            }catch(Exception e){
                System.debug('Error Type :: '+ e );
                System.debug('Error: Message: '+e.getMessage()+', Cause: '+e.getCause()+', LineNumber: '+e.getLineNumber());
				updateClientCIF(responseServer, idClient,action,false);                
            }finally{
                //Record result and request
                INTLogger.INTLoggerResult result = INTLogger.logCallout('008', 'CreaPersonaJur', request, res);       
            }
            responseServer.requestStatusCode = res.getStatusCode();
            responseServer.requestStatus = res.getStatus();
            
        } else {
            throw new XmlException('Static resource with the request template named "INT008_request_frame" could not be found.');
        }  
    }
}