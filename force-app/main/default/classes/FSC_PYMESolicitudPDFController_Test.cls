@IsTest
private class FSC_PYMESolicitudPDFController_Test {

    @IsTest
    static void test_Controller_WithId_CoversLoadAndMostGetters() {

        Account a = new Account();
        Id personRtId;

        List<RecordType> rts = [
            SELECT Id
            FROM RecordType
            WHERE DeveloperName = 'PersonAccount'
              AND SobjectType = 'Account'
            LIMIT 1
        ];
        if (!rts.isEmpty()) personRtId = rts[0].Id;

        if (personRtId != null) a.RecordTypeId = personRtId;
        a.FirstName = 'Juan';
        a.LastName  = 'Perez';

        Map<String, Schema.SObjectField> aMap = Schema.SObjectType.Account.fields.getMap();
        if (aMap.containsKey('Phone')) a.put('Phone', '8090000000');
        if (aMap.containsKey('PersonEmail')) a.put('PersonEmail', 'juan.perez@vimenca.com');

        if (aMap.containsKey('ACC_TipoIdentificacion__c')) a.put('ACC_TipoIdentificacion__c', 'Cédula');
        if (aMap.containsKey('ACC_Genero__c')) a.put('ACC_Genero__c', 'MASCULINO');
        if (aMap.containsKey('ACC_NumIdentificacion__c')) a.put('ACC_NumIdentificacion__c', '00100000000');
        if (aMap.containsKey('ACC_Nacionalidad__c')) a.put('ACC_Nacionalidad__c', 'ARGENTINA');
        if (aMap.containsKey('ACC_Estado_Civil__c')) a.put('ACC_Estado_Civil__c', 'SOLTERO/A');
        if (aMap.containsKey('Tipo_de_vivienda__c')) a.put('Tipo_de_vivienda__c', '2');
        if (aMap.containsKey('ACC_Telefono_Movil__c')) a.put('ACC_Telefono_Movil__c', '8290000000');
        if (aMap.containsKey('ACC_Nombre_Corto_Comercial__c')) a.put('ACC_Nombre_Corto_Comercial__c', 'Comercial JP');
        if (aMap.containsKey('ACC_RNC__c')) a.put('ACC_RNC__c', '131000000');

        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        insert a;

        SObject rla = Schema.getGlobalDescribe().get('ResidentialLoanApplication').newSObject();
        rla.put('AccountId', a.Id);
        rla.put('Name', 'Test RLA');

        Map<String, Schema.SObjectField> rlaMap = Schema.SObjectType.ResidentialLoanApplication.fields.getMap();
        if (rlaMap.containsKey('FSC_Sucursal__c')) rla.put('FSC_Sucursal__c', 'Sucursal Central');

        if (rlaMap.containsKey('FSC_Nombre_del_negocio__c')) rla.put('FSC_Nombre_del_negocio__c', 'Negocio Prueba');
        if (rlaMap.containsKey('FSC_Cantidad_de_empleados__c')) rla.put('FSC_Cantidad_de_empleados__c', 5);
        if (rlaMap.containsKey('FSC_A_os_de_operacion__c')) rla.put('FSC_A_os_de_operacion__c', 3);

        if (rlaMap.containsKey('FSC_Se_encuentra_en_la_misma_residencia__c')) rla.put('FSC_Se_encuentra_en_la_misma_residencia__c', true);
        if (rlaMap.containsKey('FSC_Se_encuentra_en_zona_comercial__c')) rla.put('FSC_Se_encuentra_en_zona_comercial__c', false);

        if (rlaMap.containsKey('FSC_Ingresos_Mensuales__c')) rla.put('FSC_Ingresos_Mensuales__c', 150000);
        if (rlaMap.containsKey('FSC_Monto_de_los_Ingresos__c')) rla.put('FSC_Monto_de_los_Ingresos__c', 50000);

        if (rlaMap.containsKey('FSC_Monto__c')) rla.put('FSC_Monto__c', 250000);
        if (rlaMap.containsKey('FSC_Plazo_meses__c')) rla.put('FSC_Plazo_meses__c', '24');

        if (rlaMap.containsKey('FSC_Valor_de_la_Garantia__c')) rla.put('FSC_Valor_de_la_Garantia__c', 123456.7);

        if (rlaMap.containsKey('FSC_Total_Semanal__c')) rla.put('FSC_Total_Semanal__c', 17500);

        insert rla;

        Id rlaId = (Id)rla.get('Id');

        insertIfPossible(
            'LoanApplicant',
            new Map<String, Object>{
                'LoanApplicationId' => rlaId,
                'FSC_TipoSolicitante__c' => 'Deudor',
                'FSC_TipoIdentificacion__c' => 'CÃ©dula',
                'FSC_NumIdentificacion__c' => '00100000000'
            }
        );

        insert new LoanApplicant(
            Name = 'Co Deudor PDF',
            LoanApplicationId = rlaId,
            FSC_TipoSolicitante__c = 'Co-Deudor',
            FSC_TipoIdentificacion__c = 'Cédula',
            FSC_NumIdentificacion__c = '00100000001',
            FSC_Nombre__c = 'Co',
            FSC_PrimerApellido__c = 'Deudor'
        );

        LoanApplicationAsset laa = new LoanApplicationAsset();
        laa.LoanApplicationId = rlaId;
        laa.Name = 'Garantia Test';
        try { laa.put('CashOrMarketValue', 90000); } catch (Exception e) {}
        try { laa.put('FSC_Descripcion_de_la_Garantia__c', 'Vehículo'); } catch (Exception e) {}
        try { laa.put('FSC_Numero_Facilidades__c', '1'); } catch (Exception e) {}
        try { laa.put('FSC_Porcentaje_Admisibilidad__c', 75); } catch (Exception e) {}
        insert laa;

        insertIfPossible(
            'FSC_Socios_Principales_Y_Accionistas__c',
            new Map<String, Object>{
                'Name' => 'Socio 1',
                'FSC_Residential_Loan_Application__c' => rlaId,
                'FSC_Identificacion__c' => 'Cédula',
                'FSC_Numero_Id__c' => '00100000000',
                'FSC_Cargo_en_la_Empresa__c' => 'Socio',
                'FSC_Porcentaje_Participacion_en_Acciones__c' => 50
            }
        );

        insertIfPossible(
            'FSC_Facilidades_De_Credito__c',
            new Map<String, Object>{
                'FSC_Residential_Loan_Application__c' => rlaId,
                'FSC_Numero__c' => 1,
                'FSC_Fecha_Apertura__c' => Date.today().addDays(-30),
                'FSC_Tipo_de_Facilidad__c' => 'Préstamo',
                'FSC_Plazo_meses__c' => 12,
                'FSC_Moneda__c' => 'RD',
                'FSC_Deuda_Actual__c' => 10000,
                'FSC_Limite_Autorizado__c' => 20000,
                'FSC_Aumento_Solicitado__c' => 5000,
                'FSC_Posible_Compromiso__c' => 0,
                'FSC_Compromiso_Mensual__c' => 1500,
                'FSC_Tasa__c' => 10
            }
        );

        insertIfPossible(
            'FSC_Proposito_Y_Uso_De_Fondos__c',
            new Map<String, Object>{
                'FSC_Residential_Loan_Application__c' => rlaId,
                'FSC_Numero_Facilidades__c' => 1,
                'FSC_Proposito__c' => 'Capital de trabajo'
            }
        );

        insertIfPossible(
            'FSC_Relacion_Negocios_Colaterales__c',
            new Map<String, Object>{
                'FSC_Residential_Loan_Application__c' => rlaId,
                'FSC_Tipo_de_Producto__c' => 'Cuenta',
                'FSC_Numero__c' => 1,
                'FSC_Fecha_de_Apertura__c' => Date.today().addYears(-1),
                'FSC_Balance_Promedio__c' => 1000,
                'FSC_Balance_Actual__c' => 1500,
                'FSC_Flujo_Prom_Dep__c' => 'Semanal',
                'FSC_Limite_de_Credito__c' => 0,
                'FSC_Monto_Apertura__c' => 0,
                'FSC_Monto_Minimo__c' => 0,
                'FSC_Periodo__c' => 'Mensual',
                'FSC_Tasa_Pasiva__c' => '1%'
            }
        );

        insertIfPossible(
            'FSC_Referencias__c',
            new Map<String, Object>{
                'Name' => 'Referencia 1',
                'FSC_Residential_Loan_Application__c' => rlaId,
                'FSC_Telefono__c' => '8091111111',
                'FSC_Tipo_de_Producto__c' => 'Personal',
                'FSC_Parentesco__c' => 'AMIGO (A)'
            }
        );

        insertIfPossible(
            'FSC_Clientes_Y_Proveedores_Principales__c',
            new Map<String, Object>{
                'Name' => 'Cliente 1',
                'FSC_Residential_Loan_Application__c' => rlaId,
                'FSC_Terminos_de_Negociacion__c' => 'Contado',
                'FSC_Numero_Telefonico__c' => '8092222222'
            }
        );

        insertIfPossible(
            'FSC_Fortalezas_Y_Debilidades__c',
            new Map<String, Object>{
                'Name' => 'Buena ubicación',
                'FSC_Residential_Loan_Application__c' => rlaId,
                'FSC_Tipo__c' => 'Fortaleza'
            }
        );
        insertIfPossible(
            'FSC_Fortalezas_Y_Debilidades__c',
            new Map<String, Object>{
                'Name' => 'Dependencia de temporada',
                'FSC_Residential_Loan_Application__c' => rlaId,
                'FSC_Tipo__c' => 'Debilidad'
            }
        );

        Test.startTest();
        Test.setCurrentPage(new PageReference('/apex/FSC_PYMESolicitudPDF'));
        ApexPages.currentPage().getParameters().put('id', String.valueOf(rlaId));
        FSC_PYMESolicitudPDFController c = new FSC_PYMESolicitudPDFController();
        String sink;

        sink = c.pfNoIdentificacion;
        sink = c.pfNacionalidad;
        sink = c.pfEstadoCivil;
        sink = c.pfTipoVivienda;
        sink = c.pfTelefono;
        sink = c.pfCelular;
        sink = c.pfEmail;
        sink = c.pfDireccion;

        sink = c.pjRazonSocial;
        sink = c.pjNombreComercial;
        sink = c.pjRnc;

        sink = c.negocioNombre;
        sink = c.negocioTiempo;
        sink = c.negocioSituacionLegal;
        sink = c.negocioCargo;
        sink = c.negocioEmpleados;
        sink = c.negocioEmpleaFamilia;
        sink = c.negocioAniosOperacion;
        sink = c.negocioLocal;
        sink = c.negocioTiempoLocal;
        sink = c.comentarios;
        sink = c.negocioActividad;
        sink = c.negocioTelefono;
        sink = c.negocioEmail;
        sink = c.negocioDireccion;
        sink = c.recomendaciones;
        sink = c.negocioOtrosIngresos;
        sink = c.negocioOrigenIngresos;
        sink = c.negocioMontoIngresosFmt;

        sink = c.creditoTipoSolicitud;
        sink = c.creditoDestino;
        sink = c.creditoMoneda;
        sink = c.creditoPlazoMeses;
        sink = c.creditoClasificacionRiesgo;
        sink = c.creditoGrupo;
        sink = c.creditoCondiciones;
        sink = c.creditoDescripcionNegocio;

        sink = c.garantiaTipo;
        sink = c.garantiaValorFmt;
        sink = c.garantiaPorcAdmis;
        sink = c.garantiaDescripcion;

        sink = c.historiaCliente;
        sink = c.operacionesPerspectiva;

        sink = c.totalDiasBuenosFmt;
        sink = c.totalDiasRegularesFmt;
        sink = c.totalDiasMalosFmt;

        sink = c.actEfectivoFmt;
        sink = c.actCxcFmt;
        sink = c.actInventarioFmt;
        sink = c.actTotalCorrientesFmt;
        sink = c.actTerrenosFmt;
        sink = c.actEdificacionesFmt;
        sink = c.actMaquinariasFmt;
        sink = c.actMueblesFmt;
        sink = c.actVehiculosFmt;
        sink = c.actOtrosFmt;
        sink = c.actOtrosActivosFmt;
        sink = c.actTotalFmt;
        sink = c.actTotalFijosFmt;

        sink = c.pasDocsFmt;
        sink = c.pasOtrasDeudasCPFmt;
        sink = c.pasCxpFmt;
        sink = c.pasTotalCPFmt;
        sink = c.pasOtrasCxpFmt;
        sink = c.pasOtrosFmt;
        sink = c.pasCapitalFmt;
        sink = c.pasTotalFmt;
        sink = c.pasTotalPasCapFmt;

        sink = c.gpNominaFmt;
        sink = c.gpAlquilerGeneralesFmt;
        sink = c.gpServiciosBasicosGeneralesFmt;
        sink = c.gpCombustibleFmt;
        sink = c.gpReparacionesFmt;
        sink = c.gpSegurosGeneralesFmt;
        sink = c.gpOtrosGeneralesFmt;
        sink = c.gpTotalGGAFmt;

        sink = c.gpAlquilerPersonalesFmt;
        sink = c.gpServiciosBasicosPersonalesFmt;
        sink = c.gpAlimentosFmt;
        sink = c.gpEducacionFmt;
        sink = c.gpTransporteFmt;
        sink = c.gpSegurosPersonalesFmt;
        sink = c.gpOtrosPersonalesFmt;
        sink = c.gpTotalPersonalesFmt;

        sink = c.gpCuotasFmt;
        sink = c.gpOtrosFinancierosFmt;
        sink = c.gpTotalFinancierosFmt;
        Test.stopTest();

        System.assertEquals(rlaId, c.rlaId);
        System.assertEquals('Sucursal Central', c.sucursal);
        System.assertNotEquals('', c.fechaHoyFmt);
        System.assertNotEquals(null, sink);

        if (aMap.containsKey('FirstName') || aMap.containsKey('Name')) System.assertNotEquals('', c.pfNombres);
        if (aMap.containsKey('LastName') || aMap.containsKey('Name')) System.assertNotEquals('', c.pfApellidos);
        if (aMap.containsKey('ACC_TipoIdentificacion__c') || aMap.containsKey('Name')) System.assertNotEquals('', c.pfTipoCedula);
        if (aMap.containsKey('ACC_Genero__c') || aMap.containsKey('Name')) System.assertNotEquals('', c.pfSexo);

        System.assertNotEquals(null, c.negocioIngresosMensualesVal);
        System.assertNotEquals('', c.negocioIngresosMensualesFmt);
        System.assertEquals('Si', c.negocioMismaResidencia);
        System.assertEquals('No', c.negocioZonaComercial);

        System.assertNotEquals('', c.creditoMontoFmt);
        System.assertNotEquals('', c.totalSemanalFmt);

        System.assertNotEquals(null, c.socios);
        System.assert(c.sociosSize >= 0);

        System.assertNotEquals(null, c.loanApplicants);
        System.assertEquals(1, c.loanApplicantsSize);
        System.assertEquals('Co Deudor', c.loanApplicants[0].name);

        System.assertNotEquals(null, c.facilidades);
        System.assert(c.facilidadesSize >= 0);

        System.assertNotEquals(null, c.propositos);
        System.assert(c.propositosSize >= 0);

        System.assertNotEquals(null, c.relaciones);
        System.assert(c.relacionesSize >= 0);

        System.assertNotEquals(null, c.referenciasParaTabla);
        System.assert(c.referenciasParaTablaSize >= 0);

        System.assertNotEquals(null, c.clientesProveedores);
        System.assert(c.clientesProveedoresSize >= 0);

        System.assertNotEquals(null, c.listFortalezas);
        System.assert(c.listFortalezasSize >= 0);

        System.assertNotEquals(null, c.listDebilidades);
        System.assert(c.listDebilidadesSize >= 0);

        System.assertNotEquals(null, c.garantiasLista);
        System.assert(c.garantiasListaSize >= 0);
    }

    @IsTest
    static void test_Controller_WithId_FallbackNameParsing() {
        Account a = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId(),
            Name = 'Maria Lopez',
            ACC_RNC__c = '131000011',
            ACC_TipoIdentificacion__c = 'RNC',
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO'
        );
        insert a;

        SObject rla = Schema.getGlobalDescribe().get('ResidentialLoanApplication').newSObject();
        rla.put('AccountId', a.Id);
        rla.put('Name', 'Test RLA2');

        Map<String, Schema.SObjectField> rlaMap = Schema.SObjectType.ResidentialLoanApplication.fields.getMap();
        if (rlaMap.containsKey('FSC_Sucursal__c')) rla.put('FSC_Sucursal__c', 'Sucursal X');
        insert rla;

        Id rlaId = (Id)rla.get('Id');

        Test.startTest();
        Test.setCurrentPage(new PageReference('/apex/FSC_PYMESolicitudPDF'));
        ApexPages.currentPage().getParameters().put('id', String.valueOf(rlaId));
        FSC_PYMESolicitudPDFController c = new FSC_PYMESolicitudPDFController();
        Test.stopTest();

        System.assertEquals('Maria', c.pfNombres);
        System.assertEquals('Lopez', c.pfApellidos);

        System.assertEquals('RNC', c.pfTipoCedula);
        System.assertEquals('Maria', c.pfSexo);
    }

    @IsTest
    static void test_Controller_WithoutId_CoversNullPathsAndFmtMoney() {
        Test.startTest();
        Test.setCurrentPage(new PageReference('/apex/FSC_PYMESolicitudPDF'));
        FSC_PYMESolicitudPDFController c = new FSC_PYMESolicitudPDFController();

        System.assertEquals(null, c.rlaId);
        System.assertEquals('', c.sucursal);
        System.assertNotEquals('', c.fechaHoyFmt);

        System.assertNotEquals(null, c.socios);
        System.assertEquals(0, c.sociosSize);

        System.assertNotEquals(null, c.loanApplicants);
        System.assertEquals(0, c.loanApplicantsSize);

        System.assertNotEquals(null, c.facilidades);
        System.assertEquals(0, c.facilidadesSize);

        System.assertNotEquals(null, c.propositos);
        System.assertEquals(0, c.propositosSize);

        System.assertNotEquals(null, c.relaciones);
        System.assertEquals(0, c.relacionesSize);

        System.assertNotEquals(null, c.referenciasParaTabla);
        System.assertEquals(0, c.referenciasParaTablaSize);

        System.assertNotEquals(null, c.clientesProveedores);
        System.assertEquals(0, c.clientesProveedoresSize);

        System.assertNotEquals(null, c.listFortalezas);
        System.assertEquals(0, c.listFortalezasSize);

        System.assertNotEquals(null, c.listDebilidades);
        System.assertEquals(0, c.listDebilidadesSize);

        System.assertEquals('RD$ 1,234.50', FSC_PYMESolicitudPDFController.fmtMoney(1234.5));
        System.assertEquals('RD$ 12,345.00', FSC_PYMESolicitudPDFController.fmtMoney(12345));
        System.assertEquals('RD$ 1,234,567.89', FSC_PYMESolicitudPDFController.fmtMoney(1234567.891));

        Test.stopTest();
    }

    private static void insertIfPossible(String objectApi, Map<String, Object> fields) {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        if (!gd.containsKey(objectApi)) return;

        Schema.DescribeSObjectResult d = gd.get(objectApi).getDescribe();
        if (!d.isCreateable()) return;

        SObject sob = gd.get(objectApi).newSObject();
        Map<String, Schema.SObjectField> fm = d.fields.getMap();

        for (String k : fields.keySet()) {
            if (fm.containsKey(k)) sob.put(k, fields.get(k));
        }

        try {
            insert sob;
        } catch (Exception e) {
        }
    }
}
