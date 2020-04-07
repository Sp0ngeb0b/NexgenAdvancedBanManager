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
class NexgenABMModeratePanel extends NexgenRCPModerate;

var NexgenABMClient xClient;

var UWindowEditControl warnInp;
var UWindowSmallButton warnButton;
var UWindowCheckBox hideNameInp;
var UWindowSmallButton myKickButton;

/***************************************************************************************************
 *
 *  $DESCRIPTION  Creates the contents of the panel.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function setContent() {
  local NexgenContentPanel p;
  
  // Get client controller.
  xClient = NexgenABMClient(client.getController(class'NexgenABMClient'.default.ctrlID));

  // Create layout & add components.
  createWindowRootRegion();
  splitRegionV(192, defaultComponentDist);
  playerList = NexgenPlayerListBox(addListBox(class'NexgenPlayerListBox'));

  // Player info.
  splitRegionH(49, defaultComponentDist);
  p = addContentPanel();
  p.divideRegionH(2);
  p.splitRegionV(64);
  p.splitRegionV(64);
  p.addLabel(client.lng.ipAddressTxt, true);
  p.splitRegionV(48, , , true);
  p.addLabel(client.lng.clientIDTxt, true);
  p.splitRegionV(48, , , true);
  ipAddressLabel = p.addLabel();
  copyIPAddressButton = p.addButton(client.lng.copyTxt);
  clientIDLabel = p.addLabel();
  copyClientIDButton = p.addButton(client.lng.copyTxt);

  // Player controller.
  splitRegionH(51, defaultComponentDist);
  p = addContentPanel();
  p.divideRegionH(2);
  p.splitRegionV(96, defaultComponentDist);
  p.splitRegionV(96, defaultComponentDist);
  muteToggleButton = p.addButton(client.lng.muteToggleTxt);
  p.skipRegion();
  setNameButton = p.addButton(client.lng.setPlayerNameTxt);
  playerNameInp = p.addEditBox();

  // Ban controller.
  splitRegionH(107, defaultComponentDist);
  p = addContentPanel();
  p.divideRegionH(5);
  p.splitRegionV(96, defaultComponentDist);
  p.splitRegionV(96, defaultComponentDist);
  p.splitRegionV(96, defaultComponentDist);
  p.splitRegionV(96, defaultComponentDist);
  p.splitRegionV(96, defaultComponentDist);
  p.addLabel("Warn reason");
  warnInp = p.addEditBox();
  p.addLabel(client.lng.banReasonTxt);
  banReasonInp = p.addEditBox();
  warnButton = p.addButton("Warn");
  p.splitRegionV(96, defaultComponentDist);
  myKickButton = p.addButton(client.lng.kickPlayerTxt);
  p.splitRegionV(96, defaultComponentDist);
  banButton = p.addButton(client.lng.banPlayerTxt);
  p.splitRegionV(96, defaultComponentDist);
  banForeverInp = p.addCheckBox(TA_Left, client.lng.banForeverTxt);
  hideNameInp = p.addCheckBox(TA_Left, "Hide admin name");
  banMatchesInp = p.addCheckBox(TA_Left, client.lng.banMatchesTxt);
  numMatchesInp = p.addEditBox();
  banDaysInp = p.addCheckBox(TA_Left, client.lng.banDaysTxt);
  numDaysInp = p.addEditBox();

  // Game controller.
  splitRegionH(65);
  p = addContentPanel();
  p.divideRegionH(3);
  muteAllInp = p.addCheckBox(TA_Left, client.lng.muteAllTxt);
  allowNameChangeInp = p.addCheckBox(TA_Left, client.lng.allowNameChangeTxt);
  p.splitRegionV(96, defaultComponentDist);
  showMsgButton = p.addButton(client.lng.showAdminMessageTxt);
  messageInp = p.addEditBox();

  // Configure components.
  playerNameInp.setMaxLength(32);
  warnInp.setMaxLength(100);
  banReasonInp.setMaxLength(250);
  numMatchesInp.setMaxLength(4);
  numMatchesInp.setNumericOnly(true);
  numDaysInp.setMaxLength(4);
  numDaysInp.setNumericOnly(true);
  messageInp.setMaxLength(250);
  playerList.register(self);
  muteToggleButton.register(self);
  setNameButton.register(self);

  warnButton.register(self);
  myKickButton.register(self);
  banButton.register(self);
  showMsgButton.register(self);
  banForeverInp.register(self);
  banMatchesInp.register(self);
  banDaysInp.register(self);
  muteAllInp.register(self);
  allowNameChangeInp.register(self);
  banMatchesInp.bChecked = true;
  numMatchesInp.setValue("3");
  numDaysInp.setValue("7");
  playerSelected();
  banPeriodSelected();
  setValues();
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when a player was selected from the list.
 *
 **************************************************************************************************/
function playerSelected() {
	local NexgenPlayerList item;
	
	item = NexgenPlayerList(playerList.selectedItem);
	
	muteToggleButton.bDisabled = (item == none);
	setNameButton.bDisabled = (item == none);
	myKickButton.bDisabled = (item == none);
	banButton.bDisabled = (item == none || !client.hasRight(client.R_BanOperator));
	copyIPAddressButton.bDisabled = (item == none);
	copyClientIDButton.bDisabled = (item == none);
	if (item == none) {
		playerNameInp.setValue("");
		ipAddressLabel.setText("");
		clientIDLabel.setText("");
	} else {
		playerNameInp.setValue(item.pName);
		ipAddressLabel.setText(item.pIPAddress);
		clientIDLabel.setText(item.pClientID);
	}

  warnButton.bDisabled = (NexgenPlayerList(playerList.selectedItem) == none);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Bans the currently selected player.
 *
 **************************************************************************************************/
function banPlayer() {
  local byte banPeriodType;
  local int banPeriodArgs;

  if (banMatchesInp.bChecked) {
    banPeriodType = client.sConf.BP_Matches;
    banPeriodArgs = int(class'NexgenUtil'.static.trim(numMatchesInp.getValue()));
  } else if (banDaysInp.bChecked) {
    banPeriodType = client.sConf.BP_UntilDate;
    banPeriodArgs = int(class'NexgenUtil'.static.trim(numDaysInp.getValue()));
  } else {
    banPeriodType = client.sConf.BP_Forever;
  }

  xClient.banPlayer(NexgenPlayerList(playerList.selectedItem).pNum, banPeriodType, banPeriodArgs,
                    class'NexgenUtil'.static.trim(banReasonInp.getValue()), hideNameInp.bChecked);
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
  super.notify(control, eventType);
  
  if (control == warnButton && !warnButton.bDisabled && eventType == DE_Click) {
    if(warnInp.getValue() == "") client.showMsg("<C00>You have to enter a reason.");
    else {
      xClient.warnPlayer(NexgenPlayerList(playerList.selectedItem).pNum, class'NexgenUtil'.static.trim(warnInp.getValue()), hideNameInp.bChecked);
    }
  }
  
  if (control == myKickButton && !myKickButton.bDisabled && eventType == DE_Click) {
			xClient.kickPlayer(NexgenPlayerList(playerList.selectedItem).pNum,
				                 class'NexgenUtil'.static.trim(banReasonInp.getValue()), hideNameInp.bChecked);
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/
defaultproperties
{
}
