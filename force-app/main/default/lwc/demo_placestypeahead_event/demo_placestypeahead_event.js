/*
  This custom LWC extends a Type-Ahead component to publish an event whenever an option is selected in 
  the type-ahead.  The Type-Ahead will function as normal, it just generates an event as well through
  the pub-sub framework.

  To make this component as dynamic as possible, it will publish an event to the following channel
  
  OS-Step-Channel-<step-element-name>

  where:
  <step-element-name> is the element name of the Step on which this Type-Ahead has been placed.
  
  @author Joe McMaster
  @version 1.0
    
  History
  =======
  Mar 12, 2021 - v1.0 - Initial version  

  Configuration
  =============
  Create a Type-Ahead component as usual.  Use this LWC as the LWC Component Override

  Notes
  =====
  -Other components will need to explicitly subscribe to the OS-Step-Channel-<step-element-name> to receive any event(s).
  -The event's action name will always be "result"

  THIS SOFTWARE, IS PROVIDED “AS IS” WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED,
  INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
  AND NONINFRINGEMENT.

*/
import { OmniscriptBaseMixin } from 'vlocity_cmt/omniscriptBaseMixin';
import OmniscriptPlacesTypeahead from 'vlocity_cmt/omniscriptPlacesTypeahead';
import pubsub from 'vlocity_cmt/pubsub';

export default class demo_placestypeahead_event extends OmniscriptBaseMixin(OmniscriptPlacesTypeahead) {

    /**
     * Overrides the handleSelect() method of the Type-Ahead
     * 
     * @param event  the selection event
     * 
     * @return A Promise
     */
    handleSelect(event) {

        try {

            return Promise.resolve(
                super.handleSelect(event)
                .then(result => {

                    // Generate a channel name based on the Element Name of the Step
                    let stepChannel = "OS-Step-Channel-" + super.jsonDef.JSONPath.split(":")[0];

                    // Publish the event
                    console.log(super.jsonDef.name + " (" + super.jsonDef.type + ") -> Publishing Event to " + stepChannel);
                    pubsub.fire(stepChannel, "result", event.detail);
                    return result;
                })
                .catch(err => {

                    console.error("Error in demo_placestypeahead_event.handleSelect().Promise -> " + err);                    
                    return err;
                })
            );
        }
        catch (err) {
            console.error("Error in demo_placestypeahead_event.handleSelect() -> " + err);
        }
    }  
}