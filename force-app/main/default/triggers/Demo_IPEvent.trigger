/**
 * This trigger executes when a "Run Integration Procedure" Platform Event is received.
 * 
 * The Platform Event must be defined within the Salesforce Org:
 * (1) Setup -> Platform Events (New)
 *    
 *     Label             = Demo - Run Integration Procedure
 *     Plural Label      = Demo - Run Integration Procedures
 *     Object Name       = Demo_Run_Integration_Procedure
 *     Description       = Event to trigger asynchronous execution of an Integration Procedure
 *     Publish Behavior  = Publish After Commit
 *     Deployment Status = Deployed
 * 
 * (2) Add the following custom fields to the newly created Platform Event
 * 
 *     ipkey (Text 255)
 *       -Description    = The key (Type_SubType) of the Integration Procedure to execute
 *       -Always Require = yes
 * 
 *     input0 (Text Area Long 131072)
 *     input1 (Text Area Long 131072)
 *     input2 (Text Area Long 131072)
 *     input3 (Text Area Long 131072)
 *     input4 (Text Area Long 131072)
 *       -Description = The input payload to send to the Integration Procedure
 *  
 * @author	Joe McMaster (joe.mcmaster@salesforce.com)
 * @version	2.0
 *
 *
 * History
 * -------
 * v1.0 - Jul 20, 2021 - Initial Version for Multiplay Demo
 * v2.0 - May  9, 2022 - Added "Response" platform event and correlation Id & support for extremely large payloads
 *
 */
trigger Demo_IPEvent on Demo_Run_Integration_Procedure__e (after insert) {
    
    for (Demo_Run_Integration_Procedure__e event : Trigger.New) {

        // Extract the Integration Procedure key & input payload
        String ipkey = event.ipkey__c;
        String correlationId = event.EventUuid;

        // reassemble chunked payload - this should dynamically work if more contiguous chunks to the response in the future!
        Map<String, Object> eventObj = event.getPopulatedFieldsAsMap();
        String fullInput = '';
        Integer index = 0;
        while (eventObj.containsKey('input' + index + '__c')) {
                            
            String chunk = (String)eventObj.get('input' + index + '__c');
            if (chunk != null) fullInput += chunk;
            index++;
        }
        if (fullInput == null || fullInput.equals('')) fullInput = '{}';

        System.debug('Platform Event: Running Integration Procedure (' + ipkey + ') with input -> ' + fullInput);
        Object output = vlocity_cmt.IntegrationProcedureService.runIntegrationService(ipkey, (Map<String, Object>)JSON.deserializeUntyped(fullInput), new Map<String, Object>());
        System.debug('Platform Event: Completed Integration Procedure (' + ipkey + ') with response -> ' + output);

        // Publish the response
        if (correlationId != null) {

            Demo_Integration_Procedure_Response__e responseEvent = new Demo_Integration_Procedure_Response__e();
            responseEvent.correlationId__c = correlationId;
            responseEvent.ipkey__c = ipkey;

            // Break up the output so we can handle huge payloads (5x 131,072 chars = 655,360 chars)
            Integer NUM_OUTPUT_FIELDS = 5;
            Integer OUTPUT_FIELD_LENGTH = 131072;
            
            String payload = JSON.serialize(output);
            List<String> chunks = new List<String>();
            Integer start = 0;
            while (start < payload.length()) {

                chunks.add(payload.substring(start, Math.min(payload.length(), start + OUTPUT_FIELD_LENGTH)));
                start += OUTPUT_FIELD_LENGTH;
            }

            if (chunks.size() > NUM_OUTPUT_FIELDS) responseEvent.output0__c = '{"error": "IP Response too large!"}';
            else {
                for (Integer i=0; i<chunks.size(); i++) responseEvent.put('output' + i + '__c', chunks.get(i));                
            }

            System.debug('Platform Event: Publishing Integration Procedure Response');
            System.debug('Platform Event: Num Chunks ' + chunks.size());

            // Publish the Platform Event
            List<Demo_Integration_Procedure_Response__e> responseEvents = new List<Demo_Integration_Procedure_Response__e>();
            responseEvents.add(responseEvent);
            List<Database.SaveResult> results = EventBus.publish(responseEvents);

            // Analyze Results
            for (Database.SaveResult sr : results) {
            
                if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) throw new DemoOrgUtils.DemoException('Error Publishing Response Event -> ' + err.getStatusCode() + ' - ' + err.getMessage());
                }
            }            
        }
    }
}