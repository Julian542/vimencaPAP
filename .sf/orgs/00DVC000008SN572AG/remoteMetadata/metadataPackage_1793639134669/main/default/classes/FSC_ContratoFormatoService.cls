public with sharing class FSC_ContratoFormatoService {
    private static final List<String> UNIDADES = new List<String>{
        '', 'UNO', 'DOS', 'TRES', 'CUATRO', 'CINCO', 'SEIS', 'SIETE',
        'OCHO', 'NUEVE', 'DIEZ', 'ONCE', 'DOCE', 'TRECE', 'CATORCE', 'QUINCE'
    };
    private static final List<String> DECENAS = new List<String>{
        '', '', 'VEINTE', 'TREINTA', 'CUARENTA', 'CINCUENTA',
        'SESENTA', 'SETENTA', 'OCHENTA', 'NOVENTA'
    };
    private static final List<String> CENTENAS = new List<String>{
        '', 'CIENTO', 'DOSCIENTOS', 'TRESCIENTOS', 'CUATROCIENTOS',
        'QUINIENTOS', 'SEISCIENTOS', 'SETECIENTOS', 'OCHOCIENTOS', 'NOVECIENTOS'
    };
    private static final List<String> MESES = new List<String>{
        'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
        'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    };

    public static String formatearMonto(Decimal amount) {
        if (amount == null) return '';
        Decimal scaled = amount.setScale(2);
        List<String> parts = String.valueOf(scaled.abs()).split('\\.');
        String integerPart = parts[0];
        String result = '';
        while (integerPart.length() > 3) {
            result = ',' + integerPart.right(3) + result;
            integerPart = integerPart.left(integerPart.length() - 3);
        }
        String decimals = parts.size() > 1 ? parts[1].rightPad(2, '0').left(2) : '00';
        return (scaled < 0 ? '-' : '') + integerPart + result + '.' + decimals;
    }

    public static String montoEnLetras(Decimal amount, String currencyCode) {
        if (amount == null) return '';
        Decimal scaled = amount.abs().setScale(2);
        List<String> parts = String.valueOf(scaled).split('\\.');
        Long integerPart = Long.valueOf(parts[0]);
        String decimals = parts.size() > 1 ? parts[1].rightPad(2, '0').left(2) : '00';
        String currencyName = currencyCode == '2'
            ? 'DÓLARES DE LOS ESTADOS UNIDOS DE AMÉRICA'
            : 'PESOS DOMINICANOS';
        Boolean exactMillion = integerPart >= 1000000 && modLong(integerPart, 1000000L) == 0;
        return apocoparUno(numeroEnLetras(integerPart)) +
            (exactMillion ? ' DE ' : ' ') + currencyName + ' CON ' + decimals + '/100';
    }

    public static String decimalEnLetras(Decimal value) {
        if (value == null) return '';
        Decimal scaled = value.abs().setScale(2);
        List<String> parts = String.valueOf(scaled).split('\\.');
        Long integerPart = Long.valueOf(parts[0]);
        Integer decimals = Integer.valueOf(parts.size() > 1 ? parts[1].rightPad(2, '0').left(2) : '00');
        String result = numeroEnLetras(integerPart);
        return decimals == 0 ? result : result + ' PUNTO ' + numeroEnLetras(decimals);
    }

    public static String numeroEnLetras(Long numericValue) {
        return toWords(numericValue).trim();
    }

    public static String numeroMasculinoEnLetras(Long numericValue) {
        return apocoparUno(numeroEnLetras(numericValue));
    }

    public static String fechaCompleta(Date dateValue) {
        if (dateValue == null) return '';
        return numeroMasculinoEnLetras(dateValue.day()).toLowerCase() + ' (' +
            String.valueOf(dateValue.day()).leftPad(2, '0') + ') días del mes de ' +
            mes(dateValue.month()) + ' del año ' + numeroEnLetras(dateValue.year()).toLowerCase() +
            ' (' + String.valueOf(dateValue.year()) + ')';
    }

    public static String fechaCortaEnLetras(Date dateValue) {
        if (dateValue == null) return '';
        return numeroMasculinoEnLetras(dateValue.day()).toLowerCase() + ' (' +
            String.valueOf(dateValue.day()).leftPad(2, '0') + ') del mes de ' +
            mes(dateValue.month()) + ' del año ' + numeroEnLetras(dateValue.year()).toLowerCase() +
            ' (' + String.valueOf(dateValue.year()) + ')';
    }

    public static Decimal calcularCuota(Decimal principal, Decimal annualRate, Integer months) {
        if (principal == null || months == null || months <= 0 || annualRate == null) return null;
        if (annualRate == 0) return (principal / months).setScale(2);
        Double monthlyRate = Double.valueOf(String.valueOf(annualRate)) / 1200;
        Double payment = Double.valueOf(String.valueOf(principal)) * monthlyRate /
            (1 - Math.pow(1 + monthlyRate, -months));
        return Decimal.valueOf(String.valueOf(payment)).setScale(2);
    }

    public static String simboloMoneda(String currencyCode) {
        return currencyCode == '2' ? 'US$' : 'RD$';
    }

    public static String nombreMoneda(String currencyCode) {
        return currencyCode == '2' ? 'dólares estadounidenses' : 'pesos dominicanos';
    }

    public static String mes(Integer monthNumber) {
        return monthNumber == null || monthNumber < 1 || monthNumber > 12 ? '' : MESES[monthNumber - 1];
    }

    private static String toWords(Long numericValue) {
        if (numericValue == null) return '';
        if (numericValue == 0) return 'CERO';
        if (numericValue < 0) return 'MENOS ' + toWords(-numericValue);
        if (numericValue == 100) return 'CIEN';
        if (numericValue < 16) return UNIDADES[Integer.valueOf(String.valueOf(numericValue))];
        if (numericValue == 16) return 'DIECISÉIS';
        if (numericValue < 20) return 'DIECI' + UNIDADES[Integer.valueOf(String.valueOf(numericValue - 10))];
        if (numericValue == 22) return 'VEINTIDÓS';
        if (numericValue == 23) return 'VEINTITRÉS';
        if (numericValue == 26) return 'VEINTISÉIS';
        if (numericValue < 30) return numericValue == 20 ? 'VEINTE' : 'VEINTI' + UNIDADES[Integer.valueOf(String.valueOf(numericValue - 20))];
        if (numericValue < 100) {
            Long tens = numericValue / 10;
            Long units = modLong(numericValue, 10);
            return DECENAS[Integer.valueOf(String.valueOf(tens))] +
                (units == 0 ? '' : ' Y ' + UNIDADES[Integer.valueOf(String.valueOf(units))]);
        }
        if (numericValue < 1000) {
            Long hundreds = numericValue / 100;
            Long rest = modLong(numericValue, 100);
            return CENTENAS[Integer.valueOf(String.valueOf(hundreds))] + (rest == 0 ? '' : ' ' + toWords(rest));
        }
        if (numericValue < 2000) {
            Long rest = modLong(numericValue, 1000);
            return 'MIL' + (rest == 0 ? '' : ' ' + toWords(rest));
        }
        if (numericValue < 1000000) {
            Long thousands = numericValue / 1000;
            Long rest = modLong(numericValue, 1000);
            return toWords(thousands) + ' MIL' + (rest == 0 ? '' : ' ' + toWords(rest));
        }
        if (numericValue < 2000000) {
            Long rest = modLong(numericValue, 1000000L);
            return 'UN MILLÓN' + (rest == 0 ? '' : ' ' + toWords(rest));
        }
        if (numericValue < 1000000000000L) {
            Long millions = numericValue / 1000000L;
            Long rest = modLong(numericValue, 1000000L);
            return toWords(millions) + ' MILLONES' + (rest == 0 ? '' : ' ' + toWords(rest));
        }
        return 'NÚMERO DEMASIADO GRANDE';
    }

    private static Long modLong(Long leftValue, Long rightValue) {
        return leftValue - ((leftValue / rightValue) * rightValue);
    }

    private static String apocoparUno(String words) {
        List<String> parts = words.split(' ');
        for (Integer index = 0; index < parts.size(); index++) {
            if (parts[index] == 'UNO') parts[index] = 'UN';
            if (parts[index] == 'VEINTIUNO') parts[index] = 'VEINTIÚN';
        }
        return String.join(parts, ' ');
    }
}