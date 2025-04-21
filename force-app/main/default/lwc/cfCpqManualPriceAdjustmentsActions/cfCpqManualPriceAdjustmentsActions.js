import { FlexCardMixin } from "vlocity_cmt/flexCardMixin";
    import { CurrentPageReference } from 'lightning/navigation';
    import {interpolateWithRegex, interpolateKeyValue, loadCssFromStaticResource } from "vlocity_cmt/flexCardUtility";
    
          import { LightningElement, api, track, wire } from "lwc";
          import pubsub from "vlocity_cmt/pubsub";
          import { getRecord } from "lightning/uiRecordApi";
          
          import data from "./definition";
          
          import styleDef from "./styleDefinition";
              
          export default class cfCpqManualPriceAdjustmentsActions extends FlexCardMixin(LightningElement){
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
              @track Label={CPQPolicy:"Policy",
        CPQSelectPolicy:"Select Policy",
        CPQDuration:"Duration",
        CPQMessageWhenValueMissing:"This field is required",
        CPQSelectDuration:"Select Duration",
        CPQLimitAdjustmentTime:"Limit Adjustment Time",
        Add:"Add",
        CPQAdjustBy:"Adjust By"
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
          [interpolateWithRegex(`baseinputvaluechange`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[0],0)
        };
        this.pubsubChannel0 = interpolateWithRegex(`AdjustmentMode`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel0,this.pubsubEvent[0]);

        this.pubsubEvent[1] = {
          [interpolateWithRegex(`baseinputvaluechange`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[1],1)
        };
        this.pubsubChannel1 = interpolateWithRegex(`ChildAdjustmentValue`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel1,this.pubsubEvent[1]);

        this.pubsubEvent[2] = {
          [interpolateWithRegex(`baseinputvaluechange`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[2],2)
        };
        this.pubsubChannel2 = interpolateWithRegex(`ChildAdjustmentCode`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel2,this.pubsubEvent[2]);

        this.pubsubEvent[3] = {
          [interpolateWithRegex(`cpq_chargetype`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[3],3)
        };
        this.pubsubChannel3 = interpolateWithRegex(`cpq`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel3,this.pubsubEvent[3]);

        this.pubsubEvent[4] = {
          [interpolateWithRegex(`valuechange`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[4],4)
        };
        this.pubsubChannel4 = interpolateWithRegex(`ChargeSignType`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel4,this.pubsubEvent[4]);

        this.pubsubEvent[5] = {
          [interpolateWithRegex(`baseinputvaluechange`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[5],5)
        };
        this.pubsubChannel5 = interpolateWithRegex(`LimitAdjustmentTime`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel5,this.pubsubEvent[5]);

        this.pubsubEvent[6] = {
          [interpolateWithRegex(`baseinputvaluechange`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[6],6)
        };
        this.pubsubChannel6 = interpolateWithRegex(`AdjustmentPlan`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel6,this.pubsubEvent[6]);

        this.pubsubEvent[7] = {
          [interpolateWithRegex(`baseinputvaluechange`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[7],7)
        };
        this.pubsubChannel7 = interpolateWithRegex(`AdjustmentPolicy`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel7,this.pubsubEvent[7]);

        this.pubsubEvent[8] = {
          [interpolateWithRegex(`cpq_adjustment_apply_child`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[8],8)
        };
        this.pubsubChannel8 = interpolateWithRegex(`cpq_${this.recordId}`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel8,this.pubsubEvent[8]);

              }

              unregisterEvents(){
                pubsub.unregister(this.pubsubChannel0,this.pubsubEvent[0]);
pubsub.unregister(this.pubsubChannel1,this.pubsubEvent[1]);
pubsub.unregister(this.pubsubChannel2,this.pubsubEvent[2]);
pubsub.unregister(this.pubsubChannel3,this.pubsubEvent[3]);
pubsub.unregister(this.pubsubChannel4,this.pubsubEvent[4]);
pubsub.unregister(this.pubsubChannel5,this.pubsubEvent[5]);
pubsub.unregister(this.pubsubChannel6,this.pubsubEvent[6]);
pubsub.unregister(this.pubsubChannel7,this.pubsubEvent[7]);
pubsub.unregister(this.pubsubChannel8,this.pubsubEvent[8]);

              }
            
              renderedCallback() {
                super.renderedCallback();
                
              }
          }