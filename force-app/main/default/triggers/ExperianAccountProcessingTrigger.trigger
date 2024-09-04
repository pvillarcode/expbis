trigger ExperianAccountProcessingTrigger on Experian_Account_Processing_Event__e(
  after insert
) {
  List<Id> accountIds = new List<Id>();
  for (Experian_Account_Processing_Event__e event : Trigger.new) {
    accountIds.add(event.Account_ID__c);
  }
  System.enqueueJob(new Experian_QueueAMSRegistration(accountIds));
  ExperianLogger.log(
    'Trigger enqueued job for: ' + accountIds,
    ExperianLogger.LogLevel.INFO
  );
}
