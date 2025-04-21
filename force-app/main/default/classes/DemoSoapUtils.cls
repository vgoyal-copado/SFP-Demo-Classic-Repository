/**
 * This class provides some utilities for interacting with the Salesforce SOAP API
 * 
 * @author	Joe McMaster (joe.mcmaster@salesforce.com)
 * @version	1.1
 *
 *
 * History
 * -------
 * v1.0 - May 14, 2021 - Initial Version for Multiplay Demo
 * v1.1 - Jul 20, 2021 - Added additional debugging statements & more documentation
 * 
 * Notes
 * -----
 * -These methods can be called by the guest user, although I've found that if the user credentials
 *  are for a Customer Community User License, the login will be refused (even with API Enabled in the Profile)
 * -It should work for normal Salesforce Users and users associated with a Partner Community User License
 */
public with sharing class DemoSoapUtils {

    /**
     * Performs a Login using the SOAP API and returns the Session Id
     * 
     * @param username  The username to use
     * @param password  The password to use
     * 
     * @return A map containing the sessionId and serverUrl (note, you can't log the sessionId for security reasons ... will always appear as 'SESSION_ID_REMOVED')
     */
    public static Map<String, String> login(String username, String password) {

        // Create the SOAP Request to Login
        Dom.Document requestXML = new Dom.Document();
        Dom.XmlNode login = requestXML.createRootElement('Envelope', 'http://schemas.xmlsoap.org/soap/envelope/', 'soapenv').addChildElement('Body', 'http://schemas.xmlsoap.org/soap/envelope/', null).addChildElement('login', 'urn:partner.soap.sforce.com', 'sforce');
        login.addChildElement('username', 'urn:partner.soap.sforce.com', null).addTextNode(username);
        login.addChildElement('password', 'urn:partner.soap.sforce.com', null).addTextNode(password);
        
        String loginURL = 'https://login.salesforce.com/services/Soap/u/' + DemoOrgUtils.getApiVersion();
        Dom.Document responseXML = send(loginURL, 'login', requestXML);

        // Extract the Session ID (note, you can't log it for security reasons ... will always appear as 'SESSION_ID_REMOVED')
        Dom.XmlNode result = responseXML.getRootElement().getChildElement('Body', 'http://schemas.xmlsoap.org/soap/envelope/').getChildElement('loginResponse', 'urn:partner.soap.sforce.com').getChildElement('result', 'urn:partner.soap.sforce.com');
        String serverUrl = result.getChildElement('serverUrl', 'urn:partner.soap.sforce.com').getText();
        String sessionId = result.getChildElement('sessionId', 'urn:partner.soap.sforce.com').getText();

        Map<String, String> response = new Map<String, String>();
        response.put('sessionId', sessionId);
        response.put('serverUrl', serverUrl);

        return response;
    }

    /**
     * Performs a Logout using the SOAP API
     * 
     * @param sessionDetails  The session details returned from the login() method above
     * 
     */
    public static void logout(Map<String, String> sessionDetails) {

        // Create the SOAP Request to Logout
        Dom.Document requestXML = new Dom.Document();
        Dom.XmlNode envelope = requestXML.createRootElement('Envelope', 'http://schemas.xmlsoap.org/soap/envelope/', 'soapenv');
        envelope.addChildElement('Header', 'http://schemas.xmlsoap.org/soap/envelope/', null).addChildElement('SessionHeader', 'urn:partner.soap.sforce.com', 'sforce').addChildElement('sessionId', 'urn:partner.soap.sforce.com', null).addTextNode(sessionDetails.get('sessionId'));
        envelope.addChildElement('Body', 'http://schemas.xmlsoap.org/soap/envelope/', null).addChildElement('logout', 'urn:partner.soap.sforce.com', 'sforce');

        Dom.Document responseXML = send(sessionDetails.get('serverUrl'), 'logout', requestXML);
    }

    /**
     * Sends a SOAP Message
     * 
     * @param url         The SOAP API endpoint
     * @param soapAction  The SOAP Action (optional)
     * @param soapMsg     The SOAP Message to send
     * 
     * @return The Respons SOAP Message
     */
    public static Dom.Document send(String url, String soapAction, Dom.Document soapMsg) {
        
        // Setup the SOAP Call
        HttpRequest httpReq = new HttpRequest();
        httpReq.setMethod('POST');
        httpReq.setEndpoint(url);
        httpReq.setHeader('Content-Type', 'text/xml; charset=utf-8');
        if (soapAction != null) httpReq.setHeader('SOAPAction', soapAction);        
        httpReq.setBody(soapMsg.toXmlString());

        // Make the SOAP Call
        System.debug('SOAP Request (' + url + ') -> ' + soapMsg.toXmlString());
        HttpResponse httpRes = new http().send(httpReq);
        Dom.Document soapResponse = new Dom.Document();
        soapResponse.load(httpRes.getBody());

        System.debug('SOAP Response -> ' + soapResponse.toXmlString());

        // Check for errors
        Dom.XmlNode fault = soapResponse.getRootElement().getChildElement('Body', 'http://schemas.xmlsoap.org/soap/envelope/').getChildElement('Fault', 'http://schemas.xmlsoap.org/soap/envelope/');
        if (fault != null) throw new DemoOrgUtils.DemoException(fault.getChildElement('faultstring', null).getText());

        // Return the SOAP Response
        return soapResponse;
    }
}