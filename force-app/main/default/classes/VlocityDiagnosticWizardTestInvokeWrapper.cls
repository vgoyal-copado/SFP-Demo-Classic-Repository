public class VlocityDiagnosticWizardTestInvokeWrapper implements vlocity_cmt.VlocityOpenInterface2
{
	public Object invokeMethod(String methodName, Map<String,Object> inputs, Map<String,Object> output, Map<String,Object> options)
	{
		output.put('hasErrors',false);
		return output;
	}
}