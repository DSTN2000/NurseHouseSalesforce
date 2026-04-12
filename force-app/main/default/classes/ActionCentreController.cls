public without sharing class ActionCentreController {

    public class CentreWrapper {
        @AuraEnabled public Action_Centre__c centre;
        @AuraEnabled public List<TimeSlot> timeSlots;

        public CentreWrapper(Action_Centre__c centre, List<TimeSlot> timeSlots) {
            this.centre = centre;
            this.timeSlots = timeSlots != null ? timeSlots : new List<TimeSlot>();
        }
    }

    private static Map<Id, List<TimeSlot>> fetchSlots(Set<Id> ohIds) {
        Map<Id, List<TimeSlot>> byOh = new Map<Id, List<TimeSlot>>();
        for (OperatingHours oh : [
            SELECT Id, (SELECT DayOfWeek, StartTime, EndTime FROM TimeSlots ORDER BY DayOfWeek)
            FROM OperatingHours
            WHERE Id IN :ohIds
        ]) {
            byOh.put(oh.Id, oh.TimeSlots);
        }
        return byOh;
    }

    @AuraEnabled(cacheable=true)
    public static CentreWrapper getActionCentre(Id recordId) {
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
        if (results.isEmpty()) {
            return null;
        }
        Action_Centre__c centre = results[0];
        List<TimeSlot> slots = new List<TimeSlot>();
        if (centre.Work_Time__c != null) {
            Map<Id, List<TimeSlot>> slotMap = fetchSlots(new Set<Id>{ centre.Work_Time__c });
            slots = slotMap.containsKey(centre.Work_Time__c) ? slotMap.get(centre.Work_Time__c) : slots;
        }
        return new CentreWrapper(centre, slots);
    }

    @AuraEnabled(cacheable=true)
    public static List<CentreWrapper> getActionCentres() {
        List<Action_Centre__c> centres = [
            SELECT Id, Name, Type__c, Address__c,
                   Street__c, City__c, Country__c,
                   Latitude__c, Longitude__c,
                   Work_Time__c, Work_Time__r.Name,
                   Phone__c, Email__c,
                   Description__c
            FROM Action_Centre__c
            ORDER BY Name ASC
            LIMIT 200
        ];
        Set<Id> ohIds = new Set<Id>();
        for (Action_Centre__c c : centres) {
            if (c.Work_Time__c != null) {
                ohIds.add(c.Work_Time__c);
            }
        }
        Map<Id, List<TimeSlot>> slotMap = ohIds.isEmpty() ? new Map<Id, List<TimeSlot>>() : fetchSlots(ohIds);
        List<CentreWrapper> results = new List<CentreWrapper>();
        for (Action_Centre__c c : centres) {
            results.add(new CentreWrapper(c, slotMap.get(c.Work_Time__c)));
        }
        return results;
    }
}
