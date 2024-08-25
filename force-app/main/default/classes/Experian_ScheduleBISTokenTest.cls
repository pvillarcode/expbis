@isTest
public class Experian_ScheduleBISTokenTest {
  @testSetup
  static void setup() {
    // Create a mock configuration record
    Experian_Configuration__c config = new Experian_Configuration__c(
      Experian_API_User_Name__c = 'testUser',
      Experian_API_Password__c = 'testPassword',
      Experian_API_Client_id__c = 'testClientId',
      Experian_Api_Client_Secret__c = 'testClientSecret',
      Experian_Token_URL__c = 'https://example.com/token'
    );
    insert config;
  }

  @isTest
  static void testScheduleJob() {
    Test.startTest();
    String jobId = System.schedule(
      'Test Experian Schedule',
      '0 0 0 1 1 ? 2032',
      new Experian_ScheduleBISToken()
    );
    Test.stopTest();
    System.assertNotEquals(null, jobId, 'Job ID should not be null');
  }

  @isTest
  static void testGetBISTokenSuccess() {
    // Mock the HTTP response
    Test.setMock(
      HttpCalloutMock.class,
      new MockHttpResponseGenerator(200, '{"access_token": "testToken"}')
    );

    Test.startTest();
    Experian_ScheduleBISToken.getBISToken();
    Test.stopTest();

    // Verify that the token was updated
    Experian_Configuration__c config = [
      SELECT Experian_Access_Token__c
      FROM Experian_Configuration__c
      LIMIT 1
    ];
    System.assertEquals(
      'testToken',
      config.Experian_Access_Token__c,
      'Token should be updated'
    );
  }

  @isTest
  static void testGetBISTokenFailure() {
    // Mock the HTTP response
    Test.setMock(
      HttpCalloutMock.class,
      new MockHttpResponseGenerator(400, '{"error": "invalid_request"}')
    );

    Test.startTest();
    Experian_ScheduleBISToken.getBISToken();
    Test.stopTest();

    // Verify that the token was not updated
    Experian_Configuration__c config = [
      SELECT Experian_Access_Token__c
      FROM Experian_Configuration__c
      LIMIT 1
    ];
    System.assertEquals(
      null,
      config.Experian_Access_Token__c,
      'Token should not be updated'
    );
  }

  // Mock HTTP response generator class
  private class MockHttpResponseGenerator implements HttpCalloutMock {
    private Integer statusCode;
    private String responseBody;

    public MockHttpResponseGenerator(Integer statusCode, String responseBody) {
      this.statusCode = statusCode;
      this.responseBody = responseBody;
    }

    public HTTPResponse respond(HTTPRequest req) {
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');
      res.setBody(responseBody);
      res.setStatusCode(statusCode);
      return res;
    }
  }
}
