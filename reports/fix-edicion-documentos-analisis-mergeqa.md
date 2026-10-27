# Corrección de edición de documentos — mergeQA

Fecha: 26/10/2026. Despliegue completado a las 16:22:38 (Argentina).

## Resultado

- Informe de crédito: Antigüedad Laboral permite editar, guardar y recuperar el texto en la nueva versión del documento.
- Capacidad de pago: Patrimonio se calcula como Activos − Pasivos únicamente cuando ambos campos tienen valor. Si se vacía cualquiera, el resultado queda vacío. Cero es un valor válido.
- El cálculo utiliza los valores finales del documento, incluidos los ajustes guardados, tanto en el modal como en el PDF. Los valores históricos de Patrimonio se recalculan al abrir y guardar.
- La detección de la página de Capacidad de pago acepta URLs en minúsculas al abrir directamente el PDF.

## Alcance y despliegue

Se hizo retrieve de mergeQA antes de editar los componentes. Una segunda descarga confirmó que la base remota no había cambiado.

Paquete: `manifest/packageFixEdicionDocumentosAnalisis.xml`.

Componentes desplegados exclusivamente en `VimencaMergeQA`:

- `fsc_EditarDocumentoAnalisis`
- `FSC_RlaAccionesController`
- `FSC_ControladorDocumentosAnalisisCredito`
- `FSC_DocumentosAnalisisCreditoTest`

Validación: `0AfVC00000OxRET0A3`, exitosa.

Despliegue real del paquete validado: `0AfVC00000OxRUb0AN`. Estado confirmado mediante Metadata API: `Succeeded`, `checkOnly=false`, cuatro componentes, cero errores.

El retrieve posterior confirmó que los diez archivos de los componentes publicados coinciden con el paquete validado. Los flujos y otros componentes locales no forman parte del despliegue.

## Validación Apex

108 pruebas aprobadas, cero fallos y sin advertencias de cobertura. Se ejecutaron:

- `FSC_DocumentosAnalisisCreditoTest`
- `FSC_RlaAccionesControllerTest`
- `FSC_RlaAccionesControllerPrivilegedTest`
- `FSC_CoberturaPendienteTest`
- `FSC_MissingCoverageTest`

Cobertura de los controladores modificados:

| Clase | Cobertura |
| --- | --- |
| `FSC_RlaAccionesController` | 82,71 % |
| `FSC_ControladorDocumentosAnalisisCredito` | 93,18 % |

Las regresiones verifican campos vacíos, un solo operando, cero, importes con distintos separadores, valores históricos, guardado y regeneración, edición de Antigüedad Laboral y preservación de la edición de informes Pyme.

Las pruebas LWC agregadas durante el trabajo fueron retiradas por indicación del usuario.

## Hallazgo previo fuera del alcance

La ejecución ampliada detectó un fallo en `FSC_Cobertura80Test.cubreCreacionAsincronaConProducto`, dentro de `validarAutomatizacionAbanks`. Se reprodujo por separado contra el código existente de mergeQA antes del despliegue, en la ejecución `707VC00002CNzap`. Esta prueba no integra la selección final de 108 pruebas; no se modificó el flujo de creación de préstamos.
