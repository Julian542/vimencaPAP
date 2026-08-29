public class VFS_nResumenConvenioUnicoController {

    // NUEVO: Se corrige el nombre para que coincida con el uso en el constructor (antes estaba AccountId y se usaba accountId)
    public Id accountId { get; set; }

    public Account cuenta { get; set; }

    // Direccion__c / Vias_de_Contacto__c ya no se usan (modelo viejo).
    // Se sustituyen por Contact Points (ContactPointAddress / ContactPointEmail).
    public ContactPointAddress direccion { get; set; }
    public String direccionFormateada { get; set; }
    public ContactPointEmail via { get; set; }

    // Participante__c se sustituye por AccountAccountRelation (AAR)
    public AccountAccountRelation representanteLegal { get; set; }

    public String diaActual { get; set; }
    public String mesActual { get; set; }
    public String anioActual { get; set; }

    public VFS_nResumenConvenioUnicoController(ApexPages.StandardController std) {
        inicializarFechaActual();
        accountId = std.getId();

        //Datos de cuenta
        cuenta = [
            SELECT Id, ACC_NumIdentificacion__c, IsPersonAccount, PersonContactId, MiddleName, Name,
                   ACC_NumOficina__c, ACC_CIF__c, OwnerId, Owner.Name, VFS_ActividadEconomica__c, VFS_EspecifiqueOtro__c
            FROM Account
            WHERE Id = :accountId
        ];

        // Representante Legal desde AccountAccountRelation (antes Participante__c)
        List<AccountAccountRelation> representantesLegales = [
            SELECT Id,
                   AccountId,
                   RelatedAccountId,
                   RelatedAccount.Name,
                   RelatedAccount.ACC_NumIdentificacion__c,
                   RelatedAccount.Lugar_de_nacimiento_Padron_Electoral__c,
                   AAR_Porcentaje__c
            FROM AccountAccountRelation
            WHERE AccountId = :accountId
              AND AAR_FirmanteDeContratoAutorizado__c = true
            ORDER BY AAR_Porcentaje__c DESC
            LIMIT 1
        ];

        System.debug('RepresentantesLegales contrato unico ' + representantesLegales);

        if (!representantesLegales.isEmpty()) {
            representanteLegal = representantesLegales[0];
        } else {
            representanteLegal = new AccountAccountRelation();
            direccion = new ContactPointAddress(); // NUEVO
            via = new ContactPointEmail();         // NUEVO
        }

        // Determina sobre qué Account consultar Contact Points (persona física: la misma; jurídico: el RelatedAccount del firmante)
        Id idCuentaParaDireccion;
        if (cuenta.IsPersonAccount) {
            idCuentaParaDireccion = cuenta.Id;
        } else {
            // NUEVO: antes era representanteLegal.Participante__c, ahora es RelatedAccountId
            if (representanteLegal != null && representanteLegal.RelatedAccountId != null) {
                idCuentaParaDireccion = representanteLegal.RelatedAccountId;
            }
        }

        // Dirección desde ContactPointAddress (antes Direccion__c)
        // Se prioriza IsPrimary = true, y si no existe, se toma la más reciente.
        List<ContactPointAddress> direcciones = [
            SELECT Id, ParentId, Street, City, State, PostalCode, Country, AddressType, IsPrimary, CreatedDate
            FROM ContactPointAddress
            WHERE ParentId = :idCuentaParaDireccion
              AND AddressType = 'RESIDENCIA'
            ORDER BY IsPrimary DESC, CreatedDate DESC
            LIMIT 1
        ];

        if (!direcciones.isEmpty()) {
            direccionFormateada = getDireccionJuridicaFormateada(direcciones);
            direccion = direcciones[0];
        } else {
            direccion = new ContactPointAddress();
            direccionFormateada = '';
        }
        System.debug('Direccion Convenio unico ' + direccion);

        // Correo desde ContactPointEmail (antes Vias_de_Contacto__c)
        List<ContactPointEmail> viasEmail = [
            SELECT Id, ParentId, EmailAddress, IsPrimary, CreatedDate
            FROM ContactPointEmail
            WHERE ParentId = :idCuentaParaDireccion
              AND (IsPrimary = true OR EmailAddress != null)
            ORDER BY IsPrimary DESC, CreatedDate DESC
            LIMIT 1
        ];

        if (!viasEmail.isEmpty()) {
            via = viasEmail[0];
        } else {
            via = new ContactPointEmail();
        }
        System.debug('via Convenio unico ' + via);
    }

    // Ajustado a ContactPointAddress (antes Direccion__c)
    public String getDireccionJuridicaFormateada(List<ContactPointAddress> direcciones) {
        if (direcciones == null || direcciones.isEmpty() || direcciones[0] == null) {
            return '';
        }
        ContactPointAddress dir = direcciones[0];

        List<String> partes = new List<String>();
        if (!String.isBlank(dir.Street)) partes.add(dir.Street);
        if (!String.isBlank(dir.City)) partes.add(dir.City);
        if (!String.isBlank(dir.State)) partes.add(dir.State);
        if (!String.isBlank(dir.PostalCode)) partes.add(dir.PostalCode);
        if (!String.isBlank(dir.Country)) partes.add(dir.Country);

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