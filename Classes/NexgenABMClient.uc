/*##################################################################################################
##
##  Nexgen Advanced Ban Manager version 1.03
##  Copyright (C) 2019 Patrick "Sp0ngeb0b" Peltzer
##
##  This program is free software; you can redistribute and/or modify
##  it under the terms of the Open Unreal Mod License version 1.1.
##
##  Contact: spongebobut@yahoo.com | www.unrealriders.de
##
##################################################################################################*/
class NexgenABMClient extends NexgenExtendedClientController;

// Admin Panel
var NexgenABMBanPanel banPanel;     // Link to the Ban Control Panel

// Advanced player Info
var string playerHWid;              // Detected Hardware ID of this client
var string playerMAC;               // Detected MAC Hash of this client
var string playerHostname;          // Detected Hostname of this client

// Intern variables
var bool bBanPending;               // Whether the player was already found in banlist and is only
                                    // waiting for additional info to be detected
var int banEntry;                   // Ban entry index of this client (if banned)
var string banReason;               // Ban entry reason of this client (if banned)
var string banPeriod;               // Ban entry period of this client (if banned)
var int hostnameTries;              // Amount of Hostname detection tries (every second)

// Warning variables
var bool bCurrentlyWarned;          // Is this client currently warned?
var string reason;                  // Warn reason
var string adminName;               // Admin who initiated the warning

const CMD_ABM_PREFIX = "ABM";       // Common ABM command prefix.
const CMD_ABM_DELBAN = "DEL";       // Delete ban entry command.
const CMD_ABM_CLR    = "CLR";       // Delete ban data command.

/***************************************************************************************************
 *
 *  $DESCRIPTION  Replication block.
 *
 **************************************************************************************************/
replication {

  reliable if (role == ROLE_SimulatedProxy) // Replicate to server...
    removeBan, SlogAdminAction, banPlayer, warnPlayer, readWarning;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Modifies the setup of the Nexgen remote control panel.
 *  $OVERRIDE
 *
 **************************************************************************************************/
simulated function setupControlPanel() {
  local NexgenPanelContainer container;
  local UWindowPageControlPage pageControl;
  local NexgenPanel newPanel;

  if (client.hasRight(client.R_BanOperator)) {

    // Since we can only modify a few existing tabs directly, we have to do a work around
    // First, locate the parent tab of the existing BanControl tab
  	container = NexgenPanelContainer(client.mainWindow.mainPanel.getPanel("server"));

  	// Delete the tab
  	if(container != none) {
	    container.pages.DeleteTab(container.pages.GetTab(client.lng.banControlTabTxt));
    }
    
    // Spawn the new ScrollPanelContainer and insert it before the accounts tab
    pageControl = container.pages.InsertPage(container.pages.GetPage(client.lng.accountsTabTxt), client.lng.banControlTabTxt, class'NexgenScrollPanelContainer');
    if (pageControl != none) {
			newPanel = NexgenPanel(pageControl.page);
			newPanel.panelIdentifier = "abmBanControl";
			newPanel.client = self.client;
			newPanel.setContent();
			
			// Spawn the actual content page
			banPanel = NexgenABMBanPanel(client.mainWindow.mainPanel.addPanel("", class'NexgenABMBanPanel', , "server,abmBanControl"));
		}

  }
  
  if (client.hasRight(client.R_Moderate)) {
    // Since we can only modify a few existing tabs directly, we have to do a work around
    // First, locate the parent tab of the existing moderator tab
  	container = NexgenPanelContainer(client.mainWindow.mainPanel.getPanel("game"));

  	// Delete the tab
  	if(container != none) {
	    container.pages.DeleteTab(container.pages.GetTab(client.lng.moderatorTabTxt));
    }

    // Spawn our modfied moderator tab and insert it before the match controller tab
    pageControl = container.pages.InsertPage(container.pages.GetPage(client.lng.matchControlTabTxt), client.lng.moderatorTabTxt, class'NexgenABMModeratePanel');

    if (pageControl != none) {
			newPanel = NexgenPanel(pageControl.page);
			newPanel.client = self.client;
			newPanel.setContent();
		}
  }
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Timer function. Called every second.
 *                The following actions are performed:
 *                - Warning Popup
 *                - Hostname detecting (only if ipToCountry is available)
 *
 **************************************************************************************************/
function Timer() {
  local string dataBack;
	local string playerIP, Host;
	local Actor IpToCountry;
	local NexgenClientCore ncc;
	
	// Deactivate Timer if no longer needed
	if(!bCurrentlyWarned && (playerHostname != "" || NexgenABMMain(xControl).ipToCountry == none)) {
    SetTimer(0.0, false);
    return;
  }
	
	// Implemented from NexgenWarn
	if(bCurrentlyWarned) {
	  client.showPopup(string(class'NexgenABMWarnDialog'), reason, adminName);
  }
  
  // Hostname detector
  if(NexgenABMMain(xControl).ipToCountry != none && playerHostname == "" && hostnameTries <= NexgenABMMain(xControl).HostnameTimeout) {
    hostnameTries++;
    
    // Timeout detected, disable ipToCountry for the whole game
    if (hostnameTries > NexgenABMMain(xControl).HostnameTimeout) {
      NexgenABMMain(xControl).ipToCountry = none;
      NexgenABMMain(xControl).hostnameReceived(self);
      return;
    }
    
    playerIP = client.ipAddress;
   	if (playerIP != "") {
   	
      // Request info
  		dataBack = NexgenABMMain(xControl).ipToCountry.GetItemName(PlayerIP);

      // Check response
	   	if(dataBack == "!Added to queue" || dataBack == "!Waiting in queue" || dataBack == "!Resolving now" || dataBack == "!Queue full" ) {
	  		return;
  		}

	  	Host = SelElem(dataBack, 2);

      // Invalid response, deactivate ipToCountry for rest of the game
  		if(Left(dataBack, 1) == "!" || Host == "") {
	    	NexgenABMMain(xControl).ipToCountry = none;
        NexgenABMMain(xControl).hostnameReceived(self);
        return;
  		}

      playerHostname = Host;
      NexgenABMMain(xControl).hostnameReceived(self);
  	}
  }
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Bans the specified player from the server.
 *  $PARAM        playerNum      The player code of the player the player that is to be banned.
 *  $PARAM        banPeriodType  The type of period for which the player is banned. 1 means x
 *                               matches and 2 means x days, where x is specified by the
 *                               banPeriodArgs argument. Any other value means the player is banned
 *                               forever.
 *  $PARAM        banPeriodArgs  Optional argument for the ban period type.
 *  $PARAM        reason         Description of why the player was banned.
 *
 **************************************************************************************************/
function banPlayer(int playerNum, byte banPeriodType, int banPeriodArgs, string reason) {
  local NexgenClient ntarget;
  local NexgenABMClient target;
	local string banPeriod;
	local string banPeriodDesc;
	local int year, month, day, hour, minute;
	local int entryNum;
	local bool bFound;
	local bool bHasExistingBanEntry;
	local string args;

	// Preliminary checks.
	if (!client.hasRight(client.R_Moderate) || !client.hasRight(client.R_BanOperator)) {
		return;
	}

	// Get target client.
	ntarget = xControl.control.getClientByNum(playerNum);
	if (ntarget == none) return;
	target = NexgenABMClient(xControl.getXClient(ntarget));
	if (target == none) return;

	// Check if player can kick/ban players that have an account on the server.
	if (ntarget.bHasAccount && !client.hasRight(client.R_BanAccounts)) {
		client.showMsg(control.lng.noBanAccountRightMsg);
		return;
	}

	// Get ban period.
	if (banPeriodType == xControl.control.sConf.BP_Matches) {
		banPeriod = "M" $ max(1, banPeriodArgs);
	} else if (banPeriodType == xControl.control.sConf.BP_UntilDate) {
		year = level.year;
		month = level.month;
		day = level.day;
		hour = level.hour;
		minute = level.minute;
		class'NexgenUtil'.static.computeDate(max(1, banPeriodArgs), year, month, day);
		banPeriod = "U" $ class'NexgenUtil'.static.serializeDate(year, month, day, hour, minute);
	}
	banPeriodDesc = xControl.control.lng.getBanPeriodDescription(banPeriod);

	// Kick player from the server.
	ntarget.showPopup("NexgenJustBannedDialog", reason, banPeriodDesc);
	ntarget.player.destroy();

	// Announce event.
	logAdminAction(xControl.control.lng.adminBanPlayerMsg, ntarget.playerName);

	// Check if player already has an entry in the banlist.
	entryNum = NexgenABMMain(xControl).getBanIndex(ntarget.ipAddress, ntarget.playerID, target.playerHWid,
                                  target.playerMAC, target.playerHostname);
	if (entryNum >= 0) {
		bFound = true;
		bHasExistingBanEntry = true;
	} else {
		entryNum = 0;
	}

	// Find a free slot in the ban list.
	while (!bFound && entryNum < arrayCount(NexgenABMConfig(xControl.xConf).bannedName)) {
		if (NexgenABMConfig(xControl.xConf).bannedName[entryNum] == "") {
			bFound = true;
		} else {
			entryNum++;
		}
	}

	// Cancel on error.
	if (!bFound) {
		return;
	}

	// Store ban.
	NexgenABMMain(xControl).setFixed(class'NexgenABMBanListDC'.default.containerID, "bannedName", ntarget.playerName, entryNum, self);
	if (bHasExistingBanEntry) {
		NexgenABMMain(xControl).updateBan(entryNum, ntarget.ipAddress, ntarget.playerID, target.playerHWid,
                                      target.playerMAC, target.playerHostname);
	} else {
  	NexgenABMMain(xControl).setFixed(class'NexgenABMBanListDC'.default.containerID, "bannedIPs", ntarget.ipAddress, entryNum, self);
  	NexgenABMMain(xControl).setFixed(class'NexgenABMBanListDC'.default.containerID, "bannedIDs", ntarget.playerID, entryNum, self);
  	NexgenABMMain(xControl).setFixed(class'NexgenABMBanListDC'.default.containerID, "bannedHWIDs", target.playerHWid, entryNum, self);
  	NexgenABMMain(xControl).setFixed(class'NexgenABMBanListDC'.default.containerID, "bannedMACHashes", target.playerMAC, entryNum, self);
  	NexgenABMMain(xControl).setFixed(class'NexgenABMBanListDC'.default.containerID, "bannedHostnames", target.playerHostname, entryNum, self);
	}
	NexgenABMMain(xControl).setFixed(class'NexgenABMBanListDC'.default.containerID, "banReason", reason, entryNum, self);
  NexgenABMMain(xControl).setFixed(class'NexgenABMBanListDC'.default.containerID, "banPeriod", banPeriod, entryNum, self);

	// Save changes.
  dataSyncMgr.saveSharedData(class'NexgenABMBanListDC'.default.containerID);

	// Signal event.
	class'NexgenUtil'.static.addProperty(args, "client", client.playerNum);
	class'NexgenUtil'.static.addProperty(args, "target", ntarget.playerNum);
	class'NexgenUtil'.static.addProperty(args, "period", banPeriodDesc);
	class'NexgenUtil'.static.addProperty(args, "reason", reason);
	class'NexgenUtil'.static.addProperty(args, "ban_index", entryNum);
	xControl.control.signalEvent("player_banned", args, true);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Warn a specified player.
 *  $PARAM        playerNum The playernum of the selected player
 *  $PARAM        reason The warn reason.
 *
 **************************************************************************************************/
function warnPlayer(int playerNum, string reason) {
  local NexgenClient target;
  local NexgenABMClient xClient;
  local string args;

  // Preliminary checks.
	if (!client.hasRight(client.R_Moderate)) {
		return;
	}

	// Get target client.
	target = control.getClientByNum(playerNum);
	if (target == none) return;

	// Warn player.
	xClient = NexgenABMClient(target.getController(class'NexgenABMClient'.default.ctrlID));
	xClient.reason = reason;
	xClient.adminName = client.playerName;
	xClient.bCurrentlyWarned = True;
	xClient.SetTimer(1.0, true);
  xClient.client.showPopup(string(class'NexgenABMWarnDialog'), reason, client.playerName);

  // Signal event.
	class'NexgenUtil'.static.addProperty(args, "client", client.playerNum);
	class'NexgenUtil'.static.addProperty(args, "target", target.playerNum);
	class'NexgenUtil'.static.addProperty(args, "reason", reason);
	control.signalEvent("player_warned", args, true);

	logAdminAction("<C07>"$client.playerName$" warned"@target.playerName$".");
}


function readWarning(bool bRead) { bCurrentlyWarned = !bRead; }



/***************************************************************************************************
 *
 *  $DESCRIPTION  Wrapper function for NexgenController.logAdminAction() when called clientside.
 *  $PARAM        msg                Message that describes the action performed by the administrator.
 *  $PARAM        str1               Message specific content.
 *  $PARAM        str2               Message specific content.
 *  $PARAM        str3               Message specific content.
 *  $PARAM        bNoBroadcast       Whether not to broadcast this administrator action.
 *  $PARAM        bServerAdminsOnly  Broadcast message only to administrators with the server admin
 *                                   privilege.
 *
 **************************************************************************************************/
function SlogAdminAction(string msg, optional coerce string str1, optional coerce string str2,
                        optional coerce string str3, optional bool bNoBroadcast,
                        optional bool bServerAdminsOnly) {
	control.logAdminAction(client, msg, client.playerName, str1, str2, str3,
	                       client.player.playerReplicationInfo, bNoBroadcast, bServerAdminsOnly);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Decrypting code (copied from MSuLL's HostnameBan).
 *
 **************************************************************************************************/
function string SelElem(string Str, int Elem, optional string Char) {
	local int pos;

	if(Char=="") Char=":";

	while(Elem>1) {
		Str=Mid(Str, InStr(Str, Char)+1);
		Elem--;
	}
	pos=InStr(Str, Char);

	if(pos != -1) Str=Left(Str, pos);

	return Str;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when a string was received from the other machine.
 *  $PARAM        str  The string that was send by the other machine.
 *
 **************************************************************************************************/
simulated function recvStr(string str) {
	local string cmd;
	local string args[10];
	local int argCount;

	super.recvStr(str);

	// Check controller role.
	if (role != ROLE_Authority) {
		// Commands accepted by client.
		if(class'NexgenUtil'.static.parseCmd(str, cmd, args, argCount, CMD_ABM_PREFIX)) {
      switch (cmd) {
        case CMD_ABM_CLR:    exec_ABM_CLR(); break;
        case CMD_ABM_DELBAN: exec_ABM_DELBAN(int(args[0])); break;
      }
    }
	} else {
    // Commands accepted by server.
    if(class'NexgenUtil'.static.parseCmd(str, cmd, args, argCount, CMD_ABM_PREFIX)) {
      switch (cmd) {
        case CMD_ABM_DELBAN: exec_ABM_DELBAN(int(args[0])); break;
      }
    }
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called on the server when the client removed a ban via the BanPanel.
 *  $PARAM        entryNum  The index that was removed
 *
 **************************************************************************************************/
function removeBan(int entryNum) {
  exec_ABM_DELBAN(entryNum);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Executes a exec_ABM_DELBAN command.
 *  $PARAM        args      The arguments given for the command.
 *  $PARAM        argCount  Number of arguments available for the command.
 *
 **************************************************************************************************/
simulated function exec_ABM_DELBAN(int entryNum) {
	local NexgenClient nclient;
	local NexgenABMClient xClient;
	local NexgenSharedDataContainer container;
	local int index;
	
	if(!client.hasRight(client.R_BanOperator)) return;
	
  // Server Side Call
  if (role == ROLE_Authority) {
  
    // Get the data container.
    NexgenABMConfig(xControl.xConf).removeBan(entryNum, true);
  
	  for (nclient = xControl.control.clientList; nclient != none; nclient = nclient.nextClient) {
		  xClient = NexgenABMClient(xControl.getXClient(nclient));
   	  if (xClient != none && xClient.bInitialSyncComplete && xClient.client.hasRight(client.R_BanOperator)) {
        container = xClient.dataSyncMgr.getDataContainer(class'NexgenABMBanListDC'.default.containerID);
        if(container == none || NexgenABMBanListDC(container) == none) return;
        xClient.sendStr(xClient.CMD_ABM_PREFIX @ xClient.CMD_ABM_CLR);
        NexgenABMBanListDC(container).clearData();
        container.loadData();
        container.initRemoteClient(self);
        xClient.sendStr(xClient.CMD_ABM_PREFIX @ xClient.CMD_ABM_DELBAN);
      }
    }
  } else {
    // Client side call
    container = dataSyncMgr.getDataContainer(class'NexgenABMBanListDC'.default.containerID);
    if(container == none) return;

	  // Signal event to client controllers.
	  for (index = 0; index < client.clientCtrlCount; index++) {
	  	if (NexgenExtendedClientController(client.clientCtrl[index]) != none) {
	  		NexgenExtendedClientController(client.clientCtrl[index]).dataContainerAvailable(container);
	  	}
  	}

	  // Signal event to GUI.
  	client.mainWindow.mainPanel.dataContainerAvailable(container);
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Executes a exec_ABM_CLR command.
 *  $PARAM        args      The arguments given for the command.
 *  $PARAM        argCount  Number of arguments available for the command.
 *
 **************************************************************************************************/
simulated function exec_ABM_CLR() {
  local NexgenSharedDataContainer container;

  if(!client.hasRight(client.R_BanOperator)) return;
  
  container = dataSyncMgr.getDataContainer(class'NexgenABMBanListDC'.default.containerID);
  if(container != none && NexgenABMBanListDC(container) != none) NexgenABMBanListDC(container).clearData();
  
  if(banPanel != none) {
    if(banPanel.BanData != none) {
      banPanel.BanData = none;
      banPanel.loadBanList();
    }
  }
}

/***************************************************************************************************
 *
 *  Below are fixed functions for the Empty String TCP bug. Check out this article to read more
 *  about it: http://www.unrealadmin.org/forums/showthread.php?t=31280
 *
 **************************************************************************************************/
/***************************************************************************************************
 *
 *  $DESCRIPTION  Fixed version of the setVar function in NexgenExtendedClientController.
 *                Empty strings are now formated correctly before beeing sent to the server.
 *
 **************************************************************************************************/
simulated function setVar(string dataContainerID, string varName, coerce string value, optional int index) {
	local NexgenSharedDataContainer dataContainer;
	local string oldValue;
	local string newValue;

	// Get data container.
	dataContainer = dataSyncMgr.getDataContainer(dataContainerID);

	// Check if variable can be updated.
	if (dataContainer == none || !dataContainer.mayWrite(self, varName)) return;

	// Update variable value.
	oldValue = dataContainer.getString(varName, index);
	dataContainer.set(varName, value, index);
	newValue = dataContainer.getString(varName, index);

	// Send new value to server.
	if (newValue != oldValue) {
		if (dataContainer.isArray(varName)) {
			sendStr(CMD_SYNC_PREFIX @ CMD_UPDATE_VAR
			        @ class'NexgenABMMain'.static.formatCmdArgFixed(dataContainerID)
			        @ class'NexgenABMMain'.static.formatCmdArgFixed(varName)
			        @ index
			        @ class'NexgenABMMain'.static.formatCmdArgFixed(newValue));
		} else {
			sendStr(CMD_SYNC_PREFIX @ CMD_UPDATE_VAR
			        @ class'NexgenABMMain'.static.formatCmdArgFixed(dataContainerID)
			        @ class'NexgenABMMain'.static.formatCmdArgFixed(varName)
			        @ class'NexgenABMMain'.static.formatCmdArgFixed(newValue));
		}
	}
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Corrected version of the exec_UPDATE_VAR function in NexgenExtendedClientController.
 *                Due to the invalid format function, empty strings weren't sent correctly and were
 *                therefore not identifiable for the other machine (server). This caused the var index
 *                being erroneously recognized as the new var value on the server.
 *                Since the serverside set() function in NexgenSharedDataSyncManager also uses the
 *                invalid format functions, I implemented a fixed function in NexgenABMMain. The
 *                client side set() function can still be called safely without problems.
 *
 **************************************************************************************************/
simulated function exec_UPDATE_VAR(string args[10], int argCount) {
	local int varIndex;
	local string varName;
	local string varValue;
	local NexgenSharedDataContainer container;
	local int index;

	// Get arguments.
	if (argCount == 3) {
		varName = args[1];
		varValue = args[2];
	} else if (argCount == 4) {
		varName = args[1];
		varIndex = int(args[2]);
		varValue = args[3];
	} else {
		return;
	}

	if (role == ROLE_Authority) {
  	// Server side, call fixed set() function
  	NexgenABMMain(xControl).setFixed(args[0], varName, varValue, varIndex, self);
  } else {
  
    // Client Side
    dataSyncMgr.set(args[0], varName, varValue, varIndex, self);

    container = dataSyncMgr.getDataContainer(args[0]);

		// Signal event to client controllers.
		for (index = 0; index < client.clientCtrlCount; index++) {
			if (NexgenExtendedClientController(client.clientCtrl[index]) != none) {
				NexgenExtendedClientController(client.clientCtrl[index]).varChanged(container, varName, varIndex);
			}
		}

		// Signal event to GUI.
		client.mainWindow.mainPanel.varChanged(container, varName, varIndex);
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/
defaultproperties
{
     ctrlID="NexgenABMClient"
}
