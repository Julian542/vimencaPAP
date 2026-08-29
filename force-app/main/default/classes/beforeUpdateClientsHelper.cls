public with sharing class beforeUpdateClientsHelper {
    public void updateCIF(Account recordT,Account recordTCondition){
        System.debug('------NEW: '+recordT);
        System.debug('------NEW: '+recordT.ACC_Condicion__c);
        System.debug('------NEW: '+recordT.ACC_Estado__c);
        System.debug('------OLD: '+recordTCondition.ACC_Estado__c);
        System.debug('------OLD: '+recordTCondition.ACC_Condicion__c);
        System.debug('------OLD: '+recordTCondition);
        Boolean personAccountAndProspect = false;
        if(recordT.ACC_Condicion__c=='CLIENTE' && recordT.ACC_Estado__c=='CREADO'){
            //personAccountAndProspect = (recordT.RecordType.name =='Person Account' && recordT.ACC_Condicion__c=='PROSPECTO' && recordT.ACC_Estado__c =='CONVERTIR') ? true : false ;        
            personAccountAndProspect = (recordTCondition.ACC_Condicion__c=='PROSPECTO' && recordTCondition.ACC_Estado__c =='CONVERTIR') ? true : false ;        
        }
        system.debug('Person Account Condition Result: '+personAccountAndProspect);
        if(personAccountAndProspect){
            if(recordTCondition.RecordTypeID==Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Fisica').getRecordTypeId()){//Cuando el cliente es persona fisica
                INT007.creteClient(recordTCondition.Id);//Future method
                System.debug('Prueba CIF :: ' + recordT.ACC_CIF__c);
            }else if(recordTCondition.RecordTypeID==Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId()){//Cuando el cliente es persona juridica   
                INT008.creteClientJ(recordTCondition.Id);//Future method 
            }
            personAccountAndProspect = false;
        }else if(recordTCondition.RecordTypeID==Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId()){
            if(System.IsBatch() == false && System.isFuture() == false && !Test.isRunningTest()){ 
                INT007.modifiClient(recordTCondition.Id,'M');
            }
            // INT007.modifiClient(recordTCondition.Id,'M');
            // INT007.creteClient(recordTCondition.Id); 
            //INT007.creteClient(recordTCondition.Id);
        }
    }
    // public void CalculateClasification(Account recordT,String oldClientType,String oldOrganitationtType){
    public void CalculateClasification(Account recordT,Account recordOld){
        List<String> excludeFields = new list<String> {'FIDEICOMISOS','ASOCIACIONES SIN FINES DE LUCRO','INSTITUCIONES SIN FINES DE LUCRO EXTRANJERAS','SINDICATOS EMPRESARIALES','CONDOMINIOS','PARTIDOS POLITICOS','EMBAJADAS Y/O DELEGACIONES DIPLOMÁTICAS','ASOCIACIONES RELIGIOSAS DE LA IGLESIA CATÓLICA','ONG EXTRANJERA PRIVADA','ONG EXTRANJERA PÚBLICA','INSTITUCIONES DEL SECTOR PÚBLICO NO FINANCIERO','MUNICIPIOS Y DISTRITOS MUNICIPALES','INSTITUCIONES DEL SECTOR PÚBLICO FINANCIERO: BNV Y BANCO AGRICOLA'};
            System.debug('VENTAS :: '+recordT.ACC_Volumen_Ventas_Anual__c  );
            if(!excludeFields.contains(recordT.ACC_Tipo_Organizacion__c) 
               &&( recordOld.ACC_Tipo_Organizacion__c!= recordT.ACC_Tipo_Organizacion__c
                  || recordOld.ACC_Clasificacion_Empresa__c!= recordT.ACC_Clasificacion_Empresa__c
                  || recordOld.ACC_NumEmpleados__c!= recordT.ACC_NumEmpleados__c 
                  || recordOld.ACC_Volumen_Ventas_Anual__c!= recordT.ACC_Volumen_Ventas_Anual__c 
                  || recordOld.ACC_Total_Activos__c!= recordT.ACC_Total_Activos__c )
               &&!recordT.ACC_Persona_Fisica__c && recordT.ACC_NumEmpleados__c >=0 
               && recordT.ACC_Volumen_Ventas_Anual__c >=0 && recordT.ACC_Total_Activos__c >=0){
                   System.debug('ENTRA TRIGGER');  
                   double indicador =(recordT.ACC_NumEmpleados__c /decimal.valueOf(Label.Max_Empleado))*
                       ( recordT.ACC_Total_Activos__c /decimal.valueOf(Label.Max_Activos))*
                       ( recordT.ACC_Volumen_Ventas_Anual__c /decimal.valueOf(Label.Max_Ventas));
                   double frac = 1.0/3.0;
                   double indicadorRaiz = Math.pow(indicador, frac);
                   System.debug('Fire Trieger good' + indicadorRaiz );
                   if (indicadorRaiz < 0){
                       recordT.addError('Alguno de los valores introducidos es negativo.');
                   }else if (indicadorRaiz >= 0  && indicadorRaiz <= 0.06){                  
                       asingClasification(recordT,recordOld,'Micro');                
                   } else if (indicadorRaiz > 0.06 && indicadorRaiz <= 0.29)  {
                       asingClasification(recordT,recordOld,'Pequeña');
                   } else if (indicadorRaiz > 0.29 && indicadorRaiz <= 1.0){
                       asingClasification(recordT,recordOld,'Mediana');                       
                   }else if (indicadorRaiz > 1.0){
                       asingClasification(recordT,recordOld,'Corporativa');                       
                   }            
                   recordT.ACC_Tipo_Cliente_PJ__c = (recordT.ACC_Clasificacion_Empresa__c!=recordOld.ACC_Clasificacion_Empresa__c) ? '' : recordT.ACC_Tipo_Cliente_PJ__c;
                   // records.add(recordT);
               }else if( recordT.ACC_NumEmpleados__c ==null 
               || recordT.ACC_Volumen_Ventas_Anual__c ==null || recordT.ACC_Total_Activos__c ==null){
                   recordT.ACC_Clasificacion_Empresa__c=null;
               }        
    }
    private  void asingClasification(Account recordT,Account recordOld,String clasification){
        if(recordT.ACC_Clasificacion_Empresa__c== clasification || recordT.ACC_Clasificacion_Empresa__c==null
           ||( recordOld.ACC_NumEmpleados__c!= recordT.ACC_NumEmpleados__c || recordOld.ACC_Volumen_Ventas_Anual__c!= recordT.ACC_Volumen_Ventas_Anual__c || recordOld.ACC_Total_Activos__c!= recordT.ACC_Total_Activos__c )){
                  recordT.ACC_Clasificacion_Empresa__c=clasification;   
              }else{
                  recordT.ACC_Clasificacion_Empresa__c.addError('Para esta organización solo es permitida la clasificación "'+clasification+'".');           
              }    
    }
    
    public void Traducir_Valores_Cliente(Account Acc){
        if(Acc.ACC_Fuente_Informacion__c !='' ){            
            Acc.ACC_Fuente_de_informacion_traduccion__c = Acc.ACC_Fuente_Informacion__c== NULL ? '' : generalUtils.pickListGetLabel(Account.ACC_Fuente_Informacion__c.getDescribe(), Acc.ACC_Fuente_Informacion__c);            
        }
        if (Acc.ACC_Persona_Fisica__c){            
            if(Acc.ACC_Tipo_Persona_PF__c !=''){                
                Acc.ACC_Traduccion_tipo_persona__c = Acc.ACC_Tipo_Persona_PF__c == NULL ? '' : generalUtils.pickListGetLabel(Account.ACC_Tipo_Persona_PF__c.getDescribe(), Acc.ACC_Tipo_Persona_PF__c);                
            }  
            if(Acc.ACC_Tipo_Cliente_PF__c !=''){                
                Acc.ACC_Traduccion_tipo_cliente__c  = Acc.ACC_Tipo_Cliente_PF__c  == NULL ? '' : generalUtils.pickListGetLabel(Account.ACC_Tipo_Cliente_PF__c.getDescribe(), Acc.ACC_Tipo_Cliente_PF__c);                
            }  
        }else{            
            if(Acc.ACC_Tipo_Cliente_PJ__c !=''){                
                Acc.ACC_Traduccion_tipo_cliente__c  = Acc.ACC_Tipo_Cliente_PJ__c  == NULL ? '' : generalUtils.pickListGetLabel(Account.ACC_Tipo_Cliente_PJ__c.getDescribe(), Acc.ACC_Tipo_Cliente_PJ__c  );                
            } 
            if(Acc.ACC_Tipo_Persona_PJ__c !=''){                
                Acc.ACC_Traduccion_tipo_persona__c = Acc.ACC_Tipo_Persona_PJ__c == NULL ? '' : generalUtils.pickListGetLabel(Account.ACC_Tipo_Persona_PJ__c.getDescribe(), Acc.ACC_Tipo_Persona_PJ__c);                
            }
        }                
    }
}