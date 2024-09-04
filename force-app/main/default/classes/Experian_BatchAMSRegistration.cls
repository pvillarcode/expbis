global class Experian_BatchAMSRegistration implements Database.Batchable<SObject>, Database.Stateful {
  private List<Id> accountIds;
  private String listViewId;

  global Experian_BatchAMSRegistration(List<Id> accountIds) {
    ExperianLogger.log(
      'Experian_BatchAMSRegistration constructor called with accountIds: ' +
      accountIds,
      ExperianLogger.LogLevel.INFO
    );
    this.accountIds = accountIds;
  }

  global Experian_BatchAMSRegistration(String listViewId) {
    ExperianLogger.log(
      'Experian_BatchAMSRegistration constructor called with listViewId: ' +
      listViewId,
      ExperianLogger.LogLevel.INFO
    );
    this.listViewId = listViewId;
  }

  global Database.QueryLocator start(Database.BatchableContext bc) {
    ExperianLogger.log('start method called', ExperianLogger.LogLevel.INFO);
    if (listViewId != null) {
      ExperianLogger.log(
        'listViewId is not null, processing all accounts in the list view',
        ExperianLogger.LogLevel.INFO
      );
      ListView lv = [
        SELECT Id, Name, DeveloperName, SobjectType
        FROM ListView
        WHERE Id = :listViewId
      ];
      ExperianLogger.log(
        'ListView retrieved: ' + lv,
        ExperianLogger.LogLevel.DEBUG
      );
      String query =
        'SELECT Id FROM ' + String.escapeSingleQuotes(lv.SobjectType);
      ExperianLogger.log(
        'Query to retrieve accounts: ' + query,
        ExperianLogger.LogLevel.DEBUG
      );
      return Database.getQueryLocator(query);
    } else {
      ExperianLogger.log(
        'listViewId is null, processing selected accounts',
        ExperianLogger.LogLevel.INFO
      );
      return Database.getQueryLocator(
        [SELECT Id FROM Account WHERE Id IN :accountIds]
      );
    }
  }

  global void execute(Database.BatchableContext bc, List<Account> scope) {
    ExperianLogger.log(
      'execute method called with scope size: ' + scope.size(),
      ExperianLogger.LogLevel.INFO
    );
    List<Experian_Account_Processing_Event__e> events = new List<Experian_Account_Processing_Event__e>();
    for (Account acc : scope) {
      ExperianLogger.log(
        'Processing account with Id: ' + acc.Id,
        ExperianLogger.LogLevel.DEBUG
      );
      events.add(
        new Experian_Account_Processing_Event__e(Account_ID__c = acc.Id)
      );
    }

    List<Database.SaveResult> results = EventBus.publish(events);
    for (Database.SaveResult sr : results) {
      if (sr.isSuccess()) {
        ExperianLogger.log(
          'Successfully published event. Event ID: ' + sr.getId(),
          ExperianLogger.LogLevel.INFO
        );
      } else {
        for (Database.Error err : sr.getErrors()) {
          ExperianLogger.log(
            'Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage(),
            ExperianLogger.LogLevel.ERROR
          );
        }
      }
    }
    ExperianLogger.log(
      'Published ' + events.size() + ' events to EventBus',
      ExperianLogger.LogLevel.INFO
    );
  }

  global void finish(Database.BatchableContext bc) {
    ExperianLogger.log('finish method called', ExperianLogger.LogLevel.INFO);
    // Any post-processing logic
  }
}
