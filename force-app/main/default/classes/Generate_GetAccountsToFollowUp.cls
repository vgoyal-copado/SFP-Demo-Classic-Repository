global class Generate_GetAccountsToFollowUp { 
    @InvocableMethod(label='Accounts to Follow Up Today' 
                     description='Recommend accounts the current user should follow up on today')
    global static List<List<Recommendation>> getAccounts(List<String> inputData){
        List<List<Recommendation>> outputs = new List<List<Recommendation>>();
        Integer daysSinceLastContact;
         Account[] accounts = [SELECT Name, Description, LastContactDate__c, OwnerId FROM Account WHERE OwnerId = :inputData[0]];
      
        List<Recommendation> recs = new List<Recommendation>(); 
        for (Account account:accounts) {
            if (account.LastContactDate__c != null){
                daysSinceLastContact = account.LastContactDate__c.daysBetween(date.today());
                if (daysSinceLastContact > 30){
                    Recommendation rec = new Recommendation(
                        Name = account.Name,
                        Description = 'Connect with the ' + account.Name + ' account, the last interaction was '+ daysSinceLastContact + ' days ago.',
                        ActionReference = 'accountOutreach',
                        AcceptanceLabel = 'Send Email',
                        AccountId__c = account.Id
                    );
                    recs.add(rec);
                }
            }
        }
        outputs.add(recs);
        return outputs; 
    }
}