/**
* @description       :
* @author            : Luis Naranjo
* @group             :
* @last modified on  : 14-04-2023
* @last modified by  : 
**/
public class ValidatePreQualifyFlowController {

    public class FlowInputs {
        @InvocableVariable public Account account;
        @InvocableVariable public Historial_laboral__c history;
        @InvocableVariable public Participante__c accionista;
        @InvocableVariable public Participante__c representante;
        @InvocableVariable public Informacion_Financiera__c infoFinanciera;
    }
    
    public class FlowValidateOutputs {
        @InvocableVariable public String invalidField;
        @InvocableVariable public Boolean ok;

        public FlowValidateOutputs(){
            invalidField = '';
            ok = false;
        }
    }
    
    @InvocableMethod( label='ValidatePrequalify' description='allows us to validate data to prequalify')
    public static List<FlowValidateOutputs> validatePrequalify(FlowInputs[] data) {
        try {

            FlowValidateOutputs[] responses = new List<FlowValidateOutputs>();
            FlowValidateOutputs response = new FlowValidateOutputs();

            for (FlowInputs record : data) {

                Account cliente = record.account;
                Participante__c accionista = record.accionista;
                Participante__c representante = record.representante;
                Informacion_Financiera__c infFinan = record.infoFinanciera;
                Historial_laboral__c history = record.history;

                Account clienteTrama = [SELECT 
                        tolabel(ACC_INT_Tipo_de_identificacion__c),
                        tolabel(ACC_INT_Nacionalidad__c),
                        tolabel(ACC_INT_Pais_Nacimiento__c),
                        tolabel(ACC_INT_Pais_Residencia_Legal__c),
                        tolabel(ACC_INT_Canales_a_utilizar__c),
                        tolabel(ACC_INT_Tipo_Estructura_Juridica__c)
                    from Account where id =: cliente.Id];

                Informacion_Financiera__c infFinanTrama = [Select 
                        tolabel(INF_INT_Origen_de_los_recursos__c)
                    from Informacion_Financiera__c where Id =: infFinan.Id
                ];

                //*********************************//
                //* Campos requeridos cliente N/J *//
                //*********************************//
                
                // ACRM - Código de Empresa (0001 por default)
                
                // ACRM - Tipo ID+Número de Identificación
                if (cliente.ACC_TipoIdentificacion__c == null || clienteTrama.ACC_INT_Tipo_de_identificacion__c == null){
                    response.invalidField += 'Tipo de Identificación, \n';
                }else {
                    if (clienteTrama.ACC_INT_Tipo_de_identificacion__c == '1') {		
                        if(cliente.ACC_NumIdentificacion__c == null){
                            response.invalidField += 'Cédula, \n';
                        }
                    } else if (clienteTrama.ACC_INT_Tipo_de_identificacion__c == '2') {
                        if(cliente.ACC_NumIdentificacion__c == null){
                            response.invalidField += 'Pasaporte, \n';
                        }
                    } else if (clienteTrama.ACC_INT_Tipo_de_identificacion__c == '3') {		
                        if(cliente.ACC_RNC__c == null){
                            response.invalidField += 'R.N.C., \n';
                        }             
                    }
                }

                // ACRM - Maneja Depósito EFECTIVO 
                // (unchecked por default)

                // ACRM - Maneja Op. Internacionales 
                // (unchecked por default)

                // ACRM - Código de cliente 
                // if (cliente.ACC_CIF__c == null) {
                //     response.invalidField += 'Código de Cliente (C.I.F), \n';
                // }

                // ACRM - Control de Pre vinculación
                // ('S' por default)

                // ACRM - Fecha Proceso
                // (Current time por default)
                
                // ACRM - Prev Numero Referencia
                // (Salesforce ID por default)

                // ACRM - Fecha de Nacimiento/Constitución
                if ((cliente.IsPersonAccount && cliente.PersonBirthdate == null) || (!cliente.IsPersonAccount && cliente.ACC_Fecha_Fundacion__c == null)){
                    response.invalidField += 'Fecha de Nacimiento/Constitución, \n';
                }

                // ACRM - Nacionalidad/Constitución
                if (cliente.ACC_Nacionalidad__c == null || clienteTrama.ACC_INT_Nacionalidad__c == null) {
                    response.invalidField += 'Nacionalidad/Constitución, \n';
                }

                // ACRM - Sucursal apertura
                if (cliente.ACC_INT_NumOficina__c == null) {
                    response.invalidField += 'Sucursal Apertura, \n';
                }

                // ACRM - Código de Ejecutivo - Oficial
                if (cliente.Owner_Alias__c == null) {
                    response.invalidField += 'Código de Ejecutivo - Oficial, \n';
                }

                // ACRM - Promedio ingreso mensual
                if (cliente.ACC_Total_Activos__c == null) {
                    response.invalidField += 'Promedio Ingreso Mensual, \n';
                }
                
                // ACRM - Rango promedio ingreso mensual
                if (infFinan.INF_Ingresos__c == null || infFinan.INF_Ingresos__c == null) {
                    response.invalidField += 'Rango Promedio Ingreso Mensual, \n';
                }

                // ACRM - Promedio ventas mensual
                if (cliente.ACC_Ventas_Ingresos_Anuales__c == null) {
                    response.invalidField += 'Promedio Ventas Mensual, \n';
                }

                // ACRM - Rango promedio ventas mensual
                // (Desconocido en Salesforce)

                // ACRM - Tipo de Persona   N-J
                if (cliente.ACC_INT_TipoPersona__c == null) {
                    response.invalidField += 'Tipo de Persona, \n';
                }

                // ACRM - Codigo Producto a Solicitar - 01
                if (cliente.ACC_ProductosASolicitar__c == null) {
                    response.invalidField += 'Codigo Producto a Solicitar 01, \n';
                }

                // ACRM - Código de Actividad Económica
                if (cliente.ACC_Actividad_Economica__c == null) {
                    response.invalidField += 'Código de Actividad Económica, \n';
                }

                // ACRM - Origen de los recursos
                if (infFinanTrama.INF_INT_Origen_de_los_recursos__c == null || infFinan.INF_Fuente_de_ingresos__c == null) {
                    response.invalidField += 'Origen de los Recursos, \n';
                }

                // ACRM - Codigo Servicio a Solicitar - 01
                if (cliente.ACC_Servicios_a_solicitar__c == null) {
                    response.invalidField += 'Codigo Servicio a Solicitar 01, \n';
                }

                // ACRM - Codigo Canal a Utilizar - 01
                if (cliente.ACC_Canales_a_utilizar__c == null || cliente.ACC_INT_Canales_a_utilizar__c == null) {
                    response.invalidField += ' Codigo Canal a Utilizar 01, \n';
                }

                // ACRM - Tipo de Beneficiario Final (CJ)
                if (cliente.ACC_Tipo_beneficio_final__c == null) {
                    response.invalidField += 'Tipo de Beneficiario Final (CJ), \n';
                }

                // ACRM - Relación de dignatarios
                if (cliente.ACC_Relacion_de_dignatarios__c == null) {
                    response.invalidField += 'Relación de Dignatarios, \n';
                }                

                // ACRM - GUID 
                // ( Vacio por default )

                
                //*********************************//
                //* Campos requeridos cliente F   *//
                //*********************************//

                if (cliente.ACC_Persona_Fisica__c){

                    Historial_laboral__c historyTrama = [Select 
                            tolabel(HIS_INT_Prefesion_u_Oficio__c)
                        from Historial_laboral__c where Id = :history.Id
                    ];


                    // ACRM - Primer nombre
                    if (cliente.firstName == null) {
                        response.invalidField += 'Primer nombre, \n';
                    }

                    // ACRM - Segundo nombre
                    // if (cliente.middleName == null) {
                    //     response.invalidField += 'Segundo nombre, \n';
                    // }

                    // ACRM - Primer apellido
                    if (cliente.LastName == null) {
                        response.invalidField += 'Primer apellido, \n';
                    }

                    // ACRM - Segundo apellido
                    // if (cliente.Suffix == null) {
                    //     response.invalidField += 'Segundo apellido, \n';
                    // }

                    // ACRM - Pais de nacimiento
                    if (cliente.ACC_Pais_Nacimiento__c == null || clienteTrama.ACC_INT_Pais_Nacimiento__c == null) {
                        response.invalidField += 'País de Nacimiento, \n';
                    }

                    // ACRM - País Residencia
                    if (cliente.ACC_Pais_Residencia_Legal__c == null || clienteTrama.ACC_INT_Pais_Residencia_Legal__c == null) {
                        response.invalidField += 'País Residencia, \n';
                    }

                    // ACRM - Profesión u Oficio
                    if (history.HIS_Ocupacion__c == null || historyTrama.HIS_INT_Prefesion_u_Oficio__c == null) {
                        response.invalidField += 'Profesión u Oficio, \n';
                    }

                    // ACRM - Servidor Público PEP
                    if (cliente.ACC_Persona_PEP__c == null) {
                        response.invalidField += 'Servidor Público PEP, \n';
                    }

                    // ACRM - Familiar de PEP
                    // ( false por default)

                    // ACRM - Colaborador de PEP
                    // ( false por default)

                    // ACRM - Relación con la Institucion
                    // ( Vacio por default)

                }else {

                    //*********************************//
                    //* Campos requeridos cliente J   *//
                    //*********************************//

                    // ACRM - Nombre Persona/Razón Social
                    if (cliente.ACC_Nombre_Corto_Comercial__c == null) {
                        response.invalidField += 'Nombre Persona/Razón Social, \n';
                    }

                    // ACRM - Accionista 01
                    if (accionista.PAR_Nombres__c == null) {
                        response.invalidField += 'Accionista 01, \n';
                    }

                    // ACRM - Representante 01
                    if (representante.PAR_Nombres__c == null) {
                        response.invalidField += 'Representante Legal 01, \n';
                    }

                    // ACRM - Tipo Estructura Juridica
                    if (cliente.ACC_Tipo_Organizacion__c == null || cliente.ACC_INT_Tipo_Estructura_Juridica__c == null) {
                        response.invalidField += 'Tipo Estructura Juridica, \n';
                    }
                }
            }
            
            response.ok = (response.invalidField.length() == 0); 
            responses.add(response);
            return responses;
        } catch (System.FlowException e) { throw new HandledException(e.getMessage()); }
    }
}