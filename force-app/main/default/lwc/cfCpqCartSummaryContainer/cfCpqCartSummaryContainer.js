import { FlexCardMixin } from "vlocity_cmt/flexCardMixin";
    import { CurrentPageReference } from 'lightning/navigation';
    import {interpolateWithRegex, interpolateKeyValue, loadCssFromStaticResource } from "vlocity_cmt/flexCardUtility";
    
          import { LightningElement, api, track, wire } from "lwc";
          import pubsub from "vlocity_cmt/pubsub";
          import { getRecord } from "lightning/uiRecordApi";
          
          import data from "./definition";
          
          import styleDef from "./styleDefinition";
              
          export default class cfCpqCartSummaryContainer extends FlexCardMixin(LightningElement){
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
              @track Label={CPQAddToCart:"Add to Cart",
        CPQConfigure:"Configure",
        Cart:"Cart",
        CPQDelete:"Delete",
        CPQAddProducts:"Add Products",
        close:"Close",
        CPQCatalogPreview:"Catalog Preview"
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
          [interpolateWithRegex(`cpq_catalog_item_select_cart`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[0],0),
[interpolateWithRegex(`cpq_close_preview_catalog`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[1],1),
[interpolateWithRegex(`cpq_open_preview_catalog`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[2],2),
[interpolateWithRegex(`cpqshowfilters`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[5],5),
[interpolateWithRegex(`cpq_qualified`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[6],6),
[interpolateWithRegex(`apply_filter`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[7],7),
[interpolateWithRegex(`cpq_cart_updated`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[8],8),
[interpolateWithRegex(`cpq_spinner`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[9],9),
[interpolateWithRegex(`cpq_select_multiple_products_cart`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[10],10),
[interpolateWithRegex(`cpq_remove_multiselect_cart`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[11],11),
[interpolateWithRegex(`cpq_check_multisite_flow`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[12],12),
[interpolateWithRegex(`cpqselectcart`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[13],13),
[interpolateWithRegex(`cpq_multisite_new_group_selected`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[14],14),
[interpolateWithRegex(`cpq_multisite_new_group_member_selected`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[16],16)
        };
        this.pubsubChannel0 = interpolateWithRegex(`cpq_${this.recordId}`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel0,this.pubsubEvent[0]);

        this.pubsubEvent[1] = {
          [interpolateWithRegex(`cpq`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[3],3)
        };
        this.pubsubChannel1 = interpolateWithRegex(`cpqCloneItem_${this.recordId}`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel1,this.pubsubEvent[1]);

        this.pubsubEvent[2] = {
          [interpolateWithRegex(`cpq_update_cart_summary`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[4],4)
        };
        this.pubsubChannel2 = interpolateWithRegex(`cpq_ui_event_${this.recordId}`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel2,this.pubsubEvent[2]);

        this.pubsubEvent[3] = {
          [interpolateWithRegex(`cpq_update_cartid`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[15],15)
        };
        this.pubsubChannel3 = interpolateWithRegex(`cpq_${this.recordId}_summary`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel3,this.pubsubEvent[3]);

              }

              unregisterEvents(){
                pubsub.unregister(this.pubsubChannel0,this.pubsubEvent[0]);
pubsub.unregister(this.pubsubChannel1,this.pubsubEvent[1]);
pubsub.unregister(this.pubsubChannel2,this.pubsubEvent[2]);
pubsub.unregister(this.pubsubChannel3,this.pubsubEvent[3]);

              }
            
              renderedCallback() {
                super.renderedCallback();
                
              }
          }