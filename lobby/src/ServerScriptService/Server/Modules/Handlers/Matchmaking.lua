------------------//SERVICES
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players: Players = game:GetService("Players")
local TeleportService: TeleportService = game:GetService("TeleportService")
local ServerStorage: ServerStorage = game:GetService("ServerStorage")
local MemoryStoreService: MemoryStoreService = game:GetService("MemoryStoreService")

------------------//CONSTANTS
local PVP_QUEUE_KEY: string = "PVPQueue"

local TELEPORT_IDS = {
	["Tutorial"] = 85841322739304,
	["Frosty Peaks"] = 74693752415649,
	["Jungle"] = 100446623326294,
	["Wild West"] = 130499453325606,
	["Toyland"] = 119232273357893,
}

local PVP_IDS = {
	["Frosty Peaks"] = 135072435156585,
	["Jungle"] = 80721907443358,
	["Wild West"] = 88229996824169,
	["Toyland"] = 137821835172386,
}

local SQUAD_SIZES = {
	["Solo"] = 1,
	["Duos"] = 2,
	["Trios"] = 3,
	["Squads"] = 4,
}

local DIFFICULTY_MAP = {
	normal = "Easy",
	easy = "Easy",
	medium = "Medium",
	hard = "Hard",
	impossible = "Impossible",
}

------------------//VARIABLES
local Remotes: Folder = ReplicatedStorage:WaitForChild("Remotes")
local Matchmaking: Folder = Remotes:WaitForChild("Matchmaking")

local PendingPVP: {[number]: boolean} = {}
local LocalQueue: {[number]: {[string]: any}} = {}

------------------//FUNCTIONS
local function normalize_difficulty(difficulty: any): string
	if type(difficulty) ~= "string" then
		return "Easy"
	end

	local normalized = difficulty:lower():gsub("^%s*(.-)%s*$", "%1")
	return DIFFICULTY_MAP[normalized] or "Easy"
end

local function normalize_gamemode(gamemode: any): string
	if type(gamemode) ~= "string" then
		return "Survival"
	end

	local normalized = gamemode:lower():gsub("^%s*(.-)%s*$", "%1")

	if normalized == "pvp" then
		return "PVP"
	end

	if normalized == "endless" then
		return "Endless"
	end

	return "Survival"
end

local function queue_pvp(player: Player, squadSize: number, mapName: string): ()
	local queue = MemoryStoreService:GetQueue(PVP_QUEUE_KEY)

	local success, err = pcall(function()
		queue:AddAsync({
			UserId = player.UserId,
			SquadSize = squadSize,
			Map = mapName,
		}, 60)
	end)

	if success then
		PendingPVP[player.UserId] = true
		LocalQueue[player.UserId] = {
			UserId = player.UserId,
			SquadSize = squadSize,
			Map = mapName,
		}
		print("Queued Player", player.Name)
	else
		warn("Failed to queue:", err)
		Remotes.Notification.SendNotification:FireClient(player, "[!] Failed to join the matchmaking queue. Try again later.", "Error")
	end
end

local function try_match_pvp(player: Player, squadSize: number, mapName: string, timeout: number?): {[string]: any}?
	timeout = timeout or 60

	local startTime = tick()
	local queue = MemoryStoreService:GetQueue(PVP_QUEUE_KEY, 0)

	while tick() - startTime < timeout do
		if not PendingPVP[player.UserId] then
			return nil
		end

		local ok, packed = pcall(function()
			return table.pack(queue:ReadAsync(1, false, 1))
		end)

		if not ok then
			warn("Error accessing queue for", player.Name)
			Matchmaking.ClientSearching:FireClient(player, "Search failed.")
			return nil
		end

		local items = packed[1]
		local readId = packed[2]

		if items and #items > 0 and readId then
			local entry = items[1]

			if entry and entry.UserId and entry.UserId ~= player.UserId and PendingPVP[entry.UserId] then
				local removeOk, removeErr = pcall(function()
					queue:RemoveAsync(readId)
				end)

				if not removeOk then
					warn("Failed to remove queue item:", tostring(removeErr))
				else
					Remotes.Notification.SendNotification:FireClient(player, "[!] Match found!", "Success")
					PendingPVP[entry.UserId] = nil
					print("Matched Player", player.Name, "with", entry.UserId)
					return entry
				end
			end
		end

		task.wait(1)
	end

	Matchmaking.ClientSearching:FireClient(player, "Search failed.")
	Remotes.Notification.SendNotification:FireClient(player, "[!] No opponents found. Matchmaking timed out.", "Error")
	return nil
end

local function user_data_to_table(folder: Instance?): {[string]: any}
	local data: {[string]: any} = {}

	if not folder then
		return data
	end

	local children = folder:GetChildren()
	for i = 1, #children do
		local obj = children[i]

		if obj:IsA("Folder") then
			data[obj.Name] = user_data_to_table(obj)
		elseif obj:IsA("ValueBase") then
			data[obj.Name] = obj.Value
		end
	end

	return data
end

local function get_squad_name(squad: any): string
	if type(squad) ~= "string" then
		return "Solo"
	end

	local normalized = squad:lower():gsub("%s+", ""):gsub("[%p%d]", "")

	local squadMap = {
		solo = "Solo",
		solos = "Solo",
		duo = "Duos",
		duos = "Duos",
		trio = "Trios",
		trios = "Trios",
		squad = "Squads",
		squads = "Squads",
	}

	return squadMap[normalized]
		or (normalized:find("duo") and "Duos")
		or (normalized:find("trio") and "Trios")
		or (normalized:find("squad") and "Squads")
		or "Solo"
end

local function get_party_info_from_player(player: Player): {[string]: any}?
	local inParty = player:GetAttribute("inParty")
	local leaderName = player:GetAttribute("PartyLeader")

	if not inParty or not leaderName then
		return nil
	end

	local partiesFolder = ServerStorage:FindFirstChild("Parties")
	local partyFolder = partiesFolder and partiesFolder:FindFirstChild(leaderName)

	if partyFolder and partyFolder:FindFirstChild("Members") then
		local members = {}
		local leader = Players:FindFirstChild(leaderName)

		if leader then
			members[#members + 1] = leader
		end

		local partyMembers = partyFolder.Members:GetChildren()
		for i = 1, #partyMembers do
			local memberValue = partyMembers[i]
			local memberPlayer = memberValue.Value

			if memberPlayer and memberPlayer ~= leader and memberPlayer.Parent == Players then
				members[#members + 1] = memberPlayer
			end
		end

		return {
			leader = leader,
			members = members,
		}
	end

	return {
		leader = player,
		members = {player},
	}
end

local function safe_reserve_server(placeId: number): string?
	for _ = 1, 3 do
		local success, code = pcall(function()
			return TeleportService:ReserveServer(placeId)
		end)

		if success and code then
			return code
		end

		task.wait(1)
	end

	return nil
end

local function teleport_players(playerList: {Player}, placeId: number?, teleportData: {[string]: any}): ()
	if not placeId then
		for i = 1, #playerList do
			local player = playerList[i]
			Remotes.Notification.SendNotification:FireClient(player, "[!] Failed to join match. Try again later.", "Error")
		end
		return
	end

	local code = safe_reserve_server(placeId)
	if not code then
		for i = 1, #playerList do
			local player = playerList[i]
			Remotes.Notification.SendNotification:FireClient(player, "[!] Failed to join match. Try again later.", "Error")
		end
		return
	end

	for i = 1, #playerList do
		local player = playerList[i]
		if player and player.Parent == Players then
			Remotes.Game.ShowLoadingScreen:FireClient(player)
		end
	end

	pcall(function()
		TeleportService:TeleportToPrivateServer(placeId, code, playerList, nil, teleportData)
	end)
end

------------------//MAIN FUNCTIONS
local function begin_matchmaking(player: Player, data: {[string]: any}): ()
	warn("--------------------------------------------------------")

	if not player or not player.Parent then
		return
	end

	local gamemode = normalize_gamemode(data.Gamemode)
	local difficulty = normalize_difficulty(data.Difficulty)
	local squadCanonical = get_squad_name(data.Squad)
	local desiredSize = SQUAD_SIZES[squadCanonical] or 1
	local mapName = data.Map

	if gamemode ~= "PVP" and squadCanonical == "Solo" then
		if player:GetAttribute("inParty") then
			Remotes.Notification.SendNotification:FireClient(player, "[!] Leave your party to play solo.", "Error")
			return
		end

		Matchmaking.ClientSearching:FireClient(player, "Found a match!")
		task.wait(math.random(1, 2))

		local placeId = TELEPORT_IDS[mapName]
		if placeId then
			local teleportData = {
				Player = player.UserId,
				Gamemode = gamemode,
				Difficulty = difficulty,
				Squad = "Solo",
				Map = mapName,
				UserData = user_data_to_table(player:FindFirstChild("UserData")),
			}

			teleport_players({player}, placeId, teleportData)
		end

		return
	end

	if gamemode == "PVP" then
		Matchmaking.ClientSearching:FireClient(player, "Searching Opponent...")
		queue_pvp(player, desiredSize, mapName)

		local opponentData = try_match_pvp(player, desiredSize, mapName)
		if opponentData then
			local opponentPlayer = Players:GetPlayerByUserId(opponentData.UserId)

			if opponentPlayer then
				local teleportData = {
					Leader = player.UserId,
					Members = {player.UserId, opponentData.UserId},
					Gamemode = "PVP",
					Difficulty = difficulty,
					Squad = "Duos",
					Map = mapName,
					UserData = user_data_to_table(player:FindFirstChild("UserData")),
				}

				teleport_players({player, opponentPlayer}, PVP_IDS[mapName], teleportData)
			end
		end

		return
	end

	local placeId = TELEPORT_IDS[mapName]
	local partyInfo = get_party_info_from_player(player)
	local membersList = (partyInfo and partyInfo.members) or {player}

	if #membersList == desiredSize then
		local teleportData = {
			Leader = player.UserId,
			Members = {},
			Gamemode = gamemode,
			Difficulty = difficulty,
			Squad = squadCanonical,
			Map = mapName,
			UserData = user_data_to_table(player:FindFirstChild("UserData")),
		}

		for i = 1, #membersList do
			teleportData.Members[i] = membersList[i].UserId
		end

		for i = 1, #membersList do
			Matchmaking.ClientSearching:FireClient(membersList[i], "Joining Match...")
		end

		teleport_players(membersList, placeId, teleportData)
	else
		Remotes.Notification.SendNotification:FireClient(player, "[!] Party size mismatch.", "Error")
	end
end

------------------//INIT
Matchmaking.RequestQueue.OnServerEvent:Connect(begin_matchmaking)

Matchmaking.CancelMatchmaking.OnServerEvent:Connect(function(player: Player)
	if PendingPVP[player.UserId] then
		PendingPVP[player.UserId] = nil
		LocalQueue[player.UserId] = nil
	end

	Matchmaking.ClientSearching:FireClient(player, "Cancelled")
end)

Matchmaking.GetPlayerCount.OnServerInvoke = function(player: Player)
	return {
		Survival = 0,
		PVP = 0,
	}
end

return {}
