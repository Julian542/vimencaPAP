declare module "@salesforce/apex/VFS_GenerarDocumentosUtility.generarPDFyContentDocument" {
  export default function generarPDFyContentDocument(param: {vfpName: any, recordId: any, fileName: any}): Promise<any>;
}
declare module "@salesforce/apex/VFS_GenerarDocumentosUtility.generarPDFDesdeDefinicion" {
  export default function generarPDFDesdeDefinicion(param: {name: any, recordId: any}): Promise<any>;
}
declare module "@salesforce/apex/VFS_GenerarDocumentosUtility.obtenerContentDocumentId" {
  export default function obtenerContentDocumentId(param: {titulo: any, recordId: any}): Promise<any>;
}
declare module "@salesforce/apex/VFS_GenerarDocumentosUtility.GenerarURl" {
  export default function GenerarURl(param: {contentDocumentId: any}): Promise<any>;
}
declare module "@salesforce/apex/VFS_GenerarDocumentosUtility.GetTitulo" {
  export default function GetTitulo(param: {ButtonName: any}): Promise<any>;
}
declare module "@salesforce/apex/VFS_GenerarDocumentosUtility.obtenerContratoFirmadoERP" {
  export default function obtenerContratoFirmadoERP(param: {accountId: any}): Promise<any>;
}
