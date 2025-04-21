public with sharing class Demo_MonitorJobs {
        
    public static final String DATE_FORMAT = 'yyyy-MM-dd HH:mm:ss'; 

    @AuraEnabled
    public static Map<String, Object> monitor(String start_time, List<String> jobList) {

        // Get all the Apex Classes so we can find the corresponding Jobs
        Set<String> uniqueJobSet = new Set<String>();  // some jobs can appear multiple times (if the code schedules multiple queueable jobs of the same class)
        uniqueJobSet.addAll(jobList);
        ApexClass[] apexClasses = [SELECT Id FROM ApexClass WHERE Name IN :uniqueJobSet ];

        // Search for the Jobs
        DateTime start = (DateTime.valueOfGmt(start_time)).addSeconds(-5); // Add a bit of a buffer to make sure we find all the relevant jobs in the following query        
        AsyncApexJob[] jobs = [ SELECT ApexClass.Name, CompletedDate, CreatedDate, JobItemsProcessed, NumberOfErrors, Status, TotalJobItems FROM AsyncApexJob WHERE JobType='BatchApex' AND CreatedDate > :start AND ApexClassId IN :apexClasses ORDER BY CreatedDate DESC NULLS LAST ];

        // Generate the Job Summary
        Map<String, Object> jobSummary = new Map<String, Object>();
        //jobSummary.put('query1', 'SELECT Id FROM ApexClass WHERE Name IN ' + uniqueJobSet);
        //jobSummary.put('query2', 'SELECT ApexClass.Name, CompletedDate, CreatedDate, JobItemsProcessed, NumberOfErrors, Status, TotalJobItems FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND CreatedDate > ' + start + ' AND ApexClassId IN ' + apexClasses + ' ORDER BY CreatedDate DESC NULLS LAST');        
        Map<String, Object> jobSet = new Map<String, Object>();
        jobSummary.put('jobs', jobSet);
        for (AsyncApexJob job: jobs) {

            String status = job.Status;
            if (!jobSet.containsKey(status)) jobSet.put(status, new List<String>());

            List<String> jobByStatus = (List<String>)jobSet.get(status);
            String jobName = job.ApexClass.Name;
            jobByStatus.add(jobName);
            
            // Overall Status (if a failure is detected)
            if (status.equalsIgnoreCase('Aborted') || status.equalsIgnoreCase('Failed')) jobSummary.put('status', 'Completed');
        }

        // Check if all jobs have completed
        if (jobSet.containsKey('Completed') && ((List<String>)jobSet.get('Completed')).size() >= jobList.size()) jobSummary.put('status', 'Completed');

        // Generate a decent log message
        String logMsg = '';
        for(String key: jobSet.keySet()) {

            if (!String.isEmpty(logMsg)) logMsg += ', ';

            List<String> jlist = (List<String>)jobSet.get(key);
            if (key.equals('Completed')) logMsg += key + ' Jobs (' + jlist.size() + ')';
            else {
                logMsg += key + ' ';
                String jMsg = '';
                for(String j: jlist) {
                    if (!String.isEmpty(jMsg)) jMsg += ', ';
                    jMsg += j;
                }
                logMsg += jMsg;
            }
        }

        if (!String.isEmpty(logMsg)) DemoSystemEvent.info('Demo Cleanup', logMsg);

        return jobSummary;
	}
}