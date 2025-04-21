import { FlexCardMixin } from "vlocity_cmt/flexCardMixin";
    import { CurrentPageReference } from 'lightning/navigation';
    import {interpolateWithRegex, interpolateKeyValue, loadCssFromStaticResource } from "vlocity_cmt/flexCardUtility";
    
          import { LightningElement, api, track, wire } from "lwc";
          import pubsub from "vlocity_cmt/pubsub";
          import { getRecord } from "lightning/uiRecordApi";
          
          import data from "./definition";
          
          import styleDef from "./styleDefinition";
              
          export default class cfCpqMultiSiteGroupTemplate extends FlexCardMixin(LightningElement){
              currentPageReference;        
              @wire(CurrentPageReference)
              setCurrentPageReference(currentPageReference) {
                this.currentPageReference = currentPageReference;
              }
              @api debug;
              @api recordId;
              @api objectApiName;
              
              @track record;
              @track _sessionApiVars = {};
              @track Label={MSLockedPartOne:"Locked while",
        MSLockedPartTwo:"is being processed.",
        MSApplytoGroupCompleted:"Apply to Group was completed.",
        MSWarningsErrorsPartOne:"There are",
        MSWarningsPartTwo:"warnings on",
        MSErrorsPartTwo:"errors on",
        CPQQuote:"Quote",
        CPQOrder:"Order",
        CPQCreateOrder:"Create Order",
        CPQCreateAssets:"Submit Order",
        MultiServiceCPQOrderCheckoutAction:"Submit Orders",
        MultiServiceCPQQuoteCheckoutAction:"Create and Submit Orders",
        MSPriceAndValidate:"Validate and Price",
        MSApplytomembers:"Apply to Members",
        MSGroupTemplate:"Group Template",
        MSPriceValidationCompleted:"Price and Validate async job is completed.",
        MSUnappliedStatusIcon:"You haven't applied cart items to the members of this group.",
        MSNoCartItemsStatusIcon:"There are no cart items to apply to the members of this group."
        };
              pubsubEvent = [];
              customEvent = [];
              
              connectedCallback() {
                super.connectedCallback();
                this.setStyleDefinition(styleDef);
                data.Session = {} //reinitialize on reload
                
                
                this.customLabels = this.Label;
                      
                          this.fetchUpdatedCustomLabels();
                      
                this.setDefinition(data);
 this.registerEvents();
                
                
              }
              
              disconnectedCallback(){
                super.disconnectedCallback();
                    
                    

                  this.unregisterEvents();
              }

              registerEvents() {
                
        this.pubsubEvent[0] = {
          [interpolateWithRegex(`cpq_multisite_new_group_selected`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[0],0),
[interpolateWithRegex(`cpq_cart_updated`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[1],1),
[interpolateWithRegex(`cpq_submitbutton_disable`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[3],3),
[interpolateWithRegex(`cpq_multisite_new_group_member_selected`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[4],4)
        };
        this.pubsubChannel0 = interpolateWithRegex(`cpq_${this.recordId}`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel0,this.pubsubEvent[0]);

        this.pubsubEvent[1] = {
          [interpolateWithRegex(`cpq_updated_group_cart_template_details`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[2],2)
        };
        this.pubsubChannel1 = interpolateWithRegex(`cpq_groups_${this.recordId}`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel1,this.pubsubEvent[1]);

              }

              unregisterEvents(){
                pubsub.unregister(this.pubsubChannel0,this.pubsubEvent[0]);
pubsub.unregister(this.pubsubChannel1,this.pubsubEvent[1]);

              }
            
              renderedCallback() {
                super.renderedCallback();
                
              }
          }