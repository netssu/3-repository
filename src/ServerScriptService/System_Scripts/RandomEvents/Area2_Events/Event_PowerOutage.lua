local eventLightsOff = {
	["Rarity"] = 0.15, -- 15%
	["OneTime"] = false,
	["Activated"] = false
}

--//Services
local Ts = game:GetService("TweenService")
local Rs = game:GetService("ReplicatedStorage")

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local GameConfigModule = require(ModulesFolder:FindFirstChild("GameConfigModule"))

--//Map Stuff
local MapFolder = workspace:FindFirstChild("Map")
local InteractStuff = MapFolder:FindFirstChild("Area2_AsylumReception"):FindFirstChild("InteractStuff")
local LightFallSounds = InteractStuff:FindFirstChild("LightsFallSounds")
local PowerFallSound = LightFallSounds:FindFirstChild("PowerFallSound")
local PowerOnSound = LightFallSounds:FindFirstChild("PowerRestoredSound")
local LightsArea2 = MapFolder:FindFirstChild("Area2_AsylumReception"):FindFirstChild("Light")
local ButtonMetalDoor = InteractStuff:FindFirstChild("ButtonMetalDoor")

--//Values
local lightsTurnedOff = false

local function changeLightsOn()
	for i, v in LightsArea2:GetChildren() do
		if v:IsA("Model") then
			local lightPart = v:FindFirstChild("LightPart") :: BasePart
			if lightPart then
				lightPart.Color = Color3.fromRGB(147, 163, 165)
				for _, light in lightPart:GetChildren() do
					if light:IsA("Light") then
						light.Enabled = true
					end
				end
			end
		end
		task.wait()
	end
end

function eventLightsOff:Start()
	if ButtonMetalDoor and ButtonMetalDoor:FindFirstChild("EnergyRestored") then
		if ButtonMetalDoor.EnergyRestored.Value then -- Energy already has restaured.
			changeLightsOn()
			return
		end
	end
	
	if GameConfigModule.GameMode == "Nightmare" and lightsTurnedOff then
		return
	end
	
	print("Starting Random Event: Power Outage.")
	for _, v in LightFallSounds:GetChildren() do
		if v:IsA("BasePart") then
			local sound = PowerFallSound:Clone()
			sound.Parent = v
			task.delay(math.random(20, 80)/100, function()
				sound:Play()
				game.Debris:AddItem(sound, sound.TimeLength + 2)
			end)
		end
	end
	
	for i, v in LightsArea2:GetChildren() do
		if v:IsA("Model") then
			local lightPart = v:FindFirstChild("LightPart") :: BasePart
			if lightPart then
				lightPart.Color = Color3.fromRGB(60, 66, 67)
				for _, light in lightPart:GetChildren() do
					if light:IsA("Light") then
						light.Enabled = false
					end
				end
			end
		end
		task.wait()
	end
	
	if GameConfigModule.GameMode == "Hard" then
		eventLightsOff.Rarity = 0.20
		task.wait(math.random(10, 15)) -- take more time in hard mode
	elseif GameConfigModule.GameMode == "Nightmare" then
		lightsTurnedOff = true
		return -- lights don't turn on back in nightmare mode
	else
		task.wait(math.random(6, 9))
	end
	
	changeLightsOn()
	
	for _, v in LightFallSounds:GetChildren() do
		if v:IsA("BasePart") then
			local sound = PowerOnSound:Clone()
			sound.Parent = v
			task.delay(math.random(5, 7)/100, function()
				sound:Play()
				Ts:Create(sound, TweenInfo.new(4), {Volume = 0.1}):Play()
				game.Debris:AddItem(sound, sound.TimeLength + 2)
			end)
		end
	end
end

return eventLightsOff