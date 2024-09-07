public with sharing class ExperianAlertListController {
  @AuraEnabled(cacheable=true)
  public static List<Experian_Alert__c> getAlerts() {
    return [
      SELECT
        Name,
        Account__c,
        Status__c,
        BIN__c,
        Priority__c,
        Alert_Date__c,
        Is_Deleted__c,
        Alert_ID__c,
        Definition__c,
        Trigger_ID__c,
        Id
      FROM Experian_Alert__c
      WHERE IsDeleted = FALSE
      ORDER BY Alert_Date__c DESC
      LIMIT 1000
    ];
  }

  @AuraEnabled(cacheable=true)
  public static List<Experian_Alert__c> getFilteredAlerts(
    String searchTerm,
    String selectedView,
    List<String> selectedAlertTypes,
    Integer daysAgo
  ) {
    String query =
      'SELECT Name, Account__c, Status__c, BIN__c, Priority__c, ' +
      'Alert_Date__c, Is_Deleted__c, Alert_ID__c, ' +
      'Definition__c, Trigger_ID__c, Id ' +
      'FROM Experian_Alert__c ' +
      'WHERE IsDeleted = false ';

    if (String.isNotBlank(searchTerm)) {
      query +=
        'AND (Name LIKE \'%' +
        String.escapeSingleQuotes(searchTerm) +
        '%\' ' +
        'OR Alert_ID__c LIKE \'%' +
        String.escapeSingleQuotes(searchTerm) +
        '%\' ' +
        'OR Definition__c LIKE \'%' +
        String.escapeSingleQuotes(searchTerm) +
        '%\') ';
    }

    if (selectedView == 'unread') {
      query += 'AND Status__c = \'Unread\' ';
    } else if (selectedView == 'read') {
      query += 'AND Status__c = \'Read\' ';
    }

    if (selectedAlertTypes != null && !selectedAlertTypes.isEmpty()) {
      query += 'AND Definition__c IN :selectedAlertTypes ';
    }

    if (daysAgo != null) {
      Date cutoffDate = Date.today().addDays(-daysAgo);
      query += 'AND Alert_Date__c >= :cutoffDate ';
    }

    query += 'ORDER BY Alert_Date__c DESC LIMIT 1000';

    return Database.query(query);
  }

  @AuraEnabled
  public static void updateAlertStatus(List<Id> alertIds, String newStatus) {
    List<Experian_Alert__c> alertsToUpdate = [
      SELECT Id, Status__c
      FROM Experian_Alert__c
      WHERE Id IN :alertIds
    ];
    for (Experian_Alert__c alert : alertsToUpdate) {
      alert.Status__c = newStatus;
    }
    update alertsToUpdate;
  }
}
