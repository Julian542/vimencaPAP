import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';

const OMNI_FIELD_NAME = 'FSC_GastosTramitacion__c';

export default class Fsc_GastosTramitacion extends OmniscriptBaseMixin(LightningElement) {
    value = null;
    hasApiValue = false;

    @api
    set gastosTramitacion(value) {
        this.hasApiValue = value !== null && value !== undefined && value !== '';
        this.value = this.normalizeCurrencyValue(value);
    }

    get gastosTramitacion() {
        return this.value;
    }

    connectedCallback() {
        if (!this.hasApiValue) {
            this.value = this.normalizeCurrencyValue(this.omniJsonData?.[OMNI_FIELD_NAME]);
        }
    }

    handleValueChange(event) {
        this.value = this.normalizeCurrencyValue(event.detail.value);
        this.updateOmniJson();
    }

    handleValueBlur() {
        this.value = this.normalizeCurrencyValue(this.value);
    }

    normalizeCurrencyValue(value) {
        if (value === null || value === undefined || value === '') {
            return null;
        }

        const numericValue = Number(String(value).replace(/,/g, ''));
        if (Number.isNaN(numericValue)) {
            return null;
        }

        return Number(numericValue.toFixed(2));
    }

    updateOmniJson() {
        if (typeof this.omniApplyCallResp === 'function') {
            this.omniApplyCallResp({
                [OMNI_FIELD_NAME]: this.value
            });
        }
    }
}