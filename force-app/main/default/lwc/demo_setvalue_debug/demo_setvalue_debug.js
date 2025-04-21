/**
  This custom LWC overrides a Set Values to allow a user to dump debug information
  to the browser console.

  This is useful when trying to debug an OmniScript in a Community for example where
  you don't have easy access to the data.
 
  @author Joe McMaster (joe.mcmaster@salesforce.com)
  @version 1.0
 
  History
  =======
  Sep 21, 2021 - v1.0 - Initial version
    
  Configuration
  =============
  -Create a Set Values component as usual.  Use this LWC as the LWC Component Override
  
  THIS SOFTWARE, IS PROVIDED “AS IS” WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED,
  INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
  AND NONINFRINGEMENT.

  */
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { OmniscriptBaseMixin } from "vlocity_cmt/omniscriptBaseMixin";
import OmniscriptSetValues from "vlocity_cmt/omniscriptSetValues";

export default class demo_setvalue_debug extends OmniscriptBaseMixin(OmniscriptSetValues) {
    
    /**
     * Overrides the Set Values 'execute' method to dump debug information to the browser console
     * 
     * @param event  The execution event
     * 
     */
    execute(event) {

        try {

            console.log("******** OmniScript Debug Info ********");

            console.log("Layout   = " + super.layout);
            console.log("Resuming = " + super.resume);
            console.log("Run Mode = " + super.runMode);
            console.log("OmniScript Definition:");
            console.log(JSON.parse(JSON.stringify(super.scriptHeaderDef)));
            console.log("Step Definition:");
            console.log(JSON.parse(JSON.stringify(super.jsonDef)));
            console.log("OmniScript Runtime Data:");
            console.log(JSON.parse(JSON.stringify(super.jsonData)));

            if (super.elementValue) {
                console.log("Step Data:");
                console.log(JSON.parse(JSON.stringify(super.elementValue)));
            }

            console.log("********** End of Debug Info **********");

            const toastEvent = new ShowToastEvent({
                title: 'Debug',
                message: 'Debug information has been logged to the browser console',
                variant: 'info',
                mode: 'dismissable'
            });
            this.dispatchEvent(toastEvent);

        } catch (err) {
            console.error("Error while executing LWC demo_setvalue_debug.execute() -> " + err);
        }
    }
}