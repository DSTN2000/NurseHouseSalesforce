@IsTest
private class CaseTriggerHandlerTest {

    @IsTest
    static void webCase_withName_buildsPersonalisedEmail() {
        insert new Case(Subject = 'I need help', SuppliedName = 'Anna Kovalenko', SuppliedEmail = 'anna@example.com', Origin = 'Web', Status = 'New');
        Case c = [SELECT Id, Subject, SuppliedName, SuppliedEmail, Origin, CaseNumber FROM Case LIMIT 1];

        List<Messaging.SingleEmailMessage> emails = CaseTriggerHandler.buildEmails(new List<Case>{ c });

        Assert.areEqual(1, emails.size(), 'Expected one email');
        Assert.areEqual('anna@example.com', emails[0].getToAddresses()[0], 'Wrong recipient');
        Assert.isTrue(emails[0].getHtmlBody().contains('Dear Anna Kovalenko,'), 'Should address customer by name');
        Assert.isTrue(emails[0].getHtmlBody().contains(c.CaseNumber), 'Should include case number');
    }

    @IsTest
    static void webCase_withoutName_buildsGenericGreeting() {
        insert new Case(Subject = 'Anonymous enquiry', SuppliedEmail = 'anon@example.com', Origin = 'Web', Status = 'New');
        Case c = [SELECT Id, Subject, SuppliedName, SuppliedEmail, Origin, CaseNumber FROM Case LIMIT 1];

        List<Messaging.SingleEmailMessage> emails = CaseTriggerHandler.buildEmails(new List<Case>{ c });

        Assert.areEqual(1, emails.size(), 'Expected one email');
        Assert.isTrue(emails[0].getHtmlBody().contains('Dear Customer,'), 'Should fall back to generic greeting');
    }

    @IsTest
    static void multipleCases_buildsOneEmailEach() {
        insert new List<Case>{
            new Case(Subject = 'A', SuppliedEmail = 'a@example.com', Origin = 'Web',   Status = 'New'),
            new Case(Subject = 'B', SuppliedEmail = 'b@example.com', Origin = 'Email', Status = 'New')
        };
        List<Case> cases = [SELECT Id, Subject, SuppliedName, SuppliedEmail, Origin, CaseNumber FROM Case];

        List<Messaging.SingleEmailMessage> emails = CaseTriggerHandler.buildEmails(cases);

        Assert.areEqual(2, emails.size(), 'Expected one email per case');
    }

    @IsTest
    static void insertWebCase_withEmail_doesNotThrow() {
        Test.startTest();
        insert new Case(Subject = 'Web enquiry', SuppliedName = 'Ivan Sokolov', SuppliedEmail = 'ivan@example.com', Origin = 'Web', Status = 'New');
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM Case], 'Case should be persisted');
    }

    @IsTest
    static void insertEmailCase_withEmail_doesNotThrow() {
        Test.startTest();
        insert new Case(Subject = 'Email enquiry', SuppliedName = 'Elena Morozova', SuppliedEmail = 'elena@example.com', Origin = 'Email', Status = 'New');
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM Case], 'Case should be persisted');
    }

    @IsTest
    static void insertCaseWithoutEmail_doesNotThrow() {
        Test.startTest();
        insert new Case(Subject = 'No email', Origin = 'Web', Status = 'New');
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM Case], 'Case should still be created when email is blank');
    }

    @IsTest
    static void insertPhoneCase_doesNotThrow() {
        Test.startTest();
        insert new Case(Subject = 'Phone enquiry', SuppliedEmail = 'phone@example.com', Origin = 'Phone', Status = 'New');
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM Case], 'Case should still be created for non-Web/Email origin');
    }

    @IsTest
    static void bulkInsert_doesNotThrow() {
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < 10; i++) {
            cases.add(new Case(Subject = 'Bulk Case ' + i, SuppliedName = 'User ' + i, SuppliedEmail = 'user' + i + '@example.com', Origin = 'Web', Status = 'New'));
        }

        Test.startTest();
        insert cases;
        Test.stopTest();

        Assert.areEqual(10, [SELECT COUNT() FROM Case], 'All 10 cases should be persisted');
    }
}
