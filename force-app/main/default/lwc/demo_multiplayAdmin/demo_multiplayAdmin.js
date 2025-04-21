import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import setupJob from '@salesforce/apex/Demo_Setup.setup';
import getLwcOmniScripts from '@salesforce/apex/Demo_Setup.getLWCOmniScripts';
import getOmniScript from '@salesforce/apex/Demo_Setup.getOmniScript';
import cleanupJob from '@salesforce/apex/Demo_Cleanup.cleanup';
import productMaintenanceJob from '@salesforce/apex/Demo_BuildProductHierarchy.buildHierarchy';
import refreshPlatformCache from '@salesforce/apex/Demo_BuildProductHierarchy.refreshCache';
import clearDC from '@salesforce/apex/Demo_BuildDC.clearCache';
import buildDC from '@salesforce/apex/Demo_BuildDC.buildCache';
import monitorApexJobs from '@salesforce/apex/Demo_MonitorJobs.monitor';
import statementJob from '@salesforce/apex/Demo_CleanupRegenStatements.regenerateStatements';
import publishInfoEvent from '@salesforce/apex/DemoSystemEvent.info';
import publishErrorEvent from '@salesforce/apex/DemoSystemEvent.error';

export default class demo_multiplayAdmin extends LightningElement {

    @api setupButtonDisabled = false;
    @api statementButtonDisabled = false;
    @api cleanupButtonDisabled = false;
    @api cacheButtonDisabled = false;
    @api lwcOSDisabled = false;

    // Modal
    @track lwcOmniScripts = [];
    @track lwcOsUrl = null;

    // Timer Jobs
    jobMonitor;

    /**
     * Shows an error toast message
     * 
     * @param error  The error message to display
     */
    showError(error) {

        console.error("Job Error -> " + JSON.stringify(error));

        let errorMsg = "";
        if (error.body.exceptionType) errorMsg += error.body.exceptionType + ": ";
        if (error.body.pageErrors && error.body.pageErrors[0].message) errorMsg += error.body.pageErrors[0].message;
        
        const toast = new ShowToastEvent({
            title: "Error",
            message: errorMsg,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(toast);
    }

    /**
     * Performs the Multiplay Setup Operation
     * 
     */
    setup() {

        try {

            // Disable the button until the job completes
            console.log("Starting Setup Job");
            this.setupButtonDisabled = true;

            setupJob()
                .then(result => {
                    console.log("Setup Job Complete");
                })
                .catch(error => {
                    this.showError(error);
                })
                .finally(() => {
                    this.setupButtonDisabled = false;
                });

        } catch (err) {
            console.error("Error running setup job -> " + err);
        }
    }

    /**
     * Recompiles all active LWC-based OmniScripts
     * 
     */
    recompileLwcOS() {

        try {

            this.lwcOSDisabled = true;

            let msg = "Recompiling all active LWC-based OmniSripts, this can take some time";
            console.log(msg);
            publishInfoEvent({
                type: "OmniScript",
                message: msg
            });

            getLwcOmniScripts().then(omniscripts => {

                    if (omniscripts && omniscripts.length > 0) {

                        //console.log(omniscripts);

                        // Deactivate the first OS
                        var index = 0;
                        var popup = this.deactivateOS(omniscripts, index);
                        var phase = "Deactivate"; // Deactivate, Wait, Activate

                        var _self = this;
                        // Create a job that will deactivate/activate each OmniScript in turn
                        let jobId = setInterval(function () {

                            // Get the OmniScript status
                            getOmniScript({
                                    id: omniscripts[index].Id
                                }).then(os => {

                                    //console.log(os);

                                    // Deactivation of OmniScript
                                    if (phase == "Deactivate") {

                                        if (!os.vlocity_cmt__IsActive__c) {

                                            console.log("Deactivated!");

                                            // OmniScript has been deactivated, proceed to activate it
                                            popup.close();
                                            phase = "Wait";
                                        } else console.log("Deactivating...");
                                    } else if (phase == "Wait") {

                                        popup = _self.activateOS(omniscripts, index);
                                        phase = "Activate";

                                    }
                                    // Activation of OmniScript
                                    else if (phase == "Activate") {

                                        if (os.vlocity_cmt__IsActive__c) {

                                            // OmniScript has been activated, proceed to recompile the next one
                                            popup.close();
                                            console.log("Activated!");
                                            index++;

                                            // If we are at the end of the list, stop the job
                                            // otherwise, recompile the next OmniScript
                                            if (index == omniscripts.length) {

                                                // Stop the job
                                                clearInterval(jobId);

                                                // Enable button in UI
                                                _self.lwcOSDisabled = false;

                                                publishInfoEvent({
                                                    type: "OmniScript",
                                                    message: "Completed Recompiling " + omniscripts.length + " LWC-based OmniScripts"
                                                });
                                            } else {

                                                popup = _self.deactivateOS(omniscripts, index);
                                                phase = "Deactivate";
                                            }
                                        } else console.log("Activating...");
                                    }

                                })
                                .catch(error => {

                                    let msg = "Error retrieving OmniScript";
                                    console.error(msg);
                                    publishErrorEvent({
                                        type: "OmniScript",
                                        message: msg
                                    });

                                    this.showError(error);
                                });

                        }, 2000);
                    } else console.log("No active LWC-based OmniScripts found");
                })
                .catch(error => {

                    let msg = "Error retrieving LWC-based OmniScripts";
                    console.error(msg);
                    publishErrorEvent({
                        type: "OmniScript",
                        message: msg
                    });

                    this.showError(error);
                });
        } catch (err) {

            let msg = "Error running LWC OmniSript Recompilation job -> " + err;
            console.error(msg);
            publishErrorEvent({
                type: "OmniScript",
                message: msg
            });

            this.showError(err);
        }
    }

    /**
     * Deactivates an OmniScript
     * 
     * @param omniscripts The List of OmniScripts
     * @param index       The index of this OmniScript to deactivate
     * 
     * @returns The window in which the deactivation process is taking place
     */
    deactivateOS(omniscripts, index) {

        let msg = "Deactivating " + (index + 1) + " of " + omniscripts.length + ": " + omniscripts[index].Name + " v" + omniscripts[index].vlocity_cmt__Version__c;
        console.log(msg);
        publishInfoEvent({
            type: "OmniScript",
            message: msg
        });

        let url = "/apex/vlocity_cmt__OmniLwcCompile?id=" + omniscripts[index].Id + "&activate=false";
        return window.open(url, "Deactivating " + omniscripts[index].Name, 'height=30, width=150');
    }

    /**
     * Activates an OmniScript
     * 
     * @param omniscripts  The list of OmniScripts
     * @param index        The index of this OmniScript to activate
     * 
     * @returns  The window in which the activation process is taking place
     */
    activateOS(omniscripts, index) {

        let msg = "Activating " + (index + 1) + " of " + omniscripts.length + ": " + omniscripts[index].Name + " v" + omniscripts[index].vlocity_cmt__Version__c;
        console.log(msg);
        publishInfoEvent({
            type: "OmniScript",
            message: msg
        });

        let url = "/apex/vlocity_cmt__OmniLwcCompile?id=" + omniscripts[index].Id + "&activate=true";
        return window.open(url, "Activating" + omniscripts[index].Name, 'height=30, width=150');
    }

    /**
     * Performs the Multiplay Cleanup Operation
     * 
     */
    cleanup() {

        try {

            // Disable the button until the job completes
            console.log("Starting Cleanup Job");
            this.cleanupButtonDisabled = true;

            cleanupJob()
                .then(result => {
                    console.log("Cleanup Job Complete");
                })
                .catch(error => {
                    this.showError(error);
                })
                .finally(() => {
                    this.cleanupButtonDisabled = false;
                });
        } catch (err) {
            console.error("Error running cleanup job -> " + err);
        }
    }

    /**
     * Runs the Product Hierarchy Maintenance Jobs
     * 
     */
    productMaintenance() {

        this.cacheButtonDisabled = true;

        try {

            console.log("Starting Product Hierarchy Maintenance Job");

            productMaintenanceJob()
                .then(result => {

                    // Monitor the Jobs (every 5 seconds)
                    this.monitorJob = setInterval(() => {
                        this.monitorJobs(result.start_time, result.jobs, this.refreshCpqCache);
                    }, 5000);
                })
                .catch(error => {
                    this.showError(error);
                });

        } catch (err) {
            console.error("Error running product hierarchy maintenance job -> " + err);
        }
    }

    /**
     * Refreshes the CPQ Platform Cache
     * 
     * @param self  Reference to the class instance (as this function is called from within a timer)
     */
    refreshCpqCache(self) {

        try {

            console.log("Starting refresh of CPQ Platform Cache");

            refreshPlatformCache()
                .then(result => {

                    // Monitor the Jobs (every 5 seconds)
                    self.monitorJob = setInterval(() => {
                        self.monitorJobs(result.start_time, result.jobs, self.clearCache);
                    }, 5000);
                })
                .catch(error => {
                    self.showError(error);
                });

        } catch (err) {
            console.error("Error refreshing CPQ Platform Cache -> " + err);
        }
    }

    /**
     * Monitors one or more batch jobs for completion/errors
     * 
     * @param start_time  Approximately when the jobs were started
     * @param jobList     The list of Apex queueable/batch job names to monitor
     * @param nextTask    An optional next function to run
     */
    monitorJobs(start_time, jobList, nextTask) {

        try {

            console.log("Monitoring Jobs " + JSON.stringify(jobList) + " since " + start_time);

            monitorApexJobs({start_time, jobList})
                .then(result => {

                    console.log(result);
                    if (result.status && result.status == "Completed") {
                    
                        // Stop monitoring
                        clearInterval(this.monitorJob);

                        // Trigger next task if necessary
                        if (nextTask) nextTask(this);
                    }
                })
                .catch(error => {
                    this.showError(error);
                    clearInterval(this.monitorJob);
                });

        } catch (err) {
            console.error("Error running cache monitor -> " + err);
            clearInterval(this.monitorJob);
        }
    }

    /**
     * Clears the Digital Commerce Cache
     * 
     * @param self Reference to the class instance(as this function is called from within a timer)
     */
    clearCache(self) {

        try {

            // Disable the button until the job completes
            console.log("Starting Digital Commerce Cache Cleanup");

            clearDC()
                .then(result => {

                    console.log("Cache Cleanup Complete");

                    buildDC().then(result => {
                        
                        console.log(result);

                        // Monitor the Jobs (every 5 seconds)
                        self.monitorJob = setInterval(() => {
                            self.monitorJobs(result.start_time, result.jobs, self.enableCacheButton);
                        }, 5000);
                    })
                    .catch(error => {
                        self.showError(error);
                    });

                })
                .catch(error => {
                    self.showError(error);
                });
        } catch (err) {
            console.error("Error running Digital Commerce Caceh Cleanup job -> " + err);
        }
    }

    /**
      * Enables the Build Cache Button
      * 
      * @param self Reference to the class instance(as this function is called from within a timer)
      */
    enableCacheButton(self) {

        self.cacheButtonDisabled = false;
    }

    /**
     * Regenerates the sample billing statements for the Multiplay Demo
     * 
     */
    statements() {

        try {

            // Disable the button until the job completes
            console.log("Starting Billing Statement Regeneration Job");
            this.statementButtonDisabled = true;

            statementJob()
                .then(result => {
                    console.log("Billing Statement Regeneration Job Complete");
                })
                .catch(error => {
                    this.showError(error);
                })
                .finally(() => {
                    this.statementButtonDisabled = false;
                });
        } catch (err) {
            console.error("Error running biling statement regeneration job -> " + err);
        }
    }
}