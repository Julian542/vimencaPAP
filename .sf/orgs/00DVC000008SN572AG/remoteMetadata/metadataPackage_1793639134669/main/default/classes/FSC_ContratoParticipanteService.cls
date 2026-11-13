public with sharing class FSC_ContratoParticipanteService {
    public class Participante {
        @AuraEnabled public String nombreCompleto { get; set; }
        @AuraEnabled public String tratamiento { get; set; }
        @AuraEnabled public String cargo { get; set; }
        @AuraEnabled public String nacionalidad { get; set; }
        @AuraEnabled public String estadoCivil { get; set; }
        @AuraEnabled public String identificacion { get; set; }
        @AuraEnabled public String domicilio { get; set; }
        @AuraEnabled public String matriculaNotario { get; set; }
        @AuraEnabled public String jurisdiccionNotario { get; set; }
        @AuraEnabled public String lugarFirma { get; set; }

        private Participante(FSC_Participante_Contrato__mdt source) {
            nombreCompleto = source.FSC_Nombre_Completo__c;
            tratamiento = source.FSC_Tratamiento__c;
            cargo = source.FSC_Cargo__c;
            nacionalidad = source.FSC_Nacionalidad__c;
            estadoCivil = source.FSC_Estado_Civil__c;
            identificacion = source.FSC_Identificacion__c;
            domicilio = source.FSC_Domicilio__c;
            matriculaNotario = source.FSC_Matricula_Notario__c;
            jurisdiccionNotario = source.FSC_Jurisdiccion_Notario__c;
            lugarFirma = source.FSC_Lugar_Firma__c;
        }
    }

    public class ParticipantesContrato {
        @AuraEnabled public Participante representanteBanco1 { get; set; }
        @AuraEnabled public Participante representanteBanco2 { get; set; }
        @AuraEnabled public Participante notario { get; set; }
        @AuraEnabled public List<String> errores { get; set; }

        public ParticipantesContrato() {
            errores = new List<String>();
        }
    }

    public static ParticipantesContrato getParticipantes(String tipoContrato) {
        ParticipantesContrato result = new ParticipantesContrato();
        Map<String, FSC_Participante_Contrato__mdt> exactByRole = new Map<String, FSC_Participante_Contrato__mdt>();
        Map<String, FSC_Participante_Contrato__mdt> defaultByRole = new Map<String, FSC_Participante_Contrato__mdt>();

        for (FSC_Participante_Contrato__mdt item : FSC_Participante_Contrato__mdt.getAll().values()) {
            if (!item.FSC_Activo__c || String.isBlank(item.FSC_Rol__c)) continue;
            if (item.FSC_Tipo_Contrato__c == tipoContrato) exactByRole.put(item.FSC_Rol__c, item);
            if (item.FSC_Tipo_Contrato__c == 'TODOS') defaultByRole.put(item.FSC_Rol__c, item);
        }

        result.representanteBanco1 = toParticipant(selectByRole('REPRESENTANTE_BANCO_1', exactByRole, defaultByRole));
        result.representanteBanco2 = toParticipant(selectByRole('REPRESENTANTE_BANCO_2', exactByRole, defaultByRole));
        result.notario = toParticipant(selectByRole('NOTARIO', exactByRole, defaultByRole));

        validateBankRepresentative(result.representanteBanco1, 'representante principal del Banco', result.errores);
        validateBankRepresentative(result.representanteBanco2, 'segundo representante del Banco', result.errores);
        if (result.notario == null || String.isBlank(result.notario.nombreCompleto) ||
            String.isBlank(result.notario.matriculaNotario) || String.isBlank(result.notario.jurisdiccionNotario) ||
            String.isBlank(result.notario.lugarFirma)) {
            result.errores.add('Falta configurar el notario activo en FSC_Participante_Contrato__mdt.');
        }
        return result;
    }

    private static FSC_Participante_Contrato__mdt selectByRole(
        String role,
        Map<String, FSC_Participante_Contrato__mdt> exactByRole,
        Map<String, FSC_Participante_Contrato__mdt> defaultByRole
    ) {
        return exactByRole.containsKey(role) ? exactByRole.get(role) : defaultByRole.get(role);
    }

    private static Participante toParticipant(FSC_Participante_Contrato__mdt source) {
        return source == null ? null : new Participante(source);
    }

    private static void validateBankRepresentative(Participante item, String label, List<String> errors) {
        if (item == null || String.isBlank(item.nombreCompleto) || String.isBlank(item.cargo) ||
            String.isBlank(item.nacionalidad) || String.isBlank(item.estadoCivil) ||
            String.isBlank(item.identificacion) || String.isBlank(item.domicilio)) {
            errors.add('Falta configurar el ' + label + ' en FSC_Participante_Contrato__mdt.');
        }
    }
}