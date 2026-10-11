declare module "@salesforce/apex/FSC_RlaAccionesController.getDatosDocumentoAnalisis" {
  export default function getDatosDocumentoAnalisis(param: {residentialLoanApplicationId: any, tipoDocumento: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.guardarYRegenerarDocumentoAnalisis" {
  export default function guardarYRegenerarDocumentoAnalisis(param: {residentialLoanApplicationId: any, tipoDocumento: any, cambiosJson: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.validarClasificacionMIPYMES" {
  export default function validarClasificacionMIPYMES(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.getApprovalContext" {
  export default function getApprovalContext(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.getAssignableUsers" {
  export default function getAssignableUsers(): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.getDocumentacionContratosContext" {
  export default function getDocumentacionContratosContext(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.enviarDocumentacionContratos" {
  export default function enviarDocumentacionContratos(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.solicitarDocumentacionContratos" {
  export default function solicitarDocumentacionContratos(param: {residentialLoanApplicationId: any, pedido: any}): Promise<any>;
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
declare module "@salesforce/apex/FSC_RlaAccionesController.guardarDatosPagareComplementario" {
  export default function guardarDatosPagareComplementario(param: {residentialLoanApplicationId: any, numeroPrestamoPagare: any}): Promise<any>;
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
declare module "@salesforce/apex/FSC_RlaAccionesController.aprobarProcesoActualConHistorial" {
  export default function aprobarProcesoActualConHistorial(param: {residentialLoanApplicationId: any, comentario: any, historialPago: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.rechazarBancaSeguro" {
  export default function rechazarBancaSeguro(param: {residentialLoanApplicationId: any, motivo: any, comentario: any}): Promise<any>;
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
declare module "@salesforce/apex/FSC_RlaAccionesController.validarCreacionEnAbanks" {
  export default function validarCreacionEnAbanks(param: {residentialLoanApplicationId: any}): Promise<any>;
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
declare module "@salesforce/apex/FSC_RlaAccionesController.getCapturaOperacionesContext" {
  export default function getCapturaOperacionesContext(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.guardarCapturaAbanks" {
  export default function guardarCapturaAbanks(param: {residentialLoanApplicationId: any, numeroPrestamo: any, credito: any, garantias: any, seguros: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.confirmarDesembolsoManual" {
  export default function confirmarDesembolsoManual(param: {residentialLoanApplicationId: any, amortizacion: any, recibos: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.getUsuariosCapturaOperaciones" {
  export default function getUsuariosCapturaOperaciones(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.reasignarCapturaOperaciones" {
  export default function reasignarCapturaOperaciones(param: {residentialLoanApplicationId: any, usuarioId: any, etapa: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.getUsuariosPagares" {
  export default function getUsuariosPagares(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.reasignarUsuarioPagares" {
  export default function reasignarUsuarioPagares(param: {residentialLoanApplicationId: any, usuarioId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_RlaAccionesController.descartarArchivosDesembolso" {
  export default function descartarArchivosDesembolso(param: {documentosIds: any}): Promise<any>;
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
  export default function consultarEstadoFirma(param: {residentialLoanApplicationId: any}): Promise<any>;
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
