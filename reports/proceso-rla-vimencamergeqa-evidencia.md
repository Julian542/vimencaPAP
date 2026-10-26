# Evidencia del proceso RLA — VimencaMergeQA

Consulta de configuración: 13 de octubre de 2026. Org `00DVC000009qkJJ2AY`.

Este anexo contiene condiciones y catálogo obtenidos de QA. No incluye credenciales, clientes ni contenido de archivos. La guía funcional está en [proceso-rla-vimencamergeqa.md](proceso-rla-vimencamergeqa.md).

Los nombres de archivos corresponden a `force-app/main/default/` dentro de la descarga aislada. El código local puede diferir. Las condiciones se transcriben para conservar la evidencia sin reemplazar el proyecto.

## Reglas de validación

### ResidentialLoanApplication

4 reglas recuperadas.

#### FSC_ValidarPlazoMaximoConsumo

Activa: `true`. Campo: ``.

El plazo solicitado o aprobado de un crédito de consumo supera el máximo permitido.

```text
AND(
    RecordType.DeveloperName = "FSC_Solicitud_Credito_Consumo",
    OR(
        FSC_PlazoMaximoPermitido__c < 1,
        IF(
            ISBLANK(TEXT(FSC_Plazo_meses__c)),
            FALSE,
            VALUE(TEXT(FSC_Plazo_meses__c)) > FSC_PlazoMaximoPermitido__c
        ),
        FSC_PlazoMesesAprobado__c > FSC_PlazoMaximoPermitido__c
    )
)
```

#### FSC_ValidarPlazoMaximoVehiculo

Activa: `true`. Campo: ``.

El plazo solicitado o aprobado supera el máximo permitido para la antigüedad del vehículo, o no existe un vehículo con antigüedad admitida. Revise las garantías y el plazo máximo permitido.

```text
AND(
    RecordType.DeveloperName = "FSC_Solicitud_Credito_Vehiculo",
    OR(
        AND(
            OR(FSC_AnioVehiculoMasAntiguo__c > 0, NOT(ISBLANK(FSC_PlazoMesesAprobado__c))),
            FSC_PlazoMaximoPermitido__c < 1
        ),
        IF(
            ISBLANK(TEXT(FSC_Plazo_meses__c)),
            FALSE,
            VALUE(TEXT(FSC_Plazo_meses__c)) > IF(
                FSC_AnioVehiculoMasAntiguo__c > 0,
                FSC_PlazoMaximoPermitido__c,
                $CustomMetadata.FSC_PlazoCredito__mdt.VehiculoNuevo.FSC_PlazoMaximo__c
            )
        ),
        FSC_PlazoMesesAprobado__c > FSC_PlazoMaximoPermitido__c
    )
)
```

#### FSC_Validar_Gastos_Contrato_Hip

Activa: `true`. Campo: ``.

Los gastos de contrato solo aplican a créditos hipotecarios y debe indicar únicamente uno entre garantía hipotecaria 2% y 3%.

```text
OR(
    AND(
        NOT(ISBLANK(FSC_GastosGarantiasHip2__c)),
        NOT(ISBLANK(FSC_GastosGarantiasHip3__c))
    ),
    AND(
        $RecordType.DeveloperName <> "FSC_Solicitud_Credito_Hipotecario",
        OR(
            NOT(ISBLANK(FSC_GastosLegalesContratos__c)),
            NOT(ISBLANK(FSC_GastosGarantiasHip2__c)),
            NOT(ISBLANK(FSC_GastosGarantiasHip3__c))
        )
    )
)
```

#### FSC_Validar_Tasa_Interes_Max_100

Activa: `true`. Campo: ``.

La tasa de interés no puede superar el 100%.

```text
OR(
    FSC_TasaInteres__c > 1,
    FSC_TasaInteresAprobada__c > 1
)
```

### LoanApplicant

0 reglas recuperadas.

### FSC_Garantia__c

2 reglas recuperadas.

#### FSC_ValidarAntiguedadVehiculo

Activa: `true`. Campo: `FSC_Ano_Vehiculo__c`.

Indique un año del vehículo dentro del rango permitido. No se admiten años futuros ni vehículos más antiguos que el límite configurado en Plazos de crédito.

```text
AND(
    FSC_Residential_Loan_Application__r.RecordType.DeveloperName = "FSC_Solicitud_Credito_Vehiculo",
    OR(
        ISBLANK(FSC_Ano_Vehiculo__c),
        YEAR(TODAY()) - FSC_Ano_Vehiculo__c < $CustomMetadata.FSC_PlazoCredito__mdt.VehiculoNuevo.FSC_AnioDesde__c,
        YEAR(TODAY()) - FSC_Ano_Vehiculo__c > $CustomMetadata.FSC_PlazoCredito__mdt.VehiculoUsadoAntiguo.FSC_AnioHasta__c
    )
)
```

#### FSC_ValidarPlazoVehiculo

Activa: `true`. Campo: `FSC_Ano_Vehiculo__c`.

El plazo solicitado o aprobado supera el máximo permitido para el año de este vehículo. Corrija el plazo de la solicitud antes de guardar la garantía.

```text
AND(
    FSC_Residential_Loan_Application__r.RecordType.DeveloperName = "FSC_Solicitud_Credito_Vehiculo",
    MAX(
        IF(ISBLANK(TEXT(FSC_Residential_Loan_Application__r.FSC_Plazo_meses__c)), 0, VALUE(TEXT(FSC_Residential_Loan_Application__r.FSC_Plazo_meses__c))),
        BLANKVALUE(FSC_Residential_Loan_Application__r.FSC_PlazoMesesAprobado__c, 0)
    ) > IF(
        ISBLANK(FSC_Ano_Vehiculo__c),
        0,
        IF(
            YEAR(TODAY()) - FSC_Ano_Vehiculo__c <= $CustomMetadata.FSC_PlazoCredito__mdt.VehiculoNuevo.FSC_AnioHasta__c,
            $CustomMetadata.FSC_PlazoCredito__mdt.VehiculoNuevo.FSC_PlazoMaximo__c,
            IF(
                YEAR(TODAY()) - FSC_Ano_Vehiculo__c <= $CustomMetadata.FSC_PlazoCredito__mdt.VehiculoUsadoReciente.FSC_AnioHasta__c,
                $CustomMetadata.FSC_PlazoCredito__mdt.VehiculoUsadoReciente.FSC_PlazoMaximo__c,
                $CustomMetadata.FSC_PlazoCredito__mdt.VehiculoUsadoAntiguo.FSC_PlazoMaximo__c
            )
        )
    )
)
```

### FSC_Facilidades_De_Credito__c

1 reglas recuperadas.

#### FSC_Validar_Plazo_Meses

Activa: `true`. Campo: `FSC_Plazo_meses__c`.

El plazo debe ser un numero entero entre 1 y 999 meses.

```text
AND(
    NOT(ISBLANK(FSC_Plazo_meses__c)),
    OR(
        FSC_Plazo_meses__c < 1,
        FSC_Plazo_meses__c > 999
    )
)
```

### FSC_Seguro__c

0 reglas recuperadas.

### FSC_SolicitudDeCreditoYChecklistDeDocs__c

0 reglas recuperadas.

### LoanApplicationAsset

0 reglas recuperadas.

### LoanApplicationLiability

0 reglas recuperadas.

## Configuración relevante

### FSC_PlazoCredito

| Registro | Campo | Valor |
| --- | --- | --- |
| Consumo | FSC_AnioDesde__c |  |
| Consumo | FSC_AnioHasta__c |  |
| Consumo | FSC_PlazoMaximo__c | 60.0 |
| VehiculoNuevo | FSC_AnioDesde__c | 0.0 |
| VehiculoNuevo | FSC_AnioHasta__c | 0.0 |
| VehiculoNuevo | FSC_PlazoMaximo__c | 84.0 |
| VehiculoUsadoAntiguo | FSC_AnioDesde__c | 3.0 |
| VehiculoUsadoAntiguo | FSC_AnioHasta__c | 7.0 |
| VehiculoUsadoAntiguo | FSC_PlazoMaximo__c | 60.0 |
| VehiculoUsadoReciente | FSC_AnioDesde__c | 1.0 |
| VehiculoUsadoReciente | FSC_AnioHasta__c | 2.0 |
| VehiculoUsadoReciente | FSC_PlazoMaximo__c | 72.0 |

### FSC_ConfiguracionFirmaDocumentos

| Registro | Campo | Valor |
| --- | --- | --- |
| Contrato_Consumo | FSC_FirmaDigital__c | false |
| Contrato_Consumo | FSC_NombreDocumento__c | Contrato |
| Contrato_Consumo | FSC_TipoCredito__c | FSC_Solicitud_Credito_Consumo |
| Contrato_Hipotecario | FSC_FirmaDigital__c | false |
| Contrato_Hipotecario | FSC_NombreDocumento__c | Contrato |
| Contrato_Hipotecario | FSC_TipoCredito__c | FSC_Solicitud_Credito_Hipotecario |
| Contrato_PYME | FSC_FirmaDigital__c | false |
| Contrato_PYME | FSC_NombreDocumento__c | Contrato |
| Contrato_PYME | FSC_TipoCredito__c | FSC_Solicitud_Credito_PYME |
| Contrato_Vehiculo | FSC_FirmaDigital__c | false |
| Contrato_Vehiculo | FSC_NombreDocumento__c | Contrato |
| Contrato_Vehiculo | FSC_TipoCredito__c | FSC_Solicitud_Credito_Vehiculo |
| Pagare_Consumo | FSC_FirmaDigital__c | false |
| Pagare_Consumo | FSC_NombreDocumento__c | Pagare |
| Pagare_Consumo | FSC_TipoCredito__c | FSC_Solicitud_Credito_Consumo |
| Pagare_Hipotecario | FSC_FirmaDigital__c | false |
| Pagare_Hipotecario | FSC_NombreDocumento__c | Pagare |
| Pagare_Hipotecario | FSC_TipoCredito__c | FSC_Solicitud_Credito_Hipotecario |
| Pagare_PYME | FSC_FirmaDigital__c | false |
| Pagare_PYME | FSC_NombreDocumento__c | Pagare |
| Pagare_PYME | FSC_TipoCredito__c | FSC_Solicitud_Credito_PYME |
| Pagare_Vehiculo | FSC_FirmaDigital__c | false |
| Pagare_Vehiculo | FSC_NombreDocumento__c | Pagare |
| Pagare_Vehiculo | FSC_TipoCredito__c | FSC_Solicitud_Credito_Vehiculo |
| Planilla_Consumo | FSC_FirmaDigital__c | true |
| Planilla_Consumo | FSC_NombreDocumento__c | Planilla |
| Planilla_Consumo | FSC_TipoCredito__c | FSC_Solicitud_Credito_Consumo |
| Planilla_Hipotecario | FSC_FirmaDigital__c | true |
| Planilla_Hipotecario | FSC_NombreDocumento__c | Planilla |
| Planilla_Hipotecario | FSC_TipoCredito__c | FSC_Solicitud_Credito_Hipotecario |
| Planilla_PYME | FSC_FirmaDigital__c | true |
| Planilla_PYME | FSC_NombreDocumento__c | Planilla |
| Planilla_PYME | FSC_TipoCredito__c | FSC_Solicitud_Credito_PYME |
| Planilla_Vehiculo | FSC_FirmaDigital__c | true |
| Planilla_Vehiculo | FSC_NombreDocumento__c | Planilla |
| Planilla_Vehiculo | FSC_TipoCredito__c | FSC_Solicitud_Credito_Vehiculo |

### FSC_Configuracion_Excepciones

| Registro | Campo | Valor |
| --- | --- | --- |
| FSC_Limite_Global | FSC_Maximo_Excepciones__c | 3.0 |

### FSC_MatrizClasificacionMIPYMES

| Registro | Campo | Valor |
| --- | --- | --- |
| Mediana_Empresa | FSC_CantidadMaximaEmpleados__c | 150.0 |
| Mediana_Empresa | FSC_Codigo__c | 3.0 |
| Mediana_Empresa | FSC_VentasBrutasAnualesMaximas__c | 3.026247201E8 |
| Microempresa_de_Acumulaci_n | FSC_CantidadMaximaEmpleados__c | 10.0 |
| Microempresa_de_Acumulaci_n | FSC_Codigo__c | 1.0 |
| Microempresa_de_Acumulaci_n | FSC_VentasBrutasAnualesMaximas__c | 1.198513742E7 |
| Microempresa_de_Subsistencia | FSC_CantidadMaximaEmpleados__c | 2.0 |
| Microempresa_de_Subsistencia | FSC_Codigo__c | 0.0 |
| Microempresa_de_Subsistencia | FSC_VentasBrutasAnualesMaximas__c | 898854.25 |
| Peque_a_Empresa | FSC_CantidadMaximaEmpleados__c | 50.0 |
| Peque_a_Empresa | FSC_Codigo__c | 2.0 |
| Peque_a_Empresa | FSC_VentasBrutasAnualesMaximas__c | 8.089967765E7 |

### FSC_LimiteSolicitudCredito

| Registro | Campo | Valor |
| --- | --- | --- |
| FSC_LimiteFacilidadesOtrasInstituciones | FSC_Limite__c | 5.0 |

### ConfigLoanDecisionAPI

| Registro | Campo | Valor |
| --- | --- | --- |
| Credentials | Encendido__c | false |
| PYME | Encendido__c | true |
| URL | Encendido__c | true |
| URLHipotecario | Encendido__c | true |
| URLVehicular | Encendido__c | true |

## Flows del objeto

Se incluyen activos y obsoletos con su estado explícito. Una condición ISCHANGED requiere cambio real del campo.

### FSC_After_Update_Change_SubStatus

Estado: `Active`. Disparador: `Update / RecordAfterSave`. Inicio: `Subestado_actual`.

Lógica de filtros: `and`. Solo cuando cumple requisitos: ``.
- `FSC_Subestado__c IsChanged true`
- `Status EqualTo En proceso`

Acción `Consultar_Buro_Credito`: `apex / FSC_APIBuroCredito`.
- `residentialLoanApplicationId = $Record.Id`

Acción `FSC_Crear_desembolso`: `apex / FSC_CreacionDesembolsoAsync`.
- `codigoAgencia = $User.USE_Oficina__c / Resource`
- `codigoUsuario = $User.FSC_CodigoAbanks__c / Resource`
- `residentialLoanApplicationId = $Record.Id`

Acción `FSC_Encolar_creacion_de_prestamo`: `apex / FSC_CreacionPrestamoAsync`.
- `codigoAgencia = $User.USE_Oficina__c / Resource`
- `codigoEjecutivo = CodigoUsuarioEjecutivo / Resource`
- `codigoUsuario = CodigoUsuarioEjecutivo / Resource`
- `residentialLoanApplicationId = $Record.Id`

Decisión `Subestado_actual`; salida por defecto: ``.
- `API_Buro_Credito_SubEstado_En_Motor_Buro` (and) → `Consultar_Buro_Credito`.
  - `$Record.FSC_Subestado__c EqualTo En Motor Buró`
- `API_Prestamos_SubEstado_Creacion_de_credito` (and) → `FSC_Encolar_creacion_de_prestamo`.
  - `$Record.FSC_Subestado__c EqualTo Creación de crédito`
  - `$Record.FSC_FormaDeDesembolso__c EqualTo Cuenta de ahorro`
  - `$Record.FSC_lineaFinanciera__c IsNull false`
  - `$Record.FSC_subAplicacion__c IsNull false`
- `API_Desembolso_SubEstado_Creacion_de_desembolso` (and) → `FSC_Crear_desembolso`.
  - `$Record.FSC_Subestado__c EqualTo Desembolso`
  - `$Record.FSC_FormaDeDesembolso__c EqualTo Cuenta de ahorro`

formulas `CodigoUsuarioEjecutivo` → ``.

```text
IF(ISBLANK({!$User.FSC_CodigoAbanks__c}), {!$User.Alias}, {!$User.FSC_CodigoAbanks__c})
```


### FSC_Aprobacion_PLA

Estado: `Active`. Disparador: `CreateAndUpdate / RecordAfterSave`. Inicio: `GetColaPLA`.


```text
AND(
    ISPICKVAL({!$Record.FSC_Resultado_PEP_Listas__c}, 'Coincidencia'), 
    {!$Record.RecordType.DeveloperName} != 'FSC_Solicitud_Credito_PYME',
    OR(
        AND(
            OR(
                ISCHANGED({!$Record.FSC_Subestado__c}),
                ISCHANGED({!$Record.FSC_Resultado_PEP_Listas__c})
            ),
            ISPICKVAL({!$Record.Status}, 'En proceso'), 
            ISPICKVAL({!$Record.FSC_Subestado__c}, 'En validación PEP/Listas')
        ), 
        AND(
            ISNEW(), 
            ISPICKVAL({!$Record.Status}, 'Borrador'), 
            ISPICKVAL({!$Record.FSC_Subestado__c}, 'Completando información')
        )
    )
)
```

Acción `Enviar_a_Aprobacion_PLA_Consumo`: `submit / submit`.
- `objectId = $Record.Id`
- `nextApproverIds = ListaDeUsuariosAprobadores`
- `processDefinitionNameOrId = FSC_Aprobacion_PLA_CHV`

Acción `Enviar_a_Aprobacion_PLA_General`: `submit / submit`.
- `objectId = $Record.Id`
- `nextApproverIds = ListaDeUsuariosAprobadores`
- `processDefinitionNameOrId = FSC_Aprobacion_PLA`

Acción `ObtenerUsuarioPLADesdeCola`: `apex / FSC_RandomQueueApproverAction`.
- `groupId = GetColaPLA.Id`

Decisión `Que_tipo_de_Credito_es`; salida por defecto: `Enviar_a_Aprobacion_PLA_Consumo`.
- `En_validacion_PEP_Listas` (and) → `Enviar_a_Aprobacion_PLA_General`.
  - `$Record.FSC_Subestado__c EqualTo En validación PEP/Listas`

Decisión `SeEncontroUsuarioPLA`; salida por defecto: ``.
- `UsuarioPLAEncontrado` (and) → `AsignacionUsuarioPLADesdeCola`.
  - `ObtenerUsuarioPLADesdeCola.userId IsBlank false`

assignments `AsignacionUsuarioPLADesdeCola` → `Que_tipo_de_Credito_es`.
- `ListaDeUsuariosAprobadores Add = ObtenerUsuarioPLADesdeCola.userId`

recordLookups `GetColaPLA` → `ObtenerUsuarioPLADesdeCola`.
Objeto `Group`; lógica `and`.
- `DeveloperName EqualTo FSC_Cola_PLA`

### FSC_Aprobacion_PLA_PYME

Estado: `Active`. Disparador: `CreateAndUpdate / RecordAfterSave`. Inicio: `EsSolicitudPYME`.

Lógica de filtros: `and`. Solo cuando cumple requisitos: ``.
- `FSC_Resultado_PEP_Listas__c EqualTo Coincidencia`
- `Status EqualTo En proceso`
- `FSC_Subestado__c EqualTo En validación PEP/Listas`

Acción `FSC_Enviar_a_Aprobacion_PLA`: `submit / submit`.
- `objectId = $Record.Id`
- `nextApproverIds = ListaDeUsuariosAprobadores`
- `processDefinitionNameOrId = FSC_Aprobacion_PLA_PYME`

Acción `ObtenerUsuarioPLADesdeCola`: `apex / FSC_RandomQueueApproverAction`.
- `groupId = GetColaPLA.Id`

Decisión `EsSolicitudPYME`; salida por defecto: ``.
- `TipoPYME` (and) → `GetColaPLA`.
  - `$Record.RecordType.DeveloperName EqualTo FSC_Solicitud_Credito_PYME`

Decisión `SeEncontroUsuarioPLA`; salida por defecto: ``.
- `UsuarioPLAEncontrado` (and) → `AsignacionUsuarioPLADesdeCola`.
  - `ObtenerUsuarioPLADesdeCola.userId IsBlank false`

assignments `AsignacionUsuarioPLADesdeCola` → `FSC_Enviar_a_Aprobacion_PLA`.
- `ListaDeUsuariosAprobadores Add = ObtenerUsuarioPLADesdeCola.userId`

recordLookups `GetColaPLA` → `ObtenerUsuarioPLADesdeCola`.
Objeto `Group`; lógica `and`.
- `DeveloperName EqualTo FSC_Cola_PLA`

### FSC_Aprobacion_de_Archivo_y_Custodia_de_valores

Estado: `Active`. Disparador: `CreateAndUpdate / RecordAfterSave`. Inicio: `GetColaArchivoYCustodia`.

Lógica de filtros: `and`. Solo cuando cumple requisitos: ``.
- `Status EqualTo En proceso`
- `FSC_Subestado__c EqualTo Archivo y custodia`
- `FSC_Desembolso_Realizado__c EqualTo true`
- `FSC_Doc_Incompleta_Post_Desembolso__c EqualTo false`

Acción `FSC_Enviar_a_Aprobacion_de_Archivo_y_Custodia_de_valores`: `submit / submit`.
- `objectId = $Record.Id`
- `nextApproverIds = ListaDeUsuariosAprobadores`
- `processDefinitionNameOrId = FSC_Archivo_y_custodia_de_valores`

Acción `ObtenerUsuarioArchivoYCustodiaDesdeCola`: `apex / FSC_RandomQueueApproverAction`.
- `groupId = GetColaArchivoYCustodia.Id`

Decisión `SeEncontroUsuarioArchivoYCustodia`; salida por defecto: ``.
- `UsuarioArchivoYCustodiaEncontrado` (and) → `AsignacionUsuarioArchivoYCustodiaDesdeCola`.
  - `ObtenerUsuarioArchivoYCustodiaDesdeCola.userId IsBlank false`

assignments `AsignacionUsuarioArchivoYCustodiaDesdeCola` → `FSC_Enviar_a_Aprobacion_de_Archivo_y_Custodia_de_valores`.
- `ListaDeUsuariosAprobadores Add = ObtenerUsuarioArchivoYCustodiaDesdeCola.userId`

recordLookups `GetColaArchivoYCustodia` → `ObtenerUsuarioArchivoYCustodiaDesdeCola`.
Objeto `Group`; lógica `and`.
- `DeveloperName EqualTo FSC_Cola_Archivo_y_custodia_de_valores`

### FSC_AsignarUsuariosAprobadores

Estado: `Active`. Disparador: `Update / RecordAfterSave`. Inicio: `Tipo_de_usuario`.


```text
 ISCHANGED({!$Record.LastModifiedById}) && ({!$Record.LastModifiedBy.Profile.Name} = 'Analista de crédito' || {!$Record.LastModifiedBy.Profile.Name} = 'Supervisor' || {!$Record.LastModifiedBy.Profile.Name} = 'Comité de crédito' || {!$Record.LastModifiedBy.Profile.Name} = 'Recepción y control de documentos')
```

Decisión `Tipo_de_usuario`; salida por defecto: ``.
- `Analista` (and) → `AsignarAnalista`.
  - `$Record.Owner:User.Profile.LastModifiedBy.Profile.Name EqualTo Analista de crédito`
- `Supervisor` (and) → `AsignarSupervisor`.
  - `$Record.Owner:User.Profile.LastModifiedBy.Profile.Name EqualTo Supervisor`
- `Comit` (and) → `AsignarComite`.
  - `$Record.Owner:User.Profile.LastModifiedBy.Profile.Name EqualTo Comité de crédito`
- `Control_documentos` (and) → `AsignarControlDeDocumentos`.
  - `$Record.Owner:User.Profile.LastModifiedBy.Profile.Name EqualTo Recepción y control de documentos`

recordUpdates `AsignarAnalista` → ``.
- `FSC_UsuarioAnalista__c  = $Record.LastModifiedById`

recordUpdates `AsignarComite` → ``.
- `FSC_UsuarioComite__c  = $Record.LastModifiedById`

recordUpdates `AsignarControlDeDocumentos` → ``.
- `FSC_UsuarioControlDocumentos__c  = $Record.OwnerId`

recordUpdates `AsignarSupervisor` → ``.
- `FSC_UsuarioSupervisor__c  = $Record.LastModifiedById`

### FSC_EditarNombreDeCredito

Estado: `Active`. Disparador: `Update / RecordBeforeSave`. Inicio: `No_Puede_Editar_Campo_Nombre`.

Lógica de filtros: `and`. Solo cuando cumple requisitos: ``.
- `Name IsChanged true`

### FSC_Formula_Clasificacion_MIPYMES

Estado: `Active`. Disparador: `CreateAndUpdate / RecordAfterSave`. Inicio: `Obtener_Clasificaci_n_MIPYMES_Cantidad_Maxima_Empleados`.


```text
AND(
    {!$Record.RecordType.DeveloperName} = 'FSC_Solicitud_Credito_PYME',
    OR(
        ISNEW(),
        ISCHANGED({!$Record.FSC_Cantidad_de_empleados__c}),
        ISCHANGED({!$Record.FSC_VentasBrutasAnuales__c})
    )
)
```

Decisión `Categoria_de_Cantidad_Maxima_Empleados_es_Mayor_que_Ventas_Brutas`; salida por defecto: `Actualizar_Clasificaci_n_MIPYMES_RLA_2`.
- `Si` (and) → `Actualizar_Clasificacion_MIPYMES_RLA`.
  - `Obtener_Clasificaci_n_MIPYMES_Cantidad_Maxima_Empleados.FSC_Codigo__c GreaterThan Clasificaci_n_MIPYMES_Ventas_Brutas_Anuales_Maximas.FSC_Codigo__c`

recordUpdates `Actualizar_Clasificaci_n_MIPYMES_RLA_2` → ``.
- `FSC_ClasificacionMIPYMES__c  = Clasificaci_n_MIPYMES_Ventas_Brutas_Anuales_Maximas.Label`

recordUpdates `Actualizar_Clasificacion_MIPYMES_RLA` → ``.
- `FSC_ClasificacionMIPYMES__c  = Obtener_Clasificaci_n_MIPYMES_Cantidad_Maxima_Empleados.Label`

recordLookups `Clasificaci_n_MIPYMES_Ventas_Brutas_Anuales_Maximas` → `Categoria_de_Cantidad_Maxima_Empleados_es_Mayor_que_Ventas_Brutas`.
Objeto `FSC_MatrizClasificacionMIPYMES__mdt`; lógica `or`.
- `FSC_VentasBrutasAnualesMaximas__c GreaterThanOrEqualTo $Record.FSC_VentasBrutasAnuales__c`

recordLookups `Obtener_Clasificaci_n_MIPYMES_Cantidad_Maxima_Empleados` → `Clasificaci_n_MIPYMES_Ventas_Brutas_Anuales_Maximas`.
Objeto `FSC_MatrizClasificacionMIPYMES__mdt`; lógica `or`.
- `FSC_CantidadMaximaEmpleados__c GreaterThanOrEqualTo $Record.FSC_Cantidad_de_empleados__c`

### FSC_Notificaciones_por_Email_RLA

Estado: `Active`. Disparador: `Update / RecordAfterSave`. Inicio: ``.

Lógica de filtros: `and`. Solo cuando cumple requisitos: ``.
- `FSC_EventosNotificacion__c IsChanged true`

Acción `Enviar_Analisis_Referido`: `emailSimple / emailSimple`.
- `recipientAddresses = `
- `senderType = Custom / OrgWideEmailAddress`
- `senderAddress = Custom / jvalenti@keystoneadvisors.cl`
- `emailSubject = Solicitud de crédito referida a Análisis de Crédito`
- `emailBody = Texto_Oficial_Referido`
- `relatedRecordId = $Record.Id / Resource`
- `logEmailOnSend = true`

Acción `Enviar_Asignacion_Captura`: `emailSimple / emailSimple`.
- `recipientAddresses = `
- `senderType = Custom / OrgWideEmailAddress`
- `senderAddress = Custom / jvalenti@keystoneadvisors.cl`
- `emailSubject = Solicitud asignada a captura`
- `emailBody = Texto_Asignacion_Captura`
- `relatedRecordId = $Record.Id`
- `logEmailOnSend = true`

Acción `Enviar_Asignacion_Operaciones`: `emailSimple / emailSimple`.
- `recipientAddresses = `
- `senderType = Custom / OrgWideEmailAddress`
- `senderAddress = Custom / jvalenti@keystoneadvisors.cl`
- `emailSubject = Solicitud asignada a operaciones`
- `emailBody = Texto_Asignacion_Operaciones`
- `relatedRecordId = $Record.Id`
- `logEmailOnSend = true`

Acción `Enviar_Documentacion_Contratos_A_Revision`: `emailSimple / emailSimple`.
- `recipientAddresses = `
- `senderType = Custom / OrgWideEmailAddress`
- `senderAddress = Custom / jvalenti@keystoneadvisors.cl`
- `emailSubject = Documentación para contratos lista para revisión`
- `emailBody = Texto_Documentacion_Contratos_A_Revision`
- `relatedRecordId = $Record.Id`
- `logEmailOnSend = true`

Acción `Enviar_Email_Aprobado_con_Condicion`: `emailSimple / emailSimple`.
- `recipientAddresses = `
- `ccAddresses = `
- `senderType = Custom / OrgWideEmailAddress`
- `senderAddress = Custom / jvalenti@keystoneadvisors.cl`
- `emailSubject = Tu solicitud de crédito fue aprobada con condiciones`
- `emailBody = Texto_Aprobacion_Condicionada`
- `relatedRecordId = $Record.Id / Resource`
- `logEmailOnSend = true`

Acción `Enviar_Email_Forma_de_Desembolso`: `emailSimple / emailSimple`.
- `recipientAddresses = `
- `ccAddresses = `
- `senderType = Custom / OrgWideEmailAddress`
- `senderAddress = Custom / jvalenti@keystoneadvisors.cl`
- `emailSubject = Confirmación de desembolso de tu crédito`
- `emailBody = Texto_Desembolso_Cuenta`
- `relatedRecordId = $Record.Id / Resource`
- `logEmailOnSend = true`

Acción `Enviar_Email_Forma_de_Desembolso_2`: `emailSimple / emailSimple`.
- `recipientAddresses = `
- `ccAddresses = `
- `senderType = Custom / OrgWideEmailAddress`
- `senderAddress = Custom / jvalenti@keystoneadvisors.cl`
- `emailSubject = Confirmación de desembolso de tu crédito`
- `emailBody = Texto_Desembolso_Cheque`
- `relatedRecordId = $Record.Id / Resource`
- `logEmailOnSend = true`

Acción `Enviar_Email_Forma_de_Desembolso_Combinada`: `emailSimple / emailSimple`.
- `recipientAddresses = `
- `ccAddresses = `
- `senderType = Custom / OrgWideEmailAddress`
- `senderAddress = Custom / jvalenti@keystoneadvisors.cl`
- `emailSubject = Confirmación de desembolso de tu crédito`
- `emailBody = Texto_Desembolso_Combinado`
- `relatedRecordId = $Record.Id / Resource`
- `logEmailOnSend = true`

Acción `Enviar_Email_Rechazo`: `emailSimple / emailSimple`.
- `recipientAddresses = `
- `ccAddresses = `
- `senderType = Custom / OrgWideEmailAddress`
- `senderAddress = Custom / jvalenti@keystoneadvisors.cl`
- `emailSubject = Actualización sobre tu solicitud de crédito`
- `emailBody = Texto_Rechazo_General`
- `relatedRecordId = $Record.Id / Resource`
- `logEmailOnSend = true`

Acción `Enviar_Email_Rechazo_2`: `emailSimple / emailSimple`.
- `recipientAddresses = `
- `ccAddresses = `
- `senderType = Custom / OrgWideEmailAddress`
- `senderAddress = Custom / jvalenti@keystoneadvisors.cl`
- `emailSubject = Actualización sobre tu solicitud de crédito`
- `emailBody = Texto_Rechazo_PLA`
- `relatedRecordId = $Record.Id / Resource`
- `logEmailOnSend = true`

Acción `Enviar_Email_Rechazo_3`: `emailSimple / emailSimple`.
- `recipientAddresses = `
- `ccAddresses = `
- `senderType = Custom / OrgWideEmailAddress`
- `senderAddress = Custom / jvalenti@keystoneadvisors.cl`
- `emailSubject = Actualización sobre tu solicitud de crédito`
- `emailBody = Texto_Rechazo_General`
- `relatedRecordId = $Record.Id / Resource`
- `logEmailOnSend = true`

Acción `Enviar_Email_Requiere_Informacion`: `emailSimple / emailSimple`.
- `recipientAddresses = `
- `senderType = Custom / OrgWideEmailAddress`
- `senderAddress = Custom / jvalenti@keystoneadvisors.cl`
- `emailSubject = La solicitud de crédito requiere más información`
- `emailBody = Texto_Requiere_Informacion`
- `relatedRecordId = $Record.Id / Resource`
- `logEmailOnSend = true`

Acción `Enviar_Pedido_Documentacion_Contratos`: `emailSimple / emailSimple`.
- `recipientAddresses = `
- `senderType = Custom / OrgWideEmailAddress`
- `senderAddress = Custom / jvalenti@keystoneadvisors.cl`
- `emailSubject = Documentación pendiente para contratos`
- `emailBody = Texto_Pedido_Documentacion_Contratos`
- `relatedRecordId = $Record.Id`
- `logEmailOnSend = true`

Decisión `Forma_de_Desembolso`; salida por defecto: ``.
- `Forma_de_Desembolso_Cuenta_de_ahorro` (and) → `Validar_Desembolso_Cuenta`.
  - `$Record.FSC_FormaDeDesembolso__c EqualTo Cuenta de ahorro`
- `Forma_de_Desembolso_Cheque_de_administracion` (and) → `Validar_Desembolso_Cheque`.
  - `$Record.FSC_FormaDeDesembolso__c EqualTo Cheque de administracion`
- `Forma_de_Desembolso_Combinada` (and) → `Validar_Desembolso_Combinado`.
  - `$Record.FSC_FormaDeDesembolso__c EqualTo Cuenta de ahorro y Cheque de administración`

Decisión `Notificacion_por_Cambio`; salida por defecto: ``.
- `Entrada_Documentacion_Contratos` (and) → `Enviar_Pedido_Documentacion_Contratos`.
  - `$Record.FSC_EventosNotificacion__c Contains |SUBESTADO|`
  - `$Record.FSC_Subestado__c EqualTo Documentación para contratos`
- `Documentacion_Contratos_Enviada` (1 AND (2 OR 5) AND 3 AND 4) → `Enviar_Documentacion_Contratos_A_Revision`.
  - `$Record.FSC_EventosNotificacion__c Contains |CONTRATOS_ENVIADA|`
  - `$Record.FSC_Subestado__c EqualTo Generación de pagarés y plantillas`
  - `$Record.FSC_UsuarioPagaresYContratos__c IsNull false`
  - `$Record.FSC_UsuarioPagaresYContratos__r.Email IsNull false`
  - `$Record.FSC_Subestado__c EqualTo Generación de contrato`
- `Notificacion_por_Cambio_Subestado_Rechazos` (1 AND (2 OR 3 OR 4 OR 5 OR 6)) → `Validar_Rechazo`.
  - `$Record.FSC_EventosNotificacion__c Contains |SUBESTADO|`
  - `$Record.FSC_Subestado__c EqualTo Rechazado por PLA`
  - `$Record.FSC_Subestado__c EqualTo Rechazado por Buró`
  - `$Record.FSC_Subestado__c EqualTo Rechazado por análisis`
  - `$Record.FSC_Subestado__c EqualTo Rechazado por comité`
  - `$Record.FSC_Subestado__c EqualTo Rechazado por supervisor`
- `Subestado_Analisis_de_credito` (and) → `Enviar_Analisis_Referido`.
  - `$Record.FSC_EventosNotificacion__c Contains |SUBESTADO|`
  - `$Record.FSC_Subestado__c EqualTo Análisis de crédito`
- `Notificacion_por_Cambio_Desembolso_Realizado` (1 AND 4 AND 5 AND (2 OR 3 OR 6)) → `Forma_de_Desembolso`.
  - `$Record.FSC_Desembolso_Realizado__c EqualTo true`
  - `$Record.FSC_FormaDeDesembolso__c EqualTo Cuenta de ahorro`
  - `$Record.FSC_FormaDeDesembolso__c EqualTo Cheque de administracion`
  - `$Record.FSC_EventosNotificacion__c Contains |SUBESTADO|`
  - `$Record.FSC_Subestado__c EqualTo Archivo y custodia`
  - `$Record.FSC_FormaDeDesembolso__c EqualTo Cuenta de ahorro y Cheque de administración`
- `Notificacion_por_Cambio_Aprobado_con_Condiciones` (and) → `Validar_Aprobacion`.
  - `$Record.FSC_EventosNotificacion__c Contains |APROBACION|`
  - `$Record.FSC_Aprobado_con_Condiciones__c EqualTo true`
- `Requiere_mas_Informacion` ((1 AND 2) OR (3 AND 4) OR (5 AND 6)) → `Enviar_Email_Requiere_Informacion`.
  - `$Record.FSC_EventosNotificacion__c Contains |INFO_ANALISIS|`
  - `$Record.FSC_Doc_Incompleta_Analisis__c EqualTo true`
  - `$Record.FSC_EventosNotificacion__c Contains |INFO_DESEMBOLSO|`
  - `$Record.FSC_Doc_Incompleta_Desembolso__c EqualTo true`
  - `$Record.FSC_EventosNotificacion__c Contains |INFO_POST_DESEMBOLSO|`
  - `$Record.FSC_Doc_Incompleta_Post_Desembolso__c EqualTo true`

Decisión `Notificar_Asignacion_Captura`; salida por defecto: `Notificar_Asignacion_Operaciones`.
- `Asignacion_Captura_Modificada` (and) → `Enviar_Asignacion_Captura`.
  - `Avisar_Asignacion_Captura EqualTo true`

Decisión `Notificar_Asignacion_Operaciones`; salida por defecto: `Tipo_de_Credito`.
- `Asignacion_Operaciones_Modificada` (and) → `Enviar_Asignacion_Operaciones`.
  - `Avisar_Asignacion_Operaciones EqualTo true`

Decisión `Tipo_de_Credito`; salida por defecto: ``.
- `Credito_Consumo` (and) → `Preparar_Consumo`.
  - `$Record.RecordType.DeveloperName EqualTo FSC_Solicitud_Credito_Consumo`
- `Credito_Hipotecario` (and) → `Preparar_Hipotecario`.
  - `$Record.RecordType.DeveloperName EqualTo FSC_Solicitud_Credito_Hipotecario`
- `Credito_PYME` (and) → `Preparar_PYME`.
  - `$Record.RecordType.DeveloperName EqualTo FSC_Solicitud_Credito_PYME`
- `Credito_Vehicular` (and) → `Preparar_Vehicular`.
  - `$Record.RecordType.DeveloperName EqualTo FSC_Solicitud_Credito_Vehiculo`

Decisión `Tipo_de_Rechazo`; salida por defecto: ``.
- `Tipo_de_Rechazo_Analisis` (or) → `Enviar_Email_Rechazo`.
  - `$Record.FSC_Subestado__c EqualTo Rechazado por análisis`
  - `$Record.FSC_Subestado__c EqualTo Rechazado por supervisor`
  - `$Record.FSC_Subestado__c EqualTo Rechazado por comité`
- `Tipo_de_Rechazo_Coincidencia_Listas` (and) → `Enviar_Email_Rechazo_2`.
  - `$Record.FSC_Subestado__c EqualTo Rechazado por PLA`
- `Tipo_de_Rechazo_Buro_Credito` (and) → `Enviar_Email_Rechazo_3`.
  - `$Record.FSC_Subestado__c EqualTo Rechazado por Buró`

Decisión `Validar_Aprobacion`; salida por defecto: `Registrar_Datos_Incompletos_Aprobacion`.
- `Datos_Aprobacion_Completos` (and) → `Enviar_Email_Aprobado_con_Condicion`.
  - `Datos_Aprobacion_Validos EqualTo true`

Decisión `Validar_Desembolso_Cheque`; salida por defecto: `Registrar_Datos_Incompletos_Desembolso`.
- `Datos_Cheque_Completos` (and) → `Enviar_Email_Forma_de_Desembolso_2`.
  - `Datos_Desembolso_Cheque_Validos EqualTo true`

Decisión `Validar_Desembolso_Combinado`; salida por defecto: `Registrar_Datos_Incompletos_Desembolso`.
- `Datos_Combinados_Completos` (and) → `Enviar_Email_Forma_de_Desembolso_Combinada`.
  - `Datos_Desembolso_Combinado_Validos EqualTo true`

Decisión `Validar_Desembolso_Cuenta`; salida por defecto: `Registrar_Datos_Incompletos_Desembolso`.
- `Datos_Cuenta_Completos` (and) → `Enviar_Email_Forma_de_Desembolso`.
  - `Datos_Desembolso_Cuenta_Validos EqualTo true`

Decisión `Validar_Rechazo`; salida por defecto: `Registrar_Datos_Incompletos_Rechazo`.
- `Destinatario_Rechazo_Valido` (and) → `Tipo_de_Rechazo`.
  - `Datos_Rechazo_Validos EqualTo true`

Decisión `Validar_Tipo_Credito_Entrada`; salida por defecto: ``.
- `Tipo_Credito_Soportado` (or) → `Notificar_Asignacion_Captura`.
  - `$Record.RecordType.DeveloperName EqualTo FSC_Solicitud_Credito_PYME`
  - `$Record.RecordType.DeveloperName EqualTo FSC_Solicitud_Credito_Consumo`
  - `$Record.RecordType.DeveloperName EqualTo FSC_Solicitud_Credito_Hipotecario`
  - `$Record.RecordType.DeveloperName EqualTo FSC_Solicitud_Credito_Vehiculo`

recordUpdates `Registrar_Datos_Incompletos_Aprobacion` → ``.
- `FSC_LogErrores__c  = Log_Datos_Aprobacion`

recordUpdates `Registrar_Datos_Incompletos_Desembolso` → ``.
- `FSC_LogErrores__c  = Log_Datos_Desembolso`

recordUpdates `Registrar_Datos_Incompletos_Rechazo` → ``.
- `FSC_LogErrores__c  = Log_Datos_Rechazo`

recordUpdates `Registrar_Error_Notificacion` → ``.
- `FSC_LogErrores__c  = Log_Error_Notificacion`

assignments `Preparar_Consumo` → `Notificacion_por_Cambio`.
- `Email_Cliente Assign = $Record.Account.PersonContact.Email`
- `Nombre_Producto Assign = crédito de consumo`
- `Firma_Equipo Assign = Equipo de Banca Personal`
- `Saludo_Cliente Assign = Saludo_Persona`

assignments `Preparar_Hipotecario` → `Notificacion_por_Cambio`.
- `Email_Cliente Assign = $Record.Account.PersonContact.Email`
- `Nombre_Producto Assign = crédito hipotecario`
- `Firma_Equipo Assign = Equipo de Banca Personal`
- `Saludo_Cliente Assign = Saludo_Persona`

assignments `Preparar_PYME` → `Notificacion_por_Cambio`.
- `Email_Cliente Assign = $Record.Account.ACC_Correo_Electronico_Cliente__c`
- `Nombre_Producto Assign = crédito PYME`
- `Firma_Equipo Assign = Equipo de Créditos PYME`
- `Saludo_Cliente Assign = Saludo_PYME`

assignments `Preparar_Vehicular` → `Notificacion_por_Cambio`.
- `Email_Cliente Assign = $Record.Account.PersonContact.Email`
- `Nombre_Producto Assign = crédito vehicular`
- `Firma_Equipo Assign = Equipo de Banca Personal`
- `Saludo_Cliente Assign = Saludo_Persona`

formulas `Avisar_Asignacion_Captura` → ``.

```text
AND(
    ISPICKVAL({!$Record.Status}, "En proceso"),
    ISPICKVAL({!$Record.FSC_Subestado__c}, "Creación de crédito"),
    OR(ISPICKVAL({!$Record.FSC_FormaDeDesembolso__c}, "Cheque de administracion"), ISPICKVAL({!$Record.FSC_FormaDeDesembolso__c}, "Cuenta de ahorro y Cheque de administración")),
    NOT(ISBLANK({!$Record.FSC_UsuarioCaptura__c})),
    NOT(ISBLANK({!$Record.FSC_UsuarioCaptura__r.Email})),
    CONTAINS({!$Record.FSC_EventosNotificacion__c}, "|CAPTURA|")
)
```


formulas `Avisar_Asignacion_Operaciones` → ``.

```text
AND(
    ISPICKVAL({!$Record.Status}, "En proceso"),
    ISPICKVAL({!$Record.FSC_Subestado__c}, "Desembolso"),
    OR(ISPICKVAL({!$Record.FSC_FormaDeDesembolso__c}, "Cheque de administracion"), ISPICKVAL({!$Record.FSC_FormaDeDesembolso__c}, "Cuenta de ahorro y Cheque de administración")),
    NOT(ISBLANK({!$Record.FSC_UsuarioOperaciones__c})),
    NOT(ISBLANK({!$Record.FSC_UsuarioOperaciones__r.Email})),
    CONTAINS({!$Record.FSC_EventosNotificacion__c}, "|OPERACIONES|")
)
```


formulas `Cuenta_Enmascarada` → ``.

```text
IF(
    ISBLANK({!$Record.FSC_NumeroCuentaDesembolso__c}),
    "",
    "****" & RIGHT({!$Record.FSC_NumeroCuentaDesembolso__c}, 4)
)
```


formulas `Datos_Aprobacion_Validos` → ``.

```text
AND(
    {!Email_Cliente_Valido},
    NOT(ISBLANK(TEXT({!$Record.FSC_Moneda__c}))),
    NOT(ISBLANK({!$Record.FSC_MontoAprobado__c})),
    {!$Record.FSC_MontoAprobado__c} > 0,
    NOT(ISBLANK({!$Record.FSC_PlazoMesesAprobado__c})),
    {!$Record.FSC_PlazoMesesAprobado__c} > 0,
    NOT(ISBLANK({!$Record.FSC_TasaInteresAprobada__c})),
    {!$Record.FSC_TasaInteresAprobada__c} > 0,
    {!$Record.FSC_MontoTotalCuotaMensual__c} > 0,
    NOT(ISBLANK({!$Record.FSC_Destino_del_Prestamo__c})),
    NOT(ISBLANK({!$Record.CreatedBy.Email})),
    OR(
        NOT(ISBLANK({!$Record.FSC_CondicionComite__c})),
        NOT(ISBLANK({!$Record.FSC_OtrasCondicionesComite__c})),
        NOT(ISBLANK({!$Record.FSC_Condiciones_de_la_Facilidad__c}))
    )
)
```


formulas `Datos_Desembolso_Base_Validos` → ``.

```text
AND(
    {!Email_Cliente_Valido},
    NOT(ISBLANK(TEXT({!$Record.FSC_Moneda__c}))),
    NOT(ISBLANK({!$Record.FSC_MontoDesembolso__c})),
    {!$Record.FSC_MontoDesembolso__c} > 0
)
```


formulas `Datos_Desembolso_Cheque_Validos` → ``.

```text
AND(
    {!Datos_Desembolso_Base_Validos},
    NOT(ISBLANK({!$Record.FSC_Sucursal__c})),
    NOT(ISBLANK({!$Record.FSC_BeneficiarioDesembolso__c}))
)
```


formulas `Datos_Desembolso_Combinado_Validos` → ``.

```text
AND(
    {!Datos_Desembolso_Base_Validos},
    NOT(ISBLANK({!$Record.FSC_NumeroCuentaDesembolso__c})),
    NOT(ISBLANK({!$Record.FSC_Sucursal__c})),
    NOT(ISBLANK({!$Record.FSC_BeneficiarioDesembolso__c}))
)
```


formulas `Datos_Desembolso_Cuenta_Validos` → ``.

```text
AND(
    {!Datos_Desembolso_Base_Validos},
    NOT(ISBLANK({!$Record.FSC_NumeroCuentaDesembolso__c}))
)
```


formulas `Datos_Rechazo_Validos` → ``.

```text
AND(
    {!Email_Cliente_Valido},
    NOT(ISBLANK({!$Record.Name}))
)
```


formulas `Email_Cliente_Valido` → ``.

```text
AND(
    NOT(ISBLANK({!Email_Cliente})),
    REGEX({!Email_Cliente}, "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$")
)
```


formulas `Enlace_Solicitud_Contratos` → ``.

```text
LEFT({!$Api.Partner_Server_URL_660}, FIND("/services", {!$Api.Partner_Server_URL_660})) & "lightning/r/ResidentialLoanApplication/" & {!$Record.Id} & "/view"
```


formulas `Etiqueta_Moneda` → ``.

```text
CASE(
    TEXT({!$Record.FSC_Moneda__c}),
    "1", "DOP",
    "2", "USD",
    "3", "EUR",
    ""
)
```


formulas `Log_Datos_Aprobacion` → ``.

```text
LEFT(
    IF(ISBLANK({!$Record.FSC_LogErrores__c}), "", {!$Record.FSC_LogErrores__c} & BR()) &
    TEXT({!$Flow.CurrentDateTime}) & " - Notificación de aprobación condicionada omitida por datos incompletos.",
    10000
)
```


formulas `Log_Datos_Desembolso` → ``.

```text
LEFT(
    IF(ISBLANK({!$Record.FSC_LogErrores__c}), "", {!$Record.FSC_LogErrores__c} & BR()) &
    TEXT({!$Flow.CurrentDateTime}) & " - Notificación de desembolso omitida por datos incompletos.",
    10000
)
```


formulas `Log_Datos_Rechazo` → ``.

```text
LEFT(
    IF(ISBLANK({!$Record.FSC_LogErrores__c}), "", {!$Record.FSC_LogErrores__c} & BR()) &
    TEXT({!$Flow.CurrentDateTime}) & " - Notificación de rechazo omitida por destinatario inválido.",
    10000
)
```


formulas `Log_Error_Notificacion` → ``.

```text
LEFT(
    IF(ISBLANK({!$Record.FSC_LogErrores__c}), "", {!$Record.FSC_LogErrores__c} & BR()) &
    TEXT({!$Flow.CurrentDateTime}) & " - Error al enviar notificación: " & {!$Flow.FaultMessage},
    10000
)
```


formulas `Saludo_Persona` → ``.

```text
IF(
    ISBLANK({!$Record.FSC_Nombre_Cliente__c}),
    "Hola,",
    "Hola " & {!$Record.FSC_Nombre_Cliente__c} & ","
)
```


formulas `Saludo_PYME` → ``.

```text
IF(
    ISBLANK({!$Record.Account.Name}),
    "Estimado cliente,",
    "Estimado cliente de " & {!$Record.Account.Name} & ","
)
```


### FSC_PocesoAprobacionExcepcionBuro

Estado: `Active`. Disparador: `Update / RecordAfterSave`. Inicio: `GetColaExcepcionBuro`.

Lógica de filtros: `and`. Solo cuando cumple requisitos: ``.
- `FSC_Resultado_Buro__c EqualTo Rechazado`
- `FSC_SolicitaExcepcionParaRechazoDeBuro__c EqualTo true`

Acción `EnviarAprobacionExcepcionBuro`: `submit / submit`.
- `objectId = $Record.Id`
- `nextApproverIds = ListaDeUsuariosAprobadores`
- `processDefinitionNameOrId = FSC_Excepcion_Buro`

Acción `ObtenerUsuarioExcepcionBuroDesdeCola`: `apex / FSC_RandomQueueApproverAction`.
- `groupId = GetColaExcepcionBuro.Id`

Decisión `SeEncontroUsuarioExcepcionBuro`; salida por defecto: ``.
- `UsuarioExcepcionBuroEncontrado` (and) → `AsignacionUsuarioExcepcionBuroDesdeCola`.
  - `ObtenerUsuarioExcepcionBuroDesdeCola.userId IsBlank false`

assignments `AsignacionUsuarioExcepcionBuroDesdeCola` → `EnviarAprobacionExcepcionBuro`.
- `ListaDeUsuariosAprobadores Add = ObtenerUsuarioExcepcionBuroDesdeCola.userId`

recordLookups `GetColaExcepcionBuro` → `ObtenerUsuarioExcepcionBuroDesdeCola`.
Objeto `Group`; lógica `and`.
- `DeveloperName EqualTo FSC_Cola_Excepcion_Buro`

### FSC_Preparar_Notificaciones_RLA

Estado: `Active`. Disparador: `Update / RecordBeforeSave`. Inicio: `Validar_Tipo_Credito`.

Lógica de filtros: `or`. Solo cuando cumple requisitos: ``.
- `FSC_Subestado__c IsChanged true`
- `FSC_Aprobado_con_Condiciones__c IsChanged true`
- `FSC_Doc_Incompleta_Analisis__c IsChanged true`
- `FSC_Doc_Incompleta_Desembolso__c IsChanged true`
- `FSC_Doc_Incompleta_Post_Desembolso__c IsChanged true`
- `FSC_UsuarioCaptura__c IsChanged true`
- `FSC_UsuarioOperaciones__c IsChanged true`
- `FSC_FormaDeDesembolso__c IsChanged true`

Decisión `Validar_Tipo_Credito`; salida por defecto: ``.
- `Tipo_Credito_Soportado` (or) → `Registrar_Eventos`.
  - `$Record.RecordType.DeveloperName EqualTo FSC_Solicitud_Credito_PYME`
  - `$Record.RecordType.DeveloperName EqualTo FSC_Solicitud_Credito_Consumo`
  - `$Record.RecordType.DeveloperName EqualTo FSC_Solicitud_Credito_Hipotecario`
  - `$Record.RecordType.DeveloperName EqualTo FSC_Solicitud_Credito_Vehiculo`

assignments `Registrar_Eventos` → ``.
- `$Record.FSC_EventosNotificacion__c Assign = Token_Eventos`

formulas `Token_Eventos` → ``.

```text
{!$Flow.InterviewGuid}
& IF(ISCHANGED({!$Record.FSC_Subestado__c}), "|SUBESTADO|", "")
& IF(
    AND(
        ISCHANGED({!$Record.FSC_Subestado__c}),
        ISPICKVAL({!$Record__Prior.FSC_Subestado__c}, "Documentación para contratos"),
        OR(
            ISPICKVAL({!$Record.FSC_Subestado__c}, "Generación de pagarés y plantillas"),
            ISPICKVAL({!$Record.FSC_Subestado__c}, "Generación de contrato")
        )
    ),
    "|CONTRATOS_ENVIADA|",
    ""
)
& IF(ISCHANGED({!$Record.FSC_Aprobado_con_Condiciones__c}), "|APROBACION|", "")
& IF(ISCHANGED({!$Record.FSC_Doc_Incompleta_Analisis__c}), "|INFO_ANALISIS|", "")
& IF(ISCHANGED({!$Record.FSC_Doc_Incompleta_Desembolso__c}), "|INFO_DESEMBOLSO|", "")
& IF(ISCHANGED({!$Record.FSC_Doc_Incompleta_Post_Desembolso__c}), "|INFO_POST_DESEMBOLSO|", "")
& IF(
    OR(
        ISCHANGED({!$Record.FSC_UsuarioCaptura__c}),
        ISCHANGED({!$Record.FSC_Subestado__c}),
        ISCHANGED({!$Record.FSC_FormaDeDesembolso__c})
    ),
    "|CAPTURA|",
    ""
)
& IF(
    OR(
        ISCHANGED({!$Record.FSC_UsuarioOperaciones__c}),
        ISCHANGED({!$Record.FSC_Subestado__c}),
        ISCHANGED({!$Record.FSC_FormaDeDesembolso__c})
    ),
    "|OPERACIONES|",
    ""
)
```


### FSC_ProcesoAprobacionAnalista

Estado: `Active`. Disparador: `Update / RecordAfterSave`. Inicio: `OrigenAsignacionAnalista`.


```text
AND(
ISPICKVAL({!$Record.FSC_Resultado_Buro__c}, 'Referido'),
{!$Record.FSC_Doc_Completa_Analisis__c} = true,
{!$Record.FSC_DebeRevisarComite__c} = false,
{!$Record.FSC_DebeRevisarSupervisor__c} = false,
{!$Record.FSC_Aprobado_con_Condiciones__c} = false,
OR(
    AND(
        ISPICKVAL({!$Record.FSC_Subestado__c}, 'Recepción de documentos – Análisis'),
        OR(
            ISCHANGED({!$Record.FSC_Resultado_Buro__c}),
            ISCHANGED({!$Record.FSC_Subestado__c}),
            ISCHANGED({!$Record.FSC_Doc_Completa_Analisis__c})
        )
    ),
    AND(
        ISPICKVAL({!$Record.FSC_Subestado__c}, 'Análisis de crédito'),
        ISCHANGED({!$Record.FSC_DebeRevisarSupervisor__c})
    )
)
)
```

Acción `EnviarAprobacionAnalista`: `submit / submit`.
- `objectId = $Record.Id`
- `nextApproverIds = ListaDeUsuariosAprobadores`
- `processDefinitionNameOrId = FSC_AnalistasDeCredito`

Acción `ObtenerUsuarioAleatorioDeCola`: `apex / FSC_RandomQueueApproverAction`.
- `groupId = GetColaAnalistasDeCredito.Id`

Decisión `OrigenAsignacionAnalista`; salida por defecto: `Tiene_analista_asignado`.
- `AsignacionInicial` (and) → `PrepararAnalisisCredito`.
  - `$Record.FSC_Subestado__c EqualTo Recepción de documentos – Análisis`

Decisión `SeEncontroUsuarioAleatorio`; salida por defecto: ``.
- `UsuarioAleatorioEncontrado` (and) → `PersistirUsuarioAnalistaSeleccionado`.
  - `ObtenerUsuarioAleatorioDeCola.userId IsBlank false`

Decisión `Tiene_analista_asignado`; salida por defecto: `GetColaAnalistasDeCredito`.
- `TieneAnalistaAsignadoSi` (and) → `AsignacionUsuarioAnalista`.
  - `$Record.FSC_UsuarioAnalista__c IsBlank false`

recordUpdates `PersistirUsuarioAnalistaSeleccionado` → `AsignacionUsuarioAleatorioColaAnalista`.
- `FSC_UsuarioAnalista__c  = ObtenerUsuarioAleatorioDeCola.userId`

recordUpdates `PrepararAnalisisCredito` → `Tiene_analista_asignado`.
- `FSC_DocumentacionValidadaAnalista__c  = false`
- `FSC_Subestado__c  = Análisis de crédito`

assignments `AsignacionUsuarioAleatorioColaAnalista` → `EnviarAprobacionAnalista`.
- `ListaDeUsuariosAprobadores Add = ObtenerUsuarioAleatorioDeCola.userId`

assignments `AsignacionUsuarioAnalista` → `EnviarAprobacionAnalista`.
- `ListaDeUsuariosAprobadores Add = $Record.FSC_UsuarioAnalista__c`

formulas `NombreColaAnalistasPorTipoCredito` → ``.

```text
CASE(
    {!$Record.RecordType.DeveloperName},
    "FSC_Solicitud_Credito_PYME", "FSC_ColaAnalistasDeCredito_PYME",
    "FSC_Solicitud_Credito_Consumo", "FSC_ColaAnalistasDeCredito_Consumo",
    "FSC_Solicitud_Credito_Vehiculo", "FSC_ColaAnalistasDeCredito_Vehiculo",
    "FSC_Solicitud_Credito_Hipotecario", "FSC_ColaAnalistasDeCredito_Hipotecario",
    "FSC_ColaAnalistasDeCredito"
)
```


recordLookups `GetColaAnalistasDeCredito` → `ObtenerUsuarioAleatorioDeCola`.
Objeto `Group`; lógica `and`.
- `DeveloperName EqualTo NombreColaAnalistasPorTipoCredito`

### FSC_ProcesoAprobacionBancaSeguro

Estado: `Active`. Disparador: `Update / RecordAfterSave`. Inicio: `ObtenerColaBancaSeguro`.


```text
AND(
ISPICKVAL({!$Record.Status}, 'En proceso'),
ISPICKVAL({!$Record.FSC_Subestado__c}, 'Banca Seguro'),
{!$Record.FSC_BancaSeguroAprobada__c} = false,
ISCHANGED({!$Record.FSC_Subestado__c})
)
```

Acción `EnviarAprobacionBancaSeguro`: `submit / submit`.
- `objectId = $Record.Id`
- `nextApproverIds = UsuariosAprobadores`
- `processDefinitionNameOrId = FSC_BancaSeguro`

Acción `ObtenerUsuarioBancaSeguro`: `apex / FSC_RandomQueueApproverAction`.
- `groupId = ObtenerColaBancaSeguro.Id`

Decisión `SeEncontroUsuario`; salida por defecto: ``.
- `UsuarioEncontrado` (and) → `PersistirUsuarioBancaSeguro`.
  - `ObtenerUsuarioBancaSeguro.userId IsBlank false`

recordUpdates `PersistirUsuarioBancaSeguro` → `AgregarUsuarioAprobador`.
- `FSC_UsuarioBancaSeguro__c  = ObtenerUsuarioBancaSeguro.userId`

assignments `AgregarUsuarioAprobador` → `EnviarAprobacionBancaSeguro`.
- `UsuariosAprobadores Add = ObtenerUsuarioBancaSeguro.userId`

recordLookups `ObtenerColaBancaSeguro` → `ObtenerUsuarioBancaSeguro`.
Objeto `Group`; lógica `and`.
- `DeveloperName EqualTo FSC_ColaBancaSeguro`

### FSC_ProcesoAprobacionComite

Estado: `Active`. Disparador: `Update / RecordAfterSave`. Inicio: `Tiene_comite_asignado`.


```text
AND(
ISCHANGED({!$Record.FSC_DebeRevisarComite__c}),
ISPICKVAL({!$Record.FSC_Resultado_Buro__c}, 'Referido'),
ISPICKVAL({!$Record.FSC_Subestado__c}, 'Análisis de crédito'),
{!$Record.FSC_Doc_Completa_Analisis__c} = true,
{!$Record.FSC_DebeRevisarComite__c} = true,
{!$Record.FSC_DebeRevisarSupervisor__c} = false,
{!$Record.FSC_Aprobado_con_Condiciones__c} = false
)
```

Acción `EnviarAprobacionComite`: `submit / submit`.
- `objectId = $Record.Id`
- `nextApproverIds = ListaDeUsuariosAprobadores`
- `processDefinitionNameOrId = FSC_ComiteDeCredito`

Acción `ObtenerUsuarioComiteIDesdeCola`: `apex / FSC_RandomQueueApproverAction`.
- `assignedUserFieldApiName = FSC_UsuarioComite__c`
- `groupId = GetColaComiteI.Id`

Acción `ObtenerUsuarioComiteIIDesdeCola`: `apex / FSC_RandomQueueApproverAction`.
- `assignedUserFieldApiName = FSC_UsuarioComite__c`
- `groupId = GetColaComiteII.Id`

Acción `ObtenerUsuarioComiteIIIDesdeCola`: `apex / FSC_RandomQueueApproverAction`.
- `assignedUserFieldApiName = FSC_UsuarioComite__c`
- `groupId = GetColaComiteIII.Id`

Decisión `Monto`; salida por defecto: `GetColaComiteI`.
- `Hasta_2_5M_PYME_o_7M_Otros` ((1 AND 3) OR (2 AND NOT(3))) → `GetColaComiteI`.
  - `$Record.FSC_Monto__c LessThanOrEqualTo 2500000.0`
  - `$Record.FSC_Monto__c LessThanOrEqualTo 7000000.0`
  - `$Record.RecordType.DeveloperName EqualTo FSC_Solicitud_Credito_PYME`
- `Hasta_25M` (and) → `GetColaComiteII`.
  - `$Record.FSC_Monto__c LessThanOrEqualTo 2.5E7`
- `Hasta_100M` (and) → `GetColaComiteIII`.
  - `$Record.FSC_Monto__c LessThanOrEqualTo 1.0E8`

Decisión `SeEncontroUsuarioComiteI`; salida por defecto: ``.
- `UsuarioComiteIEncontrado` (and) → `PersistirUsuarioComiteSeleccionadoI`.
  - `ObtenerUsuarioComiteIDesdeCola.userId IsBlank false`

Decisión `SeEncontroUsuarioComiteII`; salida por defecto: ``.
- `UsuarioComiteIIEncontrado` (and) → `PersistirUsuarioComiteSeleccionadoII`.
  - `ObtenerUsuarioComiteIIDesdeCola.userId IsBlank false`

Decisión `SeEncontroUsuarioComiteIII`; salida por defecto: ``.
- `UsuarioComiteIIIEncontrado` (and) → `PersistirUsuarioComiteSeleccionadoIII`.
  - `ObtenerUsuarioComiteIIIDesdeCola.userId IsBlank false`

Decisión `Tiene_comite_asignado`; salida por defecto: `Monto`.
- `TieneComiteAsignadoSi` (and) → `AsignacionUsuarioComite`.
  - `$Record.FSC_UsuarioComite__c IsBlank false`

recordUpdates `PersistirUsuarioComiteSeleccionadoI` → `AsignacionUsuarioComiteIDesdeCola`.
- `FSC_UsuarioComite__c  = ObtenerUsuarioComiteIDesdeCola.userId`

recordUpdates `PersistirUsuarioComiteSeleccionadoII` → `AsignacionUsuarioComiteIIDesdeCola`.
- `FSC_UsuarioComite__c  = ObtenerUsuarioComiteIIDesdeCola.userId`

recordUpdates `PersistirUsuarioComiteSeleccionadoIII` → `AsignacionUsuarioComiteIIIDesdeCola`.
- `FSC_UsuarioComite__c  = ObtenerUsuarioComiteIIIDesdeCola.userId`

assignments `AsignacionUsuarioComite` → `EnviarAprobacionComite`.
- `ListaDeUsuariosAprobadores Add = $Record.FSC_UsuarioComite__c`

assignments `AsignacionUsuarioComiteIDesdeCola` → `EnviarAprobacionComite`.
- `ListaDeUsuariosAprobadores Add = ObtenerUsuarioComiteIDesdeCola.userId`

assignments `AsignacionUsuarioComiteIIDesdeCola` → `EnviarAprobacionComite`.
- `ListaDeUsuariosAprobadores Add = ObtenerUsuarioComiteIIDesdeCola.userId`

assignments `AsignacionUsuarioComiteIIIDesdeCola` → `EnviarAprobacionComite`.
- `ListaDeUsuariosAprobadores Add = ObtenerUsuarioComiteIIIDesdeCola.userId`

formulas `NombreColaComiteIIIPorTipoCredito` → ``.

```text
CASE(
    {!$Record.RecordType.DeveloperName},
    "FSC_Solicitud_Credito_PYME", "FSC_ColaComiteIII_PYME",
    "FSC_Solicitud_Credito_Consumo", "FSC_ColaComiteIII_Consumo",
    "FSC_Solicitud_Credito_Vehiculo", "FSC_ColaComiteIII_Vehiculo",
    "FSC_Solicitud_Credito_Hipotecario", "FSC_ColaComiteIII_Hipotecario",
    "FSC_ColaComiteIII"
)
```


formulas `NombreColaComiteIIPorTipoCredito` → ``.

```text
CASE(
    {!$Record.RecordType.DeveloperName},
    "FSC_Solicitud_Credito_PYME", "FSC_ColaComiteII_PYME",
    "FSC_Solicitud_Credito_Consumo", "FSC_ColaComiteII_Consumo",
    "FSC_Solicitud_Credito_Vehiculo", "FSC_ColaComiteII_Vehiculo",
    "FSC_Solicitud_Credito_Hipotecario", "FSC_ColaComiteII_Hipotecario",
    "FSC_ColaComiteII"
)
```


formulas `NombreColaComiteIPorTipoCredito` → ``.

```text
CASE(
    {!$Record.RecordType.DeveloperName},
    "FSC_Solicitud_Credito_PYME", "FSC_ColaComiteI_PYME",
    "FSC_Solicitud_Credito_Consumo", "FSC_ColaComiteI_Consumo",
    "FSC_Solicitud_Credito_Vehiculo", "FSC_ColaComiteI_Vehiculo",
    "FSC_Solicitud_Credito_Hipotecario", "FSC_ColaComiteI_Hipotecario",
    "FSC_ColaComiteI"
)
```


recordLookups `GetColaComiteI` → `ObtenerUsuarioComiteIDesdeCola`.
Objeto `Group`; lógica `and`.
- `DeveloperName EqualTo NombreColaComiteIPorTipoCredito`

recordLookups `GetColaComiteII` → `ObtenerUsuarioComiteIIDesdeCola`.
Objeto `Group`; lógica `and`.
- `DeveloperName EqualTo NombreColaComiteIIPorTipoCredito`

recordLookups `GetColaComiteIII` → `ObtenerUsuarioComiteIIIDesdeCola`.
Objeto `Group`; lógica `and`.
- `DeveloperName EqualTo NombreColaComiteIIIPorTipoCredito`

### FSC_ProcesoAprobacionGestionDePagaresYContratos

Estado: `Active`. Disparador: `Update / RecordAfterSave`. Inicio: `GetColaGestionDePagaresYContratos`.


```text
AND(
ISPICKVAL({!$Record.Status}, 'En proceso'),
ISPICKVAL({!$Record.FSC_Subestado__c}, 'Generación de pagarés y plantillas'),
{!$Record.FSC_Pagares_y_Plantillas_Generados__c} = false,
ISCHANGED({!$Record.FSC_Subestado__c})
)
```

Acción `ObtenerUsuarioGestionDePagaresDesdeCola`: `apex / FSC_RandomQueueApproverAction`.
- `groupId = GetColaGestionDePagaresYContratos.Id`

Decisión `SeEncontroUsuarioGestionDePagares`; salida por defecto: ``.
- `UsuarioGestionDePagaresEncontrado` (and) → `ActualizarUsuarioPagaresYContratos`.
  - `ObtenerUsuarioGestionDePagaresDesdeCola.userId IsBlank false`

recordUpdates `ActualizarUsuarioPagaresYContratos` → ``.
- `FSC_UsuarioPagaresYContratos__c  = ObtenerUsuarioGestionDePagaresDesdeCola.userId`

recordLookups `GetColaGestionDePagaresYContratos` → `ObtenerUsuarioGestionDePagaresDesdeCola`.
Objeto `Group`; lógica `and`.
- `DeveloperName EqualTo FSC_GestionDePagaresYContratos`

### FSC_ProcesoAprobacionGestionPlanillasDeDesembolso

Estado: `Active`. Disparador: `Update / RecordAfterSave`. Inicio: `GetColaGestionPlanillasDeDesembolso`.


```text
AND(
ISPICKVAL({!$Record.Status}, 'En proceso'),
ISPICKVAL({!$Record.FSC_Subestado__c}, 'Pendiente planilla de desembolso'),
{!$Record.FSC_Desembolso_Realizado__c} = false,
ISCHANGED({!$Record.FSC_Subestado__c})
)
```

Acción `ObtenerUsuarioGestionPlanillasDesdeCola`: `apex / FSC_RandomQueueApproverAction`.
- `groupId = GetColaGestionPlanillasDeDesembolso.Id`

Decisión `SeEncontroUsuarioGestionPlanillas`; salida por defecto: ``.
- `UsuarioGestionPlanillasEncontrado` (and) → `ActualizarUsuarioGestionPlanilla`.
  - `ObtenerUsuarioGestionPlanillasDesdeCola.userId IsBlank false`

recordUpdates `ActualizarUsuarioGestionPlanilla` → ``.
- `FSC_UsuarioGestionPlanilla__c  = ObtenerUsuarioGestionPlanillasDesdeCola.userId`

recordLookups `GetColaGestionPlanillasDeDesembolso` → `ObtenerUsuarioGestionPlanillasDesdeCola`.
Objeto `Group`; lógica `and`.
- `DeveloperName EqualTo FSC_GestionPlanillasDeDesembolso`

### FSC_ProcesoAprobacionRecepcionYControlDeDocs

Estado: `Obsolete`. Disparador: `Update / RecordAfterSave`. Inicio: `Tiene_recepcionista_asignado`.


```text
AND(
NOT(ISCHANGED({!$Record.FSC_UsuarioControlDocumentos__c})),
ISPICKVAL({!$Record.FSC_Resultado_Buro__c}, 'Referido'),
ISPICKVAL({!$Record.FSC_Subestado__c}, 'Recepción de documentos – Análisis'),
{!$Record.FSC_Doc_Completa_Analisis__c} = true
)
```

Acción `EnviarAprobacionRecepcion`: `submit / submit`.
- `objectId = $Record.Id`
- `nextApproverIds = ListaDeUsuariosAprobadores`
- `processDefinitionNameOrId = FSC_RecepcionYControlDeDocs`

Acción `ObtenerUsuarioRecepcionDesdeCola`: `apex / FSC_RandomQueueApproverAction`.
- `assignedUserFieldApiName = FSC_UsuarioControlDocumentos__c`
- `groupId = GetColaRecepcionYControlDeDosc.Id`

Decisión `SeEncontroUsuarioRecepcion`; salida por defecto: ``.
- `UsuarioRecepcionEncontrado` (and) → `PersistirUsuarioRecepcionSeleccionado`.
  - `ObtenerUsuarioRecepcionDesdeCola.userId IsBlank false`

Decisión `Tiene_recepcionista_asignado`; salida por defecto: `GetColaRecepcionYControlDeDosc`.
- `TieneRecepcionistaAsignadoSi` (and) → `AsignacionUsuarioRecepcion`.
  - `$Record.FSC_UsuarioControlDocumentos__c IsBlank false`

recordUpdates `PersistirUsuarioRecepcionSeleccionado` → `AsignacionUsuarioRecepcionDesdeCola`.
- `FSC_UsuarioControlDocumentos__c  = ObtenerUsuarioRecepcionDesdeCola.userId`

assignments `AsignacionUsuarioRecepcion` → `EnviarAprobacionRecepcion`.
- `ListaDeUsuariosAprobadores Add = $Record.FSC_UsuarioControlDocumentos__c`

assignments `AsignacionUsuarioRecepcionDesdeCola` → `EnviarAprobacionRecepcion`.
- `ListaDeUsuariosAprobadores Add = ObtenerUsuarioRecepcionDesdeCola.userId`

recordLookups `GetColaRecepcionYControlDeDosc` → `ObtenerUsuarioRecepcionDesdeCola`.
Objeto `Group`; lógica `and`.
- `DeveloperName EqualTo FSC_ColaRecepcionYControlDeDocumentos`

### FSC_ProcesoAprobacionRecepcionYControlDeDocsDesembolso

Estado: `Active`. Disparador: `Update / RecordAfterSave`. Inicio: `Tiene_recepcionista_asignado`.


```text
AND(
NOT(ISCHANGED({!$Record.FSC_UsuarioControlDocumentos__c})),
ISPICKVAL({!$Record.FSC_Subestado__c}, 'Documentación para desembolso y firmas'),
{!$Record.FSC_Doc_Completa_Desembolso__c} = true
)
```

Acción `EnviarAprobacionRecepcion`: `submit / submit`.
- `objectId = $Record.Id`
- `nextApproverIds = ListaDeUsuariosAprobadores`
- `processDefinitionNameOrId = FSC_RecepcionDocsDesembolso`

Acción `ObtenerUsuarioRecepcionDesdeCola`: `apex / FSC_RandomQueueApproverAction`.
- `assignedUserFieldApiName = FSC_UsuarioControlDocumentos__c`
- `groupId = GetColaRecepcionYControlDeDosc.Id`

Decisión `SeEncontroUsuarioRecepcion`; salida por defecto: ``.
- `UsuarioRecepcionEncontrado` (and) → `PersistirUsuarioRecepcionSeleccionado`.
  - `ObtenerUsuarioRecepcionDesdeCola.userId IsBlank false`

Decisión `Tiene_recepcionista_asignado`; salida por defecto: `GetColaRecepcionYControlDeDosc`.
- `TieneRecepcionistaAsignadoSi` (and) → `AsignacionUsuarioRecepcion`.
  - `$Record.FSC_UsuarioControlDocumentos__c IsBlank false`

recordUpdates `PersistirUsuarioRecepcionSeleccionado` → `AsignacionUsuarioRecepcionDesdeCola`.
- `FSC_UsuarioControlDocumentos__c  = ObtenerUsuarioRecepcionDesdeCola.userId`

assignments `AsignacionUsuarioRecepcion` → `EnviarAprobacionRecepcion`.
- `ListaDeUsuariosAprobadores Add = $Record.FSC_UsuarioControlDocumentos__c`

assignments `AsignacionUsuarioRecepcionDesdeCola` → `EnviarAprobacionRecepcion`.
- `ListaDeUsuariosAprobadores Add = ObtenerUsuarioRecepcionDesdeCola.userId`

recordLookups `GetColaRecepcionYControlDeDosc` → `ObtenerUsuarioRecepcionDesdeCola`.
Objeto `Group`; lógica `and`.
- `DeveloperName EqualTo FSC_ColaRecepcionYControlDeDocumentos`

### FSC_ProcesoAprobacionSupervisor

Estado: `Active`. Disparador: `Update / RecordAfterSave`. Inicio: `Tiene_supervisor_asignado`.


```text
AND(
ISCHANGED({!$Record.FSC_DebeRevisarSupervisor__c}),
ISPICKVAL({!$Record.FSC_Resultado_Buro__c}, 'Referido'),
ISPICKVAL({!$Record.FSC_Subestado__c}, 'Análisis de crédito'),
{!$Record.FSC_Doc_Completa_Analisis__c} = true,
{!$Record.FSC_DebeRevisarComite__c} = false,
{!$Record.FSC_DebeRevisarSupervisor__c} = true,
{!$Record.FSC_Aprobado_con_Condiciones__c} = false
)
```

Acción `EnviarAprobacionSupervisor`: `submit / submit`.
- `objectId = $Record.Id`
- `nextApproverIds = ListaDeUsuariosAprobadores`
- `processDefinitionNameOrId = FSC_SupervisorDeCredito`

Acción `ObtenerUsuarioSupervisorDesdeCola`: `apex / FSC_RandomQueueApproverAction`.
- `assignedUserFieldApiName = FSC_UsuarioSupervisor__c`
- `groupId = GetColaSupervisorDeCredito.Id`

Decisión `SeEncontroUsuarioSupervisor`; salida por defecto: ``.
- `UsuarioSupervisorEncontrado` (and) → `PersistirUsuarioSupervisorSeleccionado`.
  - `ObtenerUsuarioSupervisorDesdeCola.userId IsBlank false`

Decisión `Tiene_supervisor_asignado`; salida por defecto: `GetColaSupervisorDeCredito`.
- `TieneSupervisorAsignadoSi` (and) → `AsignacionUsuarioSupervisor`.
  - `$Record.FSC_UsuarioSupervisor__c IsBlank false`

recordUpdates `PersistirUsuarioSupervisorSeleccionado` → `AsignacionUsuarioSupervisorDesdeCola`.
- `FSC_UsuarioSupervisor__c  = ObtenerUsuarioSupervisorDesdeCola.userId`

assignments `AsignacionUsuarioSupervisor` → `EnviarAprobacionSupervisor`.
- `ListaDeUsuariosAprobadores Add = $Record.FSC_UsuarioSupervisor__c`

assignments `AsignacionUsuarioSupervisorDesdeCola` → `EnviarAprobacionSupervisor`.
- `ListaDeUsuariosAprobadores Add = ObtenerUsuarioSupervisorDesdeCola.userId`

formulas `NombreColaSupervisoresPorTipoCredito` → ``.

```text
CASE(
    {!$Record.RecordType.DeveloperName},
    "FSC_Solicitud_Credito_PYME", "FSC_ColaSupervisores_PYME",
    "FSC_Solicitud_Credito_Consumo", "FSC_ColaSupervisores_Consumo",
    "FSC_Solicitud_Credito_Vehiculo", "FSC_ColaSupervisores_Vehiculo",
    "FSC_Solicitud_Credito_Hipotecario", "FSC_ColaSupervisores_Hipotecario",
    "FSC_ColaSupervisores"
)
```


recordLookups `GetColaSupervisorDeCredito` → `ObtenerUsuarioSupervisorDesdeCola`.
Objeto `Group`; lógica `and`.
- `DeveloperName EqualTo NombreColaSupervisoresPorTipoCredito`

### FSC_ProcesoAprobacionValidacionEnAbanks

Estado: `Active`. Disparador: `Update / RecordAfterSave`. Inicio: `FSC_ObtenerColaValidacionEnAbanks`.


```text
AND(
    ISPICKVAL({!$Record.Status}, 'En proceso'),
    ISPICKVAL({!$Record.FSC_Subestado__c}, 'Creación de crédito'),
    ISPICKVAL({!$Record.FSC_FormaDeDesembolso__c}, 'Cuenta de ahorro'),
    NOT(ISBLANK({!$Record.FSC_NumeroPrestamoAbanks__c})),
    ISBLANK({!$Record.FSC_UsuarioValidadorAbanks__c}),
    ISCHANGED({!$Record.FSC_NumeroPrestamoAbanks__c})
)
```

Acción `FSC_EnviarAprobacionValidacionEnAbanks`: `submit / submit`.
- `objectId = $Record.Id`
- `nextApproverIds = FSC_ListaUsuariosAprobadores`
- `processDefinitionNameOrId = FSC_ValidacionEnAbanks`

Acción `FSC_ObtenerUsuarioAleatorioDeCola`: `apex / FSC_RandomQueueApproverAction`.
- `groupId = FSC_ObtenerColaValidacionEnAbanks.Id`

Decisión `FSC_SeEncontroUsuarioAleatorio`; salida por defecto: ``.
- `FSC_UsuarioAleatorioEncontrado` (and) → `FSC_PersistirUsuarioValidadorAbanks`.
  - `FSC_ObtenerUsuarioAleatorioDeCola.userId IsBlank false`

recordUpdates `FSC_PersistirUsuarioValidadorAbanks` → `FSC_AsignarUsuarioAListaAprobadores`.
- `FSC_UsuarioValidadorAbanks__c  = FSC_ObtenerUsuarioAleatorioDeCola.userId`

assignments `FSC_AsignarUsuarioAListaAprobadores` → `FSC_EnviarAprobacionValidacionEnAbanks`.
- `FSC_ListaUsuariosAprobadores Add = FSC_ObtenerUsuarioAleatorioDeCola.userId`

recordLookups `FSC_ObtenerColaValidacionEnAbanks` → `FSC_ObtenerUsuarioAleatorioDeCola`.
Objeto `Group`; lógica `and`.
- `DeveloperName EqualTo FSC_ColaValidacionEnAbanks`

### FSC_ProcesoAsignacionFormalizacion

Estado: `Active`. Disparador: `Update / RecordAfterSave`. Inicio: `GetColaGestionFormalizacion`.


```text
AND(
ISPICKVAL({!$Record.Status}, 'En proceso'),
ISPICKVAL({!$Record.FSC_Subestado__c}, 'Formalización'),
ISCHANGED({!$Record.FSC_Subestado__c})
)
```

Acción `ObtenerUsuarioFormalizacionDesdeCola`: `apex / FSC_RandomQueueApproverAction`.
- `groupId = GetColaGestionFormalizacion.Id`

Decisión `SeEncontroUsuarioFormalizacion`; salida por defecto: ``.
- `UsuarioFormalizacionEncontrado` (and) → `ActualizarUsuarioFormalizacion`.
  - `ObtenerUsuarioFormalizacionDesdeCola.userId IsBlank false`

recordUpdates `ActualizarUsuarioFormalizacion` → ``.
- `FSC_UsuarioFormalizacion__c  = ObtenerUsuarioFormalizacionDesdeCola.userId`

recordLookups `GetColaGestionFormalizacion` → `ObtenerUsuarioFormalizacionDesdeCola`.
Objeto `Group`; lógica `and`.
- `DeveloperName EqualTo FSC_GestionFormalizacion`

## Procesos de aprobación

### FSC_AnalistasDeCredito

Activo: `true`. Recall: `false`. Edición: `AdminOnly`.

Lógica de entrada: `1 AND 2 AND 3 AND 4 AND 5 AND 6`.
- `ResidentialLoanApplication.FSC_Resultado_Buro__c equals Referido`
- `ResidentialLoanApplication.FSC_Subestado__c equals Análisis de crédito`
- `ResidentialLoanApplication.FSC_Doc_Completa_Analisis__c equals True`
- `ResidentialLoanApplication.FSC_DebeRevisarComite__c equals False`
- `ResidentialLoanApplication.FSC_DebeRevisarSupervisor__c equals False`
- `ResidentialLoanApplication.FSC_Aprobado_con_Condiciones__c equals False`

Aprobador del paso `FSC_StepAnalistaDeCredito`: `adhoc / `.
- Aprobación final: `FieldUpdate / FSC_DebeRevisarComite`; FSC_DebeRevisarComite__c = 1.
- Rechazo final: `FieldUpdate / FSC_Asignar_Status_Cerrada_Perdida`; Status = Cerrada Perdida.
- Rechazo final: `FieldUpdate / FSC_SubestadoRechazadoPorAnalistaDeCred`; FSC_Subestado__c = Rechazado por análisis.

### FSC_Aprobacion_PLA

Activo: `true`. Recall: `false`. Edición: `AdminOnly`.

Lógica de entrada: ``.
- `ResidentialLoanApplication.FSC_Resultado_PEP_Listas__c equals Coincidencia`
- `ResidentialLoanApplication.FSC_Subestado__c equals En validación PEP/Listas`

Aprobador del paso `FSC_Aprobar_o_Rechazar`: `adhoc / `.
- Paso FSC_Aprobar_o_Rechazar aprobado: `FieldUpdate / FSC_Asignar_ResultadoPEPListas_Aprobada`; FSC_Resultado_PEP_Listas__c = Coincidencia aprobada.
- Paso FSC_Aprobar_o_Rechazar aprobado: `FieldUpdate / FSC_Asignar_Status_En_proceso`; Status = En proceso.
- Paso FSC_Aprobar_o_Rechazar aprobado: `FieldUpdate / FSC_Asignar_Substatus_En_Motor_Buro`; FSC_Subestado__c = En Motor Buró.
- Paso FSC_Aprobar_o_Rechazar rechazado: `FieldUpdate / FSC_Asignar_ResultadoPEPListas_Rechazada`; FSC_Resultado_PEP_Listas__c = Coincidencia no aprobada.
- Paso FSC_Aprobar_o_Rechazar rechazado: `FieldUpdate / FSC_Asignar_Status_Cerrada_Perdida`; Status = Cerrada Perdida.
- Paso FSC_Aprobar_o_Rechazar rechazado: `FieldUpdate / FSC_Asignar_Substatus_Rechazado_por_PLA`; FSC_Subestado__c = Rechazado por PLA.

### FSC_Aprobacion_PLA_CHV

Activo: `true`. Recall: `false`. Edición: `AdminOnly`.

Lógica de entrada: ``.
- `ResidentialLoanApplication.FSC_Resultado_PEP_Listas__c equals Coincidencia`
- `ResidentialLoanApplication.FSC_Subestado__c equals Completando información`
- `ResidentialLoanApplication.RecordType notEqual Solicitud de crédito pyme`

Aprobador del paso `FSC_Aprobar_o_Rechazar`: `adhoc / `.
- Paso FSC_Aprobar_o_Rechazar rechazado: `FieldUpdate / FSC_Asignar_ResultadoPEPListas_Rechazada`; FSC_Resultado_PEP_Listas__c = Coincidencia no aprobada.
- Paso FSC_Aprobar_o_Rechazar rechazado: `FieldUpdate / FSC_Asignar_Status_Cerrada_Perdida`; Status = Cerrada Perdida.
- Paso FSC_Aprobar_o_Rechazar rechazado: `FieldUpdate / FSC_Asignar_Substatus_Rechazado_por_PLA`; FSC_Subestado__c = Rechazado por PLA.

### FSC_Aprobacion_PLA_Consumo

Activo: `true`. Recall: `false`. Edición: `AdminOnly`.

Lógica de entrada: ``.
- `ResidentialLoanApplication.FSC_Resultado_PEP_Listas__c equals Coincidencia`
- `ResidentialLoanApplication.FSC_Subestado__c equals Completando información`
- `ResidentialLoanApplication.RecordType equals Solicitud de crédito consumo`

Aprobador del paso `FSC_Aprobar_o_Rechazar`: `adhoc / `.
- Paso FSC_Aprobar_o_Rechazar rechazado: `FieldUpdate / FSC_Asignar_ResultadoPEPListas_Rechazada`; FSC_Resultado_PEP_Listas__c = Coincidencia no aprobada.
- Paso FSC_Aprobar_o_Rechazar rechazado: `FieldUpdate / FSC_Asignar_Status_Cerrada_Perdida`; Status = Cerrada Perdida.
- Paso FSC_Aprobar_o_Rechazar rechazado: `FieldUpdate / FSC_Asignar_Substatus_Rechazado_por_PLA`; FSC_Subestado__c = Rechazado por PLA.

### FSC_Aprobacion_PLA_PYME

Activo: `true`. Recall: `false`. Edición: `AdminOnly`.

Lógica de entrada: ``.
- `ResidentialLoanApplication.FSC_Resultado_PEP_Listas__c equals Coincidencia`
- `ResidentialLoanApplication.FSC_Subestado__c equals En validación PEP/Listas`
- `ResidentialLoanApplication.RecordType equals Solicitud de crédito pyme`

Aprobador del paso `FSC_Aprobar_o_Rechazar`: `adhoc / `.
- Paso FSC_Aprobar_o_Rechazar aprobado: `FieldUpdate / FSC_Asignar_ResultadoPEPListas_Aprobada`; FSC_Resultado_PEP_Listas__c = Coincidencia aprobada.
- Paso FSC_Aprobar_o_Rechazar aprobado: `FieldUpdate / FSC_Asignar_Status_En_proceso`; Status = En proceso.
- Paso FSC_Aprobar_o_Rechazar aprobado: `FieldUpdate / FSC_Asignar_Substatus_En_Motor_Buro`; FSC_Subestado__c = En Motor Buró.
- Paso FSC_Aprobar_o_Rechazar rechazado: `FieldUpdate / FSC_Asignar_ResultadoPEPListas_Rechazada`; FSC_Resultado_PEP_Listas__c = Coincidencia no aprobada.
- Paso FSC_Aprobar_o_Rechazar rechazado: `FieldUpdate / FSC_Asignar_Status_Cerrada_Perdida`; Status = Cerrada Perdida.
- Paso FSC_Aprobar_o_Rechazar rechazado: `FieldUpdate / FSC_Asignar_Substatus_Rechazado_por_PLA`; FSC_Subestado__c = Rechazado por PLA.

### FSC_Archivo_y_custodia_de_valores

Activo: `true`. Recall: `true`. Edición: `AdminOnly`.

Lógica de entrada: ``.
- `ResidentialLoanApplication.Status equals En proceso`
- `ResidentialLoanApplication.FSC_Subestado__c equals Archivo y custodia`
- `ResidentialLoanApplication.FSC_Desembolso_Realizado__c equals True`
- `ResidentialLoanApplication.FSC_Doc_Incompleta_Post_Desembolso__c equals False`

Aprobador del paso `FSC_ArchivoYCustodia`: `adhoc / `.
- Paso FSC_ArchivoYCustodia aprobado: `FieldUpdate / FSC_Asignar_Expediente_Archivado_True`; FSC_Expediente_Archivado__c = 1.
- Paso FSC_ArchivoYCustodia aprobado: `FieldUpdate / FSC_Asignar_Status_Cerrada_Ganada`; Status = Cerrada Ganada.
- Paso FSC_ArchivoYCustodia aprobado: `FieldUpdate / FSC_Asignar_Subestado_Completado`; FSC_Subestado__c = Completado.
- Paso FSC_ArchivoYCustodia rechazado: `FieldUpdate / FSC_Asignar_Doc_Inc_Post_Des_True`; FSC_Doc_Incompleta_Post_Desembolso__c = 1.
- Paso FSC_ArchivoYCustodia rechazado: `Task / FSC_Documentos_a_corregir_adjuntar`; .

### FSC_BancaSeguro

Activo: `true`. Recall: `false`. Edición: `AdminOrCurrentApprover`.

Lógica de entrada: `1 AND 2 AND 3`.
- `ResidentialLoanApplication.Status equals En proceso`
- `ResidentialLoanApplication.FSC_Subestado__c equals Banca Seguro`
- `ResidentialLoanApplication.FSC_BancaSeguroAprobada__c equals False`

Aprobador del paso `Revision_Banca_Seguro`: `adhoc / `.
- Aprobación final: `FieldUpdate / FSC_BancaSeguroAprobada`; FSC_BancaSeguroAprobada__c = 1.
- Aprobación final: `FieldUpdate / FSC_BancaSeguroContinuarDocumentacion`; FSC_Subestado__c = Documentación para contratos.
- Rechazo final: `FieldUpdate / FSC_Asignar_Status_Cerrada_Perdida`; Status = Cerrada Perdida.
- Rechazo final: `Alert / FSC_Notificar_Rechazo_Banca_Seguro`; .
- Rechazo final: `FieldUpdate / FSC_SubestadoRechazadoPorBancaSeguro`; FSC_Subestado__c = Rechazado por banca seguro.

### FSC_ComiteDeCredito

Activo: `true`. Recall: `false`. Edición: `AdminOnly`.

Lógica de entrada: `1 AND 2 AND 3 AND 4 AND 5 AND 6`.
- `ResidentialLoanApplication.FSC_Resultado_Buro__c equals Referido`
- `ResidentialLoanApplication.FSC_Subestado__c equals Análisis de crédito`
- `ResidentialLoanApplication.FSC_Doc_Completa_Analisis__c equals True`
- `ResidentialLoanApplication.FSC_DebeRevisarComite__c equals True`
- `ResidentialLoanApplication.FSC_DebeRevisarSupervisor__c equals False`
- `ResidentialLoanApplication.FSC_Aprobado_con_Condiciones__c equals False`

Aprobador del paso `FSC_StepComiteDeCredito`: `adhoc / `.
- Aprobación final: `FieldUpdate / FSC_FechaYHoraAprobacionComite`; FSC_FechaYHoraAprobacionComite__c = NOW().
- Aprobación final: `FieldUpdate / FSC_SolicitudAprobadaPorComite`; FSC_SolicitudAprobadaPorComite__c = 1.
- Aprobación final: `FieldUpdate / FSC_SolicitudCambiaASubestadoPagare`; FSC_Subestado__c = Generación de pagarés y plantillas.
- Rechazo final: `FieldUpdate / FSC_Asignar_Status_Cerrada_Perdida`; Status = Cerrada Perdida.
- Rechazo final: `FieldUpdate / FSC_SubestadoRechazadoPorComite`; FSC_Subestado__c = Rechazado por comité.

### FSC_Excepcion_Buro

Activo: `true`. Recall: `false`. Edición: `AdminOnly`.

Lógica de entrada: ``.
- `ResidentialLoanApplication.FSC_SolicitaExcepcionParaRechazoDeBuro__c equals True`
- `ResidentialLoanApplication.FSC_Subestado__c equals Rechazado por Buró`

Aprobador del paso `Revision`: `queue / FSC_Cola_Excepcion_Buro`.
- Aprobación final: `FieldUpdate / FSC_Asignar_Status_En_proceso`; Status = En proceso.
- Aprobación final: `FieldUpdate / FSC_AsignarSubstatusRecepcion`; FSC_Subestado__c = Recepción de documentos – Análisis.
- Aprobación final: `FieldUpdate / FSC_ExcepcionBuroAprobada`; FSC_ExcepcionBuroAprobada__c = 1.
- Aprobación final: `FieldUpdate / FSC_ResultadoBuroReferido`; FSC_Resultado_Buro__c = Referido.
- Rechazo final: `FieldUpdate / FSC_Asignar_Status_Cerrada_Perdida`; Status = Cerrada Perdida.
- Rechazo final: `FieldUpdate / FSC_ExcepcionBuroRechazada`; FSC_ExcepcionBuroRechazada__c = 1.
- Rechazo final: `FieldUpdate / FSC_SubestadoRechazadoPorAnalistaDeCred`; FSC_Subestado__c = Rechazado por análisis.

### FSC_RecepcionDocsDesembolso

Activo: `true`. Recall: `false`. Edición: `AdminOnly`.

Lógica de entrada: ``.
- `ResidentialLoanApplication.FSC_Subestado__c equals Documentación para desembolso y firmas`
- `ResidentialLoanApplication.FSC_Doc_Completa_Desembolso__c equals True`

Aprobador del paso `FSC_Recepcion_y_Control_de_Documentos`: `adhoc / `.
- Aprobación final: `FieldUpdate / FSC_AsignarSubstatusPlanillaDesembolso`; FSC_Subestado__c = Pendiente planilla de desembolso.
- Rechazo final: `FieldUpdate / FSC_DocumentacionCompletaDesembolsoFalse`; FSC_Doc_Completa_Desembolso__c = 0.

### FSC_RecepcionYControlDeDocs

Activo: `false`. Recall: `false`. Edición: `AdminOnly`.

Lógica de entrada: ``.
- `ResidentialLoanApplication.FSC_Resultado_Buro__c equals Referido`
- `ResidentialLoanApplication.FSC_Subestado__c equals Recepción de documentos – Análisis`
- `ResidentialLoanApplication.FSC_Doc_Completa_Analisis__c equals True`

Aprobador del paso `FSC_StepRecepcionYControlDeDocumentos`: `adhoc / `.
- Aprobación final: `FieldUpdate / FSC_AsignarSubstatusAnalisisDeCredito`; FSC_Subestado__c = Análisis de crédito.
- Rechazo final: `FieldUpdate / FSC_DocumentacionCompletaAnalisisFalse`; FSC_Doc_Completa_Analisis__c = 0.

### FSC_SupervisorDeCredito

Activo: `true`. Recall: `false`. Edición: `AdminOnly`.

Lógica de entrada: `1 AND 2 AND 3 AND 4 AND 5 AND 6`.
- `ResidentialLoanApplication.FSC_Resultado_Buro__c equals Referido`
- `ResidentialLoanApplication.FSC_Subestado__c equals Análisis de crédito`
- `ResidentialLoanApplication.FSC_Doc_Completa_Analisis__c equals True`
- `ResidentialLoanApplication.FSC_DebeRevisarComite__c equals False`
- `ResidentialLoanApplication.FSC_DebeRevisarSupervisor__c equals True`
- `ResidentialLoanApplication.FSC_Aprobado_con_Condiciones__c equals False`

Aprobador del paso `FSC_StepSupervisorDeCredito`: `adhoc / `.
- Aprobación final: `FieldUpdate / FSC_DebeRevisarComite`; FSC_DebeRevisarComite__c = 1.
- Aprobación final: `FieldUpdate / FSC_DebeRevisarSupervisorFalse`; FSC_DebeRevisarSupervisor__c = 0.
- Rechazo final: `FieldUpdate / FSC_Asignar_Status_Cerrada_Perdida`; Status = Cerrada Perdida.
- Rechazo final: `FieldUpdate / FSC_SubestadoRechazadoPorSupervisor`; FSC_Subestado__c = Rechazado por supervisor.

### FSC_ValidacionEnAbanks

Activo: `true`. Recall: `false`. Edición: `AdminOrCurrentApprover`.


```text
AND(
    ISPICKVAL(Status, "En proceso"),
    ISPICKVAL(FSC_Subestado__c, "Creación de crédito"),
    ISPICKVAL(FSC_FormaDeDesembolso__c, "Cuenta de ahorro"),
    NOT(ISBLANK(FSC_NumeroPrestamoAbanks__c))
)
```

Aprobador del paso `FSC_PasoValidacionEnAbanks`: `adhoc / `.
- Aprobación final: `FieldUpdate / FSC_SubestadoDesembolsoValAbanks`; FSC_Subestado__c = Desembolso.

## OmniScripts activos: pasos y controles declarados

Required indica configuración del elemento, su aplicación también depende de show/hide y del contexto. Los componentes LWC embebidos tienen validaciones adicionales.

### FSC_PlanillaDesembolso_Spanish_13.os-meta.xml

- 7.0: `IP_CrearDocumentoDesembolso` (Integration Procedure Action), IP_CrearDocumentoDesembolso.
- 0.0: `IP_ObtenerDatosRLA` (Integration Procedure Action), IP_ObtenerDatosRLA.
- 1.0: `IP_ObtenerDatosUser` (Integration Procedure Action), IP_ObtenerDatosUser.
- 10.0: `NAToRLA` (Navigate Action), NAToRLA.
- 3.0: `PasoSolicitud` (Step), PLANILLA DE DESEMBOLSO DE PRESTAMO.
- 4.0: `SEPeriodoTasa` (Set Errors), SEPeriodoTasa.
- 5.0: `SETasaFijaPorMeses` (Set Errors), SEPeriodoTasa.
- 6.0: `SetErrorsMontoDesembolsar` (Set Errors), SEMontoDesembolsar.
- 8.0: `StepFailure` (Step), Ocurrio un Error.
- 9.0: `StepSuccess` (Step), Resultado Exitoso.
- 2.0: `SVHelper` (Set Values), SVHelper.

| Elemento | Tipo | Etiqueta | Condición de visualización |
| --- | --- | --- | --- |
| CurrencyMontoDesembolsar | Currency | MONTO A DESEMBOLSAR | {"group": {"operator": "AND", "rules": [{"condition": "<>", "data": "TOTAL", "field": "FSC_TipoDesembolsoSolicitado__c"}]}} |
| FSC_clasificacionSib__c | Text | CLASIFICACION SIB | null |
| FSC_CodigoAprobacion__c | Select | CODIGO DE APROBACION | null |
| FSC_ComisionAdminSeguroMonto__c | Currency | COMISION ADMINISTRACION DE SEGURO | null |
| FSC_FormaDesembolso__c | Text Area | FORMA DE DESEMBOLSO | null |
| FSC_FormaPago__c1 | Select | ESQUEMA DE AMORTIZACION | {"group": {"operator": "AND", "rules": [{"data": "FSC_Solicitud_Credito_Hipotecario", "condition": "<>", "field": "IP_ObtenerDatosRLA:RLA\|1:RecordType:DeveloperName"}]}} |
| FSC_FormaPago__c2 | Select | ESQUEMA DE AMORTIZACION | {"group": {"operator": "AND", "rules": [{"data": "FSC_Solicitud_Credito_Hipotecario", "condition": "=", "field": "IP_ObtenerDatosRLA:RLA\|1:RecordType:DeveloperName"}]}} |
| FSC_LineaFinanciera__c | Select | LINEA FINANCIERA | null |
| FSC_Mora__c | Number | MORA | null |
| FSC_PeriodoTasa__c | Number | PERÍODO TASA (MESES) | null |
| FSC_productoBanco__c | Select | PRODUCTO BANCO | null |
| FSC_SubAplicacion__c | Select | SUB - APLICACION | null |
| FSC_TasaFijaPorMeses__c | Number | TASA FIJA POR | null |
| FSC_TipoDesembolsoSolicitado__c | Select | TIPO DE DESEMBOLSO SOLICITADO | null |

### FSC_SolicitudCreditoConsumo_Spanish_12.os-meta.xml

- 8.0: `DatosGeneralesSolicitud` (Step), Datos Generales de la Solicitud.
- 3.0: `DatosSolicitante` (Step), Listado Solicitantes.
- 2.0: `IP_GetAccountDetails` (Integration Procedure Action), IP_GetAccountDetails.
- 0.0: `IP_GetValidationForConsumo` (Integration Procedure Action), IP_GetValidationForConsumo.
- 5.0: `IP_ValidaListasControl` (Integration Procedure Action), IP_ValidaListasControl.
- 7.0: `IPActualizarCrearSolicitudCreditoConsumo1` (Integration Procedure Action), IPActualizarCrearSolicitudCreditoConsumo.
- 9.0: `IPActualizarCrearSolicitudCreditoConsumo2` (Integration Procedure Action), IPActualizarCrearSolicitudCreditoConsumo2.
- 11.0: `NARLAFallido` (Navigate Action), NARLAFallido.
- 12.0: `RAGenerarPDFConsumo` (Remote Action), RAGenerarPDFConsumo.
- 4.0: `SELoanApplicant` (Set Errors), SELoanApplicant.
- 1.0: `StepError1` (Step), Error Validacion.
- 13.0: `StepExitoso` (Step), Registro creado con éxito.
- 10.0: `StepFallido` (Step), Ocurrio un error.
- 6.0: `SVValidacionListas` (Set Values), SVValidacionListas.

| Elemento | Tipo | Etiqueta | Condición de visualización |
| --- | --- | --- | --- |
| FSC_EsConsolidacionDeudas__c | Radio | Es Consolidación de Deudas? | null |
| FSC_EsRefinanciamiento__c | Radio | Es Refinanciamiento? | null |
| FSC_SolicitudMedianteReferidor__c | Radio | Solicitud Mediante Referidor | null |

### FSC_SolicitudCreditoHipotecario_Spanish_5.os-meta.xml

- 8.0: `DatosGeneralesSolicitud` (Step), Datos Generales de la Solicitud.
- 3.0: `DatosSolicitante` (Step), Listado Solicitantes.
- 2.0: `IP_GetAccountDetails` (Integration Procedure Action), IP_GetAccountDetails.
- 0.0: `IP_GetValidationForHipotecario` (Integration Procedure Action), IP_GetValidationForHipotecario.
- 5.0: `IP_ValidaListasControl` (Integration Procedure Action), IP_ValidaListasControl.
- 7.0: `IPActualizarCrearSolicitudCreditoHipotecario1` (Integration Procedure Action), IPActualizarCrearSolicitudCreditoHipotecario1.
- 10.0: `IPActualizarCrearSolicitudCreditoHipotecario2` (Integration Procedure Action), IPActualizarCrearSolicitudCreditoHipotecario2.
- 11.0: `NARLAFallido` (Navigate Action), NARLAFallido.
- 12.0: `RAGenerarPDFConsumo` (Remote Action), RAGenerarPDFConsumo.
- 4.0: `SELoanApplicant` (Set Errors), SELoanApplicant.
- 1.0: `StepError1` (Step), Error Validacion.
- 13.0: `StepExitoso` (Step), Registro creado con éxito.
- 9.0: `StepFallido` (Step), Ocurrio un error.
- 6.0: `SVValidacionListas` (Set Values), SVValidacionListas.

| Elemento | Tipo | Etiqueta | Condición de visualización |
| --- | --- | --- | --- |
| FSC_SolicitudMedianteReferidor__c | Radio | Solicitud Mediante Referidor | null |

### FSC_SolicitudCreditoPYME_Spanish_29.os-meta.xml

- 0.0: `CallwsConsultaProdFinPFPJ_FSC` (Remote Action), Call API Consulta Prod Fin PFPJ.
- 7.0: `DatosSolicitante` (Step), Listado Solicitantes.
- 27.0: `GenerarPDF` (Remote Action), GenerarPDF.
- 13.0: `GetFinServ` (Integration Procedure Action), Get FinServ Financial Service Accounts.
- 3.0: `IP_GetAccountDetails` (Integration Procedure Action), IP_GetAccountDetails.
- 1.0: `IP_GetValidationForPYME` (Integration Procedure Action), IP_GetValidationForPYME.
- 26.0: `IP_ValidaListasControl` (Integration Procedure Action), IP_ValidaListasControl.
- 9.0: `IP_ValidarClasificacionMIPYMES` (Integration Procedure Action), IP_ValidarClasificacionMIPYMES.
- 23.0: `IPActualizarCrearSolicitudCreditoPYME` (Integration Procedure Action), IPActualizarCrearSolicitudCreditoPYME.
- 25.0: `NARLAFallido` (Navigate Action), NARLAFallido.
- 21.0: `SetErrorsActivosYPasivosIguales` (Set Errors), SetErrorsActivosYPasivosIguales.
- 5.0: `StepApplicantDetailsFisica` (Step), Datos del solicitante.
- 6.0: `StepApplicantDetailsJuridica` (Step), Datos del solicitante empresa.
- 8.0: `StepCompanyDetails` (Step), Datos del negocio.
- 14.0: `StepDescripcionFacilidades` (Step), Facilidades de crédito.
- 2.0: `StepError1` (Step), Error Validacion.
- 10.0: `StepError2` (Step), Error Validacion MIPYMES.
- 22.0: `StepEstadoGananciasPerdidas` (Step), Estado de ganancias y pérdidas.
- 19.0: `StepEstadosFinancieros` (Step), Estados financieros.
- 20.0: `StepEstadoSituacion` (Step), Estado de situación.
- 28.0: `StepExitoso` (Step), Registro creado con exito.
- 24.0: `StepFallido` (Step), Ocurrio un error.
- 18.0: `StepFortalezaDebilidades` (Step), Fortalezas y debilidades.
- 17.0: `StepHistoria` (Step), Historia del cliente.
- 11.0: `StepLoanDetails` (Step), Datos del crédito.
- 16.0: `StepReferencias` (Step), Referencias.
- 15.0: `StepRelacion` (Step), Relación de negocios colaterales.
- 12.0: `StepWarrantyDetails` (Step), Datos de la garantía.
- 4.0: `SVSetForm` (Set Values), SVSetForm.

| Elemento | Tipo | Etiqueta | Condición de visualización |
| --- | --- | --- | --- |
| Address | Text | Dirección de residencia | null |
| Email | Text | Correo Electrónico | null |
| IdentificationNumber | Number | No. de Identificación | null |
| IdentificationType | Radio | Tipo de Identificación | null |
| LastName | Text | Apellidos | null |
| MaritalStatus | Select | Estado Civil | null |
| MobilePhone | Number | Celular | null |
| Name | Text | Nombres | null |
| Nationality | Select | Nacionalidad | null |
| Phone | Number | Teléfono Res. | null |
| Sex | Radio | Sexo | null |
| CompanyName | Text | Razón Social | null |
| FantasyName | Text | Nombre comercial | null |
| RNC | Number | RNC | null |
| FSC_Ingresos_Mensuales__c | Currency | Ingresos Mensuales | null |
| RadioOtrosIngresos | Radio | Otros Ingresos | null |
| FSC_A_os_de_operacion__c | Number | Años de operación / tiempo laborando | null |
| FSC_Actividad_economica__c | Text | Actividad Económica | null |
| FSC_Cantidad_de_empleados__c | Number | Cantidad de empleados | null |
| FSC_Cargo__c | Text | Cargo | null |
| FSC_Correo_Electronico__c | Text | Correo Electrónico | null |
| FSC_Direccion_del_Negocio__c | Text | Dirección del Negocio | null |
| FSC_Emplea_familiares__c | Radio | Emplea familiares | null |
| FSC_IndicadorFormalizacion__c | Select | Indicador de formalizacion | null |
| FSC_Local_del_negocio__c | Radio | Local del negocio | null |
| FSC_Nombre_del_negocio__c | Text | Nombre del negocio | null |
| FSC_Se_encuentra_en_la_misma_residencia__c | Radio | ¿Se encuentra en el mismo inmueble de residencia? | null |
| FSC_Se_encuentra_en_zona_comercial__c | Radio | ¿Se encuentra en una zona comercial? | null |
| FSC_Situacion_Legal__c | Select | Situación Legal | null |
| FSC_Telefono__c | Number | Teléfono | null |
| FSC_Tiempo_del_negocio__c | Text | Tiempo del negocio | null |
| FSC_Tiempo_en_el_local_actual__c | Text | Tiempo en el local actual | null |
| FSC_VentasBrutasAnuales__c | Currency | Ventas brutas anuales | null |
| FSC_Aumento_Solicitado__c | Currency | Aumento Solicitado | null |
| FSC_Compromiso_Mensual__c | Currency | Compromiso Mensual | null |
| FSC_Deuda_Actual__c | Currency | Deuda Actual | null |
| FSC_Facilidades_De_Credito__c_FSC_Moneda__c | Select | Moneda | null |
| FSC_Facilidades_De_Credito__c_FSC_Plazo_meses__c | Number | Plazo (meses) | null |
| FSC_Fecha_Apertura__c | Date | Fecha Apertura | null |
| FSC_Limite_Autorizado__c | Currency | Límite Autorizado | null |
| FSC_Numero__c | Number | No. | null |
| FSC_Posible_Compromiso__c | Currency | Posible Compromiso | null |
| FSC_Tasa__c | Number | Tasa | null |
| FSC_Tipo_de_Facilidad__c | Select | Tipo de Facilidad | null |
| FSC_Proposito__c | Text | Propósito | null |
| FSC_Proposito_Y_Uso_De_Fondos__c_FSC_Numero_Facilidades__c | Number | No. Facilidades | null |
| CashOrMarketValue | Currency | Valor | {"group": {"operator": "AND", "rules": [{"data": "Sin Garantía", "condition": "<>", "field": "StepWarrantyDetails:FSC_Tipo_de_Garantia__c"}, {"field": "StepWarrantyDetails:FSC_Tipo_de_Garantia__c", "condition": "<>", "data": null}]}} |
| FSC_Descripcion_de_la_Garantia__c | Select | Descripción de la Garantía | {"group": {"operator": "AND", "rules": [{"data": "Sin Garantía", "condition": "<>", "field": "StepWarrantyDetails:FSC_Tipo_de_Garantia__c"}, {"field": "StepWarrantyDetails:FSC_Tipo_de_Garantia__c", "condition": "<>", "data": null}]}} |
| FSC_Numero_Facilidades__c | Number | No. Facilidades | {"group": {"operator": "AND", "rules": [{"data": "Sin Garantía", "condition": "<>", "field": "StepWarrantyDetails:FSC_Tipo_de_Garantia__c"}, {"field": "StepWarrantyDetails:FSC_Tipo_de_Garantia__c", "condition": "<>", "data": null}]}} |
| FSC_Porcentaje_Admisibilidad__c | Number | % Admisibilidad | {"group": {"operator": "AND", "rules": [{"data": "Sin Garantía", "condition": "<>", "field": "StepWarrantyDetails:FSC_Tipo_de_Garantia__c"}, {"field": "StepWarrantyDetails:FSC_Tipo_de_Garantia__c", "condition": "<>", "data": null}]}} |
| FSC_Alquiler_Generales__c | Currency | Alquiler | null |
| FSC_Combustible__c | Currency | Combustible | null |
| FSC_Nomina__c | Currency | Nómina | null |
| FSC_Reparaciones__c | Currency | Reparaciones | null |
| FSC_Seguros_Generales__c | Currency | Seguros | null |
| FSC_Servicios_basicos_Generales__c | Currency | Servicios básicos+ | null |
| FSC_Cuotas__c | Currency | Cuotas | null |
| FSC_Alimentos__c | Currency | Alimentos | null |
| FSC_Alquiler_Personales__c | Currency | Alquiler | null |
| FSC_Educacion__c | Currency | Educación | null |
| FSC_Seguros_Personales__c | Currency | Seguros | null |
| FSC_Servicios_basicos_Personales | Currency | Servicios básicos | null |
| FSC_Transporte__c | Currency | Transporte | null |
| FSC_DesdeAnoGananciasyPerdidas__c | Number |  | null |
| FSC_DesdeMesGananciasyPerdidas__c | Number |  | null |
| FSC_HastaAnoGananciasyPerdidas__c | Number |  | null |
| FSC_HastaMesGananciasyPerdidas__c | Number |  | null |
| FSC_CostoMercanciaVendida__c | Currency | Costo mercancía vendida (negocio) | null |
| FSC_VentasSalario__c | Currency | Ventas, Salario + | null |
| FSC_Cuentas_por_cobrar_clientes__c | Currency | Cuentas por cobrar clientes | null |
| FSC_Edificaciones__c | Currency | Edificaciones | null |
| FSC_Efectivo_en_caja_y_bancos__c | Currency | Efectivo en caja y bancos | null |
| FSC_Inventario__c | Currency | Inventario | null |
| FSC_Maquinarias_y_equipos__c | Currency | Maquinarias y equipos | null |
| FSC_Muebles_y_enseres__c | Currency | Muebles y enseres | null |
| FSC_Terrenos__c | Currency | Terrenos | null |
| FSC_Vehiculos__c | Currency | Vehículos | null |
| FSC_Capital__c | Currency | Capital | null |
| FSC_Cuentas_por_pagar_suplidores__c | Currency | Cuentas por pagar suplidores | null |
| FSC_Docs_Por_pagar_Corto_Plazo__c | Currency | Docs. Por pagar Corto Plazo | null |
| FSC_Otras_cuentas_por_pagar__c | Currency | Otras cuentas por pagar | null |
| FSC_Otras_deudas_corto_plazo__c | Currency | Otras deudas corto plazo | null |
| FSC_AnoEstadoSituacion__c | Number |  | null |
| FSC_DiaEstadoSituacion__c | Number |  | null |
| FSC_MesEstadoSituacion__c | Text |  | null |
| FSC_Historial_del_cliente__c | Text Area | Historial del cliente | null |
| FSC_AporteCapitalSinPenalidad__c | Select | Aportes a capital sin penalidad | null |
| FSC_Clasificacion_de_Riesgo__c | Select | Clasificación de Riesgo | null |
| FSC_Condiciones_de_la_Facilidad__c | Text | Condiciones de la Facilidad | null |
| FSC_Descripcion_del_Negocio__c | Text | Descripción del Negocio | null |
| FSC_Destino_del_Prestamo__c | Text | Destino del Préstamo | null |
| FSC_DestinoTaxonomiaVerde__c | Select | Destino del Crédito Taxonomía Verde | null |
| FSC_FormaDeDesembolso__c | Select | Forma de desembolso | null |
| FSC_Grupo_de_Empresa__c | Text | Grupo de Empresa / Grupo Económico | null |
| FSC_Moneda__c | Select | Moneda | null |
| FSC_Monto__c | Currency | Monto | null |
| FSC_Plazo_meses__c | Select | Plazo (meses) | null |
| FSC_TasaInteres__c | Number | Tasa de interés | null |
| FSC_Tipo_de_solicitud__c | Radio | Tipo de solicitud | null |
| FSC_Tipo_de_solicitud_Otro__c | Text |  | {"group": {"operator": "AND", "rules": [{"data": "Otro, Especifique", "condition": "=", "field": "FSC_Tipo_de_solicitud__c"}]}} |
| FSC_Tipo_de_Garantia__c | Radio | Tipo de Garantía | null |

### FSC_SolicitudCreditoVehiculo_Spanish_5.os-meta.xml

- 8.0: `DatosGeneralesSolicitud` (Step), Datos Generales de la Solicitud.
- 3.0: `DatosSolicitante` (Step), Listado Solicitantes.
- 2.0: `IP_GetAccountDetails` (Integration Procedure Action), IP_GetAccountDetails.
- 0.0: `IP_GetValidationForVehiculo` (Integration Procedure Action), IP_GetValidationForVehiculo.
- 5.0: `IP_ValidaListasControl` (Integration Procedure Action), IP_ValidaListasControl.
- 7.0: `IPActualizarCrearSolicitudCreditoVehiculo1` (Integration Procedure Action), IPActualizarCrearSolicitudCreditoVehiculo1.
- 9.0: `IPActualizarCrearSolicitudCreditoVehiculo2` (Integration Procedure Action), IPActualizarCrearSolicitudCreditoVehiculo2.
- 11.0: `NARLAFallido` (Navigate Action), NARLAFallido.
- 12.0: `RAGenerarPDFConsumo` (Remote Action), RAGenerarPDFConsumo.
- 4.0: `SELoanApplicant` (Set Errors), SELoanApplicant.
- 1.0: `StepError1` (Step), Error Validacion.
- 13.0: `StepExitoso` (Step), Registro creado con éxito.
- 10.0: `StepFallido` (Step), Ocurrio un error.
- 6.0: `SVValidacionListas` (Set Values), SVValidacionListas.

| Elemento | Tipo | Etiqueta | Condición de visualización |
| --- | --- | --- | --- |
| FSC_SolicitudMedianteReferidor__c | Radio | Solicitud Mediante Referidor | null |

## Catálogo documental vigente

Datos de FSC_ChecklistDocumentos__c. La categoría se selecciona por tipo de solicitud; Consumo tiene variantes por garantía. Precarga es una clave técnica, no una confirmación de que el archivo ya existe en un RLA concreto.

### Solicitud de crédito consumo a sola firma

| Categoría | Nº | Documento | Precarga |
| --- | --- | --- | --- |
| Documentos para análisis | 1 | Planilla de Solicitud de tramitación de préstamos de consumo debidamente completada por el(los) solicitante(s). |  |
| Documentos para análisis | 2 | Formulario de capacidad de pago debidamente completado. |  |
| Documentos para análisis | 3 | Formulario Conozca su Cliente debidamente completado y firmado por el(los) solicitante(s). |  |
| Documentos para análisis | 4 | Buró de Crédito (Equifax) de el(los) solicitante(s) con una antiguedad no mayor a 45 dias. |  |
| Documentos para análisis | 5 | Consulta de la Central de Riesgo de la SIB y el balance consolidado de el(los) solicitante(s). |  |
| Documentos para análisis | 6 | Certificación de Ingresos, Evidencia de otros ingresos y/o documentacion que sustente las fuentes de ingresos que posea el(los) solicitante(s). |  |
| Documentos para análisis | 7 | Estados de cuenta de Ahorros o Corrientes con otros bancos de el(los) solicitante(s). Nota: Para los asalariados los últimos tres (3) meses, asalariados con otros ingresos los últimos seis (6) meses, y los independientes los últimos seis (6) meses. |  |
| Documentos para análisis | 8 | Estado financiero personal de el(los) solicitante(s) debidamente completado y firmado. |  |
| Documentos para análisis | 9 | Copia de ambos lados del documento de Identidad de el(los) solicitante(s). |  |
| Documentos para análisis | 10 | Planilla de Cotización de Seguro de Vida, con la elección de el(los) solicitante(s). |  |
| Documentos para análisis | 11 | Hoja de Confirmación en las Listas por Prevención de Lavado de Activos (PLA) de el(los) solicitante(s). |  |
| Documentos para desembolso | 12 | Pagaré Individual debidamente completado y firmado por el(los) solicitante(s). |  |
| Documentos para desembolso | 13 | Carta de autorización de débito a cuenta y cobros de los gastos de cierre debidamente firmada por el(los) solicitante(s). |  |
| Documentos para desembolso | 14 | Formulario de seguro de vida debidamente completado y firmado por el(los) solicitante(s). |  |

### Solicitud de crédito consumo con garantía de CD

| Categoría | Nº | Documento | Precarga |
| --- | --- | --- | --- |
| Documentos para análisis | 1 | Planilla de Solicitud de tramitación de préstamos de consumo debidamente completada y firmada por el(los) solicitante(s). |  |
| Documentos para análisis | 2 | Formulario Conozca su cliente debidamente firmado por el(los) solicitante(s). |  |
| Documentos para análisis | 3 | Buró de Crédito de el(los) solicitante(s). |  |
| Documentos para análisis | 4 | Consulta de la Central de Riesgo de la SIBy el balance consolidado de el(los) solicitante(s). |  |
| Documentos para análisis | 5 | Copia de ambos lados del documento de Identidad de el (los) solicitante(s). |  |
| Documentos para análisis | 6 | Copia del Certificado de Deposito o de Inversión. En caso de que el certificado de inversión sea del Banco Central solicitar confirmación de no oposición en el Banco Central. |  |
| Documentos para análisis | 7 | Hoja de Confirmación en las Listas por Prevención de Lavado de Activos (PLA) de el(los) solicitante(s). |  |
| Documentos para desembolso | 8 | Pagaré Comercial Complementario debidamente compeltado y firmado por el(los) solicitante(s). |  |
| Documentos para desembolso | 9 | Carta de autorización de débito a cuenta y cobros de gastos de cierre debidamente completada y firmada por el(los) solicitante(s). |  |
| Documentos para desembolso | 10 | Original del Certificado de Deposito o de Inversión, debidamente firmado y endosado con firma y cédula de el(los) solicitante(s). |  |
| Documentos para desembolso | 11 | Contrato de pignoración debidamente validada por el Dpto. De Formalizacion y firmada por el(los) solicitante(s). |  |

### Solicitud de crédito consumo con garantía de vehículo

| Categoría | Nº | Documento | Precarga |
| --- | --- | --- | --- |
| Documentos para análisis | 1 | Planilla de Solicitud de tramitación de préstamos de consumo debidamente completada por el(los) solicitante(s). |  |
| Documentos para análisis | 2 | Formulario Conozca su Cliente debidamente completado y firmado por el(los) solicitante(s). |  |
| Documentos para análisis | 3 | Buró de Crédito de el(los) solicitante(s). |  |
| Documentos para análisis | 4 | Consulta de la Central de Riesgo de la SIB y el balance consolidado de el(los) solicitante(s). |  |
| Documentos para análisis | 5 | Certificación de Ingresos, Evidencia de otros ingresos y/o documentacion que sustente las fuentes de ingresos que posea el(los) solicitante(s). |  |
| Documentos para análisis | 6 | Los últimos tres (3) meses de estados de cuenta de Ahorros o Corrientes con otros bancos de el(los) solicitante(s). |  |
| Documentos para análisis | 7 | Estado financiero personal de el(los) solicitante(s) debidamente completado y firmado. |  |
| Documentos para análisis | 8 | Copia de ambos lados del documento de Identidad de el(los) solicitante(s). |  |
| Documentos para análisis | 9 | * Para vehículos nuevos, cotización formal emitida por el Dealer, concesionario o importador con la descripción del chasis. * Para Vehículos usados, tasación por un tasador autorizado por el Banco, para vehículos con vigencia de seis (06) meses y maquinarias de un (01) año. |  |
| Documentos para análisis | 10 | Copia de la matrícula del vehículo en caso de que sea usado. |  |
| Documentos para análisis | 11 | Hoja de Confirmación en las Listas por Prevención de Lavado de Activos (PLA) de el(los) solicitante(s). |  |
| Documentos para confección de contrato | 12 | Planilla de Cotización de Seguro, con la elección del cliente y/o endoso de seguro debidamente validado por la unidad correspondiente, con sus condiciones particulares. |  |
| Documentos para desembolso | 13 | Pagaré Comercial Complementario. |  |
| Documentos para desembolso | 14 | Contratos firmados. |  |
| Documentos para desembolso | 15 | Carta de autorización de débito a cuenta y cobros de gastos de cierre. En caso de pagar los gastos de cierre por Caja o Débito a Cuenta, enviar evidencia del pago. |  |
| Documentos para desembolso | 16 | Formulario de seguro de vehículo, con su debida aprobación. |  |
| Documentos para desembolso | 17 | Matrícula Original del vehículo, transferida a nombre del cliente, en caso de ser usados o BL. |  |

### Solicitud de crédito consumo con garantía hipotecaria

| Categoría | Nº | Documento | Precarga |
| --- | --- | --- | --- |
| Documentos para análisis | 1 | Solicitud digital para la tramitación de crédito consumo con garantía, debidamente completada y firmada. |  |
| Documentos para análisis | 2 | Formulario Conozca su Cliente firmado si aplica. |  |
| Documentos para análisis | 3 | * Buró de Crédito. * Consulta de la Central de Riesgo de la SIB, con visualización de la clasificación de los préstamos vigentes y castigados , con detalle de los préstamos actuales y el balance consolidado de la deuda que posee con las demás instituciones financieras. |  |
| Documentos para análisis | 4 | Certificación de ingresos de los solicitantes y evidencia de otros ingresos. |  |
| Documentos para análisis | 5 | Estados financieros de los solicitantes, debidamente firmados con las notas aclaratorias. |  |
| Documentos para análisis | 6 | Los últimos tres (3) meses de estados de cuenta de Ahorros o Corrientes con otros bancos firmados y sellados. |  |
| Documentos para análisis | 7 | Copia de ambos lados del documento de Identidad de el (los) solicitante(s). |  |
| Documentos para análisis | 8 | Para los préstamos con garantía hipotecaria (una segunda hipoteca adicional al préstamo hipotecario para adquisición de vivienda), cuyos fondos estarían siendo utilizados para remodelación, ampliación, reconstrucción o terminación de bienes inmuebles residenciales, el cliente deberá presentar al Banco conjuntamente con los demás documentos requeridos, un Presupuesto de Mano de Obra y Materiales, debidamente certificado por un profesional del área de ingeniería, el cual deberá estar acorde con el monto solicitado para los fines correspondientes. |  |
| Documentos para análisis | 9 | Evidencia de los recibos del pago de inicial |  |
| Documentos para análisis | 10 | Copia del Certificado de Título de Propiedad. |  |
| Documentos para análisis | 11 | Tasación Original del Inmueble por un tasador autorizado por el Banco, con vigencia de dos años. |  |
| Documentos para análisis | 12 | Hoja de Confirmación en las Listas por Prevención de Lavado de Activos. |  |
| Documentos para confección de contrato | 13 | Poder de representación. En caso de ser confeccionado en el extranjero debe estar debidamente apostillado. Copia del documento de identidad del apoderado. |  |
| Documentos para confección de contrato | 14 | Copia de la certificación de deuda de otro banco. Debe de indicar la descripción del inmueble en garantía, e indicar si los títulos reposan en la custodia de dicho Banco y que serán entregados al saldo del préstamo. |  |
| Documentos para confección de contrato | 15 | Copia de la certificación de Estado Jurídico del Inmueble (cargas y gravámenes), con antigüedad no mayor de 30 días. |  |
| Documentos para confección de contrato | 16 | Copia de la certificación de Impuesto a la Propiedad Inmobiliaria (IPI) al día, (vence a los 120 días). |  |
| Documentos para confección de contrato | 17 | Planilla de Cotización de Seguro de vida e incendio, con la elección del cliente. |  |
| Documentos para confección de contrato | 18 | Copia del acta de matrimonio en caso de que el titular del inmueble sea casado. |  |
| Documentos para desembolso | 19 | Pagaré Comercial Complementario. |  |
| Documentos para desembolso | 20 | Contratos firmados. |  |
| Documentos para desembolso | 21 | Carta de autorización de débito a cuenta y cobros de gastos de cierre. |  |
| Documentos para desembolso | 22 | Certificado de Título (duplicado del dueño) en original. |  |
| Documentos para desembolso | 23 | Certificación de Registro de Acreedor en original, si aplica. |  |
| Documentos para desembolso | 24 | Certificación de Estado Jurídico del Inmueble (cargas y gravámenes), con antigüedad no mayor de 30 días, en original. |  |
| Documentos para desembolso | 25 | Certificación de Impuesto a la Propiedad Inmobiliaria (IPI) al día, (vence a los 120 días), en original. |  |
| Documentos para desembolso | 26 | Acto de Cancelación de Hipoteca en original, si aplica. |  |
| Documentos para desembolso | 27 | Formulario de seguro de vida e incendio debidamente validado por la unidad correspondiente. |  |
| Documentos para desembolso | 28 | Certificación de deuda de otro banco. Debe de indicar la descripción del inmueble en garantía, e indicar si los títulos reposan en custodia de dicho Banco y que serán entregados al saldo del préstamo. En original si aplica. |  |

### Solicitud de crédito consumo con garantía solidaria

| Categoría | Nº | Documento | Precarga |
| --- | --- | --- | --- |
| Documentos para análisis | 1 | Planilla de Solicitud de tramitación de préstamos de consumo debidamente completada y firmada por el(los) solicitante(s) y de el(los) Garante(s) Solidario(s). |  |
| Documentos para análisis | 2 | Formulario Conozca su Cliente debidamente completado y firmado por el(los) solicitante(s) y de el(los) Garante(s) Solidario(s). . |  |
| Documentos para análisis | 3 | Buró de Crédito de el(los) solicitante(s) y el(los) garante(s) solidario(s). |  |
| Documentos para análisis | 4 | Consulta de la Central de Riesgo de la SIB y el balance consolidado de el(los) solicitante(s) y el(los) garante(s) solidario(s). |  |
| Documentos para análisis | 5 | Certificación de Ingresos, Evidencia de otros ingresos y/o documentación equivalente que sustente las fuentes de ingreso de el(los) solicitante(s) y de el(los) Garante(s) Solidario(s). |  |
| Documentos para análisis | 6 | Los últimos tres (3) meses de estados de cuenta de Ahorros o Corrientes con otros bancos de el(los) solicitante(s) y de el(los) Garante(s) Solidario(s). |  |
| Documentos para análisis | 7 | Estados financieros de los solicitantes debidamente completado y firmado con notas aclaratorias de el(los) solicitante(s) y de el(los) Garante(s) Solidario(s). |  |
| Documentos para análisis | 8 | Copia de ambos lados del documento de Identidad el(los) solicitante(s) y de el(los) Garante(s) Solidario(s). |  |
| Documentos para análisis | 9 | Planilla de Cotización de Seguro con la elección de el(los) solicitante(s). |  |
| Documentos para análisis | 10 | Hoja de Confirmación en las Listas por Prevención de Lavado de Activos (PLA) de el(los) solicitante(s) y de el(los) Garante(s) Solidario(s). |  |
| Documentos para desembolso | 11 | Pagaré Comercial Individual debidamente completado y firmado por el(los) solicitante(s) y de el(los) Garante(s) Solidario(s). |  |
| Documentos para desembolso | 12 | Carta de autorización de débito a cuenta y cobros de gastos de cierre debidamente completada y firmada por el(los) solicitante(s). |  |
| Documentos para desembolso | 13 | Formulario de seguro de vida debidamente completado y firmado por el(los) solicitante(s). |  |

### Solicitud de crédito hipotecario

| Categoría | Nº | Documento | Precarga |
| --- | --- | --- | --- |
| Documentos para análisis | 1 | Planilla de solicitud de tramitación de préstamos debidamente completada y firmada. |  |
| Documentos para análisis | 2 | Formulario Conozca su Cliente firmado si aplica. |  |
| Documentos para análisis | 3 | * Buró de Crédito. * Consulta de la Central de Riesgo de la SIB, con visualización de la clasificación de los préstamos vigentes y castigados , con detalle de los préstamos actuales y el balance consolidado de la deuda que posee con las demás instituciones financieras. |  |
| Documentos para análisis | 4 | Income Tax de los últimos dos años para los deudores en caso de ser extranjero. |  |
| Documentos para análisis | 5 | Certificación de Ingresos o documentación equivalente que sustente las fuentes de ingreso que posee el (los) solicitante(s). Evidencia de otros ingresos. |  |
| Documentos para análisis | 6 | Estados financieros de los solicitantes debidamente firmados con notas aclaratorias. |  |
| Documentos para análisis | 7 | Los últimos seis (6) meses de estados de cuenta de Ahorros o Corrientes con otros bancos firmados y sellados. |  |
| Documentos para análisis | 8 | Copia de ambos lados del documento de Identidad de el (los) solicitante(s). |  |
| Documentos para análisis | 9 | Copia del Certificado de Título de Propiedad. |  |
| Documentos para análisis | 10 | Tasación Original del Inmueble por un tasador autorizado por el Banco con vigencia de dos año. |  |
| Documentos para análisis | 11 | Copia del Contrato Opción a Compra, venta y comprobantes pago de Inicial. |  |
| Documentos para análisis | 12 | Hoja de Confirmación en las Listas por Prevención de Lavado de Activos. |  |
| Documentos para análisis | 13 | Otros documentos |  |
| Documentos para confección de contrato | 14 | Planilla de Cotización de Seguro de vide e incendio, con la eleccion del cliente. |  |
| Documentos para confección de contrato | 15 | Poder de representación. En caso de ser confeccionado en el extranjero debe estar debidamente apostillado. Copia del documento de identidad del apoderado. |  |
| Documentos para confección de contrato | 16 | Copia de la certificación de Estado Jurídico del Inmueble (cargas y gravámenes), con antigüedad no mayor de 30 días. |  |
| Documentos para confección de contrato | 17 | Certificación de Impuesto a la Propiedad Inmobiliaria (IPI) al día, (vence a los 120 días). |  |
| Documentos para confección de contrato | 18 | Certificacion de vivienda de bajo costo emitida por el INVI, en caso de que aplique. |  |
| Documentos para confección de contrato | 19 | Copia del acta de matrimonio en caso de que el titular del inmueble sea casado. |  |
| Documentos para confección de contrato | 20 | Copia del Registro Mercantil vigente. |  |
| Documentos para confección de contrato | 21 | Copia de la Certificacion Virtual de RNC o en su defecto Acta de inscripción en el RNC, emitida por la DGII. |  |
| Documentos para confección de contrato | 22 | Copia del Acta de Asamblea que designe las personas autorizadas a firmar contratos, vender o dar en garantía el inmueble, segun corresponda, registrada en Cámara de Comercio y Producción correspondiente. |  |
| Documentos para confección de contrato | 23 | Copia de ambos lados del documento de identidad de los firmantes. |  |
| Documentos para confección de contrato | 24 | Certificación de confotur |  |
| Documentos para desembolso | 25 | Pagaré Comercial Complementario. |  |
| Documentos para desembolso | 26 | Contratos firmados. |  |
| Documentos para desembolso | 27 | Carta de autorización de débito a cuenta y cobros de gastos de cierre. |  |
| Documentos para desembolso | 28 | Certificación de Estado Jurídico del Inmueble (cargas y gravámenes), con antigüedad no mayor de 30 días. |  |
| Documentos para desembolso | 29 | Certificado de Título (duplicado del dueño) en original. |  |
| Documentos para desembolso | 30 | Certificación de Impuesto a la Propiedad Inmobiliaria (IPI) al día, (vence a los 120 días), en original |  |
| Documentos para desembolso | 31 | Certificacion de vivienda de bajo costo emitida por el INVI, en caso de que aplique. En original |  |
| Documentos para desembolso | 32 | Certificacion de Registro de Acreedor en original, si aplica. |  |
| Documentos para desembolso | 33 | Acto de Cancelación de Hipoteca en original, si aplica. |  |
| Documentos para desembolso | 34 | Formulario de seguro de vida e incendio debidamente validado por la unidad correspondiente. |  |
| Documentos para desembolso | 35 | Original o copia certificada del Acta de Asamblea que designe las personas autorizadas a firmar contratos, vender o dar en garantía el inmueble, segun corresponda, registrada en Cámara de Comercio y Producción correspondiente. |  |
| Documentos para desembolso | 36 | Certificación de deuda de otro banco. Debe de indicar la descripción del inmueble en garantía, e indicar si los títulos reposan en custodia de dicho Banco y que serán entregados al saldo del préstamo. En original, si aplica. |  |

### Solicitud de crédito pyme

| Categoría | Nº | Documento | Precarga |
| --- | --- | --- | --- |
| Documentos para análisis | 1 | Copia de ambos lados del documento de identidad del solicitante. |  |
| Documentos para análisis | 2 | Solicitud de la facilidad deseada debidamente firmada, indicando el propósito y destino de los fondos. |  |
| Documentos para análisis | 3 | Formulario Conozca su Cliente debidamente completado y firmado por el(los) solictante(s). |  |
| Documentos para análisis | 4 | Buró de Crédito del(los) solictante(s). |  |
| Documentos para análisis | 5 | Consulta de la Central de Riesgo de la SB, que indique tanto la Consulta Crediticia que incluye la Clasificación de Riesgo, como los balances consolidados de las deudas vigentes que posee con las demás instituciones financieras. |  |
| Documentos para análisis | 6 | Documentación legal correspondiente a la garantía ofrecida. |  |
| Documentos para análisis | 7 | Tasación realizada con fecha reciente (como máximo de 180 días) por un tasador autorizado del Banco, cumpliendo con la normativa dictada por las autoridades reguladoras del Sistema Financiero, en los casos de créditos comerciales con garantía real de bienes inmuebles, en los casos de bienes muebles (como máximo de 90 días), si aplica. |  |
| Documentos para análisis | 8 | Reporte de Visita a la garantía ofrecida, en los casos en que lo amerite. |  |
| Documentos para análisis | 9 | Estados de cuentas bancarias por lo menos a los últimos tres meses. |  |
| Documentos para análisis | 10 | Reporte de Visita a las instalaciones, en los casos en que las áreas de Negocios lo consideren necesario. |  |
| Documentos para análisis | 11 | Hoja de Confirmación en las Listas por Prevención de Lavado de Activos (PLA) del(los) solictante(s). |  |
| Documentos para análisis | 12 | Formulario de cotización del seguro de vida y del seguro de propiedad, en los casos que lo amerite. |  |
| Documentos para análisis | 13 | Estados financieros preferiblemente de los últimos dos (02) períodos fiscales del cliente: |  |
| Documentos para análisis | 14 | Para solicitantes con deudas consolidadas en el sistema Financieros hasta RD$5,000,000.00, estados financieros firmados y/o sellados por el cliente, incluyendo Estado directos, correspondientes a tres (03) periodos y corte reciente de los estados, en caso de transcurridos 6 meses después de la fecha de corte de los EF, se solicita Estados Financieros Interinos. |  |
| Documentos para análisis | 15 | Para solicitantes con deudas consolidadas en el sistema Financieros desde RD$5,000,001 hasta RD$9,999,999, estados financieros firmados, incluyendo Estado de Flujo de Caja, Balance General, Estado de Resultado, Estado de Cambio Patrimonial, Sellados por un Contador Público Autorizado (C.P.A.) y corte reciente de los estados, en caso de transcurridos 6 meses después de la fecha de corte de los EF, se solicita Estados Financieros Interinos. |  |
| Documentos para confección de contrato | 16 | Formulario de cotización del seguro de vida y del seguro de propiedad, con la elección del solicitante, en los casos que lo amerite. |  |
| Documentos para desembolso | 17 | Pagaré Comercial debidamente completado y firmado por el(los) solictante(s). |  |
| Documentos para desembolso | 18 | Contratos debidamente firmados por el(los) solictante(s). |  |
| Documentos para desembolso | 19 | Carta de autorización de débito a cuenta y cobros de gastos de cierre debidamente firmada por el(los) solictante(s). |  |
| Documentos para desembolso | 20 | Aprobacion del seguro de vida y del seguro de propiedad, debidamente validado por Banca Seguros. |  |

### Solicitud de crédito vehicular

| Categoría | Nº | Documento | Precarga |
| --- | --- | --- | --- |
| Documentos para análisis | 1 | Planilla de Solicitud de tramitación de préstamos de consumo debidamente completada por el(los) solicitante(s). |  |
| Documentos para análisis | 2 | Formulario Conozca su Cliente debidamente completado y firmado por el(los) solicitante(s). |  |
| Documentos para análisis | 3 | Buró de Crédito de el(los) solicitante(s). |  |
| Documentos para análisis | 4 | Consulta de la Central de Riesgo de la SIB y el balance consolidado de el(los) solicitante(s). |  |
| Documentos para análisis | 5 | Certificación de Ingresos, Evidencia de otros ingresos y/o documentacion que sustente las fuentes de ingresos que posea el(los) solicitante(s). |  |
| Documentos para análisis | 6 | Los últimos tres (3) meses de estados de cuenta de Ahorros o Corrientes con otros bancos de el(los) solicitante(s). |  |
| Documentos para análisis | 7 | Estado financiero personal de el(los) solicitante(s) debidamente completado y firmado. |  |
| Documentos para análisis | 8 | Copia de ambos lados del documento de Identidad de el(los) solicitante(s). |  |
| Documentos para análisis | 9 | * Para vehículos nuevos, cotización formal emitida por el Dealer, concesionario o importador con la descripción del chasis. * Para Vehículos usados, tasación por un tasador autorizado por el Banco, para vehículos con vigencia de seis (06) meses y maquinarias de un (01) año. |  |
| Documentos para análisis | 10 | Copia de la matrícula del vehículo en caso de que sea usado. |  |
| Documentos para análisis | 11 | Hoja de Confirmación en las Listas por Prevención de Lavado de Activos (PLA) de el(los) solicitante(s). |  |
| Documentos para confección de contrato | 12 | Planilla de Cotización de Seguro, con la elección del cliente y/o endoso de seguro debidamente validado por la unidad correspondiente, con sus condiciones particulares. |  |
| Documentos para desembolso | 13 | Pagaré Comercial Complementario. |  |
| Documentos para desembolso | 14 | Contratos firmados. |  |
| Documentos para desembolso | 15 | Carta de autorización de débito a cuenta y cobros de gastos de cierre. En caso de pagar los gastos de cierre por Caja o Débito a Cuenta, enviar evidencia del pago. |  |
| Documentos para desembolso | 16 | Formulario de seguro de vehículo, con su debida aprobación. |  |
| Documentos para desembolso | 17 | Matrícula Original del vehículo, transferida a nombre del cliente, en caso de ser usados o BL. |  |

## Condiciones de acciones en fsc_RlaAcciones

Extractos de getters del LWC desplegado. Son las condiciones de presentación; el servidor puede aplicar controles adicionales.

### showSpinner

```javascript
get showSpinner() {
		return this.loading || this.validandoClasificacionMIPYMES;
	}
```

### showEnviarDocumentacionContratos

```javascript
get showEnviarDocumentacionContratos() {
		return this.status === 'En proceso' && this.substatus === 'Documentación para contratos' && this.documentacionContratos.puedeCargar === true;
	}
```

### showSolicitarDocumentacionContratos

```javascript
get showSolicitarDocumentacionContratos() {
		return this.canGeneratePagareStep && this.canCurrentUserGeneratePagare;
	}
```

### showRevisionDocumentacionContratos

```javascript
get showRevisionDocumentacionContratos() {
		return this.showSolicitarDocumentacionContratos && this.documentacionContratos.documentosAprobados !== true;
	}
```

### showPedidoDocumentacionContratos

```javascript
get showPedidoDocumentacionContratos() {
		return !!this.pedidoDocumentacionContratos && this.substatus === 'Documentación para contratos';
	}
```

### showErrorDocumentacionContratos

```javascript
get showErrorDocumentacionContratos() {
		return (
			!!this.wiredDocumentacionContratosResult?.error &&
			(this.substatus === 'Documentación para contratos' || this.isSubstatusGeneracionPagares)
		);
	}
```

### showCuentaDesembolsoSinOpciones

```javascript
get showCuentaDesembolsoSinOpciones() {
		return this.isCuentaDeAhorroSeleccionada && this.cuentaDesembolsoOptions.length === 0;
	}
```

### showSolicitarExcepcionCredito

```javascript
get showSolicitarExcepcionCredito() {
		return this.excepcionContext.puedeSolicitar === true;
	}
```

### showAccionesAprobacionExcepcion

```javascript
get showAccionesAprobacionExcepcion() {
		return (
			this.excepcionContext.hasActiveApproval === true &&
			this.excepcionContext.canActOnApproval === true &&
			this.excepcionContext.estado === 'Pendiente' &&
			!this.excepcionContext.condicion
		);
	}
```

### showRespuestaCondicionExcepcion

```javascript
get showRespuestaCondicionExcepcion() {
		return this.excepcionContext.puedeResponderCondicion === true;
	}
```

### excepcionBloqueaAccionesOrdinarias

```javascript
get excepcionBloqueaAccionesOrdinarias() {
		return this.excepcionContext.tienePendientes === true;
	}
```

### allowOficialOrAdmins

```javascript
get allowOficialOrAdmins() {
		return Boolean(TIENE_PERMISO_OFICIAL_NEGOCIO) || this.hasAdminPermission;
	}
```

### allowSupervisorAnalistaOrAdmins

```javascript
get allowSupervisorAnalistaOrAdmins() {
		return Boolean(TIENE_PERMISO_SUPERVISOR) || this.hasAdminPermission;
	}
```

### allowComiteOrAdmins

```javascript
get allowComiteOrAdmins() {
		return Boolean(TIENE_PERMISO_COMITE_CREDITO) || this.hasAdminPermission;
	}
```

### allowLavadoOrAdmins

```javascript
get allowLavadoOrAdmins() {
		return Boolean(TIENE_PERMISO_PREVENCION_LAVADO_ACTIVOS) || this.hasAdminPermission;
	}
```

### allowAnalistaOrAdmins

```javascript
get allowAnalistaOrAdmins() {
		return Boolean(TIENE_PERMISO_ANALISTA_CREDITO) || this.hasAdminPermission;
	}
```

### allowRecepcionDocsOrAdmins

```javascript
get allowRecepcionDocsOrAdmins() {
		return Boolean(TIENE_PERMISO_CONTROL_DOCUMENTOS) || this.hasAdminPermission;
	}
```

### allowSupervisorOrAdmins

```javascript
get allowSupervisorOrAdmins() {
		return Boolean(TIENE_PERMISO_SUPERVISOR) || this.hasAdminPermission;
	}
```

### allowArchivoCustodiaOrAdmins

```javascript
get allowArchivoCustodiaOrAdmins() {
		return Boolean(TIENE_PERMISO_ARCHIVO_CUSTODIA_VALORES) || this.hasAdminPermission;
	}
```

### allowOnlyAdminsForReassign

```javascript
get allowOnlyAdminsForReassign() {
		return this.hasAdminPermission;
	}
```

### canFormalizeGuarantees

```javascript
get canFormalizeGuarantees() {
		if (this.hasAdminPermission) {
			return true;
		}
		return Boolean(TIENE_PERMISO_FORMALIZACION_CREDITOS) && (!this.usuarioFormalizacion || this.usuarioFormalizacion === USER_ID);
	}
```

### showPreguntaFormalizacion

```javascript
get showPreguntaFormalizacion() {
		return (
			this.canFormalizeGuarantees &&
			this.status === 'En proceso' &&
			this.substatus === SUBSTATUS_FORMALIZACION &&
			this.formalizacionContext.tieneGarantiasAplicables === true
		);
	}
```

### showFormalizarGarantiasPendientes

```javascript
get showFormalizarGarantiasPendientes() {
		return (
			this.canFormalizeGuarantees &&
			this.status === 'En proceso' &&
			POST_SIGNATURE_SUBSTATUSES.has(this.substatus) &&
			this.substatus !== SUBSTATUS_FORMALIZACION &&
			this.formalizacionContext.tieneGarantiasAplicables === true &&
			this.formalizacionContext.todasFormalizadas !== true
		);
	}
```

### canCurrentUserCompletePlanilla

```javascript
get canCurrentUserCompletePlanilla() {
		return this.hasAdminPermission || (Boolean(TIENE_PERMISO_DESEMBOLSO_CREDITOS) && this.usuarioGestionPlanilla === USER_ID);
	}
```

### canActOnApproval

```javascript
get canActOnApproval() {
		return this.hasAdminPermission || this.isCurrentUserAssignedApprover || this.isCurrentUserQueueMember;
	}
```

### allowBancaSeguroOrAdmins

```javascript
get allowBancaSeguroOrAdmins() {
		return Boolean(TIENE_PERMISO_BANCA_SEGURO) || this.hasAdminPermission;
	}
```

### canActOnCommitteeApproval

```javascript
get canActOnCommitteeApproval() {
		return this.canActOnApproval || this.allowComiteOrAdmins;
	}
```

### showEnviarRevisionSupervisor

```javascript
get showEnviarRevisionSupervisor() {
		return this.showAnalystDecisionStage;
	}
```

### isAnalystApprovalBaseState

```javascript
get isAnalystApprovalBaseState() {
		return (
			this.hasActiveApproval &&
			this.isAnalystApproval &&
			this.canActOnApproval &&
			this.allowAnalistaOrAdmins &&
			this.resultadoBuro === 'Referido' &&
			this.substatus === 'Análisis de crédito' &&
			this.docCompletaAnalisis === true &&
			this.debeRevisarComite === false &&
			this.debeRevisarSupervisor === false &&
			this.aprobadoConCond === false
		);
	}
```

### showAnalystValidationStage

```javascript
get showAnalystValidationStage() {
		return this.isAnalystApprovalBaseState && !this.documentacionValidadaAnalista;
	}
```

### showAnalystDecisionStage

```javascript
get showAnalystDecisionStage() {
		return this.isAnalystApprovalBaseState && this.documentacionValidadaAnalista;
	}
```

### showEdicionDocumentosAnalisis

```javascript
get showEdicionDocumentosAnalisis() {
		return (
			this.status === 'En proceso' &&
			this.showAnalystDecisionStage &&
			!this.excepcionBloqueaAccionesOrdinarias &&
			(!!this.solicitudCreditoOmniSubType || this.isPymeRla)
		);
	}
```

### showBotonEditarCapacidadPago

```javascript
get showBotonEditarCapacidadPago() {
		return this.showEdicionDocumentosAnalisis && !this.isPymeRla;
	}
```

### showModalEdicionDocumentoAnalisis

```javascript
get showModalEdicionDocumentoAnalisis() {
		return !!this.documentoAnalisisEnEdicion;
	}
```

### showEnviarAFirmar

```javascript
get showEnviarAFirmar() {
		return this.allowOficialOrAdmins && this.substatus === 'Gestionar firmas' && this.firmaCompletada === false && this.enviadoAFirmar === false;
	}
```

### showConsultarEstadoFirma

```javascript
get showConsultarEstadoFirma() {
		return this.allowOficialOrAdmins && this.substatus === 'Gestionar firmas' && this.firmaCompletada === false && this.enviadoAFirmar === true;
	}
```

### showDocDesembolso

```javascript
get showDocDesembolso() {
		return this.allowOficialOrAdmins && this.isSubstatusDocumentacionDesembolsoFirmas && this.docCompletaDesembolso === false;
	}
```

### showEnviarAArchivoYCustodia

```javascript
get showEnviarAArchivoYCustodia() {
		return this.allowOficialOrAdmins && this.substatus === 'Archivo y custodia' && this.docIncompletaPostDesembolso === true;
	}
```

### showSolicitarExcepcionBuro

```javascript
get showSolicitarExcepcionBuro() {
		return this.allowOficialOrAdmins && this.substatus === 'Rechazado por Buró';
	}
```

### showReintentarListas

```javascript
get showReintentarListas() {
		return this.allowOficialOrAdmins && this.substatus === 'En validación PEP/Listas' && !this.resultadoListas;
	}
```

### showReintentarBuro

```javascript
get showReintentarBuro() {
		return this.allowOficialOrAdmins && this.substatus === 'En Motor Buró' && !this.resultadoBuro;
	}
```

### showErrorAPIPrestamos

```javascript
get showErrorAPIPrestamos() {
		return (
			this.flagErrorAPIPrestamos === true &&
			this.substatus === 'Creación de crédito' &&
			this.formaDeDesembolso === FORMA_DESEMBOLSO_CUENTA_AHORRO
		);
	}
```

### showErrorAPIDesembolso

```javascript
get showErrorAPIDesembolso() {
		return this.flagErrorAPIDesembolso === true && this.substatus === 'Desembolso' && this.formaDeDesembolso === FORMA_DESEMBOLSO_CUENTA_AHORRO;
	}
```

### showMensajeValidacionAbanks

```javascript
get showMensajeValidacionAbanks() {
		return (
			this.hasActiveApproval &&
			this.isValidacionAbanksApproval &&
			this.substatus === 'Creación de crédito' &&
			this.formaDeDesembolso === FORMA_DESEMBOLSO_CUENTA_AHORRO &&
			!!this.numeroPrestamoAbanks
		);
	}
```

### showValidacionAbanks

```javascript
get showValidacionAbanks() {
		return this.showMensajeValidacionAbanks && this.canActOnApproval;
	}
```

### showRecepcionDocs

```javascript
get showRecepcionDocs() {
		return this.allowOficialOrAdmins && this.substatus === 'Recepción de documentos – Análisis' && this.docCompletaAnalisis === false;
	}
```

### showAccionesComite

```javascript
get showAccionesComite() {
		return (
			this.allowComiteOrAdmins &&
			this.aprobadoConCond === false &&
			this.resultadoBuro === 'Referido' &&
			this.substatus === 'Análisis de crédito' &&
			this.docCompletaAnalisis === true &&
			this.debeRevisarComite === true &&
			this.debeRevisarSupervisor === false
		);
	}
```

### showClienteAceptaCondicion

```javascript
get showClienteAceptaCondicion() {
		return this.allowOficialOrAdmins && this.aprobadoConCond === true && this.substatus === 'Análisis de crédito';
	}
```

### showPlanillaDesembolso

```javascript
get showPlanillaDesembolso() {
		return (
			this.status === 'En proceso' &&
			this.isSubstatusPendientePlanillaDesembolso &&
			this.desembolsoRealizado === false &&
			this.canCurrentUserCompletePlanilla
		);
	}
```

### showGestionPlanillaAssignedBanner

```javascript
get showGestionPlanillaAssignedBanner() {
		return this.isSubstatusPendientePlanillaDesembolso;
	}
```

### showPagaresAssignedBanner

```javascript
get showPagaresAssignedBanner() {
		return this.isSubstatusGeneracionPagares && !!this.usuarioPagaresYContratosName;
	}
```

### showFormalizacionAssignedBanner

```javascript
get showFormalizacionAssignedBanner() {
		return this.substatus === SUBSTATUS_FORMALIZACION && !!this.usuarioFormalizacionName;
	}
```

### showCreadoEnAbanks

```javascript
get showCreadoEnAbanks() {
		return this.contextoManual.puedeActuar && this.contextoManual.etapa === 'Creación de crédito';
	}
```

### showDesembolsado

```javascript
get showDesembolsado() {
		return this.contextoManual.puedeActuar && this.contextoManual.etapa === 'Desembolso';
	}
```

### showResponsableManual

```javascript
get showResponsableManual() {
		return this.contextoManual.etapaManual;
	}
```

### showReasignarManual

```javascript
get showReasignarManual() {
		return this.hasAdminPermission && this.showResponsableManual;
	}
```

### showReasignarPagares

```javascript
get showReasignarPagares() {
		return this.allowSupervisorOrAdmins && this.showPagaresAssignedBanner;
	}
```

### showReasignarGestionPlanilla

```javascript
get showReasignarGestionPlanilla() {
		return this.allowSupervisorOrAdmins && this.showGestionPlanillaAssignedBanner;
	}
```

### showReasignarFormalizacion

```javascript
get showReasignarFormalizacion() {
		return this.allowSupervisorOrAdmins && this.status === 'En proceso' && this.substatus === SUBSTATUS_FORMALIZACION;
	}
```

### showCompletarInformacion

```javascript
get showCompletarInformacion() {
		return (
			this.allowOficialOrAdmins &&
			this.status === 'Borrador' &&
			this.substatus === 'Completando información' &&
			!!this.solicitudCreditoOmniSubType &&
			!this.hasActiveApproval
		);
	}
```

### showGenerarPagareButton

```javascript
get showGenerarPagareButton() {
		return this.canGeneratePagareStep && this.canCurrentUserGeneratePagare && this.documentacionContratos.documentosAprobados === true;
	}
```

### showGenerarActoGarantiaButton

```javascript
get showGenerarActoGarantiaButton() {
		if (
			this.substatus === 'Documentación para contratos' ||
			(this.isSubstatusGeneracionPagares && this.documentacionContratos.documentosAprobados !== true)
		)
			return false;
		return (
			this.isPymeRla &&
			this.status === 'En proceso' &&
			this.requiereActoGarantia &&
			!this.actoGarantiaYaGenerado &&
			this.canCurrentUserGeneratePagare
		);
	}
```

### showGenerarPagareMessage

```javascript
get showGenerarPagareMessage() {
		return false;
	}
```

### showRevisionDocumentos

```javascript
get showRevisionDocumentos() {
        return this.status === 'En proceso' && this.isSubstatusGeneracionPagares && this.pagaresGenerados === true;
    }
```

### showRevisionDocumentosButtons

```javascript
get showRevisionDocumentosButtons() {
        return this.showRevisionDocumentos && this.canCurrentUserGeneratePagare;
    }
```

### showEditarDocumentosLegales

```javascript
get showEditarDocumentosLegales() {
        return this.showRevisionDocumentosButtons && !!this.revisionDocumentos.pagareId;
    }
```

### showDocumentosPendientes

```javascript
get showDocumentosPendientes() {
        return this.showRevisionDocumentosButtons && this.revisionDocumentos.listo !== true;
    }
```

### canGeneratePagareStep

```javascript
get canGeneratePagareStep() {
		return this.status === 'En proceso' && this.isSubstatusGeneracionPagares && this.pagaresGenerados === false;
	}
```

### canCurrentUserGeneratePagare

```javascript
get canCurrentUserGeneratePagare() {
		return this.wiredPagaresContextResult?.data?.canGeneratePagare === true;
	}
```

### showDevolverAOficial

```javascript
get showDevolverAOficial() {
		if (this.isAnalystApproval) return false;
		if (!this.allowSupervisorAnalistaOrAdmins) return false;

		const base =
			this.resultadoBuro === 'Referido' &&
			this.substatus === 'Análisis de crédito' &&
			this.docCompletaAnalisis === true &&
			this.aprobadoConCond === false;

		const a = base && this.debeRevisarComite === false && this.debeRevisarSupervisor === false;
		const b = base && this.debeRevisarComite === false && this.debeRevisarSupervisor === true;

		return a || b;
	}
```

### showDevolverAAnalista

```javascript
get showDevolverAAnalista() {
		return (
			this.allowSupervisorOrAdmins &&
			this.hasActiveApproval &&
			this.canActOnApproval &&
			this.resultadoBuro === 'Referido' &&
			this.substatus === 'Análisis de crédito' &&
			this.docCompletaAnalisis === true &&
			this.debeRevisarComite === false &&
			this.debeRevisarSupervisor === true &&
			this.aprobadoConCond === false
		);
	}
```

### showDevolverAAnalistaAction

```javascript
get showDevolverAAnalistaAction() {
		return this.condition5ApproveReject;
	}
```

### condition1ApproveReject

```javascript
get condition1ApproveReject() {
		return (
			this.hasActiveApproval &&
			this.canActOnApproval &&
			this.substatus === 'En validación PEP/Listas' &&
			this.resultadoListas === 'Coincidencia' &&
			this.allowLavadoOrAdmins
		);
	}
```

### condition2ApproveReject

```javascript
get condition2ApproveReject() {
		return (
			this.hasActiveApproval &&
			this.canActOnApproval &&
			this.solicitaExcBuro === true &&
			this.substatus === 'Rechazado por Buró' &&
			this.allowAnalistaOrAdmins
		);
	}
```

### condition3ApproveReject

```javascript
get condition3ApproveReject() {
		return (
			this.hasActiveApproval &&
			this.canActOnApproval &&
			this.resultadoBuro === 'Referido' &&
			this.substatus === 'Recepción de documentos – Análisis' &&
			this.docCompletaAnalisis === true &&
			this.allowRecepcionDocsOrAdmins
		);
	}
```

### condition4ApproveReject

```javascript
get condition4ApproveReject() {
		return this.showAnalystDecisionStage;
	}
```

### condition5ApproveReject

```javascript
get condition5ApproveReject() {
		return (
			this.hasActiveApproval &&
			this.canActOnApproval &&
			this.resultadoBuro === 'Referido' &&
			this.substatus === 'Análisis de crédito' &&
			this.docCompletaAnalisis === true &&
			this.debeRevisarComite === false &&
			this.debeRevisarSupervisor === true &&
			this.aprobadoConCond === false &&
			this.allowSupervisorOrAdmins
		);
	}
```

### condition6ApproveReject

```javascript
get condition6ApproveReject() {
		return (
			this.hasActiveApproval &&
			this.canActOnCommitteeApproval &&
			this.resultadoBuro === 'Referido' &&
			this.substatus === 'Análisis de crédito' &&
			this.docCompletaAnalisis === true &&
			this.debeRevisarComite === true &&
			this.debeRevisarSupervisor === false &&
			this.aprobadoConCond === false &&
			this.allowComiteOrAdmins
		);
	}
```

### condition7ApproveReject

```javascript
get condition7ApproveReject() {
		return (
			this.hasActiveApproval &&
			this.canActOnApproval &&
			this.isSubstatusDocumentacionDesembolsoFirmas &&
			this.docCompletaDesembolso === true &&
			this.allowRecepcionDocsOrAdmins
		);
	}
```

### condition8ApproveReject

```javascript
get condition8ApproveReject() {
		return (
			this.hasActiveApproval &&
			this.canActOnApproval &&
			this.status === 'En proceso' &&
			this.substatus === 'Archivo y custodia' &&
			this.desembolsoRealizado === true &&
			this.docIncompletaDesembolso === false &&
			this.allowArchivoCustodiaOrAdmins
		);
	}
```

### condition9ApproveReject

```javascript
get condition9ApproveReject() {
		return (
			this.hasActiveApproval &&
			this.canActOnApproval &&
			this.status === 'Borrador' &&
			this.substatus === 'Completando información' &&
			this.allowOficialOrAdmins
		);
	}
```

### condition10ApproveReject

```javascript
get condition10ApproveReject() {
		return (
			this.hasActiveApproval &&
			this.isBancaSeguroApproval &&
			this.canActOnApproval &&
			this.allowBancaSeguroOrAdmins &&
			this.status === 'En proceso' &&
			this.substatus === 'Banca Seguro'
		);
	}
```

### showApproveRejectButtons

```javascript
get showApproveRejectButtons() {
		return (
			this.condition1ApproveReject ||
			this.condition2ApproveReject ||
			this.condition3ApproveReject ||
			this.condition4ApproveReject ||
			this.condition5ApproveReject ||
			this.condition6ApproveReject ||
			this.condition7ApproveReject ||
			this.condition8ApproveReject ||
			this.condition9ApproveReject ||
			this.condition10ApproveReject
		);
	}
```

### showReassignButton

```javascript
get showReassignButton() {
		return this.hasActiveApproval && this.allowOnlyAdminsForReassign && !this.showClienteAceptaCondicion && !this.isValidacionAbanksApproval;
	}
```

### showApprovalSection

```javascript
get showApprovalSection() {
		return this.hasActiveApproval;
	}
```

### showActiveApprovalBanner

```javascript
get showActiveApprovalBanner() {
		return this.showApprovalSection && !this.showClienteAceptaCondicion && !this.isValidacionAbanksApproval;
	}
```

### showEmpty

```javascript
get showEmpty() {
		return !!this.wiredRecordResult?.data && !this.hasActions && !this.hasMessages;
	}
```

## Inventario de evidencia de código

SHA-256 del contenido leído; sirve para detectar cambios posteriores. Los archivos de Apex y LWC se analizaron sin ejecutarlos.

| Archivo | SHA-256 |
| --- | --- |
| classes/FSC_RLATriggerHandler.cls | `bdd997a2c347b5cb279c40f60111e88e7f5d7a1015ace83fd79dd42d48c8a05b` |
| classes/FSC_RlaAccionesController.cls | `3d478d89f167f3af7280c8d0cac522909ac28a1ace91fec9a91469f372338a82` |
| classes/FSC_RlaApprovalAdminService.cls | `0839d5f9db937473cdcc9a5ad2797bebf8edd6283cbbe9c4a761b04b2f81ff26` |
| classes/FSC_CreditoAprobadoLockService.cls | `9ab0b577ea27f57166c3d579308b1abfc09dc30f6d6e320ff410110f4b6289d6` |
| classes/FSC_DocumentacionContratosService.cls | `f25e5dc4de0452c8dd7b01582c1b67fd19477f87636e08e4bff13f1f68c74136` |
| classes/FSC_DatosContratoController.cls | `152c383d7884ff0e64d22bc1d102a5ae10a69013d2640ad0a34d70ec2b456e5f` |
| classes/FSC_DocumentoLegalService.cls | `3efecda5deabaa8eabc456ed01f76afe6d3787b955abdf508f1b36803f915339` |
| classes/FSC_GenerarPagarePDF_Action.cls | `62b1f5df283b23e2ab19e48ab9fb46ab23d79b86a3efcf5e8142c15f24a5fe92` |
| classes/FSC_GenerarContratoPDFQueueable.cls | `7c436636fc5b985d91eaa803622d65d95c43b54ef1cf10de58915cfd792e8435` |
| classes/FSC_ConsumoDocumentoResolver.cls | `15ccabbe2de5cda731e7516f6834d3f9f3d6e8c9ab931e149cf139f3b886f23c` |
| classes/FSC_RLAContractTemplateResolver.cls | `8ec8976c06e69bcf2a774bda60cfd96f3d6e625ce25db2016572c81cc2899e5f` |
| classes/FSC_FirmarDocumentoUtility.cls | `816144b2ed154c393fa79bccb70d955dda90063314a3d7a994ef118acfb0c5b6` |
| classes/FSC_ContentVersionTriggerHandler.cls | `070c94e28d07b574a8fdd5679fabed75d64099cd5f8547683a4fa80132b56a1a` |
| classes/FSC_ConfiguracionFirmaDocumentosService.cls | `6d57330cc3896dddd0283566758571d96c745d57cc7b4ed53077cf0a5ca61cc2` |
| classes/FSC_GarantiaFormalizacionService.cls | `50d40f7f70bfc512849374386b20f697604cc67ba238f701ba335a72c2ab7927` |
| classes/FSC_GarantiaFormalizacionController.cls | `996df014918885f43722f5d46d4c6ddadc6ecccd6f79926a8401924c8ade21e8` |
| classes/FSC_PlanillaDesembolsoSaver.cls | `bd150af6fc7150bb0c669558ab0a9c79f51cb19314d9313305ae60e39e5dbe54` |
| classes/FSC_GenerarPDF.cls | `b2ba8a5a789ae0a497cab5c4025be2415f832a848afc7db0891e7bad20219bfd` |
| classes/FSC_CapturaOperacionesService.cls | `599ede95cbb2ab31d777c27b5f0b48dac4b4164db1741f3f22430f395bc94234` |
| classes/FSC_APIPrestamoPrestamos.cls | `372222d7b7ceae30ee27cd03ee6ca20fb10f0a5fcd44c55cf4275e0f3c15ebb5` |
| classes/FSC_APIPrestamoDesembolso.cls | `6768ce8994ce7360da0c6167f28f9ec572b10fbba3c4bbbf61514fd3d1a301f0` |
| classes/FSC_LoanDecisionAPI.cls | `c2f4c6ce12e43875fee5424d4eda0525ec77c34d4543d9f8cc8c6d8aeaf30245` |
| classes/FSC_APIBuroCredito.cls | `9dc36fefeea25b9d5385f72cbdc76ab80c2eaea73128052d08e3249ffda63be2` |
| classes/FSC_BuroConfigService.cls | `9d09603edaed54045775a453f9e13eb9c7fd6bdfb8f011eacda094d0f7444ba8` |
| classes/FSC_CallAPIs.cls | `66ec0825a6236371db2cd210389d251105e35b7a78383937414e201b5e5026c2` |
| classes/INT003.cls | `da6e1c082629e019ceb585f003b72628b2f4ab411367ff41890b15cca27b5d37` |
| classes/FSC_ChecklistDocsController.cls | `fe64be846d3073a1fce73bb4bde2273150456d9e8aef45f4c15e4f850da8c67e` |
| classes/FSC_ExcepcionesCreditoController.cls | `b2f9580041c4611532ee8b7fda847ade34607a49f7e16a9458d0e0cfb6b9c684` |
| classes/FSC_ExcepcionConfig.cls | `a8599bf7fe68c8837e4fbed48293894d725ee2f9a045cf87f1661a7090d1a818` |
| classes/FSC_ExcepcionTriggerHandler.cls | `78a5135fb29d12248e12e8ee8234dad3c5253a9b156e52bbafa041d1c6e30392` |
| classes/FSC_RoleAuthorizationService.cls | `e9d3dcfe6e90f1d710cbf490cac78896a1a0d5a0cdb06eb62fc2e640e40ad4cf` |
| classes/FSC_LoanApplicantController.cls | `2f244e41361b602bd2aba3824ebd7bd044ab42a17bc8b56b6a6b27e50068ba12` |
| lwc/fsc_RlaAcciones/fsc_RlaAcciones.js | `5e89174f91c234c495108885eb7a1e544c4ab789860a79f46d26fa2982aceceb` |
| lwc/fsc_PathResidentialLoanApplication/fsc_PathResidentialLoanApplication.js | `0cdf55e5483ff1b80996f2cabc14d981f542692d7765b1734b88c949997b251b` |
| lwc/fsc_loanApplicantManager/fsc_loanApplicantManager.js | `138379c7a30ba2102fc42b87630405126b89c8f95f83b9218687ef55b8c4b22d` |
| lwc/fsc_loanFacilityManager/fsc_loanFacilityManager.js | `d04cf82e0149631364aacd14c18395337fd344a247662b166e578c118f9ebf40` |
| lwc/fsc_StepDescripcionFacilidadesNext/fsc_StepDescripcionFacilidadesNext.js | `c7d507ae11adc338cac4c2d2b6a51f914eae3f2df7e0ed961a80b47ceb06e136` |

