/**
 * This class extends the default XOM Asynchronous System Interface class used by Order Management to
 * make an asynchronous Callout using an Integration Procedure (rather than a direct REST API Call).
 *
 * The general flow is as follows:
 * 
 *  -----------    ------------------    ------------    -----------------------
 * | Orch Item |  | System Interface |  | this Class |  | Integration Procedure |
 *  -----------    ------------------    ------------    -----------------------
 *       |                 |                   |                    |
 *       |     execute     |                   |                    |
 *       |---------------->|    startBatch()   |                    |
 *       |                 |------------------>|                    |
 *       |                 |                   |                    |
 *       |                 |   executeItem()   |                    |
 *       |                 |------------------>|       call         |
 *       |                 |                   |------------------->|
 *       |                 |                   |                    |<----------> Do integration stuff
 *       |                 |                   |     response/ack   |
 *       |                 | processResponse() |<-------------------|
 *       |     updates     |<------------------|                    |
 *       |<----------------|                   |                    |
 *       |     (note 1)    |    endBatch()     |                    |
 *       |                 |------------------>|                    |
 *       |                 |                   |                    |
 *       |                 |                   |                    |
 *       \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
 *                          Some time passes
 *       ////////////////////////////////////////////////////////////
 *       |                 |                   |                    |
 *       |                 |   processResponse |                    |
 *       |                 |   Deferred()      |<------------------------------- XOMAsyncResponseRESTService.processCallback() <---- REST Call
 *       |    complete     |<------------------|                    |                           (note 2)
 *       |<----------------|                   |                    |
 * 
 * 
 * note 1: By default, this class doesn't do much in terms of updates to the Orchestration Item other than capturing the IP response
 *         if there is one.  The Orchestration Item is left in an 'Active' state.
 * 
 * note 2: The default callback handler sets the Orchestration Item as 'Completed'.  If you want different behavior such as
 *         handling interim responses, you will need to create your own callback handler and modify the callback URI sent in the request
 *         accordingly.
 * 
 *
 * @author Joe McMaster (joe.mcmaster@salesforce.com)
 *
 * @version 1.6
 *
 * History
 * =======
 * 1.0 - May 24, 2019 - Initial Version
 * 1.1 - May 29, 2019 - Enhanced to support Fulfilment Request Lines
 * 1.2 - Apr 27, 2020 - Enhanced to support fetching additional Fulfillment Request Line details
 * 1.3 - Nov  6, 2020 - Fixed bug when Integration Procedures return a List object
 * 1.4 - Apr 26, 2020 - Updated Request_c and Response_c to use new Managed Package fields
 * 1.5 - Jul 29, 2020 - Fixed input to Integration Procedure so order_id is just that (not the Fulfilment Request Line)
 * 1.6 - Nov  1, 2021 - General cleanup, and updates to provide more distinct payloads for an Order Item vs. Fulfilment Request Line
 */
global class IntegrationProcedureAsyncSystemInterface extends vlocity_cmt.XOMAsyncSystemInterface {

   /* Exception class */
   public class IntegrationProcedureUnrecoverableException extends Exception {}

   /**
    * Default Constructor
    */
   global IntegrationProcedureAsyncSystemInterface() {

       super();
   }

   /**
    * This method is a part of the ISystemInterface. It is invoked at the start of the batch
    * 
    * @param url   base URL the batch is started for
    * @param path  path this batch is started for
    */
   global override void startBatch(String url, String path) {}

   /**
    * Executes a Callout OrchestrationItem
    * 
    * @param url   base URL to send the request to (in this class it is ignored)
    * @param path  path to send the request to (in this class it is interpreted as the Integration Procedure API Key)
    * @param item  OrchestrationItem that needs to be executed
    */
   global override void executeItem(String url, String path, vlocity_cmt__OrchestrationItem__c item) {

       System.debug('JOE - Orchestration Item -> ' + JSON.serialize(item.getPopulatedFieldsAsMap()));
       
       // Get the Order SObject - the technique will differ depending on if this orchestration item is related to an Order or Fulfillment Request (FR)
       // An Orchestration Item should only ever be related to a single Order Item or a Fulfilment Request Line (FRL)
       // Technically, the solution can be implemented with a 1:n relationship, but this isn't best practice (and not really supported by the default Callout code)
       // @see https://docs.vlocity.com/en/Grouping-Multiple-Fulfillment-Requests-into-One-Request.html
       Id orderId = item.vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__c;
       vlocity_cmt.XOMOrderDomainObject orderObj = null;
       if (item.vlocity_cmt__OrderItemId__c != null) {
       
            // Order Item (OI) - Get the Order Object
            orderObj = ((vlocity_cmt.XOMOrderService)vlocity_cmt.XOMObjectFactory.getService(Order.SObjectType)).getObject(orderId, true);
       }
       else {

           // Fulfilment Request Line (FRL) - Get the Fulfilment Request (FR) Object
           Set<Id> fr = new Set<Id> { 
               item.vlocity_cmt__FulfilmentRequestLineId__r.vlocity_cmt__FulfilmentRequestId__c
           };
           orderObj = ((vlocity_cmt.XOMOrderService)vlocity_cmt.XOMObjectFactory.getService(Order.SObjectType)).getFulfilmentRequests(fr, true)[0];
       }
       
       // The Payload sent to the Integration Procedure is generated by an Optional Request DataRaptor configured on the Orchestration Item Definition
       // If no Request DataRaptor is provided it will default to something like this:
       // 
       // {
       //   "responseUri" : "/services/apexrest/vlocity_cmt/asyncCallback/a2b1U000000kpOzQAI",
       //   "order_id" : "8011U000000tpvgQAA",
       //   "account_id" : "0011U00000RAyv0QAD",
       //   "order_items" : [ {
       //   	"order_item_id" : "8021U0000029DzJQAU",
       //   	"action" : "Add",
       //   	"specified_by" : {
       //   		"specification_id" : "01t1U000000rIocQAE",
       //   		"specification_name" : "Test Product"
       //  		},
       //  		"described_by" : []
       //	} ]
       // }
       // 
       Map<String, Object> ipInput   = (Map<String, Object>)JSON.deserializeUntyped(super.generatePayload(item, orderObj));
       
       // Add any extra information to the payload that might be useful and otherwise not available via the DataRaptors configured in the Callout
       ipInput.put('orchestration_item_id',   item.Id);
       ipInput.put('orchestration_item_name', item.Name);

       // Special Handling depending on the associated object (Order Item vs. Fulfilment Request Line)
       if (item.vlocity_cmt__OrderItemId__c == null) {

           // In case of Fulfilment Request, swap the order Id with the real order Id
           ipInput.put('fulfilment_request_id', ipInput.get('order_id'));
           ipInput.put('order_id', orderId);
       }

       // If you need to override the default callback URI, do it here!
       // For example: /services/apexrest/asyncIPCallback/a3A5f000000x8dZEAQ
       //ipInput.put('responseUri', 'Your Override URI');   
       
       // Call the Integration Procedure
       System.debug('JOE - Attempting to call Integration Procedure "' + path + '"');
       System.debug('JOE - IP Input -> ' + JSON.serialize(ipInput));
       Map<String, Object> ipOutput = (Map<String, Object>)vlocity_cmt.IntegrationProcedureService.runIntegrationService(path, ipInput, new Map<String, Object>());
       System.debug('JOE - IP Output -> ' + JSON.serialize(ipOutput));

       // process any response
       processResponse(item, ipInput, ipOutput);       
   }
       
   /**
    * This method is called from executeItem to handle the response from the Integration Procedure.
    * By default it does nothing (but some logging), but it could be customized to do something more.
    *
    * @param item      The Orchestration Item
    * @param ipInput   The request sent to the Integration Procedure
    * @param ipOutput  The response from the Integration Procedure (could be a list or map)
    */
   global virtual void processResponse(vlocity_cmt__OrchestrationItem__c item, Map<String, Object> ipInput, Map<String, Object> ipOutput) {
       
       // For debugging, store the Request in the Orchestration Item SObject
       if (ipInput != null) item.vlocity_cmt__Request__c = JSON.serialize(ipInput);
       if (ipOutput != null) item.vlocity_cmt__Response__c = JSON.serialize(ipOutput);

       update item;
   }

   /**
    * This method is called at the end of the batch
    * 
    * @param url   base URL for the batch
    * @param path  path for the batch
    */
   global override void endBatch(String url, String path) {}
       
   /**
    * This method is called by the Callback service when a callback is received from an external system.
    * 
    * NOTE! The default XOMAsyncResponseRESTService class will NOT call this method.  Instead it will call the super class 
    *       method XOMAsyncSystemInterface.processResponseDeferred(), so do not expect anything you put into this method to 
    *       be executed unless you create your own callback handler which explicitly creates and instance of this class and
    *       calls this method!
    * 
    * @param item      OrchestrationItem that needs to be executed
    * @param url       base URL (XOMAsyncResponseRESTService sets this to null)
    * @param path      path to send the request to (XOMAsyncResponseRESTService sets this to null)
    * @param orderObj  The order Object related to this Orchestration Item
    * @param res       The Response object to process (XOMAsyncResponseRESTService only sets the body, no headers, etc.)
    * 
    */ 
   global virtual override void processResponseDeferred(vlocity_cmt__OrchestrationItem__c item, String url, String path, vlocity_cmt.XOMOrderDomainObject orderObj, System.HttpResponse res) {

       // Customize this as needed if using your own callback handler
       super.processResponseDeferred(item, url, path, orderObj, res);
   }    
}