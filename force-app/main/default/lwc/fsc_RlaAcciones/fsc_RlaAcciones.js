import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { RefreshEvent, registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import USER_ID from '@salesforce/user/Id';
import USER_NAME_FIELD from '@salesforce/schema/User.Name';
import TIENE_PERMISO_ADMINISTRADOR from '@salesforce/customPermission/FSC_CP_Administrador';
import TIENE_PERMISO_ANALISTA_CREDITO from '@salesforce/customPermission/FSC_CP_Analista_Credito';
import TIENE_PERMISO_ARCHIVO_CUSTODIA_VALORES from '@salesforce/customPermission/FSC_CP_Archivo_Custodia_Valores';
import TIENE_PERMISO_COMITE_CREDITO from '@salesforce/customPermission/FSC_CP_Comite_Credito';
import TIENE_PERMISO_OFICIAL_NEGOCIO from '@salesforce/customPermission/FSC_CP_Oficial_Negocio';
import TIENE_PERMISO_PREVENCION_LAVADO_ACTIVOS from '@salesforce/customPermission/FSC_CP_Prevencion_Lavado_Activos';
import TIENE_PERMISO_CONTROL_DOCUMENTOS from '@salesforce/customPermission/FSC_CP_Recepcion_Control_Documentos';
import TIENE_PERMISO_SUPERVISOR from '@salesforce/customPermission/FSC_CP_Supervisor';
import TIENE_PERMISO_DESEMBOLSO_CREDITOS from '@salesforce/customPermission/FSC_CP_Desembolso_Creditos';
import TIENE_PERMISO_FORMALIZACION_CREDITOS from '@salesforce/customPermission/FSC_CP_Formalizacion_Creditos';
import TIENE_PERMISO_BANCA_SEGURO from '@salesforce/customPermission/FSC_CP_BancaSeguro';

import reintentarListas from '@salesforce/apex/FSC_RlaAccionesController.reintentarListas';
import reintentarBuro from '@salesforce/apex/FSC_RlaAccionesController.reintentarBuro';
import reintentarCreacionPrestamo from '@salesforce/apex/FSC_RlaAccionesController.reintentarCreacionPrestamo';
import validarCreacionEnAbanks from '@salesforce/apex/FSC_RlaAccionesController.validarCreacionEnAbanks';
import reintentarDesembolso from '@salesforce/apex/FSC_RlaAccionesController.reintentarDesembolso';
import aprobarConCondicion from '@salesforce/apex/FSC_RlaAccionesController.aprobarConCondicion';
import devolverAOficial from '@salesforce/apex/FSC_RlaAccionesController.devolverAOficial';
import devolverAAnalista from '@salesforce/apex/FSC_RlaAccionesController.devolverAAnalista';
import enviarRevisionSupervisor from '@salesforce/apex/FSC_RlaAccionesController.enviarRevisionSupervisor';
import enviarDocumentosFirmar from '@salesforce/apex/FSC_FirmarDocumentoUtility.enviarDocumentosFirmar';

import getApprovalContext from '@salesforce/apex/FSC_RlaAccionesController.getApprovalContext';
import getAssignableUsers from '@salesforce/apex/FSC_RlaAccionesController.getAssignableUsers';
import getPagaresContext from '@salesforce/apex/FSC_RlaAccionesController.getPagaresContext';
import getDocumentacionContratosContext from '@salesforce/apex/FSC_RlaAccionesController.getDocumentacionContratosContext';
import enviarDocumentacionContratos from '@salesforce/apex/FSC_RlaAccionesController.enviarDocumentacionContratos';
import solicitarDocumentacionContratos from '@salesforce/apex/FSC_RlaAccionesController.solicitarDocumentacionContratos';
import getFormaDesembolsoOptions from '@salesforce/apex/FSC_RlaAccionesController.getFormaDesembolsoOptions';
import getCuentasDesembolsoOptions from '@salesforce/apex/FSC_RlaAccionesController.getCuentasDesembolsoOptions';
import guardarFormaDesembolsoGestionPlanillas from '@salesforce/apex/FSC_RlaAccionesController.guardarFormaDesembolsoGestionPlanillas';
import getContextoGeneracion from '@salesforce/apex/FSC_DatosContratoController.getContextoGeneracion';
import guardarDatosYPrepararGeneracion from '@salesforce/apex/FSC_DatosContratoController.guardarDatosYPrepararGeneracion';
import validateChecklistApprovalReadiness from '@salesforce/apex/FSC_RlaAccionesController.validateChecklistApprovalReadiness';
import validarDocumentacionAnalista from '@salesforce/apex/FSC_RlaAccionesController.validarDocumentacionAnalista';
import aprobarProcesoActual from '@salesforce/apex/FSC_RlaAccionesController.aprobarProcesoActual';
import rechazarProcesoActual from '@salesforce/apex/FSC_RlaAccionesController.rechazarProcesoActual';
import rechazarBancaSeguro from '@salesforce/apex/FSC_RlaAccionesController.rechazarBancaSeguro';
import reasignarProcesoActual from '@salesforce/apex/FSC_RlaAccionesController.reasignarProcesoActual';

import marcarDocCompletaDesembolso from '@salesforce/apex/FSC_RlaAccionesController.marcarDocCompletaDesembolso';
import getCapturaOperacionesContext from '@salesforce/apex/FSC_RlaAccionesController.getCapturaOperacionesContext';
import guardarCapturaAbanks from '@salesforce/apex/FSC_RlaAccionesController.guardarCapturaAbanks';
import confirmarDesembolsoManual from '@salesforce/apex/FSC_RlaAccionesController.confirmarDesembolsoManual';
import getUsuariosCapturaOperaciones from '@salesforce/apex/FSC_RlaAccionesController.getUsuariosCapturaOperaciones';
import reasignarCapturaOperaciones from '@salesforce/apex/FSC_RlaAccionesController.reasignarCapturaOperaciones';
import getUsuariosPagares from '@salesforce/apex/FSC_RlaAccionesController.getUsuariosPagares';
import reasignarUsuarioPagares from '@salesforce/apex/FSC_RlaAccionesController.reasignarUsuarioPagares';
import descartarArchivosDesembolso from '@salesforce/apex/FSC_RlaAccionesController.descartarArchivosDesembolso';
import enviarAArchivoYCustodia from '@salesforce/apex/FSC_RlaAccionesController.enviarAArchivoYCustodia';
import solicitarExcepcionBuro from '@salesforce/apex/FSC_RlaAccionesController.solicitarExcepcionBuro';
import marcarDocCompletaAnalisis from '@salesforce/apex/FSC_RlaAccionesController.marcarDocCompletaAnalisis';
import actualizarSubestadoGeneracionPagares from '@salesforce/apex/FSC_RlaAccionesController.actualizarSubestadoGeneracionPagares';
import rechazarPorCliente from '@salesforce/apex/FSC_RlaAccionesController.rechazarPorCliente';
import consultarEstadoFirma from '@salesforce/apex/FSC_RlaAccionesController.consultarEstadoFirma';
import generarPagare from '@salesforce/apex/FSC_RlaAccionesController.generarPagare';
import generarActoGarantiaSolidaria from '@salesforce/apex/FSC_GenerarActoGarantiaSolidaria.generar';
import marcarDocumentosFirmadosFisicamente from '@salesforce/apex/FSC_RlaAccionesController.marcarDocumentosFirmadosFisicamente';
import getFirmaValidationState from '@salesforce/apex/FSC_RlaAccionesController.getFirmaValidationState';
import validarClasificacionMIPYMES from '@salesforce/apex/FSC_RlaAccionesController.validarClasificacionMIPYMES';
import getContextoExcepcion from '@salesforce/apex/FSC_ExcepcionesCreditoController.getContextoExcepcion';
import getOpcionesExcepcion from '@salesforce/apex/FSC_ExcepcionesCreditoController.getOpcionesExcepcion';
import solicitarExcepcionCredito from '@salesforce/apex/FSC_ExcepcionesCreditoController.solicitarExcepcion';
import aprobarExcepcionCredito from '@salesforce/apex/FSC_ExcepcionesCreditoController.aprobarExcepcion';
import aprobarExcepcionConCondicion from '@salesforce/apex/FSC_ExcepcionesCreditoController.aprobarExcepcionConCondicion';
import rechazarExcepcionCredito from '@salesforce/apex/FSC_ExcepcionesCreditoController.rechazarExcepcion';
import responderCondicionCliente from '@salesforce/apex/FSC_ExcepcionesCreditoController.responderCondicionCliente';
import getFormalizacionGarantiasContext from '@salesforce/apex/FSC_GarantiaFormalizacionController.getContext';
import desembolsarSinRegistrarGarantias from '@salesforce/apex/FSC_GarantiaFormalizacionController.desembolsarSinRegistrar';
import guardarFormalizacionGarantias from '@salesforce/apex/FSC_GarantiaFormalizacionController.guardarFormalizacion';

import SUBSTATUS_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_Subestado__c';
import ACTO_NUMERO_PAGARE_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_ActoNumeroPagare__c';
import NUMERO_FOLIO_PAGARE_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_NumeroFolioPagare__c';
import PAGARES_GENERADOS_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_Pagares_y_Plantillas_Generados__c';
import REQUIERE_ACTO_GARANTIA_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_Requiere_Acto_Garantia__c';
import ACTO_GARANTIA_GENERADO_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_Acto_Garantia_Generado__c';
import RESULTADO_LISTAS_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_Resultado_PEP_Listas__c';
import ERROR_VALIDACION_LISTAS_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_ErrorValidacionListas__c';
import RESULTADO_BURO_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_Resultado_Buro__c';
import STATUS_FIELD from '@salesforce/schema/ResidentialLoanApplication.Status';
import ACCOUNT_ID_FIELD from '@salesforce/schema/ResidentialLoanApplication.AccountId';
import OWNER_ID_FIELD from '@salesforce/schema/ResidentialLoanApplication.OwnerId';
import RECORD_TYPE_ID_FIELD from '@salesforce/schema/ResidentialLoanApplication.RecordTypeId';
import RECORD_TYPE_DEVELOPER_NAME_FIELD from '@salesforce/schema/ResidentialLoanApplication.RecordType.DeveloperName';

import APLICA_EXC_BURO_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_AplicaExcepcionBuro__c';
import SOLICITA_EXC_BURO_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_SolicitaExcepcionParaRechazoDeBuro__c';

import DOC_COMPLETA_ANALISIS_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_Doc_Completa_Analisis__c';
import DOC_COMPLETA_DESEMBOLSO_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_Doc_Completa_Desembolso__c';

import APROBADO_COND_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_Aprobado_con_Condiciones__c';
import DEBE_REVISAR_COMITE_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_DebeRevisarComite__c';
import DEBE_REVISAR_SUPERVISOR_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_DebeRevisarSupervisor__c';
import DOCUMENTACION_VALIDADA_ANALISTA_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_DocumentacionValidadaAnalista__c';

import MONTO_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_Monto__c';
import PLAZO_MESES_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_Plazo_meses__c';
import TASA_INTERES_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_TasaInteres__c';

import MONTO_APROBADO_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_MontoAprobado__c';
import PLAZO_MESES_APROBADO_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_PlazoMesesAprobado__c';
import MAX_LOAN_TERM_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_PlazoMaximoPermitido__c';
import TASA_INTERES_APROBADA_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_TasaInteresAprobada__c';
import OTRAS_CONDICIONES_COMITE_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_OtrasCondicionesComite__c';
import FIRMA_COMPLETADA_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_Firma_completada__c';
import ENVIADO_A_FIRMAR_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_EnviadoAFirmar__c';
import DOCUMENTOS_FIRMADOS_FIS_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_DocumentosFirmadosFis__c';
import DOC_INCOMPLETA_POST_DESEMBOLSO_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_Doc_Incompleta_Post_Desembolso__c';
import FORMA_DESEMBOLSO_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_FormaDeDesembolso__c';
import NUMERO_CUENTA_DESEMBOLSO_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_NumeroCuentaDesembolso__c';
import USUARIO_GESTION_PLANILLA_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_UsuarioGestionPlanilla__c';
import USUARIO_GESTION_PLANILLA_NAME_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_UsuarioGestionPlanilla__r.Name';
import DESEMBOLSO_REALIZADO_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_Desembolso_Realizado__c';
import DOC_INCOMPLETA_DESEMBOLSO_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_Doc_Incompleta_Desembolso__c';
import FLAG_ERROR_API_PRESTAMOS_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_FlagErrorAPIPrestamos__c';
import FLAG_ERROR_API_DESEMBOLSO_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_FlagErrorAPIDesembolso__c';
import NUMERO_PRESTAMO_ABANKS_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_NumeroPrestamoAbanks__c';
import MOTIVOS_RECHAZO_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_MotivosDeRechazo__c';
import FSC_GARANTIA_OBJECT from '@salesforce/schema/FSC_Garantia__c';
import VEHICLE_MODEL_FIELD from '@salesforce/schema/FSC_Garantia__c.FSC_Modelo_Vehiculo__c';

const PROCESS_GESTION_PLANILLAS_DESEMBOLSO = 'FSC_GestionPlanillasDeDesembolso';
const PROCESS_ANALISTA_CREDITO = 'FSC_AnalistasDeCredito';
const PROCESS_EXCEPCIONES_CREDITO = 'FSC_ExcepcionesDeCredito';
const PROCESS_VALIDACION_ABANKS = 'FSC_ValidacionEnAbanks';
const PROCESS_BANCA_SEGURO = 'FSC_BancaSeguro';
const SUBSTATUS_FORMALIZACION = 'Formalización';
const POST_SIGNATURE_SUBSTATUSES = new Set([
	SUBSTATUS_FORMALIZACION,
	'Documentación para desembolso y firmas',
	'Pendiente planilla de desembolso',
	'Creación de crédito',
	'Desembolso',
	'Archivo y custodia',
]);
const FORMALIZATION_YES_NO_OPTIONS = Object.freeze([
	{ label: 'Sí', value: 'Sí' },
	{ label: 'No', value: 'No' },
]);
const NON_FUTURE_DATE_ERROR_BY_FIELD_KEY = Object.freeze({
	seguroFechaEndoso: 'La fecha del endoso no puede ser posterior a la fecha actual.',
	garantiaFechaTitulo: 'La fecha de expedición del título no puede ser posterior a la fecha actual.',
	hipotecarioFechaPagoInicial: 'La fecha del comprobante de pago inicial no puede ser posterior a la fecha actual.',
});
const VEHICLE_BRAND_FIELD_KEY = 'vehiculoMarca';
const VEHICLE_MODEL_FIELD_KEY = 'vehiculoModelo';
const MENSAJE_CLASIFICACION_MIPYMES_INVALIDA =
	'No se puede continuar con esta solicitud de crédito pyme debido a que la cantidad de empleados o las ventas brutas anuales superan el máximo de Mediana Empresa. Debe crear un crédito comercial.';
const FORMA_DESEMBOLSO_CHEQUE_ADMINISTRACION = 'Cheque de administracion';
const FORMA_DESEMBOLSO_CUENTA_AHORRO_Y_CHEQUE_ADMINISTRACION = 'Cuenta de ahorro y Cheque de administración';
const FORMA_DESEMBOLSO_CUENTA_AHORRO = 'Cuenta de ahorro';
const SOLICITUD_CREDITO_OMNI_BY_RECORD_TYPE = {
	FSC_Solicitud_Credito_Consumo: 'SolicitudCreditoConsumo',
	FSC_Solicitud_Credito_Hipotecario: 'SolicitudCreditoHipotecario',
	FSC_Solicitud_Credito_Vehiculo: 'SolicitudCreditoVehiculo',
};

const FIELDS = [
	SUBSTATUS_FIELD,
	ACTO_NUMERO_PAGARE_FIELD,
	NUMERO_FOLIO_PAGARE_FIELD,
	PAGARES_GENERADOS_FIELD,
	REQUIERE_ACTO_GARANTIA_FIELD,
	ACTO_GARANTIA_GENERADO_FIELD,
	RESULTADO_LISTAS_FIELD,
	ERROR_VALIDACION_LISTAS_FIELD,
	RESULTADO_BURO_FIELD,
	STATUS_FIELD,
	ACCOUNT_ID_FIELD,
	OWNER_ID_FIELD,
	RECORD_TYPE_ID_FIELD,
	RECORD_TYPE_DEVELOPER_NAME_FIELD,
	APLICA_EXC_BURO_FIELD,
	SOLICITA_EXC_BURO_FIELD,
	DOC_COMPLETA_ANALISIS_FIELD,
	DOC_COMPLETA_DESEMBOLSO_FIELD,
	APROBADO_COND_FIELD,
	DEBE_REVISAR_COMITE_FIELD,
	DEBE_REVISAR_SUPERVISOR_FIELD,
	DOCUMENTACION_VALIDADA_ANALISTA_FIELD,
	MONTO_FIELD,
	PLAZO_MESES_FIELD,
	TASA_INTERES_FIELD,
	MONTO_APROBADO_FIELD,
	PLAZO_MESES_APROBADO_FIELD,
	TASA_INTERES_APROBADA_FIELD,
	OTRAS_CONDICIONES_COMITE_FIELD,
	FIRMA_COMPLETADA_FIELD,
	ENVIADO_A_FIRMAR_FIELD,
	DOC_INCOMPLETA_POST_DESEMBOLSO_FIELD,
	FORMA_DESEMBOLSO_FIELD,
	NUMERO_CUENTA_DESEMBOLSO_FIELD,
	USUARIO_GESTION_PLANILLA_FIELD,
	USUARIO_GESTION_PLANILLA_NAME_FIELD,
	DESEMBOLSO_REALIZADO_FIELD,
	DOC_INCOMPLETA_DESEMBOLSO_FIELD,
	NUMERO_PRESTAMO_ABANKS_FIELD,
];

const OPTIONAL_FIELDS = [DOCUMENTOS_FIRMADOS_FIS_FIELD, FLAG_ERROR_API_PRESTAMOS_FIELD, FLAG_ERROR_API_DESEMBOLSO_FIELD, MAX_LOAN_TERM_FIELD];

export default class Fsc_RlaAcciones extends NavigationMixin(LightningElement) {
	_recordId;
	componentConnected = false;
	lastClasificacionValidationRecordId;
	@track validandoClasificacionMIPYMES = false;
	@track clasificacionMIPYMESValidada = false;
	@track clasificacionMIPYMESInvalida = false;
	@track clasificacionMIPYMESError = '';

	@track loading = false;
	wiredRecordResult;
	wiredCapturaOperacionesResult;
	showModalCaptura = false;
	showModalDesembolsoManual = false;
	showModalReasignacionManual = false;
	creditoConfirmado = false;
	garantiasConfirmadas = false;
	segurosConfirmados = false;
	numeroCaptura = '';
	archivosAmortizacion = [];
	archivosRecibo = [];
	usuariosManuales = [];
	usuarioManualSeleccionado;
	etapaReasignacionManual;
	reasignandoPagares = false;
	formatosDesembolso = ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.jpg', '.jpeg', '.png'];
	wiredApprovalContextResult;
	wiredPagaresContextResult;
	wiredDocumentacionContratosResult;
	refreshHandlerId;
	showModalPedidoDocumentacion = false;
	pedidoDocumentacionInput = '';
	wiredExcepcionContextResult;
	wiredFormalizacionResult;
	wiredOwnerResult;
	rlaRecordTypeId;
	rlaOwnerId;
	garantiaRecordTypeId;
	vehicleModelPicklistData;

	@track showModalCondiciones = false;
	@track showModalDevolver = false;
	@track showModalReasignar = false;
	@track documentoAnalisisEnEdicion = '';

	@track montoAprobado;
	@track plazoAprobado;
	@track tasaAprobada;
	@track otrasCondicionesComite = '';

	@track motivoDevolver = '';
	@track devolverContext = 'ANALISIS';

	@track usuarioReasignadoId = '';
	@track usuariosOptions = [];

	@track showModalAprobacion = false;
	@track comentarioAprobacion = '';

	@track showModalRechazo = false;
	@track comentarioRechazoBancaSeguro = '';
	@track motivoRechazo = '';
	@track motivoRechazoPicklist = '';
	@track motivosRechazoOptions = [];

	@track showModalPlanillaDesembolso = false;
	@track formaDesembolsoSeleccionada = '';
	@track formaDesembolsoOptions = [];
	@track cuentaDesembolsoSeleccionada = '';
	@track cuentaDesembolsoOptions = [];
	@track showModalDatosPagare = false;
	@track requierePagareNotarial = true;
	@track codigoTipoPagareGeneracion = 'NOTARIAL';
	@track tipoPagareGeneracion = '';
	@track actoNumeroPagareInput = '';
	@track numeroFolioPagareInput = '';
	@track numeroPrestamoPagareInput = '';
	@track aplicaContratoGeneracion = false;
	@track contratoDisponibleGeneracion = false;
	@track generarContratoConPagareNotarial = false;
	@track nombreContratoGeneracion = '';
	@track seccionesContratoGeneracion = [];
	@track seccionesGastosHipotecarios = [];
	@track seccionesPagareGeneracion = [];
	@track seccionesActoGarantiaGeneracion = [];
	@track seccionesPignoracionGeneracion = [];
	@track requiereActoGarantiaGeneracion = false;
	@track actoGarantiaGenerado = false;
	@track generacionSoloActoGarantia = false;
	@track requierePignoracionGeneracion = false;
	@track pignoracionGenerada = false;
	@track erroresConfiguracionContrato = [];
	@track erroresConfiguracionActo = [];
	@track showModalFirmaFisica = false;
	@track showModalSolicitarExcepcionCredito = false;
	@track showModalCondicionExcepcion = false;
	@track showModalRechazoExcepcion = false;
	@track opcionesExcepcion = [];
	@track tipoExcepcionSeleccionado = '';
	@track detalleExcepcionSeleccionado = '';
	@track descripcionExcepcion = '';
	@track condicionExcepcionInput = '';
	@track motivoRechazoExcepcion = '';
	@track showModalFormalizacionGarantias = false;
	@track garantiasFormalizacion = [];

	@api
	get recordId() {
		return this._recordId;
	}

	set recordId(value) {
		this._recordId = value;
		if (this.componentConnected) {
			this.validarClasificacionMIPYMESInicial();
		}
	}

	connectedCallback() {
		this.componentConnected = true;
		this.refreshHandlerId = registerRefreshHandler(this, this.handleRefreshDocumentacion.bind(this));
		this.validarClasificacionMIPYMESInicial();
	}

	disconnectedCallback() {
		this.componentConnected = false;
		unregisterRefreshHandler(this.refreshHandlerId);
	}

	async handleRefreshDocumentacion() {
		await this.refreshAll();
		return true;
	}

	async validarClasificacionMIPYMESInicial() {
		const residentialLoanApplicationId = this.recordId;
		if (!residentialLoanApplicationId || this.lastClasificacionValidationRecordId === residentialLoanApplicationId) {
			return;
		}

		this.lastClasificacionValidationRecordId = residentialLoanApplicationId;
		this.validandoClasificacionMIPYMES = true;
		this.clasificacionMIPYMESValidada = false;
		this.clasificacionMIPYMESInvalida = false;
		this.clasificacionMIPYMESError = '';
		this.closeAllModalsForValidation();

		try {
			const clasificacionValida = await validarClasificacionMIPYMES({ residentialLoanApplicationId });
			if (this.recordId !== residentialLoanApplicationId) {
				return;
			}
			this.clasificacionMIPYMESInvalida = clasificacionValida === false;
			this.clasificacionMIPYMESValidada = true;
		} catch (error) {
			if (this.recordId !== residentialLoanApplicationId) {
				return;
			}
			this.clasificacionMIPYMESError = this.getErrorMessage(error, 'No se pudo validar la clasificación MIPYMES de la solicitud.');
		} finally {
			if (this.recordId === residentialLoanApplicationId) {
				this.validandoClasificacionMIPYMES = false;
			}
		}
	}

	get showSpinner() {
		return this.loading || this.validandoClasificacionMIPYMES;
	}

	get puedeMostrarContenido() {
		return this.clasificacionMIPYMESValidada && !this.clasificacionMIPYMESInvalida && !this.clasificacionMIPYMESError;
	}

	get containerClass() {
		return this.puedeMostrarContenido ? 'container' : 'container actionsBlocked';
	}

	get mensajeClasificacionMIPYMESInvalida() {
		return MENSAJE_CLASIFICACION_MIPYMES_INVALIDA;
	}

	closeAllModalsForValidation() {
		this.showModalPedidoDocumentacion = false;
		this.showModalCondiciones = false;
		this.showModalDevolver = false;
		this.showModalReasignar = false;
		this.showModalAprobacion = false;
		this.showModalRechazo = false;
		this.showModalPlanillaDesembolso = false;
		this.showModalDatosPagare = false;
		this.showModalFirmaFisica = false;
		this.showModalSolicitarExcepcionCredito = false;
		this.showModalCondicionExcepcion = false;
		this.showModalRechazoExcepcion = false;
		this.showModalFormalizacionGarantias = false;
	}

	@wire(getRecord, { recordId: '$recordId', fields: FIELDS, optionalFields: OPTIONAL_FIELDS })
	wiredRecord(result) {
		this.wiredRecordResult = result;
		if (result?.data) {
			this.rlaRecordTypeId = getFieldValue(result.data, RECORD_TYPE_ID_FIELD);
			this.rlaOwnerId = getFieldValue(result.data, OWNER_ID_FIELD);
		}
	}

	get formalizacionRecordId() {
		return this.canFormalizeGuarantees && this.status === 'En proceso' && POST_SIGNATURE_SUBSTATUSES.has(this.substatus)
			? this.recordId
			: undefined;
	}

	@wire(getFormalizacionGarantiasContext, { residentialLoanApplicationId: '$formalizacionRecordId' })
	wiredFormalizacion(result) {
		this.wiredFormalizacionResult = result;
		if (result?.data) {
			this.garantiasFormalizacion = (result.data.garantias || []).map((garantia) => ({
				...garantia,
				tituloRegistradoSi: garantia.tituloRegistrado === 'Sí',
				garantiaConstituidaSi: garantia.garantiaConstituida === 'Sí',
			}));
		} else {
			this.garantiasFormalizacion = [];
		}
	}

	@wire(getRecord, { recordId: '$rlaOwnerId', fields: [USER_NAME_FIELD] })
	wiredOwner(result) {
		this.wiredOwnerResult = result;
	}

	@wire(getApprovalContext, { residentialLoanApplicationId: '$recordId' })
	wiredApprovalContext(result) {
		this.wiredApprovalContextResult = result;
	}

	@wire(getPagaresContext, { residentialLoanApplicationId: '$recordId' })
	wiredPagaresContext(result) {
		this.wiredPagaresContextResult = result;
	}

	@wire(getDocumentacionContratosContext, { residentialLoanApplicationId: '$recordId' })
	wiredDocumentacionContratos(result) {
		this.wiredDocumentacionContratosResult = result;
	}

	get documentacionContratos() {
		return this.wiredDocumentacionContratosResult?.data || {};
	}

	get showEnviarDocumentacionContratos() {
		return this.status === 'En proceso' && this.substatus === 'Documentación para contratos' && this.documentacionContratos.puedeCargar === true;
	}

	get showSolicitarDocumentacionContratos() {
		return this.canGeneratePagareStep && this.canCurrentUserGeneratePagare;
	}

	get showRevisionDocumentacionContratos() {
		return this.showSolicitarDocumentacionContratos && this.documentacionContratos.documentosAprobados !== true;
	}

	get pedidoDocumentacionContratos() {
		return this.documentacionContratos.pedidoDocumentacion || '';
	}

	get showPedidoDocumentacionContratos() {
		return !!this.pedidoDocumentacionContratos && this.substatus === 'Documentación para contratos';
	}

	get showErrorDocumentacionContratos() {
		return (
			!!this.wiredDocumentacionContratosResult?.error &&
			(this.substatus === 'Documentación para contratos' || this.isSubstatusGeneracionPagares)
		);
	}

	openModalPedidoDocumentacion() {
		this.pedidoDocumentacionInput = '';
		this.showModalPedidoDocumentacion = true;
	}

	closeModalPedidoDocumentacion() {
		this.showModalPedidoDocumentacion = false;
	}

	handlePedidoDocumentacionChange(event) {
		this.pedidoDocumentacionInput = event.target.value;
	}

	async handleSolicitarDocumentacionContratos() {
		const input = this.template.querySelector('[data-pedido-documentacion]');
		if (!input?.reportValidity()) return;
		this.loading = true;
		try {
			await solicitarDocumentacionContratos({ residentialLoanApplicationId: this.recordId, pedido: this.pedidoDocumentacionInput });
			this.closeModalPedidoDocumentacion();
			await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
			await this.refreshAll();
			this.dispatchEvent(new RefreshEvent());
			this.showToast('Actualizado', 'Pedido registrado. La solicitud volvió a Documentación para contratos.', 'success');
		} catch (error) {
			this.showToast('Error', this.getErrorMessage(error, 'No se pudo solicitar documentación.'), 'error');
		} finally {
			this.loading = false;
		}
	}

	async handleEnviarDocumentacionContratos() {
		this.loading = true;
		try {
			await enviarDocumentacionContratos({ residentialLoanApplicationId: this.recordId });
			await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
			await this.refreshAll();
			this.dispatchEvent(new RefreshEvent());
			this.showToast('Actualizado', 'Documentación enviada a revisión del responsable de pagarés y contratos.', 'success');
		} catch (error) {
			this.showToast('Error', this.getErrorMessage(error, 'No se pudo enviar la documentación.'), 'error');
		} finally {
			this.loading = false;
		}
	}

	@wire(getContextoExcepcion, { residentialLoanApplicationId: '$recordId' })
	wiredExcepcionContext(result) {
		this.wiredExcepcionContextResult = result;
	}

	@wire(getPicklistValues, { recordTypeId: '$rlaRecordTypeId', fieldApiName: MOTIVOS_RECHAZO_FIELD })
	wiredMotivosRechazo({ data, error }) {
		if (data) {
			this.motivosRechazoOptions = (data.values || []).map(({ label, value }) => ({ label, value }));
		} else if (error) {
			this.motivosRechazoOptions = [];
		}
	}

	@wire(getObjectInfo, { objectApiName: FSC_GARANTIA_OBJECT })
	wiredGarantiaObjectInfo({ data }) {
		this.garantiaRecordTypeId = data?.defaultRecordTypeId;
	}

	@wire(getPicklistValues, { recordTypeId: '$garantiaRecordTypeId', fieldApiName: VEHICLE_MODEL_FIELD })
	wiredVehicleModelPicklist({ data }) {
		this.vehicleModelPicklistData = data;
		this.applyVehicleModelDependency();
	}

	get substatus() {
		return getFieldValue(this.wiredRecordResult?.data, SUBSTATUS_FIELD);
	}
	get actoNumeroPagare() {
		return getFieldValue(this.wiredRecordResult?.data, ACTO_NUMERO_PAGARE_FIELD);
	}
	get numeroFolioPagare() {
		return getFieldValue(this.wiredRecordResult?.data, NUMERO_FOLIO_PAGARE_FIELD);
	}
	get pagaresGenerados() {
		return !!getFieldValue(this.wiredRecordResult?.data, PAGARES_GENERADOS_FIELD);
	}
	get requiereActoGarantia() {
		return !!getFieldValue(this.wiredRecordResult?.data, REQUIERE_ACTO_GARANTIA_FIELD);
	}
	get actoGarantiaYaGenerado() {
		return !!getFieldValue(this.wiredRecordResult?.data, ACTO_GARANTIA_GENERADO_FIELD);
	}
	get status() {
		return getFieldValue(this.wiredRecordResult?.data, STATUS_FIELD);
	}
	get accountId() {
		return getFieldValue(this.wiredRecordResult?.data, ACCOUNT_ID_FIELD);
	}
	get ownerId() {
		return this.rlaOwnerId;
	}
	get ownerName() {
		return getFieldValue(this.wiredOwnerResult?.data, USER_NAME_FIELD) || '';
	}
	get recordTypeDeveloperName() {
		return getFieldValue(this.wiredRecordResult?.data, RECORD_TYPE_DEVELOPER_NAME_FIELD);
	}
	get isPymeRla() {
		return this.recordTypeDeveloperName === 'FSC_Solicitud_Credito_PYME';
	}

	get isConsumoRla() {
		return this.recordTypeDeveloperName === 'FSC_Solicitud_Credito_Consumo';
	}

	get isVehiculoRla() {
		return this.recordTypeDeveloperName === 'FSC_Solicitud_Credito_Vehiculo';
	}

	get isHipotecarioRla() {
		return this.recordTypeDeveloperName === 'FSC_Solicitud_Credito_Hipotecario';
	}
	get solicitudCreditoOmniSubType() {
		return SOLICITUD_CREDITO_OMNI_BY_RECORD_TYPE[this.recordTypeDeveloperName];
	}
	get resultadoListas() {
		return getFieldValue(this.wiredRecordResult?.data, RESULTADO_LISTAS_FIELD);
	}
	get mensajeValidacionListas() {
		return getFieldValue(this.wiredRecordResult?.data, ERROR_VALIDACION_LISTAS_FIELD) || 'Validación de listas pendiente.';
	}
	get resultadoBuro() {
		return getFieldValue(this.wiredRecordResult?.data, RESULTADO_BURO_FIELD);
	}

	get aplicaExcBuro() {
		return !!getFieldValue(this.wiredRecordResult?.data, APLICA_EXC_BURO_FIELD);
	}
	get solicitaExcBuro() {
		return !!getFieldValue(this.wiredRecordResult?.data, SOLICITA_EXC_BURO_FIELD);
	}

	get docCompletaAnalisis() {
		return !!getFieldValue(this.wiredRecordResult?.data, DOC_COMPLETA_ANALISIS_FIELD);
	}
	get docCompletaDesembolso() {
		return !!getFieldValue(this.wiredRecordResult?.data, DOC_COMPLETA_DESEMBOLSO_FIELD);
	}

	get aprobadoConCond() {
		return !!getFieldValue(this.wiredRecordResult?.data, APROBADO_COND_FIELD);
	}
	get debeRevisarComite() {
		return !!getFieldValue(this.wiredRecordResult?.data, DEBE_REVISAR_COMITE_FIELD);
	}
	get debeRevisarSupervisor() {
		return !!getFieldValue(this.wiredRecordResult?.data, DEBE_REVISAR_SUPERVISOR_FIELD);
	}
	get documentacionValidadaAnalista() {
		return !!getFieldValue(this.wiredRecordResult?.data, DOCUMENTACION_VALIDADA_ANALISTA_FIELD);
	}

	get monto() {
		return getFieldValue(this.wiredRecordResult?.data, MONTO_FIELD);
	}
	get plazoMeses() {
		return getFieldValue(this.wiredRecordResult?.data, PLAZO_MESES_FIELD);
	}
	get tasaInteres() {
		return getFieldValue(this.wiredRecordResult?.data, TASA_INTERES_FIELD);
	}
	get firmaCompletada() {
		return !!getFieldValue(this.wiredRecordResult?.data, FIRMA_COMPLETADA_FIELD);
	}
	get enviadoAFirmar() {
		return !!getFieldValue(this.wiredRecordResult?.data, ENVIADO_A_FIRMAR_FIELD);
	}
	get documentosFirmadosFisicamente() {
		return !!getFieldValue(this.wiredRecordResult?.data, DOCUMENTOS_FIRMADOS_FIS_FIELD);
	}
	get docIncompletaPostDesembolso() {
		return !!getFieldValue(this.wiredRecordResult?.data, DOC_INCOMPLETA_POST_DESEMBOLSO_FIELD);
	}
	get formaDeDesembolso() {
		return getFieldValue(this.wiredRecordResult?.data, FORMA_DESEMBOLSO_FIELD);
	}
	get numeroCuentaDesembolso() {
		return getFieldValue(this.wiredRecordResult?.data, NUMERO_CUENTA_DESEMBOLSO_FIELD);
	}
	get requiereModalPlanillaDesembolso() {
		return !this.formaDeDesembolso || (this.formaDeDesembolso === FORMA_DESEMBOLSO_CUENTA_AHORRO && !this.numeroCuentaDesembolso);
	}
	get isCuentaDeAhorroSeleccionada() {
		return this.formaDesembolsoSeleccionada === FORMA_DESEMBOLSO_CUENTA_AHORRO;
	}
	get isCuentaDesembolsoRequired() {
		return this.isCuentaDeAhorroSeleccionada;
	}
	get showCuentaDesembolsoSinOpciones() {
		return this.isCuentaDeAhorroSeleccionada && this.cuentaDesembolsoOptions.length === 0;
	}
	get usuarioGestionPlanilla() {
		return getFieldValue(this.wiredRecordResult?.data, USUARIO_GESTION_PLANILLA_FIELD);
	}
	get usuarioGestionPlanillaName() {
		return getFieldValue(this.wiredRecordResult?.data, USUARIO_GESTION_PLANILLA_NAME_FIELD);
	}
	get usuarioPagaresYContratos() {
		return this.wiredPagaresContextResult?.data?.assignedUserId || null;
	}
	get usuarioPagaresYContratosName() {
		return this.wiredPagaresContextResult?.data?.assignedUserName || '';
	}
	get desembolsoRealizado() {
		return !!getFieldValue(this.wiredRecordResult?.data, DESEMBOLSO_REALIZADO_FIELD);
	}
	get docIncompletaDesembolso() {
		return !!getFieldValue(this.wiredRecordResult?.data, DOC_INCOMPLETA_DESEMBOLSO_FIELD);
	}
	get flagErrorAPIPrestamos() {
		return !!getFieldValue(this.wiredRecordResult?.data, FLAG_ERROR_API_PRESTAMOS_FIELD);
	}
	get flagErrorAPIDesembolso() {
		return !!getFieldValue(this.wiredRecordResult?.data, FLAG_ERROR_API_DESEMBOLSO_FIELD);
	}
	get numeroPrestamoAbanks() {
		return getFieldValue(this.wiredRecordResult?.data, NUMERO_PRESTAMO_ABANKS_FIELD);
	}

	get isSubstatusDocumentacionDesembolsoFirmas() {
		return this.normalize(this.substatus) === this.normalize('Documentacion para desembolso y firmas');
	}

	get isSubstatusPendientePlanillaDesembolso() {
		return this.normalize(this.substatus) === this.normalize('Pendiente planilla de desembolso');
	}

	get isSubstatusGeneracionPagares() {
		return this.normalize(this.substatus) === this.normalize('Generacion de pagares y plantillas');
	}

	get approvalContext() {
		return (
			this.wiredApprovalContextResult?.data || {
				hasActiveApproval: false,
				workItemCount: 0,
				currentApproverName: '',
				currentApproverId: null,
				currentApproverType: '',
				isCurrentUserQueueMember: false,
				currentProcessDefinitionDeveloperName: '',
			}
		);
	}

	get currentApproverType() {
		return this.approvalContext?.currentApproverType || '';
	}

	get isCurrentUserQueueMember() {
		return this.approvalContext?.isCurrentUserQueueMember === true;
	}

	get hasActiveApproval() {
		return this.approvalContext?.hasActiveApproval === true;
	}

	get currentApproverName() {
		return this.approvalContext?.currentApproverName || '';
	}

	get currentApproverId() {
		return this.approvalContext?.currentApproverId || null;
	}

	get currentProcessDefinitionDeveloperName() {
		return this.approvalContext?.currentProcessDefinitionDeveloperName || '';
	}

	get isCurrentUserAssignedApprover() {
		return this.currentApproverId === USER_ID;
	}

	get isGestionPlanillasDesembolsoApproval() {
		return this.currentProcessDefinitionDeveloperName === PROCESS_GESTION_PLANILLAS_DESEMBOLSO;
	}

	get isAnalystApproval() {
		return this.currentProcessDefinitionDeveloperName === PROCESS_ANALISTA_CREDITO;
	}

	get isExceptionApproval() {
		return this.currentProcessDefinitionDeveloperName === PROCESS_EXCEPCIONES_CREDITO;
	}

	get isValidacionAbanksApproval() {
		return this.currentProcessDefinitionDeveloperName === PROCESS_VALIDACION_ABANKS;
	}

	get isBancaSeguroApproval() {
		return this.currentProcessDefinitionDeveloperName === PROCESS_BANCA_SEGURO;
	}

	get excepcionContext() {
		return (
			this.wiredExcepcionContextResult?.data || {
				excepcionId: null,
				solicitada: false,
				cantidad: 0,
				maximo: 0,
				disponibles: 0,
				limiteAlcanzado: false,
				estado: 'No aplica',
				condicion: '',
				tipo: '',
				detalle: '',
				tienePendientes: false,
				hasActiveApproval: false,
				canActOnApproval: false,
				puedeSolicitar: false,
				puedeResponderCondicion: false,
			}
		);
	}

	get showSolicitarExcepcionCredito() {
		return this.excepcionContext.puedeSolicitar === true;
	}

	get showAccionesAprobacionExcepcion() {
		return (
			this.excepcionContext.hasActiveApproval === true &&
			this.excepcionContext.canActOnApproval === true &&
			this.excepcionContext.estado === 'Pendiente' &&
			!this.excepcionContext.condicion
		);
	}

	get showRespuestaCondicionExcepcion() {
		return this.excepcionContext.puedeResponderCondicion === true;
	}

	get excepcionBloqueaAccionesOrdinarias() {
		return this.excepcionContext.tienePendientes === true;
	}

	get resumenCapacidadExcepciones() {
		const cantidad = this.excepcionContext.cantidad || 0;
		const maximo = this.excepcionContext.maximo || 0;
		if (maximo < 1) {
			return `${cantidad} excepciones registradas. La capacidad configurada no está disponible.`;
		}
		const disponibles = this.excepcionContext.disponibles ?? Math.max(0, maximo - cantidad);
		return `${cantidad} de ${maximo} excepciones registradas. Quedan ${disponibles} disponibles.`;
	}

	get tipoExcepcionOptions() {
		const tipos = [...new Set((this.opcionesExcepcion || []).map((opcion) => opcion.tipo).filter(Boolean))];
		return tipos.sort().map((tipo) => ({ label: tipo, value: tipo }));
	}

	get detalleExcepcionOptions() {
		return (this.opcionesExcepcion || [])
			.filter((opcion) => opcion.tipo === this.tipoExcepcionSeleccionado)
			.map((opcion) => ({ label: opcion.detalle, value: opcion.detalle }))
			.sort((primera, segunda) => primera.label.localeCompare(segunda.label, 'es'));
	}

	get isDetalleExcepcionDisabled() {
		return !this.tipoExcepcionSeleccionado;
	}

	get isCurrentUserGestionPlanillasApprover() {
		return this.hasActiveApproval && this.isGestionPlanillasDesembolsoApproval && this.isCurrentUserAssignedApprover;
	}

	normalize(s) {
		return (s || '')
			.trim()
			.toLowerCase()
			.replace(/á/g, 'a')
			.replace(/é/g, 'e')
			.replace(/í/g, 'i')
			.replace(/ó/g, 'o')
			.replace(/ú/g, 'u')
			.replace(/ü/g, 'u')
			.replace(/ñ/g, 'n')
			.replace(/á/g, 'a')
			.replace(/é/g, 'e')
			.replace(/í/g, 'i')
			.replace(/ó/g, 'o')
			.replace(/ú/g, 'u')
			.replace(/ü/g, 'u')
			.replace(/ñ/g, 'n');
	}

	get allowOficialOrAdmins() {
		return Boolean(TIENE_PERMISO_OFICIAL_NEGOCIO) || this.hasAdminPermission;
	}

	get allowSupervisorAnalistaOrAdmins() {
		return Boolean(TIENE_PERMISO_SUPERVISOR) || this.hasAdminPermission;
	}

	get allowComiteOrAdmins() {
		return Boolean(TIENE_PERMISO_COMITE_CREDITO) || this.hasAdminPermission;
	}

	get allowLavadoOrAdmins() {
		return Boolean(TIENE_PERMISO_PREVENCION_LAVADO_ACTIVOS) || this.hasAdminPermission;
	}

	get allowAnalistaOrAdmins() {
		return Boolean(TIENE_PERMISO_ANALISTA_CREDITO) || this.hasAdminPermission;
	}

	get allowRecepcionDocsOrAdmins() {
		return Boolean(TIENE_PERMISO_CONTROL_DOCUMENTOS) || this.hasAdminPermission;
	}

	get allowSupervisorOrAdmins() {
		return Boolean(TIENE_PERMISO_SUPERVISOR) || this.hasAdminPermission;
	}

	get allowArchivoCustodiaOrAdmins() {
		return Boolean(TIENE_PERMISO_ARCHIVO_CUSTODIA_VALORES) || this.hasAdminPermission;
	}

	get allowOnlyAdminsForReassign() {
		return this.hasAdminPermission;
	}

	get hasAdminPermission() {
		return Boolean(TIENE_PERMISO_ADMINISTRADOR);
	}

	get canFormalizeGuarantees() {
		return Boolean(TIENE_PERMISO_FORMALIZACION_CREDITOS) || this.hasAdminPermission;
	}

	get formalizacionContext() {
		return (
			this.wiredFormalizacionResult?.data || {
				tieneGarantiasAplicables: false,
				todasFormalizadas: false,
				cantidadPendientes: 0,
				garantias: [],
			}
		);
	}

	get showPreguntaFormalizacion() {
		return (
			this.canFormalizeGuarantees &&
			this.status === 'En proceso' &&
			this.substatus === SUBSTATUS_FORMALIZACION &&
			this.formalizacionContext.tieneGarantiasAplicables === true
		);
	}

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

	get formalizacionSiNoOptions() {
		return FORMALIZATION_YES_NO_OPTIONS;
	}

	get fechaGarantiaMaxima() {
		const ahora = new Date();
		const fechaLocal = new Date(ahora.getTime() - ahora.getTimezoneOffset() * 60000);
		return fechaLocal.toISOString().slice(0, 10);
	}

	get canCurrentUserCompletePlanilla() {
		return this.hasAdminPermission || (Boolean(TIENE_PERMISO_DESEMBOLSO_CREDITOS) && this.usuarioGestionPlanilla === USER_ID);
	}

	get canActOnApproval() {
		return this.hasAdminPermission || this.isCurrentUserAssignedApprover || this.isCurrentUserQueueMember;
	}

	get allowBancaSeguroOrAdmins() {
		return Boolean(TIENE_PERMISO_BANCA_SEGURO) || this.hasAdminPermission;
	}

	get canActOnCommitteeApproval() {
		return this.canActOnApproval || this.allowComiteOrAdmins;
	}

	get showEnviarRevisionSupervisor() {
		return this.showAnalystDecisionStage;
	}

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

	get showAnalystValidationStage() {
		return this.isAnalystApprovalBaseState && !this.documentacionValidadaAnalista;
	}

	get showAnalystDecisionStage() {
		return this.isAnalystApprovalBaseState && this.documentacionValidadaAnalista;
	}

	get showEdicionDocumentosAnalisis() {
		return (
			this.status === 'En proceso' &&
			this.showAnalystDecisionStage &&
			!this.excepcionBloqueaAccionesOrdinarias &&
			(!!this.solicitudCreditoOmniSubType || this.isPymeRla)
		);
	}

	get showBotonEditarCapacidadPago() {
		return this.showEdicionDocumentosAnalisis && !this.isPymeRla;
	}

	get mensajeEdicionDocumentosAnalisis() {
		return this.isPymeRla
			? 'Puede editar el informe de crédito si lo desea.'
			: 'Puede editar informe de crédito o capacidad de pago si lo desea.';
	}

	get showModalEdicionDocumentoAnalisis() {
		return !!this.documentoAnalisisEnEdicion;
	}

	get showEnviarAFirmar() {
		return this.allowOficialOrAdmins && this.substatus === 'Gestionar firmas' && this.firmaCompletada === false && this.enviadoAFirmar === false;
	}

	get showConsultarEstadoFirma() {
		return this.allowOficialOrAdmins && this.substatus === 'Gestionar firmas' && this.firmaCompletada === false && this.enviadoAFirmar === true;
	}

	get showDocDesembolso() {
		return this.allowOficialOrAdmins && this.isSubstatusDocumentacionDesembolsoFirmas && this.docCompletaDesembolso === false;
	}

	get showEnviarAArchivoYCustodia() {
		return this.allowOficialOrAdmins && this.substatus === 'Archivo y custodia' && this.docIncompletaPostDesembolso === true;
	}

	get showSolicitarExcepcionBuro() {
		return this.allowOficialOrAdmins && this.substatus === 'Rechazado por Buró';
	}

	get showReintentarListas() {
		return this.allowOficialOrAdmins && this.substatus === 'En validación PEP/Listas' && !this.resultadoListas;
	}

	get showReintentarBuro() {
		return this.allowOficialOrAdmins && this.substatus === 'En Motor Buró' && !this.resultadoBuro;
	}

	get showErrorAPIPrestamos() {
		return (
			this.flagErrorAPIPrestamos === true &&
			this.substatus === 'Creación de crédito' &&
			this.formaDeDesembolso === FORMA_DESEMBOLSO_CUENTA_AHORRO
		);
	}

	get showErrorAPIDesembolso() {
		return this.flagErrorAPIDesembolso === true && this.substatus === 'Desembolso' && this.formaDeDesembolso === FORMA_DESEMBOLSO_CUENTA_AHORRO;
	}

	get showMensajeValidacionAbanks() {
		return (
			this.hasActiveApproval &&
			this.isValidacionAbanksApproval &&
			this.substatus === 'Creación de crédito' &&
			this.formaDeDesembolso === FORMA_DESEMBOLSO_CUENTA_AHORRO &&
			!!this.numeroPrestamoAbanks
		);
	}

	get showValidacionAbanks() {
		return this.showMensajeValidacionAbanks && this.canActOnApproval;
	}

	get showRecepcionDocs() {
		return this.allowOficialOrAdmins && this.substatus === 'Recepción de documentos – Análisis' && this.docCompletaAnalisis === false;
	}

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

	get approvalLabels() {
		if (this.isBancaSeguroApproval) {
			return { mensaje: 'Aprobar', boton: 'Aprobado' };
		}
		if (this.substatus === 'En validación PEP/Listas') {
			return { mensaje: 'Aprobar', boton: 'Aprobar' };
		}

		if (this.substatus === 'Recepción de documentos – Análisis') {
			return { mensaje: 'Validar', boton: 'Validado' };
		}

		if (
			this.substatus === 'Análisis de crédito' &&
			this.docCompletaAnalisis === true &&
			this.debeRevisarComite === false &&
			this.debeRevisarSupervisor === false
		) {
			return { mensaje: 'Recomendar', boton: 'Recomendar' };
		}

		if (
			this.substatus === 'Análisis de crédito' &&
			this.docCompletaAnalisis === true &&
			this.debeRevisarComite === false &&
			this.debeRevisarSupervisor === true
		) {
			return { mensaje: 'Recomendar', boton: 'Recomendar' };
		}

		if (
			this.substatus === 'Análisis de crédito' &&
			this.docCompletaAnalisis === true &&
			this.debeRevisarComite === true &&
			this.debeRevisarSupervisor === false
		) {
			return { mensaje: 'Aprobar', boton: 'Aprobar' };
		}

		if (this.isSubstatusDocumentacionDesembolsoFirmas) {
			return { mensaje: 'Validar', boton: 'Validado' };
		}

		if (this.substatus === 'Archivo y custodia') {
			return { mensaje: 'Validar', boton: 'Validado' };
		}

		return { mensaje: 'Aprobar', boton: 'Aprobar' };
	}

	get mensajeParaAprobar() {
		return this.approvalLabels.mensaje;
	}

	get approveButtonLabel() {
		return this.approvalLabels.boton;
	}

	get rejectButtonLabel() {
		if (this.isBancaSeguroApproval) {
			return 'No aprueba';
		}
		if (this.substatus === 'En validación PEP/Listas') {
			return 'Devolver a negocio';
		}

		if (this.substatus === 'Recepción de documentos – Análisis') {
			return 'Devolver a Oficial de Negocio';
		}

		if (
			this.substatus === 'Análisis de crédito' &&
			this.docCompletaAnalisis === true &&
			this.debeRevisarComite === false &&
			this.debeRevisarSupervisor === false
		) {
			return 'Desestimar';
		}

		if (
			this.substatus === 'Análisis de crédito' &&
			this.docCompletaAnalisis === true &&
			this.debeRevisarComite === false &&
			this.debeRevisarSupervisor === true
		) {
			return 'Desestimar';
		}

		if (
			this.substatus === 'Análisis de crédito' &&
			this.docCompletaAnalisis === true &&
			this.debeRevisarComite === true &&
			this.debeRevisarSupervisor === false
		) {
			return 'Rechazar';
		}

		if (this.substatus === 'Archivo y custodia') {
			return 'Devolver a Oficial de Negocio';
		}

		return 'Rechazar';
	}

	get rejectModalTitle() {
		return this.rejectButtonLabel;
	}

	get showClienteAceptaCondicion() {
		return this.allowOficialOrAdmins && this.aprobadoConCond === true && this.substatus === 'Análisis de crédito';
	}

	get showPlanillaDesembolso() {
		return (
			this.status === 'En proceso' &&
			this.isSubstatusPendientePlanillaDesembolso &&
			this.desembolsoRealizado === false &&
			this.canCurrentUserCompletePlanilla
		);
	}

	get showGestionPlanillaAssignedBanner() {
		return this.isSubstatusPendientePlanillaDesembolso;
	}

	get showPagaresAssignedBanner() {
		return this.isSubstatusGeneracionPagares && !!this.usuarioPagaresYContratosName;
	}

	get showCreadoEnAbanks() {
		return this.contextoManual.puedeActuar && this.contextoManual.etapa === 'Creación de crédito';
	}

	get showDesembolsado() {
		return this.contextoManual.puedeActuar && this.contextoManual.etapa === 'Desembolso';
	}

	@wire(getCapturaOperacionesContext, { residentialLoanApplicationId: '$recordId' })
	wiredCapturaOperaciones(result) {
		this.wiredCapturaOperacionesResult = result;
	}

	get contextoManual() {
		return this.wiredCapturaOperacionesResult?.data || {};
	}

	get showResponsableManual() {
		return this.contextoManual.etapaManual;
	}

	get responsableManual() {
		return this.contextoManual.responsable || 'Sin asignar';
	}

	get showReasignarManual() {
		return this.hasAdminPermission && this.showResponsableManual;
	}

	get showReasignarPagares() {
		return this.allowSupervisorOrAdmins && this.showPagaresAssignedBanner;
	}

	get requiereGarantiasCaptura() {
		return this.contextoManual.requiereGarantias;
	}

	get requiereSegurosCaptura() {
		return this.contextoManual.requiereSeguros;
	}

	get disableGuardarCaptura() {
		return (
			this.loading ||
			!this.creditoConfirmado ||
			!this.numeroCaptura.trim() ||
			(this.requiereGarantiasCaptura && !this.garantiasConfirmadas) ||
			(this.requiereSegurosCaptura && !this.segurosConfirmados)
		);
	}

	get disableConfirmarDesembolsoManual() {
		return this.loading || !this.archivosAmortizacion.length || !this.archivosRecibo.length;
	}

	get isFormaDesembolsoManual() {
		return (
			this.formaDeDesembolso === FORMA_DESEMBOLSO_CHEQUE_ADMINISTRACION ||
			this.formaDeDesembolso === FORMA_DESEMBOLSO_CUENTA_AHORRO_Y_CHEQUE_ADMINISTRACION
		);
	}

	get showCompletarInformacion() {
		return (
			this.allowOficialOrAdmins &&
			this.status === 'Borrador' &&
			this.substatus === 'Completando información' &&
			!!this.solicitudCreditoOmniSubType &&
			!this.hasActiveApproval
		);
	}

	isBlankValue(value) {
		return value === null || value === undefined || !String(value).trim();
	}

	get isActoNumeroPagareMissing() {
		return this.isBlankValue(this.actoNumeroPagare);
	}

	get isNumeroFolioPagareMissing() {
		return this.isBlankValue(this.numeroFolioPagare);
	}

	get isPagareInfoMissing() {
		return this.isActoNumeroPagareMissing || this.isNumeroFolioPagareMissing;
	}

	get showGenerarPagareButton() {
		return this.canGeneratePagareStep && this.canCurrentUserGeneratePagare && this.documentacionContratos.documentosAprobados === true;
	}

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

	get disableGenerarPagareButton() {
		return this.loading;
	}

	get showGenerarPagareMessage() {
		return false;
	}

	get canGeneratePagareStep() {
		return this.status === 'En proceso' && this.isSubstatusGeneracionPagares && this.pagaresGenerados === false;
	}

	get isCurrentUserPagaresAssignee() {
		return this.usuarioPagaresYContratos === USER_ID;
	}

	get canCurrentUserGeneratePagare() {
		return this.wiredPagaresContextResult?.data?.canGeneratePagare === true;
	}

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

	get devolverModalTitle() {
		if (this.devolverContext === 'ARCHIVO_CUSTODIA') {
			return 'Enviar a Archivo y Custodia de Valores';
		}
		return this.devolverContext === 'SUPERVISOR_ANALISTA' ? 'Devolver a Analista de Crédito' : 'Devolver a Oficial de Negocio';
	}

	get devolverButtonLabel() {
		if (this.devolverContext === 'ARCHIVO_CUSTODIA') {
			return 'Enviar a Archivo y Custodia de Valores';
		}
		return this.devolverContext === 'SUPERVISOR_ANALISTA' ? 'Devolver a Analista de Crédito' : 'Devolver a Oficial de Negocio';
	}

	get showDevolverAAnalistaAction() {
		return this.condition5ApproveReject;
	}

	get devolverModalTitleSafe() {
		if (this.devolverContext === 'ARCHIVO_CUSTODIA') {
			return 'Enviar a Archivo y Custodia de Valores';
		}
		return this.devolverContext === 'SUPERVISOR_ANALISTA' ? 'Devolver a Analista de Crédito' : 'Devolver a Oficial de Negocio';
	}

	get devolverButtonLabelSafe() {
		if (this.devolverContext === 'ARCHIVO_CUSTODIA') {
			return 'Enviar a Archivo y Custodia de Valores';
		}
		return this.devolverContext === 'SUPERVISOR_ANALISTA' ? 'Devolver a Analista de Crédito' : 'Devolver a Oficial de Negocio';
	}

	get motivoDevolverLabel() {
		return this.devolverContext === 'ARCHIVO_CUSTODIA' ? 'Observaciones para archivo' : 'Motivo';
	}

	get motivoDevolverMaxLength() {
		return this.devolverContext === 'ARCHIVO_CUSTODIA' ? 2000 : 255;
	}

	get motivoDevolverHelpText() {
		return `Maximo ${this.motivoDevolverMaxLength} caracteres.`;
	}

	get condition1ApproveReject() {
		return (
			this.hasActiveApproval &&
			this.canActOnApproval &&
			this.substatus === 'En validación PEP/Listas' &&
			this.resultadoListas === 'Coincidencia' &&
			this.allowLavadoOrAdmins
		);
	}

	get condition2ApproveReject() {
		return (
			this.hasActiveApproval &&
			this.canActOnApproval &&
			this.solicitaExcBuro === true &&
			this.substatus === 'Rechazado por Buró' &&
			this.allowAnalistaOrAdmins
		);
	}

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

	get condition4ApproveReject() {
		return this.showAnalystDecisionStage;
	}

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

	get condition7ApproveReject() {
		return (
			this.hasActiveApproval &&
			this.canActOnApproval &&
			this.isSubstatusDocumentacionDesembolsoFirmas &&
			this.docCompletaDesembolso === true &&
			this.allowRecepcionDocsOrAdmins
		);
	}

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

	get condition9ApproveReject() {
		return (
			this.hasActiveApproval &&
			this.canActOnApproval &&
			this.status === 'Borrador' &&
			this.substatus === 'Completando información' &&
			this.allowOficialOrAdmins
		);
	}

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

	get showReassignButton() {
		return this.hasActiveApproval && this.allowOnlyAdminsForReassign && !this.showClienteAceptaCondicion && !this.isValidacionAbanksApproval;
	}

	get showApprovalSection() {
		return this.hasActiveApproval;
	}

	get showActiveApprovalBanner() {
		return this.showApprovalSection && !this.showClienteAceptaCondicion && !this.isValidacionAbanksApproval;
	}

	get hasActions() {
		return (
			this.showReasignarManual ||
			this.showReasignarPagares ||
			this.showEnviarDocumentacionContratos ||
			this.showEdicionDocumentosAnalisis ||
			this.showSolicitarExcepcionCredito ||
			this.showAccionesAprobacionExcepcion ||
			this.showRespuestaCondicionExcepcion ||
			this.showApprovalSection ||
			this.showAnalystValidationStage ||
			this.showEnviarRevisionSupervisor ||
			this.showEnviarAFirmar ||
			this.showConsultarEstadoFirma ||
			this.showPreguntaFormalizacion ||
			this.showFormalizarGarantiasPendientes ||
			this.showDocDesembolso ||
			this.showEnviarAArchivoYCustodia ||
			this.showSolicitarExcepcionBuro ||
			this.showReintentarListas ||
			this.showReintentarBuro ||
			this.showValidacionAbanks ||
			this.showErrorAPIPrestamos ||
			this.showErrorAPIDesembolso ||
			this.showRecepcionDocs ||
			this.showAccionesComite ||
			this.showClienteAceptaCondicion ||
			this.showPlanillaDesembolso ||
			this.showCreadoEnAbanks ||
			this.showDesembolsado ||
			this.showCompletarInformacion ||
			this.showDevolverAOficial ||
			this.showGenerarPagareButton ||
			this.showGenerarActoGarantiaButton
		);
	}

	get hasMessages() {
		return (
			this.showResponsableManual ||
			this.showEdicionDocumentosAnalisis ||
			this.showSolicitarExcepcionCredito ||
			this.showAccionesAprobacionExcepcion ||
			this.showRespuestaCondicionExcepcion ||
			this.showRecepcionDocs ||
			this.showClienteAceptaCondicion ||
			this.showDocDesembolso ||
			this.showEnviarRevisionSupervisor ||
			this.showEnviarAFirmar ||
			this.showConsultarEstadoFirma ||
			this.showPreguntaFormalizacion ||
			this.showFormalizarGarantiasPendientes ||
			this.showMensajeValidacionAbanks ||
			this.showErrorAPIPrestamos ||
			this.showErrorAPIDesembolso ||
			this.showApprovalSection ||
			this.showAnalystValidationStage ||
			this.showGestionPlanillaAssignedBanner ||
			this.showPagaresAssignedBanner ||
			this.showGenerarPagareMessage ||
			this.showCreadoEnAbanks ||
			this.showDesembolsado
		);
	}

	get showEmpty() {
		return !!this.wiredRecordResult?.data && !this.hasActions && !this.hasMessages;
	}

	get requiresChecklistApprovalValidation() {
		return this.condition3ApproveReject || this.condition4ApproveReject || this.condition7ApproveReject;
	}

	async handleValidarDocumentacionAnalista() {
		this.loading = true;
		try {
			await validarDocumentacionAnalista({ residentialLoanApplicationId: this.recordId });
			this.showToast('Actualizado', 'Documentación validada correctamente.', 'success');
			await this.refreshAll();
		} catch (e) {
			this.showToast('Advertencia', this.getErrorMessage(e, 'Debe revisar todos los documentos antes de continuar.'), 'warning');
		}
		this.loading = false;
	}

	getErrorMessage(e, defaultMessage) {
		const messages = [];
		const addMessage = (message) => {
			const normalizedMessage = typeof message === 'string' ? message.trim() : '';
			if (normalizedMessage && !messages.includes(normalizedMessage)) {
				messages.push(normalizedMessage);
			}
		};
		const addErrors = (errors) => {
			const errorList = Array.isArray(errors) ? errors : errors ? [errors] : [];
			errorList.forEach((error) => addMessage(typeof error === 'string' ? error : error?.message));
		};

		const body = e?.body;
		addErrors(Array.isArray(body) ? body : null);
		addErrors(body?.output?.errors);
		Object.values(body?.output?.fieldErrors || {}).forEach(addErrors);
		addErrors(body?.output?.pageErrors);
		addErrors(body?.pageErrors);
		addMessage(body?.message);
		addMessage(e?.message);

		return messages.length ? messages.join(' | ') : defaultMessage;
	}

	async openModalAprobacion() {
		if (this.isBancaSeguroApproval) {
			this.comentarioAprobacion = 'Aprobado por Banca Seguro';
			await this.handleAprobarProcesoActual();
			return;
		}

		if (this.requiresChecklistApprovalValidation) {
			this.loading = true;
			try {
				await validateChecklistApprovalReadiness({
					residentialLoanApplicationId: this.recordId,
				});
			} catch (e) {
				this.showToast('Advertencia', this.getErrorMessage(e, 'Debe revisar todos los documentos antes de aprobar.'), 'warning');
				this.loading = false;
				return;
			}
			this.loading = false;
		}

		this.comentarioAprobacion = '';
		this.showModalAprobacion = true;
	}

	closeModalAprobacion() {
		this.showModalAprobacion = false;
	}

	handleComentarioAprobacionChange(event) {
		this.comentarioAprobacion = event.target.value;
	}

	openModalEditarInformeCredito() {
		this.documentoAnalisisEnEdicion = 'INFORME';
	}

	openModalEditarCapacidadPago() {
		this.documentoAnalisisEnEdicion = 'CAPACIDAD';
	}

	closeModalEdicionDocumentoAnalisis() {
		this.documentoAnalisisEnEdicion = '';
	}

	async handleDocumentoAnalisisGuardado() {
		this.closeModalEdicionDocumentoAnalisis();
		await this.refreshAll();
	}

	async handleAprobarProcesoActual() {
		const comentario = (this.comentarioAprobacion || '').trim();

		if (!comentario) {
			this.showToast('Error', 'Comentario requerido.', 'error');
			return;
		}

		if (comentario.length > 255) {
			this.showToast('Error', 'Comentario máximo 255 caracteres.', 'error');
			return;
		}

		this.showModalAprobacion = false;
		this.loading = true;
		try {
			await aprobarProcesoActual({
				residentialLoanApplicationId: this.recordId,
				comentario: comentario,
			});
			this.showToast('Actualizado', 'Proceso de aprobación aprobado correctamente.', 'success');
			await this.refreshAll();
		} catch (e) {
			this.showToast('Error', this.getErrorMessage(e, 'No se pudo aprobar el proceso actual.'), 'error');
		}
		this.loading = false;
	}

	async handleRechazarProcesoActual() {
		const motivo = (this.motivoRechazo || '').trim();
		const motivoDeRechazo = (this.motivoRechazoPicklist || '').trim();
		const comentarioBancaSeguro = (this.comentarioRechazoBancaSeguro || '').trim();

		if (this.isPymeRla && !motivoDeRechazo) {
			this.showToast('Error', 'Motivo de rechazo requerido.', 'error');
			return;
		}

		if (!motivo) {
			this.showToast('Error', 'Motivo requerido.', 'error');
			return;
		}

		if (this.isBancaSeguroApproval && !comentarioBancaSeguro) {
			this.showToast('Error', 'Comentario requerido.', 'error');
			return;
		}

		if (this.isBancaSeguroApproval && comentarioBancaSeguro.length > 2000) {
			this.showToast('Error', 'Comentario máximo 2.000 caracteres.', 'error');
			return;
		}

		if (motivo.length > 255) {
			this.showToast('Error', 'Motivo máximo 255 caracteres.', 'error');
			return;
		}

		this.showModalRechazo = false;
		this.loading = true;

		try {
			if (this.isBancaSeguroApproval) {
				await rechazarBancaSeguro({
					residentialLoanApplicationId: this.recordId,
					motivo,
					comentario: comentarioBancaSeguro,
				});
			} else {
				await rechazarProcesoActual({
					residentialLoanApplicationId: this.recordId,
					motivo: motivo,
					motivoDeRechazo: this.isPymeRla ? motivoDeRechazo : null,
				});
			}
			this.showToast('Actualizado', 'Proceso de aprobación rechazado correctamente.', 'success');
			await this.refreshAll();
		} catch (e) {
			this.showToast('Error', this.getErrorMessage(e, 'No se pudo rechazar el proceso actual.'), 'error');
		}

		this.loading = false;
	}

	async openModalReasignar() {
		this.loading = true;
		try {
			const users = await getAssignableUsers();
			this.usuariosOptions = users || [];
			this.usuarioReasignadoId = '';
			this.showModalReasignar = true;
		} catch (e) {
			this.showToast('Error', this.getErrorMessage(e, 'No se pudieron cargar los usuarios.'), 'error');
		}
		this.loading = false;
	}

	closeModalReasignar() {
		this.showModalReasignar = false;
	}

	handleUsuarioReasignadoChange(event) {
		this.usuarioReasignadoId = event.detail.value;
	}

	async handleGuardarReasignacion() {
		if (!this.usuarioReasignadoId) {
			this.showToast('Error', 'Debe seleccionar un usuario.', 'error');
			return;
		}

		this.showModalReasignar = false;
		this.loading = true;
		try {
			await reasignarProcesoActual({
				residentialLoanApplicationId: this.recordId,
				newActorId: this.usuarioReasignadoId,
			});
			this.showToast('Actualizado', 'Proceso de aprobación reasignado correctamente.', 'success');
			await this.refreshAll();
		} catch (e) {
			this.showToast('Error', this.getErrorMessage(e, 'No se pudo reasignar el proceso actual.'), 'error');
		}
		this.loading = false;
	}

	async handleEnviarRevisionSupervisor() {
		this.loading = true;
		try {
			await enviarRevisionSupervisor({ residentialLoanApplicationId: this.recordId });
			this.showToast('Actualizado', 'Enviado a revisión de Supervisor.', 'success');
			await this.refreshAll();
		} catch (e) {
			this.showToast('Error', this.getErrorMessage(e, 'No se pudo enviar a revisión de Supervisor.'), 'error');
		}
		this.loading = false;
	}

	async handleReintentarListas() {
		this.loading = true;
		try {
			const rawResult = await reintentarListas({ residentialLoanApplicationId: this.recordId });
			const result = this.parseListValidationResult(rawResult);
			if (!result.success) {
				const executionState = result.apiExecuted ? 'La API fue ejecutada.' : 'La API no fue ejecutada.';
				this.showToast('Error en validación de listas', `${executionState} ${result.message || ''}`.trim(), 'error');
				await this.refreshAll();
				this.loading = false;
				return;
			}

			const warning = result.warning;
			this.showToast(
				warning ? 'Validación completada con advertencia' : 'Validación completada',
				warning || result.message || 'La validación de listas finalizó correctamente.',
				warning ? 'warning' : 'success'
			);
			await this.refreshAll();
		} catch (e) {
			this.showToast('Error', this.getErrorMessage(e, 'Error al reintentar servicio de listas'), 'error');
		}
		this.loading = false;
	}

	parseListValidationResult(rawResult) {
		try {
			return typeof rawResult === 'string' ? JSON.parse(rawResult) : rawResult || {};
		} catch (e) {
			return {
				success: false,
				apiExecuted: false,
				message: 'El procedimiento devolvió una respuesta inválida.',
			};
		}
	}

	async handleReintentarBuro() {
		this.loading = true;
		try {
			await reintentarBuro({ residentialLoanApplicationId: this.recordId });
			this.showToast('Servicio ejecutado', 'Se ejecutó el buró de crédito.', 'success');
			await this.refreshAll();
		} catch (e) {
			this.showToast('Error', this.getErrorMessage(e, 'Error al reintentar buró'), 'error');
		}
		this.loading = false;
	}

	async handleReintentarAPIPrestamos() {
		this.loading = true;
		try {
			const result = await reintentarCreacionPrestamo({ residentialLoanApplicationId: this.recordId });
			if (result?.success) {
				this.showToast('Servicio ejecutado', result.message || 'Se reintentó la creación de crédito.', 'success');
			} else {
				this.showToast('Error', result?.message || 'No se pudo reintentar la creación de crédito.', 'error');
			}
			await this.refreshAll();
		} catch (e) {
			this.showToast('Error', this.getErrorMessage(e, 'No se pudo reintentar la creación de crédito.'), 'error');
		}
		this.loading = false;
	}

	async handleValidarCreacionAbanks() {
		this.loading = true;
		try {
			const result = await validarCreacionEnAbanks({ residentialLoanApplicationId: this.recordId });
			this.showToast('Actualizado', result || 'Crédito validado en ABANKS.', 'success');
			await this.refreshAll();
		} catch (e) {
			this.showToast('Error', this.getErrorMessage(e, 'No se pudo validar la creación del crédito en ABANKS.'), 'error');
		}
		this.loading = false;
	}

	async handleReintentarAPIDesembolso() {
		this.loading = true;
		try {
			const result = await reintentarDesembolso({ residentialLoanApplicationId: this.recordId });
			this.showToast('Servicio ejecutado', result || 'Se reintentó el desembolso.', 'success');
			await this.refreshAll();
		} catch (e) {
			this.showToast('Error', this.getErrorMessage(e, 'No se pudo reintentar el desembolso.'), 'error');
		}
		this.loading = false;
	}

	validateOwnerOrAdminAction() {
		if (!this.hasAdminPermission && this.ownerId !== USER_ID) {
			this.showToast(
				'Sin autorización',
				`Solo el dueño del registro puede realizar esta acción sobre la solicitud de crédito: ${this.ownerName}`,
				'warning'
			);
			return false;
		}

		return true;
	}

	async handleEnviarAFirmar() {
		if (!this.validateOwnerOrAdminAction()) return;

		this.loading = true;
		try {
			const result = await enviarDocumentosFirmar({
				buttonName: 'Gestionar firmas',
				recordId: this.recordId,
			});

			const documentsSent = result?.documentsSent === true;
			const physicalOnly = result?.physicalOnly === true;
			if (physicalOnly) {
				this.loading = false;
				this.showModalFirmaFisica = true;
				return;
			}

			const message =
				result?.message || (documentsSent ? 'Documentos enviados a firmar.' : 'No se encontraron documentos pendientes para enviar.');

			this.showToast(
				documentsSent ? 'Proceso de firma iniciado, refresque la página en 1 minuto...' : 'Sin documentos pendientes',
				message,
				documentsSent ? 'success' : 'warning'
			);

			if (documentsSent) {
				await this.refreshAll();
			}
		} catch (e) {
			this.showToast('Error', this.getErrorMessage(e, 'No se pudo iniciar el envío a firmar.'), 'error');
		}
		// await marcarFirmaCompletaYPasarADocDesembolso({ residentialLoanApplicationId: this.recordId });
		this.loading = false;
	}

	async handleConsultarEstadoFirma() {
		this.loading = true;
		try {
			const state = await getFirmaValidationState({ residentialLoanApplicationId: this.recordId });
			if (state?.shouldAskPhysicalConfirmation === true) {
				this.loading = false;
				this.showModalFirmaFisica = true;
				return;
			}
		} catch (e) {
			this.loading = false;
			this.showToast('Error', this.getErrorMessage(e, 'No se pudo validar el estado de firmas.'), 'error');
			return;
		}

		await this.consultarEstadoFirmaDigital(false);
	}

	closeModalFirmaFisica() {
		this.showModalFirmaFisica = false;
	}

	async handleConfirmarFirmaFisica() {
		this.showModalFirmaFisica = false;
		this.loading = true;
		try {
			await marcarDocumentosFirmadosFisicamente({ residentialLoanApplicationId: this.recordId });
			this.showToast('Actualizado', 'Documentos firmados físicamente confirmados.', 'success');
			this.loading = false;
			await this.refreshAll();
		} catch (e) {
			this.showToast('Error', this.getErrorMessage(e, 'No se pudo confirmar la firma física.'), 'error');
			this.loading = false;
		}
	}

	openModalFormalizacionGarantias() {
		this.showModalFormalizacionGarantias = true;
	}

	closeModalFormalizacionGarantias() {
		if (!this.loading) {
			this.showModalFormalizacionGarantias = false;
		}
	}

	async handleDesembolsarSinRegistrarGarantias() {
		this.loading = true;
		try {
			await desembolsarSinRegistrarGarantias({ residentialLoanApplicationId: this.recordId });
			this.showToast(
				'Actualizado',
				'La solicitud pasó a Documentación para desembolso y firmas. Las garantías deberán formalizarse antes del cierre.',
				'warning'
			);
			await this.refreshAll();
			await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
			this.dispatchEvent(new RefreshEvent());
		} catch (error) {
			this.showToast('Error', this.getErrorMessage(error, 'No se pudo continuar sin registrar las garantías.'), 'error');
		} finally {
			this.loading = false;
		}
	}

	handleFormalizacionFieldChange(event) {
		const garantiaId = event.target.dataset.id;
		const fieldName = event.target.dataset.field;
		const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
		this.garantiasFormalizacion = this.garantiasFormalizacion.map((garantia) =>
			garantia.id === garantiaId ? { ...garantia, [fieldName]: value } : garantia
		);
	}

	handleTituloRegistradoChange(event) {
		const garantiaId = event.target.dataset.id;
		const tituloRegistrado = event.detail.value;
		this.garantiasFormalizacion = this.garantiasFormalizacion.map((garantia) =>
			garantia.id === garantiaId
				? {
						...garantia,
						tituloRegistrado,
						tituloRegistradoSi: tituloRegistrado === 'Sí',
						fechaFormalizacionHipotecaria: tituloRegistrado === 'Sí' ? garantia.fechaFormalizacionHipotecaria : null,
					}
				: garantia
		);
	}

	handleGarantiaConstituidaChange(event) {
		const garantiaId = event.target.dataset.id;
		const garantiaConstituida = event.detail.value;
		this.garantiasFormalizacion = this.garantiasFormalizacion.map((garantia) =>
			garantia.id === garantiaId
				? {
						...garantia,
						garantiaConstituida,
						garantiaConstituidaSi: garantiaConstituida === 'Sí',
						fechaConstitucionGarantia: garantiaConstituida === 'Sí' ? garantia.fechaConstitucionGarantia : null,
					}
				: garantia
		);
	}

	async handleGuardarFormalizacionGarantias() {
		const inputs = [...this.template.querySelectorAll('[data-formalizacion-input]')];
		const formularioValido = inputs.reduce((valido, input) => input.reportValidity() && valido, true);
		if (!formularioValido) {
			return;
		}

		this.loading = true;
		try {
			const resultado = await guardarFormalizacionGarantias({
				residentialLoanApplicationId: this.recordId,
				garantias: this.garantiasFormalizacion.map((garantia) => ({
					id: garantia.id,
					tituloRegistrado: garantia.esHipotecaria ? garantia.tituloRegistrado : null,
					fechaFormalizacionHipotecaria: garantia.fechaFormalizacionHipotecaria || null,
					garantiaConstituida: garantia.esVehiculo ? garantia.garantiaConstituida : null,
					comentarioVehiculo: garantia.comentarioVehiculo || null,
					fechaConstitucionGarantia: garantia.fechaConstitucionGarantia || null,
				})),
			});
			this.showModalFormalizacionGarantias = false;
			this.showToast(
				'Formalización guardada',
				resultado?.todasFormalizadas
					? 'Todas las garantías fueron formalizadas. La solicitud pasó a Documentación para desembolso y firmas.'
					: resultado?.subestado === 'Documentación para desembolso y firmas'
						? 'Se registró el resultado. La solicitud continúa al desembolso; los títulos no registrados y las garantías no constituidas quedan pendientes.'
						: 'Se guardaron los datos, pero existen garantías pendientes de formalización.',
				resultado?.todasFormalizadas ? 'success' : 'warning'
			);
			await this.refreshAll();
			await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
			this.dispatchEvent(new RefreshEvent());
		} catch (error) {
			this.showToast('Error', this.getErrorMessage(error, 'No se pudo guardar la formalización de garantías.'), 'error');
		} finally {
			this.loading = false;
		}
	}

	async consultarEstadoFirmaDigital(setLoading = true) {
		if (setLoading) {
			this.loading = true;
		}

		try {
			await consultarEstadoFirma({ residentialLoanApplicationId: this.recordId });
			this.showToast('Proceso iniciado', 'Consulta del estado de firma digital iniciada, refresque la página en 1 minuto...', 'success');
			await this.refreshAll();
		} catch (e) {
			this.showToast('Error', this.getErrorMessage(e, 'No se pudo consultar el estado de firma digital.'), 'error');
		}
		this.loading = false;
	}

	async handleDocDesembolsoCargadaEnviarRevision() {
		this.loading = true;
		try {
			await marcarDocCompletaDesembolso({ residentialLoanApplicationId: this.recordId });
			this.showToast('Actualizado', 'Documentación de desembolso marcada como completa.', 'success');
			await this.refreshAll();
		} catch (e) {
			this.showToast('Advertencia', this.getErrorMessage(e, 'No se pudo actualizar la documentación de desembolso.'), 'warning');
		}
		this.loading = false;
	}

	handleEnviarAArchivoYCustodia() {
		this.motivoDevolver = '';
		this.devolverContext = 'ARCHIVO_CUSTODIA';
		this.showModalDevolver = true;
	}

	async handleSolicitarExcepcionBuro() {
		this.loading = true;
		try {
			await solicitarExcepcionBuro({ residentialLoanApplicationId: this.recordId });
			this.showToast('Actualizado', 'Se solicitó excepción de buró.', 'success');
			await this.refreshAll();
		} catch (e) {
			this.showToast('Error', this.getErrorMessage(e, 'No se pudo solicitar la excepción.'), 'error');
		}
		this.loading = false;
	}

	async handleDocCargadaEnviarRevision() {
		this.loading = true;
		try {
			await marcarDocCompletaAnalisis({ residentialLoanApplicationId: this.recordId });
			this.showToast('Actualizado', 'Documentación marcada como completa para análisis.', 'success');
			await this.refreshAll();
		} catch (e) {
			console.error('Error marcarDocCompletaAnalisis', e);
			this.showToast('Advertencia', this.getErrorMessage(e, 'No se pudo actualizar la documentación.'), 'warning');
		}
		this.loading = false;
	}

	async handleAceptaCondicion() {
		this.loading = true;
		try {
			await actualizarSubestadoGeneracionPagares({ residentialLoanApplicationId: this.recordId });
			this.showToast('Actualizado', 'Subestado actualizado.', 'success');
			await this.refreshAll();
		} catch (e) {
			this.showToast('Error', this.getErrorMessage(e, 'No se pudo actualizar el subestado.'), 'error');
		}
		this.loading = false;
	}

	async handleNoAceptaCondicion() {
		this.loading = true;
		try {
			await rechazarPorCliente({ residentialLoanApplicationId: this.recordId });
			this.showToast('Actualizado', 'Solicitud marcada como rechazada por cliente.', 'success');
			await this.refreshAll();
		} catch (e) {
			this.showToast('Error', this.getErrorMessage(e, 'No se pudo actualizar la solicitud.'), 'error');
		}
		this.loading = false;
	}

	async handleGenerarPagare() {
		if (!this.canCurrentUserGeneratePagare) {
			this.showToast(
				'Sin autorización',
				'Usted no tiene autorización para realizar esta acción, solo la persona asignada o un administrador tienen permiso.',
				'warning'
			);
			return;
		}

		this.generacionSoloActoGarantia = false;
		await this.openModalDatosPagare();
	}

	async handleGenerarActoGarantia() {
		if (!this.canCurrentUserGeneratePagare) {
			this.showToast('Sin autorización', 'Solo la persona asignada o un administrador puede generar el documento.', 'warning');
			return;
		}

		this.generacionSoloActoGarantia = true;
		await this.openModalDatosPagare();
	}

	async openModalDatosPagare() {
		this.loading = true;
		try {
			const context = await getContextoGeneracion({ residentialLoanApplicationId: this.recordId });
			this.requierePagareNotarial = context?.requierePagareNotarial !== false;
			this.codigoTipoPagareGeneracion = context?.codigoTipoPagare || 'NOTARIAL';
			this.tipoPagareGeneracion = context?.tipoPagare || 'Pagaré notarial';
			this.actoNumeroPagareInput = context?.actoNumeroPagare || this.actoNumeroPagare || '';
			this.numeroFolioPagareInput = context?.numeroFolioPagare || this.numeroFolioPagare || '';
			this.numeroPrestamoPagareInput = context?.numeroPrestamoPagare || '';
			this.aplicaContratoGeneracion = context?.aplicaContrato === true;
			this.contratoDisponibleGeneracion = context?.contratoDisponible === true;
			this.generarContratoConPagareNotarial = context?.generarContratoConPagareNotarial === true;
			this.nombreContratoGeneracion = context?.nombreContrato || '';
			this.requiereActoGarantiaGeneracion = context?.requiereActoGarantia === true;
			this.actoGarantiaGenerado = context?.actoGarantiaGenerado === true;
			this.requierePignoracionGeneracion = context?.requierePignoracion === true;
			this.pignoracionGenerada = context?.pignoracionGenerada === true;
			this.erroresConfiguracionContrato = [...(context?.erroresConfiguracion || [])];
			this.erroresConfiguracionActo = [...(context?.erroresConfiguracionActo || [])];
			const contractSections = (context?.seccionesContrato || []).map((section) => ({
				...section,
				visible: true,
				campos: (section.campos || []).map((field) => this.prepareGenerationField(field, { visible: true })),
			}));
			this.seccionesGastosHipotecarios = contractSections.filter((section) =>
				(section.campos || []).some((field) => field.clave === 'gastosLegalesContratos')
			);
			this.seccionesContratoGeneracion = contractSections.filter(
				(section) => !(section.campos || []).some((field) => field.clave === 'gastosLegalesContratos')
			);
			this.seccionesPagareGeneracion = (context?.seccionesPagare || []).map((section) => ({
				...section,
				campos: (section.campos || []).map((field) => ({ ...field })),
			}));
			this.seccionesActoGarantiaGeneracion = (context?.seccionesActoGarantia || []).map((section) => ({
				...section,
				campos: (section.campos || []).map((field) => ({ ...field })),
			}));
			this.seccionesPignoracionGeneracion = (context?.seccionesPignoracion || []).map((section) => ({
				...section,
				campos: (section.campos || []).map((field) => ({ ...field })),
			}));
			this.applyVehicleModelDependency();
			this.actualizarVisibilidadCamposHipotecarios();
			this.showModalDatosPagare = true;
		} catch (error) {
			this.showToast('Error', this.getErrorMessage(error, 'No se pudieron cargar los datos de generación.'), 'error');
		} finally {
			this.loading = false;
		}
	}

	prepareGenerationField(field, additionalProperties = {}) {
		const preparedField = { ...field, ...additionalProperties };
		const nonFutureDateError = NON_FUTURE_DATE_ERROR_BY_FIELD_KEY[field.clave];
		if (nonFutureDateError) {
			preparedField.fechaMaxima = this.getTodayDateValue();
			preparedField.mensajeFechaFueraRango = nonFutureDateError;
		}
		if (field.clave === VEHICLE_MODEL_FIELD_KEY && field.esLista) {
			// Con catalogo, el servidor envia todos los modelos con su marca y aqui se filtran por la marca elegida.
			preparedField.opcionesDependientes = (field.opciones || []).filter((option) => option.controlador);
			preparedField.opciones = [];
			preparedField.deshabilitado = true;
		}
		return preparedField;
	}

	applyVehicleModelDependency() {
		const vehicleFields = this.seccionesContratoGeneracion.flatMap((section) => section.campos || []);
		const selectedBrand = vehicleFields.find((field) => field.clave === VEHICLE_BRAND_FIELD_KEY)?.valor;
		const catalogModels = vehicleFields.find((field) => field.clave === VEHICLE_MODEL_FIELD_KEY && field.esLista)?.opcionesDependientes || [];
		const usesCatalog = catalogModels.length > 0;
		const modelOptions = usesCatalog
			? catalogModels.filter((option) => option.controlador === selectedBrand).map(({ label, value }) => ({ label, value }))
			: this.getDependentPicklistOptions(this.vehicleModelPicklistData, selectedBrand);
		const hasModelSource = usesCatalog || !!this.vehicleModelPicklistData;

		this.seccionesContratoGeneracion = this.seccionesContratoGeneracion.map((section) => ({
			...section,
			campos: section.campos.map((field) => {
				if (field.clave !== VEHICLE_MODEL_FIELD_KEY || !field.esLista) {
					return field;
				}
				const modelIsValid = modelOptions.some((option) => option.value === field.valor);
				return {
					...field,
					valor: hasModelSource && !modelIsValid ? '' : field.valor,
					opciones: modelOptions,
					deshabilitado: !selectedBrand || !hasModelSource || modelOptions.length === 0,
				};
			}),
		}));
	}

	getDependentPicklistOptions(picklistData, controllingValue) {
		const controllerIndex = picklistData?.controllerValues?.[controllingValue];
		if (!Number.isInteger(controllerIndex)) {
			return [];
		}

		return (picklistData.values || [])
			.filter(({ validFor = [] }) => validFor.includes(controllerIndex))
			.map(({ label, value }) => ({ label, value }));
	}

	getTodayDateValue() {
		const today = new Date();
		const year = today.getFullYear();
		const month = String(today.getMonth() + 1).padStart(2, '0');
		const day = String(today.getDate()).padStart(2, '0');
		return `${year}-${month}-${day}`;
	}

	closeModalDatosPagare() {
		this.showModalDatosPagare = false;
		this.numeroPrestamoPagareInput = '';
		this.seccionesContratoGeneracion = [];
		this.seccionesGastosHipotecarios = [];
		this.seccionesPagareGeneracion = [];
		this.seccionesActoGarantiaGeneracion = [];
		this.seccionesPignoracionGeneracion = [];
		this.erroresConfiguracionContrato = [];
		this.erroresConfiguracionActo = [];
		this.generacionSoloActoGarantia = false;
	}

	get mostrarDatosContratoGeneracion() {
		return !this.generacionSoloActoGarantia && this.aplicaContratoGeneracion;
	}

	get mostrarGastosHipotecarios() {
		return !this.generacionSoloActoGarantia && this.isHipotecarioRla && this.seccionesGastosHipotecarios.length > 0;
	}

	get mostrarSeleccionExcepcionContrato() {
		if (this.isVehiculoRla || this.isHipotecarioRla) {
			return !this.generacionSoloActoGarantia && this.contratoDisponibleGeneracion;
		}
		return (
			!this.generacionSoloActoGarantia &&
			(this.isPymeRla || this.isConsumoRla) &&
			this.requierePagareNotarial &&
			this.contratoDisponibleGeneracion
		);
	}

	get etiquetaExcepcionContrato() {
		return this.isVehiculoRla || this.isHipotecarioRla ? 'Generar pagaré notarial como excepción' : 'Generar también el contrato como excepción';
	}

	get ayudaExcepcionContrato() {
		return this.isVehiculoRla || this.isHipotecarioRla
			? 'Si no marca esta opción, se generará el pagaré complementario.'
			: 'Por regla general, el pagaré notarial no genera contrato. Marque esta opción únicamente para aplicar la excepción.';
	}

	get mostrarSeccionPagareGeneracion() {
		return !this.generacionSoloActoGarantia;
	}

	get mostrarDatosActoGarantia() {
		return this.generacionSoloActoGarantia && this.requiereActoGarantiaGeneracion && !this.actoGarantiaGenerado;
	}

	get mostrarDatosPignoracion() {
		return !this.generacionSoloActoGarantia && this.requierePignoracionGeneracion && !this.pignoracionGenerada;
	}

	get tituloModalGeneracion() {
		return this.generacionSoloActoGarantia ? 'Datos para generar acto de garantía solidaria' : 'Datos para generar documentos';
	}

	get etiquetaBotonGeneracion() {
		return this.generacionSoloActoGarantia ? 'Guardar y generar acto' : 'Guardar y generar';
	}

	get mostrarDatosPagareNotarial() {
		return this.requierePagareNotarial;
	}

	get mostrarNumeroPrestamoPagare() {
		return false;
	}

	get mostrarSeccionesPagareGeneracion() {
		return this.seccionesPagareGeneracion.length > 0;
	}

	get tieneErroresConfiguracionContrato() {
		return this.erroresConfiguracionContrato.length > 0;
	}

	get tieneErroresConfiguracionActo() {
		return this.erroresConfiguracionActo.length > 0;
	}

	handleExcepcionContratoNotarialChange(event) {
		this.generarContratoConPagareNotarial = event.target.checked;
		if (this.isVehiculoRla || this.isHipotecarioRla) {
			this.requierePagareNotarial = this.generarContratoConPagareNotarial;
			this.codigoTipoPagareGeneracion = this.requierePagareNotarial ? 'NOTARIAL' : 'COMPLEMENTARIO';
			this.tipoPagareGeneracion = this.requierePagareNotarial ? 'Pagaré notarial' : 'Pagaré complementario';
			return;
		}
		this.aplicaContratoGeneracion = this.contratoDisponibleGeneracion && this.generarContratoConPagareNotarial;
	}

	get deshabilitarGuardarGeneracion() {
		return this.generacionSoloActoGarantia ? this.tieneErroresConfiguracionActo : this.tieneErroresConfiguracionContrato;
	}

	sanitizeDigitsOnlyInput(event) {
		const inputValue = event.detail?.value ?? event.target.value ?? '';
		const digitsOnlyValue = String(inputValue).replace(/[^0-9]/g, '');
		event.target.value = digitsOnlyValue;
		return digitsOnlyValue;
	}

	handleActoNumeroPagareChange(event) {
		this.actoNumeroPagareInput = this.sanitizeDigitsOnlyInput(event);
	}

	handleNumeroFolioPagareChange(event) {
		this.numeroFolioPagareInput = this.sanitizeDigitsOnlyInput(event);
	}

	handleNumeroPrestamoPagareChange(event) {
		this.numeroPrestamoPagareInput = event.target.value;
	}

	handleDatoContratoChange(event) {
		const fieldKey = event.target.dataset.clave;
		const fieldValue = event.detail?.value ?? event.target.value;
		if (NON_FUTURE_DATE_ERROR_BY_FIELD_KEY[fieldKey]) {
			event.target.reportValidity();
		}
		if (this.isVehiculoRla && fieldKey === 'vehiculoPropietarioGarantia') {
			this.aplicaContratoGeneracion = this.contratoDisponibleGeneracion;
		}
		if (this.isHipotecarioRla && fieldKey === 'hipotecarioPropietarioGarantia') {
			this.aplicaContratoGeneracion = this.contratoDisponibleGeneracion;
		}
		this.seccionesContratoGeneracion = this.seccionesContratoGeneracion.map((section) => ({
			...section,
			campos: section.campos.map((field) => (field.clave === fieldKey ? { ...field, valor: fieldValue } : field)),
		}));
		this.seccionesGastosHipotecarios = this.seccionesGastosHipotecarios.map((section) => ({
			...section,
			campos: section.campos.map((field) => (field.clave === fieldKey ? { ...field, valor: fieldValue } : field)),
		}));
		this.seccionesPagareGeneracion = this.seccionesPagareGeneracion.map((section) => ({
			...section,
			campos: section.campos.map((field) => (field.clave === fieldKey ? { ...field, valor: fieldValue } : field)),
		}));
		this.seccionesActoGarantiaGeneracion = this.seccionesActoGarantiaGeneracion.map((section) => ({
			...section,
			campos: section.campos.map((field) => (field.clave === fieldKey ? { ...field, valor: fieldValue } : field)),
		}));
		this.seccionesPignoracionGeneracion = this.seccionesPignoracionGeneracion.map((section) => ({
			...section,
			campos: section.campos.map((field) => (field.clave === fieldKey ? { ...field, valor: fieldValue } : field)),
		}));
		if (fieldKey === VEHICLE_BRAND_FIELD_KEY) {
			this.applyVehicleModelDependency();
		}
		if (this.isHipotecarioRla && fieldKey === 'hipotecarioTipoVendedor') {
			this.actualizarVisibilidadCamposHipotecarios(fieldValue);
		}
		if (
			fieldKey === 'vehiculoPropietarioGarantia' ||
			fieldKey === 'hipotecarioPropietarioGarantia' ||
			fieldKey === 'hipotecarioConyugeInterviniente'
		) {
			this.actualizarVisibilidadCamposHipotecarios();
		}
		if (fieldKey === 'gastosGarantiaHip2' || fieldKey === 'gastosGarantiaHip3') {
			Promise.resolve().then(() => this.validarGastosGarantiaHipotecaria(true));
		}
	}

	validarGastosGarantiaHipotecaria(mostrarError = false) {
		const campos = this.seccionesGastosHipotecarios.flatMap((section) => section.campos || []);
		const gasto2 = campos.find((field) => field.clave === 'gastosGarantiaHip2')?.valor;
		const gasto3 = campos.find((field) => field.clave === 'gastosGarantiaHip3')?.valor;
		const ambosCompletos =
			gasto2 !== null &&
			gasto2 !== undefined &&
			String(gasto2).trim() !== '' &&
			gasto3 !== null &&
			gasto3 !== undefined &&
			String(gasto3).trim() !== '';
		const mensaje = ambosCompletos ? 'Complete únicamente uno entre gastos de garantía hipotecaria 2% y 3%.' : '';
		['gastosGarantiaHip2', 'gastosGarantiaHip3'].forEach((fieldKey) => {
			const input = this.template.querySelector(`lightning-input[data-clave="${fieldKey}"]`);
			if (input) {
				input.setCustomValidity(mensaje);
				if (mostrarError || !ambosCompletos) {
					input.reportValidity();
				}
			}
		});
		return !ambosCompletos;
	}

	actualizarVisibilidadCamposHipotecarios(selectedType) {
		if (!this.isHipotecarioRla && !this.isVehiculoRla) {
			return;
		}
		const currentType =
			selectedType ||
			this.seccionesPagareGeneracion.flatMap((section) => section.campos || []).find((field) => field.clave === 'hipotecarioTipoVendedor')
				?.valor;
		const decisionFields = this.seccionesPagareGeneracion.flatMap((section) => section.campos || []);
		const currentOwner = decisionFields.find(
			(field) => field.clave === (this.isVehiculoRla ? 'vehiculoPropietarioGarantia' : 'hipotecarioPropietarioGarantia')
		)?.valor;
		const currentSpouse = decisionFields.find((field) => field.clave === 'hipotecarioConyugeInterviniente')?.valor;
		this.seccionesContratoGeneracion = this.seccionesContratoGeneracion.map((section) => {
			const campos = section.campos.map((field) => {
				const visibleBySeller = !field.mostrarParaTipoVendedor || field.mostrarParaTipoVendedor === currentType;
				const visibleByOwner = !field.mostrarParaPropietarioGarantia || field.mostrarParaPropietarioGarantia === currentOwner;
				const visibleBySpouse = !field.mostrarParaConyuge || field.mostrarParaConyuge === currentSpouse;
				const visible = visibleBySeller && visibleByOwner && visibleBySpouse;
				const conditional = field.mostrarParaTipoVendedor || field.mostrarParaPropietarioGarantia || field.mostrarParaConyuge;
				return {
					...field,
					visible,
					requerido: conditional ? visible : field.requerido,
				};
			});
			return { ...section, campos, visible: campos.some((field) => field.visible) };
		});
	}

	async handleGuardarDatosPagareYGenerar() {
		const actoNumeroPagare = (this.actoNumeroPagareInput || '').trim();
		const numeroFolioPagare = (this.numeroFolioPagareInput || '').trim();
		const numeroPrestamoPagare = (this.numeroPrestamoPagareInput || '').trim();

		if (!this.generacionSoloActoGarantia && this.requierePagareNotarial && (!actoNumeroPagare || !numeroFolioPagare)) {
			this.showToast('Error', 'Debe completar los datos obligatorios del pagaré.', 'error');
			return;
		}
		const pagareNumbersAreValid = [actoNumeroPagare, numeroFolioPagare].every((value) => /^[0-9]+$/.test(value));
		if (!this.generacionSoloActoGarantia && this.requierePagareNotarial && !pagareNumbersAreValid) {
			this.showToast('Error', 'Acto número pagaré y Número de folio pagaré solo permiten números del 0 al 9.', 'error');
			return;
		}
		if (!this.generacionSoloActoGarantia && this.mostrarNumeroPrestamoPagare && !numeroPrestamoPagare) {
			this.showToast('Error', 'Debe completar el número de préstamo del pagaré.', 'error');
			return;
		}
		const nonFutureDateInputsAreValid = Object.keys(NON_FUTURE_DATE_ERROR_BY_FIELD_KEY).every((fieldKey) => {
			const input = this.template.querySelector(`lightning-input[data-clave="${fieldKey}"]`);
			return !input || input.reportValidity();
		});
		if (!nonFutureDateInputsAreValid) {
			return;
		}
		const numericInputsAreValid = [...this.template.querySelectorAll('lightning-input[type="number"]')].every((input) => input.reportValidity());
		if (!numericInputsAreValid || !this.validarGastosGarantiaHipotecaria(true)) {
			return;
		}

		const datosContrato = {};
		const camposFaltantes = [];
		const seccionesDocumento = [
			...(!this.generacionSoloActoGarantia ? this.seccionesPagareGeneracion : []),
			...(!this.generacionSoloActoGarantia && this.aplicaContratoGeneracion ? this.seccionesContratoGeneracion : []),
			...(!this.generacionSoloActoGarantia ? this.seccionesGastosHipotecarios : []),
			...(this.mostrarDatosActoGarantia ? this.seccionesActoGarantiaGeneracion : []),
			...(this.mostrarDatosPignoracion ? this.seccionesPignoracionGeneracion : []),
		];
		if (seccionesDocumento.length > 0) {
			seccionesDocumento.forEach((section) => {
				section.campos.forEach((field) => {
					const fieldValue = field.valor === null || field.valor === undefined ? '' : String(field.valor).trim();
					datosContrato[field.clave] = fieldValue;
					if (field.requerido && !fieldValue) {
						camposFaltantes.push(field.etiqueta);
					}
				});
			});
		}

		if (camposFaltantes.length > 0) {
			this.showToast('Error', `Debe completar: ${camposFaltantes.join(', ')}.`, 'error');
			return;
		}
		const erroresConfiguracion = this.generacionSoloActoGarantia ? this.erroresConfiguracionActo : this.erroresConfiguracionContrato;
		if (erroresConfiguracion.length > 0) {
			this.showToast('Error', erroresConfiguracion.join(' '), 'error');
			return;
		}

		this.showModalDatosPagare = false;
		this.loading = true;
		try {
			await guardarDatosYPrepararGeneracion({
				residentialLoanApplicationId: this.recordId,
				actoNumeroPagare,
				numeroFolioPagare,
				numeroPrestamoPagare,
				generarContratoConPagareNotarial: this.generarContratoConPagareNotarial,
				generarSoloActoGarantia: this.generacionSoloActoGarantia,
				datosContratoJson: JSON.stringify(datosContrato),
			});
			if (this.mostrarDatosActoGarantia) {
				await generarActoGarantiaSolidaria({ residentialLoanApplicationId: this.recordId });
			}
			if (!this.generacionSoloActoGarantia) {
				await generarPagare({ residentialLoanApplicationId: this.recordId });
			}
			this.showToast(
				'Actualizado',
				this.generacionSoloActoGarantia ? 'Acto de garantía solidaria generado correctamente.' : 'Documentos generados correctamente.',
				'success'
			);
			await this.refreshAll();
		} catch (e) {
			this.showToast('Error', this.getErrorMessage(e, 'No se pudo generar el pagare.'), 'error');
		}
		this.loading = false;
	}

	handlePlanillaDesembolsoLegacy() {
		if (!this.formaDeDesembolso) {
			this.showToast('Advertencia', 'Debe completar la forma de desembolso, en la sección datos del crédito', 'warning');
			return;
		}

		const url =
			'/lightning/page/omnistudio/omniscript' +
			'?omniscript__type=FSC' +
			'&omniscript__subType=PlanillaDesembolso' +
			'&omniscript__language=Spanish' +
			'&omniscript__theme=lightning' +
			'&omniscript__tabIcon=custom:custom18' +
			'&omniscript__tabLabel=FSC_PlanillaDesembolso' +
			'&omniscript__ContextId=' +
			this.recordId;

		this[NavigationMixin.Navigate]({
			type: 'standard__webPage',
			attributes: { url: url },
		});
	}

	navigateToPlanillaDesembolso() {
		const url =
			'/lightning/page/omnistudio/omniscript' +
			'?omniscript__type=FSC' +
			'&omniscript__subType=PlanillaDesembolso' +
			'&omniscript__language=Spanish' +
			'&omniscript__theme=lightning' +
			'&omniscript__tabIcon=custom:custom18' +
			'&omniscript__tabLabel=FSC_PlanillaDesembolso' +
			'&omniscript__ContextId=' +
			this.recordId;

		this[NavigationMixin.Navigate]({
			type: 'standard__webPage',
			attributes: { url: url },
		});
	}

	async handlePlanillaDesembolso() {
		if (!this.canCurrentUserCompletePlanilla) {
			this.showToast(
				'Sin autorización',
				'Usted no tiene autorización para realizar esta acción, solo la persona asignada o el administrador tienen permiso.',
				'warning'
			);
			return;
		}

		if (!this.requiereModalPlanillaDesembolso) {
			this.navigateToPlanillaDesembolso();
			return;
		}

		this.loading = true;
		try {
			const [formaDesembolsoOptions, cuentaDesembolsoOptions] = await Promise.all([
				getFormaDesembolsoOptions(),
				getCuentasDesembolsoOptions({ residentialLoanApplicationId: this.recordId }),
			]);
			this.formaDesembolsoOptions = formaDesembolsoOptions;
			this.cuentaDesembolsoOptions = cuentaDesembolsoOptions;
			this.formaDesembolsoSeleccionada = this.formaDeDesembolso || '';
			this.cuentaDesembolsoSeleccionada = '';
			this.showModalPlanillaDesembolso = true;
		} catch (e) {
			this.showToast('Error', this.getErrorMessage(e, 'No se pudieron cargar las opciones de desembolso.'), 'error');
		}
		this.loading = false;
	}

	closeModalPlanillaDesembolso() {
		this.showModalPlanillaDesembolso = false;
	}

	handleFormaDesembolsoChange(event) {
		this.formaDesembolsoSeleccionada = event.detail.value;
		if (!this.isCuentaDeAhorroSeleccionada) {
			this.cuentaDesembolsoSeleccionada = '';
		}
	}

	handleCuentaDesembolsoChange(event) {
		this.cuentaDesembolsoSeleccionada = event.detail.value;
	}

	async handleGuardarFormaDesembolsoYContinuar() {
		if (!this.formaDesembolsoSeleccionada) {
			this.showToast('Error', 'Forma de desembolso requerida.', 'error');
			return;
		}
		if (this.isCuentaDeAhorroSeleccionada && !this.cuentaDesembolsoSeleccionada) {
			this.showToast('Error', 'Cuenta de desembolso requerida.', 'error');
			return;
		}

		this.showModalPlanillaDesembolso = false;
		this.loading = true;
		try {
			await guardarFormaDesembolsoGestionPlanillas({
				residentialLoanApplicationId: this.recordId,
				formaDeDesembolso: this.formaDesembolsoSeleccionada,
				financialAccountId: this.isCuentaDeAhorroSeleccionada ? this.cuentaDesembolsoSeleccionada : null,
			});
			this.showToast('Actualizado', 'Forma de desembolso guardada correctamente.', 'success');
			await this.refreshAll();
			this.navigateToPlanillaDesembolso();
		} catch (e) {
			this.showToast('Error', this.getErrorMessage(e, 'No se pudo guardar la forma de desembolso.'), 'error');
		}
		this.loading = false;
	}

	async handleMarcarCreadoEnAbanks() {
		if (this.loading) return;
		this.loading = true;
		try {
			await refreshApex(this.wiredCapturaOperacionesResult);
			if (!this.showCreadoEnAbanks) throw new Error('La acción ya no está disponible para este usuario.');
			this.creditoConfirmado = false;
			this.garantiasConfirmadas = false;
			this.segurosConfirmados = false;
			this.numeroCaptura = this.contextoManual.numeroPrestamo || '';
			this.showModalCaptura = true;
		} catch (e) {
			this.showToast('Error', this.getErrorMessage(e, 'No se pudo abrir la captura.'), 'error');
		}
		this.loading = false;
	}

	async handleMarcarDesembolsado() {
		if (this.loading) return;
		this.loading = true;
		try {
			await refreshApex(this.wiredCapturaOperacionesResult);
			if (!this.showDesembolsado) throw new Error('La acción ya no está disponible para este usuario.');
			this.showModalDesembolsoManual = true;
		} catch (e) {
			this.showToast('Error', this.getErrorMessage(e, 'No se pudo abrir el desembolso.'), 'error');
		}
		this.loading = false;
	}

	handleCapturaChange(event) {
		const campo = event.target.dataset.campo;
		if (campo === 'numeroCaptura') this.numeroCaptura = event.target.value;
		else if (campo === 'creditoConfirmado') this.creditoConfirmado = event.target.checked;
		else if (campo === 'garantiasConfirmadas') this.garantiasConfirmadas = event.target.checked;
		else if (campo === 'segurosConfirmados') this.segurosConfirmados = event.target.checked;
	}

	closeModalCaptura() {
		if (!this.loading) this.showModalCaptura = false;
	}

	async handleGuardarCaptura() {
		if (this.disableGuardarCaptura) return;
		this.loading = true;
		try {
			await guardarCapturaAbanks({
				residentialLoanApplicationId: this.recordId,
				numeroPrestamo: this.numeroCaptura,
				credito: this.creditoConfirmado,
				garantias: this.garantiasConfirmadas,
				seguros: this.segurosConfirmados,
			});
			this.showModalCaptura = false;
			this.showToast('Actualizado', 'Captura guardada. La solicitud pasó a Desembolso.', 'success');
			await this.actualizarEtapaManual();
		} catch (e) {
			this.showToast('Error', this.getErrorMessage(e, 'No se pudo guardar la captura.'), 'error');
			await refreshApex(this.wiredCapturaOperacionesResult);
		} finally {
			this.loading = false;
		}
	}

	handleArchivosDesembolso(event) {
		const archivos = event.detail.files.map((archivo) => ({ id: archivo.documentId, nombre: archivo.name }));
		if (event.target.dataset.tipo === 'amortizacion') this.archivosAmortizacion = [...this.archivosAmortizacion, ...archivos];
		else this.archivosRecibo = [...this.archivosRecibo, ...archivos];
	}

	async handleQuitarArchivoDesembolso(event) {
		if (this.loading) return;
		const documentoId = event.currentTarget.dataset.id;
		this.loading = true;
		try {
			await descartarArchivosDesembolso({ documentosIds: [documentoId] });
			this.archivosAmortizacion = this.archivosAmortizacion.filter((archivo) => archivo.id !== documentoId);
			this.archivosRecibo = this.archivosRecibo.filter((archivo) => archivo.id !== documentoId);
		} catch (e) {
			this.showToast('Error', this.getErrorMessage(e, 'No se pudo quitar el archivo.'), 'error');
		} finally {
			this.loading = false;
		}
	}

	async closeModalDesembolsoManual() {
		if (this.loading) return;
		this.loading = true;
		try {
			await descartarArchivosDesembolso({ documentosIds: [...this.archivosAmortizacion, ...this.archivosRecibo].map((archivo) => archivo.id) });
			this.archivosAmortizacion = [];
			this.archivosRecibo = [];
			this.showModalDesembolsoManual = false;
		} catch (e) {
			this.showToast('Error', this.getErrorMessage(e, 'No se pudieron descartar los archivos.'), 'error');
		} finally {
			this.loading = false;
		}
	}

	async handleConfirmarDesembolsoManual() {
		if (this.disableConfirmarDesembolsoManual) return;
		this.loading = true;
		try {
			await confirmarDesembolsoManual({
				residentialLoanApplicationId: this.recordId,
				amortizacion: this.archivosAmortizacion.map((archivo) => archivo.id),
				recibos: this.archivosRecibo.map((archivo) => archivo.id),
			});
			this.archivosAmortizacion = [];
			this.archivosRecibo = [];
			this.showModalDesembolsoManual = false;
			this.showToast('Actualizado', 'Archivos guardados. La solicitud pasó a Archivo y custodia.', 'success');
			await this.actualizarEtapaManual();
		} catch (e) {
			this.showToast('Error', this.getErrorMessage(e, 'No se pudo confirmar el desembolso.'), 'error');
		} finally {
			this.loading = false;
		}
	}

	async handleReasignarManual() {
		if (this.loading) return;
		this.loading = true;
		try {
			await refreshApex(this.wiredCapturaOperacionesResult);
			this.reasignandoPagares = false;
			this.etapaReasignacionManual = this.contextoManual.etapa;
			this.usuariosManuales = await getUsuariosCapturaOperaciones({ residentialLoanApplicationId: this.recordId });
			this.usuarioManualSeleccionado = null;
			this.showModalReasignacionManual = true;
		} catch (e) {
			this.showToast('Error', this.getErrorMessage(e, 'No se pudieron consultar los usuarios de la cola.'), 'error');
		} finally {
			this.loading = false;
		}
	}

	async handleReasignarPagares() {
		if (this.loading) return;
		this.loading = true;
		try {
			this.reasignandoPagares = true;
			this.usuariosManuales = await getUsuariosPagares({ residentialLoanApplicationId: this.recordId });
			this.usuarioManualSeleccionado = null;
			this.showModalReasignacionManual = true;
		} catch (e) {
			this.showToast('Error', this.getErrorMessage(e, 'No se pudieron consultar los usuarios de la cola.'), 'error');
		} finally {
			this.loading = false;
		}
	}

	handleUsuarioManualChange(event) {
		this.usuarioManualSeleccionado = event.detail.value;
	}

	closeModalReasignacionManual() {
		if (!this.loading) this.showModalReasignacionManual = false;
	}

	async handleGuardarReasignacionManual() {
		if (this.loading || !this.template.querySelector('[data-usuario-manual]').reportValidity()) return;
		this.loading = true;
		try {
			if (this.reasignandoPagares) {
				await reasignarUsuarioPagares({
					residentialLoanApplicationId: this.recordId,
					usuarioId: this.usuarioManualSeleccionado,
				});
			} else {
				await reasignarCapturaOperaciones({
					residentialLoanApplicationId: this.recordId,
					usuarioId: this.usuarioManualSeleccionado,
					etapa: this.etapaReasignacionManual,
				});
			}
			this.showModalReasignacionManual = false;
			this.showToast('Actualizado', 'Responsable reasignado.', 'success');
			await this.actualizarEtapaManual();
		} catch (e) {
			this.showToast('Error', this.getErrorMessage(e, 'No se pudo reasignar la solicitud.'), 'error');
		} finally {
			this.loading = false;
		}
	}

	async actualizarEtapaManual() {
		await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
		await this.refreshAll();
		this.dispatchEvent(new RefreshEvent());
	}

	handleCompletarInformacion() {
		const omniSubType = this.solicitudCreditoOmniSubType;

		if (!omniSubType) {
			this.showToast('Error', 'No se encontro un OmniScript para el tipo de solicitud.', 'error');
			return;
		}

		const url =
			'/lightning/page/omnistudio/omniscript' +
			'?omniscript__type=FSC' +
			'&omniscript__subType=' +
			omniSubType +
			'&omniscript__language=Spanish' +
			'&omniscript__theme=lightning' +
			'&omniscript__tabIcon=custom:custom18' +
			'&omniscript__tabLabel=FSC_' +
			omniSubType +
			'&c__ContextId=' +
			this.accountId +
			'&c__AvanzarPrimerStep=true';

		this[NavigationMixin.Navigate]({
			type: 'standard__webPage',
			attributes: { url: url },
		});
	}

	openModalCondiciones() {
		this.montoAprobado = getFieldValue(this.wiredRecordResult?.data, MONTO_APROBADO_FIELD) ?? null;
		this.plazoAprobado = getFieldValue(this.wiredRecordResult?.data, PLAZO_MESES_APROBADO_FIELD) ?? null;
		this.tasaAprobada = getFieldValue(this.wiredRecordResult?.data, TASA_INTERES_APROBADA_FIELD) ?? null;
		this.otrasCondicionesComite = getFieldValue(this.wiredRecordResult?.data, OTRAS_CONDICIONES_COMITE_FIELD) ?? '';
		this.showModalCondiciones = true;
	}

	closeModalCondiciones() {
		this.showModalCondiciones = false;
	}

	handleMontoAprobadoChange(e) {
		this.montoAprobado = e.target.value;
	}
	handlePlazoAprobadoChange(e) {
		this.plazoAprobado = e.target.value;
		e.target.reportValidity();
	}

	get maxApprovedLoanTermMonths() {
		return this.isConsumoRla || this.isVehiculoRla ? Number(getFieldValue(this.wiredRecordResult?.data, MAX_LOAN_TERM_FIELD)) || 0 : 999;
	}

	get approvedLoanTermPolicyMessage() {
		if (!(this.isConsumoRla || this.isVehiculoRla) || this.maxApprovedLoanTermMonths > 0) {
			return '';
		}
		if (getFieldValue(this.wiredRecordResult?.data, MAX_LOAN_TERM_FIELD) === undefined) {
			return 'No se pudo obtener el plazo máximo permitido. Revise el acceso al campo o espere a que cargue la solicitud.';
		}
		return this.isVehiculoRla
			? 'No hay un vehículo con antigüedad admitida o la configuración de plazos no es válida. Revise las garantías.'
			: 'La configuración del plazo de consumo no es válida.';
	}

	get approvedLoanTermOverflowMessage() {
		return this.approvedLoanTermPolicyMessage || `El plazo aprobado no puede superar ${this.maxApprovedLoanTermMonths} meses.`;
	}
	handleTasaAprobadaChange(e) {
		const sanitizedValue = this.sanitizeTasaAprobada(e.target.value);
		e.target.value = sanitizedValue;
		this.tasaAprobada = sanitizedValue;
	}
	handleOtrasCondicionesComiteChange(e) {
		this.otrasCondicionesComite = e.target.value;
	}

	sanitizeTasaAprobada(value) {
		const valueWithoutCommas = String(value ?? '').replace(/,/g, '');
		const onlyValidCharacters = valueWithoutCommas.replace(/[^0-9.]/g, '');
		const [integerPart = '', ...decimalParts] = onlyValidCharacters.split('.');
		const integerPartLimited = integerPart.slice(0, 2);

		if (!onlyValidCharacters.includes('.')) {
			return integerPartLimited;
		}

		const decimalPartLimited = decimalParts.join('').slice(0, 2);
		return `${integerPartLimited}.${decimalPartLimited}`;
	}

	get disableGuardarCondicionesButton() {
		return !!this.approvedLoanTermPolicyMessage || [this.montoAprobado, this.plazoAprobado, this.tasaAprobada].some(
			(value) => value === null || value === undefined || String(value).trim() === ''
		);
	}

	validateCondiciones() {
		if (this.approvedLoanTermPolicyMessage) {
			this.showToast('Error', this.approvedLoanTermPolicyMessage, 'error');
			return false;
		}
		const montoStr = String(this.montoAprobado ?? '').trim();
		const plazoStr = String(this.plazoAprobado ?? '').trim();
		const tasaStr = String(this.tasaAprobada ?? '').trim();
		if (!montoStr || !plazoStr || !tasaStr) {
			this.showToast('Error', 'Monto, plazo y tasa aprobados son obligatorios.', 'error');
			return false;
		}
		if (!/^\d{1,3}$/.test(plazoStr)) {
			this.showToast('Error', 'Plazo aprobado debe ser un número entero de máximo 3 dígitos.', 'error');
			return false;
		}
		if (Number(plazoStr) > this.maxApprovedLoanTermMonths) {
			this.template.querySelector('[data-approved-loan-term]')?.reportValidity();
			this.showToast('Error', this.approvedLoanTermOverflowMessage, 'error');
			return false;
		}
		if (tasaStr && !/^\d{1,2}(\.\d{1,2})?$/.test(tasaStr)) {
			this.showToast('Error', 'Tasa aprobada debe tener máximo 2 dígitos enteros y 2 decimales separados por punto.', 'error');
			return false;
		}
		if ((this.otrasCondicionesComite || '').length > 2000) {
			this.showToast('Error', 'Otras condiciones máximo 2000 caracteres.', 'error');
			return false;
		}
		return true;
	}

	async handleGuardarCondiciones() {
		if (!this.validateCondiciones()) return;
		this.showModalCondiciones = false;
		this.loading = true;
		try {
			await aprobarConCondicion({
				residentialLoanApplicationId: this.recordId,
				montoAprobado: this.montoAprobado ? Number(this.montoAprobado) : null,
				plazoMesesAprobado: this.plazoAprobado ? Number(this.plazoAprobado) : null,
				tasaInteresAprobada: this.tasaAprobada ? Number(this.tasaAprobada) : null,
				otrasCondicionesComite: this.otrasCondicionesComite || null,
			});

			this.showToast('Actualizado', 'Aprobado con condición.', 'success');
			await this.refreshAll();
		} catch (e) {
			this.showToast('Error', this.getErrorMessage(e, 'No se pudo aprobar con condición.'), 'error');
			console.log('error: ', JSON.stringify(e));
		}
		this.loading = false;
	}

	openModalDevolver() {
		this.motivoDevolver = '';
		this.devolverContext = 'ANALISIS';
		this.showModalDevolver = true;
	}

	openModalDevolverAAnalista() {
		this.motivoDevolver = '';
		this.devolverContext = 'SUPERVISOR_ANALISTA';
		this.showModalDevolver = true;
	}

	closeModalDevolver() {
		this.showModalDevolver = false;
	}

	handleMotivoChange(e) {
		this.motivoDevolver = e.target.value;
	}

	openModalRechazo() {
		this.motivoRechazo = '';
		this.motivoRechazoPicklist = '';
		this.comentarioRechazoBancaSeguro = '';
		this.showModalRechazo = true;
	}

	closeModalRechazo() {
		this.showModalRechazo = false;
	}

	handleMotivoRechazoChange(event) {
		this.motivoRechazo = event.target.value;
	}

	handleMotivoRechazoPicklistChange(event) {
		this.motivoRechazoPicklist = event.detail.value;
	}

	handleComentarioRechazoBancaSeguroChange(event) {
		this.comentarioRechazoBancaSeguro = event.target.value;
	}

	async handleGuardarDevolver() {
		const motivo = (this.motivoDevolver || '').trim();
		const maxLength = this.motivoDevolverMaxLength;
		if (!motivo) {
			this.showToast('Error', 'Motivo requerido.', 'error');
			return;
		}
		if (motivo.length > maxLength) {
			this.showToast('Error', `Motivo máximo ${maxLength} caracteres.`, 'error');
			return;
		}

		this.showModalDevolver = false;
		this.loading = true;

		try {
			if (this.devolverContext === 'ANALISIS') {
				await devolverAOficial({
					residentialLoanApplicationId: this.recordId,
					motivo: motivo,
				});
				this.showToast('Actualizado', 'Solicitud devuelta a Oficial de Negocio.', 'success');
			} else if (this.devolverContext === 'SUPERVISOR_ANALISTA') {
				await devolverAAnalista({
					residentialLoanApplicationId: this.recordId,
					motivo: motivo,
				});
				this.showToast('Actualizado', 'Solicitud devuelta a Analista de Crédito.', 'success');
			} else if (this.devolverContext === 'ARCHIVO_CUSTODIA') {
				await enviarAArchivoYCustodia({
					residentialLoanApplicationId: this.recordId,
					motivo: motivo,
				});
				this.showToast('Actualizado', 'Enviado a archivo y custodia de valores.', 'success');
			}
			await this.refreshAll();
		} catch (e) {
			const defaultMessage =
				this.devolverContext === 'ARCHIVO_CUSTODIA'
					? 'No se pudo enviar a archivo y custodia de valores.'
					: 'No se pudo devolver la solicitud.';
			this.showToast('Error', this.getErrorMessage(e, defaultMessage), 'error');
		}

		this.loading = false;
	}

	async openModalSolicitarExcepcionCredito() {
		this.loading = true;
		try {
			this.opcionesExcepcion = (await getOpcionesExcepcion()) || [];
			this.tipoExcepcionSeleccionado = '';
			this.detalleExcepcionSeleccionado = '';
			this.descripcionExcepcion = '';
			this.showModalSolicitarExcepcionCredito = true;
		} catch (error) {
			this.showToast('Error', this.getErrorMessage(error, 'No se pudo cargar el catálogo de excepciones.'), 'error');
		} finally {
			this.loading = false;
		}
	}

	closeModalSolicitarExcepcionCredito() {
		this.showModalSolicitarExcepcionCredito = false;
	}

	handleTipoExcepcionChange(event) {
		this.tipoExcepcionSeleccionado = event.detail.value;
		this.detalleExcepcionSeleccionado = '';
	}

	handleDetalleExcepcionChange(event) {
		this.detalleExcepcionSeleccionado = event.detail.value;
	}

	handleDescripcionExcepcionChange(event) {
		this.descripcionExcepcion = event.target.value;
	}

	async handleGuardarSolicitudExcepcion() {
		const descripcion = (this.descripcionExcepcion || '').trim();
		if (!this.tipoExcepcionSeleccionado || !this.detalleExcepcionSeleccionado || !descripcion) {
			this.showToast('Error', 'Tipo, detalle y descripción son obligatorios.', 'error');
			return;
		}

		this.showModalSolicitarExcepcionCredito = false;
		this.loading = true;
		try {
			await solicitarExcepcionCredito({
				residentialLoanApplicationId: this.recordId,
				tipo: this.tipoExcepcionSeleccionado,
				detalle: this.detalleExcepcionSeleccionado,
				descripcion,
			});
			this.showToast('Excepción solicitada', 'La excepción fue enviada a aprobación.', 'success');
			await this.refreshAll();
		} catch (error) {
			this.showToast('Error', this.getErrorMessage(error, 'No se pudo solicitar la excepción.'), 'error');
		} finally {
			this.loading = false;
		}
	}

	async handleAprobarExcepcionCredito() {
		this.loading = true;
		try {
			await aprobarExcepcionCredito({ excepcionId: this.excepcionContext.excepcionId });
			this.showToast('Actualizado', 'La decisión de aprobación fue registrada.', 'success');
			await this.refreshAll();
		} catch (error) {
			this.showToast('Error', this.getErrorMessage(error, 'No se pudo aprobar la excepción.'), 'error');
		} finally {
			this.loading = false;
		}
	}

	openModalCondicionExcepcion() {
		this.condicionExcepcionInput = '';
		this.showModalCondicionExcepcion = true;
	}

	closeModalCondicionExcepcion() {
		this.showModalCondicionExcepcion = false;
	}

	handleCondicionExcepcionChange(event) {
		this.condicionExcepcionInput = event.target.value;
	}

	async handleAprobarExcepcionConCondicion() {
		const condicion = (this.condicionExcepcionInput || '').trim();
		if (!condicion) {
			this.showToast('Error', 'Condición requerida.', 'error');
			return;
		}

		this.showModalCondicionExcepcion = false;
		this.loading = true;
		try {
			await aprobarExcepcionConCondicion({
				excepcionId: this.excepcionContext.excepcionId,
				condicion,
			});
			this.showToast('Actualizado', 'La excepción quedó pendiente de respuesta del cliente.', 'success');
			await this.refreshAll();
		} catch (error) {
			this.showToast('Error', this.getErrorMessage(error, 'No se pudo aprobar con condición.'), 'error');
		} finally {
			this.loading = false;
		}
	}

	openModalRechazoExcepcion() {
		this.motivoRechazoExcepcion = '';
		this.showModalRechazoExcepcion = true;
	}

	closeModalRechazoExcepcion() {
		this.showModalRechazoExcepcion = false;
	}

	handleMotivoRechazoExcepcionChange(event) {
		this.motivoRechazoExcepcion = event.target.value;
	}

	async handleRechazarExcepcionCredito() {
		const motivo = (this.motivoRechazoExcepcion || '').trim();
		if (!motivo) {
			this.showToast('Error', 'Motivo requerido.', 'error');
			return;
		}
		if (motivo.length > 255) {
			this.showToast('Error', 'Motivo máximo 255 caracteres.', 'error');
			return;
		}

		this.showModalRechazoExcepcion = false;
		this.loading = true;
		try {
			await rechazarExcepcionCredito({
				excepcionId: this.excepcionContext.excepcionId,
				motivo,
			});
			this.showToast('Actualizado', 'La excepción fue rechazada y el crédito se cerró como perdido.', 'success');
			await this.refreshAll();
		} catch (error) {
			this.showToast('Error', this.getErrorMessage(error, 'No se pudo rechazar la excepción.'), 'error');
		} finally {
			this.loading = false;
		}
	}

	async handleClienteApruebaCondicionExcepcion() {
		await this.handleRespuestaCondicionExcepcion(true);
	}

	async handleClienteNoApruebaCondicionExcepcion() {
		await this.handleRespuestaCondicionExcepcion(false);
	}

	async handleRespuestaCondicionExcepcion(clienteAprueba) {
		this.loading = true;
		try {
			await responderCondicionCliente({
				excepcionId: this.excepcionContext.excepcionId,
				clienteAprueba,
			});
			const mensaje = clienteAprueba ? 'La excepción quedó aprobada.' : 'La excepción quedó rechazada y la solicitud fue cerrada como perdida.';
			this.showToast('Actualizado', mensaje, 'success');
			await this.refreshAll();
		} catch (error) {
			this.showToast('Error', this.getErrorMessage(error, 'No se pudo registrar la respuesta del cliente.'), 'error');
		} finally {
			this.loading = false;
		}
	}

	async refreshAll() {
		const promises = [];
		if (this.wiredCapturaOperacionesResult) {
			promises.push(refreshApex(this.wiredCapturaOperacionesResult));
		}
		if (this.wiredDocumentacionContratosResult) {
			promises.push(refreshApex(this.wiredDocumentacionContratosResult));
		}
		if (this.wiredRecordResult) {
			promises.push(refreshApex(this.wiredRecordResult));
		}
		if (this.wiredApprovalContextResult) {
			promises.push(refreshApex(this.wiredApprovalContextResult));
		}
		if (this.wiredPagaresContextResult) {
			promises.push(refreshApex(this.wiredPagaresContextResult));
		}
		if (this.wiredExcepcionContextResult) {
			promises.push(refreshApex(this.wiredExcepcionContextResult));
		}
		if (this.wiredFormalizacionResult && this.formalizacionRecordId) {
			promises.push(refreshApex(this.wiredFormalizacionResult));
		}
		await Promise.all(promises);
	}

	showToast(title, message, variant) {
		this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
	}
}