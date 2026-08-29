/**
* @description       :
* @author            : Luis Naranjo
* @group             :
* @last modified on  : 08-07-2023
* @last modified by  : Luis Naranjo
**/
public class ConsultaDatacreditoFlowController {

    public static final string Cedula = 'Cédula';
    public static final string RNC = 'RNC';
    public static final string Pasaporte = 'Pasaporte';
    
    public class FlowInputs {
        @InvocableVariable public Account account;
        @InvocableVariable public Opportunity opportunity;
        @InvocableVariable public Historial_laboral__c history;
        @InvocableVariable public Informacion_Financiera__c infoFinanciera;
        @InvocableVariable public Datos_Maestros__c actividadEconomica;
        @InvocableVariable public Boolean isAsync;
    }
    
    public class FlowOutputs {
        @InvocableVariable public string dictamen;
        @InvocableVariable public String mensaje;
        @InvocableVariable public string error;
        @InvocableVariable public Integer xcore;
    }

    @InvocableMethod( label='Consultar Prestamo' description='Consulta DataCredito (Calificar Cliente)')
    public static List<FlowOutputs> qualify(FlowInputs[] toQualify) {

        try {    

            FlowOutputs[] responses = new List<FlowOutputs>();
            FlowOutputs fo = new FlowOutputs();

            for (FlowInputs record : toQualify) {                
                // Validar si los campos de Solo para Vehiculos estan diligenciados
                if (isEmpty(record.opportunity.OPP_VehTime__c) ||
                    isEmpty(record.opportunity.OPP_VehPrice__c) ||
                    isEmpty(record.opportunity.OPP_VehType__c) ||
                    isEmpty(record.opportunity.OPP_VehValue__c) ) {

                    String body = createBody(record, true);
                    if (record.isAsync) {
                        if (System.IsBatch() == false && System.isFuture() == false) {
                            consultaPrestamoConsumoAsync(body, record.opportunity.Id);                            
                        }
                    }else {
                        fo = REST_WebService.consultaPrestamoConsumo(body);
                        if (fo != null) {
                            responses.add(fo);                            
                        }
                    }
                }else {
                    String body = createBody(record, false);
                    if (record.isAsync) {
                        consultaPrestamoVehiculoAsync(body, record.opportunity.Id);
                    }else {
                        fo = REST_WebService.consultaPrestamoVehiculo(body);
                        if (fo != null) {
                            responses.add(fo);
                        }
                    }
                }
            }
            return responses;
        } catch (System.FlowException e) { 
            throw new HandledException(e.getMessage());
        }
    }

    @future(callout=true)
    public static void consultaPrestamoConsumoAsync(string body, Id oppId){
        FlowOutputs fo = REST_WebService.consultaPrestamoConsumo(body);
        if (fo != null) {
            saveResult(fo, oppId);            
        }
    }

    @future(callout=true)
    public static void consultaPrestamoVehiculoAsync(string body, Id oppId){
        FlowOutputs fo = REST_WebService.consultaPrestamoVehiculo(body);
        if (fo != null) {
            saveResult(fo, oppId);            
        }
    }

    private static void saveResult(FlowOutputs output, Id oppId) {
        Opportunity opp = new Opportunity(Id = oppId);
        opp.Dictamen__c = output.dictamen;
        opp.Razon_Decision__c = output.mensaje;
        opp.Opp_xcore__c = output.xcore;

        if (opp.Dictamen__c == 'Rechazado') {
            opp.StageName = 'Closed Lost';
        }else {
            opp.StageName = 'Solicitud de información';
        }

        update opp;        
    }
    
    public static String createBody(FlowInputs input, Boolean isConsumo){
        wpConsultaDatacredito body = new wpConsultaDatacredito();
        body.id = input.account.ACC_NumIdentificacion__c;

        if (Cedula.equals(input.account.ACC_TipoIdentificacion__c)) {
            body.idType = 'C';    
        }else if (RNC.equals(input.account.ACC_TipoIdentificacion__c)) {
            body.idType = 'R';    
        }else if (Pasaporte.equals(input.account.ACC_TipoIdentificacion__c)) {
            body.idType = 'P';    
        }        

        // Si el empleado es publico o probado -> 1 Asalariado
        if (input.history.Tipo_de_empleado__c == '1' || input.history.Tipo_de_empleado__c == '2') {
            body.asalaried = '1';                
        }else {
            body.asalaried = '0';
        }

        body.workingTime = input.history.Tiempo_de_empresa__c;
        body.sibClassification = input.actividadEconomica.DM_Direccion__c;
        body.loanAmount = input.opportunity.Monto__c.toPlainString();
        body.loanTerm = input.opportunity.Plazo__c.toPlainString();
        body.loanRate = input.opportunity.Tasa__c.toPlainString();

        if (isConsumo) {
            body.income = String.valueOf(input.history.Salario__c);
        }else {
            body.totalIncome = String.valueOf(input.history.Salario__c);      
            body.sourceIncome = String.valueOf(input.infoFinanciera.INF_INT_Origen_de_los_recursos__c);
            body.vehValue = input.opportunity.OPP_VehValue__c.toPlainString();
            body.vehPrice = input.opportunity.OPP_VehPrice__c.toPlainString();
            body.vehType = input.opportunity.OPP_VehType__c;
            body.vehTime = input.opportunity.OPP_VehTime__c.toPlainString();
        }
        return JSON.serialize(body);
    }

    private static Boolean isEmpty(String value){
        return value == null || value.trim() == '';
    }

    private static Boolean isEmpty(Decimal value){
        return isEmpty(String.valueOf(value));
    }

    
    public class wpConsultaDatacredito{

        // Credito de consumo
        public string id;
        public string idType;
        public string productType;
        public string asalaried;
        public string income;
        public string workingTime;
        public string sibClassification;
        public string loanAmount;
        public string loanRate;
        public string loanTerm;

        // Credito de vehiculo
        public string sourceIncome;
        public string totalIncome;
        public string vehValue;
        public string vehPrice;
        public string vehType;
        public string vehTime;

        public wpConsultaDatacredito(){
            this.id = '';
            this.idType = '';
            this.productType = '1';
            this.asalaried = '';
            this.income = '';
            this.workingTime = '';
            this.sibClassification = '';
            this.loanAmount = '';
            this.loanRate = '';
            this.loanTerm = '';
            this.sourceIncome = '';
            this.totalIncome = '';
            this.vehValue = '';
            this.vehPrice = '';
            this.vehType = '';
            this.vehTime = '';
        }
    }        
}