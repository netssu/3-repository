local DailyRewards = {
	Rewards_1 = { -- Daily rewards
		[1] = {["Coins"] = 50},
		[2] = {["Titles"] = "Crazy"},
		[3] = {["Coins"] = 100},
		[4] = {["Perk"] = "Cursed Doll"},
		[5] = {["Coins"] = 200},
		[6] = {["Perk"] = "Baseball Bat"},
		[7] = {["Character"] = "Steve Harrington"}
	},
	
	Rewards_2 = { -- default daily rewards after first completion
		[1] = {["Coins"] = 50,},
		[2] = {["Coins"] = 100},
		[3] = {["Perk"] = "Bandage"},
		[4] = {["Coins"] = 100},
		[5] = {["Coins"] = 150},
		[6] = {["Perk"] = "Medkit"},
		[7] = {["Perk"] = "Night Vision Goggles"}
	},
	
	Coins = {
		Img = "rbxassetid://2746729928"
	},
	
	Character = {
		["Steve Harrington"] = "rbxassetid://100504082372335" -- character image icon
	}
}

return DailyRewards