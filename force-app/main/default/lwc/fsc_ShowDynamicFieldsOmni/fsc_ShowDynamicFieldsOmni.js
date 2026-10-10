import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';

const GASTOS_TRAMITACION = 'gastosTramitacion';
const SUCURSAL_USUARIO = 'sucursalUsuario';
const SEGURO_DE_VIDA = 'seguroDeVida';
const MONTO_CUOTA_REGULAR = 'montoCuotaRegular';
const AMORTIZACION_CUOTAS_IGUALES = 'Cuotas mensuales, iguales y consecutivas, contentivas de capital e intereses cada una';
const AMORTIZACION_CAPITAL_VENCIMIENTO = 'Intereses mensuales sobre saldos insolutos de capital (Capital a vencimiento)';
const GASTOS_TRAMITACION_OMNI_FIELD = 'FSC_GastosTramitacion__c';
const SUCURSAL_USUARIO_OMNI_FIELD = 'FSC_Sucursal__c';
const SEGURO_DE_VIDA_OMNI_FIELD = 'FSC_SeguroVidaMonto__c';
const MONTO_CUOTA_REGULAR_OMNI_FIELD = 'FSC_MontoCuotaRegular__c';
const PASO_SOLICITUD_NODE = 'PasoSolicitud';

export default class Fsc_ShowDynamicFieldsOmni extends OmniscriptBaseMixin(LightningElement) {
	_fieldToShow;

	gastosTramitacionValue = null;
	hasGastosTramitacionApiValue = false;
	seguroDeVidaValue = null;
	hasSeguroDeVidaApiValue = false;
	esquemaAmortizacionValue = '';
	tasaInteresValue = null;
	plazoMesesValue = null;
	montoAprobadoValue = null;
	montoCuotaRegularValue = null;
	sucursalUsuarioValue = '';
	sucursalUsuarioDisplayValue = '';

	@api
	set fieldToShow(value) {
		this._fieldToShow = this.normalizeStringValue(value);
	}

	get fieldToShow() {
		return this._fieldToShow;
	}

	@api
	set gastosTramitacion(value) {
		this.hasGastosTramitacionApiValue = value !== null && value !== undefined && value !== '';
		this.gastosTramitacionValue = this.normalizeCurrencyValue(value);
		this.updateGastosTramitacionOmniJson();
	}

	get gastosTramitacion() {
		return this.gastosTramitacionValue;
	}

	@api
	set seguroDeVida(value) {
		this.hasSeguroDeVidaApiValue = value !== null && value !== undefined && value !== '';
		this.seguroDeVidaValue = this.normalizeCurrencyValue(value);
		this.updateSeguroDeVidaOmniJson();
	}

	get seguroDeVida() {
		return this.seguroDeVidaValue;
	}

	@api
	set esquemaAmortizacion(value) {
		this.esquemaAmortizacionValue = this.normalizeStringValue(value);
		this.calculateMontoCuotaRegular();
	}

	get esquemaAmortizacion() {
		return this.esquemaAmortizacionValue;
	}

	@api
	set tasaInteres(value) {
		this.tasaInteresValue = this.normalizeCurrencyValue(value);
		this.calculateMontoCuotaRegular();
	}

	get tasaInteres() {
		return this.tasaInteresValue;
	}

	@api
	set plazoMeses(value) {
		this.plazoMesesValue = this.normalizeCurrencyValue(value);
		this.calculateMontoCuotaRegular();
	}

	get plazoMeses() {
		return this.plazoMesesValue;
	}

	@api
	set montoAprobado(value) {
		this.montoAprobadoValue = this.normalizeCurrencyValue(value);
		this.calculateMontoCuotaRegular();
	}

	get montoAprobado() {
		return this.montoAprobadoValue;
	}

	@api
	set sucursalUsuario(value) {
		this.sucursalUsuarioValue = this.normalizeStringValue(value);
		this.sucursalUsuarioDisplayValue = this.sucursalUsuarioValue;
		this.updateSucursalUsuarioOmniJson();
		this.resolveSucursalUsuarioLabel();
	}

	get sucursalUsuario() {
		return this.sucursalUsuarioValue;
	}

	connectedCallback() {
		this.hydrateSucursalUsuarioFromOmni();

		if (!this.hasGastosTramitacionApiValue) {
			this.gastosTramitacionValue = this.normalizeCurrencyValue(this.getOmniFieldValue(GASTOS_TRAMITACION_OMNI_FIELD));
		}
		this.updateGastosTramitacionOmniJson();

		if (!this.hasSeguroDeVidaApiValue) {
			this.seguroDeVidaValue = this.normalizeCurrencyValue(this.getOmniFieldValue(SEGURO_DE_VIDA_OMNI_FIELD));
		}
		this.updateSeguroDeVidaOmniJson();
		this.calculateMontoCuotaRegular();
	}

	get normalizedFieldToShow() {
		return (this.fieldToShow || '').trim();
	}

	get showGastosTramitacion() {
		return this.normalizedFieldToShow === GASTOS_TRAMITACION;
	}

	get showSucursalUsuario() {
		return this.normalizedFieldToShow === SUCURSAL_USUARIO;
	}

	get showSeguroDeVida() {
		return this.normalizedFieldToShow === SEGURO_DE_VIDA;
	}

	get showMontoCuotaRegular() {
		return this.normalizedFieldToShow === MONTO_CUOTA_REGULAR;
	}

	get sucursalUsuarioLabel() {
		return this.sucursalUsuarioDisplayValue;
	}

	get montoCuotaRegularFormatted() {
		return this.formatCurrency(this.montoCuotaRegularValue);
	}

	handleGastosTramitacionKeyDown(event) {
		if ((event.ctrlKey || event.metaKey) && ['a', 'c', 'v', 'x'].includes(event.key.toLowerCase())) {
			return;
		}

		const allowedControlKeys = ['Backspace', 'Delete', 'ArrowLeft', 'ArrowRight', 'Home', 'End', 'Tab'];
		if (allowedControlKeys.includes(event.key) || /^[0-9]$/.test(event.key)) {
			return;
		}

		const isDecimalSeparator = event.key === '.' || event.key === ',';
		if (isDecimalSeparator && !/[.,]/.test(String(event.target.value || ''))) {
			return;
		}

		event.preventDefault();
	}

	handleGastosTramitacionBeforeInput(event) {
		if (!event.data || !event.inputType?.startsWith('insert')) {
			return;
		}

		if (!/^[0-9.,]+$/.test(event.data)) {
			event.preventDefault();
		}
	}

	handleGastosTramitacionInput(event) {
		const sanitizedValue = this.sanitizeCurrencyInput(event.target.value);
		if (event.target.value !== sanitizedValue) {
			event.target.value = sanitizedValue;
		}
		this.setGastosTramitacionInputValue(sanitizedValue, event.target);
	}

	handleGastosTramitacionPaste(event) {
		event.preventDefault();
		const sanitizedValue = this.sanitizeCurrencyInput(event.clipboardData?.getData('text'));
		event.target.value = sanitizedValue;
		this.setGastosTramitacionInputValue(sanitizedValue, event.target);
	}

	setGastosTramitacionInputValue(value, sourceInput) {
		this.gastosTramitacionValue = value;
		const input = sourceInput || this.template.querySelector('[data-gastos-tramitacion-input]');
		if (input) {
			input.value = value;
		}
		this.updateGastosTramitacionOmniJson();
	}

	handleGastosTramitacionChange(event) {
		const sanitizedValue = this.sanitizeCurrencyInput(event.detail.value);
		event.target.value = sanitizedValue;
		this.setGastosTramitacionInputValue(sanitizedValue, event.target);
	}

	handleGastosTramitacionBlur() {
		this.gastosTramitacionValue = this.normalizeCurrencyValue(this.gastosTramitacionValue);
		this.updateGastosTramitacionOmniJson();
	}

	handleSeguroDeVidaChange(event) {
		this.seguroDeVidaValue = this.normalizeCurrencyValue(event.detail.value);
		this.updateSeguroDeVidaOmniJson();
	}

	handleSeguroDeVidaBlur() {
		this.seguroDeVidaValue = this.normalizeCurrencyValue(this.seguroDeVidaValue);
		this.updateSeguroDeVidaOmniJson();
	}

	normalizeCurrencyValue(value) {
		if (value === null || value === undefined || value === '') {
			return null;
		}

		const numericValue = Number(String(value).replace(/,/g, ''));
		if (Number.isNaN(numericValue)) {
			return null;
		}

		return Number(numericValue.toFixed(2));
	}

	sanitizeCurrencyInput(value) {
		const numericValue = String(value || '').replace(',', '.').replace(/[^0-9.]/g, '');
		const [integerPart, ...decimalParts] = numericValue.split('.');
		if (decimalParts.length === 0) {
			return integerPart;
		}

		return `${integerPart || '0'}.${decimalParts.join('').slice(0, 2)}`;
	}

	normalizeNumberValue(value) {
		if (value === null || value === undefined || value === '') {
			return null;
		}

		const numericValue = Number(String(value).replace(/,/g, ''));
		return Number.isNaN(numericValue) ? null : numericValue;
	}

	normalizeStringValue(value) {
		if (value === null || value === undefined) {
			return '';
		}

		return String(value).trim();
	}

	calculateMontoCuotaRegular() {
		const montoAprobado = this.montoAprobadoValue;
		const tasaInteres = this.tasaInteresValue;
		const plazoMeses = this.plazoMesesValue;
		const tasaMensual = tasaInteres === null ? null : tasaInteres / 100 / 12;

		let calculatedValue = null;

		if (this.esquemaAmortizacionValue === AMORTIZACION_CUOTAS_IGUALES) {
			calculatedValue = this.calculateCuotaMensualIgual(montoAprobado, tasaMensual, plazoMeses);
		} else if (this.esquemaAmortizacionValue === AMORTIZACION_CAPITAL_VENCIMIENTO) {
			calculatedValue = this.calculateInteresMensual(montoAprobado, tasaMensual);
		}

		this.montoCuotaRegularValue = this.normalizeCurrencyValue(calculatedValue);
		this.updateMontoCuotaRegularOmniJson();
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

	formatCurrency(value) {
		if (value === null || value === undefined || value === '') {
			return '';
		}

		try {
			return new Intl.NumberFormat('es-DO', {
				style: 'currency',
				currency: 'DOP',
				minimumFractionDigits: 2,
				maximumFractionDigits: 2,
			}).format(value);
		} catch (e) {
			return String(value);
		}
	}

	hydrateSucursalUsuarioFromOmni() {
		if (!this.shouldUseOmniSucursalFallback()) {
			return;
		}

		const fallbackValue = this.findSucursalUsuarioInOmniJson();
		if (!fallbackValue) {
			return;
		}

		this.sucursalUsuarioValue = fallbackValue;
		this.sucursalUsuarioDisplayValue = fallbackValue;
		this.updateSucursalUsuarioOmniJson();
		this.resolveSucursalUsuarioLabel();
	}

	shouldUseOmniSucursalFallback() {
		return !this.sucursalUsuarioValue || this.sucursalUsuarioValue === '0';
	}

	findSucursalUsuarioInOmniJson() {
		const omniData = this.omniJsonData || {};
		const userData = omniData.IP_ObtenerDatosUser || {};
		const userArray = Array.isArray(userData.User) ? userData.User : [];

		const valuesToCheck = [
			...userArray.map((user) => user?.[SUCURSAL_USUARIO_OMNI_FIELD]),
			userData['User|1']?.[SUCURSAL_USUARIO_OMNI_FIELD],
			this.getOmniFieldValue(SUCURSAL_USUARIO_OMNI_FIELD),
			omniData[SUCURSAL_USUARIO_OMNI_FIELD],
			omniData.sucursalUsuario,
		];

		const selectedValue = valuesToCheck.find((value) => {
			const normalizedValue = this.normalizeStringValue(value);
			return normalizedValue && normalizedValue !== '0';
		});

		return this.normalizeStringValue(selectedValue);
	}

	resolveSucursalUsuarioLabel() {
		const sucursalValue = this.sucursalUsuarioValue;

		if (!sucursalValue) {
			this.sucursalUsuarioDisplayValue = '';
			return;
		}

		const params = {
			input: this.buildRemoteInput(sucursalValue),
			sClassName: 'FSC_ShowDynamicFieldsOmniController',
			sMethodName: 'getUserSucursalLabel',
			options: '{}',
		};

		this.omniRemoteCall(params, true)
			.then((response) => {
				if (this.sucursalUsuarioValue === sucursalValue) {
					this.sucursalUsuarioDisplayValue = this.extractSucursalLabel(response) || sucursalValue;
				}
			})
			.catch(() => {
				if (this.sucursalUsuarioValue === sucursalValue) {
					this.sucursalUsuarioDisplayValue = sucursalValue;
				}
			});
	}

	buildRemoteInput(sucursalValue) {
		let input = {};

		if (this.omniJsonDataS) {
			try {
				input = JSON.parse(this.omniJsonDataS) || {};
			} catch (e) {
				input = {};
			}
		}

		input.sucursalValue = sucursalValue;
		input.sucursalUsuario = sucursalValue;
		input[SUCURSAL_USUARIO_OMNI_FIELD] = sucursalValue;
		input[PASO_SOLICITUD_NODE] = {
			...(input[PASO_SOLICITUD_NODE] || {}),
			[SUCURSAL_USUARIO_OMNI_FIELD]: sucursalValue,
		};

		return JSON.stringify(input);
	}

	extractSucursalLabel(response) {
		const result = response?.result || response;
		return result?.label;
	}

	updateGastosTramitacionOmniJson() {
		if (typeof this.omniApplyCallResp === 'function') {
			this.omniApplyCallResp(
				this.buildPasoSolicitudPayload(GASTOS_TRAMITACION_OMNI_FIELD, this.normalizeCurrencyValue(this.gastosTramitacionValue))
			);
		}
	}

	updateSucursalUsuarioOmniJson() {
		if (typeof this.omniApplyCallResp === 'function') {
			this.omniApplyCallResp(this.buildPasoSolicitudPayload(SUCURSAL_USUARIO_OMNI_FIELD, this.sucursalUsuarioValue || null));
		}
	}

	updateSeguroDeVidaOmniJson() {
		if (typeof this.omniApplyCallResp === 'function') {
			this.omniApplyCallResp(this.buildPasoSolicitudPayload(SEGURO_DE_VIDA_OMNI_FIELD, this.seguroDeVidaValue));
		}
	}

	updateMontoCuotaRegularOmniJson() {
		if (typeof this.omniApplyCallResp === 'function') {
			this.omniApplyCallResp(this.buildPasoSolicitudPayload(MONTO_CUOTA_REGULAR_OMNI_FIELD, this.montoCuotaRegularValue));
		}
	}

	getOmniFieldValue(fieldName) {
		return this.omniJsonData?.[PASO_SOLICITUD_NODE]?.[fieldName] ?? this.omniJsonData?.[fieldName];
	}

	buildPasoSolicitudPayload(fieldName, value) {
		return {
			[PASO_SOLICITUD_NODE]: {
				[fieldName]: value,
			},
		};
	}
}