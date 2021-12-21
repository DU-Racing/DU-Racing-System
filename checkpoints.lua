-- checkWaypoint()
-- if user is in range of waypoint, triggers nextWaypoint
function checkWaypoint() -- This is checked on flush to not miss a point when moving fast, might use a vec3 inbetween positions later to make it even more accurate for sphere.

  local function getPlaneIntersection()
    local moveVec = vec3(core.getConstructWorldPos()) - oldPos -- oldPos being the worldPos from the last iteration of flush
    local dotCheck = vector.dot(vec3(waypoints[currentWaypointIndex]['n']), moveVec) --n being the normal vec in the track data
    if math.abs(dotCheck) > epsilon -- being the global constant epsilon = 1e-6
      local factor = -vector.dot(planeNormal, oldPos - vec3(waypoints[currentWaypointIndex]['c'])) / dotCheck
      
      if factor >= 0 and <=1 then -- the intersection of line and plane is between or at oldPos and currentPos; c being the coordinate of the plane
        return oldPos + moveVec * factor -- our intersectionPoint
      end
      
      return nil --Intersection happens, but it's not inbetween or at the positions we are checking for.
    end
    return nil --Move is parallel to the plane, therefore can not cross it at any point
  end

  if raceStarted then
    if waypoints[currentWaypointIndex]['t'] == 'p' then --p = plane
      local intersection = getPlaneIntersection()
      if intersection == nil then --if we got a value we did cross a plane. In this case we did not
        return nil
      end

      --from here it's the same no matter we do circle or sphere checkpoint

      local distance = vector.dist(core.getConstructWorldPos(), waypoints[currentWaypointIndex]['c']) -- c being the coordinate, c in case of plane being the first point to be taken and represents the center

      while distance <= radius do -- Are we within the radius of our next waypoint?
        local sysTime = system.getTime()
        table.insert(sectionTimes, utils.round(sysTime - splitTime,.001))
        splitTime = sysTime -- reset split time
        nextWaypoint()
        if raceStarted then updateWaypointDesired = true end --cause race might have ended at just that waypoint
      end
    end
  end
end


-- plane checkpoints.

-- track data example: 
--  3 points needed to make up the plane, then we create a plane function

--creating the track data for planes
local function generatePlaneCheckpointData(point1,point2,point3)
  point1 = vec3(point1[1],point1[2],point1[3])
  point2 = vec3(point2[1],point2[2],point2[3])
  point3 = vec3(point3[1],point3[2],point3[3])

  local planeVec1 = point2 - point1
  local planeVec2 = point3 - point1
  local planeNormal = planeVec1:cross(planeVec2)

  return point1, planeNormal
end

