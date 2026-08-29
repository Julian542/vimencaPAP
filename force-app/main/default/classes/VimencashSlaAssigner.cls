public with sharing class VimencashSlaAssigner {

    public static final String ENTITLEMENT_NAME_CANCELACIONES = 'Cancelaciones Vimencash';
    public static final String RT_DEVNAME_CANCELACIONES = 'Cancelaciones_Vimencash';

    public static void applySlaIfNeeded(Case c) {

        System.debug('on VimencashSlaAssigner.applySlaIfNeeded(c=' + (c != null ? c.Id : null) + ')');

        try {
            if (c == null) return;

            // Si ya viene con entitlement, no lo sobreescribimos
            if (c.EntitlementId != null) {
                System.debug('Case ya tiene EntitlementId: ' + c.EntitlementId);
                return;
            }

            // Validación por RecordType DeveloperName
            String rtDevName = getRecordTypeDeveloperName(c.RecordTypeId);
            System.debug('RecordType DeveloperName: ' + rtDevName);

            if (rtDevName != RT_DEVNAME_CANCELACIONES) {
                System.debug('No aplica SLA: RecordType distinto a ' + RT_DEVNAME_CANCELACIONES);
                return;
            }

            // Buscar Entitlement por nombre
            Entitlement ent = getEntitlementByName(ENTITLEMENT_NAME_CANCELACIONES);
            if (ent == null) {
                System.debug(LoggingLevel.WARN, 'No se encontró Entitlement con Name=' + ENTITLEMENT_NAME_CANCELACIONES);
                return;
            }

            c.EntitlementId = ent.Id;
            System.debug('Entitlement asignado al Case: ' + ent.Id);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'ERROR en applySlaIfNeeded: ' + e.getMessage() + ' | ' + e.getStackTraceString()
            );
            // No lanzamos excepción para no romper la creación del caso.
        }
    }

    private static String getRecordTypeDeveloperName(Id recordTypeId) {

        System.debug('on VimencashSlaAssigner.getRecordTypeDeveloperName(recordTypeId=' + recordTypeId + ')');

        try {
            if (recordTypeId == null) return null;

            RecordType rt = [
                SELECT DeveloperName
                FROM RecordType
                WHERE Id = :recordTypeId
                LIMIT 1
            ];
            return rt.DeveloperName;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'ERROR en getRecordTypeDeveloperName: ' + e.getMessage() + ' | ' + e.getStackTraceString()
            );
            return null;
        }
    }

    private static Entitlement getEntitlementByName(String entitlementName) {
        
        System.debug('on VimencashSlaAssigner.getEntitlementByName(entitlementName=' + entitlementName + ')');

        try {
            if (String.isBlank(entitlementName)) return null;

            System.debug('SOQL: Entitlement by Name');
            List<Entitlement> ents = [
                SELECT Id, Name
                FROM Entitlement
                WHERE Name = :entitlementName
                LIMIT 1
            ];
            return (ents.isEmpty()) ? null : ents[0];

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'ERROR en getEntitlementByName: ' + e.getMessage() + ' | ' + e.getStackTraceString()
            );
            return null;
        }
    }
}