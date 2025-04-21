/**
 * This class contains unit tests for validating the behavior of the
 * CustomStringFunction Apex class.
 *
 * @author	Joe McMaster (joe.mcmaster@salesforce.com)
 * @version	1.2
 *
 *
 * History
 * -------
 * v1.0 - 08-09-2018 - Initial Version with SPLIT() function
 * v1.1 - 10-01-2018 - Added STARTSWITH() function
 * v1.2 - 03-06-2019 - Added REPLACE() function 
 *
 */
@isTest
private class CustomStringFunctionsTest {

	static String SIMPLE_INPUT  = 'Mail;Email;Phone';
	static String SIMPLE_REGEX  = ';';
	
    static testMethod void split_simpleTest() {
        
        List<String> args = new List<String>();
        args.add(SIMPLE_INPUT);
        args.add(SIMPLE_REGEX);
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomStringFunctions csf = new CustomStringFunctions();
        Boolean retValue = csf.invokeMethod('split', inputMap, outputMap, null);
        String result = JSON.serializePretty(outputMap.get('result'));
        
        // Logging
		System.debug(result);
		
		// Validation
		System.assert(retValue, 'SPLIT() invokeMethod returned false when it should return true');
    }
    
    static testMethod void split_exceptionTest() {
        
        List<String> args = new List<String>();
        args.add(SIMPLE_INPUT);
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomStringFunctions csf = new CustomStringFunctions();
        
        try {
        	Boolean retValue = csf.invokeMethod('split', inputMap, outputMap, null);
        }
        catch (Exception e) {
        	
        	// We expect an exception as we called the method without enough arguments.
        	// This test is needed for 100% code coverage
        	System.debug('SPLIT() Received Expected Exception -> ' + e.getMessage());
        	
        	return;
        }
	
		// Validation - if we make it here, the test failed
		System.assert(false);
    }
    
    static testMethod void startswith_simpleTest() {
        
        List<String> args = new List<String>();
        args.add(SIMPLE_INPUT);
        args.add(SIMPLE_INPUT);
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomStringFunctions csf = new CustomStringFunctions();
        Boolean retValue = csf.invokeMethod('startswith', inputMap, outputMap, null);
        Boolean result = (Boolean)outputMap.get('result');
        
        // Logging
		System.debug(result);
		
		// Validation
		System.assert(retValue, 'STARTSWITH() invokeMethod returned false when it should return true');
		System.assert(result, 'STARTSWITH() returned false when it should return true');
    }
       
    static testMethod void startswith_exceptionTest() {
        
        List<String> args = new List<String>();
        args.add(SIMPLE_INPUT);
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomStringFunctions csf = new CustomStringFunctions();
        
        try {
        	Boolean retValue = csf.invokeMethod('startswith', inputMap, outputMap, null);
        }
        catch (Exception e) {
        	
        	// We expect an exception as we called the method without enough arguments.
        	// This test is needed for 100% code coverage
        	System.debug('STARTSWITH() Received Expected Exception -> ' + e.getMessage());
        	
        	return;
        }
                
		
		// Validation - if we make it here, the test failed
		System.assert(false);
    }

    static testMethod void replace_simpleTest() {
        
        List<String> args = new List<String>();
        args.add('abcdefgabc');
        args.add('abc');
        args.add('xyz');
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomStringFunctions csf = new CustomStringFunctions();
        Boolean retValue = csf.invokeMethod('replace', inputMap, outputMap, null);
        String result = (String)outputMap.get('result');
        
        // Logging
		System.debug(result);
		
		// Validation
		System.assert(retValue, 'REPLACE() invokeMethod returned false when it should return true');		
    }
    
    static testMethod void replace_exceptionTest() {
        
        List<String> args = new List<String>();
        args.add('abcdefgabc');
        args.add('abc');
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomStringFunctions csf = new CustomStringFunctions();
        
        try {
        	Boolean retValue = csf.invokeMethod('replace', inputMap, outputMap, null);
        }
        catch (Exception e) {
        	
        	// We expect an exception as we called the method without enough arguments.
        	// This test is needed for 100% code coverage
        	System.debug('REPLACE() Received Expected Exception -> ' + e.getMessage());
        	
        	return;
        }
                
		
		// Validation - if we make it here, the test failed
		System.assert(false);
    }    
}