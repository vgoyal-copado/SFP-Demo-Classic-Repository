/**
 * This class is used by the Salesforce scheduler to generate an email notification to admin users
 * when an org is approaching its expiry date.  The frequency of the emails is determined by the scheduled job
 * in Salesforce.
 *
 * @author  Duane Nelson (duane.nelson@salesforce.com)
 * @author  Joe McMaster (joe.mcmaster@salesforce.com)
 * @version 2.0
 *
 *
 * History
 * -------
 * v1.0 - Jun 18, 2019 - Initial Version from Duane Nelson
 * v2.0 - Sep 28, 2021 - Repurposed for Communications Cloud Demos
 *
 */
public with sharing class DemoOrgExpiryNotification implements Schedulable {

    static final Integer NOTIFICATION_THRESHOLD     = 10;  // begin notifying when org is within 10 days of expiration
    static final String  QBRANCH_ORG_EXTENSION_SITE = 'https://central.qlabs.sfdc.sh/q-extender';

    /**
     * This method is called by the Salesforce scheduler. 
     * 
     * @param sc  The schedulable context information (ignored currently)
     */
    public void execute(SchedulableContext sc) {

        notify();
    }

    /**
     * Determines how close the org is to expiring.  
     * If it is under the notification threshold, an email will be sent to all admins configured in the org.
     * 
     */
    public static void notify() {

        // get the org expiry date and determine if we are close to expiry
        Organization org = [SELECT Id, Name, PrimaryContact, TrialExpirationDate FROM Organization];
        Integer daysLeft = Math.abs(org.TrialExpirationDate.date().daysBetween(Date.Today()));

        if (daysLeft <= NOTIFICATION_THRESHOLD) {
            
            // Assemble the email addresses
            List<String> toAddresses = new List<String>();
    		for (User adminUser : [SELECT Email,Id,Name FROM User WHERE isActive=true AND Profile.Name='System Administrator' AND Email LIKE '%@salesforce.com']) {

                String emailAddress = adminUser.Email; 
        		if (!toAddresses.contains(emailAddress)) toAddresses.add(emailAddress);
    		}
                
            // Build the email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			mail.setToAddresses(toAddresses);
        	mail.setSubject('Salesforce Org Expiration Warning');
            mail.setHtmlBody(getHtmlMessage(org, daysLeft));        	

            // Send the Email and Check results
            System.debug('Sending expriation warning email to ' + JSON.serialize(toAddresses));
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            for (Messaging.SendEmailResult res : results) {

                if (res.isSuccess()) System.debug('Email sent successfully');
                else System.debug('The following errors occurred : ' + res.getErrors());
            }
        }            
        else System.debug('Demo Environment Expires in ' + daysLeft + ' days.');
    }

    /**
     * Generates the HTML Message to send
     * 
     * @param org       The Organization details
     * @param daysLeft  The number of days left before org expiration
     * 
     * @return The HTML message
     */
    public static String getHtmlMessage(Organization org, Integer daysLeft) {

        String daysMsg;
        if (daysLeft <= 0) daysMsg = 'imminently';
        else if (daysLeft == 1) daysMsg = 'in 1 day';
        else daysMsg = 'in ' + String.valueOf(daysLeft) + ' days';

        String msg = '​<body>' +
                     '  <div style=\'margin:0 auto; width: 60vw;\'>' +
                     '    <p style=\'color: #666666; font-family: "Salesforce-Sans", sans-serif; font-size: 16px; line-height: 22px; margin-top: 20px;\'>Hi There!</p>' +
                     '    <p style=\'color: #666666; font-family: "Salesforce-Sans", sans-serif; font-size: 16px; line-height: 22px; margin-top: 20px;\'>This is a just a friendly warning to let you know that the following Salesforce Org will expire <strong style=\'color: #333333; font-weight: 700;\'>' + daysMsg + '</strong>.</p>' +
                     '    <p style=\'color: #666666; font-family: "Salesforce-Sans", sans-serif; font-size: 16px; font-weight: 700; line-height: 22px; margin-top: 20px; margin-bottom: 10px;\'>Org Id  : <strong style=\'color: #333333; font-weight: 700;\'>' + org.Id + '</strong></p>' +
                     '    <p style=\'color: #666666; font-family: "Salesforce-Sans", sans-serif; font-size: 16px; font-weight: 700; line-height: 22px; margin-top: 10px; margin-bottom: 10px;\'>Org Name: <strong style=\'color: #333333; font-weight: 700;\'>' + org.Name + '</strong></p>' +
                     '    <p style=\'color: #666666; font-family: "Salesforce-Sans", sans-serif; font-size: 16px; font-weight: 700; line-height: 22px; margin-top: 10px; margin-bottom: 10px;\'>Org URL : <strong style=\'color: #333333; font-weight: 700;\'>' + URL.getOrgDomainUrl().toExternalForm() + '</strong></p>' +
                     '    <p style=\'color: #666666; font-family: "Salesforce-Sans", sans-serif; font-size: 16px; font-weight: 700; line-height: 22px; margin-top: 10px; margin-bottom: 20px;\'>Expiry Date : <strong style=\'color: #333333; font-weight: 700;\'>' +  org.TrialExpirationDate.format('EEEE, d MMM yyyy HH:mm:ssa zzzz') + '</strong></p>' +
                     '    <p style=\'color: #666666; font-family: "Salesforce-Sans", sans-serif; font-size: 16px; line-height: 22px; margin-top: 20px;\'>As a System Administrator for this Salesforce Org, you can avoid loosing access by clicking the button below and extending the expiry date.</p>' +
                     '    <div style=\'margin: 0 auto; margin-top: 40px; text-align: center;\'>' +
                     '      <a style=\'background-color: #2C9AD9; border-style: solid; border-color: black; border-width: thin; border-radius: 10px; color: #ffffff; font-family: "Saleforce-Sans", sans-serif; font-size: 16px; padding: 20px 40px; text-align: center; text-decoration: none; width: 250px;\' href="' + QBRANCH_ORG_EXTENSION_SITE + '">Request Extension</a>' +
                     '    </div>' +
                     '    <p style=\'color: #666666; font-family: "Salesforce-Sans", sans-serif; font-size: 16px; line-height: 22px; margin-top: 20px;\'>Have an awesome day!</p>' +
                     '    <p style=\'color: #666666; font-family: "Salesforce-Sans", sans-serif; font-size: 16px; line-height: 22px; margin-top: 10px;\'>Demo Engineering</p>' +
                     '    <p style=\'color: #666666; font-family: "Salesforce-Sans", sans-serif; font-size: 12px; line-height: 22px; margin-top: 20px;\'>PS: This email was generated automatically and you\'ll continue to receive daily warnings until the org has been extended or has finally expired.</p>' +
                     '  </div>' +
                     '</body>';

        return msg;
    }
}