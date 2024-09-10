sfdx force:org:create -f config\project-scratch-def.json --setalias scratchOrgBISapp --durationdays 15 --setdefaultusername --json --loglevel fatal
sfdx force:source:push --json --loglevel fatal
echo "Assigning permission set to the user"
sfdx force:user:permset:assign -n "Experian_App_Permision_set" --json --loglevel fatal
echo "Creating data"
sfdx force:data:tree:import -f ./export/Experian_Configuration__c.json -u scratchOrgBISapp
echo "System.debug('Scheduling Jobs'); ScheduleTokenJobs.scheduleJobs();" > schedule-jobs.apex
sfdx force:apex:execute -f .\scripts\apex\schedule-token-jobs.apex
sfdx force:org:open --json --loglevel fatal

