import { LightningElement, wire, track } from 'lwc';
import getProcedures from '@salesforce/apex/ProcedureController.getProcedures';
import getCurrencyRates from '@salesforce/apex/ProcedureController.getCurrencyRates';
import getCentreProcedures from '@salesforce/apex/ProcedureController.getCentreProcedures';
import getActionCentres from '@salesforce/apex/ActionCentreController.getActionCentres';


const CURRENCIES = [
    'USD',
    'BYN',
    'EUR'
];

export default class ProcedureList extends LightningElement {
    @track currency = CURRENCIES[0];
    @track nameFilter = '';
    @track centreFilter = '';
    @track selectedProcedure = null;

    _procedures = [];
    _rates = null;
    _centres = [];
    _centreProcedures = [];
    _proceduresError = null;

    @wire(getProcedures)
    wiredProcedures({ data, error }) {
        if (data) {
            this._procedures = data;
            this._proceduresError = null;
        } else if (error) {
            this._proceduresError = error;
            console.log(this._proceduresError);
            this._procedures = [];
        }
    }

    connectedCallback() {
        getCurrencyRates()
            .then(data => {
                this._rates = data;
            })
            .catch(error => {
                this._rates = null;
                console.error('Error fetching rates:', error);
            });
    }
    
    // NOTE: This does not work
    // @wire(getCurrencyRates)
    // wiredRates({ data, error }) {
    //     if (data) {
    //         this._rates = data;
    //     } else if (error) {
    //         this._rates = null;
    //     }
    // }

    @wire(getCentreProcedures)
    wiredCentreProcedures({ data, error }) {
        if (data) {
            this._centreProcedures = data;
        } else if (error) {
            this._centreProcedures = [];
        }
    }

    @wire(getActionCentres)
    wiredCentres({ data, error }) {
        if (data) {
            this._centres = data;
        } else if (error) {
            this._centres = [];
        }
    }

    get currencies() {
        return CURRENCIES.map(c => ({
            value: c,
            buttonClass: `slds-button slds-button_${c.value === this.currency ? 'brand' : 'neutral'}`
        }));
    }

    get centreOptions() {
        const opts = [{ label: 'All Centres', value: '' }];
        this._centres.forEach(c => opts.push({ label: c.Name, value: c.Id }));
        return opts;
    }

    get filteredProcedures() {
        const name = this.nameFilter.toLowerCase();
        const centre = this.centreFilter;
        const allowedProductIds = centre
            ? new Set(this._centreProcedures.filter(cp => cp.Action_Centre__c === centre).map(cp => cp.Procedure__c))
            : null;
        return this._procedures
            .filter(p => (!name || p.Product2.Name.toLowerCase().includes(name))
                      && (!allowedProductIds || allowedProductIds.has(p.Product2Id)))
            .map(p => ({
                id: p.Id,
                productId: p.Product2Id,
                name: p.Product2.Name,
                description: p.Product2.Description ?? '',
                family: p.Product2.Family ?? '',
                usdPrice: p.UnitPrice,
                displayPrice: this._convertPrice(p.UnitPrice),
                currencySymbol: this._currencySymbol()
            }));
    }

    get hasError() {
        return this._proceduresError !== null;
    }

    get isLoading() {
        return this._procedures.length === 0 && !this._proceduresError;
    }

    get hasProcedures() {
        return this.filteredProcedures.length > 0;
    }

    get showModal() {
        return this.selectedProcedure !== null;
    }

    _convertPrice(usdPrice) {
        if (!this._rates) return usdPrice;
        if (this.currency === 'BYN') {
            return (usdPrice * this._rates.USD_to_BYN__c).toFixed(2);
        }
        if (this.currency === 'EUR') {
            return (usdPrice * (this._rates.USD_to_BYN__c / this._rates.EUR_to_BYN__c)).toFixed(2);
        }
        return usdPrice.toFixed(2);
    }

    _currencySymbol() {
        if (this.currency === 'BYN') return 'BYN ';
        if (this.currency === 'EUR') return '€';
        return '$';
    }

    handleCurrencyChange(event) {
        this.currency = event.target.value;
    }

    handleNameFilter(event) {
        this.nameFilter = event.target.value;
    }

    handleCentreFilter(event) {
        this.centreFilter = event.target.value;
    }

    handleSelectProcedure(event) {
        const id = event.currentTarget.dataset.id;
        const entry = this._procedures.find(p => p.Id === id);
        if (entry) {
            this.selectedProcedure = {
                pricebookEntryId: entry.Id,
                procedureId: entry.Product2Id,
                name: entry.Product2.Name,
                usdPrice: entry.UnitPrice
            };
        }
    }

    handleModalClose() {
        this.selectedProcedure = null;
    }

    handleExportPdf() {
        // TODO: replace with the proper PDF format
        window.print();
    }
}
