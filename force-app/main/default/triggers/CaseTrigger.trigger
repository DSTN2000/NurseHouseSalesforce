trigger CaseTrigger on Case (after insert) {
    System.debug('Trigger fired');
    new CaseTriggerHandler().run(Trigger.new);
}
