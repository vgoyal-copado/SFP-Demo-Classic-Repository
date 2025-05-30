/**
 * Job to cleanup accounts created during the demos.  Accounts need to be cleaned up in thier own
 * job to avoid MIXED DML errors.
 *   
 * @author	Lars Helgeson (lars.helgeson@salesforce.com)
 * @author	Joe McMaster (joe.mcmaster@salesforce.com)
 * 
 * @version	1.0
 *
 *
 * History
 * -------
 * v1.0 - Oct  6, 2021 - Initial Version for Multiplay Demo
 * 
 */
public with sharing class Demo_CleanupAccounts extends Demo_Job {

    // Demo Config
	public static final String ACCOUNT_DEMO_PATTERN = '%Residence';
    public static final String ACCOUNT_DC_PATTERN   = 'DCPseudoAccountVLOCITY%';

    /**
     * Executes the account cleanup job
     * 
     * @param context  The Queueable Context
     */
    public override void executeJob(QueueableContext context) {
        
        try {

            cleanupAccounts();
        }
        catch (Exception e) {
            
            // Error occurred
            DemoSystemEvent.error('Demo Cleanup', 'Error Occured during cleanup -> ' + e.getMessage());
            throw e;
        }
	}

	/**
     * Cleans up Accounts with a specific name and Demo Persistent=false
     * 
     */
    public static void CleanupAccounts(){

		DemoSystemEvent.info('Demo Cleanup', 'Cleaning up non-persistent Accounts named ' + ACCOUNT_DEMO_PATTERN + ' or ' + ACCOUNT_DC_PATTERN);
        
		List<Account> deleteAccounts = [SELECT Id FROM Account WHERE (Name LIKE :ACCOUNT_DEMO_PATTERN OR Name Like:ACCOUNT_DC_PATTERN) AND Demo_Persistent__c = false];
        delete deleteAccounts;    

        DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + deleteAccounts.size() + ' Accounts');
    }
}