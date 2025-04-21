/**
 * Job to cleanup the org's recycle bin
 * 
 * @author	Joe McMaster (joe.mcmaster@salesforce.com)
 * 
 * @version	1.0
 *
 *
 * History
 * -------
 * v1.0 - Apr 19, 2022 - Initial Version for Multiplay Demo
 * 
 */
public with sharing class Demo_CleanupRecycleBin extends Demo_Job {

    /**
     * Executes the cleanup job
     * 
     * @param context  The Queueable Context
     */
    public override void executeJob(QueueableContext context) {
        
        try {

            cleanupRecycleBin(); 
        }
        catch (Exception e) {
            
            // Error occurred
            DemoSystemEvent.error('Demo Cleanup', 'Error Occured during Recycle Bin cleanup -> ' + e.getMessage());
            throw e;
        }
	}

    /**
     * Cleans up the Recycle Bin
     * 
     */
    public static void cleanupRecycleBin() {

		DemoSystemEvent.info('Demo Cleanup', 'Emptying the Recycle Bin');

        // Find the objects to delete from the recycle bin
        List<SObject> objs = new List<SObject>();
        
        // Accounts, Orders, Quotes, Opportunities & Statements
        objs.addAll([ SELECT Id FROM Account WHERE isDeleted = true ALL ROWS]);        
        objs.addAll([ SELECT Id FROM Order WHERE isDeleted = true ALL ROWS]);
        objs.addAll([ SELECT Id FROM Quote WHERE isDeleted = true ALL ROWS]);
        objs.addAll([ SELECT Id FROM Opportunity WHERE isDeleted = true ALL ROWS]);
        objs.addAll([ SELECT Id FROM vlocity_cmt__Statement__c WHERE isDeleted = true ALL ROWS]);

        // Orchestration Plans, Fulfillment Requests & FRLs
        objs.addAll([ SELECT Id FROM vlocity_cmt__OrchestrationPlan__c WHERE isDeleted = true ALL ROWS]);
        objs.addAll([ SELECT Id FROM vlocity_cmt__FulfilmentRequest__c WHERE isDeleted = true ALL ROWS]);
        objs.addAll([ SELECT Id FROM vlocity_cmt__FulfilmentRequestLine__c WHERE isDeleted = true ALL ROWS]);

        // DataRaptor Crud
        objs.addAll([ SELECT Id FROM vlocity_cmt__DRBulkData__c WHERE isDeleted = true ALL ROWS]);
        
        // Digital Commerce
        objs.addAll([ SELECT Id FROM vlocity_cmt__CachedAPIResponse__c WHERE isDeleted = true ALL ROWS]);

        // JOE - Add Other objects as needed

		DemoSystemEvent.info('Demo Cleanup', 'Removing ' + objs.size() +	' Objects from Recycle Bin');

        if (objs.size() > 0) Database.emptyRecycleBin(objs);
    }    
}