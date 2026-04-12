@IsTest
private class ProcedurePdfControllerTest {

    private static Id procedureRecordTypeId() {
        return [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND DeveloperName = 'Procedure' LIMIT 1].Id;
    }

    private static void setupData(String currencyCode) {
        Action_Centre__c centre = new Action_Centre__c(Name = 'PDF Centre', Type__c = 'Medical Centre');
        insert centre;

        Product2 product = new Product2(
            RecordTypeId = procedureRecordTypeId(),
            Name         = 'Blood Test',
            Description  = 'A routine blood test',
            IsActive     = true
        );
        insert product;

        Id stdPbId = Test.getStandardPricebookId();
        update new Pricebook2(Id = stdPbId, IsActive = true);
        insert new PricebookEntry(Pricebook2Id = stdPbId, Product2Id = product.Id, UnitPrice = 50.00, IsActive = true);

        insert new Centre_Procedure__c(Action_Centre__c = centre.Id, Procedure__c = product.Id);

        if (currencyCode == 'BYN' || currencyCode == 'EUR') {
            insert new CurrencyRate__c(
                SetupOwnerId  = UserInfo.getOrganizationId(),
                USD_to_BYN__c = 3.0,
                EUR_to_BYN__c = 3.5
            );
        }
    }

    @IsTest
    static void constructor_defaultsToUsdWhenNoCurrencyParam() {
        setupData('USD');
        PageReference page = Page.ProceduresPdf;
        Test.setCurrentPage(page);

        Test.startTest();
        ProcedurePdfController ctrl = new ProcedurePdfController();
        Test.stopTest();

        Assert.areEqual('USD', ctrl.selectedCurrency, 'Should default to USD when no currency param');
        Assert.isFalse(ctrl.sections.isEmpty(), 'Should have at least one section');
        Assert.isTrue(ctrl.sections[0].procedures[0].price.startsWith('$'), 'USD price should start with $');
    }

    @IsTest
    static void constructor_selectsBynCurrency() {
        setupData('BYN');
        PageReference page = Page.ProceduresPdf;
        page.getParameters().put('currency', 'BYN');
        Test.setCurrentPage(page);

        Test.startTest();
        ProcedurePdfController ctrl = new ProcedurePdfController();
        Test.stopTest();

        Assert.areEqual('BYN', ctrl.selectedCurrency, 'Should use BYN currency');
        Assert.isTrue(ctrl.sections[0].procedures[0].price.startsWith('BYN'), 'BYN price should start with BYN');
    }

    @IsTest
    static void constructor_selectsEurCurrency() {
        setupData('EUR');
        PageReference page = Page.ProceduresPdf;
        page.getParameters().put('currency', 'EUR');
        Test.setCurrentPage(page);

        Test.startTest();
        ProcedurePdfController ctrl = new ProcedurePdfController();
        Test.stopTest();

        Assert.areEqual('EUR', ctrl.selectedCurrency, 'Should use EUR currency');
        Assert.isTrue(ctrl.sections[0].procedures[0].price.startsWith('€'), 'EUR price should start with €');
    }

    @IsTest
    static void constructor_invalidCurrencyDefaultsToUsd() {
        setupData('USD');
        PageReference page = Page.ProceduresPdf;
        page.getParameters().put('currency', 'GBP');
        Test.setCurrentPage(page);

        Test.startTest();
        ProcedurePdfController ctrl = new ProcedurePdfController();
        Test.stopTest();

        Assert.areEqual('USD', ctrl.selectedCurrency, 'Invalid currency should fall back to USD');
    }

    @IsTest
    static void constructor_emptySectionsWhenNoLinks() {
        PageReference page = Page.ProceduresPdf;
        Test.setCurrentPage(page);

        Test.startTest();
        ProcedurePdfController ctrl = new ProcedurePdfController();
        Test.stopTest();

        Assert.areEqual(0, ctrl.sections.size(), 'No links should produce no sections');
    }

    @IsTest
    static void getPdfBaseUrl_returnsNonBlankUrl() {
        Test.startTest();
        String url = ProcedurePdfController.getPdfBaseUrl();
        Test.stopTest();

        Assert.isTrue(String.isNotBlank(url), 'Base URL should not be blank');
    }

    @IsTest
    static void generatePdf_returnsBase64String() {
        Test.startTest();
        String result = ProcedurePdfController.generatePdf('USD');
        Test.stopTest();

        Assert.isTrue(String.isNotBlank(result), 'generatePdf should return a non-blank base64 string');
    }
}
