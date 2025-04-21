/**
  This custom LWC presents a button to the user and when clicked, will
  copy a given string to the clipboard.
  
  @author Joe McMaster (joe.mcmaster@salesforce.com)
  @version 1.0
 
  History
  =======
  Oct  5, 2021 - v1.0 - Initial version
    
  Configuration
  =============
  Set the following custom LWC properties in OmniScript to configure this component

  value - (Mandatory) - Contains the value to be copied to the clipboard
  
  THIS SOFTWARE, IS PROVIDED “AS IS” WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED,
  INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
  AND NONINFRINGEMENT.

  */
import { LightningElement, api, track } from 'lwc';
import { OmniscriptBaseMixin } from "vlocity_cmt/omniscriptBaseMixin";

export default class demo_copyButton extends OmniscriptBaseMixin(LightningElement) {
    
    @api value;
    @track msg = "";

    /**
     * Handles the button click and copies the text to the clipboard
     * 
     * @param event  The click event
     */
    handleClick(event) {

        try {
        
            if (this.value) {

                console.log("Copying " + this.value + " to the clipboard");
                this.copyTextToClipboard(this.value);
                this.msg = "Copied";

                // Hide "copied" text after 2 seconds
                let _self = this;
                setTimeout(function() {

                    _self.msg = "";
                }, 2000);
            }
            else console.error("No value to copy to clipboard.");
        }
        catch (err) {
            console.error("Error while executing LWC demo_copyToClipboard.execute() -> " + err);
        }
    }

    /**
     * Copies the given content to the clipboard.  The usual approach in JavaScript to copy content
     * to the clipboard uses navigator.clipboard.writeText(), but this doesn't work from within an LWC.
     * Therefore, we need to use the following hack to accomplish it.  Given it uses a deprecated
     * function (execCommand) it may not work forever!
     * 
     * @param content  The text content to copy to the clipboard
     */
    copyTextToClipboard(content) {

        // Create an input field with the minimum size and place in a not visible part of the screen
        let tempTextAreaField = document.createElement('textarea');
        tempTextAreaField.style = 'position:fixed;top:-5rem;height:1px;width:10px;';

        // Assign the content we want to copy to the clipboard to the temporary text area field
        tempTextAreaField.value = content;

        // Append it to the body of the page
        document.body.appendChild(tempTextAreaField);

        // Select the content of the temporary markup field
        tempTextAreaField.select();

        // Run the copy function to put the content to the clipboard
        document.execCommand('copy');

        // Remove the temporary element from the DOM as it is no longer needed
        tempTextAreaField.remove();
    }
}