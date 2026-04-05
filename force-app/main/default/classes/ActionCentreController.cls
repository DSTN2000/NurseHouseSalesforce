public without sharing class ActionCentreController {

    @AuraEnabled(cacheable=true)
    public static Action_Centre__c getActionCentre(Id recordId) {
        if (recordId == null) {
            return null;
        }
        List<Action_Centre__c> results = [
            SELECT Id, Name, Type__c, Address__c,
                   Description__c, Work_Time__c, Work_Time__r.Name,
                   Phone__c, Email__c,
                   (SELECT Id, Name, Phone FROM Nurses__r ORDER BY Name ASC)
            FROM Action_Centre__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        return results.isEmpty() ? null : results[0];
    }

    @AuraEnabled(cacheable=true)
    public static List<Action_Centre__c> getActionCentres() {
        return [
            SELECT Id, Name, Type__c, Address__c,
                   Street__c, City__c, Country__c,
                   Latitude__c, Longitude__c,
                   Work_Time__c, Work_Time__r.Name, Phone__c, Email__c,
                   Description__c
            FROM Action_Centre__c
            ORDER BY Name ASC
            LIMIT 200
        ];
    }
}
