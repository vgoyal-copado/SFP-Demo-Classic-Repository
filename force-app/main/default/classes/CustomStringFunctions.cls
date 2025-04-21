/**
 * This class provides some useful functions that can be used within OmniStudio DataRaptor & Integration Procedure
 * formulas to manipulate strings.
 *  
 * I recommend you register each function with the org's Custom Metadata to make it easy to use, but this isn't necessary
 * as custom functions can now be called by the built-in FUNCTION() formula.
 *  
 * (Setup -> Custom Metadata Types -> Function Definition -> Manage Function Definitions -> New)
 *
 * @author	Joe McMaster (joe.mcmaster@salesforce.com)
 * @version	1.9
 *
 * History
 * -------
 * v1.0 - Sep  8, 2018 - Initial Version with SPLIT() function
 * v1.1 - Oct  1, 2018 - Added STARTSWITH() function
 * v1.2 - Mar  3, 2019 - Added REPLACE() function
 * v1.3 - Feb 23, 2021 - Added TONUMBER() function
 * v1.4 - Mar 17, 2021 - Added ENCRYPT() and ENCRYPT_IF_NECESSARY() functions
 * v1.5 - May 18, 2021 - Added REPLACEALL(), REPLACEFIRST(), DECRYPT(), and DECRYPT_IF_NECESSARY() functions
 * v1.6 - Sep 17, 2021 - Added LENGTH(), URLENCODE() function
 * v1.7 - Mar  2, 2022 - Added ISNUMBER() function
 * v1.8 - Jun  3, 2022 - Added support for Callable interface
 * v1.9 - Nov 29, 2022 - Added some protective code to the replace functions
 */
global class CustomStringFunctions implements vlocity_cmt.VlocityOpenInterface, Callable {
    
    /**
	 * Top level call by an OmniStudio DataRaptor or Integration Procedure (OmniStudio)
	 *
     * @param action  - The action/method to execute
     * @param args    - The input, output, and options arguments
     *
     * @returns true if the method completes successfully, false otherwise
     */ 
     public Object call(String action, Map<String, Object> args) {

        return invokeMethod(action, (Map<String, Object>)args.get('input'), (Map<String, Object>)args.get('output'), (Map<String, Object>)args.get('options'));
     }

    /**
	 * Top level call by an OmniStudio DataRaptor or Integration Procedure (OmniStudio for Vlocity)
	 *
     * @param inputMap  - The input provided by the function call (i.e. contains a single entry called 'arguments')
     * @param outputMap - Any output to be provided back to the DR/IP (must contain a single entry called 'result')
     * @param options   - Any options to aid in the execution of the method although DR/IP doesn't provide any when calling this function
     *
     * @returns true if the method completes successfully, false otherwise
     */ 
	global Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {

        if (methodName == 'length')                  outputMap.put('result', length((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'split')              outputMap.put('result', split((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'startsWith')         outputMap.put('result', startsWith((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'replace')            outputMap.put('result', replace((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'replaceAll')         outputMap.put('result', replaceAll((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'replaceFirst')       outputMap.put('result', replaceFirst((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'toNumber')           outputMap.put('result', toNumber((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'isNumber')           outputMap.put('result', isNumber((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'urlEncode')          outputMap.put('result', urlEncode((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'encrypt')            outputMap.put('result', encrypt((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'encryptIfNecessary') outputMap.put('result', encryptIfNecessary((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'denrypt')            outputMap.put('result', decrypt((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'decryptIfNecessary') outputMap.put('result', decryptIfNecessary((List<Object>)inputMap.get('arguments')));        
        
        return true;
    }
    
    /**
     * This method will return the length of a string
     *
     * The method is called by Formula as follows:
     *
     * LENGTH(<input-string>)
     * 
     * @param args - The list of input arguments provided to the function
     *
     * @returns The length of the string
     */     
     private Integer length(List<Object> args) {
             
     	// We should only ever have 1 argument passed to this function
         if (args.size() == 1) {
             
             // Force any object first to a String and then count the characters
             return String.valueOf(args.get(0)).length();
         }

         InvalidParameterValueException e = new InvalidParameterValueException('LENGTH', 'The function must be called with a single argument');
         throw e;
     }

    /**
     * This method converts a simple string value into a JSON list by splitting the source string
     * using a specified regular expression.
     *
     * The method is called by a Formula as follows:
     *
     * SPLIT(<source>, <regex>)
     *
     * where,
     * <source>  the end-to-end string to split
     * <regex>   a regular expression to use in splitting the <source> string
     * 
     * For example:
     *
     * SPLIT('Mail;Email;Phone', ';')
     * 
     * Returns:
     *
     * [
     *   "Mail",
     *   "Email",
     *   "Phone"     
     * ]
     *
     * @param args - The list of input arguments provided to the function
     *
     * @returns The list
     */
    private List<Object> split(List<Object> args) {
    		
		List<Object> theList = new List<Object>();
		
		String source;
		String regex;
		
		// Handle SPLIT(<source>, <regex>)
		if (args.size() >= 2) {
 			source = String.valueOf(args.get(0));
 			regex  = String.valueOf(args.get(1));
		}
		else {
			InvalidParameterValueException e = new InvalidParameterValueException('SPLIT', 'The function must be called with at least 2 arguments');
			throw e;
		}
    	
    	// Split the string
    	String[] parts = source.split(regex);
    	for (String part : parts) theList.add(part);
    	    	
    	return theList;
    }
    
    /**
     * This method determines if the given string starts with the given substring
     *
     * The method is called by a Formula as follows:
     *
     * STARTSWITH(<source>, <match>)
     *
     * where,
     * <source>  the full string to test
     * <match>   the substring to test against the <source> string
     
     * @param args - The list of input arguments provided to the function
     *
     * @returns true if the string starts with the given substring, false otherwise
     */
     private Boolean startsWith(List<Object> args) {
     	
		String source;
		String match;
     	
     	// Handle STARTSWITH(<source>, <match>)
		if (args.size() >= 2) {
 			source = String.valueOf(args.get(0));
 			match  = String.valueOf(args.get(1));
		}
		else {
			InvalidParameterValueException e = new InvalidParameterValueException('STARTSWITH', 'The function must be called with at least 2 arguments');
			throw e;
		}
		
		// Test if <source> starts with <match>
		return source.startsWith(match);
     }

    /**
     * This method replaces all occurrences of a substring with a replacement string
     *
     * The method is called by Formula as follows:
     *
     * REPLACE(<source>, <match>, <replacement>)
     *
     * where,
     * <source>        the full string to search
     * <match>         the substring to look for in the <source> string
     * <replacemement> the replacement string to use when a <match> is found
     * 
     * @param args - The list of input arguments provided to the function
     *
     * @returns A new string with all replacements made
     */
     private String replace(List<Object> args) {
     	
     	// Handle REPLACE(<source>, <match>, <replacement>)
		if (args.size() == 3) {
            if (args[0] == null) return null;  // avoid hard exception if no source string was provided
            else if (args[1] == null || args[2] == null) return String.valueOf(args[0]); // avoid hard exception if no match/replacement is provided
            else return String.valueOf(args[0]).replace(String.valueOf(args[1]), String.valueOf(args[2]));
        }

		InvalidParameterValueException e = new InvalidParameterValueException('REPLACE', 'The function must be called with at 3 arguments');
		throw e;
     }

    /**
     * This method replaces all occurrences of a substring that matches the given pattern
     * with a replacement string
     *
     * The method is called by Formula as follows:
     *
     * REPLACEALL(<source>, <regex>, <replacement>)
     *
     * where,
     * <source>        the full string to search
     * <regex>         the regular expression used to identify patterns in the <source> string
     * <replacemement> the replacement string to use
     * 
     * @param args - The list of input arguments provided to the function
     *
     * @returns A new string with all replacements made
     */
     private String replaceAll(List<Object> args) {
     	
     	// Handle REPLACEALL(<source>, <regex>, <replacement>)
		if (args.size() == 3) {
            if (args[0] == null) return null;  // avoid hard exception if no source string was provided
            else if (args[1] == null || args[2] == null) return String.valueOf(args[0]); // avoid hard exception if no regex/replacement is provided
            else return String.valueOf(args[0]).replaceAll(String.valueOf(args[1]), String.valueOf(args[2]));
        }

		InvalidParameterValueException e = new InvalidParameterValueException('REPLACEALL', 'The function must be called with at 3 arguments');
		throw e;
     }     

    /**
     * This method replaces the first occurrence of a substring that matches the given pattern
     * with a replacement string
     *
     * The method is called by Formula as follows:
     *
     * REPLACEFIRST(<source>, <regex>, <replacement>)
     *
     * where,
     * <source>        the full string to search
     * <regex>         the regular expression used to identify patterns in the <source> string
     * <replacemement> the replacement string to use
     * 
     * @param args - The list of input arguments provided to the function
     *
     * @returns A new string with all replacements made
     */
     private String replaceFirst(List<Object> args) {
     	
     	// Handle REPLACEFIRST(<source>, <regex>, <replacement>)
		if (args.size() == 3) {
            if (args[0] == null) return null;  // avoid hard exception if no source string was provided
            else if (args[1] == null || args[2] == null) return String.valueOf(args[0]); // avoid hard exception if no regex/replacement is provided
            else return String.valueOf(args[0]).replaceFirst(String.valueOf(args[1]), String.valueOf(args[2]));
        }

		InvalidParameterValueException e = new InvalidParameterValueException('REPLACEFIRST', 'The function must be called with at 3 arguments');
		throw e;
     }

    /**
     * This method does its best to convert a string to a number.  This is useful for stripping currency symbols from 
     * values.  It will remove any characters from the incoming String that are not digits, decimals, or negative signs
     *
     * The method is called by Formula as follows:
     *
     * TONUMBER(<input-string>)
     *
     * where,
     * <input-string>  the string to convert
     * 
     * For example:
     *
     * "5"     ==> 5
     * "0.01"  ==> 0.01
     * "$2500" ==> 2500
     * "-$23"  ==> -23
     * ""      ==> throws InvalidParameterValueException
     * "abcd"  ==> throws InvalidParameterValueException
     * 
     * @param args - The list of input arguments provided to the function
     *
     * @returns A number that the string converts to
     */
     private Double toNumber(List<Object> args) {
     
         // We should only ever have 1 argument passed to this function
         if (args.size() == 1) {
             
             // Force any object first to a String and then replace any non-digits/decimal/negative characters
             String str = String.valueOf(args.get(0)).replaceAll('[^\\d.-]', '');
             return Double.valueOf(str);
         }
         InvalidParameterValueException e = new InvalidParameterValueException('TONUMBER', 'The function must be called with a single argument');
         throw e;
     }
     
    /**
     * This method determines if the incoming value is a Number
     *
     * The method is called by Formula as follows:
     *
     * ISNUMBER(<input-string>)
     *
     * where,
     * <input-string>  the string to test
     * 
     * For example:
     *
     * "5"     ==> true
     * "0.01"  ==> true     
     * "-23"   ==> true
     * "0"     ==> true
     * "$2500" ==> false
     * ""      ==> false
     * "abcd"  ==> false
     " null    ==> false
     * 
     * @param args - The list of input arguments provided to the function
     *
     * @returns True if the string is a number, false otherwise
     */
     private Boolean isNumber(List<Object> args) {
     
         // We should only ever have 1 argument passed to this function
         if (args.size() == 1) {
             
             try {
             	Decimal.valueOf(String.valueOf(args.get(0)));
             }
             catch (Exception e) {
             	return false;
             }
             
             // If we make it here, it's a number
             return true;             
         }
         InvalidParameterValueException e = new InvalidParameterValueException('ISNUMBER', 'The function must be called with a single argument');
         throw e;
     }
     
    /**
     * This method URL Encodes a string into the application/x-www-form-urlencoded format
     *
     * The method is called by a Formula as follows:
     *
     * URLENCODE(<input-string>)
     *
     * where,
     * <input-string>  the string to encode
     * 
     * @param args - The list of input arguments provided to the function
     *
     * @returns The URL Encoded String
     */
     private String urlEncode(List<Object> args) {
     
         // We should only ever have 1 argument passed to this function
         if (args.size() == 1) {
             
             // Force any object first to a String and then encode it
             return EncodingUtil.urlEncode(String.valueOf(args.get(0)), 'UTF-8');
         }
         InvalidParameterValueException e = new InvalidParameterValueException('URLENCODE', 'The function must be called with a single argument');
         throw e;
     }

    /**
     * This method will encrypt sensitive data
     *
     * The method is called by Formula as follows:
     *
     * ENCRYPT(<input-string>)
     *
     * where,
     * <input-string>  the string to encrypt
     * 
     * @param args - The list of input arguments provided to the function
     *
     * @returns An encrypted string
     */     
     private String encrypt(List<Object> args) {
             
     	// We should only ever have 1 argument passed to this function
         if (args.size() == 1) {
             
             // Force any object first to a String and then encrypt it
             return vlocity_cmt.UserSecurity.encrypt(String.valueOf(args.get(0)));
         }
         InvalidParameterValueException e = new InvalidParameterValueException('ENCRYPT', 'The function must be called with a single argument');
         throw e;
     }

    /**
     * This method will encrypt sensitive data if the DR/IP is being executed
     * by the guest user in a Community.  This is often useful/needed for encrypting
     * SObject Ids of sensitive objects (Account Id, Cart Id, etc.)
     *
     * The method is called by Formula as follows:
     *
     * ENCRYPT_IF_NECESSARY(<input-string>)
     *
     * where,
     * <input-string>  the string to encrypt
     * 
     * @param args - The list of input arguments provided to the function
     *
     * @returns An encrypted string if the user is the guest-user, otherwise the input string as-is
     */     
     private String encryptIfNecessary(List<Object> args) {
             
     	// We should only ever have 1 argument passed to this function
         if (args.size() == 1) {
             
             // Force any object first to a String and then encrypt it if needed
             return vlocity_cmt.UserSecurity.encryptIfNecessary(String.valueOf(args.get(0)));
         }
         InvalidParameterValueException e = new InvalidParameterValueException('ENCRYPT_IF_NECESSARY', 'The function must be called with a single argument');
         throw e;
     }

    /**
     * This method will decrypt sensitive data
     *
     * The method is called by a Formula as follows:
     *
     * DECRYPT(<input-string>)
     *
     * where,
     * <input-string>  the encrypted string to decrypt
     * 
     * @param args - The list of input arguments provided to the function
     *
     * @returns A decrypted string
     */     
     private String decrypt(List<Object> args) {
             
     	// We should only ever have 1 argument passed to this function
         if (args.size() == 1) {
             
             // Force any object first to a String and then encrypt it
             return vlocity_cmt.UserSecurity.decrypt(String.valueOf(args.get(0)));
         }
         InvalidParameterValueException e = new InvalidParameterValueException('DECRYPT', 'The function must be called with a single argument');
         throw e;
     }

    /**
     * This method will decrypt sensitive data if the DR/IP is being executed
     * by the guest user in a Community.  This is often useful/needed for decrypting
     * SObject Ids of sensitive objects (Account Id, Cart Id, etc.)
     *
     * The method is called by a Formula as follows:
     *
     * DECRYPT_IF_NECESSARY(<input-string>)
     *
     * where,
     * <input-string>  the encrypted string to decrypt
     * 
     * @param args - The list of input arguments provided to the function
     *
     * @returns A decrypted string if the user is the guest-user, otherwise the input string as-is
     */     
     private String decryptIfNecessary(List<Object> args) {
             
     	// We should only ever have 1 argument passed to this function
         if (args.size() == 1) {
             
             // Force any object first to a String and then encrypt it if needed
             return vlocity_cmt.UserSecurity.decryptIfNecessary(String.valueOf(args.get(0)));
         }
         InvalidParameterValueException e = new InvalidParameterValueException('DECRYPT_IF_NECESSARY', 'The function must be called with a single argument');
         throw e;
     }
}