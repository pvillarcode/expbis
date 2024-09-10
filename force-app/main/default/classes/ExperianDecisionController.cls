public with sharing class ExperianDecisionController {
  private static final String DEFAULT_SUBCODE = '0997193';
  private static final String ENDPOINT_JSON_URL = 'https://sandbox-us-api.experian.com/businessinformation/decisioniq/v1/basicdecisions';
  private static final Integer TIMEOUT = 120000;
  private static final String USER_ID = 'qa_admin';
  private static final Integer MIN_RELIABILITY_CODE = 95;

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
    System.debug('pullNewDecision called with accountId: ' + accountId);
    try {
      // Check for existing Experian_Business__c record
      Experian_Business__c experianBusiness = getExperianBusinessForAccount(
        accountId
      );

      String bin;
      String experianName;
      Decimal reliabilityCode;
      BusinessSearch.BusinessResult businessResult;

      if (
        experianBusiness != null && String.isNotBlank(experianBusiness.BIN__c)
      ) {
        // Use existing BIN
        bin = experianBusiness.BIN__c;
        experianName = experianBusiness.Name;
        reliabilityCode = 100; // Assume high reliability for existing records
      } else {
        // No existing BIN, use getLOS
        Account acc = BusinessSearch.getAccountDetails(accountId);

        // Prepare search criteria for getLOS
        Map<String, String> searchCriteria = new Map<String, String>{
          'businessName' => acc.Name,
          'address' => acc.BillingStreet,
          'city' => acc.BillingCity,
          'state' => acc.BillingState,
          'zipcode' => acc.BillingPostalCode
        };

        // Call getLOS to get the BIN
        List<BusinessSearch.BusinessResult> results = BusinessSearch.getLOS(
          searchCriteria
        );

        if (results.isEmpty()) {
          return new Map<String, Object>{
            'success' => false,
            'message' => 'No matching business found in Experian database.'
          };
        }

        businessResult = results[0];
        bin = businessResult.bin;
        experianName = businessResult.name;
        reliabilityCode = businessResult.reliabilityCode;
      }

      if (reliabilityCode <= MIN_RELIABILITY_CODE) {
        return new Map<String, Object>{
          'success' => false,
          'message' => 'Reliability code (' +
          reliabilityCode +
          ') is too low for business ' +
          experianName +
          ' with BIN ' +
          bin +
          '.'
        };
      }

      // Create Experian_Business__c record if it doesn't exist and reliabilityCode is sufficient
      if (experianBusiness == null && businessResult != null) {
        experianBusiness = createExperianBusinessRecord(
          accountId,
          businessResult
        );
      }

      // Call the API using the separate method
      System.debug('Calling getDecisionApiCall with BIN: ' + bin);
      Map<String, Object> apiResponse = getDecisionApiCall(bin);
      System.debug('API Response: ' + apiResponse);

      if (apiResponse.containsKey('error')) {
        System.debug('API returned an error: ' + apiResponse.get('error'));
        return new Map<String, Object>{
          'success' => false,
          'message' => (String) apiResponse.get('error')
        };
      }

      // Process the successful response
      System.debug('Creating Experian Decision record');
      Experian_Decision__c newDecision = createExperianDecisionRecord(
        accountId,
        apiResponse
      );
      System.debug('New Experian Decision record: ' + newDecision);

      return new Map<String, Object>{
        'success' => true,
        'decision' => newDecision,
        'message' => 'Experian Decision pulled successfully for Business ' +
        experianName +
        ' with BIN ' +
        bin +
        '.'
      };
    } catch (Exception e) {
      System.debug('Exception occurred: ' + e.getMessage());
      ExperianLogger.log(
        'Error pulling new decision: ' + e.getMessage(),
        ExperianLogger.LogLevel.ERROR
      );
      throw new AuraHandledException(
        'Error pulling new decision: ' + e.getMessage()
      );
    }
  }

  private static Experian_Business__c getExperianBusinessForAccount(
    String accountId
  ) {
    List<Experian_Business__c> experianBusinesses = [
      SELECT Id, Name, BIN__c
      FROM Experian_Business__c
      WHERE Account__c = :accountId AND BIN__c != NULL
      LIMIT 1
    ];
    return experianBusinesses.isEmpty() ? null : experianBusinesses[0];
  }

  private static Experian_Business__c createExperianBusinessRecord(
    String accountId,
    BusinessSearch.BusinessResult businessResult
  ) {
    Experian_Business__c newBusiness = new Experian_Business__c(
      Account__c = accountId,
      Name = businessResult.name,
      BIN__c = businessResult.bin,
      Street_Address__c = businessResult.address,
      City__c = businessResult.city,
      State__c = businessResult.state,
      Zip__c = businessResult.zip
    );
    insert newBusiness;
    return newBusiness;
  }

  private static Map<String, Object> getDecisionApiCall(String bin) {
    ExperianApiService.ExperianConfigWrapper wrapper = ExperianApiService.getBIQConfig();
    Experian_Configuration__c setting = wrapper.config;
    ExperianApiService.ExperianEndpoints endpoints = wrapper.endpoints;

    // Construct the request body
    Map<String, Object> requestBody = new Map<String, Object>{
      'comments' => 'Testing',
      'bin' => bin,
      'creditPolicyId' => setting.DecisionIQ_Default_Policy_ID__c,
      'subcode' => setting.Decision_IQ_Subcode__c,
      'userId' => setting.DIQ_user_id__c
    };

    // Serialize the request body to JSON
    String jsonBody = JSON.serialize(requestBody);
    System.debug(requestBody);

    // Set up the HTTP request
    HttpRequest req = new HttpRequest();
    req.setMethod('POST');
    req.setTimeout(TIMEOUT);
    req.setEndpoint(endpoints.decisionBasicUrl);
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
