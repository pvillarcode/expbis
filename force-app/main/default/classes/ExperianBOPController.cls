public with sharing class ExperianBOPController {
  private static final String DEFAULT_SUBCODE = '0517614';
  private static final String ENDPOINT_JSON_URL = 'https://sandbox-us-api.experian.com/businessinformation/businessowners/v1/reports/bop/pdf';
  private static final Integer TIMEOUT = 120000;

  @AuraEnabled
  public static String pullBOPReport(String formData) {
    // Check if formData is null or empty
    if (String.isBlank(formData)) {
      throw new AuraHandledException('Form data is empty or null');
    }

    try {
      // Parse the formData JSON string into a Map
      Experian_Configuration__c setting = ExperianApiService.getBIQConfig();
      Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(
        formData
      );

      // Create the JSON structure
      Map<String, Object> jsonRequest = new Map<String, Object>();
      jsonRequest.put('subcode', DEFAULT_SUBCODE);
      jsonRequest.put('comments', 'Test comment');

      Map<String, Object> ownerName = new Map<String, Object>();
      ownerName.put('lastName', (String) data.get('ownerLastName'));
      ownerName.put('firstName', (String) data.get('ownerFirstName'));
      ownerName.put('middleName', (String) data.get('ownerMiddleName'));
      ownerName.put('generationCode', (String) data.get('ownerGenerationCode'));

      Map<String, Object> currentAddress = new Map<String, Object>();
      currentAddress.put('street', (String) data.get('street'));
      currentAddress.put('city', (String) data.get('city'));
      currentAddress.put('state', (String) data.get('state'));
      currentAddress.put('zip', (String) data.get('zip'));

      Map<String, Object> businessOwner = new Map<String, Object>();
      businessOwner.put('ownerName', ownerName);
      businessOwner.put('ssn', (String) data.get('ssn'));
      businessOwner.put('currentAddress', currentAddress);

      List<Map<String, Object>> businessOwners = new List<Map<String, Object>>();
      businessOwners.add(businessOwner);

      jsonRequest.put('businessOwners', businessOwners);

      // Serialize the JSON structure to a string
      String jsonString = JSON.serialize(jsonRequest);

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
      req.setBody(jsonString);

      Http http = new Http();
      HttpResponse res = http.send(req);

      // Debug the JSON string and response
      System.debug('JSON Request: ' + jsonString);
      System.debug('Response: ' + res.getBody());

      return res.getBody();
    } catch (Exception e) {
      System.debug('Error: ' + e.getMessage());
      throw new AuraHandledException(
        'Error processing request: ' + e.getMessage()
      );
    }
  }

  @AuraEnabled
  public static String pullAndSaveBOPReport(String formData, Id accountId) {
    try {
      String jsonResponse = pullBOPReport(formData);
      Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
        jsonResponse
      );

      if (responseMap.containsKey('results')) {
        String base64Data = (String) responseMap.get('results');
        String fileName =
          'ExperianBOPReport_' + Datetime.now().format('yyyyMMdd_HHmmss');

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
    } catch (Exception e) {
      System.debug('Error: ' + e.getMessage());
      throw new AuraHandledException(
        'Error processing and saving report: ' + e.getMessage()
      );
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
    ContentVersion cv = new ContentVersion();
    cv.VersionData = EncodingUtil.base64Decode(base64Data);
    cv.Title = fileName;
    cv.PathOnClient = fileName + '.pdf';
    insert cv;

    cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
    System.debug('ContentDocumentId retrieved: ' + cv.ContentDocumentId);

    ContentDocumentLink cdl = new ContentDocumentLink();
    cdl.ContentDocumentId = cv.ContentDocumentId;
    cdl.LinkedEntityId = linkedRecordId; // Link to the new Experian_Report__c record
    cdl.ShareType = 'V';
    insert cdl;

    return cv.ContentDocumentId;
  }
}
