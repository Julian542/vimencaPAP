import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';

import RLA_OBJECT from '@salesforce/schema/ResidentialLoanApplication';
import SUBSTATUS_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_Subestado__c';
import RECORDTYPEID_FIELD from '@salesforce/schema/ResidentialLoanApplication.RecordTypeId';
import STATUS_FIELD from '@salesforce/schema/ResidentialLoanApplication.Status';

export default class fsc_PathResidentialLoanApplication extends LightningElement {
	@api recordId;

	// Record actual
	recordTypeId;
	currentSubStatus;
	currentStatus; // controlling field (Status)
	pendingSubStatus = null;

	// Picklist filtrado (FULL)
	subStatusValues = [];

	// Picklist metadata cache
	picklistMeta;
	picklistsLoaded = false;

	// UI
	uiMessage = null;

	// Debug en pantalla
	dbg_controllerIndex = null;
	dbg_totalValues = 0;
	dbg_filteredValues = 0;
	dbg_controllerKeysPreview = null;
	dbg_matchedControllerKey = null;
	dbg_validForType = null;
	dbg_validForSample = null;
	dbg_validForHit = null;

	/* =======================
     PAGINACIÓN
     ======================= */
	pageSize = 6;
	pageIndex = 0;

	/* =======================
     RECORD RLA
     ======================= */
	@wire(getRecord, {
		recordId: '$recordId',
		fields: [RECORDTYPEID_FIELD, SUBSTATUS_FIELD, STATUS_FIELD],
	})
	wiredRecord({ data, error }) {
		if (error) {
			this.uiMessage = this.extractError(error) || 'No se pudo cargar el registro.';
			return;
		}
		if (!data) return;

		this.recordTypeId = getFieldValue(data, RECORDTYPEID_FIELD);
		this.currentSubStatus = getFieldValue(data, SUBSTATUS_FIELD);
		this.currentStatus = getFieldValue(data, STATUS_FIELD);

		this.recomputeDependentValues();
	}

	/* =======================
     PICKLIST DEPENDIENTE
     ======================= */
	@wire(getPicklistValuesByRecordType, {
		objectApiName: RLA_OBJECT,
		recordTypeId: '$recordTypeId',
	})
	wiredPicklists({ data, error }) {
		if (error) {
			this.picklistsLoaded = true;
			this.picklistMeta = null;
			this.subStatusValues = [];
			this.uiMessage = this.extractError(error) || 'No se pudieron cargar los valores de picklist.';
			return;
		}
		if (!data) return;

		const pick = data.picklistFieldValues?.[SUBSTATUS_FIELD.fieldApiName];
		this.picklistMeta = pick || null;
		this.picklistsLoaded = true;

		this.recomputeDependentValues();
	}

	recomputeDependentValues() {
		// reset debug
		this.dbg_controllerIndex = null;
		this.dbg_totalValues = 0;
		this.dbg_filteredValues = 0;
		this.dbg_controllerKeysPreview = null;
		this.dbg_matchedControllerKey = null;
		this.dbg_validForType = null;
		this.dbg_validForSample = null;
		this.dbg_validForHit = null;

		if (!this.picklistsLoaded || !this.picklistMeta || !this.currentStatus) return;

		const pick = this.picklistMeta;
		const controllerValues = pick.controllerValues || {};
		const controllerKeys = Object.keys(controllerValues);
		this.dbg_controllerKeysPreview = controllerKeys.slice(0, 30).join(' | ');

		const { index, matchedKey } = this.getControllerIndex(controllerValues, this.currentStatus);
		this.dbg_controllerIndex = index;
		this.dbg_matchedControllerKey = matchedKey;

		if (index === undefined || index === null) {
			this.subStatusValues = [];
			this.uiMessage = `No pude matchear el Status actual "${this.currentStatus}" contra controllerValues del picklist dependiente.`;
			this.pendingSubStatus = null;
			return;
		}

		const values = pick.values || [];
		this.dbg_totalValues = values.length;

		if (values.length > 0) {
			const sample = values[0]?.validFor;
			this.dbg_validForType = Array.isArray(sample) ? 'array' : typeof sample;
			this.dbg_validForSample = this.stringifySample(sample);
		}

		const filtered = values
			.filter((v) => {
				const ok = this.isValidForController(v.validFor, index);
				if (v.value === this.currentSubStatus && this.dbg_validForHit === null) {
					this.dbg_validForHit = ok ? 'true' : 'false';
				}
				return ok;
			})
			.map((v) => ({ label: v.label, value: v.value }));

		this.subStatusValues = filtered;
		this.dbg_filteredValues = filtered.length;

		if (filtered.length === 0) {
			this.uiMessage = `No hay valores de FSC_Subestado__c configurados para Status "${this.currentStatus}".`;
		} else {
			this.uiMessage = null;
		}

		// Si pendingSubStatus ya no existe, reset
		if (this.pendingSubStatus && !this.subStatusValues.some((v) => v.value === this.pendingSubStatus)) {
			this.pendingSubStatus = null;
		}

		// Paginación: ubicar la página del subestado actual/seleccionado
		this.snapPageToSelected();
	}

	snapPageToSelected() {
		const selected = this.pendingSubStatus ?? this.currentSubStatus;
		const idx = this.subStatusValues.findIndex((v) => v.value === selected);

		if (idx < 0) {
			this.pageIndex = 0;
			return;
		}

		const page = Math.floor(idx / this.pageSize);
		const max = this.maxPageIndex;
		this.pageIndex = Math.min(Math.max(page, 0), max);
	}

	stringifySample(sample) {
		if (sample === null || sample === undefined) return String(sample);
		if (Array.isArray(sample)) return JSON.stringify(sample);
		if (typeof sample === 'string') return sample.length > 80 ? sample.substring(0, 80) + '…' : sample;
		try {
			return JSON.stringify(sample);
		} catch {
			return String(sample);
		}
	}

	getControllerIndex(controllerValues, currentStatusValue) {
		if (!controllerValues || !currentStatusValue) return { index: undefined, matchedKey: null };

		// 1) exact match
		if (controllerValues[currentStatusValue] !== undefined) {
			return { index: Number(controllerValues[currentStatusValue]), matchedKey: currentStatusValue };
		}

		// 2) normalize match
		const target = this.normalize(currentStatusValue);
		const keys = Object.keys(controllerValues);
		const matchKey = keys.find((k) => this.normalize(k) === target);

		if (matchKey) return { index: Number(controllerValues[matchKey]), matchedKey: matchKey };

		return { index: undefined, matchedKey: null };
	}

	isValidForController(validFor, controllerIndexRaw) {
		const controllerIndex = Number(controllerIndexRaw);
		if (validFor === null || validFor === undefined) return false;

		if (Array.isArray(validFor)) {
			return validFor.map(Number).includes(controllerIndex);
		}

		if (typeof validFor !== 'string' || validFor.trim() === '') return false;

		const b64 = this.normalizeBase64(validFor);

		let bytes;
		try {
			bytes = atob(b64);
		} catch {
			return false;
		}

		const byteIndex = Math.floor(controllerIndex / 8);
		const bitIndex = controllerIndex % 8;

		if (byteIndex >= bytes.length) return false;

		const byte = bytes.charCodeAt(byteIndex);
		const maskLSB = 1 << bitIndex;
		const maskMSB = 1 << (7 - bitIndex);

		return (byte & maskLSB) !== 0 || (byte & maskMSB) !== 0;
	}

	normalizeBase64(s) {
		let out = (s || '').toString().trim();
		out = out.replace(/-/g, '+').replace(/_/g, '/');
		const pad = out.length % 4;
		if (pad === 2) out += '==';
		else if (pad === 3) out += '=';
		else if (pad === 1) out += '===';
		return out;
	}

	normalize(s) {
		return (s || '')
			.toString()
			.replace(/\u00A0/g, ' ')
			.replace(/\s+/g, ' ')
			.trim()
			.toLowerCase()
			.normalize('NFD')
			.replace(/[\u0300-\u036f]/g, '');
	}

	extractError(error) {
		return error?.body?.message || error?.message || (Array.isArray(error?.body) ? error.body.map((e) => e.message).join(' | ') : null);
	}

	/* =======================
     UI HELPERS
     ======================= */
	get ready() {
		return !!(this.recordTypeId && this.currentStatus && this.picklistsLoaded);
	}

	get hasSteps() {
		return this.subStatusValues.length > 0;
	}

	get maxPageIndex() {
		const total = this.subStatusValues.length;
		if (!total) return 0;
		return Math.max(Math.ceil(total / this.pageSize) - 1, 0);
	}

	get canPrev() {
		return this.pageIndex > 0;
	}

	get canNext() {
		return this.pageIndex < this.maxPageIndex;
	}

	get disablePrev() {
		return !this.canPrev;
	}

	get disableNext() {
		return !this.canNext;
	}

	handlePrev() {
		if (!this.canPrev) return;
		this.pageIndex = this.pageIndex - 1;
	}

	handleNext() {
		if (!this.canNext) return;
		this.pageIndex = this.pageIndex + 1;
	}

	get stepsVisible() {
		const start = this.pageIndex * this.pageSize;
		const end = start + this.pageSize;

		const slice = this.subStatusValues.slice(start, end);

		const currentIndex = this.subStatusValues.findIndex((v) => v.value === this.currentSubStatus);
		const selected = this.pendingSubStatus ?? this.currentSubStatus;

		return slice.map((v, localIdx) => {
			const globalIdx = start + localIdx;

			const isCurrent = v.value === selected;
			const isCompleted = currentIndex >= 0 ? globalIdx < currentIndex : false;

			let className = 'slds-path__item';
			if (isCompleted) className += ' slds-is-complete';
			if (isCurrent) className += ' slds-is-current slds-is-active';

			return { ...v, isCurrent, className };
		});
	}

	get pageLabel() {
		const totalPages = this.maxPageIndex + 1;
		return `${this.pageIndex + 1} / ${totalPages}`;
	}

	handleStepClick(event) {
		this.pendingSubStatus = event.currentTarget.dataset.value;
		// Si click cae en otra página (no debería, porque es visible), igual mantenemos snap por si cambia data
		this.snapPageToSelected();
	}
}