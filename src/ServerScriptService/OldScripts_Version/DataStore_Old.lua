local DataStore = {}

function DataStore.Init()
	--//Services
	local DataStore = game:GetService("DataStoreService")
	local Rs = game:GetService("ReplicatedStorage")
	
	--//Modules
	local Modules = Rs:FindFirstChild("Modules")
	local GameConfigModule = require(Rs:FindFirstChild("GameConfig"))
	local ProfileStore = require(Modules:FindFirstChild("ProfileStore"))
	
	--//Player Data
	local PlrData = DataStore:GetDataStore(GameConfigModule.datastorekey)
	local BadgesLoader = require(script:FindFirstChild("BadgesLoader"))
	
	--//Remotes
	local Remotes = Rs:FindFirstChild("Remotes")
	local PlrLoadedEvent = Remotes:FindFirstChild("PlrLoaded")
	
	game.Players.PlayerAdded:Connect(function(Plr)
		---------//[Primary Values]//---------
		local leaderstats = Instance.new("Folder", Plr)
		leaderstats.Name = "leaderstats"
		
		local Wins = Instance.new("IntValue", leaderstats)
		Wins.Name = "Wins"
		Wins.Value = 0 -- Default Value
		
		local Coins = Instance.new("IntValue", leaderstats)
		Coins.Name = "Coins"
		Coins.Value = 0
		
		local Kills = Instance.new("IntValue", leaderstats)
		Kills.Name = "Kills"
		Kills.Value = 0
		
		---------//[Secondary Values]//---------
		local OtherValues = Instance.new("Folder", Plr)
		OtherValues.Name = "OtherValues"
		
		local Deaths = Instance.new("IntValue", OtherValues)
		Deaths.Name = "Deaths"
		Deaths.Value = 0
		
		local TimePlayed = Instance.new("IntValue", OtherValues)
		TimePlayed.Name = "TimePlayed"
		TimePlayed.Value = 0
		
		local FreeRevives = Instance.new("IntValue", OtherValues)
		FreeRevives.Name = "FreeRevives"
		FreeRevives.Value = 0 -- Default Value
		
		local GroupRevive = Instance.new("BoolValue", OtherValues)
		GroupRevive.Name = "GroupRevive"
		GroupRevive.Value = false
		
		local OwnedCharacters = Instance.new("Folder", OtherValues)
		OwnedCharacters.Name = "OwnedCharacters"
		
		local EquipedCharacter = Instance.new("StringValue", OtherValues)
		EquipedCharacter.Name = "EquipedCharacter"
		EquipedCharacter.Value = "Larry" -- Default Value
		
		local AwardedBadges = Instance.new("Folder", OtherValues)
		AwardedBadges.Name = "AwardedBadges"
		
		local OwnedItems = Instance.new("Folder", OtherValues)
		OwnedItems.Name = "OwnedItems"
		
		local EquipedTitle = Instance.new("StringValue", OtherValues)
		EquipedTitle.Name = "EquipedTitle"
		EquipedTitle.Value = "Newbie" -- Default Value
		
		local EquipedEmotes = Instance.new("Folder", OtherValues)
		EquipedEmotes.Name = "EquipedEmotes"
		
		local AwardedCodes = Instance.new("Folder", OtherValues)
		AwardedCodes.Name = "AwardedCodes"
		
		---------//[Settings]//---------
		local PlrSettings = Instance.new("Folder", Plr)
		PlrSettings.Name = "PlrSettings"
		
		-- General Settings --
		local PlrTitles = Instance.new("BoolValue", PlrSettings)
		PlrTitles.Name = "PlrTitles"
		PlrTitles.Value = true -- Default Value
		
		local GameTips = Instance.new("BoolValue", PlrSettings)
		GameTips.Name = "GameTips"
		GameTips.Value = true
		
		local ToggleCrouch = Instance.new("BoolValue", PlrSettings)
		ToggleCrouch.Name = "ToggleCrouch"
		ToggleCrouch.Value = true
		
		-- Visual Settings --
		local Constrast = Instance.new("NumberValue", PlrSettings)
		Constrast.Name = "Contrast"
		Constrast.Value = 0.5
		
		local Brightness = Instance.new("NumberValue", PlrSettings)
		Brightness.Name = "Brightness"
		Brightness.Value = 0.5
		
		local GlobalShadows = Instance.new("BoolValue", PlrSettings)
		GlobalShadows.Name = "GlobalShadows"
		GlobalShadows.Value = true
		
		-- Audio Settings --
		local MasterVolume = Instance.new("IntValue", PlrSettings)
		MasterVolume.Name = "MasterVolume"
		MasterVolume.Value = 50
		
		local AmbientSounds = Instance.new("IntValue", PlrSettings)
		AmbientSounds.Name = "AmbientSounds"
		AmbientSounds.Value = 50
		
		local success, Data = pcall(function()
			return PlrData:GetAsync(Plr.UserId)
		end)
		if success and Data then
			if Data.Wins then -- In case if the value is nil
				Wins.Value = Data.Wins
			end
			if Data.Coins then
				Coins.Value = Data.Coins
			end
			if Data.Kills then
				Kills.Value = Data.Kills
			end
			if Data.Deaths then
				Deaths.Value = Data.Deaths
			end
			if Data.TimePlayed then
				TimePlayed.Value = Data.TimePlayed
			end
			if Data.FreeRevives then
				FreeRevives.Value = Data.FreeRevives
			end
			if Data.GroupRevive then
				GroupRevive.Value = Data.GroupRevive
			end
			if Data.EquipedCharacter then
				EquipedCharacter.Value = Data.EquipedCharacter
			end
			if Data.OwnedCharacters then
				for i, v in Data.OwnedCharacters do
					local newChar = Instance.new("StringValue", OwnedCharacters)
					newChar.Name = v
				end
			end
			if Data.AwardedBadges then
				for badgeName, badgeValue in Data.AwardedBadges do
					local newBadge = Instance.new("BoolValue", AwardedBadges)
					newBadge.Name = badgeName
					newBadge.Value = badgeValue
				end
				BadgesLoader.SaveAwardedBadges(Plr)
			end
			if Data.OwnedItems then
				for item, typeItem in Data.OwnedItems do
					local newItem = Instance.new("StringValue", OwnedItems)
					newItem.Name = item
					newItem.Value = typeItem
				end
			end
			if Data.EquipedTitle then
				EquipedTitle.Value = Data.EquipedTitle
			end
			if Data.EquipedEmotes then
				for posEmote, emoteName in Data.EquipedEmotes do
					local newEmote = Instance.new("StringValue", EquipedEmotes)
					newEmote.Name = emoteName
					newEmote.Value = posEmote
				end
			end
			if Data.AwardedCodes then
				for i, v in Data.AwardedCodes do
					local newCode = Instance.new("BoolValue", AwardedCodes)
					newCode.Name = v
					newCode.Value = true
				end
			end
			if Data.Settings then
				for settingName, settingValue in Data.Settings do
					local newSetting = PlrSettings:FindFirstChild(settingName)
					if newSetting then
						newSetting.Value = settingValue
					end
				end
			end
		end
		
		PlrLoadedEvent:FireClient(Plr, true)
	end)
	
	local function saveData(plr)
		local ownedChars = {}
		local awardedBadges = {}
		local ownedItems = {}
		local equipedEmotes = {}
		local awardedCodes = {}
		local plrSettings = {}
		
		--//Get plr owned Chars
		for i, v in plr.OtherValues.OwnedCharacters:GetChildren() do
			table.insert(ownedChars, v.Name)
		end
		
		--//Get plr awarded badges
		for i, v in plr.OtherValues.AwardedBadges:GetChildren() do
			awardedBadges[v.Name] = v.Value
		end
		
		--//Get plr owned items
		for i, v in plr.OtherValues.OwnedItems:GetChildren() do
			ownedItems[v.Name] = v.Value
		end
		
		--//Get plr equiped emotes
		for i, v in plr.OtherValues.EquipedEmotes:GetChildren() do
			equipedEmotes[v.Value] = v.Name
		end
		
		--//Get plr awarded codes
		for i, v in plr.OtherValues.AwardedCodes:GetChildren() do
			table.insert(awardedCodes, v.Name)
		end
		
		--//Get plr settings
		for i, v in plr.PlrSettings:GetChildren() do
			plrSettings[v.Name] = v.Value
		end
		
		local plrData = {
			Wins = plr.leaderstats.Wins.Value;
			Coins = plr.leaderstats.Coins.Value;
			Kills = plr.leaderstats.Kills.Value;
			Deaths = plr.OtherValues.Deaths.Value;
			TimePlayed = plr.OtherValues.TimePlayed.Value;
			FreeRevives = plr.OtherValues.FreeRevives.Value;
			GroupRevive = plr.OtherValues.GroupRevive.Value;
			EquipedCharacter = plr.OtherValues.EquipedCharacter.Value;
			OwnedCharacters = ownedChars;
			AwardedBadges = awardedBadges;
			OwnedItems = ownedItems;
			EquipedTitle = plr.OtherValues.EquipedTitle.Value;
			EquipedEmotes = equipedEmotes;
			AwardedCodes = awardedCodes;
			Settings = plrSettings;
		}
		
		local success, errmsg = pcall(function()
			PlrData:SetAsync(plr.UserId, plrData)
		end)
		if not success then
			warn("Can't save "..plr.Name.." Data, error: ".. errmsg)
		end
	end
	
	game:BindToClose(function()
		for i, v in game.Players:GetPlayers() do
			saveData(v)
		end
	end)
	
	game.Players.PlayerRemoving:Connect(function(plr)
		saveData(plr)
	end)
	
	coroutine.wrap(function()
		while task.wait(1) do
			for i, plr in game.Players:GetPlayers() do
				if plr:FindFirstChild("OtherValues") and plr.OtherValues:FindFirstChild("TimePlayed") then
					plr.OtherValues.TimePlayed.Value += 1
				end
			end
		end
	end)()
end

return DataStore