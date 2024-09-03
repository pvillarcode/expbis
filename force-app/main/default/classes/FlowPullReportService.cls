global with sharing class FlowPullReportService {
  @InvocableMethod(
    label='Get Business Report'
    description='Searches for a business, generates a PDF report, and creates or updates an Experian Business record'
  )
  global static List<ReportResult> getBusinessReport(
    List<BusinessReportRequest> requests
  ) {
    List<ReportResult> results = new List<ReportResult>();

    for (BusinessReportRequest request : requests) {
      ReportResult result = new ReportResult();
      try {
        // Call the future method to handle all operations
        processBusinessReportFuture(JSON.serialize(request));

        result.success = true;
        result.errorMessage = 'Business report processing initiated. Check related records shortly.';
      } catch (Exception e) {
        result.success = false;
        result.errorMessage = 'Error: ' + e.getMessage();
      }
      results.add(result);
    }

    return results;
  }

  @future(callout=true)
  private static void processBusinessReportFuture(String requestJson) {
    BusinessReportRequest request = (BusinessReportRequest) JSON.deserialize(
      requestJson,
      BusinessReportRequest.class
    );

    try {
      // Search for the business
      Map<String, String> searchCriteria = new Map<String, String>{
        'businessName' => request.businessName,
        'address' => request.address,
        'city' => request.city,
        'state' => request.state,
        'zipcode' => request.zip
      };

      List<BusinessSearch.BusinessResult> searchResults = BusinessSearch.getLOS(
        searchCriteria
      );

      if (!searchResults.isEmpty()) {
        // Assume the first result is the correct one
        BusinessSearch.BusinessResult businessInfo = searchResults[0];

        // Get JSON report
        String jsonResponse = PullReport.getJSONReport(
          JSON.serialize(new Map<String, Object>{ 'BIN' => businessInfo.bin })
        );

        // Generate PDF report
        String pdfResponse = PullReport.getPDFReport(
          JSON.serialize(new Map<String, Object>{ 'BIN' => businessInfo.bin })
        );

        // Now that all callouts are complete, perform DML operations

        // Create or update Experian Business record
        Id experianBusinessId = PullReport.saveExperianInformation(
          jsonResponse
        );

        // Update the Experian Business record with the Account ID
        updateExperianBusinessWithAccount(
          experianBusinessId,
          request.accountId
        );

        // Extract Base64 encoded PDF from JSON response
        Map<String, Object> pdfResponseMap = (Map<String, Object>) JSON.deserializeUntyped(
          pdfResponse
        );
        String base64EncodedPdf = (String) pdfResponseMap.get('results');

        // Save PDF to Salesforce and link to Experian Business record
        Experian_Business__c business = [
          SELECT Name
          FROM Experian_Business__c
          WHERE Id = :experianBusinessId
        ];
        String fileName = business.Name + ' Report pulled by Flows.pdf';

        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(base64EncodedPdf);
        cv.Title = fileName;
        cv.PathOnClient = fileName;
        insert cv;

        // Link ContentVersion to Experian Business record
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [
          SELECT ContentDocumentId
          FROM ContentVersion
          WHERE Id = :cv.Id
        ]
        .ContentDocumentId;
        cdl.LinkedEntityId = experianBusinessId;
        cdl.ShareType = 'V';
        insert cdl;
      } else {
        throw new BusinessReportException('No matching business found');
      }
    } catch (Exception e) {
      // Log the error or send a notification
      System.debug(
        'Error in processBusinessReportFuture method: ' + e.getMessage()
      );
    }
  }

  private static void updateExperianBusinessWithAccount(
    Id experianBusinessId,
    Id accountId
  ) {
    Experian_Business__c business = new Experian_Business__c(
      Id = experianBusinessId,
      Account__c = accountId
    );
    update business;
  }

  global class BusinessReportRequest {
    @InvocableVariable(required=true)
    global Id accountId;

    @InvocableVariable(required=true)
    global String businessName;

    @InvocableVariable
    global String address;

    @InvocableVariable
    global String city;

    @InvocableVariable
    global String state;

    @InvocableVariable
    global String zip;
  }

  global class ReportResult {
    @InvocableVariable
    global Boolean success;

    @InvocableVariable
    global String errorMessage;
  }

  public class BusinessReportException extends Exception {
  }
}
