import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getActionCentres from '@salesforce/apex/ActionCentreController.getActionCentres';

const CLIENT_SUPPORT_TYPE = 'Client Support Centre',
    EMPTY_MARKERS = [],
    SEPARATOR = ' | ';

const addContactInfo = (centre, displayInfo) => {
    if (centre.Phone__c) {
        displayInfo.push(`Phone: ${centre.Phone__c}`);
    }
    if (centre.Email__c) {
        displayInfo.push(`Email: ${centre.Email__c}`);
    }
};

const buildDescription = (centre) => {
    const displayInfo = [];
    if (centre.Work_Time__c) {
        displayInfo.push(`Hours: ${centre.Work_Time__c}`);
    }
    displayInfo.push(centre.Address__c)
    if (centre.Type__c === CLIENT_SUPPORT_TYPE) {
        addContactInfo(centre, displayInfo);
    }
    return displayInfo.join(SEPARATOR);
};

const buildLocation = (centre) => {
    if (centre.Latitude__c !== null && centre.Longitude__c !== null) {
        return { Latitude: centre.Latitude__c, Longitude: centre.Longitude__c };
    }
    return { City: centre.City__c, Country: centre.Country__c, Street: centre.Street__c };
};

const buildMarker = (centre) => ({
    description: buildDescription(centre),
    location: buildLocation(centre),
    title: centre.Name,
    value: centre.Id
});

export default class ActionCentreMap extends NavigationMixin(LightningElement) {
    error = null;
    mapMarkers = EMPTY_MARKERS;

    @wire(getActionCentres)
    wiredCentres({ data, error }) {
        if (data) {
            this.mapMarkers = data.map(buildMarker);
            this.error = null;
        } else if (error) {
            this.error = error;
            this.mapMarkers = EMPTY_MARKERS;
        }
    }

    handleMarkerSelect(event) {
        this[NavigationMixin.GenerateUrl]({
            attributes: {
                actionName: 'view',
                objectApiName: 'Action_Centre__c',
                recordId: event.detail.selectedMarkerValue
            },
            type: 'standard__recordPage'
        }).then(url => {
            window.open(url, '_blank');
        });
    }

    get hasError() {
        return this.error !== null;
    }

    get hasMarkers() {
        return this.mapMarkers.length > EMPTY_MARKERS.length;
    }
}
