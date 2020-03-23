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
class NexgenABMAdminPanel extends NexgenPanel;

var NexgenSimplePlayerListBox playerList;
var UWindowSmallButton TakeScreenButton;
var UWindowSmallButton RequestInfoButton;
var UWindowSmallButton SaveToFileButton;
var UWindowSmallButton CopySpecificInfoButton;
var UWindowComboControl SelectionType;

var UWindowDynamicTextArea infoArea;

var NexgenABMClient xClient;


/***************************************************************************************************
 *
 *  $DESCRIPTION  Creates the contents of the panel.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function setContent() {	
	local NexgenContentPanel p;
	
	xClient = NexgenABMClient(client.getController(class'NexgenABMClient'.default.ctrlID));
	
	// Create layout & add components.
	createWindowRootRegion();
	splitRegionV(160, defaultComponentDist);
	splitRegionH(120, defaultComponentDist, , true);
	
	// Info Window.
	p = addContentPanel();
	infoArea = p.addDynamicTextArea();

	// Player list.
	playerList = NexgenSimplePlayerListBox(addListBox(class'NexgenSimplePlayerListBox'));
	
	// Button panel.
	p = addContentPanel();
	p.divideRegionH(6);
	TakeScreenButton = p.addButton("Take Screenshot");
	RequestInfoButton = p.addButton("Request Info");
	SaveToFileButton = p.addButton("Save Info to File");
  p.skipRegion();
	SelectionType = p.addListCombo();
	CopySpecificInfoButton = p.addButton("Copy selected Info");
	
	// Configure components.
  playerList.register(self);
	TakeScreenButton.register(self);
	RequestInfoButton.register(self);
	SaveToFileButton.register(self);
	CopySpecificInfoButton.register(self);
	infoArea.bTopCentric = true;
	loadSelectionType();
  playerSelected();
  
  SaveToFileButton.bDisabled = True;
	CopySpecificInfoButton.bDisabled = True;
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Loads the Selection type list.
 *
 **************************************************************************************************/
function loadSelectionType() {
	SelectionType.addItem("Hardware ID", "0");
	SelectionType.addItem("MAC Hash 1", "1");
	SelectionType.addItem("MAC Hash 2", "2");
	SelectionType.addItem("OS", "3");
	SelectionType.addItem("CPU", "4");
	SelectionType.addItem("CPU Speed", "5");
	SelectionType.addItem("NIC Description", "6");
	SelectionType.addItem("Renderer Device", "7");
  SelectionType.addItem("Sound Device", "8");
  SelectionType.addItem("Command Line", "9");
  
  SelectionType.setSelectedIndex(0);
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when the ACE Info failed.
 *
 **************************************************************************************************/
function ACEInfoFailed() {
  infoArea.clear();
	infoArea.addText("No ACE Check found for this player.");
	RequestInfoButton.bDisabled = False;
	SaveToFileButton.bDisabled = True;
	CopySpecificInfoButton.bDisabled = True;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  The client requested the ACE Info
 *
 **************************************************************************************************/
function ACEInfoRequested() {
  infoArea.clear();
	infoArea.addText("Receiving Info...");
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  ACE Info has been received.
 *
 **************************************************************************************************/
function ACEInfoReceived() {
  infoArea.clear();
  infoArea.addText("---------------------------------------------");
  infoArea.addText("ACE INFO FOR"@xClient.PlayerName);
  infoArea.addText("");
  infoArea.addText("Time:"@Class'NexgenUtil'.static.serializeDate(xClient.level.year, xClient.level.month, xClient.level.day, xClient.level.hour, xClient.level.minute));
  infoArea.addText("ACE Version: BETA"@Class'IACECommon'.default.ACEVersion);
  infoArea.addText("---------------------------------------------");
	infoArea.addText("PlayerName:"@xClient.PlayerName);
	infoArea.addText("PlayerIP:"@xClient.PlayerIP);
	if(xClient.bTunnel) infoArea.addText("Real IP:"@xClient.RealIP);
	if(NexgenPlayerList(playerList.selectedItem) != none) {
    infoArea.addText("NexgenID:"@NexgenPlayerList(playerList.selectedItem).pClientID);
  }
  infoArea.addText("OS:"@xClient.OSString);
	infoArea.addText("CPU:"@xClient.CPUIdentifier);
	infoArea.addText("CPUSpeed:"@xClient.CPUMeasuredSpeed$" Mhz Measured - "$xClient.CPUReportedSpeed$" Mhz Reported");
	infoArea.addText("NICDesc:"@xClient.NICName);
	infoArea.addText("MACHash1:"@xClient.MACHash);
	infoArea.addText("MACHash2:"@xClient.UTDCMacHash);
	infoArea.addText("HardwareID:"@xClient.HWHash);
	infoArea.addText("UTVersion:"@xClient.UTVersion);
	infoArea.addText("Renderer:"@xClient.RenderDeviceClass);
	infoArea.addText("SoundDevice:"@xClient.SoundDeviceClass);
	infoArea.addText("CommandLine:"@xClient.UTCommandLine);
	infoArea.addText("");
	infoArea.addText("Additional Info");
	infoArea.addText("----------------");
	infoArea.addText("bWine:"@xClient.bWine);
	infoArea.addText("CoreMD5:"@xClient.CoreMD5);
  infoArea.addText("EngineMD5:"@xClient.EngineMD5);
  infoArea.addText("RenderMD5:"@xClient.RenderMD5);
  infoArea.addText("GalaxyMD5:"@xClient.GalaxyMD5);
  infoArea.addText("WinDrvMD5:"@xClient.WinDrvMD5);
  infoArea.addText("WindowMD5:"@xClient.WindowMD5);
  infoArea.addText("ACEMD5:"@xClient.ACEMD5);
  infoArea.addText("RenderDeviceFile:"@xClient.RenderDeviceFile);
  infoArea.addText("RenderDeviceMD5:"@xClient.RenderDeviceMD5);
  infoArea.addText("SoundDeviceFile:"@xClient.SoundDeviceFile);
  infoArea.addText("SoundDeviceMD5:"@xClient.SoundDeviceMD5);
	
	
	RequestInfoButton.bDisabled = False;
	SaveToFileButton.bDisabled = False;
	CopySpecificInfoButton.bDisabled = False;
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when a player was selected from the list.
 *
 **************************************************************************************************/
function playerSelected() {
	local NexgenPlayerList item;

	item = NexgenPlayerList(playerList.selectedItem);

	TakeScreenButton.bDisabled  = item == none || item.isSpectator();
	RequestInfoButton.bDisabled = item == none || item.isSpectator();
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
	

 	// Player selected?
	if (control == playerList && eventType == DE_Click) {
		playerSelected();
	}
	
	// Take screen button clicked?
	if (control == TakeScreenButton && eventType == DE_Click && !TakeScreenButton.bDisabled) {
    if(NexgenPlayerList(playerList.selectedItem) != none) {
      xClient.requestACEShot(NexgenPlayerList(playerList.selectedItem).pNum);;
    }
	}
	
	// Request Info button clicked?
	if (control == RequestInfoButton && eventType == DE_Click && !RequestInfoButton.bDisabled) {
    if(NexgenPlayerList(playerList.selectedItem) != none) {
      xClient.requestACEInfo(NexgenPlayerList(playerList.selectedItem).pNum);
      infoArea.clear();
      infoArea.addText("Info requested...");
      RequestInfoButton.bDisabled = True;
      SaveToFileButton.bDisabled = True;
	    CopySpecificInfoButton.bDisabled = True;
    }
	}

  // Save to File Button button clicked?
	if (control == SaveToFileButton && eventType == DE_Click && !SaveToFileButton.bDisabled) {
    saveToFile();
	}

  // Copy Specific Info button clicked?
	if (control == CopySpecificInfoButton && eventType == DE_Click && !CopySpecificInfoButton.bDisabled) {
    copyInfo(SelectionType.getSelectedIndex());
	}

}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Saves the current ACE Info to a local txt file in client's System folder.
 *
 **************************************************************************************************/
function saveToFile() {
  local NexgenTextFile InfoFile;
  local string timeStemp, FileName, fixedPlayerName;
  local int i;

  // Construct FileName
  timeStemp = Class'NexgenUtil'.static.serializeDate(xClient.level.year, xClient.level.month, xClient.level.day, xClient.level.hour, xClient.level.minute);
  for(i =0;i<Len(xClient.PlayerName);i++) { // Remove invalid characters (copied code from ACE)
    if(InStr("\\/*?:<>\"|", Mid(xClient.PlayerName, i, 1)) != -1) fixedPlayerName = fixedPlayerName $ "_";
    else fixedPlayerName = fixedPlayerName $ Mid(xClient.PlayerName, i, 1);
  }
  FileName = "./[ACE_Info]_"$timeStemp$"_"$fixedPlayerName;
  
  // Create file actor
  if(InfoFile == none) InfoFile = xClient.spawn(class'NexgenTextFile', xClient);
  
  // Initialize new file
  if(InfoFile == none || !InfoFile.openFile(FileName$".tmp", FileName$".txt")) {
    client.showMsg("<C00>Failed to create log file!");
    return;
  }
  
  // Write Data to file
  InfoFile.println("---------------------------------------------", true);
  InfoFile.println("ACE INFO FOR"@xClient.PlayerName, true);
  InfoFile.println("", true);
  InfoFile.println("Time:"@Class'NexgenUtil'.static.serializeDate(xClient.level.year, xClient.level.month, xClient.level.day, xClient.level.hour, xClient.level.minute), true);
  InfoFile.println("ACE Version: BETA"@Class'IACECommon'.default.ACEVersion, true);
  InfoFile.println("---------------------------------------------", true);
  InfoFile.println("PlayerName:"@xClient.PlayerName, true);
  InfoFile.println("PlayerIP:"@xClient.PlayerIP, true);
  if(xClient.bTunnel) InfoFile.println("Real IP:"@xClient.RealIP, true);
  if(NexgenPlayerList(playerList.selectedItem) != none) {
    InfoFile.println("NexgenID:"@NexgenPlayerList(playerList.selectedItem).pClientID, true);
  }
  InfoFile.println("OS:"@xClient.OSString, true);
	InfoFile.println("CPU:"@xClient.CPUIdentifier, true);
	InfoFile.println("CPUSpeed:"@xClient.CPUMeasuredSpeed$" Mhz Measured - "$xClient.CPUReportedSpeed$" Mhz Reported", true);
	InfoFile.println("NICDesc:"@xClient.NICName, true);
	InfoFile.println("MACHash1:"@xClient.MACHash, true);
	InfoFile.println("HardwareID:"@xClient.HWHash, true);
	InfoFile.println("UTVersion:"@xClient.UTVersion, true);
	InfoFile.println("Renderer:"@xClient.RenderDeviceClass, true);
	InfoFile.println("SoundDevice:"@xClient.SoundDeviceClass, true);
	InfoFile.println("CommandLine:"@xClient.UTCommandLine, true);
	InfoFile.println("", true);
	InfoFile.println("Additional Info", true);
	InfoFile.println("----------------", true);
	InfoFile.println("bWine:"@xClient.bWine, true);
	InfoFile.println("CoreMD5:"@xClient.CoreMD5, true);
  InfoFile.println("EngineMD5:"@xClient.EngineMD5, true);
  InfoFile.println("RenderMD5:"@xClient.RenderMD5, true);
  InfoFile.println("GalaxyMD5:"@xClient.GalaxyMD5, true);
  InfoFile.println("WinDrvMD5:"@xClient.WinDrvMD5, true);
  InfoFile.println("WindowMD5:"@xClient.WindowMD5, true);
  InfoFile.println("ACEMD5:"@xClient.ACEMD5, true);
  InfoFile.println("RenderDeviceFile:"@xClient.RenderDeviceFile, true);
  InfoFile.println("RenderDeviceMD5:"@xClient.RenderDeviceMD5, true);
  InfoFile.println("SoundDeviceFile:"@xClient.SoundDeviceFile, true);
  InfoFile.println("SoundDeviceMD5:"@xClient.SoundDeviceMD5, true);
  InfoFile.closeFile();

  // Inform player
  client.showMsg("<C02>Data saved in UnrealTournament -> System folder.");
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Copies a specifc Info to the client's Clipboard.
 *  $PARAM        index  Index of the data which is to be copied.
 *
 **************************************************************************************************/
function copyInfo(int index) {

  // Determine Info
  switch(index) {
    case 0: client.player.CopyToClipboard(xClient.HWHash); break;
    case 1: client.player.CopyToClipboard(xClient.MACHash); break;
    case 2: client.player.CopyToClipboard(xClient.UTDCMacHash); break;
    case 3: client.player.CopyToClipboard(xClient.OSString); break;
    case 4: client.player.CopyToClipboard(xClient.CPUIdentifier); break;
    case 5: client.player.CopyToClipboard(xClient.CPUMeasuredSpeed$" Mhz Measured - "$xClient.CPUReportedSpeed$" Mhz Reported"); break;
    case 6: client.player.CopyToClipboard(xClient.NICName); break;
    case 7: client.player.CopyToClipboard(xClient.RenderDeviceClass); break;
    case 8: client.player.CopyToClipboard(xClient.SoundDeviceClass); break;
    case 9: client.player.CopyToClipboard(xClient.UTCommandLine); break;
  }
  
  // Inform player
  client.showMsg("<C04>Info copied to Clipboard.");
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Notifies the client of a player event. Additional arguments to the event should be
 *                combined into one string which then can be send along with the playerEvent call.
 *  $PARAM        playerNum  Player identification number.
 *  $PARAM        eventType  Type of event that has occurred.
 *  $PARAM        args       Optional arguments.
 *  $REQUIRE      playerNum >= 0
 *
 **************************************************************************************************/
function playerEvent(int playerNum, string eventType, optional string args) {

	// Player has joined the game?
	if (eventType == client.PE_PlayerJoined) {
		addPlayerToList(playerList, playerNum, args);
	}

	// Player has left the game?
	if (eventType == client.PE_PlayerLeft) {
		playerList.removePlayer(playerNum);
		playerSelected();
	}

	// Attribute changed?
	if (eventType == client.PE_AttributeChanged) {
		updatePlayerInfo(playerList, playerNum, args);
		playerSelected();
	}
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/

defaultproperties
{
     panelIdentifier="ACEAdminPanel"
}
