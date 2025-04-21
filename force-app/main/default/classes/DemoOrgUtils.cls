/**
 * This class provides high level config related to the Org.
 *  
 * @author	Joe McMaster (joe.mcmaster@salesforce.com)
 * @version	1.3
 *
 *
 * History
 * -------
 * v1.0 - May 14, 2021 - Initial Version for Multiplay Demo
 * v1.1 - Sep 10, 2021 - Added getURLs(), publishIPEvent()
 * v1.2 - May  9, 2022 - Enhanced publishIPEvent() function to better support extremely large payloads
 * v1.3 - Nov 16, 2022 - Added getVersion()
 */
global with sharing class DemoOrgUtils implements vlocity_cmt.VlocityOpenInterface2 {

    // For caching so we don't constantly have to fetch the namespace in the more complicated way!
    static String namespace = 'vlocity_cmt';

    // Generic Exception class we can use anywhere
    public class DemoException extends Exception {}

    /**
     * Returns the Vlocity/SFI Namespace for this org
     * 
     * @return The namespace
     */
    public static String getNamespace() {

        if (namespace == null) {

            List<PackageLicense> packages = [SELECT NamespacePrefix FROM PackageLicense];
            for (PackageLicense pkg : packages) {

                if (pkg.NamespacePrefix == 'vlocity_cmt' || pkg.NamespacePrefix == 'vlocity_ins' || pkg.NamespacePrefix == 'vlocityins2' || pkg.NamespacePrefix == 'vlocity_ps') {
                    namespace = pkg.NamespacePrefix;
                    break;
                }
            }
        }        

        return namespace;       
    }

    /**
     * Returns the Salesforce/Managed Package for this org
     * 
     * @return The Salesforce version and managed package version
     */
    public static Map<String, Object> getVersion() {

        Map<String, Object> versionInfo = new Map<String, Object>();

        // Get the Salesforce Version
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/data');
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        httpResponse res = http.send(req);

        List<Object> verList = (List<Object>)JSON.deserializeUntyped(res.getBody());
        if (!verList.isEmpty()) {

            Map<String, Object> latestVersion = (Map<String, Object>)verList.get(verList.size() - 1);
            versionInfo.put('SalesforceVersion', latestVersion.get('label'));
        }

        // Get the Managed Package version
        String ns = getNamespace();
        List<Publisher> publishers = [SELECT Id, MajorVersion, MinorVersion, Name, NamespacePrefix FROM Publisher WHERE NamespacePrefix=:ns];
        if (!publishers.isEmpty()) versionInfo.put('ManagedPackageVersion', publishers[0].NamespacePrefix + ' ' + publishers[0].MajorVersion + '.' + publishers[0].MinorVersion);

        return versionInfo;
    }

    /**
     * Gets the latest API version from this org
     * 
     * @return The latest API version
     */
    public static Double getApiVersion() {

        // There isn't an easy way to do this, but the following should work
        AggregateResult versionQuery = [SELECT MAX(ApiVersion) MaxVersion FROM ApexClass][0];
        return (Double)versionQuery.get('MaxVersion');
    }
    
    /**
     * Top level call by a Remote Action
     *
     * @param method  The method to execute
     * @param input   The input data provided in the call to this method
     * @param output  The output object where any results will be stored
     * @param options Any options to aid in the execution of this class
     *
     * @return true if the method completes successfully, false otherwise
     */ 
    global Boolean invokeMethod(String methodName, Map<String,Object> input, Map<String,Object> output, Map<String,Object> options) {
        
        try {      
            if (methodName == 'getURLs') return getURLs(input, output, options);            
            else if (methodName == 'publishIPEvent') return publishIntegrationProcedureEvent(input, output, options);
            else if (methodName == 'getNamespace') {
                output.put('namespace', getNamespace());
                return true;
            }
            else if (methodName == 'getVersion') {
                output.putAll(getVersion());
                return true;
            }
        }
        catch (Exception e) {
                        
            output.put('error', e.getMessage() + ':' + e.getStackTraceString());
        }
        return false;
    }
    
    /**
     * Returns the various base Salesforce URLs for this Org
     * 
     * @param input   The input data provided in the call to this method
     * @param output  The output object where any results will be stored
     * @param options Any options to aid in the execution of this class
     * 
     * @return true if the function completed successfully, false otherwise
     */
    private Boolean getURLs(Map<String,Object> input, Map<String,Object> output, Map<String,Object> options) {

        output.put('baseUrl', URL.getSalesforceBaseUrl().toExternalForm());
        output.put('domainUrl', URL.getOrgDomainUrl().toExternalForm());
		output.put('siteUrl', Site.getBaseUrl());
        
        return true;
    }

    /**
     * Generates a Platform Event which can execute an Integration Procedure
     * 
     * @param input   The input data provided in the call to this method
     * @param output  The output object where any results will be stored
     * @param options Any options to aid in the execution of this class
     * 
     * @return true if the function completed successfully, false otherwise
     */
    private Boolean publishIntegrationProcedureEvent(Map<String,Object> input, Map<String,Object> output, Map<String,Object> options) {

        // Validate the input
        String ip = (String)input.remove('IntegrationProcedure');
        
        if (ip == null || ip == '') throw new DemoOrgUtils.DemoException('Missing IntegrationProcedure');

        // Generate the JSON Input based on the incoming data
        Map<String, Object> body = new Map<String, Object>();
        body.putAll(input);

        // Be sure to provide unencrypted values when running as a guest-user (from community)
        if (body.containsKey('AccountId')) body.put('AccountId', vlocity_cmt.UserSecurity.decryptIfNecessary((String)body.get('AccountId')));
        if (body.containsKey('OrderId')) body.put('OrderId', vlocity_cmt.UserSecurity.decryptIfNecessary((String)body.get('OrderId')));
        if (body.containsKey('UserId')) body.put('UserId', vlocity_cmt.UserSecurity.decryptIfNecessary((String)body.get('UserId')));
        else body.put('UserId', UserInfo.getUserId());  // not encrypted when we get the user Id this way

        // Create the Platform Event
        Demo_Run_Integration_Procedure__e event = new Demo_Run_Integration_Procedure__e();
        event.ipkey__c = ip;
        
        // Break up the input so we can handle huge payloads (5x 131,072 chars = 655,360 chars)
        Integer NUM_OUTPUT_FIELDS = 5;
        Integer OUTPUT_FIELD_LENGTH = 131072;
            
        String payload = JSON.serialize(body);
        List<String> chunks = new List<String>();
        Integer start = 0;
        while (start < payload.length()) {

            chunks.add(payload.substring(start, Math.min(payload.length(), start + OUTPUT_FIELD_LENGTH)));
            start += OUTPUT_FIELD_LENGTH;
        }

        if (chunks.size() > NUM_OUTPUT_FIELDS) throw new DemoOrgUtils.DemoException('Integration Procedure input too large!');
        else {
            for (Integer i=0; i<chunks.size(); i++) event.put('input' + i + '__c', chunks.get(i));                
        }        

        // Publish the Platform Event
        List<Demo_Run_Integration_Procedure__e> events = new List<Demo_Run_Integration_Procedure__e>();
        events.add(event);
        List<Database.SaveResult> results = EventBus.publish(events);

        // Analyze Results
        List<String> uuids = new List<String>();
        for (Database.SaveResult sr : results) {
            
            if (!sr.isSuccess()) {
                for(Database.Error err : sr.getErrors()) throw new DemoOrgUtils.DemoException('Error Publishing Event -> ' + err.getStatusCode() + ' - ' + err.getMessage());
            }
            else uuids.add(EventBus.getOperationId(sr));
        }
        if (uuids.size() == 1) output.put('correlationId', uuids.get(0));
        else if (uuids.size() > 1) output.put('correlationId', uuids);

        return true;
    }

    /**
     * Returns the corresponding SObject Type for a given Id
     *
     * @param id  The SObject Id
     *
     * @return The SObject Description
     */
    public static Schema.DescribeSObjectResult getObjectType(Object id) {

        return ((Id)id).getSobjectType().getDescribe();
    }
}