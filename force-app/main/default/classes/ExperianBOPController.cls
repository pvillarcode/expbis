public with sharing class ExperianBOPController {
  @AuraEnabled
  public static void pullBOPReport(
    String accountId,
    String ownerLastName,
    String ownerFirstName,
    String ownerMiddleName,
    String ownerGenerationCode,
    String ssn,
    String street,
    String city,
    String state,
    String zip
  ) {
    System.debug('accountId: ' + accountId);
    System.debug('ownerLastName: ' + ownerLastName);
    System.debug('ownerFirstName: ' + ownerFirstName);
    System.debug('ownerMiddleName: ' + ownerMiddleName);
  }
}
