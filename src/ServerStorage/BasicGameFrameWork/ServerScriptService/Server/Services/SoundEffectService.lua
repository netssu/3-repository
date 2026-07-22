--!strict
--[[
	SoundEffectService.lua by @Thurzin54
	
	Create a sound effect and play it.
]]

--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Modules
local Packages = Rs.Packages
local Utils = require(Rs.Shared.Utils)
local Knit = require(Packages.Knit)

local SoundEffectService = {
	Name = "SoundEffectService",
	Client = {},
}

function SoundEffectService:CreateSoundEffect(soundId: number, customParent: Instance?, rollOffMaxDistance: number?, volume: number?)
	Utils.Sounds:CreateSoundEffect(soundId, customParent, rollOffMaxDistance, volume)
end

return SoundEffectService
