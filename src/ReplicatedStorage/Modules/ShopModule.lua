--[[
	Pass Instance:
	{
		ID = 0 -- Game Pass ID,
		Enabled = true -- If the pass are avaible on game.
	}
	
	Codes Instance:
	["code name"] = {
		Reward = {["type"] = amount}, -- Reward by using the code
		Enabled = true -- if the code is enabled to use,
	}
	
	Item (Emote) Instance:
	{
		Name = "Item Name",
		Price = 0, -- Item price (coins)
		Enable = true, -- If the item are avaible on game.
		Img = 0, -- Image icon of the emote.
		AnimId = 0, -- Animation Id of the emote.
	}
	
	Item (Player Title) Instance:
	{
		Name = "Title Name",
		Price = 0, -- Item price (coins) | If price = 0, is a default item, player automatically redeem it.
		Enabled = true, -- If item are avaible on game.
		TextStyle = [TextLabel Object] -- Text style.
	}
]]

local products = {}
local plrTitles = script:FindFirstChild("PlrTitles")

products.Passes = {
	{ -- [Early Supporter] Pass
		ID = 1049187899,
		Name = "Early Supporter",
		Enabled = false,
	},
	{ -- [+20% Extra Speed] Pass
		ID = 1273579740,
		Name = "Extra Speed",
		Enabled = true
	},
	{ -- [+20% Extra Strength] Pass
		ID = 1328376906,
		Name = "Extra Strength",
		Enabled = true
	},
	{ -- [2x Money] Pass
		ID = 1328215468,
		Name = "2x Money",
		Enabled = true
	},
	{ -- [Spawn With Bat] Pass
		ID = 1404050518,
		Name = "Spawn With Bat",
		Enabled = true
	},
	{ -- [Night Vision] Pass
		ID = 1404158414,
		Name = "Night Vision",
		Enabled = true
	},
	{ -- [Cursed Doll] Pass
		ID = 1386987804,
		Name = "Cursed Doll",
		Enabled = true
	},
	{ -- [Medkit] Pass
		ID = 1403530238,
		Name = "Medkit",
		Enabled = true
	},
	
	--//[Characters Gamepasses]//--
	{ -- [Rampart] Pass
		ID = 1551626708,
		Name = "Rampart",
		Enabled = true
	}
}

products.Products = {
	{ -- [+50 Coins] Product
		ID = 3339340976,
		Name = "Coins_50",
		Reward = {["Coins"] = 50},
		Enabled = true
	},
	{ -- [+200 Coins] Product
		ID = 3339342734,
		Name = "Coins_200",
		Reward = {["Coins"] = 200},
		Enabled = true
	},
	{ -- [+500 Coins] Product
		ID = 3339344922,
		Name = "Coins_500",
		Reward = {["Coins"] = 500},
		Enabled = true
	},
	{ -- [+1200 Coins] Product
		ID= 3339345599,
		Name = "Coins_1200",
		Reward = {["Coins"] = 1200},
		Enabled = true
	},
	{ -- [+1600 Coins] Product
		ID = 3339346244,
		Name = "Coins_1600",
		Reward = {["Coins"] = 1600},
		Enabled = true
	},
	{ -- [+2000 Coins] Product
		ID = 3339347848,
		Name = "Coins_2000",
		Reward = {["Coins"] = 2000},
		Enabled = true,
	},
	{ -- [+5200 Coins] Product
		ID = 3339348774,
		Name = "Coins_5200",
		Reward = {["Coins"] = 5200},
		Enabled = true
	},
	{
		ID = 2815366790,
		Name = "Revive",
		Enabled = true
	}
}

products.Codes = {
	["FIXEDBUGS!"] = {
		Reward = {["Coins"] = 100},
		Enabled = true
	},
	["TYSM800LIKES"] = {
		Reward = {["Coins"] = 200},
		Enabled = true
	},
	["250LIKES!!"] = {
		Reward = {["Coins"] = 150},
		Enabled = true
	},
	["1kVisits"] = {
		Reward = {["Coins"] = 10},
		Enabled = true
	},
	["5kVisits"] = {
		Reward = {["Coins"] = 20},
		Enabled = true
	},
	["10kVisits"] = {
		Reward = {["Coins"] = 50},
		Enabled = true
	},
	["50kVisits"] = {
		Reward = {["Coins"] = 50},
		Enabled = true
	},
	["100kVisits"] = {
		Reward = {["Coins"] = 100},
		Enabled = true
	},
	["Alpha"] = {
		Reward = {["Coins"] = 30},
		Enabled = true
	},
	["th_secret09"] = {
		Reward = {["Coins"] = 50},
		Enabled = true
	},
	["AsylumOutbreak"] = {
		Reward = {["Coins"] = 10},
		Enabled = true
	},
	["HALLOWEEN"] = {
		Reward = {["Coins"] = 66},
		Enabled = true
	},
	["500kVisits"] = {
		Reward = {["Coins"] = 200},
		Enabled = true
	}
}

products.Items = {
	Emotes = {
		{ -- [Pointing Emote]
			Name = "Pointing",
			Price = 0, -- Default Emote
			Enabled = true,
			Img = 10005631373, -- Emote icon id
			AnimId = 71323323109270 -- Id of the emote animation
		},
		{ -- [Calling Emote]
			Name = "Calling",
			Price = 35,
			Enabled = true,
			Img = 10004979656,
			AnimId = 107503808652128
		},
		{ -- [Negative Emote]
			Name = "Negative",
			Price = 70,
			Enabled = true,
			Img = 10005559805,
			AnimId = 135463264139015,
		}
	},
	Titles = {
		{ -- [Newbie Title]
			Name = "Newbie",
			Price = 0, -- Default title
			Enabled = true,
			TextStyle = plrTitles:FindFirstChild("Newbie_Title")
		},
		{ -- [Survivor Title]
			Name = "Survivor",
			Price = 20,
			Enabled = true,
			TextStyle = plrTitles:FindFirstChild("Survivor_Title")
		},
		{ -- [Scaredy Cat]
			Name = "Scaredy Cat",
			Price = 25,
			Enabled = true,
			TextStyle = plrTitles:FindFirstChild("ScaredyCat_Title")
		},
		{ -- [The Doctor]
			Name = "The Doctor",
			Price = 30,
			Enabled = true,
			TextStyle = plrTitles:FindFirstChild("TheDoctor_Title")
		},
		{ -- [Brave]
			Name = "Brave",
			Price = 45,
			Enabled = true,
			TextStyle = plrTitles:FindFirstChild("Brave_Title")
		},
		{ -- [Prodigy Detective]
			Name = "Prodigy Detective",
			Price = 50,
			Enabled = true,
			TextStyle = plrTitles:FindFirstChild("ProdigyDetective_Title")
		},
		{ -- [Runner]
			Name = "Runner",
			Price = 50,
			Enabled = true,
			TextStyle = plrTitles:FindFirstChild("Runner_Title")
		},
		{ -- [Investigator]
			Name = "Investigator",
			Price = 60,
			Enabled = true,
			TextStyle = plrTitles:FindFirstChild("Investigator_Title")
		},
		{ -- [Experienced Agent]
			Name = "Experienced Agent",
			Price = 80,
			Enabled = true,
			TextStyle = plrTitles:FindFirstChild("ExperiencedAgent_Title")
		},
		{ -- [Lost Patient]
			Name = "Lost Patient",
			Price = 90,
			Enabled = true,
			TextStyle = plrTitles:FindFirstChild("LostPatient_Title")
		},
		{ -- [Player]
			Name = "Player",
			Price = 100,
			Enabled = true,
			TextStyle = plrTitles:FindFirstChild("Player_Title")
		},
		{ -- [Nerd]
			Name = "Nerd",
			Price = 120,
			Enabled = true,
			TextStyle = plrTitles:FindFirstChild("Nerd_Title")
		},
		{ -- [Mastermind]
			Name = "Mastermind",
			Price = 150,
			Enabled = true,
			TextStyle = plrTitles:FindFirstChild("Mastermind_Title")
		},
		{ -- [Void]
			Name = "Void",
			Price = 370,
			Enabled = true,
			TextStyle = plrTitles:FindFirstChild("Void_Title")
		},
		{ -- [Rainbow]
			Name = "Rainbow",
			Price = 520,
			Enabled = true,
			TextStyle = plrTitles:FindFirstChild("Rainbow_Title")
		},
		{ -- [Insane]
			Name = "Insane",
			Price = 0,
			Limited = true, -- can't get this title by purchasing it (only by other ways)
			Enabled = true,
			TextStyle = plrTitles:FindFirstChild("Insane_Title")
		},
		{ -- [Crazy]
			Name = "Crazy",
			Price = 0,
			Limited = true,
			Enabled = true,
			TextStyle = plrTitles:FindFirstChild("Crazy_Title")
		}
	}
}

--[[ In-game perks
	Structure:
	{
		Name = "blabla", -- name of the perk
		Desc = "blabla", -- description of the perk
		Type = "Item", -- Type of the perk | Item = inventory item
		Price = 100, -- Price in the vendor shop
		ID = 0, -- Developer product ID to purchase the perk in robux
		Enabled = true -- if the perk is enabled to be purchased/earned
	}
]]
products.Perks = {
	{
		Name = "Cursed Doll",
		Desc = "Distracts the monster for 10 seconds!",
		Img = "rbxassetid://105221517020423",
		Type = "Item",
		price = 300,
		ID = 3382855058,
		Enabled = true
	},
	{
		Name = "Medkit",
		Desc = "Heal 100% of your life!",
		Type = "Item",
		Img = "rbxassetid://70656496005263",
		price = 120,
		ID = 3382855970,
		Enabled = true
	},
	--[[{
		Name = "Baseball Bat",
		Desc = "Start with a baseball bat!",
		Type = "Item",
		Img = "rbxassetid://107003017115136",
		price = 250,
		ID = 3382855969,
		Enabled = true
	},]]
	{
		Name = "Bandage",
		Desc = "Heal 50% of your life!",
		Type = "Item",
		Img = "rbxassetid://5296816619",
		price = 75,
		ID = 3382855968,
		Enabled = true
	},
	{
		Name = "Night Vision Goggles",
		Desc = "Give you night vision to see better in dark places!",
		Type = "Item",
		Img = "rbxassetid://121799076092454",
		price = 500,
		ID = 3382982730,
		Enabled = true
	},
	{
		Name = "Bear Trap",
		Desc = "Traps and damage enemies.",
		Type = "Item",
		Img = "rbxassetid://6977364783",
		price = 150,
		ID = 3384090558,
		Enabled = true
	}
}

products.Config = {
	MaxPopularPasses = 5 -- Max number of popular passes can be shown on shop popular session.
}

function products:GetProduct(name: string): {}?
	for _, product in pairs(products.Products) do
		if product.Name == name then
			return product
		end
	end
	return nil
end

function products:GetPass(name: string | number): {}?
	for _, pass in pairs(products.Passes) do
		if pass.Name == name then
			return pass
		end
	end
	return nil
end

function products:GetTitle(name: string): {}?
	for _, title in pairs(products.Items.Titles) do
		if title.Name == name then
			return title
		end
	end
	return nil
end

function products:GetPerk(name: string): {}?
	for _, perk in pairs(products.Perks) do
		if perk.Name == name then
			return perk
		end
	end
	return nil
end

return products