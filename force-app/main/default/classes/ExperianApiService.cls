public inherited sharing class ExperianApiService {
  public static Experian_Configuration__c getBIQConfig() {
    Experian_API_host__mdt sandboxRecord = [
      SELECT Id, DeveloperName, Endpoint_URL__c
      FROM Experian_API_host__mdt
      WHERE DeveloperName = 'Sandbox'
      LIMIT 1
    ];

    return [
      SELECT
        Id,
        Name,
        Experian_Access_Token__c,
        Experian_API_Client_id__c,
        Experian_Api_Client_Secret__c,
        Experian_API_Password__c,
        Experian_API_User_Name__c,
        Experian_Token_URL__c
      FROM Experian_Configuration__c
      LIMIT 1
    ];
  }
}
