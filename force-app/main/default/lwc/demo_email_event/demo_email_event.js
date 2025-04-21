/*
  This custom LWC extends an Email component to publish an event whenever an email is entered in the field
  The Email component will function as normal, it just generates an event as well through
  the pub-sub framework.

  To make this component as dynamic as possible, it will publish an event to the following channel
  
  OS-Step-Channel-<step-element-name>

  where:
  <step-element-name> is the element name of the Step on which this Email component has been placed.
  
  @author Joe McMaster
  @version 1.0
    
  History
  =======
  Apr 28, 2021 - v1.0 - Initial version  

  Configuration
  =============
  Create an Email Field as usual.  Use this LWC as the LWC Component Override

  Notes
  =====
  -Other components will need to explicitly subscribe to the OS-Step-Channel-<step-element-name> to receive any event(s).
  -The event's action name will always be "result"

  THIS SOFTWARE, IS PROVIDED “AS IS” WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED,
  INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
  AND NONINFRINGEMENT.

*/
import { OmniscriptBaseMixin }from 'vlocity_cmt/omniscriptBaseMixin';
import OmniscriptEmail from 'vlocity_cmt/omniscriptEmail';
import pubsub from 'vlocity_cmt/pubsub';

export default class demo_email_event extends OmniscriptBaseMixin(OmniscriptEmail) {

    /**
     * Overrides the setElementValue() method of the Email component to also 
     * generate a pub-sub event
     * 
     * @param json         The JSON to set
     * @param bApi         True when value is being set via an API call, false otherwise (i.e. User Interaction/SetValues)
     * @param bValidation  Indication if validation should be run
     */
    setElementValue(json, bApi, bValidation) {

        try {

            super.setElementValue(json, bApi, bValidation);

            // Generate a channel name based on the Element Name of the Step
            let stepChannel = "OS-Step-Channel-" + super.jsonDef.JSONPath.split(":")[0];

            // Publish the event after a slight delay (50ms)
            // This gives time for the OmniScript JSON data to be updated completely
            setTimeout(() => {
                console.log(super.jsonDef.name + " (" + super.jsonDef.type + ") -> Publishing Event to " + stepChannel);
                pubsub.fire(stepChannel, "result", json);
            }, 50);            

        } catch (err) {
            console.error("Error in demo_email_event.setElementValue() -> " + err);
        }
    }
}