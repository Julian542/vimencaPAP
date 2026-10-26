declare module "@salesforce/apex/FSC_FormalizacionGarantiasController.getContexto" {
  export default function getContexto(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_FormalizacionGarantiasController.ejecutarAccion" {
  export default function ejecutarAccion(param: {residentialLoanApplicationId: any, accion: any, datos: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_FormalizacionGarantiasController.descartarArchivos" {
  export default function descartarArchivos(param: {documentosIds: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_FormalizacionGarantiasController.getDatosDocumento" {
  export default function getDatosDocumento(param: {residentialLoanApplicationId: any, tipo: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_FormalizacionGarantiasController.generarDocumento" {
  export default function generarDocumento(param: {residentialLoanApplicationId: any, tipo: any, datosJson: any}): Promise<any>;
}
