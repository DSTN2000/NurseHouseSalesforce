import { LightningElement, api, wire, track } from 'lwc';
import getActionCentres from '@salesforce/apex/ActionCentreController.getActionCentres';
import getNursesByActionCentre from '@salesforce/apex/ProcedureController.getNursesByActionCentre';
import scheduleVisit from '@salesforce/apex/ScheduleVisitAction.scheduleVisit';

export default class ScheduleVisitModal extends LightningElement {
    @api procedureId;
    @api procedureName;
    @api usdPrice;

    @track centreId = '';
    @track nurseId = '';
    @track firstName = '';
    @track lastName = '';
    @track email = '';
    @track phone = '';
    @track visitDateTime = '';
    @track houseAddress = '';
    @track notes = '';
    @track errorMessage = '';
    @track isSubmitting = false;

    centres = [];
    nurses = [];

    @wire(getActionCentres)
    wiredCentres({ data }) {
        if (data) {
            this.centres = data;
        }
    }

    @wire(getNursesByActionCentre, { centreId: '$centreId' })
    wiredNurses({ data }) {
        if (data) {
            this.nurses = data;
            this.nurseId = '';
        }
    }

    get centreOptions() {
        const opts = [{ label: '-- Select Centre --', value: '' }];
        this.centres.forEach(c => opts.push({ label: c.Name, value: c.Id }));
        return opts;
    }

    get nurseOptions() {
        const opts = [{ label: '-- Select Nurse --', value: '' }];
        this.nurses.forEach(n => opts.push({ label: n.Name, value: n.Id }));
        return opts;
    }

    get hasNurseOptions() {
        return this.centreId !== '' && this.nurses.length > 0;
    }

    get noNursesAvailable() {
        return this.centreId !== '' && this.nurses.length === 0;
    }

    get isSubmitDisabled() {
        return this.isSubmitting
            || !this.centreId
            || !this.nurseId
            || !this.firstName
            || !this.lastName
            || !this.email
            || !this.phone
            || !this.visitDateTime
            || !this.houseAddress;
    }

    get hasError() {
        return this.errorMessage !== '';
    }

    get minDateTime() {
        return new Date().toISOString().slice(0, 16);
    }

    handleCentreChange(event) {
        this.centreId = event.target.value;
        this.nurseId = '';
        this.errorMessage = '';
    }

    handleNurseChange(event) {
        this.nurseId = event.target.value;
        this.errorMessage = '';
    }

    handleFirstNameChange(event) { this.firstName = event.target.value; }
    handleLastNameChange(event)  { this.lastName  = event.target.value; }
    handleEmailChange(event)     { this.email     = event.target.value; }
    handlePhoneChange(event)     { this.phone     = event.target.value; }
    handleAddressChange(event)   { this.houseAddress = event.target.value; }
    handleNotesChange(event)     { this.notes     = event.target.value; }

    handleDateTimeChange(event) {
        // Convert local datetime-local value to ISO 8601 UTC string
        const local = event.target.value; // e.g. "2030-06-15T10:00"
        if (local) {
            this.visitDateTime = new Date(local).toISOString();
        } else {
            this.visitDateTime = '';
        }
        this.errorMessage = '';
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    async handleSubmit() {
        this.isSubmitting = true;
        this.errorMessage = '';
        try {
            await scheduleVisit({
                procedureId:    this.procedureId,
                unitPrice:      this.usdPrice,
                centreId:       this.centreId,
                nurseId:        this.nurseId,
                visitDateTime:  this.visitDateTime,
                houseAddress:   this.houseAddress,
                notes:          this.notes || null,
                clientFirstName: this.firstName,
                clientLastName:  this.lastName,
                clientEmail:     this.email,
                clientPhone:     this.phone
            });
            this.dispatchEvent(new CustomEvent('visitscheduled'));
        } catch (err) {
            this.errorMessage = (err.body && err.body.message)
                ? err.body.message
                : 'An unexpected error occurred. Please try again.';
        } finally {
            this.isSubmitting = false;
        }
    }
}
