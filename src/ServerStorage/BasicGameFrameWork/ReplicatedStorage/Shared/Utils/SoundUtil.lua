local soundUtil = {}

--//Services
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

--[[
	Create a sound effect from an id.

	@param soundId (number) The id for the sound to create.
	@param customParent (Instance?) Parent to a different instance instead of SoundService.
	@param rollOffMaxDistance (number?) RollOffMaxDistance for sounds that parent to other instances.
]]
function soundUtil:CreateSoundEffect(
	soundId: number,
	customParent: Instance?,
	rollOffMaxDistance: number?,
	volume: number?
)
	if not soundId then
		return
	end
	
	local sound = Instance.new("Sound")
	sound.Volume = volume or 1
	sound.SoundId = "rbxassetid://" .. tostring(soundId)
	sound.RollOffMaxDistance = rollOffMaxDistance or 10000
	sound.RollOffMode = rollOffMaxDistance and Enum.RollOffMode.Inverse or Enum.RollOffMode.InverseTapered
	sound.Parent = customParent or SoundService
	
	repeat
		task.wait()
	until sound.IsLoaded
	
	sound:Play()
	
	Debris:AddItem(sound, sound.TimeLength + 0.25)
end

return soundUtil