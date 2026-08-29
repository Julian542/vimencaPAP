public with sharing class ValidacionContraListasIE {
    
    
    /*
     * ejemplo de llamada para usar en la consola anonima
        ValidacionContraListasIE.RequestDTO requestData =
        ValidacionContraListasIE.buildRequest(
            'cedula',        
            '00101651586',   
            '',              
            'FELIX',        
            'RAMON',         
            'BAUTISTA',     
            'ROSARIO',       
            null,           
            ''              
        );
    
        System.debug('REQUEST:');
        System.debug(ValidacionContraListasIE.toPrettyJson(requestData));
        
        ValidacionContraListasIE.ResultDTO result =
            ValidacionContraListasIE.consultar(requestData);
        
        System.debug('RESULTADO:');
        System.debug(ValidacionContraListasIE.toPrettyJson(result));
    */
    
    public class RequestDTO {
        public String identificationType;
        public String identificationNumber;
        public String commercialName;
        public String firstName;
        public String middleName;
        public String lastName;
        public String lastName2;
        public String birthDate;
        public String nationality;
    }
    
    public class ServiceResponseDTO {
        public String responseCode;
        public String responseDesc;
        public String internalCoincidences;
        public String externalCoincidences;
        public String FoundList;
        public Integer cumplo360Relevancia;
    }
    
    public class ResultDTO {
        public Boolean success;
        public Integer statusCode;
        public String status;
        public String rawRequest;
        public String rawResponse;
        public String errorMessage;
        
        public String responseCode;
        public String responseDesc;
        public String internalCoincidences;
        public String externalCoincidences;
        public String foundList;
        public Integer cumplo360Relevancia;
        
        public Boolean hasInternalCoincidences;
        public Boolean hasExternalCoincidences;
        public Boolean hasAnyCoincidences;
    }
    
    public class ValidacionContraListasException extends Exception {}
    
    public static ResultDTO consultar(RequestDTO requestData) {
        validateRequest(requestData);
        
        HttpRequest request = buildHttpRequest(requestData);
        HttpResponse response;
        
        try {
            response = new Http().send(request);
            return buildResult(request, response);
        } catch (Exception e) {
            ResultDTO result = new ResultDTO();
            result.success = false;
            result.statusCode = null;
            result.status = null;
            result.rawRequest = request.getBody();
            result.rawResponse = null;
            result.errorMessage = e.getMessage() + ' - ' + e.getStackTraceString();
            result.hasInternalCoincidences = false;
            result.hasExternalCoincidences = false;
            result.hasAnyCoincidences = false;
            return result;
        }
    }
    
    public static void updateAccount(ResultDTO recordData, Id recordId) {
        Account acc = [
            SELECT Id,
            ACC_Resultado_Validacion__c,
            ACC_Estado__c,
            ACC_SubEstado__c,
            ACC_Condicion__c,
            ACC_Coincidencia_Listas_Externas__c,
            ACC_Coincidencia_Listas_Internas__c,
            ACC_Listas__c,
            ACC_Ultima_Actualizacion_Listas_Internas__c,
            ACC_Ultima_Actualizacion_Listas_Externas__c
            FROM Account
            WHERE Id = :recordId
            LIMIT 1
        ];
        
        String coincidenciaLI = normalizeYN(recordData.internalCoincidences);
        String coincidenciaLE = normalizeYN(recordData.externalCoincidences);
        
        List<Matriz_lista_control__c> matrizCase = [
            SELECT Id,
            MAT_Resultado_validacion__c,
            MAT_Estado__c,
            MAT_Sub_estado__c
            FROM Matriz_lista_control__c
            WHERE MAT_Coincidencia_en_listas_externas__c = :coincidenciaLE
            AND MAT_Coincidencia_en_listas__c = :coincidenciaLI
            LIMIT 1
        ];
        
        if (matrizCase.isEmpty()) {
            System.debug(
                'No existe configuración en Matriz_lista_control__c para LI=' +
                coincidenciaLI +
                ' LE=' +
                coincidenciaLE
            );
            return;
        }
        
        if (acc.ACC_Condicion__c == 'CLIENTE') {
            acc.ACC_Resultado_Validacion__c = matrizCase[0].MAT_Resultado_validacion__c;
        } else {
            acc.ACC_Resultado_Validacion__c = matrizCase[0].MAT_Resultado_validacion__c;
            acc.ACC_Estado__c = matrizCase[0].MAT_Estado__c;
            acc.ACC_SubEstado__c = matrizCase[0].MAT_Sub_estado__c != null
                ? matrizCase[0].MAT_Sub_estado__c.toUpperCase()
                : null;
        }
        
        acc.ACC_Coincidencia_Listas_Externas__c = coincidenciaLE == 'Y';
        acc.ACC_Coincidencia_Listas_Internas__c = coincidenciaLI == 'Y';
        acc.ACC_Listas__c = recordData.foundList;
        acc.ACC_Ultima_Actualizacion_Listas_Internas__c = System.now();
        acc.ACC_Ultima_Actualizacion_Listas_Externas__c = System.now();
        
        try {
            update acc;
        } catch (Exception e) {
            System.debug('ERROR NO CONTROLADO EN UPDATE ACCOUNT :: ' + e.getMessage());
        }
    }
    
    public static HttpRequest buildHttpRequest(RequestDTO requestData) {
        HttpRequest request = new HttpRequest();
        
        request.setEndpoint(Label.EndpointBlacklistRest);
        request.setMethod('POST');
        request.setTimeout(120000);
        
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setHeader('X-API-Key', Label.BlacklistApiKey);
        
        request.setBody(JSON.serialize(requestData));
        
        return request;
    }
    
    private static ResultDTO buildResult(HttpRequest request, HttpResponse response) {
        ResultDTO result = new ResultDTO();
        
        result.statusCode = response.getStatusCode();
        result.status = response.getStatus();
        result.rawRequest = request.getBody();
        result.rawResponse = response.getBody();
        
        if (response.getStatusCode() != 200) {
            result.success = false;
            result.errorMessage =
                'Error HTTP ' +
                response.getStatusCode() +
                ': ' +
                response.getStatus() +
                ' - ' +
                response.getBody();
            
            result.hasInternalCoincidences = false;
            result.hasExternalCoincidences = false;
            result.hasAnyCoincidences = false;
            
            return result;
        }
        
        if (String.isBlank(response.getBody())) {
            result.success = false;
            result.errorMessage = 'El servicio respondió HTTP 200 pero el body está vacío.';
            result.hasInternalCoincidences = false;
            result.hasExternalCoincidences = false;
            result.hasAnyCoincidences = false;
            return result;
        }
        
        ServiceResponseDTO serviceResponse;
        
        try {
            serviceResponse = (ServiceResponseDTO) JSON.deserialize(
                response.getBody(),
                ServiceResponseDTO.class
            );
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'No fue posible deserializar la respuesta JSON: ' + e.getMessage();
            result.hasInternalCoincidences = false;
            result.hasExternalCoincidences = false;
            result.hasAnyCoincidences = false;
            return result;
        }
        
        result.responseCode = normalizeString(serviceResponse.responseCode);
        result.responseDesc = normalizeString(serviceResponse.responseDesc);
        result.internalCoincidences = normalizeYN(serviceResponse.internalCoincidences);
        result.externalCoincidences = normalizeYN(serviceResponse.externalCoincidences);
        result.foundList = normalizeString(serviceResponse.FoundList);
        result.cumplo360Relevancia = serviceResponse.cumplo360Relevancia;
        
        result.hasInternalCoincidences = result.internalCoincidences == 'Y';
        result.hasExternalCoincidences = result.externalCoincidences == 'Y';
        result.hasAnyCoincidences = result.hasInternalCoincidences || result.hasExternalCoincidences;
        
        result.success = result.responseCode == '0';
        
        if (!result.success) {
            result.errorMessage =
                'El servicio respondió con error funcional. Código: ' +
                result.responseCode +
                '. Descripción: ' +
                result.responseDesc;
        }
        
        return result;
    }
    
    private static void validateRequest(RequestDTO requestData) {
        if (requestData == null) {
            throw new ValidacionContraListasException('El request no puede ser null.');
        }
        
        if (String.isBlank(requestData.identificationType)) {
            throw new ValidacionContraListasException('identificationType es requerido.');
        }
        
        if (String.isBlank(requestData.identificationNumber)) {
            throw new ValidacionContraListasException('identificationNumber es requerido.');
        }
        
        /*
El API permite commercialName y nombres.
Para persona física, deberían venir firstName / lastName.
Para empresa, probablemente commercialName.
Dejamos validación flexible para no bloquear casos reales.
*/
        if (
            String.isBlank(requestData.commercialName) &&
            String.isBlank(requestData.firstName) &&
            String.isBlank(requestData.lastName)
        ) {
            throw new ValidacionContraListasException(
                'Debe enviarse commercialName o datos de nombre de persona.'
            );
        }
    }
    
    public static RequestDTO buildRequest(
        String identificationType,
        String identificationNumber,
        String commercialName,
        String firstName,
        String middleName,
        String lastName,
        String lastName2,
        Date birthDate,
        String nationality
    ) {
        RequestDTO req = new RequestDTO();
        
        req.identificationType = normalizeIdentificationType(identificationType);
        req.identificationNumber = normalizeString(identificationNumber);
        req.commercialName = normalizeString(commercialName);
        req.firstName = normalizeString(firstName);
        req.middleName = normalizeString(middleName);
        req.lastName = normalizeString(lastName);
        req.lastName2 = normalizeString(lastName2);
        req.birthDate = formatDateYYYYMMDD(birthDate);
        req.nationality = normalizeString(nationality).toUpperCase();
        
        return req;
    }
    
    public static String toPrettyJson(Object value) {
        return JSON.serializePretty(value);
    }
    
    private static String normalizeString(Object value) {
        if (value == null) {
            return '';
        }
        
        return String.valueOf(value).trim();
    }
    
    private static String normalizeYN(String value) {
        String normalized = normalizeString(value).toUpperCase();
        
        if (
            normalized == 'Y' ||
            normalized == 'S' ||
            normalized == 'SI' ||
            normalized == 'SÍ' ||
            normalized == 'YES' ||
            normalized == 'TRUE'
        ) {
            return 'Y';
        }
        
        return 'N';
    }
    
    private static String normalizeIdentificationType(String value) {
        String normalized = normalizeString(value).toLowerCase();
        
        if (String.isBlank(normalized)) {
            return '';
        }
        
        if (
            normalized == 'cédula' ||
            normalized == 'cedula' ||
            normalized == 'ced' ||
            normalized == 'c'
        ) {
            return 'cedula';
        }
        
        return normalized;
    }
    
    private static String formatDateYYYYMMDD(Date value) {
        if (value == null) {
            return '';
        }
        
        String monthValue = value.month() < 10
            ? '0' + String.valueOf(value.month())
            : String.valueOf(value.month());
        
        String dayValue = value.day() < 10
            ? '0' + String.valueOf(value.day())
            : String.valueOf(value.day());
        
        return String.valueOf(value.year()) + monthValue + dayValue;
    }
}