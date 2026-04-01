/**
 * Queueable that performs the BNB API callouts and persists the rates.
 */
public with sharing class BnbCurrencySyncJob implements Queueable, Database.AllowsCallouts {

    public void execute(QueueableContext ctx) {
        BnbCurrencyService.syncRates();
    }
}
