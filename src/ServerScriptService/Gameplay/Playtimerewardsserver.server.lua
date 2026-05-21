-- PlaytimeRewardsServer DEBUG (Script -> ServerScriptService)
-- MODO DE TESTE: troque DEBUG_MODE para false antes de publicar!
--
-- COMANDOS DE CHAT (apenas admins):
--   /testreward 1   -> dispara o milestone 1 manualmente
--   /testreward all -> dispara TODOS os milestones em sequencia
--   /resetrewards   -> reseta os milestones (pode testar de novo)
--   /rewardstatus   -> mostra no Output o tempo de sessao e status

local Players    = game:GetService("Players")
local RS         = game:GetService("ReplicatedStorage")
local SS         = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local DataStoreModule       = require(SS:WaitForChild("Modules").MainDataModule)
local PlaytimeRewardsRemote = RS:WaitForChild("Remotes").PlaytimeRewardsRemote

-- CONFIG
local DEBUG_MODE = false
local ADMIN_IDS  = {
	-- coloque seu UserId aqui: ex: 123456789
}

local function milestoneTime(realSeconds)
	if DEBUG_MODE then return math.max(realSeconds / 60, 5) end
	return realSeconds
end

local MILESTONES = {
	{ Time = milestoneTime(5*60),    Label = "5 Minutes",  Rewards = { Ingredients = 1_500,   Food = 500,     Cash = 0,         GourmetFood = 0     } },
	{ Time = milestoneTime(15*60),   Label = "15 Minutes", Rewards = { Ingredients = 8_000,  Food = 3_000,     Cash = 0,    GourmetFood = 0     } },
	{ Time = milestoneTime(30*60),   Label = "30 Minutes", Rewards = { Ingredients = 20_000,  Food = 10_000,    Cash = 1_000,    GourmetFood = 50    } },
	{ Time = milestoneTime(60*60),   Label = "1 Hour",     Rewards = { Ingredients = 200_000, Food = 500_000,    Cash = 250_000,   GourmetFood = 250   } },
	{ Time = milestoneTime(2*3600),  Label = "2 Hours",    Rewards = { Ingredients = 0,       Food = 2_000_000,  Cash = 1_000_000, GourmetFood = 1_000 } },
	{ Time = milestoneTime(4*3600),  Label = "4 Hours",    Rewards = { Ingredients = 0,       Food = 10_000_000, Cash = 5_000_000, GourmetFood = 5_000 } },
}

if DEBUG_MODE then
	print("[PlaytimeRewards] DEBUG MODE - Tempos:")
	for i, m in ipairs(MILESTONES) do
		print(string.format("  [%d] %s -> %.0fs", i, m.Label, m.Time))
	end
end

local POLL_INTERVAL = DEBUG_MODE and 5 or 30
local SessionData   = {}

local function ApplyRewards(player, rewards, dataStore)
	if (rewards.Ingredients or 0) > 0 then
		local o = dataStore.playerstats:FindFirstChild("Ingredients")
		if o then o.Value += rewards.Ingredients end
	end
	if (rewards.Food or 0) > 0 then
		local o = dataStore.LeaderStatValues:FindFirstChild("Food")
		if o then o.Value += rewards.Food end
	end
	if (rewards.Cash or 0) > 0 then
		local o = dataStore.LeaderStatValues:FindFirstChild("Cash")
		if o then o.Value += rewards.Cash end
	end
	if (rewards.GourmetFood or 0) > 0 then
		local o = dataStore.playerstats:FindFirstChild("Gourmet Food")
		if o then o.Value += rewards.GourmetFood end
	end
end

local function BuildSummary(rewards)
	local parts = {}
	if (rewards.Ingredients or 0) > 0 then table.insert(parts, rewards.Ingredients .. " Ingredientes")  end
	if (rewards.Food        or 0) > 0 then table.insert(parts, rewards.Food        .. " Food")           end
	if (rewards.Cash        or 0) > 0 then table.insert(parts, "$" .. rewards.Cash .. " Cash")           end
	if (rewards.GourmetFood or 0) > 0 then table.insert(parts, rewards.GourmetFood .. " Gourmet Food")   end
	return table.concat(parts, " + ")
end

local function FireMilestone(player, milestone)
	local ds = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, player.UserId)
	if not ds or ds.State ~= true then
		warn("[PlaytimeRewards] DataStore indisponivel para " .. player.Name)
		return
	end
	local ok, err = pcall(ApplyRewards, player, milestone.Rewards, ds)
	if not ok then warn("[PlaytimeRewards] Erro: " .. tostring(err)) return end

	PlaytimeRewardsRemote:FireClient(player, "MilestoneReached", {
		Label   = milestone.Label,
		Summary = BuildSummary(milestone.Rewards),
		Rewards = milestone.Rewards,
	})
	print(string.format("[PlaytimeRewards] '%s' -> %s: %s",
		milestone.Label, player.Name, BuildSummary(milestone.Rewards)))
end

local function IsAdmin(player)
	for _, id in ipairs(ADMIN_IDS) do
		if player.UserId == id then return true end
	end
	return RunService:IsStudio() and #ADMIN_IDS == 0
end

local function StartTrackingPlayer(player)
	local startTime = os.time()
	SessionData[player.UserId] = {
		StartTime          = startTime,
		SecondsAccumulated = 0,
		MilestonesGiven    = {},
	}

	-- Envia ao cliente os tempos exatos (ja com DEBUG_MODE aplicado)
	task.delay(6, function()
		if not (player and player.Parent) then return end
		local milestoneData = {}
		for _, m in ipairs(MILESTONES) do
			table.insert(milestoneData, { Time = m.Time, Label = m.Label })
		end
		PlaytimeRewardsRemote:FireClient(player, "Init", {
			StartTime  = startTime,
			Milestones = milestoneData,
		})
	end)

	task.spawn(function()
		while player and player.Parent do
			task.wait(POLL_INTERVAL)
			if not (player and player.Parent) then break end

			local data = SessionData[player.UserId]
			if not data then break end

			local ds = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, player.UserId)
			if not ds or ds.State ~= true then continue end

			data.SecondsAccumulated += POLL_INTERVAL
			local sessionSec = os.time() - data.StartTime
			ds.Value.TotalTimePlayed = (ds.Value.TotalTimePlayed or 0) + POLL_INTERVAL

			if DEBUG_MODE then
				print(string.format("[PlaytimeRewards] %s sessao=%.0fs total=%.0fs",
					player.Name, sessionSec, ds.Value.TotalTimePlayed))
			end

			for _, m in ipairs(MILESTONES) do
				if sessionSec >= m.Time and not data.MilestonesGiven[m.Label] then
					data.MilestonesGiven[m.Label] = true
					FireMilestone(player, m)
				end
			end
		end
	end)
end

-- CONEXOES
Players.PlayerAdded:Connect(function(player)
	StartTrackingPlayer(player)

	player.Chatted:Connect(function(msg)
		if not IsAdmin(player) then return end
		local args = msg:lower():split(" ")

		if args[1] == "/testreward" then
			local t = args[2]
			if t == "all" then
				for _, m in ipairs(MILESTONES) do FireMilestone(player, m) task.wait(6) end
			elseif tonumber(t) then
				local m = MILESTONES[tonumber(t)]
				if m then FireMilestone(player, m)
				else warn("[PlaytimeRewards] Indice invalido: " .. t) end
			end

		elseif args[1] == "/resetrewards" then
			local data = SessionData[player.UserId]
			if data then
				data.MilestonesGiven = {}
				data.StartTime       = os.time()
				PlaytimeRewardsRemote:FireClient(player, "Reset", { StartTime = data.StartTime })
				print("[PlaytimeRewards] Resetado para " .. player.Name)
			end

		elseif args[1] == "/rewardstatus" then
			local data = SessionData[player.UserId]
			if not data then return end
			local sec = os.time() - data.StartTime
			print(string.format("[PlaytimeRewards] %s: sessao=%.0fs", player.Name, sec))
			for lbl in pairs(data.MilestonesGiven) do print("  [OK] " .. lbl) end
			for _, m in ipairs(MILESTONES) do
				if not data.MilestonesGiven[m.Label] then
					print(string.format("  Proximo: %s (faltam %.0fs)", m.Label, math.max(0, m.Time - sec)))
					break
				end
			end
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	local data = SessionData[player.UserId]
	if data then
		local ds = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, player.UserId)
		if ds and ds.State == true then
			local elapsed = os.time() - data.StartTime
			ds.Value.TotalTimePlayed = (ds.Value.TotalTimePlayed or 0) + (elapsed - data.SecondsAccumulated)
		end
		SessionData[player.UserId] = nil
	end
end)

for _, p in ipairs(Players:GetPlayers()) do StartTrackingPlayer(p) end