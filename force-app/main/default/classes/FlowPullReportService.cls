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
      // Check for existing Experian_Business__c record with non-null BIN
      List<Experian_Business__c> existingBusinesses = [
        SELECT Id, BIN__c
        FROM Experian_Business__c
        WHERE Account__c = :request.accountId AND BIN__c != NULL
        LIMIT 1
      ];

      String bin;
      if (!existingBusinesses.isEmpty()) {
        // Use existing BIN
        bin = existingBusinesses[0].BIN__c;
      } else {
        // Search for the business using getLOS
        Map<String, String> searchCriteria = new Map<String, String>{
          'accountId' => request.accountId,
          'businessName' => request.businessName,
          'address' => request.address,
          'city' => request.city,
          'state' => request.state,
          'zipcode' => request.zip
        };

        List<BusinessSearch.BusinessResult> searchResults = BusinessSearch.getLOS(
          searchCriteria
        );

        if (searchResults.isEmpty()) {
          throw new BusinessReportException('No matching business found');
        }

        // Assume the first result is the correct one
        BusinessSearch.BusinessResult businessInfo = searchResults[0];
        bin = businessInfo.bin;
      }

      // Prepare the JSON data for pullAndProcessRepor

      // Call pullAndProcessReport
      Map<String, Object> result = PullReport.completeReportProcess(
        request.accountId,
        bin
      );

      // Check if the report was successfully processed
      if (
        result.containsKey('accountId') &&
        result.containsKey('contentDocumentId')
      ) {
        // Log success
        ExperianLogger.log(
          'Business report processed successfully for Account ID: ' +
            result.get('accountId') +
            ', ContentDocument ID: ' +
            result.get('contentDocumentId'),
          ExperianLogger.LogLevel.INFO
        );
      } else {
        throw new BusinessReportException('Failed to process business report');
      }
    } catch (Exception e) {
      // Log the error
      ExperianLogger.log(
        'Error in processBusinessReportFuture method: ' + e.getMessage(),
        ExperianLogger.LogLevel.ERROR
      );
      ExperianLogger.log(
        'Stack Trace: ' + e.getStackTraceString(),
        ExperianLogger.LogLevel.ERROR
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
