/*##################################################################################################
##
##  Nexgen Advanced Ban Manager version 2.00
##  Copyright (C) 2020 Patrick "Sp0ngeb0b" Peltzer
##
##  This program is free software; you can redistribute and/or modify
##  it under the terms of the Open Unreal Mod License version 1.1.
##
##  Contact: spongebobut@yahoo.com | www.unrealriders.eu
##
##################################################################################################*/
class NexgenABMBanPanel extends NexgenRCPBanControl;

var NexgenSimpleListBox HWidList;
var NexgenSimpleListBox MACList;
var NexgenSimpleListBox HNList;
var UWindowSmallButton addHWidButton;
var UWindowSmallButton delHWidButton;
var UWindowSmallButton addMACButton;
var UWindowSmallButton delMACButton;
var UWindowSmallButton addHNButton;
var UWindowSmallButton delHNButton;
var UWindowEditControl HWidInp;
var UWindowEditControl MACInp;
var UWindowEditControl HNInp;
var NexgenEditControl SearchInp;
var UWindowComboControl SearchType;
var UWindowSmallButton resetFields;
var NexgenEditControl bannerNameInp;

var NexgenABMClient xClient;
var NexgenSharedDataContainer BanData;

const maxMasksLength = 200;


/***************************************************************************************************
 *
 *  $DESCRIPTION  Creates the contents of the panel.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function setContent() {
  local NexgenContentPanel p;
  local int region;
  local int index;
  
  // Retrieve client controller interface.
  xClient = NexgenABMClient(client.getController(class'NexgenABMClient'.default.ctrlID));

  // Create layout & add components.
  createWindowRootRegion();
  splitRegionV(160, defaultComponentDist);
  splitRegionH(60, defaultComponentDist);

  // Ban entry editor.
  p = addContentPanel();

  // Player name & ban reason.
  region = p.splitRegionH(60, defaultComponentDist) + 1;
  p.splitRegionV(96);
  p.skipRegion();
  p.divideRegionH(3);
  p.divideRegionH(3);
  p.addLabel(client.lng.playerNameTxt, true);
  p.addLabel(client.lng.banReasonTxt, true);
  p.addLabel("Admin:", true);
  playerNameInp = p.addEditBox();
  banReasonInp  = p.addEditBox();
  bannerNameInp = p.addEditBox();

  // Ban period.
  p.selectRegion(region);
  p.selectRegion(p.splitRegionH(64, defaultComponentDist));
  region = p.currRegion + 1;
  p.splitRegionH(1);
  p.skipRegion();
  p.addComponent(class'NexgenDummyComponent');
  p.splitRegionV(96);
  p.divideRegionH(3);
  p.splitRegionV(96, defaultComponentDist);
  p.addLabel(client.lng.banPeriodTxt, true);
  p.skipRegion();
  p.skipRegion();
  p.divideRegionH(3);
  p.divideRegionH(3);
  banPeriodInp[0] = p.addCheckBox(TA_Left, client.lng.banForeverTxt);
  banPeriodInp[1] = p.addCheckBox(TA_Left, client.lng.banMatchesTxt);
  banPeriodInp[2] = p.addCheckBox(TA_Left, client.lng.banUntilDateTxt);
  p.skipRegion();
  matchCountInp = p.addEditBox();
  dateInp = p.addEditBox();

  // Banned IP's and ID's.
  p.selectRegion(region);
  p.selectRegion(p.splitRegionH(1, defaultComponentDist));
  p.addComponent(class'NexgenDummyComponent');
  p.divideRegionH(5, defaultComponentDist);
  p.splitRegionV(224, defaultComponentDist, , true);
  p.splitRegionV(224, defaultComponentDist, , true);
  p.splitRegionV(224, defaultComponentDist, , true);
  p.splitRegionV(224, defaultComponentDist, , true);
  p.splitRegionV(224, defaultComponentDist, , true);
  p.splitRegionH(56);
  ipList   = NexgenSimpleListBox(p.addListBox(class'NexgenSimpleListBox'));
  p.splitRegionH(56);
  idList   = NexgenSimpleListBox(p.addListBox(class'NexgenSimpleListBox'));
  p.splitRegionH(56);
  HWidList = NexgenSimpleListBox(p.addListBox(class'NexgenSimpleListBox'));
  p.splitRegionH(56);
  MACList  = NexgenSimpleListBox(p.addListBox(class'NexgenSimpleListBox'));
  p.splitRegionH(56);
  HNList  = NexgenSimpleListBox(p.addListBox(class'NexgenSimpleListBox'));
  p.divideRegionH(3);
  p.skipRegion();
  p.divideRegionH(3);
  p.skipRegion();
  p.divideRegionH(3);
  p.skipRegion();
  p.divideRegionH(3);
  p.skipRegion();
  p.divideRegionH(3);
  p.skipRegion();
  p.addLabel(client.lng.ipAddressesTxt, true);
  p.divideRegionV(2, defaultComponentDist);
  ipAddressInp = p.addEditBox();
  p.addLabel(client.lng.clientIDsTxt, true);
  p.divideRegionV(2, defaultComponentDist);
  clientIDInp = p.addEditBox();
  p.addLabel("Hardware IDs", true);
  p.divideRegionV(2, defaultComponentDist);
  HWidInp = p.addEditBox();
  p.addLabel("MAC Hashes", true);
  p.divideRegionV(2, defaultComponentDist);
  MACInp  = p.addEditBox();
  p.addLabel("Hostnames", true);
  p.divideRegionV(2, defaultComponentDist);
  HNInp  = p.addEditBox();
  addIPButton   = p.addButton(client.lng.addTxt);
  delIPButton   = p.addButton(client.lng.removeTxt);
  addIDButton   = p.addButton(client.lng.addTxt);
  delIDButton   = p.addButton(client.lng.removeTxt);
  addHWidButton = p.addButton(client.lng.addTxt);
  delHWidButton = p.addButton(client.lng.removeTxt);
  addMACButton  = p.addButton(client.lng.addTxt);
  delMACButton  = p.addButton(client.lng.removeTxt);
  addHNButton   = p.addButton(client.lng.addTxt);
  delHNButton  = p.addButton(client.lng.removeTxt);
  
  // Ban list editor.
  p = addContentPanel();
  p.divideRegionH(3);
  addBanButton = p.addButton(client.lng.addBanTxt);
  updateBanButton = p.addButton(client.lng.updateBanTxt);
  deleteBanButton = p.addButton(client.lng.delBanTxt);

  splitRegionH(220, defaultComponentDist);
  
  // Ban list.
  banList = NexgenSimpleListBox(addListBox(class'NexgenSimpleListBox'));
  
  splitRegionH(72, defaultComponentDist);
  
  // Search panel.
  p = addContentPanel();
  p.splitRegionH(10, defaultComponentDist);
  p.addLabel("Ban search", true);
  p.divideRegionH(2, defaultComponentDist);
  SearchInp  = p.addEditBox(, 96, AL_Left);
  SearchType = p.addListCombo();
  
  // Button Panel 2
  splitRegionH(28, defaultComponentDist);
  p = addContentPanel();
  resetFields  = p.addButton("Reset Fields");
  
  splitRegionH(24, , , true);

  // Wildcards panel.
  p = addContentPanel();
  p.splitRegionH(10, defaultComponentDist);
  p.addLabel("Wildcards", true);
  p.splitRegionH(14, defaultComponentDist);
  p.addLabel("For IP adresses and hostnames:");
  p.splitRegionH(14, defaultComponentDist);
  p.addLabel("* = X chars; ? = 1 char");

  // Credits Panel
  p = addContentPanel();
  p.addLabel("NexgenABM by Sp0ngeb0b", true);

  
  // Configure components.
  ipAddressInp.setMaxLength(maxMasksLength);
  clientIDInp.setMaxLength(32);
  HWidInp.setMaxLength(32);
  MACInp.setMaxLength(32);
  HNInp.setMaxLength(maxMasksLength);
  playerNameInp.setMaxLength(32);
  banReasonInp.setMaxLength(255);
  bannerNameInp.setDisabled(true);
  matchCountInp.setMaxLength(3);
  matchCountInp.setNumericOnly(true);
  dateInp.setMaxLength(24);
  SearchInp.setMaxLength(32);
  banList.register(self);
  ipList.register(self);
  idList.register(self);
  HWidList.register(self);
  MACList.register(self);
  HNList.register(self);
  addIPButton.register(self);
  delIPButton.register(self);
  addIDButton.register(self);
  delIDButton.register(self);
  addHWidButton.register(self);
  delHWidButton.register(self);
  addMACButton.register(self);
  delMACButton.register(self);
  addHNButton.register(self);
  delHNButton.register(self);
  addBanButton.register(self);
  updateBanButton.register(self);
  deleteBanButton.register(self);
  for (index = 0; index < arrayCount(banPeriodInp); index++) {
    banPeriodInp[index].register(self);
  }
  SearchInp.register(self);
  SearchType.register(self);
  resetFields.register(self);
  loadSearchType();
  loadBanList();
  banPeriodInp[0].bChecked = true;
  banPeriodTypeSelected();
  delIPButton.bDisabled = true;
  delIDButton.bDisabled = true;
  delHWidButton.bDisabled = true;
  delMACButton.bDisabled = true;
  delHNButton.bDisabled = true;
  dateInp.setValue(client.lng.dateFormatStr);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when the initial synchronization of the given shared data container is
 *                done. After this has happend the client may query its variables and receive valid
 *                results (assuming the client is allowed to read those variables).
 *  $PARAM        container  The shared data container that has become available for use.
 *  $REQUIRE      container != none
 *  $OVERRIDE
 *
 **************************************************************************************************/
function dataContainerAvailable(NexgenSharedDataContainer container) {
  if (container.containerID == class'NexgenABMBanListDC'.default.containerID) {
    BanData = container;
    loadBanList();
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Loads the Search type list.
 *
 **************************************************************************************************/
function loadSearchType() {
  SearchType.addItem("Search by ... Name", "0");
  SearchType.addItem("Search by ... Reason", "1");
  SearchType.addItem("Search by ... Admin", "2");
  SearchType.addItem("Search by ... IP", "3");
  SearchType.addItem("Search by ... ID", "4");
  SearchType.addItem("Search by ... HWid", "5");
  SearchType.addItem("Search by ... MACHash", "6");
  SearchType.addItem("Search by ... Hostname", "7");

  SearchType.setSelectedIndex(0);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Load the banlist.
 *
 **************************************************************************************************/
function loadBanList() {
  local int index;
  local NexgenSimpleListItem item;
  local int numBans;
  local bool shouldBeAdded;
  local string SearchString;
  
  // Clear list.
  banList.items.clear();
  banList.selectedItem = none;
  
  if(BanData == none) {
    item = NexgenSimpleListItem(banList.items.append(class'NexgenSimpleListItem'));
    item.displayText = "Receiving ban list,";
    item = NexgenSimpleListItem(banList.items.append(class'NexgenSimpleListItem'));
    item.displayText = "please wait ...";
    addBanButton.bDisabled    = true;
    updateBanButton.bDisabled = true;
    deleteBanButton.bDisabled = true;
    SearchInp.setDisabled(true);
    resetFields.bDisabled = true;
    return;
  }
  
  SearchInp.setDisabled(false);
  SearchString = class'NexgenUtil'.static.trim(SearchInp.getValue());
  resetFields.bDisabled = False;
  
  // Add bans.
  while(index < BanData.getArraySize("bannedName") && BanData.getString("bannedName", index) != "") {
    if(SearchString == "" || banShouldBeAdded(index, searchString)) {
      item = NexgenSimpleListItem(banList.items.append(class'NexgenSimpleListItem'));
      item.displayText = BanData.getString("bannedName", index);
      item.itemID = index;
    }
    index++;
  }
  
  // Configure components.
  numBans = index;
  addBanButton.bDisabled = numBans >= BanData.getArraySize("bannedName");
  banSelected();
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Checks whether a specific ban entry should be added.
 *  $PARAM        index         Ban index which is to be checked.
 *  $PARAM        searchString  String which has to be found inside the ban entry.
 *  $RETURN       Whether the ban entry should be added to the list.
 *
 **************************************************************************************************/
function bool banShouldBeAdded(int index, string searchString) {

  switch(SearchType.getSelectedIndex()) {
    case 0: if(InStr(CAPS(BanData.getString("bannedName", index)), CAPS(SearchString)) != -1) return true; break;
    case 1: if(InStr(CAPS(BanData.getString("banReason", index)), CAPS(SearchString)) != -1) return true; break;
    case 2: if(InStr(CAPS(BanData.getString("bannerName", index)), CAPS(SearchString)) != -1) return true; break;
    case 3: if(InStr(CAPS(BanData.getString("bannedIPs", index)), CAPS(SearchString)) != -1) return true; break;
    case 4: if(InStr(CAPS(BanData.getString("bannedIDs", index)), CAPS(SearchString)) != -1) return true; break;
    case 5: if(InStr(CAPS(BanData.getString("bannedHWIDs", index)), CAPS(SearchString)) != -1) return true; break;
    case 6: if(InStr(CAPS(BanData.getString("bannedMACHashes", index)), CAPS(SearchString)) != -1) return true; break;
    case 7: if(InStr(CAPS(BanData.getString("bannedHostnames", index)), CAPS(SearchString)) != -1) return true; break;
  }
  
  return false;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Loads the information for the specified ban entry.
 *  $PARAM        entryNum  The entry number in the ban list.
 *  $REQUIRE      0 <= entryNum && entryNum < arrayCount(client.sConf.bannedName) &&
 *                client.sConf.bannedName[entryNum] != ""
 *
 **************************************************************************************************/
function loadBanInfo(int entryNum) {
  local string remaining, part;
  local NexgenSimpleListItem item;
  local byte banPeriodType;
  local string banArgs;
  local int index;
  
  // Player name & ban reason.
  playerNameInp.setValue(BanData.getString("bannedName", entryNum));
  banReasonInp.setValue(BanData.getString("banReason", entryNum));
  bannerNameInp.setValue(BanData.getString("bannerName", entryNum));
  
  // Ban period.
  class'NexgenConfig'.static.getBanPeriodType(BanData.getString("banPeriod", entryNum), banPeriodType, banArgs);
  for (index = 0; index < arrayCount(banPeriodInp); index++) {
    banPeriodInp[index].bChecked = index == banPeriodType;
  }
  if (banPeriodType == client.sConf.BP_Matches) {
    matchCountInp.setDisabled(false);
    matchCountInp.setValue(banArgs);
    dateInp.setDisabled(true);
    dateInp.setValue(client.lng.dateFormatStr);
  } else if (banPeriodType == client.sConf.BP_UntilDate) {
    matchCountInp.setDisabled(true);
    matchCountInp.setValue("");
    dateInp.setDisabled(false);
    dateInp.setValue(client.lng.getLocalizedDateStr(banArgs));
  } else {
    matchCountInp.setDisabled(true);
    matchCountInp.setValue("");
    dateInp.setDisabled(true);
    dateInp.setValue(client.lng.dateFormatStr);
  }
  
  // Load ip addresses.
  ipList.items.clear();
  ipList.selectedItem = none;
  remaining = BanData.getString("bannedIPs", entryNum);
  while (remaining != "") {
    // Split head element from tail.
    class'NexgenUtil'.static.split(remaining, part, remaining);
    part = class'NexgenUtil'.static.trim(part);

    // Add element to list.
    item = NexgenSimpleListItem(ipList.items.append(class'NexgenSimpleListItem'));
    item.displayText = part;
  }
  addIPButton.bDisabled = Len(BanData.getString("bannedIPs", entryNum)) >= maxMasksLength;
  delIPButton.bDisabled = true;
  clientIDInp.setMaxLength(maxMasksLength - Len(BanData.getString("bannedIPs", entryNum)));

  // Load client id's.
  idList.items.clear();
  idList.selectedItem = none;
  remaining = BanData.getString("bannedIDs", entryNum);
  while (remaining != "") {
    // Split head element from tail.
    class'NexgenUtil'.static.split(remaining, part, remaining);
    part = class'NexgenUtil'.static.trim(part);
    
    // Add element to list.
    item = NexgenSimpleListItem(idList.items.append(class'NexgenSimpleListItem'));
    item.displayText = part;
  }
  addIDButton.bDisabled = idList.items.countShown() >= client.sConf.maxBanClientIDs;
  delIDButton.bDisabled = true;
  
  // Load HW IDs.
  HWidList.items.clear();
  HWidList.selectedItem = none;
  remaining = BanData.getString("bannedHWIDs", entryNum);
  while (remaining != "") {
    // Split head element from tail.
    class'NexgenUtil'.static.split(remaining, part, remaining);
    part = class'NexgenUtil'.static.trim(part);
    
    // Add element to list.
    item = NexgenSimpleListItem(HWidList.items.append(class'NexgenSimpleListItem'));
    item.displayText = part;
  }
  addHWidButton.bDisabled = HWidList.items.countShown() >= client.sConf.maxBanClientIDs;
  delHWidButton.bDisabled = true;
  
  // Load MAC hashes.
  MACList.items.clear();
  MACList.selectedItem = none;
  remaining = BanData.getString("bannedMACHashes", entryNum);
  while (remaining != "") {
    // Split head element from tail.
    class'NexgenUtil'.static.split(remaining, part, remaining);
    part = class'NexgenUtil'.static.trim(part);
    
    // Add element to list.
    item = NexgenSimpleListItem(MACList.items.append(class'NexgenSimpleListItem'));
    item.displayText = part;
  }
  addMACButton.bDisabled = MACList.items.countShown() >= client.sConf.maxBanClientIDs;
  delMACButton.bDisabled = true;
  
  // Load Hostnames.
  HNList.items.clear();
  HNList.selectedItem = none;
  remaining = BanData.getString("bannedHostnames", entryNum);
  while (remaining != "") {
    // Split head element from tail.
    class'NexgenUtil'.static.split(remaining, part, remaining);
    part = class'NexgenUtil'.static.trim(part);

    // Add element to list.
    item = NexgenSimpleListItem(HNList.items.append(class'NexgenSimpleListItem'));
    item.displayText = part;
  }
  addHNButton.bDisabled = Len(BanData.getString("bannedHostnames", entryNum)) >= maxMasksLength;
  delHNButton.bDisabled = true;
  HNInp.setMaxLength(maxMasksLength - Len(BanData.getString("bannedHostnames", entryNum)));
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Returns the client HWid's entered in the HWid list.
 *  $RETURN       A string containing all client HWid's entered in the id list.
 *
 **************************************************************************************************/
function string getHWidList() {
  local NexgenSimpleListItem item;
  local string list;
  
  // Assemble list.
  for (item = NexgenSimpleListItem(HWidList.items); item != none; item = NexgenSimpleListItem(item.next)) {
    if (item.displayText != "") {
      if (list == "") {
        list = item.displayText;
      } else {
        list = list $ separator $ item.displayText;
      }
    }
  }
  
  // Return the list.
  return list;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Returns the client MACHashes entered in the MACHash list.
 *  $RETURN       A string containing all client MACHashes entered in the MACHash list.
 *
 **************************************************************************************************/
function string getMACList() {
  local NexgenSimpleListItem item;
  local string list;
  
  // Assemble list.
  for (item = NexgenSimpleListItem(MACList.items); item != none; item = NexgenSimpleListItem(item.next)) {
    if (item.displayText != "") {
      if (list == "") {
        list = item.displayText;
      } else {
        list = list $ separator $ item.displayText;
      }
    }
  }
  
  // Return the list.
  return list;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Returns the client MACHashes entered in the MACHash list.
 *  $RETURN       A string containing all client MACHashes entered in the MACHash list.
 *
 **************************************************************************************************/
function string getHNList() {
  local NexgenSimpleListItem item;
  local string list;

  // Assemble list.
  for (item = NexgenSimpleListItem(HNList.items); item != none; item = NexgenSimpleListItem(item.next)) {
    if (item.displayText != "") {
      if (list == "") {
        list = item.displayText;
      } else {
        list = list $ separator $ item.displayText;
      }
    }
  }

  // Return the list.
  return list;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Notifies the dialog of an event (caused by user interaction with the interface).
 *  $PARAM        control    The control object where the event was triggered.
 *  $PARAM        eventType  Identifier for the type of event that has occurred.
 *  $REQUIRE      control != none
 *  $OVERRIDE
 *
 **************************************************************************************************/
function notify(UWindowDialogControl control, byte eventType) {
  local int index;
  local int selectedIndex;
  local string value;
  local NexgenSimpleListItem item;
  local string playerName;
  
  super(NexgenPanelContainer).notify(control, eventType);
  
  // Ban period type selected?
  if (eventType == DE_Click && control.isA('UWindowCheckbox')) {
    // Find selected type.
    selectedIndex = -1;
    while (selectedIndex < 0 && index < arrayCount(banPeriodInp)) {
      if (control == banPeriodInp[index]) {
        selectedIndex = index;
      } else {
        index++;
      }
    }

    // Has a period been selected?
    if (selectedIndex >= 0) {
      // Yes, update components.
      for (index = 0; index < arrayCount(banPeriodInp); index++) {
        banPeriodInp[index].bChecked = index == selectedIndex;
      }
      banPeriodTypeSelected();
    }
  }
  
  if(BanData == none) return;
  
  // Add ban entry button clicked?
  if (control == addBanButton && eventType == DE_Click && !addBanButton.bDisabled) {
    playerName = class'NexgenUtil'.static.trim(playerNameInp.getValue());
    if (playerName != "") {
      addBan(playerName, getIPList(), getIDList(), getHWidList(), getMACList(), getHNList(),
             class'NexgenUtil'.static.trim(banReasonInp.getValue()), getCurrentBanPeriod());
    }
  }
  
  // Update ban entry button clicked?
  if (control == updateBanButton && eventType == DE_Click && !updateBanButton.bDisabled) {
    playerName = class'NexgenUtil'.static.trim(playerNameInp.getValue());
    if (playerName != "" && NexgenSimpleListItem(banList.selectedItem) != none) {
      updateBan(NexgenSimpleListItem(banList.selectedItem).itemID,
                     playerName, getIPList(), getIDList(), getHWidList(), getMACList(), getHNList(),
                     class'NexgenUtil'.static.trim(banReasonInp.getValue()), getCurrentBanPeriod());
    }
  }
  
  // Delete ban entry button clicked?
  if (control == deleteBanButton && eventType == DE_Click && !deleteBanButton.bDisabled &&
      NexgenSimpleListItem(banList.selectedItem) != none) {
    deleteBan(NexgenSimpleListItem(banList.selectedItem).itemID);
  }
  
  // Ban entry selected?
  if (control == banList && eventType == DE_Click) {
    banSelected();
  }
  
  // IP address selected?
  if (control == ipList && eventType == DE_Click) {
    delIPButton.bDisabled = ipList.selectedItem == none;
    if (ipList.selectedItem != none) {
      ipAddressInp.setValue(NexgenSimpleListItem(ipList.selectedItem).displayText);
    }
  }

  // Client ID selected?
  if (control == idList && eventType == DE_Click) {
    delIDButton.bDisabled = idList.selectedItem == none;
    if (idList.selectedItem != none) {
      clientIDInp.setValue(NexgenSimpleListItem(idList.selectedItem).displayText);
    }
  }
  
  // HWid address selected?
  if (control == HWidList && eventType == DE_Click) {
    delHWidButton.bDisabled = HWidList.selectedItem == none;
    if (HWidList.selectedItem != none) {
      HWidInp.setValue(NexgenSimpleListItem(HWidList.selectedItem).displayText);
    }
  }
    
  // MAC Hash selected?
  if (control == MACList && eventType == DE_Click) {
    delMACButton.bDisabled = MACList.selectedItem == none;
    if (MACList.selectedItem != none) {
      MACInp.setValue(NexgenSimpleListItem(MACList.selectedItem).displayText);
    }
  }
  

  // Hostname selected?
  if (control == HNList && eventType == DE_Click) {
    delHNButton.bDisabled = HNList.selectedItem == none;
    if (HNList.selectedItem != none) {
      HNInp.setValue(NexgenSimpleListItem(HNList.selectedItem).displayText);
    }
  }
  
  
  // Add IP address pressed?
  if (control == addIPButton && eventType == DE_Click && !addIPButton.bDisabled) {
    value = class'NexgenUtil'.static.trim(ipAddressInp.getValue());
    item = NexgenSimpleListItem(ipList.items.append(class'NexgenSimpleListItem'));
    item.displayText = value;
    addIPButton.bDisabled = Len(getIPList()) >= maxMasksLength;
    clientIDInp.setMaxLength(maxMasksLength - Len(getIPList()) - Len(separator));
  }

  // Del IP address pressed?
  if (control == delIPButton && eventType == DE_Click && !delIPButton.bDisabled) {
    ipList.selectedItem.remove();
    ipList.selectedItem = none;
    delIPButton.bDisabled = true;
    addIPButton.bDisabled = Len(getIPList()) >= maxMasksLength;
    clientIDInp.setMaxLength(maxMasksLength - Len(getIPList()) - Len(separator));
  }

  // Add client ID pressed?
  if (control == addIDButton && eventType == DE_Click && !addIDButton.bDisabled) {
    value = class'NexgenUtil'.static.trim(clientIDInp.getValue());
    if (class'NexgenUtil'.static.isValidClientID(value)) {
      item = NexgenSimpleListItem(idList.items.append(class'NexgenSimpleListItem'));
      item.displayText = value;
      addIDButton.bDisabled = idList.items.countShown() >= client.sConf.maxBanClientIDs;
    }
  }

  // Del client ID pressed?
  if (control == delIDButton && eventType == DE_Click && !delIDButton.bDisabled) {
    idList.selectedItem.remove();
    idList.selectedItem = none;
    delIDButton.bDisabled = true;
    addIDButton.bDisabled = idList.items.countShown() >= client.sConf.maxBanClientIDs;
  }

  // Add HWid pressed?
  if (control == addHWidButton && eventType == DE_Click && !addHWidButton.bDisabled) {
    value = class'NexgenUtil'.static.trim(HWidInp.getValue());
    if (class'NexgenUtil'.static.isValidClientID(value)) {    // ACE Hashes are in same format as the client ID :)
      item = NexgenSimpleListItem(HWidList.items.append(class'NexgenSimpleListItem'));
      item.displayText = value;
    }
    addHWidButton.bDisabled = HWidList.items.countShown() >= client.sConf.maxBanClientIDs;
  }
  
  // Del HWid address pressed?
  if (control == delHWidButton && eventType == DE_Click && !delHWidButton.bDisabled) {
    HWidList.selectedItem.remove();
    HWidList.selectedItem = none;
    delHWidButton.bDisabled = true;
    addHWidButton.bDisabled = HWidList.items.countShown() >= client.sConf.maxBanClientIDs;
  }
  
  // Add MAC Hash pressed?
  if (control == addMACButton && eventType == DE_Click && !addMACButton.bDisabled) {
    value = class'NexgenUtil'.static.trim(MACInp.getValue());
    if (class'NexgenUtil'.static.isValidClientID(value)) {
      item = NexgenSimpleListItem(MACList.items.append(class'NexgenSimpleListItem'));
      item.displayText = value;
    }
    addMACButton.bDisabled = MACList.items.countShown() >= client.sConf.maxBanClientIDs;
  }

  // Del MAC Hash pressed?
  if (control == delMACButton && eventType == DE_Click && !delMACButton.bDisabled) {
    MACList.selectedItem.remove();
    MACList.selectedItem = none;
    delMACButton.bDisabled = true;
    addMACButton.bDisabled = MACList.items.countShown() >= client.sConf.maxBanClientIDs;
  }
  
  
  // Add Hostname pressed?
  if (control == addHNButton && eventType == DE_Click && !addHNButton.bDisabled) {
    value = class'NexgenUtil'.static.trim(HNInp.getValue());
    item = NexgenSimpleListItem(HNList.items.append(class'NexgenSimpleListItem'));
    item.displayText = value;
    addHNButton.bDisabled = Len(getHNList()) >= maxMasksLength;
    HNInp.setMaxLength(maxMasksLength - Len(getHNList()) - Len(separator));
  }

  // Del Hostname pressed?
  if (control == delHNButton && eventType == DE_Click && !delHNButton.bDisabled) {
    HNList.selectedItem.remove();
    HNList.selectedItem = none;
    delHNButton.bDisabled = true;
    addHNButton.bDisabled = Len(getHNList()) >= maxMasksLength;
    HNInp.setMaxLength(maxMasksLength - Len(getHNList()) - Len(separator));
  }

  
  // New search necessary?
  if (control == SearchInp && eventType == DE_Change || control == SearchType && eventType == DE_Change) loadBanList();


  // Reset fields pressed?
  if (control == resetFields && eventType == DE_Click && !resetFields.bDisabled) resetAllFields();
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Creates a new ban entry.
 *  $PARAM        playerName   Playername of the new ban entry.
 *  $PARAM        ipList       IP addresses of the player.
 *  $PARAM        idList       ID codes of the player.
 *  $PARAM        HWidList     HWides of the player.
 *  $PARAM        MACList      MACHashes of the player.
 *  $PARAM        HNList       Hostnamees of the player.
 *  $PARAM        banReason    Reason of the new ban entry.
 *  $PARAM        banPeriod    Period of the new ban entry.
 *  $REQUIRE      playerName != ""
 *
 **************************************************************************************************/
function addBan(string playerName, string ipList, string idList,
                string HWidList, string MACList, string HNList, string banReason, string banPeriod) {
  local int entryNum, index;
  local bool bFound;
  local string bannerName;

  // Preliminary checks.
  if (class'NexgenUtil'.static.trim(playerName) == "") {
    client.showMsg("<C00>Failed to add ban - Playername required.");
    return;
  }

  // Find a free slot.
  while (!bFound && entryNum < BanData.getArraySize("bannedName")) {
    if (BanData.getString("bannedName", entryNum) == "") {
      bFound = true;
    } else {
      entryNum++;
    }
  }

  // Cancel on error.
  if (!bFound) {
    client.showMsg("<C00>Failed to add ban - Ban list is full.");
    return;
  }
  
  // Get banner name
  bannerName = xClient.accountName;
  if(bannerName == "") bannerName = client.playerName;

  // Store ban.
  xClient.setVar(class'NexgenABMBanListDC'.default.containerID, "bannedName", playerName, entryNum);
  xClient.setVar(class'NexgenABMBanListDC'.default.containerID, "bannedIPs", ipList, entryNum);
  xClient.setVar(class'NexgenABMBanListDC'.default.containerID, "bannedIDs", idList, entryNum);
  xClient.setVar(class'NexgenABMBanListDC'.default.containerID, "bannedHWIDs", HWidList, entryNum);
  xClient.setVar(class'NexgenABMBanListDC'.default.containerID, "bannedMACHashes", MACList, entryNum);
  xClient.setVar(class'NexgenABMBanListDC'.default.containerID, "bannedHostnames", HNList, entryNum);
  xClient.setVar(class'NexgenABMBanListDC'.default.containerID, "banReason", banReason, entryNum);
  xClient.setVar(class'NexgenABMBanListDC'.default.containerID, "banPeriod", banPeriod, entryNum);
  xClient.setVar(class'NexgenABMBanListDC'.default.containerID, "bannerName", bannerName, entryNum);

  // Save changes.
  xClient.saveSharedData(class'NexgenABMBanListDC'.default.containerID);
  
  // Show message
  client.showMsg("<C07>Ban list has been updated.");

  // Log action.
  xClient.SlogAdminAction("<C07>Ban entry for player"@playerName$" has been added by %1.", client.playerName, , , true, false);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Updates a ban entry.
 *  $PARAM        entryNum     Index of the updated ban entry.
 *  $PARAM        playerName   Playername of the updated ban entry.
 *  $PARAM        ipList       IP addresses of the player.
 *  $PARAM        idList       ID codes of the player.
 *  $PARAM        HWidList     HWides of the player.
 *  $PARAM        MACList      MACHashes of the player.
 *  $PARAM        HNList       Hostnamees of the player.
 *  $PARAM        banReason    Reason of the updated ban entry.
 *  $PARAM        banPeriod    Period of the updated ban entry.
 *  $REQUIRE      playerName != "" && entryNum >= BanData.getArraySize("bannedName")
 *
 **************************************************************************************************/
function updateBan(int entryNum, string playerName, string ipList, string idList,
                   string HWidList, string MACList, string HNList, string banReason, string banPeriod) {
  local int index;
  local string bannerName;

  // Preliminary checks.
  if (class'NexgenUtil'.static.trim(playerName) == "") {
    client.showMsg("<C00>Failed to update ban - PlayerName required.");
    return;
  } else if(entryNum >= BanData.getArraySize("bannedName")    ||
            BanData.getString("bannedName", entryNum) == "") {
    client.showMsg("<C00>Failed to update ban.");
    return;
  }
  
  // Get banner name
  bannerName = xClient.accountName;
  if(bannerName == "") bannerName = client.playerName;

  // Store ban.
  xClient.setVar(class'NexgenABMBanListDC'.default.containerID, "bannedName", playerName, entryNum);
  xClient.setVar(class'NexgenABMBanListDC'.default.containerID, "bannedIPs",  ipList, entryNum);
  xClient.setVar(class'NexgenABMBanListDC'.default.containerID, "bannedIDs",  idList, entryNum);
  xClient.setVar(class'NexgenABMBanListDC'.default.containerID, "bannedHWIDs", HWidList, entryNum);
  xClient.setVar(class'NexgenABMBanListDC'.default.containerID, "bannedMACHashes", MACList, entryNum);
  xClient.setVar(class'NexgenABMBanListDC'.default.containerID, "bannedHostnames", HNList, entryNum);
  xClient.setVar(class'NexgenABMBanListDC'.default.containerID, "banReason", banReason, entryNum);
  xClient.setVar(class'NexgenABMBanListDC'.default.containerID, "banPeriod",  banPeriod, entryNum);
  xClient.setVar(class'NexgenABMBanListDC'.default.containerID, "bannerName",  bannerName, entryNum);

  // Save changes.
  xClient.saveSharedData(class'NexgenABMBanListDC'.default.containerID);
  
  // Show message
  client.showMsg("<C07>Ban list has been updated.");
  
  // Log action.
  xClient.SlogAdminAction("<C07>Ban entry for player"@playerName$" has been updated by %1.", client.playerName, , , true, false);
  
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Deletes a ban entry.
 *  $PARAM        entryNum     Index of the removed ban entry.
 *  $REQUIRE      playerName != "" && entryNum >= BanData.getArraySize("bannedName")
 *
 **************************************************************************************************/
function deleteBan(int entryNum) {
  local string playername;
  local int index;

  // Preliminary checks.
  if (entryNum >= BanData.getArraySize("bannedName") ||
      BanData.getString("bannedName", entryNum) == "") {
    client.showMsg("<C00>Failed to delete ban.");
    return;
  }
  
  // Save playername
  playername = BanData.getString("bannedName", entryNum);
  
  // temporary disable further input
  BanData = none;
  loadBanList();

  // Remove ban.
  xClient.removeBan(entryNum);

  // Show message
  client.showMsg("<C07>Ban list has been updated.");
  
  // Log action.
  xClient.SlogAdminAction("<C07>Ban entry for player"@playername$" has been removed by %1.", client.playerName, , , true, false);

}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Resets all input fields (makes creating a new ban entry way easier).
 *
 **************************************************************************************************/
function resetAllFields() {
  local int index;

  playerNameInp.setValue("");
  banReasonInp.setValue("");
  bannerNameInp.setValue("");
  matchCountInp.setValue("");
  dateInp.setValue(client.lng.dateFormatStr);
  ipAddressInp.setValue("");
  clientIDInp.setValue("");
  HWidInp.setValue("");
  MACInp.setValue("");
  HNInp.setValue("");
  SearchInp.setValue("");
  ipList.items.clear();
  idList.items.clear();
  HWidList.items.clear();
  MACList.items.clear();
  HNList.items.clear();
  ipList.selectedItem = none;
  idList.selectedItem = none;
  HWidList.selectedItem = none;
  MACList.selectedItem = none;
  HNList.selectedItem = none;
  banPeriodInp[0].bChecked = true;
  for (index = 1; index < arrayCount(banPeriodInp); index++) {
    banPeriodInp[index].bChecked = false;
  }
  banPeriodTypeSelected();
  addIPButton.bDisabled = False;
  addIDButton.bDisabled = False;
  addHWIDButton.bDisabled = False;
  addMACButton.bDisabled = False;
  addHNButton.bDisabled = False;
  delIPButton.bDisabled = True;
  delIDButton.bDisabled = True;
  delHWIDButton.bDisabled = True;
  delMACButton.bDisabled = True;
  delHNButton.bDisabled = True;
  ipAddressInp.setMaxLength(maxMasksLength);
  HNInp.setMaxLength(maxMasksLength);
  loadBanList();
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when the value of a shared variable has been updated.
 *  $PARAM        container  Shared data container that contains the updated variable.
 *  $PARAM        varName    Name of the variable that was updated.
 *  $PARAM        index      Element index of the array variable that was changed.
 *  $REQUIRE      container != none && varName != "" && index >= 0
 *  $OVERRIDE
 *
 **************************************************************************************************/
function varChanged(NexgenSharedDataContainer container, string varName, optional int index) {
  if (container.containerID ~= class'NexgenABMBanListDC'.default.containerID) {
     resetAllFields();
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/
defaultproperties
{
     panelIdentifier="ABMBanPanel"
     PanelHeight=486.000000
}
