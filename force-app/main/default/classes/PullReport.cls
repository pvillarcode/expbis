public with sharing class PullReport {
  private static final String DEFAULT_SUBCODE = '0517614';
  private static final String ENDPOINT_PDF_URL = 'https://sandbox-us-api.experian.com/businessinformation/businesses/v1/reports/premierprofiles/pdf';
  private static final String ENDPOINT_JSON_URL = 'https://sandbox-us-api.experian.com/businessinformation/businesses/v1/reports/premierprofiles';
  private static final Integer TIMEOUT = 120000;

  @AuraEnabled
  public static String getJSONReport(String jsonData) {
    Map<String, Object> businessMap = (Map<String, Object>) JSON.deserializeUntyped(
      jsonData
    );

    Experian_Configuration__c setting = ExperianApiService.getBIQConfig();

    PullReportReqWrapper reqWrapper = new PullReportReqWrapper();

    reqWrapper.subcode = DEFAULT_SUBCODE;
    reqWrapper.bin = (String) businessMap.get('BIN');

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
    req.setBody(JSON.serialize(reqWrapper, true));

    Http http = new Http();
    HttpResponse res = http.send(req);

    if (res.getStatusCode() == 200) {
      System.debug('Success Json response');
      return res.getBody();
    } else {
      System.debug('Error Json response');
      return 'Error';
    }
  }

  @AuraEnabled
  public static String getPDFReport(String jsonData) {
    System.debug('getJSON Report');
    System.debug(jsonData);
    Map<String, Object> businessMap = (Map<String, Object>) JSON.deserializeUntyped(
      jsonData
    );

    Experian_Configuration__c setting = ExperianApiService.getBIQConfig();

    PullReportReqWrapper reqWrapper = new PullReportReqWrapper();

    reqWrapper.subcode = DEFAULT_SUBCODE;
    reqWrapper.bin = (String) businessMap.get('BIN');

    HttpRequest req = new HttpRequest();
    req.setMethod('POST');
    req.setTimeout(TIMEOUT);
    req.setEndpoint(ENDPOINT_PDF_URL);
    req.setHeader('Accept', 'application/pdf');
    req.setHeader('Content-type', 'application/json');
    req.setHeader(
      'Authorization',
      'Bearer ' + setting.Experian_Access_Token__c
    );
    req.setBody(JSON.serialize(reqWrapper, true));

    Http http = new Http();
    HttpResponse res = http.send(req);

    if (res.getStatusCode() == 200) {
      System.debug('Success PDF report');
      return res.getBody();
    } else {
      System.debug('Error PDF report');
      System.debug('StatusCode: ' + res.getStatusCode());
      return 'Error';
    }
  }
  @AuraEnabled
  public static Id savePDFToSalesforce(
    String base64Data,
    String fileName,
    Id customObjectId
  ) {
    if (
      String.isBlank(base64Data) ||
      String.isBlank(fileName) ||
      customObjectId == null
    ) {
      throw new AuraHandledException(
        'Invalid input: base64Data, fileName, and customObjectId are required.'
      );
    }
    if (!Schema.sObjectType.ContentVersion.isCreateable()) {
      throw new AuraHandledException(
        'Insufficient permissions to create PDF file.'
      );
    }
    ContentVersion cv = new ContentVersion();
    cv.VersionData = EncodingUtil.base64Decode(base64Data);
    cv.Title = fileName;
    cv.PathOnClient = fileName + '.pdf';
    insert cv;

    if (!Schema.sObjectType.ContentDocumentLink.isCreateable()) {
      throw new AuraHandledException(
        'Insufficient permissions to create ContentDocumentLink.'
      );
    }
    cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

    ContentDocumentLink cdl = new ContentDocumentLink();
    cdl.ContentDocumentId = cv.ContentDocumentId;
    cdl.LinkedEntityId = customObjectId;
    cdl.ShareType = 'V';
    insert cdl;

    return cv.ContentDocumentId;
  }

  @AuraEnabled
  public static Id saveExperianInformation(String jsonData) {
    try {
      Map<String, Object> parsedData = (Map<String, Object>) JSON.deserializeUntyped(
        jsonData
      );
      Map<String, Object> results = (Map<String, Object>) parsedData.get(
        'results'
      );

      Id accountId = findOrcreateAccount(results);
      Id businessId = getOrUpdateBusiness(results, accountId);

      return businessId;
    } catch (Exception e) {
      throw new AuraHandledException(
        'Error saving Experian Business Information: ' + e.getMessage()
      );
    }
  }

  public static Id findOrCreateAccount(Map<String, Object> results) {
    System.debug('Entering findOrCreateAccount method');
    AccountInfo accountInfo = extractAccountInfo(results);

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

  private static AccountInfo extractAccountInfo(Map<String, Object> results) {
    Map<String, Object> businessHeader = (Map<String, Object>) results.get(
      'businessHeader'
    );
    Map<String, Object> address = (Map<String, Object>) businessHeader.get(
      'address'
    );

    AccountInfo info = new AccountInfo();
    info.name = (String) businessHeader.get('businessName');
    info.street = (String) address.get('street');
    info.city = (String) address.get('city');
    info.state = (String) address.get('state');
    info.zip = (String) address.get('zip');
    info.phone = (String) businessHeader.get('phone');
    info.website = (String) businessHeader.get('websiteUrl');

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

  private static Id getOrUpdateBusiness(
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
      return business.Id;
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
