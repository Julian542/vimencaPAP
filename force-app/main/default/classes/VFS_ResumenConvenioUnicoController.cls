/*****************************************************************************************************
* Nombre de clase apex   :   VFS_ResumenConvenioUnicoController
* Versión                :   1.0
* Fecha de creación      :   10/04/2025
* Función                :   Controlador para visualforce VFS_ContratoUnico.
* Clase de pruebas       :    VFS_ResumenConvenioUnicoTest
*
* Registro de modificaciones    
* ---------------------------------------------------------------------------------------------------
* Desarrollador                          Fecha                          Descripción
*  
* Carlos Ventura                         14-07-2025                 Versión original
******************************************************************************************************/
public class VFS_ResumenConvenioUnicoController {
    public Id AccountId { get; set; }
    public Account cuenta { get; set; }
    public Direccion__c direccion { get; set; }
    public String direccionFormateada { get; set; }
    public Vias_de_Contacto__c via { get; set; }
    public Participante__c representanteLegal { get; set; }
    public String diaActual { get; set; }
    public String mesActual { get; set; }
    public String anioActual { get; set; }
    
    public VFS_ResumenConvenioUnicoController(ApexPages.StandardController std) {
        inicializarFechaActual();
        accountId = std.getId();
        //Datos de cuenta
        cuenta = [
            SELECT Id, ACC_NumIdentificacion__c, isPersonAccount, PersonContactId, MiddleName ,Name, ACC_NumOficina__c, ACC_CIF__c, OwnerId, Owner.Name, VFS_ActividadEconomica__c, VFS_EspecifiqueOtro__c
            FROM Account 
            WHERE Id = :accountId
        ];

        List<Participante__c> RepresentantesLegales = [
            SELECT Name, Participante__r.Lugar_de_nacimiento_Padron_Electoral__c, Participante__r.ACC_NumIdentificacion__c, Participante__r.name, PAR_Porcentaje__c, PAR_Numero_Identificacion__c
            FROM Participante__c
            WHERE PAR_Cliente__c =: accountId AND VFS_FirmanteDeContratoAutorizado__c = true
            ORDER BY PAR_Porcentaje__c DESC
            LIMIT 1
        ];
        
       
        System.debug('RepresentantesLegales contrato unico'+ RepresentantesLegales);
        if(!RepresentantesLegales.isEmpty()){
            representanteLegal = RepresentantesLegales[0];
        }else{
            representanteLegal = new Participante__c();
            direccion = new Direccion__c();
            via = new Vias_de_Contacto__c();
        }
        
        String idCuentaParaDireccion = '';
        if(cuenta.IsPersonAccount){
            idCuentaParaDireccion = cuenta.Id;
        }else{
            if(representanteLegal.Participante__c != null){
                idCuentaParaDireccion = representanteLegal.Participante__c;
            }
        }
        
        List<Direccion__c> direcciones = [
        SELECT DIR_Account__c,DIR_Calle__c, DIR_Sector__r.Name, DIR_Numero__c, DIR_Edificio__c, DIR_Estado_Ciudad__c, DIR_Direccion_Traduccion__c, DIR_N_Apartamento__c, DIR_Distrito_texto__c, DIR_Municipio_texto__c, DIR_Provincia_texto__c, DIR_Pais_Texto__c, DIR_Pais__c
            FROM Direccion__c 
            WHERE DIR_Account__c = : idCuentaParaDireccion AND DIR_Tipo_Direccion__c = 'RESIDENCIA' AND DIR_Principal__c = true ORDER BY CreatedDate desc
            LIMIT 1
        ];
        if(!direcciones.isEmpty()){
            direccionFormateada = getDireccionJuridicaFormateada(direcciones);
            direccion = direcciones[0];
        }else{
            direccion = new Direccion__c();
        }
        System.debug('Direccion Convenio unico'+ direccion);
        
        List<Vias_de_Contacto__c> Vias = [
            SELECT VIA_Numero_Correo__c, VIA_de_Contacto__c 
            FROM Vias_de_Contacto__c 
            WHERE VIA_Account__c = :idCuentaParaDireccion AND VIA_de_Contacto__c = 'CORREO ELECTRÓNICO'
            LIMIT 1
        ];
        if(!Vias.isEmpty()){
            via = Vias[0];
        }else{
            via = new Vias_de_Contacto__c();
        }
        System.debug('via Convenio unico'+ direccion);
       
    }
    
    public String getDireccionJuridicaFormateada(List<Direccion__c> direcciones) {
        if (direcciones == null || direcciones.isEmpty() || direcciones[0] == null) {
            return '';
        }
        Direccion__c dir = direcciones[0];
        List<String> partes = new List<String>();
        if (!String.isBlank(dir.DIR_Calle__c)) {
            String calle = 'Calle ' + dir.DIR_Calle__c;
            if (!String.isBlank(dir.DIR_Numero__c)) {
                calle += ' No. ' + dir.DIR_Numero__c;
            }
            partes.add(calle);
        } else if (!String.isBlank(dir.DIR_Numero__c)) {
            partes.add('No. ' + dir.DIR_Numero__c);
        }
        if (!String.isBlank(dir.DIR_Edificio__c)) {
            partes.add('Edif. ' + dir.DIR_Edificio__c);
        }
        if (!String.isBlank(dir.DIR_N_Apartamento__c)) {
            partes.add('Apt. ' + dir.DIR_N_Apartamento__c);
        }
        if (!String.isBlank(dir.DIR_Sector__c)) {
            partes.add('Sector ' + dir.DIR_Sector__r.Name);
        }
        if (!String.isBlank(dir.DIR_Provincia_texto__c)) {
            partes.add('Provincia ' + dir.DIR_Provincia_texto__c);
        }
        return String.join(partes, ', ');
    }
    
    private void inicializarFechaActual() {
        Date hoy = Date.today();
        
        diaActual = String.valueOf(hoy.day());
        anioActual = String.valueOf(hoy.year());
        Integer mesNum = hoy.month();
        mesActual = obtenerNombreMes(mesNum);
    }
    private String obtenerNombreMes(Integer mes) {
        List<String> meses = new List<String>{
            'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
                'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
                };
                    if (mes >= 1 && mes <= 12) {
                        return meses[mes - 1];  // Restamos 1 porque la lista es 0-indexed
                    }
        return '';
    }
    
}