public with sharing class ExperianAccountAlertsController {
  @AuraEnabled(cacheable=true)
  public static AccountAlertWrapper getAccountAlertsAndStatus(Id accountId) {
    Account acc = [
      SELECT Id, Name, Experian_Alert_Status__c
      FROM Account
      WHERE Id = :accountId
    ];

    List<Experian_Alert__c> alerts = [
      SELECT Id, Name, Definition__c, Priority__c, Alert_Date__c
      FROM Experian_Alert__c
      WHERE Account__c = :accountId
      ORDER BY Alert_Date__c DESC
      LIMIT 50
    ];

    return new AccountAlertWrapper(acc, alerts);
  }

  @AuraEnabled
  public static void updateAccountAlertStatus(Id accountId, String newStatus) {
    Account acc = new Account(
      Id = accountId,
      Experian_Alert_Status__c = newStatus
    );
    update acc;
  }

  public class AccountAlertWrapper {
    @AuraEnabled
    public String accountName;
    @AuraEnabled
    public String alertStatus;
    @AuraEnabled
    public List<Experian_Alert__c> alerts;

    public AccountAlertWrapper(Account acc, List<Experian_Alert__c> alertList) {
      this.accountName = acc.Name;
      this.alertStatus = acc.Experian_Alert_Status__c;
      this.alerts = alertList;
    }
  }

  @AuraEnabled
  public static Map<String, Object> getAlertDetails(Id accountId, Id alertId) {
    try {
      // Your existing logic to fetch alert details
      // This is a mock implementation. Replace with your actual API call or database query.
      Map<String, Object> mockResponse = new Map<String, Object>{
        'success' => true,
        'requestId' => 'rrt-' + String.valueOf(Math.random()).substring(2, 17),
        'comments' => 'Sample String Value',
        'results' => new Map<String, Object>{
          'id' => alertId,
          'date' => '2015-12-07',
          'type' => 46,
          'priorityCode' => 6,
          'definition' => 'Derogatory Trade - Payment Amount Past Due 61-90 Days',
          'listType' => 'DAILY',
          'triggerId' => 280335819,
          'monitoredBusiness' => new Map<String, Object>{
            'monitoredBusinessName' => 'TRANSERVICE LEASE CORP BERKLE',
            'bestBusinessName' => 'TRANSERVICE LOGISTICS INC',
            'supplierNumber' => '935328',
            'userTrackingId' => '08200000000F4623001',
            'pBIN' => '834521458'
          },
          'endCustomerData' => new Map<String, Object>{
            'totalBalance' => 0,
            'lastActivityDate' => null,
            'inactiveAcctFlag' => true,
            'currentBalance' => 0,
            'balance1to30' => 0,
            'balance31to60' => 0,
            'balance61to90' => 0,
            'balance91Plus' => 0,
            'dbt' => null,
            'tradeSupplier' => new List<Integer>{ 841056 }
          },
          'customerRoutingCode' => 'QA -101001',
          't44to47Details' => new Map<String, Object>{
            'reportDate' => null,
            'tradeCommentCode' => null,
            'tradeCommentDefinition' => null,
            'contributorBcat' => null,
            'totalBalancePct61Plus' => 0,
            'newTradeSupplierNumber' => null,
            'tradeTotals' => null,
            'tradePercentages' => null,
            'accountTotals' => new Map<String, Object>{
              'accountBalance' => 18593,
              'pastDueAmt1to30' => 0,
              'pastDueAmt31to60' => 5230,
              'pastDueAmt61to90' => 2283,
              'pastDueAmt91to120' => 4259,
              'pastDueAmt121to150' => 0,
              'pastDueAmt151to180' => 0,
              'pastDueAmt181Plus' => 0
            }
          }
        }
      };

      return mockResponse;
    } catch (Exception e) {
      return new Map<String, Object>{
        'success' => false,
        'comments' => 'Error retrieving alert details: ' + e.getMessage()
      };
    }
  }
}
