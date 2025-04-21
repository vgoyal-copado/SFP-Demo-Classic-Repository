trigger AccountTrigger1 on Account (before insert) {
    for(Account acc : trigger.new) {
        acc.Name = 'Test';
        if(String.isNotBlank(acc.PersonAssistantName)) {
            acc.PersonAssistantName += '.com1';
        }
    }
}