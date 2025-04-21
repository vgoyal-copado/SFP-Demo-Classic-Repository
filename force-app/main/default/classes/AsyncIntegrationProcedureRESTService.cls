/**
 * This class provides a REST endpoint in Salesforce where an external system can post asynchronous status updates & events
 * which will be processed by an Integration Procedure.  This class can handle multiple events for a given Orchestration Item
 * and you can control the logic as needed (i.e. complete orchestration item, move orchestration item to PONR, etc.).
 * 
 * This is useful if you need more functionality/logic than the standard XOMAsyncResponseREST class
 * which simply completes the Orchestration Item when the first event is received.
 * 
 * Setup
 * =====
 * In order properly set this up, you should:
 * (1) Deploy this Apex class to Salesforce
 * (2) Configure an Asynchronous Orchestration Item Definition
 *     -Use a System Interface that points to IntegrationProcedureAsyncSystemInterface class
 *     -Expose the custom callback URI field (Setup -> Object Manager -> Orchestration Item Definition -> Fields & Relationships -> Use Custom Callback URI)
 *       -Make sure to expose it on the correct layout (i.e. Callout)
 *       -Enable it for this Orchestration Item Definition
 *     -Configure the custom callback URI (by default, this object is not exposed as a tab)
 *       -Expose the tab (Setup -> Tabs (New) -> Object = CallbackURI)
 *       -Refresh your browser
 *       -Add the custom URI (App Launcher -> CallbackURIs (New) -> Name = XOMCallback, Path = asyncIPCallback/
 *     -To support Order Cancellation, be sure to set the Cancel/Amend Behaviour = Smart Freeze
 *     -If we need to 
 * 
 * REST Requirements
 * =================
 * External systems should receive an initial JSON request (i.e. from IntegrationProcedureAsyncSystemInterface) containing the callback URI in the form:
 *   {
 *     "responseUri": "/services/apexrest/asyncIPCallback/<orchestrationItemId>"
 *     ...
 *   }
 *  where <orchestrationItemId> is the Id for the Orchestration Item that sent the request
 * 
 * -The system must be authenticated with Salesforce (OAuth2.0) in order to send updates
 * -The system should perform an HTTP-POST to this URI (with the Salesforce domain name prepended to this URI to make it a FQDN)
 * -The system can send multiple, asynchronous events
 * -The HTTP Content-Type must be 'application/json' and the payload must be a valid JSON string containig the event information
 * 
 * Integration Procedure Input Sample
 * ==================================
 * When this endpoint is called by an external system, this class will assemble some useful information about the target Orchestration Item along
 * with any event information sent by the external system and include this as input to the Integration Procedure.  
 * 
 * The following are sample inputs you can use to build and test the Integration Procedure and adjust as necessary.
 * 
 * Sample from an Orchestration Item associated to an Order Item
    {
      "event": {
        "data": "somedata",
        "eventType": "none"
      },
      "supplemental_action": null,
      "sub_action": null,
      "action": "Add",
      "order_id": "8015f000000gDHtAAM",
      "order_item_id": "8025f000000tDUdAAM",
      "orchestration_item_state": "Running",
      "orchestration_item_name": "Async Callout",
      "orchestration_item_id": "a3A5f000000x8DsEAI"
    }
 * 
 * Sample from an Orchestration Item associated to a Fulfilment Request Line (FRL)
 * 
    {
      "event": {
        "data": "somedata",
        "eventType": "none"
      },
      "supplemental_action": null,
      "sub_action": null,
      "action": "Add",
      "order_id": "8015f000000gDveAAE",
      "fulfilment_request_id": "a2D5f000000PgaMEAS",
      "fulfilment_request_line_id": "a2C5f000000h54vEAA",
      "orchestration_item_state": "Running",
      "orchestration_item_name": "Async Callout",
      "orchestration_item_id": "a3A5f000000x8dZEAQ"
    }
 * 
 * @author Joe McMaster (joe.mcmaster@salesforce.com)
 *
 * @version 1.1
 *
 * History
 * =======
 * 1.0 - Oct 28, 2021 - Initial Version for Vivo PoC
 * 1.1 - Nov  1, 2021 - Added better support for FRLs and sending action related information to IP
 * 
 */
@RestResource(UrlMapping='/asyncIPCallback/*')
global with sharing class AsyncIntegrationProcedureRESTService {
    
    // Integration Procedure to call
    public static final String IP_KEY = 'XOM_HandleEvent';

    // Valid Orchestration Item States for which we will process events
    public static final Set<String> VALID_ORCHITEM_STATES = new Set<String> {
        'Running'
    };

    /* Exception classes */
    public class OrchItemNotFoundException extends Exception {}
    public class InvalidContentException extends Exception {}
    public class IntegrationProcedureException extends Exception {}

    /**
     * Handles an asynchronous event from an external system and passes the
     * information to an Integration Procedure
     * 
     */
    @HttpPost
    global static void processCallback() {

        try {

            RestRequest req = RestContext.request;
            Id orchItemId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);

            // Retrieve the Orchestration Item
            vlocity_cmt__OrchestrationItem__c item = getOrchestrationItem(orchItemId);

            // If an Orchestration Item was found, proceed to handle the event
            if (item != null) {

                // Treat this request as an asynchronous response to an earlier message sent by XOM
                processAsyncResponse(item, req);

                // Call the Integration Procedure
                Map<String, Object> ipOutput = (Map<String, Object>)runIP(IP_KEY, item, req);

                // Commit Changes - so we can save any changes happen to OrderDomainObject/OrderItemDomainObjects in processResponseDeferred
                vlocity_cmt.XOMObjectFactory.commitObjs();

                // If we make it here, everything is A-OK!
                buildResponse(RestContext.response, 200, 'success', ipOutput);
            }
            else throw new OrchItemNotFoundException('Ignoring async request for orchestration item ' + orchItemId + ' as no item was found or the item isn\'t in a valid state ' + VALID_ORCHITEM_STATES + ' to handle the request.');
        }
        catch (OrchItemNotFoundException e) {
            System.debug(LoggingLevel.ERROR, 'JOE -> ' + e.getMessage());
            buildResponse(RestContext.response, 404, e.getMessage(), null);  // Not Found
        }
        catch (InvalidContentException e) {
            System.debug(LoggingLevel.ERROR, 'JOE -> ' + e.getMessage());
            buildResponse(RestContext.response, 415, e.getMessage(), null);  // Unsupported Media Type
        }
        catch (Exception e) {

            // Somehing unexpected happened!
            System.debug(LoggingLevel.ERROR, 'JOE -> ' + e.getMessage());
            buildResponse(RestContext.response, 500, e.getMessage(), null);  // Internal Server Error
        }
    }

    /**
     * Retrieves the given Orchestration item if it is in a valid state (i.e. Running, etc.).  
     * Orchestration Items in other states should ignore events
     * 
     * @param orchItemId  The Orchestration Item Id to fetch
     * 
     * @return The Orchestration Item if found and in a valid state, null otherwise
     */
    private static vlocity_cmt__OrchestrationItem__c getOrchestrationItem(Id orchItemId) {

        // Retrieve OrchestrationItem
        List<vlocity_cmt__OrchestrationItem__c> items = [
            SELECT Id,
                   Name,
                   vlocity_cmt__State__c,
                   vlocity_cmt__ResponseVlocityDataRaptorBundleId__r.Name,
                   vlocity_cmt__ResponseItemsVlocityDataRaptorBundleId__r.Name,
                   vlocity_cmt__ResponseAttrsVlocityDataRaptorBundleId__r.Name,
                   vlocity_cmt__AttributesEncodingStyle__c,
                   vlocity_cmt__OrderItemsNodeName__c,
                   vlocity_cmt__Response__c,
                   vlocity_cmt__OrchestrationItemDefinitionId__r.vlocity_cmt__CustomTaskExecutionURL__c,
                   vlocity_cmt__OrderItemId__r.OrderId,
                   vlocity_cmt__OrderItemId__r.vlocity_cmt__Action__c,
                   vlocity_cmt__OrderItemId__r.vlocity_cmt__SubAction__c,
                   vlocity_cmt__OrderItemId__r.vlocity_cmt__SupplementalAction__c,
                   vlocity_cmt__FulfilmentRequestLineId__r.vlocity_cmt__FulfilmentRequestID__c,
                   vlocity_cmt__FulfilmentRequestLineId__r.vlocity_cmt__FulfilmentRequestID__r.vlocity_cmt__OrderId__c,
                   vlocity_cmt__FulfilmentRequestLineId__r.vlocity_cmt__Action__c,
                   vlocity_cmt__FulfilmentRequestLineId__r.vlocity_cmt__SubAction__c,
                   vlocity_cmt__FulfilmentRequestLineId__r.vlocity_cmt__SupplementalAction__c
            FROM vlocity_cmt__OrchestrationItem__c
            WHERE Id = :orchItemId AND vlocity_cmt__State__c = :VALID_ORCHITEM_STATES
            LIMIT 1
        ];
        
        // Return the item if we found one
        if (!items.isEmpty()) return items.get(0);

        // No item was found (or the item is currently in an invalid state)
        return null;
    }

    /**
     * Process the async event we just received as a response to an earlier request generated by XOM
     * 
     * @param item   The corresponding Orchestration Item the request is targetting
     * @param event  The original event we received asynchronously
     * 
     * @return The Order Domain Object (Order Item or Fulfillment Request Line)
     */
    private static vlocity_cmt.XOMOrderDomainObject processAsyncResponse(vlocity_cmt__OrchestrationItem__c item, RestRequest event) {

       // Get the Order SObject - the technique will differ depending on if this orchestration item is related to an Order or Fulfillment Request (FR)
       // An Orchestration Item should only ever be related to a single Order Item or a Fulfilment Request Line (FRL)
       // Technically, the solution can be implemented with a 1:n relationship, but this isn't best practice (and not really supported by the default Callout code)       
       // @see https://docs.vlocity.com/en/Grouping-Multiple-Fulfillment-Requests-into-One-Request.html
       vlocity_cmt.XOMOrderDomainObject orderObj = null;
       if (item.vlocity_cmt__OrderItemId__c != null) {
       
            // Order Item (OI) - Get the Order Object
            Id orderId = item.vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__c;
            orderObj = ((vlocity_cmt.XOMOrderService)vlocity_cmt.XOMObjectFactory.getService(Order.SObjectType)).getObject(orderId, true);
       }
       else {

           // Fulfilment Request Line (FRL) - Get the Fulfilment Request (FR) Object
           Set<Id> fr = new Set<Id> { 
               item.vlocity_cmt__FulfilmentRequestLineId__r.vlocity_cmt__FulfilmentRequestId__c
           };
           orderObj = ((vlocity_cmt.XOMOrderService)vlocity_cmt.XOMObjectFactory.getService(Order.SObjectType)).getFulfilmentRequests(fr, true)[0];
       }

        // Treat this incoming event as a response to the original, asynchronous request generated earlier by the Orchestration Item
        HttpResponse resp = new HttpResponse();
        resp.setBody(event.requestBody.toString());
        vlocity_cmt.XOMAsyncSystemInterface asyncSI = new vlocity_cmt.XOMAsyncSystemInterface();
        asyncSI.processResponseDeferred(item, null, null, orderObj, resp);

        // Update the item with any changes (i.e. event details to Response field, etc.)
        update item;

        return orderObj;
    }

    /**
     * Executes the Intgration Procedure and passes in the Orchestration Item and event details
     * 
     * @param ipKey  The Integration Procedure key
     * @param item   The corresponding Orchestration Item
     * @param event  The original event we received asynchronously
     * 
     * @return The result of the Integration Procedure
     */
    private static Map<String, Object> runIP(String ipKey, vlocity_cmt__OrchestrationItem__c item, RestRequest event) {

        // Prepare they Integration Procedure payload
        Map<String, Object> ipInput = new Map<String, Object>();
        ipInput.put('orchestration_item_id', item.Id);
        ipInput.put('orchestration_item_name', item.Name);
        ipInput.put('orchestration_item_state', item.vlocity_cmt__State__c);
        
        // Pull out fields based on the object type related to this orchesration item (Order Item vs. Fulfilment Request Line)
        if (item.vlocity_cmt__OrderItemId__r.OrderId != null) {

            // Order Item
            ipInput.put('order_item_id', item.vlocity_cmt__OrderItemId__c);
            ipInput.put('order_id', item.vlocity_cmt__OrderItemId__r.OrderId);            
            ipInput.put('action', item.vlocity_cmt__OrderItemId__r.vlocity_cmt__Action__c);
            ipInput.put('sub_action', item.vlocity_cmt__OrderItemId__r.vlocity_cmt__SubAction__c);
            ipInput.put('supplemental_action', item.vlocity_cmt__OrderItemId__r.vlocity_cmt__SupplementalAction__c);
        }
        else {

            // Fulfilment Request Line (FRL)
            ipInput.put('fulfilment_request_line_id', item.vlocity_cmt__FulfilmentRequestLineId__c);
            ipInput.put('fulfilment_request_id', item.vlocity_cmt__FulfilmentRequestLineId__r.vlocity_cmt__FulfilmentRequestID__c);            
            ipInput.put('order_id', item.vlocity_cmt__FulfilmentRequestLineId__r.vlocity_cmt__FulfilmentRequestID__r.vlocity_cmt__OrderId__c);            
            ipInput.put('action', item.vlocity_cmt__FulfilmentRequestLineId__r.vlocity_cmt__Action__c);
            ipInput.put('sub_action', item.vlocity_cmt__FulfilmentRequestLineId__r.vlocity_cmt__SubAction__c);
            ipInput.put('supplemental_action', item.vlocity_cmt__FulfilmentRequestLineId__r.vlocity_cmt__SupplementalAction__c);
        }

        String eventBody = event.requestBody.toString();
        if (eventBody != null && !eventBody.equals('')) {

            // Confirm the body contains JSON
            String contentType = event.headers.get('Content-Type');
            if (contentType.contains('application/json')) ipInput.put('event', JSON.deserializeUntyped(eventBody));
            else throw new InvalidContentException('Invalid Content-Type "' + contentType + '", expected "application/json"');
        }
        else System.debug(LoggingLevel.WARN, 'JOE - No event data was sent in the request');

        // Call the Integration Procedure
        System.debug('JOE - Attempting to call Integration Procedure "' + ipKey + '"');
        System.debug('JOE - IP Input -> ' + JSON.serialize(ipInput));
        Map<String, Object> ipOutput = (Map<String, Object>)vlocity_cmt.IntegrationProcedureService.runIntegrationService(ipKey, ipInput, new Map<String, Object>());
        System.debug('JOE - IP Output -> ' + JSON.serialize(ipOutput));

        // Check success of IP execution
        if (ipOutput.containsKey('error') && !((String)ipOutput.get('error')).equalsIgnoreCase('ok')) {                    
            throw new IntegrationProcedureException('Integration Procedure ' + ipKey + ' error: ' + ipOutput.get('error'));
        }

        // Return the result of the Integration Procedure
        return ipOutput;
    }

    /**
     * Builds the REST response we will send back
     * 
     * @param response  The REST response object
     * @param code      The HTTP Code to send
     * @param msg       The message to send in the response
     * @param output    Optional output to add to the response
     */
    private static void buildResponse(RestResponse response, Integer code, String msg, Map<String, Object> output) {        

        response.statusCode = code;

        // Build the JSON body
        Map<String, Object> body = new Map<String, Object>();
        if (code == 200) {
            body.put('success', true);
            body.put('msg', msg);
        }
        else {
            body.put('success', false);
            body.put('msg', msg);
        }
        if (output != null) body.put('output', output);        
        response.headers.put('Content-Type', 'application/json');
        response.responseBody = Blob.valueOf(JSON.serialize(body));
    }
}