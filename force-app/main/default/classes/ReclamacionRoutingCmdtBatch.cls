/*
ReclamacionRoutingCmdtBatch.runBatch(1);
ReclamacionRoutingCmdtBatch.runBatch(2);
ReclamacionRoutingCmdtBatch.runBatch(3);
ReclamacionRoutingCmdtBatch.runBatch(4);
ReclamacionRoutingCmdtBatch.runBatch(5);
ReclamacionRoutingCmdtBatch.runBatch(6);
ReclamacionRoutingCmdtBatch.runBatch(7);
*/
public with sharing class ReclamacionRoutingCmdtBatch {
    public static final Integer DEFAULT_BATCH_SIZE = 10;
    public static final String QUEUE_DEVOLUCION = 'Casos_Devolucion_Reclamaciones';
    public static final String QUEUE_ASIGNACION_MANUAL = 'Casos_Asignacion_Manual_Reclamaciones';

    public class ReclamacionRoutingDeployCallback implements Metadata.DeployCallback {
        public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
            System.debug(LoggingLevel.DEBUG,
                'ReclamacionRoutingDeployCallback.handleResult() status=' + result.status +
                ', errorMessage=' + result.errorMessage
            );

            if (String.isNotBlank(result.errorMessage)) {
                System.debug(LoggingLevel.ERROR,
                    'Error en deploy de CMDT: ' + result.errorMessage
                );
            }
        }
    }

    private static Metadata.CustomMetadataValue buildValue(String fieldApi, Object value) {
        System.debug(LoggingLevel.DEBUG, 'ReclamacionRoutingCmdtBatch.buildValue() fieldApi=' + fieldApi + ', value=' + value);

        Metadata.CustomMetadataValue x = new Metadata.CustomMetadataValue();
        x.field = fieldApi;
        x.value = value;
        return x;
    }

    private static Metadata.CustomMetadata buildRecord(
        String devName,
        String label,
        String codigo,
        String descripcion,
        String canal,
        String producto,
        String flujo,
        String recordTypeDevName,
        String supportProcess,
        String statusInicial,
        String nivelInicial,
        String grupoN1,
        String queueN1,
        String grupoN2,
        String queueN2,
        String grupoN3,
        String queueN3,
        Boolean permiteDevolucion,
        String queueDevolucion,
        Integer prioridad
    ) {
        System.debug(LoggingLevel.DEBUG, 'ReclamacionRoutingCmdtBatch.buildRecord() devName=' + devName + ', codigo=' + codigo + ', canal=' + canal + ', producto=' + producto);

        Metadata.CustomMetadata md = new Metadata.CustomMetadata();
        md.fullName = 'Reclamacion_Routing_Config.' + devName;
        md.label = label;
        md.values.add(buildValue('Activo__c', true));
        md.values.add(buildValue('Codigo_Reclamacion__c', codigo));
        md.values.add(buildValue('Descripcion_Reclamacion__c', descripcion));
        md.values.add(buildValue('Canal__c', canal));
        md.values.add(buildValue('Producto__c', producto));
        md.values.add(buildValue('Flujo_Etapas__c', flujo));
        md.values.add(buildValue('RecordType_DeveloperName__c', recordTypeDevName));
        md.values.add(buildValue('Support_Process__c', supportProcess));
        md.values.add(buildValue('Status_Inicial__c', statusInicial));
        md.values.add(buildValue('Nivel_Inicial__c', nivelInicial));
        md.values.add(buildValue('Grupo_Resolutor_N1__c', grupoN1));
        md.values.add(buildValue('Queue_N1_DeveloperName__c', queueN1));

        if (String.isNotBlank(grupoN2)) {
            md.values.add(buildValue('Grupo_Resolutor_N2__c', grupoN2));
        }
        if (String.isNotBlank(queueN2)) {
            md.values.add(buildValue('Queue_N2_DeveloperName__c', queueN2));
        }
        if (String.isNotBlank(grupoN3)) {
            md.values.add(buildValue('Grupo_Resolutor_N3__c', grupoN3));
        }
        if (String.isNotBlank(queueN3)) {
            md.values.add(buildValue('Queue_N3_DeveloperName__c', queueN3));
        }

        md.values.add(buildValue('Permite_Devolucion__c', permiteDevolucion));

        if (String.isNotBlank(queueDevolucion)) {
            md.values.add(buildValue('Queue_Devolucion_DeveloperName__c', queueDevolucion));
        }

        md.values.add(buildValue('Orden_Prioridad__c', prioridad));
        return md;
    }

    public static Integer getTotalBatches() {
        System.debug(LoggingLevel.DEBUG, 'ReclamacionRoutingCmdtBatch.getTotalBatches()');

        Integer totalRegistros = buildAllRecords().size();
        Integer totalBatches = (Integer)Math.ceil((Decimal)totalRegistros / DEFAULT_BATCH_SIZE);

        System.debug(LoggingLevel.DEBUG, 'Total registros=' + totalRegistros + ', total batches=' + totalBatches);
        return totalBatches;
    }

    public static Id runBatch(Integer batchNumber) {
        System.debug(LoggingLevel.DEBUG, 'ReclamacionRoutingCmdtBatch.runBatch() batchNumber=' + batchNumber);

        return runBatch(batchNumber, DEFAULT_BATCH_SIZE);
    }

    public static Id runBatch(Integer batchNumber, Integer batchSize) {
        System.debug(LoggingLevel.DEBUG, 'ReclamacionRoutingCmdtBatch.runBatch(batchNumber, batchSize) batchNumber=' + batchNumber + ', batchSize=' + batchSize);

        try {
            if (batchNumber == null || batchNumber <= 0) {
                throw new AuraHandledException('batchNumber debe ser mayor que 0.');
            }

            if (batchSize == null || batchSize <= 0) {
                throw new AuraHandledException('batchSize debe ser mayor que 0.');
            }

            List<Metadata.CustomMetadata> allRecords = buildAllRecords();

            Integer fromIdx = (batchNumber - 1) * batchSize;
            Integer toIdx = Math.min(fromIdx + batchSize, allRecords.size());

            if (fromIdx >= allRecords.size()) {
                System.debug(LoggingLevel.DEBUG, 'No hay más registros para el batch ' + batchNumber);
                return null;
            }

            Metadata.DeployContainer container = new Metadata.DeployContainer();

            for (Integer i = fromIdx; i < toIdx; i++) {
                container.addMetadata(allRecords[i]);
            }

            Id jobId = Metadata.Operations.enqueueDeployment(
                container,
                new ReclamacionRoutingDeployCallback()
            );

            System.debug(LoggingLevel.DEBUG, 'Batch enviado. batchNumber=' + batchNumber + ', registros=' + (toIdx - fromIdx));
            System.debug(LoggingLevel.DEBUG, 'Job Id=' + jobId);
            System.debug(LoggingLevel.DEBUG, 'Desde índice=' + fromIdx + ', hasta=' + (toIdx - 1));
            System.debug(LoggingLevel.DEBUG, 'Total registros configurados=' + allRecords.size());

            return jobId;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error en ReclamacionRoutingCmdtBatch.runBatch(): ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'StackTrace: ' + e.getStackTraceString());
            throw e;
        }
    }

    private static List<Metadata.CustomMetadata> buildAllRecords() {
        System.debug(LoggingLevel.DEBUG, 'ReclamacionRoutingCmdtBatch.buildAllRecords()');

        List<Metadata.CustomMetadata> allRecords = new List<Metadata.CustomMetadata>();

        allRecords.add(buildRecord(
            'REC001_01',
            'REC001_01',
            '1',
            'CONSUMO NO RECONOCIDO',
            'PE,PO,SA',
            'ALL',
            'PATH_4_CONTRACARGO_INVESTIGACION',
            'Reclamo_Contracargo_Investigacion',
            'Reclamo Contracargo + Investigación',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'ASIGNACION MANUAL',
            'Casos_Asignacion_Manual_Reclamaciones',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            90
        ));
        allRecords.add(buildRecord(
            'REC002_01',
            'REC002_01',
            '2',
            'RECONOCE EL CONSUMO EN ESTABLECIMIENTO, PERO NO EL MONTO DEL VOUCHER',
            'PE,PO,EP,SP,SA,SC',
            '131,132,133,134,171,172,173,174,211,212,213,216,218',
            'PATH_2_CONTRACARGO',
            'Reclamo_Contracargo',
            'Reclamo Contracargo',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC003_01',
            'REC003_01',
            '3',
            'NO RECONOCE CARGO / NO ESTIPULADO O AUTORIZADO',
            'VE',
            '131,132,133,134,171,172,173,174,111,112,113,114,121,122,123,124,161,162,163,164,165,166,167,168,169',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC003_02',
            'REC003_02',
            '3',
            'NO RECONOCE CARGO / NO ESTIPULADO O AUTORIZADO',
            'VE',
            '181,182,183,184,185,186,187,188,190,191,192,211,212,213,216,218',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC004_01',
            'REC004_01',
            '4',
            'ERROR EN EL COBRO DE INTERESES',
            'VE',
            '131,132,133,134,171,172,173,174,111,112,113,121,122,123,124,161,162,163,164,165,166,167,168,169,181',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC004_02',
            'REC004_02',
            '4',
            'ERROR EN EL COBRO DE INTERESES',
            'VE',
            '182,183,184,185,186,187,188,190,191,192,211,212,213,216,218',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC005_01',
            'REC005_01',
            '5',
            'CONSUMO DUPLICADO',
            'PE,PO',
            '114,131,132,133,134,171,172,173,174',
            'PATH_2_CONTRACARGO',
            'Reclamo_Contracargo',
            'Reclamo Contracargo',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC006_01',
            'REC006_01',
            '6',
            'PAGO NO REFLEJADO',
            'VE',
            '131,132,133,134,171,172,173,174,111,112,113,121,122,123,124,161,162,163,164,165,166,167,168,169,181',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC006_02',
            'REC006_02',
            '6',
            'PAGO NO REFLEJADO',
            'VE',
            '182,183,184,185,186,187,188,190,191,192',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC007_01',
            'REC007_01',
            '7',
            'DEPÓSITO NO REFLEJADO',
            'VE',
            '211,212,213,216,218',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC008_01',
            'REC008_01',
            '8',
            'SOLICITUD CANCELACIÓN DE PRODUCTO O SERVICIO',
            'VE',
            'ALL',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            90
        ));
        allRecords.add(buildRecord(
            'REC009_01',
            'REC009_01',
            '9',
            'DÉBITO DE CUENTA NO AUTORIZADO',
            'VE',
            '211,212,213,216,218',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'SEGURIDAD',
            'Casos_Seguridad_N2',
            'MANTENIMIENTO DE OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N3',
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC010_01',
            'REC010_01',
            '10',
            'EFECTIVO CARGADO NO DISPENSADO',
            'CA',
            '114',
            'PATH_3_INVESTIGACION_CONTRACARGO',
            'Reclamo_Investigacion_Contracargo',
            'Reclamo Investigación + Contracargo',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC011_01',
            'REC011_01',
            '11',
            'PLÁSTICO (TARJETA DE DÉBITO O CRÉDITO) RETENIDO POR CAJERO',
            'CA',
            '131,132,133,134,171,172,173,174',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'SEGURIDAD',
            'Casos_Seguridad_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC012_01',
            'REC012_01',
            '12',
            'PAGO INCOMPLETO DE INTERESES POR CONCEPTO DE CERTIFICADOS Y CUENTAS',
            'VE',
            '211,212,213,216,218',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC013_01',
            'REC013_01',
            '13',
            'NO SE LE HAN ACREDITADO LOS INTERESES ESTABLECIDOS EN SU CUENTA',
            'VE',
            '211,212,213,216,218',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC015_01',
            'REC015_01',
            '15',
            'PAGO EN EXCESO SOBRE SALDO',
            'VE',
            '131,132,133,134,171,172,173,174',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC016_01',
            'REC016_01',
            '16',
            'CAMBIO DE TASA SIN NOTIFICACIÓN PREVIA POR ESCRITO',
            'VE',
            '111,112,113,121,122,123,124,161,162,163,164,165,166,167,168,169,181,182,183,184,185,186,187,188,190',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC016_02',
            'REC016_02',
            '16',
            'CAMBIO DE TASA SIN NOTIFICACIÓN PREVIA POR ESCRITO',
            'VE',
            '191,192',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC017_01',
            'REC017_01',
            '17',
            'PRODUCTO CREADO SIN CONSENTIMIENTO EXPRESO',
            'VE',
            'ALL',
            'PATH_5_DATA_CREDITO',
            'Reclamo_Data_Credito',
            'Reclamo Data Crédito',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'SEGURIDAD',
            'Casos_Seguridad_N2',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N3',
            true,
            QUEUE_DEVOLUCION,
            90
        ));
        allRecords.add(buildRecord(
            'REC018_01',
            'REC018_01',
            '18',
            'TRANSFERENCIAS DE FONDOS NO RECONOCIDAS A TERCEROS',
            'EB',
            '211,212,213,216,218',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'SEGURIDAD',
            'Casos_Seguridad_N2',
            'EJECUCION DE OPERACIONES',
            'Casos_Ejecucion_Operaciones_N3',
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC019_01',
            'REC019_01',
            '19',
            'PROBLEMAS CON LA ENTREGA DE LOS ESTADOS DE CUENTA',
            'VE,EB',
            '131,132,133,134,171,172,173,174,211,212,213,216,218',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC020_01',
            'REC020_01',
            '20',
            'COBRO ERRÓNEO DEL IMPUESTO DE 0.15%',
            'VE,EB',
            '211,212,213,216,218',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'EJECUCION DE OPERACIONES',
            'Casos_Ejecucion_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC020_02',
            'REC020_02',
            '20',
            'COBRO ERRÓNEO DEL IMPUESTO DE 0.15%',
            'VE,EB',
            '211,212,213,216,218',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC021_01',
            'REC021_01',
            '21',
            'TRÁNSITO TARDÍO DE FONDOS',
            'VE',
            '131,132,133,134,171,172,173,174,211,212,213,216,218',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC022_01',
            'REC022_01',
            '22',
            'REDONDEO EN PERJUICIO DEL CLIENTE AL CERRAR UNA CUENTA',
            'VE',
            '111,112,113,114,121,122,123,124,161,162,163,164,165,166,167,168,169,181,182,183,184,185,186,187,188',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC022_02',
            'REC022_02',
            '22',
            'REDONDEO EN PERJUICIO DEL CLIENTE AL CERRAR UNA CUENTA',
            'VE',
            '190,191,192,211,212,213,216,218',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC023_01',
            'REC023_01',
            '23',
            'BLOQUEO / CANCELACIÓN DE PRODUCTO SIN JUSTIFICACIÓN',
            'VE',
            'ALL',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            90
        ));
        allRecords.add(buildRecord(
            'REC024_01',
            'REC024_01',
            '24',
            'CHEQUE CARGADO MÚLTIPLES VECES SOBRE UNA MISMA CUENTA CORRIENTE',
            'VE',
            '211,212,213,216,218',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC025_01',
            'REC025_01',
            '25',
            'REPORTE DE INFORMACIÓN ERRÓNEA A LOS BURÓS DE CRÉDITO',
            'VE',
            '131,132,133,134,171,172,173,174,111,112,113,121,122,123,124,161,162,163,164,165,166,167,168,169,181',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC025_02',
            'REC025_02',
            '25',
            'REPORTE DE INFORMACIÓN ERRÓNEA A LOS BURÓS DE CRÉDITO',
            'VE',
            '182,183,184,185,186,187,188,190,191,192',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC026_01',
            'REC026_01',
            '26',
            'COBRO DE PENALIDAD NO ESTIPULADA',
            'VE',
            'ALL',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            90
        ));
        allRecords.add(buildRecord(
            'REC027_01',
            'REC027_01',
            '27',
            'PAGOS NO APLICADOS DGII',
            'EB,PE,SA',
            'ALL',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            90
        ));
        allRecords.add(buildRecord(
            'REC027_02',
            'REC027_02',
            '27',
            'PAGOS NO APLICADOS DGII',
            'VE',
            'ALL',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'ADMINISTRACION SUCURSALES',
            'Casos_Administracion_Sucursales_N2',
            'CONTROL INTERNO',
            'Casos_Control_Interno_N3',
            true,
            QUEUE_DEVOLUCION,
            90
        ));
        allRecords.add(buildRecord(
            'REC028_01',
            'REC028_01',
            '28',
            'PAGOS NO APLICADOS TSS',
            'EB,PE,SA',
            'ALL',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            90
        ));
        allRecords.add(buildRecord(
            'REC028_02',
            'REC028_02',
            '28',
            'PAGOS NO APLICADOS TSS',
            'VE',
            'ALL',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'ADMINISTRACION SUCURSALES',
            'Casos_Administracion_Sucursales_N2',
            'CONTROL INTERNO',
            'Casos_Control_Interno_N3',
            true,
            QUEUE_DEVOLUCION,
            90
        ));
        allRecords.add(buildRecord(
            'REC029_01',
            'REC029_01',
            '29',
            'TRANSFERENCIA NO APLICADA',
            'EB,AM',
            'ALL',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'EJECUCION DE OPERACIONES',
            'Casos_Ejecucion_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            90
        ));
        allRecords.add(buildRecord(
            'REC030_01',
            'REC030_01',
            '30',
            'CARGO CUOTA PRÉSTAMO DIFIERE DE LA PACTADA',
            'VE',
            '111,112,113,114,121,122,123,124,161,162,163,164,165,166,167,168,169,181,182,183,184,185,186,187,188',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC030_02',
            'REC030_02',
            '30',
            'CARGO CUOTA PRÉSTAMO DIFIERE DE LA PACTADA',
            'VE',
            '190,191,192',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC031_01',
            'REC031_01',
            '31',
            'FALLO EN EL PAGO AUTOMÁTICO DEL PRÉSTAMO',
            'VE',
            '111,112,113,114,121,122,123,124,161,162,163,164,165,166,167,168,169,181,182,183,184,185,186,187,188',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC031_02',
            'REC031_02',
            '31',
            'FALLO EN EL PAGO AUTOMÁTICO DEL PRÉSTAMO',
            'VE',
            '190,191,192',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC032_01',
            'REC032_01',
            '32',
            'ERROR EN LA APLICACIÓN DE PAGO',
            'VE,AM,EB',
            '131,132,133,134,171,172,173,174',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC033_01',
            'REC033_01',
            '33',
            'NOTA DE CRÉDITO NO CORRESPONDE',
            'VE',
            '131,132,133,134,171,172,173,174,211,212,213,216,218',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC034_01',
            'REC034_01',
            '34',
            'NOTA DE CRÉDITO NO REGISTRADA',
            'VE',
            '131,132,133,134,171,172,173,174,211,212,213,216,218',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC035_01',
            'REC035_01',
            '35',
            'DEVOLUCIÓN SALDO A FAVOR',
            'VE',
            '131,132,133,134,171,172,173,174,111,112,113,121,122,123,124,161,162,163,164,165,166,167,168,169,181',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC035_02',
            'REC035_02',
            '35',
            'DEVOLUCIÓN SALDO A FAVOR',
            'VE',
            '182,183,184,185,186,187,188,190,191,192',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC036_01',
            'REC036_01',
            '36',
            'ELIMINACIÓN CARGO FLOTANTE',
            'VE',
            '131,132,133,134,171,172,173,174,211,212,213,216,218',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC038_01',
            'REC038_01',
            '38',
            'PROBLEMAS EN DPTO. COBRANZA LEGAL/EXTERNA',
            'VE',
            'ALL',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'COBROS',
            'Casos_Cobros_N2',
            'LEGAL',
            'Casos_Legal_N3',
            true,
            QUEUE_DEVOLUCION,
            90
        ));
        allRecords.add(buildRecord(
            'REC039_01',
            'REC039_01',
            '39',
            'PROBLEMAS EN DPTO. DE COBROS',
            'VE',
            'ALL',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'COBROS',
            'Casos_Cobros_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            90
        ));
        allRecords.add(buildRecord(
            'REC040_01',
            'REC040_01',
            '40',
            'PROBLEMAS LLAMADAS DE COBROS (TURBO COBRO)',
            'VE',
            'ALL',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'COBROS',
            'Casos_Cobros_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            90
        ));
        allRecords.add(buildRecord(
            'REC041_01',
            'REC041_01',
            '41',
            'PROBLEMA CON EL PROGRAMA DE FIDELIDAD',
            'VE',
            'ALL',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            90
        ));
        allRecords.add(buildRecord(
            'REC042_01',
            'REC042_01',
            '42',
            'RECLAMACIÓN BENEFICIOS DEL PROGRAMA DE FIDELIDAD',
            'VE',
            'ALL',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            90
        ));
        allRecords.add(buildRecord(
            'REC043_01',
            'REC043_01',
            '43',
            'COMPRA TARJETA DE LLAMADA NO DISPENSADO',
            'VE',
            'ALL',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'ASIGNACION MANUAL',
            'Casos_Asignacion_Manual_Reclamaciones',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            90
        ));
        allRecords.add(buildRecord(
            'REC044_01',
            'REC044_01',
            '44',
            'CANCELACIÓN DE PRODUCTO NO EJECUTADA',
            'VE,AM',
            'ALL',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            90
        ));
        allRecords.add(buildRecord(
            'REC045_01',
            'REC045_01',
            '45',
            'ERRORES DETECTADOS EN EL ESTADO DE CUENTA',
            'VE',
            '131,132,133,134,171,172,173,174,211,212,213,216,218',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC046_01',
            'REC046_01',
            '46',
            'CARGO DUPLICADO POR CERTIFICACIÓN DE CHEQUE',
            'VE',
            '211,212,213,216,218',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC047_01',
            'REC047_01',
            '47',
            'TRANSACCIÓN PROCESADA CON DIFERENCIA',
            'TODOS LOS CANALES',
            'ALL',
            'PATH_3_INVESTIGACION_CONTRACARGO',
            'Reclamo_Investigacion_Contracargo',
            'Reclamo Investigación + Contracargo',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            null,
            null,
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            90
        ));
        allRecords.add(buildRecord(
            'REC048_01',
            'REC048_01',
            '48',
            'DÉBITOS AUTOMÁTICOS POR PAGO DE FACTURAS',
            'VE,EB',
            '211,212,213,216,218',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC049_01',
            'REC049_01',
            '49',
            'CHEQUE CARGADO MULTIPLES VECES SOBRE UNA MISMA CUENTA DE AHORRO',
            'VE',
            '211,212,213,216,218',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC053_01',
            'REC053_01',
            '53',
            'CARGO / COMISIÓN DUPLICADO',
            'VE',
            'ALL',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N2',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            90
        ));
        allRecords.add(buildRecord(
            'REC054_01',
            'REC054_01',
            '54',
            'RETIRO DE EFECTIVO NO RECONOCIDO',
            'VE,CA,SA',
            '131,132,133,134,171,172,173,174,211,212,213,216,218',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'SEGURIDAD',
            'Casos_Seguridad_N2',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N3',
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC055_01',
            'REC055_01',
            '55',
            'AVANCE DE EFECTIVO NO RECONOCIDO',
            'VE,CA,SA',
            '131,132,133,134,171,172,173,174,211,212,213,216,218',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'SEGURIDAD',
            'Casos_Seguridad_N2',
            'MANTENIMIENTO OPERACIONES',
            'Casos_Mantenimiento_Operaciones_N3',
            true,
            QUEUE_DEVOLUCION,
            1
        ));
        allRecords.add(buildRecord(
            'REC056_01',
            'REC056_01',
            '56',
            'ENTREGA DE DOCUMENTOS',
            'VE',
            'ALL',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'SIN ESCALAMIENTO',
            'Casos_Asignacion_Manual_Reclamaciones',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            90
        ));
        allRecords.add(buildRecord(
            'REC057_01',
            'REC057_01',
            '57',
            'PUBLICIDAD IRRESPONSABLE',
            'VE',
            'ALL',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'SIN ESCALAMIENTO',
            'Casos_Asignacion_Manual_Reclamaciones',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            90
        ));
        allRecords.add(buildRecord(
            'REC058_01',
            'REC058_01',
            '58',
            'CONSULTA U OFERTA PROMOCIONAL NO SOLICITADA',
            'VE',
            'ALL',
            'PATH_1_ESTANDAR',
            'Reclamo_Estandar',
            'Reclamo Estándar',
            'Crear Solicitud',
            'N1',
            'GESTION DE SERVICIO Y PROTECCION AL USUARIO',
            'Casos_GSPU_N1',
            'SIN ESCALAMIENTO',
            'Casos_Asignacion_Manual_Reclamaciones',
            null,
            null,
            true,
            QUEUE_DEVOLUCION,
            90
        ));

        System.debug(LoggingLevel.DEBUG, 'Total registros cargados en memoria=' + allRecords.size());
        return allRecords;
    }
}