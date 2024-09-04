public with sharing class ExperianReportsController {
  public class PaginatedResult {
    @AuraEnabled
    public List<Experian_Report__c> records;
    @AuraEnabled
    public Integer totalRecords;

    public PaginatedResult(
      List<Experian_Report__c> records,
      Integer totalRecords
    ) {
      this.records = records;
      this.totalRecords = totalRecords;
    }
  }

  @AuraEnabled(cacheable=true)
  public static PaginatedResult getExperianReports(
    Id accountId,
    Integer pageSize,
    Integer pageNumber
  ) {
    System.debug('getExperianReports called');
    System.debug('accountId: ' + accountId);
    System.debug('pageSize: ' + pageSize);
    System.debug('pageNumber: ' + pageNumber);

    Integer offset = (pageNumber - 1) * pageSize;

    // Get total count
    Integer totalRecords = [
      SELECT COUNT()
      FROM Experian_Report__c
      WHERE Account__c = :accountId
    ];

    // Get paginated results
    List<Experian_Report__c> results = [
      SELECT
        Id,
        Name,
        CreatedDate,
        CreatedBy.Name,
        (
          SELECT ContentDocument.FileType, ContentDocumentId
          FROM ContentDocumentLinks
          ORDER BY SystemModstamp DESC
          LIMIT 1
        )
      FROM Experian_Report__c
      WHERE Account__c = :accountId
      ORDER BY CreatedDate DESC
      LIMIT :pageSize
      OFFSET :offset
    ];

    System.debug(
      'Returning ' +
        results.size() +
        ' records out of ' +
        totalRecords +
        ' total'
    );
    return new PaginatedResult(results, totalRecords);
  }
}
