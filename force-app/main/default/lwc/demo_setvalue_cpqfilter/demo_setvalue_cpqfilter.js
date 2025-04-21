/**
  This custom LWC allows you to filter a list of offers (from CPQv2 API) further than
  what is supported by the API itself.
 
  @author Joe McMaster (joe.mcmaster@salesforce.com)
  @version 2.1
 
  History
  =======
  Mar  2, 2021 - v1.0 - Initial version (filter by budget)
  Mar 23, 2021 - v2.0 - Added a more flexible filter that supports fields and attributes
  May 17, 2021 - v2.1 - Migrated to CPQ utils evaluate function
  
  Dependencies
  ============
  demo_cpq_utils - Utilities for dealing with CPQ/DC product structures
  
  Configuration
  =============
  Create a Set Values component as usual.  Use this LWC as the LWC Component Override value.
  
  Add the following Element Values within the component
  
  catalog     - Points to the catalog data retrieved from vlocity_cmt.CpqAppHandler.getCartsProducts API
  lowerPrice  - The lower price point (all offers with a lower price-point will be filtered out)
  upperPrice  - The upper price point (all offers with a higher price-point will be filtered out)
  filter      - The filter string to use that must evaluate to true for the product to be included
                For example, ATTR:VEPC_ATTR_DOWNLOAD_SPEED > 500 && FLD:IsActive
  debug       - Indication if debugging messages should be displayed in the browser console
  
  To-do
  =====
  -Test with a single product to make sure everything works as expected
  -Migrate lower/upper Price to simply use the filter
  
  THIS SOFTWARE, IS PROVIDED “AS IS” WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED,
  INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
  AND NONINFRINGEMENT.
 
 */
import { OmniscriptBaseMixin } from 'vlocity_cmt/omniscriptBaseMixin';
import OmniscriptSetValues from 'vlocity_cmt/omniscriptSetValues';
import { getOneTimeCharge, getRecurringCharge, getName, evaluate } from 'c/demo_cpq_utils';
import { getOmniScriptElementValue } from 'c/demo_os_utils';

export default class demo_offer_filter extends OmniscriptBaseMixin(OmniscriptSetValues) {

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

            let catalog = getOmniScriptElementValue(this, "catalog");

            // Filter by budget
            let filteredCatalog = this.budgetFilter(catalog, getOmniScriptElementValue(this, "lowerPrice"), getOmniScriptElementValue(this, "upperPrice"));
            filteredCatalog = this.filter(filteredCatalog, getOmniScriptElementValue(this, "filter"));

            // Update OmniScript
            let update = {};
            update[super.jsonDef.name] = filteredCatalog;
            super.omniApplyCallResp(update);

            // If we wanted to execute the regular SetValues code, do the following
            // return Promise.resolve(super.execute(event));

            // Return a simple Promise (OmniScript expects this)
            return Promise.resolve({error:false});
        }
        catch (err) { 
            
            console.error("Error while executing LWC demo_offer_filter.execute() -> " + err);

            // We should probably return some error message, so keep an eye out for an example of how
            return Promise.resolve({error:true});
        }
    }

    /**
     * This filters products by an expression such as:
     * ATTR:<attributeCode> <operator> <value>
     * FLD:<fieldName> <operator> <value>
     * 
     * @param catalog     The incoming catalog to be filtered
     * @param expression  The filter expression
     * 
     * @returns List of products that match the filter
     */
    filter(catalog, expression) {

        let productMatches = [];

        if (expression) {

            if (this.debug) console.log("CPQ Filter -> " + expression);

            // Go through the catalog
            for(let product of catalog) {

                if (evaluate(product, expression)) {
                    
                    if (this.debug) console.log("CPQ Filter - Including " + getName(product));
                    productMatches.push(product);
                }                
                else if (this.debug) console.log("CPQ Filter - Excluding " + getName(product));
            }

            return productMatches;
        }

        return catalog;  // filter not applicable
    }

    /**
     * This filters products by their price in order to fit within a given budget.
     * Both the One-Time & Recurring Prices will be examined.  If either falls within
     * the buget, the product will be included.
     * 
     * @param catalog     The incoming catalog to be filtered
     * @param lowerPrice  The lower price of the budget
     * @param upperPrice  The upper price of the budget
     * 
     * @return List of products that fit within the budget
     */
    budgetFilter(catalog, lowerPrice, upperPrice) {
    
        // We must have a lowerPrice or upperPrice (or both)
        if (lowerPrice || upperPrice) {
        
            let fc = [];

            for(let i=0; i<catalog.length; i++) {

                // If either the OTC or MRC falls within the budget, include it
                let otc = getOneTimeCharge(catalog[i]);
                let mrc = getRecurringCharge(catalog[i]);

                if (lowerPrice && (otc < lowerPrice || mrc < lowerPrice)) continue;
                if (upperPrice && (otc > upperPrice || mrc > upperPrice)) continue;
                fc.push(catalog[i]);
            }

            // return the filtered list of products
            return fc;
        }

        return catalog;  // filter not applicable
    }
}