/**
 * Job to cleanup orders created during the demos.
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
public with sharing class Demo_CleanupOrders extends Demo_Job {

    /**
     * Executes the cleanup job
     * 
     * @param context  The Queueable Context
     */
    public override void executeJob(QueueableContext context) {
        
        try {

            cleanupOrders(); 
        }
        catch (Exception e) {
            
            // Error occurred
            DemoSystemEvent.error('Demo Cleanup', 'Error Occured during order cleanup -> ' + e.getMessage());
            throw e;
        }
	}

    /**
     * Cleans up Orders with Draft and Activated status and Demo Persistent=false
     * 
     */
    public static void cleanupOrders() {

		DemoSystemEvent.info('Demo Cleanup', 'Cleaning up non-persistent Orders');

		// Get list of draft Orders to delete
        List<Order> draftOrders = [ SELECT Id FROM Order WHERE Status = 'Draft' AND Demo_Persistent__c = false ];
        delete draftOrders;    

		DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + draftOrders.size() +	' Draft Orders');

		// Get list of activated Orders to delete
        Order[] activatedOrders = [	SELECT Id FROM Order WHERE Status = 'Activated' AND Demo_Persistent__c = false ];
        
		// Set status to Draft on the Activated Orders
        for (Order order : activatedOrders) order.Status = 'Draft';
        update activatedOrders;

		// Delete the Orders
        delete activatedOrders;    
	
        DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + activatedOrders.size() + ' Activated Orders');
    }    
}