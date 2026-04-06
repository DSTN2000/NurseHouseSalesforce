public without sharing class CaseCreationAction {

    public class CaseInput {
        @InvocableVariable(label='Subject' required=true)
        public String subject;

        @InvocableVariable(label='Description')
        public String description;

        @InvocableVariable(label='Supplied Name')
        public String suppliedName;

        @InvocableVariable(label='Supplied Email')
        public String suppliedEmail;
    }

    @InvocableMethod(label='Create Web Case' description='Creates a Case from a public EC form, bypassing SuppliedName/SuppliedEmail FLS restrictions.')
    public static void createCase(List<CaseInput> inputs) {
        List<Case> cases = new List<Case>();
        for (CaseInput i : inputs) {
            cases.add(new Case(
                Subject       = i.subject,
                Description   = i.description,
                SuppliedName  = i.suppliedName,
                SuppliedEmail = i.suppliedEmail,
                Origin        = 'Web',
                Status        = 'New'
            ));
        }
        insert cases;
    }
}
