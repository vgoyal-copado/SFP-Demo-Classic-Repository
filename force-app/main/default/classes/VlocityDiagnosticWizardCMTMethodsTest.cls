@isTest
private class VlocityDiagnosticWizardCMTMethodsTest {

	@isTest static void invokeTelcoAdminConsoleMethodTest()
	{
		Map<String,Object> inputs = new Map<String,Object>();
		Map<String,Object> output = new Map<String,Object>();
		Map<String,Object> options = new Map<String,Object> {
			'telcoAdminConsoleMethod' => 'ThisWillNotDoAnything'
		};
		String methodName = 'invokeTelcoAdminConsoleMethod';

		Type classType = Type.forName('VlocityDiagnosticWizardCMTMethods');
		vlocity_cmt.VlocityOpenInterface2 classInstance = (vlocity_cmt.VlocityOpenInterface2) classType.newInstance();

		Object result1 = classInstance.invokeMethod(methodName, inputs, output, options);
	}

	@isTest static void checkAndSetVlocityFeatureTest()
	{
		//Fail - vlocity_cmt__IsTriggerOn__c == false
		Map<String,Object> inputs1 = new Map<String,Object>();
		Map<String,Object> output1 = new Map<String,Object>();
		Map<String,Object> options1 = new Map<String,Object>
		{'VlocityFeature'=>
			           new Map<String,Object> {'Name'=>'ThisWillDoNothing',
			                                   'value'=>'true'}};
		String methodName1 = 'checkVlocityFeature';
		Type classType1 = Type.forName('VlocityDiagnosticWizardCMTMethods');
		vlocity_cmt.VlocityOpenInterface2 classInstance1 = (vlocity_cmt.VlocityOpenInterface2) classType1.newInstance();
		Object result1 = classInstance1.invokeMethod(methodName1, inputs1, output1, options1);
		System.assertEquals(output1.get('hasErrors'),true);


		//Pass - vlocity_cmt__IsTriggerOn__c set to true
		Map<String,Object> inputs2 = new Map<String,Object>();
		Map<String,Object> output2 = new Map<String,Object>();

		Map<String,Object> options2 = new Map<String,Object> {
			'VlocityFeature'=> new Map<String,Object> {
				'Name'=>'ThisWillDoNothing',
				'value'=>'true'
			}
		};

		String methodName2 = 'setVlocityFeature';
		Type classType2 = Type.forName('VlocityDiagnosticWizardCMTMethods');

		vlocity_cmt.VlocityOpenInterface2 classInstance2 = (vlocity_cmt.VlocityOpenInterface2) classType2.newInstance();

		Object result2 = classInstance2.invokeMethod(methodName2, inputs2, output2, options2);

		System.assertEquals(output2.get('hasErrors'),false);
	}

	@isTest static void callSuperTest()
	{
		Map<String,Object> inputs = new Map<String,Object>();
		Map<String,Object> output = new Map<String,Object>();
		Map<String,Object> options = new Map<String,Object> {};
		String methodName = 'PLACEHOLDER';

		Type classType = Type.forName('VlocityDiagnosticWizardCMTMethods');
		vlocity_cmt.VlocityOpenInterface2 classInstance = (vlocity_cmt.VlocityOpenInterface2) classType.newInstance();

		Object result = classInstance.invokeMethod(methodName, inputs, output, options);
		System.assertEquals(output.get('hasErrors'), false);
	}
}