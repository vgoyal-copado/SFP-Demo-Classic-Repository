/**
  This custom LWC allows you to tag an offer (from the CPQv2 API) as 'recommended'
 
  @author Joe McMaster (joe.mcmaster@salesforce.com)
  @version 1.0
 
  History
  =======
  Mar 23, 2021 - v1.0 - Initial version

  Dependencies
  ============
  demo_cpq_utils - Utilities for dealing with CPQ/DC product structures

  Configuration
  =============
  Create a Set Values component as usual.  Use this LWC as the LWC Component Override value.
  
  Add the following Element Values within the component
  
  catalog   - Points to the catalog data retrieved from vlocity_cmt.CpqAppHandler.getCartsProducts API
  recommend - The recommendation expression that must evaluate to true for the product to be recommended
              For example, ATTR:VEPC_ATTR_DOWNLOAD_SPEED > 500 && FLD:IsActive
  debug     - Indication if debugging messages should be displayed in the browser console

  To-do
  =====
  -Test with a single product to make sure everything works as expected

  THIS SOFTWARE, IS PROVIDED “AS IS” WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED,
  INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
  AND NONINFRINGEMENT.
 
 */
import { OmniscriptBaseMixin } from 'vlocity_cmt/omniscriptBaseMixin';
import OmniscriptSetValues from 'vlocity_cmt/omniscriptSetValues';
import { getName, getCode, evaluate } from 'c/demo_cpq_utils';
import { getOmniScriptElementValue } from 'c/demo_os_utils';

export default class demo_setvalue_cpqrecommend extends OmniscriptBaseMixin(OmniscriptSetValues) {

    debug = false;

    /**
     * Overrides the Set Values 'execute' method
     * 
     * @param event  The event triggering this execution
     * 
     * @return Promise
     */
    execute(event) {

        try {

            this.debug = String(getOmniScriptElementValue(this, "debug")) === "true";

            // Get the new catalog with any recommendations
            let recommendCatalog = this.recommend(getOmniScriptElementValue(this, "catalog"), getOmniScriptElementValue(this, "recommend"));

            // Update OmniScript
            let update = {};
            update[super.jsonDef.name] = recommendCatalog;
            super.omniApplyCallResp(update);

            // If we wanted to execute the regular SetValues code, do the following
            // return Promise.resolve(super.execute(event));

            // Return a simple Promise (OmniScript expects this)
            return Promise.resolve({error:false});
        }
        catch (err) { 
            
            console.error("Error while executing LWC demo_offer_cpqrecommend.execute() -> " + err);

            // We should probably return some error message, so keep an eye out for an example of how
            return Promise.resolve({error:true});
        }
    }

    /**
     * This evaluates an expression against each product to determine if it is recommended.
     * Only 1 product can be recommended and if multiple products are recommended, only 
     * the last product will be tagged with a "recommend" field.
     * 
     * Within your expresions, you can examine attributes and/or fields such as:
     * ATTR:<attributeCode> <operator> <value> && FLD:<fieldName> <operator> <value>
     * 
     * @param catalog     The incoming catalog to process
     * @param expression  The recommendation expression
     * 
     * @returns The same list of products with 0-1 products recommended based on the expression
     */
    recommend(catalog, expression) {

        if (expression) {

            if (this.debug) console.log("CPQ Recommendation -> " + expression);
            let recommendedProduct = null;
            let products = [];

            // Go through the catalog
            for(let product of catalog) {                

                // Temporarily keep this as the recommended product (it can be replaced if we find another later)
                if (evaluate(product, expression)) {
                    if (this.debug) console.log("CPQ Recommending " + getName(product));
                    recommendedProduct = product;
                }
                
                // Push this product into the list
                products.push(product);
            }

            // Now that we've analyzed all the products, locate the one we'll recommend and tag it
            if (recommendedProduct) {
                for(let pr of products) {

                    if (getCode(pr) === getCode(recommendedProduct)) {
                        pr.recommend = true;
                        break;
                    }
                }
            }

            return products;
        }
        
        return catalog;        
    }
}