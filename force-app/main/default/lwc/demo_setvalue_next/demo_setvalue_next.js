/**
  This custom LWC overrides a Set Values to simply jump to the next OmniScript step (or Action).
  This is useful in situations where you want to conditionally display a "Next" button.  You can
  also set JSON data just as you would with a normal Set Values.
 
  @author Joe McMaster (joe.mcmaster@salesforce.com)
  @version 1.0
 
  History
  =======
  Jan 21, 2021 - v1.0 - Initial version
  Mar 12, 2021 - v1.1 - Code cleanup, now returning a Promise
  
  Configuration
  =============
  -Create a Set Values component as usual.  Use this LWC as the LWC Component Override
  
  THIS SOFTWARE, IS PROVIDED “AS IS” WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED,
  INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
  AND NONINFRINGEMENT.

  */
import { OmniscriptBaseMixin } from "vlocity_cmt/omniscriptBaseMixin";
import OmniscriptSetValues from "vlocity_cmt/omniscriptSetValues";

export default class demo_setvalue_next extends OmniscriptBaseMixin(OmniscriptSetValues) {
    
    /**
     * Overrides the Set Values 'execute' method to move the OmniScript to the next step
     * @param event  The execution event
     * 
     */
    execute(event) {

        try {

            // Perform regular Set Value operations
            return Promise.resolve(
                super.execute(event)
                .then(result => {

                    // Move to the next Step in OmniScript
                    console.log("Moving to next step");
                    super.omniNextStep();
                })
                .catch(err => {
                    console.error("Error in demo_setvalue_next.execute().Promise -> " + err);                    
                    return err;
                })
            );
            
        } catch (err) {
            console.error("Error while executing LWC demo_setvalue_next.execute() -> " + err);
        }
    }
}