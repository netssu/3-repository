--//Services
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local UpdatePlrOptions = Remotes:FindFirstChild("UpdatePlrOptions")
local UpdatePlrWins = Remotes:FindFirstChild("UpdatePlrWins")
local PlrLoadedEvent = Remotes:FindFirstChild("PlrDataLoaded")
local SpeedrunStartEvent = Remotes:FindFirstChild("SpeedrunStart")

--//Modules
local Modules = Rs:FindFirstChild("Modules")
local GameConfigModule = require(Modules:FindFirstChild("GameConfigModule"))

--//ProfileStore
local ProfileStore = require(ServerScriptService.Libraries.ProfileStore)

--//Modules
local GameConfig = require(Rs.GameConfig)
local DataManager = require(ServerScriptService.Data.DataManager)
local TemplateProfile = require(ServerScriptService.Data.Template)

--//Values
local DAILY_REWARD_TIME = 24 * 60 * 60 -- 24 hours (daily reward)

local function GetStoreName()
	return RunService:IsStudio() and "Test" or GameConfig.datastorekey
end

--//Acess profiles
local PlayerStore = ProfileStore.New(GetStoreName(), TemplateProfile)

local loaded = false

--//Add leaderstatas and synchronize player data
local function Initialize(player: Player, profile: typeof(PlayerStore.StartSessionAsync()))
	-- How sync data with player:
	-- EventName:FireClient(player, profile.Data.Coins)

	if RunService:IsStudio() then
		print("Profile loaded for:", player.Name, profile.Data)
	end

	-- leaderstats
	local leaderstats = Instance.new("Folder", player)
	leaderstats.Name = "leaderstats"

	local Wins = Instance.new("IntValue", leaderstats)
	Wins.Name = "Wins"
	Wins.Value = profile.Data.Wins

	local Coins = Instance.new("IntValue", leaderstats)
	Coins.Name = "Coins"
	Coins.Value = profile.Data.Coins

	local Kills = Instance.new("IntValue", leaderstats)
	Kills.Name = "Kills"
	Kills.Value = profile.Data.Kills


	-- Secondary Values
	local OtherValues = Instance.new("Folder", player)
	OtherValues.Name = "OtherValues"

	local Deaths = Instance.new("IntValue", OtherValues)
	Deaths.Name = "Deaths"
	Deaths.Value = profile.Data.Deaths

	local TimePlayed = Instance.new("IntValue", OtherValues)
	TimePlayed.Name = "TimePlayed"
	TimePlayed.Value = profile.Data.TimePlayed

	local FreeRevives = Instance.new("IntValue", OtherValues)
	FreeRevives.Name = "FreeRevives"
	FreeRevives.Value = 2 --profile.Data.FreeRevives //temporaly desactivated for bug fixing

	--[[local GroupReward = Instance.new("BoolValue", OtherValues)
	GroupReward.Name = "GroupReward"
	GroupReward.Value = profile.Data.GroupReward]]

	local EquipedCharacter = Instance.new("StringValue", OtherValues)
	EquipedCharacter.Name = "EquipedCharacter"
	EquipedCharacter.Value = profile.Data.EquipedCharacter

	local EquipedTitle = Instance.new("StringValue", OtherValues)
	EquipedTitle.Name = "EquipedTitle"
	EquipedTitle.Value = profile.Data.EquipedTitle

	local OwnedCharacters = Instance.new("Folder", OtherValues)
	OwnedCharacters.Name = "OwnedCharacters"
	for i, v in profile.Data.OwnedCharacters do
		local newChar = Instance.new("StringValue", OwnedCharacters)
		newChar.Name = v
	end

	local AwardedBadges = Instance.new("Folder", OtherValues)
	AwardedBadges.Name = "AwardedBadges"
	for badgeName, badgeValue in profile.Data.AwardedBadges do
		local newBadge = Instance.new("BoolValue", AwardedBadges)
		newBadge.Name = badgeName
		newBadge.Value = badgeValue
	end

	local OwnedItems = Instance.new("Folder", OtherValues)
	OwnedItems.Name = "OwnedItems"
	for item, typeItem in profile.Data.OwnedItems do
		local newItem = Instance.new("StringValue", OwnedItems)
		newItem.Name = item
		newItem.Value = typeItem
	end

	local EquipedEmotes = Instance.new("Folder", OtherValues)
	EquipedEmotes.Name = "EquipedEmotes"
	for posEmote, emoteName in profile.Data.EquipedEmotes do
		local newEmote = Instance.new("StringValue", EquipedEmotes)
		newEmote.Name = emoteName
		newEmote.Value = posEmote
	end

	--[[local AwardedCodes = Instance.new("Folder", OtherValues)
	AwardedCodes.Name = "AwardedCodes"
	for codeName, codeValue in profile.Data.AwardedCodes do
		local newCode = Instance.new("BoolValue", AwardedCodes)
		newCode.Name = codeName
		newCode.Value = true
	end]]


	-- Settings --
	local PlrSettings = Instance.new("Folder", player)
	PlrSettings.Name = "PlrSettings"

	-- General Settings --
	local PlrTitles = Instance.new("BoolValue", PlrSettings)
	PlrTitles.Name = "PlrTitles"
	PlrTitles.Value = profile.Data.PlrTitles

	local GameTips = Instance.new("BoolValue", PlrSettings)
	GameTips.Name = "GameTips"
	GameTips.Value = profile.Data.GameTips

	local ToggleCrouch = Instance.new("BoolValue", PlrSettings)
	ToggleCrouch.Name = "ToggleCrouch"
	ToggleCrouch.Value = profile.Data.ToggleCrouch

	-- Visual Settings --
	local Constrast = Instance.new("NumberValue", PlrSettings)
	Constrast.Name = "Contrast"
	Constrast.Value = profile.Data.Contrast

	local Brightness = Instance.new("NumberValue", PlrSettings)
	Brightness.Name = "Brightness"
	Brightness.Value = profile.Data.Brightness

	local GlobalShadows = Instance.new("BoolValue", PlrSettings)
	GlobalShadows.Name = "GlobalShadows"
	GlobalShadows.Value = profile.Data.GlobalShadows

	-- Audio Settings --
	local MasterVolume = Instance.new("IntValue", PlrSettings)
	MasterVolume.Name = "MasterVolume"
	MasterVolume.Value = profile.Data.MasterVolume

	local AmbientSounds = Instance.new("IntValue", PlrSettings)
	AmbientSounds.Name = "AmbientSounds"
	AmbientSounds.Value = profile.Data.AmbientSounds

	loaded = true
	Rs.CanLoadChar.Value = true
	task.delay(5, function() PlrLoadedEvent:FireClient(player) end)
end


local function PlayerAdded(player: Player)

	-- Check if the profile already exists
	if DataManager.Profiles[player] then return end

	-- Starting new profile session
	local profile = PlayerStore:StartSessionAsync("Player_"..player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	-- Ensure that the profile exists
	if profile ~= nil then

		profile:AddUserId(player.UserId) -- GDPR compliance
		profile:Reconcile() -- Fill in missing data variables from template


		--//Handles session locking
		profile.OnSessionEnd:Connect(function() -- Cancel function runs
			DataManager.Profiles[player] = nil
			player:Kick("Data error occured. Please rejoin")
		end)

		local lastLogin = profile.Data.LastLogin or 0
		local currentTime = os.time()
		local timeSinceLastLogin = currentTime - lastLogin

		profile.Data.DailyTime += timeSinceLastLogin

		local running = true
		player.AncestryChanged:Connect(function(_, parent)
			if not parent then
				running = false
			end
		end)

		--//Calculate the daily reward time
		coroutine.wrap(function()
			while running do
				task.wait(1)
				if player and player.Parent == Players and not profile.Data.DailyReward then
					profile.Data.DailyTime += 1
					if profile.Data.DailyTime >= DAILY_REWARD_TIME then
						profile.Data.DailyTime = 0
						profile.Data.DailyReward = true
					end
				end
			end
		end)()


		if player.Parent == Players then

			DataManager.Profiles[player] = profile
			Initialize(player, profile)

		else

			profile:EndSession() -- Fires OnSessionEnd
		end
	else -- Only when server shuts down when player joining

		player:Kick("Data error occured. Please rejoin.")
	end
end

local function PlayerLeaving(player: Player)
	local profile = DataManager.Profiles[player]
	if not profile then return end
	profile:EndSession()
	DataManager.Profiles[player] = nil
end

--//Early joiners check
for i, plr in Players:GetPlayers() do
	task.spawn(PlayerAdded, plr)
end

Players.PlayerAdded:Connect(PlayerAdded)
Players.PlayerRemoving:Connect(PlayerLeaving)

game:BindToClose(function()
	for _, plr in Players:GetPlayers() do
		PlayerLeaving(plr)
	end
end)

--//Data manager | Time Played | Wins | Speedrun timer
coroutine.wrap(function()
	while task.wait(1) do
		for i, plr in game.Players:GetPlayers() do
			if plr:FindFirstChild("OtherValues") and plr.OtherValues:FindFirstChild("TimePlayed") then
				DataManager.AddTimePlayed(plr, 1)
			end
		end
	end
end)()

local plrsWinDebounce = {}
local plrsSpeedrunTime = {}

SpeedrunStartEvent.OnServerEvent:Connect(function(plr)
	if not plrsSpeedrunTime[plr] then -- Only receive this when speedrun gamemode is enabled
		plrsSpeedrunTime[plr] = os.clock()
	end
end)

--//Give a win when a player beat the game -- ONLY FIRES WHEN PLAYER BEAT THE GAME
UpdatePlrWins.OnServerEvent:Connect(function(plr, amount)
	if plr and amount and not plrsWinDebounce[plr.Name] then
		DataManager.AddWins(plr, amount)
		plrsWinDebounce[plr.Name] = true
		
		if GameConfigModule.GameMode == "Speedrun" then
			local timeSpent = os.clock() - plrsSpeedrunTime[plr]
			
			local profileData = DataManager.GetProfileData(plr)
			if profileData and profileData["Speedruns"] then
				if profileData["Speedruns"]["Chapter1"] then -- update/create a speedrun time
					local oldTime = profileData["Speedruns"]["Chapter1"]
					if timeSpent < oldTime then
						DataManager.UpdateSpeedrunTime(plr, "Chapter1", timeSpent)
					end
				else
					DataManager.UpdateSpeedrunTime(plr, "Chapter1", timeSpent)
				end
			end
		end
		
		task.delay(20, function()
			plrsWinDebounce[plr.Name] = nil
		end)
	end
end)
