declare module "@salesforce/apex/fsc_lookup_controller.search" {
  export default function search(param: {searchTerm: any, selectedIds: any}): Promise<any>;
}
declare module "@salesforce/apex/fsc_lookup_controller.searchEjecutivo" {
  export default function searchEjecutivo(param: {searchTerm: any, selectedIds: any}): Promise<any>;
}
declare module "@salesforce/apex/fsc_lookup_controller.getEjecutivosCambioOptions" {
  export default function getEjecutivosCambioOptions(): Promise<any>;
}
declare module "@salesforce/apex/fsc_lookup_controller.searchAumento" {
  export default function searchAumento(param: {searchTerm: any, selectedIds: any}): Promise<any>;
}
declare module "@salesforce/apex/fsc_lookup_controller.searchMatriz" {
  export default function searchMatriz(param: {producto: any}): Promise<any>;
}
declare module "@salesforce/apex/fsc_lookup_controller.getRecentlyViewed" {
  export default function getRecentlyViewed(param: {accountId: any}): Promise<any>;
}
declare module "@salesforce/apex/fsc_lookup_controller.getRecentlyViewedAumento" {
  export default function getRecentlyViewedAumento(param: {accountId: any}): Promise<any>;
}
declare module "@salesforce/apex/fsc_lookup_controller.getRecentlyViewedFinn" {
  export default function getRecentlyViewedFinn(param: {accountId: any, notInclude: any}): Promise<any>;
}
declare module "@salesforce/apex/fsc_lookup_controller.searchTarjetaCredito" {
  export default function searchTarjetaCredito(param: {searchTerm: any, selectedIds: any, excluirVigentes: any}): Promise<any>;
}
declare module "@salesforce/apex/fsc_lookup_controller.getRecentlyViewedTarjetaCredito" {
  export default function getRecentlyViewedTarjetaCredito(param: {accountId: any, excluirVigentes: any}): Promise<any>;
}
declare module "@salesforce/apex/fsc_lookup_controller.searchTrasladoBalance" {
  export default function searchTrasladoBalance(param: {searchTerm: any, selectedIds: any, notInclude: any}): Promise<any>;
}
declare module "@salesforce/apex/fsc_lookup_controller.getRecentlyViewedTrasladoBalance" {
  export default function getRecentlyViewedTrasladoBalance(param: {accountId: any, notInclude: any}): Promise<any>;
}
