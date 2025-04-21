/*
  This custom LWC renders offers from both the CPQv2 and Digital Commerce APIs as a series of tiles
  that can be selected to add/remove offers to a cart or basket.  It can also be used as a simple
  selectable items component without making API calls to add/remove products.
  
  @author Joe McMaster
  @version 3.7
    
  History
  =======
  Jan 12, 2021 - v1.0 - Initial version
  Mar 15, 2021 - v1.1 - Select button renames to "Remove" when offer is added
                      - Colour changes to add/remove button
  Mar 26, 2021 - v2.0 - Support for recommended products (see demo_setvalue_cpqrecommend LWC)
                      - Support for Digital Commerce APIs
  Apr 22, 2021 - v2.1 - Minor CSS fixes
                      - Support for back-stepping in OmniScript
  May  4, 2021 - v2.2 - Fixed Image Sizing issue
  May  5, 2021 - v3.0 - Added sortby, filter, and recommend capabilities
  Jul 15, 2021 - v3.1 - Fixed sorting issue when some sortkeys have undefined values
  Aug 26, 2021 - v3.2 - Fixes to support Change of Plan flows (support displaying Assets)
  Oct 19, 2021 - v3.3 - Support for adding child offers (CPQv2 mode only)
  Dec  2, 2021 - v3.4 - Modified to display offer name when product image is hidden
  Jan  4, 2022 - v3.5 - Added hide-pricing property + various CSS fixes
  Mar 22, 2022 - v3.6 - Enhanced support for adding child offers (CPQv2 mode only) so a simple 
                        parent line item code can be passed, rather than a large complex payload
  Aug 10, 2022 - v3.7 - CSS tweaks

  Notes
  =====
  -Use a hyphen in the product description to denote individual features and have them displayed
  as a list on the tile.

  Configuration
  =============
  Set the following custom LWC properties in OmniScript to configure this component
  
  catalog               - (Mandatory) - Points to the catalog data retrieved from the CPQv2 API (getCartsProducts) or Digital Commerce API (getOffers)
  hide-images           - (Optional)  - set to true to hide the product image for each tile
  hide-body             - (Optional)  - set to true to hide the product description
  hide-footer           - (Optional)  - set to hide the entire footer (price + buttons)
  hide-pricing          - (Optional)  - set to hide the pricing
  hide-buttons          - (Optional)  - set to hide the buttons (add/remove)
  auto-advance          - (Optional)  - if set to true, the OmniScript will automatically move to the next Step when a user selects an offer
  select-mode           - (Optional)  - The type of selection to use for each tile
                                      - select (default) when the user selects the tile, the selected offer will be populated in the OmniScript JSON data
                                      - api - the selected offer will be populated in the OmniScript JSON data and the CPQv2/DC API will be called
                                      - none - the tile will be read-only and users will not be able to select it 
  cart-id-node          - (Optional)  - if set, specifies the top-level JSON node in OmniScript that is used to track the cart Id
                                      - if set, the LWC will make the necessary API calls to add/remove products from an existing cart (CPQv2)
                                      - When using CPQv2 APIs, this will contain the SObject Id of the cart (Opportunity, Quote, or Order)
                                      - When using Digital Commerce APIs, this will contain the current Basket Id and be updated by the LWC as needed
  cart-node             - (Optional)  - if set, specifies the top-level JSON node in the OmniScript that is used to track the line items in the cart/basket
                                      - if not set, it will default to "cart"
  context-key           - (Optional)  - When using Digital Commerce, this will contain the current user's context Id
  parent-line-item      - (Optional)  - The parent line item on which to add offers
                                      - By default, offers are added to the root level of the cart.  Setting this will attempt to add the offer as a child of the given parent line item
                                      - Only supported in CPQv2 mode!
  parent-line-item-code - (Optional)  - A simple line item code that represents the parent line item offers should be added to (rather than the root level of the cart)
                                      - This will result in the "first" line item with a matching code being used as a parent
                                      - Use this rather than parent-line-item when the use-case is simple and there is no possibiilty of having multiple parents
                                      - Only supported in CPQv2 mode!
  sort-by               - (Optional)  - A field or attribute to use in sorting the catalog
                                        For example, ATTR:VEPC_ATTR_DOWNLOAD_SPEED
  sort-direction        - (Optional)  - The sort direction (ASC or DEC).  The default is ASC.
  filter                - (Optional)  - A filter expression to use on the catalog.  Both fields and attributes can be used in the filter expression
                                        For example, ATTR: VEPC_ATTR_DOWNLOAD_SPEED > 500 && FLD: IsActive
  recommend             - (Optional)  - A recommendation expression to use on the catalog in order to recommend a particular offer.  Both fields and attributes
                                        can be used to make the recommendation, and at most 1 offer will be tagged as recommended
                                        For example, ATTR: VEPC_ATTR_DOWNLOAD_SPEED > 500 && FLD: IsActive
  add-button-label      - (Optional)  - The default "add" button name
  remove-button-label   - (Optional)  - The default "remove" button name                                 
  debug                 - (Optional)  - if set, extra debug information will be displayed
*/
import {
    LightningElement,
    api,
    track
} from 'lwc';
import {
    OmniscriptBaseMixin
} from 'vlocity_cmt/omniscriptBaseMixin';
import {
    getName,
    getCode,
    getOneTimeCharge,
    getRecurringCharge,
    getDescription,
    getFeatures,
    getImage,
    addToCart,
    delFromCart,
    getAllLineItems,
    evaluate
} from 'c/demo_cpq_utils';
import {
    getDataJson
} from 'c/demo_os_utils';

export default class demo_offer_tiles extends OmniscriptBaseMixin(LightningElement) {

    @api selectMode = "select"; // The tile selection behaviour
    @api contextKey = undefined; // context-key (when using Digital Commerce APIs)
    @api cartIdNode = undefined; // The top-level OmniScript node where we can find/update the cart/basket Id
    @api cartNode = "cart"; // The top-level OmniScript node where the shopping cart will be stored (defaults to "cart")
    @api parentLineItem = undefined; // The parent line item to add offers to
    @api parentLineItemCode = undefined; // The product code of the parent line item to look for
    @api addButtonLabel = "Select"; // The default add button label
    @api removeButtonLabel = "Remove"; // The default delete button label

    @api
    get catalog() {
        return this._catalog;
    }

    // Initialize the catalog data
    set catalog(data) {

        try {

            if (data) {

                // Compute UI fields to help us render it easily (regardless of CPQv2 vs. Digital Commerce APIs)
                this._catalog = [].concat(JSON.parse(JSON.stringify(data)));

                // process the catalog
                this.initCatalog();
            }
        } catch (err) {
            console.error("Error in set catalog() -> " + err);
        }
    }

    // Initialize the auto-advance flag
    @api
    get autoAdvance() {
        return this._autoAdvance;
    }
    set autoAdvance(data) {

        try {
            if (data) this._autoAdvance = String(data) === "true";
        } catch (err) {
            console.error("Error in set autoAdvance() -> " + err);
        }
    }

    // Initialize the hide-images flag
    @api
    get hideImages() {
        return this._hideImages;
    }
    set hideImages(data) {

        try {
            if (data) this._hideImages = String(data) === "true";
        } catch (err) {
            console.error("Error in set hideImages() -> " + err);
        }
    }

    // Initialize the hide-body flag
    @api
    get hideBody() {
        return this._hideBody;
    }
    set hideBody(data) {

        try {
            if (data) this._hideBody = String(data) === "true";
        } catch (err) {
            console.error("Error in set hideBody() -> " + err);
        }
    }

    // Initialize the hide-buttons flag
    @api
    get hideFooter() {
        return this._hideFooter;
    }
    set hideFooter(data) {

        try {
            if (data) this._hideFooter = String(data) === "true";
        } catch (err) {
            console.error("Error in set hideFooter() -> " + err);
        }
    }

    // Initialize the hide-buttons flag
    @api
    get hideButtons() {
        return this._hideButtons;
    }
    set hideButtons(data) {

        try {
            if (data) this._hideButtons = String(data) === "true";
        } catch (err) {
            console.error("Error in set hideButtons() -> " + err);
        }
    }

    // Initialize the hide-pricing flag
    @api
    get hidePricing() {
        return this._hidePricing;
    }
    set hidePricing(data) {

        try {
            if (data) this._hidePricing = String(data) === "true";
        } catch (err) {
            console.error("Error in set hidePricing() -> " + err);
        }
    }

    // The field or attribute to sort by
    @api
    get sortBy() {
        return this._sortByExpression;
    }
    set sortBy(data) {

        try {
            if (data) {

                this._sortByExpression = data;

                // process the catalog
                this.initCatalog();
            }
        } catch (err) {
            console.error("Error in set sortBy() -> " + err);
        }
    }

    // The sort direction
    @api
    get sortDirection() {
        return this._sortDirection;
    }
    set sortDirection(data) {

        try {
            if (data) {

                this._sortDirection = data;

                // process the catalog
                this.initCatalog();
            }
        } catch (err) {
            console.error("Error in set sortDirection() -> " + err);
        }
    }

    // The Recommendation Expression
    @api
    get recommend() {
        return this._recommendExpression;
    }
    set recommend(data) {

        try {
            if (data) {

                this._recommendExpression = data;

                // process the catalog
                this.initCatalog();
            }
        } catch (err) {
            console.error("Error in set recommend() -> " + err);
        }
    }

    // The Filter Expression
    @api
    get filter() {
        return this._filterExpression;
    }
    set filter(data) {

        try {
            if (data) {

                this._filterExpression = data;

                // process the catalog
                this.initCatalog();
            }
        } catch (err) {
            console.error("Error in set filter() -> " + err);
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
    @track _catalog = []; // track this variable so that the UI is re-rendered upon any changes (i.e. offer selections)
    @track _hideImages = false; // flag to indicate when to show images
    @track _hideBody = false; // flag to indicate when to show product description
    @track _hideFooter = false; // flag to indicate when to show the footer
    @track _hidePricing = false; // flag to indicate when to show the pricing
    @track _hideButtons = false; // flag to indicate when to show the add/remove buttons
    @track _spinnerEnabled = false; // Spinner to show when API calls are being made
    _sortByExpression = null; // Attribute or Field expression used to sort offers
    _sortDirection = "ASC"; // Sort direction (Ascending or Descending)
    _recommendExpression = null; // The recommendation expression
    _filterExpression = null; // The filter expression
    _autoAdvance = false; // flag to indicate if we should auto-advance after a product selection
    _debug = false; // enable to see more debug information

    /**
     * Processes the catalog
     * 
     */
    initCatalog() {

        if (this._catalog) {

            // process each item in the catalog
            for (let product of this._catalog) {

                product.ui = {
                    name: getName(product),
                    code: getCode(product),
                    otc: getOneTimeCharge(product),
                    mrc: getRecurringCharge(product),
                    description: getDescription(product),
                    features: getFeatures(product),
                    productImage: getImage(product),
                    show: true,
                    recommend: false,
                    sortkey: evaluate(product, this._sortByExpression)
                };

                // Set the pricing text
                let pricingText = "";
                if (product.ui.otc) {

                    pricingText += "$";
                    if (product.ui.otc % 1 != 0) pricingText += product.ui.otc.toFixed(2);
                    else pricingText += product.ui.otc;
                }
                if (product.ui.mrc) {

                    if (pricingText.length > 0) pricingText += " + ";

                    pricingText += "$";
                    if (product.ui.mrc % 1 != 0) pricingText += product.ui.mrc.toFixed(2);
                    else pricingText += product.ui.mrc;

                    pricingText += " / month";
                }
                product.ui.pricingText = pricingText;
            }

            // Sort the catalog
            this.sortCatalog();

            // filter catalog
            this.filterCatalog();

            // Make a product recommendation
            this.recommendOffer();

            // If we've back-stepped onto this Step refresh the selected offers from the OmniScript data
            this.setSelectedOffers();
        }
    }

    /**
     * Sorts the catalog
     * 
     */
    sortCatalog() {

        // Sort the catalog
        if (this._sortByExpression) {

            if (this._sortDirection == "ASC") this._catalog.sort(this.sortAscending);
            else this._catalog.sort(this.sortDescending);
        }
    }

    /**
     * Ascending sorting algorithm for the catalog
     * 
     * @param prod1  The first product
     * @param prod2  The second product
     * 
     * @return -1 if prod1 comes before prod2, 0 if prod1 = prod2, and 1 if prod1 comes after prod2
     */
    sortAscending(prod1, prod2) {

        // Handle undefined values
        if (!prod1.ui.sortkey && prod2.ui.sortkey) return -1;
        else if (prod1.ui.sortkey && !prod2.ui.sortkey) return 1;

        // Normal sort
        if (prod1.ui.sortkey < prod2.ui.sortkey) return -1;
        else if (prod1.ui.sortkey > prod2.ui.sortkey) return 1;

        return 0;
    }

    /**
     * Descending sorting algorithm for the catalog
     * 
     * @param prod1  The first product
     * @param prod2  The second product
     * 
     * @return -1 if prod1 comes after prod2, 0 if prod1 = prod2, and 1 if prod1 comes before prod2
     */
    sortDescending(prod1, prod2) {

        // Handle undefined values
        if (!prod1.ui.sortkey && prod2.ui.sortkey) return 1;
        else if (prod1.ui.sortkey && !prod2.ui.sortkey) return -1;

        if (prod1.ui.sortkey < prod2.ui.sortkey) return 1;
        else if (prod1.ui.sortkey > prod2.ui.sortkey) return -1;

        return 0;
    }

    /**
     * This filters products by an expression such as:
     * ATTR:<attributeCode> <operator> <value>
     * FLD:<fieldName> <operator> <value>
     */
    filterCatalog() {

        if (this._filterExpression) {

            // Go through the catalog
            for (let product of this._catalog) {

                if (evaluate(product, this._filterExpression)) product.ui.show = true;
                else product.ui.show = false;
            }
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
     * @returns The same list of products with 0-1 products recommended based on the expression
     */
    recommendOffer() {

        if (this._recommendExpression) {

            let recommendedProduct = null;

            // Go through the catalog
            for (let product of this._catalog) {

                // Temporarily keep this as the recommended product (it can be replaced if we find another later)
                if (evaluate(product, this._recommendExpression)) recommendedProduct = product;
            }

            // if we've found a recommended product, tag it as such
            if (recommendedProduct) recommendedProduct.ui.recommend = true;
        }
    }

    /**
     * Programmtically selects products based on what has been selected in the past (i.e. if we backstep in the OmniScript)
     * 
     */
    setSelectedOffers() {

        // If we back back-stepped into this component, check the OmniScript data to determine if any
        // have been selected in the past
        let selections = getDataJson(this);
        if (selections) {

            for (let s of selections) {

                let code = getCode(s);

                // Find the product tile and select it programmtically
                for (let p of this._catalog) {

                    if (code == getCode(p)) p.ui.selected = true;
                }
            }
        }
    }

    /**
     * A JavaScript filter used to return all products that are selected
     * 
     * @param product  The product to evaluate
     * 
     * @return true if the product is selected
     */
    static getAllSelectedOffers(product) {
        return product.ui.selected;
    }

    /**
     * Handles the selection of an offer
     * 
     * @param {*} event   The offer selection event
     */
    selectOffer(event) {

        try {

            // Detect when selectionMode is set to "none" and make the tile read-only (no response to clicks)
            if (this.selectMode != "select" && this.selectMode != "api") return;

            // Use currentTarget vs target as the click can come from any element inside the div.
            // The 'currentTarget' is the element where we've attached onclick() handler
            var productCode = event.currentTarget.dataset.productCode;

            // find the product that was selected
            let selectedProduct = this._catalog.filter(function (product) {
                return getCode(product) === this;
            }, productCode)[0];

            // Toggle the selection flag
            selectedProduct.ui.selected = !selectedProduct.ui.selected;

            if (this._debug) {
                if (selectedProduct.ui.selected) console.log("Product " + getName(selectedProduct) + " selected");
                else console.log("Product " + getName(selectedProduct) + " deselected");
            }

            // Add to cart if we have an existing cart (or at least a contextKey for adding the intial product with Digital Commerce) 
            if (this.selectMode == "api") {

                this._spinnerEnabled = true;

                // If the offer has been deselected, remove it from the cart
                if (!selectedProduct.ui.selected) this.deleteOfferFromCart(selectedProduct).then(result => {
                    this._spinnerEnabled = false;
                });
                else {

                    // Support for adding products to a parent line item
                    let parentLI;
                    if (this.parentLineItem) parentLI = this.parentLineItem;
                    else if (this.parentLineItemCode) {

                        // Try to locate the parent line item by Code
                        let cart = JSON.parse(JSON.stringify(super.omniJsonData[this.cartNode]));
                        parentLI = getAllLineItems(cart).filter(li => {
                            return this.parentLineItemCode == getCode(li);
                        })[0];
                    }

                    this.addOfferToCart(selectedProduct, parentLI).then(result => {

                        // Stop Spinner
                        this._spinnerEnabled = false;

                        // Auto-Advance if configured
                        if (this._autoAdvance) {
                            console.log("Auto Advancing to next OmniScript Step");
                            this.omniNextStep();
                        }
                    });
                }
            } else {

                // Update the OmniScript data with the list of selected products
                this.omniUpdateDataJson(this._catalog.filter(demo_offer_tiles.getAllSelectedOffers));

                // Auto-Advance if configured
                if (this._autoAdvance && selectedProduct.ui.selected) {
                    console.log("Auto Advancing to next OmniScript Step");
                    this.omniNextStep();
                }
            }

        } catch (err) {
            console.error("Error in selectOffer() -> " + err);
        }
    }

    /**
     * Adds a product to the cart
     * 
     * @param product         The product to add to the cart
     * @param parentLineItem  (Optional) The parent line item this offer should become a child of
     * 
     * @return A Promise
     */
    addOfferToCart(product, parentLineItem) {

        // Add the product to the cart/basket
        return addToCart(this.cartIdNode, this.cartNode, this.contextKey, parentLineItem, product, this, this._debug).then(response => {

            // Update the OmniScript data with the list of selected products
            this.omniUpdateDataJson(this._catalog.filter(demo_offer_tiles.getAllSelectedOffers));

        }).catch(err => {
            console.error("Unable to add " + getName(product) + " to the cart -> " + err);
        });
    }

    /**
     * Removes a line item from the cart
     * 
     * @param product  The product to remove from the cart
     * 
     * @return A Promise
     */
    deleteOfferFromCart(product) {

        // Remove the line item from the cart/basket
        return delFromCart(this.cartIdNode, this.cartNode, product, this, this._debug).then(response => {

            // Update the OmniScript data with the list of selected products
            this.omniUpdateDataJson(this._catalog.filter(demo_offer_tiles.getAllSelectedOffers));

        }).catch(err => {
            console.error("Unable to remove " + getName(product) + " from the cart -> " + err);
        });
    }
}