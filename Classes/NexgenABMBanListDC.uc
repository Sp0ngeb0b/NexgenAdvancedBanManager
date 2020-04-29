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
class NexgenABMBanListDC extends NexgenSharedDataContainer;

var NexgenABMConfig xConf;

var string bannedName[256];                // Name of banned player.
var string bannedIPs[256];                 // IP address(es) of the banned player.
var string bannedIDs[256];                 // Client ID(s) of the banned player.
var string bannedHWIDs[256];               // Hardware ID(s) of the banned player.
var string bannedMACHashes[256];           // MAC Hash(es) of the banned player.
var string bannedHostnames[256];           // Hostnames(s) of the banned player.
var string banReason[256];                 // Reason why the player was banned.
var string banPeriod[256];                 // Duration string of the ban entry.
var string bannerName[256];                // Account name of the Admin

/***************************************************************************************************
 *
 *  $DESCRIPTION  Loads the data that for this shared data container.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function loadData() {
  local int index;

  xConf = NexgenABMConfig(xControl.xConf);

  for (index = 0; index < arrayCount(bannedName); index++) {
    bannedName[index]      = xConf.bannedName[index];
    bannedIPs[index]       = xConf.bannedIPs[index];
    bannedIDs[index]       = xConf.bannedIDs[index];
    bannedHWIDs[index]     = xConf.bannedHWIDs[index];
    bannedMACHashes[index] = xConf.bannedMACHashes[index];
    bannedHostnames[index] = xConf.bannedHostnames[index];
    banReason[index]       = xConf.banReason[index];
    banPeriod[index]       = xConf.banPeriod[index];
    bannerName[index]      = xConf.bannerName[index];
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Sends the initial shared data setup commands to the specified client.
 *  $PARAM        xClient  The client controller which should be setup.
 *  $REQUIRE      xClient != none
 *
 **************************************************************************************************/
function reInitRemoteClient(NexgenExtendedClientController xClient) {
	local int varIndex;
	local int varCount;
	local string currentVar;
	local byte currentVarType;
	local string currentVarValue;
	local int varArrayIndex;
	local int varArrayCount;
	
	// Send variable initialization commands.
	varCount = getVarCount();
	for (varIndex = 0; varIndex < varCount; varIndex++) {
		// Retrieve variable information.
		currentVar = getVarName(varIndex);
		currentVarType = getVarType(currentVar);
		
		// Check if the variable is an array.
		if (isArray(currentVar)) {
			// Variable is array, send whole array contents.
			varArrayCount = getArraySize(currentVar);
			for (varArrayIndex = 0; varArrayIndex < varArrayCount; varArrayIndex++) {
				currentVarValue = getString(currentVar, varArrayIndex);
				if (!isTypeDefaultValue(currentVarType, currentVarValue)) {
					xClient.sendStr(xClient.CMD_SYNC_PREFIX @ xClient.CMD_INIT_VAR
					                @ class'NexgenUtil'.static.formatCmdArg(currentVar)
					                @ varArrayIndex
					                @ class'NexgenUtil'.static.formatCmdArg(currentVarValue));
				}
			}
		} else {
			// Variable contains a single value, send it.
			currentVarValue = getString(currentVar);
			if (!isTypeDefaultValue(currentVarType, currentVarValue)) {
				xClient.sendStr(xClient.CMD_SYNC_PREFIX @ xClient.CMD_INIT_VAR
				                @ class'NexgenUtil'.static.formatCmdArg(currentVar)
				                @ class'NexgenUtil'.static.formatCmdArg(currentVarValue));
			}
		}
	}
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Saves the data store in this shared data container.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function saveData() {
  xConf.saveConfig();
}

/***************************************************************************************************
 *
 *  $DESCRIPTION Overwrites original function so that only admins receive the initial info.
 *               (optimizes network performance)
 *
 **************************************************************************************************/
function initRemoteClient(NexgenExtendedClientController xClient) {
  if(!xClient.client.hasRight(xClient.client.R_BanOperator)) return;
  super.initRemoteClient(xClient);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Changes the value of the specified variable.
 *  $PARAM        varName  Name of the variable whose value is to be changed.
 *  $PARAM        value    New value for the variable.
 *  $PARAM        index    Array index in case the variable is an array.
 *  $REQUIRE      varName != "" && imply(isArray(varName), 0 <= index && index <= getArraySize(varName))
 *  $OVERRIDE
 *
 **************************************************************************************************/
function set(string varName, coerce string value, optional int index) {
  switch (varName) {
    case "bannedName":       bannedName[index]      = value; if (xConf != none) { xConf.bannedName[index]      = bannedName[index];      } break;
    case "bannedIPs":        bannedIPs[index]       = value; if (xConf != none) { xConf.bannedIPs[index]       = bannedIPs[index];       } break;
    case "bannedIDs":        bannedIDs[index]       = value; if (xConf != none) { xConf.bannedIDs[index]       = bannedIDs[index];       } break;
    case "bannedHWIDs":      bannedHWIDs[index]     = value; if (xConf != none) { xConf.bannedHWIDs[index]     = bannedHWIDs[index];     } break;
    case "bannedMACHashes":  bannedMACHashes[index] = value; if (xConf != none) { xConf.bannedMACHashes[index] = bannedMACHashes[index]; } break;
    case "bannedHostnames":  bannedHostnames[index] = value; if (xConf != none) { xConf.bannedHostnames[index] = bannedHostnames[index]; } break;
    case "banReason":        banReason[index]       = value; if (xConf != none) { xConf.banReason[index]       = banReason[index];       } break;
    case "banPeriod":        banPeriod[index]       = value; if (xConf != none) { xConf.banPeriod[index]       = banPeriod[index];       } break;
    case "bannerName":       bannerName[index]      = value; if (xConf != none) { xConf.bannerName[index]      = bannerName[index];      } break;
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Checks whether the specified client is allowed to read the variable value.
 *  $PARAM        xClient  The controller of the client that is to be checked.
 *  $PARAM        varName  Name of the variable whose access is to be checked.
 *  $REQUIRE      varName != ""
 *  $RETURN       True if the variable may be read by the specified client, false if not.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function bool mayRead(NexgenExtendedClientController xClient, string varName) {

  return xClient.client.hasRight(xClient.client.R_BanOperator);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Checks whether the specified client is allowed to change the variable value.
 *  $PARAM        xClient  The controller of the client that is to be checked.
 *  $PARAM        varName  Name of the variable whose access is to be checked.
 *  $REQUIRE      varName != ""
 *  $RETURN       True if the variable may be changed by the specified client, false if not.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function bool mayWrite(NexgenExtendedClientController xClient, string varName) {
  return xClient.client.hasRight(xClient.client.R_BanOperator);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Checks whether the specified client is allowed to save the data in this container.
 *  $PARAM        xClient  The controller of the client that is to be checked.
 *  $REQUIRE      xClient != none
 *  $RETURN       True if the data may be saved by the specified client, false if not.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function bool maySaveData(NexgenExtendedClientController xClient) {
  return xClient.client.hasRight(xClient.client.R_BanOperator);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Reads the string value of the specified variable.
 *  $PARAM        varName  Name of the variable whose value is to be retrieved.
 *  $PARAM        index    Index of the element in the array that is to be retrieved.
 *  $REQUIRE      varName != "" && imply(isArray(varName), 0 <= index && index <= getArraySize(varName))
 *  $RETURN       The string value of the specified variable.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function string getString(string varName, optional int index) {
  switch (varName) {
    case "bannedName":          return bannedName[index];
    case "bannedIPs":           return bannedIPs[index];
    case "bannedIDs":           return bannedIDs[index];
    case "bannedHWIDs":         return bannedHWIDs[index];
    case "bannedMACHashes":     return bannedMACHashes[index];
    case "bannedHostnames":     return bannedHostnames[index];
    case "banReason":           return banReason[index];
    case "banPeriod":           return banPeriod[index];
    case "bannerName":          return bannerName[index];
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Returns the number of variables that are stored in the container.
 *  $RETURN       The number of variables stored in the shared data container.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function int getVarCount() {
  return 9;
}



/***************************************************************************************************
 *
 *  $DESCRIPTION  Retrieves the variable name of the variable at the specified index.
 *  $PARAM        varIndex  Index of the variable whose name is to be retrieved.
 *  $REQUIRE      0 <= varIndex && varIndex <= getVarCount()
 *  $RETURN       The name of the specified variable.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function string getVarName(int varIndex) {
  switch (varIndex) {
    case 0:  return "bannedName";
    case 1:  return "bannedIPs";
    case 2:  return "bannedIDs";
    case 3:  return "bannedHWIDs";
    case 4:  return "bannedMACHashes";
    case 5:  return "bannedHostnames";
    case 6:  return "banReason";
    case 7:  return "banPeriod";
    case 8:  return "bannerName";
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Retrieves the data type of the specified variable.
 *  $PARAM        varName  Name of the variable whose data type is to be retrieved.
 *  $REQUIRE      varName != ""
 *  $RETURN       The data type of the specified variable.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function byte getVarType(string varName) {
  switch (varName) {
    case "bannedName":       return DT_STRING;
    case "bannedIPs":        return DT_STRING;
    case "bannedIDs":        return DT_STRING;
    case "bannedHWIDs":      return DT_STRING;
    case "bannedMACHashes":  return DT_STRING;
    case "bannedHostnames":  return DT_STRING;
    case "banReason":        return DT_STRING;
    case "banPeriod":        return DT_STRING;
    case "bannerName":       return DT_STRING;
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Retrieves the array length of the specified variable.
 *  $PARAM        varName  Name of the variable which is to be checked.
 *  $REQUIRE      varName != "" && isArray(varName)
 *  $RETURN       The size of the array.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function int getArraySize(string varName) {
  switch (varName) {
    case "bannedName":         return arrayCount(bannedName);
    case "bannedIPs":          return arrayCount(bannedIPs);
    case "bannedIDs":          return arrayCount(bannedIDs);
    case "bannedHWIDs":        return arrayCount(bannedHWIDs);
    case "bannedMACHashes":    return arrayCount(bannedMACHashes);
    case "bannedHostnames":    return arrayCount(bannedHostnames);
    case "banReason":          return arrayCount(banReason);
    case "banPeriod":          return arrayCount(banPeriod);
    case "bannerName":         return arrayCount(bannerName);
    default:                   return 0;
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Checks whether the specified variable is an array.
 *  $PARAM        varName  Name of the variable which is to be checked.
 *  $REQUIRE      varName != ""
 *  $RETURN       True if the variable is an array, false if not.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function bool isArray(string varName) {
  switch (varName) {
    case "bannedName":
    case "bannedIPs":
    case "bannedIDs":
    case "bannedHWIDs":
    case "bannedMACHashes":
    case "bannedHostnames":
    case "banReason":
    case "banPeriod":
    case "bannerName":
      return true;
    default:
      return false;
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Resets all variables.
 *
 **************************************************************************************************/
function clearData() {
  local int index;

  for (index = 0; index < arrayCount(bannedName); index++) {
    bannedName[index]      = "";
    bannedIPs[index]       = "";
    bannedIDs[index]       = "";
    bannedHWIDs[index]     = "";
    bannedMACHashes[index] = "";
    bannedHostnames[index] = "";
    banReason[index]       = "";
    banPeriod[index]       = "";
    bannerName[index]      = "";
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/
defaultproperties
{
     containerID="NexgenABM_banList"
}
