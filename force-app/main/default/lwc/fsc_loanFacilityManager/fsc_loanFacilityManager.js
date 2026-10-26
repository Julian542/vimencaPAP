import { LightningElement, api, wire } from 'lwc';
import getCreditPolicyRules from '@salesforce/apex/FSC_CreditPolicyController.getRules';
import evaluateCreditPolicy from '@salesforce/apex/FSC_CreditPolicyController.evaluate';
import getLoanTermConfiguration from '@salesforce/apex/FSC_LoanFacilityController.getLoanTermConfiguration';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';
import getInsuranceRate from '@salesforce/apex/FSC_LoanFacilityController.getInsuranceRate';
import getGuaranteeConfiguration from '@salesforce/apex/FSC_LoanFacilityController.getGuaranteeConfiguration';
import getVehicleCatalog from '@salesforce/apex/FSC_LoanFacilityController.getVehicleCatalog';
import getInsuranceTypeOptions from '@salesforce/apex/FSC_LoanFacilityController.getGuaranteeTypeOptions';
import FACILITY_OBJECT from '@salesforce/schema/FSC_Facilidades_De_Credito__c';
import GUARANTEE_OBJECT from '@salesforce/schema/FSC_Garantia__c';
import INSURANCE_OBJECT from '@salesforce/schema/FSC_Seguro__c';
import FSC_TIPO_FACILIDAD_FIELD from '@salesforce/schema/FSC_Facilidades_De_Credito__c.FSC_Tipo_Facilidad__c';
import FSC_FACILIDAD_FIELD from '@salesforce/schema/FSC_Facilidades_De_Credito__c.FSC_Facilidad__c';
import FSC_ESTADO_DEL_VEHICULO_FIELD from '@salesforce/schema/FSC_Facilidades_De_Credito__c.FSC_EstadoDelVehiculo__c';
import FSC_TIPO_MODALIDAD_FIELD from '@salesforce/schema/FSC_Facilidades_De_Credito__c.FSC_Tipo_Modalidad__c';
import FSC_LINEAS_FINANCIERAS_FIELD from '@salesforce/schema/FSC_Facilidades_De_Credito__c.FSC_Lineas_Financieras_Empresas__c';
import FSC_FORMA_PAGO_FIELD from '@salesforce/schema/FSC_Facilidades_De_Credito__c.FSC_Forma_De_Pago__c';
import FSC_CLASE_GARANTIA_FIELD from '@salesforce/schema/FSC_Garantia__c.FSC_Clase_de_Garantia__c';
import FSC_PROPOSITO_GARANTIA_HIPOTECARIO_FIELD from '@salesforce/schema/FSC_Garantia__c.FSC_Proposito_Garantia_Hipotecario__c';
import FSC_TASADO_POR_FIELD from '@salesforce/schema/FSC_Garantia__c.FSC_Tasado_Por__c';
import FSC_CONCESIONARIO_FIELD from '@salesforce/schema/FSC_Garantia__c.FSC_Concesionario__c';
import FSC_MARCA_VEHICULO_FIELD from '@salesforce/schema/FSC_Garantia__c.FSC_Marca_Vehiculo__c';
import FSC_MODELO_VEHICULO_FIELD from '@salesforce/schema/FSC_Garantia__c.FSC_Modelo_Vehiculo__c';
import FSC_FUENTE_DE_INGRESOS_FIELD from '@salesforce/schema/FSC_Seguro__c.FSC_Fuente_de_Ingresos__c';

const YES_NO_OPTIONS = [
	{ label: 'Si', value: 'true' },
	{ label: 'No', value: 'false' },
];
const EXTERNAL_APPRAISER_OPTIONS = [
	{ label: 'SI', value: 'true' },
	{ label: 'NO', value: 'false' },
];
const FORMA_PAGO_CUOTAS_MENSUALES_IGUALES = 'Cuotas mensuales, iguales y consecutivas, contentivas de capital e intereses cada una';
const FORMA_PAGO_CAPITAL_VENCIMIENTO = 'Intereses mensuales sobre saldos insolutos de capital (Capital a vencimiento)';
const INSURANCE_TYPE_LIFE = 'seguro de vida';
const INSURANCE_TYPE_FIRE = 'seguro de incendio';
const LOAN_TYPE_CONSUMO = 'consumo';
const LOAN_TYPE_HIPOTECARIO = 'hipotecario';
const LOAN_TYPE_VEHICULO = 'vehiculo';
const DEFAULT_FACILITY_CONSUMO = 'CONSUMO - 401';
const NEW_VEHICLE_GUARANTEE_CLASS = 'VEHICULOS NUEVOS -P2';
const HIPOTECARIO_FACILITY_DOLARES = 'HIPOTECARIO PARA LA VIVIENDA DOLARES - 453';
const HIPOTECARIO_FACILITY_VALUES = Object.freeze(['HIPOTECARIOS PARA LA VIVIENDA - 402', HIPOTECARIO_FACILITY_DOLARES]);
const MONEDA_PESOS = '1';
const MONEDA_DOLARES = '2';
const OMNI_SUBTYPE_CONSUMO = 'solicitudcreditoconsumo';
const OMNI_SUBTYPE_HIPOTECARIO = 'solicitudcreditohipotecario';
const OMNI_SUBTYPE_VEHICULO = 'solicitudcreditovehiculo';

const EMPTY_GUARANTEE = Object.freeze({
	FSC_Clase_de_Garantia__c: '',
	FSC_Tipo_de_Garantia__c: '',
	FSC_Descripcion_de_la_Garantia__c: '',
	FSC_Proposito_Garantia_Hipotecario__c: '',
	FSC_Valor_Tasado__c: '',
	FSC_Valor_Mejoras__c: '',
	FSC_SaldoPrimeraHipoteca__c: '',
	FSC_EsTasadorExterno__c: null,
	FSC_NombreTasadorExterno__c: '',
	FSC_Tasado_Por__c: '',
	FSC_Fecha_Tasacion__c: '',
	FSC_Monto_Inicial_Avance_Pagado__c: '',
	FSC_Valor_Inmueble__c: '',
	FSC_Precio_de_Venta__c: '',
	FSC_Metros_Cuadrados_de_Construccion__c: '',
	FSC_Ubicacion__c: '',
	FSC_Tipo_de_Inmueble__c: '',
	FSC_Es_Concesionario_Dealer__c: null,
	FSC_Concesionario__c: '',
	FSC_Marca_Vehiculo__c: '',
	FSC_Modelo_Vehiculo__c: '',
	FSC_Ano_Vehiculo__c: '',
	FSC_Color_Vehiculo__c: '',
	FSC_Numero_Chasis_Vehiculo__c: '',
	FSC_Serial_Motor_Vehiculo__c: '',
	FSC_Numero_Placa_Vehiculo__c: '',
	FSC_Numero_Matricula__c: '',
	FSC_Fecha_Expedicion_Vehiculo__c: '',
	FSC_Valor_Vehiculo__c: '',
});

const EMPTY_INSURANCE = Object.freeze({
	FSC_Tipo_de_Seguro__c: '',
	FSC_Monto_de_la_Prima__c: '',
	FSC_Seguro_Desempleo__c: null,
	FSC_Monto_Prima_Desempleo__c: '',
	FSC_Fuente_de_Ingresos__c: '',
});

export default class FscLoanFacilityManager extends OmniscriptBaseMixin(LightningElement) {
	facilities = [];
	yesNoOptions = YES_NO_OPTIONS;
	tasadorExternoOptions = EXTERNAL_APPRAISER_OPTIONS;
	tipoFacilidadOptions = [];
	allFacilidadOptions = [];
	estadoDelVehiculoOptions = [];
	tipoModalidadOptions = [];
	lineasFinancierasOptions = [];
	formaPagoOptions = [];
	claseGarantiaOptions = [];
	catalogClassOptions = [];
	vehicleCatalog = [];
	guaranteeConfigurationByClass = {};
	isGuaranteeConfigurationReady = false;
	guaranteeConfigurationError = '';
	loanTermConfiguration;
	loanTermConfigurationError = '';
	propositoGarantiaOptions = [];
	creditPolicyRules = [];
	creditPolicyError = '';
	creditPolicyResult;
	creditPolicyRequestKey = '';
	creditPolicyValidatedKey = '';
	creditPolicyTimer;
	creditPolicyDisconnected = false;
	tasadoPorOptions = [];
	concesionarioOptions = [];
	modeloVehiculoPicklistData;
	tipoSeguroOptions = [];
	fuenteIngresosOptions = [];
	marcaVehiculoPicklistOptions = [];
	isInsuranceRateLoading = false;
	insuranceRateRequestId = 0;
	lastNotifiedFacilitiesJson = '';
	attemptedInsuranceValidation = false;
	attemptedGuaranteeValidation = false;

	editRowKey = null;

	tipoFacilidad = '';
	facilidad = '';
	estadoDelVehiculo = '';
	prestamoConvenio = null;
	tipoModalidad = '';
	lineasFinancierasEmpresas = '';
	lineasFinancierasSearchTerm = '';
	showLineasFinancierasDropdown = false;
	lineasFinancierasBlurTimeout = null;
	prestamoConGarantia = false;
	requiereContratoPagareNotarial = null;
	descripcionPropositoFacilidad = '';

	montoSolicitado = '';
	plazoMeses = '';
	tasaInteres = '';
	tasaFija = null;
	tiempoTasaFija = '';
	formaPago = '';
	montoCuota = '';

	guaranteeRows = [];
	insuranceRows = [];
	guaranteeDraft = this.createGuaranteeDraft();
	insuranceDraft = this.createInsuranceDraft();
	showGuaranteeEditor = false;
	showInsuranceEditor = false;
	guaranteeEditKey = null;
	insuranceEditKey = null;

	rowKeyCounter = 0;
	_tipoCredito = '';

	@api
	set tipoCredito(value) {
		this._tipoCredito = value || '';
		this.applyFacilityRules();
	}

	get tipoCredito() {
		return this._tipoCredito;
	}

	@api
	set value(value) {
		const facilities = this.normalizeFacilities(this.extractFacilities(value));
		this.facilities = facilities;

		if (this.stringifyFacilities(facilities) !== this.lastNotifiedFacilitiesJson) {
			this.loadPrimaryFacility();
		}
	}

	get value() {
		return this.facilities;
	}

	@wire(getObjectInfo, { objectApiName: FACILITY_OBJECT })
	facilityObjectInfo;

	@wire(getLoanTermConfiguration)
	wiredLoanTermConfiguration({ data, error }) {
		if (data) {
			this.loanTermConfiguration = data;
			this.loanTermConfigurationError = '';
			this.updatePlazoMesesValidity();
		} else if (error) {
			this.loanTermConfiguration = undefined;
			this.loanTermConfigurationError = error.body?.message || 'No se pudo cargar la configuración de plazos de crédito.';
			this.updatePlazoMesesValidity();
		}
	}

	@wire(getGuaranteeConfiguration)
	wiredGuaranteeConfiguration({ error, data }) {
		if (data) {
			const configurationByClass = {};
			data.forEach((configuration) => {
				// Los textos historicos de la clase apuntan a la misma configuracion que la descripcion del API.
				(configuration.aliases || []).forEach((alias) => {
					configurationByClass[this.normalizeKey(alias)] = configuration;
				});
				configurationByClass[this.normalizeKey(configuration.value)] = configuration;
			});
			this.guaranteeConfigurationByClass = configurationByClass;
			this.catalogClassOptions = data
				.filter((configuration) => configuration.fromCatalog)
				.map((configuration) => ({ label: configuration.value, value: configuration.value }));
			this.isGuaranteeConfigurationReady = data.length > 0;
			this.guaranteeConfigurationError = data.length ? '' : 'No hay clases de garantia configuradas. Contacte al administrador.';
		} else if (error) {
			this.guaranteeConfigurationByClass = {};
			this.catalogClassOptions = [];
			this.isGuaranteeConfigurationReady = false;
			this.guaranteeConfigurationError = 'No fue posible cargar la configuracion de garantias. Contacte al administrador.';
			this.logPicklistError('configuracion de garantias desde metadata', error);
		}
	}

	@wire(getObjectInfo, { objectApiName: GUARANTEE_OBJECT })
	guaranteeObjectInfo;

	@wire(getObjectInfo, { objectApiName: INSURANCE_OBJECT })
	insuranceObjectInfo;

	@wire(getPicklistValues, {
		recordTypeId: '$facilityObjectInfo.data.defaultRecordTypeId',
		fieldApiName: FSC_TIPO_FACILIDAD_FIELD,
	})
	wiredTipoFacilidadPicklist({ error, data }) {
		if (data) {
			this.tipoFacilidadOptions = data.values;
		} else if (error) {
			this.logPicklistError('tipo facilidad', error);
		}
	}

	@wire(getPicklistValues, {
		recordTypeId: '$facilityObjectInfo.data.defaultRecordTypeId',
		fieldApiName: FSC_FACILIDAD_FIELD,
	})
	wiredFacilidadPicklist({ error, data }) {
		if (data) {
			this.allFacilidadOptions = data.values;
			this.applyFacilityRules();
		} else if (error) {
			this.logPicklistError('facilidad', error);
		}
	}

	@wire(getPicklistValues, {
		recordTypeId: '$facilityObjectInfo.data.defaultRecordTypeId',
		fieldApiName: FSC_ESTADO_DEL_VEHICULO_FIELD,
	})
	wiredEstadoDelVehiculoPicklist({ error, data }) {
		if (data) {
			this.estadoDelVehiculoOptions = data.values;
		} else if (error) {
			this.logPicklistError('estado del vehiculo', error);
		}
	}

	@wire(getPicklistValues, {
		recordTypeId: '$facilityObjectInfo.data.defaultRecordTypeId',
		fieldApiName: FSC_TIPO_MODALIDAD_FIELD,
	})
	wiredTipoModalidadPicklist({ error, data }) {
		if (data) {
			this.tipoModalidadOptions = data.values;
		} else if (error) {
			this.logPicklistError('tipo modalidad', error);
		}
	}

	@wire(getPicklistValues, {
		recordTypeId: '$facilityObjectInfo.data.defaultRecordTypeId',
		fieldApiName: FSC_LINEAS_FINANCIERAS_FIELD,
	})
	wiredLineasFinancierasPicklist({ error, data }) {
		if (data) {
			this.lineasFinancierasOptions = data.values;
			this.syncLineasFinancierasSearchTerm();
			this.updateLineasFinancierasValidity();
		} else if (error) {
			this.logPicklistError('lineas financieras', error);
		}
	}

	@wire(getPicklistValues, {
		recordTypeId: '$facilityObjectInfo.data.defaultRecordTypeId',
		fieldApiName: FSC_FORMA_PAGO_FIELD,
	})
	wiredFormaPagoPicklist({ error, data }) {
		if (data) {
			this.formaPagoOptions = data.values;
			if (this.isTipoCreditoHipotecario && !this.formaPago) {
				this.formaPago = this.getDefaultFormaPagoValue();
				this.calculateInstallment();
			}
		} else if (error) {
			this.logPicklistError('forma de pago', error);
		}
	}

	@wire(getPicklistValues, {
		recordTypeId: '$guaranteeObjectInfo.data.defaultRecordTypeId',
		fieldApiName: FSC_CLASE_GARANTIA_FIELD,
	})
	wiredClaseGarantiaPicklist({ error, data }) {
		if (data) {
			this.claseGarantiaOptions = data.values;
		} else if (error) {
			this.logPicklistError('clase de garantia', error);
		}
	}

	@wire(getPicklistValues, {
		recordTypeId: '$guaranteeObjectInfo.data.defaultRecordTypeId',
		fieldApiName: FSC_PROPOSITO_GARANTIA_HIPOTECARIO_FIELD,
	})
	wiredPropositoGarantiaPicklist({ error, data }) {
		if (data) {
			this.propositoGarantiaOptions = data.values;
		} else if (error) {
			this.logPicklistError('proposito garantia hipotecario', error);
		}
	}

	@wire(getPicklistValues, {
		recordTypeId: '$guaranteeObjectInfo.data.defaultRecordTypeId',
		fieldApiName: FSC_TASADO_POR_FIELD,
	})
	wiredTasadoPorPicklist({ error, data }) {
		if (data) {
			this.tasadoPorOptions = data.values;
		} else if (error) {
			this.logPicklistError('tasado por', error);
		}
	}

	@wire(getPicklistValues, {
		recordTypeId: '$guaranteeObjectInfo.data.defaultRecordTypeId',
		fieldApiName: FSC_CONCESIONARIO_FIELD,
	})
	wiredConcesionarioPicklist({ error, data }) {
		if (data) {
			this.concesionarioOptions = data.values;
		} else if (error) {
			this.logPicklistError('concesionario', error);
		}
	}

	@wire(getPicklistValues, {
		recordTypeId: '$guaranteeObjectInfo.data.defaultRecordTypeId',
		fieldApiName: FSC_MARCA_VEHICULO_FIELD,
	})
	wiredMarcaVehiculoPicklist({ error, data }) {
		if (data) {
			this.marcaVehiculoPicklistOptions = data.values;
		} else if (error) {
			this.logPicklistError('marca vehiculo', error);
		}
	}

	@wire(getVehicleCatalog)
	wiredVehicleCatalog({ error, data }) {
		if (data) {
			this.vehicleCatalog = data;
			this.syncVehicleModelWithOptions();
		} else if (error) {
			// Sin catalogo se siguen usando los picklists historicos de marca y modelo.
			this.vehicleCatalog = [];
			this.logPicklistError('catalogo de vehiculos', error);
		}
	}

	@wire(getPicklistValues, {
		recordTypeId: '$guaranteeObjectInfo.data.defaultRecordTypeId',
		fieldApiName: FSC_MODELO_VEHICULO_FIELD,
	})
	wiredModeloVehiculoPicklist({ error, data }) {
		if (data) {
			this.modeloVehiculoPicklistData = data;
			this.syncVehicleModelWithOptions();
		} else if (error) {
			this.logPicklistError('modelo vehiculo', error);
		}
	}

	@wire(getInsuranceTypeOptions, { facilityValue: '$facilidad', loanType: '$loanRequestType' })
	wiredTipoSeguroOptions({ error, data }) {
		if (data) {
			this.tipoSeguroOptions = data;
			this.recalculateInsuranceDraftPremium();
		} else if (error) {
			this.logPicklistError('tipo de seguro', error);
		}
	}

	@wire(getPicklistValues, {
		recordTypeId: '$insuranceObjectInfo.data.defaultRecordTypeId',
		fieldApiName: FSC_FUENTE_DE_INGRESOS_FIELD,
	})
	wiredFuenteIngresosPicklist({ error, data }) {
		if (data) {
			this.fuenteIngresosOptions = data.values;
		} else if (error) {
			this.logPicklistError('fuente de ingresos', error);
		}
	}

	connectedCallback() {
		this.creditPolicyDisconnected = false;
		this.hydrateFacilitiesFromOmni();
		this.applyFacilityRules();
	}

	validateForNavigation(reportErrors) {
		if (reportErrors) {
			this.attemptedInsuranceValidation = true;
			this.attemptedGuaranteeValidation = true;
		}

		if (this.isFacilitySaveDisabled) {
			if (reportErrors) {
				//this.showToast('Advertencia', 'Debe guardar o cancelar la edicion de garantias y seguros antes de continuar.', 'warning');
			}
			return false;
		}

		if (!this.validateFacilityInputs(reportErrors)) {
			return false;
		}

		if (!this.validateFacility(reportErrors)) {
			return false;
		}

		if (!this.validateMontoPrestacionesParaPrestamoConvenio(reportErrors)) {
			return false;
		}

		if (!this.validateFacilidadesExternasParaConsolidacion(reportErrors)) {
			return false;
		}

		if (!this.validateRequiredGuarantees(reportErrors)) {
			return false;
		}

		if (!this.validateRequiredInsurances(reportErrors)) {
			return false;
		}

		if (reportErrors) {
			this.persistFacilityDraft();
			return this.facilities.length > 0;
		}

		return this.hasFacilityDraftValue();
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
		const isComponentValid = this.validateForNavigation(reportErrors);
		this.isValid = isComponentValid;
		this._showValidation = reportErrors && !isComponentValid;
		return isComponentValid;
	}

	get guaranteeColumns() {
		return [
			{
				label: 'Clase de Garantia',
				fieldName: 'FSC_Clase_de_Garantia__c',
			},
			{ label: 'Tipo de Garantia', fieldName: 'FSC_Tipo_de_Garantia__c' },
			{
				label: 'Descripcion de la Garantia',
				fieldName: 'FSC_Descripcion_de_la_Garantia__c',
			},
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

	get insuranceColumns() {
		return [
			{ label: 'Tipo de Seguro', fieldName: 'FSC_Tipo_de_Seguro__c' },
			{
				label: 'Monto de la Prima',
				fieldName: 'FSC_Monto_de_la_Prima__c',
				type: 'number',
				typeAttributes: {
					minimumFractionDigits: 2,
					maximumFractionDigits: 2,
				},
			},
			{
				label: 'Monto Prima Desempleo',
				fieldName: 'FSC_Monto_Prima_Desempleo__c',
				type: 'number',
				typeAttributes: {
					minimumFractionDigits: 2,
					maximumFractionDigits: 2,
				},
			},
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

	get hasGuarantees() {
		return this.guaranteeRows.length > 0;
	}

	get showRequiredGuaranteeError() {
		return this.attemptedGuaranteeValidation && !!this.requiredGuaranteeMessage;
	}

	get requiredGuaranteeMessage() {
		return this.isTipoCreditoHipotecario && !this.hasGuarantees
			? 'Debe agregar al menos una garantia para continuar con la solicitud hipotecaria.'
			: '';
	}

	get hasInsurances() {
		return this.insuranceRows.length > 0;
	}

	get showRequiredInsuranceError() {
		return this.attemptedInsuranceValidation && !!this.requiredInsuranceMessage;
	}

	get requiredInsuranceMessage() {
		const missingInsurances = this.getMissingRequiredInsurances();
		if (missingInsurances.length === 0) {
			return '';
		}

		if (this.loanRequestType === LOAN_TYPE_VEHICULO) {
			return 'Debe agregar al menos un seguro de vehiculo.';
		}

		return `Debe agregar los seguros obligatorios: ${missingInsurances.join(', ')}.`;
	}

	get prestamoConvenioValue() {
		return this.booleanToRadioValue(this.prestamoConvenio);
	}

	get prestamoConGarantiaValue() {
		return this.booleanToRadioValue(this.prestamoConGarantia);
	}

	get requiereContratoValue() {
		return this.booleanToRadioValue(this.getRequiereContratoValue());
	}

	get formaPagoValue() {
		return this.getFormaPagoValue();
	}

	get requiereContratoLabel() {
		return this.isTipoCreditoHipotecario ? 'Requiere Contrato?' : '¿Requiere Pagaré Notarial?';
	}

	get isRequiereContratoDisabled() {
		return this.isTipoCreditoHipotecario;
	}

	get isFormaPagoDisabled() {
		return this.isTipoCreditoHipotecario;
	}

	get tasaFijaValue() {
		return this.booleanToRadioValue(this.tasaFija);
	}

	get showTiempoTasaFija() {
		return this.tasaFija === true;
	}

	get hasTipoFacilidadSelected() {
		return !!this.tipoFacilidad;
	}

	get hasFacilidadSelected() {
		return !!this.facilidad;
	}

	get showFacilidadField() {
		return !this.usesDefaultConsumoFacility;
	}

	get facilidadOptions() {
		if (!this.isTipoCreditoHipotecario) {
			return this.allFacilidadOptions;
		}

		return this.allFacilidadOptions.filter((option) => HIPOTECARIO_FACILITY_VALUES.includes(option.value));
	}

	get showPrestamoConvenioFields() {
		return this.loanRequestType !== LOAN_TYPE_HIPOTECARIO;
	}

	get hasPrestamoConvenioSelected() {
		return this.showPrestamoConvenioFields && this.prestamoConvenio;
	}

	get filteredLineasFinancierasOptions() {
		const searchTerm = this.normalizeText(this.lineasFinancierasSearchTerm);
		if (!searchTerm) {
			return this.lineasFinancierasOptions;
		}

		return this.lineasFinancierasOptions.filter((option) => {
			const label = this.normalizeText(option.label);
			const value = this.normalizeText(option.value);
			return label.includes(searchTerm) || value.includes(searchTerm);
		});
	}

	get hasFilteredLineasFinancierasOptions() {
		return this.filteredLineasFinancierasOptions.length > 0;
	}

	get showLineasFinancierasOptions() {
		return this.showLineasFinancierasDropdown;
	}

	get isTipoCreditoVehiculo() {
		return this.tipoCredito === 'Vehiculo';
	}

	get isTipoCreditoHipotecario() {
		return this.loanRequestType === LOAN_TYPE_HIPOTECARIO;
	}

	get monedaFacilidad() {
		if (this.loanRequestType === LOAN_TYPE_CONSUMO) return MONEDA_PESOS;
		if (!this.isTipoCreditoHipotecario || !HIPOTECARIO_FACILITY_VALUES.includes(this.facilidad)) {
			return null;
		}
		return this.facilidad === HIPOTECARIO_FACILITY_DOLARES ? MONEDA_DOLARES : MONEDA_PESOS;
	}

	get montoSolicitadoLabel() {
		return this.withSimboloMoneda('Monto Solicitado');
	}

	get montoCuotaLabel() {
		return this.withSimboloMoneda('Monto de la Cuota');
	}

	withSimboloMoneda(label) {
		const moneda = this.monedaFacilidad;
		if (!moneda) {
			return label;
		}
		return `${label} (${moneda === MONEDA_DOLARES ? 'US$' : 'RD$'})`;
	}

	get isTipoCreditoConGarantiaObligatoria() {
		return [LOAN_TYPE_HIPOTECARIO, LOAN_TYPE_VEHICULO].includes(this.loanRequestType);
	}

	get usesDefaultConsumoFacility() {
		return [LOAN_TYPE_CONSUMO, LOAN_TYPE_VEHICULO].includes(this.loanRequestType);
	}

	get maxLoanTermMonths() {
		if (this.usesCreditPolicy && this.currentCreditPolicyResult?.maxMonths) return this.currentCreditPolicyResult.maxMonths;
		if (this.loanRequestType === LOAN_TYPE_CONSUMO) {
			return this.loanTermConfiguration?.consumoMaxMonths || 0;
		}
		if (this.loanRequestType === LOAN_TYPE_VEHICULO) {
			return this.vehicleLoanYears.length
				? this.getVehicleMaxMonths(this.loanTermConfiguration, this.vehicleLoanYears)
				: this.loanTermConfiguration?.vehicleRanges[0]?.maxMonths || 0;
		}
		return 999;
	}

	getVehicleMaxMonths(configuration, vehicleYears) {
		if (!configuration?.vehicleRanges?.length || !vehicleYears?.length) {
			return 0;
		}
		let maxMonths = 999;
		for (const value of vehicleYears) {
			const year = Number(value);
			if (!/^\d{4}$/.test(String(value)) || !Number.isInteger(year)) {
				return 0;
			}
			const age = configuration.referenceYear - year;
			const range = configuration.vehicleRanges.find((item) => age >= item.ageFrom && age <= item.ageTo);
			if (!range) {
				return 0;
			}
			maxMonths = Math.min(maxMonths, range.maxMonths);
		}
		return maxMonths;
	}

	get vehicleLoanYears() {
		return this.guaranteeRows.filter((row) => this.hasValue(row.FSC_Ano_Vehiculo__c)).map((row) => row.FSC_Ano_Vehiculo__c);
	}

	get loanTermPolicyMessage() {
		if (this.usesCreditPolicy) return this.currentCreditPolicyResult?.termMessage || '';
		if (![LOAN_TYPE_CONSUMO, LOAN_TYPE_VEHICULO].includes(this.loanRequestType)) {
			return '';
		}
		if (!this.loanTermConfiguration) {
			return this.loanTermConfigurationError || 'Espere a que cargue la configuración de plazos de crédito.';
		}
		if (this.loanRequestType === LOAN_TYPE_VEHICULO) {
			if (!this.vehicleLoanYears.length) {
				return 'Agregue la garantía del vehículo e indique su año para determinar el plazo máximo.';
			}
			if (!this.maxLoanTermMonths) {
				return 'El año del vehículo está fuera del rango de antigüedad permitido.';
			}
		}
		return '';
	}

	get loanTermHelpText() {
		if (this.usesCreditPolicy && this.currentCreditPolicyResult?.minMonths) {
			return `Plazo permitido: ${this.currentCreditPolicyResult.minMonths} a ${this.currentCreditPolicyResult.maxMonths} meses.`;
		}
		if (this.usesCreditPolicy && !this.currentCreditPolicyResult) {
			return 'Validando límites del crédito...';
		}
		return this.loanTermPolicyMessage || `Plazo máximo: ${this.maxLoanTermMonths} meses.`;
	}

	applyFacilityRules() {
		if (this.isTipoCreditoConGarantiaObligatoria) {
			this.prestamoConGarantia = true;
		}

		if (this.usesDefaultConsumoFacility) {
			this.facilidad = DEFAULT_FACILITY_CONSUMO;
			return;
		}

		if (this.isTipoCreditoHipotecario && this.facilidad && !HIPOTECARIO_FACILITY_VALUES.includes(this.facilidad)) {
			this.facilidad = '';
		}
	}

	getRequiereContratoValue() {
		return this.isTipoCreditoHipotecario ? true : this.requiereContratoPagareNotarial;
	}

	getDefaultFormaPagoValue() {
		return this.formaPagoOptions[0]?.value || '';
	}

	getFormaPagoValue() {
		return this.isTipoCreditoHipotecario ? this.getDefaultFormaPagoValue() : this.formaPago;
	}

	get isPrestamoConGarantiaDisabled() {
		return this.isTipoCreditoConGarantiaObligatoria || !this.hasTipoFacilidadSelected;
	}

	get isEstadoDelVehiculoDisabled() {
		return !this.isTipoCreditoVehiculo;
	}

	get isAddGuaranteeDisabled() {
		return this.prestamoConGarantia !== true || !this.isGuaranteeConfigurationReady;
	}

	get hasGuaranteeClassSelected() {
		return !!this.guaranteeDraft.FSC_Clase_de_Garantia__c;
	}

	get garantiaClaseOptions() {
		const classOptions = this.catalogClassOptions.length ? this.catalogClassOptions : this.claseGarantiaOptions;
		const existingGroup = this.getExistingSpecialGuaranteeGroup();
		if (!existingGroup) {
			return classOptions;
		}

		return classOptions.filter((option) => {
			const optionGroup = this.getGuaranteeGroup(option.value);
			return !optionGroup || optionGroup === existingGroup;
		});
	}

	get guaranteeTypeOptions() {
		return this.getConfirmedGuaranteeTypeOptions(this.guaranteeDraft.FSC_Clase_de_Garantia__c);
	}

	get isGuaranteeTypeDisabled() {
		return !this.hasGuaranteeClassSelected || this.guaranteeTypeOptions.length === 0;
	}

	get isRealEstateGuarantee() {
		return this.isRealEstateGuaranteeClass(this.guaranteeDraft.FSC_Clase_de_Garantia__c);
	}

	get isVehicleGuarantee() {
		return this.isVehicleGuaranteeClass(this.guaranteeDraft.FSC_Clase_de_Garantia__c);
	}

	get showGuaranteeDescription() {
		return !this.isRealEstateGuarantee && !this.isVehicleGuarantee;
	}

	get isDealerGuarantee() {
		return this.isVehicleGuarantee && this.guaranteeDraft.FSC_Es_Concesionario_Dealer__c === true;
	}

	get fechaTasacionMaxima() {
		const today = new Date();
		const year = today.getFullYear();
		const month = String(today.getMonth() + 1).padStart(2, '0');
		const day = String(today.getDate()).padStart(2, '0');
		return `${year}-${month}-${day}`;
	}

	get anioVehiculoMinimo() {
		if (this.loanRequestType === LOAN_TYPE_VEHICULO && this.loanTermConfiguration) {
			const ranges = this.loanTermConfiguration.vehicleRanges;
			const maxAge = this.isNewVehicleGuarantee ? ranges[0].ageTo : ranges[ranges.length - 1].ageTo;
			return this.anioVehiculoMaximo - maxAge;
		}
		return this.isNewVehicleGuarantee ? this.anioVehiculoMaximo - 1 : 1900;
	}

	get anioVehiculoMaximo() {
		if (this.loanRequestType === LOAN_TYPE_VEHICULO && this.loanTermConfiguration) {
			return this.loanTermConfiguration.referenceYear;
		}
		return Number(this.fechaTasacionMaxima.slice(0, 4));
	}

	get isNewVehicleGuarantee() {
		return this.normalizeKey(this.guaranteeDraft.FSC_Clase_de_Garantia__c) === this.normalizeKey(NEW_VEHICLE_GUARANTEE_CLASS);
	}

	get dealerValue() {
		return this.booleanToRadioValue(this.guaranteeDraft.FSC_Es_Concesionario_Dealer__c);
	}

	get tasadorExternoValue() {
		return this.booleanToRadioValue(this.guaranteeDraft.FSC_EsTasadorExterno__c);
	}

	get isExternalAppraiser() {
		return this.isRealEstateGuarantee && this.guaranteeDraft.FSC_EsTasadorExterno__c === true;
	}

	get isInternalAppraiser() {
		return this.isRealEstateGuarantee && this.guaranteeDraft.FSC_EsTasadorExterno__c === false;
	}

	get marcaVehiculoOptions() {
		if (this.vehicleCatalog.length) {
			return this.vehicleCatalog.map(({ label, value }) => ({ label, value }));
		}
		return this.marcaVehiculoPicklistOptions;
	}

	get modeloVehiculoOptions() {
		return this.getModelOptionsForBrand(this.guaranteeDraft.FSC_Marca_Vehiculo__c);
	}

	getModelOptionsForBrand(brand) {
		if (this.vehicleCatalog.length) {
			const catalogBrand = this.vehicleCatalog.find((option) => option.value === brand);
			return (catalogBrand?.models || []).map(({ label, value }) => ({ label, value }));
		}
		return this.getDependentPicklistOptions(this.modeloVehiculoPicklistData, brand);
	}

	get isModeloVehiculoDisabled() {
		return !this.guaranteeDraft.FSC_Marca_Vehiculo__c || this.modeloVehiculoOptions.length === 0;
	}

	get isLifeInsuranceSelected() {
		return this.isLifeInsuranceType(this.insuranceDraft.FSC_Tipo_de_Seguro__c);
	}

	get seguroDesempleoValue() {
		return this.booleanToRadioValue(this.insuranceDraft.FSC_Seguro_Desempleo__c);
	}

	get hasSeguroDesempleoSelected() {
		return this.insuranceDraft.FSC_Seguro_Desempleo__c !== null;
	}

	get showInsuranceUnemploymentFields() {
		return this.isLifeInsuranceSelected && this.insuranceDraft.FSC_Seguro_Desempleo__c === true;
	}

	get insurancePremiumStatusMessage() {
		const premiumAmount = this.insuranceDraft.FSC_Monto_de_la_Prima__c;
		if (!this.insuranceDraft.FSC_Tipo_de_Seguro__c || (premiumAmount !== '' && premiumAmount !== null && premiumAmount !== undefined)) {
			return '';
		}

		if (this.isInsuranceRateLoading) {
			return 'Calculando monto de la prima...';
		}

		const insuranceConfiguration = this.getSelectedInsuranceConfiguration();
		if (!insuranceConfiguration) {
			return 'No se encontro la configuracion del seguro seleccionado.';
		}
		if (insuranceConfiguration.rate === null || insuranceConfiguration.rate === undefined) {
			return 'El seguro seleccionado no tiene una tasa configurada.';
		}

		const formulaParameters = this.parseInsuranceFormulaParameters(insuranceConfiguration);
		const debtor = this.getApplicantByRole('deudor');
		if (formulaParameters.requiresApplicantAge && !debtor?.FSC_FechaNacimiento__c) {
			return 'Complete la fecha de nacimiento del deudor para calcular la prima.';
		}
		if (
			formulaParameters.maximumApplicantAge &&
			this.calculateAge(debtor?.FSC_FechaNacimiento__c) > Number(formulaParameters.maximumApplicantAge)
		) {
			return 'La edad del deudor supera el limite configurado para este seguro.';
		}

		const calculationBase = this.getInsuranceCalculationBase(insuranceConfiguration.calculationBase);
		if (!Number.isFinite(calculationBase) || calculationBase <= 0) {
			if (insuranceConfiguration.calculationBase === 'MONTO_SOLICITADO') {
				return 'Complete el monto solicitado para calcular la prima.';
			}
			if (insuranceConfiguration.calculationBase === 'VALOR_VEHICULO') {
				return 'Agregue una garantia de vehiculo con su valor para calcular la prima.';
			}
			if (insuranceConfiguration.calculationBase === 'VALOR_INMUEBLE') {
				return 'Agregue una garantia inmobiliaria con su valor tasado, valor del inmueble o precio de venta para calcular la prima.';
			}
			return 'La configuracion seleccionada no contiene una base valida para calcular la prima.';
		}

		if (formulaParameters.minimumBase && calculationBase < Number(formulaParameters.minimumBase)) {
			return 'La base de calculo es menor al minimo permitido para este seguro.';
		}
		if (formulaParameters.maximumBase && calculationBase > Number(formulaParameters.maximumBase)) {
			return 'La base de calculo supera el maximo permitido para este seguro.';
		}

		return 'No fue posible calcular la prima con los datos actuales.';
	}

	get unemploymentPremiumStatusMessage() {
		const unemploymentPremium = this.insuranceDraft.FSC_Monto_Prima_Desempleo__c;
		if (
			!this.insuranceDraft.FSC_Seguro_Desempleo__c ||
			(unemploymentPremium !== '' && unemploymentPremium !== null && unemploymentPremium !== undefined)
		) {
			return '';
		}

		const unemploymentParameters = this.getUnemploymentParameters();
		if (!unemploymentParameters) {
			return 'No se encontro una configuracion activa para calcular la prima de desempleo.';
		}

		const incomeSource = this.normalizeContextKey(this.insuranceDraft.FSC_Fuente_de_Ingresos__c);
		if (!incomeSource) {
			return 'Seleccione la fuente de ingresos para calcular la prima de desempleo.';
		}
		if (!['empleadoprivado', 'empleadopublico', 'militar'].includes(incomeSource)) {
			return 'La fuente de ingresos seleccionada no es elegible para el seguro de desempleo.';
		}

		const debtor = this.getApplicantByRole('deudor');
		if (!debtor?.FSC_TiempoLaborando__c) {
			return 'Complete la fecha de inicio laboral del deudor para calcular la prima de desempleo.';
		}

		const employmentMonths = this.calculateEmploymentMonths(debtor.FSC_TiempoLaborando__c);
		if (!Number.isFinite(employmentMonths)) {
			return 'La fecha de inicio laboral del deudor no es valida.';
		}

		const minimumMonths =
			incomeSource === 'empleadoprivado'
				? Number(unemploymentParameters.privateMinimumMonths)
				: Number(unemploymentParameters.publicMinimumMonths);
		if (employmentMonths < minimumMonths) {
			return `El deudor necesita al menos ${minimumMonths} meses de antiguedad laboral para esta fuente de ingresos.`;
		}

		const requestedAmount = this.parseNumber(this.montoSolicitado);
		if (requestedAmount <= 0) {
			return 'Complete el monto solicitado para calcular la prima de desempleo.';
		}
		if (this.parseNumber(this.montoCuota) <= 0) {
			return 'Complete plazo, tasa y forma de pago para calcular una cuota valida.';
		}
		if (
			this.insuranceDraft.FSC_Monto_de_la_Prima__c === '' ||
			this.insuranceDraft.FSC_Monto_de_la_Prima__c === null ||
			this.insuranceDraft.FSC_Monto_de_la_Prima__c === undefined
		) {
			return 'Primero complete los datos requeridos para calcular el monto de la prima principal.';
		}

		return 'La cuota financiada supera el limite permitido o no fue posible calcular la prima de desempleo con los datos actuales.';
	}

	get guaranteeEditorTitle() {
		return this.guaranteeEditKey ? 'Modificar garantia' : 'Agregar garantia';
	}

	get insuranceEditorTitle() {
		return this.insuranceEditKey ? 'Modificar seguro' : 'Agregar seguro';
	}

	get isFacilitySaveDisabled() {
		return (
			this.showGuaranteeEditor ||
			this.showInsuranceEditor ||
			((this.prestamoConGarantia || this.guaranteeRows.length > 0) && !this.isGuaranteeConfigurationReady)
		);
	}

	extractFacilities(value) {
		if (Array.isArray(value)) {
			return value;
		}

		if (Array.isArray(value?.FSC_Facilidades_De_Credito__c)) {
			return value.FSC_Facilidades_De_Credito__c;
		}

		if (Array.isArray(value?.DatosGeneralesSolicitud?.FSC_Facilidades_De_Credito__c)) {
			return value.DatosGeneralesSolicitud.FSC_Facilidades_De_Credito__c;
		}

		return [];
	}

	hydrateFacilitiesFromOmni() {
		if (this.facilities.length > 0) {
			this.loadPrimaryFacility();
			return;
		}

		const facilities = this.normalizeFacilities(this.extractFacilities(this.omniJsonData));
		if (facilities.length > 0) {
			this.facilities = facilities;
			this.loadPrimaryFacility();
		}
	}

	logPicklistError(scope, error) {
		console.error(`Error loading picklist values for ${scope}`, error);
	}

	normalizeText(value) {
		return (value || '')
			.normalize('NFD')
			.replace(/[\u0300-\u036f]/g, '')
			.toUpperCase();
	}

	// Igual que FSC_CatalogoGarantiaService.normalizarClave: ignora acentos, espacios y signos.
	normalizeKey(value) {
		return this.normalizeText(value).replace(/[^A-Z0-9]/g, '');
	}

	normalizeContextKey(value) {
		return String(value || '')
			.normalize('NFD')
			.replace(/[\u0300-\u036f]/g, '')
			.toLowerCase()
			.replace(/[^a-z0-9]/g, '');
	}

	normalizeInsuranceType(value) {
		return String(value || '')
			.normalize('NFD')
			.replace(/[\u0300-\u036f]/g, '')
			.replace(/_/g, ' ')
			.trim()
			.toLowerCase();
	}

	isLifeInsuranceType(value) {
		return this.normalizeInsuranceType(value).includes(INSURANCE_TYPE_LIFE);
	}

	resetUnemploymentInsuranceFields(draft) {
		draft.FSC_Seguro_Desempleo__c = null;
		draft.FSC_Monto_Prima_Desempleo__c = '';
		draft.FSC_Fuente_de_Ingresos__c = '';
		return draft;
	}

	isFireInsuranceType(value) {
		const insuranceType = this.normalizeInsuranceType(value);
		return insuranceType.includes(INSURANCE_TYPE_FIRE) || insuranceType.includes('seguro incendio');
	}

	get loanRequestType() {
		const explicitTipoCredito = this.normalizeContextKey(this.tipoCredito);
		const explicitType = this.resolveLoanRequestTypeFromKey(explicitTipoCredito);
		if (explicitType) {
			return explicitType;
		}

		const contextValues = this.collectOmniContextValues(this.omniJsonData);
		const contextType = contextValues.map((value) => this.resolveLoanRequestTypeFromKey(this.normalizeContextKey(value))).find((type) => !!type);

		return contextType || '';
	}

	get hasCodeudor() {
		return this.extractLoanApplicants(this.omniJsonData).some(
			(applicant) => this.normalizeContextKey(applicant?.FSC_TipoSolicitante__c) === 'codeudor'
		);
	}

	resolveLoanRequestTypeFromKey(value) {
		if (!value) {
			return '';
		}

		if (value.includes(OMNI_SUBTYPE_HIPOTECARIO) || value.includes('hipotecario')) {
			return LOAN_TYPE_HIPOTECARIO;
		}

		if (value.includes(OMNI_SUBTYPE_VEHICULO) || value.includes('vehiculo') || value.includes('vehicular')) {
			return LOAN_TYPE_VEHICULO;
		}

		if (value.includes(OMNI_SUBTYPE_CONSUMO) || value.includes('consumo')) {
			return LOAN_TYPE_CONSUMO;
		}

		return '';
	}

	extractLoanApplicants(value) {
		if (Array.isArray(value?.LoanApplicant)) {
			return value.LoanApplicant;
		}

		if (Array.isArray(value?.DatosSolicitante?.LoanApplicant)) {
			return value.DatosSolicitante.LoanApplicant;
		}

		return [];
	}

	validateMontoPrestacionesParaPrestamoConvenio(reportErrors = true) {
		if (!this.hasPrestamoConvenioSelected) {
			return true;
		}

		const applicants = this.extractLoanApplicants(this.omniJsonData);
		const hasMissingMontoPrestaciones =
			applicants.length === 0 || applicants.some((applicant) => !this.hasValue(applicant?.FSC_MontoPrestacionesLaborales__c));

		if (!hasMissingMontoPrestaciones) {
			return true;
		}

		if (reportErrors) {
			this.showToast(
				'Campo requerido',
				'Debe volver al paso Datos del Solicitante y completar el campo Monto Prestaciones Laborales para continuar con un préstamo de convenio.',
				'warning'
			);
		}

		return false;
	}

	validateFacilidadesExternasParaConsolidacion(reportErrors = true) {
		if (this.loanRequestType !== LOAN_TYPE_CONSUMO || !this.isConsolidacionDeudasSelected(this.omniJsonData)) {
			return true;
		}

		const deudor = this.getApplicantByRole('deudor');
		if (this.hasFacilidadesOtrasInstituciones(deudor)) {
			return true;
		}

		if (reportErrors) {
			this.showToast(
				'Facilidades requeridas',
				'Debe volver al paso Datos del Solicitante y registrar al menos una facilidad en Otras Instituciones para el deudor antes de continuar con la consolidación de deuda.',
				'warning'
			);
		}

		return false;
	}

	isConsolidacionDeudasSelected(value, visited = new WeakSet()) {
		if (value === null || value === undefined || typeof value !== 'object') {
			return false;
		}

		if (visited.has(value)) {
			return false;
		}
		visited.add(value);

		const consolidacionDeudas = value.FSC_EsConsolidacionDeudas__c;
		if (this.normalizeBoolean(consolidacionDeudas) === true || ['si', 'yes'].includes(this.normalizeContextKey(consolidacionDeudas))) {
			return true;
		}

		return Object.values(value).some((child) => this.isConsolidacionDeudasSelected(child, visited));
	}

	hasFacilidadesOtrasInstituciones(applicant) {
		const facilities =
			applicant?.FSC_Facilidad_Otra_Institucion__c ||
			applicant?.FSC_Facilidad_Otra_Institucion__r ||
			applicant?.FSC_Facilidades_Otras_Instituciones__r;
		const rows = Array.isArray(facilities) ? facilities : Array.isArray(facilities?.records) ? facilities.records : [];
		return rows.length > 0;
	}

	collectOmniContextValues(value, values = [], visited = new WeakSet(), parentKey = '') {
		if (values.length >= 200 || value === null || value === undefined) {
			return values;
		}

		if (typeof value !== 'object') {
			const stringValue = String(value);
			const normalizedValue = this.normalizeContextKey(stringValue);
			const normalizedParentKey = this.normalizeContextKey(parentKey);
			const isKnownContextKey = ['tipocredito', 'recordtype', 'omniscript', 'script', 'subtype', 'ssubtype'].some((key) =>
				normalizedParentKey.includes(key)
			);

			if (isKnownContextKey || normalizedValue.includes('fscsolicitudcredito') || normalizedValue.includes('solicitudcredito')) {
				values.push(stringValue);
			}
			return values;
		}

		if (visited.has(value)) {
			return values;
		}
		visited.add(value);

		Object.entries(value).forEach(([key, child]) => this.collectOmniContextValues(child, values, visited, key));
		return values;
	}

	getRequiredInsuranceRules() {
		if (this.loanRequestType === LOAN_TYPE_CONSUMO) {
			return [
				{
					label: 'Seguro de vida',
					matches: (insuranceType) => this.isLifeInsuranceType(insuranceType),
				},
			];
		}

		if (this.loanRequestType === LOAN_TYPE_HIPOTECARIO) {
			return [
				{
					label: 'Seguro de vida',
					matches: (insuranceType) => this.isLifeInsuranceType(insuranceType),
				},
				{
					label: 'Seguro de incendio',
					matches: (insuranceType) => this.isFireInsuranceType(insuranceType),
				},
			];
		}

		if (this.loanRequestType === LOAN_TYPE_VEHICULO) {
			return [
				{
					label: 'Seguro de vehiculo',
					matches: (insuranceType) =>
						!!this.normalizeInsuranceType(insuranceType) &&
						!this.isLifeInsuranceType(insuranceType) &&
						!this.isFireInsuranceType(insuranceType),
				},
			];
		}

		return [];
	}

	getMissingRequiredInsurances() {
		const insuranceTypes = this.insuranceRows.map((row) => this.normalizeInsuranceType(row.FSC_Tipo_de_Seguro__c));
		return this.getRequiredInsuranceRules()
			.filter((rule) => !insuranceTypes.some((insuranceType) => rule.matches(insuranceType)))
			.map((rule) => rule.label);
	}

	validateRequiredInsurances(reportErrors = true) {
		const message = this.requiredInsuranceMessage;
		if (!message) {
			return true;
		}

		if (reportErrors) {
			this.showToast('Seguros requeridos', message, 'warning');
		}
		return false;
	}

	validateRequiredGuarantees(reportErrors = true) {
		const message = this.requiredGuaranteeMessage;
		if (!message) {
			return true;
		}

		if (reportErrors) {
			this.showToast('Garantia requerida', message, 'warning');
		}
		return false;
	}

	isRealEstateGuaranteeClass(value) {
		return this.getGuaranteeGroup(value) === 'real-estate';
	}

	isVehicleGuaranteeClass(value) {
		return this.getGuaranteeGroup(value) === 'vehicle';
	}

	getGuaranteeGroup(value) {
		const group = this.guaranteeConfigurationByClass[this.normalizeKey(value)]?.groupName;
		return group === 'general' ? '' : group || '';
	}

	getExistingSpecialGuaranteeGroup() {
		const existingGuarantee = this.guaranteeRows.find(
			(row) => row.__key !== this.guaranteeEditKey && this.getGuaranteeGroup(row.FSC_Clase_de_Garantia__c)
		);
		return existingGuarantee ? this.getGuaranteeGroup(existingGuarantee.FSC_Clase_de_Garantia__c) : '';
	}

	hasIncompatibleGuaranteeGroup(classValue) {
		const selectedGroup = this.getGuaranteeGroup(classValue);
		const existingGroup = this.getExistingSpecialGuaranteeGroup();
		return !!selectedGroup && !!existingGroup && selectedGroup !== existingGroup;
	}

	getConfirmedGuaranteeTypeOptions(classValue) {
		const configuration = this.guaranteeConfigurationByClass[this.normalizeKey(classValue)];
		return (configuration?.types || []).map(({ value }) => ({ label: value, value }));
	}

	// Una garantia guardada antes del catalogo se alinea con el valor equivalente del API al editarla.
	alignGuaranteeDraftWithCatalog(draft) {
		const configuration = this.guaranteeConfigurationByClass[this.normalizeKey(draft.FSC_Clase_de_Garantia__c)];
		if (configuration?.fromCatalog) {
			draft.FSC_Clase_de_Garantia__c = configuration.value;
			const matchingType = (configuration.types || []).find(
				(type) => this.normalizeKey(type.value) === this.normalizeKey(draft.FSC_Tipo_de_Garantia__c)
			);
			if (matchingType) {
				draft.FSC_Tipo_de_Garantia__c = matchingType.value;
			}
		}

		if (!this.vehicleCatalog.length || !draft.FSC_Marca_Vehiculo__c) {
			return draft;
		}
		const brand = this.vehicleCatalog.find((option) => this.normalizeKey(option.value) === this.normalizeKey(draft.FSC_Marca_Vehiculo__c));
		if (brand) {
			draft.FSC_Marca_Vehiculo__c = brand.value;
			const model = (brand.models || []).find((option) => this.normalizeKey(option.value) === this.normalizeKey(draft.FSC_Modelo_Vehiculo__c));
			if (model) {
				draft.FSC_Modelo_Vehiculo__c = model.value;
			}
		}
		return draft;
	}

	getDependentPicklistOptions(picklistData, controllingValue) {
		if (!picklistData) {
			return [];
		}

		const controllerIndex = picklistData.controllerValues?.[controllingValue];
		if (controllerIndex === undefined) {
			return picklistData.controllerValues ? [] : picklistData.values;
		}

		return picklistData.values.filter((option) => option.validFor?.includes(controllerIndex));
	}

	notifyFacilitiesChange() {
		const payload = this.facilities;
		const facilitiesJson = this.stringifyFacilities(payload);

		if (facilitiesJson !== this.lastNotifiedFacilitiesJson && typeof this.omniUpdateDataJson === 'function') {
			this.lastNotifiedFacilitiesJson = facilitiesJson;
			this.omniUpdateDataJson(payload);
		}

		if (typeof this.omniValidate === 'function') {
			this.omniValidate(false);
		}
	}

	loadPrimaryFacility() {
		const [facility] = this.facilities;

		if (facility) {
			this.loadFacilityIntoForm(facility);
			return;
		}

		this.resetFacilityForm();
	}

	loadFacilityIntoForm(row) {
		if (!row) {
			this.resetFacilityForm();
			return;
		}

		this.editRowKey = row.__key;
		this.tipoFacilidad = row.FSC_Tipo_Facilidad__c || '';
		this.facilidad = row.FSC_Facilidad__c || '';
		this.applyFacilityRules();
		this.estadoDelVehiculo = row.FSC_EstadoDelVehiculo__c || '';
		this.prestamoConvenio = this.normalizeBoolean(row.FSC_Prestamo_Convenio__c);
		this.tipoModalidad = row.FSC_Tipo_Modalidad__c || '';
		this.lineasFinancierasEmpresas = row.FSC_Lineas_Financieras_Empresas__c || '';
		this.syncLineasFinancierasSearchTerm();
		this.prestamoConGarantia = this.isTipoCreditoConGarantiaObligatoria
			? true
			: row.FSC_Prestamo_Con_Garantia__c === null || row.FSC_Prestamo_Con_Garantia__c === undefined
				? false
				: this.normalizeBoolean(row.FSC_Prestamo_Con_Garantia__c);
		this.requiereContratoPagareNotarial = this.normalizeBoolean(row.FSC_Requiere_Contrato_Pagare_Notarial__c);
		this.descripcionPropositoFacilidad = row.FSC_Descripcion_Proposito_Facilidad__c || '';
		this.montoSolicitado = this.normalizeInputValue(row.FSC_Monto_Solicitado__c);
		this.plazoMeses = this.normalizeInputValue(row.FSC_Plazo_meses__c);
		this.tasaInteres = this.normalizeInputValue(row.FSC_Tasa_Interes__c);
		this.tasaFija = this.normalizeBoolean(row.FSC_Tasa_Fija__c);
		this.tiempoTasaFija = this.normalizeInputValue(row.FSC_Tiempo_Tasa_Fija__c);
		this.formaPago = row.FSC_Forma_De_Pago__c || '';
		this.montoCuota = this.normalizeInputValue(row.FSC_Monto_De_La_Cuota__c);
		this.calculateInstallment();
		this.guaranteeRows = this.normalizeGuarantees(row.FSC_Garantias__r);
		this.insuranceRows = this.normalizeInsurances(row.FSC_Seguros__r);
		this.closeGuaranteeEditor();
		this.closeInsuranceEditor();
	}

	resetFacilityForm() {
		this.editRowKey = null;
		this.tipoFacilidad = '';
		this.facilidad = this.usesDefaultConsumoFacility ? DEFAULT_FACILITY_CONSUMO : '';
		this.estadoDelVehiculo = '';
		this.prestamoConvenio = null;
		this.tipoModalidad = '';
		this.lineasFinancierasEmpresas = '';
		this.lineasFinancierasSearchTerm = '';
		this.showLineasFinancierasDropdown = false;
		this.prestamoConGarantia = this.isTipoCreditoConGarantiaObligatoria;
		this.requiereContratoPagareNotarial = null;
		this.descripcionPropositoFacilidad = '';
		this.montoSolicitado = '';
		this.plazoMeses = '';
		this.tasaInteres = '';
		this.tasaFija = null;
		this.tiempoTasaFija = '';
		this.formaPago = '';
		this.montoCuota = '';
		this.guaranteeRows = [];
		this.insuranceRows = [];
		this.closeGuaranteeEditor();
		this.closeInsuranceEditor();
	}

	handleValueChange(event) {
		const fieldName = event.target.name;
		if (fieldName === 'formaPago' && this.isTipoCreditoHipotecario) {
			this.formaPago = this.getDefaultFormaPagoValue();
			this.calculateInstallment();
			this.persistFacilityDraft();
			return;
		}

		const previousValue = this[fieldName];
		const value = event.detail?.value ?? event.target.value;
		this[fieldName] = value;

		if (fieldName === 'tipoFacilidad' && previousValue !== value) {
			this.prestamoConGarantia = this.hasTipoFacilidadSelected ? this.prestamoConGarantia : false;
			this.plazoMeses = '';
			this.tasaInteres = '';
			this.formaPago = '';
			this.montoCuota = '';
			this.guaranteeRows = [];
			this.insuranceRows = [];
			this.facilidad = '';
			this.estadoDelVehiculo = '';
			this.prestamoConvenio = null;
			this.requiereContratoPagareNotarial = null;
			this.tipoModalidad = '';
			this.lineasFinancierasEmpresas = '';
			this.lineasFinancierasSearchTerm = '';
			this.showLineasFinancierasDropdown = false;
			this.applyFacilityRules();
		}

		if (fieldName === 'facilidad' && previousValue !== value) {
			this.estadoDelVehiculo = '';
			this.prestamoConvenio = null;
			this.requiereContratoPagareNotarial = null;
			this.tipoModalidad = '';
			this.lineasFinancierasEmpresas = '';
			this.lineasFinancierasSearchTerm = '';
			this.showLineasFinancierasDropdown = false;
		}

		if (fieldName === 'tasaFija' && value !== 'true') {
			this.tiempoTasaFija = '';
		}
		if (['plazoMeses', 'tiempoTasaFija'].includes(fieldName)) {
			this.updateTiempoTasaFijaValidity(true);
		}
		if (fieldName === 'plazoMeses') {
			this.setPlazoMesesValidity(event.target, value);
			event.target.reportValidity();
		}

		if (['montoSolicitado', 'plazoMeses', 'tasaInteres', 'formaPago'].includes(fieldName)) {
			this.calculateInstallment();
			this.recalculateInsuranceDraftPremium();
		}

		this.queueCreditPolicyValidation();
		this.persistFacilityDraft();
	}

	handleNumericKeyDown(event) {
		if ((event.ctrlKey || event.metaKey) && ['a', 'c', 'v', 'x'].includes(event.key.toLowerCase())) {
			return;
		}

		const allowedControlKeys = ['Backspace', 'Delete', 'ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown', 'Home', 'End', 'Tab'];
		if (allowedControlKeys.includes(event.key) || /^[0-9]$/.test(event.key)) {
			return;
		}

		const numericMode = event.target.dataset.numericMode;
		const isDecimalInput = ['decimal', 'decimal-dot'].includes(numericMode);
		const isAllowedDecimalSeparator = event.key === '.' || (numericMode === 'decimal' && event.key === ',');
		const currentValue = String(event.target.value || '');
		if (isDecimalInput && isAllowedDecimalSeparator && !/[.,]/.test(currentValue)) {
			return;
		}

		event.preventDefault();
	}

	handleNumericInput(event) {
		const numericMode = event.target.dataset.numericMode;
		const rawValue = String(event.target.value || '');
		if (numericMode === 'decimal-dot' && rawValue.includes(',')) {
			event.target.value = this[event.target.name] ?? '';
			return;
		}

		const sanitizedValue = this.sanitizeNumericInput(rawValue, numericMode);
		if (event.target.value !== sanitizedValue) {
			event.target.value = sanitizedValue;
		}
		this.updateNumericField(event.target.name, sanitizedValue, event.target.dataset.numericTarget);
	}

	handlePlazoMesesInput(event) {
		const sanitizedValue = this.sanitizeNumericInput(event.target.value, 'integer').slice(0, 3);
		if (event.target.value !== sanitizedValue) {
			event.target.value = sanitizedValue;
		}
		this.updateNumericField('plazoMeses', sanitizedValue);
		this.setPlazoMesesValidity(event.target, sanitizedValue);
		event.target.reportValidity();
		this.updateTiempoTasaFijaValidity(true);
	}

	handleTiempoTasaFijaInput(event) {
		const sanitizedValue = this.sanitizeNumericInput(event.target.value, 'integer');
		if (event.target.value !== sanitizedValue) {
			event.target.value = sanitizedValue;
		}
		this.setTiempoTasaFijaValidity(event.target, sanitizedValue);
		event.target.reportValidity();
		this.updateNumericField('tiempoTasaFija', sanitizedValue);
	}

	handleNumericPaste(event) {
		const clipboardValue = event.clipboardData?.getData('text') || '';
		if (!clipboardValue) {
			return;
		}

		event.preventDefault();
		const numericMode = event.target.dataset.numericMode;
		if (numericMode === 'decimal-dot' && clipboardValue.includes(',')) {
			return;
		}

		const sanitizedValue = this.sanitizeNumericInput(clipboardValue, numericMode);
		event.target.value = sanitizedValue;
		this.updateNumericField(event.target.name, sanitizedValue, event.target.dataset.numericTarget);
	}

	handlePlazoMesesPaste(event) {
		const clipboardValue = event.clipboardData?.getData('text') || '';
		if (!clipboardValue) {
			return;
		}

		event.preventDefault();
		const sanitizedValue = this.sanitizeNumericInput(clipboardValue, 'integer').slice(0, 3);
		event.target.value = sanitizedValue;
		this.updateNumericField('plazoMeses', sanitizedValue);
		this.setPlazoMesesValidity(event.target, sanitizedValue);
		event.target.reportValidity();
		this.updateTiempoTasaFijaValidity(true);
	}

	handleTiempoTasaFijaPaste(event) {
		const clipboardValue = event.clipboardData?.getData('text') || '';
		if (!clipboardValue) {
			return;
		}

		event.preventDefault();
		const sanitizedValue = this.sanitizeNumericInput(clipboardValue, 'integer');
		event.target.value = sanitizedValue;
		this.setTiempoTasaFijaValidity(event.target, sanitizedValue);
		event.target.reportValidity();
		this.updateNumericField('tiempoTasaFija', sanitizedValue);
	}

	sanitizeNumericInput(value, numericMode) {
		const isDecimalInput = ['decimal', 'decimal-dot'].includes(numericMode);
		const normalizedValue = numericMode === 'decimal' ? String(value || '').replace(',', '.') : String(value || '');
		if (!isDecimalInput) {
			return normalizedValue.replace(/\D/g, '');
		}

		const numericValue = normalizedValue.replace(/[^0-9.]/g, '');
		const [integerPart, ...decimalParts] = numericValue.split('.');
		if (decimalParts.length === 0) {
			return integerPart;
		}

		return `${integerPart}.${decimalParts.join('').slice(0, 2)}`;
	}

	updateNumericField(fieldName, value, target) {
		if (target === 'guarantee') {
			this.guaranteeDraft = {
				...this.guaranteeDraft,
				[fieldName]: value,
			};
			return;
		}

		this[fieldName] = value;
		this.queueCreditPolicyValidation();
		if (['montoSolicitado', 'plazoMeses', 'tasaInteres'].includes(fieldName)) {
			this.calculateInstallment();
		}
		if (['montoSolicitado', 'plazoMeses', 'tasaInteres'].includes(fieldName)) {
			this.recalculateInsuranceDraftPremium();
		}
		this.persistFacilityDraft();
	}

	handleBooleanChange(event) {
		const fieldName = event.target.name;
		if (fieldName === 'prestamoConGarantia' && this.isTipoCreditoConGarantiaObligatoria) {
			this.prestamoConGarantia = true;
			this.persistFacilityDraft();
			return;
		}

		if (fieldName === 'requiereContratoPagareNotarial' && this.isTipoCreditoHipotecario) {
			this.requiereContratoPagareNotarial = true;
			this.persistFacilityDraft();
			return;
		}

		this[fieldName] = event.detail.value === 'true';

		if (fieldName === 'prestamoConvenio' && this[fieldName] !== true) {
			this.tipoModalidad = '';
			this.lineasFinancierasEmpresas = '';
			this.lineasFinancierasSearchTerm = '';
			this.showLineasFinancierasDropdown = false;
		}

		if (fieldName === 'prestamoConGarantia' && this[fieldName] !== true) {
			this.guaranteeRows = [];
			this.closeGuaranteeEditor();
			this.recalculateInsuranceDraftPremium();
		}

		if (fieldName === 'tasaFija' && this[fieldName] !== true) {
			this.tiempoTasaFija = '';
		}

		this.persistFacilityDraft();
	}

	handleLineasFinancierasFocus() {
		this.clearLineasFinancierasBlurTimeout();
		this.showLineasFinancierasDropdown = true;
	}

	handleLineasFinancierasInput(event) {
		this.updateLineasFinancierasSearch(event.target.value || '');
	}

	handleLineasFinancierasPaste(event) {
		const input = event.target;
		window.setTimeout(() => {
			this.updateLineasFinancierasSearch(input.value || '');
		}, 0);
	}

	updateLineasFinancierasSearch(value) {
		this.lineasFinancierasSearchTerm = value;
		this.lineasFinancierasEmpresas = '';
		this.showLineasFinancierasDropdown = true;
		this.updateLineasFinancierasValidity();

		if (!this.lineasFinancierasSearchTerm) {
			this.persistFacilityDraft();
		}
	}

	handleLineasFinancierasBlur() {
		this.lineasFinancierasBlurTimeout = window.setTimeout(() => {
			this.showLineasFinancierasDropdown = false;
			if (this.lineasFinancierasEmpresas) {
				this.syncLineasFinancierasSearchTerm();
			}
			this.updateLineasFinancierasValidity();
		}, 200);
	}

	handleLineasFinancierasSelect(event) {
		event.preventDefault();
		this.clearLineasFinancierasBlurTimeout();
		const selectedValue = event.currentTarget.dataset.value || '';
		this.lineasFinancierasEmpresas = selectedValue;
		this.syncLineasFinancierasSearchTerm();
		this.showLineasFinancierasDropdown = false;
		this.updateLineasFinancierasValidity();
		this.persistFacilityDraft();
	}

	clearLineasFinancierasBlurTimeout() {
		if (this.lineasFinancierasBlurTimeout) {
			window.clearTimeout(this.lineasFinancierasBlurTimeout);
			this.lineasFinancierasBlurTimeout = null;
		}
	}

	syncLineasFinancierasSearchTerm() {
		this.lineasFinancierasSearchTerm = this.getLineasFinancierasLabel(this.lineasFinancierasEmpresas);
		this.updateLineasFinancierasValidity();
	}

	getLineasFinancierasLabel(value) {
		if (!value) {
			return '';
		}

		const selectedOption = this.lineasFinancierasOptions.find((option) => option.value === value);
		return selectedOption?.label || value;
	}

	updateLineasFinancierasValidity() {
		const input = this.template?.querySelector('lightning-input[name="lineasFinancierasEmpresasSearch"]');
		if (!input) {
			return;
		}

		const hasTypedValue = !!this.lineasFinancierasSearchTerm?.trim();
		const isInvalidSelection = hasTypedValue && !this.lineasFinancierasEmpresas;
		input.setCustomValidity(isInvalidSelection ? 'Seleccione una opcion valida de la lista.' : '');
	}

	calculateInstallment() {
		this.calculateMontoCuotaRegular();
	}

	calculateMontoCuotaRegular() {
		const montoAprobado = this.normalizeCurrencyValue(this.montoSolicitado);
		const tasaInteres = this.normalizeCurrencyValue(this.tasaInteres);
		const plazoMeses = this.normalizeCurrencyValue(this.plazoMeses);
		const tasaMensual = tasaInteres === null ? null : tasaInteres / 100 / 12;
		const formaPago = (this.getFormaPagoValue() || '').trim();

		let calculatedValue = null;

		if (formaPago === FORMA_PAGO_CUOTAS_MENSUALES_IGUALES) {
			calculatedValue = this.calculateCuotaMensualIgual(montoAprobado, tasaMensual, plazoMeses);
		} else if (formaPago === FORMA_PAGO_CAPITAL_VENCIMIENTO) {
			calculatedValue = this.calculateInteresMensual(montoAprobado, tasaMensual);
		}

		this.montoCuota = this.formatInstallmentValue(calculatedValue);
	}

	calculateCuotaMensualIgual(montoAprobado, tasaMensual, plazoMeses) {
		if (montoAprobado === null || tasaMensual === null || plazoMeses === null || plazoMeses <= 0) {
			return null;
		}

		if (tasaMensual === 0) {
			return montoAprobado / plazoMeses;
		}

		return (montoAprobado * tasaMensual) / (1 - 1 / Math.pow(tasaMensual + 1, plazoMeses));
	}

	calculateInteresMensual(montoAprobado, tasaMensual) {
		if (montoAprobado === null || tasaMensual === null) {
			return null;
		}

		return montoAprobado * tasaMensual;
	}

	formatInstallmentValue(value) {
		const normalizedValue = this.normalizeCurrencyValue(value);
		return normalizedValue === null ? '' : normalizedValue.toFixed(2);
	}

	saveFacility() {
		if (!this.validateFacilityInputs()) {
			return;
		}

		if (!this.validateFacility()) {
			return;
		}

		this.attemptedGuaranteeValidation = true;
		if (!this.validateRequiredGuarantees()) {
			return;
		}

		if (this.isFacilitySaveDisabled) {
			//this.showToast('Advertencia', 'Debe guardar o cancelar la edicion de garantias y seguros antes de continuar.', 'warning');
			return;
		}

		try {
			this.persistFacilityDraft();
		} catch (error) {
			console.error('Error saving facility', error);
			this.showToast('Error', 'No fue posible guardar la facilidad.', 'error');
		}
	}

	persistFacilityDraft() {
		if (!this.hasFacilityDraftValue()) {
			this.facilities = [];
			this.editRowKey = null;
			this.notifyFacilitiesChange();
			return;
		}

		const payload = this.buildFacilityPayload();
		this.editRowKey = payload.__key;
		this.facilities = [payload];
		this.notifyFacilitiesChange();
	}

	hasFacilityDraftValue() {
		const values = [
			this.tipoFacilidad,
			this.facilidad,
			this.estadoDelVehiculo,
			this.prestamoConvenio,
			this.tipoModalidad,
			this.lineasFinancierasEmpresas,
			this.requiereContratoPagareNotarial,
			this.descripcionPropositoFacilidad,
			this.montoSolicitado,
			this.plazoMeses,
			this.tasaInteres,
			this.tasaFija,
			this.tiempoTasaFija,
			this.formaPago,
			this.montoCuota,
		];

		return (
			values.some((value) => this.hasValue(value)) ||
			this.prestamoConGarantia === true ||
			this.guaranteeRows.length > 0 ||
			this.insuranceRows.length > 0
		);
	}

	hasValue(value) {
		if (value === null || value === undefined) {
			return false;
		}

		if (typeof value === 'string') {
			return value.trim() !== '';
		}

		return true;
	}

	validateFacilityInputs(reportErrors = true) {
		this.queueCreditPolicyValidation(reportErrors);
		this.updateCreditPolicyAmountValidity();
		if (this.usesCreditPolicy && this.creditPolicyValidationMessage) {
			if (reportErrors) this.showToast('Límites del crédito', this.creditPolicyValidationMessage, 'error');
			return false;
		}
		const loanTermError = this.loanTermValidationMessage;
		if (loanTermError) {
			this.updatePlazoMesesValidity();
			if (reportErrors) {
				this.template.querySelector('[data-plazo-meses]')?.reportValidity();
			}
			return false;
		}
		this.updateLineasFinancierasValidity();
		this.updatePlazoMesesValidity();
		this.updateTiempoTasaFijaValidity();
		const inputs = [...this.template.querySelectorAll('[data-facility-input]')];
		return inputs.reduce((isValid, input) => {
			if (reportErrors) {
				input.reportValidity();
			}
			return isValid && input.checkValidity();
		}, true);
	}

	updatePlazoMesesValidity(reportErrors = false) {
		const input = this.template.querySelector('[data-plazo-meses]');
		if (!input) {
			return;
		}

		this.setPlazoMesesValidity(input, this.plazoMeses);
		if (reportErrors) input.reportValidity();
	}

	setPlazoMesesValidity(input, value) {
		input.setCustomValidity(this.getLoanTermValidationMessage(value));
	}

	get loanTermValidationMessage() {
		return this.getLoanTermValidationMessage(this.plazoMeses);
	}

	getLoanTermValidationMessage(value) {
		if (this.usesCreditPolicy) return this.loanTermPolicyMessage;
		const plazo = Number(value);
		const isValidPlazo = !value || (Number.isInteger(plazo) && plazo >= 1 && plazo <= this.maxLoanTermMonths);
		return this.loanTermPolicyMessage || (isValidPlazo ? '' : `El plazo debe ser un número entero entre 1 y ${this.maxLoanTermMonths} meses.`);
	}

	updateTiempoTasaFijaValidity(reportError = false) {
		const input = this.template.querySelector('lightning-input[name="tiempoTasaFija"]');
		if (!input) {
			return;
		}

		this.setTiempoTasaFijaValidity(input, this.tiempoTasaFija);
		if (reportError) {
			input.reportValidity();
		}
	}

	setTiempoTasaFijaValidity(input, value) {
		const tiempoTasaFija = Number(value);
		const plazo = Number(this.plazoMeses);
		const hasComparableValues = this.hasValue(value) && this.hasValue(this.plazoMeses);
		const exceedsLoanTerm =
			this.tasaFija === true && hasComparableValues && Number.isFinite(tiempoTasaFija) && Number.isFinite(plazo) && tiempoTasaFija > plazo;
		input.setCustomValidity(exceedsLoanTerm ? 'El tiempo de tasa fija no puede ser mayor al plazo del credito.' : '');
	}

	validateFacility(reportErrors = true) {
		const validations = [
			{
				value: this.tipoFacilidad,
				message: 'Debe seleccionar el tipo de facilidad.',
			},
			{
				value: this.facilidad,
				message: 'Debe seleccionar la facilidad.',
			},
			{
				value: this.montoSolicitado,
				message: 'Debe indicar el monto solicitado.',
			},
			{
				value: this.tasaFija,
				message: 'Debe indicar si la tasa es fija.',
			},
		];

		if (this.hasTipoFacilidadSelected) {
			validations.push(
				{
					value: this.plazoMeses,
					message: 'Debe indicar el plazo en meses.',
				},
				{
					value: this.tasaInteres,
					message: 'Debe indicar la tasa de interes.',
				},
				{
					value: this.getFormaPagoValue(),
					message: 'Debe indicar la forma de pago.',
				}
			);
		}

		if (this.hasFacilidadSelected) {
			validations.push({
				value: this.getRequiereContratoValue(),
				message: 'Debe indicar si requiere contrato o pagare notarial.',
			});

			if (this.showPrestamoConvenioFields) {
				validations.push({
					value: this.prestamoConvenio,
					message: 'Debe indicar si el prestamo es de convenio.',
				});
			}
		}

		if (this.hasPrestamoConvenioSelected) {
			validations.push(
				{
					value: this.tipoModalidad,
					message: 'Debe seleccionar el tipo de modalidad.',
				},
				{
					value: this.lineasFinancierasEmpresas,
					message: 'Debe seleccionar las lineas financieras empresas.',
				}
			);
		}

		const error = validations.find((item) => item.value === '' || item.value === null || item.value === undefined);
		if (error) {
			if (reportErrors) {
				this.showToast('Campo requerido', error.message, 'warning');
			}
			return false;
		}

		if (this.tasaFija === true && !this.tiempoTasaFija) {
			if (reportErrors) {
				this.showToast('Campo requerido', 'Debe indicar el tiempo de tasa fija.', 'warning');
			}
			return false;
		}

		return true;
	}

	buildFacilityPayload() {
		const amount = this.montoSolicitado;
		const term = this.normalizeNumberValue(this.plazoMeses, 0);
		const rate = this.normalizeNumberValue(this.tasaInteres, 5);
		const cuota = this.normalizeNumberValue(this.montoCuota, 2);
		const key = this.editRowKey || this.facilities[0]?.__key || this.generateRowKey('facilidad');
		const facilityValue = this.usesDefaultConsumoFacility ? DEFAULT_FACILITY_CONSUMO : this.facilidad;

		return {
			__key: key,
			Name: `${facilityValue || 'Facilidad'} ${key}`,
			FSC_Tipo_Facilidad__c: this.tipoFacilidad,
			FSC_Facilidad__c: facilityValue,
			FSC_EstadoDelVehiculo__c: this.isTipoCreditoVehiculo ? this.estadoDelVehiculo : null,
			FSC_Prestamo_Convenio__c: this.showPrestamoConvenioFields ? this.prestamoConvenio : null,
			FSC_Tipo_Modalidad__c: this.hasPrestamoConvenioSelected ? this.tipoModalidad : '',
			FSC_Lineas_Financieras_Empresas__c: this.hasPrestamoConvenioSelected ? this.lineasFinancierasEmpresas : '',
			FSC_Prestamo_Con_Garantia__c: this.prestamoConGarantia,
			FSC_Requiere_Contrato_Pagare_Notarial__c: this.getRequiereContratoValue(),
			FSC_Descripcion_Proposito_Facilidad__c: this.descripcionPropositoFacilidad,
			FSC_Monto_Solicitado__c: amount,
			FSC_Plazo_meses__c: term,
			FSC_Tasa_Interes__c: rate,
			FSC_Tasa_Fija__c: this.tasaFija,
			FSC_Tiempo_Tasa_Fija__c: this.tasaFija === true ? this.normalizeNumberValue(this.tiempoTasaFija, 0) : null,
			FSC_Forma_De_Pago__c: this.getFormaPagoValue(),
			FSC_Monto_De_La_Cuota__c: cuota,
			FSC_Tipo_de_Facilidad__c: this.tipoFacilidad,
			FSC_Aumento_Solicitado__c: amount,
			FSC_Tasa__c: rate,
			FSC_Compromiso_Mensual__c: cuota,
			FSC_Garantias__r: this.serializeGuarantees(),
			FSC_Seguros__r: this.serializeInsurances(),
			...(this.monedaFacilidad ? { FSC_Moneda__c: this.monedaFacilidad } : {}),
		};
	}

	handleAddGuarantee() {
		if (this.isAddGuaranteeDisabled) {
			return;
		}
		this.guaranteeDraft = this.createGuaranteeDraft();
		this.guaranteeEditKey = null;
		this.showGuaranteeEditor = true;
	}

	handleGuaranteeRowAction(event) {
		const { action, row } = event.detail;

		if (action.name === 'edit') {
			if (!this.validateGuaranteeConfiguration()) {
				return;
			}
			this.guaranteeDraft = {
				__key: row.__key,
				FSC_Clase_de_Garantia__c: row.FSC_Clase_de_Garantia__c || '',
				FSC_Tipo_de_Garantia__c: row.FSC_Tipo_de_Garantia__c || '',
				FSC_Descripcion_de_la_Garantia__c: row.FSC_Descripcion_de_la_Garantia__c || '',
				FSC_Proposito_Garantia_Hipotecario__c: row.FSC_Proposito_Garantia_Hipotecario__c || '',
				FSC_Valor_Tasado__c: this.normalizeInputValue(row.FSC_Valor_Tasado__c),
				FSC_Valor_Mejoras__c: this.normalizeInputValue(row.FSC_Valor_Mejoras__c),
				FSC_SaldoPrimeraHipoteca__c: this.normalizeInputValue(row.FSC_SaldoPrimeraHipoteca__c),
				FSC_EsTasadorExterno__c: this.normalizeBoolean(row.FSC_EsTasadorExterno__c),
				FSC_NombreTasadorExterno__c: row.FSC_NombreTasadorExterno__c || '',
				FSC_Tasado_Por__c: row.FSC_Tasado_Por__c || '',
				FSC_Fecha_Tasacion__c: row.FSC_Fecha_Tasacion__c || '',
				FSC_Monto_Inicial_Avance_Pagado__c: this.normalizeInputValue(row.FSC_Monto_Inicial_Avance_Pagado__c),
				FSC_Valor_Inmueble__c: this.normalizeInputValue(row.FSC_Valor_Inmueble__c),
				FSC_Precio_de_Venta__c: this.normalizeInputValue(row.FSC_Precio_de_Venta__c),
				FSC_Metros_Cuadrados_de_Construccion__c: this.normalizeInputValue(row.FSC_Metros_Cuadrados_de_Construccion__c),
				FSC_Ubicacion__c: row.FSC_Ubicacion__c || '',
				FSC_Tipo_de_Inmueble__c: row.FSC_Tipo_de_Inmueble__c || '',
				FSC_Es_Concesionario_Dealer__c: this.normalizeBoolean(row.FSC_Es_Concesionario_Dealer__c),
				FSC_Concesionario__c: row.FSC_Concesionario__c || '',
				FSC_Marca_Vehiculo__c: row.FSC_Marca_Vehiculo__c || '',
				FSC_Modelo_Vehiculo__c: row.FSC_Modelo_Vehiculo__c || '',
				FSC_Ano_Vehiculo__c: this.normalizeInputValue(row.FSC_Ano_Vehiculo__c),
				FSC_Color_Vehiculo__c: row.FSC_Color_Vehiculo__c || '',
				FSC_Numero_Chasis_Vehiculo__c: row.FSC_Numero_Chasis_Vehiculo__c || '',
				FSC_Serial_Motor_Vehiculo__c: row.FSC_Serial_Motor_Vehiculo__c || '',
				FSC_Numero_Placa_Vehiculo__c: row.FSC_Numero_Placa_Vehiculo__c || '',
				FSC_Numero_Matricula__c: row.FSC_Numero_Matricula__c || '',
				FSC_Fecha_Expedicion_Vehiculo__c: row.FSC_Fecha_Expedicion_Vehiculo__c || '',
				FSC_Valor_Vehiculo__c: this.normalizeInputValue(row.FSC_Valor_Vehiculo__c),
			};
			this.alignGuaranteeDraftWithCatalog(this.guaranteeDraft);
			this.clearGuaranteeFieldsForClass(this.guaranteeDraft);
			this.syncVehicleModelWithOptions();
			this.guaranteeEditKey = row.__key;
			this.showGuaranteeEditor = true;
			return;
		}

		if (action.name === 'delete') {
			this.guaranteeRows = this.guaranteeRows.filter((item) => item.__key !== row.__key);
			this.updatePlazoMesesValidity();
			this.recalculateInsuranceDraftPremium();
			this.persistFacilityDraft();
		}
	}

	handleGuaranteeDraftChange(event) {
		if (!this.validateGuaranteeConfiguration()) {
			return;
		}
		const fieldName = event.target.name;
		let value = event.detail?.value ?? event.target.value;
		if (['FSC_Valor_Tasado__c', 'FSC_Metros_Cuadrados_de_Construccion__c'].includes(fieldName)) {
			value = this.sanitizeNumericInput(value, 'decimal');
			if (event.target.value !== value) {
				event.target.value = value;
			}
		}
		if (fieldName === 'FSC_Fecha_Tasacion__c') {
			if (value > this.fechaTasacionMaxima) {
				event.target.setCustomValidity('La fecha de tasacion no puede ser posterior a hoy.');
				event.target.reportValidity();
				return;
			}
			event.target.setCustomValidity('');
		}
		if (fieldName === 'FSC_Fecha_Expedicion_Vehiculo__c') {
			if (value > this.fechaTasacionMaxima) {
				event.target.setCustomValidity('La fecha de expedición del vehículo no puede ser posterior a hoy.');
				event.target.reportValidity();
				return;
			}
			event.target.setCustomValidity('');
		}
		if (fieldName === 'FSC_Ano_Vehiculo__c') {
			value = this.sanitizeNumericInput(value, 'integer').slice(0, 4);
			if (event.target.value !== value) {
				event.target.value = value;
			}
			this.setVehicleYearValidity(event.target, value);
		}
		if (['FSC_Es_Concesionario_Dealer__c', 'FSC_EsTasadorExterno__c'].includes(fieldName)) {
			value = value === 'true';
		}
		const nextDraft = {
			...this.guaranteeDraft,
			[fieldName]: value,
		};

		if (fieldName === 'FSC_Clase_de_Garantia__c') {
			nextDraft.FSC_Tipo_de_Garantia__c = '';
			this.clearGuaranteeFieldsForClass(nextDraft);
		}

		if (fieldName === 'FSC_Es_Concesionario_Dealer__c' && !value) {
			nextDraft.FSC_Concesionario__c = '';
		}

		if (fieldName === 'FSC_EsTasadorExterno__c') {
			if (value) {
				nextDraft.FSC_Tasado_Por__c = '';
			} else {
				nextDraft.FSC_NombreTasadorExterno__c = '';
			}
		}

		if (fieldName === 'FSC_Marca_Vehiculo__c') {
			this.clearVehicleModelIfInvalid(nextDraft);
		}

		this.guaranteeDraft = nextDraft;
		this.syncGuaranteeTypeWithOptions();
		this.syncVehicleModelWithOptions();
	}

	handleVehicleYearInput(event) {
		const value = this.sanitizeNumericInput(event.target.value, 'integer').slice(0, 4);
		if (event.target.value !== value) {
			event.target.value = value;
		}
		this.setVehicleYearValidity(event.target, value);
		event.target.reportValidity();
		this.updateNumericField('FSC_Ano_Vehiculo__c', value, 'guarantee');
	}

	handleVehicleYearPaste(event) {
		event.preventDefault();
		const value = this.sanitizeNumericInput(event.clipboardData?.getData('text') || '', 'integer').slice(0, 4);
		event.target.value = value;
		this.setVehicleYearValidity(event.target, value);
		event.target.reportValidity();
		this.updateNumericField('FSC_Ano_Vehiculo__c', value, 'guarantee');
	}

	setVehicleYearValidity(input, value) {
		if (this.loanRequestType === LOAN_TYPE_VEHICULO && !this.loanTermConfiguration) {
			input.setCustomValidity(this.loanTermConfigurationError || 'Espere a que cargue la configuración de plazos de crédito.');
			return;
		}
		const year = Number(value);
		const isCompleteYear = /^\d{4}$/.test(String(value));
		const isWithinRange = year >= this.anioVehiculoMinimo && year <= this.anioVehiculoMaximo;
		input.setCustomValidity(
			value && (!isCompleteYear || !isWithinRange) ? `Ingrese un año entre ${this.anioVehiculoMinimo} y ${this.anioVehiculoMaximo}.` : ''
		);
	}

	clearGuaranteeFieldsForClass(draft) {
		if (this.isRealEstateGuaranteeClass(draft.FSC_Clase_de_Garantia__c) || this.isVehicleGuaranteeClass(draft.FSC_Clase_de_Garantia__c)) {
			draft.FSC_Descripcion_de_la_Garantia__c = '';
		}

		if (!this.isRealEstateGuaranteeClass(draft.FSC_Clase_de_Garantia__c)) {
			draft.FSC_Proposito_Garantia_Hipotecario__c = '';
			draft.FSC_Valor_Tasado__c = '';
			draft.FSC_Valor_Mejoras__c = '';
			draft.FSC_SaldoPrimeraHipoteca__c = '';
			draft.FSC_EsTasadorExterno__c = null;
			draft.FSC_NombreTasadorExterno__c = '';
			draft.FSC_Tasado_Por__c = '';
			draft.FSC_Fecha_Tasacion__c = '';
			draft.FSC_Monto_Inicial_Avance_Pagado__c = '';
			draft.FSC_Valor_Inmueble__c = '';
			draft.FSC_Precio_de_Venta__c = '';
			draft.FSC_Metros_Cuadrados_de_Construccion__c = '';
			draft.FSC_Ubicacion__c = '';
			draft.FSC_Tipo_de_Inmueble__c = '';
		}

		if (!this.isVehicleGuaranteeClass(draft.FSC_Clase_de_Garantia__c)) {
			draft.FSC_Es_Concesionario_Dealer__c = null;
			draft.FSC_Concesionario__c = '';
			draft.FSC_Marca_Vehiculo__c = '';
			draft.FSC_Modelo_Vehiculo__c = '';
			draft.FSC_Ano_Vehiculo__c = '';
			draft.FSC_Color_Vehiculo__c = '';
			draft.FSC_Numero_Chasis_Vehiculo__c = '';
			draft.FSC_Serial_Motor_Vehiculo__c = '';
			draft.FSC_Numero_Placa_Vehiculo__c = '';
			draft.FSC_Numero_Matricula__c = '';
			draft.FSC_Fecha_Expedicion_Vehiculo__c = '';
			draft.FSC_Valor_Vehiculo__c = '';
		}

		if (draft.FSC_Es_Concesionario_Dealer__c !== true) {
			draft.FSC_Concesionario__c = '';
		}

		if (draft.FSC_EsTasadorExterno__c === true) {
			draft.FSC_Tasado_Por__c = '';
		} else if (draft.FSC_EsTasadorExterno__c === false) {
			draft.FSC_NombreTasadorExterno__c = '';
		}
	}

	syncGuaranteeTypeWithOptions() {
		const currentGuaranteeType = this.guaranteeDraft.FSC_Tipo_de_Garantia__c;
		if (!currentGuaranteeType) {
			return;
		}

		const hasCurrentValue = this.guaranteeTypeOptions.some((option) => option.value === currentGuaranteeType);
		if (hasCurrentValue) {
			return;
		}

		this.guaranteeDraft = {
			...this.guaranteeDraft,
			FSC_Tipo_de_Garantia__c: '',
		};
	}

	clearVehicleModelIfInvalid(draft) {
		if (!draft.FSC_Modelo_Vehiculo__c) {
			return;
		}

		const modelOptions = this.getModelOptionsForBrand(draft.FSC_Marca_Vehiculo__c);
		const hasCurrentValue = modelOptions.some((option) => option.value === draft.FSC_Modelo_Vehiculo__c);
		if (!hasCurrentValue) {
			draft.FSC_Modelo_Vehiculo__c = '';
		}
	}

	syncVehicleModelWithOptions() {
		const nextDraft = { ...this.guaranteeDraft };
		this.clearVehicleModelIfInvalid(nextDraft);

		if (nextDraft.FSC_Modelo_Vehiculo__c !== this.guaranteeDraft.FSC_Modelo_Vehiculo__c) {
			this.guaranteeDraft = nextDraft;
		}
	}

	saveGuarantee() {
		if (!this.validateGuaranteeConfiguration()) {
			return;
		}
		if (!this.validateGuaranteeInputs()) {
			this.showToast('Campo requerido', 'Debe completar todos los campos obligatorios de la garantia.', 'warning');
			return;
		}

		if (this.hasIncompatibleGuaranteeGroup(this.guaranteeDraft.FSC_Clase_de_Garantia__c)) {
			this.showToast(
				'Garantia incompatible',
				'No puede combinar garantias de vehiculo e hipotecarias dentro de la misma facilidad.',
				'warning'
			);
			return;
		}

		const payload = {
			__key: this.guaranteeEditKey || this.generateRowKey('garantia'),
			Name: `${this.guaranteeDraft.FSC_Tipo_de_Garantia__c || 'Garantia'}`,
			FSC_Clase_de_Garantia__c: this.guaranteeDraft.FSC_Clase_de_Garantia__c,
			FSC_Tipo_de_Garantia__c: this.guaranteeDraft.FSC_Tipo_de_Garantia__c,
			FSC_Descripcion_de_la_Garantia__c: this.guaranteeDraft.FSC_Descripcion_de_la_Garantia__c || '',
			FSC_Proposito_Garantia_Hipotecario__c: this.guaranteeDraft.FSC_Proposito_Garantia_Hipotecario__c || '',
			FSC_Valor_Tasado__c: this.normalizeNumberValue(this.guaranteeDraft.FSC_Valor_Tasado__c, 2),
			FSC_Valor_Mejoras__c: this.normalizeNumberValue(this.guaranteeDraft.FSC_Valor_Mejoras__c, 2),
			FSC_SaldoPrimeraHipoteca__c: this.normalizeNumberValue(this.guaranteeDraft.FSC_SaldoPrimeraHipoteca__c, 2),
			FSC_EsTasadorExterno__c: this.guaranteeDraft.FSC_EsTasadorExterno__c === true,
			FSC_NombreTasadorExterno__c: this.guaranteeDraft.FSC_NombreTasadorExterno__c || '',
			FSC_Tasado_Por__c: this.guaranteeDraft.FSC_Tasado_Por__c || '',
			FSC_Fecha_Tasacion__c: this.guaranteeDraft.FSC_Fecha_Tasacion__c || null,
			FSC_Monto_Inicial_Avance_Pagado__c: this.normalizeNumberValue(this.guaranteeDraft.FSC_Monto_Inicial_Avance_Pagado__c, 2),
			FSC_Valor_Inmueble__c: this.normalizeNumberValue(this.guaranteeDraft.FSC_Valor_Inmueble__c, 2),
			FSC_Precio_de_Venta__c: this.normalizeNumberValue(this.guaranteeDraft.FSC_Precio_de_Venta__c, 2),
			FSC_Metros_Cuadrados_de_Construccion__c: this.normalizeNumberValue(this.guaranteeDraft.FSC_Metros_Cuadrados_de_Construccion__c, 2),
			FSC_Ubicacion__c: this.guaranteeDraft.FSC_Ubicacion__c || '',
			FSC_Tipo_de_Inmueble__c: this.guaranteeDraft.FSC_Tipo_de_Inmueble__c || '',
			FSC_Es_Concesionario_Dealer__c: this.guaranteeDraft.FSC_Es_Concesionario_Dealer__c === true,
			FSC_Concesionario__c: this.guaranteeDraft.FSC_Concesionario__c || '',
			FSC_Marca_Vehiculo__c: this.guaranteeDraft.FSC_Marca_Vehiculo__c || '',
			FSC_Modelo_Vehiculo__c: this.guaranteeDraft.FSC_Modelo_Vehiculo__c || '',
			FSC_Ano_Vehiculo__c: this.normalizeNumberValue(this.guaranteeDraft.FSC_Ano_Vehiculo__c, 0),
			FSC_Color_Vehiculo__c: this.guaranteeDraft.FSC_Color_Vehiculo__c || '',
			FSC_Numero_Chasis_Vehiculo__c: this.guaranteeDraft.FSC_Numero_Chasis_Vehiculo__c || '',
			FSC_Serial_Motor_Vehiculo__c: this.guaranteeDraft.FSC_Serial_Motor_Vehiculo__c || '',
			FSC_Numero_Placa_Vehiculo__c: this.guaranteeDraft.FSC_Numero_Placa_Vehiculo__c || '',
			FSC_Numero_Matricula__c: this.guaranteeDraft.FSC_Numero_Matricula__c || '',
			FSC_Fecha_Expedicion_Vehiculo__c: this.guaranteeDraft.FSC_Fecha_Expedicion_Vehiculo__c || null,
			FSC_Valor_Vehiculo__c: this.normalizeNumberValue(this.guaranteeDraft.FSC_Valor_Vehiculo__c, 2),
		};

		if (this.guaranteeEditKey) {
			this.guaranteeRows = this.guaranteeRows.map((item) => {
				return item.__key === this.guaranteeEditKey ? payload : item;
			});
		} else {
			this.guaranteeRows = [...this.guaranteeRows, payload];
		}

		this.closeGuaranteeEditor();
		this.updatePlazoMesesValidity();
		this.recalculateInsuranceDraftPremium();
		this.persistFacilityDraft();
	}

	validateGuaranteeConfiguration() {
		if (this.isGuaranteeConfigurationReady) {
			return true;
		}
		this.showToast(
			'Configuracion de garantias',
			this.guaranteeConfigurationError || 'Espere a que cargue la configuracion de garantias.',
			'warning'
		);
		return false;
	}

	validateGuaranteeInputs() {
		const inputs = [...this.template.querySelectorAll('[data-guarantee-input]')];
		return inputs.reduce((isValid, input) => {
			if (input.name === 'FSC_Ano_Vehiculo__c') {
				this.setVehicleYearValidity(input, input.value);
			}
			if (input.name === 'FSC_Fecha_Expedicion_Vehiculo__c') {
				input.setCustomValidity(
					input.value > this.fechaTasacionMaxima ? 'La fecha de expedición del vehículo no puede ser posterior a hoy.' : ''
				);
			}
			input.reportValidity();
			return isValid && input.checkValidity();
		}, true);
	}

	closeGuaranteeEditor() {
		this.showGuaranteeEditor = false;
		this.guaranteeEditKey = null;
		this.guaranteeDraft = this.createGuaranteeDraft();
	}

	handleAddInsurance() {
		this.insuranceDraft = this.createInsuranceDraft();
		this.insuranceEditKey = null;
		this.showInsuranceEditor = true;
	}

	handleInsuranceRowAction(event) {
		const { action, row } = event.detail;

		if (action.name === 'edit') {
			const nextDraft = {
				__key: row.__key,
				FSC_Tipo_de_Seguro__c: row.FSC_Tipo_de_Seguro__c || '',
				FSC_Monto_de_la_Prima__c: this.normalizeInputValue(row.FSC_Monto_de_la_Prima__c),
				FSC_Seguro_Desempleo__c: this.normalizeBoolean(row.FSC_Seguro_Desempleo__c),
				FSC_Monto_Prima_Desempleo__c: this.normalizeInputValue(row.FSC_Monto_Prima_Desempleo__c),
				FSC_Fuente_de_Ingresos__c: row.FSC_Fuente_de_Ingresos__c || '',
			};
			this.insuranceDraft = this.isLifeInsuranceType(nextDraft.FSC_Tipo_de_Seguro__c)
				? nextDraft
				: this.resetUnemploymentInsuranceFields(nextDraft);
			this.insuranceEditKey = row.__key;
			this.showInsuranceEditor = true;
			this.loadInsuranceRate(this.insuranceDraft.FSC_Tipo_de_Seguro__c);
			return;
		}

		if (action.name === 'delete') {
			this.insuranceRows = this.insuranceRows.filter((item) => item.__key !== row.__key);
			this.persistFacilityDraft();
		}
	}

	async handleInsuranceDraftChange(event) {
		const fieldName = event.target.name;
		const value = event.detail?.value ?? event.target.value;
		const nextDraft = {
			...this.insuranceDraft,
			[fieldName]: value,
		};

		if (fieldName === 'FSC_Tipo_de_Seguro__c') {
			if (!this.isLifeInsuranceType(value)) {
				this.resetUnemploymentInsuranceFields(nextDraft);
			}

			if (!value) {
				nextDraft.FSC_Monto_de_la_Prima__c = '';
				this.insuranceDraft = nextDraft;
				return;
			}

			nextDraft.FSC_Monto_de_la_Prima__c = '';
			this.insuranceDraft = nextDraft;
			await this.loadInsuranceRate(value);
			return;
		}

		if (fieldName === 'FSC_Fuente_de_Ingresos__c') {
			nextDraft.FSC_Monto_Prima_Desempleo__c = this.calculateUnemploymentPremium(nextDraft);
		}

		this.insuranceDraft = nextDraft;
	}

	handleInsuranceBooleanChange(event) {
		const value = event.detail.value === 'true';
		const nextDraft = {
			...this.insuranceDraft,
			FSC_Seguro_Desempleo__c: value,
		};

		if (!value) {
			nextDraft.FSC_Monto_Prima_Desempleo__c = '';
			nextDraft.FSC_Fuente_de_Ingresos__c = '';
		} else {
			nextDraft.FSC_Monto_Prima_Desempleo__c = this.calculateUnemploymentPremium(nextDraft);
		}

		this.insuranceDraft = nextDraft;
	}

	saveInsurance() {
		if (!this.insuranceDraft.FSC_Tipo_de_Seguro__c) {
			this.showToast('Campo requerido', 'Debe completar el tipo de seguro.', 'warning');
			return;
		}

		const isLifeInsurance = this.isLifeInsuranceSelected;

		if (isLifeInsurance && this.insuranceDraft.FSC_Seguro_Desempleo__c === null) {
			this.showToast('Campo requerido', 'Debe indicar si el seguro es de desempleo.', 'warning');
			return;
		}

		if (isLifeInsurance && this.insuranceDraft.FSC_Seguro_Desempleo__c && !this.insuranceDraft.FSC_Fuente_de_Ingresos__c) {
			this.showToast('Campo requerido', 'Debe completar la fuente de ingresos.', 'warning');
			return;
		}

		if (this.isInsuranceRateLoading) {
			this.showToast('Espere', 'Se esta consultando la tasa del tipo de seguro seleccionado.', 'info');
			return;
		}

		if (
			this.insuranceDraft.FSC_Monto_de_la_Prima__c === '' ||
			this.insuranceDraft.FSC_Monto_de_la_Prima__c === null ||
			this.insuranceDraft.FSC_Monto_de_la_Prima__c === undefined
		) {
			this.showToast(
				'Prima no calculada',
				'Complete la fecha de nacimiento, el monto solicitado y la garantia aplicable antes de guardar el seguro.',
				'warning'
			);
			return;
		}

		const payload = {
			__key: this.insuranceEditKey || this.generateRowKey('seguro'),
			Name: this.insuranceDraft.FSC_Tipo_de_Seguro__c,
			FSC_Tipo_de_Seguro__c: this.insuranceDraft.FSC_Tipo_de_Seguro__c,
			FSC_Monto_de_la_Prima__c: this.normalizeNumberValue(this.insuranceDraft.FSC_Monto_de_la_Prima__c, 2),
			FSC_Seguro_Desempleo__c: isLifeInsurance ? this.insuranceDraft.FSC_Seguro_Desempleo__c : null,
			FSC_Monto_Prima_Desempleo__c: isLifeInsurance ? this.normalizeNumberValue(this.insuranceDraft.FSC_Monto_Prima_Desempleo__c, 2) : null,
			FSC_Fuente_de_Ingresos__c: isLifeInsurance ? this.insuranceDraft.FSC_Fuente_de_Ingresos__c || '' : '',
		};

		if (this.insuranceEditKey) {
			this.insuranceRows = this.insuranceRows.map((item) => {
				return item.__key === this.insuranceEditKey ? payload : item;
			});
		} else {
			this.insuranceRows = [...this.insuranceRows, payload];
		}

		this.closeInsuranceEditor();
		this.persistFacilityDraft();
	}

	closeInsuranceEditor() {
		this.showInsuranceEditor = false;
		this.insuranceEditKey = null;
		this.insuranceDraft = this.createInsuranceDraft();
		this.isInsuranceRateLoading = false;
		this.insuranceRateRequestId += 1;
	}

	async loadInsuranceRate(insuranceType) {
		const requestId = this.insuranceRateRequestId + 1;
		this.insuranceRateRequestId = requestId;
		this.isInsuranceRateLoading = true;
		const selectedOption = this.tipoSeguroOptions.find((option) => option.value === insuranceType);

		if (selectedOption?.rate !== null && selectedOption?.rate !== undefined) {
			const nextDraft = {
				...this.insuranceDraft,
				FSC_Monto_de_la_Prima__c: this.calculateInsurancePremium(selectedOption),
			};
			nextDraft.FSC_Monto_Prima_Desempleo__c = this.calculateUnemploymentPremium(nextDraft);
			this.insuranceDraft = nextDraft;
			this.isInsuranceRateLoading = false;
			return;
		}

		try {
			const result = await getInsuranceRate({
				facilityValue: this.facilidad,
				insuranceType,
			});

			if (requestId !== this.insuranceRateRequestId || this.insuranceDraft.FSC_Tipo_de_Seguro__c !== insuranceType) {
				return;
			}

			const nextDraft = {
				...this.insuranceDraft,
				FSC_Monto_de_la_Prima__c: this.calculateInsurancePremium(result),
			};
			nextDraft.FSC_Monto_Prima_Desempleo__c = this.calculateUnemploymentPremium(nextDraft);
			this.insuranceDraft = nextDraft;
		} catch (error) {
			if (requestId !== this.insuranceRateRequestId) {
				return;
			}

			this.insuranceDraft = {
				...this.insuranceDraft,
				FSC_Monto_de_la_Prima__c: '',
			};
			this.logPicklistError('tasa puntual de seguro desde metadata', error);
			this.showToast('Error', 'No fue posible obtener la tasa del tipo de seguro seleccionado.', 'error');
		} finally {
			if (requestId === this.insuranceRateRequestId) {
				this.isInsuranceRateLoading = false;
			}
		}
	}

	getSelectedInsuranceConfiguration() {
		return this.tipoSeguroOptions.find((option) => option.value === this.insuranceDraft.FSC_Tipo_de_Seguro__c);
	}

	recalculateInsuranceDraftPremium() {
		if (!this.showInsuranceEditor || !this.insuranceDraft.FSC_Tipo_de_Seguro__c || this.isInsuranceRateLoading) {
			return;
		}

		const insuranceConfiguration = this.getSelectedInsuranceConfiguration();
		if (insuranceConfiguration?.rate === null || insuranceConfiguration?.rate === undefined) {
			return;
		}

		const nextDraft = {
			...this.insuranceDraft,
			FSC_Monto_de_la_Prima__c: this.calculateInsurancePremium(insuranceConfiguration),
		};
		nextDraft.FSC_Monto_Prima_Desempleo__c = this.calculateUnemploymentPremium(nextDraft);
		this.insuranceDraft = nextDraft;
	}

	calculateInsurancePremium(insuranceConfiguration) {
		const insuranceRate = insuranceConfiguration?.rate;
		if (insuranceRate === null || insuranceRate === undefined) {
			return '';
		}

		const formulaParameters = this.parseInsuranceFormulaParameters(insuranceConfiguration);
		const debtor = this.getApplicantByRole('deudor');
		if (formulaParameters.requiresApplicantAge && !debtor?.FSC_FechaNacimiento__c) {
			return '';
		}
		if (
			formulaParameters.maximumApplicantAge &&
			this.calculateAge(debtor?.FSC_FechaNacimiento__c) > Number(formulaParameters.maximumApplicantAge)
		) {
			return '';
		}

		const calculationBase = this.getInsuranceCalculationBase(insuranceConfiguration?.calculationBase);
		const rate = Number(insuranceRate);
		const rateDivisor = Number(insuranceConfiguration?.rateDivisor || 1);
		if (
			!Number.isFinite(calculationBase) ||
			calculationBase <= 0 ||
			!Number.isFinite(rate) ||
			!Number.isFinite(rateDivisor) ||
			rateDivisor <= 0
		) {
			return '';
		}
		if (
			(formulaParameters.minimumBase && calculationBase < Number(formulaParameters.minimumBase)) ||
			(formulaParameters.maximumBase && calculationBase > Number(formulaParameters.maximumBase))
		) {
			return '';
		}

		const coDebtor = this.getApplicantByRole('codeudor');
		const applicantFactor = coDebtor?.FSC_FechaNacimiento__c ? Number(formulaParameters.coDebtorMultiplier || 1) : 1;
		const calculatedPremium = (rate * calculationBase * applicantFactor) / rateDivisor;
		const minimumMonthlyPremium = Number(formulaParameters.minimumMonthlyPremium || 0);
		const fixedMonthlyCharge = Number(formulaParameters.fixedMonthlyCharge || 0);
		const fixedChargeFactor = coDebtor?.FSC_FechaNacimiento__c ? Number(formulaParameters.fixedChargeMultiplierWithCoDebtor || 1) : 1;
		const premium = Math.max(calculatedPremium, minimumMonthlyPremium) + fixedMonthlyCharge * fixedChargeFactor;
		return this.normalizeInputValue(this.normalizeNumberValue(premium, 2));
	}

	calculateAge(birthDateValue) {
		if (!birthDateValue) {
			return NaN;
		}

		const birthDate = new Date(`${birthDateValue}T00:00:00`);
		if (Number.isNaN(birthDate.getTime())) {
			return NaN;
		}

		const today = new Date();
		let age = today.getFullYear() - birthDate.getFullYear();
		const birthdayHasPassed =
			today.getMonth() > birthDate.getMonth() || (today.getMonth() === birthDate.getMonth() && today.getDate() >= birthDate.getDate());
		if (!birthdayHasPassed) {
			age -= 1;
		}
		return age;
	}

	parseInsuranceFormulaParameters(insuranceConfiguration) {
		if (!insuranceConfiguration?.formulaParameters) {
			return {};
		}

		try {
			return JSON.parse(insuranceConfiguration.formulaParameters);
		} catch (error) {
			console.error('Invalid insurance formula parameters in FSC_TiposSeguro__mdt', error);
			return {};
		}
	}

	getInsuranceCalculationBase(calculationBase) {
		if (calculationBase === 'MONTO_SOLICITADO') {
			return this.parseNumber(this.montoSolicitado);
		}

		if (calculationBase === 'VALOR_VEHICULO') {
			const vehicleGuarantee = this.guaranteeRows.find((guarantee) => this.parseNumber(guarantee.FSC_Valor_Vehiculo__c) > 0);
			return this.parseNumber(vehicleGuarantee?.FSC_Valor_Vehiculo__c);
		}

		if (calculationBase === 'VALOR_INMUEBLE') {
			const realEstateGuarantee = this.guaranteeRows.find(
				(guarantee) =>
					this.parseNumber(guarantee.FSC_Valor_Tasado__c) > 0 ||
					this.parseNumber(guarantee.FSC_Valor_Inmueble__c) > 0 ||
					this.parseNumber(guarantee.FSC_Precio_de_Venta__c) > 0
			);
			return this.parseNumber(
				realEstateGuarantee?.FSC_Valor_Tasado__c || realEstateGuarantee?.FSC_Valor_Inmueble__c || realEstateGuarantee?.FSC_Precio_de_Venta__c
			);
		}

		return NaN;
	}

	getApplicantByRole(role) {
		const acceptedRoles = role === 'deudor' ? ['deudor', 'solicitante', 'solicitanteprincipal'] : ['codeudor', 'cosolicitante'];
		return this.extractLoanApplicants(this.omniJsonData).find((applicant) =>
			acceptedRoles.includes(this.normalizeContextKey(applicant?.FSC_TipoSolicitante__c))
		);
	}

	calculateUnemploymentPremium(draft = this.insuranceDraft) {
		if (!draft?.FSC_Seguro_Desempleo__c || !this.isLifeInsuranceType(draft.FSC_Tipo_de_Seguro__c)) {
			return '';
		}

		const unemploymentParameters = this.getUnemploymentParameters(draft.FSC_Tipo_de_Seguro__c);
		if (!unemploymentParameters) {
			return '';
		}

		const incomeSource = this.normalizeContextKey(draft.FSC_Fuente_de_Ingresos__c);
		const baseRate =
			incomeSource === 'empleadoprivado'
				? Number(unemploymentParameters.privateRate)
				: ['empleadopublico', 'militar'].includes(incomeSource)
					? Number(unemploymentParameters.publicRate)
					: null;
		if (baseRate === null || !this.isEligibleForUnemploymentInsurance(incomeSource, unemploymentParameters)) {
			return '';
		}

		const requestedAmount = this.parseNumber(this.montoSolicitado);
		const installmentAmount = this.parseNumber(this.montoCuota);
		const lifePremium = this.parseNumber(draft.FSC_Monto_de_la_Prima__c);
		if (
			requestedAmount <= 0 ||
			installmentAmount <= 0 ||
			draft.FSC_Monto_de_la_Prima__c === '' ||
			draft.FSC_Monto_de_la_Prima__c === null ||
			draft.FSC_Monto_de_la_Prima__c === undefined
		) {
			return '';
		}

		const administrationFee = this.getInsuranceAdministrationFee(requestedAmount, unemploymentParameters.administrationFees);
		const unemploymentRate =
			baseRate *
			Number(unemploymentParameters.coverageMonths) *
			Number(unemploymentParameters.taxFactor) *
			Number(unemploymentParameters.markupFactor);
		const installmentWithLifeAndAdministration = installmentAmount + lifePremium + administrationFee;
		const debtorUnemploymentPremium = (installmentWithLifeAndAdministration * unemploymentRate) / 1000;
		const financedInstallment =
			(installmentWithLifeAndAdministration + debtorUnemploymentPremium) * Number(unemploymentParameters.financingFactor);

		if (financedInstallment > Number(unemploymentParameters.maxInstallment)) {
			return '';
		}

		return this.normalizeInputValue(this.normalizeNumberValue((financedInstallment * unemploymentRate) / 1000, 2));
	}

	getUnemploymentParameters(insuranceType = this.insuranceDraft.FSC_Tipo_de_Seguro__c) {
		const selectedConfiguration = this.tipoSeguroOptions.find((option) => option.value === insuranceType);
		const selectedUnemploymentParameters = this.parseInsuranceFormulaParameters(selectedConfiguration).unemployment;
		if (selectedUnemploymentParameters) {
			return selectedUnemploymentParameters;
		}

		for (const insuranceConfiguration of this.tipoSeguroOptions) {
			const unemploymentParameters = this.parseInsuranceFormulaParameters(insuranceConfiguration).unemployment;
			if (unemploymentParameters) {
				return unemploymentParameters;
			}
		}
		return null;
	}

	getInsuranceAdministrationFee(requestedAmount, administrationFees = []) {
		const matchingRange = administrationFees.find(([maximumAmount]) => requestedAmount <= Number(maximumAmount));
		return matchingRange ? Number(matchingRange[1]) : 0;
	}

	isEligibleForUnemploymentInsurance(incomeSource, unemploymentParameters) {
		const debtor = this.getApplicantByRole('deudor');
		const employmentStartDate = debtor?.FSC_TiempoLaborando__c;
		if (!employmentStartDate) {
			return false;
		}

		const employmentMonths = this.calculateEmploymentMonths(employmentStartDate);
		if (!Number.isFinite(employmentMonths)) {
			return false;
		}

		const minimumMonths =
			incomeSource === 'empleadoprivado'
				? Number(unemploymentParameters.privateMinimumMonths)
				: Number(unemploymentParameters.publicMinimumMonths);
		return employmentMonths >= minimumMonths;
	}

	calculateEmploymentMonths(employmentStartDate) {
		const startDate = new Date(`${employmentStartDate}T00:00:00`);
		if (Number.isNaN(startDate.getTime())) {
			return NaN;
		}

		const today = new Date();
		let employmentMonths = (today.getFullYear() - startDate.getFullYear()) * 12 + today.getMonth() - startDate.getMonth();
		if (today.getDate() < startDate.getDate()) {
			employmentMonths -= 1;
		}
		return employmentMonths;
	}

	createGuaranteeDraft() {
		return {
			__key: null,
			...EMPTY_GUARANTEE,
		};
	}

	createInsuranceDraft() {
		return {
			__key: null,
			...EMPTY_INSURANCE,
		};
	}

	normalizeFacilities(rows) {
		return rows.map((row) => ({
			__key: row.__key || row.Id || this.generateRowKey('facilidad'),
			...row,
			FSC_Garantias__r: this.normalizeGuarantees(row.FSC_Garantias__r),
			FSC_Seguros__r: this.normalizeInsurances(row.FSC_Seguros__r),
		}));
	}

	normalizeGuarantees(rows) {
		const normalizedRows = Array.isArray(rows) ? rows : Array.isArray(rows?.records) ? rows.records : [];

		return normalizedRows.map((row) => ({
			__key: row.__key || row.Id || this.generateRowKey('garantia'),
			Name: row.Name || '',
			FSC_Clase_de_Garantia__c: row.FSC_Clase_de_Garantia__c || '',
			FSC_Tipo_de_Garantia__c: row.FSC_Tipo_de_Garantia__c || '',
			FSC_Descripcion_de_la_Garantia__c: row.FSC_Descripcion_de_la_Garantia__c || '',
			FSC_Proposito_Garantia_Hipotecario__c: row.FSC_Proposito_Garantia_Hipotecario__c || '',
			FSC_Valor_Tasado__c: this.normalizeNumberValue(row.FSC_Valor_Tasado__c, 2),
			FSC_Valor_Mejoras__c: this.normalizeNumberValue(row.FSC_Valor_Mejoras__c, 2),
			FSC_SaldoPrimeraHipoteca__c: this.normalizeNumberValue(row.FSC_SaldoPrimeraHipoteca__c, 2),
			FSC_EsTasadorExterno__c: this.normalizeBoolean(row.FSC_EsTasadorExterno__c),
			FSC_NombreTasadorExterno__c: row.FSC_NombreTasadorExterno__c || '',
			FSC_Tasado_Por__c: row.FSC_Tasado_Por__c || '',
			FSC_Fecha_Tasacion__c: row.FSC_Fecha_Tasacion__c || '',
			FSC_Monto_Inicial_Avance_Pagado__c: this.normalizeNumberValue(row.FSC_Monto_Inicial_Avance_Pagado__c, 2),
			FSC_Valor_Inmueble__c: this.normalizeNumberValue(row.FSC_Valor_Inmueble__c, 2),
			FSC_Precio_de_Venta__c: this.normalizeNumberValue(row.FSC_Precio_de_Venta__c, 2),
			FSC_Metros_Cuadrados_de_Construccion__c: this.normalizeNumberValue(row.FSC_Metros_Cuadrados_de_Construccion__c, 2),
			FSC_Ubicacion__c: row.FSC_Ubicacion__c || '',
			FSC_Tipo_de_Inmueble__c: row.FSC_Tipo_de_Inmueble__c || '',
			FSC_Es_Concesionario_Dealer__c: this.normalizeBoolean(row.FSC_Es_Concesionario_Dealer__c),
			FSC_Concesionario__c: row.FSC_Concesionario__c || '',
			FSC_Marca_Vehiculo__c: row.FSC_Marca_Vehiculo__c || '',
			FSC_Modelo_Vehiculo__c: row.FSC_Modelo_Vehiculo__c || '',
			FSC_Ano_Vehiculo__c: this.normalizeNumberValue(row.FSC_Ano_Vehiculo__c, 0),
			FSC_Color_Vehiculo__c: row.FSC_Color_Vehiculo__c || '',
			FSC_Numero_Chasis_Vehiculo__c: row.FSC_Numero_Chasis_Vehiculo__c || '',
			FSC_Serial_Motor_Vehiculo__c: row.FSC_Serial_Motor_Vehiculo__c || '',
			FSC_Numero_Placa_Vehiculo__c: row.FSC_Numero_Placa_Vehiculo__c || '',
			FSC_Numero_Matricula__c: row.FSC_Numero_Matricula__c || '',
			FSC_Fecha_Expedicion_Vehiculo__c: row.FSC_Fecha_Expedicion_Vehiculo__c || '',
			FSC_Valor_Vehiculo__c: this.normalizeNumberValue(row.FSC_Valor_Vehiculo__c, 2),
		}));
	}

	normalizeInsurances(rows) {
		const normalizedRows = Array.isArray(rows) ? rows : Array.isArray(rows?.records) ? rows.records : [];

		return normalizedRows.map((row) => {
			const isLifeInsurance = this.isLifeInsuranceType(row.FSC_Tipo_de_Seguro__c);
			return {
				__key: row.__key || row.Id || this.generateRowKey('seguro'),
				Name: row.Name || '',
				FSC_Tipo_de_Seguro__c: row.FSC_Tipo_de_Seguro__c || '',
				FSC_Monto_de_la_Prima__c: this.normalizeNumberValue(row.FSC_Monto_de_la_Prima__c, 5),
				FSC_Seguro_Desempleo__c: isLifeInsurance ? this.normalizeBoolean(row.FSC_Seguro_Desempleo__c) : null,
				FSC_Monto_Prima_Desempleo__c: isLifeInsurance ? this.normalizeNumberValue(row.FSC_Monto_Prima_Desempleo__c, 5) : null,
				FSC_Fuente_de_Ingresos__c: isLifeInsurance ? row.FSC_Fuente_de_Ingresos__c || '' : '',
			};
		});
	}

	serializeGuarantees() {
		return this.guaranteeRows.map((item, index) => ({
			Name: item.Name || `Garantia ${index + 1}`,
			FSC_Clase_de_Garantia__c: item.FSC_Clase_de_Garantia__c || '',
			FSC_Tipo_de_Garantia__c: item.FSC_Tipo_de_Garantia__c || '',
			FSC_Descripcion_de_la_Garantia__c: item.FSC_Descripcion_de_la_Garantia__c || '',
			FSC_Proposito_Garantia_Hipotecario__c: item.FSC_Proposito_Garantia_Hipotecario__c || '',
			FSC_Valor_Tasado__c: this.normalizeNumberValue(item.FSC_Valor_Tasado__c, 2),
			FSC_Valor_Mejoras__c: this.normalizeNumberValue(item.FSC_Valor_Mejoras__c, 2),
			FSC_SaldoPrimeraHipoteca__c: this.normalizeNumberValue(item.FSC_SaldoPrimeraHipoteca__c, 2),
			FSC_EsTasadorExterno__c: item.FSC_EsTasadorExterno__c === true,
			FSC_NombreTasadorExterno__c: item.FSC_NombreTasadorExterno__c || '',
			FSC_Tasado_Por__c: item.FSC_Tasado_Por__c || '',
			FSC_Fecha_Tasacion__c: item.FSC_Fecha_Tasacion__c || null,
			FSC_Monto_Inicial_Avance_Pagado__c: this.normalizeNumberValue(item.FSC_Monto_Inicial_Avance_Pagado__c, 2),
			FSC_Valor_Inmueble__c: this.normalizeNumberValue(item.FSC_Valor_Inmueble__c, 2),
			FSC_Precio_de_Venta__c: this.normalizeNumberValue(item.FSC_Precio_de_Venta__c, 2),
			FSC_Metros_Cuadrados_de_Construccion__c: this.normalizeNumberValue(item.FSC_Metros_Cuadrados_de_Construccion__c, 2),
			FSC_Ubicacion__c: item.FSC_Ubicacion__c || '',
			FSC_Tipo_de_Inmueble__c: item.FSC_Tipo_de_Inmueble__c || '',
			FSC_Es_Concesionario_Dealer__c: item.FSC_Es_Concesionario_Dealer__c === true,
			FSC_Concesionario__c: item.FSC_Concesionario__c || '',
			FSC_Marca_Vehiculo__c: item.FSC_Marca_Vehiculo__c || '',
			FSC_Modelo_Vehiculo__c: item.FSC_Modelo_Vehiculo__c || '',
			FSC_Ano_Vehiculo__c: this.normalizeNumberValue(item.FSC_Ano_Vehiculo__c, 0),
			FSC_Color_Vehiculo__c: item.FSC_Color_Vehiculo__c || '',
			FSC_Numero_Chasis_Vehiculo__c: item.FSC_Numero_Chasis_Vehiculo__c || '',
			FSC_Serial_Motor_Vehiculo__c: item.FSC_Serial_Motor_Vehiculo__c || '',
			FSC_Numero_Placa_Vehiculo__c: item.FSC_Numero_Placa_Vehiculo__c || '',
			FSC_Numero_Matricula__c: item.FSC_Numero_Matricula__c || '',
			FSC_Fecha_Expedicion_Vehiculo__c: item.FSC_Fecha_Expedicion_Vehiculo__c || null,
			FSC_Valor_Vehiculo__c: this.normalizeNumberValue(item.FSC_Valor_Vehiculo__c, 2),
		}));
	}

	serializeInsurances() {
		return this.insuranceRows.map((item, index) => {
			const isLifeInsurance = this.isLifeInsuranceType(item.FSC_Tipo_de_Seguro__c);
			return {
				Name: item.Name || `Seguro ${index + 1}`,
				FSC_Tipo_de_Seguro__c: item.FSC_Tipo_de_Seguro__c || '',
				FSC_Monto_de_la_Prima__c: this.normalizeNumberValue(item.FSC_Monto_de_la_Prima__c, 5),
				FSC_Seguro_Desempleo__c: isLifeInsurance ? item.FSC_Seguro_Desempleo__c : null,
				FSC_Monto_Prima_Desempleo__c: isLifeInsurance ? this.normalizeNumberValue(item.FSC_Monto_Prima_Desempleo__c, 5) : null,
				FSC_Fuente_de_Ingresos__c: isLifeInsurance ? item.FSC_Fuente_de_Ingresos__c || '' : '',
			};
		});
	}

	generateRowKey(prefix) {
		this.rowKeyCounter += 1;
		return `${prefix}-${this.rowKeyCounter}`;
	}

	normalizeBoolean(value) {
		if (value === true || value === 'true') {
			return true;
		}

		if (value === false || value === 'false') {
			return false;
		}

		return null;
	}

	booleanToRadioValue(value) {
		if (value === true) {
			return 'true';
		}

		if (value === false) {
			return 'false';
		}

		return '';
	}

	normalizeInputValue(value) {
		return value === null || value === undefined ? '' : String(value);
	}

	normalizeCurrencyValue(value) {
		if (value === null || value === undefined || value === '') {
			return null;
		}

		const numericValue = Number(String(value).replace(/,/g, ''));
		if (!Number.isFinite(numericValue)) {
			return null;
		}

		return Number(numericValue.toFixed(2));
	}

	parseNumber(value) {
		const parsed = Number(String(value).replace(/,/g, ''));
		return Number.isFinite(parsed) ? parsed : 0;
	}

	normalizeNumberValue(value, scale) {
		if (value === '' || value === null || value === undefined) {
			return null;
		}

		const parsed = this.parseNumber(value);
		return scale === 0 ? Math.round(parsed) : Number(parsed.toFixed(scale));
	}

	stringifyFacilities(facilities) {
		return JSON.stringify(Array.isArray(facilities) ? facilities : []);
	}

	@wire(getCreditPolicyRules)
	wiredCreditPolicyRules({ data, error }) {
		if (data) {
			this.creditPolicyRules = data;
			this.creditPolicyError = data.length ? '' : 'No hay reglas de crédito configuradas.';
		} else if (error) {
			this.creditPolicyRules = [];
			this.creditPolicyError = 'No se pudo cargar la política de crédito. Revise los permisos y la configuración.';
		}
	}

	get usesCreditPolicy() {
		return (
			this.isTipoCreditoHipotecario ||
			(this.loanRequestType === LOAN_TYPE_CONSUMO &&
				this.guaranteeRows.some(
					(row) =>
						this.isRealEstateGuaranteeClass(row.FSC_Clase_de_Garantia__c) ||
						this.creditPolicyRules.some((rule) => rule.FSC_Proposito__c === row.FSC_Proposito_Garantia_Hipotecario__c)
				))
		);
	}

	get creditPolicyContext() {
		const source = this.omniJsonData || {};
		const debtor = this.getApplicantByRole('deudor');
		const candidates = [
			source.ContextId,
			source.AccountId,
			source.DatosSolicitante?.AccountId,
			source.StepDatosSolicitante?.AccountId,
			debtor?.AccountId,
		];
		const accountId = candidates.find((value) => String(value || '').startsWith('001')) || '';
		return {
			loanType: this.loanRequestType,
			accountId,
			applicants: {
				LoanApplicant: this.extractLoanApplicants(source).map((applicant) => ({
					FSC_TipoSolicitante__c: applicant.FSC_TipoSolicitante__c,
					FSC_Nacionalidad__c: applicant.FSC_Nacionalidad__c,
				})),
			},
			facility: {
				FSC_Monto_Solicitado__c: this.montoSolicitado,
				FSC_Plazo_meses__c: this.plazoMeses,
				FSC_Moneda__c: this.monedaFacilidad || MONEDA_PESOS,
				FSC_Garantias__r: this.serializeGuarantees(),
			},
		};
	}

	get currentCreditPolicyResult() {
		return this.creditPolicyValidatedKey === JSON.stringify(this.creditPolicyContext) ? this.creditPolicyResult : undefined;
	}

	get creditPolicyValidationMessage() {
		if (!this.usesCreditPolicy) return '';
		if (this.creditPolicyError) return this.creditPolicyError;
		const result = this.currentCreditPolicyResult;
		return result
			? result.valid
				? ''
				: result.message || 'Revise los límites del crédito.'
			: 'Espere a que se validen los límites del crédito.';
	}

	get creditPolicyDisplayMessage() {
		return this.usesCreditPolicy ? this.creditPolicyError || this.currentCreditPolicyResult?.message || '' : '';
	}

	get creditPolicyAmountHelp() {
		const result = this.currentCreditPolicyResult;
		return result?.minAmount != null ? `Monto permitido: ${result.minAmount} a ${result.maxAmount} ${result.currencyCode}.` : '';
	}

	get filteredPropositoGarantiaOptions() {
		if (![LOAN_TYPE_HIPOTECARIO, LOAN_TYPE_CONSUMO].includes(this.loanRequestType)) return this.propositoGarantiaOptions;
		const product = this.isTipoCreditoHipotecario ? 'HIPOTECARIO' : 'CONSUMO_GARANTIA_INMOBILIARIA';
		const currency = this.monedaFacilidad === MONEDA_DOLARES ? 'USD' : 'DOP';
		const profile = this.currentCreditPolicyResult?.profile;
		return this.propositoGarantiaOptions.filter((option) =>
			this.creditPolicyRules.some(
				(rule) =>
					rule.FSC_Producto__c === product &&
					rule.FSC_Proposito__c === option.value &&
					(rule.FSC_Moneda__c === currency || rule.FSC_Moneda__c === 'TODAS') &&
					(!profile || rule.FSC_Perfil__c === profile)
			)
		);
	}

	get draftCreditPolicyRule() {
		const product = this.isTipoCreditoHipotecario ? 'HIPOTECARIO' : 'CONSUMO_GARANTIA_INMOBILIARIA';
		return this.creditPolicyRules.find(
			(rule) => rule.FSC_Producto__c === product && rule.FSC_Proposito__c === this.guaranteeDraft.FSC_Proposito_Garantia_Hipotecario__c
		);
	}

	get requiresImprovementsValue() {
		return this.draftCreditPolicyRule?.FSC_BaseCalculo__c === 'MEJORAS';
	}

	get requiresPropertyValue() {
		return !!this.draftCreditPolicyRule && !this.requiresImprovementsValue;
	}

	get requiresFirstMortgageBalance() {
		return this.draftCreditPolicyRule?.FSC_BaseCalculo__c === 'INMUEBLE_CON_PRIMER_RANGO';
	}

	get requiresSalePrice() {
		return this.draftCreditPolicyRule?.FSC_BaseCalculo__c === 'MENOR_INMUEBLE_VENTA';
	}

	renderedCallback() {
		this.queueCreditPolicyValidation();
		this.updateCreditPolicyAmountValidity();
		this.updatePlazoMesesValidity();
	}

	disconnectedCallback() {
		this.creditPolicyDisconnected = true;
		clearTimeout(this.creditPolicyTimer);
	}

	queueCreditPolicyValidation(immediate = false) {
		if (!this.usesCreditPolicy || this.creditPolicyDisconnected) return;
		const contextJson = JSON.stringify(this.creditPolicyContext);
		if (contextJson === this.creditPolicyRequestKey && (!immediate || this.creditPolicyTimer === undefined)) return;
		this.creditPolicyRequestKey = contextJson;
		clearTimeout(this.creditPolicyTimer);
		this.creditPolicyTimer = undefined;
		this.updateCreditPolicyAmountValidity(true);
		this.updatePlazoMesesValidity(true);
		const validate = () => {
			this.creditPolicyTimer = undefined;
			if (!this.isCurrentCreditPolicyRequest(contextJson)) return;
			evaluateCreditPolicy({ contextJson })
				.then((result) => {
					if (!this.isCurrentCreditPolicyRequest(contextJson)) return;
					this.applyCreditPolicyResult(result, contextJson);
				})
				.catch(() => {
					if (!this.isCurrentCreditPolicyRequest(contextJson)) return;
					this.applyCreditPolicyResult(
						{ valid: false, message: 'No se pudieron validar los límites. Revise los datos y los permisos.' },
						contextJson
					);
				});
		};
		if (immediate) validate();
		else this.creditPolicyTimer = setTimeout(validate, 1000);
	}

	isCurrentCreditPolicyRequest(contextJson) {
		return (
			!this.creditPolicyDisconnected &&
			this.usesCreditPolicy &&
			this.creditPolicyRequestKey === contextJson &&
			JSON.stringify(this.creditPolicyContext) === contextJson
		);
	}

	applyCreditPolicyResult(result, contextJson) {
		this.creditPolicyResult = result;
		this.creditPolicyValidatedKey = contextJson;
		this.updateCreditPolicyAmountValidity(true);
		this.updatePlazoMesesValidity(true);
		this.omniValidate?.(false);
	}

	updateCreditPolicyAmountValidity(reportErrors = false) {
		const input = this.template.querySelector('lightning-input[name="montoSolicitado"]');
		input?.setCustomValidity(this.usesCreditPolicy ? this.currentCreditPolicyResult?.amountMessage || '' : '');
		if (reportErrors) input?.reportValidity();
	}

	showToast(title, message, variant) {
		this.dispatchEvent(
			new ShowToastEvent({
				title,
				message,
				variant,
			})
		);
	}
}