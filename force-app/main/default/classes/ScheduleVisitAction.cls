public without sharing class ScheduleVisitAction {

    @AuraEnabled
    public static Id scheduleVisit(
        Id      procedureId,
        Decimal unitPrice,
        Id      centreId,
        Id      nurseId,
        String  visitDateTime,
        String  houseAddress,
        String  notes,
        String  clientFirstName,
        String  clientLastName,
        String  clientEmail,
        String  clientPhone
    ) {
        DateTime visitDT = (DateTime) JSON.deserialize('"' + visitDateTime + '"', DateTime.class);

        checkNurseConflict(nurseId, visitDT);

        Lead lead = new Lead(
            FirstName = clientFirstName,
            LastName  = clientLastName,
            Email     = clientEmail,
            Phone     = clientPhone,
            Company   = 'N/A',
            Status    = 'Open - Not Contacted'
        );
        upsert lead Lead.Email;

        Scheduled_Visit__c visit = new Scheduled_Visit__c(
            Nurse__c           = nurseId,
            Lead__c            = lead.Id,
            Action_Centre__c   = centreId,
            Visit_Date_Time__c = visitDT,
            House_Address__c   = houseAddress,
            Notes__c           = notes,
            Status__c          = 'Scheduled',
            Total_Price__c     = unitPrice
        );
        insert visit;

        insert new Visit_Procedure__c(
            Scheduled_Visit__c = visit.Id,
            Procedure__c       = procedureId,
            Unit_Price__c      = unitPrice
        );

        return visit.Id;
    }

    private static void checkNurseConflict(Id nurseId, DateTime visitDT) {
        DateTime windowStart = visitDT.addHours(-1);
        DateTime windowEnd   = visitDT.addHours(1);

        List<Scheduled_Visit__c> conflicts = [
            SELECT Id
            FROM Scheduled_Visit__c
            WHERE Nurse__c = :nurseId
              AND Visit_Date_Time__c >= :windowStart
              AND Visit_Date_Time__c <= :windowEnd
            LIMIT 1
        ];

        if (!conflicts.isEmpty()) {
            throw new AuraHandledException(
                'This nurse already has a visit within 1 hour of the selected time. Please choose a different time or nurse.'
            );
        }
    }
}
