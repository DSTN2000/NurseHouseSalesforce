@IsTest
private class BnbCurrencySchedulerTest {

    private class SuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            if (req.getEndpoint().endsWith('/431')) {
                res.setBody('{"Cur_OfficialRate":2.9394}');
            } else {
                res.setBody('{"Cur_OfficialRate":3.3703}');
            }
            return res;
        }
    }

    @IsTest
    static void execute_enqueuesSync() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        new BnbCurrencyScheduler().execute(null);
        Test.stopTest();

        CurrencyRate__c saved = CurrencyRate__c.getOrgDefaults();
        Assert.areEqual(2.9394, saved.USD_to_BYN__c, 'Scheduler should enqueue job that syncs USD rate');
        Assert.areEqual(3.3703, saved.EUR_to_BYN__c, 'Scheduler should enqueue job that syncs EUR rate');
    }

    @IsTest
    static void schedule_runsViaSystem() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        String jobId = System.schedule('Test BNB Sync', '0 0 0 * * ?', new BnbCurrencyScheduler());
        Test.stopTest();

        Assert.isNotNull(jobId, 'Scheduled job should return a job Id');
    }
}
