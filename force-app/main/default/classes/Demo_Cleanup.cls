/**
 * Performs all of the cleanup operations for the Multiplay Demo.  The cleanup is imlpemented as a set of Queuable jobs
 * and are chained as follows:
 * 
 * @author	Lars Helgeson (lars.helgeson@salesforce.com)
 * @author	Joe McMaster (joe.mcmaster@salesforce.com)
 * 
 * @version	1.5
 *
 *
 * History
 * -------
 * v1.0 - May 14, 2021 - Initial Version for Multiplay Demo
 * v1.1 - July 9, 2021 - Added methods to clean up Accounts, Assets, Cases, Contracts, Orders, paused OmniScripts, Orchestration Plans
 * v1.2 - Aug 19, 2021 - Added Billing Statement regeneration code
 *                       Enhanced to use Platform Events for logging
 * v1.3 - Sep  7, 2021 - Fixed DML Error (MIXED_DML_OPERATION)
 * v1.4 - Oct  6, 2021 - Rebuilt to use Queueable Apex
 *                     - Added support for Change of Plan situations
 *                     - Better Error Reporting
 * v1.5 - Jan  3, 2022 - Seperated jobs into separate classes for a more modular approach
 * v1.6 - Apr 19, 2022 - Added Cleanup Recycle Bin job
 */
public with sharing class Demo_Cleanup {

	/**
     * Queues the cleanup jobs
     * 
     * @return The Job Id
     */    
    @AuraEnabled
    public static Id cleanup() {

        DemoSystemEvent.info('Demo Cleanup', 'Beginning Cleanup');

        // Queue the jobs
        Demo_JobChain jobs = new Demo_JobChain();
        jobs.add(new Demo_CleanupOrders());
        jobs.add(new Demo_CleanupCases());
        jobs.add(new Demo_CleanupContracts());
        jobs.add(new Demo_CleanupAssets());
        jobs.add(new Demo_CleanupOmniScripts());
        jobs.add(new Demo_CleanupXOM());
        jobs.add(new Demo_CleanupUsers());
        jobs.add(new Demo_CleanupAccounts());
        jobs.add(new Demo_CleanupRegenStatements());
        jobs.add(new Demo_CleanupComplete());
        jobs.add(new Demo_CleanupRecycleBin());

        return jobs.start();
    }
}