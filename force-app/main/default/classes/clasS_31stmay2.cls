public class clasS_31stmay2 {
public static void execute() {
        System.debug('Deploying this class with Vlocity enabled1');
        Account a = [Select id, name from Account limit 1];
        
        a.name = 'Naman Test 26 Sep';
        update a;
    }
}