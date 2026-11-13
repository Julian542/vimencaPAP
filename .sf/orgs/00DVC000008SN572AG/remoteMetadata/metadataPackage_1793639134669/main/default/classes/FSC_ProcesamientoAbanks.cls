public without sharing class FSC_ProcesamientoAbanks {
    @TestVisible private static Boolean automatizacionTest;
    private static final String CUENTA = 'Cuenta de ahorro';

    public static Boolean habilitado() {
        if (automatizacionTest != null) return automatizacionTest;
        FSC_APIPrestamoConfig__mdt config = FSC_APIPrestamoConfig__mdt.getInstance('Default');
        return config != null && config.FSC_AutomatizarCreacionYDesembolso__c;
    }

    public static Boolean esCuentaManual(ResidentialLoanApplication rla) {
        return rla.FSC_FormaDeDesembolso__c == CUENTA &&
            (!habilitado() || rla.FSC_ProcesamientoAbanksManual__c == true);
    }

    public static void fijarModoManual(ResidentialLoanApplication rla) {
        if (rla.Status == 'En proceso' &&
            (rla.FSC_Subestado__c == 'Creación de crédito' || rla.FSC_Subestado__c == 'Desembolso') && esCuentaManual(rla)) {
            // El regreso de la API no cambia solicitudes que ya comenzaron manualmente.
            rla.FSC_ProcesamientoAbanksManual__c = true;
        }
    }

    // Se consulta en sistema para no exigir nuevos permisos de campo a los usuarios.
    public static Set<Id> habilitadas(Set<Id> solicitudesIds) {
        Set<Id> resultado = new Set<Id>();
        if (!habilitado() || solicitudesIds == null || solicitudesIds.isEmpty()) return resultado;
        for (ResidentialLoanApplication rla : [
            SELECT Id FROM ResidentialLoanApplication
            WHERE Id IN :solicitudesIds AND FSC_ProcesamientoAbanksManual__c = false
        ]) resultado.add(rla.Id);
        return resultado;
    }
}