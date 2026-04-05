public without sharing class ActionCentreController {

    @AuraEnabled(cacheable=true)
    public static List<Action_Centre__c> getActionCentres() {
        List<Action_Centre__c> centres = [
            SELECT Id, Name, Type__c, Address__c,
                   Street__c, City__c, Country__c,
                   Latitude__c, Longitude__c,
                   Work_Time__c, Phone__c, Email__c,
                   Description__c
            FROM Action_Centre__c
            ORDER BY Name ASC
            LIMIT 200
        ];
        return (List<Action_Centre__c>) Security.stripInaccessible(
            AccessType.READABLE, centres
        ).getRecords();
    }
}
