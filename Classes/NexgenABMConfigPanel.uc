/*##################################################################################################
##
##  Nexgen Advanced Ban Manager version 1.02
##  Copyright (C) 2013 Patrick "Sp0ngeb0b" Peltzer
##
##  This program is free software; you can redistribute and/or modify
##  it under the terms of the Open Unreal Mod License version 1.1.
##
##  Contact: spongebobut@yahoo.com | www.unrealriders.de
##
##################################################################################################*/
class NexgenABMConfigPanel extends NexgenPanel;

var UWindowCheckbox bKickForACEBypassAttemptBox;
var UWindowEditControl BypassDetectionTimeInp;

var UWindowSmallButton resetButton;
var UWindowSmallButton saveButton;

var NexgenABMClient xClient;
var NexgenSharedDataContainer configData;

/***************************************************************************************************
 *
 *  $DESCRIPTION  Creates the contents of the panel.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function setContent() {
  local int region;

	// Retrieve client controller interface.
	xClient = NexgenABMClient(client.getController(class'NexgenABMClient'.default.ctrlID));

	// Create layout & add components.
	createPanelRootRegion();
	splitRegionH(12, defaultComponentDist);
	addLabel("Nexgen Advanced Ban Manager - Settings", true, TA_Center);
	
	splitRegionH(1, defaultComponentDist);
	addComponent(class'NexgenDummyComponent');
	
	splitRegionH(20, defaultComponentDist, , true);
	region = currRegion;
	skipRegion();
	splitRegionV(196, , , true);
	skipRegion();
	divideRegionV(2, defaultComponentDist);
	saveButton = addButton(client.lng.saveTxt);
	resetButton = addButton(client.lng.resetTxt);

	selectRegion(region);
	selectRegion(divideRegionH(2, defaultComponentDist));
	
	splitRegionV(16, defaultComponentDist, , true);
	splitRegionV(32, defaultComponentDist, , true);
	
	addLabel("Detect ACE bypass try and kick player", true, TA_Left);
	bKickForACEBypassAttemptBox = addCheckBox(TA_Right);
	
	addLabel("Timelimit for ACE bypass attempt (until Hardware Info must be available) (sec)", true, TA_Left);
	BypassDetectionTimeInp = addEditBox();
	
	// Configure Components
	resetButton.bDisabled = true;
	saveButton.bDisabled = true;
  BypassDetectionTimeInp.setNumericOnly(true);
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
  if (container.containerID == class'NexgenABMConfigDC'.default.containerID) {
		configData = container;
		setValues();
		resetButton.bDisabled = false;
		saveButton.bDisabled = false;
	}
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Sets the values of all input components to the current settings.
 *
 **************************************************************************************************/
function setValues() {
	local int index;

	// Quit if configuration is not available.
	if (configData == none) return;
	
	bKickForACEBypassAttemptBox.bChecked = configData.getBool("bKickForACEBypassAttempt");
	BypassDetectionTimeInp.setValue(configData.getString("BypassDetectionTime"));
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
	if (container.containerID ~= class'NexgenABMConfigDC'.default.containerID) {
		switch (varName) {
	 		case "bKickForACEBypassAttempt": bKickForACEBypassAttemptBox.bChecked = container.getBool(varName); break;
	 		case "BypassDetectionTime":      BypassDetectionTimeInp.setValue(container.getString(varName));     break;
		}
	}
}



/***************************************************************************************************
 *
 *  $DESCRIPTION  Saves the current settings.
 *
 **************************************************************************************************/
function saveSettings() {
	local int index;

	xClient.setVar(class'NexgenABMConfigDC'.default.containerID, "bKickForACEBypassAttempt", bKickForACEBypassAttemptBox.bChecked);
	xClient.setVar(class'NexgenABMConfigDC'.default.containerID, "BypassDetectionTime",      BypassDetectionTimeInp.getValue());
	xClient.saveSharedData(class'NexgenABMConfigDC'.default.containerID);
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

	// Button pressed?
	if (control != none && eventType == DE_Click && control.isA('UWindowSmallButton') &&
	    !UWindowSmallButton(control).bDisabled) {

		switch (control) {
			case resetButton: setValues(); break;
			case saveButton: saveSettings(); break;
		}
	}
}



/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/

defaultproperties
{
     panelIdentifier="ABMConfigPanel"
     PanelHeight=96.000000
}
