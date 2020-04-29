**Preview:**

![moderate](https://user-images.githubusercontent.com/12958319/78816944-b41b4300-79d2-11ea-85a7-c652bde76870.jpg)
![banControl](https://user-images.githubusercontent.com/12958319/78816941-b2ea1600-79d2-11ea-9af5-c354c4c8d123.jpg)

```
####################################################################################################
##
##  Nexgen Advanced Ban Manager
##  [NexgenABM201 - For Nexgen 112]
##
##  Version: 2.01
##  Release Date: April 2020
##  Author: Patrick "Sp0ngeb0b" Peltzer
##  Contact: spongebobut@yahoo.com  -  www.unrealriders.eu
##
####################################################################################################
##   Table of Content
##
##   1. About
##   2. Requirements
##   3. Server Install
##   4. Upgrading from a previous version
##   5. Credits and thanks
##   6. Info for programmers
##   7. FAQs
##   8. Changelog
##
####################################################################################################

####################################################################################################
## 
##  1. About
##
####################################################################################################
The main goal of the Nexgen Advanced Ban Manager is - as the name suggests - the improvement of the
existing ban system in Nexgen. It offers reliable functions to keep unwanted players out permanently,
as it makes use of the hardware Information detected by ACE. On top of that, NexgenABM also includes 
the ability to ban via the player's hostname. Both, IP and hostname bans offer support for Ban Masks, 
which allow range banning and precise specifications.

Nexgen's original Ban Control tab has been completely revised, creating the necessary space for
including access to all ban parameters. Besides that, a polished Ban Search panel has been added
to complement the interface.

Coming with NexgenABM is the use of the TCP implementation in Nexgen 1.12. Nexgen's original ban 
data was sent using UT's standard replication method, which can result in long client initialization 
with a full ban list. NexgenABM's banlist initializes the clients way faster.

The plugin also extends the administrative functions by a warning function, which will pop up a
window on the target client, forcing him to read the warning. Also, warnings, kicks and bans
will now either include the account name of the performing admin, or hide it if desired by him.

For your comfort, NexgenABM comes with an integrated setup program, which will automatically transfer
all existing ban entries from Nexgen's original ban system to the NexgenABM.ini file (and eventually
erase the old data in Nexgen.ini).

####################################################################################################
##
##  2. Requirements
##
####################################################################################################
Nexgen 1.12

Optional:
NexgenACEExt (any version, allows banning by HW id or MAC hash)
IpToCountry (allows banning by hostname)

Note: This plugin replaces NexgenWarn!

####################################################################################################
## 
##  3. Server Install
##
####################################################################################################
 1. Create a copy of your existing Nexgen.ini to backup your existing ban entries.

 2. Make sure your server has been shut down.
 
 3. Deinstall any existing version of NexgenWarn.

 4. Copy the NexgenABM201.u file to the system folder of your UT
    server.

 5. If your server is using redirect upload the NexgenABM201.u.uz file
    to the redirect server.

 6. Open your servers configuration file and add the following server package:

      ServerPackages=NexgenABM201

    Also add the following server actor:

      ServerActors=NexgenABM201.NexgenABMMain

    Note that the actor must be added AFTER the Nexgen controller server actor
    (ServerActors=Nexgen112.NexgenActor).
    
    Also note that if you want to use the Hostname banning feature, the plugin's ServerActor must be
    loaded AFTER the IpToCountry.LinkActor ServerActor!

 7. Restart your server. NexgenABM will now automatically transfer your existing ban list  and is 
    then ready to be used in-game.
    
####################################################################################################
##
##  4. Upgrading from a previous version
##
####################################################################################################
 1. Make sure your server has been shut down.

 2. Delete NexgenABMxxx.u (where xxx is the previous version of the
    Plugin) from your servers system folder and upload NexgenABM201.u
    to the same folder.

 3. If your server is using redirect you may wish to delete
    NexgenABMxxx.u.uz if it is no longer used by other servers.
    Also upload NexgenABM201.u.uz to the redirect server.

 4. Open NexgenABM.ini.

 5. Do a search and replace "NexgenABMxxx." with "NexgenABM201." (without the quotes).
    Again xxx denotes the previous version of NexgenABM that was installed on your server.

 6. Save the changes and close the file.

 7. Goto the [Engine.GameEngine] section and edit the server package and
    server actor lines for Nexgen. They should look like this:

      ServerActors=NexgenABM201.NexgenABMMain

      ServerPackages=NexgenABM201

 8. Save changes to the servers configuration file and close it.

 9. Restart your server.

####################################################################################################
## 
##  5. Credits and thanks
##
####################################################################################################
- Defrost for developing Nexgen (http://www.unrealadmin.org/forums/showthread.php?t=26835)
  
- AnthraX for his priceless work on ACE (http://utgl.unrealadmin.org/ace/)

- Thanks to Matthew "MSuLL" Sullivan for parts of his work from 'HostnameBan'.
  (http://www.unrealadmin.org/forums/showthread.php?t=16076)

- [es]Rush and MSuLL for creating IpToCountry.
  (http://www.unrealadmin.org/forums/showthread.php?t=29924)

- To my admin team from the 'ComboGib >GRAPPLE< Server <//UrS//>', for their intensive testing, bug-
  finding and feedback, and ofcourse for simply beeing the best team to have. Big thanks guys! :)
  
- aZ-Boy and Krisuh for bug reporting

####################################################################################################
##
##  6. Info for programmers
##
####################################################################################################
This mod is open source. You can view/and or use the source code of it partially or entirely without
my permission. You are also more then welcome to recompile this mod for another Nexgen version.
Nonetheless I would like you to follow these limitations:

- If you use parts of this code for your own projects, please give credits to me in your readme.
  (Patrick 'Sp0ngeb0b' Peltzer)
  
- If you recompile or edit this plugin, please leave the credits part of the readme intact, as well
  as the author line in the panel. Also note that you have to pay attention to the naming of your
  version to avoid missmatches. All official updates will be made ONLY by me and therefore counting up
  version numbers are forbidden (e.g. NexgenABM202). Instead, add an unique suffix 
  (e.g. NexgenABM202_X).
  
While working with Nexgen's 1.12 TCP functions, I encountered a far-reaching bug in Nexgen's core
file which will prevent empty strings in an array to be transfered correctly. A detailed explanation
and solution can be found here: http://www.unrealadmin.org/forums/showthread.php?t=31280

####################################################################################################
##
##  7. FAQs
##
####################################################################################################
Q: Does this plugin require ACE?
A: No, ACE info can optionally be provided by using NexgenACEExt. NexgenABM is independent of ACE
   and NexgenACEExt.
   
Q: Do I have to run IpToCountry?
A: No, IpToCountry is only optional. Note that you won't be able to perform Hostname bans if you
   don't run IpToCountry.
   
Q: Why are spectators not affected by HW id and MAC bans?
A: ACE must be configured to check spectators in order to generate hardware information for them. 
   Set 'bCheckSpectators' to 'true' in your ACE configuration.

Q: Banned players rejoin the game for a few seconds before beeing kicked again. Why is there a delay?
A: There could be 2 possible reasons for that:
   1) The player is only hardware banned, and ACE needs some time to detect the hardware Info.
   2) NexgenABM uses the original Nexgen setting whether to automatically update ban entries. If this
      feature is enabled, the plugin waits with kicking the player until all required info is received.
      Although the client may have already failed the first check (IP and ID bans), it will stay
      on the server until its Hostname and its ACE info is received. Eventually he will be kicked.

Q: How many ban entries are supported?
A: 256.

Q: I'm using a custom Nexgen version and there's no compatible version of this plugin available.
   Am I allowed to recompile this package on my own?
A: Generally, if you want a version of this plugin for a custom Nexgen version, ask me and I will
   do the job for you. If - for whatever reasons - you are unable to get in contact with me, you are
   allowed to recompile the plugin with respecting the conditions stated in section 6.

####################################################################################################
##
##  8. Changelog
##
####################################################################################################
- Version 2.01:
  [Fixed]   Ban method post checkLogin now correctly let Nexgen remove the client handlers   
  [Fixed]   Ban Control GUI not useable after deleting a ban entry
  [Changed] Hostname signaling and processing now delayed till client's initial login is completed

- Version 2.00:
  [Removed] ACE features since they are now included in NexgenACEExt
  [Added]   Account name of admin banning is now displayed in the popup and saved for the ban entry
  [Added]   Option for admins to not display their names when warning/kicking/banning   
    
- Version 1.02:
  [Fix]   RequestInfo and TakeScreenshot buttons mistakenly disabled for green, gold and teamless
          players
  [Fix]   Critical bug in use with Bots
  [Added] Feature to detect ACE bypass attempts and kick the respective player

- Hotfix  1.01:
  [Fix]   Sometimes players were erroneously considered as banned


Bug reports / feedback can be send directly to me.



Sp0ngeb0b, April 2020

admin@unrealriders.eu / spongebobut@yahoo.com
www.unrealriders.eu
```