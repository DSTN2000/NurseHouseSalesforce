public without sharing class ProcedurePdfController {

    public String selectedCurrency { get; private set; }
    public List<CentreSection> sections { get; private set; }

    public class CentreSection {
        public String centreName { get; set; }
        public List<ProcedureRow> procedures { get; set; }
    }

    public class ProcedureRow {
        public String name { get; set; }
        public String description { get; set; }
        public String price { get; set; }
    }

    public ProcedurePdfController() {
        selectedCurrency = ApexPages.currentPage().getParameters().get('currency');
        if (selectedCurrency == null || (!selectedCurrency.equals('BYN') && !selectedCurrency.equals('EUR'))) {
            selectedCurrency = 'USD';
        }

        CurrencyRate__c rates = BnbCurrencyService.getCurrentRates();
        Decimal usdToByn = rates != null ? rates.USD_to_BYN__c : null;
        Decimal eurToByn = rates != null ? rates.EUR_to_BYN__c : null;

        // Fetch all centre-procedure links with names
        List<Centre_Procedure__c> links = [
            SELECT Action_Centre__c, Action_Centre__r.Name,
                   Procedure__c, Procedure__r.Name, Procedure__r.Description
            FROM Centre_Procedure__c
            WHERE Action_Centre__c != NULL AND Procedure__c != NULL
            ORDER BY Action_Centre__r.Name ASC, Procedure__r.Name ASC
        ];

        // Fetch prices from standard pricebook
        Set<Id> productIds = new Set<Id>();
        for (Centre_Procedure__c cp : links) {
            productIds.add(cp.Procedure__c);
        }
        Map<Id, Decimal> priceByProductId = new Map<Id, Decimal>();
        for (PricebookEntry pbe : [
            SELECT Product2Id, UnitPrice FROM PricebookEntry
            WHERE Product2Id IN :productIds AND Pricebook2.IsStandard = TRUE
        ]) {
            priceByProductId.put(pbe.Product2Id, pbe.UnitPrice);
        }

        // Group by centre
        sections = new List<CentreSection>();
        Map<Id, CentreSection> sectionMap = new Map<Id, CentreSection>();
        for (Centre_Procedure__c cp : links) {
            if (!sectionMap.containsKey(cp.Action_Centre__c)) {
                CentreSection s = new CentreSection();
                s.centreName = cp.Action_Centre__r.Name;
                s.procedures = new List<ProcedureRow>();
                sectionMap.put(cp.Action_Centre__c, s);
                sections.add(s);
            }
            Decimal usdPrice = priceByProductId.get(cp.Procedure__c);
            ProcedureRow row = new ProcedureRow();
            row.name = cp.Procedure__r.Name;
            row.description = cp.Procedure__r.Description;
            row.price = formatPrice(usdPrice, selectedCurrency, usdToByn, eurToByn);
            sectionMap.get(cp.Action_Centre__c).procedures.add(row);
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getPdfBaseUrl() {
        return URL.getOrgDomainUrl().toExternalForm();
    }

    private static String formatPrice(Decimal usdPrice, String cur, Decimal usdToByn, Decimal eurToByn) {
        if (usdPrice == null) return '-';
        if (cur == 'BYN' && usdToByn != null) {
            return 'BYN ' + (usdPrice * usdToByn).setScale(2);
        }
        if (cur == 'EUR' && usdToByn != null && eurToByn != null) {
            return '€' + (usdPrice * (usdToByn / eurToByn)).setScale(2);
        }
        return '$' + usdPrice.setScale(2);
    }
}
