@IsTest
private class ScheduleVisitActionTest {

    private static Id nurseRecordTypeId() {
        return [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Nurse' LIMIT 1].Id;
    }

    private static Id procedureRecordTypeId() {
        return [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND DeveloperName = 'Procedure' LIMIT 1].Id;
    }

    @TestSetup
    static void setup() {
        Action_Centre__c centre = new Action_Centre__c(Name = 'Test Centre', Type__c = 'Medical Centre');
        insert centre;

        Account nurse = new Account(
            RecordTypeId     = nurseRecordTypeId(),
            FirstName        = 'Jane',
            LastName         = 'Doe',
            Action_Centre__c = centre.Id,
            Is_Active__c     = true
        );
        insert nurse;

        Product2 procedure = new Product2(
            RecordTypeId = procedureRecordTypeId(),
            Name         = 'Blood Test',
            IsActive     = true
        );
        insert procedure;

        Id stdPbId = Test.getStandardPricebookId();
        update new Pricebook2(Id = stdPbId, IsActive = true);
        insert new PricebookEntry(
            Pricebook2Id = stdPbId,
            Product2Id   = procedure.Id,
            UnitPrice    = 49.99,
            IsActive     = true
        );
    }

    private static Account getNurse() {
        return [SELECT Id FROM Account WHERE LastName = 'Doe' LIMIT 1];
    }

    private static Action_Centre__c getCentre() {
        return [SELECT Id FROM Action_Centre__c LIMIT 1];
    }

    private static Product2 getProcedure() {
        return [SELECT Id FROM Product2 LIMIT 1];
    }

    @IsTest
    static void scheduleVisit_createsVisitAndLead() {
        Account nurse = getNurse();
        Action_Centre__c centre = getCentre();
        Product2 procedure = getProcedure();
        String visitDT = '2030-06-15T10:00:00.000Z';

        Test.startTest();
        Id visitId = ScheduleVisitAction.scheduleVisit(
            procedure.Id, 49.99, centre.Id, nurse.Id,
            visitDT, '123 Main St', 'No notes',
            'Ivan', 'Sokolov', 'ivan@example.com', '+375291000001'
        );
        Test.stopTest();

        Assert.isNotNull(visitId, 'Visit Id should be returned');

        Scheduled_Visit__c visit = [
            SELECT Id, Nurse__c, Lead__c, Action_Centre__c, Status__c, Total_Price__c, House_Address__c
            FROM Scheduled_Visit__c WHERE Id = :visitId
        ];
        Assert.areEqual(nurse.Id,   visit.Nurse__c,          'Nurse should be linked');
        Assert.areEqual(centre.Id,  visit.Action_Centre__c,  'Centre should be linked');
        Assert.areEqual('Scheduled', visit.Status__c,         'Status should be Scheduled');
        Assert.areEqual(49.99,       visit.Total_Price__c,    'Price should match');
        Assert.areEqual('123 Main St', visit.House_Address__c, 'Address should match');
        Assert.isNotNull(visit.Lead__c, 'Lead should be linked');

        List<Visit_Procedure__c> vps = [SELECT Procedure__c, Unit_Price__c FROM Visit_Procedure__c WHERE Scheduled_Visit__c = :visitId];
        Assert.areEqual(1,           vps.size(),          'One Visit_Procedure__c should be created');
        Assert.areEqual(procedure.Id, vps[0].Procedure__c, 'Procedure should be linked');
        Assert.areEqual(49.99,        vps[0].Unit_Price__c, 'Unit price should match');

        Assert.areEqual(1, [SELECT COUNT() FROM Lead WHERE Email = 'ivan@example.com'], 'One Lead should exist');
    }

    @IsTest
    static void scheduleVisit_reusesExistingLeadByEmail() {
        insert new Lead(
            FirstName = 'Ivan', LastName = 'Sokolov',
            Email = 'ivan@example.com', Company = 'N/A',
            Status = 'Open - Not Contacted'
        );

        Account nurse = getNurse();
        Action_Centre__c centre = getCentre();
        Product2 procedure = getProcedure();

        Test.startTest();
        ScheduleVisitAction.scheduleVisit(
            procedure.Id, 49.99, centre.Id, nurse.Id,
            '2030-06-15T10:00:00.000Z', '123 Main St', null,
            'Ivan', 'Sokolov', 'ivan@example.com', '+375291000001'
        );
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM Lead WHERE Email = 'ivan@example.com'], 'No duplicate Lead should be created');
    }

    @IsTest
    static void scheduleVisit_throwsWhenNurseHasConflictingVisit() {
        Account nurse = getNurse();
        Action_Centre__c centre = getCentre();
        Product2 procedure = getProcedure();

        Lead existingLead = new Lead(LastName = 'Existing', Company = 'N/A', Status = 'Open - Not Contacted');
        insert existingLead;

        DateTime conflictTime = DateTime.newInstanceGmt(2030, 6, 15, 10, 0, 0);
        insert new Scheduled_Visit__c(
            Nurse__c           = nurse.Id,
            Lead__c            = existingLead.Id,
            Action_Centre__c   = centre.Id,
            Visit_Date_Time__c = conflictTime,
            House_Address__c   = '1 Conflict St',
            Status__c          = 'Scheduled',
            Total_Price__c     = 20
        );

        // Request a visit 30 minutes later — within the 1h window
        String conflictingDT = '2030-06-15T10:30:00.000Z';

        Test.startTest();
        try {
            ScheduleVisitAction.scheduleVisit(
                procedure.Id, 49.99, centre.Id, nurse.Id,
                conflictingDT, '456 Other St', null,
                'Elena', 'Morozova', 'elena@example.com', '+375291000002'
            );
            Assert.fail('Expected AuraHandledException was not thrown');
        } catch (AuraHandledException e) {
            Assert.isTrue(
                e.getMessage() != null,
                'AuraHandledException should have been thrown'
            );
        }
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM Scheduled_Visit__c], 'No new visit should have been created');
    }

    @IsTest
    static void scheduleVisit_allowsVisitOutsideConflictWindow() {
        Account nurse = getNurse();
        Action_Centre__c centre = getCentre();
        Product2 procedure = getProcedure();

        Lead existingLead = new Lead(LastName = 'Existing', Company = 'N/A', Status = 'Open - Not Contacted');
        insert existingLead;

        DateTime existingTime = DateTime.newInstanceGmt(2030, 6, 15, 10, 0, 0);
        insert new Scheduled_Visit__c(
            Nurse__c           = nurse.Id,
            Lead__c            = existingLead.Id,
            Action_Centre__c   = centre.Id,
            Visit_Date_Time__c = existingTime,
            House_Address__c   = '1 Safe St',
            Status__c          = 'Scheduled',
            Total_Price__c     = 20
        );

        // Request a visit exactly 61 minutes later — outside the 1h window
        String safeDT = '2030-06-15T11:01:00.000Z';

        Test.startTest();
        Id visitId = ScheduleVisitAction.scheduleVisit(
            procedure.Id, 49.99, centre.Id, nurse.Id,
            safeDT, '789 New St', null,
            'Pavel', 'Fedorov', 'pavel@example.com', '+375291000003'
        );
        Test.stopTest();

        Assert.isNotNull(visitId, 'Visit outside conflict window should be created');
        Assert.areEqual(2, [SELECT COUNT() FROM Scheduled_Visit__c], 'Two visits should exist');
    }
}
