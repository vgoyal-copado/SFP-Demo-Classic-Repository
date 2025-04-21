/**
 * Job to cleanup assets created during the demos.
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
public with sharing class Demo_CleanupAssets extends Demo_Job {

    /**
     * Executes the cleanup job
     * 
     * @param context  The Queueable Context
     */
    public override void executeJob(QueueableContext context) {
        
        try {

            cleanupAssets(); 
        }
        catch (Exception e) {
            
            // Error occurred
            DemoSystemEvent.error('Demo Cleanup', 'Error Occured during asset cleanup -> ' + e.getMessage());
            throw e;
        }
	}

	/**
     * Cleans up Assets with Demo Persistent=false
     * 
     */
    public static void cleanupAssets() {

		DemoSystemEvent.info('Demo Cleanup', 'Cleaning up non-persistent Assets');

        // Remove all Asset Relationships (we can't cleanup assets that have relationships)
        List<AssetRelationship> assetRelationships = new List<AssetRelationship>();
        for(AssetRelationship rel : [SELECT Id, Asset.Demo_Persistent__c, RelatedAsset.Demo_Persistent__c FROM AssetRelationship]) {
            if (!rel.Asset.Demo_Persistent__c && !rel.RelatedAsset.Demo_Persistent__c) assetRelationships.add(rel);
        }
        if (!assetRelationships.isEmpty()) {
            delete assetRelationships;
            DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + assetRelationships.size() + ' Asset Relationships');
        }

        List<Asset> assets = [SELECT Id, Product2.Name FROM Asset WHERE Demo_Persistent__c = false];
        delete assets;

        DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + assets.size() + ' Assets');
    }
}