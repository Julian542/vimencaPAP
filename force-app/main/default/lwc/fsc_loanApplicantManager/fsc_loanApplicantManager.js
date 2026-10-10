import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';
import LOANAPPLICANT_OBJECT from '@salesforce/schema/LoanApplicant';
import CONTACTPOINTPHONE_OBJECT from '@salesforce/schema/ContactPointPhone';
import FSC_FACILIDAD_OTRA_INSTITUCION_OBJECT from '@salesforce/schema/FSC_Facilidad_Otra_Institucion__c';
import FSC_REFERENCIAS_OBJECT from '@salesforce/schema/FSC_Referencias__c';
import FSC_TIPO_SOLICITANTE_FIELD from '@salesforce/schema/LoanApplicant.FSC_TipoSolicitante__c';
import FSC_TIPO_IDENTIFICACION_FIELD from '@salesforce/schema/LoanApplicant.FSC_TipoIdentificacion__c';
import FSC_ESTADO_CIVIL_FIELD from '@salesforce/schema/LoanApplicant.FSC_EstadoCivil__c';
import FSC_TIPO_VIVIENDA_FIELD from '@salesforce/schema/LoanApplicant.FSC_TipoVivienda__c';
import FSC_CLASIFICACION_SIB_FIELD from '@salesforce/schema/LoanApplicant.FSC_ClasificacionSIB__c';
import FSC_NACIONALIDAD_FIELD from '@salesforce/schema/LoanApplicant.FSC_Nacionalidad__c';
import FSC_OCUPACION_FIELD from '@salesforce/schema/LoanApplicant.FSC_Ocupacion__c';
import FSC_FUENTE_INGRESO_FIELD from '@salesforce/schema/LoanApplicant.FSC_FuenteIngreso__c';
import CONTACTPOINTPHONE_TIPO_CONTACTO_FIELD from '@salesforce/schema/ContactPointPhone.FSC_TipoContacto__c';
import REFERENCIA_TIPO_IDENTIFICACION_FIELD from '@salesforce/schema/FSC_Referencias__c.FSC_TipoIdentificacion__c';
import REFERENCIA_PARENTESCO_FIELD from '@salesforce/schema/FSC_Referencias__c.FSC_Parentesco__c';
import FSC_OI_TIPO_FACILIDAD_FIELD from '@salesforce/schema/FSC_Facilidad_Otra_Institucion__c.FSC_TipoFacilidad__c';
import FSC_OI_MONEDA_FIELD from '@salesforce/schema/FSC_Facilidad_Otra_Institucion__c.FSC_Moneda__c';
import FSC_OI_FACILIDAD_FIELD from '@salesforce/schema/FSC_Facilidad_Otra_Institucion__c.FSC_Facilidad__c';
import FSC_OI_ENTIDAD_FINANCIERA_FIELD from '@salesforce/schema/FSC_Facilidad_Otra_Institucion__c.FSC_EntidadFinanciera__c';
import getLoanApplicant from '@salesforce/apex/FSC_LoanApplicantController.getLoanApplicant';
import getAccountLoanApplicant from '@salesforce/apex/FSC_LoanApplicantController.getAccountLoanApplicant';
import updateDebtorAccount from '@salesforce/apex/FSC_LoanApplicantController.updateDebtorAccount';
import obtenerLimiteFacilidadesOtrasInstituciones from '@salesforce/apex/FSC_LoanApplicantController.obtenerLimiteFacilidadesOtrasInstituciones';
const INVALID_EMAIL_MESSAGE = 'Ingrese una direccion de correo valida, por ejemplo usuario@dominio.com.';
const INVALID_REFERENCE_EMAIL_MESSAGE = 'Ingrese un correo valido sin espacios ni caracteres especiales no permitidos.';
const DUPLICATE_REFERENCE_IDENTIFICATION_MESSAGE = 'Ya existe una referencia con el mismo tipo y numero de identificacion.';
const UNIQUE_REFERENCE_RELATIONSHIPS = new Set(['conyuge', 'esposo (a)', 'nuera', 'yerno', 'madre', 'padre']);

function normalizarLimiteFacilidadesOtrasInstituciones(valor) {
	const valorNumerico = Number(valor);
	return valorNumerico;
}

function alcanzaLimiteFacilidadesOtrasInstituciones(cantidadRegistros, limiteConfigurado) {
	return Number(cantidadRegistros) >= normalizarLimiteFacilidadesOtrasInstituciones(limiteConfigurado);
}

function excedeLimiteFacilidadesOtrasInstituciones(cantidadRegistros, limiteConfigurado) {
	return Number(cantidadRegistros) > normalizarLimiteFacilidadesOtrasInstituciones(limiteConfigurado);
}

export default class FscLoanApplicantManager extends OmniscriptBaseMixin(LightningElement) {
	@track applicants = [];

	_tipoCredito = '';
	@api recordId = '';
	@api accountId = '';
	@api contextId = '';
	@api residentialLoanApplicationId = '';

	@api
	set tipoCredito(value) {
		this._tipoCredito = value || '';
		this.ensurePrimaryAccountApplicant();
	}

	get tipoCredito() {
		return this._tipoCredito;
	}

	@api
	set value(val) {
		const incomingApplicants = this.normalizeApplicants(this.extractApplicants(val));
		if (this.isStaleApplicantsValue(incomingApplicants)) {
			return;
		}

		this.applicants = incomingApplicants;
		this.ensurePrimaryAccountApplicant();
	}

	get value() {
		return this.applicants.length > 0 ? this.applicants : null;
	}

	@track showModal = false;
	@track modalTitle = 'Agregar Solicitante';
	@track currentStep = '1';
	@track tipoIdentificacion = '';
	@track numIdentificacion = '';
	@track tipoSolicitante = '';
	@track existingApplicant = null;
	@track existingApplicantId = '';
	@track isLoadingApplicant = false;
	@track isReadonly = false;
	@track isEdit = false;
	@track isExistingInDB = false;
	@track isEditingPrimaryAccountApplicant = false;
	@track attemptedOsValidation = false;
	@track isSavingApplicant = false;

	allTipoSolicitanteOptions = [];
	tipoIdentificacionOptions = [];
	estadoCivilOptions = [];
	tipoViviendaOptions = [];
	clasificacionSIBOptions = [];
	nacionalidadOptions = [];
	ocupacionOptions = [];
	fuenteIngresoOptions = [];
	tipoContactoOptions = [];
	facilidadOptions = [];
	facilidadMonedaOptions = [];
	tipoFacilidadOptions = [];
	entidadFinancieraOptions = [];
	referenciaTipoIdentificacionOptions = [];
	allReferenceRelationshipOptions = [];
	rowKeyCounter = 0;
	pendingApplicantsSyncSignature = null;
	pendingApplicantsSyncTimeout = null;
	primaryAccountApplicantKey = '';
	primaryAccountLoadKey = '';
	primaryAccountReadonlyFields = {};
	isLoadingPrimaryAccountApplicant = false;
	limiteMaximoFacilidadesOtrasInstituciones = 0;

	@wire(obtenerLimiteFacilidadesOtrasInstituciones)
	limiteFacilidadesOtrasInstitucionesConectado({ data }) {
		if (data !== undefined) {
			this.limiteMaximoFacilidadesOtrasInstituciones = normalizarLimiteFacilidadesOtrasInstituciones(data);
		}
	}

	@wire(getObjectInfo, { objectApiName: LOANAPPLICANT_OBJECT })
	objectInfo;

	@wire(getObjectInfo, { objectApiName: CONTACTPOINTPHONE_OBJECT })
	contactPointPhoneObjectInfo;

	@wire(getObjectInfo, { objectApiName: FSC_FACILIDAD_OTRA_INSTITUCION_OBJECT })
	facilidadOtraInstitucionObjectInfo;

	@wire(getObjectInfo, { objectApiName: FSC_REFERENCIAS_OBJECT })
	referenciaObjectInfo;

	@wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: FSC_TIPO_SOLICITANTE_FIELD })
	wiredTipoSolicitantePicklist({ error, data }) {
		if (data) {
			this.allTipoSolicitanteOptions = data.values;
		} else if (error) {
			console.error('Error loading tipo solicitante picklist:', error);
		}
	}

	@wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: FSC_TIPO_IDENTIFICACION_FIELD })
	wiredTipoIdentificacionPicklist({ error, data }) {
		if (data) {
			this.tipoIdentificacionOptions = data.values;
		} else if (error) {
			console.error('Error loading tipo identificacion picklist:', error);
		}
	}

	@wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: FSC_ESTADO_CIVIL_FIELD })
	wiredEstadoCivilPicklist({ error, data }) {
		if (data) {
			this.estadoCivilOptions = data.values;
		} else if (error) {
			console.error('Error loading estado civil picklist:', error);
		}
	}

	@wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: FSC_TIPO_VIVIENDA_FIELD })
	wiredTipoViviendaPicklist({ error, data }) {
		if (data) {
			this.tipoViviendaOptions = data.values;
		} else if (error) {
			console.error('Error loading tipo vivienda picklist:', error);
		}
	}

	@wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: FSC_CLASIFICACION_SIB_FIELD })
	wiredClasificacionSIBPicklist({ error, data }) {
		if (data) {
			this.clasificacionSIBOptions = data.values;
		} else if (error) {
			console.error('Error loading clasificacion SIB picklist:', error);
		}
	}

	@wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: FSC_NACIONALIDAD_FIELD })
	wiredNacionalidadPicklist({ error, data }) {
		if (data) {
			this.nacionalidadOptions = data.values;
		} else if (error) {
			console.error('Error loading nacionalidad picklist:', error);
		}
	}

	@wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: FSC_OCUPACION_FIELD })
	wiredOcupacionPicklist({ error, data }) {
		if (data) {
			this.ocupacionOptions = data.values;
		} else if (error) {
			console.error('Error loading ocupacion picklist:', error);
		}
	}

	@wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: FSC_FUENTE_INGRESO_FIELD })
	wiredFuenteIngresoPicklist({ error, data }) {
		if (data) {
			this.fuenteIngresoOptions = data.values;
		} else if (error) {
			console.error('Error loading fuente de ingreso picklist:', error);
		}
	}

	@wire(getPicklistValues, {
		recordTypeId: '$contactPointPhoneObjectInfo.data.defaultRecordTypeId',
		fieldApiName: CONTACTPOINTPHONE_TIPO_CONTACTO_FIELD,
	})
	wiredTipoContactoPicklist({ error, data }) {
		if (data) {
			this.tipoContactoOptions = data.values;
		} else if (error) {
			console.error('Error loading tipo contacto picklist:', error);
		}
	}

	@wire(getPicklistValues, { recordTypeId: '$facilidadOtraInstitucionObjectInfo.data.defaultRecordTypeId', fieldApiName: FSC_OI_FACILIDAD_FIELD })
	wiredFacilidadPicklist({ error, data }) {
		if (data) {
			this.facilidadOptions = data.values;
		} else if (error) {
			console.error('Error loading facilidad picklist:', error);
		}
	}

	@wire(getPicklistValues, { recordTypeId: '$facilidadOtraInstitucionObjectInfo.data.defaultRecordTypeId', fieldApiName: FSC_OI_MONEDA_FIELD })
	wiredFacilidadMonedaPicklist({ error, data }) {
		if (data) {
			this.facilidadMonedaOptions = data.values;
		} else if (error) {
			console.error('Error loading moneda picklist:', error);
		}
	}

	@wire(getPicklistValues, {
		recordTypeId: '$facilidadOtraInstitucionObjectInfo.data.defaultRecordTypeId',
		fieldApiName: FSC_OI_TIPO_FACILIDAD_FIELD,
	})
	wiredTipoFacilidadPicklist({ error, data }) {
		if (data) {
			this.tipoFacilidadOptions = data.values;
		} else if (error) {
			console.error('Error loading tipo facilidad picklist:', error);
		}
	}

	@wire(getPicklistValues, {
		recordTypeId: '$facilidadOtraInstitucionObjectInfo.data.defaultRecordTypeId',
		fieldApiName: FSC_OI_ENTIDAD_FINANCIERA_FIELD,
	})
	wiredEntidadFinancieraPicklist({ error, data }) {
		if (data) {
			this.entidadFinancieraOptions = data.values;
		} else if (error) {
			console.error('Error loading entidad financiera picklist:', error);
		}
	}

	@wire(getPicklistValues, {
		recordTypeId: '$referenciaObjectInfo.data.defaultRecordTypeId',
		fieldApiName: REFERENCIA_TIPO_IDENTIFICACION_FIELD,
	})
	wiredReferenciaTipoIdentificacionPicklist({ error, data }) {
		if (data) {
			this.referenciaTipoIdentificacionOptions = data.values;
		} else if (error) {
			console.error('Error loading referencia tipo identificacion picklist:', error);
		}
	}

	@wire(getPicklistValues, {
		recordTypeId: '$referenciaObjectInfo.data.defaultRecordTypeId',
		fieldApiName: REFERENCIA_PARENTESCO_FIELD,
	})
	wiredReferenciaParentescoPicklist({ error, data }) {
		if (data) {
			this.allReferenceRelationshipOptions = data.values;
		} else if (error) {
			console.error('Error loading referencia parentesco picklist:', error);
		}
	}

	@track nombre = '';
	@track primerApellido = '';
	@track segundoApellido = '';
	@track fechaNacimiento = '';

	get fechaNacimientoMaxima() {
		const today = new Date();
		const year = today.getFullYear() - 18;
		const month = today.getMonth();
		const day = Math.min(today.getDate(), new Date(year, month + 1, 0).getDate());
		return `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
	}

	get fechaActual() {
		const today = new Date();
		return `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`;
	}

	@track nacionalidad = '';
	@track estadoCivil = '';
	@track tipoVivienda = '';
	@track tiempoVivienda = '';
	@track ocupacion = '';
	@track empresaLabora = '';
	@track lugarLabora = '';
	@track tiempoLaborando = '';
	@track empresaAnterior = '';
	@track fuenteIngreso = '';
	@track ingresosMensuales = '';
	@track otrosIngresos = '';
	@track descripcionOtrosIngresos = '';
	@track montoPrestaciones = '';
	@track numeroDependientes = '';
	@track tipoNegocio = '';
	@track clasificacionSIB = '';
	@track telefonos = [];
	@track direcciones = [];
	@track direccionesElectronicas = [];
	@track referencias = [];
	@track facilidadesOtrasInstituciones = [];
	@track telefonoDraft = null;
	@track direccionDraft = null;
	@track direccionElectronicaDraft = null;
	@track referenciaDraft = null;
	@track showTelefonoEditor = false;
	@track showDireccionEditor = false;
	@track showDireccionElectronicaEditor = false;
	@track showReferenciaEditor = false;
	@track showFacilidadOtraInstitucionEditor = false;
	telefonoEditKey = null;
	direccionEditKey = null;
	direccionElectronicaEditKey = null;
	referenciaEditKey = null;
	facilidadOtraInstitucionEditKey = null;
	@track facilidadOtraInstitucionDraft = null;

	get isStep1() {
		return this.currentStep === '1';
	}

	get isStep2() {
		return this.currentStep === '2';
	}

	get isExistingApplicant() {
		return !!this.existingApplicantId;
	}

	get totalIngresos() {
		const ingresos = Number(this.ingresosMensuales) || 0;
		const otros = Number(this.otrosIngresos) || 0;
		return (ingresos + otros).toFixed(2);
	}

	get actionButtonLabel() {
		return this.isEdit ? 'Guardar' : 'Agregar';
	}

	get hasApplicants() {
		return this.applicants.length > 0;
	}

	get isCreditoPyme() {
		return (
			String(this.tipoCredito || '')
				.trim()
				.toUpperCase() === 'PYME'
		);
	}

	get requiresAccountDebtor() {
		return !this.isCreditoPyme;
	}

	get isCedulaSelected() {
		return this.normalizeText(this.tipoIdentificacion) === 'cedula';
	}

	get numIdentificacionMaxLength() {
		return this.isCedulaSelected ? 11 : 20;
	}

	get numIdentificacionPattern() {
		return this.isCedulaSelected ? '[0-9-]{1,11}' : null;
	}

	get isReferenciaCedulaSelected() {
		return this.normalizeText(this.referenciaDraft?.FSC_TipoIdentificacion__c) === 'cedula';
	}

	get isReferenciaPasaporteSelected() {
		return this.normalizeText(this.referenciaDraft?.FSC_TipoIdentificacion__c) === 'pasaporte';
	}

	get isReferenciaRncSelected() {
		return this.normalizeText(this.referenciaDraft?.FSC_TipoIdentificacion__c) === 'rnc';
	}

	get isReferenciaIdentificacionRequired() {
		return !!this.referenciaDraft?.FSC_TipoIdentificacion__c;
	}

	get isReferenciaTipoIdentificacionRequired() {
		return !!String(this.referenciaDraft?.FSC_Identificacion__c || '').trim();
	}

	get referenciaIdentificacionMaxLength() {
		if (this.isReferenciaCedulaSelected) {
			return 11;
		}

		return this.isReferenciaPasaporteSelected || this.isReferenciaRncSelected ? 9 : 255;
	}

	get referenciaIdentificacionPattern() {
		if (this.isReferenciaRncSelected) {
			return '[0-9]{9}';
		}

		if (this.isReferenciaCedulaSelected) {
			return '[0-9-]{1,11}';
		}

		return this.isReferenciaPasaporteSelected ? '^[A-Z]{3}[0-9]{6}$' : null;
	}

	get referenciaIdentificacionPatternMessage() {
		if (this.isReferenciaRncSelected) {
			return 'Para RNC, ingrese exactamente 9 digitos, sin guiones ni espacios.';
		}

		if (this.isReferenciaCedulaSelected) {
			return 'Para cedula, ingrese solo numeros y guiones, hasta 11 caracteres.';
		}

		if (this.isReferenciaPasaporteSelected) {
			return 'Para pasaporte, ingrese 3 letras mayusculas seguidas de 6 numeros (por ejemplo, ABC123456).';
		}

		return 'Ingrese una identificacion valida.';
	}

	get hasRequiredDeudor() {
		if (this.isCreditoPyme) {
			return true;
		}

		return this.applicants.some((applicant) => this.isDeudorApplicant(applicant));
	}

	get showRequiredDeudorError() {
		return this.attemptedOsValidation && !this.isCreditoPyme && !this.hasRequiredDeudor;
	}

	get requiredDeudorMessage() {
		return 'Debe agregar al menos un Deudor para continuar con la solicitud.';
	}

	get hasRequiredDeudorReferences() {
		return this.applicants
			.filter((applicant) => this.isDeudorApplicant(applicant))
			.every((applicant) => this.hasMinimumRequiredReferences(applicant));
	}

	get showRequiredDeudorReferencesError() {
		return this.attemptedOsValidation && !this.hasRequiredDeudorReferences;
	}

	get requiredDeudorReferencesMessage() {
		return 'Cada Deudor debe tener al menos dos referencias completas para continuar.';
	}

	get hasRequiredLaborData() {
		return this.applicants.every((applicant) => this.hasCompleteLaborData(applicant));
	}

	get showRequiredLaborDataError() {
		return this.attemptedOsValidation && !this.hasRequiredLaborData;
	}

	get requiredLaborDataMessage() {
		return 'Todos los solicitantes deben tener completos los Datos Laborales completos: ocupación, fuente de ingreso, tiempo laborando, ingresos mensuales, tipo de negocio y monto prestaciones.';
	}

	get tipoSolicitanteOptions() {
		const hasAnotherDeudor = this.hasAnotherDeudor();
		return this.allTipoSolicitanteOptions.filter((option) => {
			const isDeudorOption = this.normalizeApplicantType(option.value) === 'deudor' || this.normalizeApplicantType(option.label) === 'deudor';
			return !isDeudorOption || (!this.isCreditoPyme && !hasAnotherDeudor);
		});
	}

	get isPrimaryAccountTipoSolicitanteDisabled() {
		return this.isEditingPrimaryAccountApplicant;
	}

	get isPrimaryAccountNombreReadonly() {
		return this.isPrimaryAccountFieldReadonly('FSC_Nombre__c');
	}

	get isPrimaryAccountPrimerApellidoReadonly() {
		return this.isPrimaryAccountFieldReadonly('FSC_PrimerApellido__c');
	}

	get isPrimaryAccountSegundoApellidoReadonly() {
		return this.isPrimaryAccountFieldReadonly('FSC_SegundoApellido__c');
	}

	get isPrimaryAccountNacionalidadDisabled() {
		return this.isPrimaryAccountFieldReadonly('FSC_Nacionalidad__c');
	}

	get hasTelefonos() {
		return this.telefonos.length > 0;
	}

	get hasDirecciones() {
		return this.direcciones.length > 0;
	}

	get hasDireccionesElectronicas() {
		return this.direccionesElectronicas.length > 0;
	}

	get hasReferencias() {
		return this.referencias.length > 0;
	}

	get referenciaParentescoOptions() {
		return this.allReferenceRelationshipOptions.filter((option) => !this.isReferenceRelationshipInUse(option.value));
	}

	get hasFacilidadesOtrasInstituciones() {
		return this.facilidadesOtrasInstituciones.length > 0;
	}

	get alcanzoLimiteFacilidadesOtrasInstituciones() {
		return alcanzaLimiteFacilidadesOtrasInstituciones(this.facilidadesOtrasInstituciones.length, this.limiteMaximoFacilidadesOtrasInstituciones);
	}

	get tienenCantidadValidaFacilidadesOtrasInstituciones() {
		return this.applicants.every(
			(solicitante) =>
				!excedeLimiteFacilidadesOtrasInstituciones(
					this.obtenerFacilidadesOtrasInstituciones(solicitante).length,
					this.limiteMaximoFacilidadesOtrasInstituciones
				)
		);
	}

	get mostrarErrorLimiteFacilidadesOtrasInstituciones() {
		return this.attemptedOsValidation && !this.tienenCantidadValidaFacilidadesOtrasInstituciones;
	}

	get mensajeLimiteFacilidadesOtrasInstituciones() {
		return `Solo se permiten ${this.limiteMaximoFacilidadesOtrasInstituciones} facilidades en otras instituciones por solicitante.`;
	}

	get telefonoColumns() {
		return [
			{ label: 'Tipo de Contacto', fieldName: 'FSC_TipoContacto__c' },
			{ label: 'Numero de Telefono', fieldName: 'TelephoneNumber' },
			{
				type: 'action',
				typeAttributes: {
					rowActions: [
						{ label: 'Modificar', name: 'edit' },
						{ label: 'Eliminar', name: 'delete' },
					],
				},
			},
		];
	}

	get direccionColumns() {
		return [
			{ label: 'Nombre de la Direccion', fieldName: 'Name' },
			{ label: 'Calle', fieldName: 'Street' },
			{ label: 'Ciudad', fieldName: 'City' },
			{ label: 'Estado', fieldName: 'State' },
			{ label: 'Codigo Postal', fieldName: 'PostalCode' },
			{ label: 'Pais', fieldName: 'Country' },
			{
				type: 'action',
				typeAttributes: {
					rowActions: [
						{ label: 'Modificar', name: 'edit' },
						{ label: 'Eliminar', name: 'delete' },
					],
				},
			},
		];
	}

	get direccionElectronicaColumns() {
		return [
			{ label: 'Email', fieldName: 'EmailAddress' },
			{
				type: 'action',
				typeAttributes: {
					rowActions: [
						{ label: 'Modificar', name: 'edit' },
						{ label: 'Eliminar', name: 'delete' },
					],
				},
			},
		];
	}

	get referenciaColumns() {
		return [
			{ label: 'Nombres', fieldName: 'FSC_FirstName__c' },
			{ label: 'Apellidos', fieldName: 'FSC_LastName__c' },
			{ label: 'Identificacion', fieldName: 'FSC_Identificacion__c' },
			{ label: 'Telefono', fieldName: 'FSC_Telefono__c' },
			{ label: 'Email', fieldName: 'FSC_Email__c' },
			{ label: 'Parentesco', fieldName: 'FSC_Parentesco__c' },
			{
				type: 'action',
				typeAttributes: {
					rowActions: [
						{ label: 'Modificar', name: 'edit' },
						{ label: 'Eliminar', name: 'delete' },
					],
				},
			},
		];
	}

	get telefonoEditorTitle() {
		return this.telefonoEditKey ? 'Modificar telefono' : 'Agregar telefono';
	}

	get direccionEditorTitle() {
		return this.direccionEditKey ? 'Modificar direccion' : 'Agregar direccion';
	}

	get direccionElectronicaEditorTitle() {
		return this.direccionElectronicaEditKey ? 'Modificar correo' : 'Agregar correo';
	}

	get referenciaEditorTitle() {
		return this.referenciaEditKey ? 'Modificar referencia' : 'Agregar referencia';
	}

	get facilidadOtraInstitucionColumns() {
		return [
			{ label: 'Entidad Financiera', fieldName: 'FSC_EntidadFinanciera__c' },
			{ label: 'Tipo de Facilidad', fieldName: 'FSC_TipoFacilidad__c' },
			{ label: 'Facilidad', fieldName: 'FSC_Facilidad__c' },
			{ label: 'Moneda', fieldName: 'FSC_Moneda__c' },
			{ label: 'Balance', fieldName: 'FSC_Balance__c', type: 'number' },
			{
				type: 'action',
				typeAttributes: {
					rowActions: [
						{ label: 'Modificar', name: 'edit' },
						{ label: 'Eliminar', name: 'delete' },
					],
				},
			},
		];
	}

	get facilidadOtraInstitucionEditorTitle() {
		return this.facilidadOtraInstitucionEditKey ? 'Modificar facilidad' : 'Agregar facilidad';
	}

	connectedCallback() {
		this.hydrateApplicantsFromOmni();
		this.ensurePrimaryAccountApplicant();
	}

	renderedCallback() {
		if (typeof super.renderedCallback === 'function') {
			super.renderedCallback();
		}
		this.ensurePrimaryAccountApplicant();
	}

	@api
	checkValidity() {
		return this.updateOmniValidity(false);
	}

	@api
	reportValidity() {
		return this.updateOmniValidity(true);
	}

	updateOmniValidity(reportErrors) {
		if (reportErrors) {
			this.attemptedOsValidation = true;
		}

		const isComponentValid = this.validateApplicants();
		this.isValid = isComponentValid;
		this._showValidation = reportErrors && !isComponentValid;
		return isComponentValid;
	}

	validateApplicants() {
		this.hydrateApplicantsFromOmni();
		this.ensurePrimaryAccountApplicant();
		return (
			this.hasRequiredDeudor &&
			this.hasRequiredDeudorReferences &&
			this.hasRequiredLaborData &&
			this.tienenCantidadValidaFacilidadesOtrasInstituciones
		);
	}

	isDeudorApplicant(applicant) {
		return this.normalizeApplicantType(applicant?.FSC_TipoSolicitante__c) === 'deudor';
	}

	normalizeText(value) {
		return String(value ?? '')
			.normalize('NFD')
			.replace(/[\u0300-\u036f]/g, '')
			.trim()
			.toLowerCase();
	}

	normalizeApplicantType(value) {
		return this.normalizeText(value).replace(/[^a-z0-9]/g, '');
	}

	isBlank(value) {
		return value === undefined || value === null || String(value).trim() === '';
	}

	hasCompleteLaborData(applicant) {
		return (
			!this.isBlank(applicant?.FSC_Ocupacion__c) &&
			!this.isBlank(applicant?.FSC_FuenteIngreso__c) &&
			!this.isBlank(applicant?.FSC_TiempoLaborando__c) &&
			!this.isBlank(applicant?.FSC_IngresosMensuales__c) &&
			!this.isBlank(applicant?.FSC_TipoNegocio__c)
		);
	}

	isStaleApplicantsValue(incomingApplicants) {
		if (!this.pendingApplicantsSyncSignature) {
			return false;
		}

		const incomingSignature = this.getApplicantsSignature(incomingApplicants);
		if (incomingSignature === this.pendingApplicantsSyncSignature) {
			this.clearPendingApplicantsSync();
			return false;
		}

		return true;
	}

	getApplicantsSignature(applicants) {
		return JSON.stringify(Array.isArray(applicants) ? applicants : []);
	}

	clearPendingApplicantsSync() {
		this.pendingApplicantsSyncSignature = null;
		if (this.pendingApplicantsSyncTimeout) {
			window.clearTimeout(this.pendingApplicantsSyncTimeout);
			this.pendingApplicantsSyncTimeout = null;
		}
	}

	notifyApplicantsChange() {
		const payload = this.applicants.length > 0 ? this.applicants : null;
		this.pendingApplicantsSyncSignature = this.getApplicantsSignature(this.applicants);
		if (this.pendingApplicantsSyncTimeout) {
			window.clearTimeout(this.pendingApplicantsSyncTimeout);
		}
		this.pendingApplicantsSyncTimeout = window.setTimeout(() => {
			this.clearPendingApplicantsSync();
		}, 1500);

		if (typeof this.omniUpdateDataJson === 'function') {
			this.omniUpdateDataJson(payload);
		}

		if (typeof this.omniValidate === 'function') {
			this.omniValidate(this.attemptedOsValidation);
		}
	}

	get columns() {
		return [
			{ label: 'Tipo de Solicitante', fieldName: 'FSC_TipoSolicitante__c' },
			{ label: 'Tipo de Identificación', fieldName: 'FSC_TipoIdentificacion__c' },
			{ label: 'Número de Identificación', fieldName: 'FSC_NumIdentificacion__c' },
			{
				type: 'action',
				typeAttributes: {
					rowActions: this.getApplicantRowActions.bind(this),
				},
			},
		];
	}

	getApplicantRowActions(row, doneCallback) {
		const actions = [{ label: 'Modificar', name: 'edit' }];
		if (!this.isPrimaryAccountApplicant(row)) {
			actions.push({ label: 'Eliminar', name: 'delete' });
		}
		doneCallback(actions);
	}

	handleAddApplicant() {
		this.modalTitle = 'Agregar Solicitante';
		this.isEdit = false;
		this.isReadonly = false;
		this.showModal = true;
		this.currentStep = '1';
		this.resetForm();
	}

	closeModal() {
		this.showModal = false;
		this.resetForm();
	}

	resetForm() {
		this.tipoIdentificacion = '';
		this.numIdentificacion = '';
		this.tipoSolicitante = '';
		this.existingApplicant = null;
		this.existingApplicantId = '';
		this.isEditingPrimaryAccountApplicant = false;
		this.isExistingInDB = false;
		this.isLoadingApplicant = false;
		this.nombre = '';
		this.primerApellido = '';
		this.segundoApellido = '';
		this.fechaNacimiento = '';
		this.nacionalidad = '';
		this.estadoCivil = '';
		this.tipoVivienda = '';
		this.tiempoVivienda = '';
		this.ocupacion = '';
		this.empresaLabora = '';
		this.lugarLabora = '';
		this.tiempoLaborando = '';
		this.empresaAnterior = '';
		this.fuenteIngreso = '';
		this.ingresosMensuales = '';
		this.otrosIngresos = '';
		this.descripcionOtrosIngresos = '';
		this.montoPrestaciones = '';
		this.numeroDependientes = '';
		this.tipoNegocio = '';
		this.clasificacionSIB = '';
		this.telefonos = [];
		this.direcciones = [];
		this.direccionesElectronicas = [];
		this.referencias = [];
		this.facilidadesOtrasInstituciones = [];
		this.closeTelefonoEditor();
		this.closeDireccionEditor();
		this.closeDireccionElectronicaEditor();
		this.closeReferenciaEditor();
		this.closeFacilidadOtraInstitucionEditor();
	}

	handleTipoIdentificacionChange(event) {
		this.tipoIdentificacion = event.target.value;
		this.numIdentificacion = this.sanitizeNumIdentificacion(this.numIdentificacion);
	}

	handleNumIdentificacionChange(event) {
		this.numIdentificacion = this.sanitizeNumIdentificacion(event.target.value);
		event.target.value = this.numIdentificacion;
	}

	sanitizeNumIdentificacion(value) {
		const nextValue = String(value || '');
		if (!this.isCedulaSelected) {
			return nextValue;
		}

		return nextValue.replace(/[^0-9-]/g, '').slice(0, 11);
	}

	handleTipoSolicitanteChange(event) {
		this.tipoSolicitante = event.target.value;
	}

	extractApplicants(value) {
		if (Array.isArray(value)) {
			return value;
		}

		if (Array.isArray(value?.LoanApplicant)) {
			return value.LoanApplicant;
		}

		if (Array.isArray(value?.DatosSolicitante?.LoanApplicant)) {
			return value.DatosSolicitante.LoanApplicant;
		}

		return [];
	}

	normalizeApplicants(rows) {
		return Array.isArray(rows)
			? rows.map((row) => ({
					...row,
					Name: this.buildApplicantName(row),
				}))
			: [];
	}

	buildApplicantName(applicant) {
		return `${applicant?.FSC_Nombre__c || ''} ${applicant?.FSC_PrimerApellido__c || ''} ${applicant?.FSC_SegundoApellido__c || ''}`;
	}

	hydrateApplicantsFromOmni() {
		if (this.applicants.length > 0) {
			return;
		}

		const applicants = this.normalizeApplicants(this.extractApplicants(this.omniJsonData));
		if (applicants.length > 0) {
			this.applicants = applicants;
		}
	}

	ensurePrimaryAccountApplicant() {
		if (!this.requiresAccountDebtor || this.isLoadingPrimaryAccountApplicant) {
			return;
		}

		const omniAccountApplicant = this.buildAccountApplicantFromOmni();
		if (omniAccountApplicant) {
			this.upsertPrimaryAccountApplicant(omniAccountApplicant);
			return;
		}

		const contextId = this.getAccountApplicantContextId();
		if (!contextId || contextId === this.primaryAccountLoadKey) {
			return;
		}

		this.primaryAccountLoadKey = contextId;
		this.isLoadingPrimaryAccountApplicant = true;
		getAccountLoanApplicant({ contextId })
			.then((applicant) => {
				if (applicant) {
					this.upsertPrimaryAccountApplicant(applicant);
				}
			})
			.catch((error) => {
				console.error('Error loading account applicant:', error);
			})
			.finally(() => {
				this.isLoadingPrimaryAccountApplicant = false;
			});
	}

	buildAccountApplicantFromOmni() {
		const account = this.findFirstObject(this.omniJsonData, (candidate) => this.looksLikeAccount(candidate));
		return account ? this.buildAccountApplicant(account) : null;
	}

	looksLikeAccount(candidate) {
		return !!(candidate?.ACC_NumIdentificacion__c && candidate?.ACC_TipoIdentificacion__c);
	}

	buildAccountApplicant(account) {
		const lastNames = this.splitLastNames(account.LastName);
		return {
			Name: this.joinNonBlank([account.FirstName, account.MiddleName, account.LastName], ' ') || account.Name || '',
			FSC_TipoSolicitante__c: 'Deudor',
			FSC_TipoIdentificacion__c: account.ACC_TipoIdentificacion__c || '',
			FSC_NumIdentificacion__c: account.ACC_NumIdentificacion__c || '',
			FSC_Nombre__c: this.joinNonBlank([account.FirstName, account.MiddleName], ' ') || account.Name || '',
			FSC_PrimerApellido__c: lastNames[0],
			FSC_SegundoApellido__c: lastNames[1],
			FSC_FechaNacimiento__c: this.normalizeDateValue(account.PersonBirthdate),
			FSC_Nacionalidad__c: account.ACC_Nacionalidad__c || '',
			FSC_EstadoCivil__c: account.ACC_Estado_Civil__c || '',
			FSC_TipoVivienda__c: account.Tipo_de_vivienda__c || '',
			FSC_NumeroDependientes__c: account.ACC_N_Dependientes__c || '',
			FSC_Referencias__c: this.getRelatedRows(account, ['FSC_Referencias__c', 'Referencias', 'Referencias__r']),
		};
	}

	upsertPrimaryAccountApplicant(accountApplicant) {
		const primaryApplicant = this.normalizeApplicants([{ ...accountApplicant, FSC_TipoSolicitante__c: 'Deudor' }])[0];
		this.primaryAccountReadonlyFields = this.getPrimaryAccountReadonlyFields(primaryApplicant);
		const hasUsableAccountData =
			primaryApplicant.FSC_NumIdentificacion__c ||
			primaryApplicant.FSC_Nombre__c ||
			primaryApplicant.FSC_PrimerApellido__c ||
			primaryApplicant.Name;

		if (!hasUsableAccountData) {
			return;
		}

		let existingIndex = this.applicants.findIndex(
			(applicant) => this.isSameApplicant(applicant, primaryApplicant) || this.isSameDocumentApplicant(applicant, primaryApplicant)
		);
		if (existingIndex < 0) {
			existingIndex = this.applicants.findIndex(
				(applicant) => this.isDeudorApplicant(applicant) && !applicant.FSC_TipoIdentificacion__c && !applicant.FSC_NumIdentificacion__c
			);
		}
		const nextApplicants = [...this.applicants];
		if (existingIndex >= 0) {
			nextApplicants[existingIndex] = this.mergeMissingApplicantFields(nextApplicants[existingIndex], primaryApplicant);
		} else {
			nextApplicants.unshift(primaryApplicant);
		}

		this.primaryAccountApplicantKey = this.getApplicantUniqueKey(primaryApplicant);
		if (JSON.stringify(nextApplicants) !== JSON.stringify(this.applicants)) {
			this.applicants = nextApplicants;
			this.notifyApplicantsChange();
		}
	}

	mergeMissingApplicantFields(existingApplicant, primaryApplicant) {
		const merged = { ...primaryApplicant, ...existingApplicant, FSC_TipoSolicitante__c: 'Deudor' };
		Object.keys(primaryApplicant).forEach((field) => {
			if ((merged[field] === undefined || merged[field] === null || merged[field] === '') && primaryApplicant[field]) {
				merged[field] = primaryApplicant[field];
			}
		});
		merged.Name = this.buildApplicantName(merged);
		return merged;
	}

	getPrimaryAccountReadonlyFields(applicant) {
		return {
			FSC_Nombre__c: this.hasNonBlankValue(applicant?.FSC_Nombre__c),
			FSC_PrimerApellido__c: this.hasNonBlankValue(applicant?.FSC_PrimerApellido__c),
			FSC_SegundoApellido__c: this.hasNonBlankValue(applicant?.FSC_SegundoApellido__c),
			FSC_Nacionalidad__c: this.hasNonBlankValue(applicant?.FSC_Nacionalidad__c),
		};
	}

	hasNonBlankValue(value) {
		return value !== undefined && value !== null && String(value).trim() !== '';
	}

	isPrimaryAccountFieldReadonly(fieldName) {
		if (!this.isEditingPrimaryAccountApplicant) {
			return false;
		}

		if (Object.prototype.hasOwnProperty.call(this.primaryAccountReadonlyFields, fieldName)) {
			return this.primaryAccountReadonlyFields[fieldName];
		}

		return this.hasNonBlankValue(this.existingApplicant?.[fieldName]);
	}

	getAccountApplicantContextId() {
		const account = this.findFirstObject(
			this.omniJsonData,
			(candidate) =>
				String(candidate?.AccountId || '').startsWith('001') ||
				String(candidate?.accountId || '').startsWith('001') ||
				String(candidate?.Id || '').startsWith('001')
		);
		return (
			this.accountId ||
			account?.AccountId ||
			account?.accountId ||
			account?.Id ||
			this.residentialLoanApplicationId ||
			this.contextId ||
			this.recordId ||
			this.findFirstValue(this.omniJsonData, ['AccountId', 'accountId', 'ContextId', 'contextId', 'recordId'])
		);
	}

	findFirstObject(value, predicate, visited = new WeakSet()) {
		if (!value || typeof value !== 'object') {
			return null;
		}

		if (visited.has(value)) {
			return null;
		}
		visited.add(value);

		if (predicate(value)) {
			return value;
		}

		const values = Array.isArray(value) ? value : Object.values(value);
		for (const child of values) {
			const match = this.findFirstObject(child, predicate, visited);
			if (match) {
				return match;
			}
		}

		return null;
	}

	findFirstValue(value, keys, visited = new WeakSet()) {
		if (!value || typeof value !== 'object') {
			return '';
		}

		if (visited.has(value)) {
			return '';
		}
		visited.add(value);

		for (const key of keys) {
			if (value[key]) {
				return value[key];
			}
		}

		const values = Array.isArray(value) ? value : Object.values(value);
		for (const child of values) {
			const match = this.findFirstValue(child, keys, visited);
			if (match) {
				return match;
			}
		}

		return '';
	}

	splitLastNames(lastNames) {
		const parts = String(lastNames || '')
			.trim()
			.split(/\s+/)
			.filter(Boolean);
		return [parts[0] || '', parts.slice(1).join(' ')];
	}

	joinNonBlank(values, separator) {
		return values.filter((value) => value).join(separator);
	}

	handleNombreChange(event) {
		this.nombre = event.target.value;
	}
	handlePrimerApellidoChange(event) {
		this.primerApellido = event.target.value;
	}
	handleSegundoApellidoChange(event) {
		this.segundoApellido = event.target.value;
	}
	handleFechaNacimientoChange(event) {
		const fechaNacimiento = event.target.value;
		if (fechaNacimiento && fechaNacimiento > this.fechaNacimientoMaxima) {
			event.target.setCustomValidity('La fecha de nacimiento debe corresponder a una persona mayor de 18 años.');
			event.target.reportValidity();
			return;
		}

		event.target.setCustomValidity('');
		this.fechaNacimiento = fechaNacimiento;
	}
	handleNacionalidadChange(event) {
		this.nacionalidad = event.target.value;
	}
	handleEstadoCivilChange(event) {
		this.estadoCivil = event.target.value;
	}
	handleTipoViviendaChange(event) {
		this.tipoVivienda = event.target.value;
	}
	handleTiempoViviendaChange(event) {
		this.handleNonFutureDateChange(event, 'tiempoVivienda');
	}
	handleOcupacionChange(event) {
		this.ocupacion = event.target.value;
	}
	handleEmpresaLaboraChange(event) {
		this.empresaLabora = event.target.value;
	}
	handleLugarLaboraChange(event) {
		this.lugarLabora = event.target.value;
	}
	handleTiempoLaborandoChange(event) {
		this.handleNonFutureDateChange(event, 'tiempoLaborando');
	}
	handleNonFutureDateChange(event, stateProperty) {
		const dateValue = event.target.value;
		const validationMessage = dateValue && dateValue > this.fechaActual ? 'La fecha no puede ser mayor a hoy.' : '';

		event.target.setCustomValidity(validationMessage);
		event.target.reportValidity();
		if (!validationMessage) {
			this[stateProperty] = dateValue;
		}
	}
	handleEmpresaAnteriorChange(event) {
		this.empresaAnterior = event.target.value;
	}
	handleFuenteIngresoChange(event) {
		this.fuenteIngreso = event.target.value;
	}
	handleNumericInputKeyDown(event) {
		if ((event.ctrlKey || event.metaKey) && ['a', 'c', 'v', 'x'].includes(event.key.toLowerCase())) {
			return;
		}

		const allowedControlKeys = ['Backspace', 'Delete', 'ArrowLeft', 'ArrowRight', 'Home', 'End', 'Tab'];
		if (allowedControlKeys.includes(event.key) || /^[0-9]$/.test(event.key)) {
			return;
		}

		event.preventDefault();
	}
	handleNumericInputPaste(event) {
		event.preventDefault();
		const sanitizedValue = this.sanitizeNumericInput(event.clipboardData?.getData('text'));
		this.setNumericInputValue(event.target.dataset.numericInput, sanitizedValue);
	}
	setNumericInputValue(fieldName, value) {
		this[fieldName] = value;
		const input = this.template.querySelector(`[data-numeric-input="${fieldName}"]`);
		if (input) {
			input.value = value;
		}
	}
	handleAmountInput(event) {
		const sanitizedValue = this.sanitizeDecimalInput(event.target.value);
		this.setNumericInputValue(event.target.dataset.numericInput, sanitizedValue);
	}
	handleAmountBlur(event) {
		const sanitizedValue = this.sanitizeDecimalInput(event.target.value);
		this.setNumericInputValue(event.target.dataset.numericInput, this.normalizeDecimalValue(sanitizedValue));
	}
	handleAmountKeyDown(event) {
		if ((event.ctrlKey || event.metaKey) && ['a', 'c', 'v', 'x'].includes(event.key.toLowerCase())) {
			return;
		}

		const allowedControlKeys = ['Backspace', 'Delete', 'ArrowLeft', 'ArrowRight', 'Home', 'End', 'Tab'];
		if (allowedControlKeys.includes(event.key) || /^[0-9]$/.test(event.key)) {
			return;
		}

		if (['.', ','].includes(event.key) && !/[.,]/.test(event.target.value)) {
			return;
		}

		event.preventDefault();
	}
	handleAmountPaste(event) {
		event.preventDefault();
		const sanitizedValue = this.sanitizeDecimalInput(event.clipboardData?.getData('text'));
		this.setNumericInputValue(event.target.dataset.numericInput, this.normalizeDecimalValue(sanitizedValue));
	}
	handleOtrosIngresosChange(event) {
		this.otrosIngresos = event.target.value;
	}
	handleDescripcionOtrosIngresosChange(event) {
		this.descripcionOtrosIngresos = event.target.value;
	}
	sanitizeNumericInput(value) {
		return String(value || '').replace(/[^0-9]/g, '');
	}
	sanitizeDecimalInput(value) {
		const normalizedValue = String(value ?? '')
			.replace(',', '.')
			.replace(/[^0-9.]/g, '');
		const [integerPart, ...decimalParts] = normalizedValue.split('.');
		const limitedIntegerPart = integerPart.slice(0, 10);
		if (decimalParts.length === 0) {
			return limitedIntegerPart;
		}

		return `${limitedIntegerPart || '0'}.${decimalParts.join('').slice(0, 2)}`;
	}
	normalizeDecimalValue(value) {
		if (value === null || value === undefined || value === '') {
			return '';
		}

		const decimalValue = Number(String(value).trim().replace(',', '.'));
		return Number.isFinite(decimalValue) && decimalValue >= 0 ? decimalValue.toFixed(2) : '';
	}
	handleNumeroDependientesInput(event) {
		const sanitizedValue = this.sanitizeNumericInput(event.target.value);
		this.setNumericInputValue('numeroDependientes', sanitizedValue);
	}
	handleNumeroDependientesChange(event) {
		this.setNumericInputValue('numeroDependientes', this.sanitizeNumericInput(event.target.value));
	}
	handleTipoNegocioChange(event) {
		this.tipoNegocio = event.target.value;
	}
	handleClasificacionSIBChange(event) {
		this.clasificacionSIB = event.target.value;
	}

	previousStep() {
		this.currentStep = '1';
	}

	generateRowKey(prefix) {
		this.rowKeyCounter += 1;
		return `${prefix}-${this.rowKeyCounter}`;
	}

	createTelefonoRow(data = {}) {
		return {
			_key: data._key || this.generateRowKey('telefono'),
			FSC_TipoContacto__c: data.FSC_TipoContacto__c || '',
			TelephoneNumber: data.TelephoneNumber || '',
		};
	}

	createDireccionRow(data = {}) {
		return {
			_key: data._key || this.generateRowKey('direccion'),
			Name: data.Name || '',
			Street: data.Street || '',
			City: data.City || '',
			State: data.State || '',
			PostalCode: data.PostalCode || '',
			Country: data.Country || '',
		};
	}

	createDireccionElectronicaRow(data = {}) {
		return {
			_key: data._key || this.generateRowKey('email'),
			EmailAddress: data.EmailAddress || '',
		};
	}

	createReferenciaRow(data = {}) {
		const firstName = data.FSC_FirstName__c || '';
		const lastName = data.FSC_LastName__c || '';

		return {
			_key: data._key || this.generateRowKey('referencia'),
			Name: data.Name || this.buildReferenciaName(firstName, lastName),
			FSC_FirstName__c: firstName,
			FSC_LastName__c: lastName,
			FSC_LoanApplicant__c: data.FSC_LoanApplicant__c || this.existingApplicantId || '',
			FSC_TipoIdentificacion__c: data.FSC_TipoIdentificacion__c || '',
			FSC_Identificacion__c: data.FSC_Identificacion__c || '',
			FSC_Direccion__c: data.FSC_Direccion__c || '',
			FSC_Email__c: data.FSC_Email__c || '',
			FSC_Telefono__c: data.FSC_Telefono__c || '',
			FSC_Parentesco__c: data.FSC_Parentesco__c || '',
			FSC_LugarTrabajo__c: data.FSC_LugarTrabajo__c || '',
		};
	}

	buildReferenciaName(firstName, lastName) {
		return `${firstName || ''} ${lastName || ''}`.trim();
	}

	createFacilidadOtraInstitucionRow(data = {}) {
		return {
			_key: data._key || this.generateRowKey('facilidad-otra'),
			Name: data.Name || '',
			FSC_TipoFacilidad__c: data.FSC_TipoFacilidad__c || '',
			FSC_Moneda__c: data.FSC_Moneda__c || '',
			FSC_LoanApplicant__c: data.FSC_LoanApplicant__c || this.existingApplicantId || '',
			FSC_Facilidad__c: data.FSC_Facilidad__c || '',
			FSC_EntidadFinanciera__c: data.FSC_EntidadFinanciera__c || '',
			FSC_DescripcionFacilidad__c: data.FSC_DescripcionFacilidad__c || '',
			FSC_Balance__c: data.FSC_Balance__c || '',
		};
	}

	normalizeRows(rows, rowFactory) {
		const normalizedRows = Array.isArray(rows) ? rows : Array.isArray(rows?.records) ? rows.records : [];

		return normalizedRows.map((row) => rowFactory.call(this, row));
	}

	normalizeDateValue(value) {
		return value ? String(value).split('T')[0] : '';
	}

	getRelatedRows(record, relationshipNames) {
		for (const relationshipName of relationshipNames) {
			const rows = record?.[relationshipName];
			if (Array.isArray(rows) || Array.isArray(rows?.records)) {
				return rows;
			}
		}

		return [];
	}

	updateCollectionRow(collectionName, rowKey, fieldName, value) {
		this[collectionName] = this[collectionName].map((row) => (row._key === rowKey ? { ...row, [fieldName]: value } : row));
	}

	removeCollectionRow(collectionName, rowKey) {
		this[collectionName] = this[collectionName].filter((row) => row._key !== rowKey);
	}

	serializeCollectionRows(rows, fields) {
		return rows
			.filter((row) => fields.some((field) => row[field]))
			.map((row) => {
				const serializedRow = {};
				fields.forEach((field) => {
					serializedRow[field] = row[field] || '';
				});
				return serializedRow;
			});
	}

	serializeFacilidadesOtrasInstituciones() {
		return this.facilidadesOtrasInstituciones
			.filter((row) =>
				[
					'FSC_TipoFacilidad__c',
					'FSC_Moneda__c',
					'FSC_Facilidad__c',
					'FSC_EntidadFinanciera__c',
					'FSC_DescripcionFacilidad__c',
					'FSC_Balance__c',
				].some((field) => row[field])
			)
			.map((row, index) => ({
				Name: row.Name || `Fuera de Banco Vimenca ${index + 1}`,
				FSC_TipoFacilidad__c: row.FSC_TipoFacilidad__c || '',
				FSC_Moneda__c: row.FSC_Moneda__c || '',
				FSC_LoanApplicant__c: row.FSC_LoanApplicant__c || this.existingApplicantId || '',
				FSC_Facilidad__c: row.FSC_Facilidad__c || '',
				FSC_EntidadFinanciera__c: row.FSC_EntidadFinanciera__c || '',
				FSC_DescripcionFacilidad__c: row.FSC_DescripcionFacilidad__c || '',
				FSC_Balance__c: row.FSC_Balance__c || '',
			}));
	}

	serializeReferencias() {
		return this.referencias
			.filter((row) =>
				[
					'FSC_FirstName__c',
					'FSC_LastName__c',
					'FSC_TipoIdentificacion__c',
					'FSC_Identificacion__c',
					'FSC_Direccion__c',
					'FSC_Email__c',
					'FSC_Telefono__c',
					'FSC_Parentesco__c',
					'FSC_LugarTrabajo__c',
				].some((field) => row[field])
			)
			.map((row) => ({
				Name: this.buildReferenciaName(row.FSC_FirstName__c, row.FSC_LastName__c),
				FSC_FirstName__c: row.FSC_FirstName__c || '',
				FSC_LastName__c: row.FSC_LastName__c || '',
				FSC_LoanApplicant__c: row.FSC_LoanApplicant__c || this.existingApplicantId || '',
				FSC_TipoIdentificacion__c: row.FSC_TipoIdentificacion__c || '',
				FSC_Identificacion__c: row.FSC_Identificacion__c || '',
				FSC_Direccion__c: row.FSC_Direccion__c || '',
				FSC_Email__c: row.FSC_Email__c || '',
				FSC_Telefono__c: row.FSC_Telefono__c || '',
				FSC_Parentesco__c: row.FSC_Parentesco__c || '',
				FSC_LugarTrabajo__c: row.FSC_LugarTrabajo__c || '',
			}));
	}

	getApplicantUniqueKey(applicant) {
		if (applicant?.Id) {
			return `id:${applicant.Id}`;
		}

		return `doc:${applicant?.FSC_TipoIdentificacion__c || ''}:${applicant?.FSC_NumIdentificacion__c || ''}`;
	}

	isSameApplicant(applicantA, applicantB) {
		return this.getApplicantUniqueKey(applicantA) === this.getApplicantUniqueKey(applicantB);
	}

	isSameDocumentApplicant(applicantA, applicantB) {
		const tipoA = applicantA?.FSC_TipoIdentificacion__c || '';
		const tipoB = applicantB?.FSC_TipoIdentificacion__c || '';
		const numA = applicantA?.FSC_NumIdentificacion__c || '';
		const numB = applicantB?.FSC_NumIdentificacion__c || '';
		return !!tipoA && !!numA && tipoA === tipoB && numA === numB;
	}

	hasAnotherDeudor() {
		const currentApplicant = this.isEdit ? this.existingApplicant : null;
		return this.applicants.some(
			(applicant) => this.isDeudorApplicant(applicant) && (!currentApplicant || !this.isSameApplicant(applicant, currentApplicant))
		);
	}

	isPrimaryAccountApplicant(applicant) {
		if (this.primaryAccountApplicantKey) {
			return this.getApplicantUniqueKey(applicant) === this.primaryAccountApplicantKey;
		}

		const firstDeudor = this.applicants.find((row) => this.isDeudorApplicant(row));
		return this.requiresAccountDebtor && !!firstDeudor && this.isSameApplicant(firstDeudor, applicant);
	}

	hasMinimumRequiredReferences(applicant) {
		return this.countCompleteReferences(this.getApplicantReferences(applicant)) >= 2;
	}

	getApplicantReferences(applicant) {
		const rows = this.getRelatedRows(applicant, ['FSC_Referencias__c', 'Referencias', 'Referencias__r']);
		return Array.isArray(rows) ? rows : Array.isArray(rows?.records) ? rows.records : [];
	}

	obtenerFacilidadesOtrasInstituciones(solicitante) {
		const filas = this.getRelatedRows(solicitante, [
			'FSC_Facilidad_Otra_Institucion__c',
			'FSC_Facilidad_Otra_Institucion__r',
			'FSC_Facilidades_Otras_Instituciones__r',
		]);
		return Array.isArray(filas) ? filas : Array.isArray(filas?.records) ? filas.records : [];
	}

	countCompleteReferences(rows) {
		return (Array.isArray(rows) ? rows : []).filter((row) => this.isCompleteReference(row)).length;
	}

	isCompleteReference(row) {
		return !!(row?.FSC_FirstName__c && row?.FSC_LastName__c && row?.FSC_Telefono__c && row?.FSC_Parentesco__c);
	}

	handleAddTelefono() {
		this.telefonoDraft = this.createTelefonoRow();
		this.telefonoEditKey = null;
		this.showTelefonoEditor = true;
	}

	handleTelefonoRowAction(event) {
		const { action, row } = event.detail;

		if (action.name === 'edit') {
			this.telefonoDraft = this.createTelefonoRow(row);
			this.telefonoEditKey = row._key;
			this.showTelefonoEditor = true;
			return;
		}

		if (action.name === 'delete') {
			this.removeCollectionRow('telefonos', row._key);
		}
	}

	handleTelefonoDraftChange(event) {
		const value = event.target.name === 'TelephoneNumber' ? this.sanitizeNumericInput(event.target.value) : event.target.value;
		if (event.target.name === 'TelephoneNumber' && event.target.value !== value) {
			event.target.value = value;
		}
		this.telefonoDraft = {
			...this.telefonoDraft,
			[event.target.name]: value,
		};
	}

	handleTelefonoInput(event) {
		const telephoneNumber = this.sanitizeNumericInput(event.target.value);
		if (event.target.value !== telephoneNumber) {
			event.target.value = telephoneNumber;
		}
		this.updateTelefonoDraft(telephoneNumber);
	}

	handleTelefonoPaste(event) {
		event.preventDefault();
		const telephoneNumber = this.sanitizeNumericInput(event.clipboardData?.getData('text'));
		event.target.value = telephoneNumber;
		this.updateTelefonoDraft(telephoneNumber);
	}

	updateTelefonoDraft(telephoneNumber) {
		this.telefonoDraft = {
			...this.telefonoDraft,
			TelephoneNumber: telephoneNumber,
		};
	}

	saveTelefono() {
		const telephoneInput = this.template.querySelector('[data-telefono-input]');
		if (telephoneInput && !telephoneInput.checkValidity()) {
			telephoneInput.reportValidity();
			return;
		}

		if (!this.telefonoDraft?.FSC_TipoContacto__c || !this.telefonoDraft?.TelephoneNumber) {
			this.dispatchEvent(
				new ShowToastEvent({
					title: 'Campo requerido',
					message: 'Debe completar el tipo de contacto y el numero de telefono.',
					variant: 'warning',
				})
			);
			return;
		}

		const payload = this.createTelefonoRow({
			...this.telefonoDraft,
			_key: this.telefonoEditKey || this.telefonoDraft._key || this.generateRowKey('telefono'),
		});

		if (this.telefonoEditKey) {
			this.telefonos = this.telefonos.map((row) => (row._key === this.telefonoEditKey ? payload : row));
		} else {
			this.telefonos = [...this.telefonos, payload];
		}

		this.closeTelefonoEditor();
	}

	closeTelefonoEditor() {
		this.showTelefonoEditor = false;
		this.telefonoEditKey = null;
		this.telefonoDraft = this.createTelefonoRow();
	}

	handleAddDireccion() {
		this.direccionDraft = this.createDireccionRow();
		this.direccionEditKey = null;
		this.showDireccionEditor = true;
	}

	handleDireccionRowAction(event) {
		const { action, row } = event.detail;

		if (action.name === 'edit') {
			this.direccionDraft = this.createDireccionRow(row);
			this.direccionEditKey = row._key;
			this.showDireccionEditor = true;
			return;
		}

		if (action.name === 'delete') {
			this.removeCollectionRow('direcciones', row._key);
		}
	}

	handleDireccionDraftChange(event) {
		this.direccionDraft = {
			...this.direccionDraft,
			[event.target.name]: event.target.value,
		};
	}

	saveDireccion() {
		if (
			!this.direccionDraft?.Name &&
			!this.direccionDraft?.Street &&
			!this.direccionDraft?.City &&
			!this.direccionDraft?.State &&
			!this.direccionDraft?.PostalCode &&
			!this.direccionDraft?.Country
		) {
			this.dispatchEvent(
				new ShowToastEvent({
					title: 'Campo requerido',
					message: 'Debe completar al menos un dato de la direccion.',
					variant: 'warning',
				})
			);
			return;
		}

		const payload = this.createDireccionRow({
			...this.direccionDraft,
			_key: this.direccionEditKey || this.direccionDraft._key || this.generateRowKey('direccion'),
		});

		if (this.direccionEditKey) {
			this.direcciones = this.direcciones.map((row) => (row._key === this.direccionEditKey ? payload : row));
		} else {
			this.direcciones = [...this.direcciones, payload];
		}

		this.closeDireccionEditor();
	}

	closeDireccionEditor() {
		this.showDireccionEditor = false;
		this.direccionEditKey = null;
		this.direccionDraft = this.createDireccionRow();
	}

	handleAddDireccionElectronica() {
		this.direccionElectronicaDraft = this.createDireccionElectronicaRow();
		this.direccionElectronicaEditKey = null;
		this.showDireccionElectronicaEditor = true;
	}

	handleDireccionElectronicaRowAction(event) {
		const { action, row } = event.detail;

		if (action.name === 'edit') {
			this.direccionElectronicaDraft = this.createDireccionElectronicaRow(row);
			this.direccionElectronicaEditKey = row._key;
			this.showDireccionElectronicaEditor = true;
			return;
		}

		if (action.name === 'delete') {
			this.removeCollectionRow('direccionesElectronicas', row._key);
		}
	}

	handleDireccionElectronicaDraftChange(event) {
		if (event.target.name === 'EmailAddress') {
			this.applyReferenceEmailValidation(event.target);
		} else {
			event.target.setCustomValidity('');
		}
		this.direccionElectronicaDraft = {
			...this.direccionElectronicaDraft,
			[event.target.name]: event.target.value,
		};
	}

	saveDireccionElectronica() {
		const emailInput = this.template.querySelector('[data-direccion-electronica-input]');
		const emailValue = String(emailInput?.value ?? this.direccionElectronicaDraft?.EmailAddress ?? '');
		const emailAddress = emailValue.trim();
		if (!emailAddress) {
			this.dispatchEvent(
				new ShowToastEvent({
					title: 'Campo requerido',
					message: 'Debe completar el correo electronico.',
					variant: 'warning',
				})
			);
			return;
		}

		const validationMessage = this.getReferenceEmailValidationMessage(emailValue);
		const hasValidEmailFormat = emailInput ? this.applyReferenceEmailValidation(emailInput) : !validationMessage;

		if (!hasValidEmailFormat || (emailInput && !emailInput.checkValidity())) {
			return;
		}

		const payload = this.createDireccionElectronicaRow({
			...this.direccionElectronicaDraft,
			EmailAddress: emailAddress,
			_key: this.direccionElectronicaEditKey || this.direccionElectronicaDraft._key || this.generateRowKey('email'),
		});

		if (this.direccionElectronicaEditKey) {
			this.direccionesElectronicas = this.direccionesElectronicas.map((row) => (row._key === this.direccionElectronicaEditKey ? payload : row));
		} else {
			this.direccionesElectronicas = [...this.direccionesElectronicas, payload];
		}

		this.closeDireccionElectronicaEditor();
	}

	handleDireccionElectronicaEmailBlur(event) {
		const emailInput = event.target;
		setTimeout(() => this.applyReferenceEmailValidation(emailInput), 0);
	}

	isValidEmailAddress(value) {
		const emailAddress = String(value || '').trim();
		if (emailAddress.length > 254 || emailAddress.indexOf('@') !== emailAddress.lastIndexOf('@')) {
			return false;
		}

		const [localPart, domain] = emailAddress.split('@');
		if (
			!localPart ||
			localPart.length > 64 ||
			localPart.startsWith('.') ||
			localPart.endsWith('.') ||
			localPart.includes('..') ||
			!/^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+$/.test(localPart) ||
			!domain ||
			domain.length > 253
		) {
			return false;
		}

		const domainLabels = domain.split('.');
		return (
			domainLabels.length > 1 &&
			domainLabels.every((label) => label.length > 0 && label.length <= 63 && /^[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?$/.test(label))
		);
	}

	isValidReferenceEmailAddress(value) {
		if (!this.isValidEmailAddress(value)) {
			return false;
		}

		const [localPart, domain] = String(value || '')
			.trim()
			.split('@');
		const hasValidLocalPart = /^[a-zA-Z0-9]+(?:[._+-][a-zA-Z0-9]+)*$/.test(localPart);
		const topLevelDomain = domain.split('.').pop();
		const hasValidTopLevelDomain = /^(?:[a-zA-Z]{2,63}|xn--[a-zA-Z0-9-]{2,59})$/.test(topLevelDomain);

		return hasValidLocalPart && hasValidTopLevelDomain;
	}

	getReferenceEmailValidationMessage(value) {
		const inputValue = String(value || '');
		const emailAddress = inputValue.trim();
		if (!inputValue) {
			return '';
		}

		if (inputValue !== emailAddress || /[^a-zA-Z0-9@._+-]/.test(inputValue)) {
			return INVALID_REFERENCE_EMAIL_MESSAGE;
		}

		return this.isValidReferenceEmailAddress(emailAddress) ? '' : INVALID_EMAIL_MESSAGE;
	}

	closeDireccionElectronicaEditor() {
		this.showDireccionElectronicaEditor = false;
		this.direccionElectronicaEditKey = null;
		this.direccionElectronicaDraft = this.createDireccionElectronicaRow();
	}

	handleAddReferencia() {
		this.referenciaDraft = this.createReferenciaRow();
		this.referenciaEditKey = null;
		this.showReferenciaEditor = true;
	}

	handleReferenciaRowAction(event) {
		const { action, row } = event.detail;

		if (action.name === 'edit') {
			this.referenciaDraft = this.createReferenciaRow(row);
			this.referenciaEditKey = row._key;
			this.showReferenciaEditor = true;
			return;
		}

		if (action.name === 'delete') {
			this.removeCollectionRow('referencias', row._key);
		}
	}

	handleReferenciaDraftChange(event) {
		const fieldName = event.target.name;
		if (fieldName === 'FSC_Parentesco__c') {
			event.target.setCustomValidity('');
		} else if (fieldName === 'FSC_Email__c') {
			this.applyReferenceEmailValidation(event.target);
		} else if (fieldName === 'FSC_Telefono__c') {
			this.applyReferencePhoneValidation(event.target);
		} else if (fieldName === 'FSC_Identificacion__c') {
			event.target.setCustomValidity('');
		} else if (fieldName === 'FSC_TipoIdentificacion__c') {
			this.template.querySelector('lightning-input[name="FSC_Identificacion__c"]')?.setCustomValidity('');
		}

		const fieldValue =
			fieldName === 'FSC_Identificacion__c'
				? this.sanitizeIdentificacionByType(event.target.value, this.referenciaDraft?.FSC_TipoIdentificacion__c)
				: event.target.value;
		if (fieldName === 'FSC_Identificacion__c') {
			event.target.value = fieldValue;
		}

		const nextDraft = {
			...this.referenciaDraft,
			[fieldName]: fieldValue,
		};
		if (fieldName === 'FSC_TipoIdentificacion__c') {
			nextDraft.FSC_Identificacion__c = this.sanitizeIdentificacionByType(nextDraft.FSC_Identificacion__c, nextDraft.FSC_TipoIdentificacion__c);
		}
		nextDraft.Name = this.buildReferenciaName(nextDraft.FSC_FirstName__c, nextDraft.FSC_LastName__c);
		this.referenciaDraft = nextDraft;
	}

	handleReferenciaIdentificacionInput(event) {
		const sanitizedValue = this.sanitizeIdentificacionByType(event.target.value, this.referenciaDraft?.FSC_TipoIdentificacion__c);
		event.target.value = sanitizedValue;
		this.referenciaDraft = {
			...this.referenciaDraft,
			FSC_Identificacion__c: sanitizedValue,
		};
	}

	handleReferenciaIdentificacionKeyDown(event) {
		const identificationType = this.normalizeText(this.referenciaDraft?.FSC_TipoIdentificacion__c);
		if (identificationType === 'rnc') {
			this.handleNumericInputKeyDown(event);
			return;
		}

		if (!['cedula', 'pasaporte'].includes(identificationType)) {
			return;
		}

		if ((event.ctrlKey || event.metaKey) && ['a', 'c', 'v', 'x'].includes(event.key.toLowerCase())) {
			return;
		}

		const allowedControlKeys = ['Backspace', 'Delete', 'ArrowLeft', 'ArrowRight', 'Home', 'End', 'Tab'];
		const allowedCharacterPattern = identificationType === 'cedula' ? /^[0-9-]$/ : /^[A-Za-z0-9]$/;
		if (allowedControlKeys.includes(event.key) || allowedCharacterPattern.test(event.key)) {
			return;
		}

		event.preventDefault();
	}

	handleReferenciaEmailBlur(event) {
		const emailInput = event.target;
		setTimeout(() => this.applyReferenceEmailValidation(emailInput), 0);
	}

	applyReferenceEmailValidation(emailInput) {
		const emailValue = emailInput?.value ?? this.referenciaDraft?.FSC_Email__c;
		const validationMessage =
			this.getReferenceEmailValidationMessage(emailValue) || this.getReferenceContactDuplicateMessage('FSC_Email__c', emailValue);
		if (!emailInput) {
			return !validationMessage;
		}

		emailInput.setCustomValidity('');
		const hasNativeValidationError = !emailInput.checkValidity();
		emailInput.setCustomValidity(hasNativeValidationError ? '' : validationMessage);
		emailInput.reportValidity();
		return !validationMessage;
	}

	getReferenceContactDuplicateMessage(fieldName, value) {
		const normalizeValue = (contactValue) =>
			fieldName === 'FSC_Telefono__c'
				? this.sanitizeNumericInput(contactValue)
				: String(contactValue || '')
						.trim()
						.toLowerCase();
		const normalizedValue = normalizeValue(value);
		if (!normalizedValue) {
			return '';
		}

		const isDuplicate = this.referencias.some(
			(reference) => reference._key !== this.referenciaEditKey && normalizeValue(reference[fieldName]) === normalizedValue
		);
		if (!isDuplicate) {
			return '';
		}

		return fieldName === 'FSC_Telefono__c' ? 'Ya existe una referencia con el mismo telefono.' : 'Ya existe una referencia con el mismo email.';
	}

	applyReferencePhoneValidation(phoneInput) {
		const phoneValue = phoneInput?.value ?? this.referenciaDraft?.FSC_Telefono__c;
		const validationMessage = this.getReferenceContactDuplicateMessage('FSC_Telefono__c', phoneValue);
		phoneInput?.setCustomValidity(validationMessage);
		phoneInput?.reportValidity();
		return !validationMessage;
	}

	handleReferenciaTelefonoInput(event) {
		const sanitizedValue = this.sanitizeNumericInput(event.target.value);
		event.target.value = sanitizedValue;
		this.referenciaDraft = {
			...this.referenciaDraft,
			FSC_Telefono__c: sanitizedValue,
		};
		this.applyReferencePhoneValidation(event.target);
	}

	sanitizeIdentificacionByType(value, identificationType) {
		const nextValue = String(value || '');
		const normalizedIdentificationType = this.normalizeText(identificationType);
		if (normalizedIdentificationType === 'rnc') {
			return this.sanitizeNumericInput(nextValue).slice(0, 9);
		}

		if (normalizedIdentificationType === 'cedula') {
			return nextValue.replace(/[^0-9-]/g, '').slice(0, 11);
		}

		if (normalizedIdentificationType === 'pasaporte') {
			return this.sanitizePassportIdentification(nextValue);
		}

		return nextValue;
	}

	sanitizePassportIdentification(value) {
		let sanitizedValue = '';
		for (const character of String(value || '').toUpperCase()) {
			const isLetterPosition = sanitizedValue.length < 3;
			const isAllowedCharacter = isLetterPosition ? /^[A-Z]$/.test(character) : /^[0-9]$/.test(character);
			if (isAllowedCharacter) {
				sanitizedValue += character;
			}

			if (sanitizedValue.length === 9) {
				break;
			}
		}

		return sanitizedValue;
	}

	saveReferencia() {
		if (!this.validateUniqueReferenceRelationship()) {
			return;
		}

		if (!this.validateUniqueReferenceIdentification()) {
			return;
		}

		const emailInput = this.template.querySelector('[data-referencia-email-input]');
		const emailValue = String(emailInput?.value ?? this.referenciaDraft.FSC_Email__c ?? '');
		const emailAddress = emailValue.trim();
		const hasValidEmailFormat = this.applyReferenceEmailValidation(emailInput);
		const phoneInput = this.template.querySelector('lightning-input[name="FSC_Telefono__c"]');
		const hasUniquePhone = this.applyReferencePhoneValidation(phoneInput);

		if (!hasValidEmailFormat || (emailInput && !emailInput.checkValidity()) || !hasUniquePhone) {
			return;
		}

		if (!this.validateReferenciaInputs()) {
			this.dispatchEvent(
				new ShowToastEvent({
					title: 'Revise los campos de la referencia',
					message:
						'Complete los campos obligatorios y corrija los errores indicados. Si ingresa el tipo o el numero de identificacion, debe completar ambos.',
					variant: 'warning',
				})
			);
			return;
		}

		const payload = this.createReferenciaRow({
			...this.referenciaDraft,
			FSC_Email__c: emailAddress,
			_key: this.referenciaEditKey || this.referenciaDraft._key || this.generateRowKey('referencia'),
		});

		if (this.referenciaEditKey) {
			this.referencias = this.referencias.map((row) => (row._key === this.referenciaEditKey ? payload : row));
		} else {
			this.referencias = [...this.referencias, payload];
		}

		this.closeReferenciaEditor();
	}

	isReferenceRelationshipInUse(relationshipValue) {
		const normalizedRelationship = this.normalizeText(relationshipValue);
		return (
			UNIQUE_REFERENCE_RELATIONSHIPS.has(normalizedRelationship) &&
			this.referencias.some(
				(reference) => reference._key !== this.referenciaEditKey && this.normalizeText(reference.FSC_Parentesco__c) === normalizedRelationship
			)
		);
	}

	validateUniqueReferenceRelationship() {
		const isDuplicate = this.isReferenceRelationshipInUse(this.referenciaDraft.FSC_Parentesco__c);
		const message = isDuplicate ? 'El parentesco seleccionado solo puede utilizarse en una referencia.' : '';
		const relationshipInput = this.template.querySelector('lightning-combobox[name="FSC_Parentesco__c"]');
		relationshipInput?.setCustomValidity(message);
		relationshipInput?.reportValidity();
		if (isDuplicate) {
			this.dispatchEvent(new ShowToastEvent({ title: 'Parentesco duplicado', message, variant: 'warning' }));
		}
		return !isDuplicate;
	}

	validateUniqueReferenceIdentification() {
		const isDuplicate = this.isReferenceIdentificationInUse(
			this.referenciaDraft.FSC_TipoIdentificacion__c,
			this.referenciaDraft.FSC_Identificacion__c
		);
		const identificationInput = this.template.querySelector('lightning-input[name="FSC_Identificacion__c"]');
		identificationInput?.setCustomValidity(isDuplicate ? DUPLICATE_REFERENCE_IDENTIFICATION_MESSAGE : '');
		identificationInput?.reportValidity();

		if (isDuplicate) {
			this.dispatchEvent(
				new ShowToastEvent({
					title: 'Identificacion duplicada',
					message: DUPLICATE_REFERENCE_IDENTIFICATION_MESSAGE,
					variant: 'warning',
				})
			);
		}

		return !isDuplicate;
	}

	isReferenceIdentificationInUse(identificationType, identificationValue) {
		const normalizedType = this.normalizeText(identificationType);
		const normalizedValue = this.normalizeReferenceIdentification(identificationType, identificationValue);
		if (!normalizedType || !normalizedValue) {
			return false;
		}

		return this.referencias.some(
			(reference) =>
				reference._key !== this.referenciaEditKey &&
				this.normalizeText(reference.FSC_TipoIdentificacion__c) === normalizedType &&
				this.normalizeReferenceIdentification(reference.FSC_TipoIdentificacion__c, reference.FSC_Identificacion__c) === normalizedValue
		);
	}

	normalizeReferenceIdentification(identificationType, identificationValue) {
		const normalizedValue = String(identificationValue || '')
			.trim()
			.toUpperCase();
		return this.normalizeText(identificationType) === 'cedula' ? normalizedValue.replace(/-/g, '') : normalizedValue;
	}

	validateReferenciaInputs() {
		const inputs = [...this.template.querySelectorAll('[data-referencia-input]')];
		if (inputs.length === 0) {
			return (
				this.isCompleteReference(this.referenciaDraft) &&
				this.isReferenciaIdentificacionRequired === this.isReferenciaTipoIdentificacionRequired
			);
		}

		return inputs.reduce((isValid, input) => {
			input.reportValidity();
			return isValid && input.checkValidity();
		}, true);
	}

	closeReferenciaEditor() {
		this.showReferenciaEditor = false;
		this.referenciaEditKey = null;
		this.referenciaDraft = this.createReferenciaRow();
	}

	handleAddFacilidadOtraInstitucion() {
		if (this.alcanzoLimiteFacilidadesOtrasInstituciones) {
			this.mostrarNotificacionLimiteFacilidadesOtrasInstituciones();
			return;
		}

		this.facilidadOtraInstitucionDraft = this.createFacilidadOtraInstitucionRow();
		this.facilidadOtraInstitucionEditKey = null;
		this.showFacilidadOtraInstitucionEditor = true;
	}

	handleFacilidadOtraInstitucionRowAction(event) {
		const { action, row } = event.detail;

		if (action.name === 'edit') {
			this.facilidadOtraInstitucionDraft = this.createFacilidadOtraInstitucionRow(row);
			this.facilidadOtraInstitucionEditKey = row._key;
			this.showFacilidadOtraInstitucionEditor = true;
			return;
		}

		if (action.name === 'delete') {
			this.removeCollectionRow('facilidadesOtrasInstituciones', row._key);
		}
	}

	handleFacilidadOtraInstitucionDraftChange(event) {
		this.facilidadOtraInstitucionDraft = {
			...this.facilidadOtraInstitucionDraft,
			[event.target.name]: event.target.value,
		};
	}

	saveFacilidadOtraInstitucion() {
		if (!this.facilidadOtraInstitucionEditKey && this.alcanzoLimiteFacilidadesOtrasInstituciones) {
			this.mostrarNotificacionLimiteFacilidadesOtrasInstituciones();
			return;
		}

		if (!this.validateInputs('[data-facilidad-otra-institucion-input]')) {
			return;
		}

		const payload = this.createFacilidadOtraInstitucionRow({
			...this.facilidadOtraInstitucionDraft,
			_key: this.facilidadOtraInstitucionEditKey || this.facilidadOtraInstitucionDraft._key || this.generateRowKey('facilidad-otra'),
		});

		if (this.facilidadOtraInstitucionEditKey) {
			this.facilidadesOtrasInstituciones = this.facilidadesOtrasInstituciones.map((row) => {
				return row._key === this.facilidadOtraInstitucionEditKey ? payload : row;
			});
		} else {
			this.facilidadesOtrasInstituciones = [...this.facilidadesOtrasInstituciones, payload];
		}

		this.closeFacilidadOtraInstitucionEditor();
	}

	mostrarNotificacionLimiteFacilidadesOtrasInstituciones() {
		this.dispatchEvent(
			new ShowToastEvent({
				title: 'Límite de facilidades alcanzado',
				message: this.mensajeLimiteFacilidadesOtrasInstituciones,
				variant: 'error',
			})
		);
	}

	closeFacilidadOtraInstitucionEditor() {
		this.showFacilidadOtraInstitucionEditor = false;
		this.facilidadOtraInstitucionEditKey = null;
		this.facilidadOtraInstitucionDraft = this.createFacilidadOtraInstitucionRow();
	}

	syncStep1ValuesFromTemplate() {
		const tipoIdentificacionInput = this.template.querySelector('[data-step1-field="tipoIdentificacion"]');
		const numIdentificacionInput = this.template.querySelector('[data-step1-field="numIdentificacion"]');

		if (tipoIdentificacionInput) {
			this.tipoIdentificacion = tipoIdentificacionInput.value || '';
		}

		if (numIdentificacionInput) {
			this.numIdentificacion = numIdentificacionInput.value || '';
		}
	}

	validateStep1Inputs() {
		return this.validateInputs('[data-step1-input]');
	}

	validatePersonalDataInputs() {
		return this.validateInputs('[data-personal-input]');
	}

	validateLaborDataInputs() {
		return this.validateInputs('[data-laboral-input]');
	}

	validateInputs(selector) {
		const inputs = [...this.template.querySelectorAll(selector)];
		let firstInvalidInput;

		inputs.forEach((input) => {
			input.reportValidity();
			if (!input.checkValidity() && !firstInvalidInput) {
				firstInvalidInput = input;
			}
		});

		if (firstInvalidInput) {
			this.focusAndScrollToInvalidInput(firstInvalidInput);
		}

		return !firstInvalidInput;
	}

	focusAndScrollToInvalidInput(input) {
		input.focus();
		input.scrollIntoView({ behavior: 'smooth', block: 'center', inline: 'nearest' });
	}

	nextStep() {
		if (this.isLoadingApplicant) {
			return;
		}

		this.syncStep1ValuesFromTemplate();

		if (!this.validateStep1Inputs()) {
			return;
		}

		if (this.tipoIdentificacion && this.numIdentificacion) {
			const duplicate = this.applicants.some(
				(applicant) =>
					applicant.FSC_TipoIdentificacion__c === this.tipoIdentificacion && applicant.FSC_NumIdentificacion__c === this.numIdentificacion
			);
			if (duplicate) {
				this.dispatchEvent(
					new ShowToastEvent({
						title: 'Advertencia',
						message: 'Ya existe un solicitante con el mismo tipo y número de identificación.',
						variant: 'warning',
					})
				);
				return;
			}

			this.isLoadingApplicant = true;
			this.loadExistingApplicant()
				.then(() => {
					this.isLoadingApplicant = false;
					this.currentStep = '2';
				})
				.catch(() => {
					this.isLoadingApplicant = false;
					this.currentStep = '2';
				});
		}
	}

	async loadExistingApplicant() {
		try {
			const applicant = await getLoanApplicant({
				tipoId: this.tipoIdentificacion,
				numId: this.numIdentificacion,
			});
			if (applicant) {
				this.existingApplicant = applicant;
				this.existingApplicantId = applicant.Id || '';
				this.populateFields(applicant);
				this.isReadonly = true;
				this.isExistingInDB = !!applicant.Id;
			} else {
				this.existingApplicant = null;
				this.existingApplicantId = '';
				this.isReadonly = false;
				this.isExistingInDB = false;
			}
		} catch (error) {
			this.existingApplicant = null;
			this.existingApplicantId = '';
		}
	}

	populateFields(applicant) {
		if (applicant) {
			this.tipoSolicitante = applicant.FSC_TipoSolicitante__c || '';
			this.nombre = applicant.FSC_Nombre__c || '';
			this.primerApellido = applicant.FSC_PrimerApellido__c || '';
			this.segundoApellido = applicant.FSC_SegundoApellido__c || '';
			this.fechaNacimiento = applicant.FSC_FechaNacimiento__c || '';
			this.nacionalidad = applicant.FSC_Nacionalidad__c || '';
			this.estadoCivil = applicant.FSC_EstadoCivil__c || '';
			this.tipoVivienda = applicant.FSC_TipoVivienda__c || '';
			this.tiempoVivienda = this.normalizeDateValue(applicant.FSC_TiempoVivienda__c);
			this.ocupacion = applicant.FSC_Ocupacion__c || '';
			this.empresaLabora = applicant.FSC_EmpresaAnteriorLaboro__c || '';
			this.lugarLabora = applicant.FSC_LugarFondeLabora__c || '';
			this.tiempoLaborando = applicant.FSC_TiempoLaborando__c || '';
			this.empresaAnterior = applicant.FSC_EmpresaAnteriorLaboro__c || '';
			this.fuenteIngreso = applicant.FSC_FuenteIngreso__c || '';
			this.ingresosMensuales = this.normalizeDecimalValue(applicant.FSC_IngresosMensuales__c);
			this.otrosIngresos = applicant.FSC_OtrosIngresos__c || '';
			this.descripcionOtrosIngresos = applicant.FSC_DescripcionOtrosIngresos__c || '';
			this.montoPrestaciones = applicant.FSC_MontoPrestacionesLaborales__c || '';
			this.numeroDependientes = applicant.FSC_NumeroDependientes__c || '';
			this.tipoNegocio = applicant.FSC_TipoNegocio__c || '';
			this.clasificacionSIB = applicant.FSC_ClasificacionSIB__c || '';
			this.telefonos = this.normalizeRows(
				this.getRelatedRows(applicant, ['ContactPointPhone', 'Contact_Point_Phones', 'Contact_Point_Phones__r']),
				this.createTelefonoRow
			);
			this.direcciones = this.normalizeRows(
				this.getRelatedRows(applicant, ['ContactPointAddress', 'Contact_Point_Addresses', 'Contact_Point_Addresses__r']),
				this.createDireccionRow
			);
			this.direccionesElectronicas = this.normalizeRows(
				this.getRelatedRows(applicant, ['ContactPointEmail', 'Contact_Point_Emails', 'Contact_Point_Emails__r']),
				this.createDireccionElectronicaRow
			);
			this.referencias = this.normalizeRows(
				this.getRelatedRows(applicant, ['FSC_Referencias__c', 'Referencias', 'Referencias__r']),
				this.createReferenciaRow
			);
			this.facilidadesOtrasInstituciones = this.normalizeRows(
				applicant.FSC_Facilidad_Otra_Institucion__c,
				this.createFacilidadOtraInstitucionRow
			);
		}
	}

	async saveApplicant() {
		if (
			this.showTelefonoEditor ||
			this.showDireccionEditor ||
			this.showDireccionElectronicaEditor ||
			this.showReferenciaEditor ||
			this.showFacilidadOtraInstitucionEditor
		) {
			this.dispatchEvent(
				new ShowToastEvent({
					title: 'Advertencia',
					message: 'Debe guardar o cancelar la edicion de telefonos, direcciones, correos, referencias o facilidades antes de continuar.',
					variant: 'warning',
				})
			);
			return;
		}

		if (this.isEditingPrimaryAccountApplicant) {
			this.tipoSolicitante = 'Deudor';
		}

		if (excedeLimiteFacilidadesOtrasInstituciones(this.facilidadesOtrasInstituciones.length, this.limiteMaximoFacilidadesOtrasInstituciones)) {
			this.mostrarNotificacionLimiteFacilidadesOtrasInstituciones();
			return;
		}

		if (!this.tipoSolicitante) {
			this.dispatchEvent(
				new ShowToastEvent({
					title: 'Campo requerido',
					message: 'Debe seleccionar el tipo de solicitante.',
					variant: 'warning',
				})
			);
			return;
		}

		if (this.normalizeApplicantType(this.tipoSolicitante) === 'deudor' && this.hasAnotherDeudor()) {
			this.dispatchEvent(
				new ShowToastEvent({
					title: 'Accion no permitida',
					message: 'Ya existe un Deudor en la solicitud.',
					variant: 'warning',
				})
			);
			return;
		}

		if (!this.validatePersonalDataInputs()) {
			return;
		}

		if (!this.validateLaborDataInputs()) {
			this.dispatchEvent(
				new ShowToastEvent({
					title: 'Campos laborales requeridos',
					message: this.requiredLaborDataMessage,
					variant: 'warning',
				})
			);
			return;
		}

		if (this.normalizeApplicantType(this.tipoSolicitante) === 'deudor' && this.countCompleteReferences(this.referencias) < 2) {
			this.dispatchEvent(
				new ShowToastEvent({
					title: 'Referencias requeridas',
					message: 'El Deudor debe tener al menos dos referencias completas.',
					variant: 'warning',
				})
			);
			return;
		}

		const newApplicant = {
			...(this.isEdit ? this.existingApplicant || {} : {}),
			Name: this.buildApplicantName({
				FSC_Nombre__c: this.nombre,
				FSC_PrimerApellido__c: this.primerApellido,
				FSC_SegundoApellido__c: this.segundoApellido,
			}),
			FSC_TipoSolicitante__c: this.isEditingPrimaryAccountApplicant ? 'Deudor' : this.tipoSolicitante,
			FSC_TipoIdentificacion__c: this.tipoIdentificacion,
			FSC_NumIdentificacion__c: this.numIdentificacion,
			FSC_Nombre__c: this.nombre,
			FSC_PrimerApellido__c: this.primerApellido,
			FSC_SegundoApellido__c: this.segundoApellido,
			FSC_FechaNacimiento__c: this.fechaNacimiento,
			FSC_Nacionalidad__c: this.nacionalidad,
			FSC_EstadoCivil__c: this.estadoCivil,
			FSC_TipoVivienda__c: this.tipoVivienda,
			FSC_TiempoVivienda__c: this.tiempoVivienda,
			FSC_Ocupacion__c: this.ocupacion,
			FSC_EmpresaAnteriorLaboro__c: this.empresaAnterior,
			FSC_LugarFondeLabora__c: this.lugarLabora,
			FSC_TiempoLaborando__c: this.tiempoLaborando,
			FSC_FuenteIngreso__c: this.fuenteIngreso,
			FSC_IngresosMensuales__c: this.ingresosMensuales,
			FSC_OtrosIngresos__c: this.otrosIngresos,
			FSC_DescripcionOtrosIngresos__c: this.descripcionOtrosIngresos,
			FSC_TotalIngresos__c: this.totalIngresos,
			FSC_MontoPrestacionesLaborales__c: this.montoPrestaciones,
			FSC_NumeroDependientes__c: this.numeroDependientes,
			FSC_TipoNegocio__c: this.tipoNegocio,
			FSC_ClasificacionSIB__c: this.clasificacionSIB,
			ContactPointPhone: this.serializeCollectionRows(this.telefonos, ['FSC_TipoContacto__c', 'TelephoneNumber']),
			ContactPointAddress: this.serializeCollectionRows(this.direcciones, ['Name', 'Street', 'City', 'State', 'PostalCode', 'Country']),
			ContactPointEmail: this.serializeCollectionRows(this.direccionesElectronicas, ['EmailAddress']),
			FSC_Referencias__c: this.serializeReferencias(),
			FSC_Facilidad_Otra_Institucion__c: this.serializeFacilidadesOtrasInstituciones(),
		};

		if (this.normalizeApplicantType(newApplicant.FSC_TipoSolicitante__c) === 'deudor' && this.requiresAccountDebtor) {
			this.isSavingApplicant = true;
			try {
				await updateDebtorAccount({
					contextId: this.getAccountApplicantContextId(),
					applicantJson: JSON.stringify(newApplicant),
				});
			} catch (error) {
				this.dispatchEvent(
					new ShowToastEvent({
						title: 'No se pudo guardar el Deudor',
						message: error?.body?.message || error?.message || 'Ocurrio un error al actualizar la informacion del Account.',
						variant: 'error',
					})
				);
				return;
			} finally {
				this.isSavingApplicant = false;
			}
		}

		if (this.isEdit) {
			this.applicants = this.applicants.map((applicant) => {
				if (this.isSameApplicant(applicant, this.existingApplicant || newApplicant)) {
					return newApplicant;
				}
				return applicant;
			});
		} else {
			this.applicants = [...this.applicants, newApplicant];
		}

		this.notifyApplicantsChange();
		this.isEdit = false;
		this.closeModal();
	}

	handleRowAction(event) {
		const actionName = event.detail.action.name;
		const row = event.detail.row;
		if (actionName === 'edit') {
			this.existingApplicant = row;
			this.existingApplicantId = row.Id || '';
			this.tipoIdentificacion = row.FSC_TipoIdentificacion__c || '';
			this.numIdentificacion = row.FSC_NumIdentificacion__c || '';
			this.tipoSolicitante = row.FSC_TipoSolicitante__c || '';
			this.populateFields(row);
			this.isEditingPrimaryAccountApplicant = this.isPrimaryAccountApplicant(row);
			this.isReadonly = false;
			this.isExistingInDB = !!row.Id;
			this.isEdit = true;
			this.modalTitle = 'Modificar Solicitante';
			this.currentStep = '2';
			this.showModal = true;
		} else if (actionName === 'delete') {
			if (this.isPrimaryAccountApplicant(row)) {
				this.dispatchEvent(
					new ShowToastEvent({
						title: 'Accion no permitida',
						message: 'El Deudor asociado al Account de la solicitud no puede eliminarse.',
						variant: 'warning',
					})
				);
				return;
			}
			this.applicants = this.applicants.filter((applicant) => !this.isSameApplicant(applicant, row));
			this.notifyApplicantsChange();
		}
	}
}