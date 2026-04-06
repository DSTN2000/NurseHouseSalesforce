@IsTest
private class ProcedureControllerTest {

    private static Id nurseRecordTypeId() {
        return [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Nurse' LIMIT 1].Id;
    }

    private static Action_Centre__c createCentre() {
        Action_Centre__c centre = new Action_Centre__c(Name = 'Test Centre', Type__c = 'Medical Centre');
        insert centre;
        return centre;
    }

    private static Account createNurse(Id centreId) {
        Account nurse = new Account(
            RecordTypeId   = nurseRecordTypeId(),
            FirstName      = 'Jane',
            LastName       = 'Doe',
            Action_Centre__c = centreId,
            Is_Active__c   = true
        );
        insert nurse;
        return nurse;
    }

    private static Id procedureRecordTypeId() {
        return [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND DeveloperName = 'Procedure' LIMIT 1].Id;
    }

    private static Product2 createProduct(String name) {
        Product2 p = new Product2(RecordTypeId = procedureRecordTypeId(), Name = name, IsActive = true);
        insert p;
        return p;
    }

    private static void addStandardPricebookEntry(Id productId, Decimal price) {
        Id stdPbId = Test.getStandardPricebookId();
        update new Pricebook2(Id = stdPbId, IsActive = true);
        insert new PricebookEntry(
            Pricebook2Id = stdPbId,
            Product2Id   = productId,
            UnitPrice    = price,
            IsActive     = true
        );
    }

    @IsTest
    static void getProcedures_returnsActiveProductsWithPrice() {
        Product2 p = createProduct('Blood Test');
        addStandardPricebookEntry(p.Id, 49.99);

        Test.startTest();
        List<PricebookEntry> results = ProcedureController.getProcedures();
        Test.stopTest();

        Assert.isFalse(results.isEmpty(), 'Should return at least one PricebookEntry');
        PricebookEntry entry = results[0];
        Assert.areEqual('Blood Test', entry.Product2.Name, 'Product name should match');
        Assert.areEqual(49.99, entry.UnitPrice, 'UnitPrice should match inserted value');
    }

    @IsTest
    static void getProcedures_excludesInactiveProducts() {
        Product2 active = createProduct('Active Procedure');
        addStandardPricebookEntry(active.Id, 10.00);

        Product2 inactive = new Product2(RecordTypeId = procedureRecordTypeId(), Name = 'Inactive Procedure', IsActive = false);
        insert inactive;
        addStandardPricebookEntry(inactive.Id, 5.00);

        Test.startTest();
        List<PricebookEntry> results = ProcedureController.getProcedures();
        Test.stopTest();

        for (PricebookEntry e : results) {
            Assert.areNotEqual('Inactive Procedure', e.Product2.Name, 'Inactive products should not be returned');
        }
    }

    @IsTest
    static void getProcedures_returnsEmptyListWhenNoProcedures() {
        Test.startTest();
        List<PricebookEntry> results = ProcedureController.getProcedures();
        Test.stopTest();

        Assert.areEqual(0, results.size(), 'Should return empty list when no products exist');
    }

    @IsTest
    static void getNursesByActionCentre_returnsNursesForCentre() {
        Action_Centre__c centre = createCentre();
        createNurse(centre.Id);

        Test.startTest();
        List<Account> nurses = ProcedureController.getNursesByActionCentre(centre.Id);
        Test.stopTest();

        Assert.areEqual(1, nurses.size(), 'Should return one nurse for the centre');
        Assert.areEqual('Jane Doe', nurses[0].Name, 'Nurse name should match');
    }

    @IsTest
    static void getNursesByActionCentre_doesNotReturnNursesFromOtherCentres() {
        Action_Centre__c centreA = createCentre();
        Action_Centre__c centreB = new Action_Centre__c(Name = 'Centre B', Type__c = 'Client Support Centre');
        insert centreB;
        createNurse(centreA.Id);

        Test.startTest();
        List<Account> nurses = ProcedureController.getNursesByActionCentre(centreB.Id);
        Test.stopTest();

        Assert.areEqual(0, nurses.size(), 'Should not return nurses from a different centre');
    }

    @IsTest
    static void getNursesByActionCentre_returnsEmptyListForNullId() {
        Test.startTest();
        List<Account> nurses = ProcedureController.getNursesByActionCentre(null);
        Test.stopTest();

        Assert.areEqual(0, nurses.size(), 'Should return empty list for null centreId');
    }

    @IsTest
    static void getCurrencyRates_returnsStoredRates() {
        insert new CurrencyRate__c(
            SetupOwnerId  = UserInfo.getOrganizationId(),
            USD_to_BYN__c = 3.27,
            EUR_to_BYN__c = 3.56
        );

        Test.startTest();
        CurrencyRate__c rates = ProcedureController.getCurrencyRates();
        Test.stopTest();

        Assert.areEqual(3.27, rates.USD_to_BYN__c, 'USD rate should match stored value');
        Assert.areEqual(3.56, rates.EUR_to_BYN__c, 'EUR rate should match stored value');
    }
}
