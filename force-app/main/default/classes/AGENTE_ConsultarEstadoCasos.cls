public with sharing class AGENTE_ConsultarEstadoCasos {

    private static final Integer PAGE_SIZE = 5;
    private static final Integer MAX_RECENT_CASES = 10;
    private static final Integer MAX_CASE_NUMBER_ZERO_VARIANTS = 12;
    private static final Integer MAX_CASE_MATCH_QUERY_ROWS = 20;
    private static final Integer MAX_BY_NUMBER_FALLBACK_SCAN = 500;

    public class CaseItem {
        @InvocableVariable
        public String caseNumber;

        @InvocableVariable
        public String caseStatus;

        public CaseItem() {}

        public CaseItem(Case c) {
            this.caseNumber = c.CaseNumber;
            this.caseStatus = c.Status;
        }
    }

    public class InvocableInput {
        @InvocableVariable(required=true)
        public String accountId;

        @InvocableVariable(required=true)
        public String mode;
        // BY_NUMBER = buscar caso puntual por numero
        // RECENT = listar ultimos casos

        @InvocableVariable(required=false)
        public String caseNumber;

        @InvocableVariable(required=false)
        public Integer displayOffset;
    }

    public class InvocableOutput {
        @InvocableVariable
        public String status;
        // OK / NOT_FOUND / NO_CASES / INVALID_INPUT / ERROR

        @InvocableVariable
        public String message;

        @InvocableVariable
        public String displayText;

        @InvocableVariable
        public Boolean found;

        @InvocableVariable
        public String outCaseNumber;

        @InvocableVariable
        public String outCaseStatus;

        @InvocableVariable
        public Integer displayedCount;

        @InvocableVariable
        public Integer nextDisplayOffset;

        @InvocableVariable
        public Integer remainingCount;

        @InvocableVariable
        public Boolean hasMore;

        @InvocableVariable
        public String casesJson;
    }

    @InvocableMethod(
        label='Consultar estado de casos'
        description='Busca un caso puntual por numero o lista los ultimos casos del cliente validado, mostrando solo numero de caso y estado.'
    )
    public static List<InvocableOutput> ejecutar(List<InvocableInput> inputs) {
        List<InvocableOutput> outputs = new List<InvocableOutput>();

        if (inputs == null || inputs.isEmpty()) {
            outputs.add(errorOutput('INVALID_INPUT', 'No se recibió información de entrada.'));
            return outputs;
        }

        for (InvocableInput input : inputs) {
            outputs.add(procesar(input));
        }

        return outputs;
    }

    private static InvocableOutput procesar(InvocableInput input) {
        try {
            validarInput(input);

            String normalizedMode = normalizeMode(input.mode);

            if (normalizedMode == 'BY_NUMBER') {
                return buscarPorNumero(input);
            }

            if (normalizedMode == 'RECENT') {
                return listarRecientes(input);
            }

            return errorOutput(
                'INVALID_INPUT',
                'El modo enviado no es válido. Usa BY_NUMBER o RECENT.'
            );

        } catch (AuraHandledException ahe) {
            return errorOutput('INVALID_INPUT', ahe.getMessage());
        } catch (Exception e) {
            return errorOutput('ERROR', 'Ocurrió un error al consultar los casos: ' + e.getMessage());
        }
    }

    private static void validarInput(InvocableInput input) {
        if (input == null) {
            throw new AuraHandledException('La solicitud está vacía.');
        }

        if (String.isBlank(input.accountId)) {
            throw new AuraHandledException('No se recibió el accountId validado.');
        }

        if (String.isBlank(input.mode)) {
            throw new AuraHandledException('No se recibió el modo de consulta.');
        }

        String normalizedMode = normalizeMode(input.mode);

        if (normalizedMode != 'BY_NUMBER' && normalizedMode != 'RECENT') {
            throw new AuraHandledException('El modo de consulta no es válido.');
        }

        if (normalizedMode == 'BY_NUMBER' && String.isBlank(input.caseNumber)) {
            throw new AuraHandledException('Para buscar por número debes enviar caseNumber.');
        }
    }

    private static InvocableOutput buscarPorNumero(InvocableInput input) {
        InvocableOutput out = baseOutput();

        String normalizedInput = normalizeCaseNumber(input.caseNumber);

        if (String.isBlank(normalizedInput)) {
            out.status = 'INVALID_INPUT';
            out.message = 'El número de caso ingresado no es válido.';
            out.displayText = 'No fue posible interpretar el número de caso ingresado.';
            return out;
        }

        Set<String> caseNumberVariants = buildCaseNumberVariants(normalizedInput);

        List<Case> exactCandidates = [
            SELECT Id, CaseNumber, Status, AccountId, CreatedDate
            FROM Case
            WHERE AccountId = :input.accountId
              AND CaseNumber IN :caseNumberVariants
            ORDER BY CreatedDate DESC
            LIMIT :MAX_CASE_MATCH_QUERY_ROWS
        ];

        Case matchedCase = findMatchingCase(exactCandidates, normalizedInput);

        if (matchedCase == null) {
            List<Case> fallbackCandidates = [
                SELECT Id, CaseNumber, Status, AccountId, CreatedDate
                FROM Case
                WHERE AccountId = :input.accountId
                ORDER BY CreatedDate DESC
                LIMIT :MAX_BY_NUMBER_FALLBACK_SCAN
            ];

            matchedCase = findMatchingCase(fallbackCandidates, normalizedInput);
        }

        if (matchedCase == null) {
            out.status = 'NOT_FOUND';
            out.found = false;
            out.message = 'No se encontró un caso asociado al cliente validado con ese número.';
            out.displayText = 'No encontré un caso asociado a tu cuenta con ese número.';
            out.casesJson = '[]';
            return out;
        }

        out.status = 'OK';
        out.found = true;
        out.outCaseNumber = matchedCase.CaseNumber;
        out.outCaseStatus = matchedCase.Status;
        out.displayedCount = 1;
        out.nextDisplayOffset = 0;
        out.remainingCount = 0;
        out.hasMore = false;
        out.message = 'Caso encontrado correctamente.';
        out.displayText = 'Caso #' + matchedCase.CaseNumber + ' - Estado: ' + String.valueOf(matchedCase.Status);
        out.casesJson = JSON.serialize(new List<CaseItem>{ new CaseItem(matchedCase) });

        return out;
    }

    private static InvocableOutput listarRecientes(InvocableInput input) {
        InvocableOutput out = baseOutput();

        Integer safeOffset = input.displayOffset == null ? 0 : input.displayOffset;
        if (safeOffset < 0) {
            safeOffset = 0;
        }

        Integer totalCases = [
            SELECT COUNT()
            FROM Case
            WHERE AccountId = :input.accountId
        ];

        Integer cappedTotal = Math.min(totalCases, MAX_RECENT_CASES);

        if (cappedTotal == 0) {
            out.status = 'NO_CASES';
            out.found = false;
            out.message = 'No se encontraron casos para la cuenta validada.';
            out.displayText = 'No encontré casos asociados a tu cuenta.';
            out.casesJson = '[]';
            return out;
        }

        if (safeOffset >= cappedTotal) {
            out.status = 'NO_CASES';
            out.found = false;
            out.message = 'No hay más casos para mostrar.';
            out.displayText = 'No hay más casos para mostrar.';
            out.casesJson = '[]';
            out.displayedCount = 0;
            out.nextDisplayOffset = safeOffset;
            out.remainingCount = 0;
            out.hasMore = false;
            return out;
        }

        Integer pageLimit = Math.min(PAGE_SIZE, cappedTotal - safeOffset);

        List<Case> pageCases = [
            SELECT Id, CaseNumber, Status, AccountId, CreatedDate
            FROM Case
            WHERE AccountId = :input.accountId
            ORDER BY CreatedDate DESC
            LIMIT :pageLimit
            OFFSET :safeOffset
        ];

        if (pageCases.isEmpty()) {
            out.status = 'NO_CASES';
            out.found = false;
            out.message = 'No hay más casos para mostrar.';
            out.displayText = 'No hay más casos para mostrar.';
            out.casesJson = '[]';
            out.displayedCount = 0;
            out.nextDisplayOffset = safeOffset;
            out.remainingCount = 0;
            out.hasMore = false;
            return out;
        }

        List<CaseItem> items = new List<CaseItem>();
        List<String> lines = new List<String>();

        for (Case c : pageCases) {
            items.add(new CaseItem(c));
            lines.add('Caso #' + c.CaseNumber + ' - Estado: ' + String.valueOf(c.Status));
        }

        Integer nextOffset = safeOffset + pageCases.size();
        Integer remaining = Math.max(0, cappedTotal - nextOffset);
        Boolean hasMore = remaining > 0;

        out.status = 'OK';
        out.found = true;
        out.message = 'Casos obtenidos correctamente.';
        out.displayText = String.join(lines, '\n');
        out.displayedCount = pageCases.size();
        out.nextDisplayOffset = nextOffset;
        out.remainingCount = remaining;
        out.hasMore = hasMore;
        out.casesJson = JSON.serialize(items);

        return out;
    }

    private static Case findMatchingCase(List<Case> candidates, String normalizedInput) {
        for (Case c : candidates) {
            if (normalizeCaseNumber(c.CaseNumber) == normalizedInput) {
                return c;
            }
        }
        return null;
    }

    private static Set<String> buildCaseNumberVariants(String normalizedInput) {
        Set<String> variants = new Set<String>();

        if (String.isBlank(normalizedInput)) {
            return variants;
        }

        variants.add(normalizedInput);

        String current = normalizedInput;
        for (Integer i = 1; i <= MAX_CASE_NUMBER_ZERO_VARIANTS; i++) {
            current = '0' + current;
            variants.add(current);
        }

        return variants;
    }

    private static InvocableOutput baseOutput() {
        InvocableOutput out = new InvocableOutput();
        out.status = '';
        out.message = '';
        out.displayText = '';
        out.found = false;
        out.outCaseNumber = '';
        out.outCaseStatus = '';
        out.displayedCount = 0;
        out.nextDisplayOffset = 0;
        out.remainingCount = 0;
        out.hasMore = false;
        out.casesJson = '[]';
        return out;
    }

    private static InvocableOutput errorOutput(String status, String message) {
        InvocableOutput out = baseOutput();
        out.status = status;
        out.message = message;
        out.displayText = 'No fue posible consultar los casos en este momento.';
        return out;
    }

    private static String normalizeMode(String value) {
        return String.isBlank(value) ? '' : value.trim().toUpperCase();
    }

    private static String normalizeCaseNumber(String value) {
        if (String.isBlank(value)) {
            return '';
        }

        String digitsOnly = value.replaceAll('[^0-9]', '');
        return stripLeadingZeros(digitsOnly);
    }

    private static String stripLeadingZeros(String value) {
        if (String.isBlank(value)) {
            return '';
        }

        Integer i = 0;
        while (i < value.length() - 1 && value.substring(i, i + 1) == '0') {
            i++;
        }

        return value.substring(i);
    }
}