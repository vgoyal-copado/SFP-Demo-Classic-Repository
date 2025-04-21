public class VlocityDiagnosticWizardCMTMethods extends VlocityDiagnosticWizardBaseMethods
{
	/**
	 * The VlocityOpenInterface2 method override to dynamically call methods available for the CMT Upgrade Wizard,
	 *    and in the VlocityDiagnosticWizardBaseMethods class
	 * @param  methodName  The name of the method that will be invoked
	 * @param  inputs      The inputs of the method
	 * @param  outputs     A map to store output information in
	 * @param  options     Any optional parameters
	 * @return Object      Returns the output map
	 */
	public override Object invokeMethod(String methodName,
	                                    Map<String,Object> inputs,
	                                    Map<String,Object> output,
	                                    Map<String,Object> options)
	{
		switch on methodName
		{
			when 'invokeTelcoAdminConsoleMethod'
			{
				return invokeTelcoAdminConsoleMethod(inputs, output, options);
			}
			when 'checkVlocityFeature'
			{
				return checkVlocityFeature(inputs, output, options);
			}
			when 'setVlocityFeature'
			{
				return setVlocityFeature(inputs, output, options);
			}
			when else
			{
				return super.invokeMethod(methodName, inputs, output, options);
			}
		}
	}

	/**
	 * A class used to invoke Vlocity methods with TelcoAdminConsoleController.
	 *  Takes in standard VlocityOpenInterface2 inputs and calls invokeMethod on the controller
	 * @param  inputs      The inputs of the method (not used)
	 * @param  output     A map to store output information in
	 *  @param  options     Any optional parameters
	 *  @return Object      return output (the method run, or an error message)
	 */
	public static Map<String,Object> invokeTelcoAdminConsoleMethod(Map<String,Object> inputs,
	                                                               Map<String,Object> output,
	                                                               Map<String,Object> options)
	{
		Map<String, Object> parametersMap = new Map<String, Object>();

        //The key 'telcoAdminConsoleParameters' contains a Map<String, String> that contain any additional custom parameters required
        if(options.containsKey('telcoAdminConsoleParameters'))
		{
			parametersMap = (Map<String, Object>) options.get('telcoAdminConsoleParameters');
		}

		parametersMap.put('methodName', options.get('telcoAdminConsoleMethodName'));
		String parametersInput = JSON.serialize(parametersMap);

		vlocity_cmt.TelcoAdminConsoleController controller = new vlocity_cmt.TelcoAdminConsoleController();
		controller.setParameters(parametersInput);
		controller.invokeMethod();
		//vlocity_cmt.TelcoAdminConsoleController is not global, so only thrown errors will cause invokeMethod to fail
		output.put('telcoAdminConsoleMethodRun', parametersMap.get('methodName'));
		output.put('hasErrors',false);
		return output;
	}

	/**
	 * checkVlocityFeatureValue uses the VlocityFeatureService wrapper to check the desired VlocityFeature value
	 * @param  inputs  inputs are the inputs of the method (not used)
	 * @param  output  output is the output of the method
	 * @param  options options are the parameters of the method in form:
	 *	{'VlocityFeature' => {'Name' => 'featureName', 'Value' => 'featureValue'}}
	 * @return         return output (actual matches expected, or error message)
	 */
	public static Map<String,Object> checkVlocityFeature(Map<String,Object> inputs,
	                                                     Map<String,Object> output,
	                                                     Map<String,Object> options)
	{
		Map<String,Object> vlocityFeatureOptions = (Map<String,Object>)options.get('VlocityFeature');
		String thisName = (String)vlocityFeatureOptions.get('Name');
		String thisValue = (String)vlocityFeatureOptions.get('Value');

		String vlocityFeatureValue = vlocity_cmt.VlocityFeatureService.getFeatureValue(thisName) ? 'true' : 'false';

		if (!vlocityFeatureValue.equalsIgnoreCase(thisValue))
		{
			output.put('hasErrors', true);
			output.put('hasWarnings', true);
			output.put('errorMessage','Actual value: "'+vlocityFeatureValue + '" does not match expected value of: "' + thisValue + '"');
			return output;
		}

		output.put('hasErrors', false);
		return output;
	}

	/**
	 * setVlocityFeatureValue uses the VlocityFeatureService wrapper to set the desired VlocityFeature value
	 * @param  inputs  inputs are the inputs of the method (not used)
	 * @param  output  output is the output of the method
	 * @param  options options are the parameters of the method in form:
	 *	{'VlocityFeature' => {'Name' => 'featureName', 'Value' => 'featureValue'}}
	 * @return         return output (VlocityFeatureService.SetFeatureValue did not throw error)
	 */
	public static Map<String,Object> setVlocityFeature(Map<String,Object> inputs,
	                                                   Map<String,Object> output,
	                                                   Map<String,Object> options)
	{
		Map<String,Object> vlocityFeatureOptions = (Map<String,Object>)options.get('VlocityFeature');
		String thisName = (String)vlocityFeatureOptions.get('Name');
		String thisValue = (String)vlocityFeatureOptions.get('Value');

		vlocity_cmt.VlocityFeatureService.SetFeatureValue(thisName, thisValue);

		output.put('hasErrors', false);
		return output;
	}
}