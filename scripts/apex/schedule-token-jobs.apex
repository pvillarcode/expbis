public with sharing class ScheduleTokenJobs {
    public void scheduleJobs() {
        System.schedule('Experian_ScheduleBISToken1', '0 0 * * * ?', new Experian_ScheduleBISToken());
        System.schedule('Experian_ScheduleBISToken2', '0 20 * * * ?', new Experian_ScheduleBISToken());
        System.schedule('Experian_ScheduleBISToken3', '0 40 * * * ?', new Experian_ScheduleBISToken());
    }
}