import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';

const DEFAULT_OUTPUT_PARENT_NODE = 'PasoSolicitud';

export default class FscOmniDateWithMinDate extends OmniscriptBaseMixin(LightningElement) {
	_fieldApiName = '';
	_defaultValue = '';
	_createdDate = '';

	@api label = '';
	@api outputParentNode = DEFAULT_OUTPUT_PARENT_NODE;
	@api required = 'false';

	value = '';
	minimumDate = '';

	@api
	get fieldApiName() {
		return this._fieldApiName;
	}

	set fieldApiName(value) {
		this._fieldApiName = value || '';
		this.initializeValue();
	}

	@api
	get defaultValue() {
		return this._defaultValue;
	}

	set defaultValue(value) {
		this._defaultValue = value || '';
		this.initializeValue();
	}

	@api
	get createdDate() {
		return this._createdDate;
	}

	set createdDate(value) {
		this._createdDate = value || '';
		this.minimumDate = this.resolveMinimumDate();
		this.validateInput();
	}

	connectedCallback() {
		this.minimumDate = this.resolveMinimumDate();
		this.initializeValue();
	}

	renderedCallback() {
		const minimumDate = this.resolveMinimumDate();
		if (minimumDate !== this.minimumDate) {
			this.minimumDate = minimumDate;
		}
		this.validateInput();
	}

	get isRequired() {
		return this.required === true || this.required === 'true';
	}

	get minimumDateErrorMessage() {
		return this.minimumDate ? `La fecha no puede ser anterior a ${this.formatDate(this.minimumDate)}.` : '';
	}

	handleChange(event) {
		this.value = event.target.value || '';
		const isValid = this.validateInput(event.target);
		if (!isValid) {
			event.target.reportValidity();
			return;
		}

		this.writeValueToOmniJson();
	}

	@api
	checkValidity() {
		const input = this.template.querySelector('lightning-input');
		this.validateInput(input);
		return input ? input.checkValidity() : true;
	}

	@api
	reportValidity() {
		const input = this.template.querySelector('lightning-input');
		this.validateInput(input);
		return input ? input.reportValidity() : true;
	}

	initializeValue() {
		if (!this._fieldApiName || this.value) {
			return;
		}

		const currentValue = this.omniJsonData?.[this.outputParentNode || DEFAULT_OUTPUT_PARENT_NODE]?.[this._fieldApiName];
		const initialValue = this.toIsoDate(currentValue || this._defaultValue);
		if (!initialValue) {
			return;
		}

		this.value = initialValue;
		this.writeValueToOmniJson();
	}

	validateInput(input = this.template.querySelector('lightning-input')) {
		if (!input) {
			return true;
		}

		const inputValue = input.value || this.value;
		const isEarlierThanMinimum = inputValue && this.minimumDate && inputValue < this.minimumDate;
		input.setCustomValidity(isEarlierThanMinimum ? this.minimumDateErrorMessage : '');
		return !isEarlierThanMinimum;
	}

	writeValueToOmniJson() {
		if (!this._fieldApiName || typeof this.omniApplyCallResp !== 'function') {
			return;
		}

		this.omniApplyCallResp({
			[this.outputParentNode || DEFAULT_OUTPUT_PARENT_NODE]: {
				[this._fieldApiName]: this.value || null,
			},
		});
	}

	toIsoDate(value) {
		const rawValue = String(value || '').trim();
		const isoMatch = rawValue.match(/^(\d{4}-\d{2}-\d{2})/);
		if (isoMatch) {
			return isoMatch[1];
		}

		const displayMatch = rawValue.match(/^(\d{2})-(\d{2})-(\d{4})$/);
		return displayMatch ? `${displayMatch[3]}-${displayMatch[2]}-${displayMatch[1]}` : '';
	}

	resolveMinimumDate() {
		const createdDateFromOmni = this.omniJsonData?.IP_ObtenerDatosRLA?.RLA?.[0]?.CreatedDate;
		return this.toIsoDate(this._createdDate || createdDateFromOmni);
	}

	formatDate(value) {
		const [year, month, day] = String(value || '').split('-');
		return year && month && day ? `${day}-${month}-${year}` : value;
	}
}