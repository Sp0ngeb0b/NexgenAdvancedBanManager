/*##################################################################################################
##
##  Nexgen Advanced Ban Manager version 2.01
##  Copyright (C) 2020 Patrick "Sp0ngeb0b" Peltzer
##
##  This program is free software; you can redistribute and/or modify
##  it under the terms of the Open Unreal Mod License version 1.1.
##
##  Contact: spongebobut@yahoo.com | www.unrealriders.eu
##
##################################################################################################*/
/*##################################################################################################
##  Changelog:
##
##  Version 2.00:
##  [Removed] ACE features since they are now included in NexgenACEExt
##  [Added]   Account name of admin banning is now displayed in the popup and saved for the ban entry
##            Option for admins to not display their names when warning/kicking/banning
##
##  Version 1.03:
##  [Removed] Bypass detection  
##  [Changed] Spectators are supported if feature is enabled in ACE
##
##  Version 1.02:
##  [Fix]     RequestInfo and TakeScreenshot buttons mistakenly disabled for green, gold and teamless
##            players
##  [Fix]     Critical bug in use with Bots
##  [Added]   Feature to detect ACE bypass attempts and kick the respective player
##
##  Hotfix  1.01:
##  [Fix]     Sometimes players were erroneously considered as banned
##
##################################################################################################*/
class NexgenABMMain extends NexgenExtendedPlugin;

var Actor ipToCountry;                 // IpToCountry Actor (if available)

var byte ACEStatus;                    // 0=Not presend, 1=Checking Players, 2=Checking Players+Spectators

const separator = ",";                 // global separator
const HostnameTimeout = 10;            // Time in seconds before giving up on Hostname detection
const maxMasksLength = 200;            // max length of a mask string

/***************************************************************************************************
 *
 *  $DESCRIPTION  Initializes the plugin. Note that if this function returns false the plugin will
 *                be destroyed and is not to be used anywhere.
 *  $RETURN       True if the initialization succeeded, false if it failed.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function bool initialize() {

  // Let super class initialize.
  if (!super.initialize()) {
    return false;
  }

  // Locate IpToCountry
  ForEach Level.AllActors(class'Actor', ipToCountry, 'IpToCountry') break;  

  return true;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when a new client has been created. Use this function to setup the new
 *                client with your own extensions (in order to support the plugin).
 *  $PARAM        client  The client that was just created.
 *  $REQUIRE      client != none
 *  $OVERRIDE
 *
 **************************************************************************************************/
function clientCreated(NexgenClient client) {
  local NexgenExtendedClientController xClient;

  xClient = NexgenExtendedClientController(client.addController(clientControllerClass, self));
  xClient.dataSyncMgr = dataSyncMgr;
  xClient.xControl = self;
  if(ipToCountry != none) xClient.setTimer(1.0, true);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when the plugin requires the to shared data containers to be created. These
 *                may only be created / added to the shared data synchronization manager inside this
 *                function. Once created they may not be destroyed until the current map unloads.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function createSharedDataContainers() {
  dataSyncMgr.addDataContainer(class'NexgenABMBanListDC');
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Checks if the login request of the specified client should be accepted. If the
 *                request is rejected, this function will automatically kill the client.
 *  $PARAM        client  The client whose login request is to be checked.
 *  $REQUIRE      client != none
 *
 **************************************************************************************************/
function bool checkLogin(NexgenClient client, out name rejectType, out string reason,
                    out string popupWindowClass, out string popupArgs[4]) {
  local NexgenABMClient xClient;

  xClient = NexgenABMClient(getXClient(client));

  if(xClient != none && isBanned(xClient)) {
    if(control.sConf.autoUpdateBans) {
      if( ACEStatus == 2 || (ACEStatus == 1 && !client.bSpectator) || ipToCountry != none) {
        xClient.bBanPending = True;
        return true;
      } else updateBan(xClient.banEntry, xClient.client.ipAddress, xClient.client.playerID, "", "", "");
    }
    rejectType = control.RT_Banned;
    reason = control.lng.bannedMsg;
    popupWindowClass = "NexgenBannedDialog";
    popupArgs[0] = xClient.banReason;
    popupArgs[1] = xClient.banPeriod;
    return false;
  }
  
  return true;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called whenever a client has finished its initialisation process. During this
 *                process things such as the remote control window are created. So only after the
 *                client is fully initialized all functions can be safely called.
 *  $PARAM        client  The client that has finished initializing.
 *  $REQUIRE      client != none
 *  $OVERRIDE
 *
 **************************************************************************************************/
function clientInitialized(NexgenClient client) {
	local NexgenExtendedClientController xClient;
  
	super.clientInitialized(client);
  
  // Get client controller.
	xClient = getXClient(client);
  
  if((client.hasRight(client.R_Moderate) || client.hasRight(client.R_BanOperator)) && NexgenABMClient(xClient) != none) {
    NexgenABMClient(xClient).getAccountTitle();
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when a general event has occurred in the system.
 *  $PARAM        type      The type of event that has occurred.
 *  $PARAM        argument  Optional arguments providing details about the event.
 *
 **************************************************************************************************/
function notifyEvent(string type, optional string arguments) {
  local NexgenClient client;
  local NexgenABMClient xClient;
  
  // Listen for ACE settings
  if(type == "ace_config") {
    if(bool(class'NexgenUtil'.static.getProperty(arguments, "bCheckSpectators"))) ACEStatus = 2;
    else ACEStatus = 1;
  }

  // Player ACE Info available
  if(type == "ace_login") {
    client = control.getClientByNum(int(class'NexgenUtil'.static.getProperty(arguments, "client")));
    xClient = NexgenABMClient(getXClient(client));
    if(xClient != none) {
      xClient.playerHWid = class'NexgenUtil'.static.getProperty(arguments, "HWid");
      xClient.playerMAC  = class'NexgenUtil'.static.getProperty(arguments, "MAC");
      ACEInfoReceived(xClient);
    }
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when a client's HWid and MAC Hash is received.
 *  $PARAM        xClient The client whose ACE data is available.
 *  $REQUIRE      xClient != none
 *
 **************************************************************************************************/
function ACEInfoReceived(NexgenABMClient xClient) {

  if(xClient == none) return;

  // Client already failed our previous checks?
  if(xClient.bBanPending) {
    // All necessary Info available?
    if(xClient.playerHostname != "" || ipToCountry == none) {
      // Yes. Update entry and ban player.
      updateBan(xClient.banEntry, xClient.client.ipAddress, xClient.client.playerID, xClient.playerHWid,
                xClient.playerMAC, xClient.playerHostname);
      banPlayer(xClient);
    }
  } else {
    // Check login for this client
    if(isBanned(xClient, xClient.playerHWid, xClient.playerMAC, xClient.playerHostname)) {
      if(control.sConf.autoUpdateBans) {
        if(xClient.playerHostname != "" || ipToCountry == none) {
          updateBan(xClient.banEntry, xClient.client.ipAddress, xClient.client.playerID, xClient.playerHWid,
                    xClient.playerMAC, xClient.playerHostname);                                                                                                                                                                                                                                                          
          banPlayer(xClient);
        } else xClient.bBanPending = True;
      } else banPlayer(xClient);
    }
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when a client's Hostname is available or the process failed.
 *  $PARAM        xClient The client whose Hostname is available.
 *  $REQUIRE      xClient != none
 *
 **************************************************************************************************/
function hostnameReceived(NexgenABMClient xClient) {
  local string args;
  
  if(xClient == none) return;
  
  // Signal event.
  class'NexgenUtil'.static.addProperty(args, "client", xClient.client.playerNum);
  class'NexgenUtil'.static.addProperty(args, "hostname", xClient.playerHostname);
  control.signalEvent("player_hostname", args, true);
  
  // Client already failed our previous checks?
  if(xClient.bBanPending) {
    // All necessary Info available?
    if( ACEStatus == 0 || (ACEStatus == 1 && xClient.client.bSpectator) || (xClient.playerHWid != "" && xClient.playerMAC != "")) {
      // Yes. Update entry and ban player.
      updateBan(xClient.banEntry, xClient.client.ipAddress, xClient.client.playerID, xClient.playerHWid,
                xClient.playerMAC, xClient.playerHostname);
      banPlayer(xClient);
    }
  } else {
    // Check login for this client
    if(isBanned(xClient, xClient.playerHWid, xClient.playerMAC, xClient.playerHostname)) {
      if(control.sConf.autoUpdateBans) {
        if( (ACEStatus == 2 || (ACEStatus == 1 && !xClient.client.bSpectator)) && xClient.playerHWid != "" && xClient.playerMAC != "") {
          updateBan(xClient.banEntry, xClient.client.ipAddress, xClient.client.playerID, xClient.playerHWid,
                    xClient.playerMAC, xClient.playerHostname);
          banPlayer(xClient);
        } else xClient.bBanPending = True;
      } else banPlayer(xClient);
    }
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Disconnects the specific client.
 *  $PARAM        xClient Client to be removed.
 *  $REQUIRE      xClient != none
 *
 **************************************************************************************************/
function banPlayer(NexgenABMClient xClient) {
  if(xClient == none) return;

  // Extended detail log
  control.nscLog("Client is banned in ban entry"@xClient.banEntry);
  control.nscLog("Client IP"@xClient.client.ipAddress);
  control.nscLog("Client ID"@xClient.client.playerID);
  control.nscLog("Client HWid"@xClient.playerHWid);
  control.nscLog("Client MAC"@xClient.playerMAC);
  control.nscLog("Client Hostname"@xClient.playerHostname);

  xClient.client.showPopup("NexgenBannedDialog", xClient.banReason, xClient.banPeriod, "", "");
  xClient.client.player.destroy();
  control.nscLog(control.lng.format(control.lng.loginRejectedMsg, control.lng.bannedMsg));
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Checks if the specified client is banned on this server.
 *  $PARAM        client     The client for which the ban is to be checked.
 *  $PARAM        HWid       The client's HWid.
 *  $PARAM        MACHash    The client's MACHash.
 *  $PARAM        Hostname   The client's Hostname.
 *  $REQUIRE      client != none
 *  $RETURN       True if the client is banned, false if not.
 *  $ENSURE       result == true ? new.banPeriod != "" : true
 *
 **************************************************************************************************/
function bool isBanned(NexgenABMClient xClient, optional string HWid, optional string MACHash, optional string Hostname) {
  local int banIndex;
  local bool bBanned;

  // Get ban entry.
  banIndex = getBanIndex(xClient.client.ipAddress, xClient.client.playerID, HWid, MACHash, Hostname);

  // Check if player is banned and the ban hasn't expired.
  if (banIndex >= 0) {
    xClient.banEntry  = banIndex;
    xClient.banReason = NexgenABMConfig(xConf).banReason[banIndex];
    xClient.banPeriod = control.lng.getBanPeriodDescription(NexgenABMConfig(xConf).banPeriod[banIndex]);
    bBanned = !isExpiredBan(banIndex);
  }

  // Return result.
  return bBanned;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Returns the index in the ban list for the given player info.
 *  $PARAM        playerName  Name of the player for which the entry in the ban list is to be found.
 *  $PARAM        playerIP    IP address of the player.
 *  $PARAM        playerID    ID code of the player.
 *  $PARAM        HWid        HWid of the player.
 *  $PARAM        MACHash     MACHash of the player.
 *  $PARAM        Hostname    Hostname of the player.
 *  $RETURN       The index in the ban list for the specified player if banned, -1 if the player is
 *                not banned on the server.
 *  $ENSURE       0 <= result && result <= arrayCount(bannedName) || result == -1
 *
 **************************************************************************************************/
function int getBanIndex(string playerIP, string playerID, string HWid, string MACHash, string Hostname) {
  local int index;
  local bool bFound, bIPMatch, bIDMatch, bHWidMatch, bMACMatch, bHNMatch;

  // Lookup player in the ban list.
  while (!bFound && index < arrayCount(NexgenABMConfig(xConf).bannedName) && NexgenABMConfig(xConf).bannedName[index] != "") {
    if(playerIP != "" && NexgenABMConfig(xConf).bannedIPs[index] != "")       bIPMatch   = checkMasksString(NexgenABMConfig(xConf).bannedIPs[index], playerIP);
    if(playerID != "" && NexgenABMConfig(xConf).bannedIDs[index] != "")       bIDMatch   = instr(NexgenABMConfig(xConf).bannedIDs[index], playerID)       >= 0;
    if(HWid != "" && NexgenABMConfig(xConf).bannedHWIDs[index] != "")         bHWidMatch = instr(NexgenABMConfig(xConf).bannedHWIDs[index], HWid)         >= 0;
    if(MACHash != "" && NexgenABMConfig(xConf).bannedMACHashes[index] != "")  bMACMatch  = instr(NexgenABMConfig(xConf).bannedMACHashes[index], MACHash)  >= 0;
    if(Hostname != "" && NexgenABMConfig(xConf).bannedHostnames[index] != "") bHNMatch   = checkMasksString(NexgenABMConfig(xConf).bannedHostnames[index], Hostname);
    
    // Match?
    if (bIPMatch || bIDMatch || bHWidMatch || bMACMatch || bHNMatch) {
      // Oh yeah.
      bFound = true;
    } else {
      // Nope, maybe next.
      index++;
    }
  }

  // Return index in the ban list.
  if (bFound) {
    return index;
  } else {
    return -1;
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Updates the specified ban entry. If a new IP or ID for the specified entry is
 *                detected it will be added.
 *  $PARAM        index     Location in the banlist.
 *  $PARAM        playerIP       IP address of the player.
 *  $PARAM        playerID       ID code of the player.
 *  $PARAM        playerHWid     HWid of the player.
 *  $PARAM        playerMACHash  MACHash of the player.
 *  $PARAM        playerHN       Hostname of the player.
 *  $REQUIRE      0 <= index && index <= arrayCount(bannedName) && bannedName[index] != ""
 *  $RETURN       True if the specified ban entry was updated, false if no changes were made.
 *  $ENSURE       instr(bannedIPs[index], playerIP) >= 0 && instr(bannedIDs[index], playerID) >= 0
 *
 **************************************************************************************************/
function bool updateBan(int index, string playerIP, string playerID, string playerHWid, string playerMACHash,
                        string playerHN) {
  local bool bIPMatch, bIDMatch, bHWIDMatch, bMACMatch, bHNMatch;
  local string currID, currHWid, currMACHash;
  local int idCount, HWidCount, MACCount;
  local string remaining;
  
  
  if(playerIP != "") {
    // Compare & count IP address.
    if(checkMasksString(NexgenABMConfig(xConf).bannedIPs[index], playerIP)) {
      bIPMatch = true;
    }

    // Add IP address if not already in the list and the list isn't full.
    if (!bIPMatch && Len(NexgenABMConfig(xConf).bannedIPs[index]) + Len(playerIP) + Len(separator) < maxMasksLength) {
      if (NexgenABMConfig(xConf).bannedIPs[index] == "") {
        setFixed(class'NexgenABMBanListDC'.default.containerID, "bannedIPs", playerIP, index, self);
      } else {
        setFixed(class'NexgenABMBanListDC'.default.containerID, "bannedIPs", NexgenABMConfig(xConf).bannedIPs[index] $ separator $ playerIP, index, self);
      }
    }
  }

  if(playerID != "") {
    // Compare & count client ID's.
    remaining = NexgenABMConfig(xConf).bannedIDs[index];
    while (!bIDMatch && remaining != "") {
      class'NexgenUtil'.static.split(remaining, currID, remaining);
      currID = class'NexgenUtil'.static.trim(currID);
      if (currID ~= playerID) {
        bIDMatch = true;
      } else {
        idCount++;
      }
    }
    
    // Add client ID if not already in the list and the list isn't full.
    if (!bIDMatch && idCount < control.sConf.maxBanClientIDs) {
      if (NexgenABMConfig(xConf).bannedIDs[index] == "") {
        setFixed(class'NexgenABMBanListDC'.default.containerID, "bannedIDs", playerID, index, self);
      } else {
        setFixed(class'NexgenABMBanListDC'.default.containerID, "bannedIDs", NexgenABMConfig(xConf).bannedIDs[index] $ separator $ playerID, index, self);
      }
    }
  }
  
  if(playerHWid != "") {
    // Compare & count client HWid's.
    remaining = NexgenABMConfig(xConf).bannedHWIDs[index];
    while (!bHWidMatch && remaining != "") {
      class'NexgenUtil'.static.split(remaining, currHWid, remaining);
      currHWid = class'NexgenUtil'.static.trim(currHWid);
      if (currHWid ~= playerHWid) {
        bHWIDMatch = true;
      } else {
        HWidCount++;
      }
    }
    
    // Add client ID if not already in the list and the list isn't full.
    if (!bHWIDMatch && HWidCount < control.sConf.maxBanClientIDs) {
      if (NexgenABMConfig(xConf).bannedHWIDs[index] == "") {
        setFixed(class'NexgenABMBanListDC'.default.containerID, "bannedHWIDs", playerHWid, index, self);
      } else {
        setFixed(class'NexgenABMBanListDC'.default.containerID, "bannedHWIDs", NexgenABMConfig(xConf).bannedHWIDs[index] $ separator $ playerHWid, index, self);
      }
    }
  }
  
  if(playerMACHash != "") {
    // Compare & count client MACHashes.
    remaining = NexgenABMConfig(xConf).bannedMACHashes[index];
    while (!bMACMatch && remaining != "") {
      class'NexgenUtil'.static.split(remaining, currMACHash, remaining);
      currMACHash = class'NexgenUtil'.static.trim(currMACHash);
      if (currMACHash ~= playerMACHash) {
        bMACMatch = true;
      } else {
        MACCount++;
      }
    }

    // Add MACHash if not already in the list and the list isn't full.
    if (!bMACMatch && MACCount < control.sConf.maxBanClientIDs) {
      if (NexgenABMConfig(xConf).bannedMACHashes[index] == "") {
        setFixed(class'NexgenABMBanListDC'.default.containerID, "bannedMACHashes", playerMACHash, index, self);
      } else {
        setFixed(class'NexgenABMBanListDC'.default.containerID, "bannedMACHashes", NexgenABMConfig(xConf).bannedMACHashes[index] $ separator $ playerMACHash, index, self);
      }
    }
  }
  
  if(playerHN != "") {
    // Compare & count IP address.
    if(checkMasksString(NexgenABMConfig(xConf).bannedHostnames[index], playerHN)) {
      bHNMatch = true;
    }

    // Add IP address if not already in the list and the list isn't full.
    if (!bHNMatch && Len(NexgenABMConfig(xConf).bannedHostnames[index]) + Len(playerHN) + Len(separator) < maxMasksLength) {
      if (NexgenABMConfig(xConf).bannedHostnames[index] == "") {
        setFixed(class'NexgenABMBanListDC'.default.containerID, "bannedHostnames", playerHN, index, self);
      } else {
        setFixed(class'NexgenABMBanListDC'.default.containerID, "bannedHostnames", NexgenABMConfig(xConf).bannedHostnames[index] $ separator $ playerHN, index, self);
      }
    }
  }

  // Save changes.
  if (!bIPMatch || !bIDMatch || !bHWIDMatch || !bMACMatch || !bHNMatch) {
    dataSyncMgr.saveSharedData(class'NexgenABMBanListDC'.default.containerID);
    return true;
  } else {
    return false;
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Checks whether the specified ban entry has expired.
 *  $PARAM        index  Location in the banlist.
 *  $REQUIRE      0 <= index && index <= arrayCount(bannedName) && bannedName[index] != ""
 *  $RETURN       True if the specified ban entry has expired, false if not.
 *
 **************************************************************************************************/
function bool isExpiredBan(int index) {
  local bool bExpired;
  local byte banPeriodType;
  local string banPeriodArgs;
  local int year, month, day, hour, minute;

  // Get period type.
  class'NexgenConfig'.static.getBanPeriodType(NexgenABMConfig(xConf).banPeriod[index],
                                              banPeriodType,
                                              banPeriodArgs);

  // Check for expiration.
  if (banPeriodType == control.sConf.BP_Matches) {
    // Banned for some matches.
    bExpired = (int(banPeriodArgs) <= 0);

  } else if (banPeriodType == control.sConf.BP_UntilDate) {
    // Banned until some date.
    class'NexgenUtil'.static.readDate(banPeriodArgs, year, month, day, hour, minute);

    bExpired =  level.year   > year  || level.year  == year  &&
               (level.month  > month || level.month == month &&
               (level.day    > day   || level.day   == day   &&
               (level.hour   > hour  || level.hour  == hour  &&
                level.minute >= minute)));

  } else {
    // Banned forever, never expires.
    bExpired = false;
  }

  // Return result.
  return bExpired;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Compares a string with multiple masks.
 *  $PARAM        masksString  Multiple masks.
 *  $PARAM        target       The string which is to be checked with the Masks.
 *  $RETURN       True if the target string matches one of the mask
 *
 **************************************************************************************************/
function bool checkMasksString(string masksString, string target) {
  local string currMask, remaining;
  local bool bFound;

  remaining = masksString;

  // Split head element from tail.
  while (remaining != "" && !bFound) {
    class'NexgenUtil'.static.split(remaining, currMask, remaining);
    currMask = class'NexgenUtil'.static.trim(currMask);
    bFound = _match(currMask, target);
  }

   return bFound;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Compares a string with a mask (copied from MSuLL's HostnameBan).
 *                Wildcards: * = X chars; ? = 1 char
 *                Wildcards can appear anywhere in the mask
 *  $PARAM        mask       The mask.
 *  $PARAM        target     The string which is to be checked with the Mask.
 *  $RETURN       True if the target string matches the mask
 *
 **************************************************************************************************/
static final function bool _match(string mask, string target) {
  local string m, mp, cp;

  m = Left(mask, 1);
  while ((target != "") && (m != "*")) {
    if (m != Left(target, 1) && m != "?") return false;
    mask = Mid(Mask, 1);
    target = Mid(target, 1);
    m = Left(mask, 1);
  }

  while (target != "") {
    if (m == "*") {
      mask = Mid(Mask, 1);
      if (mask == "") return true; // only "*" mask -> always true
      mp = mask;
      cp = Mid(target, 1);
      m = Left(mask, 1);
    } else if (m == Left(target, 1) || m == "?") {
      mask = Mid(Mask, 1);
      target = Mid(target, 1);
      m = Left(mask, 1);
    } else {
      mask = mp;
      m = Left(mask, 1);
      target = cp;
      cp = Mid(cp, 1);
    }
  }

  while (Left(mask, 1) == "*") mask = Mid(Mask, 1);
  return (mask == "");
}

/***************************************************************************************************
 *
 *  Below are fixed functions for the Empty String TCP bug. Check out this article to read more
 *  about it: http://www.unrealadmin.org/forums/showthread.php?t=31280
 *
 **************************************************************************************************/
/***************************************************************************************************
 *
 *  $DESCRIPTION  Fixed serverside set() function of NexgenSharedDataSyncManager. Uses correct
 *                formatting.
 *
 **************************************************************************************************/
function setFixed(string dataContainerID, string varName, coerce string value, optional int index, optional Object author) {
  local NexgenSharedDataContainer dataContainer;
  local NexgenClient client;
  local NexgenExtendedClientController xClient;
  local string oldValue;
  local string newValue;

  // Get the data container.
  dataContainer = dataSyncMgr.getDataContainer(dataContainerID);
  if (dataContainer == none) return;

  oldValue = dataContainer.getString(varName, index);
  dataContainer.set(varName, value, index);
  newValue = dataContainer.getString(varName, index);

  // Notify clients if variable has changed.
  if (newValue != oldValue) {
    for (client = control.clientList; client != none; client = client.nextClient) {
      xClient = getXClient(client);
      if (xClient != none && xClient.bInitialSyncComplete && dataContainer.mayRead(xClient, varName)) {
        if (dataContainer.isArray(varName)) {
          xClient.sendStr(xClient.CMD_SYNC_PREFIX @ xClient.CMD_UPDATE_VAR
                          @ static.formatCmdArgFixed(dataContainerID)
                          @ static.formatCmdArgFixed(varName)
                          @ index
                          @ static.formatCmdArgFixed(newValue));
        } else {
          xClient.sendStr(xClient.CMD_SYNC_PREFIX @ xClient.CMD_UPDATE_VAR
                          @ static.formatCmdArgFixed(dataContainerID)
                          @ static.formatCmdArgFixed(varName)
                          @ static.formatCmdArgFixed(newValue));
        }
      }
    }
  }

  // Also notify the server side controller of this event.
  if (newValue != oldValue) {
    varChanged(dataContainer, varName, index, author);
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Corrected version of the static formatCmdArg function in NexgenUtil. Empty strings
 *                are formated correctly now (original source of all trouble).
 *
 **************************************************************************************************/
static function string formatCmdArgFixed(coerce string arg) {
  local string result;

  result = arg;

  // Escape argument if necessary.
  if (result == "") {
    result = "\"\"";                      // Fix (originally, arg was assigned instead of result -_-)
  } else {
    result = class'NexgenUtil'.static.replace(result, "\\", "\\\\");
    result = class'NexgenUtil'.static.replace(result, "\"", "\\\"");
    result = class'NexgenUtil'.static.replace(result, chr(0x09), "\\t");
    result = class'NexgenUtil'.static.replace(result, chr(0x0A), "\\n");
    result = class'NexgenUtil'.static.replace(result, chr(0x0D), "\\r");

    if (instr(arg, " ") > 0) {
      result = "\"" $ result $ "\"";
    }
  }

  // Return result.
  return result;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/
defaultproperties
{
     versionNum=201
     extConfigClass=Class'NexgenABMConfigExt'
     sysConfigClass=Class'NexgenABMConfigSys'
     clientControllerClass=Class'NexgenABMClient'
     pluginName="Nexgen Advanced Ban Manager"
     pluginAuthor="Sp0ngeb0b"
     pluginVersion="2.01"
}