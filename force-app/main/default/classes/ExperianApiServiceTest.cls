@isTest
private class ExperianApiServiceTest {
  @testSetup
  static void setup() {
    // Insert a test record for Experian_Configuration__c
    Experian_Configuration__c config = new Experian_Configuration__c(
      Name = 'Test Config',
      Experian_Access_Token__c = 'testAccessToken',
      Experian_API_Client_id__c = 'testClientId',
      Experian_Api_Client_Secret__c = 'testClientSecret',
      Experian_API_Password__c = 'testPassword',
      Experian_API_User_Name__c = 'testUserName',
      Experian_Token_URL__c = 'https://test.token.url'
    );
    insert config;
  }

  @isTest
  static void testGetBIQConfig() {
    // Call the method
    Experian_Configuration__c result = ExperianApiService.getBIQConfig();

    // Assert the results
    System.assertNotEquals(null, result, 'The result should not be null');
    System.assertEquals(
      'Test Config',
      result.Name,
      'The Name should match the test data'
    );
    System.assertEquals(
      'testAccessToken',
      result.Experian_Access_Token__c,
      'The Access Token should match the test data'
    );
    System.assertEquals(
      'testClientId',
      result.Experian_API_Client_id__c,
      'The Client ID should match the test data'
    );
    System.assertEquals(
      'testClientSecret',
      result.Experian_Api_Client_Secret__c,
      'The Client Secret should match the test data'
    );
    System.assertEquals(
      'testPassword',
      result.Experian_API_Password__c,
      'The Password should match the test data'
    );
    System.assertEquals(
      'testUserName',
      result.Experian_API_User_Name__c,
      'The User Name should match the test data'
    );
    System.assertEquals(
      'https://test.token.url',
      result.Experian_Token_URL__c,
      'The Token URL should match the test data'
    );
  }
}
