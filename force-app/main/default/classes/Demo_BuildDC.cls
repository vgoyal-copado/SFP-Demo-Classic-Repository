/**
 * Job to populate the Digital Commerce cache
 *   
  * @author	Joe McMaster (joe.mcmaster@salesforce.com)
 * 
 * @version	1.1
 *
 *
 * History
 * -------
 * v1.0 - May  3, 2022 - Initial Version for Multiplay Demo
 * v1.1 - Jun 22, 2022 - Updated for 238 jobs
 * 
 */
public with sharing class Demo_BuildDC {

    // 238 Jobs (no product versioning)
    public static final List<String> DC_CACHE_REFRESH_BATCH_JOBS = new List<String>{'EcomDataProfileGeneratorBatch',
                                                                                    'RuleSetCombinationGeneratorBatch',
                                                                                    'ContextEligibilityGeneratorBatch',
                                                                                    'GetOffersHierarchyHelperBatch',
                                                                                    'GetOffersItemBatch',
                                                                                    'GetOffersBatch',
                                                                                    'GetContainOffersBatch',
                                                                                    'GetPricesBatch',
                                                                                    'GetOfferDetailsBatch',
                                                                                    'PromotionWrapperBatch'};

    /**
     * Cleans out the Digital Commerce Cache
     * 
     */
    @AuraEnabled
    public static void clearCache() {

		DemoSystemEvent.info('Demo Cleanup', 'Clearing the Digital Commerce Cache');

        delete[ SELECT Id FROM vlocity_cmt__CachedAPIResponse__c ];        
        delete [SELECT Id FROM vlocity_cmt__CachedAPIResponseOffers__c];
        delete [SELECT Id FROM vlocity_cmt__CachedAPIChange__c];
        delete [SELECT Id FROM vlocity_cmt__CachedAPIChangeEntry__c];
	}

    /**
     * Populate the Digital Commerce Cache
     * 
     * @return The job summary
     */
    @AuraEnabled
    public static Map<String, Object> buildCache() {

		DemoSystemEvent.info('Demo Cleanup', 'Building the Digital Commerce Cache');

        Map<String, Object> result = new Map<String, Object> {
            'start_time' => DateTime.now().formatGmt(Demo_MonitorJobs.DATE_FORMAT),
            'jobs' => DC_CACHE_REFRESH_BATCH_JOBS
        };

        vlocity_cmt.TelcoAdminConsoleController telcoController = new vlocity_cmt.TelcoAdminConsoleController();        
        Map<String, Object> input = new Map<String, Object>();
        input.put('methodName', 'populateCacheCAJob');

        // Setup the Jobs to run (NOTE: This may be a different set of jobs once Product Versioning is enabled in demo)
        List<String> dcJobs = new List<String>();

        // 236
        //dcJobs.add('ContextEligibilityGenerator');
        //dcJobs.add('GetOffersHierarchyHelper');
        //dcJobs.add('GetContainOffers');
        //dcJobs.add('GetOffers');
        //dcJobs.add('GetPrices');
        //dcJobs.add('GetOfferDetails');

        // 238
        dcJobs.add('EcomDataProfileGenerator');
        dcJobs.add('RuleSetCombinationGenerator');
        dcJobs.add('ContextEligibilityGenerator');
        dcJobs.add('GetOffersHierarchyHelper');
        dcJobs.add('GetOffersItem');
        dcJobs.add('GetOffers');
        dcJobs.add('GetContainOffers');
        dcJobs.add('GetPrices');
        dcJobs.add('GetOfferDetails');
        dcJobs.add('PromotionWrapper');

        input.put('selectedList', dcJobs);
        
        // Set Start/End Dates
        input.put('effectiveStartTime', Datetime.now().addHours(-12).getTime());
        input.put('expirationTime', Datetime.now().addYears(2).getTime());

        // Set the Catalogs to Build
        List<String> catalogs = new List<String>();
        List<String> catalogCodes = new List<String>();
        vlocity_cmt__Catalog__c[] cats =  [ SELECT Id,Name,vlocity_cmt__CatalogCode__c FROM vlocity_cmt__Catalog__c WHERE vlocity_cmt__IsActive__c = true ];
        for(vlocity_cmt__Catalog__c cat: cats) {
            catalogs.add(cat.Id);
            catalogCodes.add((String)cat.get('vlocity_cmt__CatalogCode__c'));
        }
        Map<String, Object> filters = new Map<String, Object>();
        filters.put('Catalogs', catalogs);
        filters.put('catalogCodes', catalogCodes);
        input.put('filters', filters);

        // Kick off the Jobs
        telcoController.setParameters(JSON.serialize(input));
        telcoController.invokeMethod();
        
        DemoSystemEvent.info('Demo Cleanup', 'Cache Build in progress.  Give it a few minutes');

        return result;
	}
}