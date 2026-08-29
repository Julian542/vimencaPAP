/**
 * @description       : an adapted version of ActualizacionClienteREST to FinServClouc
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 27-12-2025
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
@RestResource(urlMapping='/Account/actualizacionCliente/*')
global class ActualizacionClienteREST_FSC {
    private static final Map<Integer,String> RES_STATUS = new Map<Integer,String>{200=>'Success', 202=>'Partial Success', 404=>'Not found'};

    @HttpPut
    global static void doPut(){

        RestRequest req                     = RestContext.request;
        String reqBody                      = req.requestBody.toString();
        RestResponse res                    = RestContext.response;
        ResponseWrapper resWrapper          = new ResponseWrapper();
        Map<String,ClienteDTO> mapClientes  = new Map<String,ClienteDTO>();
        Set<String> estadosDisponibles      = getEstadoPickListValues();
        Set<String> segmentoDisponibles     = getSegmentoPickListValues();
        Map<String,Id> datosMaestrosMap     = getDatosMaestrosByDireccion();

        List<ClienteDTO> clientes       = (List<ClienteDTO>) JSON.deserialize(reqBody, List<ClienteDTO>.class);
        List<Account> lstToUpdate       = new List<Account>();
        Set<String> ownersEmails        = new Set<String>();
        map<String, Id> mpEmailUserid   = new map<String, Id>();

        for(ClienteDTO c: clientes){
            if(!String.isBlank(c.CIF)){
                mapClientes.put(c.CIF, c);
            }

            if(!String.isBlank(c.ejecutivo) && !ownersEmails.contains(c.ejecutivo)){
                ownersEmails.add(c.ejecutivo);
            }
        }

        for(User u : [SELECT Id, Email FROM User WHERE Email IN :ownersEmails AND IsActive = true]){
            mpEmailUserid.put(u.Email, u.Id);
        }

        Map<Id,Account> accounts = new Map<Id,Account>([
            SELECT Id, ACC_CIF__c, ACC_Estado__c, ACC_Ejecutivo__c, ACC_Segmento__c, Industry, OwnerId
            FROM Account
            WHERE ACC_CIF__c
            IN :mapClientes.keySet()
        ]);
        ClienteDTO cliente= new ClienteDTO();

        if(accounts.isEmpty()){
            resWrapper.errors.add('Error Code: NINGUNO DE LOS CIF EXISTE. Fields: (ACC_CIF__c). Message: NINGUNO DE LOS CIF EXISTE');
            res.statusCode = 404;
        }else if(accounts.size() != mapClientes.size()){
            resWrapper.errors.add('Error Code: UNO O ALGUNOS DE LOS CIF NO EXISTE. Fields: (ACC_CIF__c). Message: UNO O ALGUNOS DE LOS CIF NO EXISTE');
        }

        for(Account acc : accounts.values()){
            if(mapClientes.containsKey(acc.ACC_CIF__c)){
                cliente                         = mapClientes.get(acc.ACC_CIF__c);
                acc.ACC_Estado__c               = (!String.isBlank(cliente.estado))             ? cliente.estado                        : acc.ACC_Estado__c;
                acc.ACC_Ejecutivo__c            = !(String.isBlank(cliente.ejecutivo))          ? cliente.ejecutivo                     : acc.ACC_Ejecutivo__c;
                acc.OwnerId                     = mpEmailUserid.containsKey(cliente.ejecutivo)  ? mpEmailUserid.get(cliente.ejecutivo)  : acc.OwnerId;
                acc.ACC_Segmento__c             = (!String.isBlank(cliente.segmento))           ? cliente.segmento                      : acc.ACC_Segmento__c;
                acc.Industry                    = (!(String.isBlank(cliente.CIIU)))             ? datosMaestrosMap.get(cliente.CIIU)    : acc.Industry;
                if(!String.isBlank(cliente.CIIU)){
                    if(datosMaestrosMap.containsKey(cliente.CIIU)){
                        acc.Industry = datosMaestrosMap.get(cliente.CIIU);
                    }else{
                        resWrapper.errors.add('Error Code: ACTIVIDAD ECONOMICA NO EXISTE. Fields: (Industry). Message: Actividad Economica no existente');
                    }
                }
                if(!mpEmailUserid.containsKey(cliente.ejecutivo)){
                    resWrapper.errors.add('Error Code: EL CORREO DEL EJECUTIVO NO EXISTE. Fields: (OwnerId). Message: CORREO DEL EJECUTIVO NO EXISTE');
                }
            }
        }

        List<Database.SaveResult> sr = Database.update(accounts.values(), false);
        for(Database.SaveResult r: sr){
            if(!r.isSuccess()){
                for(Database.Error err : r.getErrors()) {
                    resWrapper.errors.add('Error Code: '+err.getStatusCode()+'. Fields: '+err.getFields()+'.Message: '+err.getMessage());
                }
            }
        }

        if(resWrapper.errors.isEmpty()){
            res.StatusCode = 200;
        }else if(res.statusCode == null){
            res.StatusCode = 202;
        }
        resWrapper.message = RES_STATUS.get(res.StatusCode);
        res.responseBody   = Blob.valueOf(JSON.serialize(resWrapper));
    }

    private static Set<String> getEstadoPickListValues(){

        Set<String> estadosDisponibles= new Set<String>();
        List<Schema.PicklistEntry> estadosPE = Account.ACC_Estado__c.getDescribe().getPicklistvalues();

        for(Schema.PicklistEntry pe : estadosPE){
            estadosDisponibles.add(pe.getValue());
        }

        return estadosDisponibles;
    }

    private static Set<String> getSegmentoPickListValues(){

        Set<String> segmentoDisponibles= new Set<String>();
        List<Schema.PicklistEntry> segmentoPE = Account.ACC_Segmento__c.getDescribe().getPicklistvalues();

        for(Schema.PicklistEntry p : segmentoPE){
            segmentoDisponibles.add(p.getValue());
        }

        return segmentoDisponibles;
    }

    private static Map<String,Id> getDatosMaestrosByDireccion(){

        Map<String,Id> mapDM = new Map<String,Id>();

        for(List<Datos_Maestros__c> listDM : [SELECT Id, DM_Direccion__c FROM Datos_Maestros__c]){
            for(Datos_Maestros__c dm : listDM){
                mapDM.put(dm.DM_Direccion__c, dm.Id);
            }
        }

        return mapDM;
    }

    global class ClienteDTO{
        public String CIF;
        public String CIIU;
        public String estado;
        public String ejecutivo;
        public String segmento;
    }

    global class ResponseWrapper{
        String message;
        List<String> errors;

        global ResponseWrapper(){
            this.errors= new List<String>();
        }
    }
}