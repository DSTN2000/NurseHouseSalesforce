Id stdPbId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;

List<Action_Centre__c> centres = new List<Action_Centre__c>{
    new Action_Centre__c(
        Name = 'City Medical Centre',
        Type__c = 'Medical Centre',
        Street__c = 'Wall Street',
        City__c = 'New York',
        Country__c = 'United States',
        Latitude__c = 40.7058089,
        Longitude__c = -74.0084337,
        Description__c = 'Full-service medical centre providing professional nursing care.'
    ),
    new Action_Centre__c(
        Name = 'Central Client Support Centre',
        Type__c = 'Client Support Centre',
        Street__c = 'Broadway',
        City__c = 'New York',
        Country__c = 'United States',
        Latitude__c = 40.7079284,
        Longitude__c = -74.0114693,
        Description__c = 'Client support centre for consultations and service requests.',
        Phone__c = '+12125550001',
        Email__c = 'support@nursehouse.com'
    )
};
upsert centres;

Id nurseRtId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Nurse' LIMIT 1].Id;
List<Account> nurses = new List<Account>{
    new Account(RecordTypeId = nurseRtId, LastName = 'Kovalenko', FirstName = 'Anna',   Phone = '+375291111111'),
    new Account(RecordTypeId = nurseRtId, LastName = 'Ivanova',   FirstName = 'Maria',  Phone = '+375292222222'),
    new Account(RecordTypeId = nurseRtId, LastName = 'Petrov',    FirstName = 'Sergei', Phone = '+375293333333')
};
upsert nurses;

Id procRtId = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND DeveloperName = 'Procedure' LIMIT 1].Id;
List<Product2> procedures = new List<Product2>{
    new Product2(RecordTypeId = procRtId, Name = 'Blood Pressure Check',  IsActive = true),
    new Product2(RecordTypeId = procRtId, Name = 'Wound Dressing',        IsActive = true),
    new Product2(RecordTypeId = procRtId, Name = 'Injection',             IsActive = true),
    new Product2(RecordTypeId = procRtId, Name = 'Blood Sugar Test',      IsActive = true),
    new Product2(RecordTypeId = procRtId, Name = 'Physiotherapy Session', IsActive = true)
};
upsert procedures;

List<PricebookEntry> entries = new List<PricebookEntry>();
Decimal[] prices = new Decimal[]{ 20, 35, 25, 15, 50 };
for (Integer i = 0; i < procedures.size(); i++) {
    entries.add(new PricebookEntry(Pricebook2Id = stdPbId, Product2Id = procedures[i].Id, UnitPrice = prices[i], IsActive = true));
}
upsert entries;

List<Lead> leads = new List<Lead>{
    new Lead(FirstName = 'Ivan',  LastName = 'Sokolov',  Company = 'N/A', Phone = '+375291000001'),
    new Lead(FirstName = 'Elena', LastName = 'Morozova', Company = 'N/A', Phone = '+375291000002'),
    new Lead(FirstName = 'Pavel', LastName = 'Fedorov',  Company = 'N/A', Phone = '+375291000003')
};
upsert leads;

DateTime base = DateTime.now();
List<Scheduled_Visit__c> visits = new List<Scheduled_Visit__c>{
    new Scheduled_Visit__c(Nurse__c = nurses[0].Id, Lead__c = leads[0].Id, Action_Centre__c = centres[0].Id, Visit_Date_Time__c = base,            Status__c = 'Completed', Total_Price__c = 55),
    new Scheduled_Visit__c(Nurse__c = nurses[0].Id, Lead__c = leads[1].Id, Action_Centre__c = centres[0].Id, Visit_Date_Time__c = base.addDays(1), Status__c = 'Completed', Total_Price__c = 35),
    new Scheduled_Visit__c(Nurse__c = nurses[1].Id, Lead__c = leads[2].Id, Action_Centre__c = centres[1].Id, Visit_Date_Time__c = base.addDays(2), Status__c = 'Completed', Total_Price__c = 25),
    new Scheduled_Visit__c(Nurse__c = nurses[1].Id, Lead__c = leads[0].Id, Action_Centre__c = centres[1].Id, Visit_Date_Time__c = base.addDays(3), Status__c = 'Scheduled', Total_Price__c = 70),
    new Scheduled_Visit__c(Nurse__c = nurses[2].Id, Lead__c = leads[1].Id, Action_Centre__c = centres[0].Id, Visit_Date_Time__c = base.addDays(4), Status__c = 'Completed', Total_Price__c = 50)
};
upsert visits;

List<Visit_Procedure__c> vps = new List<Visit_Procedure__c>{
    new Visit_Procedure__c(Scheduled_Visit__c = visits[0].Id, Procedure__c = procedures[0].Id, Unit_Price__c = 20),
    new Visit_Procedure__c(Scheduled_Visit__c = visits[0].Id, Procedure__c = procedures[2].Id, Unit_Price__c = 25),
    new Visit_Procedure__c(Scheduled_Visit__c = visits[0].Id, Procedure__c = procedures[3].Id, Unit_Price__c = 15),
    new Visit_Procedure__c(Scheduled_Visit__c = visits[1].Id, Procedure__c = procedures[1].Id, Unit_Price__c = 35),
    new Visit_Procedure__c(Scheduled_Visit__c = visits[2].Id, Procedure__c = procedures[2].Id, Unit_Price__c = 25),
    new Visit_Procedure__c(Scheduled_Visit__c = visits[3].Id, Procedure__c = procedures[0].Id, Unit_Price__c = 20),
    new Visit_Procedure__c(Scheduled_Visit__c = visits[3].Id, Procedure__c = procedures[4].Id, Unit_Price__c = 50),
    new Visit_Procedure__c(Scheduled_Visit__c = visits[4].Id, Procedure__c = procedures[3].Id, Unit_Price__c = 15),
    new Visit_Procedure__c(Scheduled_Visit__c = visits[4].Id, Procedure__c = procedures[2].Id, Unit_Price__c = 25)
};
upsert vps;

System.debug('Seed complete: 3 nurses, 5 procedures, 5 visits, 9 visit-procedures');
