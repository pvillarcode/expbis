/*
// TO SCHEDULE TO RUN DAILY
public class ScheduleDeleteOldReports {
    public static void scheduleDaily() {
        ExperianDeleteOldReportsBatch batchJob = new ExperianDeleteOldReportsBatch(30); // Delete reports older than 30 days
        String jobName = 'Delete Old Experian Reports';
        String cronExp = '0 0 1 * * ?'; // Run daily at 1 AM
        System.schedule(jobName, cronExp, batchJob);
    }
}

//TO RUN INMEDIATELY
ExperianDeleteOldReportsBatch.runNow(30);

System.debug('Batch job to delete old Experian reports has been queued.');
*/

global class ExperianDeleteOldReportsBatch implements Database.Batchable<sObject>, Schedulable {
  private Integer daysOld;

  global ExperianDeleteOldReportsBatch(Integer daysOld) {
    this.daysOld = daysOld;
  }

  global Database.QueryLocator start(Database.BatchableContext BC) {
    Date cutoffDate = Date.today().addDays(-daysOld);
    return Database.getQueryLocator(
      [
        SELECT Id, ContentDocumentId, LinkedEntityId
        FROM ContentDocumentLink
        WHERE
          LinkedEntityId IN (SELECT Id FROM Experian_Report__c)
          AND ContentDocument.CreatedDate <= :cutoffDate
      ]
    );
  }

  global void execute(
    Database.BatchableContext BC,
    List<ContentDocumentLink> scope
  ) {
    Set<Id> contentDocumentIds = new Set<Id>();
    Set<Id> experianReportIds = new Set<Id>();

    for (ContentDocumentLink cdl : scope) {
      contentDocumentIds.add(cdl.ContentDocumentId);
      experianReportIds.add(cdl.LinkedEntityId);
    }

    if (!contentDocumentIds.isEmpty()) {
      delete [SELECT Id FROM ContentDocument WHERE Id IN :contentDocumentIds];
    }

    if (!experianReportIds.isEmpty()) {
      delete [SELECT Id FROM Experian_Report__c WHERE Id IN :experianReportIds];
    }
  }

  global void finish(Database.BatchableContext BC) {
    // Optional: Add any post-processing logic here
  }

  global void execute(SchedulableContext SC) {
    Database.executeBatch(this);
  }

  public static void runNow(Integer daysOld) {
    ExperianDeleteOldReportsBatch batch = new ExperianDeleteOldReportsBatch(
      daysOld
    );
    Database.executeBatch(batch);
  }
}
