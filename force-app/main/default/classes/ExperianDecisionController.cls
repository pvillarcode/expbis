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
  public static Map<String, Object> initiateDecisionProcess(String accountId) {
    try {
      // Check for existing Experian_Business__c record
      Experian_Business__c experianBusiness = getExperianBusinessForAccount(
        accountId
      );

      if (
        experianBusiness != null && String.isNotBlank(experianBusiness.BIN__c)
      ) {
        // Existing business found, pull decision directly
        return pullDecisionForExistingBusiness(experianBusiness);
      } else {
        // No existing business, perform LOS search
        Account acc = BusinessSearch.getAccountDetails(accountId);
        Map<String, String> searchCriteria = new Map<String, String>{
          'businessName' => acc.Name,
          'address' => acc.BillingStreet,
          'city' => acc.BillingCity,
          'state' => acc.BillingState,
          'zipcode' => acc.BillingPostalCode
        };

        List<BusinessSearch.BusinessResult> results = BusinessSearch.getLOS(
          searchCriteria
        );

        if (results.isEmpty()) {
          return new Map<String, Object>{
            'success' => false,
            'message' => 'No matching businesses found in Experian database.'
          };
        }

        // Return the list of businesses for user selection
        return new Map<String, Object>{
          'success' => true,
          'businessResults' => results
        };
      }
    } catch (Exception e) {
      ExperianLogger.log(
        'Error initiating decision process: ' + e.getMessage(),
        ExperianLogger.LogLevel.ERROR
      );
      throw new AuraHandledException(
        'Error initiating decision process: ' + e.getMessage()
      );
    }
  }

  @AuraEnabled
  public static Map<String, Object> pullDecisionForSelectedBusiness(
    String accountId,
    String bin,
    String businessName,
    String street,
    String city,
    String state,
    String zip
  ) {
    try {
      Map<String, Object> apiResponse = getDecisionApiCall(bin);

      if (apiResponse.containsKey('error')) {
        return new Map<String, Object>{
          'success' => false,
          'message' => (String) apiResponse.get('error')
        };
      }

      // Extract necessary information from apiResponse
      String score = (String) apiResponse.get('score');
      String decision = (String) apiResponse.get('decision');
      String creditLimit = (String) apiResponse.get('creditLimit');
      String triggeredRule = (String) apiResponse.get('triggeredRule');

      // Create the Experian_Decision__c record synchronously
      Experian_Decision__c newDecision = createExperianDecisionRecord(
        accountId,
        score,
        decision,
        creditLimit,
        triggeredRule
      );

      // Create the Experian_Business__c record asynchronously
      createExperianBusinessAsync(
        accountId,
        bin,
        businessName,
        street,
        city,
        state,
        zip
      );

      return new Map<String, Object>{
        'success' => true,
        'decision' => newDecision,
        'message' => 'Experian Decision pulled successfully for Business ' +
        businessName +
        ' with BIN ' +
        bin +
        '.'
      };
    } catch (Exception e) {
      ExperianLogger.log(
        'Error pulling decision for selected business: ' + e.getMessage(),
        ExperianLogger.LogLevel.ERROR
      );
      throw new AuraHandledException(
        'Error pulling decision for selected business: ' + e.getMessage()
      );
    }
  }
  private static Map<String, Object> pullDecisionForExistingBusiness(
    Experian_Business__c experianBusiness
  ) {
    try {
      Map<String, Object> apiResponse = getDecisionApiCall(
        experianBusiness.BIN__c
      );

      if (apiResponse.containsKey('error')) {
        return new Map<String, Object>{
          'success' => false,
          'message' => (String) apiResponse.get('error')
        };
      }

      // Extract necessary information from apiResponse
      String score = (String) apiResponse.get('score');
      String decision = (String) apiResponse.get('decision');
      String creditLimit = (String) apiResponse.get('creditLimit');
      String triggeredRule = (String) apiResponse.get('triggeredRule');

      // Process the successful response
      Experian_Decision__c newDecision = createExperianDecisionRecord(
        experianBusiness.Account__c,
        score,
        decision,
        creditLimit,
        triggeredRule
      );

      return new Map<String, Object>{
        'success' => true,
        'decision' => newDecision,
        'message' => 'Experian Decision pulled successfully for Business ' +
        experianBusiness.Name +
        ' with BIN ' +
        experianBusiness.BIN__c +
        '.'
      };
    } catch (Exception e) {
      ExperianLogger.log(
        'Error pulling decision for existing business: ' + e.getMessage(),
        ExperianLogger.LogLevel.ERROR
      );
      throw new AuraHandledException(
        'Error pulling decision for existing business: ' + e.getMessage()
      );
    }
  }

  @future
  private static void createExperianBusinessAsync(
    String accountId,
    String bin,
    String businessName,
    String street,
    String city,
    String state,
    String zip
  ) {
    try {
      Experian_Business__c experianBusiness = new Experian_Business__c(
        Account__c = accountId,
        Name = businessName,
        BIN__c = bin,
        Street_Address__c = street,
        City__c = city,
        State__c = state,
        Zip__c = zip
      );
      insert experianBusiness;
    } catch (Exception e) {
      ExperianLogger.log(
        'Error creating Experian Business record asynchronously: ' +
        e.getMessage(),
        ExperianLogger.LogLevel.ERROR
      );
    }
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
    newDecision = [
      SELECT
        Id,
        CreatedDate,
        Score__c,
        Decision__c,
        Credit_Limit__c,
        Triggered_Rule__c
      FROM Experian_Decision__c
      WHERE Id = :newDecision.Id
      LIMIT 1
    ];

    return newDecision;
  }

  private static Experian_Business__c getExperianBusinessForAccount(
    String accountId
  ) {
    List<Experian_Business__c> experianBusinesses = [
      SELECT Id, Name, BIN__c, Account__c
      FROM Experian_Business__c
      WHERE Account__c = :accountId AND BIN__c != NULL
      LIMIT 1
    ];
    return experianBusinesses.isEmpty() ? null : experianBusinesses[0];
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
}
