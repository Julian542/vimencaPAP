@IsTest
private class FSC_ContratoRedaccionServiceTest {
	@IsTest
	static void parteConcuerdaGeneroYNumero() {
		FSC_ContratoParte hombre = FSC_ContratoParte.crear('PRESTATARIO', FSC_ContratoParte.SEXO_MASCULINO, false);
		System.assertEquals('EL PRESTATARIO', hombre.nombre);
		System.assertEquals('', hombre.n);
		System.assertEquals('o', hombre.o);
		System.assertEquals('es', hombre.es);
		System.assertEquals('lo', hombre.lo);
		System.assertEquals('le', hombre.le);
		System.assertEquals('', hombre.s);
		System.assertEquals('este', hombre.este);
		System.assertEquals('deudor', hombre.deudor);

		FSC_ContratoParte mujer = FSC_ContratoParte.crear('PRESTATARIO - COMPRADOR', FSC_ContratoParte.SEXO_FEMENINO, false);
		System.assertEquals('LA PRESTATARIA - COMPRADORA', mujer.nombre);
		System.assertEquals('deudora', mujer.deudor);
		System.assertEquals('esta', mujer.este);

		FSC_ContratoParte mujeres = FSC_ContratoParte.crear(
			'COMPRADOR - GARANTE REAL',
			new List<String>{ FSC_ContratoParte.SEXO_FEMENINO, FSC_ContratoParte.SEXO_FEMENINO },
			false
		);
		System.assertEquals('LAS COMPRADORAS - GARANTES REALES', mujeres.nombre);
		System.assertEquals('n', mujeres.n);
		System.assertEquals('as', mujeres.o);
		System.assertEquals('son', mujeres.es);
		System.assertEquals('las', mujeres.lo);
		System.assertEquals('les', mujeres.le);
		System.assertEquals('s', mujeres.s);
		System.assertEquals('estas', mujeres.este);
		System.assertEquals('deudoras', mujeres.deudor);

		FSC_ContratoParte mixtos = FSC_ContratoParte.crear(
			'PRESTATARIO - GARANTE MOBILIARIO',
			new List<String>{ FSC_ContratoParte.SEXO_FEMENINO, FSC_ContratoParte.SEXO_MASCULINO },
			false
		);
		System.assertEquals('LOS PRESTATARIOS - GARANTES MOBILIARIOS', mixtos.nombre);
		System.assertEquals('estos', mixtos.este);
		System.assertEquals('deudores', mixtos.deudor);
	}

	@IsTest
	static void empresaEsFemeninaSalvoQueTengaCodeudores() {
		System.assertEquals('LA PRESTATARIA', FSC_ContratoParte.crear('PRESTATARIO', (String) null, true).nombre);
		System.assertEquals(
			'LOS PRESTATARIOS',
			FSC_ContratoParte.crear('PRESTATARIO', new List<String>{ null, FSC_ContratoParte.SEXO_FEMENINO }, true).nombre
		);
		System.assertEquals('EL PRESTATARIO', FSC_ContratoParte.crear('PRESTATARIO', new List<String>(), false).nombre);
	}

	@IsTest
	static void combinaSujetosEnPlural() {
		FSC_ContratoParte deudora = FSC_ContratoParte.crear('PRESTATARIO', FSC_ContratoParte.SEXO_FEMENINO, false);
		FSC_ContratoParte garante = FSC_ContratoParte.crear('GARANTE SOLIDARIO', FSC_ContratoParte.SEXO_FEMENINO, false);
		FSC_ContratoParte ambas = FSC_ContratoParte.combinar(deudora, garante);
		System.assertEquals('LA PRESTATARIA y LA GARANTE SOLIDARIA', ambas.nombre);
		System.assertEquals(true, ambas.plural);
		System.assertEquals(true, ambas.femenino);
		System.assertEquals(deudora, FSC_ContratoParte.combinar(deudora, null));
	}

	@IsTest
	static void seguroDistingueEndosadoYColectivo() {
		FSC_ContratoSeguro endosado = FSC_ContratoSeguro.crear(
			FSC_ContratoSeguro.TIPO_INCENDIO,
			'POL-1',
			'Aseguradora',
			'Santo Domingo',
			Date.newInstance(2026, 9, 15),
			1500000,
			null,
			24,
			'1'
		);
		System.assertEquals(true, endosado.aplica);
		System.assertEquals(true, endosado.endosado);
		System.assertEquals(true, endosado.esIncendio);
		System.assertEquals(false, endosado.esVida);
		System.assertEquals(false, endosado.esVehiculo);
		System.assert(endosado.fechaEndoso.contains('(2026)'));
		System.assertEquals('1,500,000.00', endosado.montoNumero);
		System.assertEquals('RD$', endosado.simboloMoneda);

		FSC_ContratoSeguro colectivo = FSC_ContratoSeguro.crear(
			FSC_ContratoSeguro.TIPO_VIDA,
			'POL-2',
			'Aseguradora',
			'Santo Domingo',
			null,
			null,
			850,
			36,
			'1'
		);
		System.assertEquals(false, colectivo.endosado);
		System.assertEquals('36', colectivo.cuotasNumero);
		System.assertEquals('treinta y seis', colectivo.cuotasLetras);
		System.assertEquals('850.00', colectivo.primaNumero);

		FSC_ContratoSeguro ninguno = FSC_ContratoSeguro.noAplica(FSC_ContratoSeguro.TIPO_VEHICULO);
		System.assertEquals(false, ninguno.aplica);
		System.assertEquals(true, ninguno.esVehiculo);
		System.assertEquals('', FSC_ContratoSeguro.crear(FSC_ContratoSeguro.TIPO_VIDA, null, null, null, null, null, null, null, '1').cuotasLetras);
	}

	@IsTest
	static void reglasDeSeguroSegunDeudorYGarantia() {
		System.assertEquals(true, FSC_ContratoRedaccionService.aplicaSeguroVida(true, FSC_RLAContractTemplateResolver.TEMPLATE_SOLA_FIRMA));
		System.assertEquals(true, FSC_ContratoRedaccionService.aplicaSeguroVida(true, FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_HIPOTECARIA));
		System.assertEquals(
			false,
			FSC_ContratoRedaccionService.aplicaSeguroVida(true, FSC_RLAContractTemplateResolver.TEMPLATE_CONSUMO_GARANTIA_MOBILIARIA)
		);
		System.assertEquals(
			false,
			FSC_ContratoRedaccionService.aplicaSeguroVida(true, FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_MOBILIARIA_CON_POSESION)
		);
		System.assertEquals(false, FSC_ContratoRedaccionService.aplicaSeguroVida(false, FSC_RLAContractTemplateResolver.TEMPLATE_SOLA_FIRMA));

		System.assertEquals(
			FSC_ContratoSeguro.TIPO_VEHICULO,
			FSC_ContratoRedaccionService.tipoSeguroPropiedad(FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_MOBILIARIA_SIN_POSESION)
		);
		System.assertEquals(
			FSC_ContratoSeguro.TIPO_INCENDIO,
			FSC_ContratoRedaccionService.tipoSeguroPropiedad(FSC_RLAContractTemplateResolver.TEMPLATE_HIPOTECARIO_PERSONA_FISICA)
		);
		System.assertEquals(null, FSC_ContratoRedaccionService.tipoSeguroPropiedad(FSC_RLAContractTemplateResolver.TEMPLATE_SOLA_FIRMA));
	}

	@IsTest
	static void generalesDePersonaConSexoYDocumento() {
		String mujer = FSC_ContratoRedaccionService.generalesPersona(
			'ANA PÉREZ',
			FSC_ContratoParte.SEXO_FEMENINO,
			'Dominicana',
			'Soltera',
			'40200695563',
			'Calle 4 No. 17'
		);
		System.assertEquals(
			'ANA PÉREZ, dominicana, mayor de edad, soltera, portadora de la cédula de identidad y electoral No. 402-0069556-3, ' +
			'domiciliada y residente en Calle 4 No. 17',
			mujer
		);
		String sinSexo = FSC_ContratoRedaccionService.generalesPersona('JOHN DOE', null, 'Estadounidense', 'Casado', 'P1234567', 'Miami');
		System.assert(sinSexo.contains('portador(a) del documento de identidad No. P1234567'));
		System.assertEquals('101-0214-1', FSC_ContratoRedaccionService.formatearCedula('101-0214-1'));
		System.assertEquals('1-31-71634-2', FSC_ContratoRedaccionService.formatearRnc('131716342'));
		System.assertEquals('RNC-X', FSC_ContratoRedaccionService.formatearRnc('RNC-X'));
		System.assertEquals('portador', FSC_ContratoRedaccionService.concordar('portador', FSC_ContratoParte.SEXO_MASCULINO));
	}

	@IsTest
	static void generalesDeEmpresaConUnoOVariosRepresentantes() {
		FSC_ContratoRedaccionService.Representante nicole = representante('NICOLE UREÑA', 'Gerente', FSC_ContratoParte.SEXO_FEMENINO);
		FSC_ContratoRedaccionService.Representante wilki = representante('WILKI GIL', 'Gerente', FSC_ContratoParte.SEXO_MASCULINO);

		String dos = FSC_ContratoRedaccionService.generalesEmpresa(
			'COMIENDO BUENO GIL RD, S.R.L.',
			'131716342',
			'145454SD',
			'Calle 4 No. 17',
			new List<FSC_ContratoRedaccionService.Representante>{ nicole, wilki }
		);
		System.assert(dos.startsWith('COMIENDO BUENO GIL RD, S.R.L., sociedad comercial organizada y existente'));
		System.assert(dos.contains('RNC No. 1-31-71634-2, Registro Mercantil No. 145454SD'));
		System.assert(dos.contains('debidamente representada por sus Gerentes, señores NICOLE UREÑA, dominicana'));
		System.assert(dos.contains(', y WILKI GIL, dominicano'));

		String una = FSC_ContratoRedaccionService.generalesEmpresa(
			'EMPRESA, S.R.L.',
			'131716342',
			'RM',
			'Domicilio',
			new List<FSC_ContratoRedaccionService.Representante>{ nicole, null }
		);
		System.assert(una.contains('debidamente representada por su Gerente, señora NICOLE UREÑA'));

		FSC_ContratoRedaccionService.Representante presidente = representante('ANA GIL', 'Presidente Ejecutivo', FSC_ContratoParte.SEXO_FEMENINO);
		String distintos = FSC_ContratoRedaccionService.generalesEmpresa(
			'EMPRESA, S.R.L.',
			'131716342',
			'RM',
			'Domicilio',
			new List<FSC_ContratoRedaccionService.Representante>{ wilki, presidente }
		);
		System.assert(distintos.contains('por su Gerente, señor WILKI GIL'));
		System.assert(distintos.contains('; y su Presidente Ejecutivo, señora ANA GIL'));

		FSC_ContratoRedaccionService.Representante ella = representante('LUISA', 'Gerente', FSC_ContratoParte.SEXO_FEMENINO);
		System.assert(
			FSC_ContratoRedaccionService.generalesEmpresa('E', 'R', 'M', 'D', new List<FSC_ContratoRedaccionService.Representante>{ nicole, ella })
				.contains('sus Gerentes, señoras')
		);
		System.assert(FSC_ContratoRedaccionService.generalesEmpresa('E', 'R', 'M', 'D', null).endsWith('debidamente representada por '));
		System.assertEquals('Directores Generales de Ventas', FSC_ContratoRedaccionService.pluralizar('Director General de Ventas'));
	}

	private static FSC_ContratoRedaccionService.Representante representante(String nombre, String cargo, String sexo) {
		FSC_ContratoRedaccionService.Representante item = new FSC_ContratoRedaccionService.Representante();
		item.nombre = nombre;
		item.cargo = cargo;
		item.sexo = sexo;
		item.nacionalidad = sexo == FSC_ContratoParte.SEXO_FEMENINO ? 'Dominicana' : 'Dominicano';
		item.estadoCivil = sexo == FSC_ContratoParte.SEXO_FEMENINO ? 'Soltera' : 'Soltero';
		item.identificacion = '00113130439';
		item.domicilio = 'Calle 4 No. 17';
		return item;
	}
}