import { FlexCardMixin } from "vlocity_cmt/flexCardMixin";
    import { CurrentPageReference } from 'lightning/navigation';
    import {interpolateWithRegex, interpolateKeyValue, loadCssFromStaticResource } from "vlocity_cmt/flexCardUtility";
    
          import { LightningElement, api, track, wire } from "lwc";
          import pubsub from "vlocity_cmt/pubsub";
          import { getRecord } from "lightning/uiRecordApi";
          import { OmniscriptBaseMixin } from "vlocity_cmt/omniscriptBaseMixin";
          import data from "./definition";
          
          import styleDef from "./styleDefinition";
              
          export default class cfCpqProductSearch extends FlexCardMixin(OmniscriptBaseMixin(LightningElement)){
              currentPageReference;        
              @wire(CurrentPageReference)
              setCurrentPageReference(currentPageReference) {
                this.currentPageReference = currentPageReference;
              }
              @api debug;
              @api recordId;
              @api objectApiName;
              @track _omniSupportKey = 'cfCpqProductSearch';
                  @api get omniSupportKey() {
                    return this._omniSupportKey;
                  }
                  set omniSupportKey(parentRecordKey) {
                    this._omniSupportKey = this._omniSupportKey  + '_' + parentRecordKey;
                  }
              @track record;
              @track _sessionApiVars = {};
              @track Label={CPQSearch:"Search",
        CPQProduct:"Product",
        CPQNoResultsFoundFor:"No results found for"
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
                    this.omniSaveState(this.records,this.omniSupportKey,true);
                    

                  this.unregisterEvents();
              }

              registerEvents() {
                
        this.pubsubEvent[0] = {
          [interpolateWithRegex(`basetypeaheadinputchange`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[0],0),
[interpolateWithRegex(`baseinputvaluechange`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[2],2)
        };
        this.pubsubChannel0 = interpolateWithRegex(`type`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel0,this.pubsubEvent[0]);

        this.pubsubEvent[1] = {
          [interpolateWithRegex(`cpqresponse`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[1],1),
[interpolateWithRegex(`apply_filter`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[3],3),
[interpolateWithRegex(`productlist`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[5],5),
[interpolateWithRegex(`selectedproductsevent`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[7],7),
[interpolateWithRegex(`result`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[8],8),
[interpolateWithRegex(`cpq_catalog_item_select_browse`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[9],9),
[interpolateWithRegex(`cpq_catalog_item_select_cart`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[10],10),
[interpolateWithRegex(`offersearchselect`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[13],13),
[interpolateWithRegex(`resultselect`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[16],16)
        };
        this.pubsubChannel1 = interpolateWithRegex(`cpq_${this.recordId}`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel1,this.pubsubEvent[1]);

        this.pubsubEvent[2] = {
          [interpolateWithRegex(`basetypeaheadinputchange`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[4],4),
[interpolateWithRegex(`baseinputvaluechange`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[6],6)
        };
        this.pubsubChannel2 = interpolateWithRegex(`multiselectproductlist`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel2,this.pubsubEvent[2]);

        this.pubsubEvent[3] = {
          [interpolateWithRegex(`basetypeaheadinputchange`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[11],11),
[interpolateWithRegex(`baseinputvaluechange`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[12],12)
        };
        this.pubsubChannel3 = interpolateWithRegex(`offers`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel3,this.pubsubEvent[3]);

        this.pubsubEvent[4] = {
          [interpolateWithRegex(`basetypeaheadinputchange`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[14],14),
[interpolateWithRegex(`baseinputvaluechange`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[15],15)
        };
        this.pubsubChannel4 = interpolateWithRegex(`typeCart`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel4,this.pubsubEvent[4]);

              }

              unregisterEvents(){
                pubsub.unregister(this.pubsubChannel0,this.pubsubEvent[0]);
pubsub.unregister(this.pubsubChannel1,this.pubsubEvent[1]);
pubsub.unregister(this.pubsubChannel2,this.pubsubEvent[2]);
pubsub.unregister(this.pubsubChannel3,this.pubsubEvent[3]);
pubsub.unregister(this.pubsubChannel4,this.pubsubEvent[4]);

              }
            
              renderedCallback() {
                super.renderedCallback();
                
              }
          }