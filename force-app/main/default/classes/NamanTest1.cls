/**
 * An apex page controller that exposes the change password functionality
 */
public with sharing class NamanTest1 {
    public String oldPassword {get; set;}
    public String newPassword {get; set;}
    public String verifyNewPassword {get; set;}        
    
    public PageReference changePassword() {
        return Site.changePassword(newPassword, verifyNewPassword, oldpassword);    
    }     
    
     public static void NamanTest1() {
        // Instantiate a new controller with all parameters in the page 4
        NamanTest1 controller = new NamanTest1();
        controller.oldPassword = '123456';
        controller.newPassword = 'qwerty1'; 
        controller.verifyNewPassword = 'qwerty1';                
        
        System.assertEquals(controller.changePassword(),null);                           
    }    
}