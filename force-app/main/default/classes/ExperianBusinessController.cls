public with sharing class ExperianBusinessController {
  @AuraEnabled(cacheable=true)
  public static List<Experian_Business__c> getExperianBusinessInfo(
    Id accountId
  ) {
    return [
      SELECT
        Id,
        Name,
        Business_Phone__c,
        City__c,
        State__c,
        Street_Address__c,
        Zip_Extension__c,
        Zip__c,
        Account__c,
        BIN__c,
        bf_business_type__c,
        bf_Date_of_Incorporation__c,
        bf_File_Established_Date__c,
        FSR_Score__c,
        bf_Years_in_Business__c,
        FSR_Risk_Code__c,
        FSR_Risk_Definition__c,
        FSR_Dispute_Indicator__c,
        FSR_Model_Code__c,
        FSR_Model_Title__c,
        Commercial_Score__c,
        Commercial_Model_Code__c,
        Commercial_Model_Title__c,
        Commercial_Risk_Code__c,
        Commercial_Risk_Definition__c,
        Commercial_Credit_Limit_Recommendation__c,
        Commercial_Dispute_Indicator__c,
        cfs_Active_Business_Indicator__c,
        cfs_Business_Risk_Triggers_Indicator__c,
        cfs_Matching_Business_Indicator__c,
        cfs_Name_Address_Verification_Indicator__c,
        cfs_Possible_OFAC_Match__c
      FROM Experian_Business__c
      WHERE Account__c = :accountId
    ];
  }

  public class PaginatedResult {
    @AuraEnabled
    public List<ContentDocumentLink> records;
    @AuraEnabled
    public Integer totalRecords;

    public PaginatedResult(
      List<ContentDocumentLink> records,
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

    Id businessId;
    try {
      businessId = [
        SELECT Id
        FROM Experian_Business__c
        WHERE Account__c = :accountId
        LIMIT 1
      ]
      .Id;
    } catch (Exception e) {
      System.debug('Error finding Experian_Business__c: ' + e.getMessage());
      return new PaginatedResult(new List<ContentDocumentLink>(), 0);
    }

    Integer offset = (pageNumber - 1) * pageSize;

    // Get total count
    Integer totalRecords = [
      SELECT COUNT()
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :businessId
    ];

    // Get paginated results
    List<ContentDocumentLink> results = [
      SELECT
        ContentDocumentId,
        ContentDocument.Title,
        ContentDocument.CreatedDate,
        ContentDocument.CreatedBy.Name
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :businessId
      ORDER BY ContentDocument.CreatedDate DESC
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
