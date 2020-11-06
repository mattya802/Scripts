var ui = SpreadsheetApp.getUi();
var sheet = SpreadsheetApp.getActiveSpreadsheet();
var contactSheet = sheet.getSheetByName('Contacts');
var orderSheet = sheet.getSheetByName('Orders');
var partySheet = sheet.getSheetByName('Parties');

function onOpen() {
  ui.createMenu('Script')
  .addItem('getPartyProfitTotal', 'getPartyProfitTotal')
  .addItem('getPersonProfitTotal', 'getPersonProfitTotal')
  .addToUi();
}

function onEdit() {
  var lock = LockService.getScriptLock();
  lock.waitLock(100000);
  var activeSheet = sheet.getActiveSheet();
  var activeCell = sheet.getActiveCell();
  var activeColumn = activeCell.getColumn();
  if (activeSheet.getName() === "Orders" && (activeColumn == 6 || activeColumn == 5)) {
    getPartyProfitTotal();
    getPersonProfitTotal();
  }
  lock.releaseLock();
}

function getPartyProfitTotal() {
  var orderColumns = orderSheet.getRange(2,3,orderSheet.getLastRow()-1,5);
  var orders = orderColumns.getValues(); // party name in [x][0] and profits in [x][4]
  var newTotal = 0;
  partySheet.getRange(2,3,partySheet.getLastRow()-1).setValue(0);
  for(var i=0; i<orders.length; i++) {
    if (orders[i][0]) {
      var party = orders[i][0];
      var textFinder = partySheet.createTextFinder(party);
      var searchRow = textFinder.findNext().getRow();
      Logger.log("orders",orders[i][4],"row",searchRow);
      newTotal = (partySheet.getRange(searchRow,3).getValue() + orders[i][4]);
      partySheet.getRange(searchRow,3).setValue(newTotal);
    }
  }
}

function getPersonProfitTotal() {
  var orderColumns = orderSheet.getRange(2,1,orderSheet.getLastRow()-1,7);
  var orders = orderColumns.getValues(); // person name in [x][0] party name in [x][2] and profits in [x][6]
  var newTotal = 0;
  contactSheet.getRange(2,5,contactSheet.getLastRow()-1).setValue(0);
  for(var i=0; i<orders.length; i++) {
    if (orders[i][0]) {
      var person = orders[i][0];
      var textFinder = contactSheet.createTextFinder(person);
      var searchRow = textFinder.findNext().getRow();
      newTotal = (contactSheet.getRange(searchRow,5).getValue() + orders[i][6]);
      contactSheet.getRange(searchRow,5).setValue(newTotal);
    }
  }
}
