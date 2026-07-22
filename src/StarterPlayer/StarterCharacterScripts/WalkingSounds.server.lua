--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--// Modules
local IDList = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WalkSoundsIDList"))

--// RemoteEvent (criado uma única vez)
local updateWalkspeedRemote = ReplicatedStorage:FindFirstChild("UpdateWalkspeed") or Instance.new("RemoteEvent")
updateWalkspeedRemote.Name = "UpdateWalkspeed"
updateWalkspeedRemote.Parent = ReplicatedStorage

--// Funções auxiliares
local function getMaterialName(materialEnum)
	return materialEnum and string.split(tostring(materialEnum), "Enum.Material.")[2] or nil
end

local function getSoundData(material)
	return IDList[material] or nil
end

local function createFootstepSound(parent)
	local sound = Instance.new("Sound")
	sound.Name = "FootstepSound"
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = 10
	sound.RollOffMaxDistance = 40
	sound.Looped = true
	sound.Parent = parent
	return sound
end

local function applySoundProperties(sound, data, humanoid)
	if not data or not sound then return end
	sound.SoundId = data.id
	sound.Volume = data.volume
	sound.PlaybackSpeed = (humanoid.WalkSpeed / 12) * data.speed
end

local function setupCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid")
	local rootPart = character:WaitForChild("HumanoidRootPart")

	-- Remove som padrão de corrida
	local defaultRunSound = rootPart:FindFirstChild("Running")
	if defaultRunSound then
		defaultRunSound.Volume = 0
	end

	-- Cria som customizado
	local footstepSound = createFootstepSound(rootPart)

	-- Estado inicial
	local lastMaterial = nil

	-- Atualiza WalkSpeed via Remote
	updateWalkspeedRemote.OnServerEvent:Connect(function(plr, walkspeed)
		if plr == player and humanoid then
			local values = player:FindFirstChild("PlayerValues")
			local onCutscene = values and values:FindFirstChild("OnCutscene")
			local onInspect = values and values:FindFirstChild("OnInspect")
			if (onCutscene and onCutscene.Value) or (onInspect and onInspect.Value) then
				humanoid.WalkSpeed = 0
				return
			end
			if typeof(walkspeed) ~= "number" then return end
			humanoid.WalkSpeed = walkspeed
		end
	end)

	-- Conecta evento Running
	humanoid.Running:Connect(function(speed)
		if speed > 0 and humanoid.MoveDirection.Magnitude > 0 and humanoid:GetState() ~= Enum.HumanoidStateType.Climbing then
			local currentMaterial = getMaterialName(humanoid.FloorMaterial)
			if currentMaterial and currentMaterial ~= lastMaterial then
				lastMaterial = currentMaterial
				local soundData = getSoundData(currentMaterial)
				if soundData then
					applySoundProperties(footstepSound, soundData, humanoid)
				end
			end
			if not footstepSound.Playing then
				footstepSound:Play()
			end
		else
			footstepSound:Stop()
		end
	end)

	-- Atualiza material se mudar (substitui loop pesado)
	RunService.Heartbeat:Connect(function()
		if humanoid.Parent then
			local currentMaterial = getMaterialName(humanoid.FloorMaterial)
			if currentMaterial and currentMaterial ~= lastMaterial then
				lastMaterial = currentMaterial
				local soundData = getSoundData(currentMaterial)
				if soundData then
					applySoundProperties(footstepSound, soundData, humanoid)
				end
			end
		end
	end)
end

--// Player Added
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)
end)
