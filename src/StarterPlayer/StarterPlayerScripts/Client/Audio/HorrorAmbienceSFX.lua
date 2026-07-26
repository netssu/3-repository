local HorrorAmbienceSFX = {
	DataLoad = false
}

--//Services
local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--//Modules
local ModulesFolder = ReplicatedStorage:WaitForChild("Modules")
local FactorUtil = require(ModulesFolder:WaitForChild("FactorUtil"))

--//Player
local LocalPlayer = Players.LocalPlayer

--//Config
local SOUND_IDS = {
	-- Add the horror effect ids here. They can be numbers or rbxassetid strings.
	-- Example: 1234567890,
	-- Example: "rbxassetid://1234567890",
}

local INTERVAL_SECONDS = 7 * 60
local BASE_VOLUME = 0.18
local MAX_VOLUME = 0.28
local MIN_DISTANCE_STUDS = 10
local MAX_DISTANCE_STUDS = 16
local SIDE_BEHIND_DISTANCE_STUDS = 4
local POSITION_HEIGHT_MIN = 1
local POSITION_HEIGHT_MAX = 3
local ROLLOFF_MIN_DISTANCE = 5
local ROLLOFF_MAX_DISTANCE = 55
local PLAYBACK_SPEED_MIN = 0.96
local PLAYBACK_SPEED_MAX = 1.04
local FALLBACK_CLEANUP_SECONDS = 45
local TEST_BUTTON_COOLDOWN_SECONDS = 2
local SHOW_TEST_BUTTON = RunService:IsStudio()

local rng = Random.new()
local normalizedSoundIds = {}
local lastSoundId = nil
local automaticLoopStarted = false
local canUseTestButton = true

local function normalizeSoundId(rawSoundId)
	if rawSoundId == nil then
		return nil
	end

	local soundId = tostring(rawSoundId):gsub("%s+", "")
	if soundId == "" or soundId == "0" or soundId == "rbxassetid://0" then
		return nil
	end

	if tonumber(soundId) then
		return `rbxassetid://{soundId}`
	end

	return soundId
end

local function loadSoundIds()
	normalizedSoundIds = {}

	for _, rawSoundId in ipairs(SOUND_IDS) do
		local soundId = normalizeSoundId(rawSoundId)
		if soundId then
			table.insert(normalizedSoundIds, soundId)
		end
	end
end

local function preloadSoundIds()
	if #normalizedSoundIds == 0 then
		return
	end

	task.spawn(function()
		local soundsToPreload = {}

		for _, soundId in ipairs(normalizedSoundIds) do
			local sound = Instance.new("Sound")
			sound.SoundId = soundId
			table.insert(soundsToPreload, sound)
		end

		pcall(function()
			ContentProvider:PreloadAsync(soundsToPreload)
		end)

		for _, sound in ipairs(soundsToPreload) do
			sound:Destroy()
		end
	end)
end

local function getRandomSoundId()
	if #normalizedSoundIds == 0 then
		return nil
	end

	if #normalizedSoundIds == 1 then
		lastSoundId = normalizedSoundIds[1]
		return lastSoundId
	end

	local selectedSoundId = nil
	repeat
		selectedSoundId = normalizedSoundIds[rng:NextInteger(1, #normalizedSoundIds)]
	until selectedSoundId ~= lastSoundId

	lastSoundId = selectedSoundId
	return selectedSoundId
end

local function applyVolumeSetting(volume, settingName)
	local plrSettings = LocalPlayer:FindFirstChild("PlrSettings")
	if not plrSettings then
		return volume
	end

	local setting = plrSettings:FindFirstChild(settingName)
	if not setting or not (setting:IsA("IntValue") or setting:IsA("NumberValue")) then
		return volume
	end

	local volumeIncrement = FactorUtil.CalcFactor(setting.Value / 100)
	return volume + (volume * volumeIncrement)
end

local function getConfiguredVolume()
	local volume = BASE_VOLUME
	volume = applyVolumeSetting(volume, "MasterVolume")
	volume = applyVolumeSetting(volume, "AmbientSounds")

	return math.clamp(volume, 0, MAX_VOLUME)
end

local function getRootPart()
	local character = LocalPlayer.Character
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function getHorizontalVector(vector, fallback)
	local flatVector = Vector3.new(vector.X, 0, vector.Z)
	if flatVector.Magnitude <= 0.001 then
		return fallback
	end

	return flatVector.Unit
end

local function getPlayerFacingVectors(rootPart)
	local camera = workspace.CurrentCamera
	local fallbackLook = getHorizontalVector(rootPart.CFrame.LookVector, Vector3.new(0, 0, -1))
	local fallbackRight = getHorizontalVector(rootPart.CFrame.RightVector, Vector3.new(1, 0, 0))

	if not camera then
		return fallbackLook, fallbackRight
	end

	local lookVector = getHorizontalVector(camera.CFrame.LookVector, fallbackLook)
	local rightVector = getHorizontalVector(camera.CFrame.RightVector, fallbackRight)

	return lookVector, rightVector
end

local function getEmitterPosition(rootPart)
	local lookVector, rightVector = getPlayerFacingVectors(rootPart)
	local distance = rng:NextNumber(MIN_DISTANCE_STUDS, MAX_DISTANCE_STUDS)
	local height = rng:NextNumber(POSITION_HEIGHT_MIN, POSITION_HEIGHT_MAX)
	local shouldPlayBehind = rng:NextInteger(1, 2) == 1

	if shouldPlayBehind then
		local sideDrift = rng:NextNumber(-SIDE_BEHIND_DISTANCE_STUDS, SIDE_BEHIND_DISTANCE_STUDS)
		return rootPart.Position - (lookVector * distance) + (rightVector * sideDrift) + Vector3.new(0, height, 0)
	end

	local sideSign = 1
	if rng:NextInteger(1, 2) == 1 then
		sideSign = -1
	end

	local behindDrift = rng:NextNumber(2, SIDE_BEHIND_DISTANCE_STUDS)
	return rootPart.Position + (rightVector * sideSign * distance) - (lookVector * behindDrift) + Vector3.new(0, height, 0)
end

local function createEmitter(position)
	local emitter = Instance.new("Part")
	emitter.Name = "HorrorAmbienceSFXEmitter"
	emitter.Anchored = true
	emitter.CanCollide = false
	emitter.CanQuery = false
	emitter.CanTouch = false
	emitter.Transparency = 1
	emitter.Size = Vector3.new(0.2, 0.2, 0.2)
	emitter.CFrame = CFrame.new(position)
	emitter.Parent = workspace

	return emitter
end

local function playRandomEffect(showMissingSoundWarning)
	local soundId = getRandomSoundId()
	if not soundId then
		if showMissingSoundWarning then
			warn("[HorrorAmbienceSFX] Add sound ids to SOUND_IDS before testing the effect.")
		end
		return false
	end

	local rootPart = getRootPart()
	if not rootPart then
		return false
	end

	local emitter = createEmitter(getEmitterPosition(rootPart))
	local sound = Instance.new("Sound")
	sound.Name = "RandomHorrorEffect"
	sound.SoundId = soundId
	sound.Volume = getConfiguredVolume()
	sound.PlaybackSpeed = rng:NextNumber(PLAYBACK_SPEED_MIN, PLAYBACK_SPEED_MAX)
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = ROLLOFF_MIN_DISTANCE
	sound.RollOffMaxDistance = ROLLOFF_MAX_DISTANCE
	sound.Parent = emitter

	sound.Ended:Connect(function()
		if emitter.Parent then
			emitter:Destroy()
		end
	end)

	Debris:AddItem(emitter, FALLBACK_CLEANUP_SECONDS)
	sound:Play()

	return true
end

local function setupTestButton()
	if not SHOW_TEST_BUTTON then
		return
	end

	local Packages = ReplicatedStorage:WaitForChild("Packages")
	local TopBarApp = require(Packages:WaitForChild("Icon"))
	local testButton = TopBarApp.new()

	testButton:setName("HorrorAmbienceSFXTestButton")
	testButton:setLabel("SFX")
	testButton:setCaption("Testar efeito sonoro de terror")
	testButton:setOrder(3)
	testButton:setRight()
	testButton:oneClick(true)

	testButton:bindEvent("selected", function()
		if not canUseTestButton then
			return
		end

		canUseTestButton = false
		playRandomEffect(true)

		task.delay(TEST_BUTTON_COOLDOWN_SECONDS, function()
			canUseTestButton = true
		end)
	end)
end

function HorrorAmbienceSFX:Init()
	loadSoundIds()
	preloadSoundIds()
	setupTestButton()
end

function HorrorAmbienceSFX:Start()
	if automaticLoopStarted then
		return
	end

	automaticLoopStarted = true

	task.spawn(function()
		while true do
			task.wait(INTERVAL_SECONDS)
			playRandomEffect(false)
		end
	end)
end

return HorrorAmbienceSFX
