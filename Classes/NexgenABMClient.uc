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
class NexgenABMClient extends NexgenExtendedClientController;

// Admin Panel
var NexgenABMAdminPanel ACEPanel;   // Link to the ACE Admin Panel
var NexgenABMBanPanel banPanel;     // Link to the Ban Control Panel

// Advanced player Info
var IACECheck playerCheck;          // Link to the ACE Check actor for this client
var string playerHWid;              // Detected Hardware ID of this client
var string playerMAC;               // Detected MAC Hash of this client
var string playerHostname;          // Detected Hostname of this client

// Intern variables
var bool bBanPending;               // Whether the player was already found in banlist and is only
                                    // waiting for additional info to be detected
var int banEntry;                   // Ban entry index of this client (if banned)
var string banReason;               // Ban entry reason of this client (if banned)
var string banPeriod;               // Ban entry period of this client (if banned)
var int HostnameTries;              // Amount of Hostname detection tries (every second)
var int AceTimeOut;                 // Time in seconds the client is already waiting for his ACE info to be available

// Warning variables
var bool bCurrentlyWarned;          // Is this client currently warned?
var string reason;                  // Warn reason
var string adminName;               // Admin who initiated the warning


// ACE variables for a specifc client
var string     PlayerName;          // Name of the player that owns this checker
var string     PlayerIP;            // Ip of the player that owns this checker
var string     UTCommandLine;       // Commandline of the application
var string     UTVersion;           // UT Client version
var string     CPUIdentifier;       // CPU Identifier string
var string     CPUMeasuredSpeed;    // CPU Measured speed
var string     CPUReportedSpeed;    // CPU Reported speed - trough the commandline
var string     OSString;            // Full OS Version string
var string     NICName;             // Full name of the primary network interface
var string     MACHash;             // MD5 hash of the primary mac address
var string     UTDCMacHash;         // UTDC compatible hash of the mac address
var string     HWHash;              // MD5 hash of the hardware ID
var string     CoreMD5;             // MD5 hash of the core.dll file
var string     EngineMD5;           // MD5 hash of the engine.dll file
var string     RenderMD5;           // MD5 hash of the render.dll file
var string     GalaxyMD5;           // MD5 hash of the galaxy.dll file
var string     WinDrvMD5;           // MD5 hash of the windrv.dll file
var string     WindowMD5;           // MD5 hash of the window.dll file
var string     RenderDeviceClass;   // Class of the renderdevice (eg: OpenGLDrv.OpenGLRenderDevice)
var string     RenderDeviceFile;    // DLL file of the renderdevice
var string     RenderDeviceMD5;     // MD5 hash of the renderdevice dll file
var string     SoundDeviceClass;    // Class of the sounddevice (eg: OpenAL.OpenALDevice)
var string     SoundDeviceFile;     // DLL file of the sounddevice
var string     SoundDeviceMD5;      // MD5 hash of the sounddevice file
var string     ACEMD5;              // MD5 hash of the ace module
var bool       bTunnel;             // Is the user behind a UDP Proxy/Tunnel?
var string     RealIP;              // RealIP of the player (only set if bTunnel == true)
var bool       bWine;               // Is the client running UT using the Wine Emulator?

const CMD_ABM_PREFIX = "ABM";       // Common ABM command prefix.
const CMD_ABM_DELBAN = "DEL";       // Delete ban entry command.
const CMD_ABM_CLR    = "CLR";       // Delete ban data command.

const CMD_ACEINFO_PREFIX = "ACEINFO";  // Common ACE info command prefix.
const CMD_ACEINFO_NEW = "ACEN";        // ACE info initiation command.
const CMD_ACEINFO_VAR = "ACEV";        // ACE info variable command.
const CMD_ACEINFO_COMPLETE = "ACEC";   // Command that indicates that the  ACE initialization is complete.


/***************************************************************************************************
 *
 *  $DESCRIPTION  Replication block.
 *
 **************************************************************************************************/
replication {

  reliable if (role != ROLE_SimulatedProxy) // Replicate to client...
    ACEInfoFailed, ACEInfoRequested;

  reliable if (role == ROLE_SimulatedProxy) // Replicate to server...
    removeBan, requestACEInfo, requestACEShot, SlogAdminAction, banPlayer, warnPlayer, ReadWarning;
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
    // Spawn ACE Panel
		ACEPanel = NexgenABMAdminPanel(client.mainWindow.mainPanel.addPanel("ACE Admin", class'NexgenABMAdminPanel', , "game"));

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
  
  // Add config panel
  if (client.hasRight(client.R_ServerAdmin)) {
		client.addPluginConfigPanel(class'NexgenABMConfigPanel');
	}
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Timer function. Called every second.
 *                The following actions are performed:
 *                - Warning Popup
 *                - ACE info detecting (only for players)
 *                - Hostname detecting (only if ipToCountry is available)
 *
 **************************************************************************************************/
function Timer() {
  local string DataBack;
	local string playerIP, Host;
	local Actor IpToCountry;
	local NexgenClientCore ncc;
	
	// Deactivate Timer if no longer needed
	if(!bCurrentlyWarned && (client.bSpectator || playerHWid != "" && playerMAC != "")
      && (playerHostname != "" || NexgenABMMain(xControl).ipToCountry == none)) {
    SetTimer(0.0, false);
    return;
  }
	
	// Implemented from NexgenWarn
	if(bCurrentlyWarned) {
	  client.showPopup(string(class'NexgenABMWarnDialog'), reason, adminName);
  }

  // Search for ACE Check Info
  if(!client.bSpectator && playerCheck == none) {
    foreach AllActors(class'IACECheck',playerCheck) {
      if(playerCheck != none && playerCheck.PlayerID == client.player.PlayerReplicationInfo.PlayerID) break;
      else playerCheck = none;
    }
  }

  // Check whether the ACE info is available
  if(playerCheck != none && (playerHWid == "" || playerMAC == "")) {
    playerHWid = playerCheck.xxGetToken(playerCheck.HWHash, ":", 1);
    playerMAC  = playerCheck.MACHash;
    
    
    // It is, notify controller
    if(playerHWid != "" && playerMAC != "") {
      NexgenABMMain(xControl).ACEInfoReceived(self);
    }
  }
  

  // Kick player for ACE bypass attempt
  if(NexgenABMConfig(xControl.xConf).bKickForACEBypassAttempt && !client.bSpectator &&
     playerHWid == "" && playerMAC == "") {
    AceTimeOut++;

    if(AceTimeOut >= NexgenABMConfig(xControl.xConf).BypassDetectionTime) {
      ncc = NexgenClientCore(client.getController(class'NexgenClientCore'.default.ctrlID));
      if(ncc != none) ncc.kickPlayer(client.playerNum, "ACE Bypass attempt detected!");
    }
  }
  
  
  // Hostname detector
  if(NexgenABMMain(xControl).ipToCountry != none && playerHostname == "" && HostnameTries <= NexgenABMMain(xControl).HostnameTimeout) {
    HostnameTries++;
    
    // Timeout detected, disable ipToCountry for the whole game
    if (HostnameTries > NexgenABMMain(xControl).HostnameTimeout) {
      NexgenABMMain(xControl).ipToCountry = none;
      NexgenABMMain(xControl).hostnameReceived(self);
      return;
    }
    
    playerIP = client.ipAddress;
   	if (playerIP != "") {
   	
      // Request info
  		DataBack = NexgenABMMain(xControl).ipToCountry.GetItemName(PlayerIP);

      // Check response
	   	if(DataBack == "!Added to queue" || DataBack == "!Waiting in queue" || DataBack == "!Resolving now" || DataBack == "!Queue full" ) {
	  		return;
  		}

	  	Host = SelElem(DataBack, 2);

      // Invalid response, deactivate ipToCountry for rest of the game
  		if(Left(DataBack, 1) == "!" || Host == "") {
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


function ReadWarning(bool bRead) { bCurrentlyWarned = !bRead; }


/***************************************************************************************************
 *
 *  $DESCRIPTION  Called on the server when the Client requests the ACE Info for a specific player.
 *  $PARAM        Num  The playerNum of the target player.
 *
 **************************************************************************************************/
function requestACEInfo(int Num) {
  local IACECheck A;
  local NexgenClient target;
  local string CommandLine;
  local string HWID;

  if(role != ROLE_Authority || !client.hasRight(client.R_Moderate)) return;
  
  target = control.getClientByNum(Num);
  if(target == none) {
    ACEInfoFailed();
    return;
  }

  foreach AllActors(class'IACECheck',A) {
    if(A.PlayerID == target.player.PlayerReplicationInfo.PlayerID) break;
    else A = none;
  }
  if(A == none) {
    ACEInfoFailed();
    return;
  } else ACEInfoRequested();

  if (A.UTCommandLine == "") CommandLine = "<none>";
  else CommandLine = A.UTCommandLine;

  if (A.bWine) HWID = "N/A";
  else HWID = A.xxGetToken(A.HWHash, ":", 1);


  // Init command
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_NEW @ class'NexgenABMMain'.static.formatCmdArgFixed(self.class));

  // Variables
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenABMMain'.static.formatCmdArgFixed("PlayerName") @ class'NexgenABMMain'.static.formatCmdArgFixed(A.PlayerName));
	sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenABMMain'.static.formatCmdArgFixed("PlayerIP") @ class'NexgenABMMain'.static.formatCmdArgFixed(A.PlayerIP));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenABMMain'.static.formatCmdArgFixed("UTCommandLine") @ class'NexgenABMMain'.static.formatCmdArgFixed(CommandLine));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenABMMain'.static.formatCmdArgFixed("UTVersion") @ class'NexgenABMMain'.static.formatCmdArgFixed(A.UTVersion));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenABMMain'.static.formatCmdArgFixed("CPUIdentifier") @ class'NexgenABMMain'.static.formatCmdArgFixed(A.CPUIdentifier));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenABMMain'.static.formatCmdArgFixed("CPUMeasuredSpeed") @ class'NexgenABMMain'.static.formatCmdArgFixed(A.CPUMeasuredSpeed));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenABMMain'.static.formatCmdArgFixed("CPUReportedSpeed") @ class'NexgenABMMain'.static.formatCmdArgFixed(A.CPUReportedSpeed));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenABMMain'.static.formatCmdArgFixed("OSString") @ class'NexgenABMMain'.static.formatCmdArgFixed(A.OSString));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenABMMain'.static.formatCmdArgFixed("NICName") @ class'NexgenABMMain'.static.formatCmdArgFixed(A.NICName));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenABMMain'.static.formatCmdArgFixed("MACHash") @ class'NexgenABMMain'.static.formatCmdArgFixed(A.MACHash));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenABMMain'.static.formatCmdArgFixed("UTDCMacHash") @ class'NexgenABMMain'.static.formatCmdArgFixed(A.UTDCMacHash));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenABMMain'.static.formatCmdArgFixed("HWHash") @ class'NexgenABMMain'.static.formatCmdArgFixed(HWID));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenABMMain'.static.formatCmdArgFixed("CoreMD5") @ class'NexgenABMMain'.static.formatCmdArgFixed(A.CoreMD5));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenABMMain'.static.formatCmdArgFixed("EngineMD5") @ class'NexgenABMMain'.static.formatCmdArgFixed(A.EngineMD5));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenABMMain'.static.formatCmdArgFixed("RenderMD5") @ class'NexgenABMMain'.static.formatCmdArgFixed(A.RenderMD5));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenABMMain'.static.formatCmdArgFixed("GalaxyMD5") @ class'NexgenABMMain'.static.formatCmdArgFixed(A.GalaxyMD5));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenABMMain'.static.formatCmdArgFixed("WinDrvMD5") @ class'NexgenABMMain'.static.formatCmdArgFixed(A.WinDrvMD5));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenABMMain'.static.formatCmdArgFixed("RenderDeviceClass") @ class'NexgenABMMain'.static.formatCmdArgFixed(A.RenderDeviceClass));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenABMMain'.static.formatCmdArgFixed("RenderDeviceFile") @ class'NexgenABMMain'.static.formatCmdArgFixed(A.RenderDeviceFile));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenABMMain'.static.formatCmdArgFixed("RenderDeviceMD5") @ class'NexgenABMMain'.static.formatCmdArgFixed(A.RenderDeviceMD5));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenABMMain'.static.formatCmdArgFixed("SoundDeviceClass") @ class'NexgenABMMain'.static.formatCmdArgFixed(A.SoundDeviceClass));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenABMMain'.static.formatCmdArgFixed("SoundDeviceFile") @ class'NexgenABMMain'.static.formatCmdArgFixed(A.SoundDeviceFile));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenABMMain'.static.formatCmdArgFixed("SoundDeviceMD5") @ class'NexgenABMMain'.static.formatCmdArgFixed(A.SoundDeviceMD5));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenABMMain'.static.formatCmdArgFixed("ACEMD5") @ class'NexgenABMMain'.static.formatCmdArgFixed(A.ACEMD5));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenABMMain'.static.formatCmdArgFixed("bTunnel") @ class'NexgenABMMain'.static.formatCmdArgFixed(A.bTunnel));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenABMMain'.static.formatCmdArgFixed("RealIP") @ class'NexgenABMMain'.static.formatCmdArgFixed(A.RealIP));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenABMMain'.static.formatCmdArgFixed("bWine") @ class'NexgenABMMain'.static.formatCmdArgFixed(A.bWine));

	// Complete Command
	sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_COMPLETE);

}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Called on the server when the Client requests the ACE Info for a specific player.
 *  $PARAM        Num  The playerNum of the target player.
 *
 **************************************************************************************************/
function requestACEShot(int Num) {
  local IACECheck A;
  local NexgenClient target;

  if(role != ROLE_Authority || !client.hasRight(client.R_Moderate)) return;
  
  target = control.getClientByNum(Num);
  if(target == none) {
    ACEInfoFailed();
    return;
  }

  foreach AllActors(class'IACECheck',A) {
    if(A.PlayerID == target.player.PlayerReplicationInfo.PlayerID) break;
    else A = none;
  }
  if(A == none) {
    client.showMsg("<C00>Screenshot failed!");
    return;
  }

  A.CreateScreenshot(client.player);

}

simulated function ACEInfoFailed()    { if(ACEPanel != none) ACEPanel.ACEInfoFailed();    }
simulated function ACEInfoRequested() { if(ACEPanel != none) ACEPanel.ACEInfoRequested(); }




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
    } else if (class'NexgenUtil'.static.parseCmd(str, cmd, args, argCount, CMD_ACEINFO_PREFIX)) {
			switch (cmd) {
				case CMD_ACEINFO_NEW:       exec_ACEINFO_NEW(args, argCount); break;
				case CMD_ACEINFO_VAR:       exec_ACEINFO_VAR(args, argCount); break;
				case CMD_ACEINFO_COMPLETE:  exec_ACEINFO_COMPLETE(args, argCount); break;
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
 *  $DESCRIPTION  Executes a INIT_CONTAINER command.
 *  $PARAM        args      The arguments given for the command.
 *  $PARAM        argCount  Number of arguments available for the command.
 *
 **************************************************************************************************/
simulated function exec_INIT_CONTAINER(string args[10], int argCount) {
  if(!bInitialSyncComplete) super.exec_INIT_CONTAINER(args, argCount);
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Executes a INIT_CONTAINER command.
 *  $PARAM        args      The arguments given for the command.
 *  $PARAM        argCount  Number of arguments available for the command.
 *
 **************************************************************************************************/
simulated function exec_ACEINFO_NEW(string args[10], int argCount) {

  if(!client.hasRight(client.R_Moderate)) return;

  // Clear results
  PlayerName = "";
  PlayerIP = "";
  UTCommandLine = "";
  UTVersion = "";
  CPUIdentifier = "";
  CPUMeasuredSpeed = "";
  CPUReportedSpeed = "";
  OSString = "";
  NICName = "";
  MACHash = "";
  UTDCMacHash = "";
  HWHash = "";
  CoreMD5 = "";
  EngineMD5 = "";
  RenderMD5 = "";
  GalaxyMD5 = "";
  WinDrvMD5 = "";
  WindowMD5 = "";
  RenderDeviceClass = "";
  RenderDeviceFile = "";
  RenderDeviceMD5 = "";
  SoundDeviceClass = "";
  SoundDeviceFile = "";
  SoundDeviceMD5 = "";
  ACEMD5 = "";
  bTunnel = false;
  RealIP = "";
  bWine = false;
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Executes a INIT_VAR command.
 *  $PARAM        args      The arguments given for the command.
 *  $PARAM        argCount  Number of arguments available for the command.
 *
 **************************************************************************************************/
simulated function exec_ACEINFO_VAR(string args[10], int argCount) {
  if(!client.hasRight(client.R_Moderate)) return;
  switch(args[0]) {
    case "PlayerName":        PlayerName        = args[1]; break;
    case "PlayerIP":          PlayerIP          = args[1]; break;
    case "UTCommandLine":     UTCommandLine     = args[1]; break;
    case "UTVersion":         UTVersion         = args[1]; break;
    case "CPUIdentifier":     CPUIdentifier     = args[1]; break;
    case "CPUMeasuredSpeed":  CPUMeasuredSpeed  = args[1]; break;
    case "CPUReportedSpeed":  CPUReportedSpeed  = args[1]; break;
    case "OSString":          OSString          = args[1]; break;
    case "NICName":           NICName           = args[1]; break;
    case "MACHash":           MACHash           = args[1]; break;
    case "UTDCMacHash":       UTDCMacHash       = args[1]; break;
    case "HWHash":            HWHash            = args[1]; break;
    case "CoreMD5":           CoreMD5           = args[1]; break;
    case "EngineMD5":         EngineMD5         = args[1]; break;
    case "RenderMD5":         RenderMD5         = args[1]; break;
    case "GalaxyMD5":         GalaxyMD5         = args[1]; break;
    case "WinDrvMD5":         WinDrvMD5         = args[1]; break;
    case "RenderDeviceClass": RenderDeviceClass = args[1]; break;
    case "RenderDeviceFile":  RenderDeviceFile  = args[1]; break;
    case "RenderDeviceMD5":   RenderDeviceMD5   = args[1]; break;
    case "SoundDeviceClass":  SoundDeviceClass  = args[1]; break;
    case "SoundDeviceFile":   SoundDeviceFile   = args[1]; break;
    case "SoundDeviceMD5":    SoundDeviceMD5    = args[1]; break;
    case "ACEMD5":            ACEMD5            = args[1]; break;
    case "bTunnel":           bTunnel           = bool(args[1]); break;
    case "RealIP":            RealIP            = args[1]; break;
    case "bWine":             bWine             = bool(args[1]); break;
  }

}



/***************************************************************************************************
 *
 *  $DESCRIPTION  Executes a INIT_COMPLETE command.
 *  $PARAM        args      The arguments given for the command.
 *  $PARAM        argCount  Number of arguments available for the command.
 *
 **************************************************************************************************/
simulated function exec_ACEINFO_COMPLETE(string args[10], int argCount) {

  if(!client.hasRight(client.R_Moderate)) return;
  
  // Notify GUI
  ACEPanel.ACEInfoReceived();

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