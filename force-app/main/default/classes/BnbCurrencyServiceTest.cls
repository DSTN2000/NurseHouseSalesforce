@IsTest
private class BnbCurrencyServiceTest {

    private class SuccessMock implements HttpCalloutMock {
        private final Decimal usdRate;
        private final Decimal eurRate;

        SuccessMock(Decimal usdRate, Decimal eurRate) {
            this.usdRate = usdRate;
            this.eurRate = eurRate;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            if (req.getEndpoint().endsWith('/431')) {
                res.setBody('{"Cur_ID":431,"Cur_Abbreviation":"USD","Cur_Scale":1,"Cur_OfficialRate":' + usdRate + '}');
            } else {
                res.setBody('{"Cur_ID":451,"Cur_Abbreviation":"EUR","Cur_Scale":1,"Cur_OfficialRate":' + eurRate + '}');
            }
            return res;
        }
    }

    private class ErrorMock implements HttpCalloutMock {
        private final Integer statusCode;

        ErrorMock(Integer statusCode) {
            this.statusCode = statusCode;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody('{"error":"Service unavailable"}');
            return res;
        }
    }

    private class MissingFieldMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"Cur_ID":431,"Cur_Abbreviation":"USD"}');
            return res;
        }
    }

    @IsTest
    static void syncRates_persistsCorrectValues() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock(2.9394, 3.3703));

        Test.startTest();
        BnbCurrencyService.syncRates();
        Test.stopTest();

        CurrencyRate__c saved = CurrencyRate__c.getOrgDefaults();
        Assert.areEqual(2.9394, saved.USD_to_BYN__c, 'USD rate should match API response');
        Assert.areEqual(3.3703, saved.EUR_to_BYN__c, 'EUR rate should match API response');
    }

    @IsTest
    static void syncRates_overwritesPreviousValues() {
        insert new CurrencyRate__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            USD_to_BYN__c = 1.0,
            EUR_to_BYN__c = 1.0
        );
        Test.setMock(HttpCalloutMock.class, new SuccessMock(2.9394, 3.3703));

        Test.startTest();
        BnbCurrencyService.syncRates();
        Test.stopTest();

        CurrencyRate__c saved = CurrencyRate__c.getOrgDefaults();
        Assert.areEqual(2.9394, saved.USD_to_BYN__c, 'USD rate should be overwritten');
        Assert.areEqual(3.3703, saved.EUR_to_BYN__c, 'EUR rate should be overwritten');
    }

    @IsTest
    static void syncRates_throwsOnHttpError() {
        Test.setMock(HttpCalloutMock.class, new ErrorMock(503));

        Test.startTest();
        try {
            BnbCurrencyService.syncRates();
            Assert.fail('Expected BnbCalloutException was not thrown');
        } catch (BnbCurrencyService.BnbCalloutException e) {
            Assert.isTrue(e.getMessage().contains('503'), 'Exception message should include HTTP status code');
        }
        Test.stopTest();
    }

    @IsTest
    static void syncRates_throwsWhenRateFieldMissing() {
        Test.setMock(HttpCalloutMock.class, new MissingFieldMock());

        Test.startTest();
        try {
            BnbCurrencyService.syncRates();
            Assert.fail('Expected BnbCalloutException was not thrown');
        } catch (BnbCurrencyService.BnbCalloutException e) {
            Assert.isTrue(e.getMessage().contains('Cur_OfficialRate'), 'Exception message should name the missing field');
        }
        Test.stopTest();
    }

    @IsTest
    static void getCurrentRates_returnsNullWhenNeverSynced() {
        CurrencyRate__c rates = BnbCurrencyService.getCurrentRates();
        Assert.isNull(rates.USD_to_BYN__c, 'USD rate should be null before first sync');
        Assert.isNull(rates.EUR_to_BYN__c, 'EUR rate should be null before first sync');
    }

    @IsTest
    static void getCurrentRates_returnsPersistedValues() {
        insert new CurrencyRate__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            USD_to_BYN__c = 2.5,
            EUR_to_BYN__c = 3.1
        );

        CurrencyRate__c rates = BnbCurrencyService.getCurrentRates();
        Assert.areEqual(2.5, rates.USD_to_BYN__c, 'Should return persisted USD rate');
        Assert.areEqual(3.1, rates.EUR_to_BYN__c, 'Should return persisted EUR rate');
    }

    @IsTest
    static void syncJob_persistsRates() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock(2.9394, 3.3703));

        Test.startTest();
        System.enqueueJob(new BnbCurrencySyncJob());
        Test.stopTest();

        CurrencyRate__c saved = CurrencyRate__c.getOrgDefaults();
        Assert.areEqual(2.9394, saved.USD_to_BYN__c, 'Queueable should have synced USD rate');
        Assert.areEqual(3.3703, saved.EUR_to_BYN__c, 'Queueable should have synced EUR rate');
    }
}