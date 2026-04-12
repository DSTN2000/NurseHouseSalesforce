public with sharing class CaseTriggerHandler {

    private static final Set<String> CONFIRMATION_ORIGINS = new Set<String>{ 'Web', 'Email' };
    private static final String EMAIL_SUBJECT = 'Your request has been received — Nurse House';

    public void run(List<Case> newCases) {
        List<Case> eligible = filterEligible(newCases);
        if (eligible.isEmpty()) {
            return;
        }
        List<Messaging.SingleEmailMessage> emails = buildEmails(eligible);
        Messaging.sendEmail(emails, false);
    }

    private static List<Case> filterEligible(List<Case> cases) {
        List<Case> eligible = new List<Case>();
        for (Case c : cases) {
            if (CONFIRMATION_ORIGINS.contains(c.Origin) && String.isNotBlank(c.SuppliedEmail)) {
                eligible.add(c);
            }
        }
        return eligible;
    }

    @TestVisible
    private static List<Messaging.SingleEmailMessage> buildEmails(List<Case> cases) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Case c : cases) {
            emails.add(buildEmail(c));
        }
        return emails;
    }

    private static Messaging.SingleEmailMessage buildEmail(Case c) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{ c.SuppliedEmail });
        email.setSubject(EMAIL_SUBJECT);
        email.setHtmlBody(buildHtmlBody(c));
        // Required when sending to arbitrary addresses with no targetObjectId —
        // without this Salesforce tries to log an activity and may suppress delivery
        email.setSaveAsActivity(false);
        return email;
    }

    private static String buildHtmlBody(Case c) {
        String greeting = String.isNotBlank(c.SuppliedName)
            ? 'Dear ' + c.SuppliedName + ','
            : 'Dear Customer,';
        return '<p>' + greeting + '</p>'
            + '<p>Thank you for reaching out to Nurse House. '
            + 'We have received your request and our team will get back to you shortly.</p>'
            + '<p><strong>Your case number:</strong> ' + c.CaseNumber + '</p>'
            + '<p><strong>Subject:</strong> ' + c.Subject + '</p>'
            + '<p>Best regards,<br/>The Nurse House Team</p>';
    }
}
