# du-racing
This script allows any race track owner or event organiser set up and manage a race system that has many features to make managing races over any distance possible with multiple racers.

## Instructions

* How do I set the DU-Racing System up?
* Very easy would be promised too much, but fairly easy might do (step-by-step):

* 1) Place a core (type doesn't matter) for your start/finish.
* 2) Place 1 programming board, 3 databanks, 1 emitter, 1 receiver, 1 screen (any size, M+ recommended) on the core.
* 3) Copy the "system" code.
* 4) Paste it onto the programming board, by rightclick > advanced > paste Lua configuration from clipboard.
* 5) Open the programming boards code by using "ctrl + L" or by rightclick > advanced > edit Lua script
* 6) Look on the named slots on the left and connect the elements listed (step 2) in the order, top to bottom.

* 7) Place 1 programming board, 1 databank, 1 emitter, 1 receiver on a ship that you want to use for racing.
* 8) Copy the "vehicle" code.
* 10) Paste it onto the programming board, by rightclick > advanced > paste Lua configuration from clipboard.
* 11) Open the programming boards code by using "ctrl + L" or by rightclick > advanced > edit Lua script. Here the slots named "light" are optional. They require lights placed on the vehicle and are recommended for when using multiple of the same ship in one race. Using the lights each race can set a color for his racer.

* How do I use the DU-Racing System?

* 1) Start on the vehicle. Go to the Lua parameters by rightclick > advanced > edit Lua parameters.
* 2) Activate "orgMode" by using the check-box on the right.
* 3) Start the programming board.
* 4) To record a track to later race on it, Press "alt+2" or type "addWaypoint" where you want to add a waypoint. The first one should be the startpoint, last one finish. Try not to overdo it here.
* 5) When done with the waypoints, type "saveTrack(your track name, lap count, waypoint radius)" in your Lua-chat. This will save the track on the local vehicle databank. Waypoint radius is the radius a racer needs to get within in order to clear the waypoint. Example: "saveTrack(MyTrack,5,40)"
* 5.1) OPTIONAL: Deactivate the vehicle programming board, edit lua parameters, deactivate org mode, activate testMode. Set your track name for the testTrack parameter. Start the programming board. You can now test the track. To do so, press "alt+1" or type "startRace" in Lua-chat to initiate the start sequence.
* 6) Activate the programming board on the start/finish.
* 7) Type "broadcastTrack(your track name)" in the Lua-chat in order to transfer the track data. This can also be done at a later point as the data is saved on the vehicle databank meanwhile.
* 8) Deactivate the vehicle programming board (give some secs after the previous step here for the DU emitters/receivers to catch up :wink: )
* 9) Type "setTrack(your track name)" in the Lua-chat to set your created track as active.
* 10) Type "setRaceEvent(your event name)" in the Lua-chat to set your active event. The event name is simply made up by you. It allows to have multiple races on the same track with different or same racers with different lap times taken each time.
* 11) Restart the start/finish programming board (you should see your event name and track name on the screen).
* 12) On the vehicle go to Lua parameters, deactivate orgMode or testMode if necessary. Set your event Name for the eventName Parameter at the very top.
* 13) Start vehicle board.
* 14) The vehicle should now automatically register to the race. When done so, the name without a given time shows up on the screen.
* 15) Register all racers you want to the race.
* 16) The one having the start/fninsh board active types "startRace" in his Lua-chat. This initiates the start sequence. (No need to stay close to the board after the sequence is started)
* 17) After everyone finished the race, the one having the start/fninsh board active in the beginning restarts it (unload issues DU^^). Now the times from the racers automatically register back to the before started race and you have a winner!
* 
## Features

* Organiser mode - Plot the waypoints while flying around the track, save them locally and test it, then broadcast it to the central system.
* Test mode - Set the test track key in the params and run the track without an official race being set.
* Race mode - Registers racer with central system and awaits signal to start. Records times on leaderboards.
* Central System - A central system that records all race data and stores tracks ready for races. Leaderboards for track and lap times.
* Waypoint race system - Waypoints are set automatically and checked off as you go through them.
* Multiple tracks - Save multiple tracks in your central system for easy switching on events.
* Multiple racers - Allows multiple racers to take part in the same race.
* Team and Color system on ships - Set your team name and color on the ships to automatically set the light colors on the ship and for leaderboards.
* Supports multiple laps - Races can consist of 1 or more laps.
* Text command system - Lua chat text command system to help with managing the data in the databanks and exporting data.
* Custom Race UI - Useful data overlays and UI elements for the race system, including toast notifications.
* Race key system - Official races use a race key that is shared with racers to register them in the race.
* Track sharing system - Allows the tracks on the central system to be broadcast to racers. 
* Multipart message broadcasts - Large datasets are broken down in to smaller chunks to be emitted properly.
* Broadcast message queue system - Ensures messages are not lost from overloading receivers and allows a larger volume of data and racers to be handled.

## Upcoming Features

* Ship classification - Automatically classify a ship for racing based on the components fitted.

## DU Racing Official Events
To take part in DU Racing official events, with prizes and leaderboards, you will need to purchase a pre-made ship or core with the system pre-loaded. This ensures no manipulation of the scripts can take place and keeps eveything equal. Contact us in game for more information or visit the main DU Racing track at ::pos{0,2,-14.6622,-12.0493,0.0004} (Alioth)

## Vehicle Configuration
Racers require the following components: Programming Board, Emitter, Receiver.

The board must be linked to the Core, Emitter, Receiver and optionally up to 3 lights that will have the color set based on the ship parameters.

## Vehicle Operation
When you have started the board, you can type 'help' in the Lua chat console to see a list of commands.

### Organiser Mode
Organiser mode allows you to plot out a new track. To enter Organiser mode, right click the programming board and enable the checkbox. There are a couple of other parameters which are useful here. The first is radius, which is the distance racers need to get within the waypoint to proceed to the next one, and lapSetting which is the number of laps for this track.

Once you have these set, activate the board and get in the vehicle then proceed to set waypoints where needed using ALT+2 or typing 'add waypoint' in the Lua chat.

When you completed the waypoints, type 'save track Your Track Name'. This will save the track information to the vehicle and allow you to run a test on it before completing. To run a test, check the next section.

When you are happy with the track, you can type 'broadcast track Your Track Name' in to the Lua console and it will send the data to the central system where it can then be used for races.

### Test Mode
Test mode allows tracks to be tested and races to be started by the racer themselves. No lap data is sent to the central system during these tests. First you will need to set the 'testTrackKey' parameter to match the name of the track you want to test. This would have been set previously in organiser mode, or broadcasted to your vehicle from the central system.

When this is set, activate the board and get in the vehicle. You can now start the test race by typing 'start' in the Lua console, or by pressing ALT+1.

### Race Mode
By default, the vehicle is in race mode. The parameter 'raceID' needs to be set to match the one provided by the race organiser.

When the board is activated it will attempt to register with the central race system. This will sign the racer up to the race and download the track that will be used. The vehicle should complete registration within 10 seconds of board activation, when this has happened it will show a message 'awaiting race start'.

Once the start signal has been sent, the countdown to start will begin on the racers HUD with lights, and then the race begins and each waypoint needs to be hit in order to proceed to the next. When all waypoints and laps are completed, the vehicle will then attempt to bradcast the race statistics back to the central system. The data will be broadcast on a loop until the central system confirms it received it.

## System Configuration
To set up the main system you will need a board, screen, emitter, receiver, and 3 databanks. 

## System Operation

### Creating a track
Tracks are created on the ships and then broadcasted to the main system. Once you have created a track on the vehicle, use the broadcast track command with the system board active and the track will be sent to the system and can be used in future races.

### Creating a race
A race must be created for racers to register. A race is a single event using a track that is saved. To create a race you need a track to use and a race key that you set which is unique to this race.

First you will need to set the track. eg "set track Alioth Loop". Then you will need to create a race with the following command: "set key My Race Key". This race key is used by the racers to register on this race, they set this on the vehicle as a parameter and when they activate the board they will register on the race and await the start command.

You can use the "list racers" command in Lua chat to list registered racers. When all racers are registered, the race is started by ALT+1 or typing "start race" in to Lua. This will broadcast the start command to the racers and the countdown will begin.

## Databanks LOD

XS core = 21m 
S  core = 43m 
M  core = 75m 
L  core = 150m

### Race Screens

#### Active Race Screen

#### Active Track Leaderboard
