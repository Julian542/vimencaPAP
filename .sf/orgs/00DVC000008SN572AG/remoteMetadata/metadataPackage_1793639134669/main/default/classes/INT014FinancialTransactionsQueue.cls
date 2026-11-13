public with sharing class INT014FinancialTransactionsQueue implements Queueable, Database.AllowsCallouts {

    private List<Id> financialAccountIds;

    public INT014FinancialTransactionsQueue(List<Id> financialAccountIds) {
        this.financialAccountIds = (financialAccountIds == null)
            ? new List<Id>()
            : new List<Id>(financialAccountIds);
    }

    public void execute(QueueableContext context) {

        System.debug(' INT014FinancialTransactionsQueue.execute - financialAccountIds: ' + financialAccountIds);

        if (financialAccountIds == null || financialAccountIds.isEmpty()) {
            System.debug(' No hay cuentas financieras por procesar.');
            return;
        }

        Id currentAccountId = financialAccountIds[0];
        financialAccountIds.remove(0);

        List<FinServ__FinancialAccountTransaction__c> trxList =
            new List<FinServ__FinancialAccountTransaction__c>();

        try {
            FinServ__FinancialAccount__c acc = [
                SELECT Id, Name, FinServ__FinancialAccountNumber__c, FIN_Linea_de_producto__c
                FROM FinServ__FinancialAccount__c
                WHERE Id = :currentAccountId
                LIMIT 1
            ];

            Map<String, String> filtros = new Map<String, String>{
                'fromDate' => formatDateDdMmYyyy(Date.today().addMonths(-3)),
                'untilDate' => formatDateDdMmYyyy(Date.today()),
                'state' => '',
                'minimunAmount' => '',
                'maxAmount' => '',
                'credirDebit' => '',
                'documentNumber' => ''
            };

            System.debug(' Procesando cuenta: ' + acc.Id + ' - ' + acc.FinServ__FinancialAccountNumber__c);
            System.debug(' Filtros: ' + filtros);

            INT014_FSC.Response resp = INT014_FSC.checkProductTransactions(acc.Id, filtros);

            System.debug(' Resp INT014: ' + resp);

            if (resp != null && resp.succesTimeout && resp.responseList != null && !resp.responseList.isEmpty()) {

                for (Map<String, Object> row : resp.responseList) {
                    System.debug(' Row: ' + row);

                    FinServ__FinancialAccountTransaction__c trx =
                        new FinServ__FinancialAccountTransaction__c();

                    trx.FinServ__FinancialAccount__c = acc.Id;

                    trx.FinServ__TransactionDate__c =
                        parseDate(getValue(row, new List<String>{ 'FechaTransaccion' }));

                    trx.FinServ__PostDate__c =
                        parseDate(getValue(row, new List<String>{ 'FechaProceso' }));

                    trx.FinServ__Description__c =
                        getValue(row, new List<String>{ 'Descripcion', 'DescTransaccion', 'DetalleFactura' });

                    String amountRaw = getValue(
                        row,
                        new List<String>{
                            'Valor',
                            'MontoLocal',
                            'MontoOriginal',
                            'MontoTotal',
                            'MontoCapital',
                            'MontoInteres',
                            'TotalPagado',
                            'TotalFacturado'
                        }
                    );

                    trx.FinServ__Amount__c = parseDecimal(amountRaw);

                    trx.FinServ__TransactionType__c =
                        getValue(row, new List<String>{ 'CreditoDebito' });

                    trx.FinServ__TransactionSubtype__c =
                        getValue(row, new List<String>{ 'TipoMovimiento', 'TipoTransaccion' });

                    trx.FinServ__TransactionStatus__c =
                        getValue(row, new List<String>{ 'Estado', 'EstadoConsumo' });

                    trx.FinServ__SourceTransactionType__c =
                        getValue(row, new List<String>{ 'CodTransaccion', 'CodigoTransaccion' });

                    trx.FinServ__TransactionId__c =
                        getValue(row, new List<String>{ 'NumDocumento', 'Documento', 'NumTransaccion' });

                    trx.FinServ__RunningBalance__c =
                        parseDecimal(getValue(row, new List<String>{ 'Saldo' }));

                    trx.FinServ__SourceSystemId__c =
                        safe(acc.FinServ__FinancialAccountNumber__c) + '|' +
                        safe(getValue(row, new List<String>{ 'FechaTransaccion' })) + '|' +
                        safe(getValue(row, new List<String>{ 'NumDocumento', 'Documento', 'NumTransaccion' })) + '|' +
                        safe(getValue(row, new List<String>{ 'CodTransaccion', 'CodigoTransaccion' })) + '|' +
                        safe(getValue(row, new List<String>{ 'Valor', 'MontoTotal', 'MontoCapital' }));

                    if (trx.FinServ__Amount__c == null) {
                        System.debug(' Transacción omitida por monto nulo. Row: ' + row);
                        continue;
                    }

                    trxList.add(trx);
                }
            } else {
                System.debug(' INT014 no devolvió transacciones para la cuenta: ' + acc.Id);
            }

            if (!trxList.isEmpty()) {
                System.debug(' Upsert de transacciones: ' + trxList.size());
                upsert trxList FinServ__SourceSystemId__c;
            } else {
                System.debug(' No hay transacciones para guardar.');
            }

        } catch (Exception e) {
            System.debug(' Error en INT014FinancialTransactionsQueue: ' + e.getMessage());
            System.debug(' StackTrace: ' + e.getStackTraceString());
        }

        // Encadenar siguiente cuenta
        if (!financialAccountIds.isEmpty()) {
            System.debug(' Encolando siguiente ejecución. Pendientes: ' + financialAccountIds.size());
            System.enqueueJob(new INT014FinancialTransactionsQueue(financialAccountIds));
        } else {
            System.debug(' Proceso de transacciones finalizado.');
        }
    }

    private static String getValue(Map<String, Object> row, List<String> keys) {
        for (String key : keys) {
            if (row.containsKey(key) && row.get(key) != null && !String.isBlank(String.valueOf(row.get(key)))) {
                return String.valueOf(row.get(key)).trim();
            }
        }
        return null;
    }

    private static Datetime parseDate(String value) {
        if (String.isBlank(value)) return null;

        String raw = value.trim();

        try {
            if (raw.contains('/')) {
                List<String> parts = raw.split(' ');
                List<String> dateParts = parts[0].split('/');

                Integer dayNum = Integer.valueOf(dateParts[0]);
                Integer monthNum = Integer.valueOf(dateParts[1]);
                Integer yearNum = Integer.valueOf(dateParts[2]);

                Integer hourNum = 0;
                Integer minuteNum = 0;
                Integer secondNum = 0;

                if (parts.size() > 1) {
                    List<String> timeParts = parts[1].split(':');
                    if (timeParts.size() > 0) hourNum = Integer.valueOf(timeParts[0]);
                    if (timeParts.size() > 1) minuteNum = Integer.valueOf(timeParts[1]);
                    if (timeParts.size() > 2) secondNum = Integer.valueOf(timeParts[2]);
                }

                return Datetime.newInstance(yearNum, monthNum, dayNum, hourNum, minuteNum, secondNum);
            }

            return Datetime.valueOf(raw);

        } catch (Exception e) {
            System.debug(' No se pudo convertir a Datetime: ' + value);
            return null;
        }
    }

    private static Decimal parseDecimal(String value) {
        if (String.isBlank(value)) return null;

        String raw = value.trim();

        try {
            if (raw.contains('.') && raw.contains(',')) {
                raw = raw.replace(',', '');
            } else if (raw.contains(',') && !raw.contains('.')) {
                raw = raw.replace(',', '.');
            }
            return Decimal.valueOf(raw);
        } catch (Exception e) {
            System.debug(' No se pudo convertir a Decimal: ' + value);
            return null;
        }
    }

    private static String formatDateDdMmYyyy(Date inputDate) {
        if (inputDate == null) {
            return '';
        }

        String dayValue = inputDate.day() < 10 ? '0' + String.valueOf(inputDate.day()) : String.valueOf(inputDate.day());
        String monthValue = inputDate.month() < 10 ? '0' + String.valueOf(inputDate.month()) : String.valueOf(inputDate.month());

        return dayValue + '/' + monthValue + '/' + String.valueOf(inputDate.year());
    }

    private static String safe(String value) {
        return value == null ? '' : value.trim();
    }
}