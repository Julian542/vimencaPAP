public class ComprobanteReclamoExtension {

    public Case reclamo {get;set;}
    public List<TRA_Transaccion__c> transacciones {get;set;}
    public List<ID> recordTypes = new List<Id>();
    public Boolean isPF {get;set;}
    
    public ComprobanteReclamoExtension(ApexPages.StandardController stdController) {
        
        reclamo = (Case)stdController.getRecord();

        reclamo = [
            SELECT Id,
                   Asignado_a__c,
                   CreatedDate,
                   CAS_Tipo_de_cuenta_financiera__c,
                   Type,
                   CAS_Monto__c,
                   CAS_Numero_transacciones__c,
                   Description,
                   CAS_Correo_Electronico_Cliente__c,
                   CAS_Solucion_de_Reclamacion__c,
                   CaseNumber,
                   RecordTypeId,
                   CAS_Tipo_Caso__c,
                   Origin,
                   CAS_Canal_distribucion__c,
                   CAS_Donde_recibir_respuesta__c,
                   Asignado_a__r.USE_Codigo__c,
                   Asignado_a__r.USE_Oficina__c,
                   Asignado_a__r.Name,
                   Asset.ASE_N_de_cuenta__c,
                   Account.Name,
                   Account.ACC_TipoIdentificacion__c,
                   Account.ACC_NumIdentificacion__c,
                   Account.ACC_RNC__c,
                   Account.Phone,
                   Account.ACC_Telefono_Movil__c,
                   Account.BillingCountry,
                   Account.BillingState,
                   Account.BillingCity,
                   Account.BillingStreet,
                   Account.BillingPostalCode,
                   Account.ACC_Moneda__c,
                   Account.RecordTypeId,
                   Account.IsPersonAccount,
                   CreatedBy.Name
            FROM Case
            WHERE Id = :reclamo.Id
            LIMIT 1
        ];
        
        transacciones = [
            SELECT Id,
                   TRA_Canal__c,
                   TRA_Credito_Debito__c,
                   TRA_Fecha__c,
                   TRA_Moneda__c,
                   TRA_Monto__c,
                   Name
            FROM TRA_Transaccion__c
            WHERE TRA_Reclamacion__c = :reclamo.Id
        ];
        
        if (reclamo.Account.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Personas_Juridicas').getRecordTypeId()) {
            isPF = false;
        }

        if (reclamo.Account.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId()) {
            isPF = true;
        }
        
        recordTypes.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Reclamaciones').getRecordTypeId());
        recordTypes.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('RT_Soporte_1').getRecordTypeId());
        recordTypes.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('RT_Soporte_2').getRecordTypeId());
        recordTypes.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('RT_Soporte_3').getRecordTypeId());
        recordTypes.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('RT_Soporte_4').getRecordTypeId());
        recordTypes.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('RT_Soporte_5').getRecordTypeId());
        recordTypes.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('RT_Soporte_6').getRecordTypeId());
        recordTypes.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('RT_Soporte_7').getRecordTypeId());
        recordTypes.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('RT_Soporte_8').getRecordTypeId());
        recordTypes.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('RT_Solicitud_1_1').getRecordTypeId());
        recordTypes.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('RT_Solicitud_1_2').getRecordTypeId());
        recordTypes.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('RT_Solicitud_2').getRecordTypeId());
        recordTypes.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('RT_Solicitud_3').getRecordTypeId());
        recordTypes.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('RT_Solicitud_4').getRecordTypeId());
        recordTypes.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('RT_Solicitud_5').getRecordTypeId());
        recordTypes.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('RT_Solicitud_6').getRecordTypeId());
    }
    
    public String getReclamoCreatedDate(){
        return generalUtils.getDate(reclamo.CreatedDate.Date());
    }
    
    public String getReclamoCreatedDateTime(){
        return generalUtils.getDateTime(reclamo.CreatedDate);
    }
    
    public String getOficina(){
        return generalUtils.pickListGetLabel(user.USE_Oficina__c.getDescribe(), reclamo.Asignado_a__r.USE_Oficina__c);
    }
    
    public String getTipoReclamo(){
        return generalUtils.pickListGetLabel(Case.Type.getDescribe(), reclamo.Type);
    }
    
    public String getSLA(){
        if(reclamo.recordTypeId == recordTypes[1]) return '30 días laborales';
        else if(reclamo.recordTypeId == recordTypes[2]) return '30 días laborales';
        else if(reclamo.recordTypeId == recordTypes[3] || reclamo.recordTypeId == recordTypes[4]) return '30 días laborales';
        else if(reclamo.recordTypeId == recordTypes[5] || reclamo.recordTypeId == recordTypes[6] || reclamo.recordTypeId == recordTypes[7] || reclamo.recordTypeId == recordTypes[8])
            return '3 días laborales';        
        else if(reclamo.recordTypeId == recordTypes[9] && (reclamo.type == 'S12' || reclamo.type == 'S14' || reclamo.type == 'S15' || reclamo.type == 'S27' || reclamo.type == 'S28'))  
            return '1 día laboral';          
        else if(reclamo.recordTypeId == recordTypes[15] && (reclamo.type == 'S17' || reclamo.type == 'S24' || reclamo.type == 'S25' || reclamo.type == 'S29'))  
            return '1 día laboral';
        else if(reclamo.recordTypeId == recordTypes[9] && (reclamo.type == 'S7' || reclamo.type == 'S16' || reclamo.type == 'S19'))  
            return '2 días laborales';            
        else if(reclamo.recordTypeId == recordTypes[15] && (reclamo.type != 'S17' || reclamo.type != 'S24' || reclamo.type != 'S19' || reclamo.type != 'S25' || reclamo.type != 'S29' || reclamo.type != 'S30' || reclamo.type != 'S31'))
            return '2 días laborales'; 
        else if((reclamo.recordTypeId == recordTypes[10] && reclamo.type == 'S26') || (reclamo.recordTypeId == recordTypes[14] && reclamo.type == 'S13') || (reclamo.recordTypeId == recordTypes[15] && reclamo.type == 'S30'))
            return '3 días laborales';
        else if((reclamo.recordTypeId == recordTypes[15] && reclamo.type == 'S31') || (reclamo.recordTypeId == recordTypes[13] && reclamo.type == 'S5'))
            return '4 días laborales';  
        else if((reclamo.recordTypeId == recordTypes[11] && reclamo.type == 'S2') || (reclamo.recordTypeId == recordTypes[13] && reclamo.type == 'S4'))
            return '6 días laborales';   
        else if((reclamo.recordTypeId == recordTypes[12] && reclamo.type == 'S6'))
            return '7 días laborales';
        else if((reclamo.recordTypeId == recordTypes[10] && reclamo.type == 'S1'))
            return '11 días laborales';
        else if((reclamo.recordTypeId == recordTypes[12] && reclamo.type == 'S3'))
            return '11 días laborales';
        else if((reclamo.recordTypeId == recordTypes[10] && reclamo.type == 'S8') || (reclamo.recordTypeId == recordTypes[11] && (reclamo.type == 'S9' || reclamo.type == 'S10' || reclamo.type == 'S11')))
            return '16 días laborales';   
            
        return '';
    }
}