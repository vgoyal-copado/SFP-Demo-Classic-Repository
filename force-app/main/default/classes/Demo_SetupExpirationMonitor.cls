/**
 * Job to setup the org expiration monitor.
 *   
 * @author	Joe McMaster (joe.mcmaster@salesforce.com)
 * 
 * @version	1.0
 *
 *
 * History
 * -------
 * v1.0 - Jan  3, 2022 - Initial Version for Multiplay Demo
 * 
 */
public with sharing class Demo_SetupExpirationMonitor extends Demo_Job {

    public static final String ORG_EXPIRATION_MONITOR_JOB = 'Demo - Org Expiration Monitor';
    public static final String DAILY_SCHEDULE             = '0 0 0 * * ?';  // Daily, 12AM

    /**
     * Executes the job
     * 
     * @param context  The Queueable Context
     */
    public override void executeJob(QueueableContext context) {
        
        try {

            setupOrgExpirationMonitor();
        }
        catch (Exception e) {
            
            // Error occurred
            DemoSystemEvent.error('Demo Setup', 'Error Occured during org expiration monitor setup -> ' + e.getMessage());
            throw e;
        }
	}

    /**
     * Sets up a scheduled job that will monitor the org expiration date
     * and email warnings to system administrators if it is approaching
     * 
     */
    private static void setupOrgExpirationMonitor() {

        // Unschedule any pre-existing jobs
        for (CronTrigger cronJob: [SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.Name=:ORG_EXPIRATION_MONITOR_JOB]) System.abortJob(cronJob.Id);

        // Schedule the job
        DemoOrgExpiryNotification job = new DemoOrgExpiryNotification();
        System.schedule(ORG_EXPIRATION_MONITOR_JOB, DAILY_SCHEDULE, job);
        DemoSystemEvent.info('Demo Setup', ORG_EXPIRATION_MONITOR_JOB + ' job has been scheduled.');
    }
}