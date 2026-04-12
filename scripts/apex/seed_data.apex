// Wipe existing seed data
delete [SELECT Id FROM Visit_Procedure__c LIMIT 200];
delete [SELECT Id FROM Scheduled_Visit__c LIMIT 200];
delete [SELECT Id FROM Lead WHERE Company = 'N/A' LIMIT 200];
delete [SELECT Id FROM Centre_Procedure__c LIMIT 200];

Id nurseRtIdClean = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Nurse' LIMIT 1].Id;
delete [SELECT Id FROM Account WHERE RecordTypeId = :nurseRtIdClean LIMIT 200];

delete [SELECT Id FROM Action_Centre__c LIMIT 200];

Id procRtIdClean = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND DeveloperName = 'Procedure' LIMIT 1].Id;
List<Product2> oldProcs = [SELECT Id FROM Product2 WHERE RecordTypeId = :procRtIdClean LIMIT 200];
List<PricebookEntry> oldEntries = [SELECT Id FROM PricebookEntry WHERE Product2Id IN :oldProcs LIMIT 200];
delete oldEntries;
delete oldProcs;

delete [SELECT Id FROM OperatingHours WHERE Name LIKE 'Nurse House%' LIMIT 200];

// Operating Hours
List<OperatingHours> opHours = new List<OperatingHours>{
    new OperatingHours(Name = 'Nurse House Medical Centre Hours',  TimeZone = 'America/New_York'),
    new OperatingHours(Name = 'Nurse House Client Support Hours',  TimeZone = 'America/New_York')
};
insert opHours;

// Time Slots — Medical Centre: Mon–Sat 08:00–18:00
List<TimeSlot> timeSlots = new List<TimeSlot>{
    new TimeSlot(OperatingHoursId = opHours[0].Id, DayOfWeek = 'Monday',    StartTime = Time.newInstance(8, 0, 0, 0), EndTime = Time.newInstance(18, 0, 0, 0)),
    new TimeSlot(OperatingHoursId = opHours[0].Id, DayOfWeek = 'Tuesday',   StartTime = Time.newInstance(8, 0, 0, 0), EndTime = Time.newInstance(18, 0, 0, 0)),
    new TimeSlot(OperatingHoursId = opHours[0].Id, DayOfWeek = 'Wednesday', StartTime = Time.newInstance(8, 0, 0, 0), EndTime = Time.newInstance(18, 0, 0, 0)),
    new TimeSlot(OperatingHoursId = opHours[0].Id, DayOfWeek = 'Thursday',  StartTime = Time.newInstance(8, 0, 0, 0), EndTime = Time.newInstance(18, 0, 0, 0)),
    new TimeSlot(OperatingHoursId = opHours[0].Id, DayOfWeek = 'Friday',    StartTime = Time.newInstance(8, 0, 0, 0), EndTime = Time.newInstance(18, 0, 0, 0)),
    new TimeSlot(OperatingHoursId = opHours[0].Id, DayOfWeek = 'Saturday',  StartTime = Time.newInstance(9, 0, 0, 0), EndTime = Time.newInstance(14, 0, 0, 0)),
    // Time Slots — Client Support: Mon–Fri 09:00–17:00
    new TimeSlot(OperatingHoursId = opHours[1].Id, DayOfWeek = 'Monday',    StartTime = Time.newInstance(9, 0, 0, 0), EndTime = Time.newInstance(17, 0, 0, 0)),
    new TimeSlot(OperatingHoursId = opHours[1].Id, DayOfWeek = 'Tuesday',   StartTime = Time.newInstance(9, 0, 0, 0), EndTime = Time.newInstance(17, 0, 0, 0)),
    new TimeSlot(OperatingHoursId = opHours[1].Id, DayOfWeek = 'Wednesday', StartTime = Time.newInstance(9, 0, 0, 0), EndTime = Time.newInstance(17, 0, 0, 0)),
    new TimeSlot(OperatingHoursId = opHours[1].Id, DayOfWeek = 'Thursday',  StartTime = Time.newInstance(9, 0, 0, 0), EndTime = Time.newInstance(17, 0, 0, 0)),
    new TimeSlot(OperatingHoursId = opHours[1].Id, DayOfWeek = 'Friday',    StartTime = Time.newInstance(9, 0, 0, 0), EndTime = Time.newInstance(17, 0, 0, 0))
};
insert timeSlots;

// Action Centres 
List<Action_Centre__c> centres = new List<Action_Centre__c>{
    new Action_Centre__c(
        Name        = 'City Medical Centre',
        Type__c     = 'Medical Centre',
        Street__c   = 'Wall Street',
        City__c     = 'New York',
        Country__c  = 'United States',
        Latitude__c = 40.7058089,
        Longitude__c = -74.0084337,
        Description__c = 'Full-service medical centre providing professional nursing care.',
        Work_Time__c   = opHours[0].Id
    ),
    new Action_Centre__c(
        Name        = 'Central Client Support Centre',
        Type__c     = 'Client Support Centre',
        Street__c   = 'Broadway',
        City__c     = 'New York',
        Country__c  = 'United States',
        Latitude__c = 40.7079284,
        Longitude__c = -74.0114693,
        Description__c = 'Client support centre for consultations and service requests.',
        Work_Time__c   = opHours[1].Id,
        Phone__c    = '+12125550001',
        Email__c    = 'support@nursehouse.com'
    ),
    new Action_Centre__c(
        Name        = 'Brooklyn Medical Centre',
        Type__c     = 'Medical Centre',
        Street__c   = 'Atlantic Avenue',
        City__c     = 'Brooklyn',
        Country__c  = 'United States',
        Latitude__c = 40.6843,
        Longitude__c = -73.9441,
        Description__c = 'Medical centre serving the Brooklyn area with home nursing services.',
        Work_Time__c   = opHours[0].Id
    )
};
insert centres;

// Nurses (Person Accounts) 
Id nurseRtId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Nurse' LIMIT 1].Id;
List<Account> nurses = new List<Account>{
    new Account(RecordTypeId = nurseRtId, LastName = 'Kovalenko', FirstName = 'Anna',   Phone = '+375291111111', Action_Centre__c = centres[0].Id),
    new Account(RecordTypeId = nurseRtId, LastName = 'Ivanova',   FirstName = 'Maria',  Phone = '+375292222222', Action_Centre__c = centres[0].Id),
    new Account(RecordTypeId = nurseRtId, LastName = 'Petrov',    FirstName = 'Sergei', Phone = '+375293333333', Action_Centre__c = centres[1].Id)
};
insert nurses;

// Procedures & Pricebook Entries 
Id stdPbId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;
Id procRtId = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' AND DeveloperName = 'Procedure' LIMIT 1].Id;
List<Product2> procedures = new List<Product2>{
    new Product2(RecordTypeId = procRtId, Name = 'Blood Pressure Check',  IsActive = true),
    new Product2(RecordTypeId = procRtId, Name = 'Wound Dressing',        IsActive = true),
    new Product2(RecordTypeId = procRtId, Name = 'Injection',             IsActive = true),
    new Product2(RecordTypeId = procRtId, Name = 'Blood Sugar Test',      IsActive = true),
    new Product2(RecordTypeId = procRtId, Name = 'Physiotherapy Session', IsActive = true)
};
insert procedures;

List<PricebookEntry> entries = new List<PricebookEntry>();
Decimal[] prices = new Decimal[]{ 20, 35, 25, 15, 50 };
for (Integer i = 0; i < procedures.size(); i++) {
    entries.add(new PricebookEntry(Pricebook2Id = stdPbId, Product2Id = procedures[i].Id, UnitPrice = prices[i], IsActive = true));
}
insert entries;

// Centre Procedures (many-to-many: which procedures each centre offers)
List<Centre_Procedure__c> centreProcedures = new List<Centre_Procedure__c>{
    // City Medical Centre: Blood Pressure Check, Wound Dressing, Injection, Blood Sugar Test
    new Centre_Procedure__c(Action_Centre__c = centres[0].Id, Procedure__c = procedures[0].Id),
    new Centre_Procedure__c(Action_Centre__c = centres[0].Id, Procedure__c = procedures[1].Id),
    new Centre_Procedure__c(Action_Centre__c = centres[0].Id, Procedure__c = procedures[2].Id),
    new Centre_Procedure__c(Action_Centre__c = centres[0].Id, Procedure__c = procedures[3].Id),
    // Central Client Support Centre: Blood Pressure Check, Injection
    new Centre_Procedure__c(Action_Centre__c = centres[1].Id, Procedure__c = procedures[0].Id),
    new Centre_Procedure__c(Action_Centre__c = centres[1].Id, Procedure__c = procedures[2].Id),
    // Brooklyn Medical Centre: Wound Dressing, Physiotherapy Session, Blood Sugar Test
    new Centre_Procedure__c(Action_Centre__c = centres[2].Id, Procedure__c = procedures[1].Id),
    new Centre_Procedure__c(Action_Centre__c = centres[2].Id, Procedure__c = procedures[3].Id),
    new Centre_Procedure__c(Action_Centre__c = centres[2].Id, Procedure__c = procedures[4].Id)
};
insert centreProcedures;

// Leads
List<Lead> leads = new List<Lead>{
    new Lead(FirstName = 'Ivan',  LastName = 'Sokolov',  Company = 'N/A', Phone = '+375291000001'),
    new Lead(FirstName = 'Elena', LastName = 'Morozova', Company = 'N/A', Phone = '+375291000002'),
    new Lead(FirstName = 'Pavel', LastName = 'Fedorov',  Company = 'N/A', Phone = '+375291000003')
};
insert leads;

// Scheduled Visits 
DateTime base = DateTime.now();
List<Scheduled_Visit__c> visits = new List<Scheduled_Visit__c>{
    new Scheduled_Visit__c(Nurse__c = nurses[0].Id, Lead__c = leads[0].Id, Action_Centre__c = centres[0].Id, Visit_Date_Time__c = base,            Status__c = 'Completed', Total_Price__c = 55),
    new Scheduled_Visit__c(Nurse__c = nurses[0].Id, Lead__c = leads[1].Id, Action_Centre__c = centres[0].Id, Visit_Date_Time__c = base.addDays(1), Status__c = 'Completed', Total_Price__c = 35),
    new Scheduled_Visit__c(Nurse__c = nurses[1].Id, Lead__c = leads[2].Id, Action_Centre__c = centres[1].Id, Visit_Date_Time__c = base.addDays(2), Status__c = 'Completed', Total_Price__c = 25),
    new Scheduled_Visit__c(Nurse__c = nurses[1].Id, Lead__c = leads[0].Id, Action_Centre__c = centres[1].Id, Visit_Date_Time__c = base.addDays(3), Status__c = 'Scheduled',  Total_Price__c = 70),
    new Scheduled_Visit__c(Nurse__c = nurses[2].Id, Lead__c = leads[1].Id, Action_Centre__c = centres[0].Id, Visit_Date_Time__c = base.addDays(4), Status__c = 'Completed', Total_Price__c = 50)
};
insert visits;

// Visit Procedures 
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
insert vps;

System.debug('Seed complete: 2 operating hours, 11 time slots, 3 centres, 3 nurses, 5 procedures, 9 centre-procedures, 5 visits, 9 visit-procedures');
