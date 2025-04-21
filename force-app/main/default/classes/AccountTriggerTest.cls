@IsTest
private class AccountTriggerTest {
    @IsTest
    private static void test1() {
        Account acc = new Account(Name = 'Testing');
        insert acc;
    }
}