import { FlexCardMixin } from "vlocity_cmt/flexCardMixin";
    import { CurrentPageReference } from 'lightning/navigation';
    import {interpolateWithRegex, interpolateKeyValue, loadCssFromStaticResource } from "vlocity_cmt/flexCardUtility";
    
          import { LightningElement, api, track, wire } from "lwc";
          import pubsub from "vlocity_cmt/pubsub";
          import { getRecord } from "lightning/uiRecordApi";
          import { OmniscriptBaseMixin } from "vlocity_cmt/omniscriptBaseMixin";
          import data from "./definition";
          
          import styleDef from "./styleDefinition";
              
          export default class cfCpqChangeOfPlanGroups extends FlexCardMixin(OmniscriptBaseMixin(LightningElement)){
              currentPageReference;        
              @wire(CurrentPageReference)
              setCurrentPageReference(currentPageReference) {
                this.currentPageReference = currentPageReference;
              }
              @api debug;
              @api recordId;
              @api objectApiName;
              @track _omniSupportKey = 'cfCpqChangeOfPlanGroups';
                  @api get omniSupportKey() {
                    return this._omniSupportKey;
                  }
                  set omniSupportKey(parentRecordKey) {
                    this._omniSupportKey = this._omniSupportKey  + '_' + parentRecordKey;
                  }
              @track record;
              @track _sessionApiVars = {};
              @track Label={CPQNoAssetGroupsMessage:"No Asset Groups Found"
        };
              pubsubEvent = [];
              customEvent = [];
              
              connectedCallback() {
                super.connectedCallback();
                this.setStyleDefinition(styleDef);
                data.Session = {} //reinitialize on reload
                
                
                this.customLabels = this.Label;
                      
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
          [interpolateWithRegex(`baseinputvaluechange`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[0],0)
        };
        this.pubsubChannel0 = interpolateWithRegex(`cpq_cop_groups_radio_${this.recordId}`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel0,this.pubsubEvent[0]);

              }

              unregisterEvents(){
                pubsub.unregister(this.pubsubChannel0,this.pubsubEvent[0]);

              }
            
              renderedCallback() {
                super.renderedCallback();
                
              }
          }