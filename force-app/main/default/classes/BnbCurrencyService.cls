/**
 * Fetches USD and EUR official rates from the Belarusian National Bank (BNB) API
 * and persists them in the CurrencyRate__c Custom Setting.
 *
 * BNB endpoints used:
 *   GET /exrates/rates/431  →  USD
 *   GET /exrates/rates/451  →  EUR
 */
public with sharing class BnbCurrencyService {

    private static final String NAMED_CREDENTIAL = 'callout:BNB_API';
    private static final String USD_PATH = '/exrates/rates/431';
    private static final String EUR_PATH = '/exrates/rates/451';
    private static final String RATE_FIELD   = 'Cur_OfficialRate';

    /**
     * Fetches both rates and upserts the org-level CurrencyRate__c record.
     * Throws BnbCalloutException if either callout fails or returns a bad status.
     */
    public static void syncRates() {
        Decimal usdRate = fetchRate(USD_PATH, 'USD');
        Decimal eurRate = fetchRate(EUR_PATH, 'EUR');
        persistRates(usdRate, eurRate);
    }

    /**
     * Returns the current org-level rates, or null if never synced.
     */
    public static CurrencyRate__c getCurrentRates() {
        return CurrencyRate__c.getOrgDefaults();
    }

    // Helpers

    private static Decimal fetchRate(String path, String currencyCode) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + path);
        req.setMethod('GET');
        req.setTimeout(10000);

        HttpResponse res = new Http().send(req);

        if (res.getStatusCode() != 200) {
            throw new BnbCalloutException(
                'BNB API returned ' + res.getStatusCode() +
                ' for ' + currencyCode + ': ' + res.getBody()
            );
        }

        Map<String, Object> payload =
            (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

        if (!payload.containsKey(RATE_FIELD) || payload.get(RATE_FIELD) == null) {
            throw new BnbCalloutException(
                'BNB API response missing ' + RATE_FIELD + ' for ' + currencyCode
            );
        }

        return (Decimal) payload.get(RATE_FIELD);
    }

    private static void persistRates(Decimal usdRate, Decimal eurRate) {
        if (!Schema.sObjectType.CurrencyRate__c.isCreateable() ||
            !Schema.sObjectType.CurrencyRate__c.isUpdateable()) {
            throw new BnbCalloutException(
                'Insufficient permissions to write CurrencyRate__c'
            );
        }
        CurrencyRate__c setting = CurrencyRate__c.getOrgDefaults();
        setting.USD_to_BYN__c = usdRate;
        setting.EUR_to_BYN__c = eurRate;
        upsert setting;
    }

    public class BnbCalloutException extends Exception {}
}
