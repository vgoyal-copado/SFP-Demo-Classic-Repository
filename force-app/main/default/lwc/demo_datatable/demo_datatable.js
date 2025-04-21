/**
  This custom LWC is used to display a table and uses the standard Salesforce lightning-datatable LWC.
  
  @see https://developer.salesforce.com/docs/component-library/bundle/lightning-datatable
  
  @author Dean Fischesser (dfischesser@salesforce.com), Joe McMaster (joe.mcmaster@salesforce.com)
  @version 2.1
 
  History
  =======
  Aug 25, 2020 - v1.0 - Initial Version
  Feb 10, 2021 - v2.0 - Updates to make fully metadata driven (no hard-coded columns or row key)
                      - Support for sorting, inline editing (including calling an optional DataRaptor to persist changes)
                      - Support for LWC OmniOut (requires some changes to the NodeJS project)
  Apr 21, 2021 - v2.1 - Renamed CSS class (to be more consistent)
                      - Documented list of CSS token overrides
  
  
  Configuration
  =============
  Set the following custom LWC properties for this component
  
  rows                   - References a list of data in the OmniScript that should appear in the table
  key-field              - The field name to use as the unique key for each row (Required)
  columns                - The list of columns to display in the table in the form (you will need to set this using a SetValues):
                            [
                             {
                                "fieldName": <the name of the field in the data>,
                                "label": <the label to use as the column name>,
                                "type": <optional type>,
                                "sortable": true,
                                "editable": true
                                ...
                              }
                            ]
                            ** See the Salesforce lightning-datatable developer documentation for a complete list of column properties you can set
  max-row-selection      - The maximum number of rows that can be selected in the table.  Setting this to a value < 1 will hide the selection column (Optional, Default = 1000)
  show-row-number-column - Shows the row number column (**Note, the row number column will always show if any columns are editable) (Optional, Default = false)
  update-Dataraptor      - The DataRaptor to call when an inline-edit is made (Optional)
  debug                  - show extra debug information in the browser console (Optional, Default = false)

  Notes
  =====
  -No sorting is performed on the initial load, but you can sort thereafter
  -If any columns are marked as editable, the row number column is always shown (behaviour of the datatable LWC)
  -Bulk inline edits can be performed by selecting >1 row and then editing one of the fields (an option will appear asking if you want to update all records)

 */
import { LightningElement, api, track } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_cmt/omniscriptBaseMixin';

export default class demo_datatable extends OmniscriptBaseMixin(LightningElement) {  

    @api namespace = "vlocity" + "_cmt";  // Fool the OmniOut export process so it doesn't change the namespace to 'c'
    @api columns = [];    
    @api keyField;
    @api showRowNumberColumn = false;
    @api sortedBy;
    @api sortedDirection = "desc";
    @api hideCheckboxColumn = false;
    @api draftValues = [];
    @api debug = false;

    // DataRaptor to handle inline editing
    @api updateDataraptor;

    // Rows
    @api
    get rows() { return this._rows; }
    set rows(data) {

        if (data) {

            if (Array.isArray(data)) this._rows = JSON.parse(JSON.stringify(data));
            else this._rows = [ JSON.parse(JSON.stringify(data)) ];            
        }
    }
    
    // Max Row Selection
    @api
    get maxRowSelection() { return this._maxRowSelection; }
    set maxRowSelection(data) {

        if (data) {

            this._maxRowSelection = data;

            // Hide the checkbox column if row selection is set to 0
            if (this._maxRowSelection < 1) this.hideCheckboxColumn = true;
            else this.hideCheckboxColumn = false;
        }
    }

    @track _rows = [];
    @track _maxRowSelection = 1000;
    
    /**
     * Sorts the rows by the selected column and sort direction
     * 
     * @param fieldName      The field name by which to sort the data
     * @param sortDirection  The sort direction
     * 
     * @return The sorted rows
     */
    sortData(fieldName, sortDirection) {
       
        if (this.debug) console.log("Sorting by " + fieldName + " in " + sortDirection + "ending direction");

        // Create a new array to sort
        let sortedData = JSON.parse(JSON.stringify(this._rows));
        
        // Sort it
        sortedData.sort(function (a, b) {            


            // Sort Ascending
            if (sortDirection === "asc") {

                // undefined values always appear first in an ascending sort
                if (a[fieldName] === undefined && b[fieldName] !== undefined) return -1;
                else if (a[fieldName] !== undefined && b[fieldName] === undefined) return 1;                    
                else if (a[fieldName] > b[fieldName]) return 1;
                else if (a[fieldName] < b[fieldName]) return -1;                
                else return 0;
            }
            // Sort Descending
            else {

                // undefined values always appear last in a decending sort
                if (a[fieldName] === undefined && b[fieldName] !== undefined) return 1;
                else if (a[fieldName] !== undefined && b[fieldName] === undefined) return -1;
                else if (a[fieldName] > b[fieldName]) return -1;
                else if (a[fieldName] < b[fieldName]) return 1;                
                else return 0;
            }
        });

        return sortedData;
    }

    /**
     * Handle sorting events
     * 
     * @param {*} event 
     */
    handleSort(event) {

        try {
        
            var fieldName = event.detail.fieldName;
            var sortDirection = event.detail.sortDirection;
            
            // sort the rows
            this.sortedBy = fieldName;
            this.sortedDirection = sortDirection;
            this._rows = this.sortData(fieldName, sortDirection);
        }
        catch (err) {
            console.error("Error in demo_datatable.handleSort() -> " + err);
        }
    }

    /**
     * Handles selection/deselection of rows in the table
     * 
     * @param {*} event The row selection event
     */
    handleRowSelection(event) {

        try {

            let selections = event.detail.selectedRows;

            if (this.debug) console.log("Row(s) Selected -> " + JSON.stringify(selections));            
            super.omniUpdateDataJson(selections);
        }
        catch (err) {
            console.error("Error in demo_datatable.handleRowSelected() -> " + err);
        }
    }

    /**
     * Handles any inline edit.  The event can contain updates for multiple rows,
     * and each row may have multiple updates.
     * 
     * @param {*} event The inline edit event 
     */
    handleSave(event) {

        try {
        
            let updates = event.detail.draftValues;

            // Track updates for a call to a DataRaptor
            let drUpdates = [];

            // Handle multiple updates at once
            for (let i=0; i<updates.length; i++) {

                if (this.debug) console.log("Handling Save! -> " + JSON.stringify(updates[i]));

                // Find the row and update accordingly
                for (let x=0; x<this._rows.length; x++) {
                    if (this._rows[x][this.keyField] == updates[i][this.keyField]) {
                        
                        // Found the Row, make the update(s)
                        for (let key in updates[i]) this._rows[x][key] = updates[i][key];

                        // Call the DataRaptor
                        if (this.updateDataraptor) drUpdates.push(this._rows[x]);
                    }
                }
            }

            // Clear the draft values now that we've persisted them
            this.draftValues = [];

            // Call the Update DataRaptor
            this.dataRaptorUpdates(drUpdates);

            // Make sure any edits are carried over to the OmniScript JSON if the row being edited happens to be selected
            super.omniUpdateDataJson(this.template.querySelector('lightning-datatable').getSelectedRows());
        }
        catch (err) {
            console.error("Error in demo_datatable.handleSave() -> " + err);
        }
    }

    /**
     * Calls a DataRaptor to update one or more records
     * 
     * @param updates  List of records to update
     */
    dataRaptorUpdates(updates) {   

        if (this.updateDataraptor && updates !== undefined && updates.length > 0) {

            // Setup the call
            let inputData  = {
                bundleName: this.updateDataraptor,
                bulkUpload: false,
                ignoreCache: true,
                inputType: "JSON",
                objectList: updates
            };
            let optionData = {
                useQueuableApexRemoting: false
            };

            let request = {
               sClassName: this.namespace + ".DefaultDROmniScriptIntegration",
               sMethodName: "invokeInboundDR",
               input: JSON.stringify(inputData),
               options: JSON.stringify(optionData)
            };         
            if (this.debug) {
                console.log("Calling DataRaptor '" + this.updateDataraptor + "' with payload -> " + JSON.stringify(updates));
                //console.log("Raw DataRaptor Request -> " + JSON.stringify(request));
            } 

            // Call the DataRaptor
            super.omniRemoteCall(request, true).then(response => {

                if (response.result && response.result.IBDRresp && response.result.IBDRresp.hasErrors) console.error("DataRaptor Error -> " + JSON.stringify(response));
                else if (this.debug) console.log("DataRaptor Response -> " + JSON.stringify(response));

            }).catch(error => {
                console.error("DataRaptor Error -> " + JSON.stringify(error));
            });
        }
    }
}