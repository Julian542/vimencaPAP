declare module "@salesforce/apex/FSC_RlaAccionesController.validarClasificacionMIPYMES" {
  export default function validarClasificacionMIPYMES(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.getApprovalContext" {
  export default function getApprovalContext(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.getAssignableUsers" {
  export default function getAssignableUsers(): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.getPagaresContext" {
  export default function getPagaresContext(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.getFormaDesembolsoOptions" {
  export default function getFormaDesembolsoOptions(): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.getCuentasDesembolsoOptions" {
  export default function getCuentasDesembolsoOptions(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.guardarFormaDesembolsoGestionPlanillas" {
  export default function guardarFormaDesembolsoGestionPlanillas(param: {residentialLoanApplicationId: any, formaDeDesembolso: any, financialAccountId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.guardarDatosPagare" {
  export default function guardarDatosPagare(param: {residentialLoanApplicationId: any, actoNumeroPagare: any, numeroFolioPagare: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.validateChecklistApprovalReadiness" {
  export default function validateChecklistApprovalReadiness(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.validarDocumentacionAnalista" {
  export default function validarDocumentacionAnalista(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.aprobarProcesoActual" {
  export default function aprobarProcesoActual(param: {residentialLoanApplicationId: any, comentario: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.rechazarProcesoActual" {
  export default function rechazarProcesoActual(param: {residentialLoanApplicationId: any, motivo: any, motivoDeRechazo: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.reasignarProcesoActual" {
  export default function reasignarProcesoActual(param: {residentialLoanApplicationId: any, newActorId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.reintentarListas" {
  export default function reintentarListas(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.reintentarBuro" {
  export default function reintentarBuro(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.reintentarCreacionPrestamo" {
  export default function reintentarCreacionPrestamo(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.reintentarDesembolso" {
  export default function reintentarDesembolso(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.cancelarAprobacion" {
  export default function cancelarAprobacion(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.aprobarConCondicion" {
  export default function aprobarConCondicion(param: {residentialLoanApplicationId: any, montoAprobado: any, plazoMesesAprobado: any, tasaInteresAprobada: any, otrasCondicionesComite: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.devolverAOficial" {
  export default function devolverAOficial(param: {residentialLoanApplicationId: any, motivo: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.devolverAAnalista" {
  export default function devolverAAnalista(param: {residentialLoanApplicationId: any, motivo: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.enviarRevisionSupervisor" {
  export default function enviarRevisionSupervisor(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.marcarFirmaCompletaYPasarADocDesembolso" {
  export default function marcarFirmaCompletaYPasarADocDesembolso(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.marcarEnviadoAFirmar" {
  export default function marcarEnviadoAFirmar(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.marcarDocumentosFirmadosFisicamente" {
  export default function marcarDocumentosFirmadosFisicamente(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.getFirmaValidationState" {
  export default function getFirmaValidationState(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.marcarDocCompletaDesembolso" {
  export default function marcarDocCompletaDesembolso(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.marcarCreadoEnAbanks" {
  export default function marcarCreadoEnAbanks(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.marcarDesembolsado" {
  export default function marcarDesembolsado(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.enviarAArchivoYCustodia" {
  export default function enviarAArchivoYCustodia(param: {residentialLoanApplicationId: any, motivo: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.solicitarExcepcionBuro" {
  export default function solicitarExcepcionBuro(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.marcarDocCompletaAnalisis" {
  export default function marcarDocCompletaAnalisis(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.consultarEstadoFirma" {
  export default function consultarEstadoFirma(): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.actualizarSubestadoGeneracionPagares" {
  export default function actualizarSubestadoGeneracionPagares(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.generarPagare" {
  export default function generarPagare(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.rechazarPorCliente" {
  export default function rechazarPorCliente(param: {residentialLoanApplicationId: any}): Promise<any>;
}
