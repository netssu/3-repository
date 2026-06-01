local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local StoredData = Modules:WaitForChild("StoredData")

local WaveCrateData = require(StoredData:WaitForChild("WaveCrateData"))

local NotificationRemote = Remotes:WaitForChild("Notification"):WaitForChild("SendNotification")

local WaveCrateManager = {}

local ActiveDamageBuffs = {}

--[[
	Wave hook options:
	- Fire once per wave from server:
	  ServerScriptService.Signals.WaveCrateDrop:Fire(playerOrPlayersArray, {
		DropChance = 0.35,
		NotifyNoDrop = false,
	  })
	- Or require this module and call:
	  WaveCrateManager.RollDropForPlayer(player, context)
]]

local function getWeightedChoice(weightTable)
	local totalWeight = 0
	for _, value in pairs(weightTable) do
		local weight = tonumber(value)
		if weight and weight > 0 then
			totalWeight += weight
		end
	end

	if totalWeight <= 0 then
		return nil
	end

	local roll = math.random() * totalWeight
	local running = 0

	for key, value in pairs(weightTable) do
		local weight = tonumber(value)
		if weight and weight > 0 then
			running += weight
			if roll <= running then
				return key
			end
		end
	end

	return nil
end

local function getRarityRoll()
	local rarityWeights = {}
	for rarityName, rarityData in pairs(WaveCrateData.Rarities) do
		rarityWeights[rarityName] = rarityData.Weight or 0
	end

	return getWeightedChoice(rarityWeights) or "Common"
end

local function getCrateRoll(rarityName)
	local crateWeights = {}
	for crateName, crateData in pairs(WaveCrateData.Crates) do
		local allowed = crateData.AllowedRarities and crateData.AllowedRarities[rarityName]
		if allowed then
			crateWeights[crateName] = crateData.DropWeight or 0
		end
	end

	local pickedCrate = getWeightedChoice(crateWeights)
	if pickedCrate then
		return pickedCrate
	end

	-- fallback
	for crateName in pairs(WaveCrateData.Crates) do
		return crateName
	end

	return nil
end

local function getEffect(crateName, rarityName)
	local crateData = WaveCrateData.Crates[crateName]
	if not crateData then
		return nil
	end

	local effectsByRarity = crateData.EffectsByRarity or {}
	return effectsByRarity[rarityName] or effectsByRarity.Common
end

local function getEnemyRoots()
	local roots = {}
	local candidateNames = {
		"Enemies",
		"Mobs",
		"Worms",
		"Units",
		"TrackEnemies",
	}

	for _, name in ipairs(candidateNames) do
		local root = Workspace:FindFirstChild(name)
		if root then
			table.insert(roots, root)
		end
	end

	local mapRoot = Workspace:FindFirstChild("Map")
	if mapRoot then
		for _, name in ipairs(candidateNames) do
			local root = mapRoot:FindFirstChild(name)
			if root then
				table.insert(roots, root)
			end
		end
	end

	return roots
end

local function isEnemyModel(model)
	if not model or not model:IsA("Model") then
		return false
	end

	if model:GetAttribute("IsEnemy") == true then
		return true
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		if Players:GetPlayerFromCharacter(model) == nil then
			return true
		end
	end

	local healthValue = model:FindFirstChild("Health", true)
	if healthValue and (healthValue:IsA("IntValue") or healthValue:IsA("NumberValue")) then
		return healthValue.Value > 0
	end

	local healthAttr = model:GetAttribute("Health")
	return type(healthAttr) == "number" and healthAttr > 0
end

local function applyDamageToEnemy(model, damage)
	if damage <= 0 then
		return false
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid:TakeDamage(damage)
		return true
	end

	local healthValue = model:FindFirstChild("Health", true)
	if healthValue and (healthValue:IsA("IntValue") or healthValue:IsA("NumberValue")) then
		healthValue.Value = math.max(0, healthValue.Value - damage)
		return true
	end

	local healthAttr = model:GetAttribute("Health")
	if type(healthAttr) == "number" then
		model:SetAttribute("Health", math.max(0, healthAttr - damage))
		return true
	end

	return false
end

local function applyAirStrike(damage)
	local roots = getEnemyRoots()
	local seenModels = {}
	local hitCount = 0

	for _, root in ipairs(roots) do
		for _, descendant in ipairs(root:GetDescendants()) do
			if descendant:IsA("Model") and not seenModels[descendant] and isEnemyModel(descendant) then
				seenModels[descendant] = true
				if applyDamageToEnemy(descendant, damage) then
					hitCount += 1
				end
			end
		end
	end

	return hitCount
end

local function clearDamageBuff(player)
	ActiveDamageBuffs[player] = nil
	player:SetAttribute("WaveDamageMultiplier", 1)
	player:SetAttribute("WaveDamageBuffExpiresAt", 0)
end

local function applyDamageCrate(player, effect)
	local duration = math.max(1, math.floor(effect.Duration or 20))
	local multiplier = math.max(1, tonumber(effect.Multiplier) or 1.2)
	local version = (ActiveDamageBuffs[player] and ActiveDamageBuffs[player].Version or 0) + 1
	local expiresAt = os.time() + duration

	ActiveDamageBuffs[player] = {
		Multiplier = multiplier,
		ExpiresAt = expiresAt,
		Version = version,
	}

	player:SetAttribute("WaveDamageMultiplier", multiplier)
	player:SetAttribute("WaveDamageBuffExpiresAt", expiresAt)

	NotificationRemote:FireClient(player, string.format("Damage buff ativo: +%d%% por %ds", math.floor((multiplier - 1) * 100), duration), "Success")

	task.delay(duration, function()
		local active = ActiveDamageBuffs[player]
		if not active or active.Version ~= version then
			return
		end

		clearDamageBuff(player)
		NotificationRemote:FireClient(player, "Damage buff acabou.", "Normal")
	end)
end

local function applyCoinCrate(player, effect)
	local userData = player:FindFirstChild("UserData")
	local money = userData and userData:FindFirstChild("Money")
	local coins = math.max(0, math.floor(effect.Coins or 0))
	local lifetime = math.max(1, math.floor(effect.Lifetime or 8))

	if money and coins > 0 then
		money.Value += coins
		NotificationRemote:FireClient(player, string.format("Coin Crate: +$%d", coins), "Success")
	else
		NotificationRemote:FireClient(player, "Coin Crate acionada, mas sem carteira de moedas configurada.", "Error")
	end

	task.delay(lifetime, function()
		if player and player.Parent == Players then
			NotificationRemote:FireClient(player, "Coin Crate expirou.", "Normal")
		end
	end)
end

local function applyAirStrikeCrate(player, effect)
	local damage = math.max(1, math.floor(effect.Damage or 100))
	local hitCount = applyAirStrike(damage)

	NotificationRemote:FireClient(player, string.format("Air Strike: %d de dano em %d inimigos.", damage, hitCount), "Success")
end

local function applyCrateEffect(player, crateName, rarityName)
	local effect = getEffect(crateName, rarityName)
	if not effect then
		return false
	end

	if crateName == "DamageCrate" then
		applyDamageCrate(player, effect)
		return true
	end

	if crateName == "AirStrikeCrate" then
		applyAirStrikeCrate(player, effect)
		return true
	end

	if crateName == "CoinCrate" then
		applyCoinCrate(player, effect)
		return true
	end

	return false
end

function WaveCrateManager.GetWaveDamageMultiplier(player)
	local active = ActiveDamageBuffs[player]
	if not active then
		return 1
	end

	if os.time() >= active.ExpiresAt then
		clearDamageBuff(player)
		return 1
	end

	return active.Multiplier
end

function WaveCrateManager.RollDropForPlayer(player, context)
	if not player or not player:IsA("Player") then
		return nil
	end

	context = context or {}
	local forceDrop = context.ForceDrop == true
	local dropChance = tonumber(context.DropChance) or WaveCrateData.DropChancePerWave or 0.35
	dropChance = math.clamp(dropChance, 0, 1)
	local notifyNoDrop = context.NotifyNoDrop == true

	if not forceDrop and math.random() > dropChance then
		if notifyNoDrop then
			NotificationRemote:FireClient(player, "Sem crate drop nesta wave.", "Normal")
		end
		return nil
	end

	local rarityName = context.Rarity or getRarityRoll()
	local crateName = context.CrateName or getCrateRoll(rarityName)
	local crateData = crateName and WaveCrateData.Crates[crateName]

	if not crateData then
		return nil
	end

	local displayName = crateData.DisplayName or crateName
	NotificationRemote:FireClient(player, string.format("Dropou %s [%s]!", displayName, rarityName), "Success")

	local applied = applyCrateEffect(player, crateName, rarityName)
	if not applied then
		NotificationRemote:FireClient(player, "Crate dropada, mas sem efeito configurado.", "Error")
	end

	return {
		CrateName = crateName,
		Rarity = rarityName,
		Applied = applied,
	}
end

function WaveCrateManager.RollDropForPlayers(playersList, context)
	if type(playersList) ~= "table" then
		return
	end

	for _, player in ipairs(playersList) do
		WaveCrateManager.RollDropForPlayer(player, context)
	end
end

local function ensureWaveSignals()
	local signalsFolder = ServerScriptService:FindFirstChild("Signals")
	if not signalsFolder then
		signalsFolder = Instance.new("Folder")
		signalsFolder.Name = "Signals"
		signalsFolder.Parent = ServerScriptService
	end

	local dropSignal = signalsFolder:FindFirstChild("WaveCrateDrop")
	if not dropSignal then
		dropSignal = Instance.new("BindableEvent")
		dropSignal.Name = "WaveCrateDrop"
		dropSignal.Parent = signalsFolder
	end

	if dropSignal:IsA("BindableEvent") then
		dropSignal.Event:Connect(function(targetPlayers, context)
			if typeof(targetPlayers) == "Instance" and targetPlayers:IsA("Player") then
				WaveCrateManager.RollDropForPlayer(targetPlayers, context)
				return
			end

			if type(targetPlayers) == "table" then
				WaveCrateManager.RollDropForPlayers(targetPlayers, context)
				return
			end
		end)
	end
end

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("WaveDamageMultiplier", 1)
	player:SetAttribute("WaveDamageBuffExpiresAt", 0)
end)

Players.PlayerRemoving:Connect(function(player)
	ActiveDamageBuffs[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	player:SetAttribute("WaveDamageMultiplier", 1)
	player:SetAttribute("WaveDamageBuffExpiresAt", 0)
end

ensureWaveSignals()

return WaveCrateManager
