/**
 * Schedulable entry point for daily BNB currency rate sync.
 * Delegates to BnbCurrencySyncJob (Queueable) because callouts
 * are not permitted directly inside Schedulable.execute().
 *
 * To schedule daily at midnight via Anonymous Apex:
 *   System.schedule('BNB Daily Rate Sync', '0 0 0 * * ?', new BnbCurrencyScheduler());
 */
public with sharing class BnbCurrencyScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        System.enqueueJob(new BnbCurrencySyncJob());
    }
}
