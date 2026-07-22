--//Services
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

--//Player
local Char = script.Parent
local Hum = Char:WaitForChild("Humanoid") :: Humanoid
local RootPart = Char:WaitForChild("HumanoidRootPart") :: BasePart
local Camera = workspace.CurrentCamera

--//Values
local MaxEchoFactor = 130
local DetectionRadius = 30 -- Player detection area
local RayCount = 20 -- Number of rays to cast to detect nearby objects
local delayToDetect = 4 -- between each function call
local lastFunctionCall = 0
local loopConnection: RBXScriptConnection = nil

-- Adjust AmbientReverb to simulate the environment.
local function adjustReverb(distanceFactor)
	if distanceFactor >= MaxEchoFactor * 0.75 then -- 75%
		SoundService.AmbientReverb = Enum.ReverbType.ConcertHall -- Very echo
	elseif distanceFactor >= MaxEchoFactor * 0.4 then -- 40%
		SoundService.AmbientReverb = Enum.ReverbType.Hallway -- Medium echo
	elseif distanceFactor >= MaxEchoFactor * 0.25 then -- 25%
		SoundService.AmbientReverb = Enum.ReverbType.City -- Low echo
	else
		SoundService.AmbientReverb = Enum.ReverbType.NoReverb -- No echo
	end
end

-- Get all ancestos from a part.
local function getAllAncestors(part)
	local ancestors = {}
	local current = part
	
	while current do
		table.insert(ancestors, current)
		current = current.Parent
	end
	
	return ancestors
end

-- Check if an instance has a humanoid (to don't detect Players or NPCs)
local function hasHumanoid(instance: Instance)
	if not instance or not instance.Parent then
		return false
	end
	local Ancestors = getAllAncestors(instance)
	for i, v in ipairs(Ancestors) do
		if v:FindFirstChildOfClass("Humanoid") then
			return true
		end
	end
	return false
end

-- Detect close objects and change the distance factor and reverb to simulate the environment
local function detectEnvironment()
	local totalProximity = 0
	local hitCount = 0
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {Char}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	
	for i = 1, RayCount do
		local angle = math.rad((i / RayCount) * 360)
		local direction = Vector3.new(math.cos(angle), 0, math.sin(angle)).Unit * DetectionRadius
		local result = workspace:Raycast(RootPart.Position, direction, raycastParams)
		
		if result and not hasHumanoid(result.Instance) then
			hitCount += 1
			local proximity = (RootPart.Position - result.Position).Magnitude
			totalProximity += proximity
		end
	end
	
	if hitCount > 0 then
		local averageProximity = totalProximity / hitCount
		local distanceFactor = math.clamp((averageProximity / DetectionRadius) * MaxEchoFactor, 0, MaxEchoFactor)
		SoundService.DistanceFactor = distanceFactor
		adjustReverb(distanceFactor)
	else
		--//If don't detect objects, then simulate a very open zone with high echo
		SoundService.DistanceFactor = MaxEchoFactor
		adjustReverb(MaxEchoFactor)
	end
end

loopConnection = RunService.Heartbeat:Connect(function()
	if tick() - lastFunctionCall >= delayToDetect then
		lastFunctionCall = tick()
	else
		return
	end
	detectEnvironment()
end)

Hum.Died:Connect(function()
	if (loopConnection) then
		loopConnection:Disconnect()
		loopConnection = nil
	end
end)