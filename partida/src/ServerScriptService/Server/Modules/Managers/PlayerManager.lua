------------------//SERVICES
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService: TeleportService = game:GetService("TeleportService")

------------------//CONSTANTS
local LOBBY_PLACE_ID = 77035582123606
local STARTING_CASH = 300

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

local MAX_RETRIES = 5
local RETRY_WAIT = 0.1

------------------//VARIABLES
local remotes = ReplicatedStorage:FindFirstChild("Remotes")

local clientLoading = remotes:FindFirstChild("ClientLoading")
local clientLoadedEvent = clientLoading:FindFirstChild("ClientLoaded")

local requestGameStartEvent = remotes:FindFirstChild("Game"):FindFirstChild("RequestGameStart")

local isCinematic = true
local playersLoaded = {}

------------------//FUNCTIONS
local function find_index(list: {string}, value: string): number
	for i = 1, #list do
		if list[i] == value then
			return i
		end
	end
	return 0
end

local function normalizeDifficulty(difficulty: any): string
	if typeof(difficulty) ~= "string" then
		return DIFFICULTY_ORDER[1]
	end

	return DIFFICULTY_ALIASES[difficulty]
		or DIFFICULTY_ALIASES[difficulty:lower()]
		or DIFFICULTY_ORDER[1]
end

local function normalizeMap(mapName: any): string
	if typeof(mapName) ~= "string" then
		return MAP_ORDER[1]
	end

	if find_index(MAP_ORDER, mapName) > 0 then
		return mapName
	end

	return MAP_ORDER[1]
end

local function getUserData(player: Player): Folder
	local userData
	repeat
		userData = player:FindFirstChild("UserData")
		if not userData then
			task.wait(0.1)
		end
	until userData

	return userData :: Folder
end

local function ensureMapFolder(userData: Folder): Folder
	local mapFolder = userData:FindFirstChild("Map")
	if not mapFolder then
		mapFolder = Instance.new("Folder")
		mapFolder.Name = "Map"
		mapFolder.Parent = userData
	end
	return mapFolder :: Folder
end

local function ensureStringValue(parent: Instance, name: string, defaultValue: string): StringValue
	local v = parent:FindFirstChild(name)
	if v and not v:IsA("StringValue") then
		v:Destroy()
		v = nil
	end

	if not v then
		v = Instance.new("StringValue")
		v.Name = name
		v.Value = defaultValue
		v.Parent = parent
	end
	return v :: StringValue
end

local function getCurrentMapData(player: Player, teleportData: any?): (string, string)
	if teleportData then
		local mapName = teleportData.Map
		local difficulty = teleportData.Difficulty

		if mapName or difficulty then
			return normalizeMap(mapName), normalizeDifficulty(difficulty)
		end
	end

	local userData = getUserData(player)
	local mapFolder = userData:FindFirstChild("Map")

	if mapFolder then
		local lvl = mapFolder:FindFirstChild("Level")
		local diff = mapFolder:FindFirstChild("Difficulty")
		if lvl and lvl:IsA("StringValue") and diff and diff:IsA("StringValue") then
			return normalizeMap(lvl.Value), normalizeDifficulty(diff.Value)
		end
	end

	if teleportData and teleportData.UserData and teleportData.UserData.Map then
		return normalizeMap(teleportData.UserData.Map.Level), normalizeDifficulty(teleportData.UserData.Map.Difficulty)
	end

	return MAP_ORDER[1], DIFFICULTY_ORDER[1]
end

local function getStoredMapData(player: Player, teleportData: any?): (string, string)
	local userData = getUserData(player)
	local mapFolder = userData:FindFirstChild("Map")

	if mapFolder then
		local lvl = mapFolder:FindFirstChild("Level")
		local diff = mapFolder:FindFirstChild("Difficulty")
		if lvl and lvl:IsA("StringValue") and diff and diff:IsA("StringValue") then
			return normalizeMap(lvl.Value), normalizeDifficulty(diff.Value)
		end
	end

	if teleportData and teleportData.UserData and teleportData.UserData.Map then
		return normalizeMap(teleportData.UserData.Map.Level), normalizeDifficulty(teleportData.UserData.Map.Difficulty)
	end

	return MAP_ORDER[1], DIFFICULTY_ORDER[1]
end

local function setPlayerMapData(player: Player, mapName: string, difficulty: string): ()
	local userData = getUserData(player)
	local mapFolder = ensureMapFolder(userData)

	local lvl = ensureStringValue(mapFolder, "Level", MAP_ORDER[1])
	local diff = ensureStringValue(mapFolder, "Difficulty", DIFFICULTY_ORDER[1])

	lvl.Value = normalizeMap(mapName)
	diff.Value = normalizeDifficulty(difficulty)
end

local function computeNextMapDifficulty(currentMap: string, currentDifficulty: string): (string, string, boolean)
	local mapIndex = find_index(MAP_ORDER, currentMap)
	if mapIndex == 0 then
		mapIndex = 1
	end

	local diffIndex = find_index(DIFFICULTY_ORDER, currentDifficulty)
	if diffIndex == 0 then
		diffIndex = 1
	end

	local nextMapIndex = mapIndex
	local nextDiffIndex = diffIndex

	if diffIndex < #DIFFICULTY_ORDER then
		nextDiffIndex += 1
	else
		if mapIndex < #MAP_ORDER then
			nextMapIndex += 1
			nextDiffIndex = 1
		end
	end

	local advanced = nextMapIndex ~= mapIndex or nextDiffIndex ~= diffIndex
	return MAP_ORDER[nextMapIndex], DIFFICULTY_ORDER[nextDiffIndex], advanced
end

local function applyWinProgression(player: Player, teleportData: any?): (string, string, string, string, boolean)
	local currentMap, currentDifficulty = getCurrentMapData(player, teleportData)
	local nextMap, nextDifficulty, advanced = computeNextMapDifficulty(currentMap, currentDifficulty)
	setPlayerMapData(player, nextMap, nextDifficulty)
	return nextMap, nextDifficulty, currentMap, currentDifficulty, advanced
end

local function setupTempCash(player: Player): ()
	player:SetAttribute("TempCash", STARTING_CASH)
end

local function PrintTableRecursive(tbl, indent)
	indent = indent or ""
	for key, value in pairs(tbl) do
		if typeof(value) == "table" then
			print(indent .. tostring(key) .. ": {")
			PrintTableRecursive(value, indent .. "  ")
			print(indent .. "}")
		else
			print(indent .. tostring(key) .. ": " .. tostring(value))
		end
	end
end

local function checkIfAllPlayersLoaded(difficulty, gamemode)
	local list = Players:GetPlayers()
	for i = 1, #list do
		local plr = list[i]
		if not playersLoaded[plr] then
			return false
		end
	end

	print("[🛡️] All clients loaded, starting game.")
	requestGameStartEvent:Fire(difficulty, gamemode)

	if isCinematic then
		remotes.Game.StartCinematic:FireAllClients()
	end

	return true
end

local function setupPlayer(player: Player)
	local spawnPosition = workspace:FindFirstChild("SpawnPos")
	if not spawnPosition then return end

	local character = player.Character
	if not character then return end

	local desc = character:GetDescendants()
	for i = 1, #desc do
		local inst = desc[i]
		if inst:IsA("BasePart") then
			inst.CollisionGroup = "Players"
		end
	end

	local joinData = player:GetJoinData()
	local teleportData = joinData.TeleportData

	if teleportData then
		teleportData.Difficulty = normalizeDifficulty(teleportData.Difficulty)

		PrintTableRecursive(teleportData)

		if teleportData.UserData and teleportData.UserData.Quests then
			for category, questData in pairs(teleportData.UserData.Quests) do
				if questData.Active then
					for questName, questInfo in pairs(questData.Active) do
						local progress = questInfo.Progress or 0
						local attributeName = string.format("Quest_%s_%s", category, questName)
						attributeName = attributeName:gsub("%s+", "_"):gsub("[^%w_]", "")
						player:SetAttribute(attributeName, progress)
					end
				end
			end
		end

		if teleportData.Gamemode ~= "PVP" then
			local mapName, mapDiff = getCurrentMapData(player, teleportData)
			setPlayerMapData(player, mapName, mapDiff)
		end
	end

	character:SetPrimaryPartCFrame(spawnPosition.CFrame)
	setupTempCash(player)

	if not teleportData then
		teleportData = {}
		teleportData.Difficulty = "Easy"
		teleportData.Gamemode = "endless"
	end

	checkIfAllPlayersLoaded(teleportData.Difficulty, teleportData.Gamemode)
end

------------------//MAIN FUNCTIONS
local function gatherQuestAttributes(player: Player): {}
	local attrs = player:GetAttributes()
	if not attrs or next(attrs) == nil then
		return {}
	end

	local out = {}
	for name, value in pairs(attrs) do
		if string.sub(name, 1, 6) == "Quest_" then
			local category, rest = string.match(name, "^Quest_([^_]+)_(.+)$")
			if category and rest then
				category = category:gsub("^%s+", ""):gsub("%s+$", "")
				local questName = rest:gsub("^%s+", ""):gsub("%s+$", "")
				questName = questName:gsub("_", " ")
				out[category] = out[category] or {}
				out[category][questName] = value
			end
		end
	end

	return out
end

------------------//INIT
remotes.Game.ReturnToLobby.OnServerEvent:Connect(function(player: Player, didWin: boolean?)
	local questData = {}
	for i = 1, MAX_RETRIES do
		questData = gatherQuestAttributes(player)
		if next(questData) ~= nil then
			break
		end
		if i < MAX_RETRIES then
			task.wait(RETRY_WAIT)
		end
	end

	local joinData = player:GetJoinData()
	local teleportDataIn = joinData.TeleportData

	local serverRecordedWin = player:GetAttribute("MatchWon") == true
	local wonMatch = didWin == true and serverRecordedWin
	local isPVP = teleportDataIn and teleportDataIn.Gamemode == "PVP"
	local canAdvanceProgression = wonMatch and not isPVP
	local mapLevel, mapDifficulty

	if isPVP then
		mapLevel, mapDifficulty = getStoredMapData(player, teleportDataIn)
	else
		mapLevel, mapDifficulty = getCurrentMapData(player, teleportDataIn)
	end

	local clearedMap, clearedDifficulty = mapLevel, mapDifficulty
	local advanced = false

	if canAdvanceProgression then
		if teleportDataIn and teleportDataIn.Map == "Tutorial" then
			clearedMap = "Tutorial"
			clearedDifficulty = normalizeDifficulty(teleportDataIn.Difficulty)
			mapLevel = MAP_ORDER[1]
			mapDifficulty = DIFFICULTY_ORDER[1]
			advanced = true
			setPlayerMapData(player, mapLevel, mapDifficulty)
		else
			mapLevel, mapDifficulty, clearedMap, clearedDifficulty, advanced = applyWinProgression(player, teleportDataIn)
		end
	else
		if not isPVP then
			setPlayerMapData(player, mapLevel, mapDifficulty)
		end
	end

	local teleportData = {
		Result = wonMatch and "Won" or "Lost",
		Progression = {
			Won = wonMatch,
			CanAdvance = canAdvanceProgression,
			Advanced = advanced,
			ClearedMap = clearedMap,
			ClearedDifficulty = clearedDifficulty,
			NextMap = mapLevel,
			NextDifficulty = mapDifficulty,
		},
		UserData = {
			Quests = questData,
			Map = {
				Level = mapLevel,
				Difficulty = mapDifficulty,
			},
		},
	}

	TeleportService:Teleport(LOBBY_PLACE_ID, player, teleportData)
end)

clientLoadedEvent.OnServerEvent:Connect(function(player: Player)
	playersLoaded[player] = true
	setupPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	playersLoaded[player] = nil
end)

return {}
