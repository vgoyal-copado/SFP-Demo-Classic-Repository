/**
 * Job to cleanup community users created during the demos.  Users need to be cleaned up in thier own
 * job to avoid MIXED DML errors.
 *   
 * @author	Lars Helgeson (lars.helgeson@salesforce.com)
 * @author	Joe McMaster (joe.mcmaster@salesforce.com)
 * 
 * @version	1.1
 *
 *
 * History
 * -------
 * v1.0 - Oct  6, 2021 - Initial Version for Multiplay Demo
 * v1.1 - Apr 28, 2022 - Added Cleanup of license assignments
 */
public with sharing class Demo_CleanupUsers extends Demo_Job {

    // Demo Config
	public static final String USERNAME_PATTERN = 'demo-%';

    /**
     * Executes the user cleanup job
     * 
     * @param context  The Queueable Context
     */
    public override void executeJob(QueueableContext context) {
        
        try {

            cleanupUsers();
        }
        catch (Exception e) {
            
            // Error occurred
            DemoSystemEvent.error('Demo Cleanup', 'Error Occured during cleanup -> ' + e.getMessage());
            throw e;
        }
	}

    /**
     * Cleans up any users in the org that were registered during past demos
     * 
     */
    public static void cleanupUsers() {

		DemoSystemEvent.info('Demo Cleanup', 'Cleaning up Community Users named ' + USERNAME_PATTERN);
        
        // Disable user accounts generated from the buy-flow
        User[] users = [SELECT Id, Username FROM User WHERE Username LIKE :USERNAME_PATTERN AND IsActive=true AND IsPortalEnabled=true];
        
        for (User user : users) {
			DemoSystemEvent.info('Demo Cleanup', 'Deactivating Community User ' + user.Username);
			user.isActive = false;        //set to inactive
			user.IsPortalEnabled = false; //disable as portal user
		}
        update users;

        // Remove Deactivated Users from any Licensing
        delete [ SELECT Id FROM UserPackageLicense WHERE UserId IN :users ];
        
        DemoSystemEvent.info('Demo Cleanup', 'Deactivated ' + users.size() + ' Community Users');
    }    
}