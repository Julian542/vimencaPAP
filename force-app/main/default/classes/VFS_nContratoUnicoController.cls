/* Esta clase es un controlador de Visualforce para generar/mostrar el “Contrato Único” con datos del cliente en el modelo FSC.
 * 
 * @author: Jhonny Peroza
 * @last updated: 11-02-26
 */
public with sharing class VFS_nContratoUnicoController {

    public Id accountId { get; set; }
    public Account cuenta { get; set; }
    public ContactPointAddress direccion { get; set; }
    public String direccionFormateada { get; set; }
    public ContactPointEmail via { get; set; }

    // Ahora el representante legal viene desde FinServ__AccountAccountRelation__c
    public FinServ__AccountAccountRelation__c representanteLegalRel { get; set; }

    // Si necesitas seguir usando un Account "representanteLegal" en otras partes del VF, lo mantenemos poblado
    public Account representanteLegal { get; set; }

    public String diaActual { get; set; }
    public String mesActual { get; set; }
    public String anioActual { get; set; }

    // sin que intente resolverlo como AccountStandardController.viaDeContacto
    public ContactPointEmail getViaDeContacto() {
        return via;
    }

    public VFS_nContratoUnicoController(ApexPages.StandardController std) {

        inicializarFechaActual();

        accountId = std.getId();

        cuenta = [
            SELECT Id, PersonContactId, MiddleName, Name, ACC_NumOficina__c, ACC_CIF__c, OwnerId, Owner.Name,
                   VFS_ActividadEconomica__c, VFS_EspecifiqueOtro__c, IsPersonAccount
            FROM Account
            WHERE Id = :accountId
        ];

        representanteLegalRel = null;
        representanteLegal = new Account();
        direccion = new ContactPointAddress();
        via = new ContactPointEmail();
        direccionFormateada = '';

        // Obtiene la relación del representante legal (FinServ__AccountAccountRelation__c)
        FinServ__AccountAccountRelation__c repRel = getRepresentanteLegalRelacion(accountId);
        if (repRel != null && repRel.Id != null) {
            representanteLegalRel = repRel;

            // Poblamos también el Account, por compatibilidad con VF existente
            if (repRel.FinServ__RelatedAccount__c != null) {
                representanteLegal = [
                    SELECT Id, PersonContactId, Name, FirstName, LastName, MiddleName, Suffix,
                           Lugar_de_nacimiento_Padron_Electoral__c, ACC_NumIdentificacion__c, ACC_RNC__c, ACC_Nacionalidad__c,
                           ACC_Persona_PEP__c
                    FROM Account
                    WHERE Id = :repRel.FinServ__RelatedAccount__c
                    LIMIT 1
                ];
            }
        }

        // Decide de quién tomar la dirección y el email
        Id idCuentaParaDireccion;
        if (cuenta.IsPersonAccount) {
            idCuentaParaDireccion = cuenta.Id;
        } else {
            Id repId = (representanteLegalRel != null) ? representanteLegalRel.FinServ__RelatedAccount__c : null;
            idCuentaParaDireccion = (repId != null) ? repId : cuenta.Id;
        }

        // Dirección residencial principal
        List<ContactPointAddress> direcciones = [
            SELECT Id, ParentId, AddressType, IsPrimary, Street, City, State, PostalCode, Country, 
                   CPA_Distrito__c, CPA_N_Apartamento__c
            FROM ContactPointAddress
            WHERE ParentId = :idCuentaParaDireccion
              AND AddressType = 'RESIDENCIA'
              AND IsPrimary = true
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (!direcciones.isEmpty()) {
            direccion = direcciones[0];
            direccionFormateada = getDireccionJuridicaFormateada(direcciones);
        } else {
            direccion = new ContactPointAddress();
            direccionFormateada = '';
        }
        System.debug('Direccion contrato unico ' + direccion);

        // Email
        List<ContactPointEmail> vias = [
            SELECT Id, ParentId, EmailAddress, IsPrimary
            FROM ContactPointEmail
            WHERE ParentId = :idCuentaParaDireccion
              AND EmailAddress != null
            ORDER BY IsPrimary DESC, CreatedDate DESC
            LIMIT 1
        ];
        if (!vias.isEmpty()) {
            via = vias[0];
        } else {
            via = new ContactPointEmail();
        }
        System.debug('via contrato unico ' + via);
    }

    private FinServ__AccountAccountRelation__c getRepresentanteLegalRelacion(Id accId) {
        try {
            List<FinServ__AccountAccountRelation__c> rels = [
                SELECT Id,
                       FinServ__Account__c,
                       FinServ__RelatedAccount__c,
                       FinServ__RelatedAccount__r.Name,
                       FinServ__RelatedAccount__r.ACC_NumIdentificacion__c
                FROM FinServ__AccountAccountRelation__c
                WHERE FinServ__Account__c = :accId
                  AND FinServ__RelatedAccount__c != null
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            System.debug('RepresentanteLegal contrato unico (AAR) ' + rels);

            return (!rels.isEmpty()) ? rels[0] : null;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'ERROR getRepresentanteLegalRelacion: ' + e.getMessage() + ' | ' + e.getStackTraceString());
            return null;
        }
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
            return meses[mes - 1];
        }
        return '';
    }

    public String getDireccionJuridicaFormateada(List<ContactPointAddress> direcciones) {
        if (direcciones == null || direcciones.isEmpty() || direcciones[0] == null) {
            return '';
        }

        ContactPointAddress dir = direcciones[0];
        List<String> partes = new List<String>();

        if (!String.isBlank(dir.Street)) {
            partes.add(dir.Street);
        }
        if (!String.isBlank((String)dir.get('CPA_N_Apartamento__c'))) {
            partes.add('Apt. ' + String.valueOf(dir.get('CPA_N_Apartamento__c')));
        }
        if (!String.isBlank((String)dir.get('CPA_Distrito__c'))) {
            partes.add('Distrito ' + String.valueOf(dir.get('CPA_Distrito__c')));
        }
        if (!String.isBlank(dir.City)) {
            partes.add(dir.City);
        }
        if (!String.isBlank(dir.State)) {
            partes.add(dir.State);
        }
        if (!String.isBlank(dir.PostalCode)) {
            partes.add(dir.PostalCode);
        }
        if (!String.isBlank(dir.Country)) {
            partes.add(dir.Country);
        }

        return String.join(partes, ', ');
    }
}