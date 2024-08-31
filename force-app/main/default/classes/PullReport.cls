public with sharing class PullReport {
  private static final String DEFAULT_SUBCODE = '0517614';
  private static final String ENDPOINT_PDF_URL = 'https://sandbox-us-api.experian.com/businessinformation/businesses/v1/reports/premierprofiles/pdf';
  private static final String ENDPOINT_JSON_URL = 'https://sandbox-us-api.experian.com/businessinformation/businesses/v1/reports/premierprofiles';
  private static final Integer TIMEOUT = 120000;

  @AuraEnabled
  public static String getJSONReport(String jsonData) {
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

    ContentVersion cv = new ContentVersion();
    cv.VersionData = EncodingUtil.base64Decode(base64Data);
    cv.Title = fileName;
    cv.PathOnClient = fileName + '.pdf';
    insert cv;

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
      System.debug('Business: ' + businessId);
      //TODO update Related records

      return businessId;
    } catch (Exception e) {
      throw new AuraHandledException(
        'Error saving Experian Business Information: ' + e.getMessage()
      );
    }
  }

  private static Id findOrcreateAccount(Map<String, Object> results) {
    Map<String, Object> businessHeader = (Map<String, Object>) results.get(
      'businessHeader'
    );
    Map<String, Object> address = (Map<String, Object>) businessHeader.get(
      'address'
    );

    String accountName = (String) businessHeader.get('businessName');

    List<Account> existingAccounts = [
      SELECT Id
      FROM Account
      WHERE Name = :accountName
      LIMIT 1
    ];

    if (!existingAccounts.isEmpty()) {
      return existingAccounts[0].Id;
    } else {
      Account newAccount = new Account(
        Name = accountName,
        BillingStreet = (String) address.get('street'),
        BillingCity = (String) address.get('city'),
        BillingState = (String) address.get('state'),
        BillingPostalCode = (String) address.get('zip'),
        Phone = (String) businessHeader.get('phone'),
        Website = (String) businessHeader.get('websiteUrl')
      );
      insert newAccount;
      return newAccount.Id;
    }
  }

  private static Id getOrUpdateBusiness(
    Map<String, Object> results,
    Id accountId
  ) {
    try {
      List<Experian_Business__c> existingBusinesses = [
        SELECT Id
        FROM Experian_Business__c
        WHERE Account__c = :accountId
        LIMIT 1
      ];

      Experian_Business__c business;

      if (!existingBusinesses.isEmpty()) {
        business = existingBusinesses[0];
      } else {
        business = new Experian_Business__c(Account__c = accountId);
      }

      Map<String, Object> businessHeader = (Map<String, Object>) results.get(
        'businessHeader'
      );

      Map<String, Object> address = (Map<String, Object>) businessHeader.get(
        'address'
      );

      Map<String, Object> businessFacts = (Map<String, Object>) results.get(
        'businessFacts'
      );

      Map<String, Object> scoreInformation = (Map<String, Object>) results.get(
        'scoreInformation'
      );

      business.BIN__c = (String) businessHeader.get('bin');
      business.Name = (String) businessHeader.get('businessName');
      business.Business_Phone__c = (String) businessHeader.get('phone');
      business.City__c = (String) address.get('city');
      business.State__c = (String) address.get('state');
      business.Zip__c = (String) address.get('zip');

      business.bf_business_type__c = (String) businessFacts.get('businessType');
      business.bf_Date_of_Incorporation__c = (String) businessFacts.get(
        'dateOfIncorporation'
      );
      business.bf_File_Established_Date__c = (String) businessFacts.get(
        'fileEstablishedDate'
      );
      business.bf_Years_In_Business__c = getSafeString(
        businessFacts,
        'yearsInBusiness'
      );

      if (scoreInformation != null) {
        // FSR Score information
        Map<String, Object> fsrScore = (Map<String, Object>) scoreInformation.get(
          'fsrScore'
        );
        if (fsrScore != null) {
          business.FSR_Score__c = getSafeString(fsrScore, 'score');
          business.FSR_Model_Code__c = getSafeString(fsrScore, 'modelCode');
          business.FSR_Model_Title__c = getSafeString(fsrScore, 'modelTitle');
          business.FSR_Dispute_Indicator__c = getSafeBoolean(
            fsrScore,
            'customerDisputeIndicator'
          );

          // Accessing nested RiskClass
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
        } else {
          System.debug('FSR Score is null');
        }

        Map<String, Object> commercialScore = (Map<String, Object>) scoreInformation.get(
          'commercialScore'
        );
        if (commercialScore != null) {
          business.Commercial_Score__c = getSafeString(
            commercialScore,
            'score'
          );
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

          // Accessing nested RiskClass
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
        } else {
          System.debug('Commercial Score is null');
        }
      } else {
        System.debug('Score Information is null');
      }

      System.debug('Business: ' + business);
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

  // Helper methods for safe attribute access
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
