--//Services
local Rs = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")

--//Modules
local ModulesFolder = Rs:WaitForChild("Modules")
local FactorUtil = require(ModulesFolder:WaitForChild("FactorUtil"))

--//Graphics Stuff
local ColorCorrection = Lighting:WaitForChild("ColorCorrection")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local PlrLoadedEvent = Remotes:WaitForChild("PlrDataLoaded")

--//Player
local Plr = game.Players.LocalPlayer

--//Values
local PlrSettings = Plr:WaitForChild("PlrSettings", 30) :: Folder
local MasterVolume = PlrSettings:WaitForChild("MasterVolume", 30) :: IntValue
local tag = "customSound"
local CustomSnds = {}

local function checkValidySnd(sound: Sound)
	if sound:IsA("Sound") then
		CustomSnds[sound] = true
		local volumeIncrement = FactorUtil.CalcFactor(MasterVolume.Value/100)
		sound.Volume = sound.Volume + (sound.Volume * volumeIncrement)
	end
end

local function removeSound(sound: Sound)
	if CustomSnds[sound] then
		CustomSnds[sound] = nil
	end
end

local function setupPlrSettings()
	-- Visual Settings --
	local GlobalShadows = PlrSettings:WaitForChild("GlobalShadows", 30) :: BoolValue
	local ContrastValue = PlrSettings:WaitForChild("Contrast", 30) :: NumberValue
	local BrightnessValue = PlrSettings:WaitForChild("Brightness", 30) :: NumberValue
	
	local constrastFactor = FactorUtil.CalcFactor(ContrastValue.Value)
	local brightnessFactor = FactorUtil.CalcFactor(BrightnessValue.Value)
	local contrastIncrement = 0.3 + (ColorCorrection.Contrast * constrastFactor / 1.25)
	local brightnessIncrement = -0.01 + (ColorCorrection.Brightness * brightnessFactor / 1.25)
	
	Lighting.GlobalShadows = GlobalShadows.Value
	ColorCorrection.Contrast = contrastIncrement
	ColorCorrection.Brightness = brightnessIncrement
	
	--[[
	for i, v in CollectionService:GetTagged(tag) do
		checkValidySnd(v)
	end
	
	CollectionService:GetInstanceRemovedSignal(tag):Connect(removeSound)
	CollectionService:GetInstanceAddedSignal(tag):Connect(checkValidySnd)]]
end

PlrLoadedEvent.OnClientEvent:Connect(function()
	setupPlrSettings()
end)