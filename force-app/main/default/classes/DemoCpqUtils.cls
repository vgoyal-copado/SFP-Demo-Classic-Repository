/**
 * This class provides utilities help with CPQ related operations
 *  
 * @author	Joe McMaster (joe.mcmaster@salesforce.com)
 * @version	1.2
 *
 *
 * History
 * -------
 * v1.0 - May 21, 2021 - Initial Version for Multiplay Demo
 * v1.1 - Aug 25, 2021 - Added getCartsTargetOffers method to support Change-of-Plan flows
 * v1.2 - Jun 29, 2022 - Enhanced reparentOrder() method to properly set service/billing accounts on order and order items
 * v1.2 - Nov  3, 2022 - Updated to Callable interface, added getAttributes method/custom formula
 *
 */
global without sharing class DemoCpqUtils implements vlocity_cmt.VlocityOpenInterface2, Callable {

    /**
	 * Top level call by an OmniStudio DataRaptor or Integration Procedure (OmniStudio)
	 *
     * @param action  - The action/method to execute
     * @param args    - The input, output, and options arguments
     *
     * @returns true if the method completes successfully, false otherwise
     */ 
     public Object call(String action, Map<String, Object> args) {

        return invokeMethod(action, (Map<String, Object>)args.get('input'), (Map<String, Object>)args.get('output'), (Map<String, Object>)args.get('options'));
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

            if (methodName == 'reparentOrder') return reparentOrder(input, output, options);            
            else if (methodName == 'getOrderDetails') return getOrderDetails(input, output, options);
            else if (methodName == 'setOrderAddress') return setOrderAddress(input, output, options);
            else if (methodName == 'setOrderName') return setOrderName(input, output, options);
            else if (methodName == 'setBillingAddress') return setBillingAddress(input, output, options);
            else if (methodName == 'addPaymentMethodAsUser') return addPaymentMethodAsUser(input, output, options);
            else if (methodName == 'submitOrderAsUser') return submitOrderAsUser(input, output, options);
            else if (methodName == 'getCartsTargetOffers') return getCartsTargetOffers(input, output, options);
            else if (methodName == 'getAttributes') return getAttributes(input, output, options);
        }
        catch (Exception e) {

            output.put('error', e.getMessage() + ':' + e.getStackTraceString());
        }

        return false;
    }

    /**
     * Attempts to reparent an order.  Useful in guest-user situations where an order is created under
     * a temporary account until the user registers to complete a buy flow.  At this point we want to 
     * reparent the order under a newly created account for the user.
     * 
     * @param input   The input data provided in the call to this method
     * @param output  The output object where any results will be stored
     * @param options Any options to aid in the execution of this class
     * 
     * @return true if the function completed successfully, false otherwise
     */
    private Boolean reparentOrder(Map<String,Object> input, Map<String,Object> output, Map<String,Object> options) {

        String orderId   = (String)input.get('OrderId');
        String accountId = (String)input.get('AccountId');

        if (orderId == null || orderId == '')     throw new DemoOrgUtils.DemoException('Missing OrderId');
        if (accountId == null || accountId == '') throw new DemoOrgUtils.DemoException('Missing AccountId');

        // Update the Order
        Order order = [SELECT Id, AccountId, vlocity_cmt__DefaultBillingAccountId__c, vlocity_cmt__DefaultServiceAccountId__c FROM Order WHERE Id=:orderId][0];
        order.AccountId = accountId;
        if (order.vlocity_cmt__DefaultBillingAccountId__c != null) order.vlocity_cmt__DefaultBillingAccountId__c = accountId;
        if (order.vlocity_cmt__DefaultServiceAccountId__c != null) order.vlocity_cmt__DefaultServiceAccountId__c = accountId;
        update order;

        // Update related accounts for each Line Item
        OrderItem[] lineItems = [SELECT Id, vlocity_cmt__BillingAccountId__c, vlocity_cmt__ServiceAccountId__c FROM OrderItem WHERE OrderId=:orderId];
        for(OrderItem li: lineItems) {
            if (li.vlocity_cmt__BillingAccountId__c != null) li.vlocity_cmt__BillingAccountId__c = accountId;
            if (li.vlocity_cmt__ServiceAccountId__c != null) li.vlocity_cmt__ServiceAccountId__c = accountId;
        }
        update lineItems;

        return true;
    }

    /**
     * Attempts to set the Billing Address on an Account and/or Contact record
     * 
     * @param input   The input data provided in the call to this method
     * @param output  The output object where any results will be stored
     * @param options Any options to aid in the execution of this class
     * 
     * @return true if the function completed successfully, false otherwise
     */
    private Boolean setBillingAddress(Map<String,Object> input, Map<String,Object> output, Map<String,Object> options) {

        String accountId     = (String)input.get('AccountId');
        String contactId     = (String)input.get('ContactId');
        String streetAddress = (String)input.get('StreetAddress');
        String city          = (String)input.get('City');
        String state         = (String)input.get('State');
        String country       = (String)input.get('Country');
        String postalCode    = (String)input.get('PostalCode');

        if ((accountId == null || accountId == '') && (contactId == null || contactId == '')) throw new DemoOrgUtils.DemoException('Missing AccountId or ContactId');
        if (streetAddress == null || streetAddress == '') throw new DemoOrgUtils.DemoException('Missing StreetAddress');
        if (city == null || city == '')                   throw new DemoOrgUtils.DemoException('Missing City');
        if (state == null || state == '')                 throw new DemoOrgUtils.DemoException('Missing State');
        if (country == null || country == '')             throw new DemoOrgUtils.DemoException('Missing Country');
        if (postalCode == null || postalCode == '')       throw new DemoOrgUtils.DemoException('Missing PostalCode');

        // Fetch the Account
        if (accountId != null && accountId != '') {

            Account account = [SELECT BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode FROM Account WHERE Id=:accountId][0];
            
            // Set the Billing Address
            account.BillingStreet     = streetAddress;
            account.BillingCity       = city;
            account.BillingState      = state;
            account.BillingCountry    = country;
            account.BillingPostalCode = postalCode;        

            update account;
        }

        // Fetch the Contact
        if (contactId != null && contactId != '') {

            Contact contact = [SELECT OtherStreet, OtherCity, OtherState, OtherCountry, OtherPostalCode FROM Contact WHERE Id=:contactId][0];

            // Set the Billing (Other) Address
            contact.OtherStreet     = streetAddress;
            contact.OtherCity       = city;
            contact.OtherState      = state;
            contact.OtherCountry    = country;
            contact.OtherPostalCode = postalCode;   

            update contact;
        }

        return true;
    }

    /**
     * Attempts to copy the address details of the parent account to the order
     * 
     * @param input   The input data provided in the call to this method
     * @param output  The output object where any results will be stored
     * @param options Any options to aid in the execution of this class
     * 
     * @return true if the function completed successfully, false otherwise
     */
    private Boolean setOrderAddress(Map<String,Object> input, Map<String,Object> output, Map<String,Object> options) {

        String orderId   = (String)input.get('OrderId');

        if (orderId == null || orderId == '') throw new DemoOrgUtils.DemoException('Missing OrderId');

        // Fetch the Order and Account
        Order order = [SELECT Id, AccountId FROM Order WHERE Id=:orderId][0];
        Account account = [SELECT BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode, ShippingStreet, ShippingCity, ShippingState, ShippingCountry, ShippingPostalCode FROM Account WHERE Id=:order.AccountId][0];

        // Set Order Address from account
        order.BillingStreet      = account.BillingStreet;
        order.BillingCity        = account.BillingCity;
        order.BillingState       = account.BillingState;
        order.BillingCountry     = account.BillingCountry;
        order.BillingPostalCode  = account.BillingPostalCode;
        order.ShippingStreet     = account.ShippingStreet;
        order.ShippingCity       = account.ShippingCity;
        order.ShippingState      = account.ShippingState;
        order.ShippingCountry    = account.ShippingCountry;
        order.ShippingPostalCode = account.ShippingPostalCode;

        update order;

        return true;
    }

    /**
     * Attempts to set the order name
     * 
     * @param input   The input data provided in the call to this method
     * @param output  The output object where any results will be stored
     * @param options Any options to aid in the execution of this class
     * 
     * @return true if the function completed successfully, false otherwise
     */
    private Boolean setOrderName(Map<String,Object> input, Map<String,Object> output, Map<String,Object> options) {

        String orderId      = (String)input.get('OrderId');
        String orderName    = (String)input.get('OrderName');
        String orderChannel = (String)input.get('Channel');

        if (orderId == null || orderId == '')     throw new DemoOrgUtils.DemoException('Missing OrderId');
        if (orderName == null || orderName == '') throw new DemoOrgUtils.DemoException('Missing OrderName');

        // Fetch the Order and Account
        Order order = [SELECT Id, Name, vlocity_cmt__OriginatingChannel__c FROM Order WHERE Id=:orderId][0];        
        if (orderChannel != null) order.vlocity_cmt__OriginatingChannel__c = orderChannel;
        order.Name = orderName;
        update order;

        return true;
    }

    /**
     * Gets the Order Details
     * 
     * @param input   The input data provided in the call to this method
     * @param output  The output object where any results will be stored
     * @param options Any options to aid in the execution of this class
     * 
     * @return true if the function completed successfully, false otherwise
     */
    private Boolean getOrderDetails(Map<String,Object> input, Map<String,Object> output, Map<String,Object> options) {

        String orderId   = (String)input.get('OrderId');

        if (orderId == null || orderId == '') throw new DemoOrgUtils.DemoException('Missing OrderId');

        Order order = [SELECT Id, Name, OrderNumber, Status, vlocity_cmt__FulfilmentStatus__c, vlocity_cmt__OrchestrationPlanId__c FROM Order WHERE Id=:orderId][0];

        output.put('OrderId', vlocity_cmt.UserSecurity.encryptIfNecessary(order.Id));
        output.put('OrderName', order.Name);
        output.put('OrderNumber', order.OrderNumber);
        output.put('ShortOrderNumber', order.OrderNumber.replaceAll('^0+', ''));
        output.put('OrderStatus', order.Status);
        output.put('OrderFulfilmentStatus', order.vlocity_cmt__FulfilmentStatus__c);
        output.put('OrchestrationPlanId', order.vlocity_cmt__OrchestrationPlanId__c);

        return true;
    }

    /**
     * Submits an order as a specific user.  This is most useful when we are in an anonymous buy-flow and we need
     * to submit an order as a guest user.  Guest users can perform most CPQ/DC operations except for submitting the final
     * order submission to OM.  This method is useful to automatically login the user (so they are no longer anonymous) 
     * and submit the order by calling an integration procedure
     * 
     * @param input   The input data provided in the call to this method
     * @param output  The output object where any results will be stored
     * @param options Any options to aid in the execution of this class
     * 
     * @return true if the function completed successfully, false otherwise
     */
    private Boolean submitOrderAsUser(Map<String,Object> input, Map<String,Object> output, Map<String,Object> options) {

        // Validate the input
        String orderId   = (String)input.get('OrderId');
        String username  = (String)input.get('Username');
        String password  = (String)input.get('Password');
        String vip       = (String)input.get('IntegrationProcedure');

        if (orderId == null || orderId == '')   throw new DemoOrgUtils.DemoException('Missing OrderId');
        if (username == null || username == '') throw new DemoOrgUtils.DemoException('Missing Username');
        if (password == null || password == '') throw new DemoOrgUtils.DemoException('Missing Password');
        if (vip == null || vip == '')           throw new DemoOrgUtils.DemoException('Missing IntegrationProcedure');

        // Generate the JSON Request based on the incoming data (remove sensitive bits that the Integration Procedure doesn't need)
        Map<String, Object> body = new Map<String, Object>();
        body.putAll(input);
        body.remove('Username');
        body.remove('Password');
        body.remove('IntegrationProcedure');

        // Be sure to provide unencrypted values when running as a guest-user
        body.put('OrderId', vlocity_cmt.UserSecurity.decryptIfNecessary(orderId));

        output.putAll(executeIntegrationProcedureAsUser(username, password, vip, body));

        // Encrypt the OrderId value if one is returned and we are the guest user
        if (output.containsKey('OrderId')) output.put('OrderId', vlocity_cmt.UserSecurity.encryptIfNecessary((String)output.get('OrderId')));

        return true;
    }

    /**
     * Adds a Payment Method as a specific user
     * 
     * @param input   The input data provided in the call to this method
     * @param output  The output object where any results will be stored
     * @param options Any options to aid in the execution of this class
     * 
     * @return true if the function completed successfully, false otherwise
     */
    private Boolean addPaymentMethodAsUser(Map<String,Object> input, Map<String,Object> output, Map<String,Object> options) {

        // Validate the input
        String accountId = (String)input.get('AccountId');
        String username  = (String)input.get('Username');
        String password  = (String)input.get('Password');
        String vip       = (String)input.get('IntegrationProcedure');

        if (accountId == null || accountId == '') throw new DemoOrgUtils.DemoException('Missing AccountId');
        if (username == null || username == '')   throw new DemoOrgUtils.DemoException('Missing Username');
        if (password == null || password == '')   throw new DemoOrgUtils.DemoException('Missing Password');
        if (vip == null || vip == '')             throw new DemoOrgUtils.DemoException('Missing IntegrationProcedure');

        // Generate the JSON Request based on the incoming data (remove sensitive bits that the Integration Procedure doesn't need)
        Map<String, Object> body = new Map<String, Object>();
        body.putAll(input);
        body.remove('Username');
        body.remove('Password');
        body.remove('IntegrationProcedure');

        // Be sure to provide unencrypted values when running as a guest-user
        body.put('AccountId', vlocity_cmt.UserSecurity.decryptIfNecessary(accountId));

        output.putAll(executeIntegrationProcedureAsUser(username, password, vip, body));

        return true;
    }

    /**
     * Retrieves the attributes from a Product, Opportunity Line Item, Quote Line Item, Order Item, or Asset object
     * 
     * @param input   The input data provided in the call to this method
     * @param output  The output object where any results will be stored
     * @param options Any options to aid in the execution of this class
     * 
     * @return true if the function completed successfully, false otherwise
     */
    private Boolean getAttributes(Map<String,Object> input, Map<String,Object> output, Map<String,Object> options) {

        // Get the Id of the Object to examine
        // When called from a Remote Action, we expect an 'Id' parameter
        // When called from a Custom Formula, we expect an 'arguments' parameter which then contains the 'Id' parameter
        String objectId = null;        
        if (input.containsKey('Id')) objectId = (String)input.get('Id');
        else if (input.containsKey('arguments')) {

            List<Object> args = (List<Object>)input.get('arguments');

            // When calling from a Custom Formula we should return nothing if no arguments are provided, an exception will be too harsh for DataRaptor/IPs
            if (!args.isEmpty() && args[0] != null) objectId = (String)args[0];
            else {
                output.put('result', null);
                return false;
            }
        }

        // Error checking
        if (objectId == null || objectId == '') throw new DemoOrgUtils.DemoException('Missing Id');
        
        // Determine the type of Object we are dealing with
        String objectType = DemoOrgUtils.getObjectType(objectId).getName();

        // Build the Query
        String jsonAttributes = null;     // V1 Attribute Model
        String attributeMetadata = null;  // V2 Attribute Model
        String attributeValues = null;    // V2 Attribute Model
        switch on objectType {

            when 'Product2' {
                
                String query = 'SELECT vlocity_cmt__JSONAttribute__c, vlocity_cmt__AttributeMetadata__c, vlocity_cmt__AttributeDefaultValues__c FROM ' + objectTYpe + ' WHERE Id=\'' + objectId + '\'';
                
                List<SObject> objs = Database.query(query);
                if (objs.isEmpty()) throw new DemoOrgUtils.DemoException(objectType + ' object with Id = ' + objectId + ' was not found!');
                else {
                    jsonAttributes = (String)objs[0].get('vlocity_cmt__JSONAttribute__c');
                    attributeMetadata = (String)objs[0].get('vlocity_cmt__AttributeMetadata__c');
                    attributeValues = (String)objs[0].get('vlocity_cmt__AttributeDefaultValues__c');
                }
            }

            when 'OpportunityLineItem', 'QuoteLineItem', 'OrderItem', 'Asset' {

                String query = 'SELECT vlocity_cmt__JSONAttribute__c, Product2.vlocity_cmt__AttributeMetadata__c, vlocity_cmt__AttributeSelectedValues__c FROM ' + objectTYpe + ' WHERE Id=\'' + objectId + '\'';
                
                List<SObject> objs = Database.query(query);
                if (objs.isEmpty()) throw new DemoOrgUtils.DemoException(objectType + ' object with Id = ' + objectId + ' was not found!');
                else {
                    jsonAttributes = (String)objs[0].get('vlocity_cmt__JSONAttribute__c');
                    attributeMetadata = (String)objs[0].getSObject('Product2').get('vlocity_cmt__AttributeMetadata__c');
                    attributeValues = (String)objs[0].get('vlocity_cmt__AttributeSelectedValues__c');
                }                
            }

            // Unsupported SObject
            when else {
                throw new DemoOrgUtils.DemoException(objectType + ' objects are not supported!');
            }
        }

        // Always prefer the V2 Attribute model if it is present
        if (String.isNotBlank(attributeMetadata)) output.put('result', getV2Attributes(attributeMetadata, attributeValues));
        else output.put('result', getV1Attributes(jsonAttributes));

        return true;
    }

    /**
     * Returns the V1 Attribute definitions for a Product, Opportunity Line Item, Quote Line Item, Order Item, or Asset object
     *
     * @param jsonAttributes  The JSON encoded attribute value
     *
     * @return The attributes in a simple list
     */
    private List<Object> getV1Attributes(String jsonAttributes) {

        List<Object> attributeList = new List<Object>();

        if (String.isNotBlank(jsonAttributes)) {
        
            Map<String, Object> json = (Map<String, Object>)JSON.deserializeUntyped(jsonAttributes);
            Iterator<String> categoryIterator = json.keySet().iterator();
            while (categoryIterator.hasNext()) {

                // Get the attributes within the category
                List<Object> category = (List<Object>)json.get(categoryIterator.next());
                for (Integer i=0; i<category.size(); i++) {

                    Map<String, Object> att = (Map<String, Object>)category[i];

                    Object value = att.get('value__c');

                    // Create Entry
                    Map<String, Object> entry = new Map<String, Object>();
                    entry.put('Code', att.get('attributeuniquecode__c'));
                    entry.put('Name', att.get('attributedisplayname__c'));
                    entry.put('Value', value);
                    entry.put('Label', String.valueOf(value));   // Default the label in case we don't have one in the metadata

                    // Add the value label if we can find one
                    if (att.containsKey('attributeRunTimeInfo')) {

                        Map<String, Object> runtimeInfo = (Map<String, Object>)att.get('attributeRunTimeInfo');

                        if (runtimeInfo.containsKey('values')) {

                            List<Object> valueEntries = (List<Object>)runtimeInfo.get('values');
                            for(Object valueEntry: valueEntries) {

                                Map<String, Object> v = (Map<String, Object>)valueEntry;
                                if (v.containsKey('value') && v.containsKey('displayText') && v.get('value') == value) {
                                    entry.put('Label', v.get('displayText'));
                                    break;
                                }
                            }
                        }                        
                    }                    
                    attributeList.add(entry);
                }
            }
        }

        return attributeList;
    }

    /**
     * Returns the V2 Attribute definitions for a Product, Opportunity Line Item, Quote Line Item, Order Item, or Asset object
     *
     * @param metadata  The Attribute Metadata as a JSON encoded string
     * @param values    The Attribute values as a JSON encoded string
     *
     * @return The attributes in a simple list
     */
    private List<Object> getV2Attributes(String metadata, String values) {

        List<Object> attributeList = new List<Object>();

        if (String.isNotBlank(metadata) && String.isNotBlank(values)) {

            Map<String, Object> attMetadata = (Map<String, Object>)JSON.deserializeUntyped(metadata);
            Map<String, Object> attValues   = (Map<String, Object>)JSON.deserializeUntyped(values);

            //System.debug('JOE - Metadata = ' + JSON.serialize(attMetadata));
            //System.debug('JOE - Values = ' + JSON.serialize(attValues));

            // Discover all the attributes from the metadata
            List<Object> categories = (List<Object>)attMetadata.get('records');
            if (categories != null) {

                for (Object category: categories) {

                    Map<String, Object> productAttributes = (Map<String, Object>)((Map<String, Object>)category).get('productAttributes');
                    if (productAttributes != null) {

                        List<Object> attributes = (List<Object>)productAttributes.get('records');
                        if (attributes != null) {

                            for (Object attribute: attributes) {

                                Map<String, Object> attributeObj = (Map<String, Object>)attribute;
                                String code = (String)attributeObj.get('code');
                                Object value = attValues.get(code);

                                Map<String, Object> entry = new Map<String, Object>();
                                entry.put('Code', code);
                                entry.put('Name', attributeObj.get('label'));
                                entry.put('Value', value);
                                entry.put('Label', String.valueOf(value));   // Default the label in case we don't have one in the metadata

                                // Add the value label if we can find one
                                if (attributeObj.containsKey('values')) {

                                    List<Object> valueEntries = (List<Object>)attributeObj.get('values');
                                    for(Object valueEntry: valueEntries) {

                                        Map<String, Object> v = (Map<String, Object>)valueEntry;
                                        if (v.containsKey('value') && v.containsKey('label') && v.get('value') == value) {
                                            entry.put('Label', v.get('label'));
                                            break;
                                        }
                                    }
                                }
                                attributeList.add(entry);
                            }
                        }
                    }
                }
            }
        }

        return attributeList;
    }

    /**
     * Submits an order as a specific user.  This is most useful when we are in an anonymous buy-flow and we need
     * to submit an order as a guest user.  Guest users can perform most CPQ/DC operations except for submitting the final
     * order submission to OM.  This method is useful to automatically login the user (so they are no longer anonymous) 
     * and submit the order by calling an integration procedure
     * 
     * @param username  The username to login with
     * @param password  The password to login with
     * @param ipKey     The Integration Procedure key to execute
     * @param body      The JSON input data that will be sent to the Integration Procedure
     * 
     * @return The Integration Procedure response
     */
    private Map<String, Object> executeIntegrationProcedureAsUser(String username, String password, String ipKey, Map<String,Object> body) {

        // Login via SOAP (so we have a sessionId)
        Map<String, String> session = DemoSoapUtils.login(username, password);
        
        // Call the Integration Procedure (via REST)
        String url = session.get('serverUrl').replaceAll('/services/.*$', '') + '/services/apexrest/' + DemoOrgUtils.getNamespace() + '/v1/integrationprocedure/' + ipKey;
        //System.debug('Order Submission URL -> ' + url);

        HttpRequest httpReq = new HttpRequest();
        httpReq.setMethod('POST');
        httpReq.setEndpoint(url);
        httpReq.setHeader('Authorization', 'Bearer ' + session.get('sessionId'));
        httpReq.setHeader('Content-Type', 'application/json; charset=utf-8');
        httpReq.setBody(JSON.serialize(body));
        httpReq.setTimeout(30000);  // 30 seconds to allow for slower Integration Procedures

        //System.debug('Order Submission Request -> ' + JSON.serialize(body));

        HttpResponse httpRes = new http().send(httpReq);
        //System.debug('Order Submission Response -> ' + httpRes.getBody());

        // Logout via SOAP
        DemoSoapUtils.logout(session);

        return (Map<String, Object>)JSON.deserializeUntyped(httpRes.getBody());
    }

    /**
     * For a given cart, retrieves a list of target upgrade/downgrade offers.
     * The default CPQv2 API could be called directly, but it doesn't include any images
     * which are useful for visual buy-flows.  This method will wrap the standard
     * CPQv2 API so that it also provides images.
     * 
     * @param input   The input data provided in the call to this method
     * @param output  The output object where any results will be stored
     * @param options Any options to aid in the execution of this class
     * 
     * @return true if the function completed successfully, false otherwise
     */
    private Boolean getCartsTargetOffers(Map<String,Object> input, Map<String,Object> output, Map<String,Object> options) {

        // Validate the input
        String cartId = (String)input.get('cartId');
        if (cartId == null || cartId == '') throw new DemoOrgUtils.DemoException('Missing cartId');

        vlocity_cmt.CpqAppHandler cpq = new vlocity_cmt.CpqAppHandler();
        Boolean response = (Boolean)cpq.invokeMethod('getCartsTargetOffers', input, output, options);

        if (response && output.containsKey('result')) {   
    
            // Make a list of Product2.Id values so we can query attachments
            List<Id> productIds = new List<Id>();
    
            // Get rid of the JSONRecord class types to make it easier to deal with
            Map<String, Object> outputMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(output));
            Map<String, Object> result = (Map<String, Object>)outputMap.get('result');
            List<Object> records = (List<Object>)result.get('records');

            // Get the product Ids
            for (Object record: records) {

                Id productId = (Id)((Map<String, Object>)((Map<String, Object>)record).get('fields')).get('productId');
                if (!productIds.contains(productId)) productIds.add(productId);        
            }    

            System.debug('Product Ids -> ' + JSON.serialize(productIds));

            // Query all the attachments
            List<vlocity_cmt__VlocityAttachment__c> attachments = [ SELECT Name, vlocity_cmt__ContentType__c, vlocity_cmt__Description__c, vlocity_cmt__IsDefaultImage__c, vlocity_cmt__DisplayConditionsData__c, vlocity_cmt__ObjectId__c, vlocity_cmt__SequenceNumber__c, vlocity_cmt__UrlLong__c FROM vlocity_cmt__VlocityAttachment__c WHERE vlocity_cmt__ObjectId__c IN :productIds ];
    
            // Augment the original CPQv2 API response with attachment data
            for (Object record: records) {
        
                Map<String, Object> recordFields = (Map<String, Object>)((Map<String, Object>)record).get('fields');
                Id productId = (Id)recordFields.get('productId');

                // Find any attachments
                List<Object> prAttachments = new List<Object>();
                recordFields.put('Attachments', prAttachments);

                for (vlocity_cmt__VlocityAttachment__c attachment: attachments) {          

                    if (attachment.get('vlocity_cmt__ObjectId__c') == productId) {                    

                        System.debug('Found Attachment for product (' + productId + ') -> ' + attachment.Name);

                        // Create the Attachment
                        Map<String, Object> prAttachment = new Map<String, Object>();
                        prAttachment.put('contentType', attachment.get('vlocity_cmt__ContentType__c'));
                        prAttachment.put('defaultAttachment', attachment.get('vlocity_cmt__IsDefaultImage__c'));
                        prAttachment.put('description', attachment.get('vlocity_cmt__Description__c'));
                        prAttachment.put('displayConditionsData', attachment.get('vlocity_cmt__DisplayConditionsData__c'));
                        //prAttachment.put('mimeType', '');  // not in the SObject table?
                        prAttachment.put('sequenceNumber', attachment.get('vlocity_cmt__SequenceNumber__c'));
                        prAttachment.put('title', attachment.Name);
                        prAttachment.put('url', attachment.get('vlocity_cmt__UrlLong__c'));

                        // Add it to the list of attachments
                        prAttachments.add(prAttachment);
                    }
                }
            }
            
            // Replace the output
            output.put('result', result);
        }

        return true;
    }
}