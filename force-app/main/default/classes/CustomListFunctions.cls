/**
 * This class provides some useful functions that can be used within OmniStudio DataRaptor & Integration Procedure
 * formulas to manipulate Lists.
 *  
 * I recommend you register each function with the org's Custom Metadata to make it easy to use, but this isn't necessary
 * as custom functions can now be called by the built-in FUNCTION() formula.
 *  
 * (Setup -> Custom Metadata Types -> Function Definition -> Manage Function Definitions -> New)
 *
 * @author	Joe McMaster (joe.mcmaster@salesforce.com)
 * @version	1.2
 *
 * History
 * -------
 * v1.0 - 12-28-2018 - Initial Version with TOLIST() function.  Although the code here is correct, a DR or IP seems to 'simplify' the list responses returned by this function and therefore doesn't give you the expected behavior
 * v1.1 - 04-04-2019 - Added SIZE() function
 * v1.2 - 04-25-2019 - Added LOOKUP() function
 *
 */
global class CustomListFunctions implements vlocity_cmt.VlocityOpenInterface {
    
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
        
		// Convert a set of Objects into a List
		// Examples:
		//
		// TOLIST('Param1', 'Param2', 'Param3')
		//
        if (methodName == 'toList') outputMap.put('result', toList((List<Object>)inputMap.get('arguments')));
        
        // Determine the size of a list
        //
        // SIZE(<list object>)
        else if (methodName == 'size') outputMap.put('result', size(inputMap.get('arguments')));
        
        // Enhance the first list with subsequent lists using a common lookup key to match
        // Examples:
        //
        // LOOKUP(<key>, <source list>, <lookup list>)
        else if (methodName == 'lookup') outputMap.put('result', lookup((List<Object>)inputMap.get('arguments')));
        
        return true;
    }
    
    /**
     * This method creates a list of objects from zero or more arguments
     *
     * The method is called by a Formula as follows:
     *
     * TOLIST(<item1>, <item2>, <item3>, <item4>, ...)
     *
     * where,
     * <itemX>  is an object (String, Integer, etc.)
     * 
     * For example:
     *
     * TOLIST(10, 20, 30)  ====> [ 10, 20, 30 ]
     * TOLIST(10)          ====> [ 10 ]
     * TOLIST()            ====> [ ]            // Note calling this from a DR will result in a FormulaParser.StackUnderflowException
     * 
     * @param args - The list of input arguments provided to the function
     *
     * @returns The list
     */
    private List<Object> toList(List<Object> args) {
    		
		List<Object> theList = new List<Object>();
		
		for (Integer i=0; i<args.size(); i++) theList.add(args.get(i));
		    	    	
    	return theList;
    }
    
    /**
     * This method determines the size of a list
     *
     * The method is called by a Formula as follows:
     *
     * SIZE(<obj>)
     *
     * where,
     * <obj>  is an object (i.e. a list)
     * 
     * For example:
     *
     * SIZE(10, 20, 30)  ====> 3
     * SIZE(10)          ====> 1
     * SIZE()            ====> 0
     * SIZE(NULL)        ====> 0
     * 
     * @param obj  The object determine the length of
     *
     * @returns The size of the object
     */
    private Integer size(Object obj) {		

        if (obj == null) return 0;
        else if (obj instanceof List<Object>) {
            
            List<Object> listobj = (List<Object>)obj;
            
            // Look for lists containing a null
            if (listobj.size() == 1 && listobj.get(0) == null) return 0;
            else return ((List<Object>)obj).size();
        }
        else return 1;
    }
    
    /**
     * This method will enhance the source list with fields from the lookup list by matching a common key.  The source list is maintained/returned and is enhanced
     * with any successful lookups.
     *
     * The method is called by a Formula as follows:
     *
     *  LOOKUP(<key>, <source list>, <lookup list>)
     *
     * where,
     * <key>         is the key used to locate matching entries in the lookup list.  Assumed key is a root level node in the lookup list.
     * <source list> is the list of entries that will be enhanced
     * <lookup list> is the lookup list for matching.  Any matches found will result in all the nodes from the lookup list being added to the source list (even if they exist in the source list already)
     * 
     * For example:
     *
     * SIZE('Id', [ {Id: 123, Value: test}, {Id: 456, Value: test2} ], [ {Id: 123, Value2: extra} ])  ====> {Id: 123, Value: test, Value2: extra}, {Id: 456, Value: test2}
     * 
     * @param args - The list of input arguments provided to the function
     *
     * @returns The enhanced list after lookups
     */
    private List<Object> lookup(List<Object> args) {		

        List<Object> newlist = new List<Object>();
        
        String key;
        List<Object> sourceList;
        List<Object> lookupList;
                
        // Validation/Init
		if (args.size() == 3) {
            
            // Get the field key
            key = String.valueOf(args.get(0));
            
            // Get the source list
            Map<String, Object> sourceListContainer = (Map<String, Object>)args.get(1);
            if (sourceListContainer.containsKey('VLOCITY-FORMULA-LIST')) sourceList = (List<Object>)sourceListContainer.get('VLOCITY-FORMULA-LIST');
            else {
                System.debug(LoggingLevel.ERROR, 'LOOKUP() source object must be a list, use the LIST() formula');
                InvalidParameterValueException e = new InvalidParameterValueException('LOOKUP', 'The source object must be a list, use the LIST() formula');
				throw e;
            }
            
            // Get the lookup list
            Map<String, Object> lookupListContainer = (Map<String, Object>)args.get(2);
            if (lookupListContainer.containsKey('VLOCITY-FORMULA-LIST')) lookupList = (List<Object>)lookupListContainer.get('VLOCITY-FORMULA-LIST');
            else {
                System.debug(LoggingLevel.ERROR, 'LOOKUP() lookup object must be a list, use the LIST() formula');
                InvalidParameterValueException e = new InvalidParameterValueException('LOOKUP', 'The lookup object must be a list, use the LIST() formula');
				throw e;
            }
		}
        else {
            System.debug(LoggingLevel.ERROR, 'LOOKUP() The function must be called with 3 arguments (String, List, List)');
   			InvalidParameterValueException e = new InvalidParameterValueException('LOOKUP', 'The function must be called with 3 arguments (String, List, List)');
			throw e;
        }
        
        // Traverse the source list
        Iterator<Object> sourceIter = sourceList.iterator();
        while (sourceIter.hasNext()) {
            
            Object obj = sourceIter.next();
            if (obj instanceof Map<String, Object>) {
                
                Map<String, Object> mobj = (Map<String, Object>) ((Map<String, Object>)obj).clone();
                if (mobj.containsKey(key)) {
                    
                    // Go through lookup list and try to find matching entries based on the key
                    Object keyValue = mobj.get(key);
                    Iterator<Object> lookupIter = lookupList.iterator();
                    while (lookupIter.hasNext()) {
                        
                        Object lobj = lookupIter.next();
                        if (lobj instanceof Map<String, Object>) {
                            
                            Map<String, Object> lo = (Map<String, Object>)lobj;
                            if (lo.containsKey(key) && lo.get(key).equals(keyValue)) {
                                
                                // Found a match, merge all the fields
                                for (String lfield : lo.keySet()) mobj.put(lfield, lo.get(lfield));
                            }
                        }
                        else System.debug(LoggingLevel.WARN, 'LOOKUP() formula found a non-Map object in the lookup list and it will be ignored => ' + String.valueOf(lobj));
                    }
                }
                newList.add(mobj);
            }
            else System.debug(LoggingLevel.WARN, 'LOOKUP() formula found a non-Map object in the source list and it will be ignored => ' + String.valueOf(obj));
        }
		
        return newList;
    }    
}