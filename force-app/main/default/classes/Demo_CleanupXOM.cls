/**
 * Job to cleanup Order Management objects created during the demos.
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
public with sharing class Demo_CleanupXOM extends Demo_Job {

    /**
     * Executes the cleanup job
     * 
     * @param context  The Queueable Context
     */
    public override void executeJob(QueueableContext context) {
        
        try {

            cleanupOrchestrationPlans();
        }
        catch (Exception e) {
            
            // Error occurred
            DemoSystemEvent.error('Demo Cleanup', 'Error Occured during XOM cleanup -> ' + e.getMessage());
            throw e;
        }
	}

	/**
     * Cleans up Orchestration Plans
     * 
     */
    public static void cleanupOrchestrationPlans() {   

		DemoSystemEvent.info('Demo Cleanup', 'Cleaning up Orchestration Plans');

        delete [ SELECT Id FROM vlocity_cmt__OrchestrationDependency__c ];
        delete [ SELECT id FROM vlocity_cmt__OrchestrationItem__c ];
        delete [ SELECT id FROM vlocity_cmt__OrchestrationPlan__c ];
        delete [ SELECT id FROM vlocity_cmt__FulfilmentRequestDecompRelationship__c ];
        delete [ SELECT id FROM vlocity_cmt__FulfilmentRequest__c ];
        delete [ SELECT id FROM vlocity_cmt__InventoryItemDecompositionRelationship__c ];
        delete [ SELECT id FROM vlocity_cmt__FulfilmentRequestLine__c ];
        delete [ SELECT id FROM vlocity_cmt__InventoryItem__c ];
	}
}