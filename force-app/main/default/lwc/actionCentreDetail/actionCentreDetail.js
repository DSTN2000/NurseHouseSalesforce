import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getActionCentre from '@salesforce/apex/ActionCentreController.getActionCentre';

const CLIENT_SUPPORT_TYPE = 'Client Support Centre',
    EMPTY_LIST = [];

export default class ActionCentreDetail extends LightningElement {
    recordId = null;
    centre = null;
    error = null;

    @wire(CurrentPageReference)
    pageRef(ref) {
        if (ref) {
            this.recordId = ref.attributes?.recordId ?? ref.state?.recordId ?? null;
        }
    }

    @wire(getActionCentre, { recordId: '$recordId' })
    wiredCentre({ data, error }) {
        if (data) {
            this.centre = data;
            this.error = null;
        } else if (error) {
            this.error = error;
            this.centre = null;
        } else if (data === null) {
            this.error = { message: 'Action Centre not found.' };
            this.centre = null;
        }
    }

    get isLoading() {
        return this.centre === null && this.error === null;
    }

    get hasError() {
        return this.error !== null;
    }

    get isClientSupport() {
        return this.centre && this.centre.Type__c === CLIENT_SUPPORT_TYPE;
    }

    get nurses() {
        if (this.centre && this.centre.Nurses__r) {
            return this.centre.Nurses__r;
        }
        return EMPTY_LIST;
    }

    get hasNurses() {
        return this.nurses.length > EMPTY_LIST.length;
    }
}
