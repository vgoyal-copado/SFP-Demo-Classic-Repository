global with sharing class GuestUserEncryptionUtils implements vlocity_cmt.VlocityOpenInterface {

    /**
     * Top Level method invoked by OmniScript, VIPs, etc.
     *
     * @param method  - The name of the method to execute
     * @param input   - The input data provided in the call to this method
     * @param output  - The output object where any results will be stored
     * @param options - Any options to aid in the execution of this class
     *
     * @return true if the method completes successfully, false otherwise
     */ 
    global boolean invokeMethod(String method, Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) {
        
        try {

            // encrypt any sensitive data
            if (method.equalsIgnoreCase('encrypt')) return encrypt(input, output, options);
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'ERROR ' + e.getMessage() + ' Line: ' + e.getLineNumber());
        }

        // if we make it here, an invalid method was specified
        System.debug(LoggingLevel.ERROR, 'Invalid Method ' + method + ' called on Apex class GuesetUserEncryptionUtils');
        return false;        
    }

    /**
     * Searches for sensitive information to encrypt.  This only occurs if
     * it is the Salesforce Guest User executing this method from a Community.
     * 
     * @param input   - The input data provided in the call to this method
     * @param output  - The output object where any results will be stored
     * @param options - Any options to aid in the execution of this class
     * 
     * @return true if the encryption was successful
     */
    private boolean encrypt(Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) {

        // If we aren't the guest user, skip everything
        if (!vlocity_cmt.UserSecurity.isGuestUser()) {
            output.putAll(input);
            return true;
        }

        // Look for sensitive data to encrypt
        Iterator<String> keyIter = input.keySet().iterator();
        while (keyIter.hasNext()) {

            String key = keyIter.next();
            Object value = input.get(key);

            System.debug('JOE -> Found ' + key + ' = ' + value);
            if (key.equalsIgnoreCase('AccountId') && value instanceof String) {
                value = vlocity_cmt.UserSecurity.encrypt(String.valueOf(value));
                System.debug('JOE - Encrypting ' + key + ' -> ' + value);
            }

            output.put(key, value);
        }
        return true;
    }
}