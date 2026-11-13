import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDocumentoLegalEditable from '@salesforce/apex/FSC_RlaAccionesController.getDocumentoLegalEditable';
import guardarDocumentoLegalEditado from '@salesforce/apex/FSC_RlaAccionesController.guardarDocumentoLegalEditado';

export default class FscEditarDocumentoLegal extends LightningElement {
    @api recordId;
    @api contentVersionId;
    @api tipoDocumento;
    sections = [];
    loading = true;
    saving = false;
    errorMessage = '';
    baseline = new Map();
    changes = {};

    get modalTitle() {
        return this.tipoDocumento === 'PAGARE' ? 'Editar pagaré' : 'Editar contrato';
    }

    get busy() {
        return this.loading || this.saving;
    }

    get disableSave() {
        return this.busy || !this.sections.length;
    }

    connectedCallback() {
        this.load();
    }

    async load() {
        try {
            const data = await getDocumentoLegalEditable({
                residentialLoanApplicationId: this.recordId,
                contentVersionId: this.contentVersionId
            });
            const groups = new Map();
            (data.bloques || []).forEach((block) => {
                this.baseline.set(block.clave, block.texto);
                if (!groups.has(block.parrafo)) groups.set(block.parrafo, []);
                groups.get(block.parrafo).push({
                    key: block.clave,
                    text: block.texto,
                    label: `Texto ${this.baseline.size}`,
                    rows: Math.min(24, Math.max(2, Math.ceil(block.texto.length / 100)))
                });
            });
            this.sections = [...groups.entries()].map(([key, blocks], index) => ({
                key: String(key), label: `Bloque ${index + 1}`, blocks
            }));
        } catch (error) {
            this.errorMessage = error?.body?.message || error?.message || 'No fue posible abrir el documento.';
        } finally {
            this.loading = false;
        }
    }

    handleChange(event) {
        const key = event.target.dataset.key;
        if (!this.baseline.has(key) || this.busy) return;
        const text = event.target.value;
        if (text === this.baseline.get(key)) delete this.changes[key];
        else this.changes[key] = text;
    }

    handleCancel() {
        if (!this.saving) this.dispatchEvent(new CustomEvent('cancel'));
    }

    async handleSave() {
        if (this.busy) return;
        if (!Object.keys(this.changes).length) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Sin cambios', message: 'Modifique al menos un texto antes de guardar.', variant: 'info' }));
            return;
        }
        this.saving = true;
        this.errorMessage = '';
        try {
            const versionId = await guardarDocumentoLegalEditado({
                residentialLoanApplicationId: this.recordId,
                contentVersionId: this.contentVersionId,
                cambiosJson: JSON.stringify(this.changes)
            });
            this.dispatchEvent(new ShowToastEvent({ title: 'Documento guardado', message: 'El PDF fue reemplazado con los textos editados.', variant: 'success' }));
            this.dispatchEvent(new CustomEvent('saved', { detail: { versionId } }));
        } catch (error) {
            this.errorMessage = error?.body?.message || error?.message || 'No fue posible guardar el documento. El archivo anterior se conserva.';
        } finally {
            this.saving = false;
        }
    }
}