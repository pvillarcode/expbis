public with sharing class PullReport {
  private static final String DEFAULT_SUBCODE = '0517614';
  private static final String ENDPOINT_PDF_URL = 'https://sandbox-us-api.experian.com/businessinformation/businesses/v1/reports/premierprofiles/pdf';
  private static final String ENDPOINT_JSON_URL = 'https://sandbox-us-api.experian.com/businessinformation/businesses/v1/reports/premierprofiles';
  private static final Integer TIMEOUT = 120000;

  @AuraEnabled
  public static String getReport() {
    Experian_Configuration__c setting = ExperianApiService.getBIQConfig();
    try {
      PullReportReqWrapper reqWrapper = new PullReportReqWrapper();

      reqWrapper.subcode = DEFAULT_SUBCODE;
      reqWrapper.bin = '722799117';

      String pdfRerportData = getPDFreport(reqWrapper);
      String jsonReportData = getJsonReport(reqWrapper);

      return pdfRerportData;
    } catch (Exception e) {
      System.debug('Error: ' + e.getMessage());
    }
    return null;
  }

  @AuraEnabled
  public static Id savePDFToSalesforce(String base64Data, String fileName) {
    ContentVersion cv = new ContentVersion();
    cv.VersionData = EncodingUtil.base64Decode(base64Data);
    cv.Title = fileName;
    cv.PathOnClient = fileName + '.pdf';
    insert cv;

    return cv.Id;
  }

  @AuraEnabled
  public static Id saveExperianInformation(String jsonData) {
    Map<String, Object> parsedData = (Map<String, Object>) JSON.deserializeUntyped(
      jsonData
    );
    Map<String, Object> results = (Map<String, Object>) parsedData.get(
      'results'
    );

    Id accountId = createAccount(results);
    return accountId;
  }

  private static Id createAccount(Map<String, Object> results) {
    Map<String, Object> businessHeader = (Map<String, Object>) results.get(
      'businessHeader'
    );
    Map<String, Object> address = (Map<String, Object>) businessHeader.get(
      'address'
    );

    Account newAccount = new Account(
      Name = (String) businessHeader.get('businessName'),
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

  @AuraEnabled
  public static String getJSONReport(PullReportReqWrapper reqWrapper2) {
    Experian_Configuration__c setting = ExperianApiService.getBIQConfig();

    PullReportReqWrapper reqWrapper = new PullReportReqWrapper();

    reqWrapper.subcode = DEFAULT_SUBCODE;
    reqWrapper.bin = '988793145';

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
  public static String getPDFReport(PullReportReqWrapper reqWrapper2) {
    Experian_Configuration__c setting = ExperianApiService.getBIQConfig();

    PullReportReqWrapper reqWrapper = new PullReportReqWrapper();

    reqWrapper.subcode = DEFAULT_SUBCODE;
    reqWrapper.bin = '988793145';

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
}
