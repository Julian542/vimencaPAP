import { LightningElement, api, wire, track } from 'lwc';
import getApprovalHistory from '@salesforce/apex/FSC_ApprovalHistoryController.getApprovalHistory';

const PAGE_SIZE = 3;

export default class Fsc_ApprovalHistory extends LightningElement {
    @api recordId;

    @track items = [];
    @track visibleCount = PAGE_SIZE;
    @track error;

    @wire(getApprovalHistory, { recordId: '$recordId' })
    wiredHistory({ error, data }) {
        if (data) {
            this.items = data
                .filter(item => !this.shouldExcludeItem(item))
                .map(item => ({
                    ...item,
                    stepName: this.translateStepName(item.stepName),
                    status: this.translateStatus(item.status)
                }));

            this.error = undefined;
            this.visibleCount = PAGE_SIZE;
        } else if (error) {
            this.error = error;
            this.items = [];
        }
    }

    normalize(value) {
        return (value || '').trim().toLowerCase();
    }

    shouldExcludeItem(item) {
        const stepName = this.normalize(item.stepName);
        const status = this.normalize(item.status);

        return (
            stepName === 'locked' ||
            stepName === 'unlocked' ||
            status === 'locked' ||
            status === 'unlocked'
        );
    }

    translateStepName(stepName) {
        const translations = {
            'approval step': 'Paso de aprobación',
            'approval request submitted': 'Aprobación enviada',
            'pending approval': 'Pendiente de aprobación'
        };

        const key = this.normalize(stepName);
        return translations[key] || stepName;
    }

    translateStatus(status) {
        const translations = {
            'rejected': 'Rechazado',
            'approved': 'Aprobado',
            'pending': 'Pendiente',
            'submitted': 'Enviado'
        };

        const key = this.normalize(status);
        return translations[key] || status;
    }

    get totalCount() {
        return this.items.length;
    }

    get title() {
        if (this.totalCount > 0) {
            return `Historial de aprobaciones (${this.totalCount}${this.totalCount >= 3 ? '+' : ''})`;
        }
        return 'Historial de aprobaciones';
    }

    get visibleItems() {
        return this.items.slice(0, this.visibleCount);
    }

    get hasItems() {
        return this.totalCount > 0;
    }

    get hasMore() {
        return this.visibleCount < this.totalCount;
    }

    get showViewMore() {
        return this.hasItems && this.hasMore;
    }

    get showEmpty() {
        return !this.error && this.totalCount === 0;
    }

    get errorMessage() {
        return this.error?.body?.message || 'No se pudo cargar el historial de aprobaciones.';
    }

    handleViewMore() {
        this.visibleCount += PAGE_SIZE;
    }
}