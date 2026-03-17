## Final project

In order to fulfill needs of the Nurse House business we need to develop a Salesforce CRM solution.

The system will use those standard objects:

* Lead \- a person that can be our client  
* Person Account \- a person that is working for us (Nurses)  
* Contact \- a person that we are working with  
* Product \- procedures that the client can request  
* PriceBook \- our price books for the procedures  
* Case \- client requests

And those custom objects:

* Action Centre \- the physical residences of our company   
      with two types:  
      Medical Centre  
      Client Support Centre  
* Scheduled Visit \- the scheduled action of the Nurse for the Person with procedures

**The goal is:**

**Create a Salesforce structure**  
1\) Give the ability to create and view Nurses  
2\) Give the ability to create and view Procedures and their pricings  
3\) Create a Dashboard that fits those needs:  
    1\) We can see the usage of top 10 procedures  
    2\) We can see the amounts of the Visits in this month for each Nurse  
    3\) We can see the value amounts closed by each Nurse in this month  
4\) Create Email-to-Case so that all Email requests can be seen as Cases  
5\) Create a Screen Flow that is pre-populated with the Nurse information and takes as an input a short survey for the Nurse services, so that the client can send us a review.  
    1\) The result of the review should be stored in the system  
6\) An integration with Belarusian National Bank in order to sync the Currency conversion ratio  
7\) On Scheduled Visit there should be an ability to send an email to the Client with the survey

**Create publicly available site for our clients, that can be used by anyone that includes:**  
1\) Home page with short info about the business and the map with all Action Centres  
    1\) For Medical Centre there should be ability to see the work time and address  
    2\) For the Client Support there should be ability to see the work time, address and contacts (phone and email)  
2\) Each centre should have a dedicated page with it's short description, address, work time, contacts and the list of the Nurses  
3\) Page to ask the question (create the Case)  
4\) Page with the list of all procedures  
    1\) Should have ability to change the Currency (USD/EUR/BYN) using the BNB currency conversion ratios  
    2\) We should be able to filter procedures by Centre and/or Name  
    3\) We should be able to export current list of procedures as PDF file, with prices of the currently selected currency, grouped by the Centre  
    4\) When selecting a procedure should be ability to schedule it via selecting the Centre and Nurse, entering the needed info and related House Address  
        1\) When procedure is scheduled the Lead should be created if we don't have this client yet  
        2\) The client should be related to the Scheduled Visit we've created, same as the Nurse  
        3\) If the Nurse already has a Scheduled Visit on this date and time (1h window) then there should not be an ability to request another Visit

**Quality requirements:**  
1\) Everything should be presented in GIT  
2\) All Apex classes should be covered by Unit Tests with at least 85% coverage  
