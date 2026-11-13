public without sharing class FSC_ContratoIntervinienteService {
    public static final String TIPO_CODEUDOR = 'Co-Deudor';
    public static final String TIPO_GARANTE = 'Garante';

    public class Interviniente {
        public Integer indice { get; set; }
        public String nombre { get; set; }
        public String identificacion { get; set; }
        public String nacionalidad { get; set; }
        public String estadoCivil { get; set; }
        public String domicilio { get; set; }
        public String sexo { get; set; }
        public String generales { get; set; }
    }

    public static Map<String, Object> parse(String jsonValue) {
        if (String.isBlank(jsonValue)) return new Map<String, Object>();
        try {
            return (Map<String, Object>) JSON.deserializeUntyped(jsonValue);
        } catch (Exception ignored) {
            return new Map<String, Object>();
        }
    }

    public static List<Interviniente> getApplicants(
        Id rlaId,
        String applicantType,
        String keyPrefix,
        Map<String, Object> values,
        Boolean ensureOne
    ) {
        List<LoanApplicant> applicants = [
            SELECT
                Id,
                Name,
                FSC_Nombre__c,
                FSC_PrimerApellido__c,
                FSC_SegundoApellido__c,
                FSC_NumIdentificacion__c,
                FSC_Nacionalidad__c,
                FSC_EstadoCivil__c,
                (SELECT Street, City, State, Country FROM Contact_Point_Addresses__r ORDER BY CreatedDate ASC, Id ASC LIMIT 1)
            FROM LoanApplicant
            WHERE LoanApplicationId = :rlaId AND FSC_TipoSolicitante__c = :applicantType
            ORDER BY CreatedDate ASC, Id ASC
        ];

        List<Interviniente> result = new List<Interviniente>();
        Integer count = applicants.isEmpty() && ensureOne == true ? 1 : applicants.size();
        for (Integer index = 0; index < count; index++) {
            LoanApplicant applicant = applicants.isEmpty() ? null : applicants[index];
            String prefix = keyPrefix + String.valueOf(index) + '_';
            Interviniente item = new Interviniente();
            item.indice = index;
            item.nombre = first(stored(values, prefix + 'nombre'), applicantName(applicant));
            item.identificacion = first(stored(values, prefix + 'identificacion'), applicant == null ? null : applicant.FSC_NumIdentificacion__c);
            item.nacionalidad = first(stored(values, prefix + 'nacionalidad'), applicant == null ? null : applicant.FSC_Nacionalidad__c);
            item.estadoCivil = first(stored(values, prefix + 'estadoCivil'), applicant == null ? null : applicant.FSC_EstadoCivil__c);
            item.domicilio = first(stored(values, prefix + 'domicilio'), applicantAddress(applicant));
            item.sexo = stored(values, prefix + 'sexo');
            item.generales = buildGenerales(item);
            result.add(item);
        }
        return result;
    }

    public static Interviniente getConyuge(Id accountId, Map<String, Object> values) {
        Account spouse = findSpouse(accountId);
        Interviniente item = new Interviniente();
        item.indice = 0;
        item.nombre = first(stored(values, 'conyuge_nombre'), spouse == null ? null : spouse.Name);
        item.identificacion = first(stored(values, 'conyuge_identificacion'), spouse == null ? null : spouse.ACC_NumIdentificacion__c);
        item.nacionalidad = first(stored(values, 'conyuge_nacionalidad'), spouse == null ? null : spouse.ACC_Nacionalidad__c);
        item.estadoCivil = first(stored(values, 'conyuge_estadoCivil'), spouse == null ? null : spouse.ACC_Estado_Civil__c);
        item.domicilio = first(stored(values, 'conyuge_domicilio'), spouse == null ? null : accountAddress(spouse));
        item.sexo = stored(values, 'conyuge_sexo');
        item.generales = buildGenerales(item);
        return item;
    }

    public static Interviniente fromPrimaryAccount(
        String name,
        String identification,
        String nationality,
        String civilStatus,
        String address
    ) {
        return fromPrimaryAccount(name, identification, nationality, civilStatus, address, null);
    }

    public static Interviniente fromPrimaryAccount(
        String name,
        String identification,
        String nationality,
        String civilStatus,
        String address,
        String sex
    ) {
        Interviniente item = new Interviniente();
        item.indice = -1;
        item.nombre = name;
        item.identificacion = identification;
        item.nacionalidad = nationality;
        item.estadoCivil = civilStatus;
        item.domicilio = address;
        item.sexo = sex;
        item.generales = buildGenerales(item);
        return item;
    }

    public static String joinGenerales(List<Interviniente> people) {
        List<String> values = new List<String>();
        for (Interviniente person : people) {
            if (!String.isBlank(person.generales)) values.add(person.generales);
        }
        return joinWithLast(values);
    }

    public static List<String> sexes(List<Interviniente> people) {
        List<String> values = new List<String>();
        for (Interviniente person : people) values.add(person.sexo);
        return values;
    }

    public static String joinNames(List<Interviniente> people) {
        List<String> values = new List<String>();
        for (Interviniente person : people) {
            if (!String.isBlank(person.nombre)) values.add(person.nombre);
        }
        return joinWithLast(values);
    }

    public static Boolean isApplicant(Id rlaId, String identification) {
        if (String.isBlank(identification)) return false;
        Integer applicantCount = [
            SELECT COUNT()
            FROM LoanApplicant
            WHERE LoanApplicationId = :rlaId AND FSC_NumIdentificacion__c = :identification
        ];
        return applicantCount > 0;
    }

    private static Account findSpouse(Id accountId) {
        if (accountId == null) return null;
        Account holder = [SELECT Id, PersonContactId FROM Account WHERE Id = :accountId LIMIT 1];
        if (holder.PersonContactId == null) return null;
        List<AccountContactRelation> relations = [
            SELECT AccountId
            FROM AccountContactRelation
            WHERE ContactId = :holder.PersonContactId
                AND Tipo_de_relacion__c = 'Familiar'
                AND Parentesco__c = 'Cónyuge'
            ORDER BY CreatedDate ASC, Id ASC
            LIMIT 1
        ];
        if (relations.isEmpty()) return null;
        List<Account> spouses = [
            SELECT
                Id,
                Name,
                ACC_NumIdentificacion__c,
                ACC_Nacionalidad__c,
                ACC_Estado_Civil__c,
                BillingStreet,
                BillingCity,
                BillingState,
                BillingCountry
            FROM Account
            WHERE Id = :relations[0].AccountId
            LIMIT 1
        ];
        return spouses.isEmpty() ? null : spouses[0];
    }

    private static String buildGenerales(Interviniente item) {
        if (item == null || String.isBlank(item.nombre)) return '';
        return item.nombre + ', de nacionalidad ' + item.nacionalidad + ', mayor de edad, estado civil ' +
            item.estadoCivil + ', ' + FSC_ContratoRedaccionService.concordar('portador', item.sexo) +
            ' del documento de identidad No. ' + item.identificacion + ', ' +
            FSC_ContratoRedaccionService.concordar('domiciliado', item.sexo) + ' y residente en ' + item.domicilio;
    }

    private static String applicantName(LoanApplicant applicant) {
        if (applicant == null) return '';
        List<String> parts = new List<String>();
        for (String value : new List<String>{ applicant.FSC_Nombre__c, applicant.FSC_PrimerApellido__c, applicant.FSC_SegundoApellido__c }) {
            if (!String.isBlank(value)) parts.add(value.trim());
        }
        return parts.isEmpty() ? applicant.Name : String.join(parts, ' ');
    }

    private static String applicantAddress(LoanApplicant applicant) {
        if (applicant == null || applicant.Contact_Point_Addresses__r == null || applicant.Contact_Point_Addresses__r.isEmpty()) return '';
        ContactPointAddress address = applicant.Contact_Point_Addresses__r[0];
        return joinAddress(address.Street, address.City, address.State, address.Country);
    }

    private static String accountAddress(Account account) {
        return joinAddress(account.BillingStreet, account.BillingCity, account.BillingState, account.BillingCountry);
    }

    private static String joinAddress(String street, String city, String state, String country) {
        List<String> parts = new List<String>();
        for (String value : new List<String>{ street, city, state, country }) {
            if (!String.isBlank(value)) parts.add(value.trim());
        }
        return String.join(parts, ', ');
    }

    private static String stored(Map<String, Object> values, String key) {
        return values != null && values.containsKey(key) && values.get(key) != null ? String.valueOf(values.get(key)).trim() : '';
    }

    private static String first(Object firstValue, Object secondValue) {
        String firstText = firstValue == null ? '' : String.valueOf(firstValue).trim();
        return String.isBlank(firstText) ? (secondValue == null ? '' : String.valueOf(secondValue).trim()) : firstText;
    }

    private static String joinWithLast(List<String> values) {
        if (values.isEmpty()) return '';
        if (values.size() == 1) return values[0];
        String lastValue = values.remove(values.size() - 1);
        return String.join(values, '; ') + '; y ' + lastValue;
    }
}