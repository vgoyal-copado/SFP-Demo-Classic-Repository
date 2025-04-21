trigger demoSetPaymentMethod on Account (before update) {

    for (Account a : trigger.new) {
        if (a.Demo_Paperless_Billing__c != trigger.oldMap.get(a.Id).Demo_Paperless_Billing__c){
            if (a.Demo_Paperless_Billing__c) a.vlocity_cmt__BillDeliveryMethod__c = 'Electronic Statements Online';
            else a.vlocity_cmt__BillDeliveryMethod__c = 'Paper Billing';
        } // if change from old to new
    }
}