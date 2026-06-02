-- services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- modules
local LevelData = require(ReplicatedStorage.Modules.StoredData.LevelData)
local LobbyCrateData = require(ReplicatedStorage.Modules.StoredData.LobbyCrateData)
local QuestPool = require(ReplicatedStorage.Modules.StoredData.QuestsData)

local NotificationRemote = ReplicatedStorage.Remotes.Notification.SendNotification

-- config
local MAX_LEVEL = 50
local TOUCH_COOLDOWN = 3

-- time constants in seconds
local ONE_DAY = 86400
local ONE_WEEK = 604800
local ONE_MONTH = 2592000

-- waits until userdata exists and returns it
local function getUserData(Player : Player)
	local userData
	repeat
		userData = Player:FindFirstChild("UserData")
		if not userData then
			task.wait(0.1)
		end
	until userData

	return userData
end

local function isNumericValue(valueObject: Instance?): boolean
	return valueObject ~= nil and (valueObject:IsA("IntValue") or valueObject:IsA("NumberValue"))
end

local function ensureTimerValue(parent: Instance, valueName: string, defaultValue: number)
	local valueObject = parent:FindFirstChild(valueName)
	if valueObject and not isNumericValue(valueObject) then
		valueObject:Destroy()
		valueObject = nil
	end

	if not valueObject then
		valueObject = Instance.new("NumberValue")
		valueObject.Name = valueName
		valueObject.Value = defaultValue
		valueObject.Parent = parent
	end

	return valueObject
end

local function ensureCratesFolder(userData: Folder)
	local cratesFolder = userData:FindFirstChild("Crates")
	if not cratesFolder then
		cratesFolder = Instance.new("Folder")
		cratesFolder.Name = "Crates"
		cratesFolder.Parent = userData
	end

	return cratesFolder
end

local function syncLegacyLobbyTimer(userData: Folder, timersFolder: Folder)
	local legacyTimer = userData:FindFirstChild("RemainingTimer")
	local goldTimer = timersFolder:FindFirstChild(LobbyCrateData.LegacyCrateId)
	if isNumericValue(legacyTimer) and isNumericValue(goldTimer) then
		legacyTimer.Value = goldTimer.Value
	end
end

local function ensureLobbyCrateTimers(userData: Folder)
	local timersFolder = userData:FindFirstChild("LobbyCrateTimers")
	if not timersFolder then
		timersFolder = Instance.new("Folder")
		timersFolder.Name = "LobbyCrateTimers"
		timersFolder.Parent = userData
	end

	local legacyTimer = userData:FindFirstChild("RemainingTimer")

	for _, crateId in ipairs(LobbyCrateData.Order) do
		local defaultTimer = LobbyCrateData.GetCooldown(crateId)
		if crateId == LobbyCrateData.LegacyCrateId and isNumericValue(legacyTimer) then
			defaultTimer = legacyTimer.Value
		end

		ensureTimerValue(timersFolder, crateId, defaultTimer)
	end

	syncLegacyLobbyTimer(userData, timersFolder)

	return timersFolder
end

local function getLobbyCrateId(crateModel: Instance)
	return LobbyCrateData.ResolveCrateId(crateModel.Name, crateModel:GetAttribute("CrateId"))
end

local function getLobbyCrateTouchPart(crateModel: Instance)
	if crateModel:IsA("BasePart") then
		return crateModel
	end

	local touchPartName = crateModel:GetAttribute("TouchPartName")
	if type(touchPartName) == "string" and touchPartName ~= "" then
		local namedTouchPart = crateModel:FindFirstChild(touchPartName, true)
		if namedTouchPart and namedTouchPart:IsA("BasePart") then
			return namedTouchPart
		end
	end

	for _, childName in ipairs({ "Crate", "TouchPart", "Hitbox" }) do
		local child = crateModel:FindFirstChild(childName, true)
		if child and child:IsA("BasePart") then
			return child
		end
	end

	if crateModel:IsA("Model") and crateModel.PrimaryPart then
		return crateModel.PrimaryPart
	end

	return crateModel:FindFirstChildWhichIsA("BasePart", true)
end

local function getLobbyCrateModels()
	local crateModels = {}
	local seen = {}

	for _, folderName in ipairs(LobbyCrateData.FolderNames) do
		local folder = Workspace:FindFirstChild(folderName)
		if folder then
			for _, child in ipairs(folder:GetChildren()) do
				if not seen[child] and getLobbyCrateId(child) then
					seen[child] = true
					table.insert(crateModels, child)
				end
			end
		end
	end

	local legacyCrate = Workspace:FindFirstChild(LobbyCrateData.LegacyModelName)
	if legacyCrate and not seen[legacyCrate] and getLobbyCrateId(legacyCrate) then
		table.insert(crateModels, legacyCrate)
	end

	return crateModels
end

local function grantLobbyCrateReward(player: Player, userData: Folder, crateId: string)
	local crateConfig = LobbyCrateData.GetConfig(crateId)
	if not crateConfig or not crateConfig.Reward then
		NotificationRemote:FireClient(player, "This crate has no reward configured.", "Error")
		return false
	end

	local reward = crateConfig.Reward

	if reward.Type == "Money" then
		local money = userData:FindFirstChild("Money")
		if not isNumericValue(money) then
			NotificationRemote:FireClient(player, "This crate cannot grant money right now.", "Error")
			return false
		end

		local amount = tonumber(reward.Amount) or 0
		money.Value += amount
		NotificationRemote:FireClient(player, string.format("You claimed the golden crate and got $%d", amount), "Success")
		return true
	end

	if reward.Type == "InventoryCrate" then
		local cratesFolder = ensureCratesFolder(userData)
		local crateName = tostring(reward.CrateName or "")
		local amount = math.max(1, tonumber(reward.Amount) or 1)
		local crateValue = cratesFolder:FindFirstChild(crateName)

		if crateValue and not isNumericValue(crateValue) then
			crateValue:Destroy()
			crateValue = nil
		end

		if not crateValue then
			crateValue = Instance.new("IntValue")
			crateValue.Name = crateName
			crateValue.Value = 0
			crateValue.Parent = cratesFolder
		end

		crateValue.Value += amount
		NotificationRemote:FireClient(player, string.format("You claimed %dx %s Crate", amount, crateName), "Success")
		return true
	end

	NotificationRemote:FireClient(player, "This crate reward type is not supported.", "Error")
	return false
end

-- applies quest progress from teleport data when coming from another place
local function applyQuestData(player: Player, teleportData)
	-- no teleport data so nothing to apply
	if not teleportData or not teleportData.UserData or not teleportData.UserData.Quests then
		print("[🏠] No teleport quest data found for " .. player.Name)
		return
	end

	local questTable = teleportData.UserData.Quests

	local UserData = getUserData(player)
	if not UserData then 
		warn("No userdata for player " .. player.Name)
		return 
	end

	local QuestsFolder = UserData:FindFirstChild("Quests")
	if not QuestsFolder then 
		print("No Quests folder for player", player.Name)
		return 
	end 

	-- loop through each category (daily, weekly, monthly)
	for categoryName, quests in pairs(questTable) do
		local categoryFolder = QuestsFolder:FindFirstChild(categoryName)
		if not categoryFolder then
			print("Missing category folder:", categoryName)
			continue
		end

		print("Found category:", categoryName)

		local ActiveQuestsFolder = categoryFolder:FindFirstChild("Active")
		if not ActiveQuestsFolder then 
			warn("No active folder for category:", categoryName)
			continue
		end

		-- update progress for each quest
		for questName, questValue in pairs(quests) do
			local questObject = ActiveQuestsFolder:FindFirstChild(questName)
			if not questObject then
				print("Quest not found:", questName, "in category:", categoryName)
			else
				local progressValue = questObject:FindFirstChild("Progress")
				if progressValue and (progressValue:IsA("IntValue") or progressValue:IsA("NumberValue")) then
					progressValue.Value = questValue
					print("Updated quest:", questName, "Progress =", questValue)
				else
					warn("Progress value not found or invalid for quest:", questName)
				end
			end
		end
	end
end

-- creates the leaderstats folder for the default roblox leaderboard
local function setupLeaderboard(Player)
	local UserData = Player:WaitForChild("UserData", 10)
	if not UserData then return end

	local Statistics = UserData:FindFirstChild("Statistics")
	if not Statistics then return end

	local WinsStat = Statistics:FindFirstChild("Wins")
	if not WinsStat then return end

	-- create leaderstats folder
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = Player

	-- create wins value
	local Wins = Instance.new("IntValue")
	Wins.Name = "Wins"
	Wins.Value = WinsStat.Value or 0
	Wins.Parent = leaderstats

	-- keep it synced with the actual wins stat
	WinsStat:GetPropertyChangedSignal("Value"):Connect(function()
		Wins.Value = WinsStat.Value
	end)
end

-- makes players not collide with each other
local function setupNoCollide(Player)
	-- register collision group if it doesnt exist
	if not PhysicsService:IsCollisionGroupRegistered("Players") then
		pcall(function()
			PhysicsService:RegisterCollisionGroup("Players")
		end)
	end

	-- disable collisions between players
	PhysicsService:CollisionGroupSetCollidable("Players", "Players", false)

	-- applies the collision group to all parts in a character
	local function applyNoCollide(Character)
		for _, part in ipairs(Character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CollisionGroup = "Players"
			end
		end

		-- handle new parts added to character (accessories etc)
		Character.DescendantAdded:Connect(function(desc)
			if desc:IsA("BasePart") then
				desc.CollisionGroup = "Players"
			end
		end)
	end

	-- apply to existing character
	if Player.Character then
		applyNoCollide(Player.Character)
	end

	-- apply to future characters
	Player.CharacterAdded:Connect(applyNoCollide)
end

-- handles leveling up when player has enough xp
local function processLevelUps(Player, EXP, Level)
	while Level.Value < MAX_LEVEL do
		local currentLevel = math.max(Level.Value, 1)
		local levelData = LevelData[tostring(currentLevel)]

		if not levelData then
			warn("[PlayerManager] Missing LevelData for level " .. currentLevel)
			break
		end

		local requiredXP = levelData.MaxXP

		-- check if they have enough xp to level up
		if EXP.Value >= requiredXP then
			EXP.Value -= requiredXP
			Level.Value += 1
			print(Player.Name .. " leveled up to Level " .. Level.Value)
		else
			break
		end
	end
end

-- helper to create instances quickly
local function newInstance(className, name, parent)
	local inst = Instance.new(className)
	inst.Name = name
	if parent then inst.Parent = parent end
	return inst
end

-- picks random quests from a pool using fisher-yates shuffle
local function pickRandomQuests(sourceTable, count)
	local picked = {}
	if not sourceTable then return picked end

	-- create index array
	local indices = {}
	for i = 1, #sourceTable do indices[#indices+1] = i end

	-- shuffle the indices
	for i = #indices, 2, -1 do
		local j = math.random(1, i)
		indices[i], indices[j] = indices[j], indices[i]
	end

	-- pick the first count items
	for i = 1, math.min(count, #indices) do
		picked[#picked+1] = sourceTable[indices[i]]
	end

	return picked
end

-- creates a folder for an active quest with all its values
local function createActiveQuestFolder(activeFolder, quest)
	local qFolder = Instance.new("Folder")
	qFolder.Name = quest.Name
	qFolder.Parent = activeFolder

	-- create progress tracking values
	local prog = Instance.new("IntValue"); prog.Name = "Progress"; prog.Value = 0; prog.Parent = qFolder
	local targ = Instance.new("IntValue"); targ.Name = "Target"; targ.Value = quest.TargetAmount or 1; targ.Parent = qFolder
	local done = Instance.new("BoolValue"); done.Name = "Completed"; done.Value = false; done.Parent = qFolder

	-- optional description
	if quest.Description then
		local desc = Instance.new("StringValue"); desc.Name = "Description"; desc.Value = quest.Description; desc.Parent = qFolder
	end

	-- optional target data name for tracking
	if quest.TargetDataName then
		local key = Instance.new("StringValue"); key.Name = "TargetDataName"; key.Value = quest.TargetDataName; key.Parent = qFolder
	end

	return qFolder
end

-- sets up a quest category (daily/weekly/monthly) and resets if needed
local function ensureCategoryStructure(questsFolder, categoryName, pool, resetInterval, assignCount)
	-- get or create category folder
	local category = questsFolder:FindFirstChild(categoryName)
	if not category then
		category = newInstance("Folder", categoryName, questsFolder)
	end

	-- get or create subfolders
	local active = category:FindFirstChild("Active") or newInstance("Folder", "Active", category)
	local completed = category:FindFirstChild("Completed") or newInstance("Folder", "Completed", category)
	local lastReset = category:FindFirstChild("LastReset") or newInstance("NumberValue", "LastReset", category)

	local now = os.time()
	local last = lastReset.Value or 0

	local activeChildren = active:GetChildren()
	local activeCount = #activeChildren

	-- check if we need to reset quests
	if now - last >= resetInterval or (activeCount == 0 and #completed:GetChildren() == 0) then
		-- clear all existing quests
		for _, child in ipairs(activeChildren) do
			child:Destroy()
		end
		for _, child in ipairs(completed:GetChildren()) do
			child:Destroy()
		end

		-- pick new random quests
		local picks = pickRandomQuests(pool, assignCount)
		for _, quest in ipairs(picks) do
			createActiveQuestFolder(active, quest)
		end
		lastReset.Value = now
	else
		-- trim extra quests if theres too many
		while #active:GetChildren() > assignCount do
			active:GetChildren()[#active:GetChildren()]:Destroy()
		end
	end
end

-- sets up all quest categories for a player
local function setupQuests(Player)
	if not Player then return end

	local UserData = Player:FindFirstChild("UserData") or Player:WaitForChild("UserData", 5)
	if not UserData then return end

	-- get or create quests folder
	local questsFolder = UserData:FindFirstChild("Quests")
	if not questsFolder then
		questsFolder = newInstance("Folder", "Quests", UserData)
	end

	-- setup each category with 3 quests each
	ensureCategoryStructure(questsFolder, "Daily", QuestPool.Daily, ONE_DAY, 3)
	ensureCategoryStructure(questsFolder, "Weekly", QuestPool.Weekly, ONE_WEEK, 3)
	ensureCategoryStructure(questsFolder, "Monthly", QuestPool.Monthly, ONE_MONTH, 3)
end

-- finds the highest rarity worm in the players hotbar
local function getRarestEquippedWorm(Player : Player)
	task.wait(5)

	local WormModels = game.ReplicatedStorage.Storage.Towers
	if not WormModels then return end

	local UserData = Player:WaitForChild("UserData")
	if not UserData then return end

	local Hotbar = UserData:WaitForChild("Hotbar")
	if not Hotbar then return end

	-- rarity rankings
	local rarityRank = {
		Common = 1,
		Uncommon = 2,
		Rare = 3,
		Epic = 4,
		Legendary = 5
	}

	local highestWorm = nil
	local highestRank = 0

	-- loop through hotbar and find the best one
	for _, data in ipairs(Hotbar:GetChildren()) do
		local wormName = data.Value
		if wormName == "" then continue end

		local wormModel = WormModels:FindFirstChild(wormName)
		if not wormModel then continue end

		local rarityValue = wormModel:GetAttribute("Rarity")
		if not rarityValue then continue end

		local rank = rarityRank[rarityValue]
		if rank and rank > highestRank then
			highestRank = rank
			highestWorm = wormName
		end
	end

	if highestWorm then
		game.ReplicatedStorage.Remotes.Pets.EquipPet:Fire(Player, highestWorm)
	else
		warn("Cannot find highest rarity")
	end
end

-- main player setup function
local function setupPlayer(Player: Player)
	Player:SetAttribute("inParty", false)
	setupNoCollide(Player)

	-- check for teleport data from other places
	local joinData = Player:GetJoinData()
	local teleportData = joinData.TeleportData

	if teleportData then
		applyQuestData(Player, teleportData)
	else
		print("[🏠] Player " .. Player.Name .. " joined without teleport data.")
	end

	-- timer loop for all players (runs forever)

	-- wait for character to load
	local Character = Player.Character or Player.CharacterAdded:Wait()
	if not Character then
		Player:Kick("Failed to load character")
		return
	end

	-- teleport to spawn
	Character:PivotTo(Workspace.SpawnPos.CFrame)

	local UserData = Player:WaitForChild("UserData", 5)
	if not UserData then return end
	ensureLobbyCrateTimers(UserData)

	local PlayTime = UserData:FindFirstChild("Statistics"):FindFirstChild("TimePlaying")

	local EXP = UserData:FindFirstChild("EXP")
	local Level = UserData:FindFirstChild("Level")
	if not EXP or not Level then return end

	-- process any pending level ups
	processLevelUps(Player, EXP, Level)

	-- listen for xp changes to level up
	EXP:GetPropertyChangedSignal("Value"):Connect(function()
		processLevelUps(Player, EXP, Level)
	end)

	-- run other setup stuff in background
	task.spawn(function()
		setupLeaderboard(Player)
		setupQuests(Player)
		getRarestEquippedWorm(Player)
	end)
end

-- crate touch handling
local recentTouches = {}
local registeredLobbyCrates = {}
local watchedLobbyFolders = {}

local function registerTouchCooldown(player: Player, crateId: string): boolean
	local touchKey = string.format("%d:%s", player.UserId, crateId)
	if recentTouches[touchKey] then
		return false
	end

	recentTouches[touchKey] = true
	task.delay(TOUCH_COOLDOWN, function()
		recentTouches[touchKey] = nil
	end)

	return true
end

local function handleLobbyCrateTouch(crateId: string, hit: BasePart)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player or not registerTouchCooldown(player, crateId) then
		return
	end

	local userData = player:FindFirstChild("UserData")
	if not userData then
		return
	end

	local timersFolder = ensureLobbyCrateTimers(userData)
	local timerValue = timersFolder:FindFirstChild(crateId)
	if not isNumericValue(timerValue) or timerValue.Value > 0 then
		return
	end

	if grantLobbyCrateReward(player, userData, crateId) then
		timerValue.Value = LobbyCrateData.GetCooldown(crateId)
		syncLegacyLobbyTimer(userData, timersFolder)
	end
end

local function connectLobbyCrate(crateModel: Instance)
	if registeredLobbyCrates[crateModel] then
		return
	end

	local crateId = getLobbyCrateId(crateModel)
	local touchPart = crateId and getLobbyCrateTouchPart(crateModel)
	if not crateId or not touchPart then
		return
	end

	registeredLobbyCrates[crateModel] = true
	touchPart.Touched:Connect(function(hit)
		handleLobbyCrateTouch(crateId, hit)
	end)
end

local function watchLobbyFolder(folder: Instance?)
	if not folder or watchedLobbyFolders[folder] then
		return
	end

	watchedLobbyFolders[folder] = true
	for _, child in ipairs(folder:GetChildren()) do
		connectLobbyCrate(child)
	end

	folder.ChildAdded:Connect(function(child)
		task.defer(connectLobbyCrate, child)
	end)
end

for _, crateModel in ipairs(getLobbyCrateModels()) do
	connectLobbyCrate(crateModel)
end

for _, folderName in ipairs(LobbyCrateData.FolderNames) do
	watchLobbyFolder(Workspace:FindFirstChild(folderName))
end

Workspace.ChildAdded:Connect(function(child)
	if child.Name == LobbyCrateData.LegacyModelName then
		task.defer(connectLobbyCrate, child)
		return
	end

	if table.find(LobbyCrateData.FolderNames, child.Name) then
		task.defer(watchLobbyFolder, child)
	end
end)

-- connect player added event
Players.PlayerAdded:Connect(setupPlayer)

task.spawn(function()
	while true do
		for _, player in ipairs(Players:GetPlayers()) do
			local userData = player:FindFirstChild("UserData")
			if not userData then continue end

			local timersFolder = ensureLobbyCrateTimers(userData)
			for _, crateId in ipairs(LobbyCrateData.Order) do
				local timerValue = timersFolder:FindFirstChild(crateId)
				if isNumericValue(timerValue) and timerValue.Value > 0 then
					timerValue.Value = math.max(0, timerValue.Value - 1)
				end
			end
			syncLegacyLobbyTimer(userData, timersFolder)

			-- increment playtime
			local stats = userData:FindFirstChild("Statistics")
			if stats then
				local playTime = stats:FindFirstChild("TimePlaying")
				if playTime then
					playTime.Value += 1
				end
			end
		end

		task.wait(1)
	end
end)

return {}
