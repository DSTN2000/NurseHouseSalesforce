public without sharing class ProcedureController {

    private static final String PROCEDURE_RT_NAME = 'Procedure';

    @AuraEnabled(cacheable=true)
    public static List<PricebookEntry> getProcedures() {
        List<RecordType> rts = [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'Product2' AND DeveloperName = :PROCEDURE_RT_NAME
            LIMIT 1
        ];
        if (rts.isEmpty()) {
            return new List<PricebookEntry>();
        }
        Id procedureRtId = rts[0].Id;
        return [
            SELECT Id,
                   Product2Id,
                   Product2.Name,
                   Product2.Description,
                   Product2.Family,
                   UnitPrice
            FROM PricebookEntry
            WHERE Pricebook2.IsStandard = TRUE
              AND Product2.IsActive = TRUE
              AND Product2.RecordTypeId = :procedureRtId
            ORDER BY Product2.Name ASC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> getNursesByActionCentre(Id centreId) {
        if (centreId == null) {
            return new List<Account>();
        }
        return [
            SELECT Id, Name, Phone
            FROM Account
            WHERE Action_Centre__c = :centreId
              AND IsPersonAccount = TRUE
              AND Is_Active__c = TRUE
            ORDER BY Name ASC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Centre_Procedure__c> getCentreProcedures() {
        return [
            SELECT Id, Action_Centre__c, Procedure__c
            FROM Centre_Procedure__c
            WHERE Action_Centre__c != NULL
              AND Procedure__c != NULL
        ];
    }

    @AuraEnabled(cacheable=true)
    public static CurrencyRate__c getCurrencyRates() {
        return BnbCurrencyService.getCurrentRates();
    }
}
