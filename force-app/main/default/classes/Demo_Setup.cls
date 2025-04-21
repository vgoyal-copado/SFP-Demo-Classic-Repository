/**
 * Performs any necessary setup for the demo
 *  
 * @author	Joe McMaster (joe.mcmaster@salesforce.com)
 * @version	1.1
 *
 *
 * History
 * -------
 * v1.0 - Sep 29, 2021 - Initial Version for Multiplay Demo
 * v1.1 - Jan  3, 2022 - Seperated jobs into separate classes for a more modular approach
 * 
 */
public with sharing class Demo_Setup {
    

    /**
     * Runs all setup tasks
     * 
     * @return The Job Id
     */
    @AuraEnabled 
    public static Id setup() {   

        // Start of Job
        DemoSystemEvent.info('Demo Setup', 'Beginning Setup');

        // Queue the Setup Jobs
        Demo_JobChain jobs = new Demo_JobChain();
        jobs.add(new Demo_SetupExpirationMonitor());
        jobs.add(new Demo_SetupComplete());

        return jobs.start();
	}

    /**
     * Returns a list of active LWC-based OmniScripts
     * 
     * @return List of active LWC-based OmniScripts
     */
    @AuraEnabled 
    public static List<Object> getLWCOmniScripts() {

        List<Object> lwcOSList = new List<Object>();

        try {

            // Fetch all active LWC-based OmniScripts
            for(vlocity_cmt__OmniScript__c os : [SELECT Id,Name,vlocity_cmt__IsActive__c,vlocity_cmt__IsLwcEnabled__c,vlocity_cmt__IsProcedure__c,vlocity_cmt__LwcId__c,vlocity_cmt__SubType__c,vlocity_cmt__Type__c,vlocity_cmt__Version__c FROM vlocity_cmt__OmniScript__c WHERE vlocity_cmt__IsActive__c = true AND vlocity_cmt__IsProcedure__c = false AND vlocity_cmt__IsLwcEnabled__c = true ORDER BY vlocity_cmt__IsReusable__c DESC]) {

                lwcOSList.add(os.getPopulatedFieldsAsMap());
            }
        }
        catch (Exception e) {

            // Error occurred
            DemoSystemEvent.error('Demo Setup', 'Error fetching LWC-based OmniScripts -> ' + e.getMessage());
            throw e;
        }

        return lwcOSList;
    }

    /**
     * Returns the details of an OmniScripts
     * 
     * @param id  The OmniScript Id
     * 
     * @return The OmniScript details
     */
    @AuraEnabled 
    public static Map<String, Object> getOmniScript(String id) {

        try {

            // Fetch the OmniScript
            vlocity_cmt__OmniScript__c[] omniscripts = [SELECT Id,Name,vlocity_cmt__IsActive__c,vlocity_cmt__IsLwcEnabled__c,vlocity_cmt__IsProcedure__c,vlocity_cmt__LwcId__c,vlocity_cmt__SubType__c,vlocity_cmt__Type__c,vlocity_cmt__Version__c FROM vlocity_cmt__OmniScript__c WHERE Id=:id];

            if (!omniscripts.isEmpty()) return omniscripts[0].getPopulatedFieldsAsMap();
        }
        catch (Exception e) {

            // Error occurred
            DemoSystemEvent.error('Demo Setup', 'Error fetching OmniScript (id =' + id + ') -> ' + e.getMessage());
            throw e;
        }

        return null;
    }
}