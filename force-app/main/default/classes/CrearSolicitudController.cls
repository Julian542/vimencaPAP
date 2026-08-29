public class CrearSolicitudController {
    
    @AuraEnabled
    public static string crearSolicitud(String oppId){
        
        CrearSolicitudHelper.Input input = new CrearSolicitudHelper.Input();
        List<String> camposRequeridos = new List<String>();
        
        // Recopilar data de entrada para la solicitud        
        input.opportunity = [SELECT 
                             Opp_numSolictud__c, AccountId, Producto__c, Plazo__c, Tasa__c, Monto__c, Tipo_Solicitud__c, 
                             Forma_de_pago__c, opp_xcore__c, Razon_Decision__c, Dictamen__c 
                             FROM Opportunity 
                             WHERE Id = :oppId];
        
        input.account = [SELECT 
                         ACC_NumIdentificacion__c, ACC_TipoIdentificacion__c, Lastname, FirstName, MiddleName 
                         FROM Account 
                         WHERE Id = :input.opportunity.AccountId];
        
        if (input.opportunity.Producto__c == null) {
            Map<String,Schema.SObjectField> mapOppfields = Schema.Opportunity.SObjectType.getDescribe().fields.getMap();            
            camposRequeridos.add(mapOppfields.get('Producto__c').getDescribe().getLabel());
        }else {
            input.facilidad = [SELECT 
                               PRO_Codigo_de_producto__c 
                               FROM Matriz_de_producto__c 
                               WHERE Id = :input.opportunity.Producto__c];
        }
        
        input.user = [SELECT UsuarioBizagi__c FROM User where Id = :UserInfo.getUserId()];
        
        camposRequeridos.addAll(CrearSolicitudHelper.validar(input));
        if (camposRequeridos.size() == 0) {
            CrearSolicitudHelper.Output response = new CrearSolicitudHelper.Output();
            try{    
                response = CrearSolicitudHelper.crearSolicitud(input);
                if(response.errorMessage == ''){
                    input.opportunity.Opp_numSolictud__c = String.valueOf(response.processRadNumber);
                    update input.opportunity;
                    return 'OK';
                }
                return response.errorMessage;
            }catch(Exception e){return e.getMessage();}       
        }else {
            return 'Lis siguientes son requeridos para enviar la solicitud: '+
                String.valueOf(camposRequeridos).replace('(','').replace(')','');
        }
    }
}