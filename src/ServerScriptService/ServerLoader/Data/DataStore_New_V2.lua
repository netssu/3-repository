local dataStore = {}

function dataStore.Init()
	--//Services
	local ServerScriptService = game:GetService("ServerScriptService")
	local RunService = game:GetService("RunService")
	local Players = game:GetService("Players")
	local Rs = game:GetService("ReplicatedStorage")
	
	--//Remotes
	local Remotes = Rs:FindFirstChild("Remotes")
	local PlrLoadedEvent = Remotes:FindFirstChild("PlrLoaded")
	local CompletedTutorial = Remotes:FindFirstChild("CompletedTutorial")
	
	--//ProfileStore
	local ProfileStore = require(ServerScriptService.Libraries.ProfileStore)
	
	--//Modules
	local GameConfig = require(Rs.GameConfig)
	local BadgesLoader = require(script.BadgesLoader)
	local DataManager = require(ServerScriptService.Data.DataManager)
	local TemplateProfile = require(ServerScriptService.Data.Template)
	
	--//Values
	local DAILY_REWARD_TIME = 24 * 60 * 60 -- 24 hours (daily reward)
	
	local function GetStoreName()
		return RunService:IsStudio() and "Test" or GameConfig.datastorekey
	end
	
	--//Acess profiles
	local PlayerStore = ProfileStore.New(GetStoreName(), TemplateProfile)
	
	
	--//Add leaderstatas and synchronize player data
	local function Initialize(player: Player, profile: typeof(PlayerStore.StartSessionAsync()))
		if RunService:IsStudio() then print(profile) end
		-- How sync data with player:
		-- EventName:FireClient(player, profile.Data.Coins)
		
		
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
		FreeRevives.Value = profile.Data.FreeRevives
		
		local GroupReward = Instance.new("BoolValue", OtherValues)
		GroupReward.Name = "GroupReward"
		GroupReward.Value = profile.Data.GroupReward
		
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
			if typeItem == "Title" then
				newItem.Value = "Titles"
			end
		end
		
		local EquipedEmotes = Instance.new("Folder", OtherValues)
		EquipedEmotes.Name = "EquipedEmotes"
		for posEmote, emoteName in profile.Data.EquipedEmotes do
			local newEmote = Instance.new("StringValue", EquipedEmotes)
			newEmote.Name = emoteName
			newEmote.Value = posEmote
		end
		
		local AwardedCodes = Instance.new("Folder", OtherValues)
		AwardedCodes.Name = "AwardedCodes"
		for codeName, codeValue in profile.Data.AwardedCodes do
			local newCode = Instance.new("BoolValue", AwardedCodes)
			newCode.Name = codeName
			newCode.Value = true
		end
		
		-- daily rewards
		local currentDay = Instance.new("IntValue", OtherValues) -- current day to claim the daily reward
		currentDay.Name = "CurrentDay"
		currentDay.Value = profile.Data.CurrentDay
		
		local rewardType = Instance.new("IntValue", OtherValues)
		rewardType.Name = "RewardType"
		rewardType.Value = profile.Data.RewardType
		
		local ClaimedDailyReward = Instance.new("BoolValue", OtherValues)
		ClaimedDailyReward.Name = "ClaimedDailyReward"
		ClaimedDailyReward.Value = false
		
		local RewardTime = Instance.new("IntValue", OtherValues)
		RewardTime.Name = "RewardTime"
		RewardTime.Value = 0
		-- daily rewards
		
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
		
		PlrLoadedEvent:FireClient(player, true)
		BadgesLoader.SaveAwardedBadges(player)
		
		local DataLoaded = Instance.new("BoolValue", player)
		DataLoaded.Name = "DataLoaded"
		DataLoaded.Value = true
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
		
		--------------------------------------------
		if RunService:IsStudio() then --[ testing ]--
			task.spawn(function()
				if not profile then return end
				
				if profile.Data.Speedruns then
					table.clear(profile.Data.Speedruns)
				end
				if profile.Data.GroupReward then
					profile.Data.GroupReward = false
				end
				profile.Data.DailyReward = true
			end)
		end
		--------------------------------------------
		
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
			profile.Data.RewardTime += timeSinceLastLogin
			
			if profile.Data.CurrentDay >= 8 then
				profile.Data.CurrentDay = 1
				profile.Data.ClaimedDailyReward = false
				profile.Data.RewardType = 2
			end
			
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
					if player and player.Parent == Players then
						if not profile.Data.DailyReward then
							profile.Data.DailyTime += 1
							if profile.Data.DailyTime >= DAILY_REWARD_TIME then
								profile.Data.DailyTime = 0
								profile.Data.DailyReward = true -- player can claim the wheel daily reward again
							end
						end
						if profile.Data.ClaimedDailyReward then
							profile.Data.RewardTime += 1
							
							if profile.Data.RewardTime >= DAILY_REWARD_TIME then -- the timer will just start again after the player claim the reward
								profile.Data.RewardTime = 0
								profile.Data.CurrentDay += 1
								profile.Data.ClaimedDailyReward = false
								
								if profile.Data.CurrentDay >= 8 then
									profile.Data.CurrentDay = 1
									profile.Data.RewardType = 2
								end
							end
							
							local OtherValues = player:FindFirstChild("OtherValues")
							local rewardTime = OtherValues and OtherValues:FindFirstChild("RewardTime") :: IntValue
							if rewardTime then
								rewardTime.Value = profile.Data.RewardTime
							end
						end
					end
				end
			end)()
			
			if player.Parent == Players then
				
				DataManager.Profiles[player] = profile
				Initialize(player, profile)
				
				CompletedTutorial.OnServerEvent:Connect(function(plr: Player)
					--DataManager.Profiles[player].Data.FirstTime = false
					if profile and profile.Data then
						if profile.Data.FirstTime then
							profile.Data.FirstTime = false
						end
					end
				end)
				
			else
				
				profile:EndSession() -- Fires OnSessionEnd
			end
		else -- Only when server shuts down when player joining
			
			player:Kick("Data error occured. Please rejoin.")
		end
	end
	
	local function PlayerLeaving(player: Player)
		local profile = DataManager.Profiles[player]
		if profile then
			if profile.Data then
				profile.Data.LastLogin = os.time()
			end
			profile:EndSession()
		end
		if profile and player and player.Parent == Players and profile[player] then
			DataManager.Profiles[player] = nil
		end
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
	
	coroutine.wrap(function()
		while task.wait(1) do
			for i, plr in game.Players:GetPlayers() do
				if plr:FindFirstChild("OtherValues") and plr.OtherValues:FindFirstChild("TimePlayed") then
					DataManager.AddTimePlayed(plr, 1)
				end
			end
		end
	end)()
end

return dataStore