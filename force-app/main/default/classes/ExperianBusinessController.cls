public with sharing class ExperianBusinessController {
  @AuraEnabled(cacheable=true)
  public static List<Experian_Business__c> getExperianBusinessInfo(
    Id accountId
  ) {
    return [
      SELECT
        Id,
        Name,
        Bank_Data_Indicator__c,
        Business_Phone__c,
        Executive_Summary_Indicator__c,
        City__c,
        Financial_Statemen_Indicator__c,
        Goverment_Data_Indicator__c,
        Inquiry_Indicator__c,
        Number_of_Trade_Lines__c,
        State__c,
        Street_Address__c,
        UCC_Indicator__c,
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
        Commercial_Dispute_Indicator__c
      FROM Experian_Business__c
      WHERE Account__c = :accountId
    ];
  }
}
