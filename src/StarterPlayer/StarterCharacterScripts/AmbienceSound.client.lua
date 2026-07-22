--//Services
local Ts = game:GetService("TweenService")
local Rs = game:GetService("ReplicatedStorage")

--//Modules
local ModulesFolder = Rs:WaitForChild("Modules")
local FactorUtil = require(ModulesFolder:WaitForChild("FactorUtil"))

--//Player
local Plr = game.Players.LocalPlayer
local Char = script.Parent
local Hum = Char:WaitForChild("Humanoid") :: Humanoid
local HumanoidRootPart = Char:WaitForChild("HumanoidRootPart")
local PlrSettings = Plr:WaitForChild("PlrSettings")

--//Sound Parts
local Map = workspace:WaitForChild("Map")
local InteractParts = Map:WaitForChild("InteractParts")
local SoundParts = InteractParts:WaitForChild("SoundParts")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local StopAmbienceSoundEvent = Remotes:WaitForChild("StopAmbienceSound")
local PlrDataLoaded = Remotes:WaitForChild("PlrDataLoaded")

--//Values
local AmbienceParts = {}
local CurrentPlaying = nil
local MasterVolume = PlrSettings:WaitForChild("MasterVolume") :: IntValue --// 0~100
local AmbientVolume = PlrSettings:WaitForChild("AmbientSounds") :: IntValue --// 0~100

-- Load the function on all Sound Parts
local function loadSoundParts()
	for i, part: BasePart in ipairs(AmbienceParts) do
		if not part:HasTag("MarkedSoundPart") then
			part:AddTag("MarkedSoundPart")
			part.Touched:Connect(function(hit)
				if hit.Parent:FindFirstChildWhichIsA("Humanoid") then
					local player = game.Players:GetPlayerFromCharacter(hit.Parent)
					if player and player == game.Players.LocalPlayer and part:FindFirstChildWhichIsA("Sound") then
						if CurrentPlaying and CurrentPlaying.Name == part:FindFirstChildWhichIsA("Sound").Name then return end
						
						if CurrentPlaying then
							local OldSound = CurrentPlaying
							local tween = Ts:Create(CurrentPlaying, TweenInfo.new(3), {Volume = 0})
							tween:Play()
							
							tween.Completed:Connect(function()
								OldSound:Destroy()
							end)
						end
						
						local DefaultSound = part:FindFirstChildWhichIsA("Sound")
						
						local MasterVolumeIncrement = DefaultSound.Volume FactorUtil.CalcFactor(MasterVolume.Value/100)
						local AmbientVolumeIncrement = DefaultSound.Volume FactorUtil.CalcFactor(AmbientVolume.Value/100)
						local CalcVolume = DefaultSound.Volume + (DefaultSound.Volume * AmbientVolumeIncrement)
						local SoundVolume = DefaultSound.Volume + (DefaultSound.Volume * MasterVolumeIncrement)
						
						local Sound = part:FindFirstChildWhichIsA("Sound"):Clone()
						Sound.Parent = Char
						Sound.Volume = 0
						Sound:Play()
						
						CurrentPlaying = Sound
						
						Ts:Create(Sound, TweenInfo.new(4), {Volume = SoundVolume}):Play()
					end
				end
			end)
		end
	end
end

SoundParts.ChildAdded:Connect(function(child)
	if child:HasTag("SoundPart") then
		table.insert(AmbienceParts, child)
	end
	loadSoundParts()
end)

Hum.Died:Connect(function()
	CurrentPlaying = nil
	for i, v in ipairs(AmbienceParts) do
		if v:HasTag("MarkedSoundPart") then
			v:RemoveTag("MarkedSoundPart")
		end
	end
end)

StopAmbienceSoundEvent.OnClientEvent:Connect(function()
	if CurrentPlaying then
		local OldSound = CurrentPlaying
		local tween = Ts:Create(CurrentPlaying, TweenInfo.new(3), {Volume = 0})
		tween:Play()
		
		tween.Completed:Connect(function()
			OldSound:Destroy()
		end)
		
		CurrentPlaying = nil
	end
end)

if not game:IsLoaded() then
	game.Loaded:Wait()
end

for i, v in SoundParts:GetChildren() do
	if v:HasTag("SoundPart") then
		table.insert(AmbienceParts, v)
	end
end

loadSoundParts()