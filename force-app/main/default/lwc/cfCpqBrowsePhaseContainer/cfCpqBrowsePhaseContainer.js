import { FlexCardMixin } from "vlocity_cmt/flexCardMixin";
    import { CurrentPageReference } from 'lightning/navigation';
    import {interpolateWithRegex, interpolateKeyValue, loadCssFromStaticResource } from "vlocity_cmt/flexCardUtility";
    
          import { LightningElement, api, track, wire } from "lwc";
          import pubsub from "vlocity_cmt/pubsub";
          import { getRecord } from "lightning/uiRecordApi";
          
          import data from "./definition";
          
          import styleDef from "./styleDefinition";
              
          export default class cfCpqBrowsePhaseContainer extends FlexCardMixin(LightningElement){
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
              @track Label={CPQDelete:"Delete",
        Close:"Close",
        CPQCartPreview:"Cart Preview"
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
          [interpolateWithRegex(`cpqchangeviewtotile`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[0],0),
[interpolateWithRegex(`cpqchangeviewtolist`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[1],1),
[interpolateWithRegex(`cpq_catalog_item_select_browse`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[2],2),
[interpolateWithRegex(`apply_filter`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[3],3),
[interpolateWithRegex(`cpqshowfilters`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[4],4),
[interpolateWithRegex(`cpq_qualified`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[5],5),
[interpolateWithRegex(`cpq_summarycart_details`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[6],6),
[interpolateWithRegex(`cpq_preview_cart`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[7],7),
[interpolateWithRegex(`cpq_close_preview_cart`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[8],8),
[interpolateWithRegex(`cpq_spinner`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[10],10),
[interpolateWithRegex(`cpqselectbrowse`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[11],11),
[interpolateWithRegex(`cpq_multisite_new_group_selected`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[12],12),
[interpolateWithRegex(`cpq_multisite_new_group_member_selected`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[14],14),
[interpolateWithRegex(`cpq_cart_updated`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[15],15),
[interpolateWithRegex(`cpq_check_multisite_flow`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[16],16)
        };
        this.pubsubChannel0 = interpolateWithRegex(`cpq_${this.recordId}`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel0,this.pubsubEvent[0]);

        this.pubsubEvent[1] = {
          [interpolateWithRegex(`cpq_update_cart_persistentcartview`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[9],9)
        };
        this.pubsubChannel1 = interpolateWithRegex(`cpq_ui_event_${this.recordId}`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel1,this.pubsubEvent[1]);

        this.pubsubEvent[2] = {
          [interpolateWithRegex(`cpq_update_cartid`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[13],13)
        };
        this.pubsubChannel2 = interpolateWithRegex(`cpq_${this.recordId}_browse`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel2,this.pubsubEvent[2]);

              }

              unregisterEvents(){
                pubsub.unregister(this.pubsubChannel0,this.pubsubEvent[0]);
pubsub.unregister(this.pubsubChannel1,this.pubsubEvent[1]);
pubsub.unregister(this.pubsubChannel2,this.pubsubEvent[2]);

              }
            
              renderedCallback() {
                super.renderedCallback();
                
              }
          }