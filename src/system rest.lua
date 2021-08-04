--TICK 'slowUpdate'
buildRaceStatScreen()

--TICK 'consumeMsgQueue'
MSG:consumeQueue()

--INPUT TEXT (*)
handleTextCommandInput(text)

--ACTION START 'option1'
handleTextCommandInput("startRace")
