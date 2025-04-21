/**
 * Job to run the Product Hierarchy Jobs
 *   
  * @author	Joe McMaster (joe.mcmaster@salesforce.com)
 * 
 * @version	1.0
 *
 *
 * History
 * -------
 * v1.0 - Jul 27, 2022 - Initial Version for Multiplay Demo
 * 
 */
public with sharing class Demo_BuildProductHierarchy {

    // Resulting Apex Queueable/Batch jobs that will be generated once we call the controller
    public static final List<String> HIERARCHY_BATCH_JOBS = new List<String>{'ResolveProductSpecHierarchyBatchJob', 'DeleteProdHierDataStoreRecordsBatchJob'};
    public static final List<String> PLATFORM_REFRESH_BATCH_JOBS = new List<String>{'V2ProductHierarchyBatchProcessor', 'DeleteSObjectBatchProcessor', 'DeleteSObjectBatchProcessor', 'ProductAttributesBatchProcessor'};

    /**
     * Starts the Produce Hierarchy Maintenance Job
     * 
     */
    @AuraEnabled
    public static Map<String, Object> buildHierarchy() {

        Map<String, Object> result = new Map<String, Object> {
            'start_time' => DateTime.now().formatGmt(Demo_MonitorJobs.DATE_FORMAT),
            'jobs' => HIERARCHY_BATCH_JOBS
        };

        try {
            
            DemoSystemEvent.info('Demo Cleanup', 'Running the Product Hierarchy Maintenance Job');

            vlocity_cmt.TelcoAdminConsoleController telcoController = new vlocity_cmt.TelcoAdminConsoleController();        
            Map<String, Object> input = new Map<String, Object>();
            input.put('methodName', 'startProductHierarchyJob');
            input.put('deleteOldData', 'true');

            // Kick off the Jobs
            telcoController.setParameters(JSON.serialize(input));
            telcoController.invokeMethod();      
        }
        catch (Exception e) {
            
            // Error occurred
            DemoSystemEvent.error('Demo Cleanup', 'Error Occured during initialization of Product Hierarchy Maintenance Job -> ' + e.getMessage());
            throw e;
        }

        return result;
	}

    /**
     * Starts the Produce Hierarchy Maintenance Job
     * 
     */
    @AuraEnabled
    public static Map<String, Object> refreshCache() {

        clearPlatformCache();
        return buildPlatformCache();
	}

    /**
     * Clears the Platform Cache
     * 
     */
    public static void clearPlatformCache() {

        try {
            
            DemoSystemEvent.info('Demo Cleanup', 'Clearing the Platform Cache');

            vlocity_cmt.TelcoAdminConsoleController telcoController = new vlocity_cmt.TelcoAdminConsoleController();        
            Map<String, Object> input = new Map<String, Object>();
            input.put('methodName', 'clearPlatformCache');

            // Kick off the Jobs
            telcoController.setParameters(JSON.serialize(input));
            telcoController.invokeMethod();
        }
        catch (Exception e) {
            
            // Error occurred
            DemoSystemEvent.error('Demo Cleanup', 'Error Occured during clearing of the Platform Cache -> ' + e.getMessage());
            throw e;
        }
    }

    /**
     * Builds the Platform Cache
     * 
     * @return A status message
     */
    public static Map<String, Object> buildPlatformCache() {

        Map<String, Object> result = new Map<String, Object> {
            'start_time' => DateTime.now().formatGmt(Demo_MonitorJobs.DATE_FORMAT),
            'jobs' => PLATFORM_REFRESH_BATCH_JOBS
        };

         try {
            
            DemoSystemEvent.info('Demo Cleanup', 'Refreshing the Platform Cache');

            vlocity_cmt.TelcoAdminConsoleController telcoController = new vlocity_cmt.TelcoAdminConsoleController();        
            Map<String, Object> input = new Map<String, Object>();
            input.put('methodName', 'refreshPriceBook');

            // Kick off the Jobs
            telcoController.setParameters(JSON.serialize(input));
            telcoController.invokeMethod();
        }
        catch (Exception e) {
            
            // Error occurred
            DemoSystemEvent.error('Demo Cleanup', 'Error Occured during refresh of the Platform Cache -> ' + e.getMessage());
            throw e;
        }        

        return result;
    }     
}