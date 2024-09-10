@isTest
private class ExperianApiServiceTest {
  @TestSetup
  static void setupTestData() {
    // Create test Experian Configuration record
    Experian_Configuration__c testConfig = new Experian_Configuration__c(
      Name = 'Test Config',
      Experian_Environment__c = 'Test',
      Default_Subcode__c = '1234567',
      Experian_Access_Token__c = 'test_token',
      Experian_API_Client_id__c = 'test_client_id',
      Experian_Api_Client_Secret__c = 'test_client_secret',
      Experian_API_Password__c = 'test_password',
      Experian_API_User_Name__c = 'test_user',
      Experian_Token_URL__c = '/oauth2/v1/token',
      Token_URL__c = '/oauth2/v1/token',
      AMS_Get_Alert_Detail_URL__c = '/businessinformation/ams/v1/alerts/',
      AMS_Get_Alert_List_URL__c = '/businessinformation/ams/v1/alerts',
      AMS_Register_URL__c = '/businessinformation/ams/v1/accounts',
      AMS_Unregister_URL__c = '/businessinformation/ams/v1/accounts/',
      AMS_Subcode__c = '0123456',
      AMS_Subscriber_Code__c = '1234567',
      Decision_Basic_URL__c = '/businessinformation/businesses/v1/decisionbasic',
      DecisionIQ_Default_Policy_ID__c = 'test_policy_id',
      Decision_IQ_Subcode__c = '7654321',
      DIQ_user_id__c = 'test_diq_user',
      Premier_Profile_JSON_URL__c = '/businessinformation/businesses/v1/premierprofiles',
      Premier_Profile_PDF_URL__c = '/businessinformation/businesses/v1/premierprofiles',
      Search_URL__c = '/businessinformation/businesses/v1/search',
      BOP_PDF_URL__c = '/businessinformation/businesses/v1/bop'
    );
    insert testConfig;

    // Create test Experian API host custom metadata
    Experian_API_host__mdt testHostUrl = new Experian_API_host__mdt(
      DeveloperName = 'Test',
      Endpoint_URL__c = 'https://sandbox-us-api.experian.com'
    );
    // Note: In a real test scenario, you'd need to use Custom Metadata Types deployment
    // to create this record. For this example, we'll assume it exists.
  }

  @isTest
  static void testGetBIQConfig() {
    Test.startTest();
    ExperianApiService.ExperianConfigWrapper result = ExperianApiService.getBIQConfig();
    Test.stopTest();

    // Verify the config object
    System.assertNotEquals(null, result.config, 'Config should not be null');
    System.assertEquals(
      'Test Config',
      result.config.Name,
      'Config name should match'
    );
    System.assertEquals(
      'Test',
      result.config.Experian_Environment__c,
      'Environment should match'
    );

    // Verify the endpoints object
    System.assertNotEquals(
      null,
      result.endpoints,
      'Endpoints should not be null'
    );
    String expectedBaseUrl = 'https://sandbox-us-api.experian.com';
    System.assertEquals(
      expectedBaseUrl + '/oauth2/v1/token',
      result.endpoints.tokenUrl,
      'Token URL should match'
    );
    System.assertEquals(
      expectedBaseUrl + '/businessinformation/ams/v1/alerts/',
      result.endpoints.amsGetAlertDetailUrl,
      'AMS Get Alert Detail URL should match'
    );
    System.assertEquals(
      expectedBaseUrl + '/businessinformation/ams/v1/alerts',
      result.endpoints.amsGetAlertListUrl,
      'AMS Get Alert List URL should match'
    );
    System.assertEquals(
      expectedBaseUrl + '/businessinformation/ams/v1/accounts',
      result.endpoints.amsRegisterUrl,
      'AMS Register URL should match'
    );
    System.assertEquals(
      expectedBaseUrl + '/businessinformation/ams/v1/accounts/',
      result.endpoints.amsUnregisterUrl,
      'AMS Unregister URL should match'
    );
    System.assertEquals(
      expectedBaseUrl + '/businessinformation/businesses/v1/decisionbasic',
      result.endpoints.decisionBasicUrl,
      'Decision Basic URL should match'
    );
    System.assertEquals(
      expectedBaseUrl + '/businessinformation/businesses/v1/premierprofiles',
      result.endpoints.premierProfileJsonUrl,
      'Premier Profile JSON URL should match'
    );
    System.assertEquals(
      expectedBaseUrl + '/businessinformation/businesses/v1/premierprofiles',
      result.endpoints.premierProfilePdfUrl,
      'Premier Profile PDF URL should match'
    );
    System.assertEquals(
      expectedBaseUrl + '/businessinformation/businesses/v1/search',
      result.endpoints.searchUrl,
      'Search URL should match'
    );
    System.assertEquals(
      expectedBaseUrl + '/businessinformation/businesses/v1/bop',
      result.endpoints.bopPdfUrl,
      'BOP PDF URL should match'
    );
  }

  @isTest
  static void testGetBIQConfigNoData() {
    // Delete the test data to simulate no configuration
    delete [SELECT Id FROM Experian_Configuration__c];

    Test.startTest();
    try {
      ExperianApiService.ExperianConfigWrapper result = ExperianApiService.getBIQConfig();
      System.assert(false, 'Should have thrown an exception');
    } catch (QueryException e) {
      System.assert(
        e.getMessage().contains('List has no rows for assignment to SObject'),
        'Expected QueryException when no configuration exists'
      );
    }
    Test.stopTest();
  }
}
