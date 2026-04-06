@IsTest
private class CaseCreationActionTest {

    @IsTest
    static void createCase_createsWithAllFields() {
        CaseCreationAction.CaseInput input = new CaseCreationAction.CaseInput();
        input.subject       = 'Test Subject';
        input.description   = 'Test Description';
        input.suppliedName  = 'Dan Soltan';
        input.suppliedEmail = 'dan@example.com';

        Test.startTest();
        CaseCreationAction.createCase(new List<CaseCreationAction.CaseInput>{ input });
        Test.stopTest();

        List<Case> cases = [SELECT Id, Subject, Description, SuppliedName, SuppliedEmail, Origin, Status FROM Case];
        Assert.areEqual(1, cases.size(), 'Expected one Case to be created');
        Assert.areEqual('Test Subject', cases[0].Subject, 'Subject should match input');
        Assert.areEqual('Test Description', cases[0].Description, 'Description should match input');
        Assert.areEqual('Dan Soltan', cases[0].SuppliedName, 'SuppliedName should match input');
        Assert.areEqual('dan@example.com', cases[0].SuppliedEmail, 'SuppliedEmail should match input');
        Assert.areEqual('Web', cases[0].Origin, 'Origin should be Web');
        Assert.areEqual('New', cases[0].Status, 'Status should be New');
    }

    @IsTest
    static void createCase_handlesNullOptionalFields() {
        CaseCreationAction.CaseInput input = new CaseCreationAction.CaseInput();
        input.subject       = 'No Description Case';
        input.description   = null;
        input.suppliedName  = 'Anonymous';
        input.suppliedEmail = null;

        Test.startTest();
        CaseCreationAction.createCase(new List<CaseCreationAction.CaseInput>{ input });
        Test.stopTest();

        List<Case> cases = [SELECT Id, Subject, SuppliedName FROM Case];
        Assert.areEqual(1, cases.size(), 'Expected one Case to be created');
        Assert.areEqual('No Description Case', cases[0].Subject, 'Subject should match input');
        Assert.areEqual('Anonymous', cases[0].SuppliedName, 'SuppliedName should match input');
    }

    @IsTest
    static void createCase_bulkCreatesAllCases() {
        List<CaseCreationAction.CaseInput> inputs = new List<CaseCreationAction.CaseInput>();
        for (Integer i = 0; i < 5; i++) {
            CaseCreationAction.CaseInput inp = new CaseCreationAction.CaseInput();
            inp.subject       = 'Bulk Case ' + i;
            inp.description   = 'Bulk Description ' + i;
            inp.suppliedName  = 'User ' + i;
            inp.suppliedEmail = 'user' + i + '@example.com';
            inputs.add(inp);
        }

        Test.startTest();
        CaseCreationAction.createCase(inputs);
        Test.stopTest();

        Assert.areEqual(5, [SELECT COUNT() FROM Case], 'Expected 5 Cases to be created');
    }
}
