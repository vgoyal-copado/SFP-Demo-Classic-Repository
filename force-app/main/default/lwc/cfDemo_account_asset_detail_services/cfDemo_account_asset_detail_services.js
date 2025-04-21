import { FlexCardMixin } from "vlocity_cmt/flexCardMixin";
    import {interpolateWithRegex, interpolateKeyValue, fetchCustomLabels } from "vlocity_cmt/flexCardUtility";
    
          import { LightningElement, api, track } from "lwc";
          import { loadStyle } from "lightning/platformResourceLoader";

          import pubsub from "vlocity_cmt/pubsub";
          
          import data from "./definition";
          
          import styleDef from "./styleDefinition";
              
          export default class cfDemo_account_asset_detail_services extends FlexCardMixin(LightningElement){
              @api debug;
              @api recordId;
              
              @track record;

              _regexPattern = /\{([a-zA-Z.0-9_]*)\}/g; //for {} fields by default
              
              connectedCallback() {
                super.connectedCallback();
                this.registerPubSub();
                this.setStyleDefinition(styleDef);
                
                
                this.setDefinition(data);
                this.setAttribute(
                  "class",
                  "card-a5L8Y00001bLrQBEAW"
                );
                this.getCommunityPrefix().then((result) => {
                  loadStyle(this, result +"/servlet/servlet.FileDownload?file=00P8Y00001gaZWb").then(() =>{
                    //Loading Custom CSS.
                  })
                });
                
              }
              
              executeAction(event) {
                let dataset = event.currentTarget.dataset;
                if (dataset && dataset.onchange === 'setValue' ) {
                  this.setValueOnToggle(event);
                }
                if(dataset && typeof dataset.actionIndex !== 'undefined') {
                  let actionIndex = dataset.actionIndex;
                  this.elementIndex = event.currentTarget && event.currentTarget.closest(".cf-vlocity-state") ? event.currentTarget.closest(".cf-vlocity-state").dataset.rindex : null;
                  if (this.records) {
                    this.record = this.records[this.elementIndex];
                  }
                  this.action = {};
                  this.action[actionIndex] = true;
                  this.template.querySelector('.execute-action').executeAction(event, this.card);
                }
                event.stopPropagation();
              }

              registerPubSub() {
                
              }
            
              renderedCallback() {
                super.renderedCallback();
                
              }

              handleEventAction(actionObj, index, event) {
                this.action = {};
                let fromActionObj = actionObj.eventtype === "event" ? event.detail : event;
                actionObj = interpolateWithRegex(
                  actionObj,
                  {action : fromActionObj},
                  this._regexPattern
                );
                if(actionObj.actionData) {
                  actionObj.actionData = interpolateKeyValue(actionObj.actionData, {action : fromActionObj});
                }
                if(fromActionObj) {
                  this.action = {...fromActionObj};
                }
                this.action["listener"+index] = fromActionObj || true;
                let eve = {
                  currentTarget : {
                    action : actionObj
                  }
                }
                this.elementIndex = 0;
                if(typeof actionObj.recordIndex !== "undefined") {
                  this.elementIndex = parseInt(actionObj.recordIndex, 10);
                }
                if(actionObj.eventtype === "event") {
                  let stateElement =
                      event.target && event.target.closest(".cf-vlocity-state")
                        ? event.target.closest(".cf-vlocity-state")
                        : null;
                  if(stateElement && stateElement.dataset.rindex) {
                    this.elementIndex = parseInt(stateElement.dataset.rindex,10);
                  }
                  eve.currentTarget.action.recordIndex = this.elementIndex;
                  event.stopPropagation();
                }
                let actionData = {"action":event};
                let sessionVar = {};
                if(data && data.sessionVars){
                  data.sessionVars.forEach(field => {
                    sessionVar[field.name] = field.val;
                  });
                }
                const sessionVars = {"Session":sessionVar};
                if(this.records && this.records.length > 0) {
                  eve.currentTarget.record = this.records[this.elementIndex];
                  this.record =  {
                    ...this.records[this.elementIndex],
                    ...actionData,
                    ...sessionVars,
                    ...{"Parent":data.Parent},
                    ...{"User":data.User}
                  }                
                } else {
                  this.record =  {
                    ...actionData,
                    ...sessionVars,
                    ...{"Parent":data.Parent},
                    ...{"User":data.User}
                  }    
                }
                let ele = this.template.querySelector(".action-trigger");

                ele.executeAction(eve, this.card);
              }

              disconnectedCallback() {
                super.disconnectedCallback();
                
              }

          }