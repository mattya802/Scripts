//
// Requirements:  Need to enable the following Advanced Google Services: Admin SDK and Calendar API
//                 
//
// Global variables
var startPeriod = new Date();        // now
var endPeriod = new Date();
endPeriod.setDate(startPeriod.getDate() + 180);   // 180 days from now

function syncTimeOff() {
  // Define source calendars to "pull" time off events from
  var sources = [
    // Insert source calendars here
    CalendarApp.getCalendarById('source1@gmail.com'),
    CalendarApp.getCalendarById('source2@gmail.com')
  ];
  // Define target calendars
  var targets = [
    // Insert target calendars here
    CalendarApp.getCalendarById('target1@gmail.com'),
    CalendarApp.getCalendarById('target2@gmail.com')
  ];
  // Loop through the source calendars
  sources.forEach( function(source) {
    checkCalendar(source,targets);
  });
  // Loop through the targets and check for modified or deleted events
  targets.forEach( function(target) {
    targetMaybeDeleteEvent(target);
    targetMaybeModifyEvent(target);
    Utilities.sleep(100);
  });
  var debug = Logger.getLog();
}

function checkCalendar(source,targets) {
  //
  // Get events from source calendars
  var calendarId = source.getId();
  var events = Calendar.Events.list(calendarId, {
    timeMin: startPeriod.toISOString(),
    timeMax: endPeriod.toISOString(),
    singleEvents: true,
    orderBy: 'startTime',
    q: "Time off",
  });
  events.items.forEach( function(event) {
  // Loop through events and call maybeCopyEvent
  maybeCopyEvent(source,targets,event);
  // For each source event, loop through the targets and check if we need to remove Pending
  targets.forEach(function (target) {
    targetMaybeRemovePending(source,target,event);
    });
  Utilities.sleep(100); 
  });
}

function maybeCopyEvent(source,targets,event) {
  var calendarId = source.getId();
  var result = AdminDirectory.Users.get(calendarId, {fields:'name',viewType:'domain_public'});
  var fullName = result.name.fullName;
  var newTitle = fullName.concat(" ",event.summary);
  // We're still within the loop of each source event. Now loop through the targets and determine if we need to create a new event or not.
  targets.forEach(function (target) {
    if (event.start.date) {
      targetMaybeCreateAllDayEvent(newTitle,event,target,calendarId);
      }
    else {
      targetMaybeCreateEvent(newTitle,event,target,calendarId);
      }
  });
}

function targetMaybeCreateAllDayEvent(newTitle,event,target,calendarId) {
  var tempStartTime = new Date(event.start.date);
  // Necessary to add 4 hours due to the way date is stored for AllDayEvents
  var startTime = new Date(tempStartTime.getTime() + 4 * 60 * 60 * 1000);
  var tempEndTime = new Date(event.end.date);
  var endTime = new Date(tempEndTime.getTime() + 4 * 60 * 60 * 1000);
  var targetEventsInTimeFrame = target.getEvents(startTime,endTime,{search:newTitle});
  // Only create if the event doesn't already exist in the target calendar
  if(targetEventsInTimeFrame.length===0) {
    target.createAllDayEvent(newTitle,startTime,endTime,{description:calendarId});
  }
}

function targetMaybeCreateEvent(newTitle,event,target,calendarId) {
  var startTime = new Date(event.start.dateTime);
  var endTime = new Date(event.end.dateTime);
  var targetEventsInTimeFrame = target.getEvents(startTime,endTime,{search:newTitle});
  // Only create if the event doesn't already exist in the target calendar
  if(targetEventsInTimeFrame.length===0) {
    target.createEvent(newTitle,startTime,endTime,{description:calendarId});
  }
}

function targetMaybeDeleteEvent(target) {
  // Loop through target calendar events and confirm event still exists in source. If it does not, then delete in the target.
  // This functionality relies on having the calendarId (email address) in the desription of the event in the target. If that is not present, entries could be mistakenly deleted.
  //
  var targetEvents = target.getEvents(startPeriod,endPeriod);
  targetEvents.forEach(function (targetEvent) {
    var targetStartTime = targetEvent.getStartTime();
    var targetEndTime = targetEvent.getEndTime();
    var sourceId = targetEvent.getDescription();
    var sourceEvents = Calendar.Events.list(sourceId, {
    timeMin: targetStartTime.toISOString(),
    timeMax: targetEndTime.toISOString(),
    singleEvents: true,
    orderBy: 'startTime',
    q: "Time off",
    });
    if (sourceEvents.items.length===0) {
    targetEvent.deleteEvent();
    }
  });    
}

function targetMaybeModifyEvent(target) {
  // Loop through the target calendar events and check for any modifications to startTime and endTime in the source calendar. Adjust as necessary.
  // This functionality relies on having the calendarId (email address) in the desription of the event in the target. If that is not present, entries could be mistakenly deleted.
  //
  var targetEvents = target.getEvents(startPeriod,endPeriod);
  var allDayEvent = "";
  targetEvents.forEach(function (targetEvent) {
    var targetStartTime = targetEvent.getStartTime();
    var targetEndTime = targetEvent.getEndTime();
    var sourceId = targetEvent.getDescription();
    var sourceCalendar = CalendarApp.getCalendarById(sourceId);
    var sourceEvents = Calendar.Events.list(sourceId, {
    timeMin: targetStartTime.toISOString(),
    timeMax: targetEndTime.toISOString(),
    singleEvents: true,
    orderBy: 'startTime',
    q: "Time off",
    });
    sourceEvents.items.forEach(function (sourceEvent) {
    // If this is not an all day event, then use dateTime for sourceStart and EndTime
    if (sourceEvent.end.dateTime) {
      var sourceStartTime = new Date(sourceEvent.start.dateTime);
      var sourceEndTime = new Date(sourceEvent.end.dateTime);
    }
    // Else if this IS an all day event, use start.date for Start and EndTime. Also need to add 4 hours due to the way dates are stored with AllDayEvents.
    else {
      var startDate = new Date(sourceEvent.start.date);
      var sourceStartTime = new Date(startDate.getTime() + 4 * 60 * 60 * 1000);
      var endDate = new Date(sourceEvent.end.date);
      var sourceEndTime = new Date(endDate.getTime() + 4 * 60 * 60 * 1000);
      var allDayEvent = 1;
    }
    if (targetStartTime.getTime() != sourceStartTime.getTime()) {
      if (targetEndTime.getTime() != sourceEndTime.getTime()) {
        setNewStartAndEndDate(targetEvent,sourceStartTime,sourceEndTime,allDayEvent);
      }
      else {
        setNewStartAndEndDate(targetEvent,sourceStartTime,sourceEndTime,allDayEvent);
      }
    }
      else {
        if (targetEndTime.getTime() != sourceEndTime.getTime()) {
          setNewStartAndEndDate(targetEvent,sourceStartTime,sourceEndTime,allDayEvent);
        }
      }
    });
  });
}
    
function setNewStartAndEndDate(targetEvent,sourceStartTime,sourceEndTime,allDayEvent) {
  if (allDayEvent) {
    targetEvent.setAllDayDates(sourceStartTime,sourceEndTime);
    }
  else {
    targetEvent.setTime(sourceStartTime,sourceEndTime);
    }
}

function targetMaybeRemovePending(source,target,event) {
  // Loop through the target calendar events and compare to the associated source calendar event. If source is no longer "PENDING", then remove "PENDING" from the target title. 
  // 
  var title = event.summary;
  var startTime = new Date(event.start.dateTime);
  var endTime = new Date(event.end.dateTime);
  var targetEventsInTimeFrame = target.getEvents(startTime,endTime,{search:title});
  targetEventsInTimeFrame.forEach(function (targetEvent) {
  if ((title.indexOf("PENDING")) === -1 && (targetEvent.getTitle().indexOf("PENDING"))>-1 && ((targetEvent.getDescription()) === (source.getId()))) {
    var currentTitle = targetEvent.getTitle();
    var newTitle = currentTitle.replace(" PENDING:","");
    targetEvent.setTitle(newTitle);
  }
  });
}
