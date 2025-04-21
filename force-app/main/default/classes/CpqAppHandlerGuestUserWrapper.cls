/*
  This wraps the CpqAppHandler class so that it can be called by Guest Users in 
  a Salesforce Community.  The CPQ APIs need write access to create orders, etc.
  so this class is defined using "without sharing" which removes security restrictions
  so that anonymous users can successfully call the APIs
  
  @author Joe McMaster
  @version 1.0
    
  History
  =======
  Mar 19, 2021 - v1.0 - Initial version

*/
global without sharing class CpqAppHandlerGuestUserWrapper implements vlocity_cmt.VlocityOpenInterface2 {

    /**
     * Top level call by Vlocity CPQ
     *
     * @param method  - The method to execute
     * @param input   - The input data provided in the call to this method
     * @param output  - The output object where any results will be stored
     * @param options - Any options to aid in the execution of this class
     *
     * @returns true if the method completes successfully, false otherwise
     */ 
    global Object invokeMethod(String methodName, Map<String,Object> input, Map<String,Object> output, Map<String,Object> options) {
        
        vlocity_cmt.CpqAppHandler appHandler = new vlocity_cmt.CpqAppHandler();
        return appHandler.invokeMethod(methodName, input, output, options);
    }
}