/*
  This custom LWC renders a list of appointments that a user can select.  The appointments
  are in the following form and provided by the Integration Procedure called 'Demo_GetAppointments':

  [
      {
          "Slot": "8:00am - 9:00am",
          "Date": "2021-04-13"
      },
      {
          "Slot": "4:00pm - 5:00pm",
          "Date": "2021-04-13"
      },
      {
          "Slot": "8:00am - 9:00am",
          "Date": "2021-04-14"
      }
      ....
  ]
  
  @author Joe McMaster
  @version 1.1
    
  History
  =======
  Apr 13, 2021 - v1.0 - Initial version

  Configuration
  =============
  Set the following custom LWC properties in OmniScript to configure this component
  
  appointments - (Mandatory) - Points to the list of appointments in the following form

*/
import { LightningElement, api, track } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_cmt/omniscriptBaseMixin';
import { getDataJson } from 'c/demo_os_utils';

export default class demo_wfm_appointment_booker extends OmniscriptBaseMixin(LightningElement) {

    @api
    get appointments() {
        return this._appointments;
    }

    // Initialize the appointments
    set appointments(data) {

        try {

            if (data) {
                
                // Organizes a flat list of appointments into a better, hierarchical structure so we can display
                // it on the page by day.  Appointments will be organized into a list/day                
                let days = [];

                for (let appt of data) {

                    // Find the day if it is already in the list
                    let day;
                    for(let d of days) {
                        if (d.date == appt.Date) {
                            day = d;
                            break;
                        }
                    }

                    // If we didn't find the day, add it
                    if (!day) {
                        day = {
                            date: appt.Date,
                            dateLabel: new Intl.DateTimeFormat('en-US', {dateStyle: 'medium'}).format(new Date(appt.Date)),
                            dayLabel: new Intl.DateTimeFormat('en-US', {weekday: 'long'}).format(new Date(appt.Date)),
                            timeslots: []
                        };
                        days.push(day);
                    }

                    // Add the timeslot
                    day.timeslots.push({
                        id: appt.Date + " " + appt.Slot,
                        slot: appt.Slot,
                        selected: false
                    });
                }

                this._appointments = days;

                // If we've back-stepped onto this Step refresh any selected appointment from the OmniScript data
                this.setSelectedAppointment();
            }
        } catch (err) {
            console.error("Error in set appointments() -> " + err);
        }
    }

    @track _appointments = []; // track this variable so that the UI is re-rendered upon any changes (i.e. appointment selection)


    /**
     * Programmtically selects products based on what has been selected in the past (i.e. if we backstep in the OmniScript)
     * 
     */
    setSelectedAppointment() {

        // If we back back-stepped into this component, check the OmniScript data to determine if any
        // have been selected in the past
        let selection = getDataJson(this);
        if (selection) {

            let id = selection.id;

            // Find the appointment and select it programmtically
            for (let day of this._appointments) {
                for (let slot of day.timeslots) {
                    if (id == slot.id) slot.selected = true;
                }
            }
        }
    }

    /**
     * Selects an Appointment Slot
     * 
     * @param event  The selection event
     */
    selectAppointment(event) {

        try {

            // Find the timeslot Id that was selected
            var timeslotId = event.target.dataset.id;

            // Go through the timeslots and deslect everything (except the new one)
            for (let day of this._appointments) {
                for (let slot of day.timeslots) {
                    if (slot.id == timeslotId) {
                        slot.selected = !slot.selected;

                        // If the slot is selected (still) add it to the OmniScript JSON
                        if (slot.selected) super.omniUpdateDataJson(slot);
                        else super.omniUpdateDataJson(null);
                    }
                    else slot.selected = false;
                }
            }
        }
        catch(err) {
            console.error("Error in selectAppointment -> " + err);
        }
    }
}