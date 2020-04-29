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
class NexgenABMConfig extends NexgenPluginConfig;

// Ban List
var config string bannedName[256];                // Name of banned player.
var config string bannedIPs[256];                 // IP address(es) of the banned player.
var config string bannedIDs[256];                 // Client ID(s) of the banned player.
var config string bannedHWIDs[256];               // Hardware ID(s) of the banned player.
var config string bannedMACHashes[256];           // MAC Hash(es) of the banned player.
var config string bannedHostnames[256];           // Hostnames(s) of the banned player.
var config string banReason[256];                 // Reason why the player was banned.
var config string banPeriod[256];                 // Duration string of the ban entry.
var config string bannerName[256];                // Account name of the Admin

/***************************************************************************************************
 *
 *  $DESCRIPTION  Automatically installs the plugin.
 *  $ENSURE       lastInstalledVersion >= xControl.versionNum
 *
 **************************************************************************************************/
function install() {  
  lastInstalledVersion = xControl.versionNum;
  
  // Transfer old ban entries
  if(xControl.control.sConf.bannedName[0] != "" && bannedName[0] == "") copyOldBans();

  // Remove expired bans if desired.
  if (xControl.control.sConf.removeExpiredBans) {
    cleanExpiredBans();
  }

  // Update ban periods.
  updateBanPeriods();

  // Save updated config or create new one
  saveconfig();
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Removes all expired bans from the banlist.
 *  $RETURN       True if one or more bans were removed from the banlist.
 *
 **************************************************************************************************/
function bool cleanExpiredBans() {
  local int currBan;
  local bool bBanDeleted;

  // Check each ban entry.
  while (currBan < arrayCount(bannedName) && bannedName[currBan] != "") {
    if (NexgenABMMain(xControl).isExpiredBan(currBan)) {
      removeBan(currBan, false);
      bBanDeleted = true;
    } else {
      currBan++;
    }
  }

  // Return result.
  return bBanDeleted;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Removes the specified entry from the banlist.
 *  $PARAM        entryNum  Location in the banlist.
 *  $PARAM        bForced   Whether the action was performed by an admin.
 *  $REQUIRE      0 <= entryNum && entryNum <= arrayCount(bannedName) && bannedName[entryNum] != ""
 *  $ENSURE       new.bannedName[entryNum] != old.bannedName[entryNum]
 *
 **************************************************************************************************/
function removeBan(int entryNum, bool bForced) {
  local int index;

  for (index = entryNum; index < arrayCount(bannedName); index++) {
    // Last entry?
    if (index + 1 == arrayCount(bannedName)) {
      // Yes, clear fields.
      bannedName[index]       = "";
      bannedIPs[index]        = "";
      bannedIDs[index]        = "";
      bannedHWIDs[index]      = "";
      bannedMACHashes[index]  = "";
      bannedHostnames[index]  = "";
      banReason[index]        = "";
      banPeriod[index]        = "";
      bannerName[index]       = "";
    } else {
      // No, copy fields from next entry.
      bannedName[index]      = bannedName[index + 1];
      bannedIPs[index]       = bannedIPs[index + 1];
      bannedIDs[index]       = bannedIDs[index + 1];
      bannedHWIDs[index]     = bannedHWIDs[index + 1];
      bannedMACHashes[index] = bannedMACHashes[index + 1];
      bannedHostnames[index] = bannedHostnames[index + 1];
      banReason[index]       = banReason[index + 1];
      banPeriod[index]       = banPeriod[index + 1];
      bannerName[index]      = bannerName[index + 1];
    }
  }
  if(bForced) saveconfig();

}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Updates the ban period strings. Note this function should only be called once
 *                during the game, preferrably at the beginning of the game as it might cause a
 *                checksum mismatch for the dynamic config data.
 *
 **************************************************************************************************/
function updateBanPeriods() {
  local int currBan;
  local byte banPeriodType;
  local string banPeriodArgs;

  // Check each ban entry.
  while (currBan < arrayCount(bannedName) && bannedName[currBan] != "") {
    class'NexgenConfig'.static.getBanPeriodType(banPeriod[currBan], banPeriodType, banPeriodArgs);

    if (banPeriodType == xControl.control.sConf.BP_Matches) {
      banPeriod[currBan] = "M" $ max(0, int(banPeriodArgs) - 1);
    }

    currBan++;
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Transfers all original Nexgen ban entries into the AdvancedBanManager config file.
 *
 **************************************************************************************************/
function copyOldBans() {
  local int index;

  for(index=0;index<ArrayCount(xControl.control.sConf.bannedName); index++) {
    // Check whether we are done
    if(xControl.control.sConf.bannedName[index] == "") break;

    // Copy old ban entry
    bannedName[index] = xControl.control.sConf.bannedName[index];
    bannerName[index] = xControl.control.sConf.bannerName[index];
    bannedIPs[index] = xControl.control.sConf.bannedIPs[index];
    bannedIDs[index] = xControl.control.sConf.bannedIDs[index];
    banReason[index] = xControl.control.sConf.banReason[index];
    banPeriod[index] = xControl.control.sConf.banPeriod[index];

    // Delete entry
    xControl.control.sConf.bannedName[index] = "";
    xControl.control.sConf.bannerName[index] = "";
    xControl.control.sConf.bannedIPs[index] = "";
    xControl.control.sConf.bannedIDs[index] = "";
    xControl.control.sConf.banReason[index] = "";
    xControl.control.sConf.banPeriod[index] = "";
  }

  // Save Nexgen config
  xControl.control.sConf.saveConfig();

  // Log transfer
  xControl.control.nscLog(xControl.pluginName$": All old ban entries successfully transfered.");
}

defaultproperties
{
}

