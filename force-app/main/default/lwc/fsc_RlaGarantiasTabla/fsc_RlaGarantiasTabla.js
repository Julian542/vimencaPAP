import { LightningElement, api, wire } from 'lwc';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';
import getGarantias from '@salesforce/apex/FSC_RlaGarantiasTablaController.getGarantias';

export default class Fsc_RlaGarantiasTabla extends OmniscriptBaseMixin(LightningElement) {
	@api title = 'Garantías relacionadas';
	@api emptyMessage = 'No se encontraron garantías relacionadas.';
	@api residentialLoanApplicationId;
	@api recordId;
	@api contextId;

	rows = [];
	errorMessage = '';
	isLoaded = false;
	_hasReportedValidity = false;

	renderedCallback() {
		if (typeof super.renderedCallback === 'function') {
			super.renderedCallback();
		}
		if (!this._hasReportedValidity && typeof this.omniValidate === 'function') {
			this._hasReportedValidity = true;
			this.omniValidate(false);
		}
	}

	@api
	checkValidity() {
		// La tabla es informativa; no exige garantías para avanzar.
		return true;
	}

	@api
	reportValidity() {
		return this.checkValidity();
	}

	@wire(getGarantias, { residentialLoanApplicationId: '$effectiveResidentialLoanApplicationId' })
	wiredGarantias({ data, error }) {
		if (data === undefined && error === undefined) {
			return;
		}

		this.isLoaded = true;

		if (data) {
			this.rows = (data || []).map((item) => ({
				id: item.id,
				titulo: item.descripcionGarantia || item.nombre || 'Garantía',
				subtitulo: this.getSubtitle(item),
				esPyme: item.esPyme,
				numeroFacilidad: item.numeroFacilidad || '',
				detalles: (item.detalles || []).map((detalle, index) => this.getDetail(detalle, index)),
				hasDetalles: (item.detalles || []).length > 0,
				hasImportes: (item.importes || []).length > 0,
				hasMonedaPendiente: (item.importes || []).some((importe) => !importe.moneda),
				importes: (item.importes || []).map((importe) => ({
					...importe,
					valorFormatted: this.formatCurrency(importe.valor, importe.moneda),
				})),
				porcentajeAdmisibilidadFormatted: this.formatPercent(item.porcentajeAdmisibilidad),
			}));
			this.errorMessage = '';
			return;
		}

		this.rows = [];
		this.errorMessage = this.normalizeError(error);
	}

	get effectiveResidentialLoanApplicationId() {
		const omniData = this.omniJsonData || {};
		const omniResidentialLoanApplication = omniData.ResidentialLoanApplication || {};

		return this.firstNonEmptyValue([
			this.residentialLoanApplicationId,
			this.recordId,
			this.contextId,
			omniData.ContextId,
			omniData.recordId,
			omniData.residentialLoanApplicationId,
			omniData.ResidentialLoanApplicationId,
			omniResidentialLoanApplication.Id,
		]);
	}

	get hasRows() {
		return this.rows.length > 0;
	}

	get hasEffectiveResidentialLoanApplicationId() {
		return !!this.effectiveResidentialLoanApplicationId;
	}

	get hasError() {
		return !!this.errorMessage;
	}

	get showLoading() {
		return this.hasEffectiveResidentialLoanApplicationId && !this.isLoaded;
	}

	get showEmpty() {
		return this.hasEffectiveResidentialLoanApplicationId && this.isLoaded && !this.hasRows && !this.hasError;
	}

	get showTable() {
		return this.hasRows;
	}

	get showPymeColumns() {
		return this.rows.some((row) => row.esPyme);
	}

	get countLabel() {
		return `${this.rows.length} ${this.rows.length === 1 ? 'garantía' : 'garantías'}`;
	}

	getSubtitle(item) {
		const nombre = (item.nombre || '').trim();
		const descripcion = (item.descripcionGarantia || '').trim();
		return descripcion && nombre.toLocaleLowerCase() !== descripcion.toLocaleLowerCase() ? nombre : '';
	}

	getDetail(value, index) {
		const separator = value.indexOf(':');
		return {
			id: String(index),
			etiqueta: separator >= 0 ? value.slice(0, separator) : 'Descripción',
			valor: separator >= 0 ? value.slice(separator + 1).trim() : value,
		};
	}

	firstNonEmptyValue(values) {
		for (const value of values) {
			if (value !== null && value !== undefined && String(value).trim()) {
				return String(value).trim();
			}
		}

		return null;
	}

	formatCurrency(value, currency) {
		if (value === null || value === undefined || value === '') {
			return '';
		}

		// Conserva la moneda de cada importe, sin convertir su valor.
		const number = new Intl.NumberFormat('es-DO', {
			minimumFractionDigits: 2,
			maximumFractionDigits: 2,
		}).format(value);
		if (!currency) {
			return number;
		}
		try {
			return new Intl.NumberFormat('es-DO', {
				style: 'currency',
				currency,
				currencyDisplay: 'code',
				minimumFractionDigits: 2,
				maximumFractionDigits: 2,
			}).format(value);
		} catch (e) {
			return `${currency} ${number}`;
		}
	}

	formatPercent(value) {
		if (value === null || value === undefined || value === '') {
			return '';
		}

		try {
			return `${new Intl.NumberFormat('es-DO', {
				minimumFractionDigits: 0,
				maximumFractionDigits: 2,
			}).format(value)}%`;
		} catch (e) {
			return `${value}%`;
		}
	}

	normalizeError(error) {
		if (Array.isArray(error?.body)) {
			return error.body.map((item) => item.message).join(' | ');
		}

		if (typeof error?.body?.message === 'string') {
			return error.body.message;
		}

		if (typeof error?.message === 'string') {
			return error.message;
		}

		return 'Ocurrió un error al cargar las garantías.';
	}
}