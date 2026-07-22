local config = {}
config.gameversion = "v1.0"
config.datastorekey = "PlayerData" -- If change this value will create a new data for the whole game
config.datastoreversion = "v1"
config.testmode = false
config.ownerid = 605235231
config.groupid = 35529401
config.ChatTags = require(script.RankData)

-- set to true on VoiceChatOnly places, so don't need to script everytime when update the lobby place
config.VoiceChatOnlyServer = false

config.devs = {
	["605235231"] = "AimbotJokers",
	["1436215361"] = "oigaleratudobemm",
}

return config