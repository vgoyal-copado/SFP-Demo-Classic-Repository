/**
 * Job to cleanup contracts created during the demos.
 * 
 * @author	Lars Helgeson (lars.helgeson@salesforce.com)
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
public with sharing class Demo_CleanupContracts extends Demo_Job {

    /**
     * Executes the cleanup job
     * 
     * @param context  The Queueable Context
     */
    public override void executeJob(QueueableContext context) {
        
        try {

            cleanupDraftContracts(); 
        }
        catch (Exception e) {
            
            // Error occurred
            DemoSystemEvent.error('Demo Cleanup', 'Error Occured during contract cleanup -> ' + e.getMessage());
            throw e;
        }
	}

	/**
     * Cleans up Contracts with draft status and Demo Persistent=false
	 * Not necessarily needed for B2C, but it's here just in case
     * 
     */
    public static void cleanupDraftContracts() {

		DemoSystemEvent.info('Demo Cleanup', 'Cleaning up non-persistent Contracts');

        List<Contract> draftContracts = [ SELECT Id FROM Contract WHERE Status = 'Draft' AND Demo_Persistent__c = false ];
        delete draftContracts;    

		DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + draftContracts.size() + ' Draft Contracts');
	}
}