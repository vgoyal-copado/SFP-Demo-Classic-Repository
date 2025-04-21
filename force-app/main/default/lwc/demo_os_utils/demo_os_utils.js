/*
  This component exposes a number of useful JavaScript utilities for OmniScripts
  
  @author Joe McMaster
  @version 1.3
    
  History
  =======
  Apr  6, 2021 - v1.0 - Initial version
  Apr 22, 2021 - v1.1 - Added getDataJson()
  Jul 21, 2021 - v1.2 - Improved getDataJson() method to support more complex hierarchies of JSON data
  May 25, 2022 - v1.3 - Added better support for LWC Extensions vs. Custom LWC

  Configuration
  =============
  This component does not need to be configured directly, but can be leveraged by any other LWC by using
  the following pattern:

  import { getOmniScriptElementValue, .... } from 'c/demo_os_utils'

  THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 
*/

/**
 * Returns the OmniScript Header Definition
 * 
 * @param osComponent The OmniScript Component
 * 
 * @return The OmniScript Header Definition
 */
function getHeaderDef(osComponent) {

  if (osComponent.scriptHeaderDef) return osComponent.scriptHeaderDef; // Extension of Base LWC
  else return osComponent.omniScriptHeaderDef; // Custom LWC
}

/**
 * Returns the OmniScript Metadata Definition
 * 
 * @param osComponent The OmniScript Component
 * 
 * @return The OmniScript Metadata Definition
 */
function getJsonDef(osComponent) {

  if (osComponent.jsonDef) return osComponent.jsonDef; // Extension of Base LWC
  else return osComponent.omniJsonDef; // Custom LWC
}

/**
 * Returns the OmniScript runtime JSON data from the OmniScript
 * 
 * @param osComponent The OmniScript Component
 * 
 * @return The OmniScript JSON Data
 */
function getFullDataJson(osComponent) {

  if (osComponent.jsonData) return osComponent.jsonData; // Extension of Base LWC
  else return osComponent.omniJsonData; // Custom LWC
}

/**
 * Locates the Data JSON for the given component (if there is any)
 * 
 * @param osComponent  The OmniScript Component
 * 
 * @return The Data JSON currently associated to this component
 */
function getDataJson(osComponent) {

  // Determine the Path to the JSON data we should look for
  let jsonPath = getJsonDef(osComponent).JSONPath.split(":"); // for example: AddOnSelections:AddOnContainer|1:SelectedAddOns

  // Dig through the JSON to find the data
  let jsonData = getFullDataJson(osComponent);

  for (let elementName of jsonPath) {

    // See if the element name contains a pipe (|) which signifies the data could be a list and we need to work with
    // a specific node in the list
    let elementIndex = -1;
    let elementParts = elementName.split('|');
    if (elementParts.length > 1) {
      elementName = elementParts[0];
      elementIndex = Number(elementParts[1]);
    }

    if (jsonData[elementName]) {

      jsonData = jsonData[elementName]; // Getting warmer

      // If we are to get a particular index and we have a list, grab it
      if (elementIndex >= 0 && Array.isArray(jsonData)) jsonData = jsonData[elementIndex - 1];
    } else return undefined; // Nothing found
  }

  return jsonData;
}

/**
 * Retrieves the given element value from an OmniScript SetValues component (under the elementValueMap) and
 * takes care of any merge fields.
 * 
 * @param osComponent The OmniScript SetValues Component calling this method
 * @param elementName The name of the element to retrieve
 * 
 * @return The value of the element or undefined if it doesn't exist
 */
function getOmniScriptElementValue(osComponent, elementName) {

  let elements = osComponent.jsonDef.propSetMap.elementValueMap;
  if (elements && elementName in elements) {

    // handleMergeFieldUtil(<raw-string>, <os-data>, <os-labels>, ???)
    // example I found regarding 4th parameter -> this.isRepeatNotation(this.jsonDef.propSetMap.elementValueMap) ? this.jsonDef.JSONPath : null
    let value = osComponent.handleMergeFieldUtil(elements[elementName], getFullDataJson(osComponent), getHeaderDef(osComponent).labelMap, null);

    // Try to convert into a Map or List if this is really a JSON string
    if (typeof value === "string") {
      try {
        value = JSON.parse(value);
      } catch (err) {} // not a JSON string, that's ok!
    }

    //console.info("Found " + elementName + " (" + typeof value + ") = " + value);
    return value;
  }
}

/**
 * Evaluates a JavaScript expression provided as a string.  This is slightly safer than using the
 * JavaScript eval() method.
 * 
 * @param expression  The expression to evaluate
 * 
 * @returns true or false depending on the result of the expression
 */
function evaluateExpression(expression) {

  return Function('"use strict";return (' + expression + ')')();
}


// Methods that can be imported into your LWC
export {
  getOmniScriptElementValue,
  evaluateExpression,
  getJsonDef,
  getHeaderDef,
  getDataJson,
  getFullDataJson
};