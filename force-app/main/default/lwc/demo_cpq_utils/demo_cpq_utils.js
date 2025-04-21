/*
  This component exposes a number of useful JavaScript utilities for dealing with CPQ data.
  
  @author Joe McMaster
  @version 1.7
    
  History
  =======
  Mar 24, 2021 - v1.0 - Initial version
  May  5, 2021 - v1.1 - CPQv2 Operations now trigger getCartsItems to update the cart
  May 10, 2021 - v1.2 - Minor fixes, added 'evaluate' function
  Jun 30, 2021 - v1.3 - Minor fix to better handle products without pricing (i.e. don't break entirely!)
  Jul 15, 2021 - v1.4 - Fixed filter to handle hyphens in Attribute Codes
                      - Better handling of undefined/null values in evaluate() method
  Aug 26, 2021 - v1.5 - Support for asset objects
  Oct 19, 2021 - v1.6 - Support for adding child offers
  May 25, 2022 - v1.7 - Better Support for calling from LWC Extension components rather than just Custom LWCs

  Notes
  =====
  -Both Digital Commerce (including MTS) and CPQv2 APIs are supported in the various calls

  Configuration
  =============
  This component does not need to be configured directly, but can be leveraged by any other LWC by using
  the following pattern:

  import { getOneTimeCharge, getRecurringCharge, getImage, .... } from 'c/demo_cpq_utils'
  ....
  getOneTimeCharge(product);
  getRecurringCharge(product);
  getImage(product);
  ....

  THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 
*/
import { getFullDataJson } from 'c/demo_os_utils';

/**
 * Determines if this product definitaion (or line item) came from the CPQv2 API or
 * the Digital Commerce API
 * 
 * @param product The product (or line item) object
 * 
 * @return true if this product/line-item is from the Digital Commerce API or false otherwise
 */
function isDC(product) {

    let dc = false;

    // Products from the DC API do not contain the 'productId' field, while they do when originating from CPQv2
    // Line Items from the DC API contain the 'lineItemKey' field, while they do not when originating from CPQv2
    // Special case when dealing with Change-of-Plan (CoP), all fields are bundled under a "fields" node
    if ((!product.productId && !product.fields) || product.lineItemKey) dc = true;

    return dc;
}

/**
 * Returns the one time charge (OTC) for this product, line item, or asset
 * 
 * @param product The product, line item, or asset object
 * 
 * @return the one time charge or undefined if there isn't one
 */
function getOneTimeCharge(product) {

    // If this is a line item (or asset), return the One-Time Charge
    if (product.itemType === "lineItem" || product.itemType === "asset") return toNumber(getFieldValue(product, "vlocity_cmt__OneTimeTotal__c"));

    // If this is a product, try to find the One Time Charge depending on the API type in use
    // Digital Commerce
    if (isDC(product)) {

        if (Array.isArray(product.priceResult)) {
            for (let priceEntry of product.priceResult) {
                if (priceEntry.Type__c === "Price" && priceEntry.ChargeType__c === "One-time") return priceEntry.chargeamount;
            }
        }
    }
    // CPQv2
    else return toNumber(getFieldValue(product, "UnitPrice"));
}

/**
 * Returns the recurring charge (i.e. MRC) for this product, line item, or asset
 * 
 * @param product The product, line item, or asset object
 * 
 * @return the recurring charge or undefined if there isn't one
 */
function getRecurringCharge(product) {

    // If this is a line item (or asset), return the Recurring Charge
    if (product.itemType === "lineItem" || product.itemType === "asset") return toNumber(getFieldValue(product, "vlocity_cmt__RecurringTotal__c"));

    // If this is a product, try to find the Recurring Charge depending on the API type in use
    // Digital Commerce
    if (isDC(product)) {

        if (Array.isArray(product.priceResult)) {
            for (let priceEntry of product.priceResult) {
                if (priceEntry.Type__c === "Price" && priceEntry.ChargeType__c === "Recurring") return priceEntry.chargeamount;
            }
        }
    }
    // CPQv2 Product
    else return toNumber(getFieldValue(product, "vlocity_cmt__RecurringPrice__c"));
}

/**
 * Returns the Product Name
 * 
 * @param product The product (or line item) object
 * 
 * @return The name of the product
 */
function getName(product) {

    // Digital Commerce
    return getFieldValue(product, "Name");
}

/**
 * Returns the Product Code
 * 
 * @param product The product object
 * 
 * @return The product code
 */
function getCode(product) {

    // Digital Commerce
    if (isDC(product)) return product.ProductCode;

    // CPQv2
    return getFieldValue(product, "ProductCode");
}

/**
 * Returns the Product Pricebook Entry Id (in case of CPQv2 API) or 
 * the Product Code (in case of the Digital Commerce API)
 * 
 * @param product The product object
 * 
 * @returns The product's pricebook entry Id (CPQv2 API) or Product Code (DC API)
 */
function getId(product) {

    // Digital Commerce
    if (isDC(product)) return product.ProductCode;

    // CPQv2
    return getFieldValue(product, "Id");
}

/**
 * Attempts to extract the Catalog Code from a Digital Commerce offer.  Calling
 * this for a CPQv2 product will return undefined
 * 
 * @param product  The product object
 * 
 * @return The Catalog Code, undefined otherwise
 */
function getCatalogCode(product) {

    if (isDC(product)) {

        // Likely need to make this more robust but for now ....
        // Get the URL such as v3/catalogs/WATCHES/basket, and then extract the Catalog Code (WATCHES)
        var link = product.addtocart.rest.link;
        if (link) return link.replace(/.*catalogs\//g, '').replace(/\/.*/g, '');
    }
}

/**
 * Extracts the Product Description for better visualization.  Only the lines in the product
 * description that DO NOT start with a hyphen are considered general description text.
 * 
 * @param product  The product or line item object
 * 
 * @return The product description
 */
function getDescription(product) {

    let description = "";

    // Split by carriage return
    let parts = [];
    if (isDC(product) && product.Description) parts = product.Description.split(/\r?\n/); // DC API Structure
    else if (product.fields && product.fields.Product2) parts = product.fields.Product2.Description.split(/\r?\n/); // Change-of-Plan API structure
    else if (product.Product2 && product.Product2.Description) parts = product.Product2.Description.split(/\r?\n/); // Standard CPQv2 API structure

    // Build description (but filter out anylines that start with a hyphen)
    for (let p of parts) {
        if (!p.startsWith('-')) description += p;
    }

    return description;
}

/**
 * Extracts a list of product features from the Product Description for better visualization
 * Features must appear in the Product Description on separate lines and start with a hyphen.  All
 * other text in the Description field will be ignored.
 * 
 * @param desc  The product description (as a blob of text)
 * 
 * @return List of features
 */
function getFeatures(product) {

    let features = [];

    let parts = [];
    if (isDC(product) && product.Description) parts = product.Description.split(/\r?\n/); // DC API Structure
    else if (product.fields && product.fields.Product2) parts = product.fields.Product2.Description.split(/\r?\n/); // Change-of-Plan API structure
    else if (product.Product2 && product.Product2.Description) parts = product.Product2.Description.split(/\r?\n/); // Standard CPQv2 API structure

    // Build feature list (each line in the description starting with a hyphen is a feature)
    for (let p of parts) {
        if (p.startsWith('-')) features.push(p.substring(1));
    }

    return features;
}

/**
 * Returns the product offer image to use for this product or line item (if one can be found)
 * 
 * @param product  The product (or line item) object
 * 
 * @return The image attachment if one was found, undefinded otherwise
 */
function getImage(product) {

    let image;

    let attachments = undefined;
    if (product.Attachments) attachments = product.Attachments; // CPQv2 and DC API Structure
    else if (product.fields && product.fields.Attachments) attachments = product.fields.Attachments; // Change-of-Plan API structure

    // If we have a list of attachments, return them
    // In most cases, we will have a list of attachments (if the CPQv2 APIs are called with the 'includeAttachment' parameter)
    if (attachments) {

        // look for an appropriate image
        // We will use the first image found (or an image that is marked as default)
        for (let attachment of attachments) {
            if (attachment.contentType === "Image" && (!image || attachment.defaultAttachment)) image = attachment;
        }
    }

    return image;
}

/**
 * Retrieves a field value from the product (or line item) object.  It attempts to interpret a single
 * value from the field depending on the type of field that is found.
 * 
 * @param product    The product or line item object to search
 * @param fieldName  The field name to retrieve
 * 
 * @return The field value if found, undefined otherwise
 */
function getFieldValue(product, fieldName) {

    // Most API responses will have fields at the root of their structure
    let field = product[fieldName];

    // Change of Plan (CoP) bundles everyting under a "fields" node instead of at the root
    if (!field && product.fields) field = product.fields[fieldName];

    if (field) {

        // If this is a map, look for the "value" field within it
        // Otherwise just return the object (could be a simple string, integer, boolean, double, etc.
        if (typeof field === "object" && "value" in field) return field.value;
        else return field;
    }

    // If we make it here, no field was found		
    console.warn("Did not find field '" + fieldName + "' on product '" + getName(product) + "'.");
}

/**
 * Updates a field on a line item (i.e. Quantity)
 *
 * @param lineItem    The line item to update 
 * @param fieldName   The field to update
 * @param fieldValue  The new value for this field
 * 
 * @return true if the field was updated, false if it wasn't (i.e. could not be found)
 */
function setFieldValue(lineItem, fieldName, fieldValue) {

    let field = lineItem[fieldName];

    if (field && field.value) {

        // Move current value of this field to the previous value
        field.previousValue = field.value;

        // Set new value
        field.value = fieldValue;

        return true;
    }

    // If we make it here, no update was made
    console.warn("Did not find field '" + fieldName + "' on line item '" + getName(lineItem) + "'");
    return false;
}

/**
 * Returns a specific attribute value from the product. All attribute categories will
 * be searched and the first attribute found will be returned.
 * 
 * @param product        The product definition to search
 * @param attributeCode  The attribute code to search for
 * 
 * @return the attribute value if found, undefined otherwise
 */
function getAttributeValue(product, attributeCode) {

    // Digital Commerce
    if (isDC(product)) {

        // Go through each Product Attribute Category looking for a match
        if (product.AttributeCategory) {
            for (let category in product.AttributeCategory) {

                // Go through each Attribute in the Category
                for (let attribute of product.AttributeCategory[category]) {
                    if (attribute.attributeuniquecode__c && attribute.attributeuniquecode__c === attributeCode) return attribute.value__c;
                }
            }
        }
    }
    // CPQv2
    else {

        // Go through each Product Attribute Category looking for a match
        if (product.attributeCategories && product.attributeCategories.records) {
            for (let category of product.attributeCategories.records) {

                // Go through each Attribute in the Category
                if (category.productAttributes && category.productAttributes.records) {
                    for (let attribute of category.productAttributes.records) {

                        if (attribute.code && attribute.code === attributeCode) return attribute.userValues;
                    }
                }
            }
        }
    }

    // If we make it here, no attribute was found		
    console.warn("Did not find attribute code '" + attributeCode + "' on product '" + getName(product) + "'.");
}

/**
 * Updates an attribute on a line item.
 * 	 
 * @param attributeCode   The attribute code
 * @param attributeValue  The new attribute value
 * 
 * @return true if the attribute was updated, false if it wasn't (i.e. could not be found)
 */
function setAttributeValue(lineItem, attributeCode, attributeValue) {

    // Go through each Line Item Attribute Category looking for a match
    if (lineItem.attributeCategories && lineItem.attributeCategories.records) {
        for (let category of lineItem.attributeCategories.records) {

            // Go through each Attribute in the Category
            if (category.productAttributes && category.productAttributes.records) {
                for (let attribute of category.productAttributes.records) {

                    if (attribute.code && attribute.code === attributeCode) {

                        // input type we are dealing with (simple vs. drop-down/select)
                        let inputType = attribute.inputType;
                        let dataType = attribute.dataType;
                        let values = attribute.values;

                        switch (inputType) {

                            // Simple Types
                            case "text":
                            case "number":
                            case "date":
                            case "datetime":
                            case "checkbox":
                            case "percentage":

                                if (dataType === "text" || dataType === "number" || dataType === "checkbox" || dataType === "percentage") {

                                    values[0].value = attributeValue;
                                    att.userValues = attributeValue;
                                    return true;
                                } else if ((dataType === "datetime" || dataType === "date") && typeof attributeValue === "string") {

                                    values[0].value = attributeValue;
                                    att.userValues = attributeValue;
                                    return true;
                                } else if ((dataType === "datetime" || dataType === "date") && attributeValue instanceof Date) {

                                    values[0].value = attributeValue.toISOString();
                                    att.userValues = attributeValue.toISOString();
                                    return true;
                                } else console.error("Attribute '" + attributeCode + "' has a data type of '" + dataType + "' which is not currently supported!");

                                break;

                                // Drop-Downs
                            case "dropdown":

                                // Not sure yet how to handle a multi-select item so raise an error until we encounter an example to help me enhance this method
                                if (att.multiselect === true) console.error("Attribute '" + attributeCode + "' is a drop-down with multi-select and this is not currently supported!");
                                else {

                                    // Locate the value we want from the list of possible values
                                    for (let i = 0; i < values.length; i++) {

                                        let valueEntry = values[i];
                                        if (valueEntry.label === attributeValue) {

                                            att.userValues = valueEntry.value;
                                            return true;
                                        }
                                    }

                                    // If we make it here, we didn't find the corresponding value in the list of possible values for the drop-down
                                    console.error("'" + attributeValue + "' is not a valid value for attribute '" + attributeCode + "'");
                                }

                                break;


                            default:

                                console.error("Attribute '" + attributeCode + "' uses an input type of '" + inputType + "' which is not currently supported!");
                        }

                    }
                }
            }
        }
    }

    // If we make it here, no updates were made
    return false;
}

/**
 * Extracts the numerical equivalent from the incoming string value (which could be a string such as "0.00" or "$2,500.99", etc.)
 * 
 * @param value  The value to process
 * 
 * @return The proper numerical value
 */
function toNumber(value) {

    let v = 0;

    if (value === null || value === undefined) v = 0;
    else if (typeof value === "string" || value instanceof String) v = parseFloat(value.replace(/[^\d.-]/g, ""));
    else v = parseFloat(value);

    return v;
}

/**
 * Returns the cartId (CPQv2 API), Digital Commerce products will return undefined.
 * 
 * @param product  The product object
 * 
 * @return The cartId from the product
 */
function getCartId(product) {

    // CPQv2
    if (!isDC(product)) {

        if (product.actions.addtocart) {

            let addtocart = product.actions.addtocart;
            if (addtocart.remote && addtocart.remote.params && addtocart.remote.params.cartId) return addtocart.remote.params.cartId;
        }
    }
}

/**
 * Makes a Digital Commerce API request to add an offer to the cart
 * 
 * @param cartIdNode   The top-level OmniScript JSON node where the cartId is stored (Digital Commerce Basket Id)
 * @param cartNode     The top-level OmniScript JSON node where the current basket line items are stored
 * @param contextKey   The contextId used in Digital Commerce
 * @param mtsKey       The MTS transaction key (see Multi-Transaction Service documentation)
 * @param product      The product to add to the basket
 * @param debug        Indication if debug messages should be written to the browser console
 * 
 * @return A Promise for the completion of the API Request
 */
function addToCartDC(cartIdNode, cartNode, contextKey, mtsKey, product, osComponent, debug) {

    let addAction = product.addtocart.rest;

    // Create the Digital Commerce API Request
    let input = {
        apiName: "basketOperations",
        catalogCode: getCatalogCode(product), // INTERNET        
        offer: getCode(product),
        methodName: addAction.params.basketAction, // AddWithNoConfig
        requestURL: addAction.link, // v3/catalogs/INTERNET/basket
        cartContextKey: getFullDataJson(osComponent)[cartIdNode],
        contextkey: contextKey,
        includeAttachment: true,
        isloggedin: false,
    };

    // API Action
    let action = addAction.params.basketAction.substring(0, 1).toLowerCase() + addAction.params.basketAction.substring(1);

    // Add the MTS Key (if we have one)
    if (mtsKey) input.multiTransactionKey = mtsKey;

    if (debug) console.log("DC API Request (" + action + ") -> " + JSON.stringify(input));

    // Make the Digital Commerce API Request
    let request = osComponent.omniRemoteCall({
        sClassName: "vlocity_cmt.CpqAppHandler", // update this someday to `${this._ns}.CpqAppHandler when it is supported in CMT
        sMethodName: action, // addWithNoConfig
        input: JSON.stringify(input),
        options: "{}"
    });

    // Handle the Digital Commerce API Response
    return request.then(response => {

        // Handle errors (but ignore MTS messages)
        if (response.error && !response.result.nexttransaction) {
            console.error("DC API Error (" + action + ") -> " + JSON.stringify(response));
            throw JSON.stringify(response);
        } else if (debug) console.log("DC API Response (" + action + ") -> " + JSON.stringify(response));

        // See if we have the response contains information from MTS (Multi-Transaction Service)
        // MTS breaks the API request up so that we can avoid exceeding governor limits.  The implication
        // is that we need to make the API request again and include the MTS key to get the complete API response
        if (response.result.nexttransaction && response.result.nexttransaction.rest.params.multiTransactionKey) {

            if (debug) console.log("DC API Response (" + action + ") -> Multi-Transaction Service (MTS) was triggered");

            // Resend the API Request with the MTS Key
            let txKey = response.result.nexttransaction.rest.params.multiTransactionKey;
            return addToCartDC(cartIdNode, cartNode, contextKey, txKey, product, osComponent, debug);
        } else {

            // Update the OmniScript with the new cart & basket Id (we get a new basket Id each time we add/remove a product)
            updateOmniScriptCart(cartIdNode, response.result.cartContextKey, cartNode, response.result.result, osComponent);

            return response;
        }
    });
}

/**
 * Removes a line item from the basket using the Digital Commerce APIs
 * 
 * @param cartIdNode   The top-level OmniScript JSON node where the cartId is stored (Digital Commerce Basket Id)
 * @param cartNode     The top-level OmniScript JSON node where the current basket line items are stored
 * @param mtsKey       The MTS transaction key(see Multi - Transaction Service documentation)
 * @param product      The product to remove from the basket
 * @param osComponent  The OmniScript LWC Component calling this method
 * @param debug        Indication if debug messages should be written to the browser console
 * 
 * @return A Promise
 */
function delFromCartDC(cartIdNode, cartNode, mtsKey, product, osComponent, debug) {

    // Find this line item in the cart
    let cart = getFullDataJson(osComponent)[cartNode];
    let lineItem = cart.records.filter(li => {
        return li.ProductCode == getCode(product);
    })[0]; // for now we always assume only 1 line item for this product will ever exist

    let deleteAction = lineItem.actions.deleteFromBasketAction.rest;

    // Create the Digital Commerce API Request
    let input = {
        apiName: "basketOperations",
        catalogCode: getCatalogCode(product),
        offer: getCode(product),
        methodName: deleteAction.params.basketAction, // deleteFromBasket
        requestURL: deleteAction.link, // /v3/catalogs/INTERNET/basket/5ad30e1cc7908Y000000PBo138db2a8a?contextKey=342904921a3d2d7d8fa30b799f5cc319
        cartContextKey: getFullDataJson(osComponent)[cartIdNode],
        bundleContextKey: deleteAction.params.bundleContextKey,
        lineItemKey: deleteAction.params.lineItemKey,
        includeAttachment: true,
        isloggedin: false,
    };

    // API Action
    let action = deleteAction.params.basketAction;

    // Add the MTS Key (if we have one)
    if (mtsKey) input.multiTransactionKey = mtsKey;

    if (debug) console.log("DC API Request (" + action + ") -> " + JSON.stringify(input));

    // Make the Digital Commerce API Call
    let request = osComponent.omniRemoteCall({
        sClassName: "vlocity_cmt.CpqAppHandler", // update this someday to `${this._ns}.CpqAppHandler when it is supported in CMT
        sMethodName: action, // deleteFromBasket
        input: JSON.stringify(input),
        options: "{}"
    });

    return request.then(response => {

        // Handle errors (but ignore MTS messages)
        if (response.error && !response.result.nexttransaction) {
            console.error("DC API Error (" + action + ") -> " + JSON.stringify(response));
            throw JSON.stringify(response);
        } else if (debug) console.log("DC API Response (" + action + ") -> " + JSON.stringify(response));

        // See if we have the response contains information from MTS (Multi-Transaction Service)
        // MTS breaks the API request up so that we can avoid exceeding governor limits.  The implication
        // is that we need to make the API request again and include the MTS key to get the complete API response
        if (response.result.nexttransaction && response.result.nexttransaction.rest.params.multiTransactionKey) {

            if (debug) console.log("DC API Response (" + action + ") -> Multi-Transaction Service (MTS) was triggered");

            // Resend the API Request with the MTS Key
            let txKey = response.result.nexttransaction.rest.params.multiTransactionKey;
            return delFromCartDC(cartIdNode, cartNode, txKey, product, osComponent, debug);
        } else {

            // Update the OmniScript with the new cart & basket Id (we get a new basket Id each time we add/remove a product)
            // Due to merging of OmniScript data we need to make sure we include this so taht it
            // properly removes the list of records in the cart when we get an empty response
            if (response.result.result.totalSize == 0) response.result.result.records = [];
            updateOmniScriptCart(cartIdNode, response.result.cartContextKey, cartNode, response.result.result, osComponent);

            return response;
        }
    });
}

/**
 * Analyze the CPQv2 API Response for errors/warnings
 * 
 * @param response  The CPQv2 API Response
 */
function analyzeCPQResponse(response) {

    // Check for Messages, Warnings, and Errors.  The CPQ APIs are somewhat inconsistent in their behavior
    // (1) A response with no messages at all is assumed to be successful
    // (2) A response with a "success" message is assumed to be successful.
    // (3) A response with a "success" message followed by any "error/warning" messages is assumed to be successful. 
    // (4) A response with no "success" message and any "error" messages is assumed to be a failure.
    // 
    // Any warnings/error messages will be logged in the browser console
    let success = false;
    let messages = response.result.messages;
    if (messages) {

        // A response with no messages at all is assumed to be successful
        if (messages.length === 0) success = true;

        for (let msg of messages) {

            let severity = msg.severity;
            let msgText = msg.message;

            // success codes I've seen include 150, 151 (possibly others so don't use this for the check)
            if (severity === "INFO" && msgText.startsWith("Success")) success = true;
            else if (severity === "WARN") console.warn("CPQ API Warning -> " + msgText);
            else if (severity === "ERROR" && success) console.warn("CPQ API Warning -> " + msgText);
            else if (severity === "ERROR" && !success) console.error("CPQ API Error -> " + msgText);
        }
    }
}

/**
 * Adds a product to the cart
 * 
 * @param cartIdNode     The top-level OmniScript JSON node where the cartId is stored (CPQv2 Cart Id)
 * @param cartNode       The top-level OmniScript JSON node where the current cart line items are stored
 * @param parentLineItem The parent line item this offer should become a child of (if not set, offer will be a root line item)
 * @param product        The product to add to the cart
 * @param osComponent    The OmniScript LWC Component calling this method
 * @param debug          Indication if debug messages should be written to the browser console
 * 
 * @return A Promise
 */
function addToCartCPQ(cartIdNode, cartNode, parentLineItem, product, osComponent, debug) {

    let addAction = product.actions.addtocart.remote;

    // Create the CPQ v2 API Request
    let input = {
        cartId: getFullDataJson(osComponent)[cartIdNode],
        validate: false,
        price: false,
        includeAttachment: true,
        items: [{
            itemId: getId(product)
        }]
    };

    // Update the request if we are adding as a child line item
    if (parentLineItem) {

        // If the parent line item is a virtual product, add the line item to the parent of the virtual product
        if (isVirtual(parentLineItem)) {

            // In the case of virtual products:
            //  (1) parentId is actually the Id the virtual product's parent
            //  (2) parentHierarchyPath is from the virtual product itself
            //  (3) the parentRecord is the virtual product
            input.items[0].parentId = getId(getParent(parentLineItem, getFullDataJson(osComponent)[cartNode]));
            input.items[0].parentHierarchyPath = getFieldValue(parentLineItem, "productHierarchyPath");
            input.items[0].parentRecord = {
                "records": [parentLineItem]
            };
        }
        // Otherwise the parent line item is a regular line item
        else {

            input.items[0].parentId = getId(parentLineItem);
            input.items[0].parentRecord = {
                "records": [parentLineItem]
            };
        }
    }

    // API Action
    let action = addAction.params.methodName;

    if (debug) console.log("CPQ API Request (" + action + ") -> " + JSON.stringify(input));

    // Make the CPQv2 API Call
    let request = osComponent.omniRemoteCall({
        sClassName: "vlocity_cmt.CpqAppHandler", // update this someday to `${this._ns}.CpqAppHandler when it is supported in CMT
        sMethodName: action, // postCartsItems
        input: JSON.stringify(input),
        options: "{}"
    });

    return request.then(response => {

        // Check for errors/warnings from the API response
        analyzeCPQResponse(response);

        if (debug) console.log("CPQ API Response (" + action + ") -> " + JSON.stringify(response));

        return refreshCartCPQ(cartIdNode, cartNode, osComponent, debug);
    });
}

/**
 * Modifies a line item in the cart
 * 
 * @param cartIdNode     The top-level OmniScript JSON node where the cartId is stored (CPQv2 Cart Id or Digital Commerce Basket Id)
 * @param cartNode       The top-level OmniScript JSON node where the current cart/basket line items are stored
 * @param contextKey     The contextId (only used in Digital Commerce)
 * @param lineItem       The line item to update
 * @param osComponent    The OmniScript LWC Component calling this method
 * @param debug          Indication if debug messages should be written to the browser console
 * 
 * @return A Promise
 */
function updateLineItem(cartIdNode, cartNode, contextKey, lineItem, osComponent, debug) {

    if (debug) console.log("Updating " + getName(lineItem) + " in the cart");

    // Digital Commerce
    if (isDC(product)) {
        console.error("Updating Line Items from Digital Commerce isn't yet supported.");
        //return updateLineItemDC(cartIdNode, cartNode, contextKey, lineItem, osComponent, debug);
    }
    // CPQv2
    else return updateLineItemCPQ(cartIdNode, cartNode, lineItem, osComponent, debug);
}

/**
 * Modifies a line item in the cart
 * 
 * @param cartIdNode     The top-level OmniScript JSON node where the cartId is stored (CPQv2 Cart Id)
 * @param cartNode       The top-level OmniScript JSON node where the current cart line items are stored
 * @param lineItem       The line item to update
 * @param osComponent    The OmniScript LWC Component calling this method
 * @param debug          Indication if debug messages should be written to the browser console
 * 
 * @return A Promise
 */
function updateLineItemCPQ(cartIdNode, cartNode, lineItem, osComponent, debug) {

    let updateAction = lineItem.actions.updateitems.remote;

    // Create the CPQ v2 API Request
    let input = {
        cartId: getFullDataJson(osComponent)[cartIdNode],
        validate: false,
        price: false,
        items: {
            records: []
        }
    };

    // For updates on a child item, we need to setup the Parent>Child structure
    let updatedItem = null;
    let parentLineItem = item.getParent(lineItem, getFullDataJson(osComponent)[cartNode]);

    if (parentLineItem) {

        // Clone the parent line item and trim it of unnecessary data
        updatedItem = JSON.parse(JSON.stringify(parentLineItem));
        delete updatedItem.lineItems;
        delete updatedItem.childProducts;

        // Add the lineItems/records structure
        updatedItem.lineItems = {
            records: []
        };

        // Add the actual object we are updating
        let childItem = JSON.parse(JSON.stringify(lineItem));
        delete childItem.lineItems;
        delete childItem.childProducts;

        updatedItem.lineItems.records.push(childItem);
    } else {

        updatedItem = JSON.parse(JSON.stringify(item));
        delete updatedItem.lineItems;
        delete updatedItem.childProducts;
    }
    input.items.records.push(updatedItem);

    // API Action
    let action = updateAction.params.methodName;

    if (debug) console.log("CPQ API Request (" + action + ") -> " + JSON.stringify(input));

    // Make the CPQv2 API Call
    let request = osComponent.omniRemoteCall({
        sClassName: "vlocity_cmt.CpqAppHandler", // update this someday to `${this._ns}.CpqAppHandler when it is supported in CMT
        sMethodName: action, // putCartsItems
        input: JSON.stringify(input),
        options: "{}"
    });

    return request.then(response => {

        // Check for errors/warnings from the API response
        analyzeCPQResponse(response);

        if (debug) console.log("CPQ API Response (" + action + ") -> " + JSON.stringify(response));

        return refreshCartCPQ(cartIdNode, cartNode, osComponent, debug);
    });
}

/**
 * Removes a line item from the basket
 * 
 * @param cartIdNode   The top-level OmniScript JSON node where the cartId is stored (CPQv2 Cart Id)
 * @param cartNode     The top-level OmniScript JSON node where the current cart line items are stored
 * @param product      The product to remove from the cart
 * @param osComponent  The OmniScript LWC Component calling this method
 * @param debug        Indication if debug messages should be written to the browser console
 * 
 * @return A Promise
 */
function delFromCartCPQ(cartIdNode, cartNode, product, osComponent, debug) {

    let cart = getFullDataJson(osComponent)[cartNode];

    // Find this line item in the cart
    let lineItem = cart.records.filter(li => {
        return li.ProductCode == getCode(product);
    })[0]; // for now we always assume only 1 line item for this product will ever exist

    let deleteAction = lineItem.actions.deleteitem.remote;

    // API Action
    let action = deleteAction.params.methodName;

    // Create the CPQ v2 API Request
    let input = {
        cartId: getFullDataJson(osComponent)[cartIdNode],
        id: deleteAction.params.id,
        validate: false,
        price: false
    };

    if (debug) console.log("CPQ API Request (" + action + ") -> " + JSON.stringify(input));

    // Make the CPQv2 API Call
    let request = osComponent.omniRemoteCall({
        sClassName: "vlocity_cmt.CpqAppHandler", // update this someday to `${this._ns}.CpqAppHandler when it is supported in CMT
        sMethodName: action, // deleteCartsItems
        input: JSON.stringify(input),
        options: "{}"
    });

    return request.then(response => {

        // Check for errors/warnings from the API response
        analyzeCPQResponse(response);

        if (debug) console.log("CPQ API Response (" + action + ") -> " + JSON.stringify(response));

        return refreshCartCPQ(cartIdNode, cartNode, osComponent, debug);
    });
}

/**
 * Retrieves the cart details
 * 
 * @param cartIdNode   The top-level OmniScript JSON node where the cartId is stored (CPQv2 Cart Id)
 * @param cartNode     The top - level OmniScript JSON node where the current cart line items are stored
 * @param osComponent  The OmniScript LWC Component calling this method
 * @param debug        Indication if debug messages should be written to the browser console
 * 
 * @return A Promise
 */
function refreshCartCPQ(cartIdNode, cartNode, osComponent, debug) {

    let refreshItems = refreshCartItemsCPQ(cartIdNode, osComponent, debug);

    return refreshItems.then(response => {

        let refreshSummary = refreshCartSummaryCPQ(cartIdNode, osComponent, debug);

        return refreshSummary.then(summary => {

            // Add the cart summary to the main API response
            if (summary && summary.result && summary.result.records) response.result.summary = summary.result.records;

            // Update OmniScript
            updateOmniScriptCart(cartIdNode, null, cartNode, response.result, osComponent);

            return response;
        });
    });
}

/**
 * Retrieves the CPQv2 cart items
 * 
 * @param cartIdNode   The top-level OmniScript JSON node where the cartId is stored (CPQv2 Cart Id)
 * @param osComponent  The OmniScript LWC Component calling this method
 * @param debug        Indication if debug messages should be written to the browser console
 * 
 * @return A Promise
 */
function refreshCartItemsCPQ(cartIdNode, osComponent, debug) {

    // Create the CPQ v2 API Request
    let input = {
        cartId: getFullDataJson(osComponent)[cartIdNode],
        validate: true,
        price: true,
        includeAttachment: true
    };

    // API Action
    let action = "getCartsItems";  // old action
    //let action = "getCartLineItemPrices"; // new action

    if (debug) console.log("CPQ API Request (" + action + ") -> " + JSON.stringify(input));

    // Make the CPQv2 API Call
    let request = osComponent.omniRemoteCall({
        sClassName: "vlocity_cmt.CpqAppHandler", // update this someday to `${this._ns}.CpqAppHandler when it is supported in CMT
        sMethodName: action,
        input: JSON.stringify(input),
        options: "{}"
    });

    return request.then(response => {

        // Look for errors/warnings in the API response
        analyzeCPQResponse(response);

        if (debug) console.log("CPQ API Response (" + action + ") -> " + JSON.stringify(response));

        return response;
    });
}

/**
 * Retrieves the CPQv2 cart summary
 * 
 * @param cartIdNode   The top-level OmniScript JSON node where the cartId is stored (CPQv2 Cart Id)
 * @param osComponent  The OmniScript LWC Component calling this method
 * @param debug        Indication if debug messages should be written to the browser console
 * 
 * @return A Promise
 */
function refreshCartSummaryCPQ(cartIdNode, osComponent, debug) {

    // Create the CPQ v2 API Request
    let input = {
        cartId: getFullDataJson(osComponent)[cartIdNode],
        validate: false, // validate should have been called previously (getCartsItems)
        price: false, // price should have been called previously (getCartsItems)
    };

    // API Action
    let action = "getCarts";

    if (debug) console.log("CPQ API Request (" + action + ") -> " + JSON.stringify(input));

    // Make the CPQv2 API Call
    let request = osComponent.omniRemoteCall({
        sClassName: "vlocity_cmt.CpqAppHandler", // update this someday to `${this._ns}.CpqAppHandler when it is supported in CMT
        sMethodName: action,
        input: JSON.stringify(input),
        options: "{}"
    });

    return request.then(response => {

        // Look for errors/warnings in the API response
        analyzeCPQResponse(response);

        if (debug) console.log("CPQ API Response (" + action + ") -> " + JSON.stringify(response));

        return response;
    });
}

/**
 * Updates the cart details saved in the OmniScript data
 * 
 * @param cartIdNode  The top - level OmniScript JSON node where the cartId is stored(CPQv2 Cart Id or Digital Commerce Basket Id)
 * @param cartId      The new cartId to set in OmniScript
 * @param cartNode    The top - level OmniScript JSON node where the current cart / basket line items are stored
 * @param cart        The new cart to set in OmniScript
 * @param osComponent The OmniScript LWC Component calling this method
 */
function updateOmniScriptCart(cartIdNode, cartId, cartNode, cart, osComponent) {

    let clear = {};
    let update = {};

    if (cartId) {
        clear[cartIdNode] = null;
        update[cartIdNode] = cartId;
    }
    if (cart) {
        clear[cartNode] = null;
        update[cartNode] = cart;
    }

    // In order to trigger any other LWCs (i.e. shopping cart) that a change has taken place, we need
    // to forcefully clear the data and then set it again.

    // Clear data
    osComponent.omniApplyCallResp(clear);

    // Push new data
    osComponent.omniApplyCallResp(update);
}

/**
 * Adds a product to the cart
 * 
 * @param cartIdNode     The top-level OmniScript JSON node where the cartId is stored (CPQv2 Cart Id or Digital Commerce Basket Id)
 * @param cartNode       The top-level OmniScript JSON node where the current cart/basket line items are stored
 * @param contextKey     The contextId (only used in Digital Commerce)
 * @param parentLineItem The parent line item this offer should become a child of (if not set, offer will be a root line item)
 * @param product        The product to add to the cart
 * @param osComponent    The OmniScript LWC Component calling this method
 * @param debug          Indication if debug messages should be written to the browser console
 * 
 * @return A Promise
 */
function addToCart(cartIdNode, cartNode, contextKey, parentLineItem, product, osComponent, debug) {

    if (debug) {
        if (parentLineItem && !isDC(parentLineItem)) console.log("Adding " + getName(product) + " to parent line item " + getName(parentLineItem));
        else console.log("Adding " + getName(product) + " to the cart");
    }

    // Digital Commerce
    if (isDC(product)) return addToCartDC(cartIdNode, cartNode, contextKey, null, product, osComponent, debug);
    // CPQv2
    else return addToCartCPQ(cartIdNode, cartNode, parentLineItem, product, osComponent, debug);
}

/**
 * Removes a line item from the cart
 * 
 * @param cartIdNode   The top-level OmniScript JSON node where the cartId is stored (CPQv2 Cart Id or Digital Commerce Basket Id)
 * @param cartNode     The top-level OmniScript JSON node where the current cart/basket line items are stored
 * @param product      The product to remove from the cart
 * @param osComponent  The OmniScript LWC Component calling this method
 * @param debug        Indication if debug messages should be written to the browser console
 * 
 * @return A Promise
 */
function delFromCart(cartIdNode, cartNode, product, osComponent, debug) {

    if (debug) console.log("Removing " + getName(product) + " from the cart");

    // Digital Commerce
    if (isDC(product)) return delFromCartDC(cartIdNode, cartNode, null, product, osComponent, debug);
    // CPQv2
    else return delFromCartCPQ(cartIdNode, cartNode, product, osComponent, debug);
}

/**
 * Returns the top-level line items of the cart, or the immediate child line items of
 * a parent line item.
 * 
 * @param container  The conatainer (cart, basket, or line item) object
 * 
 * @return The top level line items
 */
function getLineItems(container) {

    let items = [];
    if (container) {

        // If we are dealing with a cart, return root line items
        if (container.records) {
            for (let rec of container.records.reverse()) items.push(rec);
        }

        // If we are dealing with a line item, return immediate child line items
        if (container.lineItems && container.lineItems.records) {
            for (let rec of container.lineItems.records) items.push(rec);
        }

        // Find product groups (virtual line items)
        if (container.productGroups && container.productGroups.records) {
            for (let rec of container.productGroups.records) items.push(rec);
        }
    }

    return items;
}

/**
 * Returns a 'flat' representation of the order items with any hierarchy removed.  This makes it 
 * much easier to display a summary within the cart.  Items are returned in the order in which they
 * were added to the cart.
 * 
 * @param container  The container (i.e. cart, line item, etc.) from CPQv2 of Digital Commerce
 * 
 * @return A flat list of all line items, including children, grandchildren, etc.
 */
function getAllLineItems(container) {

    let lineItems = [];

    if (container && container.records) {

        for (let record of container.records.reverse()) {

            // Add this line item
            lineItems.push(record);

            // If there are child line items, add them as well
            if (record.lineItems) lineItems = lineItems.concat(getAllLineItems(record.lineItems));

            // If there are any virtual line items, add them as well
            if (record.productGroups) lineItems = lineItems.concat(getAllLineItems(record.productGroups));
        }
    }

    return lineItems;
}

/**
 * Returns the line item's action value (i.e. Add, Disconnect, etc.)
 * 
 * @param lineItem  The line item from the CPQv2 or Digital Commerce API
 * 
 * @return The action value
 */
function getAction(lineItem) {

    return getFieldValue(lineItem, "vlocity_cmt__Action__c");
}

/**
 * Returns the line item's sub-action value (i.e. Replace, Reassign, etc.)
 * 
 * @param lineItem  The line item from the CPQv2 or Digital Commerce API
 * 
 * @return The sub-action value
 */
function getSubAction(lineItem) {

    return getFieldValue(lineItem, "vlocity_cmt__SubAction__c");
}

/**
 * Derives a single action label to be used for UI/display purposes.
 * 
 * For example:
 * 
 * Action       Sub-Action      Return Value
 * =========================================
 * Disconnect   Replace         Disconnect
 * Add          Replace         Add
 * Disconnect   Reassign        Reassign
 * Add          Reassign        Reassigned
 * 
 * @param lineItem  The line item from the CPQv2 or Digital Commerce API
 * 
 * @return A single action label to use for display
 */
function getActionLabel(lineItem) {

    // In most cases we will just use the Action value
    let action = getAction(lineItem);

    // In the Change-of-Plan Keep scenario, we'll use the Sub-Action
    let subaction = getSubAction(lineItem);

    if (action == "Disconnect" && subaction && subaction === "Reassign") return subaction;
    else if (action == "Add" && subaction && subaction === "Reassign") return "Reassigned";
    else return action;
}

/**
 * Returns the Quantity of a Line Item
 * 
 * @param lineItem  The line item
 * 
 * @return The Quantity of the line item
 */
function getQuantity(lineItem) {

    return toNumber(getFieldValue(lineItem, "Quantity"));
}

/**
 * Returns the OneTime Total for the cart/basket
 * 
 * @param cart  The cart/basket from the CPQv2 API or Digital Commerce APIs
 * 
 * @return The One-Time total
 */
function getOneTimeTotal(cart) {

    // When using Digital Commerce, we get the totals directly
    if (cart && cart.totals) return cart.totals.EffectiveOneTimeTotal__c;

    // In the case of CPQv2, we'll look for a summary node use it
    // If no summary is found (i.e. no getCarts API call) then we'll add up each line item instead
    let total = 0;
    if (cart.summary && cart.summary[0] && cart.summary[0].details) total = cart.summary[0].details.records[0].EffectiveOneTimeTotal__c;
    else {

        // Add up each line item
        for (let lineItem of getAllLineItems(cart)) total += getOneTimeCharge(lineItem);
    }

    return total;
}

/**
 * Returns the Recurring Total for the cart/basket
 * 
 * @param cart  The cart/basket from the CPQv2 API or Digital Commerce APIs
 * 
 * @return The Recurring Total
 */
function getRecurringTotal(cart) {

    // When using Digital Commerce, we get the totals directly
    if (cart && cart.totals) return cart.totals.EffectiveRecurringTotal__c;

    // In the case of CPQv2, we'll look for a summary node use it
    // If no summary is found (i.e. no getCarts API call) then we'll add up each line item instead
    let total = 0;
    if (cart.summary && cart.summary[0] && cart.summary[0].details) total = cart.summary[0].details.records[0].EffectiveRecurringTotal__c;
    else {

        // Add up each line item
        for (let lineItem of getAllLineItems(cart)) total += getRecurringCharge(lineItem);
    }

    return total;
}

/**
 * Determines if this line item is a child line item
 * 
 * @param lineItem The line item
 * 
 * @return true if this line item is a child line item, false otherwise
 */
function isChild(lineItem) {

    // Digital Commerce Scenario
    if (isDC(lineItem)) return lineItem.lineNumber.split(".").length > 1;

    // CPQv2 Scenario - Regular vs. Virtual Line Items
    //                - Virtual Line Items are always child line items
    if (isVirtual(lineItem)) return true;
    else return getFieldValue(lineItem, "vlocity_cmt__LineNumber__c").split(".").length > 1;
}

/**
 * Determines if this line item is a virtual product (i.e. product group)
 * 
 * @param lineItem The line item to test
 * 
 * @return true if this line item is a virtual product, false otherwise
 */
function isVirtual(lineItem) {

    // Digital Commerce Scenario
    if (isDC(lineItem)) return false;

    // CPQv2 Scenario
    if (lineItem.isVirtualItem) return getFieldValue(lineItem, "isVirtualItem");
    else return false;
}

/**
 * Returns the parent line item of the given child line item.
 * 
 * @param lineItem  The child line item
 * @param container The container (cart, basket, or line item) to search within
 * 
 * @returns The parent line item if found
 */
function getParent(lineItem, container) {

    // Find the line item in question
    let items = getLineItems(container);

    for (let item of items) {

        // Found the child line item we are looking for!
        if (getId(item) == getId(lineItem)) {

            // If this is a child line item, then return its parent line item
            // Otherwise it is a root level line item and has no parent
            if (isChild(item)) return container;
            return undefined;
        } else {

            // Look for line items under this line item
            let parent = getParent(lineItem, item);
            if (parent) return parent;
        }
    }
}

/**
 * Evaluates an expression against a product by substituting actual field or attribute values into an expression string.
 * For example, the incoming expression might look something like this:
 * 
 * ATTR:VEPC_ATTR_DOWNLOAD_SPEED > 500 && FLD:IsActive
 * 
 * where:
 * ATTR: <attributeCode> <operator> <value>
 * FLD: <fieldName> <operator> <value>
 * 
 * The resulting expression after substitution would then return a new completed string such as:
 * 
 * 1000 > 500 && true
 * 
 * This evaluates to true
 * 
 * @param product      The product to evaluate the expression against
 * @param expression   The string expression
 * 
 * @return The evaluation result of the computed expression
 */
function evaluate(product, expression) {

    // Don't evaluate if no expression was provided
    if (!expression) return undefined;

    let exp = expression;

    // Build the expression to evaluate this product
    let attributeMatches = [].concat(expression.match(/ATTR:[\w-]+/) || []); // always returns a list
    for (let match of attributeMatches) {

        let av = getAttributeValue(product, match.split(":")[1]);
        if (av) {
            if (typeof av == "string") exp = exp.replaceAll(match, "\"" + av + "\"");
            else exp = exp.replaceAll(match, av);
        } else exp = exp.replaceAll(match, "undefined");
    }
    let fieldMatches = [].concat(expression.match(/FLD:[\w-]+/) || []); // always returns a list
    for (let fmatch of fieldMatches) {

        let fv = getFieldValue(product, fmatch.split(":")[1]);
        if (fv) {
            if (typeof fv == "string") exp = exp.replaceAll(fmatch, "\"" + fv + "\"");
            else exp = exp.replaceAll(fmatch, fv);
        } else exp = exp.replaceAll(fmatch, "undefined");
    }

    // If we have no expression, kick out
    if (exp == "") return "";

    // Evaluate the expression and return an appropriate result
    let result = Function('"use strict";return (' + exp + ')')();

    // Handle undefined results
    if (result == undefined || result == null) return result;

    // Return boolean if the result was true or false
    else if (result == "true" || result == "false") return result == "true";

    // Return number if the result was a numerical value
    else if (!Number.isNaN(result)) return Number(result);

    // Return string as a last resort
    else return result;
}

// Methods that can be imported into your LWC
export {
    isDC,
    toNumber,
    getId,
    getName,
    getCode,
    getCatalogCode,
    getOneTimeCharge,
    getRecurringCharge,
    getDescription,
    getFeatures,
    getImage,
    getAttributeValue,
    setAttributeValue,
    getFieldValue,
    setFieldValue,
    getCartId,
    getParent,
    addToCart,
    delFromCart,
    getLineItems,
    getAllLineItems,
    getAction,
    getSubAction,
    getActionLabel,
    getQuantity,
    isChild,
    isVirtual,
    getOneTimeTotal,
    getRecurringTotal,
    evaluate
};