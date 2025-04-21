/**
 * Job to cleanup saved omniscripts created during the demos.
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
public with sharing class Demo_CleanupOmniScripts extends Demo_Job {

    /**
     * Executes the cleanup job
     * 
     * @param context  The Queueable Context
     */
    public override void executeJob(QueueableContext context) {
        
        try {

            cleanupPausedScripts();
        }
        catch (Exception e) {
            
            // Error occurred
            DemoSystemEvent.error('Demo Cleanup', 'Error Occured during saved OmniScript cleanup -> ' + e.getMessage());
            throw e;
        }
	}

    /**
     * Cleans up paused OmniScripts
     * 
     */
    public static void cleanupPausedScripts() {

		DemoSystemEvent.info('Demo Cleanup', 'Cleaning up Paused OmniScripts');

        delete [ SELECT Id FROM vlocity_cmt__OmniScriptInstance__c ];
        delete [ SELECT Id FROM vlocity_cmt__VlocityTrackingEntry__c ];
	}
}