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

    _timeSlots = [];

    @wire(getActionCentre, { recordId: '$recordId' })
    wiredCentre({ data, error }) {
        if (data) {
            this.centre = data.centre;
            this._timeSlots = data.timeSlots ?? [];
            this.error = null;
        } else if (error) {
            this.error = error;
            this.centre = null;
            this._timeSlots = [];
        } else if (data === null) {
            this.error = { message: 'Action Centre not found.' };
            this.centre = null;
            this._timeSlots = [];
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

    get timeSlots() {
        return this._timeSlots.map(slot => ({
            day: slot.DayOfWeek,
            hours: `${formatTime(slot.StartTime)} – ${formatTime(slot.EndTime)}`,
            key: slot.DayOfWeek
        }));
    }

    get hasTimeSlots() {
        return this._timeSlots.length > EMPTY_LIST.length;
    }
}

function formatTime(timeVal) {
    // LWR serialises Salesforce Time fields as milliseconds since midnight
    const totalMinutes = Math.floor(timeVal / 60000);
    const hour = Math.floor(totalMinutes / 60);
    const minute = totalMinutes % 60;
    const period = hour < 12 ? 'AM' : 'PM';
    const displayHour = hour % 12 || 12;
    return `${displayHour}:${String(minute).padStart(2, '0')} ${period}`;
}
