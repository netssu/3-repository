--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Map Stuff
local Map = workspace:FindFirstChild("Map")
local AsylumZone2 = Map:FindFirstChild("Area2_AsylumReception")
local InteractStuff = AsylumZone2:FindFirstChild("InteractStuff")
local flayedScare = InteractStuff:FindFirstChild("FlayedScare")
local enableFlayedScare = InteractStuff:FindFirstChild("EnableFlayedScare")
local lightFlayedScare = InteractStuff:FindFirstChild("Light_FlayedScare")

--//Values
local actived = false

local function changeLightPart(state: boolean)
	if state then
		lightFlayedScare.Light_Part.Material = Enum.Material.Neon
		lightFlayedScare.Light_Part.Color = Color3.fromRGB(229, 242, 255)
		
		for _, v in lightFlayedScare.Light_Part:GetChildren() do
			if v:IsA("Light") then
				v.Enabled = true
			end
		end
	else
		lightFlayedScare.Light_Part.Material = Enum.Material.Glacier
		lightFlayedScare.Light_Part.Color = Color3.fromRGB(111, 118, 124)
		lightFlayedScare.Light_Part.LightBlink:Play()
		lightFlayedScare.sndScarePart.HorrorHit:Play()
		
		for _, v in lightFlayedScare.Light_Part:GetChildren() do
			if v:IsA("Light") then
				v.Enabled = false
			end
		end
	end
end

enableFlayedScare.Touched:Connect(function(hit)
	if actived then return end
	
	if not hit or not hit.Parent then return end
	local player = game.Players:GetPlayerFromCharacter(hit.Parent)
	if player then
		local hum = hit.Parent:FindFirstChild("Humanoid") :: Humanoid
		if hum and hum.Health > 0 then
			actived = true
			
			changeLightPart(false)
			flayedScare.Parent = Rs
			
			task.wait(0.3)
			
			changeLightPart(true)
		end
	end
end)