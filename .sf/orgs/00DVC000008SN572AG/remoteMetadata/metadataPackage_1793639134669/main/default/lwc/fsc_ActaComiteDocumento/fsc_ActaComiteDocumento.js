import { LightningElement, api, track } from 'lwc';
import getActaDocumentData from '@salesforce/apex/FSC_ActaComitePDFController.getActaDocumentData';
import generateEditedPdf from '@salesforce/apex/FSC_ActaComitePDFController.generateEditedPdf';

const ROW_FIELDS = [
	{ key: 'numero', label: 'No.', inputType: 'number' },
	{ key: 'sucursal', label: 'Sucursal' },
	{ key: 'oficial', label: 'Oficial' },
	{ key: 'nombreCliente', label: 'Nombre del cliente', wide: true },
	{ key: 'tipoFacilidad', label: 'Tipo facilidad', wide: true },
	{ key: 'montoSolicitado', label: 'Monto solicitado' },
	{ key: 'montoAprobado', label: 'Monto aprobado' },
	{ key: 'cuotaSolicitada', label: 'Cuota solicitada' },
	{ key: 'plazoSolicitado', label: 'Plazo solicitado' },
	{ key: 'tasaRefSolicitada', label: 'Tasa de referencia solicitada' },
	{ key: 'cuotaAprobada', label: 'Cuota aprobada' },
	{ key: 'plazoAprobado', label: 'Plazo aprobado' },
	{ key: 'tasaRefAprobada', label: 'Tasa de referencia aprobada' },
	{ key: 'garantiaPrincipal', label: 'Garantía principal' },
	{ key: 'valorGarantiaPrincipal', label: 'Valor garantía principal' },
	{ key: 'descGarantiaPrincipal', label: 'Descripción garantía principal', textarea: true, wide: true },
	{ key: 'garantiaSecundaria', label: 'Garantía secundaria' },
	{ key: 'valorGarantiaSecundaria', label: 'Valor garantía secundaria' },
	{ key: 'descGarantiaSecundaria', label: 'Descripción garantía secundaria', textarea: true, wide: true },
	{ key: 'decisionComite', label: 'Decisión comité' },
	{ key: 'condicion', label: 'Condición', wide: true },
	{ key: 'observaciones', label: 'Observaciones, comentarios y/o acuerdos', textarea: true, wide: true }
];

export default class FscActaComiteDocumento extends LightningElement {
	@api pdfUrl;
	@api actaDate;
	@track showModal = false;
	@track loading = false;
	@track saving = false;
	@track errorMessage = '';
	@track sections = [];
	@track miembros = [];
	actaNumero = '';
	actaFecha = '';
	textoQuorum = '';
	textoObjetivo = '';
	confirmacionRemota = '';
	baseline = new Map();
	editedPdfData;
	editedFileName;

	get disableDownload() {
		return !this.pdfUrl;
	}

	get showSpinner() {
		return this.loading || this.saving;
	}

	get disableActions() {
		return this.showSpinner;
	}

	get disableSave() {
		return this.showSpinner || !this.documentLoaded;
	}

	get documentLoaded() {
		return !this.loading && this.sections.length > 0;
	}

	handleDownload() {
		if (this.editedPdfData) {
			this.downloadBase64Pdf(this.editedPdfData, this.editedFileName);
			return;
		}
		if (this.pdfUrl) {
			window.open(this.pdfUrl, '_blank', 'noopener,noreferrer');
		}
	}

	async handleEdit() {
		this.showModal = true;
		this.loading = true;
		this.errorMessage = '';
		this.sections = [];
		this.baseline = new Map();
		try {
			const data = await getActaDocumentData({ actaDate: this.resolvedActaDate });
			this.actaNumero = data.actaNumero ?? '';
			this.actaFecha = data.actaFecha ?? '';
			this.textoQuorum = data.textoQuorum ?? '';
			this.textoObjetivo = data.textoObjetivo ?? '';
			this.confirmacionRemota = data.confirmacionRemota ?? '';
			this.miembros = (data.miembrosComite ?? []).map((member, index) => ({
				...member,
				id: `member-${index}`,
				presencialId: `presencial-${index}`
			}));
			this.sections = (data.seccionesActa ?? []).map((section, sectionIndex) => ({
				id: `section-${sectionIndex}`,
				title: section.titulo,
				rows: (section.solicitudes ?? []).map((row, rowIndex) => ({
					id: `row-${sectionIndex}-${rowIndex}`,
					numberLabel: row.numero ?? rowIndex + 1,
					fields: ROW_FIELDS.map((config) => ({
						...config,
						id: `${sectionIndex}-${rowIndex}-${config.key}`,
						sectionIndex,
						rowIndex,
						value: row[config.key] === null || row[config.key] === undefined ? '' : String(row[config.key]),
						inputType: config.inputType || 'text',
						fieldClass: config.wide ? 'field field_wide' : 'field'
					}))
				}))
			}));
			this.captureBaseline();
		} catch (error) {
			this.errorMessage = this.getErrorMessage(error, 'No fue posible cargar la información del acta.');
		} finally {
			this.loading = false;
		}
	}

	get resolvedActaDate() {
		if (this.actaDate) {
			return this.actaDate;
		}
		try {
			return new URL(this.pdfUrl, window.location.origin).searchParams.get('actaDate');
		} catch (error) {
			return null;
		}
	}

	captureBaseline() {
		this.baseline.set('actaNumero', this.actaNumero);
		this.baseline.set('confirmacionRemota', this.confirmacionRemota);
		this.sections.forEach((section, sectionIndex) => {
			section.rows.forEach((row, rowIndex) => {
				row.fields.forEach((field) => this.baseline.set(this.rowKey(sectionIndex, rowIndex, field.key), field.value));
			});
		});
	}

	handleHeaderChange(event) {
		this[event.target.dataset.key] = event.detail?.value ?? event.target.value ?? '';
	}

	handleRowChange(event) {
		const sectionIndex = Number(event.target.dataset.sectionIndex);
		const rowIndex = Number(event.target.dataset.rowIndex);
		const key = event.target.dataset.key;
		const value = event.detail?.value ?? event.target.value ?? '';
		this.sections = this.sections.map((section, currentSectionIndex) => ({
			...section,
			rows: section.rows.map((row, currentRowIndex) => ({
				...row,
				fields: row.fields.map((field) =>
					currentSectionIndex === sectionIndex && currentRowIndex === rowIndex && field.key === key
						? { ...field, value }
						: field
				)
			}))
		}));
	}

	handleCancel() {
		if (!this.saving) {
			this.showModal = false;
			this.errorMessage = '';
		}
	}

	async handleSaveAndDownload() {
		const inputs = [...this.template.querySelectorAll('lightning-input, lightning-textarea')];
		if (!inputs.reduce((valid, input) => input.reportValidity() && valid, true)) {
			return;
		}

		this.saving = true;
		this.errorMessage = '';
		try {
			const result = await generateEditedPdf({
				actaDate: this.resolvedActaDate,
				changesJson: JSON.stringify(this.buildChanges())
			});
			this.editedPdfData = result.base64Data;
			this.editedFileName = result.fileName;
			this.downloadBase64Pdf(result.base64Data, result.fileName);
			this.showModal = false;
		} catch (error) {
			this.errorMessage = this.getErrorMessage(error, 'No fue posible guardar y descargar el documento.');
		} finally {
			this.saving = false;
		}
	}

	buildChanges() {
		const changes = { rows: [] };
		if (this.actaNumero !== this.baseline.get('actaNumero')) {
			changes.actaNumero = this.actaNumero;
		}
		if (this.confirmacionRemota !== this.baseline.get('confirmacionRemota')) {
			changes.confirmacionRemota = this.confirmacionRemota;
		}
		this.sections.forEach((section, sectionIndex) => {
			section.rows.forEach((row, rowIndex) => {
				const values = {};
				row.fields.forEach((field) => {
					if (field.value !== this.baseline.get(this.rowKey(sectionIndex, rowIndex, field.key))) {
						values[field.key] = field.value;
					}
				});
				if (Object.keys(values).length) {
					changes.rows.push({ sectionIndex, rowIndex, values });
				}
			});
		});
		return changes;
	}

	rowKey(sectionIndex, rowIndex, fieldName) {
		return `${sectionIndex}.${rowIndex}.${fieldName}`;
	}

	downloadBase64Pdf(base64Data, fileName) {
		const binary = window.atob(base64Data);
		const bytes = new Uint8Array(binary.length);
		for (let index = 0; index < binary.length; index += 1) {
			bytes[index] = binary.charCodeAt(index);
		}
		const objectUrl = URL.createObjectURL(new Blob([bytes], { type: 'application/pdf' }));
		const link = document.createElement('a');
		link.href = objectUrl;
		link.download = fileName || 'Acta_Comite_Credito_Editada.pdf';
		link.click();
		window.setTimeout(() => URL.revokeObjectURL(objectUrl), 1000);
	}

	getErrorMessage(error, fallback) {
		return error?.body?.message || error?.message || fallback;
	}
}