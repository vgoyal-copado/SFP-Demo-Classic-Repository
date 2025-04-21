/**
 * This class provides some useful functions that can be used within OmniStudio DataRaptor & Integration Procedure
 * formulas.
 *  
 * I recommend you register each function with the org's Custom Metadata to make it easy to use, but this isn't necessary
 * as custom functions can now be called by the built-in FUNCTION() formula.
 *  
 * (Setup -> Custom Metadata Types -> Function Definition -> Manage Function Definitions -> New)
 *
 * @author	Joe McMaster (joe.mcmaster@salesforce.com)
 * @version	1.1
 * 
 *
 * History
 * -------
 * v1.0 - May 21, 2021 - Added ISGUESTUSER() function
 * v1.1 - Nov 15, 2021 - Added GET_SESSION_ID() function
 *
 */
global class CustomDemoFunctions implements vlocity_cmt.VlocityOpenInterface {
    
    /**
	 * Top level call by a OmniStudio DataRaptor or Integration Procedure
	 *
     * @param inputMap  - The input provided by the function call (i.e. contains a single entry called 'arguments')
     * @param outputMap - Any output to be provided back to the DR/IP (must contain a single entry called 'result')
     * @param options   - Any options to aid in the execution of the method although DR/IP doesn't provide any when calling this function
     *
     * @returns true if the method completes successfully, false otherwise
     */ 
	global Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {

        if (methodName == 'isGuestUser') return isGuestUser(inputMap, outputMap, options);
        else if (methodName == 'getCommunityDetails') return getCommunityDetails(inputMap, outputMap, options);
        else if (methodName == 'getSessionId') return getSessionId(inputMap, outputMap, options);
        
        return true;
    }
    
    /**
     * This method determines if the current user session is for a Guest User
     *
     * The method is called by a Formula as follows:
     *
     * ISGUESTUSER()
     *
     * @param inputMap  - The input provided by the function call (i.e. contains a single entry called 'arguments')
     * @param outputMap - Any output to be provided back to the DR/IP (must contain a single entry called 'result')
     * @param options   - Any options to aid in the execution of the method although DR/IP doesn't provide any when calling this function
     *
     * @returns true if the method executes successfully
     */
    private Boolean isGuestUser(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
    		
        outputMap.put('result', Auth.CommunitiesUtil.isGuestUser());

        return true;
    }

    /**
     * This method returns details about the current Community
     *
     * The method is called by a Formula as follows:
     *
     * GET_COMMUNITY_DETAILS()
     *
     * @param inputMap  - The input provided by the function call (i.e. contains a single entry called 'arguments')
     * @param outputMap - Any output to be provided back to the DR/IP (must contain a single entry called 'result')
     * @param options   - Any options to aid in the execution of the method although DR/IP doesn't provide any when calling this function
     *
     * @returns true if the method executes successfully
     */
    private Boolean getCommunityDetails(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
    	
        Map<String, Object> details = new Map<String, Object>();
        details.put('IsGuestUser', Auth.CommunitiesUtil.isGuestUser());
        details.put('CommunityBaseUrl', Site.getBaseUrl());
        details.put('CommunityName', Site.getName());
        details.put('OrgId', UserInfo.getOrganizationId());
        details.put('OrgName', UserInfo.getOrganizationName());

        outputMap.put('result', details);

        return true;
    }
    
    /**
     * This method returns the current session Id
     *
     * The method is called by a Formula as follows:
     *
     * GET_SESSION_ID()
     *
     * @param inputMap  - The input provided by the function call (i.e. contains a single entry called 'arguments')
     * @param outputMap - Any output to be provided back to the DR/IP (must contain a single entry called 'result')
     * @param options   - Any options to aid in the execution of the method although DR/IP doesn't provide any when calling this function
     *
     * @returns true if the method executes successfully
     */
    private Boolean getSessionId(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {        

        outputMap.put('result', UserInfo.getSessionId());

        return true;
    }    
}