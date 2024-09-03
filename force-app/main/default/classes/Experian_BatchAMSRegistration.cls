public with sharing class Experian_BatchAMSRegistration {
  private List<Account> accountsToProcess;

  public Experian_BatchAMSRegistration(List<Account> accounts) {
    this.accountsToProcess = accounts;
  }

  public Iterable<sObject> start(Database.BatchableContext bc) {
    return this.accountsToProcess;
  }

  public void execute(Database.BatchableContext bc, List<Account> scope) {
    List<Account_Processing_Event__e> events = new List<Account_Processing_Event__e>();
    for (Account acc : scope) {
      events.add(new Account_Processing_Event__e(AccountId__c = acc.Id));
    }
    EventBus.publish(events);
  }

  public void finish(Database.BatchableContext bc) {
    // Any post-processing logic
  }
}
