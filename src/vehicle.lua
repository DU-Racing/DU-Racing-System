--DU RACING v1.0 created by rexsilex, NinjaFox and cAIRLs

utils = require('cpml/utils')

-- Params
raceEventName = "TestRex" --export: This should be set to match the raceEventName used on the central system (keep the "")

orgMode = false --export: If checked you can create new tracks and broadcast them to a central system

testRace = true --export: If checked this will allow you to test a track that is saved 
testTrackName = "TESTERA" --export: Active track name, only used for test races (keep the "")

teamName = "Your team name here" --export: The name of the team racing for
teamColorRed = 255 --export: Change the vehicle light color - red 0-255
teamColorGreen = 255 --export: Change the vehicle light color - green 0-255
teamColorBlue = 205 --export: Change the vehicle light color - blue 0-255

-- Globals
myDebug = true --true for getting debug Printouts
waypoints = {}
radius = 20 -- default radius used when none set on track
sectionTimes = {} -- stores the times for each section
savedWaypoints = {} -- stores the waypoints when an organiser is plotting a race
currentWaypointIndex = 0 -- keeps track of the current active waypoint index
currentWaypoint = nil -- vec3 of the current waypoint poisition, used for working out distance
startTime = 0 -- start time in ms
endTime = 0 -- end time ms
splitTime = 0 -- current splt time start
lapTime = 0 -- tracks lap time
lapTimes = {} -- tracks all lap times
remainingLaps = 1 -- updated when the waypoints for the track are loaded
totalLaps = 1
trackName = ''
raceStarted = false
messageParts = {} -- multipart messaging table
gTab = 'race' --race tracks new test config
gState = 'start' -- start, awaiting, ready, set, live, finished, error, organizer, test
gData = { mainMessage = 'Loading...', toast = 'Welcome to DU Racing' }
consumerStarted = false
bestTime = nil
updateWaypointDesired = false --Triggers updating waypoint in system update as waypoints can't be set from flush
masterId = unit.getMasterPlayerId()
updateOverlayDesired = false
consumerStartDesired = false
raceStartCooldownIndicator = false

duRacingLogo =
  '<svg style="width: 100%; height: 100%;" width="815.000000pt" height="493.000000pt" viewBox="0 0 815.000000 493.000000" preserveAspectRatio="xMidYMid meet"> <g transform="translate(0.000000,493.000000) scale(0.100000,-0.100000)" fill="rgba(255,255,255,1)" stroke="none"> <path d="M3190 4824 c0 -11 104 -156 114 -160 16 -5 298 -25 302 -21 3 2 -59 100 -90 144 -1 1 -60 9 -131 18 -72 8 -145 17 -162 19 -18 3 -33 2 -33 0z"/> <path d="M3890 4724 c0 -9 81 -124 88 -124 4 -1 63 -9 132 -20 69 -10 126 -17 128 -15 3 3 -66 115 -71 115 -1 0 -58 11 -127 25 -132 26 -150 28 -150 19z"/> <path d="M4516 4692 c41 -71 45 -73 169 -98 65 -13 119 -23 121 -21 1 1 -12 22 -30 47 -32 44 -34 45 -147 73 -63 15 -118 27 -122 27 -5 0 -1 -13 9 -28z"/> <path d="M1880 4619 c-186 -13 -320 -26 -326 -31 -3 -3 36 -63 85 -134 50 -71 87 -131 83 -135 -4 -3 -34 -11 -67 -18 -33 -7 -138 -31 -234 -53 -109 -25 -177 -36 -183 -30 -5 5 -55 74 -112 153 l-102 144 -44 -3 c-56 -4 -543 -101 -552 -110 -3 -4 52 -88 123 -186 71 -99 126 -183 122 -186 -4 -4 -60 -27 -123 -50 -137 -51 -481 -197 -493 -209 -6 -6 301 -442 359 -510 2 -2 76 44 166 102 192 123 394 240 407 235 5 -1 71 -88 147 -193 75 -104 152 -210 170 -235 l33 -46 -107 -92 c-59 -50 -168 -153 -244 -229 l-136 -138 255 -348 255 -347 65 112 c63 111 250 396 295 451 l23 28 221 -308 c122 -169 227 -317 234 -329 11 -17 5 -39 -43 -165 -60 -154 -143 -417 -172 -539 l-18 -75 348 -475 c191 -261 355 -483 365 -493 16 -17 17 -9 23 160 7 208 30 485 56 666 l17 128 -278 386 c-153 213 -278 390 -278 396 0 29 247 508 269 521 4 3 104 -132 222 -299 118 -167 217 -304 221 -305 4 0 11 12 14 28 13 49 91 254 138 363 l47 106 -175 251 c-97 138 -176 255 -176 260 0 5 61 71 135 146 83 84 133 142 128 149 -3 7 -60 90 -126 185 -112 163 -118 174 -101 187 11 8 79 42 151 77 73 35 133 66 133 70 0 4 -40 67 -90 139 -49 72 -90 134 -90 138 0 4 42 17 93 29 162 36 219 45 225 36 59 -83 152 -225 152 -231 0 -4 -61 -30 -136 -58 -74 -27 -137 -52 -140 -56 -2 -4 41 -73 96 -154 56 -80 103 -151 105 -158 2 -7 -51 -52 -117 -102 -67 -49 -126 -97 -131 -106 -8 -12 21 -61 133 -222 79 -114 146 -207 149 -207 3 1 24 26 46 57 22 31 71 91 108 134 l68 79 -121 178 -121 177 25 20 c14 11 72 47 130 79 l104 59 -91 134 c-74 107 -89 136 -77 143 8 5 69 23 136 41 l123 32 -71 106 c-39 58 -72 107 -73 109 -1 1 -64 -7 -139 -18 -75 -11 -143 -20 -151 -20 -8 0 -48 50 -90 110 l-77 111 -61 -7 c-123 -13 -269 -32 -273 -37 -3 -2 34 -60 80 -128 47 -68 82 -125 78 -126 -4 -1 -74 -23 -157 -49 -82 -26 -157 -48 -166 -51 -19 -5 -216 274 -203 287 9 8 275 60 309 60 52 1 48 15 -30 129 -42 61 -75 112 -73 112 2 1 83 4 180 8 l178 6 -60 90 c-57 85 -62 90 -102 97 -54 8 -338 10 -338 2 0 -3 29 -48 65 -99 36 -52 65 -96 65 -98 0 -2 -39 -7 -87 -11 -111 -8 -297 -28 -301 -32 -3 -2 136 -207 170 -250 6 -8 -19 -18 -84 -34 -51 -13 -143 -38 -205 -55 l-112 -32 -106 151 -106 151 28 7 c41 10 356 58 382 58 17 0 22 4 17 16 -6 17 -156 235 -159 233 -1 -1 -58 -6 -127 -10z m-516 -584 c64 -91 119 -171 122 -178 3 -8 -17 -22 -53 -37 -32 -13 -145 -65 -250 -116 l-193 -92 -128 176 c-70 97 -138 192 -151 209 l-22 33 28 11 c15 6 122 40 238 75 116 36 221 69 235 74 14 5 32 9 41 9 9 1 63 -66 133 -164z m708 -198 l117 -166 -97 -52 c-53 -28 -143 -79 -200 -112 -88 -51 -106 -58 -117 -46 -7 8 -72 97 -144 199 l-131 185 42 19 c73 33 392 145 403 142 6 -1 63 -77 127 -169z m607 -177 c61 -88 111 -162 111 -164 0 -2 -21 -16 -47 -32 -27 -15 -100 -62 -164 -105 l-116 -77 -132 188 c-72 103 -131 190 -131 194 0 3 10 11 23 17 39 21 321 139 334 139 6 0 61 -72 122 -160z m-736 -442 c87 -123 158 -227 158 -231 0 -5 -52 -65 -115 -135 -63 -70 -143 -162 -177 -205 -59 -75 -63 -77 -79 -60 -30 32 -380 523 -380 533 0 18 404 318 430 320 4 0 77 -100 163 -222z m677 -164 c102 -145 148 -219 142 -227 -5 -7 -34 -43 -64 -82 -31 -38 -90 -121 -132 -182 l-76 -113 -185 261 c-102 143 -185 264 -185 269 0 17 320 290 340 290 5 0 77 -97 160 -216z"/> <path d="M5127 4599 c28 -47 41 -55 138 -78 50 -12 98 -24 108 -27 16 -5 14 0 -8 34 -16 24 -37 42 -53 46 -15 3 -66 17 -115 30 l-87 25 17 -30z"/> <path d="M4180 4546 c0 -14 71 -117 83 -121 19 -7 231 -33 236 -29 2 2 -12 28 -31 57 l-36 54 -103 17 c-57 10 -114 20 -126 23 -13 3 -23 2 -23 -1z"/> <path d="M3010 4504 c0 -11 124 -186 135 -190 7 -3 80 -1 163 3 l152 8 -62 93 -61 92 -163 0 c-90 0 -164 -3 -164 -6z"/> <path d="M3706 4463 c9 -16 33 -51 51 -79 l34 -51 136 -6 c76 -4 138 -5 140 -4 1 2 -18 33 -42 70 -28 40 -54 69 -68 72 -29 6 -209 25 -243 25 l-26 0 18 -27z"/> <path d="M4670 4474 c0 -3 12 -23 27 -47 15 -23 28 -43 28 -45 3 -4 219 -41 223 -38 2 3 -8 22 -23 44 -19 28 -36 42 -58 46 -18 4 -69 15 -114 25 -46 10 -83 17 -83 15z"/> <path d="M5079 4293 c24 -45 39 -53 134 -73 55 -12 101 -20 103 -18 2 3 -9 18 -24 35 -22 25 -44 35 -114 52 -107 26 -111 26 -99 4z"/> <path d="M3547 4170 c36 -56 72 -99 78 -96 7 2 59 7 116 11 166 10 158 1 92 100 l-56 85 -149 0 -148 0 67 -100z"/> <path d="M4514 4244 c65 -99 56 -92 121 -99 33 -3 84 -9 114 -12 l54 -6 -23 39 c-40 67 -44 69 -142 83 -51 7 -104 15 -118 18 l-24 6 18 -29z"/> <path d="M5390 4256 c0 -21 37 -57 69 -66 20 -5 66 -18 104 -29 l67 -20 -16 28 c-13 21 -34 32 -102 53 -48 15 -95 30 -104 33 -10 4 -18 4 -18 1z"/> <path d="M6030 4232 c0 -6 6 -14 13 -19 15 -10 157 -52 177 -53 35 -1 -18 29 -89 50 -40 12 -80 24 -87 27 -8 3 -14 0 -14 -5z"/> <path d="M3995 4204 c10 -16 32 -50 49 -75 l30 -46 125 -6 c69 -3 126 -5 128 -3 1 1 -17 32 -42 68 -49 73 -37 69 -225 84 l-84 7 19 -29z"/> <path d="M5733 4177 c9 -14 43 -31 103 -49 106 -33 115 -34 89 -9 -11 10 -62 32 -113 49 -91 30 -93 31 -79 9z"/> <path d="M4990 4175 c0 -11 50 -85 58 -85 7 0 113 -16 170 -26 l33 -5 -27 40 c-15 23 -28 41 -29 41 -2 0 -47 9 -100 20 -109 22 -105 22 -105 15z"/> <path d="M6460 4128 c8 -8 50 -27 93 -42 43 -15 85 -30 94 -33 10 -4 14 -2 10 4 -6 10 -124 59 -187 78 -22 6 -23 5 -10 -7z"/> <path d="M5519 4083 c5 -11 16 -24 23 -30 16 -12 181 -54 187 -47 13 13 -42 45 -109 64 -41 12 -83 24 -93 27 -16 4 -17 2 -8 -14z"/> <path d="M5975 4028 c11 -17 38 -28 105 -44 88 -20 105 -19 76 6 -11 9 -176 60 -194 60 -2 0 4 -10 13 -22z"/> <path d="M4935 4009 c5 -8 21 -33 36 -55 l28 -42 98 -4 c54 -3 100 -4 101 -2 2 1 -10 23 -27 47 -33 48 -31 47 -180 63 -53 6 -63 5 -56 -7z"/> <path d="M4540 4003 c0 -2 21 -35 46 -73 l47 -70 115 0 114 0 -18 28 c-68 106 -63 100 -117 106 -69 7 -187 13 -187 9z"/> <path d="M5236 3951 c11 -18 24 -36 29 -41 11 -9 184 -34 191 -28 1 2 -6 18 -17 35 -17 27 -28 33 -87 42 -37 7 -82 14 -101 18 l-34 6 19 -32z"/> <path d="M3910 3878 c-58 -11 -107 -22 -109 -24 -2 -2 131 -203 155 -233 3 -3 220 66 236 76 4 2 -23 49 -60 103 -77 114 -63 109 -222 78z"/> <path d="M6257 3874 c3 -8 24 -19 47 -25 22 -6 63 -17 90 -25 27 -8 51 -12 54 -10 7 7 -30 23 -115 49 -61 19 -80 21 -76 11z"/> <path d="M5220 3861 c0 -2 12 -23 28 -47 l27 -44 93 0 c50 0 92 2 92 5 0 19 -48 75 -65 76 -11 0 -55 4 -97 7 -43 4 -78 6 -78 3z"/> <path d="M5730 3862 c0 -26 42 -50 102 -56 34 -4 74 -10 87 -13 23 -6 23 -5 7 19 -14 21 -32 28 -99 42 -95 19 -97 19 -97 8z"/> <path d="M4154 3845 c4 -11 96 -154 112 -173 5 -6 229 21 237 28 5 5 -14 42 -42 84 l-52 76 -130 0 c-112 0 -130 -2 -125 -15z"/> <path d="M5990 3821 c0 -5 6 -13 13 -18 15 -12 169 -45 176 -38 11 11 -18 24 -96 44 -93 24 -93 24 -93 12z"/> <path d="M4840 3804 c0 -4 57 -92 84 -130 3 -4 188 15 192 19 8 8 -55 101 -74 109 -20 8 -202 10 -202 2z"/> <path d="M5621 3758 c21 -33 28 -36 113 -51 50 -9 92 -14 94 -12 2 2 -4 14 -12 27 -13 19 -33 28 -94 41 -42 10 -88 20 -101 24 l-23 6 23 -35z"/> <path d="M6750 3777 c16 -16 168 -62 177 -53 3 2 -35 17 -83 32 -49 14 -93 29 -99 32 -5 2 -3 -2 5 -11z"/> <path d="M6020 3703 c1 -27 30 -41 105 -50 44 -6 82 -9 84 -7 13 11 -29 34 -77 44 -31 6 -69 13 -84 16 -16 3 -28 2 -28 -3z"/> <path d="M6240 3656 c8 -7 42 -19 75 -25 33 -6 71 -14 85 -18 19 -4 22 -3 14 6 -11 12 -144 50 -174 51 -12 0 -12 -2 0 -14z"/> <path d="M4587 3641 l-57 -6 51 -80 c28 -44 54 -84 59 -88 9 -10 220 24 220 35 0 5 -21 40 -46 78 l-47 70 -61 -2 c-34 -1 -87 -4 -119 -7z"/> <path d="M5770 3636 c0 -4 7 -18 16 -31 15 -23 22 -25 95 -25 44 0 79 4 79 8 0 28 -30 41 -107 47 -46 4 -83 4 -83 1z"/> <path d="M6040 3622 c0 -20 27 -30 105 -37 71 -7 78 -6 67 7 -7 9 -35 19 -64 22 -28 4 -64 10 -79 13 -17 3 -29 1 -29 -5z"/> <path d="M5419 3576 l31 -44 82 5 c46 3 84 6 85 7 1 1 -9 19 -23 39 l-25 37 -90 0 -90 0 30 -44z"/> <path d="M5170 3574 c0 -17 84 -125 94 -121 7 3 44 8 82 12 38 4 72 9 76 12 4 2 -7 26 -25 53 l-32 50 -97 0 c-54 0 -98 -2 -98 -6z"/> <path d="M6846 3515 c3 -6 33 -17 67 -23 34 -7 73 -15 87 -18 60 -13 -10 16 -82 34 -54 14 -75 16 -72 7z"/> <path d="M3855 3461 c-60 -27 -111 -54 -113 -59 -2 -7 146 -236 194 -300 1 -2 42 25 91 60 49 34 99 70 111 78 l22 15 -85 128 c-47 70 -91 127 -98 127 -6 0 -61 -22 -122 -49z"/> <path d="M5896 3429 c20 -34 21 -34 105 -39 46 -3 85 -5 87 -4 8 5 -20 44 -36 53 -9 5 -53 12 -96 16 l-79 8 19 -34z"/> <path d="M4560 3374 c-30 -9 -72 -20 -92 -25 l-38 -10 76 -113 75 -113 102 43 c56 24 101 48 99 54 -1 6 -28 49 -59 95 -63 95 -63 95 -163 69z"/> <path d="M5245 3348 c-38 -5 -72 -11 -73 -13 -3 -2 80 -133 103 -163 4 -4 179 40 187 47 4 4 -13 37 -37 74 -51 75 -45 73 -180 55z"/> <path d="M6103 2155 c-136 -42 -218 -137 -250 -289 -35 -169 21 -292 153 -332 93 -28 261 -11 339 35 26 15 32 27 47 92 26 118 31 109 -71 109 l-89 0 -21 -62 c-12 -34 -31 -72 -43 -85 -27 -29 -73 -31 -88 -4 -15 29 -12 137 6 231 30 159 79 250 134 250 35 0 40 -13 40 -106 l0 -75 88 3 87 3 18 90 c21 106 22 103 -81 135 -75 23 -204 26 -269 5z"/> <path d="M7635 2156 c-106 -34 -178 -95 -222 -192 -83 -182 -27 -394 115 -434 81 -22 154 -8 208 42 22 19 22 19 32 -11 11 -30 13 -31 70 -31 l59 0 27 133 c14 72 26 138 26 145 0 9 -32 12 -124 12 -69 0 -127 -3 -129 -7 -2 -5 -7 -20 -11 -35 -6 -27 -5 -28 34 -28 46 0 49 -9 25 -68 -24 -55 -53 -82 -91 -82 -49 0 -58 25 -51 134 4 50 16 128 27 174 33 136 73 196 127 190 l28 -3 3 -88 3 -88 82 3 81 3 19 94 c21 108 25 101 -72 131 -73 23 -203 26 -266 6z"/> <path d="M3376 2143 c-9 -32 -126 -589 -126 -602 0 -10 44 -12 198 -9 182 3 201 5 250 27 75 34 144 113 173 198 31 92 32 228 2 294 -41 91 -93 109 -319 109 -156 0 -173 -2 -178 -17z m304 -77 c12 -32 -5 -181 -31 -284 -21 -82 -59 -156 -89 -172 -22 -12 -80 -14 -80 -2 0 4 20 102 45 217 25 116 48 222 51 238 5 25 10 27 50 27 38 0 46 -4 54 -24z"/> <path d="M4005 2148 c-18 -54 -87 -416 -88 -465 -2 -73 17 -107 79 -138 32 -16 59 -20 149 -20 100 0 115 2 168 28 63 31 99 71 121 135 12 32 106 450 106 468 0 2 -20 4 -44 4 -34 0 -46 -4 -50 -17 -2 -10 -24 -110 -47 -223 -55 -268 -77 -309 -170 -310 -52 0 -89 32 -89 76 0 20 20 129 45 243 25 114 45 213 45 219 0 17 -219 17 -225 0z"/> <path d="M4721 1863 c-34 -164 -65 -306 -67 -315 -5 -16 5 -18 104 -18 l109 0 22 103 c11 56 24 117 27 135 4 17 10 32 14 32 4 0 27 -61 50 -135 l44 -136 144 3 143 3 33 75 33 75 90 3 c102 3 103 3 103 -85 0 -74 -1 -73 126 -73 102 0 114 2 113 18 0 9 -14 150 -32 312 l-32 295 -121 3 -120 3 -135 -291 c-74 -159 -136 -290 -139 -290 -3 0 -26 55 -51 123 l-46 122 34 17 c19 10 42 23 51 30 27 23 52 91 52 145 0 44 -5 58 -30 86 -42 49 -83 57 -282 57 l-174 0 -63 -297z m347 215 c15 -15 15 -70 1 -122 -15 -54 -50 -86 -94 -86 -19 0 -35 2 -35 4 0 6 41 189 45 204 5 15 67 16 83 0z m477 -199 l10 -119 -72 0 -71 0 56 125 c31 68 58 122 62 119 3 -3 10 -59 15 -125z"/> <path d="M6555 2148 c-2 -7 -33 -148 -68 -313 l-63 -300 104 -3 c58 -1 106 -1 109 1 4 5 133 601 133 617 0 16 -209 13 -215 -2z"/> <path d="M6855 2148 c-2 -7 -30 -132 -60 -278 -31 -146 -60 -282 -65 -303 l-8 -38 46 3 47 3 45 212 c25 116 47 214 50 216 3 3 25 -76 48 -176 24 -100 48 -199 53 -219 l10 -38 118 0 118 0 62 293 c35 160 65 302 68 315 5 20 2 22 -40 22 -35 0 -47 -4 -51 -17 -2 -10 -24 -109 -47 -221 -24 -111 -46 -199 -50 -195 -5 7 -99 410 -99 428 0 3 -54 5 -120 5 -88 0 -122 -3 -125 -12z"/> </g> </svg>'

-- Functions
function handleTextCommandInput(text)
  local commands = {
    help = function()
      system.print('-==:: DU Racing Command Help ::==-')
      system.print('"start" or {ALT+1} - When in test mode starts the test race with the set track.')
      system.print('"addWaypoint" or {ALT+2} - When in organizer mode, adds the current core position to the track waypoints.')
      system.print('"saveTrack(track name, lap count, waypoint radius)" - When in organizer mode, saves the created waypoints with the given track name, lap count and waypoint radius to the local databank.')
      system.print('"broadcastTrack(track name)" - When in organizer mode, broadcasts the prior saved track to a central system.')
      system.print('"listTracks" - Lists all track keys saved in the local, connected databank.')
    end,
    addWaypoint = function()
      if orgMode then
        saveWaypoint()
      else
        errorPrint('Waypoints can only be saved in organizer mode.')
      end
    end,
    start = function()
      if testRace then
        startCountdown()
      else
        errorPrint('You can only start a race from a vehicle if you are in test mode.')
      end
    end,
    listTracks = function()
      local keys = db.getKeys()
      if keys ~= '[]' then
        keys = json.decode(keys)
        local out = ''
        for key, value in pairs(keys) do
        if value ~= 'activeRace' then
          out = value .. ', ' .. out
        end
        end
        system.print(out)
      else
        system.print('No tracks saved on this Databank.')
      end
    end,
    saveTrack = function(trackNameLapCountWaypointRadius)
      local trackName, lapCount, waypointRadius
      local paramSeperation = string.find(trackNameLapCountWaypointRadius,',')
      if paramSeperation then
        trackName = string.sub(trackNameLapCountWaypointRadius,1,paramSeperation - 1)
        local LapCountWaypointRadius = string.sub(trackNameLapCountWaypointRadius,paramSeperation + 1,#trackNameLapCountWaypointRadius)
        paramSeperation = string.find(LapCountWaypointRadius,',')
        if paramSeperation then
          lapCount = tonumber(string.sub(LapCountWaypointRadius,1,paramSeperation - 1))
          lapCount = type(lapCount) == 'number' and math.ceil(lapCount) or false
          waypointRadius = tonumber(string.sub(LapCountWaypointRadius,paramSeperation + 1,#LapCountWaypointRadius))
          waypointRadius = type(waypointRadius) == 'number' and waypointRadius or false
        end
      end
      
      local err = ''
      if not savedWaypoints[1] then err = 'No waypoints created that could be saved for a track. ' end
      if not trackName or trackName=='' then err = err..'A track can not be saved without a name. ' end
      if not lapCount or not (lapCount > 0) then err = err..'Lap Count must be an integer greater zero. ' end
      if not waypointRadius or not (waypointRadius > 0) then err = err..'Waypoint radius must be a number greater zero.' end
      if err ~= '' then
        errorPrint(err)
      else
        -- Exports current saved waypoints to JSON
        local track = {name = trackName, radius = waypointRadius, laps = lapCount, waypoints = savedWaypoints}
        db.setStringValue(trackName, json.encode(track))
        system.print([[The track has been saved to the local databank. 
        Change to test mode to try it out. 
        Type "broadcastTrack(trackName)" to save the track to a closeby, active central system.]])
      end
    end,
    exportTrack = function(trackName)
      if trackName ~= '' then
        local track = db.getStringValue(trackName)
        local err = ''
        if not track then err = 'No track found with this track name. ' end
        if not screen then err = err..'No screen connected for exporting.' end
        if err ~= '' then
          errorPrint(err)
        else
          screen.setHTML(track)
          system.print('Track has been exported to the screen HTML.')
        end
      else
        errorPrint('The track name must be given to export a track.')
      end
    end,
    broadcastTrack = function(trackName)
      if trackName ~= '' then
        local track = db.getStringValue(trackName)
        if not track then
          errorPrint('No track with this name is saved on the databank. If you just recorded the track, save it using "saveTrack(track name, lap count, waypoint radius)" first.')
        else
          MSG:send('fdu-centralsplit', track) --saves track
          system.print('Track "'..trackName..'" has been broadcasted to the central system.')
        end
      else
        errorPrint('A track name must be used to broadcast a track.')
      end
    end
  }

  if myDebug then myPrint('Entered Command: "'..text..'"', false) end
  
  local paramStart = string.find(text,'%(')
  local cmd = paramStart and string.sub(text,1,paramStart-1) or text
  local paramsString = ''
  
  if paramStart then
    local paramEnd = string.find(text,'%)')
    paramEnd = paramEnd or #text+1--we assume someone just forgot the closing ) and try to process anyway
    paramsString = string.sub(text,paramStart+1,paramEnd-1)
  end
  if commands[cmd] then
    commands[cmd](paramsString)
  else
    errorPrint('Following command could not be executed: "'..text..'"')
  end
end

-- Message part system functions
function getKeysSortedByValue(tbl, sortFunction)
  local keys = {}
  for key in pairs(tbl) do
    table.insert(keys, key)
  end

  table.sort(
    keys,
    function(a, b)
      return sortFunction(tbl[a], tbl[b])
    end
  )

  return keys
end

-- calcDistance(worldPos v1, worldPos v2)
-- Returns the distance in metres between 2 vectors
function calcDistance(v1, v2)
  return (vec3(v2) - vec3(v1)):len()
end

-- xyzPosition(float x, float y, float z)
-- Returns a waypoint string from the given coordinates
function xyzPosition(x, y, z)
  -- using 0 for body works with world coordinates
  return '::pos{0,0,'..x..','..y..','..z..'}'
end

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

-- nextWaypoint
-- returns null increments the active index in use of waypoint, sets the vec3 waypoint for user
function nextWaypoint()
  local now = system.getTime()
  -- Queries the databank and set the next waypoint
  if raceStartCooldownIndicator == false then
    gState = 'midrace'
    myPrint('Waypoint complete.', true)
  end --Preventing instant "Waypoint complete" Message to override start sequence
  currentWaypointIndex = currentWaypointIndex + 1
  nextPoint = waypoints[currentWaypointIndex]
  
  if not nextPoint then -- no more waypoints?
    table.insert(lapTimes, utils.round(now - lapTime,.001))
    if(prevEnd==nil) then
      prevEnd = startTime
    end
    local thisLapTime = now - prevEnd 
    prevEnd=now
    updateBestTime(thisLapTime)
    -- check laps
    remainingLaps = remainingLaps - 1
    myPrint('Lap complete.', true)
    
    if remainingLaps == 0 then
      endTime = now
      --updateTime()
      endRace()
    else

    -- reset lap start
    lapTime = now
    -- reset the waypoints for next lap
    currentWaypointIndex = 1
    nextPoint = waypoints[1]
    end
  end
  if raceStarted then currentWaypoint = vec3(nextPoint[1], nextPoint[2], nextPoint[3]) end
  updateOverlayDesired = true
end

function modulus(a, b)
  return a - math.floor(a / b) * b
end

function updateWaypointMarker()
  system.setWaypoint('::pos{0,0,'..currentWaypoint.x..','..currentWaypoint.y..','..currentWaypoint.z..'}')
end

-- Start Race
function startRace()
  unit.stopTimer('countGo')
  if not raceStarted or testRace then
    gData.mainMessage = ''
    gState = 'green'
    myPrint('! GO !', true)
    raceStarted = true
    raceStartCooldownIndicator = true
    unit.setTimer('raceStartCooldown',2)
    --[[ set first waypoint moved to start of countdown
    currentWaypointIndex = 1
    currentWaypoint = vec3(waypoints[1][1], waypoints[1][2], waypoints[1][3])
    system.setWaypoint(xyzPosition(currentWaypoint.x, currentWaypoint.y, currentWaypoint.z))]]

    -- set start time and first split time
    startTime = system.getTime()
    prevEnd = nil
    lapTime, splitTime = startTime, startTime
  end
end

--TODO Counts down from 5 to go. Needs to be able to communicate with tower
-- Suggest refactor on this to use 1 function that decrements a value
function startCountdown()
	if not raceStarted or testRace then
    unit.setTimer('count5', 1)
    unit.setTimer('count4', 2)
		unit.setTimer('count3', 3)
		unit.setTimer('count2', 4)
		unit.setTimer('count1', 5)
		unit.setTimer('countSet', 6)
		unit.setTimer('countGo', 7)
		gData.mainMessage = ''
		gState = 'red5'
	end
end
function countdownReady5()
  unit.stopTimer('count5')
  gState = 'red5'
  myPrint('Ready', true)
end
function countdownReady4()
  unit.stopTimer('count4')
  gState = 'red4'
  myPrint('5', true)
end
function countdownReady3()
  unit.stopTimer('count3')
  gState = 'red3'
  myPrint('4', true)
end
function countdownReady2()
  unit.stopTimer('count2')
  gState = 'red2'
  myPrint('3', true)
end
function countdownReady1()
  unit.stopTimer('count1')
  gState = 'red1'
  myPrint('2', true)
end
function countdownSet() 
  gState = 'red'
  unit.stopTimer('countSet')
  myPrint('1', true)
end

function updateBestTime(time)
  debugPrint('bestTime'..formatTime(bestTime))
  debugPrint('newTime'..formatTime(time))
  if bestTime == nil or bestTime ==0 or time < bestTime then --store personal track record
    debugPrint('Best time logic')
    db.setStringValue(trackName..'-bestTime-'..masterId, json.encode(time))
    debugPrint('ref'..tostring(deltaTimeRef))
    bestTime = time   
    myPrint('New personal track record! '..formatTime(time), true)
  end
end
-- End Race
function endRace()
  --system.setWaypoint(nil)
  --TODO where do we set final waypoint? Might be a box stop area / parking area?

  gData.mainMessage = 'Final time ' .. formatTime(endTime - startTime)

  local finishTime = endTime-startTime
  myPrint('Finished race', true)
  myPrint('Section times: ' .. json.encode(sectionTimes), false)
  myPrint('Lap times: ' .. json.encode(lapTimes), false)
  myPrint('Final time: ' .. formatTime(finishTime), false)
  raceStarted = false
  
  if testRace == false then
    sendFinalTimes() -- Emit this data
  end
end

MSG = {
  queue = {},
  lastSendChannel = '',
  lastReceived = {channel='',msg=''},
  
  queueMessage = function(self, channel, message)
    table.insert(MSG.queue, {channel = channel, message = message}) --, time = system.getTime()})
    if myDebug then system.print('Vehicle added to queue: '..json.encode(MSG.queue)) end
    if consumerStarted == false then
      consumerStarted = true
      MSG:consumeQueue() --we can send the first msg instantly.
      consumerStartDesired = true
      if myDebug then system.print('Vehicle consumer started.') end
    end
  end,
  
  consumeQueue = function()
    MSG.lastSendChannel = MSG.queue[1]['channel']
    debugPrint('Broadcasting message'..MSG.queue[1]['message'])
    emitter.broadcast(MSG.queue[1]['channel']..'@'..MSG.queue[1]['message'])
    emitter.broadcast(MSG.queue[1]['message'])
  end,
  
  -- unqueueMessage = function(key)
    -- table.remove(MSG.queue, key)
    -- local count = 0
    -- for _ in pairs(MSG.queue) do count = count + 1 end
    -- if count == 0 then 
      -- unit.stopTimer('consumeMsgQueue')
      -- consumerStarted = false
    -- end
  -- end,
  
  unqueueMessage = function()
    local queueCount = GNR:countTableEntries(MSG.queue)
    if queueCount == 0 then
      unit.stopTimer('consumeMsgQueue')
      consumerStarted = false
      if myDebug then system.print('Vehicle queue stopped. No more entries.') end
    else
      if myDebug then system.print('Vehicle unqueued: '..json.encode(MSG.queue[1])) end
      table.remove(MSG.queue, 1)
      if myDebug then system.print('Vehicle remaining queue: '..json.encode(MSG.queue)) end
      if GNR:countTableEntries(MSG.queue) == 0 then
        unit.stopTimer('consumeMsgQueue')
        consumerStarted = false
        if myDebug then system.print('Vehicle queue stopped. No more entries after removal.') end
      end
    end
  end,

	send = function(self, channel, data) --data needs to be string

    local function split(str, maxLength)
      local splitParts = {}
      local strLength = str:len()

      local splitCount = math.ceil(strLength / maxLength)
      local remainingSplitsCount = splitCount
      local startPos = 1
      local endPos = maxLength
      while remainingSplitsCount > 0 do
        table.insert(splitParts, string.sub(str, startPos, endPos))
        startPos = endPos + 1
        endPos = endPos + maxLength > strLength and strLength or endPos + maxLength
        remainingSplitsCount = remainingSplitsCount - 1
      end
      return splitParts, splitCount
    end

    local index = 1
    local dataParts, dataPartsCount = split(data, 250)
    for lineId, dataContent in ipairs(dataParts) do
      local sendContent = customEncode({i = index, msgPartsCount = dataPartsCount, content = dataContent})
      MSG:queueMessage(channel, sendContent)
      index = index + 1
    end
	end,
  
  confirmReceive = function(self,channel)
    debugPrint('Vehicle-received broadcast sending...')
    MSG:queueMessage(channel,'DUR-vehicle-received')
  end
}

GNR = {
  countTableEntries = function(self,t)
    local count = 0
    for _ in pairs(t) do
      count = count + 1
    end
    return count
  end
}

function getCompleteMessage()
  local assembeledMessage = ''
  for key in ipairs(messageParts) do
    assembeledMessage = assembeledMessage .. messageParts[key]['content']
  end
  return assembeledMessage
end

function intFormat0(n)
  return string.format('%.f', n)
end
-- Emitter/Receiver functions

-- Clear DB
function clearDB()
  db.clear() -- Clears the databank of all entries
end

-- Set Track Waypoints
function setTrackWaypoints(trackKey, trackJson)
  -- Sets the JSON as waypoints for the location
  db.setStringValue(trackKey, trackJson)
end
-- character table string
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- encoding
function enc(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

-- decoding
function dec(data)
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

function customEncode(data)
  local encodedData = enc(json.encode(data))
  debugPrint('Base64: '..tostring(encodedData))
  return encodedData
end
-- Emit final times
function sendFinalTimes()
  -- JSON encode the logged times and emit them to the stadium
  local times = {
    finalTime = utils.round(endTime - startTime,.001),
    lapTimes = lapTimes,
    raceEventName = raceEventName,
    racer = masterId
  }
  
  local timeData = customEncode(times)
  
  MSG:queueMessage(raceEventName..'-finish',timeData)
end

-- Race Organiser Functions

-- Save waypoint
function saveWaypoint()
  -- Saves the current position as a waypoint
  table.insert(savedWaypoints, core.getConstructWorldPos())

  -- Output to lua console for debug
	local pos = core.getConstructWorldPos()
  local curr = xyzPosition(pos[1], pos[2], pos[3])
  system.print(curr)
end

-- save broadcasted track
function saveBroadcastedTrack(str)
  local track = json.decode(dec(str))
  if track == nil or type(track) ~= 'table' then
    errorPrint('Received track data is not valid. Restart board to retry.')
  else
    db.setStringValue(track['name'], str)
    loadTrack(track['name'])
    myPrint('Track: "'..track['name']..'" has been loaded.')
    registerConfirm()
  end
end

-- load track
function loadTrack(name)
  if db.hasKey(name..'-bestTime-'..masterId) then
        
    bestTime = json.decode(db.getStringValue(name..'-bestTime-'..masterId))
    debugPrint('Current best time'..tostring(bestTime))
  else
    bestTime = nil --needs to stay in case we start a new race without restarting the pb
    debugPrint('No best time')
  end
  if db.hasKey(name) then
    local track = db.getStringValue(name)
    if track ~= nil and track ~= '' then
      -- Sets the number of laps for this track
      track = json.decode(track)
      remainingLaps = track['laps']
      totalLaps = remainingLaps
      waypoints = track['waypoints']
      if track['radius'] ~= nil then
        radius = track['radius']
      end

      
      if not waypoints then
        errorPrint('Could not load track. No track waypoints found.')
        return false
      end
      trackName = name
    end
    errorPrint('Track could not be loaded. Track data is empty.')
  else
    errorPrint('Track could not be loaded. No track with the given name saved.')
  end
end

function toggleTestMode()
  testRace = ~testRace
  if testRace then
    enterTestMode()
  else
    exitTestMode()
  end
end

--UI stuff
function updateOverlay()
  local html = '<div class="mainWrapper">'
  html = html .. '<div class="mainMessage">' .. gData.mainMessage .. '</div>'
  if gData.toast ~= '' then
    html = html .. '<div class="toast">' .. gData.toast .. '</div>'
  end
  doLights = false
  local startLight1,startLight2,startLight3,startLight4,startLight5='','','','',''
  if gState == 'red5' then
    doLights = true
  end
  if gState == 'red4' then
    doLights = true
    startLight1='activeRed'
  end
  if gState == 'red3' then
    doLights = true
    startLight1='activeRed'
    startLight2='activeRed'
  end
  if gState == 'red2' then
    startLight1='activeRed'
    startLight2='activeRed'
    startLight3='activeRed'
    doLights = true
  end
  if gState == 'red1' then
    startLight1='activeRed'
    startLight2='activeRed'
    startLight3='activeRed'
    startLight4='activeRed'
    doLights = true
  end
  if gState == 'red' then
    startLight1='activeRed'
    startLight2='activeRed'
    startLight3='activeRed'
    startLight4='activeRed'
    startLight5='activeRed'
    doLights = true
  end
  if gState == 'green' then
    startLight1='activeGreen'
    startLight2='activeGreen'
    startLight3='activeGreen'
    startLight4='activeGreen'
    startLight5='activeGreen'
    doLights = true
  end
  if doLights then
    html = html..
      [[<div id="traffic" class="fadeaway">
        <svg viewBox="0 0 845 200">
          <g stroke="#000" stroke-opacity="0.65" fill="#333" fill-opacity="0.65">
            <path d="M 0 0 L 1 200 L 845 200 L 845 1" fill-opacity="0.65"/>
            <path fill="#444" d="M 20 20 L 20 180 L 825 180 L 825 20" fill-opacity="0.35"/>
            <circle cx="100" cy="100" r="75" id="rl" class="]]..startLight1..[["></circle>
            <circle cx="260" cy="100" r="75" id="r2" class="]]..startLight2..[["></circle>
            <circle cx="420" cy="100" r="75" id="r3" class="]]..startLight3..[["></circle>
            <circle cx="580" cy="100" r="75" id="yl" class="]]..startLight4..[["></circle>
            <circle cx="740" cy="100" r="75" id="gl" class="]]..startLight5..[["></circle>
          </g>
        </svg>
      </div>]]
  end
	local waypointText, lapsText
  if gState == 'start' or gState == 'awaiting' then
		waypointText, lapsText = '---','---'
  else
		waypointText = currentWaypointIndex - 1 < 0 and 0 or currentWaypointIndex - 1 > #waypoints and #waypoints or currentWaypointIndex - 1
    waypointText = waypointText .. '/' .. #waypoints
    lapsText = totalLaps - remainingLaps + 1
    lapsText = lapsText > totalLaps and totalLaps or lapsText
		lapsText = lapsText .. '/' .. totalLaps
	end
  html = html..
    [[<div class="mainArea">
      <div class="logo">]]
        ..duRacingLogo..
      [[</div>
      <div class="info">
        <span class="label">Track Name: </span>
        <span class="value">]]..trackName..[[</span>
      </div>
      <div class="info">
        <span class="label">Team Name: </span>
        <span class="value">]]..teamName..[[&nbsp;&nbsp;
          <span style="margin-left: 10px;display: inline-block; width: 10px; height: 10px; background: rgb(]]..teamColorRed..', '..teamColorGreen..', '..teamColorBlue..[[);"></span>
        </span>
      </div>
      <div class="info">
        <span class="label">Laps: </span>
        <span class="value">]]..lapsText..[[</span> 
      </div>
      <div class="info">
        <span class="label">Waypoints: </span>
        <span class="value">]]..waypointText..[[</span> 
      </div>
    </div>]]

  system.setScreen(styles .. html)
end

function clearOverlay()
  system.destroyWidgetPanel(raceInfoPanel)
end

function initOverlay()
  --section: Race Status
  raceInfoPanel = system.createWidgetPanel('DU Racing Clock')
  lapTimeRef = addStaticWidget(raceInfoPanel, '0:00:00.000', 'Lap Time', '')
  totalTimeRef = addStaticWidget(raceInfoPanel, '0:00:00.000', 'Total Time', '')
  deltaTimeRef = addStaticWidget(raceInfoPanel, '--:--:--.---', 'Best Lap', '')

  --set up styles
  styles =
    [[

  <style type="text/css">
  .mainWrapper, .glowText{
  	color: #a1ecfb;
    margin: 0 0 20px;
    transition: color 250ms ease-out;
    text-transform: uppercase;
  }
  .mainMessage{
    font-size: 7vh;
    position: absolute; 
    top: 15vh;
    left: 0;
    text-align: center;
    width: 100vw;
  }
  .activeRed{
    fill: red;
  }
  .activeYellow{
    fill: yellow;
  }
  .activeGreen{
    fill: green;
  }
  .toast{
    -webkit-animation: cssAnimation 0s ease-in 5s forwards;
    background-color: rgba(2,17,20,0.65);
    border: 1px solid rgb(2, 157, 187);
    font-size: 2vh;
    font-weight: 700;
    color: #a1ecfb;
    display: block;
    padding: 20px;
    animation-fill-mode: forwards;
    position: relative; 
    top: 80vh;
    left: 30vw;
    text-align: center;
    width: 40vw;
  }
  .fadeaway{
    -webkit-animation: cssAnimation 0s ease-in 2s forwards;
    animation-fill-mode: forwards;
  }
  .mainArea {
    position: absolute; 
    left: 2vw; 
    top: 5vh;
    width: 30vw;
    height: 17vh;
    padding: 1vh 1vw;
  }
  .mainArea .logo {
    display: block;
    width: 17vw; 
    height: 17vh;
    background-color: rgba(2,17,20,0.65);
    padding: 2vh 2vw;
  }
  .mainArea .info {
    position: relative;
    display: block;
    padding: 1em 5em 1em 1em;
    overflow: hidden;
    margin: 10px 0;
    width: 17vw;
    border-top: 0;
    border-left: 1px solid rgb(2, 157, 187);
  }
  .mainArea .info:before {
    content : "";
    position: absolute;
    left  : 0;
    bottom  : 0;
    height  : 1px;
    width   : 15vw;
    border-bottom: 1px solid rgb(2, 157, 187);
  }
  .mainArea .info:after {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background-color: rgba(2,17,20,0.65);
    border: 1px solid rgb(2, 157, 187);
    transform-origin: 100% 0;
    transform: skew(-45deg);
    z-index: -1;
  }
  .mainArea .label {
    display: inline-block;
    width: 6vw;
  }
  .mainArea .value {
    display: inline-block;
    color: #ffffff;
  }
  .ad, .map{
    width: 100%;
  }
  @-webkit-keyframes cssAnimation {
    to {width: 0; height: 0; visibility: hidden;}
  }
  #traffic{
    left:24.75vw; top:5vw; width:50vw; height:10vw;
    position: absolute;
  }
  circle{
    transition: all 0.5s cubic-bezier(.89,.27,.78,.59);
  }
  </style>  
  ]]

  --updateOverlayDesired = true
  system.showScreen(1)
end

function toast(message)
  gData.toast = message
  updateOverlayDesired = true
end

function addProgressWidget(parentPanel, value)
  local tempWidget = system.createWidget(parentPanel, 'gauge')
  local tempData = system.createData('{"percentage": ' .. value .. '}')
  system.addDataToWidget(tempData, tempWidget)
  return tempData
end

function addStaticWidget(parentPanel, value, label, unit)
  local tempWidget = system.createWidget(parentPanel, 'value')
  local tempData =
  system.createData('{"value": "' .. value .. '","label":"' .. label .. '", "unit": "' .. unit .. '"}')
  system.addDataToWidget(tempData, tempWidget)
  return tempData
end

function updateTime()
  if raceStarted then
    local now = system.getTime()
    system.updateData(totalTimeRef, '{"value": "' .. formatTime(now - startTime) .. '"}')
    system.updateData(lapTimeRef, '{"value": "' .. formatTime(now - lapTime) .. '"}')
    system.updateData(deltaTimeRef, '{"value": "' .. formatTime(bestTime) .. '"}')
  end
end

function formatTime(seconds)
  
  if(seconds == nil)then
    return '--:--:--.---'
  end 
  local function leadingZero(num)
    num = tonumber(num)
		return num < 10 and '0'..num or num
	end

  function postZeros(num)
    if(string.len(num)<5)then 
      return num..'00'
    end
    if(string.len(num)<6) then 
      return num..'0'
    end 
    return num
  end
  local secondsRemaining = seconds
  local hours = math.floor(secondsRemaining / 3600)
  secondsRemaining = modulus(secondsRemaining, 3600)
  local minutes = math.floor(secondsRemaining / 60)
  local seconds = modulus(secondsRemaining, 60)  
  return leadingZero(hours) .. ':' .. leadingZero(minutes) .. ':' .. postZeros(leadingZero(utils.round(seconds,.001)))
end

-- Activate screen and UI
initOverlay()
if screen then
  screen.activate()
end

function setDefaults()
  -- Lights (if set)
  if light1 then 
    light1.setRGBColor(teamColorRed, teamColorGreen, teamColorBlue)
  end
  if light2 then 
     light2.setRGBColor(teamColorRed, teamColorGreen, teamColorBlue)
  end
  if light3 then 
     light3.setRGBColor(teamColorRed, teamColorGreen, teamColorBlue)
  end
end

function onStart()
  unit.hide()
  setDefaults()
  if orgMode then
    trackName = 'TBC'
    newRaceInfoPanel = system.createWidgetPanel('New Race')
    gState = 'organiser'
    myPrint('-==:: DU Racing Organiser Mode ::==-', false)
    myPrint([[To create a new track type "addWaypoint" in the lua console or press "ALT+2" to save the current location as a new waypoint.
    The first waypoint should be at the start area, last at the finish line.
    Type "saveTrack(track name, lap count, waypoint radius)" to save the track local and optional "broadcastTrack(track name)" afterwards to add it to the central system.]]
    ,false)
    gData.mainMessage = ''
    toast('Entering Organizer Mode')
  elseif testRace then
    enterTestMode()
  else
    -- emit racer online if we have a race ID
    if raceEventName ~= "" then
      local startData = {raceEventName = raceEventName, racer = masterId}
      startData = customEncode(startData)
      MSG:queueMessage(raceEventName ..'-register', startData)
    end
    gState = 'awaiting'
    gData.mainMessage = 'REGISTERING'
    toast('Registering with mainframe')
  end
end

function registerConfirm()
  gState = 'ready'
  gData.mainMessage = ''
  toast('Awaiting race start')
end

function enterTestMode()
  myPrint('-==:: DU Racing Test Mode ::==-')
  -- Check they have an active track
  if testTrackName == '' then
    errorPrint('No test track has been set. Do so in the exported Lua parameters.')
    return false
  end

  loadTrack(testTrackName)

  myPrint('Type "start" in lua console or hit {ALT+1} to start the test race.')
  gData.mainMessage = 'Press ALT+1 to begin.'
  toast('Test mode activated.')
end

function exitTestMode()
  myPrint('Exiting Test Mode.', true)
end
function setState(newState, newData, clear)
  gState = newState
  if clear then
    gData = newData
  else
    --todo, only overwrite new data
  end
end

function errorPrint(msg)
  myPrint('ERROR: ' .. msg, true)
  gState = 'error'
end

function debugPrint(msg)
  if(myDebug) then
    system.print(msg)
  end
end

--Helper function to wrap system.print().  If second argument is true, it will also call a toast with the same message.
function myPrint(msg, doToast)
  return system.print(msg), doToast and toast(msg)
end

onStart()


