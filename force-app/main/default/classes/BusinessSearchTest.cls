@isTest
public class BusinessSearchTest {
  @testSetup
  static void setup() {
    // Create a mock configuration record
    Experian_Configuration__c config = new Experian_Configuration__c(
      Experian_Access_Token__c = 'testAccessToken'
    );
    insert config;
  }

  @isTest
  static void testGetLOS_Success() {
    // Mock the HTTP response
    Test.setMock(
      HttpCalloutMock.class,
      new MockHttpResponseGenerator(
        200,
        '{"results": [{"bin": "123456", "businessName": "Test Business", "phone": "123-456-7890", "address": {"street": "123 Test St", "city": "Test City", "state": "TS", "zip": "12345"}, "reliabilityCode": 1.0, "numberOfTradelines": 5, "financialStatementIndicator": true, "keyFactsIndicator": true, "inquiryIndicator": true, "bankDataIndicator": true, "governmentDataIndicator": true, "executiveSummaryIndicator": true, "uccIndicator": true, "businessGeocode": {"latitude": 12.34, "longitude": 56.78}}]}'
      )
    );

    Map<String, String> searchCriteria = new Map<String, String>{
      'businessName' => 'Test Business',
      'address' => '123 Test St',
      'city' => 'Test City',
      'state' => 'TS',
      'zipcode' => '12345'
    };

    Test.startTest();
    List<BusinessSearch.BusinessResult> results = BusinessSearch.getLOS(
      searchCriteria
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'There should be one result');
    BusinessSearch.BusinessResult result = results[0];
    System.assertEquals('123456', result.bin, 'BIN should match');
    System.assertEquals(
      'Test Business',
      result.name,
      'Business name should match'
    );
    System.assertEquals('123-456-7890', result.phone, 'Phone should match');
    System.assertEquals(
      '123 Test St, Test City, TS 12345',
      result.address,
      'Address should match'
    );
    System.assertEquals(
      1.0,
      result.reliabilityCode,
      'Reliability code should match'
    );
    System.assertEquals(
      5,
      result.numberOfTradelines,
      'Number of tradelines should match'
    );
    System.assertEquals(
      true,
      result.financialStatementIndicator,
      'Financial statement indicator should match'
    );
    System.assertEquals(
      true,
      result.keyFactsIndicator,
      'Key facts indicator should match'
    );
    System.assertEquals(
      true,
      result.inquiryIndicator,
      'Inquiry indicator should match'
    );
    System.assertEquals(
      true,
      result.bankDataIndicator,
      'Bank data indicator should match'
    );
    System.assertEquals(
      true,
      result.governmentDataIndicator,
      'Government data indicator should match'
    );
    System.assertEquals(
      true,
      result.executiveSummaryIndicator,
      'Executive summary indicator should match'
    );
    System.assertEquals(
      true,
      result.uccIndicator,
      'UCC indicator should match'
    );
    System.assertEquals(12.34, result.latitude, 'Latitude should match');
    System.assertEquals(56.78, result.longitude, 'Longitude should match');
  }

  @isTest
  static void testGetLOS_Failure() {
    // Mock the HTTP response
    Test.setMock(
      HttpCalloutMock.class,
      new MockHttpResponseGenerator(400, '{"error": "invalid_request"}')
    );

    Map<String, String> searchCriteria = new Map<String, String>{
      'businessName' => 'Test Business',
      'address' => '123 Test St',
      'city' => 'Test City',
      'state' => 'TS',
      'zipcode' => '12345'
    };

    Test.startTest();
    List<BusinessSearch.BusinessResult> results = BusinessSearch.getLOS(
      searchCriteria
    );
    Test.stopTest();

    System.assertEquals(0, results.size(), 'There should be no results');
  }

  @isTest
  static void testGetLOS_MissingOptionalFields() {
    // Mock the HTTP response
    Test.setMock(
      HttpCalloutMock.class,
      new MockHttpResponseGenerator(
        200,
        '{"results": [{"bin": "123456", "businessName": "Test Business", "phone": "123-456-7890", "address": {"street": "123 Test St", "city": "Test City", "state": "TS", "zip": "12345"}, "reliabilityCode": 1.0, "numberOfTradelines": 5, "financialStatementIndicator": true, "keyFactsIndicator": true, "inquiryIndicator": true, "bankDataIndicator": true, "governmentDataIndicator": true, "executiveSummaryIndicator": true, "uccIndicator": true, "businessGeocode": {"latitude": 12.34, "longitude": 56.78}}]}'
      )
    );

    Map<String, String> searchCriteria = new Map<String, String>{
      'businessName' => 'Test Business',
      'address' => '123 Test St',
      'city' => 'Test City',
      'state' => 'TS',
      'zipcode' => '12345'
    };

    Test.startTest();
    List<BusinessSearch.BusinessResult> results = BusinessSearch.getLOS(
      searchCriteria
    );
    Test.stopTest();

    System.assertEquals(1, results.size(), 'There should be one result');
    BusinessSearch.BusinessResult result = results[0];
    System.assertEquals('123456', result.bin, 'BIN should match');
    System.assertEquals(
      'Test Business',
      result.name,
      'Business name should match'
    );
    System.assertEquals('123-456-7890', result.phone, 'Phone should match');
    System.assertEquals(
      '123 Test St, Test City, TS 12345',
      result.address,
      'Address should match'
    );
    System.assertEquals(
      1.0,
      result.reliabilityCode,
      'Reliability code should match'
    );
    System.assertEquals(
      5,
      result.numberOfTradelines,
      'Number of tradelines should match'
    );
    System.assertEquals(
      true,
      result.financialStatementIndicator,
      'Financial statement indicator should match'
    );
    System.assertEquals(
      true,
      result.keyFactsIndicator,
      'Key facts indicator should match'
    );
    System.assertEquals(
      true,
      result.inquiryIndicator,
      'Inquiry indicator should match'
    );
    System.assertEquals(
      true,
      result.bankDataIndicator,
      'Bank data indicator should match'
    );
    System.assertEquals(
      true,
      result.governmentDataIndicator,
      'Government data indicator should match'
    );
    System.assertEquals(
      true,
      result.executiveSummaryIndicator,
      'Executive summary indicator should match'
    );
    System.assertEquals(
      true,
      result.uccIndicator,
      'UCC indicator should match'
    );
    System.assertEquals(12.34, result.latitude, 'Latitude should match');
    System.assertEquals(56.78, result.longitude, 'Longitude should match');
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
