public with sharing class ExperianAlertListController {
  @AuraEnabled(cacheable=true)
  public static List<AccountAlertWrapper> getAlertsByAccount() {
    try {
      List<AccountAlertWrapper> result = new List<AccountAlertWrapper>();

      List<Account> accounts = [
        SELECT
          Id,
          Name,
          Experian_Alert_Status__c,
          (
            SELECT
              Id,
              Name,
              Alert_ID__c,
              Definition__c,
              Priority__c,
              Alert_Date__c
            FROM Experian_Alerts__r
            ORDER BY Alert_Date__c DESC
          )
        FROM Account
        WHERE Id IN (SELECT Account__c FROM Experian_Alert__c)
        LIMIT 1000
      ];

      for (Account acc : accounts) {
        AccountAlertWrapper wrapper = new AccountAlertWrapper();
        wrapper.accountId = acc.Id;
        wrapper.accountName = acc.Name;
        wrapper.alertStatus = acc.Experian_Alert_Status__c != null
          ? acc.Experian_Alert_Status__c
          : 'Unknown';
        wrapper.alertCount = acc.Experian_Alerts__r.size();
        wrapper.alerts = acc.Experian_Alerts__r;
        wrapper.summary = createSummary(acc.Experian_Alerts__r);
        result.add(wrapper);
      }

      return result;
    } catch (Exception e) {
      throw new AuraHandledException(
        'Error fetching alerts: ' + e.getMessage()
      );
    }
  }

  private static String createSummary(List<Experian_Alert__c> alerts) {
    List<String> definitions = new List<String>();
    for (Experian_Alert__c alert : alerts) {
      if (alert.Definition__c != null) {
        definitions.add(alert.Definition__c);
      }
      if (definitions.size() == 2)
        break;
    }

    String summary = String.join(definitions, ', ');
    if (alerts.size() > 2) {
      summary += '...';
    }
    return summary;
  }

  @AuraEnabled
  public static List<AccountAlertWrapper> getFilteredAlerts(
    String searchTerm,
    String selectedView,
    List<String> selectedAlertTypes,
    Integer daysAgo
  ) {
    try {
      List<AccountAlertWrapper> result = new List<AccountAlertWrapper>();

      String query =
        'SELECT Id, Name, Experian_Alert_Status__c, ' +
        '(SELECT Id, Name, Alert_ID__c, Definition__c, Priority__c, Alert_Date__c ' +
        'FROM Experian_Alerts__r ';

      List<String> whereConditions = new List<String>();
      List<String> alertWhereConditions = new List<String>();

      if (String.isNotBlank(searchTerm)) {
        whereConditions.add('Name LIKE :searchTermLike');
      }

      if (selectedView == 'unread') {
        whereConditions.add('Experian_Alert_Status__c = \'Unread\'');
      } else if (selectedView == 'read') {
        whereConditions.add('Experian_Alert_Status__c = \'Read\'');
      }

      if (!selectedAlertTypes.isEmpty()) {
        alertWhereConditions.add('Definition__c IN :selectedAlertTypes');
      }

      if (daysAgo != null) {
        Date cutoffDate = Date.today().addDays(-daysAgo);
        alertWhereConditions.add('Alert_Date__c >= :cutoffDate');
      }

      if (!alertWhereConditions.isEmpty()) {
        query += 'WHERE ' + String.join(alertWhereConditions, ' AND ');
      }

      query += ' ORDER BY Alert_Date__c DESC) FROM Account';

      if (!whereConditions.isEmpty()) {
        query += ' WHERE ' + String.join(whereConditions, ' AND ');
      }

      query += ' AND Id IN (SELECT Account__c FROM Experian_Alert__c)';

      String searchTermLike = '%' + searchTerm + '%';
      List<Account> accounts = Database.query(query);

      for (Account acc : accounts) {
        AccountAlertWrapper wrapper = new AccountAlertWrapper();
        wrapper.accountId = acc.Id;
        wrapper.accountName = acc.Name;
        wrapper.alertStatus = acc.Experian_Alert_Status__c != null
          ? acc.Experian_Alert_Status__c
          : 'Unknown';
        wrapper.alertCount = acc.Experian_Alerts__r.size();
        wrapper.alerts = acc.Experian_Alerts__r;
        wrapper.summary = createSummary(acc.Experian_Alerts__r);
        result.add(wrapper);
      }

      return result;
    } catch (Exception e) {
      throw new AuraHandledException(
        'Error filtering alerts: ' + e.getMessage()
      );
    }
  }

  @AuraEnabled
  public static void updateAccountAlertStatus(
    List<String> accountIds,
    String newStatus
  ) {
    try {
      List<Account> accountsToUpdate = [
        SELECT Id, Experian_Alert_Status__c
        FROM Account
        WHERE Id IN :accountIds
      ];

      for (Account acc : accountsToUpdate) {
        acc.Experian_Alert_Status__c = newStatus;
      }

      update accountsToUpdate;
    } catch (Exception e) {
      throw new AuraHandledException(
        'Error updating account alert status: ' + e.getMessage()
      );
    }
  }

  public class AccountAlertWrapper {
    @AuraEnabled
    public String accountId;
    @AuraEnabled
    public String accountName;
    @AuraEnabled
    public String alertStatus;
    @AuraEnabled
    public Integer alertCount;
    @AuraEnabled
    public List<Experian_Alert__c> alerts;
    @AuraEnabled
    public String summary;
  }

  @TestVisible
  private static void assertPermissions() {
    if (!FeatureManagement.checkPermission('Manage_Experian_Alerts')) {
      throw new AuraHandledException(
        'Insufficient permissions to manage Experian alerts'
      );
    }
  }
}
