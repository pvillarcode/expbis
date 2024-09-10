public with sharing class PullReport {
  private static final String DEFAULT_SUBCODE = '0517614';
  private static final String ENDPOINT_PDF_URL = 'https://sandbox-us-api.experian.com/businessinformation/businesses/v1/reports/premierprofiles/pdf';
  private static final String ENDPOINT_JSON_URL = 'https://sandbox-us-api.experian.com/businessinformation/businesses/v1/reports/premierprofiles';
  private static final Integer TIMEOUT = 120000;

  @AuraEnabled
  public static Map<String, Object> initiateReportProcess(
    String jsonData,
    Id accountId
  ) {
    System.debug(
      'Starting initiateReportProcess with jsonData: ' +
        jsonData +
        ' and accountId: ' +
        accountId
    );
    try {
      // Parse the JSON data
      Map<String, Object> businessData = (Map<String, Object>) JSON.deserializeUntyped(
        jsonData
      );
      System.debug('Parsed businessData: ' + businessData);
      String bin = (String) businessData.get('BIN');
      System.debug('Extracted BIN: ' + bin);

      // Find or create the account
      if (accountId == null) {
        System.debug('accountId is null, calling findOrCreateAccount');
        accountId = findOrCreateAccount(businessData);
        System.debug('Created or found accountId: ' + accountId);
      }

      // Return the accountId and other necessary information
      Map<String, Object> result = new Map<String, Object>{
        'accountId' => accountId,
        'bin' => bin
      };
      System.debug('Returning result: ' + result);
      return result;
    } catch (Exception e) {
      System.debug('Exception caught: ' + e.getMessage());
      throw new AuraHandledException(
        'Error initiating report process: ' + e.getMessage()
      );
    }
  }

  @AuraEnabled
  public static Map<String, Object> completeReportProcess(
    Id accountId,
    String bin
  ) {
    System.debug(
      'Starting completeReportProcess with accountId: ' +
        accountId +
        ' and bin: ' +
        bin
    );
    try {
      // Make the callouts
      String jsonReport = getJSONReport(bin);
      System.debug('Retrieved JSON report: ' + jsonReport);
      String pdfReport = getPDFReport(bin);
      System.debug('Retrieved PDF report');

      // Process and save the data
      Experian_Business__c experianBusiness = saveExperianInformation(
        jsonReport,
        accountId
      );
      System.debug('Saved Experian information: ' + experianBusiness);

      String contentDocumentId = savePDFToSalesforce(
        pdfReport,
        'PremierProfile_' + System.now().getTime(),
        accountId
      );
      System.debug(
        'Saved PDF to Salesforce with contentDocumentId: ' + contentDocumentId
      );

      return new Map<String, Object>{
        'accountId' => accountId,
        'contentDocumentId' => contentDocumentId
      };
    } catch (System.LimitException e) {
      System.debug('Storage limit exception: ' + e.getMessage());
      throw new AuraHandledException(
        'Storage limit exceeded. Please contact your administrator.'
      );
    } catch (Exception e) {
      System.debug('Exception caught: ' + e.getMessage());
      throw new AuraHandledException(
        'Error completing report process: ' + e.getMessage()
      );
    }
  }

  @AuraEnabled
  public static List<Experian_Scoring_Model__c> getScoringModels() {
    ExperianApiService.ExperianConfigWrapper wrapper = ExperianApiService.getBIQConfig();
    Experian_Configuration__c setting = wrapper.config;
    ExperianApiService.ExperianEndpoints endpoints = wrapper.endpoints;

    List<Experian_Scoring_Model__c> scoringModels = [
      SELECT Id, Name, Model_Code__c
      FROM Experian_Scoring_Model__c
      WHERE Experian_Configuration__c = :setting.Id
    ];

    return scoringModels;
  }

  private static String getJSONReport(String bin) {
    ExperianApiService.ExperianConfigWrapper wrapper = ExperianApiService.getBIQConfig();
    Experian_Configuration__c setting = wrapper.config;
    ExperianApiService.ExperianEndpoints endpoints = wrapper.endpoints;

    HttpRequest req = new HttpRequest();
    System.debug('Initializing HttpRequest');

    req.setEndpoint(endpoints.premierProfileJsonUrl);
    System.debug('Set endpoint: ' + endpoints.premierProfileJsonUrl);

    req.setMethod('POST');
    System.debug('Set method to POST');

    req.setHeader('Content-Type', 'application/json');
    System.debug('Set Content-Type header to application/json');

    req.setHeader(
      'Authorization',
      'Bearer ' + setting.Experian_Access_Token__c
    );
    System.debug('Set Authorization header with token');

    Map<String, Object> requestBody = new Map<String, Object>{
      'bin' => bin,
      'subcode' => setting.Default_Subcode__c
    };
    req.setBody(JSON.serialize(requestBody));
    System.debug('Set request body: ' + JSON.serialize(requestBody));

    Http http = new Http();
    System.debug('Initialized Http object');

    HttpResponse res = http.send(req);
    System.debug('Sent HTTP request');

    if (res.getStatusCode() != 200) {
      System.debug('Failed to get JSON report. Status: ' + res.getStatus());
      throw new AuraHandledException(
        'Failed to get JSON report. Status: ' + res.getStatus()
      );
    }

    System.debug('Successfully received response');
    return res.getBody();
  }

  @AuraEnabled
  public static String getPDFReport(String bin) {
    ExperianApiService.ExperianConfigWrapper wrapper = ExperianApiService.getBIQConfig();
    Experian_Configuration__c setting = wrapper.config;
    ExperianApiService.ExperianEndpoints endpoints = wrapper.endpoints;

    if (String.isBlank(bin)) {
      System.debug('BIN is blank, returning null');
      return null;
    }

    System.debug('BIN is not blank, proceeding with HTTP request');

    HttpRequest req = new HttpRequest();
    System.debug('Initialized HttpRequest');

    req.setMethod('POST');
    System.debug('Set method to POST');

    req.setTimeout(TIMEOUT);
    System.debug('Set timeout to ' + TIMEOUT);

    req.setEndpoint(endpoints.premierProfilePdfUrl);
    System.debug('Set endpoint: ' + endpoints.premierProfilePdfUrl);

    req.setHeader('Accept', 'application/pdf');
    System.debug('Set Accept header to application/pdf');

    req.setHeader('Content-type', 'application/json');
    System.debug('Set Content-type header to application/json');

    req.setHeader(
      'Authorization',
      'Bearer ' + setting.Experian_Access_Token__c
    );
    System.debug('Set Authorization header with token');

    Map<String, Object> requestBody = new Map<String, Object>{
      'bin' => bin,
      'subcode' => setting.Default_Subcode__c
    };
    req.setBody(JSON.serialize(requestBody));
    System.debug('Set request body: ' + JSON.serialize(requestBody));

    Http http = new Http();
    System.debug('Initialized Http object');

    HttpResponse res = http.send(req);
    System.debug('Sent HTTP request');

    if (res.getStatusCode() != 200) {
      System.debug('Failed to get PDF report. Status: ' + res.getStatus());
      throw new AuraHandledException(
        'Failed to get PDF report. Status: ' + res.getStatus()
      );
    }

    return res.getBody();
  }

  @AuraEnabled
  public static String savePDFToSalesforce(
    String jsonResponse,
    String fileName,
    Id accountId
  ) {
    System.debug('Entering savePDFToSalesforce method');

    System.debug('fileName: ' + fileName);
    System.debug('accountId: ' + accountId);
    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
      jsonResponse
    );

    if (
      String.isBlank(jsonResponse) ||
      String.isBlank(fileName) ||
      accountId == null
    ) {
      System.debug('Invalid input detected');
      throw new AuraHandledException(
        'Invalid input: jsonResponse, fileName, and accountId are required.'
      );
    }

    if (responseMap.containsKey('results')) {
      String base64Data = (String) responseMap.get('results');

      if (fileName == null) {
        fileName =
          'PremierProfileReport_' + Datetime.now().format('yyyyMMdd_HHmmss');
      }

      Experian_Report__c experianReport = createExperianReport(
        accountId,
        fileName
      );
      String contentDocumentId = createContentVersion(
        base64Data,
        fileName,
        experianReport.Id
      );

      return contentDocumentId;
    } else {
      throw new AuraHandledException('No results found in the API response');
    }
  }

  private static Experian_Report__c createExperianReport(
    Id accountId,
    String fileName
  ) {
    Experian_Report__c experianReport = new Experian_Report__c(
      Account__c = accountId,
      Name = fileName
    );
    insert experianReport;
    return experianReport;
  }

  private static String createContentVersion(
    String base64Data,
    String fileName,
    Id linkedRecordId
  ) {
    try {
      ExperianLogger.log(
        'Creating Content Version for file: ' + fileName,
        ExperianLogger.LogLevel.DEBUG
      );
      ContentVersion cv = new ContentVersion();
      cv.VersionData = EncodingUtil.base64Decode(base64Data);
      cv.Title = fileName;
      cv.PathOnClient = fileName + '.pdf';
      insert cv;

      cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
      ExperianLogger.log(
        'ContentDocumentId retrieved: ' + cv.ContentDocumentId,
        ExperianLogger.LogLevel.DEBUG
      );

      ContentDocumentLink cdl = new ContentDocumentLink();
      cdl.ContentDocumentId = cv.ContentDocumentId;
      cdl.LinkedEntityId = linkedRecordId;
      cdl.ShareType = 'V';
      insert cdl;

      ExperianLogger.log(
        'Content Version created and linked successfully',
        ExperianLogger.LogLevel.DEBUG
      );
      return cv.ContentDocumentId;
    } catch (Exception e) {
      System.debug(
        'Error creating Content Version: ' +
          e.getMessage() +
          '\n' +
          e.getStackTraceString()
      );
      ExperianLogger.log(
        'Error creating Content Version: ' +
          e.getMessage() +
          '\n' +
          e.getStackTraceString(),
        ExperianLogger.LogLevel.ERROR
      );
      throw new AuraHandledException(
        'Error creating Content Version: ' + e.getMessage()
      );
    }
  }

  private static Experian_Business__c saveExperianInformation(
    String jsonReport,
    Id accountId
  ) {
    try {
      Map<String, Object> parsedData = (Map<String, Object>) JSON.deserializeUntyped(
        jsonReport
      );
      Map<String, Object> results = (Map<String, Object>) parsedData.get(
        'results'
      );

      Experian_Business__c business = getOrUpdateBusiness(results, accountId);

      return business;
    } catch (Exception e) {
      throw new AuraHandledException(
        'Error saving Experian Business Information: ' + e.getMessage()
      );
    }
  }

  public static Id findOrCreateAccount(Map<String, Object> businessData) {
    AccountInfo accountInfo = extractAccountInfo(businessData);

    Id accountId = findExactMatch(accountInfo);
    if (accountId != null) {
      return accountId;
    }

    accountId = findPotentialDuplicate(accountInfo);
    if (accountId != null) {
      return accountId;
    }

    return createNewAccount(accountInfo);
  }

  private static Id findExactMatch(AccountInfo info) {
    List<Account> exactMatches = [
      SELECT Id
      FROM Account
      WHERE
        Name = :info.name
        AND BillingStreet = :info.street
        AND BillingCity = :info.city
        AND BillingState = :info.state
        AND BillingPostalCode = :info.zip
      LIMIT 1
    ];

    if (!exactMatches.isEmpty()) {
      System.debug(
        'Exact match found. Returning account Id: ' + exactMatches[0].Id
      );
      return exactMatches[0].Id;
    }
    return null;
  }

  private static AccountInfo extractAccountInfo(
    Map<String, Object> businessData
  ) {
    AccountInfo info = new AccountInfo();
    info.name = (String) businessData.get('name');
    info.street = (String) businessData.get('address');
    info.city = (String) businessData.get('city');
    info.state = (String) businessData.get('state');
    info.zip = (String) businessData.get('zip');
    info.phone = (String) businessData.get('phone');
    info.website = (String) businessData.get('websiteUrl');

    System.debug('Extracted AccountInfo: ' + info);
    return info;
  }

  private static Id findPotentialDuplicate(AccountInfo info) {
    List<Account> potentialDuplicates = [
      SELECT
        Id,
        Name,
        BillingStreet,
        BillingCity,
        BillingState,
        BillingPostalCode
      FROM Account
      WHERE
        BillingStreet = :info.street
        AND BillingCity = :info.city
        AND BillingState = :info.state
        AND BillingPostalCode = :info.zip
      LIMIT 5
    ];

    System.debug('Potential duplicates found: ' + potentialDuplicates.size());

    if (!potentialDuplicates.isEmpty()) {
      for (Account acc : potentialDuplicates) {
        System.debug(
          'Potential duplicate: ' +
            acc.Name +
            ' at ' +
            acc.BillingStreet +
            ', ' +
            acc.BillingCity
        );
      }
      return potentialDuplicates[0].Id;
    }
    return null;
  }

  private static Id createNewAccount(AccountInfo info) {
    System.debug('No duplicates found. Attempting to create new account.');

    Account newAccount = new Account(
      Name = info.name,
      BillingStreet = info.street,
      BillingCity = info.city,
      BillingState = info.state,
      BillingPostalCode = info.zip,
      Phone = info.phone,
      Website = info.website
    );

    try {
      insert newAccount;
      System.debug('New account created successfully. Id: ' + newAccount.Id);
      return newAccount.Id;
    } catch (DmlException e) {
      System.debug('Error creating account: ' + e.getMessage());
      throw new AuraHandledException(
        'Error creating account: ' + e.getMessage()
      );
    }
  }

  private class AccountInfo {
    public String name, street, city, state, zip, phone, website;

    public override String toString() {
      return String.format(
        'AccountInfo: {0} at {1}, {2}, {3} {4}',
        new List<String>{ name, street, city, state, zip }
      );
    }
  }

  private static Experian_Business__c getOrUpdateBusiness(
    Map<String, Object> results,
    Id accountId
  ) {
    try {
      if (!Schema.sObjectType.Experian_Business__c.isAccessible()) {
        throw new AuraHandledException(
          'Insufficient permissions to access Experian_Business__c.'
        );
      }
      Experian_Business__c business = getExistingOrNewBusiness(accountId);

      updateBusinessFields(business, results);

      if (
        !Schema.sObjectType.Experian_Business__c.isCreateable() ||
        !Schema.sObjectType.Experian_Business__c.isUpdateable()
      ) {
        throw new AuraHandledException(
          'Insufficient permissions to create or update Experian_Business__c.'
        );
      }
      upsert business;
      return business;
    } catch (Exception e) {
      System.debug('Error message: ' + e.getMessage());
      System.debug('Stack trace: ' + e.getStackTraceString());
      System.debug('Line number: ' + e.getLineNumber());
      throw new AuraHandledException(
        'Error saving Experian Business Information: ' + e.getMessage()
      );
    }
  }

  private static Experian_Business__c getExistingOrNewBusiness(Id accountId) {
    List<Experian_Business__c> existingBusinesses = [
      SELECT Id
      FROM Experian_Business__c
      WHERE Account__c = :accountId
      LIMIT 1
    ];

    return !existingBusinesses.isEmpty()
      ? existingBusinesses[0]
      : new Experian_Business__c(Account__c = accountId);
  }

  private static void updateBusinessFields(
    Experian_Business__c business,
    Map<String, Object> results
  ) {
    updateBusinessHeaderFields(
      business,
      (Map<String, Object>) results.get('businessHeader')
    );
    updateBusinessFactsFields(
      business,
      (Map<String, Object>) results.get('businessFacts')
    );
    updateScoreInformationFields(
      business,
      (Map<String, Object>) results.get('scoreInformation')
    );
    updateCommercialFraudFields(
      business,
      (Map<String, Object>) results.get('commercialFraudShieldSummary')
    );
  }

  private static void updateCommercialFraudFields(
    Experian_Business__c business,
    Map<String, Object> commercialFraudShieldSummary
  ) {
    if (commercialFraudShieldSummary != null) {
      business.cfs_Active_Business_Indicator__c = getSafeBoolean(
        commercialFraudShieldSummary,
        'activeBusinessIndicator'
      );
      business.cfs_Business_Risk_Triggers_Indicator__c = getSafeBoolean(
        commercialFraudShieldSummary,
        'businessRiskTriggersIndicator'
      );
      business.cfs_Matching_Business_Indicator__c = getSafeString(
        commercialFraudShieldSummary,
        'matchingBusinessIndicator'
      );
      business.cfs_Name_Address_Verification_Indicator__c = getSafeBoolean(
        commercialFraudShieldSummary,
        'nameAddressVerificationIndicator'
      );
      business.cfs_Victim_Statement_Indicator__c = getSafeBoolean(
        commercialFraudShieldSummary,
        'businessVictimStatementIndicator'
      );
      Map<String, Object> ofacMatchWarning = (Map<String, Object>) commercialFraudShieldSummary.get(
        'ofacMatchWarning'
      );
      if (ofacMatchWarning != null) {
        business.cfs_Possible_OFAC_Match__c = getSafeString(
          ofacMatchWarning,
          'definition'
        );
      }
    }
  }

  private static void updateBusinessHeaderFields(
    Experian_Business__c business,
    Map<String, Object> businessHeader
  ) {
    if (businessHeader != null) {
      Map<String, Object> address = (Map<String, Object>) businessHeader.get(
        'address'
      );
      business.BIN__c = getSafeString(businessHeader, 'bin');
      business.Name = getSafeString(businessHeader, 'businessName');
      business.Business_Phone__c = getSafeString(businessHeader, 'phone');
      business.City__c = getSafeString(address, 'city');
      business.State__c = getSafeString(address, 'state');
      business.Zip__c = getSafeString(address, 'zip');
    }
  }

  private static void updateBusinessFactsFields(
    Experian_Business__c business,
    Map<String, Object> businessFacts
  ) {
    if (businessFacts != null) {
      business.bf_business_type__c = getSafeString(
        businessFacts,
        'businessType'
      );
      business.bf_Date_of_Incorporation__c = getSafeString(
        businessFacts,
        'dateOfIncorporation'
      );
      business.bf_File_Established_Date__c = getSafeString(
        businessFacts,
        'fileEstablishedDate'
      );
      business.bf_Years_In_Business__c = getSafeString(
        businessFacts,
        'yearsInBusiness'
      );
    }
  }

  private static void updateScoreInformationFields(
    Experian_Business__c business,
    Map<String, Object> scoreInformation
  ) {
    if (scoreInformation != null) {
      updateFSRScoreFields(
        business,
        (Map<String, Object>) scoreInformation.get('fsrScore')
      );
      updateCommercialScoreFields(
        business,
        (Map<String, Object>) scoreInformation.get('commercialScore')
      );
    }
  }

  private static void updateFSRScoreFields(
    Experian_Business__c business,
    Map<String, Object> fsrScore
  ) {
    if (fsrScore != null) {
      business.FSR_Score__c = getSafeString(fsrScore, 'score');
      business.FSR_Model_Code__c = getSafeString(fsrScore, 'modelCode');
      business.FSR_Model_Title__c = getSafeString(fsrScore, 'modelTitle');
      business.FSR_Dispute_Indicator__c = getSafeBoolean(
        fsrScore,
        'customerDisputeIndicator'
      );

      Map<String, Object> riskClass = (Map<String, Object>) fsrScore.get(
        'riskClass'
      );
      if (riskClass != null) {
        business.FSR_Risk_Code__c = getSafeString(riskClass, 'code');
        business.FSR_Risk_Definition__c = getSafeString(
          riskClass,
          'definition'
        );
      }
    }
  }

  private static void updateCommercialScoreFields(
    Experian_Business__c business,
    Map<String, Object> commercialScore
  ) {
    if (commercialScore != null) {
      business.Commercial_Score__c = getSafeString(commercialScore, 'score');
      business.Commercial_Model_Code__c = getSafeString(
        commercialScore,
        'modelCode'
      );
      business.Commercial_Model_Title__c = getSafeString(
        commercialScore,
        'modelTitle'
      );
      business.Commercial_Credit_Limit_Recommendation__c = getSafeString(
        commercialScore,
        'recommendedCreditLimitAmount'
      );
      business.Commercial_Dispute_Indicator__c = getSafeBoolean(
        commercialScore,
        'customerDisputeIndicator'
      );

      Map<String, Object> riskClass = (Map<String, Object>) commercialScore.get(
        'riskClass'
      );
      if (riskClass != null) {
        business.Commercial_Risk_Code__c = getSafeString(riskClass, 'code');
        business.Commercial_Risk_Definition__c = getSafeString(
          riskClass,
          'definition'
        );
      }
    }
  }

  private static String getSafeString(Map<String, Object> data, String key) {
    Object value = data.get(key);
    return value != null ? String.valueOf(value) : null;
  }

  private static Integer getSafeInteger(Map<String, Object> data, String key) {
    Object value = data.get(key);
    return value != null ? Integer.valueOf(value) : null;
  }

  private static Boolean getSafeBoolean(Map<String, Object> data, String key) {
    Object value = data.get(key);
    return value != null ? Boolean.valueOf(value) : false;
  }

  private static Date getSafeDate(Map<String, Object> data, String key) {
    String dateStr = getSafeString(data, key);
    return String.isNotBlank(dateStr) ? Date.valueOf(dateStr) : null;
  }

  // Method to safely get nested values
  private static Object getNestedValue(
    Map<String, Object> data,
    String[] keys
  ) {
    Object current = data;
    for (String key : keys) {
      if (current instanceof Map<String, Object>) {
        current = ((Map<String, Object>) current).get(key);
        if (current == null) {
          return null;
        }
      } else {
        return null;
      }
    }
    return current;
  }

  // Convenience methods for nested values
  private static String getNestedString(
    Map<String, Object> data,
    String[] keys
  ) {
    Object value = getNestedValue(data, keys);
    return value != null ? String.valueOf(value) : null;
  }

  private static Integer getNestedInteger(
    Map<String, Object> data,
    String[] keys
  ) {
    Object value = getNestedValue(data, keys);
    return value != null ? Integer.valueOf(value) : null;
  }
}
