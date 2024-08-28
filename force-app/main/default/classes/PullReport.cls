public with sharing class PullReport {
  private static final String DEFAULT_SUBCODE = '0517614';
  private static final String ENDPOINT_URL = 'https://sandbox-us-api.experian.com/businessinformation/businesses/v1/reports/premierprofiles/pdf';
  private static final Integer TIMEOUT = 120000;

  @AuraEnabled
  public static String getReport() {
    Experian_Configuration__c setting = ExperianApiService.getBIQConfig();
    try {
      PullReportReqWrapper reqWrapper = new PullReportReqWrapper();

      reqWrapper.subcode = DEFAULT_SUBCODE;
      reqWrapper.bin = '722799117';

      HttpRequest req = new HttpRequest();
      req.setMethod('POST');
      req.setTimeout(120000);
      req.setEndpoint(
        'https://sandbox-us-api.experian.com/businessinformation/businesses/v1/reports/premierprofiles/pdf'
      );
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
        System.debug('Success');
        return res.getBody();
      } else {
        System.debug('Error');
        return 'Error';
      }
    } catch (Exception e) {
      System.debug('Error: ' + e.getMessage());
      return e.getMessage();
    }
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
}
