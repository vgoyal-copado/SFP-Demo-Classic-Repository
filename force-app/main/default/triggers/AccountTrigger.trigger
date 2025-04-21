trigger AccountTrigger on Account (before insert) {
    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            System.debug('before insert');
        }
    }
}