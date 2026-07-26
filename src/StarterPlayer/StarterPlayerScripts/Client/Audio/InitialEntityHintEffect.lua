local InitialEntityHintEffect = {
	DataLoad = false
}

--//Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

--//Modules
local ModulesFolder = ReplicatedStorage:WaitForChild("Modules")
local SoundPlayer = require(ModulesFolder.Utils:WaitForChild("SoundPlayer"))

--//Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local HintEffectEvent = Remotes:WaitForChild("InitialEntityHintEffect")

local function playEntranceEffect()
	local effectsFolder = SoundService:FindFirstChild("Effects")
	if not effectsFolder then
		warn("[InitialEntityHintEffect] SoundService.Effects was not found.")
		return
	end

	local horrorEffect = effectsFolder:FindFirstChild("HorrorEffect")
	if not horrorEffect or not horrorEffect:IsA("Sound") then
		warn("[InitialEntityHintEffect] SoundService.Effects.HorrorEffect was not found.")
		return
	end

	SoundPlayer:PlaySound(horrorEffect)
end

function InitialEntityHintEffect:Init()
end

function InitialEntityHintEffect:Start()
	HintEffectEvent.OnClientEvent:Connect(playEntranceEffect)
end

return InitialEntityHintEffect
