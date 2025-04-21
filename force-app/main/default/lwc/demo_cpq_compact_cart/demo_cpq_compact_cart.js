/*
  This custom LWC renders a simple and compact cart summary that can be placed in an OmniScript step.
  
  @author Joe McMaster
  @version 2.3
    
  History
  =======
  Jan 12, 2021 - v1.0 - Initial version
  Mar 30, 2021 - v2.0 - Support for both CPQv2 cart & Digital Commerce basket models
  Apr 22, 2021 - v2.1 - Fixed alignment issue when both OTC & MRC prices appear in the cart
  Aug 27, 2021 - v2.2 - Fixes for Change-of-Plan support
  Oct 20, 2021 - v2.3 - Support for Virtual Line Items, styling fixes for offers with both OTC & MRC

  Configuration
  =============
  Set the following custom LWC properties in OmniScript to configure this component

  cart         - (Mandatory) - The cart from the CPQv2 or Digital Commerce APIs
  title        - (Optional)  - The title to place in the header of the cart summary (default is blank)
  hide-actions - (Optional)  - set to hide the actions column
  tax-rate     - (Optional)  - The tax rate to apply for demo purposes (default is 0)
  debug        - (Optional)  - Indication if debug mode should be enabled

*/
import { LightningElement, api, track } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_cmt/omniscriptBaseMixin';
import { getName, getCode, getQuantity, getDescription, getImage, getLineItems, getAllLineItems, getAction, getSubAction, getActionLabel, isChild, isVirtual, getOneTimeCharge, getRecurringCharge, getOneTimeTotal, getRecurringTotal } from 'c/demo_cpq_utils';

export default class demo_compact_cart extends OmniscriptBaseMixin(LightningElement) { 

    // cart
    @api
    get cart() { 
        return this._cart; 
    }
    set cart(data) {

        try {

            if (data) {
                
                this._cart = JSON.parse(JSON.stringify(data));
                this.lineItems = getAllLineItems(this._cart);
                this.otcSubTotal = 0;
                this.mrcSubTotal = 0;

                for (let line of this.lineItems) {

                    line.ui = {
                        name: getName(line),
                        code: getCode(line),
                        quantity: getQuantity(line),
                        action: getAction(line),
                        subaction: getSubAction(line),
                        actionLabel: getActionLabel(line),
                        otc: getOneTimeCharge(line),
                        mrc: getRecurringCharge(line),
                        description: getDescription(line),
                        productImage: getImage(line),
                        isChild: isChild(line),
                        isVirtual: isVirtual(line)
                    };

                    // Set the pricing text
                    let pricingText = "";
                    if (line.ui.otc) pricingText += "$" + line.ui.otc.toFixed(2);
                    if (line.ui.mrc) {
                        if (pricingText.length > 0) pricingText += ", ";
                        pricingText += "$" + line.ui.mrc.toFixed(2) + " / month";
                    }
                    line.ui.pricingText = pricingText;

                    // If this is a child line item, indent the name
                    if (line.ui.isChild) line.ui.name = "   " + line.ui.name;
                }

                this.calculateTotals();
            }
        }
        catch (err) {
            console.error("Error in set cart() -> " + err);
        }
    }

    // title
    @api title = "";

    // tax-rate
    @api
    get taxRate() {
        return this._taxRate;
    }
    set taxRate(data) {
        
        try {

            if (data) {
                this._taxRate = data;
                this.calculateTotals();
            }
        }
        catch (err) {
            console.error("Error in set taxRate() -> " + err);
        }
    }

    // Initialize the hide-actions flag
    @api
    get hideActions() {
        return this._hideActions;
    }
    set hideActions(data) {

        try {
            if (data) this._hideActions = String(data) === "true";
        } catch (err) {
            console.error("Error in set hideActions() -> " + err);
        }
    }

    // Initialize the debug flag
    @api
    get debug() {
        return this._debug;
    }
    set debug(data) {
        try {
            if (data) this._debug = String(data) === "true";
        } catch (err) {
            console.error("Error in set debug() -> " + err);
        }
    }

    // Private variables
    @track _cart = [];           // track this variable so that the UI is re-rendered upon any changes
    @track _taxRate = 0;         // tax rate to apply
    @track _hideActions = false; // flag to indicate when to show actions
    _debug = false;              // enable to see more debug information    

    @track lineItems = [];
    @track lineItemCount = "No Items";

    @track otcSubTotal = 0;
    @track mrcSubTotal = 0;
    @track otcTax = 0;
    @track mrcTax = 0;
    @track otcTotal = 0;
    @track mrcTotal = 0;
    @track otcSubTotalText = "";
    @track mrcSubTotalText = "";
    @track otcTaxText = "";
    @track mrcTaxText = "";
    @track otcTotalText = "";
    @track mrcTotalText = "";
    
    /**
     * Performs the calculations necessary to determine the totals shown in the cart
     * 
     */
    calculateTotals() {

        // Number of Line Items (only count top-level line items)
        let numItems = getLineItems(this._cart).length;
        if (numItems === 0) this.lineItemCount = "No Items";
        else if (numItems === 1) this.lineItemCount = "1 Item";
        else this.lineItemCount = numItems + " Items";

        // Calculate Cart Sub-Totals
        this.otcSubTotal = getOneTimeTotal(this._cart);        
        this.mrcSubTotal = getRecurringTotal(this._cart);
        this.otcSubTotalText = this.otcSubTotal.toFixed(2);
        this.mrcSubTotalText = this.mrcSubTotal.toFixed(2);

        // Calculate Taxes & Fees
        this.otcTax = this.otcSubTotal * this._taxRate;
        this.mrcTax = this.mrcSubTotal * this._taxRate;
        this.otcTaxText = this.otcTax.toFixed(2);
        this.mrcTaxText = this.mrcTax.toFixed(2);

        // Calculate Totals
        this.otcTotal = this.otcSubTotal + this.otcTax;
        this.mrcTotal = this.mrcSubTotal + this.mrcTax;
        this.otcTotalText = this.otcTotal.toFixed(2);
        this.mrcTotalText = this.mrcTotal.toFixed(2);
    }
}