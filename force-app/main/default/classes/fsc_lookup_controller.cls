public with sharing class fsc_lookup_controller {
    private final static Integer MAX_RESULTS = 5;

    @AuraEnabled(cacheable=true scope='global')
    public static List<FSC_LookupSearchResult> search(String searchTerm, List<String> selectedIds) {
        searchTerm = '%'+searchTerm+'%';

        List<FSC_LookupSearchResult> results = new List<FSC_LookupSearchResult>();

        String accountIcon = 'custom:custom16';
        
        List<FinServ__FinancialAccount__c> accounts = [SELECT Id, Name, FIN_Linea_de_producto__c FROM FinServ__FinancialAccount__c WHERE FinServ__PrimaryOwner__c IN: selectedIds AND Name LIKE: searchTerm LIMIT :MAX_RESULTS];
        
        for (FinServ__FinancialAccount__c account : accounts) {
            results.add(new FSC_LookupSearchResult(account.Id, 'Account', accountIcon, account.FIN_Linea_de_producto__c +' - '+ account.Name, ''));
        }

        results.sort();

        return results;
    }

    @AuraEnabled(cacheable=true scope='global')
    public static List<FSC_LookupSearchResult> searchEjecutivo(String searchTerm, List<String> selectedIds) {
        searchTerm = '%'+searchTerm+'%';

        List<FSC_LookupSearchResult> results = new List<FSC_LookupSearchResult>();

        System.debug(searchTerm);
        String accountIcon = 'utility:user';
        
        List<User> usuarios = [SELECT Id, Name FROM User WHERE Canal_Atencion__c != null AND IsActive = true AND Name LIKE: searchTerm LIMIT :MAX_RESULTS];
        System.debug(usuarios);
        
        for (User account : usuarios) {
            results.add(new FSC_LookupSearchResult(account.Id, 'Account', accountIcon, account.Name, ''));
        }

        results.sort();

        return results;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getEjecutivosCambioOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();

        List<User> usuarios = [
            SELECT Id, Name
            FROM User
            WHERE Canal_Atencion__c != null
            AND IsActive = true
            ORDER BY Name
        ];

        for (User usr : usuarios) {
            options.add(new Map<String, String>{
                'label' => usr.Name,
                'value' => usr.Id
            });
        }

        return options;
    }

    @AuraEnabled(cacheable=true scope='global')
    public static List<FSC_LookupSearchResult> searchAumento(String searchTerm, List<String> selectedIds) {
        searchTerm = '%'+searchTerm+'%';

        List<FSC_LookupSearchResult> results = new List<FSC_LookupSearchResult>();

        String accountIcon = 'custom:custom16';
        
        List<FinServ__FinancialAccount__c> accounts = [SELECT Id, Name, FIN_Linea_de_producto__c, RecordType.DeveloperName FROM FinServ__FinancialAccount__c WHERE FinServ__PrimaryOwner__c IN: selectedIds AND Name LIKE: searchTerm AND RecordType.DeveloperName IN ('CreditCard', 'LoanAccount', 'HELOC', 'Mortgage', 'AutoLoan') LIMIT :MAX_RESULTS];
        
        for (FinServ__FinancialAccount__c account : accounts) {
            results.add(new FSC_LookupSearchResult(account.Id, 'Account', accountIcon, account.FIN_Linea_de_producto__c +' - '+ account.Name, ''));
        }

        results.sort();

        return results;
    }

    @AuraEnabled
    public static List<FSC_LookupSearchResult> searchMatriz(String producto) {
        // searchTerm = '%'+searchTerm+'%';
        // producto = '%'+producto;


        List<FSC_LookupSearchResult> results = new List<FSC_LookupSearchResult>();

        String accountIcon = 'custom:custom16';
        
        // AND PRO_Nombre_de_linea_de_producto__c  LIKE: searchTerm
        List<Matriz_de_producto__c> products = [SELECT Id, Name FROM Matriz_de_producto__c WHERE PRO_Nombre_de_linea_de_producto__c  =: producto AND PRO_Migrado__c  = true ];
        
        for (Matriz_de_producto__c prod : products) {
            results.add(new FSC_LookupSearchResult(prod.Id, 'Account', accountIcon, prod.Name, ''));
        }

        results.sort();
        
        system.debug('result '+results);

        return results;
    }

    @AuraEnabled(cacheable=true scope='global')
    public static List<FSC_LookupSearchResult> getRecentlyViewed(String accountId) {
        List<FSC_LookupSearchResult> results = new List<FSC_LookupSearchResult>();
        
        List<FinServ__FinancialAccount__c> accounts = [SELECT Id, Name, FIN_Linea_de_producto__c FROM FinServ__FinancialAccount__c WHERE FinServ__PrimaryOwner__c =: accountId LIMIT :MAX_RESULTS];

        for (FinServ__FinancialAccount__c recentRecord : accounts) {
            results.add(
                new FSC_LookupSearchResult(
                    recentRecord.Id,
                    'Account',
                    'custom:custom16',
                    recentRecord.FIN_Linea_de_producto__c +' - '+ recentRecord.Name,
                    ''
                )
            );
        }
        return results;
    }

    @AuraEnabled(cacheable=true scope='global')
    public static List<FSC_LookupSearchResult> getRecentlyViewedAumento(String accountId) {
        List<FSC_LookupSearchResult> results = new List<FSC_LookupSearchResult>();
        
        List<FinServ__FinancialAccount__c> accounts = [SELECT Id, Name, FIN_Linea_de_producto__c, RecordType.DeveloperName FROM FinServ__FinancialAccount__c WHERE FinServ__PrimaryOwner__c =: accountId AND RecordType.DeveloperName IN ('CreditCard', 'LoanAccount', 'HELOC', 'Mortgage', 'AutoLoan') LIMIT :MAX_RESULTS];

        for (FinServ__FinancialAccount__c recentRecord : accounts) {
            results.add(
                new FSC_LookupSearchResult(
                    recentRecord.Id,
                    'Account',
                    'custom:custom16',
                    recentRecord.FIN_Linea_de_producto__c +' - '+ recentRecord.Name,
                    ''
                )
            );
        }
        return results;
    }

    @AuraEnabled(cacheable=true scope='global')
    public static List<FSC_LookupSearchResult> getRecentlyViewedFinn(String accountId, String notInclude) {
        List<FSC_LookupSearchResult> results = new List<FSC_LookupSearchResult>();
        
        List<FinServ__FinancialAccount__c> accounts = [SELECT Id, Name, FIN_Linea_de_producto__c FROM FinServ__FinancialAccount__c WHERE FinServ__PrimaryOwner__c =: accountId AND Id !=: notInclude LIMIT :MAX_RESULTS];

        for (FinServ__FinancialAccount__c recentRecord : accounts) {
            results.add(
                new FSC_LookupSearchResult(
                    recentRecord.Id,
                    'Account',
                    'custom:custom16',
                    recentRecord.FIN_Linea_de_producto__c +' - '+ recentRecord.Name,
                    ''
                )
            );
        }
        return results;
    }

    // @AuraEnabled
    // public static string getFinnancialAccCurrencies(String accountId){
    //     try {
    //         List<FinServ__FinancialAccount__c> accounts = [SELECT Id, Name, FIN_Linea_de_producto__c, FIN_Monto_disponible__c, FIN_Moneda__c FROM FinServ__FinancialAccount__c WHERE Id =: accountId];     
    //     } catch (Exception e) {
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }

    @AuraEnabled
    public static List<FSC_LookupSearchResult> searchTarjetaCredito(
        String searchTerm,
        List<String> selectedIds,
        Boolean excluirVigentes
    ) {
        searchTerm = '%' + searchTerm + '%';

        List<FSC_LookupSearchResult> results = new List<FSC_LookupSearchResult>();

        String accountIcon = 'custom:custom16';

        List<FinServ__FinancialAccount__c> accounts;

        if (excluirVigentes == true) {
            accounts = [
                SELECT Id,
                    Name,
                    FIN_Linea_de_producto__c,
                    RecordType.DeveloperName,
                    FinServ__Status__c
                FROM FinServ__FinancialAccount__c
                WHERE FinServ__PrimaryOwner__c IN :selectedIds
                AND Name LIKE :searchTerm
                AND RecordType.DeveloperName = 'CreditCard'
                AND (
                    FinServ__Status__c = null
                    OR FinServ__Status__c != 'VIGENTE'
                )
                LIMIT :MAX_RESULTS
            ];
        } else {
            accounts = [
                SELECT Id,
                    Name,
                    FIN_Linea_de_producto__c,
                    RecordType.DeveloperName
                FROM FinServ__FinancialAccount__c
                WHERE FinServ__PrimaryOwner__c IN :selectedIds
                AND Name LIKE :searchTerm
                AND RecordType.DeveloperName = 'CreditCard'
                LIMIT :MAX_RESULTS
            ];
        }

        for (FinServ__FinancialAccount__c account : accounts) {
            results.add(
                new FSC_LookupSearchResult(
                    account.Id,
                    'Account',
                    accountIcon,
                    account.FIN_Linea_de_producto__c + ' - ' + account.Name,
                    ''
                )
            );
        }

        results.sort();

        return results;
    }

    @AuraEnabled(cacheable=true scope='global')
    public static List<FSC_LookupSearchResult> getRecentlyViewedTarjetaCredito(
        String accountId,
        Boolean excluirVigentes
    ) {
        List<FSC_LookupSearchResult> results = new List<FSC_LookupSearchResult>();

        List<FinServ__FinancialAccount__c> accounts;

        if (excluirVigentes == true) {
            accounts = [
                SELECT Id, Name, FIN_Linea_de_producto__c, RecordType.DeveloperName, FinServ__Status__c
                FROM FinServ__FinancialAccount__c
                WHERE FinServ__PrimaryOwner__c = :accountId
                AND RecordType.DeveloperName = 'CreditCard'
                AND FinServ__Status__c != 'VIGENTE'
                LIMIT :MAX_RESULTS
            ];
        } else {
            accounts = [
                SELECT Id, Name, FIN_Linea_de_producto__c, RecordType.DeveloperName
                FROM FinServ__FinancialAccount__c
                WHERE FinServ__PrimaryOwner__c = :accountId
                AND RecordType.DeveloperName = 'CreditCard'
                LIMIT :MAX_RESULTS
            ];
        }

        for (FinServ__FinancialAccount__c recentRecord : accounts) {
            results.add(
                new FSC_LookupSearchResult(
                    recentRecord.Id,
                    'Account',
                    'custom:custom16',
                    recentRecord.FIN_Linea_de_producto__c + ' - ' + recentRecord.Name,
                    ''
                )
            );
        }

        return results;
    }

    @AuraEnabled(cacheable=true scope='global')
    public static List<FSC_LookupSearchResult> searchTrasladoBalance(String searchTerm, List<String> selectedIds, String notInclude) {
        searchTerm = '%' + searchTerm + '%';

        List<FSC_LookupSearchResult> results = new List<FSC_LookupSearchResult>();

        String accountIcon = 'custom:custom16';

        List<FinServ__FinancialAccount__c> accounts = [
            SELECT Id, Name, FIN_Linea_de_producto__c, RecordType.DeveloperName
            FROM FinServ__FinancialAccount__c
            WHERE FinServ__PrimaryOwner__c IN :selectedIds
            AND Name LIKE :searchTerm
            AND RecordType.DeveloperName IN ('CheckingAccount', 'SavingsAccount')
            AND Id != :notInclude
            LIMIT :MAX_RESULTS
        ];

        for (FinServ__FinancialAccount__c account : accounts) {
            results.add(
                new FSC_LookupSearchResult(
                    account.Id,
                    'Account',
                    accountIcon,
                    account.FIN_Linea_de_producto__c + ' - ' + account.Name,
                    ''
                )
            );
        }

        results.sort();

        return results;
    }

    @AuraEnabled(cacheable=true scope='global')
    public static List<FSC_LookupSearchResult> getRecentlyViewedTrasladoBalance(String accountId, String notInclude) {
        List<FSC_LookupSearchResult> results = new List<FSC_LookupSearchResult>();

        List<FinServ__FinancialAccount__c> accounts = [
            SELECT Id, Name, FIN_Linea_de_producto__c, RecordType.DeveloperName
            FROM FinServ__FinancialAccount__c
            WHERE FinServ__PrimaryOwner__c = :accountId
            AND RecordType.DeveloperName IN ('CheckingAccount', 'SavingsAccount')
            AND Id != :notInclude
            LIMIT :MAX_RESULTS
        ];

        for (FinServ__FinancialAccount__c recentRecord : accounts) {
            results.add(
                new FSC_LookupSearchResult(
                    recentRecord.Id,
                    'Account',
                    'custom:custom16',
                    recentRecord.FIN_Linea_de_producto__c + ' - ' + recentRecord.Name,
                    ''
                )
            );
        }

        return results;
}

}