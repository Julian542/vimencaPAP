public with sharing class MatrizProductoMigracion {
    public class ProductSeed {
        public Integer codigo;
        public String nombre;
        public String linea;

        public ProductSeed(Integer codigo, String nombre, String linea) {
            this.codigo = codigo;
            this.nombre = nombre;
            this.linea = linea;
        }
    }

    public static void run() {
        System.debug('Inicia MatrizProductoMigracion.run()');

        try {
            List<ProductSeed> seeds = new List<ProductSeed>{
                new ProductSeed(111, 'Préstamos Comerciales a través de Líneas de Crédito', 'Préstamos'),
                new ProductSeed(112, 'Préstamos Comerciales Individuales', 'Préstamos'),
                new ProductSeed(113, 'Préstamos Comerciales Pool de Bancos', 'Préstamos'),
                new ProductSeed(114, 'Préstamos Interbancarios', 'Préstamos'),
                new ProductSeed(115, 'Líneas de crédito asociadas a las operaciones de Confirming', 'Líneas de crédito'),
                new ProductSeed(121, 'Microcrédito Grupal (Créditos otorgados a 2 o más personas con garantía mancomunada e indivisible)', 'Líneas de crédito'),
                new ProductSeed(122, 'Microcrédito a través de Líneas de Crédito', 'Líneas de crédito'),
                new ProductSeed(123, 'Microcrédito Individual', 'Líneas de crédito'),
                new ProductSeed(124, 'Microcrédito Comunal', 'Líneas de crédito'),
                new ProductSeed(131, 'Tarjeta de Crédito Corporativa', 'Tarjetas de crédito'),
                new ProductSeed(132, 'Tarjeta de Crédito Empresarial', 'Tarjetas de crédito'),
                new ProductSeed(133, 'Tarjeta de Crédito Distribución/Suplidor', 'Tarjetas de crédito'),
                new ProductSeed(134, 'Tarjeta de Crédito Empresarial Flotilla', 'Tarjetas de crédito'),
                new ProductSeed(141, 'Adelantos en Cuenta Corriente', 'Cuentas corrientes'),
                new ProductSeed(142, 'Documentos Descontados', 'Préstamos'),
                new ProductSeed(143, 'Descuentos de Facturas', 'Préstamos'),
                new ProductSeed(144, 'Anticipos sobre Documentos de Exportación', 'Préstamos'),
                new ProductSeed(145, 'Operaciones de Reporto', 'Certificados financieros'),
                new ProductSeed(146, 'Arrendamientos Financieros (Leasing)', 'Préstamos'),
                new ProductSeed(147, 'Cartas de Crédito Emitidas sin Depósito Previo No Negociadas', 'Líneas de crédito'),
                new ProductSeed(148, 'Cartas de Créditos Confirmadas No Negociadas', 'Líneas de crédito'),
                new ProductSeed(152, 'Avales', 'Líneas de crédito'),
                new ProductSeed(153, 'Fianzas', 'Líneas de crédito'),
                new ProductSeed(154, 'Operaciones de Factoraje (reverse factoring)', 'Préstamos'),
                new ProductSeed(149, 'Participación en Hipotecas Aseguradas', 'Préstamos'),
                new ProductSeed(151, 'Venta de Bienes Adjudicados', '-'),
                new ProductSeed(161, 'Préstamos Personales para Gastos', 'Préstamos'),
                new ProductSeed(162, 'Préstamos a través de Líneas de Crédito Personales (Créditos Diferidos Etc.)', 'Préstamos'),
                new ProductSeed(163, 'Préstamos Personales con Descuento por Nómina', 'Préstamos'),
                new ProductSeed(164, 'Préstamos Personales con Garantía de Certificados Financieros', 'Préstamos'),
                new ProductSeed(165, 'Préstamos Personales para Vehículos Nuevos', 'Préstamos'),
                new ProductSeed(166, 'Préstamos Personales para Vehículos Usados', 'Préstamos'),
                new ProductSeed(167, 'Préstamos Personales para Solares', 'Préstamos'),
                new ProductSeed(168, 'Líneas de Crédito Personales para Gastos Educativos', 'Líneas de crédito'),
                new ProductSeed(169, 'Préstamos Personales para Gastos Educativos', 'Préstamos'),
                new ProductSeed(171, 'Tarjeta de Crédito Personal Clásica/Standard', 'Tarjetas de crédito'),
                new ProductSeed(172, 'Tarjeta de Crédito Personal Oro/Gold', 'Tarjetas de crédito'),
                new ProductSeed(173, 'Tarjeta de Crédito Personal Platino/Platinum (o superior)', 'Tarjetas de crédito'),
                new ProductSeed(174, 'Tarjeta de Crédito Personal Flotilla', 'Tarjetas de crédito'),
                new ProductSeed(181, 'Préstamo para adquisición de la Vivienda del Deudor', 'Préstamos'),
                new ProductSeed(182, 'Préstamo para la Construcción de la Vivienda del Deudor', 'Préstamos'),
                new ProductSeed(183, 'Préstamo para adquisición de Segunda Vivienda o Veraneo', 'Préstamos'),
                new ProductSeed(184, 'Préstamo para la Construcción de 2da Vivienda o Veraneo', 'Préstamos'),
                new ProductSeed(185, 'Préstamos para Adquisición de vivienda de bajo costo procedente de un fideicomiso', 'Préstamos'),
                new ProductSeed(186, 'Préstamos para Adquisición de segunda vivienda o veraneo de bajo costo procedente de un fideicomiso', 'Préstamos'),
                new ProductSeed(187, 'Préstamos para la Remodelación de la Vivienda del deudor', 'Préstamos'),
                new ProductSeed(188, 'Préstamos para la Remodelación de la Segunda Vivienda o Veraneo', 'Préstamos'),
                new ProductSeed(190, 'Mutuos de Títulos Valores de Deuda', 'Certificados financieros'),
                new ProductSeed(191, 'Líneas de Crédito Personales para Gastos Educativos Superior', 'Líneas de crédito'),
                new ProductSeed(192, 'Préstamos Personales para Gastos Educativos Superior', 'Préstamos'),
                new ProductSeed(211, 'Cuentas Corrientes No Remuneradas', 'Cuentas corrientes'),
                new ProductSeed(212, 'Cuentas Corrientes Remuneradas', 'Cuentas corrientes'),
                new ProductSeed(213, 'Cuentas de Ahorro', 'Cuentas de ahorro'),
                new ProductSeed(214, 'Depósitos Overnight BC', 'Certificados financieros'),
                new ProductSeed(215, 'Depósitos Interbancarios', 'Certificados financieros'),
                new ProductSeed(216, 'Cuenta de Ahorro Programado', 'Cuentas de ahorro'),
                new ProductSeed(217, 'Letras de un día', 'Certificados financieros'),
                new ProductSeed(218, 'Cuentas Básicas de Ahorro', 'Cuentas de ahorro'),
                new ProductSeed(219, 'Cuentas Básicas de Nómina', 'Cuentas corrientes'),
                new ProductSeed(221, 'Depósitos a Plazo', 'Certificados financieros'),
                new ProductSeed(231, 'Certificados Financieros', 'Certificados financieros'),
                new ProductSeed(233, 'Letras', 'Certificados financieros'),
                new ProductSeed(234, 'Notas', 'Certificados financieros'),
                new ProductSeed(235, 'Cédulas Hipotecarias', 'Certificados financieros'),
                new ProductSeed(236, 'Aceptaciones Bancarias', 'Certificados financieros'),
                new ProductSeed(237, 'Contratos de Participación Hipotecaria', 'Certificados financieros'),
                new ProductSeed(238, 'Pagarés Negociables', 'Certificados financieros'),
                new ProductSeed(239, 'Papeles Comerciales', 'Certificados financieros'),
                new ProductSeed(251, 'Bonos de Caja o Básicos', 'Certificados financieros'),
                new ProductSeed(252, 'Bonos Rescatables (Callable Bonds)', 'Certificados financieros'),
                new ProductSeed(254, 'Bonos con Opción de Venta (Put Bonds)', 'Certificados financieros'),
                new ProductSeed(255, 'Cupones de bonos y obligaciones (Strip)', 'Certificados financieros'),
                new ProductSeed(256, 'Bonos Perpetuos (Sin Vencimiento)', 'Certificados financieros'),
                new ProductSeed(257, 'Bonos Subordinados', 'Certificados financieros'),
                new ProductSeed(258, 'Bonos Canjeables (Por Acciones Existentes)', 'Certificados financieros'),
                new ProductSeed(259, 'Bonos Convertibles (En Nuevas Acciones)', 'Certificados financieros'),
                new ProductSeed(260, 'Bonos con Opción de Venta y Compra', 'Certificados financieros'),
                new ProductSeed(261, 'Bonos con Plan de amortización', 'Certificados financieros'),
                new ProductSeed(262, 'Bonos con Plan de amortización con opción de compra', 'Certificados financieros'),
                new ProductSeed(263, 'Bonos con Plan de amortización con opción de venta', 'Certificados financieros'),
                new ProductSeed(264, 'Bonos con Plan de amortización con opción de compra y venta', 'Certificados financieros'),
                new ProductSeed(265, 'Bonos Perpetuos con opción de compra', 'Certificados financieros'),
                new ProductSeed(266, 'Cuotas de Participación en Fondos de Inversión Abiertos o Fondos Mutuos', 'Certificados financieros'),
                new ProductSeed(267, 'Cuotas de Participación en Fondos de Inversión Cerrados', 'Certificados financieros'),
                new ProductSeed(268, 'Bonos hipotecarios', 'Certificados financieros'),
                new ProductSeed(269, 'Letras hipotecarias', 'Certificados financieros'),
                new ProductSeed(291, 'Acciones Comunes', 'Certificados financieros'),
                new ProductSeed(292, 'Acciones Preferentes', 'Certificados financieros'),
                new ProductSeed(308, 'Notas Estructuradas de Crédito (Credit-Linked Notes)', 'Certificados financieros'),
                new ProductSeed(309, 'Contratos a plazo forward de compra de divisas', 'Certificados financieros'),
                new ProductSeed(310, 'Contratos a plazo forward de compra de títulos', 'Certificados financieros'),
                new ProductSeed(311, 'Contratos a plazo forward de compra de tasa de interés', 'Certificados financieros'),
                new ProductSeed(312, 'Contratos a plazo forward de compra de commodities', 'Certificados financieros'),
                new ProductSeed(313, 'Contratos a plazo forward de venta de divisas', 'Certificados financieros')
            };

            Set<String> lineasObjetivo = new Set<String>();
            Set<String> nombresObjetivo = new Set<String>();

            for (ProductSeed seed : seeds) {
                nombresObjetivo.add(seed.nombre);
                if (!String.isBlank(seed.linea) && seed.linea != '-') {
                    lineasObjetivo.add(seed.linea);
                }
            }

            System.debug('Líneas objetivo: ' + lineasObjetivo);
            System.debug('Cantidad de nombres objetivo: ' + nombresObjetivo.size());

            Map<String, Matriz_de_producto__c> templateByLine = new Map<String, Matriz_de_producto__c>();

            for (Matriz_de_producto__c rec : [
                SELECT Id, OwnerId, Name, PRO_Admite_Mancomunada_PF__c, PRO_Admite_Mancomunada_PJ__c,
                       PRO_Admite_Tarjeta_de_debito_PF__c, PRO_Admite_Tarjeta_de_debito_PJ__c,
                       PRO_Admite_libreta_PF_PJ__c, PRO_Clase_de_la_cuenta__c,
                       PRO_Codigo_de_linea_de_producto__c, PRO_Codigo_de_producto__c,
                       PRO_Condiciones_de_movilizacion__c, PRO_Control_Tipo_Cuenta__c,
                       PRO_Descripcion_de_linea_de_producto__c, PRO_Descripcion_del_producto__c,
                       PRO_Estado__c, PRO_Extranjero__c, PRO_Indicador_de_bloqueo__c,
                       PRO_Juridico__c, PRO_Linea_de_producto__c, PRO_Mayor_de_edad__c,
                       PRO_Menor_de_edad__c, PRO_Moneda__c, PRO_Monto_minimo_apertura__c,
                       PRO_Nacional__c, PRO_Natural__c, PRO_Nombre_de_linea_de_producto__c,
                       PRO_Otros_PF_PJ__c, PRO_PEP__c, PRO_Requiere_Tarjeta_de_debito_PF__c,
                       PRO_Requiere_Tarjeta_de_debito_PJ__c, PRO_Requiere_chequera_PF_PJ__c,
                       PRO_Requiere_libreta_PF_PJ__c, PRO_Requiere_vinculado_PF__c,
                       PRO_Requiere_vinculado_PJ__c, PRO_Segmento__c, PRO_Tasas__c,
                       PRO_Tipo__c, PRO_Tipo_de_cuenta__c, PRO_Tipo_de_producto_financiero__c,
                       eror__c, PROD_Codigo_SIB__c, PROD_Monto_maximo__c, PROD_Plazo__c,
                       PROD_Producto_principal__c, PROD_Tasa_maxima__c, PROD_Tasa_minima__c,
                       PRO_ID_Externo__c
                FROM Matriz_de_producto__c
                WHERE PRO_Nombre_de_linea_de_producto__c IN :lineasObjetivo
                  AND PRO_Estado__c = 'Activo'
                ORDER BY CreatedDate ASC
            ]) {
                System.debug('Plantilla candidata encontrada. Línea: ' + rec.PRO_Nombre_de_linea_de_producto__c + ' / Nombre: ' + rec.Name);

                String linea = rec.PRO_Nombre_de_linea_de_producto__c;

                if (!templateByLine.containsKey(linea)) {
                    templateByLine.put(linea, rec);
                    continue;
                }

                // Para tarjetas prefiero una plantilla BTC y no la anomalía BLC.
                if (linea == 'Tarjetas de crédito'
                    && templateByLine.get(linea).PRO_Codigo_de_linea_de_producto__c != 'BTC'
                    && rec.PRO_Codigo_de_linea_de_producto__c == 'BTC') {
                    templateByLine.put(linea, rec);
                }
            }

            System.debug('Plantillas encontradas por línea: ' + templateByLine.keySet());

            Set<String> existingNames = new Set<String>();
            for (Matriz_de_producto__c rec : [
                SELECT Name
                FROM Matriz_de_producto__c
                WHERE Name IN :nombresObjetivo
            ]) {
                existingNames.add(rec.Name != null ? rec.Name.trim().toUpperCase() : null);
            }

            System.debug('Cantidad de nombres existentes ya creados: ' + existingNames.size());

            Integer maxCodigo = 0;
            Integer maxExterno = 0;

            for (Matriz_de_producto__c recMax : [
                SELECT PRO_Codigo_de_producto__c, PRO_ID_Externo__c
                FROM Matriz_de_producto__c
            ]) {
                if (!String.isBlank(recMax.PRO_Codigo_de_producto__c)) {
                    try {
                        Integer valCodigo = Integer.valueOf(recMax.PRO_Codigo_de_producto__c);
                        if (valCodigo > maxCodigo) {
                            maxCodigo = valCodigo;
                        }
                    } catch (Exception e) {
                        System.debug('Valor no numérico en PRO_Codigo_de_producto__c: ' + recMax.PRO_Codigo_de_producto__c);
                    }
                }

                if (!String.isBlank(recMax.PRO_ID_Externo__c)) {
                    try {
                        Integer valExterno = Integer.valueOf(recMax.PRO_ID_Externo__c);
                        if (valExterno > maxExterno) {
                            maxExterno = valExterno;
                        }
                    } catch (Exception e) {
                        System.debug('Valor no numérico en PRO_ID_Externo__c: ' + recMax.PRO_ID_Externo__c);
                    }
                }
            }

            Integer nextConsecutivo = Math.max(maxCodigo, maxExterno) + 1;
            System.debug('maxCodigo: ' + maxCodigo);
            System.debug('maxExterno: ' + maxExterno);
            System.debug('nextConsecutivo inicial: ' + nextConsecutivo);

            List<Matriz_de_producto__c> toInsert = new List<Matriz_de_producto__c>();
            List<String> skipped = new List<String>();

            for (ProductSeed seed : seeds) {
                System.debug('Procesando seed. Código: ' + seed.codigo + ' / Nombre: ' + seed.nombre + ' / Línea: ' + seed.linea);

                String normalizedName = seed.nombre != null ? seed.nombre.trim().toUpperCase() : null;

                if (String.isBlank(seed.linea) || seed.linea == '-') {
                    skipped.add('OMITIDO POR REVISIÓN MANUAL -> ' + seed.codigo + ' - ' + seed.nombre);
                    continue;
                }

                if (existingNames.contains(normalizedName)) {
                    skipped.add('YA EXISTE -> ' + seed.codigo + ' - ' + seed.nombre);
                    continue;
                }

                if (!templateByLine.containsKey(seed.linea)) {
                    skipped.add('SIN PLANTILLA DE LÍNEA -> ' + seed.codigo + ' - ' + seed.nombre + ' / Línea: ' + seed.linea);
                    continue;
                }

                Matriz_de_producto__c nuevo = templateByLine.get(seed.linea).clone(false, true, false, false);

                nuevo.Name = seed.nombre;
                nuevo.PRO_Migrado__c = true;

                // Se asignan nuevos consecutivos.
                nuevo.PRO_Codigo_de_producto__c = String.valueOf(nextConsecutivo);
                nuevo.PRO_ID_Externo__c = String.valueOf(nextConsecutivo);

                // Se guarda el código oficial del catálogo de reclamaciones.
                nuevo.PROD_Codigo_SIB__c = String.valueOf(seed.codigo);

                // Limpieza de campos que no deben heredarse como valores específicos del producto plantilla.
                nuevo.PROD_Producto_principal__c = null;
                nuevo.PROD_Monto_maximo__c = null;
                nuevo.PROD_Plazo__c = null;
                nuevo.PROD_Tasa_maxima__c = null;
                nuevo.PROD_Tasa_minima__c = null;
                nuevo.PRO_Monto_minimo_apertura__c = null;

                toInsert.add(nuevo);
                System.debug('Registro preparado para insert. Nombre: ' + nuevo.Name + ' / Consecutivo: ' + nextConsecutivo);

                nextConsecutivo++;
            }

            System.debug('Total a insertar: ' + toInsert.size());

            if (!toInsert.isEmpty()) {
                Database.SaveResult[] results = Database.insert(toInsert, false);

                Integer okCount = 0;
                Integer errorCount = 0;

                for (Integer i = 0; i < results.size(); i++) {
                    if (results[i].isSuccess()) {
                        okCount++;
                        System.debug('INSERT OK -> ' + toInsert[i].Name + ' / Id: ' + results[i].getId());
                    } else {
                        errorCount++;
                        for (Database.Error err : results[i].getErrors()) {
                            System.debug(
                                'INSERT ERROR -> ' + toInsert[i].Name +
                                ' / Mensaje: ' + err.getMessage()
                            );
                        }
                    }
                }

                System.debug('Insertados correctamente: ' + okCount);
                System.debug('Con error: ' + errorCount);
            }

            if (!skipped.isEmpty()) {
                System.debug('Registros omitidos: ' + skipped);
            }

            System.debug('Finaliza MatrizProductoMigracion.run()');

        } catch (Exception e) {
            System.debug('ERROR GENERAL: ' + e.getMessage());
            System.debug('STACKTRACE: ' + e.getStackTraceString());
            throw e;
        }
    }
}