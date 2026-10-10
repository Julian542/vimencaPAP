import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';

const COLUMNS = [
    {
        label: 'Tipo',
        fieldName: 'RecordTypeLabel',
        type: 'text'
    },
    {
        label: 'Nombre',
        fieldName: 'Name',
        type: 'text'
    }
];

export default class Fsc_FinancialAccountsTable extends OmniscriptBaseMixin(LightningElement) {
    title = 'Productos';
    stepNodeName = 'StepDescripcionFacilidades';
    recordsNodeName = 'FinServRecords';

    columns = COLUMNS;

    get rows() {
        console.log('this title: ' + this.title);
        console.log('this stepNodeName: ' + this.stepNodeName);
        console.log('this recordsNodeName: ' + this.recordsNodeName);

        console.log('this title: ' + JSON.stringify(this.title));
        console.log('this stepNodeName: ' + JSON.stringify(this.stepNodeName));
        console.log('this recordsNodeName: ' + JSON.stringify(this.recordsNodeName));

        const json = this.omniJsonData || {};
        let records = [];

        // Ruta principal: StepDescripcionFacilidades.FinServRecords
        if (
            this.stepNodeName &&
            json[this.stepNodeName] &&
            Array.isArray(json[this.stepNodeName][this.recordsNodeName])
        ) {
            records = json[this.stepNodeName][this.recordsNodeName];
        }
        // Fallback por si el array termina en raíz
        else if (Array.isArray(json[this.recordsNodeName])) {
            records = json[this.recordsNodeName];
        }

        return records.map((item) => ({
            Id: item.Id,
            Name: item.Name || '',
            RecordTypeLabel: item.RecordTypeLabel || '',
            AccountId: item.AccountId || ''
        }));
    }

    get hasRows() {
        return this.rows.length > 0;
    }
}