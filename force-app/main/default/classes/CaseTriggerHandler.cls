public without sharing class CaseTriggerHandler {

    private static final Set<String> CONFIRMATION_ORIGINS = new Set<String>{ 'Web', 'Email' };
    private static final String EMAIL_SUBJECT = 'Your request has been received — Nurse House';

    public void run(List<Case> newCases) {
        List<Case> eligible = filterEligible(newCases);
        if (eligible.isEmpty()) {
            return;
        }
        // Send via @future so emails are dispatched with a verified org-wide sender identity,
        // bypassing the guest user's unverified email address which Salesforce blocks
        Set<String> eligibleIds = new Set<String>();
        for (Case c : eligible) {
            eligibleIds.add(c.Id);
        }
        sendConfirmationEmailsAsync(eligibleIds);
    }

    @future
    private static void sendConfirmationEmailsAsync(Set<String> caseIds) {
        List<Case> cases = [
            SELECT Id, Subject, SuppliedName, SuppliedEmail, CaseNumber
            FROM Case
            WHERE Id IN :caseIds
        ];
        // Use org-wide address so delivery is not blocked when the @future
        // runs in a context initiated by a guest user (unverified sender)
        List<OrgWideEmailAddress> owas = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
        Id owaId = owas.isEmpty() ? null : owas[0].Id;
        List<Messaging.SingleEmailMessage> emails = buildEmails(cases, owaId);
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
    private static List<Messaging.SingleEmailMessage> buildEmails(List<Case> cases, Id owaId) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Case c : cases) {
            emails.add(buildEmail(c, owaId));
        }
        return emails;
    }

    private static Messaging.SingleEmailMessage buildEmail(Case c, Id owaId) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{ c.SuppliedEmail });
        email.setSubject(EMAIL_SUBJECT);
        email.setHtmlBody(buildHtmlBody(c));
        email.setSaveAsActivity(false);
        if (owaId != null) {
            email.setOrgWideEmailAddressId(owaId);
        }
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
