var ss = SpreadsheetApp.getActiveSpreadsheet();  
var ui = SpreadsheetApp.getUi();

function onOpen() {
    ui.createMenu('Script')
    .addItem('Run', 'Expand')
    .addToUi();
  }
  
function newSheet() {
  var yourNewSheet = ss.getSheetByName("Results");

    if (yourNewSheet != null) {
        ss.deleteSheet(yourNewSheet);
    }
    yourNewSheet = ss.insertSheet();
    yourNewSheet.setName("Results");
}


function Expand() {
  
  var currentSheet = ss.getActiveSheet();
  newSheet();
  var desiredOutcomeSheet = ss.getSheetByName('Results');
  var data = currentSheet.getRange(1, 1, currentSheet.getLastRow(), currentSheet.getLastColumn()+1).getValues();
  var jiraNumbers = [];
  var applications = [];
  var issueNumbers = "",
      hasComma = false,
      arrayOfIssueNumbers = [],
      arrayRowData = [],
      thisRowData,
      hasNewLine;

  // loop through each row
  for (var i=0;i<data.length;i+=1) {
    
    issueNumbers = data[i][0];
    hasComma = issueNumbers.indexOf(",") !== -1;
    hasNewLine = issueNumbers.indexOf("\n") !== -1;
    // if no multiple issue numbers
    if (!hasComma && !hasNewLine) {
      if (i===0) {
        data[i].splice(0, 1, "Module");
        data[i].splice(1, 0, "Change");
      }
      // not first line and doesn't have multiple change numbers
      else {
        var jiraNumber = data[i][0].split("|").slice(2,3);
        var application = data[i][0].split("|").slice(1,2);
        var module = data[i][0].split("|").slice(0,1);
        data[i].splice(0, 1, module[0].concat(" ",application[0]));
        data[i].splice(1, 0, jiraNumber[0]);
      }
      desiredOutcomeSheet.appendRow(data[i]);
    }
    
    // else, has multiple issue numbers
    else {
      // initialize arrays for each row
      arrayOfIssueNumbers = [];
      jiraNumbers = [];
      applications = [];

      // If the cell has a new line in it, split the cell into an array and then back into a string with each line separated by commas.
      if (hasNewLine) {
        var arrayNewNewLine = issueNumbers.split("\n");//Get rid of new line
        issueNumbers = arrayNewNewLine.toString(); //Back to string.  Handles cells with both new line and commas
        arrayOfIssueNumbers = issueNumbers.split(",");
        //
      }
      arrayOfIssueNumbers.forEach (function(issueNumber) {
        var jiraNumber = issueNumber.split("|").slice(2,3);
        var moduleAndApp = issueNumber.split("|").slice(0,2);
        jiraNumbers.push(jiraNumber);
        applications.push(moduleAndApp);
      });
    
      // loop through once for every new line in the cell being split. Example // 3 change numbers will loop here 3 times and create 3 new rows below
      for (var j=0;j<arrayOfIssueNumbers.length;j+=1) {
        arrayRowData = []; //Reset
        thisRowData = data[i];
        // loop through each cell in the row and push it to arrayRowData to create new row
        for (var k=0;k<thisRowData.length;k+=1) {
          arrayRowData.push(thisRowData[k]);
        }

        var application = applications[j][1];
        var module = applications[j][0];
        arrayRowData.splice(0, 1, module.concat(" ",application));
        arrayRowData.splice(1, 0, jiraNumbers[j][0]);
        // Add change number as required association to other change numbers on that same jira
        var requiredAssociations = arrayRowData[8];
        if (requiredAssociations) {
          for (var l=0;l<jiraNumbers.length;l+=1) {
            requiredAssociations = requiredAssociations.concat(" ",module," ",application," ",jiraNumbers[l][0]);
          }
        arrayRowData[8] = requiredAssociations;
        }
        // Append finalized data to new sheet
        desiredOutcomeSheet.appendRow(arrayRowData);
      }
    }
  }
  // Only sort from row 2 down and then freeze the first row
  var sortRange = desiredOutcomeSheet.getRange(2, 1, desiredOutcomeSheet.getLastRow() - 1, desiredOutcomeSheet.getLastColumn());
  sortRange.sort(1);
  desiredOutcomeSheet.setFrozenRows(1);
  var formatRange = desiredOutcomeSheet.getRange(2, 6, desiredOutcomeSheet.getLastRow() - 1, desiredOutcomeSheet.getLastColumn());
  formatRange.setWrap(true);
  desiredOutcomeSheet.autoResizeColumns(1,5);
  desiredOutcomeSheet.setColumnWidth(6, 300);
  desiredOutcomeSheet.setColumnWidths(8, 2, 300);
}
