/**
  This custom LWC overrides a Set Values to simply jump back the previous OmniScript step.
  This is useful in situations where you want to conditionally display a "Previous" button.  You can
  also set JSON data just as you would with a normal Set Values.
 
  @author Joe McMaster (joe.mcmaster@salesforce.com)
  @version 1.0
 
  History
  =======
  May 13, 2021 - v1.0 - Initial version
   
  Configuration
  =============
  -Create a Set Values component as usual.  Use this LWC as the LWC Component Override
  
  THIS SOFTWARE, IS PROVIDED “AS IS” WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED,
  INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
  AND NONINFRINGEMENT.

  */
import { OmniscriptBaseMixin } from "vlocity_cmt/omniscriptBaseMixin";
import OmniscriptSetValues from "vlocity_cmt/omniscriptSetValues";
import template from "./demo_setvalue_prev.html";

export default class demo_setvalue_prev extends OmniscriptBaseMixin(OmniscriptSetValues) {
    
    /**
     * Overrides the render method so we can use our own template.
     * 
     * @return The SetValues template to use
     */
    render() {
        return template;
    }
    
    /**
     * Overrides the Set Values 'execute' method to move the OmniScript to the previous step
     *
     * @param event  The execution event
     * 
     */
    execute(event) {

        try {

            // Perform regular Set Value operations
            return Promise.resolve(
                super.execute(event)
                .then(result => {

                    // Move to the previous Step in OmniScript
                    console.log("Moving to previous step");
                    super.omniPrevStep();
                })
                .catch(err => {
                    console.error("Error in demo_setvalue_prev.execute().Promise -> " + err);                    
                    return err;
                })
            );
            
        } catch (err) {
            console.error("Error while executing LWC demo_setvalue_prev.execute() -> " + err);
        }
    }
}