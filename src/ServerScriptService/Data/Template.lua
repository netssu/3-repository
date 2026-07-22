return {
	-- plrs stats --
	Wins = 0,
	Coins = 0,
	Kills = 0,
	Deaths = 0,
	TimePlayed = 0,
	FreeRevives = 0,
	GroupReward = false,
	DailyReward = true, -- wheel daily reward
	DailyTime = 0,
	LastLogin = 0,
	CurrentDay = 1, -- menu daily reward
	ClaimedDailyReward = false,
	RewardType = 1,
	RewardTime = 0,
	FirstTime = true,
	
	-- events --
	Events = {
		Xmas_2025 = {}
	},
	
	-- plr owned items in-game --
	OwnedCharacters = {},
	AwardedBadges = {},
	OwnedItems = {},
	EquipedEmotes = {},
	AwardedCodes = {},
	OwnedPerks = {}, -- example: ["Item Name"] = 2 (amount)
	EquipedPerks = {}, --max equipped = 3
	
	EquipedCharacter = "Mike Wheeler", --"Larry",
	EquipedTitle = "Newbie",
	
	-- plr settings --
	PlrTitles = true,
	GameTips = true,
	ToggleCrouch = true,
	Contrast = 0.5,
	Brightness = 0.5,
	GlobalShadows = true,
	MasterVolume = 50,
	AmbientSounds = 50,
	
	-- speedrun --
	Speedruns = {} -- example = ["Mode Name"] = 124532.234 -- time spend in seconds to beat
}