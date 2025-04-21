/**
 * This class provides some useful mathmatical functions that can be used within OmniStudio DataRaptor & Integration Procedure
 * formulas.
 *  
 * I recommend you register each function with the org's Custom Metadata to make it easy to use, but this isn't necessary
 * as custom functions can now be called by the built-in FUNCTION() formula.
 *  
 * (Setup -> Custom Metadata Types -> Function Definition -> Manage Function Definitions -> New)
 *
 * @author	Joe McMaster (joe.mcmaster@salesforce.com)
 * @version	1.0
 * 
 *
 * History
 * -------
 * v1.0 - Oct 12, 2018 - Initial Version with RANDOM() function
 * 
 */
global class CustomMathFunctions implements vlocity_cmt.VlocityOpenInterface {
    
    /**
	 * Top level call by an OmniStudio DataRaptor or Integration Procedure
	 *
     * @param inputMap  - The input provided by the function call (i.e. contains a single entry called 'arguments')
     * @param outputMap - Any output to be provided back to the DR/IP (must contain a single entry called 'result')
     * @param options   - Any options to aid in the execution of the method although DR/IP doesn't provide any when calling this function
     *
     * @returns true if the method completes successfully, false otherwise
     */ 
	global Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {

        if (methodName == 'random') outputMap.put('result', random((List<Object>)inputMap.get('arguments')));
        
        return true;
    }
    
    /**
     * This method will generate a random number (Double) between 0.0 and 1.0
     *
     * The method is called by a Formula as follows:
     *
     * RANDOM()
     * 
     * @param args - The list of input arguments provided to the function
     *
     * @returns The length of the string
     */     
     private Double random(List<Object> args) {
             
        return Math.random();

     }
}