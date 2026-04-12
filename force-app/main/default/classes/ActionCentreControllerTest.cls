@IsTest
private class ActionCentreControllerTest {

    @TestSetup
    static void setup() {
        OperatingHours oh = new OperatingHours(Name = 'Test Hours', TimeZone = 'America/New_York');
        insert oh;

        insert new TimeSlot(
            OperatingHoursId = oh.Id,
            DayOfWeek        = 'Monday',
            StartTime        = Time.newInstance(9, 0, 0, 0),
            EndTime          = Time.newInstance(17, 0, 0, 0)
        );

        insert new Action_Centre__c(
            Name        = 'Test Centre',
            Type__c     = 'Medical Centre',
            Work_Time__c = oh.Id
        );
    }

    @IsTest
    static void getActionCentre_returnsWrapperWithTimeSlots() {
        Action_Centre__c centre = [SELECT Id FROM Action_Centre__c LIMIT 1];

        Test.startTest();
        ActionCentreController.CentreWrapper result = ActionCentreController.getActionCentre(centre.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Should return a wrapper');
        Assert.areEqual('Test Centre', result.centre.Name, 'Centre name should match');
        Assert.areEqual(1, result.timeSlots.size(), 'Should return one time slot');
        Assert.areEqual('Monday', result.timeSlots[0].DayOfWeek, 'Day of week should match');
    }

    @IsTest
    static void getActionCentre_returnsNullForNullId() {
        Test.startTest();
        ActionCentreController.CentreWrapper result = ActionCentreController.getActionCentre(null);
        Test.stopTest();

        Assert.isNull(result, 'Should return null for null recordId');
    }

    @IsTest
    static void getActionCentre_returnsNullForDeletedRecord() {
        Action_Centre__c centre = [SELECT Id FROM Action_Centre__c LIMIT 1];
        Id centreId = centre.Id;
        delete centre;

        Test.startTest();
        ActionCentreController.CentreWrapper result = ActionCentreController.getActionCentre(centreId);
        Test.stopTest();

        Assert.isNull(result, 'Should return null when no record is found');
    }

    @IsTest
    static void getActionCentre_returnsEmptySlotsWhenNoOperatingHours() {
        Action_Centre__c noOhCentre = new Action_Centre__c(Name = 'No Hours Centre', Type__c = 'Client Support Centre');
        insert noOhCentre;

        Test.startTest();
        ActionCentreController.CentreWrapper result = ActionCentreController.getActionCentre(noOhCentre.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Should return a wrapper even without operating hours');
        Assert.areEqual(0, result.timeSlots.size(), 'Should return empty time slots when no operating hours');
    }

    @IsTest
    static void getActionCentres_returnsAllCentresWithSlots() {
        Test.startTest();
        List<ActionCentreController.CentreWrapper> results = ActionCentreController.getActionCentres();
        Test.stopTest();

        Assert.isFalse(results.isEmpty(), 'Should return at least one centre');
        // Find our test centre
        ActionCentreController.CentreWrapper testWrapper = null;
        for (ActionCentreController.CentreWrapper w : results) {
            if (w.centre.Name == 'Test Centre') {
                testWrapper = w;
            }
        }
        Assert.isNotNull(testWrapper, 'Test Centre should be in results');
        Assert.areEqual(1, testWrapper.timeSlots.size(), 'Test Centre should have one time slot');
    }

    @IsTest
    static void getActionCentres_returnsEmptySlotsForCentreWithNoOperatingHours() {
        insert new Action_Centre__c(Name = 'No Hours Centre', Type__c = 'Client Support Centre');

        Test.startTest();
        List<ActionCentreController.CentreWrapper> results = ActionCentreController.getActionCentres();
        Test.stopTest();

        for (ActionCentreController.CentreWrapper w : results) {
            if (w.centre.Name == 'No Hours Centre') {
                Assert.areEqual(0, w.timeSlots.size(), 'Centre without operating hours should have empty slots');
            }
        }
    }
}
