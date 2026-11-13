import { LightningElement, api, wire, track } from 'lwc';
import getHistory from '@salesforce/apex/FSC_RlaFieldHistoryController.getHistory';
import { refreshApex } from '@salesforce/apex';

export default class Fsc_RlaFieldHistory extends LightningElement {
    @api recordId;
    @api limitRows = 200;

    @track rows = [];
    @track errorMessage = '';

    @track selectedField = 'ALL';
    @track dateFrom = null;
    @track dateTo = null;
    @track searchText = '';

    wiredHistoryResult;

    @wire(getHistory, { recordId: '$recordId', limitRows: '$limitRows' })
    wiredHistory(result) {
        this.wiredHistoryResult = result;

        const { data, error } = result;

        if (data) {
            this.rows = (data || []).map((item, index) => {
                const createdDateValue = item.createdDate ? new Date(item.createdDate) : null;
                const oldValueSafe = item.oldValue || '';
                const newValueSafe = item.newValue || '';

                return {
                    ...item,
                    rowKey: item.historyId || `${item.fieldApiName}-${item.createdDate}-${index}`,
                    createdDateValue,
                    createdDateOnly: createdDateValue ? this.toLocalDateOnly(createdDateValue) : null,
                    oldValueSafe,
                    newValueSafe,
                    oldValueDisplay: oldValueSafe || '—',
                    newValueDisplay: newValueSafe || '—',
                    badgeLabel: item.hasChanged ? 'Valor cambiado' : 'Sin cambio'
                };
            });

            this.errorMessage = '';
        } else if (error) {
            this.rows = [];
            this.errorMessage =
                error?.body?.message ||
                error?.message ||
                'No se pudo obtener el historial.';
        }
    }

    toLocalDateOnly(dateValue) {
        const year = dateValue.getFullYear();
        const month = String(dateValue.getMonth() + 1).padStart(2, '0');
        const day = String(dateValue.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}`;
    }

    normalize(value) {
        return (value || '')
            .toString()
            .trim()
            .toLowerCase()
            .normalize('NFD')
            .replace(/[\u0300-\u036f]/g, '');
    }

    get fieldOptions() {
        const options = [{ label: 'Todos los campos', value: 'ALL' }];

        const uniqueMap = new Map();
        (this.rows || []).forEach(row => {
            const key = row.fieldApiName || '';
            if (key && !uniqueMap.has(key)) {
                uniqueMap.set(key, row.fieldLabel || row.fieldApiName);
            }
        });

        const sorted = [...uniqueMap.entries()]
            .sort((a, b) => (a[1] || '').localeCompare(b[1] || ''));

        sorted.forEach(([apiName, label]) => {
            options.push({
                label: `${label} (${apiName})`,
                value: apiName
            });
        });

        return options;
    }

    get filteredRows() {
        let result = [...(this.rows || [])];

        if (this.selectedField && this.selectedField !== 'ALL') {
            result = result.filter(row => row.fieldApiName === this.selectedField);
        }

        if (this.dateFrom) {
            result = result.filter(row => row.createdDateOnly && row.createdDateOnly >= this.dateFrom);
        }

        if (this.dateTo) {
            result = result.filter(row => row.createdDateOnly && row.createdDateOnly <= this.dateTo);
        }

        const search = this.normalize(this.searchText);
        if (search) {
            result = result.filter(row => {
                const haystack = [
                    row.fieldLabel,
                    row.fieldApiName,
                    row.oldValueSafe,
                    row.newValueSafe,
                    row.createdByName
                ]
                    .map(value => this.normalize(value))
                    .join(' ');

                return haystack.includes(search);
            });
        }

        return result;
    }

    get totalCount() {
        return (this.rows || []).length;
    }

    get filteredCount() {
        return (this.filteredRows || []).length;
    }

    get hasRows() {
        return this.totalCount > 0;
    }

    get hasFilteredRows() {
        return this.filteredCount > 0;
    }

    get showEmpty() {
        return !this.errorMessage && !this.hasRows;
    }

    get showNoFilteredResults() {
        return !this.errorMessage && this.hasRows && !this.hasFilteredRows;
    }

    get summaryText() {
        return `Mostrando ${this.filteredCount} de ${this.totalCount} cambios`;
    }

    handleFieldChange(event) {
        this.selectedField = event.detail.value;
    }

    handleDateFromChange(event) {
        this.dateFrom = event.detail.value || null;
    }

    handleDateToChange(event) {
        this.dateTo = event.detail.value || null;
    }

    handleSearchChange(event) {
        this.searchText = event.target.value || '';
    }

    handleClearFilters() {
        this.selectedField = 'ALL';
        this.dateFrom = null;
        this.dateTo = null;
        this.searchText = '';
    }

    async handleRefresh() {
        if (this.wiredHistoryResult) {
            await refreshApex(this.wiredHistoryResult);
        }
    }
}