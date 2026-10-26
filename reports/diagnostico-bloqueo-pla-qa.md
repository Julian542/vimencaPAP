# Diagnóstico y propuesta: bloqueo al crear solicitud con coincidencia PLA

Org revisada: VimencaMergeQA (sandbox, 00DVC000009qkJJ2AY).
Fecha: 26/10/2026.

## Evidencia recuperada

Retrieve 09SVC00000fP6Vd2AK, finalizado correctamente. Copia aislada en:
`/var/folders/rq/g0kvc9516mx57wkys9rhty940000gn/T/vimenca-pla-review-1as3umte/retrieved/unpackaged/unpackaged`.

Se confirmó mediante consulta que están activos el OmniScript FSC_SolicitudCreditoConsumo versión 12 y la IP FSC_ActualizarCrearSolicitudCreditoConsumo versión 9. Se recuperaron también Data Mappers, triggers, clases y aprobaciones relacionados. FlowDefinition del Flow PLA: versión activa 301VC00003doJqrYAE al iniciar la revisión; latest coincide con active.

El Flow FSC_Aprobacion_PLA y la IP de creación recuperados coinciden con las copias locales. El OmniScript recuperado contiene diferencias ajenas al error respecto a la copia local; no se sobrescribió.

## Causa

La IP crea primero ResidentialLoanApplication y después sus LoanApplicant. La solicitud nueva con coincidencia en listas cumple la rama ISNEW del Flow FSC_Aprobacion_PLA y se envía en la misma transacción al proceso FSC_Aprobacion_PLA_CHV. Ese proceso tiene recordEditability AdminOnly. LoanApplicant.LoanApplicationId es MasterDetail.

La respuesta Network aportada confirma que falla el guardado de LoanApplicant por registro bloqueado (success false, DMPCrearLoanApplicantStatus false). La respuesta funcional no contiene CreacionExitosa; la acción NARLAFallido del OmniScript regresa al Account cuando CreacionExitosa es distinto de true.

## Cambio propuesto

1. FSC_Aprobacion_PLA: conservar las condiciones y lógica existentes para solicitudes En proceso / En validación PEP/Listas; retirar únicamente la rama de envío al crear un borrador.
2. FSC_Aprobacion_PLA_Creacion: nuevo Flow solo para creación, con los mismos criterios de coincidencia, tipo de registro distinto de PYME y estado Borrador / Completando información. Ejecutar su lógica en una ruta AsyncAfterCommit. Comprobar que exista un LoanApplicant Deudor y después reutilizar selección de aprobador de FSC_Cola_PLA y envío a FSC_Aprobacion_PLA_CHV.

La aprobación se inicia después de que la transacción de creación termine de guardar solicitud, participantes y relacionados. El chequeo del deudor evita enviar una solicitud que no tenga al participante principal; no demuestra por sí solo que una carga parcial de varios participantes esté completa.

No requiere campos nuevos, cambios de Permission Sets, modificación de recordEditability ni cambios del OmniScript o la IP para resolver este bloqueo.

## Validación realizada

Se preparó una propuesta aislada en `/var/folders/rq/g0kvc9516mx57wkys9rhty940000gn/T/vimenca-pla-review-1as3umte/candidate-two-flows` y ZIP en `/var/folders/rq/g0kvc9516mx57wkys9rhty940000gn/T/vimenca-pla-review-1as3umte/candidate-two-flows.zip`.

Validación Metadata API con --dry-run, checkOnly=true:
- Id: 0AfVC00000OxKw90AF
- Resultado: Succeeded
- Componentes: 2 Flows
- Errores: 0
- Sin ejecución de pruebas Apex ni creación de datos funcionales.

La alternativa de agregar una ruta asíncrona directamente al Flow actual con sus condiciones de actualización fue rechazada por Salesforce en validación; separar la creación conserva esas condiciones.

## Prueba funcional pendiente

Antes de desplegar el arreglo, activarlo en el entorno de prueba y verificar con el usuario/PS Oficial de Negocio:
- Coincidencia: guarda deudor y codeudores, muestra confirmación del OmniScript y crea una sola aprobación PLA después del guardado.
- Sin coincidencia: continúa por Datos Generales y finaliza igual que antes.
- Solicitud existente en En validación PEP/Listas: conserva su envío al proceso general.

La validación de metadata no sustituye esa reproducción. No se desplegó ni activó ningún cambio.
