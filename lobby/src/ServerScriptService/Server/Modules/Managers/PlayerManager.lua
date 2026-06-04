-- services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local PhysicsService = game:GetService("PhysicsService")

local Remotes = game.ReplicatedStorage:WaitForChild("Remotes")
local GameRemotes = Remotes:WaitForChild("Game")

-- crate touch part reference
local CrateTouch = workspace.Crate.Crate

-- modules
local LevelData = require(game.ReplicatedStorage.Modules.StoredData.LevelData)
local QuestPool = require(game.ReplicatedStorage.Modules.StoredData.QuestsData)

-- config
local MAX_LEVEL = 50
local MAP_ORDER = {
	"Frosty Peaks",
	"Jungle",
	"Wild West",
	"Toyland",
}

local DIFFICULTY_ORDER = {
	"Easy",
	"Medium",
	"Hard",
	"Impossible",
}

local DIFFICULTY_ALIASES = {
	Normal = "Easy",
	easy = "Easy",
	medium = "Medium",
	hard = "Hard",
	impossible = "Impossible",
}

-- time constants in seconds
local ONE_DAY = 86400
local ONE_WEEK = 604800
local ONE_MONTH = 2592000
local CRATE_COOLDOWN = 14400

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

local function findIndex(list: {string}, value: string): number
	for index = 1, #list do
		if list[index] == value then
			return index
		end
	end
	return 0
end

local function normalizeMap(mapName): string
	if type(mapName) ~= "string" then
		return MAP_ORDER[1]
	end

	if findIndex(MAP_ORDER, mapName) > 0 then
		return mapName
	end

	return MAP_ORDER[1]
end

local function normalizeDifficulty(difficulty): string
	if type(difficulty) ~= "string" then
		return DIFFICULTY_ORDER[1]
	end

	return DIFFICULTY_ALIASES[difficulty]
		or DIFFICULTY_ALIASES[difficulty:lower()]
		or DIFFICULTY_ORDER[1]
end

local function ensureFolder(parent: Instance, name: string): Folder
	local folder = parent:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
	end

	return folder :: Folder
end

local function ensureStringValue(parent: Instance, name: string, defaultValue: string): StringValue
	local value = parent:FindFirstChild(name)
	if value and not value:IsA("StringValue") then
		value:Destroy()
		value = nil
	end

	if not value then
		value = Instance.new("StringValue")
		value.Name = name
		value.Value = defaultValue
		value.Parent = parent
	end

	return value :: StringValue
end

local function setMapProgress(player: Player, mapName, difficulty): ()
	local userData = getUserData(player)
	local mapFolder = ensureFolder(userData, "Map")
	local levelValue = ensureStringValue(mapFolder, "Level", MAP_ORDER[1])
	local difficultyValue = ensureStringValue(mapFolder, "Difficulty", DIFFICULTY_ORDER[1])

	levelValue.Value = normalizeMap(mapName)
	difficultyValue.Value = normalizeDifficulty(difficulty)
	player:SetAttribute("MapLevel", levelValue.Value)
	player:SetAttribute("Difficulty", difficultyValue.Value)
end

local function getReturnedMapData(teleportData)
	if not teleportData or type(teleportData) ~= "table" then
		return nil, nil
	end

	if teleportData.UserData and teleportData.UserData.Map then
		return teleportData.UserData.Map.Level, teleportData.UserData.Map.Difficulty
	end

	if teleportData.Progression then
		return teleportData.Progression.NextMap, teleportData.Progression.NextDifficulty
	end

	return nil, nil
end

local function applyMapProgressionData(player: Player, teleportData): ()
	local mapName, difficulty = getReturnedMapData(teleportData)

	if mapName or difficulty then
		setMapProgress(player, mapName, difficulty)
	else
		local userData = getUserData(player)
		local mapFolder = userData:FindFirstChild("Map")
		if mapFolder then
			local levelValue = mapFolder:FindFirstChild("Level")
			local difficultyValue = mapFolder:FindFirstChild("Difficulty")
			setMapProgress(
				player,
				levelValue and levelValue:IsA("StringValue") and levelValue.Value or MAP_ORDER[1],
				difficultyValue and difficultyValue:IsA("StringValue") and difficultyValue.Value or DIFFICULTY_ORDER[1]
			)
		else
			setMapProgress(player, MAP_ORDER[1], DIFFICULTY_ORDER[1])
		end
	end

	if teleportData
		and teleportData.Progression
		and teleportData.Progression.Won == true
		and teleportData.Progression.CanAdvance ~= false then
		local progression = teleportData.Progression
		local nextMap = normalizeMap(progression.NextMap)
		local nextDifficulty = normalizeDifficulty(progression.NextDifficulty)

		if progression.Advanced == true then
			Remotes.Notification.SendNotification:FireClient(
				player,
				"Mission cleared! Next: " .. nextMap .. " - " .. nextDifficulty,
				"Success"
			)
		else
			Remotes.Notification.SendNotification:FireClient(player, "Final mission cleared!", "Success")
		end
	end
end

local function setCompletedTutorial(player: Player, completed: boolean)
	if not completed then
		return
	end

	local userData = getUserData(player)
	local completedTutorial = userData:FindFirstChild("CompletedTutorial")
	if not completedTutorial then
		completedTutorial = Instance.new("BoolValue")
		completedTutorial.Name = "CompletedTutorial"
		completedTutorial.Parent = userData
	end

	if completedTutorial:IsA("BoolValue") then
		completedTutorial.Value = true
	end

	local onboarding = userData:FindFirstChild("Onboarding")
	if onboarding then
		local onboardingCompleted = onboarding:FindFirstChild("Completed")
		if onboardingCompleted and onboardingCompleted:IsA("BoolValue") then
			onboardingCompleted.Value = true
		end

		local stage = onboarding:FindFirstChild("Stage")
		if stage and stage:IsA("StringValue") then
			stage.Value = "completed"
		end
	end
end

local function teleportDataCompletedTutorial(teleportData): boolean
	if not teleportData then
		return false
	end

	if teleportData.CompletedTutorial == true or teleportData.TutorialCompleted == true then
		return true
	end

	local onboarding = teleportData.Onboarding
	if type(onboarding) == "table" and (onboarding.Completed == true or onboarding.Stage == "completed") then
		return true
	end

	local userData = teleportData.UserData
	if type(userData) ~= "table" then
		return false
	end

	if userData.CompletedTutorial == true or userData.TutorialCompleted == true then
		return true
	end

	onboarding = userData.Onboarding
	return type(onboarding) == "table" and (onboarding.Completed == true or onboarding.Stage == "completed")
end

local function applyTutorialData(player: Player, teleportData)
	setCompletedTutorial(player, teleportDataCompletedTutorial(teleportData))
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
		applyTutorialData(Player, teleportData)
		applyMapProgressionData(Player, teleportData)
		applyQuestData(Player, teleportData)
	else
		applyMapProgressionData(Player, nil)
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
	Character:PivotTo(workspace.SpawnPos.CFrame)

	local UserData = Player:WaitForChild("UserData", 5)
	if not UserData then return end

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
local TOUCH_COOLDOWN = 3
local recentTouches = {}

CrateTouch.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end

	-- debounce check
	if recentTouches[player] then return end
	recentTouches[player] = true
	task.delay(TOUCH_COOLDOWN, function()
		recentTouches[player] = nil
	end)

	local userData = player:FindFirstChild("UserData")
	if not userData then return end

	local timer = userData:FindFirstChild("RemainingTimer")
	local money = userData:FindFirstChild("Money")
	if not timer or not money then return end

	-- check if crate is ready to claim
	if timer.Value <= 0 then
		local reward = 1200
		money.Value += reward
		timer.Value = CRATE_COOLDOWN
		game.ReplicatedStorage.Remotes.Notification.SendNotification:FireClient(player, "You claimed the golden crate and got $" .. reward, "Success")
		return
	end
end)

-- connect player added event
Players.PlayerAdded:Connect(setupPlayer)

local skipTutorial = GameRemotes:FindFirstChild("SkipTutorial")
if not skipTutorial then
	skipTutorial = Instance.new("RemoteEvent")
	skipTutorial.Name = "SkipTutorial"
	skipTutorial.Parent = GameRemotes
end

skipTutorial.OnServerEvent:Connect(function(player)
	setCompletedTutorial(player, true)
	game.ReplicatedStorage.Remotes.Notification.SendNotification:FireClient(player, "Tutorial skipped. Daily Rewards unlocked.", "Success")
end)

task.spawn(function()
	while true do
		for _, player in ipairs(Players:GetPlayers()) do
			local userData = player:FindFirstChild("UserData")
			if not userData then continue end

			-- countdown remaining timer
			local remaining = userData:FindFirstChild("RemainingTimer")
			if remaining and remaining.Value > 0 then
				remaining.Value -= 1
			end

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
