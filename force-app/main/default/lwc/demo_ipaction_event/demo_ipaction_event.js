/*
  This custom LWC extends an Integration Procedure Action to allow it to be triggered by the pub-sub framework.

  To make this component as dynamic as possible, it will automatically register an event listener on the following channel
  
  OS-Step-Channel-<step-element-name>

  where:
  <step-element-name> is the element name of the Step on which this Integration Procedure has been placed.
  
  @author Joe McMaster
  @version 1.0
    
  History
  =======
  Mar 12, 2021 - v1.0 - Initial version  

  Configuration
  =============
  Create an Integration Procedure Action as usual.  Use this LWC as the LWC Component Override

  Notes
  =====
  -Other components will need to explicitly publish to the OS-Step-Channel-<step-element-name>
  -The event's action name is assumed to be "result"

  THIS SOFTWARE, IS PROVIDED “AS IS” WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED,
  INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
  AND NONINFRINGEMENT.

*/
import { OmniscriptBaseMixin } from 'vlocity_cmt/omniscriptBaseMixin';
import OmniscriptIpAction from 'vlocity_cmt/omniscriptIpAction';
import pubsub from 'vlocity_cmt/pubsub';

export default class demo_ipaction_event extends OmniscriptBaseMixin(OmniscriptIpAction) {

    /**
     * Overrides the connectedCallback() method of the IP Action to register 
     * for events.
     * 
     */
    connectedCallback() {
        
        super.connectedCallback();

        // Generate a channel name based on the Element Name of the Step
        let stepChannel = "OS-Step-Channel-" + super.jsonDef.JSONPath.split(":")[0];        

        // Register for events
        console.log(super.jsonDef.name + " (" + super.jsonDef.type + ") -> Subscribing to " + stepChannel);
        pubsub.register(stepChannel, { result: this.executeOnEvent.bind(this) });
    }
  
    /**
     * Triggers this IP Action based on an event
     * 
     * @param event  The event that triggered this IP Action
     */
    executeOnEvent(event) {

        try {
        
            console.log(super.jsonDef.name + " (" + super.jsonDef.type + ") -> Received Event -> " + JSON.stringify(event));
            super.execute();
        }
        catch(err) {
            console.error("Error in demo_ipaction_event.executeOnEvent() -> " + err);
        }
    }

    /**
     * Overrides the disconnectedCallback() method of the IP Action to unregister
     * from events.
     * 
     */
    disconnectCallback() {

        let stepChannel = "OS-Step-Channel-" + super.jsonDef.JSONPath.split(":")[0];

        // Unregister from events
        console.log(super.jsonDef.name + " (" + super.jsonDef.type + ") -> Unsubscribing from " + stepChannel);
        pubsub.unregister(stepChannel, { result: this.executeOnEvent.bind(this) });

        super.disconnectCallback();
    }
}