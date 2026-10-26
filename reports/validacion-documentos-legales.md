# Revisión y edición de pagarés y contratos

Desplegado en `vimencab`, el 11/10/2026. Deployment ID: `0AfVC00000OjPNp0AN`. Estado: **Succeeded**; 29 componentes, sin errores de componentes ni de pruebas.

## Comportamiento

- Generar pagarés y documentos adicionales conserva `Generación de pagarés y plantillas` para los cuatro tipos de crédito.
- Se muestra: «Debe revisar el pagaré y contrato generado y luego presionar el botón Validado.»
- `Validado` comprueba los archivos requeridos y el acto de garantía, cuando corresponda, antes de avanzar a `Gestionar firmas`.
- Los editores permiten cambiar los textos del pagaré, contrato y pignoración, separados por párrafos y bloques. Guardar reemplaza el archivo; cancelar no guarda.
- Solo se modifica el contenido del archivo. La edición no actualiza campos de la solicitud, cuenta, garantías ni participantes.
- El HTML y CSS provienen de las plantillas actuales. Imágenes, anexos, atributos, firmas técnicas y diseño quedan fuera del editor. El texto se escapa para impedir cambios de estructura.
- Las ediciones persisten en el archivo y se conservan cuando ABANKS completa el pagaré complementario. Los archivos anteriores al despliegue no tienen la copia HTML editable.
- Se verifica autorización, pertenencia del documento, etapa, versión vigente y ausencia de envío a firma. El reemplazo es transaccional: si falla, conserva el archivo anterior.
- Si la generación asíncrona del documento adicional falla, el componente permite actualizar y reintentar.

## Pruebas

**121 pruebas Apex del alcance aprobadas**, ejecutadas con `RunSpecifiedTests`. **6 pruebas Jest del editor aprobadas** y ESLint sin errores.

| Clase modificada | Cobertura en el despliegue |
| --- | ---: |
| `FSC_DocumentoLegalService` | 89.49% |
| `FSC_RlaAccionesController` | 83.97% |
| `FSC_GenerarContratoPDFQueueable` | 84.72% |
| `FSC_RegenerarPagareComplementarioQbl` | 82.05% |
| `FSC_GenerarPagarePDF_Action` | 89.57% |

La suite cubre generación sin avance en los cuatro tipos, validación, contrato y pignoración, reemplazo de archivos, preservación de texto con ABANKS, entradas inválidas, autorización, archivos ajenos o enviados a firma y recuperación de generación. Incluye regresión del editor de análisis existente.

Al ampliar inicialmente la selección se observaron dos fallos ajenos a este cambio en `FSC_Cobertura80Test`: `cubreCandidatoNuevo` (AuraHandledException) y `cubreProductosInformePyme` (NullPointerException). Esa clase no forma parte de la suite final. No se afirma que toda la suite de la org esté libre de fallos.

## Verificación del formato

Las **16 plantillas** se compararon con su versión anterior: sin cambios en CSS, imágenes ni estructura. Solo se agregó el modo HTML para capturar el documento y dos atributos sin efecto visual para completar los campos del pagaré complementario.

Se compararon PDFs originales de Visualforce con la reimpresión del HTML mediante el motor usado al editar. **10 plantillas, 72 páginas: todas idénticas píxel por píxel**, con igual tamaño, texto y cantidad de imágenes.

| Plantilla comparada | Páginas | Datos de prueba |
| --- | ---: | --- |
| `FSC_PagarePDF` | 2 | Solicitud temporal ficticia |
| `FSC_PagareComercialComplementarioPDF` | 4 | Solicitud temporal ficticia |
| `FSC_PagareConsumoSimplePDF` | 4 | Solicitud temporal ficticia |
| `FSC_ContratoPrestamoComercialSF` | 9 | Plantilla sin datos de solicitud |
| `FSC_ContratoPrestamoComercialCH` | 11 | Plantilla sin datos de solicitud |
| `FSC_ContratoPrestamoComercialGMSP` | 11 | Plantilla sin datos de solicitud |
| `FSC_ContratoPrestamoComercialGS` | 9 | Plantilla sin datos de solicitud |
| `FSC_ContratoPrestamoComercialGarantiaCD` | 11 | Plantilla sin datos de solicitud |
| `FSC_ContratoConsumoHipotecario` | 9 | Plantilla sin datos de solicitud |
| `FSC_PignoracionCertificadoConsumoPDF` | 2 | Solicitud temporal ficticia |

Las otras seis variantes (contrato vehicular y cinco contratos hipotecarios de compra) requieren solicitudes completas y no se compararon visualmente en esta ejecución. Su estructura, CSS e imágenes se verificaron en el código; el motor de renderizado y el editor son comunes.

Además se ejecutó el guardado real del editor para un pagaré y un contrato: texto nuevo presente en el PDF, archivo anterior eliminado, datos y subestado de la solicitud conservados. Las imágenes conservaron contenido y posición, incluido el anexo del contrato.

Los archivos y registros temporales usados para estas comprobaciones se eliminaron. No se modificaron PermissionSets ni Perfiles.

## Límite de la conservación visual

Se conservan las plantillas, estilos, márgenes, imágenes y estructura. Cambiar la longitud del texto puede cambiar saltos de línea, posición de párrafos y número de páginas. La comparación idéntica corresponde a reimprimir el mismo texto.

## Despliegue reproducible

Manifest: `manifest/packageDocumentosLegales.xml`. Solo incluye las clases, páginas, componentes y el campo técnico de ContentVersion utilizados por esta solución. No incluye PermissionSets ni Perfiles.
