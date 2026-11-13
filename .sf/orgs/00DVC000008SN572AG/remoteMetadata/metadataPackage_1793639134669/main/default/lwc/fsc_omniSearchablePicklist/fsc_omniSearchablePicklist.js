import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';
import getReferidorOptions from '@salesforce/apex/FSC_OmniSearchablePicklistController.getReferidorOptions';

export default class FscOmniSearchablePicklist extends OmniscriptBaseMixin(LightningElement) {
	@api label = 'Referidor';
	@api placeholder = 'Seleccione una opcion';
	@api outputFieldName = 'FSC_Referidor__c';
	@api outputParentNodeName = 'DatosGeneralesSolicitud';
	@api optionsNodeName = 'FSC_NombreReferidor__c';
	@api optionLabelField = 'FSC_NombreReferidor__c';
	@api optionValueField = 'FSC_NombreReferidor__c';
	@api emptyMessage = 'No hay opciones disponibles.';

	_optionsConfig;
	_required = true;
	_useReferidorMetadataOptions = true;
	_value = '';
	apexOptions = [];
	isLoadingOptions = false;
	hasLoadedApexOptions = false;
	searchTerm = '';
	showDropdown = false;
	isPointerDownInDropdown = false;
	isEditingSearch = false;
	validationMessage = '';
	initializedFromOmni = false;
	hasUserInteracted = false;
	hasValidationAttempted = false;

	@api
	set required(value) {
		this._required = value === true || value === 'true' || value === '';
	}

	get required() {
		return this._required;
	}

	@api
	set useReferidorMetadataOptions(value) {
		this._useReferidorMetadataOptions = value === true || value === 'true' || value === '';
		this.loadReferidorOptionsIfNeeded();
	}

	get useReferidorMetadataOptions() {
		return this._useReferidorMetadataOptions;
	}

	@api
	set value(value) {
		const nextValue = value || '';
		if (this.isEditingSearch) {
			if (!nextValue) {
				this._value = '';
			}
			return;
		}

		this._value = nextValue;
		this.syncSearchTerm();
	}

	get value() {
		return this._value;
	}

	@api
	set options(value) {
		this._optionsConfig = value;
		if (!this.isEditingSearch) {
			this.syncSearchTerm();
		}
	}

	get options() {
		return this._optionsConfig;
	}

	connectedCallback() {
		this.initializeFromOmni();
		this.loadReferidorOptionsIfNeeded();
		this.syncSearchTerm();
	}

	renderedCallback() {
		this.initializeFromOmni();
		if (this.hasUserInteracted || this.hasValidationAttempted) {
			this.updateInputValidity();
		}
	}

	disconnectedCallback() {
		this.clearDropdownPointerListeners();
	}

	get isRequired() {
		return this.required;
	}

	get formElementClass() {
		return this.validationMessage ? 'slds-form-element slds-has-error' : 'slds-form-element';
	}

	get hasValidationError() {
		return !!this.validationMessage;
	}

	get inputDescribedBy() {
		return this.hasValidationError ? 'search-input-error' : undefined;
	}

	get comboboxClass() {
		const baseClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
		return this.showDropdown ? `${baseClass} slds-is-open` : baseClass;
	}

	get normalizedOptions() {
		return this.normalizeOptions(this.getRawOptions());
	}

	get filteredOptions() {
		const searchKey = this.normalizeSearchValue(this.searchTerm);
		if (!searchKey) {
			return this.normalizedOptions;
		}

		return this.normalizedOptions.filter((option) => {
			const label = this.normalizeSearchValue(option.label);
			const value = this.normalizeSearchValue(option.value);
			return label.includes(searchKey) || value.includes(searchKey);
		});
	}

	get renderedOptions() {
		return this.filteredOptions.map((option) => ({
			...option,
			className: 'slds-listbox__item',
			ariaSelected: option.value === this.value ? 'true' : 'false',
		}));
	}

	get hasFilteredOptions() {
		return this.filteredOptions.length > 0;
	}

	get emptyOptionClass() {
		return this.hasFilteredOptions ? 'slds-listbox__item slds-hide' : 'slds-listbox__item';
	}

	get currentEmptyMessage() {
		return this.isLoadingOptions ? 'Cargando opciones...' : this.emptyMessage;
	}

	get shouldUseReferidorMetadataOptions() {
		return this.useReferidorMetadataOptions && this.optionsNodeName === 'FSC_NombreReferidor__c';
	}

	initializeFromOmni() {
		if (this.initializedFromOmni || this.value) {
			return;
		}

		const omniValue = this.findFirstValueByKey(this.omniJsonData, this.outputFieldName);
		if (omniValue) {
			this._value = omniValue;
			this.syncSearchTerm();
		}

		this.initializedFromOmni = true;
	}

	getRawOptions() {
		if (this.shouldUseReferidorMetadataOptions) {
			return this.apexOptions;
		}

		const configuredOptions = this.parseOptions(this.options);
		if (configuredOptions.length > 0) {
			return configuredOptions;
		}

		const omniOptions = this.findFirstValueByKey(this.omniJsonData, this.optionsNodeName);
		const parsedOmniOptions = this.parseOptions(omniOptions);
		if (parsedOmniOptions.length > 0) {
			return parsedOmniOptions;
		}

		return this.apexOptions;
	}

	async loadReferidorOptionsIfNeeded() {
		if (!this.shouldUseReferidorMetadataOptions || this.hasLoadedApexOptions || this.isLoadingOptions) {
			return;
		}

		this.isLoadingOptions = true;
		try {
			const result = await getReferidorOptions();
			this.apexOptions = Array.isArray(result) ? result : [];
			this.hasLoadedApexOptions = true;
			if (this.value) {
				this.syncSearchTerm();
			}
		} catch (error) {
			this.apexOptions = [];
			this.hasLoadedApexOptions = true;
			console.error('Error loading referidor options', error);
		} finally {
			this.isLoadingOptions = false;
		}
	}

	parseOptions(value) {
		if (!value) {
			return [];
		}

		if (Array.isArray(value)) {
			return value;
		}

		if (Array.isArray(value.records)) {
			return value.records;
		}

		if (typeof value === 'string') {
			try {
				const parsedValue = JSON.parse(value);
				return this.parseOptions(parsedValue);
			} catch (error) {
				return value
					.split(';')
					.map((item) => item.trim())
					.filter((item) => !!item);
			}
		}

		return [];
	}

	normalizeOptions(rows) {
		const normalizedOptions = rows
			.map((row) => {
				if (typeof row === 'string') {
					return { label: row, value: row };
				}

				const label = row?.[this.optionLabelField] || row?.label || row?.Name || row?.name || row?.FSC_NombreReferidor__c || row?.value || '';
				const value = row?.[this.optionValueField] || row?.value || row?.FSC_NombreReferidor__c || row?.Name || row?.name || label;

				return {
					label: String(label || ''),
					value: String(value || ''),
				};
			})
			.filter((option) => option.label && option.value);

		// Evita claves repetidas en el listado.
		return [...new Map(normalizedOptions.map((option) => [option.value, option])).values()];
	}

	findFirstValueByKey(value, key, visited = new WeakSet()) {
		if (!value || !key || typeof value !== 'object') {
			return null;
		}

		if (visited.has(value)) {
			return null;
		}
		visited.add(value);

		if (Object.prototype.hasOwnProperty.call(value, key)) {
			return value[key];
		}

		for (const childValue of Object.values(value)) {
			const result = this.findFirstValueByKey(childValue, key, visited);
			if (result !== null && result !== undefined) {
				return result;
			}
		}

		return null;
	}

	normalizeSearchValue(value) {
		return String(value || '')
			.normalize('NFD')
			.replace(/[\u0300-\u036f]/g, '')
			.trim()
			.toLowerCase();
	}

	handleFocus() {
		this.showDropdown = true;
	}

	handleSearchInput(event) {
		const value = event.currentTarget.value ?? '';
		this.updateSearch(value);
	}

	updateSearch(value) {
		const hadSelectedValue = !!this._value;
		this.isEditingSearch = true;
		this.hasUserInteracted = true;
		this.searchTerm = value;
		this._value = '';
		this.showDropdown = true;

		if (hadSelectedValue) {
			this.updateOmniValue();
		}

		this.updateInputValidity();
	}

	handleBlur(event) {
		const nextFocusedElement = event.relatedTarget;
		if (this.isPointerDownInDropdown || (nextFocusedElement && this.template.contains(nextFocusedElement))) {
			return;
		}

		this.hasUserInteracted = true;
		this.showDropdown = false;
		if (this.value) {
			this.syncSearchTerm();
		}
		this.updateInputValidity();
	}

	handleDropdownPointerDown() {
		this.isPointerDownInDropdown = true;
		this.clearDropdownPointerListeners();
		window.addEventListener('pointerup', this.handleDropdownPointerEnd, { once: true });
		window.addEventListener('pointercancel', this.handleDropdownPointerEnd, { once: true });
	}

	handleDropdownPointerEnd = () => {
		const shouldRestoreInputFocus = this.isPointerDownInDropdown && this.showDropdown;
		this.isPointerDownInDropdown = false;
		this.clearDropdownPointerListeners();

		if (shouldRestoreInputFocus) {
			this.template.querySelector('.c-searchable-picklist__input')?.focus();
		}
	};

	clearDropdownPointerListeners() {
		window.removeEventListener('pointerup', this.handleDropdownPointerEnd);
		window.removeEventListener('pointercancel', this.handleDropdownPointerEnd);
	}

	handleSelect(event) {
		const selectedValue = event.currentTarget.dataset.value || '';
		this.isEditingSearch = false;
		this.hasUserInteracted = true;
		this._value = selectedValue;
		this.syncSearchTerm();
		this.showDropdown = false;
		this.updateOmniValue();
		this.updateInputValidity();
	}

	syncSearchTerm() {
		this.searchTerm = this.getOptionLabel(this.value);
		this.updateInputValidity();
	}

	getOptionLabel(value) {
		if (!value) {
			return '';
		}

		const option = this.normalizedOptions.find((item) => item.value === value);
		return option?.label || value;
	}

	updateOmniValue() {
		// Actualiza solo el nodo de este componente.
		if (typeof this.omniUpdateDataJson === 'function') {
			this.omniUpdateDataJson(this.value);
		}

		this.dispatchEvent(
			new CustomEvent('change', {
				detail: {
					value: this.value,
					fieldName: this.outputFieldName,
				},
			})
		);
	}

	updateInputValidity() {
		const input = this.template.querySelector('.c-searchable-picklist__input');
		if (!input) {
			return;
		}

		let message = '';
		if (!this.hasUserInteracted && !this.hasValidationAttempted) {
			input.setCustomValidity(message);
		} else {
			const hasTypedValue = !!this.searchTerm?.trim();
			const isInvalidSelection = hasTypedValue && !this.value;
			message = this.required && !this.value ? 'Seleccione una opción.' : isInvalidSelection ? 'Seleccione una opción válida de la lista.' : '';
			input.setCustomValidity(message);
		}

		if (this.validationMessage !== message) {
			this.validationMessage = message;
		}
	}

	@api
	checkValidity() {
		return !this.required || !!this.value;
	}

	@api
	reportValidity() {
		this.hasValidationAttempted = true;
		this.updateInputValidity();
		const input = this.template.querySelector('.c-searchable-picklist__input');
		input?.reportValidity();
		return this.checkValidity();
	}

	@api
	isValid() {
		return this.checkValidity();
	}
}