import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { RefreshEvent, registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';
import getDocumentacionContratosContext from '@salesforce/apex/FSC_RlaAccionesController.getDocumentacionContratosContext';

import TIENE_PERMISO_ADMINISTRADOR from '@salesforce/customPermission/FSC_CP_Administrador';
import TIENE_PERMISO_ANALISTA_CREDITO from '@salesforce/customPermission/FSC_CP_Analista_Credito';
import TIENE_PERMISO_OFICIAL_NEGOCIO from '@salesforce/customPermission/FSC_CP_Oficial_Negocio';
import TIENE_PERMISO_CONTROL_DOCUMENTOS from '@salesforce/customPermission/FSC_CP_Recepcion_Control_Documentos';

import initAndGetRows from '@salesforce/apex/FSC_ChecklistDocsController.initAndGetRows';
import saveRows from '@salesforce/apex/FSC_ChecklistDocsController.saveRows';
import processUploadedFiles from '@salesforce/apex/FSC_ChecklistDocsController.processUploadedFiles';

import SUBESTADO_FIELD from '@salesforce/schema/ResidentialLoanApplication.FSC_Subestado__c';

const SUBESTADO_ANALISIS = 'Recepción de documentos – Análisis';
const SUBESTADO_CREDITO = 'Análisis de crédito';
const SUBESTADO_DESEMBOLSO = 'Documentación para desembolso y firmas';
const SUBESTADO_CONTRATOS = 'Documentación para contratos';
const SUBESTADO_PAGARES = 'Generación de pagarés y plantillas';

const CAT_ANALISIS = 'Documentos para análisis';
const CAT_CONTRATO = 'Documentos para confección de contrato';
const CAT_DESEMBOLSO = 'Documentos para desembolso';

const ESTADO_PENDIENTE = 'Pendiente';
const ESTADO_APROBADO = 'Aprobado';
const ESTADO_OBSERVADO = 'Observado';

const ACCEPTED_FILE_FORMATS = ['.pdf', '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tif', '.tiff', '.webp', '.heic', '.doc', '.docx'];

export default class Fsc_ChecklistDocs extends LightningElement {
	@api recordId;

	@track rows = [];
	loading = false;
	errorMessage = null;
	isMultiple = true;
	activeSectionName = '';

	// joinId -> { joinId, noAplica?, comentario?, comentarioOficial?, estadoRevision? }
	pending = new Map();

	subestado;
	wiredContratosResult;
	refreshHandlerId;

	@wire(getDocumentacionContratosContext, { residentialLoanApplicationId: '$recordId' })
	wiredContratos(result) {
		this.wiredContratosResult = result;
		this.rows = this.decorateRows(this.rows);
	}

	get esEtapaContratos() {
		return this.subestado === SUBESTADO_CONTRATOS || this.subestado === SUBESTADO_PAGARES;
	}

	get puedeCargarContratos() {
		return this.wiredContratosResult?.data?.puedeCargar === true;
	}

	get puedeRevisarContratos() {
		return this.wiredContratosResult?.data?.puedeRevisar === true;
	}

	estadoRevisionOptions = [
		{ label: 'Pendiente', value: ESTADO_PENDIENTE },
		{ label: 'Aprobado', value: ESTADO_APROBADO },
		{ label: 'Observado', value: ESTADO_OBSERVADO },
	];

	@wire(getRecord, { recordId: '$recordId', fields: [SUBESTADO_FIELD] })
	wiredRla({ data, error }) {
		if (data) {
			const anterior = this.subestado;
			this.subestado = getFieldValue(data, SUBESTADO_FIELD);
			if (anterior && anterior !== this.subestado) {
				this.pending.clear();
				this.load();
			}
		} else if (error) {
			this.subestado = null;
		}

		if (this.rows?.length) {
			this.rows = this.decorateRows(this.rows);
		}
	}

	connectedCallback() {
		this.refreshHandlerId = registerRefreshHandler(this, this.handleRefreshDocumentacion.bind(this));
		this.load();
	}

	disconnectedCallback() {
		unregisterRefreshHandler(this.refreshHandlerId);
	}

	async handleRefreshDocumentacion() {
		if (this.wiredContratosResult) await refreshApex(this.wiredContratosResult);
		await this.load({ preservePending: true });
		return true;
	}

	get hasReviewerPermission() {
		return Boolean(TIENE_PERMISO_CONTROL_DOCUMENTOS || TIENE_PERMISO_ANALISTA_CREDITO);
	}

	get hasOfficialPermission() {
		return Boolean(TIENE_PERMISO_OFICIAL_NEGOCIO);
	}

	get hasAdminPermission() {
		return Boolean(TIENE_PERMISO_ADMINISTRADOR);
	}

	get isReviewerOnly() {
		if (this.esEtapaContratos) return this.subestado === SUBESTADO_PAGARES && this.puedeRevisarContratos;
		return this.hasReviewerPermission;
	}

	get isBusinessOfficialOnly() {
		if (this.esEtapaContratos) return this.subestado === SUBESTADO_CONTRATOS && this.puedeCargarContratos;
		return this.hasOfficialPermission;
	}

	get canSave() {
		if (this.esEtapaContratos) return this.isReviewerOnly || this.isBusinessOfficialOnly;
		return this.hasAdminPermission || this.isReviewerOnly || this.isBusinessOfficialOnly;
	}

	get hasRows() {
		return Array.isArray(this.rows) && this.rows.length > 0;
	}

	get acceptedFormats() {
		return ACCEPTED_FILE_FORMATS;
	}

	get isSaveDisabled() {
		return this.loading || !this.canSave;
	}

	get canApproveAll() {
		if (this.esEtapaContratos) return this.isReviewerOnly && this.getRelevantRows().length > 0;
		return (this.hasAdminPermission || this.isReviewerOnly) && this.getRelevantRows().length > 0;
	}

	get isApproveAllDisabled() {
		return this.loading || !this.canApproveAll;
	}

	get categoryOrder() {
		return [CAT_ANALISIS, CAT_CONTRATO, CAT_DESEMBOLSO];
	}

	normalizeCategoryLabel(label) {
		const s = (label || '').trim();
		return s ? s : 'Sin categoría';
	}

	categoryKeyFromLabel(label) {
		return this.normalizeCategoryLabel(label)
			.toLowerCase()
			.normalize('NFD')
			.replace(/[\u0300-\u036f]/g, '')
			.replace(/[^a-z0-9]+/g, '_')
			.replace(/^_+|_+$/g, '');
	}

	isCategoryRelevant(categoryLabel, forReviewer = false) {
		const cat = this.normalizeCategoryLabel(categoryLabel);
		const sub = (this.subestado || '').trim();

		if (sub === SUBESTADO_ANALISIS) {
			return cat === CAT_ANALISIS;
		}

		if (sub === SUBESTADO_CREDITO) {
			return forReviewer && cat === CAT_ANALISIS;
		}

		if (sub === SUBESTADO_DESEMBOLSO) {
			return cat === CAT_DESEMBOLSO;
		}

		if (sub === SUBESTADO_CONTRATOS) {
			return !forReviewer && cat === CAT_CONTRATO;
		}

		if (sub === SUBESTADO_PAGARES) {
			return forReviewer && cat === CAT_CONTRATO;
		}

		return false;
	}

	getRelevantRows() {
		const forReviewer = this.esEtapaContratos ? this.isReviewerOnly : this.hasAdminPermission || this.isReviewerOnly;
		return (this.rows || []).filter((r) => this.isCategoryRelevant(r.categoria, forReviewer));
	}

	get groupedSections() {
		const map = new Map();

		(this.rows || []).forEach((r) => {
			const label = this.normalizeCategoryLabel(r.categoria);
			if (!map.has(label)) {
				map.set(label, { key: this.categoryKeyFromLabel(label), label, rows: [] });
			}
			map.get(label).rows.push(r);
		});

		const sections = Array.from(map.values());

		const order = this.categoryOrder;
		const rank = (label) => {
			const idx = order.indexOf(label);
			return idx === -1 ? 999 : idx;
		};

		sections.sort((a, b) => {
			const ra = rank(a.label);
			const rb = rank(b.label);
			if (ra !== rb) return ra - rb;
			return (a.label || '').localeCompare(b.label || '', 'es');
		});

		return sections.filter((s) => (s.rows || []).length > 0);
	}

	handleAccordionToggle(event) {
		const open = event.detail.openSections;
		this.activeSectionName = Array.isArray(open) ? (open.length ? open[0] : '') : open || '';
	}

	async load({ preservePending = false } = {}) {
		this.loading = true;
		this.errorMessage = null;
		const pendingBeforeLoad = preservePending ? new Map(this.pending) : new Map();

		try {
			const data = await initAndGetRows({ residentialLoanApplicationId: this.recordId });
			const rowsWithPendingChanges = (data || []).map((row) => {
				const pendingChange = pendingBeforeLoad.get(row.joinId);
				return pendingChange ? { ...row, ...pendingChange } : row;
			});
			this.rows = this.decorateRows(rowsWithPendingChanges);
			if (!preservePending) {
				this.pending.clear();
			}
		} catch (e) {
			this.rows = [];
			this.errorMessage = this.normalizeError(e);
		} finally {
			this.loading = false;
		}
	}

	decorateRows(data) {
		return (data || []).map((r) => {
			const files = (r.files || []).map((f) => ({
				...f,
				url: `/lightning/r/ContentDocument/${f.contentDocumentId}/view`,
				shortTitle: f.title && f.title.length > 15 ? `${f.title.substring(0, 15)}...` : f.title,
			}));

			const hasFile = files.length >= 1;
			const isReviewerRelevant = this.isCategoryRelevant(r.categoria, true);
			const isOfficialRelevant = this.isCategoryRelevant(r.categoria, false);
			const forReviewer = this.esEtapaContratos ? this.isReviewerOnly : this.hasAdminPermission || this.isReviewerOnly;
			const isRelevant = forReviewer ? isReviewerRelevant : isOfficialRelevant;
			const isPendienteOrObservado = r.estadoRevision === ESTADO_PENDIENTE || r.estadoRevision === ESTADO_OBSERVADO;

			// Oficial/Admin:
			// - solo categoría relevante según subestado
			// - y además solo si está Pendiente u Observado
			const canOfficialEditDocument = isOfficialRelevant && isPendienteOrObservado;
			// El comentario oficial puede editarse fuera del subestado actual,
			// salvo cuando el documento ya fue aprobado por revision.
			const canOfficialEditComment = isPendienteOrObservado && (!this.esEtapaContratos || isOfficialRelevant) &&
				(this.normalizeCategoryLabel(r.categoria) !== CAT_CONTRATO || this.subestado === SUBESTADO_CONTRATOS);

			// Reviewer:
			// - solo categoría relevante según subestado
			// - solo puede editar estado/comentario
			const canReviewerReviewDocument = isReviewerRelevant;

			let uploadDisabled = true;
			let noAplicaDisabled = true;
			let comentarioOficialDisabled = true;
			let comentarioDisabled = true;
			let estadoRevisionDisabled = true;

			if (this.esEtapaContratos) {
				const cargar = this.subestado === SUBESTADO_CONTRATOS && this.puedeCargarContratos;
				const revisar = this.subestado === SUBESTADO_PAGARES && this.puedeRevisarContratos;
				uploadDisabled = !cargar || !canOfficialEditDocument || r.noAplica === true;
				noAplicaDisabled = !cargar || !canOfficialEditDocument;
				comentarioOficialDisabled = !cargar || !canOfficialEditComment;
				comentarioDisabled = !revisar || !canReviewerReviewDocument;
				estadoRevisionDisabled = !revisar || !canReviewerReviewDocument;
			} else if (this.hasAdminPermission) {
				uploadDisabled = !canOfficialEditDocument || r.noAplica === true;
				noAplicaDisabled = !canOfficialEditDocument;
				comentarioOficialDisabled = !canOfficialEditComment;
				comentarioDisabled = !canReviewerReviewDocument;
				estadoRevisionDisabled = !canReviewerReviewDocument;
			} else if (this.isReviewerOnly) {
				uploadDisabled = true;
				noAplicaDisabled = true;
				comentarioOficialDisabled = true;
				comentarioDisabled = !canReviewerReviewDocument;
				estadoRevisionDisabled = !canReviewerReviewDocument;
			} else if (this.isBusinessOfficialOnly) {
				uploadDisabled = !canOfficialEditDocument || r.noAplica === true;
				noAplicaDisabled = !canOfficialEditDocument;
				comentarioOficialDisabled = !canOfficialEditComment;
				comentarioDisabled = true;
				estadoRevisionDisabled = true;
			}

			let uploadHint = '';

			if (this.isReviewerOnly) {
				if (!isReviewerRelevant) {
					uploadHint = 'No corresponde validar esta categoría en el subestado actual.';
				} else if (r.noAplica === true) {
					uploadHint = 'Marcado como No aplica.';
				} else if (hasFile) {
					uploadHint = 'Documento cargado.';
				} else {
					uploadHint = 'Sin archivo cargado.';
				}
			} else {
				if (!isOfficialRelevant) {
					uploadHint = 'No corresponde editar esta categoría en el subestado actual.';
				} else if (!isPendienteOrObservado) {
					uploadHint = 'Solo se puede modificar si el documento está en Pendiente u Observado.';
				} else if (r.noAplica === true) {
					uploadHint = 'No aplica: no se requiere archivo.';
				} else if (!hasFile) {
					uploadHint = 'Requerido: carga uno o más archivos.';
				} else {
					uploadHint = 'Puedes agregar más archivos mientras esté en Pendiente u Observado.';
				}
			}

			return {
				...r,
				files,
				hasFile,
				isRelevant,
				uploadDisabled,
				noAplicaDisabled,
				comentarioOficialDisabled,
				comentarioDisabled,
				estadoRevisionDisabled,
				uploadHint,
				estadoRevisionValue: r.estadoRevision || '',
			};
		});
	}

	handleNoAplicaChange(event) {
		const joinId = event.target.dataset.joinid;
		const value = event.target.checked;

		this.upsertPending(joinId, {
			noAplica: value,
			estadoRevision: ESTADO_PENDIENTE,
		});

		this.updateRow(joinId, {
			noAplica: value,
			estadoRevision: ESTADO_PENDIENTE,
		});
	}

	handleComentarioChange(event) {
		const joinId = event.target.dataset.joinid;
		const value = event.target.value;

		this.upsertPending(joinId, { comentario: value });
		this.updateRow(joinId, { comentario: value });
	}

	handleComentarioOficialChange(event) {
		const joinId = event.target.dataset.joinid;
		const value = event.target.value;

		this.upsertPending(joinId, {
			comentarioOficial: value,
			estadoRevision: ESTADO_PENDIENTE,
		});

		this.updateRow(joinId, {
			comentarioOficial: value,
			estadoRevision: ESTADO_PENDIENTE,
		});
	}

	handleEstadoRevisionChange(event) {
		const joinId = event.target.dataset.joinid;
		const value = event.detail.value;

		this.upsertPending(joinId, { estadoRevision: value });
		this.updateRow(joinId, { estadoRevision: value });
	}

	upsertPending(joinId, patch) {
		if (!joinId) return;
		const current = this.pending.get(joinId) || { joinId };
		this.pending.set(joinId, { ...current, ...patch });
	}

	updateRow(joinId, patch) {
		const updated = (this.rows || []).map((r) => {
			if (r.joinId !== joinId) return r;
			return { ...r, ...patch };
		});

		this.rows = this.decorateRows(updated);
	}

	validateCategoryComplete(categoryLabel) {
		const cat = this.normalizeCategoryLabel(categoryLabel);
		const inCategory = (this.rows || []).filter((r) => this.normalizeCategoryLabel(r.categoria) === cat);

		if (inCategory.length === 0) return true;

		const invalid = inCategory.filter((r) => r.noAplica !== true && (r.files || []).length < 1);
		if (invalid.length === 0) return true;

		this.toast(
			'Faltan documentos',
			`Debes cargar todos los documentos de la categoría "${cat}" (o marcar "No aplica") antes de guardar.`,
			'warning'
		);
		return false;
	}

	validateRequiredBySubestadoForOfficial() {
		const sub = (this.subestado || '').trim();

		if (sub === SUBESTADO_ANALISIS) {
			return this.validateCategoryComplete(CAT_ANALISIS);
		}

		if (sub === SUBESTADO_DESEMBOLSO) {
			return this.validateCategoryComplete(CAT_DESEMBOLSO);
		}
		if (sub === SUBESTADO_CONTRATOS) return this.validateCategoryComplete(CAT_CONTRATO);

		return true;
	}

	validateReviewerBySubestado() {
		if (!this.isReviewerOnly) return true;
		if (this.subestado === SUBESTADO_PAGARES && !this.validateCategoryComplete(CAT_CONTRATO)) return false;

		const relevantRows = this.getRelevantRows();

		if (!relevantRows.length) return true;

		const invalidEstado = relevantRows.find((r) => !r.estadoRevision || r.estadoRevision === ESTADO_PENDIENTE);

		if (invalidEstado) {
			this.toast(
				'Estado de revisión requerido',
				'Debes completar el estado de revisión de todos los documentos de la categoría correspondiente antes de guardar.',
				'warning'
			);
			return false;
		}

		const invalidComentario = relevantRows.find((r) => r.estadoRevision === ESTADO_OBSERVADO && (!r.comentario || !r.comentario.trim()));

		if (invalidComentario) {
			this.toast('Comentario requerido', 'Si un documento queda con estado "Observado", debes ingresar un comentario.', 'warning');
			return false;
		}

		return true;
	}

	async handleSave() {
		await this.savePendingChanges('Cambios guardados correctamente.');
	}

	async handleApproveAll() {
		if (!this.canApproveAll) {
			return;
		}

		const rowsToApprove = this.getRelevantRows().filter((r) => r.joinId && r.estadoRevision !== ESTADO_APROBADO);

		if (!rowsToApprove.length) {
			this.toast('Sin cambios', 'Todos los documentos de la categoría correspondiente ya están aprobados.', 'info');
			return;
		}

		rowsToApprove.forEach((row) => {
			this.upsertPending(row.joinId, { estadoRevision: ESTADO_APROBADO });
			this.updateRow(row.joinId, { estadoRevision: ESTADO_APROBADO });
		});

		await this.savePendingChanges('Todos los documentos de la categoría correspondiente fueron aprobados.');
	}

	async savePendingChanges(successMessage) {
		if (this.pending.size === 0) {
			this.toast('Sin cambios', 'No hay cambios para guardar.', 'info');
			return;
		}

		if ((this.hasAdminPermission || this.isBusinessOfficialOnly) && !this.validateRequiredBySubestadoForOfficial()) {
			return;
		}

		if (!this.validateReviewerBySubestado()) {
			return;
		}

		this.loading = true;

		try {
			const joinIds = [];
			const noAplicaList = [];
			const comentarioList = [];
			const comentarioOficialList = [];
			const estadoRevisionList = [];

			for (const value of this.pending.values()) {
				joinIds.push(value.joinId);
				noAplicaList.push(Object.prototype.hasOwnProperty.call(value, 'noAplica') ? value.noAplica : null);
				comentarioList.push(Object.prototype.hasOwnProperty.call(value, 'comentario') ? value.comentario : null);
				comentarioOficialList.push(Object.prototype.hasOwnProperty.call(value, 'comentarioOficial') ? value.comentarioOficial : null);
				estadoRevisionList.push(Object.prototype.hasOwnProperty.call(value, 'estadoRevision') ? value.estadoRevision : null);
			}

			await saveRows({
				joinIds,
				noAplicaList,
				comentarioList,
				comentarioOficialList,
				estadoRevisionList,
			});

			this.toast('Guardado', successMessage, 'success');
			await this.load();
			this.dispatchEvent(new RefreshEvent());
		} catch (e) {
			this.toast('Error', this.normalizeError(e), 'error');
		} finally {
			this.loading = false;
		}
	}

	async handleUploadFinished(event) {
		const joinId = event.currentTarget?.dataset?.joinid;

		const uploaded = event.detail.files || [];
		const contentDocumentIds = uploaded.map((f) => f.documentId).filter(Boolean);

		if (!joinId || contentDocumentIds.length === 0) {
			this.toast('Error', 'No se pudo identificar el join o el archivo.', 'error');
			return;
		}

		this.loading = true;
		try {
			const result = await processUploadedFiles({
				residentialLoanApplicationId: this.recordId,
				joinId,
				contentDocumentIds,
			});

			await this.load({ preservePending: true });
			this.dispatchEvent(new RefreshEvent());

			const rejectedFileNames = result?.rejectedFileNames || [];
			const acceptedCount = (result?.acceptedContentDocumentIds || []).length;
			if (rejectedFileNames.length > 0) {
				const acceptedMessage = acceptedCount > 0 ? ` Se cargaron ${acceptedCount} archivo(s) válido(s).` : '';
				this.toast(
					'Formato no permitido',
					`No se admitieron: ${rejectedFileNames.join(', ')}.${acceptedMessage}`,
					'warning'
				);
			} else {
				this.toast(
					acceptedCount === 1 ? 'Archivo subido' : 'Archivos subidos',
					acceptedCount === 1 ? 'El archivo se cargó correctamente.' : `Se cargaron ${acceptedCount} archivos correctamente.`,
					'success'
				);
			}
		} catch (e) {
			this.toast('Error', this.normalizeError(e), 'error');
			await this.load({ preservePending: true });
		} finally {
			this.loading = false;
		}
	}

	toast(title, message, variant) {
		this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
	}

	normalizeError(e) {
		try {
			if (Array.isArray(e?.body)) return e.body.map((x) => x.message).join(' | ');
			if (typeof e?.body?.message === 'string') return e.body.message;
			if (typeof e?.message === 'string') return e.message;
			return 'Error inesperado';
		} catch {
			return 'Error inesperado';
		}
	}
}