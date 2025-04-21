trigger AccountTrigger2 on Account (before insert) {
    for(Account acc : trigger.new) {
        acc.Name = 'Test';
        if(String.isBlank(acc.PersonAssistantName)) {
            acc.PersonAssistantName = 'https://test.com';
        }
    }
}