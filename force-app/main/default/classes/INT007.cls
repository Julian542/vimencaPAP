public class INT007 {
    public class Response extends INTResponse {
        public final List<String> fieldList = new List<String>{'CIF'};
            public Map<String, String> valuesClient = new Map<String, String>{
                '[function_document]' => 'ACC_NumIdentificacion__c',  //principal fields
                    '[function_documentType]' => 'ACC_TipoIdentificacion__c',
                    '[function_firstName]' => 'FirstName',
                    '[function_secondName]' => 'MiddleName',
                    '[function_lastName]' => 'LastName',
                    '[function_secondlastName]' => 'Suffix',
                    '[function_midleName]' => 'MiddleName',
                    '[function_sufijo]' => 'Suffix',
                    '[function_gender]' => 'ACC_Genero__c',
                    '[function_maritalStatus]' => 'ACC_Estado_Civil__c',
                    '[function_birthDate]' => 'PersonBirthdate',
                    '[function_nacionality]' => 'ACC_Nacionalidad__c',
                    '[function_clientType]' => 'ACC_Tipo_Cliente_PF__c',
                    '[function_laboralSector]' => 'ACC_Tipo_Sector__c',//Obligatoriio
                    '[function_ActivityType]' => 'ACC_Tipo_Actividad__c',
                    '[function_segment]' => 'ACC_Segmento__c',
                    '[function_totalAssets]' => 'ACC_Total_Activos__c',
                    '[function_MonedaActivos]' => 'ACC_Moneda__c',
                    '[function_anualSales]' => 'ACC_Ventas_Ingresos_Anuales__c',
                    '[function_numEmployees]' => 'ACC_NumEmpleados__c',//principal fields
                    
                    '[function_lastDocument]' => 'ACC_N_Identificacion_Anterior__c',//Secondary Fields
                    '[function_lastDocumentType]' => 'ACC_Tipo_Identificacion_Anterior__c',
                    '[function_typePerson]' => 'ACC_Tipo_Persona_PF__c',
                    '[function_actEconSIB]' => 'Actividad_Economica_Name__c',/////////////////////////////////////////////MIRAR
                    '[function_codActEconSIB]' => 'Actividad_Economica_Direccion__c',
                    '[function_secondNationality]' => 'ACC_Otra_Nacionalidad__c',
                    '[function_bornCountry]' => 'ACC_Pais_Nacimiento__c',
                    '[function_bornProvince]' => 'ACC_Provincia_Nacimiento__c',
                    '[function_bornCityDes]' => 'ACC_Ciudad_de_nacimiento__c',
                    '[function_bornCity]' => 'Ciudad_Nacimiento_Codigo__c',
                    '[function_vinculationType]' => 'ACC_Tipo_Vinculacion__c',
                    '[function_jobPlace]' => 'ACC_Nombre_Puesto__c',
                    //'[function_Executive]' => 'ACC_Ejecutivo__c', //////////////////////////////                       
                    '[function_Executive]' => 'ACC_Nombre_Ejecutivo__c',                       
                    '[function_attentionPoint]' => 'ACC_NumOficina__c',
                    '[function_zone]' => 'ACC_Zona__c',
                    '[function_residenciaRepDom]' => 'ACC_Residencia_Rep_Dom__c',   
                    '[function_otherCountryRes]' => 'ACC_Posee_Resid_Otro_Pais__c',
                    '[function_housingtype]' => 'Tipo_de_vivienda__c',
                    '[function_depositorType]' => 'ACC_Tipo_Depositante__c',
                    '[function_exRelation]' => 'ACC_Relacion_Exterior__c',
                    '[function_currency]' => 'ACC_Moneda__c',
                    '[function_infoFont]' => 'FuenteInformacion',
                    '[function_codFuenteInfo]' => 'ACC_Fuente_Informacion__c',
                    '[function_dateInfo]' => 'ACC_Fecha_Informacion__c',
                    '[function_heritage]' => 'ACC_Patrimonio_Num__c',
                    '[function_heritageDesc]' => 'ACC_Patrimonio_Desc__c',
                    '[function_personPEP]' => 'ACC_Persona_PEP__c',
                    '[function_firstNamePEP]' => 'ACC_Primer_Nombre_PEP__c',
                    '[function_lastNamePEP]'=> 'ACC_Segundo_Nombre_PEP__c',
                    '[function_relationPEP]' => 'ACC_Tipo_Relacion_PEP__c',
                    '[function_ocupationPEP]' => 'ACC_Ocupacion_PEP__c',
                    '[function_instiNamePEP]' => 'ACC_Institucion_Trabajo_PEP__c',
                    '[function_addresInstiPEP]' => 'ACC_Direccion_Trabajo_PEP__c',
                    '[function_documentTypePEP]' => 'ACC_Tipo_Identif_PEP__c',
                    '[function_documentPEP]' => 'ACC_N_Identificacion_PEP__c',
                    '[function_formFATCA]' => 'ACC_Aplica_FATCA__c',
                    '[function_nameAltFATCA]' => 'ACC_Nombre_FATCA__c',
                    '[function_lastNameAltFATCA]' => 'ACC_Apellido_FATCA__c',
                    '[function_passaportNumFATCA]' => 'ACC_N_Pasaporte_FATCA__c',
                    '[function_dateExpFATCA]' => 'ACC_Fecha_Expiracion_FATCA__c',
                    '[function_tinFATCA]' => 'ACC_TIN_FATCA__c',
                    '[function_SSNFATCA]' => 'ACC_SSN_FATCA__c',
                    '[function_seconfNatioFATCA]' => 'ACC_Nacionalidad_FATCA__c',
                    '[function_addressFATCA]' => 'ACC_Direccion_FATCA__c',
                    '[function_cityFATCA]' => 'ACC_Ciudad_FATCA__c',
                    '[function_stateFATCA]' => 'ACC_Estado_FATCA__c',
                    '[function_postalCodeFATCA]' => 'ACC_Codigo_Postal_FATCA__c',
                    '[function_phoneFATCA]' => 'ACC_Telefono_FATCA__c',
                    '[function_adultAge]' => 'ACC_Es_Mayor_de_Edad__c',
                    '[function_officeCode]' => 'ACC_NumOficina__c',
                    '[function_employeeCode]' => 'Owner_Alias__c',
                    '[function_CIF]' => 'ACC_CIF__c',
                    '[function_knowClient]' => 'ACC_Cliente_Conocido__c',
                    '[function_isEmployee]' => 'ACC_Es_Empleado_Vimenca__c'                                       
                    };
                    public Map<String, String> valuesAdresses = new Map<String, String>{
                        '[function_addressId]' => 'DIR_Id_Externo_Direccion__c',
                            '[function_addressExternalIdBk]' => 'DIR_Id_Externo_Direccion_bk__c', //Este fue el nuevo campo agregado
                            '[function_addressIdentifier]' => 'DIR_Identificador__c',
                            '[function_addressPrimary]' => 'DIR_Principal__c',
                            '[function_addressType]' => 'DIR_Tipo_Direccion__c',
                            '[function_addressStreet]' => 'DIR_Calle__c',
                            '[function_addressNum]' => 'DIR_Numero__c',
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
                            '[function_contactSMS]' => 'VIA_Envio_SMS__c',
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
                    public Map<String, String> finanData = new Map<String, String>{
                         '[function_finanDataFont]' => 'INF_Fuente_de_ingresos__c',   //Finance Data
                             '[function_finanDataRange]' => 'INF_Ingresos__c',
                             '[function_finanDataPeriod]' => 'INF_Periodo__c'
                            };
                    public Map<String, String> laboral = new Map<String, String>{
                         '[function_laboralJob]' => 'HIS_Empleo__c',   //Laboral History
                             '[function_laboralCompany]' => 'HIS_Empresa__c',
                             '[function_laboralEmployeeType]' => 'Tipo_de_empleado__c',
                             '[function_laboralCompanyTime]' => 'Tiempo_de_empresa__c',
                             '[function_laboralPosition]' => 'HIS_Puesto_de_trabajo__c',
                             '[function_laboralFunction]' => 'HIS_Ocupacion__c',
                             '[function_laboralSalary]' => 'Salario__c',
                             '[function_laboralStartDate]' => 'HIS_Fecha_de_ingreso__c',
                             '[function_laboralEndDate]' => 'HIS_Fecha_de_fin__c',
                             '[function_laboralAddress]' => 'Direcci_n_de_la_empresa__c',
                             '[function_laboralPhone]' => 'Telefono_de_empresa_valor__c',
                             '[function_laboralMail]' => 'Correo_laboral_valor__c'
                            };   
                    public Map<String, String> conyuge = new Map<String, String>{
                         '[function_partnerDocument]' => 'ACC_NumIdentificacion__c',   //Finance Data
                             '[function_partnerDocumentType]' => 'ACC_TipoIdentificacion__c',
                             '[function_partnerFirstName]' => 'FirstName',
                             '[function_partnerSecondName]' => 'MiddleName',
                             '[function_partnerLastName]' => 'LastName',
                             '[function_partnerSecondLastName]' => 'Suffix',
                             '[function_partnerBirthDate]' => 'PersonBirthdate',
                             '[function_partnerBornCountry]' => 'ACC_Pais_Nacimiento__c',
                             '[function_partnerBornState]' => 'ACC_Provincia_Nacimiento__c',
                             '[function_partnerBornCityDes]' => 'ACC_Ciudad_de_nacimiento__c',
                             '[function_partnerBornCity]' => 'Ciudad_Nacimiento_Codigo__c'
                            }; 
                     public Map<String, String> conyugeLab = new Map<String, String>{
                             '[function_partnerLaboralPosition]' => 'HIS_Puesto_de_trabajo__c',
                             '[function_partnerLaboralFunction]' => 'HIS_Ocupacion__c',
                             '[function_partnerLaboralCompany]' => 'HIS_Empresa__c',
                             '[function_partnerLaboralSalary]' => 'Salario__c',
                             '[function_partnerLaboralAddress]' => 'Direcci_n_de_la_empresa__c',
                             '[function_partnerLaboralPhone]' => 'Telefono_de_empresa_valor__c',
                             '[function_partnerLaboralMail]' => 'Correo_laboral_valor__c'
                            }; 
    }
    
    public static INT007.Response parse(String response) {
        INT007.Response r = new INT007.Response();
        
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
    
    public static void updateClientCIF(INT007.Response responseServer, id idClient,String action, Boolean estate) {
        System.debug('Entrando en updateClientCIF');
        Account accountUpdate =[SELECT id, ACC_CIF__c From Account WHERE id=:idClient];
        if(estate){   
            System.debug('responseServer.values: '+responseServer.values);         
            accountUpdate.ACC_CIF__c = responseServer.values.get('CIF').toString();
            accountUpdate.Resultado_de_la_Integracion__c = 'Registro creado correctamente en el core.';
       }else{
            accountUpdate.Resultado_de_la_Integracion__c = 'Integracion fallida Error code: ' + responseServer.errorCode + ' Texo de error : '+ responseServer.errorText;
           if(action=='C'){ 
               accountUpdate.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Fisica').getRecordTypeId();
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
    public static String fillXML(INT007.Response responseServer, Account client, String frame){
        String detailClient =  frame.substringBetween('<Function>', '</Function>');
        String addressesClient ='<Direcciones>'+frame.substringBetween('<Direcciones>', '</Direcciones>')+'</Direcciones>';
        String contactInfo ='<ViasContacto>'+frame.substringBetween('<ViasContacto>', '</ViasContacto>')+'</ViasContacto>';
        String references ='<Referencias>'+frame.substringBetween('<Referencias>', '</Referencias>')+'</Referencias>';
        String finanData ='<DatosFinancieros>'+frame.substringBetween('<DatosFinancieros>', '</DatosFinancieros>')+'</DatosFinancieros>';
        String laboral ='<HistorialLaboral>'+frame.substringBetween('<HistorialLaboral>', '</HistorialLaboral>')+'</HistorialLaboral>';
        String conyuge ='<Conyuge>'+frame.substringBetween('<Conyuge>', '</Conyuge>')+'</Conyuge>';
        String conyugeLab ='<EmpleoActual>'+frame.substringBetween('<EmpleoActual>', '</EmpleoActual>')+'</EmpleoActual>';
        frame = frame.replace(detailClient, fillDetailClient(responseServer.valuesClient,client,detailClient));
        frame = frame.replace(addressesClient,fillAdressesClient(responseServer.valuesAdresses,client,addressesClient));
        frame = frame.replace(contactInfo,fillContactInfo(responseServer.valuesContactInfo,client,contactInfo));
        frame = frame.replace(references,fillReferences(responseServer.valuesReferences,client,references));
        frame = frame.replace(finanData,fillFinanData(responseServer.finanData,client,finanData));
        frame = frame.replace(laboral,fillLaboral(responseServer.laboral,client,laboral));
        frame = frame.replace(conyuge,fillConyuge(responseServer.conyuge,client,conyuge));
        frame = frame.replace(conyugeLab,fillConyugeLab(responseServer.conyugeLab,client,conyugeLab));
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
        List<Referencia__c> references= Database.query(soql);               
        if(references.size()>0){
            for(Referencia__c reference:references){
            referencesXML+= INTUtilities.fillCorrectType(valuesReferences,reference,frame);
        } 
        }else{
            referencesXML=INTUtilities.fillCorrectType(valuesReferences,new Referencia__c(),frame);
        }  
        return referencesXML;
    }
    public static String fillFinanData(Map<String, String> valuesContInfo, SObject client, String frame){
        String fillFinanDataXML='';
        List<String> fields = new List<String>(Informacion_Financiera__c.SObjectType.getDescribe().fields.getMap().keySet());
        String soql = ''
            + ' SELECT ' + String.join(fields, ',')
            + ' FROM Informacion_Financiera__c'
            + ' WHERE INF_Cuenta__c=\''+String.escapeSingleQuotes(client.id)+'\'';
        List<Informacion_Financiera__c> contactWays = Database.query(soql);      
        if(contactWays.size()>0){
            for(Informacion_Financiera__c contact:contactWays){
                fillFinanDataXML+= INTUtilities.fillCorrectType(valuesContInfo,contact,frame);
            }
        }else{
            fillFinanDataXML=INTUtilities.fillCorrectType(valuesContInfo,new Informacion_Financiera__c(),frame);
        }                
        return fillFinanDataXML;
    }
    
    public static String fillLaboral(Map<String, String> valuesLaboral, SObject client, String frame){
        String fillLaboralXML='';
        List<String> fields = new List<String>(Historial_laboral__c.SObjectType.getDescribe().fields.getMap().keySet());
        String soql = ''
            + ' SELECT ' + String.join(fields, ',')
            + ' FROM Historial_laboral__c'
            + ' WHERE HIS_Cuenta__c=\''+String.escapeSingleQuotes(client.id)+'\'';
        List<Historial_laboral__c> laboralHis = Database.query(soql);      
        if(laboralHis.size()>0){
            for(Historial_laboral__c contact:laboralHis){
                fillLaboralXML+= INTUtilities.fillCorrectType(valuesLaboral,contact,frame);
            }
        }else{
            fillLaboralXML=INTUtilities.fillCorrectType(valuesLaboral,new Historial_laboral__c(),frame);
        }                
        return fillLaboralXML;
    }
    
     public static String fillConyuge(Map<String, String> valuesConyuge, SObject client, String frame){
        String fillConyugeXML='';
         
        //String contactId = [SELECT PersonContactId FROM Account WHERE Id =: client.Id Limit 1].PersonContactId;
        List<Account> contactList = [SELECT PersonContactId FROM Account WHERE Id =: client.Id Limit 1];
        string contactId = contactList.size() > 0 ? contactList[0].PersonContactId : null;
        string conyugeId = null; 
         
        if(contactId != null){
            List<AccountContactRelation> accList = [SELECT AccountId FROM AccountContactRelation WHERE ContactId =: contactId 
                                AND Tipo_de_relacion__c = 'Familiar' AND Parentesco__c = 'Cónyuge' Limit 1];
           	
            conyugeId = !accList.isEmpty() ? accList[0].AccountId : null;
            if(conyugeId != null){
                List<String> fields = new List<String>(Account.SObjectType.getDescribe().fields.getMap().keySet());
                String soql = ''
                    + ' SELECT toLabel(ACC_Fuente_Informacion__c) FuenteInformacion, '
                    + String.join(fields, ',')
                    + ' FROM Account'
                    + ' WHERE id=\''+String.escapeSingleQuotes(conyugeId)+'\'';
                
                List<Account> personAccount = Database.query(soql);
                
                for(Account acc : personAccount){
                    fillConyugeXML = INTUtilities.fillCorrectType(valuesConyuge,acc,frame); 
                }                
            }
     	}
         
         if(contactId == null || conyugeId == null){
             fillConyugeXML = INTUtilities.fillCorrectType(valuesConyuge,new Account(),frame);
         }
         
        return fillConyugeXML;
    }
    
     public static String fillConyugeLab(Map<String, String> valuesConyugeLab, SObject client, String frame){
        String fillConyugeLabXML='';
        List<Account> accList = [SELECT PersonContactId FROM Account WHERE Id =: client.Id Limit 1];        
        string contactId = !accList.isEmpty() ? accList[0].PersonContactId : null;
        string conyugeId = null;
        if(contactId != null){
            List<AccountContactRelation> accConList = [SELECT AccountId FROM AccountContactRelation WHERE ContactId =: contactId 
                                                       AND Tipo_de_relacion__c = 'Familiar' AND Parentesco__c = 'Cónyuge' Limit 1];
            
            conyugeId = !accConList.isEmpty() ? accConList[0].AccountId : null;
           	if(conyugeId!= null){
                List<String> fields = new List<String>(Historial_laboral__c.SObjectType.getDescribe().fields.getMap().keySet());
                String soql = ''
                    + ' SELECT ' + String.join(fields, ',')
                    + ' FROM Historial_laboral__c'
                    + ' WHERE HIS_Cuenta__c=\''+String.escapeSingleQuotes(conyugeId)+'\' AND HIS_Empleo__c=\'Actual\'';
                
                List<Historial_laboral__c> laboralHis = Database.query(soql);   
                
                if(laboralHis.size()>0){
                    fillConyugeLabXML+= INTUtilities.fillCorrectType(valuesConyugeLab,laboralHis[0],frame);     
                }else{
                    fillConyugeLabXML+=INTUtilities.fillCorrectType(valuesConyugeLab,new Historial_laboral__c(),frame);
                }    
            }
     	}
         
         if(contactId == null || conyugeId == null){
             fillConyugeLabXML+=INTUtilities.fillCorrectType(valuesConyugeLab,new Historial_laboral__c(),frame);
         }
         
        return fillConyugeLabXML;
    }
    
    public static void creteClient(Id idClient) {          
        createOrModifyPF(idClient,'C');        
    }
    public static void modifiClient(Id idClient,String action) {          
        createOrModifyPF(idClient,action);        
    }
    
    @InvocableMethod
    public static void Cliente007_PF(List<Id> recordId) {
        modifiClient(recordId[0],'M');
       // createOrModifyPF(recordId[0],'M');
    }
    @future(callout=true)
    public static void createOrModifyPF(Id idClient, String action) {  
        List<StaticResource> srList = [SELECT id, name, body FROM StaticResource WHERE name = 'INT007_request_frame'];
        List<AuthSession> authList = [Select id, SourceIP, Users.Name, LoginType, NumSecondsValid, CreatedDate From AuthSession WHERE UsersId =: UserInfo.getUserId() Order By CreatedDate DESC LIMIT 1];
        
        List<String> fields = new List<String>(Account.SObjectType.getDescribe().fields.getMap().keySet());
        String soql = ''
            + ' SELECT toLabel(ACC_Fuente_Informacion__c) FuenteInformacion, '
            + String.join(fields, ',')
            + ' FROM Account'
            + ' WHERE id=\''+String.escapeSingleQuotes(idClient)+'\'';
        Account client = Database.query(soql);
        
        HttpRequest request = new HttpRequest();
        HttpResponse res;
        Http http = new Http();
        System.debug('Peticion INT007 lanzada');
        INT007.Response responseServer = new INT007.Response();
        String frame;
        
        // If parameters are not specified, throw exception.
        
        // If static resource with the frame to be sent exists, replaces fields and sends it.
        if(!srList.isEmpty()) {
            // Setup request
            request.setEndpoint(Label.EndpointWs);
            request.setMethod('POST');
            request.setTimeout(120000);
            request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
            request.setHeader('SoapAction','http://crmintegration.local/CreaPersonaFis');
            
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
            
            // String frame2='<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"> <SOAP-ENV:Header> <wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"> <wsse:UsernameToken wsu:Id="UsernameToken-XXDARIO"> <wsse:Username>crmuser</wsse:Username> <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">Crm!user0001</wsse:Password> </wsse:UsernameToken> </wsse:Security> </SOAP-ENV:Header> <SOAP-ENV:Body> <HTTPSleepTime xmlns="http://crmintegration.local/">30000</HTTPSleepTime> <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Contacto%20IO"> <Function> <FunctionName>CreaPersonaFis</FunctionName> <UserName>vimenca.viseo@force.com.viseodev</UserName> <Channel>SIEBEL</Channel> <RequestDate>25/01/2020</RequestDate> <RequestTime>01:42:59</RequestTime> <Terminal>2.152.106.158</Terminal> <Version>1</Version> <Accion>C</Accion> <NumDocumento>40223588902</NumDocumento> <TipoDocumento>Cédula</TipoDocumento> <NumDocumentoAnt></NumDocumentoAnt> <TipoDocumentoAnt></TipoDocumentoAnt> <PrimerNombre>RAMONA</PrimerNombre> <SegundoNombre></SegundoNombre> <PrimerApellido>JEAN</PrimerApellido> <SegundoApellido></SegundoApellido> <TipoPersona>P5</TipoPersona> <TipoCliente>511</TipoCliente> <SectorLaboral>PRIVADO</SectorLaboral> <TipoActividad>ELECTRICIDAD</TipoActividad> <ActEconSIB>ACABADO DE MUEBLES, TALES COMO LA FUMIGACIÓN, PINTURA Y PULIDO</ActEconSIB> <CodActEconSIB>361033</CodActEconSIB> <Genero>FEMENINO</Genero> <EstadoCivil>SOLTERO/A</EstadoCivil> <FechaNacimiento>01/14/2000</FechaNacimiento> <Nacionalidad>REPUBLICA DOMINICANA</Nacionalidad> <OtraNacionalidad></OtraNacionalidad> <PaisNacimiento>REPUBLICA DOMINICANA</PaisNacimiento> <ProvinciaNacimiento>06</ProvinciaNacimiento> <CiudadNacimientoDesc>PIMENTEL</CiudadNacimientoDesc> <CiudadNacimiento>0604</CiudadNacimiento> <TipoVinculacion>DEUDOR O EMISOR NO VINCULADO</TipoVinculacion> <PuestoTrabajo>20000</PuestoTrabajo> <Ejecutivo>Desarrollo 1</Ejecutivo> <PuntoAtencion>MEGACENTRO</PuntoAtencion> <Zona></Zona> <Segmento>99</Segmento> <ResidenciaRepDom>PERMANENTE</ResidenciaRepDom> <PaisOtraResidencia></PaisOtraResidencia> <TipoDepositante></TipoDepositante> <RelacionExt></RelacionExt> <TotalActivos>5000</TotalActivos> <MonedaActivos>DOP</MonedaActivos> <TotalVentasAnual>12500</TotalVentasAnual> <Moneda>DOP</Moneda> <NumEmpleados>0</NumEmpleados> <FuenteInfo></FuenteInfo> <CodFuenteInfo></CodFuenteInfo> <FechaInfo>01/01/2020</FechaInfo> <PersonaPEP>NO</PersonaPEP> <PrimerNombrePEP></PrimerNombrePEP> <SegundoNombrePEP></SegundoNombrePEP> <PrimerApelllidoPEP></PrimerApelllidoPEP> <SegundoApelllidoPEP></SegundoApelllidoPEP> <TipoRelacionPEP></TipoRelacionPEP> <OcupacionPEP></OcupacionPEP> <NombreInstitucionPEP></NombreInstitucionPEP> <DirInstitucionPEP></DirInstitucionPEP> <TipoDocPEP></TipoDocPEP> <NumDocPEP></NumDocPEP> <FormularioFATCA></FormularioFATCA> <NombreAltFATCA></NombreAltFATCA> <ApellidoAltFATCA></ApellidoAltFATCA> <NumPasaporteFATCA></NumPasaporteFATCA> <FechaExpFATCA></FechaExpFATCA> <TINFATCA></TINFATCA> <SSNFATCA></SSNFATCA> <SegNacionalidadFATCA></SegNacionalidadFATCA> <DireccionFATCA></DireccionFATCA> <CiudadFATCA></CiudadFATCA> <EstadoFATCA></EstadoFATCA> <CodPostalFATCA></CodPostalFATCA> <TelefonoFATCA></TelefonoFATCA> <EsMayorEdad>SI</EsMayorEdad> <CodOficina>2</CodOficina> <CodEmpleado>DESA01</CodEmpleado> <CIF></CIF> <ClienteConocido></ClienteConocido> <EsEmpleado>N</EsEmpleado> <Direcciones> <Identificador>1-W2EHV</Identificador> <Principal>Y</Principal> <TipoDir>RESIDENCIA</TipoDir> <Calle>TEST</Calle> <Numero>2</Numero> <Edificio></Edificio> <NumApart></NumApart> <Pais>REPUBLICA DOMINICANA</Pais> <Provincia>05</Provincia> <Municipio>0501</Municipio> <DistritoMunicipal>050102</DistritoMunicipal> <Sector>CAÑONGO</Sector> <CodPostal></CodPostal> <EstadoCiudadCP></EstadoCiudadCP> <Telefono></Telefono> <Extension></Extension> <TelefonoAdic1></TelefonoAdic1> <TelefonoAdic2></TelefonoAdic2> </Direcciones> <ViasContacto> <Identificador>1-W2EI3</Identificador> <Principal>Y</Principal> <TipoVia>TELÉFONO MÓVIL</TipoVia> <ViaContacto>8092211452</ViaContacto> <Telefonica>Claro</Telefonica> <EnvioSMS>N</EnvioSMS> <RefExterna>1-W2EI3</RefExterna> </ViasContacto> <Referencias> <Tipo>COMERCIAL</Tipo> <Nombre>TEST</Nombre> <Telefono>8095544778</Telefono> <Direccion>TEST</Direccion> </Referencias> <Referencias> <Tipo>BANCARIA</Tipo> <Nombre>TEST2</Nombre> <Telefono>8095566998</Telefono> <Direccion>TEST2</Direccion> </Referencias> <DatosFinancieros> <Fuente>Honorarios Profesionales</Fuente> <RangoIngresos>BR Rango 03</RangoIngresos> <Periodo>Trimestral</Periodo> </DatosFinancieros> </Function> </ListOfBREAIFuncionGeneral> </SOAP-ENV:Body> </SOAP-ENV:Envelope> ';
           // String frame2='<?xml version="1.0" encoding="UTF-8"?> <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"> <SOAP-ENV:Header> <wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"> <wsse:UsernameToken wsu:Id="UsernameToken-XXDARIO"> <wsse:Username>crmuser</wsse:Username> <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">Crm!user0001</wsse:Password> </wsse:UsernameToken> </wsse:Security> </SOAP-ENV:Header> <SOAP-ENV:Body> <HTTPSleepTime xmlns="http://crmintegration.local/">30000</HTTPSleepTime> <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Contacto%20IO"> <Function> <FunctionName>CreaPersonaFis</FunctionName> <UserName>vimenca.viseo@force.com.calidad</UserName> <Channel>SIEBEL</Channel> <RequestDate>11/02/2020</RequestDate> <RequestTime>09:04:25</RequestTime> <Terminal>77.225.103.117</Terminal> <Version>1</Version> <Accion>C</Accion> <NumDocumento>00112760749</NumDocumento> <TipoDocumento>Cédula</TipoDocumento> <NumDocumentoAnt /> <TipoDocumentoAnt /> <PrimerNombre>GABRIELA</PrimerNombre> <SegundoNombre /> <PrimerApellido>RAMIREZ</PrimerApellido> <SegundoApellido>DE LA CRUZ</SegundoApellido> <TipoPersona>P5</TipoPersona> <TipoCliente>511</TipoCliente> <SectorLaboral>PRIVADO</SectorLaboral> <TipoActividad>ELECTRICIDAD</TipoActividad> <ActEconSIB>ACABADO DE MUEBLES, TALES COMO LA FUMIGACIÓN, PINTURA Y PULIDO</ActEconSIB> <CodActEconSIB>361033</CodActEconSIB> <Genero>FEMENINO</Genero> <EstadoCivil>SOLTERO/A</EstadoCivil> <FechaNacimiento>05/02/1976</FechaNacimiento> <Nacionalidad>REPUBLICA DOMINICANA</Nacionalidad> <OtraNacionalidad /> <PaisNacimiento>REPUBLICA DOMINICANA</PaisNacimiento> <ProvinciaNacimiento>20</ProvinciaNacimiento> <CiudadNacimientoDesc /> <CiudadNacimiento>LAS TERRENAS</CiudadNacimiento> <TipoVinculacion>DEUDOR O EMISOR NO VINCULADO</TipoVinculacion> <PuestoTrabajo>20000</PuestoTrabajo> <Ejecutivo>0053i000002DQmhAAG</Ejecutivo> <PuntoAtencion /> <Zona>Servicio al Cliente</Zona> <Segmento>99</Segmento> <ResidenciaRepDom>PERMANENTE</ResidenciaRepDom> <PaisOtraResidencia>N</PaisOtraResidencia> <TipoDepositante /> <RelacionExt>Exportador No Zona Franca</RelacionExt> <TotalActivos>100</TotalActivos> <MonedaActivos /> <TotalVentasAnual>77000.00</TotalVentasAnual> <Moneda>DOP</Moneda> <NumEmpleados>20</NumEmpleados> <FuenteInfo>E</FuenteInfo> <CodFuenteInfo /> <FechaInfo>03/06/2019</FechaInfo> <PersonaPEP>NO</PersonaPEP> <PrimerNombrePEP /> <SegundoNombrePEP /> <PrimerApelllidoPEP /> <SegundoApelllidoPEP /> <TipoRelacionPEP /> <OcupacionPEP /> <NombreInstitucionPEP /> <DirInstitucionPEP /> <TipoDocPEP /> <NumDocPEP /> <FormularioFATCA>N</FormularioFATCA> <NombreAltFATCA /> <ApellidoAltFATCA /> <NumPasaporteFATCA /> <FechaExpFATCA /> <TINFATCA /> <SSNFATCA /> <SegNacionalidadFATCA /> <DireccionFATCA /> <CiudadFATCA /> <EstadoFATCA /> <CodPostalFATCA /> <TelefonoFATCA /> <EsMayorEdad>Y</EsMayorEdad> <CodOficina>4 - BAVARO</CodOficina> <CodEmpleado>P5</CodEmpleado> <CIF>1062751</CIF> <ClienteConocido>Y</ClienteConocido> <EsEmpleado>N</EsEmpleado> <Direcciones> <Identificador /> <Principal>Y</Principal> <TipoDir>RESIDENCIA</TipoDir> <Calle>Av, Lincoln</Calle> <Numero>78</Numero> <Edificio /> <NumApart /> <Pais>DO</Pais> <Provincia>32</Provincia> <Municipio>3201</Municipio> <DistritoMunicipal>320101</DistritoMunicipal> <Sector>LOS TRINITARIOS</Sector> <CodPostal /> <EstadoCiudadCP /> <Telefono /> <Extension /> <TelefonoAdic1 /> <TelefonoAdic2 /> </Direcciones> <ViasContacto> <Identificador /> <Principal>N</Principal> <TipoVia>CORREO ELECTRÓNICO</TipoVia> <ViaContacto>catti.simo@viseo.com</ViaContacto> <Telefonica /> <EnvioSMS>N</EnvioSMS> <RefExterna /> </ViasContacto> <ViasContacto> <Identificador /> <Principal>N</Principal> <TipoVia>TELÉFONO FIJO</TipoVia> <ViaContacto>8092233232</ViaContacto> <Telefonica>Claro</Telefonica> <EnvioSMS>N</EnvioSMS> <RefExterna /> </ViasContacto> <ViasContacto> <Identificador /> <Principal>Y</Principal> <TipoVia>TELÉFONO FIJO</TipoVia> <ViaContacto>32456543</ViaContacto> <Telefonica>Claro</Telefonica> <EnvioSMS>N</EnvioSMS> <RefExterna /> </ViasContacto> <Referencias> <Tipo>COMERCIAL</Tipo> <Nombre>La Nacional</Nombre> <Telefono>8092220033</Telefono> <Direccion /> </Referencias> <Referencias> <Tipo>PERSONAL</Tipo> <Nombre>Carlos A</Nombre> <Telefono>8093334434</Telefono> <Direccion /> </Referencias> <Referencias> <Tipo>PERSONAL</Tipo> <Nombre>Caros A</Nombre> <Telefono>6578888888</Telefono> <Direccion /> </Referencias> <Referencias> <Tipo>PERSONAL</Tipo> <Nombre>Ana</Nombre> <Telefono>8905555555</Telefono> <Direccion /> </Referencias> <Referencias> <Tipo>PERSONAL</Tipo> <Nombre>Carlos</Nombre> <Telefono>809334434</Telefono> <Direccion>RD</Direccion> </Referencias> <Referencias> <Tipo>COMERCIAL</Tipo> <Nombre>ttt</Nombre> <Telefono>8096913400</Telefono> <Direccion>Calle Sirio 24</Direccion> </Referencias> <Referencias> <Tipo>COMERCIAL</Tipo> <Nombre>Ejemplo</Nombre> <Telefono /> <Direccion /> </Referencias> <DatosFinancieros> <Fuente>Dividendos</Fuente> <RangoIngresos>RD$ 100,001 A RD$ 135,000</RangoIngresos> <Periodo>Mensual</Periodo> </DatosFinancieros> </Function> </ListOfBREAIFuncionGeneral> </SOAP-ENV:Body> </SOAP-ENV:Envelope>';
           // String frame2='<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"> <SOAP-ENV:Header> <wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"> <wsse:UsernameToken wsu:Id="UsernameToken-XXDARIO"> <wsse:Username>crmuser</wsse:Username> <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">Crm!user0001</wsse:Password> </wsse:UsernameToken> </wsse:Security> </SOAP-ENV:Header> <SOAP-ENV:Body> <HTTPSleepTime xmlns="http://crmintegration.local/">30000</HTTPSleepTime> <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Contacto%20IO"> <Function> <FunctionName>CreaPersonaFis</FunctionName> <UserName>vimenca.viseo@force.com.viseodev</UserName> <Channel>SIEBEL</Channel> <RequestDate>25/01/2020</RequestDate> <RequestTime>01:42:59</RequestTime> <Terminal>2.152.106.158</Terminal> <Version>1</Version> <Accion>C</Accion> <NumDocumento>40223588902</NumDocumento> <TipoDocumento>Cédula</TipoDocumento> <NumDocumentoAnt></NumDocumentoAnt> <TipoDocumentoAnt></TipoDocumentoAnt> <PrimerNombre>RAMONA</PrimerNombre> <SegundoNombre></SegundoNombre> <PrimerApellido>JEAN</PrimerApellido> <SegundoApellido></SegundoApellido> <TipoPersona>P5</TipoPersona> <TipoCliente>511</TipoCliente> <SectorLaboral>PRIVADO</SectorLaboral> <TipoActividad>ELECTRICIDAD</TipoActividad> <ActEconSIB>ACABADO DE MUEBLES, TALES COMO LA FUMIGACIÓN, PINTURA Y PULIDO</ActEconSIB> <CodActEconSIB>361033</CodActEconSIB> <Genero>FEMENINO</Genero> <EstadoCivil>SOLTERO/A</EstadoCivil> <FechaNacimiento>01/14/2000</FechaNacimiento> <Nacionalidad>REPUBLICA DOMINICANA</Nacionalidad> <OtraNacionalidad></OtraNacionalidad> <PaisNacimiento>REPUBLICA DOMINICANA</PaisNacimiento> <ProvinciaNacimiento>06</ProvinciaNacimiento> <CiudadNacimientoDesc>PIMENTEL</CiudadNacimientoDesc> <CiudadNacimiento>0604</CiudadNacimiento> <TipoVinculacion>DEUDOR O EMISOR NO VINCULADO</TipoVinculacion> <PuestoTrabajo>20000</PuestoTrabajo> <Ejecutivo>Desarrollo 1</Ejecutivo> <PuntoAtencion>MEGACENTRO</PuntoAtencion> <Zona></Zona> <Segmento>99</Segmento> <ResidenciaRepDom>PERMANENTE</ResidenciaRepDom> <PaisOtraResidencia></PaisOtraResidencia> <TipoDepositante></TipoDepositante> <RelacionExt></RelacionExt> <TotalActivos>5000</TotalActivos> <MonedaActivos>DOP</MonedaActivos> <TotalVentasAnual>12500</TotalVentasAnual> <Moneda>DOP</Moneda> <NumEmpleados>0</NumEmpleados> <FuenteInfo></FuenteInfo> <CodFuenteInfo></CodFuenteInfo> <FechaInfo>01/01/2020</FechaInfo> <PersonaPEP>NO</PersonaPEP> <PrimerNombrePEP></PrimerNombrePEP> <SegundoNombrePEP></SegundoNombrePEP> <PrimerApelllidoPEP></PrimerApelllidoPEP> <SegundoApelllidoPEP></SegundoApelllidoPEP> <TipoRelacionPEP></TipoRelacionPEP> <OcupacionPEP></OcupacionPEP> <NombreInstitucionPEP></NombreInstitucionPEP> <DirInstitucionPEP></DirInstitucionPEP> <TipoDocPEP></TipoDocPEP> <NumDocPEP></NumDocPEP> <FormularioFATCA></FormularioFATCA> <NombreAltFATCA></NombreAltFATCA> <ApellidoAltFATCA></ApellidoAltFATCA> <NumPasaporteFATCA></NumPasaporteFATCA> <FechaExpFATCA></FechaExpFATCA> <TINFATCA></TINFATCA> <SSNFATCA></SSNFATCA> <SegNacionalidadFATCA></SegNacionalidadFATCA> <DireccionFATCA></DireccionFATCA> <CiudadFATCA></CiudadFATCA> <EstadoFATCA></EstadoFATCA> <CodPostalFATCA></CodPostalFATCA> <TelefonoFATCA></TelefonoFATCA> <EsMayorEdad>SI</EsMayorEdad> <CodOficina>2</CodOficina> <CodEmpleado>DESA01</CodEmpleado> <CIF></CIF> <ClienteConocido></ClienteConocido> <EsEmpleado>N</EsEmpleado> <Direcciones> <Identificador>1-W2EHV</Identificador> <Principal>Y</Principal> <TipoDir>RESIDENCIA</TipoDir> <Calle>TEST</Calle> <Numero>2</Numero> <Edificio></Edificio> <NumApart></NumApart> <Pais>REPUBLICA DOMINICANA</Pais> <Provincia>05</Provincia> <Municipio>0501</Municipio> <DistritoMunicipal>050102</DistritoMunicipal> <Sector>CAÑONGO</Sector> <CodPostal></CodPostal> <EstadoCiudadCP></EstadoCiudadCP> <Telefono></Telefono> <Extension></Extension> <TelefonoAdic1></TelefonoAdic1> <TelefonoAdic2></TelefonoAdic2> </Direcciones> <ViasContacto> <Identificador>1-W2EI3</Identificador> <Principal>Y</Principal> <TipoVia>TELÉFONO MÓVIL</TipoVia> <ViaContacto>8092211452</ViaContacto> <Telefonica>Claro</Telefonica> <EnvioSMS>N</EnvioSMS> <RefExterna>1-W2EI3</RefExterna> </ViasContacto> <Referencias> <Tipo>COMERCIAL</Tipo> <Nombre>TEST</Nombre> <Telefono>8095544778</Telefono> <Direccion>TEST</Direccion> </Referencias> <Referencias> <Tipo>BANCARIA</Tipo> <Nombre>TEST2</Nombre> <Telefono>8095566998</Telefono> <Direccion>TEST2</Direccion> </Referencias> <DatosFinancieros> <Fuente>Honorarios Profesionales</Fuente> <RangoIngresos>BR Rango 03</RangoIngresos> <Periodo>Trimestral</Periodo> </DatosFinancieros> </Function> </ListOfBREAIFuncionGeneral> </SOAP-ENV:Body> </SOAP-ENV:Envelope> ';
            request.setBody(frame);
           // request.setBody(frame2);
            res = http.send(request);
            //System.debug(res.getBody());                      
            
            try{
                switch on (res.getStatusCode()) {
                    when 200 {
                        responseServer = parse(res.getBody());
                        updateClientCIF(responseServer, idClient,action,true);
                        //Esta es la buena...                    
                    }
                    when else {                    
                        // On Error
                        responseServer.errorCode = '500';
                        responseServer.errorText = 'Error en el servidor';
                        updateClientCIF(responseServer, idClient,action,false);
                        system.debug(res);
                    }
                }
            }catch(Exception e){
                System.debug('Error Type :: '+ e );
                updateClientCIF(responseServer, idClient,action,false);
            }finally{
                //Record result and request
                INTLogger.INTLoggerResult result = INTLogger.logCallout('007', 'CreaPersonaFis', request, res);       
            }
            responseServer.requestStatusCode = res.getStatusCode();
            responseServer.requestStatus = res.getStatus();
            
        } else {
            throw new XmlException('Static resource with the request template named "INT007_request_frame" could not be found.');
        }
    }
}