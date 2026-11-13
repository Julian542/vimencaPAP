@IsTest
private class FSC_ConsultaProdFinRemoteActionTest {

    private static Account createAccount() {
        Account acc = new Account(
            Name = 'Cuenta Remote Action ' + System.now().getTime()
        );
        insert acc;
        return acc;
    }

    private static Map<String, Object> buildArgs(Map<String, Object> input) {
        return new Map<String, Object>{
            'input' => input,
            'output' => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        };
    }

    @IsTest
    static void call_startAsync_returnsSuccessWhenAccountIdIsValid() {
        Account acc = createAccount();
        Callable action = new FSC_ConsultaProdFinRemoteAction();

        Map<String, Object> result = (Map<String, Object>) action.call(
            'startAsync',
            buildArgs(new Map<String, Object>{ 'accountId' => acc.Id })
        );

        System.assertEquals(true, result.get('success'));
        System.assertEquals('Proceso encolado correctamente.', result.get('message'));
        System.assertEquals(acc.Id, result.get('accountId'));
    }

    @IsTest
    static void call_iniciarConsulta_acceptsAlternativeKeyAfterInvalidValue() {
        Account acc = createAccount();
        Callable action = new FSC_ConsultaProdFinRemoteAction();

        Map<String, Object> result = (Map<String, Object>) action.call(
            'iniciarConsultaProdFinAsync',
            buildArgs(new Map<String, Object>{
                'accountId' => 'valor-invalido',
                'ContextId' => acc.Id
            })
        );

        System.assertEquals(true, result.get('success'));
        System.assertEquals(acc.Id, result.get('accountId'));
    }

    @IsTest
    static void call_returnsErrorWhenInputIsNull() {
        Callable action = new FSC_ConsultaProdFinRemoteAction();

        Map<String, Object> result = (Map<String, Object>) action.call(
            'startAsync',
            buildArgs(null)
        );

        System.assertEquals(false, result.get('success'));
        System.assert(String.valueOf(result.get('message')).contains('Account Id'));
    }

    @IsTest
    static void call_returnsErrorWhenActionIsNotSupported() {
        Callable action = new FSC_ConsultaProdFinRemoteAction();

        Map<String, Object> result = (Map<String, Object>) action.call(
            'accionNoSoportada',
            buildArgs(new Map<String, Object>())
        );

        System.assertEquals(false, result.get('success'));
        System.assert(String.valueOf(result.get('message')).contains('accionNoSoportada'));
    }
}