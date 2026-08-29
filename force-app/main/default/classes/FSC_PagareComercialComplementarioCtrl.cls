public without sharing class FSC_PagareComercialComplementarioCtrl {
	private static final List<String> UNITS_CARDINAL = new List<String>{
		'',
		'UNO',
		'DOS',
		'TRES',
		'CUATRO',
		'CINCO',
		'SEIS',
		'SIETE',
		'OCHO',
		'NUEVE',
		'DIEZ',
		'ONCE',
		'DOCE',
		'TRECE',
		'CATORCE',
		'QUINCE'
	};
	private static final List<String> UNITS_PLAZO = new List<String>{
		'',
		'UN',
		'DOS',
		'TRES',
		'CUATRO',
		'CINCO',
		'SEIS',
		'SIETE',
		'OCHO',
		'NUEVE',
		'DIEZ',
		'ONCE',
		'DOCE',
		'TRECE',
		'CATORCE',
		'QUINCE'
	};
	private static final List<String> TENS = new List<String>{
		'',
		'',
		'VEINTE',
		'TREINTA',
		'CUARENTA',
		'CINCUENTA',
		'SESENTA',
		'SETENTA',
		'OCHENTA',
		'NOVENTA'
	};
	private static final List<String> HUNDREDS = new List<String>{
		'',
		'CIENTO',
		'DOSCIENTOS',
		'TRESCIENTOS',
		'CUATROCIENTOS',
		'QUINIENTOS',
		'SEISCIENTOS',
		'SETECIENTOS',
		'OCHOCIENTOS',
		'NOVECIENTOS'
	};
	private static final List<String> MESES = new List<String>{
		'enero',
		'febrero',
		'marzo',
		'abril',
		'mayo',
		'junio',
		'julio',
		'agosto',
		'septiembre',
		'octubre',
		'noviembre',
		'diciembre'
	};
	private static final Map<Integer, String> NUMBERS_0_30 = new Map<Integer, String>{
		0 => 'cero',
		1 => 'uno',
		2 => 'dos',
		3 => 'tres',
		4 => 'cuatro',
		5 => 'cinco',
		6 => 'seis',
		7 => 'siete',
		8 => 'ocho',
		9 => 'nueve',
		10 => 'diez',
		11 => 'once',
		12 => 'doce',
		13 => 'trece',
		14 => 'catorce',
		15 => 'quince',
		16 => 'dieciséis',
		17 => 'diecisiete',
		18 => 'dieciocho',
		19 => 'diecinueve',
		20 => 'veinte',
		21 => 'veintiuno',
		22 => 'veintidós',
		23 => 'veintitrés',
		24 => 'veinticuatro',
		25 => 'veinticinco',
		26 => 'veintiséis',
		27 => 'veintisiete',
		28 => 'veintiocho',
		29 => 'veintinueve',
		30 => 'treinta'
	};
	private static final Map<Integer, String> LOWER_TENS = new Map<Integer, String>{
		30 => 'treinta',
		40 => 'cuarenta',
		50 => 'cincuenta',
		60 => 'sesenta',
		70 => 'setenta',
		80 => 'ochenta',
		90 => 'noventa'
	};

	public String fechaString {
		get {
			return fechaNotarial(Date.today());
		}
	}
	public String actoNumeroPagare { get; private set; }
	public String numeroFolioPagare { get; private set; }
	public Integer numeroFolioInicial { get; private set; }
	public String numeroFolioPagina2 { get; private set; }
	public String nombreCliente { get; private set; }
	public String cedula { get; private set; }
	public String direccion { get; private set; }
	public String valorMontoTexto { get; private set; }
	public String valorMonto { get; private set; }
	public String tasaInteresTexto { get; private set; }
	public Integer tasaInteres { get; private set; }
	public String plazoMesesTexto { get; private set; }
	public String plazoMeses { get; private set; }
	public String plazoAniosTexto { get; private set; }
	public String plazoAnios { get; private set; }
	public String cuotaMensualTexto { get; private set; }
	public String cuotaMensual { get; private set; }
	public String seguroVidaMontoTexto { get; private set; }
	public String seguroVidaMonto { get; private set; }
	public String comisionAdminSeguroMontoTexto { get; private set; }
	public String comisionAdminSeguroMonto { get; private set; }
	public String nombreDeudorFirma { get; private set; }
	public String nombreTestigo1Firma { get; private set; }
	public String nombreTestigo2Firma { get; private set; }
	public String nombreNotarioFirma { get; private set; }
	public String cedulaIndividuo1 { get; private set; }
	public String cedulaIndividuo2 { get; private set; }
	public String cedulaIndividuo3 { get; private set; }
	public FSC_IndividuosEnPagareDeCredito__mdt individuo1 { get; private set; }
	public FSC_IndividuosEnPagareDeCredito__mdt individuo2 { get; private set; }
	public FSC_IndividuosEnPagareDeCredito__mdt individuo3 { get; private set; }
	public List<FSC_LoanApplicantFirmanteService.Firmante> loanApplicantFirmantes { get; private set; }

	public FSC_PagareComercialComplementarioCtrl(ApexPages.StandardController sc) {
		Id rlaId = (Id) ApexPages.currentPage().getParameters().get('id');

		ResidentialLoanApplication rla = [
			SELECT
				Id,
				FSC_Monto__c,
				FSC_MontoAprobado__c,
				FSC_Plazo_meses__c,
				FSC_PlazoMesesAprobado__c,
				FSC_TasaInteres__c,
				FSC_TasaInteresAprobada__c,
				FSC_SeguroVidaMonto__c,
				FSC_ComisionAdminSeguroMonto__c,
				FSC_ActoNumeroPagare__c,
				FSC_NumeroFolioPagare__c,
				FSC_Aprobado_con_Condiciones__c,
				Account.Name,
				Account.ACC_NumIdentificacion__c,
				Account.BillingStreet,
				Account.BillingCity,
				Account.BillingState,
				Account.BillingCountry
			FROM ResidentialLoanApplication
			WHERE Id = :rlaId
			LIMIT 1
		];

		setIndividuos(queryIndividuos());

		normalizeApprovedValues(rla);

		Decimal monto = rla.FSC_MontoAprobado__c;
		Integer meses = (rla.FSC_PlazoMesesAprobado__c == null) ? 0 : Integer.valueOf(rla.FSC_PlazoMesesAprobado__c);

		valorMonto = formatAmountEs(monto);
		valorMontoTexto = numberToWordsEs(monto);
		setFolioFields(rla);

		nombreCliente = (rla.Account == null) ? '' : rla.Account.Name;
		cedula = (rla.Account == null) ? '' : formatCedula(rla.Account.ACC_NumIdentificacion__c);
		nombreDeudorFirma = nombreCliente;

		Decimal tasaDec = rla.FSC_TasaInteresAprobada__c;
		Integer tasaEntera = (tasaDec == null) ? 0 : Integer.valueOf(tasaDec.setScale(0));
		tasaInteres = tasaEntera;
		tasaInteresTexto = integerToWordsEs(tasaEntera);

		plazoMeses = (meses == 0) ? '' : String.valueOf(meses);
		plazoMesesTexto = (meses == 0) ? '' : integerToWordsEs(meses);

		Integer anios = meses / 12;
		plazoAnios = (meses == 0) ? '' : String.valueOf(anios);
		plazoAniosTexto = buildPlazoAniosTexto(meses);

		Decimal cuota = (meses > 0 && monto != null) ? (monto / Decimal.valueOf(meses)).setScale(2) : 0;
		cuotaMensual = formatAmountEs(cuota);
		cuotaMensualTexto = numberToWordsEs(cuota);
		seguroVidaMonto = formatAmountEs(rla.FSC_SeguroVidaMonto__c);
		seguroVidaMontoTexto = amountToWordsEs(rla.FSC_SeguroVidaMonto__c);

		comisionAdminSeguroMonto = formatAmountEs(rla.FSC_ComisionAdminSeguroMonto__c);
		comisionAdminSeguroMontoTexto = amountToWordsEs(rla.FSC_ComisionAdminSeguroMonto__c);

		cedulaIndividuo1 = formatCedula(individuo1 == null ? null : individuo1.FSC_Cedula__c);
		cedulaIndividuo2 = formatCedula(individuo2 == null ? null : individuo2.FSC_Cedula__c);
		cedulaIndividuo3 = formatCedula(individuo3 == null ? null : individuo3.FSC_Cedula__c);
		nombreNotarioFirma = (individuo1 == null) ? '' : individuo1.FSC_Nombre__c;
		nombreTestigo1Firma = (individuo2 == null) ? '' : individuo2.FSC_Nombre__c;
		nombreTestigo2Firma = (individuo3 == null) ? '' : individuo3.FSC_Nombre__c;

		direccion = buildDireccion(rla.Account);
		loanApplicantFirmantes = FSC_LoanApplicantFirmanteService.queryFirmantes(rlaId);
	}

	private static List<FSC_IndividuosEnPagareDeCredito__mdt> queryIndividuos() {
		return [
			SELECT Id, FSC_Nombre__c, FSC_NumeroElectoral__c, FSC_Cedula__c, FSC_Direccion__c
			FROM FSC_IndividuosEnPagareDeCredito__mdt
			ORDER BY DeveloperName ASC
		];
	}

	private void setIndividuos(List<FSC_IndividuosEnPagareDeCredito__mdt> individuos) {
		List<FSC_IndividuosEnPagareDeCredito__mdt> testigos = new List<FSC_IndividuosEnPagareDeCredito__mdt>();
		for (FSC_IndividuosEnPagareDeCredito__mdt item : individuos) {
			if (!String.isBlank(item.FSC_NumeroElectoral__c) && individuo1 == null) {
				individuo1 = item;
			} else {
				testigos.add(item);
			}
		}

		individuo2 = firstItem(testigos, 0);
		individuo3 = firstItem(testigos, 1);
		individuo1 = individuo1 == null ? firstItem(individuos, 0) : individuo1;
		individuo2 = individuo2 == null ? firstItem(individuos, 1) : individuo2;
		individuo3 = individuo3 == null ? firstItem(individuos, 2) : individuo3;
	}

	private static FSC_IndividuosEnPagareDeCredito__mdt firstItem(List<FSC_IndividuosEnPagareDeCredito__mdt> items, Integer index) {
		return items != null && items.size() > index ? items[index] : null;
	}

	private static void normalizeApprovedValues(ResidentialLoanApplication rla) {
		if (rla.FSC_Aprobado_con_Condiciones__c != false) {
			return;
		}

		rla.FSC_MontoAprobado__c = rla.FSC_Monto__c;
		rla.FSC_PlazoMesesAprobado__c = (rla.FSC_Plazo_meses__c == null) ? null : Integer.valueOf(rla.FSC_Plazo_meses__c);
		rla.FSC_TasaInteresAprobada__c = rla.FSC_TasaInteres__c;
	}

	private void setFolioFields(ResidentialLoanApplication rla) {
		actoNumeroPagare = String.isBlank(rla.FSC_ActoNumeroPagare__c) ? '' : rla.FSC_ActoNumeroPagare__c;
		numeroFolioPagare = normalizeTextValue(rla.get('FSC_NumeroFolioPagare__c'));
		numeroFolioInicial = tryParseInteger(rla.get('FSC_NumeroFolioPagare__c'));
		numeroFolioPagina2 = buildNumeroFolioOffset(1);
	}

	private static String buildPlazoAniosTexto(Integer meses) {
		if (meses == null || meses == 0) {
			return '';
		}

		Integer anios = meses / 12;
		Integer mesesRestantes = Math.mod(meses, 12);
		List<String> parts = new List<String>();
		if (anios > 0) {
			parts.add(buildPlazoPart(anios, ' AÑO', ' AÑOS'));
		}
		if (mesesRestantes > 0) {
			parts.add(buildPlazoPart(mesesRestantes, ' MES', ' MESES'));
		}
		return String.join(parts, ' Y ');
	}

	private static String buildPlazoPart(Integer value, String singular, String plural) {
		return integerToWordsEsPlazo(value) + (value == 1 ? singular : plural);
	}

	private static String amountToWordsEs(Decimal amount) {
		return amount == null ? '' : numberToWordsEs(amount.setScale(2));
	}

	private static String buildDireccion(Account account) {
		List<String> parts = new List<String>();
		if (account != null) {
			addIfNotBlank(parts, account.BillingStreet);
			addIfNotBlank(parts, account.BillingCity);
			addIfNotBlank(parts, account.BillingState);
			addIfNotBlank(parts, account.BillingCountry);
		}
		return String.join(parts, ', ');
	}

	private static void addIfNotBlank(List<String> values, String value) {
		if (!String.isBlank(value)) {
			values.add(value);
		}
	}

	public Boolean getHasNumeroFolio() {
		return !String.isBlank(numeroFolioPagare);
	}

	public Boolean getHasNumeroFolioPagina2() {
		return !String.isBlank(numeroFolioPagina2);
	}

	public Integer getLoanApplicantFirmantesSize() {
		return loanApplicantFirmantes == null ? 0 : loanApplicantFirmantes.size();
	}

	private static String normalizeTextValue(Object value) {
		return value == null ? '' : String.valueOf(value).trim();
	}

	private static Integer tryParseInteger(Object value) {
		if (value == null) {
			return null;
		}

		try {
			if (value instanceof Integer) {
				return (Integer) value;
			}

			if (value instanceof Long) {
				return Integer.valueOf(String.valueOf(value));
			}

			if (value instanceof Decimal) {
				return ((Decimal) value).intValue();
			}

			return Decimal.valueOf(String.valueOf(value).trim()).intValue();
		} catch (Exception e) {
			return null;
		}
	}

	private String buildNumeroFolioOffset(Integer offset) {
		if (numeroFolioInicial == null) {
			return '';
		}

		return String.valueOf(numeroFolioInicial + offset);
	}

	@TestVisible
	private static String formatAmountEs(Decimal amount) {
		if (amount == null)
			return '';

		Decimal scaledAmount = amount.setScale(2);
		List<String> parts = String.valueOf(scaledAmount.abs()).split('\\.');
		String entero = parts[0];
		String decimalPart = (parts.size() > 1) ? parts[1] : '00';
		Integer decimales = Integer.valueOf(decimalPart.rightPad(2, '0').substring(0, 2));

		String enteroFormateado = '';
		while (entero.length() > 3) {
			enteroFormateado = '.' + entero.right(3) + enteroFormateado;
			entero = entero.left(entero.length() - 3);
		}
		enteroFormateado = entero + enteroFormateado;

		String signo = scaledAmount < 0 ? '-' : '';
		return signo + enteroFormateado + ',' + String.valueOf(decimales).leftPad(2, '0');
	}

	@TestVisible
	private static String formatCedula(String rawCedula) {
		if (String.isBlank(rawCedula))
			return '';

		String onlyDigits = rawCedula.replaceAll('[^0-9]', '');
		if (String.isBlank(onlyDigits))
			return rawCedula;
		if (onlyDigits.length() > 11) {
			onlyDigits = onlyDigits.right(11);
		}
		onlyDigits = onlyDigits.leftPad(11, '0');

		return onlyDigits.substring(0, 3) + '-' + onlyDigits.substring(3, 10) + '-' + onlyDigits.substring(10, 11);
	}

	@TestVisible
	private static String formatCedula(Decimal rawCedula) {
		if (rawCedula == null)
			return '';
		return formatCedula(String.valueOf(rawCedula.setScale(0).longValue()));
	}

	@TestVisible
	private static Long modLong(Long a, Long b) {
		if (b == 0)
			return 0;
		Long q = a / b;
		return a - (q * b);
	}

	@TestVisible
	private static String integerToWordsEs(Integer n) {
		if (n == null)
			return '';
		Long ln = (Long) n;
		return toWordsEs(ln).trim();
	}
	@TestVisible
	private static String integerToWordsEsPlazo(Integer n) {
		if (n == null)
			return '';
		Long ln = (Long) n;
		return toWordsEsPlazo(ln).trim();
	}

	@TestVisible
	private static String numberToWordsEs(Decimal amount) {
		if (amount == null)
			return '';

		Decimal absAmt = amount.abs().setScale(2);
		List<String> parts = String.valueOf(absAmt).split('\\.');
		Long entero = Long.valueOf(parts[0]);
		Integer centavos = Integer.valueOf(((parts.size() > 1) ? parts[1] : '00').rightPad(2, '0').substring(0, 2));

		String letras = toWordsEs(entero).trim();
		String cent = String.valueOf(centavos).leftPad(2, '0');

		return letras + ' CON ' + cent + '/100';
	}

	@TestVisible
	private static String toWordsEs(Long n) {
		return toWordsEs(n, UNITS_CARDINAL, true);
	}

	@TestVisible
	private static String toWordsEsPlazo(Long n) {
		return toWordsEs(n, UNITS_PLAZO, false);
	}

	private static String toWordsEs(Long n, List<String> units, Boolean useUnitsRecursively) {
		if (n == 0) {
			return 'CERO';
		}
		if (n < 0) {
			return 'MENOS ' + toWordsEs(-n, units, useUnitsRecursively);
		}
		if (n == 100) {
			return 'CIEN';
		}
		if (n < 16) {
			return units[Integer.valueOf(n)];
		}
		if (n < 20) {
			return 'DIECI' + units[Integer.valueOf(n - 10)];
		}
		if (n < 30) {
			return (n == 20) ? 'VEINTE' : 'VEINTI' + units[Integer.valueOf(n - 20)];
		}
		if (n < 100) {
			Long dec = n / 10;
			Long uni = modLong(n, 10);
			String left = TENS[Integer.valueOf(dec)];
			return (uni == 0) ? left : (left + ' Y ' + units[Integer.valueOf(uni)]);
		}

		List<String> recursiveUnits = useUnitsRecursively ? units : UNITS_CARDINAL;
		if (n < 1000) {
			Long cen = n / 100;
			Long rest = modLong(n, 100);
			String left = HUNDREDS[Integer.valueOf(cen)];
			return (rest == 0) ? left : (left + ' ' + toWordsEs(rest, recursiveUnits, useUnitsRecursively));
		}
		if (n < 2000) {
			Long rest = modLong(n, 1000);
			return (rest == 0) ? 'MIL' : ('MIL ' + toWordsEs(rest, recursiveUnits, useUnitsRecursively));
		}
		if (n < 1000000) {
			Long mil = n / 1000;
			Long rest = modLong(n, 1000);
			String left = toWordsEs(mil, recursiveUnits, useUnitsRecursively) + ' MIL';
			return (rest == 0) ? left : (left + ' ' + toWordsEs(rest, recursiveUnits, useUnitsRecursively));
		}
		if (n < 2000000) {
			Long rest = modLong(n, 1000000L);
			return (rest == 0) ? 'UN MILLON' : ('UN MILLON ' + toWordsEs(rest, recursiveUnits, useUnitsRecursively));
		}
		if (n < 1000000000000L) {
			Long mill = n / 1000000L;
			Long rest = modLong(n, 1000000L);
			String left = toWordsEs(mill, recursiveUnits, useUnitsRecursively) + ' MILLONES';
			return (rest == 0) ? left : (left + ' ' + toWordsEs(rest, recursiveUnits, useUnitsRecursively));
		}

		return 'NUMERO DEMASIADO GRANDE';
	}

	public static String fechaNotarial(Date d) {
		Integer day = d.day();
		Integer year = d.year();
		if (year < 2000 || year > 2099) {
			throw new IllegalArgumentException('Solo soporta años 2000..2099');
		}

		String diaLetras = numeroALetras_0_99(day);
		String dd = String.valueOf(day);
		String mes = mesEnLetras(d.month());
		String anioLetras = numeroALetras_0_99(Math.mod(year, 100));
		String yyyy = String.valueOf(year);

		return 'a los ' + diaLetras + ' (' + dd + ') días del mes de ' + mes + ' del año dos mil ' + anioLetras + ' (' + yyyy + ')';
	}

	@TestVisible
	private static String mesEnLetras(Integer m) {
		return MESES[m - 1];
	}

	@TestVisible
	private static String numeroALetras_0_99(Integer n) {
		if (n == null)
			return '';
		if (n < 0 || n > 99)
			throw new IllegalArgumentException('Solo soporta 0..99');

		if (NUMBERS_0_30.containsKey(n))
			return NUMBERS_0_30.get(n);

		Integer dec = (n / 10) * 10;
		Integer uni = Math.mod(n, 10);

		return LOWER_TENS.get(dec) + ' y ' + NUMBERS_0_30.get(uni);
	}
}