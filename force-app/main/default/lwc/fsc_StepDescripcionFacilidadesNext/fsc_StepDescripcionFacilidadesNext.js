import { LightningElement, api, track } from 'lwc';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';

export default class StepDescripcionFacilidadesNext extends OmniscriptBaseMixin(LightningElement) {
    @api tipoGarantia = '';
    @track hasFunds = false;
    @track hasFacilities = false;
    @track hasAssets = false;
    @track attemptedNext = false;

    _timer;

    connectedCallback() {
        this.syncValidation();

        // Workaround pragmático:
        // OmniScript a veces no re-renderiza bonito fuera del Preview.
        // Este polling liviano mantiene el estado del botón actualizado.
        this._timer = window.setInterval(() => {
            this.syncValidation();
        }, 400);
    }

    disconnectedCallback() {
        if (this._timer) {
            window.clearInterval(this._timer);
            this._timer = null;
        }
    }

    get skipsAssetValidation() {
        return this.normalizeText(this.tipoGarantia) === 'sin garantia';
    }

    get canProceed() {
        return this.hasFunds && this.hasFacilities && (this.skipsAssetValidation || this.hasAssets);
    }

    get showError() {
        return this.attemptedNext && !this.canProceed;
    }

    syncValidation() {
        const data = this.omniJsonData || {};

        this.hasFunds = this.countRecords(data.StepDescripcionFacilidades?.FSC_Proposito_Y_Uso_De_Fondos__c ?? data.FSC_Proposito_Y_Uso_De_Fondos__c) > 0;
        this.hasFacilities = this.countRecords(data.StepDescripcionFacilidades?.FSC_Facilidades_De_Credito__c ?? data.FSC_Facilidades_De_Credito__c) > 0;
        this.hasAssets = this.countRecords(data.StepDescripcionFacilidades?.LoanApplicationAsset ?? data.LoanApplicationAsset) > 0;
    }

    countRecords(node) {
        if (node === null || node === undefined) {
            return 0;
        }

        // Caso: varios registros
        if (Array.isArray(node)) {
            return node.filter(record => this.isMeaningfulRecord(record)).length;
        }

        // Caso: un solo registro => viene como {}
        if (typeof node === 'object') {
            return this.isMeaningfulRecord(node) ? 1 : 0;
        }

        return 0;
    }

    normalizeText(value) {
        return String(value ?? '')
            .normalize('NFD')
            .replace(/[\u0300-\u036f]/g, '')
            .trim()
            .toLowerCase();
    }

    isMeaningfulRecord(record) {
        if (!record || typeof record !== 'object' || Array.isArray(record)) {
            return false;
        }

        const keys = Object.keys(record);
        if (keys.length === 0) {
            return false;
        }

        return keys.some(key => {
            const value = record[key];

            if (value === null || value === undefined) {
                return false;
            }

            if (typeof value === 'string') {
                return value.trim() !== '';
            }

            if (Array.isArray(value)) {
                return value.length > 0;
            }

            if (typeof value === 'object') {
                return Object.keys(value).length > 0;
            }

            // números, boolean, fechas, etc.
            return true;
        });
    }

    handleNext() {
        this.attemptedNext = true;
        this.syncValidation();

        if (!this.canProceed) {
            return;
        }

        this.omniNextStep();
    }

    handlePrevious() {
        this.omniPrevStep();
    }
}