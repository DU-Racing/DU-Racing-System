# du-racing
This script allows any race track owner or event organiser set up and manage a race system that has many features to make managing races over any distance possible with multiple racers.

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

### Race Screens

#### Active Race Screen

#### Active Track Leaderboard