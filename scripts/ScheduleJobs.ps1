echo "System.debug('Scheduling Jobs'); ScheduleTokenJobs.scheduleJobs();" > schedule-jobs.apex
sfdx force:apex:execute -f .\scripts\apex\schedule-token-jobs.apex