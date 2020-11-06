// This program will remove all events from a calendar. This is meant to be used to clear out a "Time Off" calendar, so that all entries can be re-added with the appropriate calendarId in the description. 
// The calendarId is required for the proper handling of modified and cancelled events.
function clearCalendar() {
  // Define which calendars you want to clear
  var targets = [
    // Enter your target calender here:
  ];
  var startPeriod = new Date();        // now
  var endPeriod = new Date();
  endPeriod.setDate(startPeriod.getDate() + 365);   // 365 days from now
    //if (Browser.msgBox("All target calendars will have ALL events deleted. Are you sure you want to continue?",Browser.Buttons.YES_NO) === "yes") {
     targets.forEach( function(target) {
      var targetEvents = target.getEvents(startPeriod,endPeriod);
    targetEvents.forEach( function(targetEvent) {
      targetEvent.deleteEvent();
      Utilities.sleep(200);
    });
  });
//}
}
