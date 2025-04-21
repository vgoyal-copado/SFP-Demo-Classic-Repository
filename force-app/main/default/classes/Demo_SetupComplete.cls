/**
 * Job to simply notify (via Platform Event) that the setup operations have completed
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
public with sharing class Demo_SetupComplete extends Demo_Job {

    /**
     * Executes the cleanup job
     * 
     * @param context  The Queueable Context
     */
    public override void executeJob(QueueableContext context) {
        
        try {

            DemoSystemEvent.info('Demo Setup', 'Setup Complete!');
        }
        catch (Exception e) {
            
            // Error occurred
            DemoSystemEvent.error('Demo Setup', 'Error Occured during setup completion -> ' + e.getMessage());
            throw e;
        }
	}
}