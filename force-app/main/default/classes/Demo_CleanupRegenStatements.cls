/**
 * Job to re-generate billing statements.
 *   
 * @author	Lars Helgeson (lars.helgeson@salesforce.com)
 * @author	Joe McMaster (joe.mcmaster@salesforce.com)
 * 
 * @version	1.0
 *
 *
 * History
 * -------
 * v1.0 - Oct  6, 2021 - Initial Version for Multiplay Demo
 * 
 */
public with sharing class Demo_CleanupRegenStatements extends Demo_Job {

    // Billing Statement Config    
	public static final String ACCOUNT_PATTERN  = '%Residence';
    public static final Integer NUMBER_OF_STATEMENTS = 6;
    public static final Integer NUMBER_OF_STATEMENT_LINEITEMS = 1;
    public static final Integer NUMBER_OF_STATEMENT_LINEITEMS_VOD = 4;
    public static final String  INTERNET_SERVICE_NAME = 'Blaze Internet Premium';
    public static final Double  INTERNET_SERVICE_MONTHLY_PRICE = 50.0;
    public static final Double  STATE_TAX = 0.06;
    public static final Double  LOCAL_TAX = 0.025;
    public static final Double  REGULATORY_FEES = 0.055;

	/**
     * Queues the statement regeneration job
     * 
     * @return The Job Id
     */    
    @AuraEnabled
    public static Id regenerateStatements() {

        // Queue the jobs
        Demo_JobChain jobs = new Demo_JobChain();        
        jobs.add(new Demo_CleanupRegenStatements());

        return jobs.start();
    }

    /**
     * Executes the statement regeneration job
     * 
     * @param context  The Queueable Context
     */
    public override void executeJob(QueueableContext context) {
        
        try {

            cleanupStatements();
            generateBillingStatements();
           
        }
        catch (Exception e) {
            
            // Error occurred
            DemoSystemEvent.error('Demo Cleanup', 'Error Occured during cleanup -> ' + e.getMessage());
            throw e;
        }
	}

    /**
     * Cleans up Billing Statements
     *
     */
    private static void cleanupStatements() {
        
		DemoSystemEvent.info('Demo Cleanup', 'Cleaning up non-persistent Billing Statements');

        delete [ SELECT Id FROM vlocity_cmt__Statement__c WHERE	Demo_Persistent__c = false ];
    }

    /**
     * Regenerates the sample billing statements
     * 
     */
    private static void generateBillingStatements() {

		// Identify Accounts which need Statements
        List<vlocity_cmt__Statement__c> newStatements = new List<vlocity_cmt__Statement__c>();
        List<vlocity_cmt__StatementLineItem__c> newStatementLines = new List<vlocity_cmt__StatementLineItem__c>();

        // All accounts that end with "Residence"
        List<Account> accts = [ SELECT Id, Name FROM Account WHERE Name LIKE :ACCOUNT_PATTERN ];

        // Loop through the list of Accounts
        for(Account acct:accts) {

            DemoSystemEvent.info('Demo Cleanup', 'Generating Sample Billing Statements for ' + acct.Name);

            // Generate a given number of billing statements 
            for(Integer iMonth = 1; iMonth < NUMBER_OF_STATEMENTS + 1; iMonth++) {

                vlocity_cmt__Statement__c newStatement = new vlocity_cmt__Statement__c();
                Date dt = system.Date.today().addDays(-1 * iMonth * 28);
                Date newDate= Date.newInstance(dt.year(), dt.month(), 1);
                newStatement.vlocity_cmt__StatementDate__c = newDate;
                if (iMonth == 1) newStatement.vlocity_cmt__StatementDetails__c = 'Latest';

                newStatement.vlocity_cmt__AccountId__c = acct.Id;
                newStatement.vlocity_cmt__AdditionalDiscount__c = 0;
                newStatement.vlocity_cmt__StatementPeriodStartDate__c = newDate.addDays(-30);
                newStatement.vlocity_cmt__StatementPeriodEndDate__c = newDate.addDays(-1);
                newStatement.vlocity_cmt__DueDate__c = newDate.addDays(30);
                newStatement.Name = 'Billing Cycle - '+newDate.month() + '/' + newDate.day() + '/' + newDate.year();
                newStatement.vlocity_cmt__OverdueAmount__c = 0.0;
                newStatement.vlocity_cmt__PreviousBalance__c = 0.0;

				newStatements.add(newStatement);        
            }
        }
        insert newStatements;

        // Iterate over newStatements to create Statement Line Items
        for (vlocity_cmt__Statement__c updStatement:newStatements) {

            // Add NUMBER_OF_STATEMENT_LINEITEMS+NUMBER_OF_STATEMENT_LINEITEMS_VOD statement lines for the latest statement, NUMBER_OF_STATEMENT_LINEITEMS for the rest
            integer nStatementLineCount = NUMBER_OF_STATEMENT_LINEITEMS + 1;
            if (updStatement.vlocity_cmt__StatementDetails__c == 'Latest') nStatementLineCount = NUMBER_OF_STATEMENT_LINEITEMS + NUMBER_OF_STATEMENT_LINEITEMS_VOD + 1;

            double statementBalance=0;            
            for (integer iStatementLine = 1; iStatementLine < nStatementLineCount; iStatementLine++) {

                vlocity_cmt__StatementLineItem__c newStatementLine = new vlocity_cmt__StatementLineItem__c();                
                newStatementLine.vlocity_cmt__StatementId__c = updStatement.Id;

                Double multiplier;
                Double newBalance;
                String sliCategory;
                String sliServiceType;
                String sliServiceName;
                String sliType;
                String sliSubType;
                Integer rand;

                if (iStatementLine < NUMBER_OF_STATEMENT_LINEITEMS + 1) {

                    // Standard monthly bill
                    newBalance     = INTERNET_SERVICE_MONTHLY_PRICE;
                    sliCategory    = 'Service';
                    sliServiceType = 'Internet';
                    sliServiceName = INTERNET_SERVICE_NAME;
                    sliType        = 'Plan';
                    sliSubType     = 'Base';
                } 
                else {

                    // Additional line items for higher latest bill
                    multiplier = 1;
                    newBalance = (Math.random() + 1 * 10) * multiplier;

                    sliCategory    = 'Usage';
                    sliServiceType = 'Streaming';
                    sliType        = 'Add On';
                    sliSubType     = 'On Demand';

                    rand = Math.round(Math.ceil(Math.random() * 4));
                    sliServiceName = (rand <= 1) ? 'Series Purchase' : sliServiceName;
                    sliServiceName = (rand == 2) ? 'Movie Purchase' : sliServiceName;
                    sliServiceName = (rand == 3) ? 'Pay Per View' : sliServiceName;
                    sliServiceName = (rand >= 4) ? 'Sports Purchase' : sliServiceName;
                }

                newStatementLine.vlocity_cmt__CurrencyAmount__c = newBalance;
                newStatementLine.vlocity_cmt__StatementDate__c  = updStatement.vlocity_cmt__StatementDate__c;
                newStatementLine.vlocity_cmt__Recurring__c      = 'Y';
                newStatementLine.vlocity_cmt__OneTime__c        = 'N';
                newStatementLine.vlocity_cmt__Category__c       = sliCategory;
                newStatementLine.vlocity_cmt__ServiceType__c    = sliServiceType;
                newStatementLine.vlocity_cmt__ServiceName__c    = sliServiceName;
                newStatementLine.vlocity_cmt__Type__c           = sliType;
                newStatementLine.vlocity_cmt__Subtype__c        = sliSubType;

                newStatementLines.add(newStatementLine); 

                statementBalance += newBalance;
            }

            // Add (State) taxes and fees
            vlocity_cmt__StatementLineItem__c newStatementLine = new vlocity_cmt__StatementLineItem__c();
            newStatementLine.vlocity_cmt__StatementId__c    = updStatement.Id;
            newStatementLine.vlocity_cmt__CurrencyAmount__c = statementBalance * STATE_TAX;
            newStatementLine.vlocity_cmt__StatementDate__c  = updStatement.vlocity_cmt__StatementDate__c;
            newStatementLine.vlocity_cmt__Recurring__c      = 'N';
            newStatementLine.vlocity_cmt__OneTime__c        = 'Y';
            newStatementLine.vlocity_cmt__Category__c       = 'Taxes and Fees';
            newStatementLine.vlocity_cmt__ServiceType__c    = 'Internet';
            newStatementLine.vlocity_cmt__ServiceName__c    = 'State Tax';
            newStatementLine.vlocity_cmt__Type__c           = 'Tax';
            newStatementLine.vlocity_cmt__Subtype__c        = 'State';

            newStatementLines.add(newStatementLine); 
            statementBalance += newStatementLine.vlocity_cmt__CurrencyAmount__c; 

            // Add (Local) taxes and fees
            vlocity_cmt__StatementLineItem__c newStatementLineLocal = new vlocity_cmt__StatementLineItem__c();
            newStatementLineLocal.vlocity_cmt__StatementId__c    = updStatement.Id;
            newStatementLineLocal.vlocity_cmt__CurrencyAmount__c = statementBalance * LOCAL_TAX;
            newStatementLineLocal.vlocity_cmt__StatementDate__c  = updStatement.vlocity_cmt__StatementDate__c;
            newStatementLineLocal.vlocity_cmt__Recurring__c      = 'N';
            newStatementLineLocal.vlocity_cmt__OneTime__c        = 'Y';
            newStatementLineLocal.vlocity_cmt__Category__c       = 'Taxes and Fees';
            newStatementLineLocal.vlocity_cmt__ServiceType__c    = 'Internet';
            newStatementLineLocal.vlocity_cmt__ServiceName__c    = 'Local Tax';
            newStatementLineLocal.vlocity_cmt__Type__c           = 'Tax';
            newStatementLineLocal.vlocity_cmt__Subtype__c        = 'Local';

            newStatementLines.add(newStatementLineLocal); 
            statementBalance += newStatementLine.vlocity_cmt__CurrencyAmount__c; 

            // Regulatory Fees
            vlocity_cmt__StatementLineItem__c newStatementLineFee = new vlocity_cmt__StatementLineItem__c();
            newStatementLineFee.vlocity_cmt__StatementId__c    = updStatement.Id;
            newStatementLineFee.vlocity_cmt__CurrencyAmount__c = statementBalance * REGULATORY_FEES;
            newStatementLineFee.vlocity_cmt__StatementDate__c  = updStatement.vlocity_cmt__StatementDate__c;
            newStatementLineFee.vlocity_cmt__Recurring__c      = 'N';
            newStatementLineFee.vlocity_cmt__OneTime__c        = 'Y';
            newStatementLineFee.vlocity_cmt__Category__c       = 'Taxes and Fees';
            newStatementLineFee.vlocity_cmt__ServiceType__c    = 'Internet';
            newStatementLineFee.vlocity_cmt__ServiceName__c    = 'Regulatory Fee';
            newStatementLineFee.vlocity_cmt__Type__c           = 'Fee';
            newStatementLineFee.vlocity_cmt__Subtype__c        = 'Regulatory';

            newStatementLines.add(newStatementLineFee); 
            statementBalance += newStatementLine.vlocity_cmt__CurrencyAmount__c; 

            updStatement.vlocity_cmt__CurrentBalance__c  =  statementBalance;
            updStatement.vlocity_cmt__BalanceDue__c = updStatement.vlocity_cmt__CurrentBalance__c + updStatement.vlocity_cmt__PreviousBalance__c;
        }
        insert newStatementLines;
        update newStatements;

        DemoSystemEvent.info('Demo Cleanup', 'Finished Generating Sample Billing Statements');
    }    
}