public with sharing class ExperianDecisionController {
  private static final String DEFAULT_SUBCODE = '0997193';
  private static final String ENDPOINT_JSON_URL = 'https://sandbox-us-api.experian.com/businessinformation/decisioniq/v1/basicdecisions';
  private static final Integer TIMEOUT = 120000;
  private static final String USER_ID = 'qa_admin';

  @AuraEnabled(cacheable=true)
  public static List<Experian_Decision__c> getAllDecisions(String accountId) {
    return [
      SELECT
        Id,
        CreatedDate,
        Name,
        Score__c,
        Decision__c,
        Credit_Limit__c,
        Triggered_Rule__c
      FROM Experian_Decision__c
      WHERE Account__c = :accountId
      ORDER BY CreatedDate DESC
      LIMIT 50
    ];
  }

  @AuraEnabled
  public static Map<String, Object> pullNewDecision(String accountId) {
    try {
      Experian_Business__c experianBusiness = getExperianBusinessForAccount(
        accountId
      );

      if (experianBusiness == null) {
        return new Map<String, Object>{
          'success' => false,
          'message' => 'No Experian Business record found or created for this account.'
        };
      }

      if (String.isBlank(experianBusiness.BIN__c)) {
        return new Map<String, Object>{
          'success' => false,
          'message' => 'Experian Business record is being processed. Please try again in a few moments.'
        };
      }

      // Call the API using the separate method
      Map<String, Object> apiResponse = getDecisionApiCall(
        experianBusiness.BIN__c
      );

      if (apiResponse.containsKey('error')) {
        return new Map<String, Object>{
          'success' => false,
          'message' => (String) apiResponse.get('error')
        };
      }

      // Process the successful response
      Experian_Decision__c newDecision = createExperianDecisionRecord(
        accountId,
        apiResponse
      );

      return new Map<String, Object>{
        'success' => true,
        'decision' => newDecision
      };
    } catch (Exception e) {
      ExperianLogger.log(
        'Error pulling new decision: ' + e.getMessage(),
        ExperianLogger.LogLevel.ERROR
      );
      throw new AuraHandledException(
        'Error pulling new decision: ' + e.getMessage()
      );
    }
  }

  private static Map<String, Object> getDecisionApiCall(String bin) {
    Experian_Configuration__c setting = ExperianApiService.getBIQConfig();

    // Construct the request body
    Map<String, Object> requestBody = new Map<String, Object>{
      'comments' => 'Testing',
      'bin' => bin,
      'creditPolicyId' => '830',
      'subcode' => DEFAULT_SUBCODE,
      'userId' => USER_ID
    };

    // Serialize the request body to JSON
    String jsonBody = JSON.serialize(requestBody);

    // Set up the HTTP request
    HttpRequest req = new HttpRequest();
    req.setMethod('POST');
    req.setTimeout(TIMEOUT);
    req.setEndpoint(ENDPOINT_JSON_URL);
    req.setHeader('Accept', 'application/json');
    req.setHeader('Content-type', 'application/json');
    req.setHeader(
      'Authorization',
      'Bearer ' + setting.Experian_Access_Token__c
    );
    req.setBody(jsonBody);

    // Send the HTTP request
    Http http = new Http();
    HttpResponse res = http.send(req);

    // Process the response
    Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(
      res.getBody()
    );

    if (res.getStatusCode() == 200 && responseBody.get('success') == true) {
      List<Object> results = (List<Object>) responseBody.get('results');
      if (!results.isEmpty()) {
        return (Map<String, Object>) results[0];
      }
    }

    // Handle error response
    String errorMessage = 'API request failed. ';
    if (responseBody.containsKey('errors')) {
      List<Object> errors = (List<Object>) responseBody.get('errors');
      if (!errors.isEmpty()) {
        Map<String, Object> error = (Map<String, Object>) errors[0];
        errorMessage +=
          'Error Code: ' +
          error.get('errorCode') +
          ', Error Type: ' +
          error.get('errorType') +
          ', Message: ' +
          error.get('message');
      }
    } else {
      errorMessage +=
        'Status Code: ' +
        res.getStatusCode() +
        ', Body: ' +
        res.getBody();
    }

    // Log the error
    ExperianLogger.log(
      'Experian API Error: ' + errorMessage,
      ExperianLogger.LogLevel.ERROR
    );

    return new Map<String, Object>{ 'error' => errorMessage };
  }

  private static Experian_Decision__c createExperianDecisionRecord(
    String accountId,
    Map<String, Object> decisionData
  ) {
    Experian_Decision__c newDecision = new Experian_Decision__c(
      Account__c = accountId,
      Score__c = (String) decisionData.get('score'),
      Decision__c = (String) decisionData.get('decision'),
      Credit_Limit__c = (String) decisionData.get('creditLimit'),
      Triggered_Rule__c = (String) decisionData.get('triggeredRule'),
      Name = 'Decision ' + Datetime.now().format('yyyy-MM-dd HH:mm:ss')
    );

    insert newDecision;
    return newDecision;
  }

  private static Experian_Business__c getExperianBusinessForAccount(
    String accountId
  ) {
    List<Experian_Business__c> experianBusinesses = [
      SELECT Id, BIN__c
      FROM Experian_Business__c
      WHERE Account__c = :accountId
      LIMIT 1
    ];

    if (!experianBusinesses.isEmpty()) {
      return experianBusinesses[0];
    }

    // If no existing record, try to create one
    try {
      Experian_Business__c newBusiness = BusinessSearch.createExperianBusinessFromAccount(
        accountId
      );
      if (newBusiness != null) {
        return newBusiness;
      }
    } catch (Exception e) {
      System.debug(
        'Error creating Experian Business record: ' + e.getMessage()
      );
    }

    // If we couldn't find or create a record, return null
    return null;
  }

  private static Experian_Decision__c createExperianDecisionRecord(
    String accountId,
    String score,
    String decision,
    String creditLimit,
    String triggeredRule
  ) {
    Experian_Decision__c newDecision = new Experian_Decision__c(
      Account__c = accountId,
      Score__c = score,
      Decision__c = decision,
      Credit_Limit__c = creditLimit,
      Triggered_Rule__c = triggeredRule,
      Name = 'Decision ' + Datetime.now().format('yyyy-MM-dd HH:mm:ss')
    );

    insert newDecision;
    return newDecision;
  }

  private static String getStatusClass(String decision) {
    switch on decision.toUpperCase() {
      when 'APPROVE' {
        return 'slds-text-color_success';
      }
      when 'DECLINE' {
        return 'slds-text-color_error';
      }
      when 'MANUAL REVIEW' {
        return 'slds-text-color_warning';
      }
      when else {
        return 'slds-text-color_weak';
      }
    }
  }

  private static String getStatusIcon(String decision) {
    switch on decision.toUpperCase() {
      when 'APPROVE' {
        return 'utility:check';
      }
      when 'DECLINE' {
        return 'utility:close';
      }
      when 'MANUAL REVIEW' {
        return 'utility:warning';
      }
      when else {
        return 'utility:help';
      }
    }
  }
}
