public with sharing class AlertRegistrationController {
  @AuraEnabled(cacheable=true)
  public static List<Map<String, String>> getAccountLists() {
    List<Map<String, String>> accountLists = new List<Map<String, String>>();
    List<ListView> views = [
      SELECT Id, Name, DeveloperName
      FROM ListView
      WHERE SObjectType = 'Account' AND IsSoqlCompatible = TRUE
      ORDER BY Name
    ];

    for (ListView view : views) {
      Map<String, String> viewData = new Map<String, String>();
      viewData.put('Id', view.Id);
      viewData.put('Name', view.Name);
      accountLists.add(viewData);
    }

    return accountLists;
  }

  @AuraEnabled(cacheable=true)
  public static Integer getTotalAccountsInList(String listViewId) {
    Integer totalAccounts = 0;
    try {
      ListView lv = [
        SELECT Id, Name, DeveloperName, SobjectType
        FROM ListView
        WHERE Id = :listViewId
      ];
      String query =
        'SELECT COUNT() FROM ' + String.escapeSingleQuotes(lv.SobjectType);
      totalAccounts = Database.countQuery(query);
    } catch (Exception e) {
      System.debug('Error fetching total accounts: ' + e.getMessage());
      throw new AuraHandledException(
        'Error fetching total accounts: ' + e.getMessage()
      );
    }
    return totalAccounts;
  }

  @AuraEnabled(cacheable=true)
  public static List<Account> getAccounts(
    String listViewId,
    Integer offset,
    Integer recordLimit
  ) {
    List<Account> accounts = new List<Account>();
    try {
      ListView lv = [
        SELECT Id, Name, DeveloperName, SobjectType
        FROM ListView
        WHERE Id = :listViewId
      ];

      String query =
        'SELECT Id, Name, Experian_AMS_Registration_status__c ' +
        'FROM ' +
        String.escapeSingleQuotes(lv.SobjectType) +
        ' LIMIT :recordLimit OFFSET :offset';

      accounts = Database.query(query);
    } catch (Exception e) {
      System.debug('Error fetching accounts: ' + e.getMessage());
      throw new AuraHandledException(
        'Error fetching accounts: ' + e.getMessage()
      );
    }
    return accounts;
  }

  @AuraEnabled
  public static String registerAMS(List<Id> accountIds, String listViewId) {
    System.debug(
      'registerAMS method called with accountIds: ' +
        accountIds +
        ' and listViewId: ' +
        listViewId
    );
    try {
      Experian_BatchAMSRegistration batchJob;

      if (listViewId != null) {
        System.debug(
          'listViewId is not null, processing all accounts in the list view'
        );
        // Process all accounts in the list view
        ListView lv = [
          SELECT Id, Name, DeveloperName, SobjectType
          FROM ListView
          WHERE Id = :listViewId
        ];
        System.debug('ListView retrieved: ' + lv);

        // Create a batch job that will query the accounts in batches
        batchJob = new Experian_BatchAMSRegistration(listViewId);
      } else if (accountIds != null && !accountIds.isEmpty()) {
        System.debug(
          'accountIds is not null and not empty, processing selected accounts'
        );
        // Process only selected accounts
        batchJob = new Experian_BatchAMSRegistration(accountIds);
      } else {
        System.debug('No accounts specified for registration');
        throw new AuraHandledException(
          'No accounts specified for registration'
        );
      }

      // Start the batch process
      System.debug('Starting batch process for AMS registration');
      Id batchId = Database.executeBatch(batchJob, 200); // Process 200 records at a time
      System.debug('Batch job started with ID: ' + batchId);

      return 'Batch job started with ID: ' + batchId;
    } catch (Exception e) {
      System.debug('Error initiating AMS registration: ' + e.getMessage());
      throw new AuraHandledException(
        'Error initiating AMS registration: ' + e.getMessage()
      );
    }
  }

  @AuraEnabled
  public static void unregisterAMS(List<Id> accountIds, String listViewId) {
    try {
      List<Account> accountsToProcess;
      if (listViewId != null) {
        // Process all accounts in the list view
        ListView lv = [
          SELECT Id, Name, DeveloperName, SobjectType
          FROM ListView
          WHERE Id = :listViewId
        ];
        String query =
          'SELECT Id, Name FROM ' + String.escapeSingleQuotes(lv.SobjectType);
        accountsToProcess = Database.query(query);
      } else if (accountIds != null && !accountIds.isEmpty()) {
        // Process only selected accounts
        accountsToProcess = [
          SELECT Id, Name
          FROM Account
          WHERE Id IN :accountIds
        ];
      } else {
        throw new AuraHandledException(
          'No accounts specified for unregistration'
        );
      }

      for (Account acc : accountsToProcess) {
        System.debug('Unregistering AMS for account: ' + acc.Name);
        // Implement your AMS unregistration logic here
      }
    } catch (Exception e) {
      System.debug('Error unregistering AMS: ' + e.getMessage());
      throw new AuraHandledException(
        'Error unregistering AMS: ' + e.getMessage()
      );
    }
  }
}
