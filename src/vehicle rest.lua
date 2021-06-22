--TICK 'consumeMsgQueue'
MSG:consumeQueue()
if myDebug then system.print('MSG consumer running: '..json.encode(MSG.queue)) end

--TICK 'raceStartCooldown'
raceStartCooldownIndicator = false
gState = 'midrace'
unit.stopTimer('raceStartCooldown')

--TICK 'count5'
countdownReady5()
currentWaypointIndex = 1
currentWaypoint = vec3(waypoints[1][1], waypoints[1][2], waypoints[1][3])
radius = waypoints[1][4]
updateWaypointMarker()

--TICK 'count4'
countdownReady4()

--TICK 'count3'
countdownReady3()

--TICK 'count2'
countdownReady2()

--TICK 'count1'
countdownReady1()

--TICK 'countSet'
countdownSet()

--TICK 'countGo'
startRace()

--FLUSH
checkWaypoint()
updateTime()

--ACTION START 'option2'
handleTextCommandInput("addWaypoint")

--ACTION START 'option1'
handleTextCommandInput("start")

--UPDATE
--updateTime()
if updateOverlayDesired then
	updateOverlay()
  updateOverlayDesired = false
end
if updateWaypointDesired then
  updateWaypointDesired = false
  updateWaypointMarker()
    
  if myDebug then system.print('Next waypoint: '..xyzPosition(currentWaypoint.x, currentWaypoint.y, currentWaypoint.z)) end
end
if consumerStartDesired then
  unit.setTimer('consumeMsgQueue', 1)
  consumerStartDesired = false
end

--INPUT TEXT (*)
handleTextCommandInput(text)
