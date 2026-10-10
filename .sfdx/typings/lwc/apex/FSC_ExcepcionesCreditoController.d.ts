declare module "@salesforce/apex/FSC_ExcepcionesCreditoController.getContextoExcepcion" {
  export default function getContextoExcepcion(param: {residentialLoanApplicationId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_ExcepcionesCreditoController.getOpcionesExcepcion" {
  export default function getOpcionesExcepcion(): Promise<any>;
}
declare module "@salesforce/apex/FSC_ExcepcionesCreditoController.solicitarExcepcion" {
  export default function solicitarExcepcion(param: {residentialLoanApplicationId: any, tipo: any, detalle: any, descripcion: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_ExcepcionesCreditoController.aprobarExcepcion" {
  export default function aprobarExcepcion(param: {excepcionId: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_ExcepcionesCreditoController.aprobarExcepcionConCondicion" {
  export default function aprobarExcepcionConCondicion(param: {excepcionId: any, condicion: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_ExcepcionesCreditoController.rechazarExcepcion" {
  export default function rechazarExcepcion(param: {excepcionId: any, motivo: any}): Promise<any>;
}
declare module "@salesforce/apex/FSC_ExcepcionesCreditoController.responderCondicionCliente" {
  export default function responderCondicionCliente(param: {excepcionId: any, clienteAprueba: any}): Promise<any>;
}
