-- checkWaypoint()
-- if user is in range of waypoint, triggers nextWaypoint
function checkWaypoint() -- This is checked on flush to not miss a point when moving fast, might use a vec3 inbetween positions later to make it even more accurate
  if raceStarted then
    local distance = calcDistance(core.getConstructWorldPos(), waypoints[currentWaypointIndex])

    while distance <= radius do -- Are we within the radius of our next waypoint?
      local sysTime = system.getTime()
      table.insert(sectionTimes, utils.round(sysTime - splitTime,.001))
      splitTime = sysTime -- reset split time
      nextWaypoint()
      if raceStarted then updateWaypointDesired = true end --cause race might have ended at just that waypoint
      distance = calcDistance(core.getConstructWorldPos(), waypoints[currentWaypointIndex])
    end
    --[[if currentWaypoint and distance <= radius then -- Are we within the radius of our target destination?
      local sysTime = system.getTime()
      table.insert(sectionTimes, utils.round(sysTime - splitTime,.001))
      splitTime = sysTime -- reset split time
      nextWaypoint()
    end]]
  end
end
