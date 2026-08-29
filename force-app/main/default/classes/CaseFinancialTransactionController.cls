public with sharing class CaseFinancialTransactionController {

    public class TransactionFilter {
        @AuraEnabled public Date fechaDesde;
        @AuraEnabled public Date fechaHasta;
        @AuraEnabled public String estado;
        @AuraEnabled public String creditoDebito;
        @AuraEnabled public Decimal montoMinimo;
        @AuraEnabled public Decimal montoMaximo;
        @AuraEnabled public String numeroDocumento;
    }

    public class TransactionRow {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public Date fecha;
        @AuraEnabled public Decimal monto;
        @AuraEnabled public String descripcion;
        @AuraEnabled public String creditoDebito;
        @AuraEnabled public String estado;
        @AuraEnabled public String numeroDocumento;
        @AuraEnabled public String tipoTransaccion;
        @AuraEnabled public String sourceTransactionType;
    }

    @AuraEnabled(cacheable=true)
    public static List<TransactionRow> getTransactionsByCase(Id caseId, TransactionFilter filters) {
        System.debug('INICIO CaseFinancialTransactionController.getTransactionsByCase');
        System.debug('caseId recibido: ' + caseId);
        System.debug('filters recibido null: ' + (filters == null));

        if (filters != null) {
            System.debug('filters.fechaDesde: ' + filters.fechaDesde);
            System.debug('filters.fechaHasta: ' + filters.fechaHasta);
            System.debug('filters.estado: ' + filters.estado);
            System.debug('filters.creditoDebito: ' + filters.creditoDebito);
            System.debug('filters.montoMinimo: ' + filters.montoMinimo);
            System.debug('filters.montoMaximo: ' + filters.montoMaximo);
            System.debug('filters.numeroDocumento: ' + filters.numeroDocumento);
        }

        if (caseId == null) {
            System.debug('ERROR: caseId viene null');
            throw new AuraHandledException('Debe enviar el Id del caso.');
        }

        Case caso = [
            SELECT Id,
                   CaseNumber,
                   FinServ__FinancialAccount__c,
                   FinServ__FinancialAccount__r.Name
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

        System.debug('Caso encontrado Id: ' + caso.Id);
        System.debug('Caso encontrado CaseNumber: ' + caso.CaseNumber);
        System.debug('Caso FinServ__FinancialAccount__c: ' + caso.FinServ__FinancialAccount__c);
        System.debug('Caso FinancialAccount Name: ' + (
            caso.FinServ__FinancialAccount__r != null
                ? caso.FinServ__FinancialAccount__r.Name
                : null
        ));

        if (caso.FinServ__FinancialAccount__c == null) {
            System.debug('FIN: El caso no tiene FinServ__FinancialAccount__c asociado');
            return new List<TransactionRow>();
        }

        Id financialAccountId = caso.FinServ__FinancialAccount__c;
        String financialAccountName = caso.FinServ__FinancialAccount__r != null
            ? caso.FinServ__FinancialAccount__r.Name
            : null;

        System.debug('financialAccountId usado para consultar transacciones: ' + financialAccountId);
        System.debug('financialAccountName usado solo para comparación visual: ' + financialAccountName);

        List<FinServ__FinancialAccountTransaction__c> debugTxSoloPorCuenta = [
            SELECT Id,
                   Name,
                   FinServ__FinancialAccount__c,
                   FinServ__FinancialAccount__r.Name,
                   FinServ__TransactionDate__c,
                   FinServ__Amount__c,
                   FinServ__Description__c,
                   FinServ__TransactionType__c,
                   FinServ__TransactionStatus__c,
                   FinServ__TransactionId__c,
                   FinServ__SourceTransactionType__c,
                   FinServ__SourceSystemId__c
            FROM FinServ__FinancialAccountTransaction__c
            WHERE FinServ__FinancialAccount__c = :financialAccountId
            ORDER BY FinServ__TransactionDate__c DESC
            LIMIT 20
        ];

        System.debug('DEBUG TOTAL TX SOLO POR FINANCIAL ACCOUNT ID: ' + debugTxSoloPorCuenta.size());
        System.debug('DEBUG DATA TX SOLO POR FINANCIAL ACCOUNT ID: ' + JSON.serializePretty(debugTxSoloPorCuenta));

        if (String.isNotBlank(financialAccountName)) {
            List<FinServ__FinancialAccountTransaction__c> debugTxPorAccountName = [
                SELECT Id,
                       Name,
                       FinServ__FinancialAccount__c,
                       FinServ__FinancialAccount__r.Name,
                       FinServ__TransactionDate__c,
                       FinServ__Amount__c,
                       FinServ__Description__c,
                       FinServ__TransactionType__c,
                       FinServ__TransactionStatus__c,
                       FinServ__TransactionId__c,
                       FinServ__SourceTransactionType__c,
                       FinServ__SourceSystemId__c
                FROM FinServ__FinancialAccountTransaction__c
                WHERE FinServ__FinancialAccount__r.Name = :financialAccountName
                ORDER BY FinServ__TransactionDate__c DESC
                LIMIT 20
            ];

            System.debug('DEBUG TOTAL TX POR FINANCIAL ACCOUNT NAME: ' + debugTxPorAccountName.size());
            System.debug('DEBUG DATA TX POR FINANCIAL ACCOUNT NAME: ' + JSON.serializePretty(debugTxPorAccountName));
        } else {
            System.debug('DEBUG NO SE CONSULTA POR NAME PORQUE financialAccountName viene vacío');
        }

        DateTime fechaDesdeDateTime;
        DateTime fechaHastaDateTime;
        String estadoFiltro;
        String creditoDebitoFiltro;
        Decimal montoMinimoFiltro;
        Decimal montoMaximoFiltro;
        String numeroDocumentoLike;

        if (filters != null) {
            if (filters.fechaDesde != null) {
                fechaDesdeDateTime = DateTime.newInstance(
                    filters.fechaDesde,
                    Time.newInstance(0, 0, 0, 0)
                );
            }

            if (filters.fechaHasta != null) {
                Date fechaHastaMasUno = filters.fechaHasta.addDays(1);
                fechaHastaDateTime = DateTime.newInstance(
                    fechaHastaMasUno,
                    Time.newInstance(0, 0, 0, 0)
                );
            }

            if (String.isNotBlank(filters.estado)) {
                estadoFiltro = filters.estado.trim();
            }

            if (String.isNotBlank(filters.creditoDebito)) {
                creditoDebitoFiltro = filters.creditoDebito.trim();
            }

            if (filters.montoMinimo != null) {
                montoMinimoFiltro = filters.montoMinimo;
            }

            if (filters.montoMaximo != null) {
                montoMaximoFiltro = filters.montoMaximo;
            }

            if (String.isNotBlank(filters.numeroDocumento)) {
                numeroDocumentoLike = '%' + filters.numeroDocumento.trim() + '%';
            }
        }

        System.debug('fechaDesdeDateTime usada: ' + fechaDesdeDateTime);
        System.debug('fechaHastaDateTime usada exclusiva: ' + fechaHastaDateTime);
        System.debug('estadoFiltro usado: ' + estadoFiltro);
        System.debug('creditoDebitoFiltro usado: ' + creditoDebitoFiltro);
        System.debug('montoMinimoFiltro usado: ' + montoMinimoFiltro);
        System.debug('montoMaximoFiltro usado: ' + montoMaximoFiltro);
        System.debug('numeroDocumentoLike usado: ' + numeroDocumentoLike);

        String query =
            'SELECT Id, ' +
            'Name, ' +
            'FinServ__FinancialAccount__c, ' +
            'FinServ__FinancialAccount__r.Name, ' +
            'FinServ__TransactionDate__c, ' +
            'FinServ__Amount__c, ' +
            'FinServ__Description__c, ' +
            'FinServ__TransactionType__c, ' +
            'FinServ__TransactionStatus__c, ' +
            'FinServ__TransactionId__c, ' +
            'FinServ__SourceTransactionType__c, ' +
            'FinServ__SourceSystemId__c ' +
            'FROM FinServ__FinancialAccountTransaction__c ' +
            'WHERE FinServ__FinancialAccount__c = :financialAccountId ';

        if (fechaDesdeDateTime != null) {
            query += 'AND FinServ__TransactionDate__c >= :fechaDesdeDateTime ';
            System.debug('Filtro aplicado fecha desde: ' + fechaDesdeDateTime);
        } else {
            System.debug('No se aplica filtro fecha desde');
        }

        if (fechaHastaDateTime != null) {
            query += 'AND FinServ__TransactionDate__c < :fechaHastaDateTime ';
            System.debug('Filtro aplicado fecha hasta exclusiva: ' + fechaHastaDateTime);
        } else {
            System.debug('No se aplica filtro fecha hasta');
        }

        if (String.isNotBlank(estadoFiltro)) {
            query += 'AND FinServ__TransactionStatus__c = :estadoFiltro ';
            System.debug('Filtro aplicado estado: ' + estadoFiltro);
        } else {
            System.debug('No se aplica filtro estado');
        }

        if (String.isNotBlank(creditoDebitoFiltro)) {
            query += 'AND FinServ__TransactionType__c = :creditoDebitoFiltro ';
            System.debug('Filtro aplicado creditoDebito: ' + creditoDebitoFiltro);
        } else {
            System.debug('No se aplica filtro creditoDebito');
        }

        if (montoMinimoFiltro != null) {
            query += 'AND FinServ__Amount__c >= :montoMinimoFiltro ';
            System.debug('Filtro aplicado monto minimo: ' + montoMinimoFiltro);
        } else {
            System.debug('No se aplica filtro monto minimo');
        }

        if (montoMaximoFiltro != null) {
            query += 'AND FinServ__Amount__c <= :montoMaximoFiltro ';
            System.debug('Filtro aplicado monto maximo: ' + montoMaximoFiltro);
        } else {
            System.debug('No se aplica filtro monto maximo');
        }

        if (String.isNotBlank(numeroDocumentoLike)) {
            query += 'AND FinServ__TransactionId__c LIKE :numeroDocumentoLike ';
            System.debug('Filtro aplicado numero documento like: ' + numeroDocumentoLike);
        } else {
            System.debug('No se aplica filtro numero documento');
        }

        query += 'ORDER BY FinServ__TransactionDate__c DESC LIMIT 200';

        System.debug('QUERY FINAL TRANSACCIONES: ' + query);

        List<FinServ__FinancialAccountTransaction__c> transactions = Database.query(query);

        System.debug('TOTAL TX FINAL ENCONTRADAS: ' + transactions.size());
        System.debug('DATA TX FINAL ENCONTRADAS: ' + JSON.serializePretty(transactions));

        List<TransactionRow> rows = new List<TransactionRow>();

        for (FinServ__FinancialAccountTransaction__c tx : transactions) {
            TransactionRow row = new TransactionRow();

            row.id = tx.Id;
            row.name = tx.Name;
            row.fecha = tx.FinServ__TransactionDate__c != null
                ? tx.FinServ__TransactionDate__c.date()
                : null;
            row.monto = tx.FinServ__Amount__c;
            row.descripcion = tx.FinServ__Description__c;
            row.creditoDebito = tx.FinServ__TransactionType__c;
            row.estado = tx.FinServ__TransactionStatus__c;
            row.numeroDocumento = tx.FinServ__TransactionId__c;
            row.tipoTransaccion = tx.FinServ__TransactionType__c;
            row.sourceTransactionType = tx.FinServ__SourceTransactionType__c;

            rows.add(row);
        }

        System.debug('TOTAL ROWS DEVUELTAS AL LWC: ' + rows.size());
        System.debug('FIN CaseFinancialTransactionController.getTransactionsByCase');

        return rows;
    }

    @AuraEnabled
    public static void linkTransactionsToCase(Id caseId, List<Id> transactionIds) {
        System.debug('INICIO CaseFinancialTransactionController.linkTransactionsToCase');
        System.debug('caseId recibido link: ' + caseId);
        System.debug('transactionIds recibido link: ' + transactionIds);

        if (caseId == null) {
            System.debug('ERROR link: caseId viene null');
            throw new AuraHandledException('Debe enviar el Id del caso.');
        }

        if (transactionIds == null || transactionIds.isEmpty()) {
            System.debug('ERROR link: transactionIds viene null o vacío');
            throw new AuraHandledException('Debe seleccionar al menos una transacción.');
        }

        Case caso = [
            SELECT Id,
                   CaseNumber,
                   FinServ__FinancialAccount__c,
                   FinServ__FinancialAccount__r.Name
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

        System.debug('link Caso Id: ' + caso.Id);
        System.debug('link Caso CaseNumber: ' + caso.CaseNumber);
        System.debug('link Caso FinancialAccount Id: ' + caso.FinServ__FinancialAccount__c);
        System.debug('link Caso FinancialAccount Name: ' + (
            caso.FinServ__FinancialAccount__r != null
                ? caso.FinServ__FinancialAccount__r.Name
                : null
        ));

        if (caso.FinServ__FinancialAccount__c == null) {
            System.debug('ERROR link: El caso no tiene producto financiero asociado');
            throw new AuraHandledException('El caso no tiene producto financiero asociado.');
        }

        List<FinServ__FinancialAccountTransaction__c> transactions = [
            SELECT Id,
                   Name,
                   FinServ__FinancialAccount__c,
                   FinServ__FinancialAccount__r.Name,
                   FinServ__TransactionDate__c,
                   FinServ__Amount__c,
                   FinServ__Description__c,
                   FinServ__TransactionType__c,
                   FinServ__TransactionStatus__c,
                   FinServ__TransactionId__c,
                   FinServ__SourceTransactionType__c,
                   FinServ__SourceSystemId__c
            FROM FinServ__FinancialAccountTransaction__c
            WHERE Id IN :transactionIds
            AND FinServ__FinancialAccount__c = :caso.FinServ__FinancialAccount__c
        ];

        System.debug('link TOTAL TX VALIDAS ENCONTRADAS: ' + transactions.size());
        System.debug('link DATA TX VALIDAS ENCONTRADAS: ' + JSON.serializePretty(transactions));

        if (transactions.isEmpty()) {
            System.debug('ERROR link: No se encontraron transacciones válidas para enlazar');
            throw new AuraHandledException('No se encontraron transacciones válidas para enlazar.');
        }

        List<TRA_Transaccion__c> recordsToInsert = new List<TRA_Transaccion__c>();

        for (FinServ__FinancialAccountTransaction__c tx : transactions) {
            TRA_Transaccion__c record = new TRA_Transaccion__c();

            record.TRA_Reclamacion__c = caseId;

            if (tx.FinServ__TransactionDate__c != null) {
                record.TRA_Fecha__c = tx.FinServ__TransactionDate__c.date();
            }

            record.TRA_Monto__c = tx.FinServ__Amount__c;

            if (String.isNotBlank(tx.FinServ__TransactionType__c)) {
                record.TRA_Credito_Debito__c = tx.FinServ__TransactionType__c;
            }

            record.Name = buildTransactionName(tx);

            System.debug('link TRA_Transaccion__c preparada: ' + JSON.serializePretty(record));

            recordsToInsert.add(record);
        }

        System.debug('link TOTAL TRA_Transaccion__c A INSERTAR: ' + recordsToInsert.size());

        insert recordsToInsert;

        System.debug('link INSERT OK TRA_Transaccion__c: ' + JSON.serializePretty(recordsToInsert));
        System.debug('FIN CaseFinancialTransactionController.linkTransactionsToCase');
    }

    private static String buildTransactionName(FinServ__FinancialAccountTransaction__c tx) {
        String value = tx.Name;

        if (String.isNotBlank(tx.FinServ__Description__c)) {
            value += ' - ' + tx.FinServ__Description__c;
        }

        if (value != null && value.length() > 80) {
            value = value.substring(0, 80);
        }

        return value;
    }
}