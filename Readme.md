**Preview:**

![BanControl](https://user-images.githubusercontent.com/12958319/77366259-f2203200-6d57-11ea-8c0b-880c2af94485.jpg)
![ACEInfo](https://user-images.githubusercontent.com/12958319/77366255-f0566e80-6d57-11ea-9e48-4b68ded8facd.jpg)

```
####################################################################################################
##
##  Nexgen Advanced Ban Manager
##  [NexgenABM102 - For Nexgen 112 and ACE 0.8]
##
##  Version: 1.02
##  Release Date: September 2013
##  Author: Patrick "Sp0ngeb0b" Peltzer
##  Contact: spongebobut@yahoo.com  -  www.unrealriders.de
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
as it makes use of the unique and not-changeable hardware Information detected by ACE. On top of
that, NexgenABM also includes the ability to ban via the player's hostname. Both, IP and hostname
bans offer support for Ban Masks, which allow range banning and precise specifications.

Nexgen's original Ban Control tab has been completely revised, creating the necessary space for
including access to all ban parameters. Besides that, a polished Ban Search panel has been added
to complement the User friendly interface.

Coming with NexgenABM is the use of the TCP implementation in Nexgen 1.12, which kicks the Client -
Server communication of UT into a new dimension. It guarantees fast, smooth and reliable data
transfer with low impact on the server performance. Nexgen's original ban data was sent using UT's
replication netcode, which was slow, limited and uncomfortable. Client initialization often took
around 10 seconds with a full ban list. NexgenABM's banlist instead even allows the double amount of
ban entries (256) and initializes the clients in a few seconds. The TCP communication is also used
for another main feature of NexgenABM ...

... called the ACE Admin panel. As you might have already thought, it integrates important ACE
functions in Nexgen. It's similiar to The_Cowboy's ACEManager, as the panel provides the possibility
to easily request a ScreenShot of any player plus view the detailed ACE Infos of them.

Last but not least contains this plugin the complete functions of NexgenWarn
(http://www.unrealadmin.org/forums/showthread.php?t=30883), which can and must be dropped from the
server in return.

For your comfort, NexgenABM comes with an integrated setup program, which will automatically transfer
all existing ban entries from Nexgen's original ban system to the NexgenABM.ini file (and eventually
erase the old data in Nexgen.ini).

Version 1.02 introduces a new feature with regards to a possible ACE exploit, which allows possible
cheaters to prevent ACE from initializing them. NexgenABM now allows the admin to determine a
timelimit until each client's Hardware ID and MAC Hash must be available. If the client fails to
provide this info in the specified time, he will automatically be kicked. The settings can be
changed ingame in the Server -> Settings -> Plugins panel.



####################################################################################################
##
##  2. Requirements
##
####################################################################################################
Nexgen 1.12
ACE v 0.8 (any version using IACEv08c)
IpToCountry (optional, enables Hostname Banning)

Removal of NexgenWarn
  


####################################################################################################
## 
##  3. Server Install
##
####################################################################################################
 1. Create a copy of your existing Nexgen.ini (as I can not guarantee that no data will be lost
    during the transfer).

 2. Make sure your server has been shut down.
 
 3. Deinstall any existing version of NexgenWarn.

 4. Copy the NexgenABM102.u file to the system folder of your UT
    server.

 5. If your server is using redirect upload the NexgenABM102.u.uz file
    to the redirect server.

 6. Open your servers configuration file and add the following server package:

      ServerPackages=NexgenABM102

    Also add the following server actor:

      ServerActors=NexgenABM102.NexgenABMMain

    Note that the actor must be added AFTER the Nexgen controller server actor
    (ServerActors=Nexgen112.NexgenActor).
    
    Also note that if you want to use the Hostname banning feature, the plugin's ServerActor must be
    loaded AFTER the IpToCountry.LinkActor ServerActor!

 7. Restart your server. NexgenABM will now automatically transfer your existing BanList and is then
    ready to be used in-game.



####################################################################################################
##
##  4. Upgrading from a previous version
##
####################################################################################################
 1. Make sure your server has been shut down.

 2. Delete NexgenABM10x.u (where x is the previous version of the
    Plugin) from your servers system folder and upload NexgenABM102.u
    to the same folder.

 3. If your server is using redirect you may wish to delete
    NexgenABM10x.u.uz if it is no longer used by other servers.
    Also upload NexgenABM102.u.uz to the redirect server.

 4. Open NexgenABM.ini.

 5. Do a search and replace "NexgenABM10x." with "NexgenABM102." (without the quotes).
    Again the x denotes the previous version of NexgenABM that was installed on your server.

 6. Save the changes and close the file.

 7. Goto the [Engine.GameEngine] section and edit the server package and
    server actor lines for Nexgen. They should look like this:

      ServerActors=NexgenABM102.NexgenABMMain

      ServerPackages=NexgenABM102

 8. Save changes to the servers configuration file and close it.

 9. Restart your server.



####################################################################################################
## 
##  5. Credits and thanks
##
####################################################################################################
- Defrost for developing Nexgen and especially for his nearly forgotten work on the great TCP
  implementation in Nexgen 1.12. (http://www.unrealadmin.org/forums/showthread.php?t=26835)
  
- AnthraX for his priceless work on ACE (http://utgl.unrealadmin.org/ace/)

- Thanks to Matthew "MSuLL" Sullivan for parts of his work from 'HostnameBan'.
  (http://www.unrealadmin.org/forums/showthread.php?t=16076)

- [es]Rush and MSuLL for creating IpToCountry.
  (http://www.unrealadmin.org/forums/showthread.php?t=29924)

- The_Cowboy for ACE_Manager
  (http://www.unrealadmin.org/forums/showthread.php?t=30023)

- To my admin team from the 'ComboGib >GRAPPLE< Server <//UrS//>', for their intensive testing, bug-
  finding and feedback, and ofcourse for simply beeing the best team to have. Big thanks guys! :)
  
- aZ-Boy for bug reporting and his suggestion for the ACE bypass kick feature



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
  version numbers are forbidden (e.g. NexgenABM103). Instead, add an unique suffix (e.g. NexgenABM103_K).
  
While working with Nexgen's 1.12 TCP functions, I encountered a far-reaching bug in Nexgen's core
file which will prevent empty strings in an array to be transfered correctly. A detailed explanation
and solution can be found here: http://www.unrealadmin.org/forums/showthread.php?t=31280


####################################################################################################
##
##  7. FAQs
##
####################################################################################################
Q: Does this plugin require ACE absolutely?
A: Yes, as it makes heavy use of ACE's features.

Q: What ACE versions are supported?
A: By now, only ACE versions 0.8g and 0.8h are supported. In theory, every version using the IACEv08c
   package should work.
   
Q: Will there be a version for ACE 0.9?
A: If this version is ever gonna be released to the public, there will for sure be an update of this
   plugin. Until then, I can not compile this plugin for 0.9 since I don't have the specific IACE file.

Q: Do I have to run IpToCountry?
A: No, IpToCountry is only optional. Note that you won't be able to perform Hostname bans if you
   don't run IpToCountry.
   
Q: Why are spectators not affected by HardwareID and MAC bans?
A: Since all public ACE versions only perform checks on players, there is no way to detect Spectator's
   hardware info.
   
Q: Banned players rejoin the game for a few seconds before beeing kicked again. Why is there a delay?
A: There could be 2 possible reasons for that:
   1) The player is only hardware banned, and ACE needs some time to detect the hardware Info.
   2) NexgenABM uses the original Nexgen setting whether to automatically update ban entries. If this
      feature is enabled, the plugin waits with kicking the player until all required info is received.
      Although the client may have already failed the first check (IP and ID bans), it will stay
      on the server until its Hostname and its ACE info is received. Eventually he will be kicked.

Q: How many ban entries are supported?
A: 256.

Q: What admin permissions are required for accessing the ACE Admin tab?
A: Clients must have Moderator rights to access the panel.

Q: I'm using a custom Nexgen version and there's no compatible version of this plugin available.
   Am I allowed to recompile this package on my own?
A: Generally, if you want a version of this plugin for a custom Nexgen version, ask me and I will
   do the job for you. If - for whatever reasons - you are unable to get in contact with me, you are
   allowed to recompile the plugin with respecting the conditions stated in section 5.
   
Q: How does the ACE bypass detection work?
A: NexgenABM constantly checks whether each client's Hardware ID and MAC Hash is available. If it
   isn't after the specified timelimit, it will assume that the player is trying to bypass ACE and
   kick him.



####################################################################################################
##
##  8. Changelog
##
####################################################################################################
- Version 1.02:
  [Fix]   RequestInfo and TakeScreenshot buttons mistakenly disabled for green, gold and teamless
          players
  [Fix]   Critical bug in use with Bots
  [Added] Feature to detect ACE bypass attempts and kick the respective player

- Hotfix  1.01:
  [Fix]   Sometimes players were erroneously considered as banned


Bug reports / feedback can be send directly to me.



Sp0ngeb0b, September 2013

admin@unrealriders.de / spongebobut@yahoo.com
www.unrealriders.de
#unrealriders @ QuakeNet

```
