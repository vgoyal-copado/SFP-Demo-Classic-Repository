/*
  This custom LWC overrides a Set Values component to render it as a hyperlink instead of a button 
  when placed into an OmniScript Step.
  
  @author Joe McMaster
  @version 1.1
    
  History
  =======
  Jan 12, 2021 - v1.0 - Initial version
  Apr 29, 2021 - v1.1 - Fixed redirect issue when used in a Salseforce Community

  Notes
  =====
  -The Set Values component will still be rendered as a button in the WYSIWYG editor, but as a link during Preview/Live

  Configuration
  =============
  Create a Set Values component as usual.  Use this template as the LWC Component Override
*/
import { OmniscriptBaseMixin } from 'vlocity_cmt/omniscriptBaseMixin';
import OmniscriptSetValues from 'vlocity_cmt/omniscriptSetValues';
import template from "./demo_setvalue_link.html";

export default class SetValuesLink extends OmniscriptBaseMixin(OmniscriptSetValues) {

    /**
     * Overrides the render method so we can use our own template.
     * 
     * @return The SetValues template to use
     */
    render() {
        return template;
    }
}