-- Get services
local players = game:GetService("Players")
local soundService = game:GetService("SoundService")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- Set local variables
local player = players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Create sound variables
local id
local volume
local playbackSpeed

-- Create material variables
local floorMaterial
local material

-- Get the HumanoidRootPart and wait for the server audio
local root = character:WaitForChild("HumanoidRootPart")
local serverSound = root:FindFirstChild("CurrentSound") or Instance.new("Sound", root)

-- Get remote
local updateWalkspeedRemote = replicatedStorage:WaitForChild("UpdateWalkspeed")

-- Create sound instance
local currentSound = Instance.new("Sound", character:WaitForChild("HumanoidRootPart"))
	  currentSound.Name = "CurrentSound"
	  currentSound.RollOffMode = Enum.RollOffMode.InverseTapered
	  currentSound.RollOffMaxDistance = 1
	  currentSound.RollOffMaxDistance= 30

-- fetch the ID list
local IDList = require(replicatedStorage:WaitForChild("Modules"):WaitForChild("WalkSoundsIDList"))

-- Delete default running sound
local soundToRemote = character:WaitForChild("HumanoidRootPart"):WaitForChild("Running", 30)
if soundToRemote then
	soundToRemote.Volume = 0
end

-- Delete the death sound on client
local defaultDeathSound = character:WaitForChild("HumanoidRootPart"):WaitForChild("Died", 30)
if defaultDeathSound then
	defaultDeathSound.Volume = 0
end

-- Get the current floor material.
local function getFloorMaterial()
	floorMaterial = humanoid.FloorMaterial
	material = string.split(tostring(floorMaterial), "Enum.Material.")[2]

	return material
end

-- Get the correct sound from our sound list.
local function getSoundProperties()
	for name, data in pairs(IDList) do
		if name == material then
			id = data.id
			volume = data.volume
			playbackSpeed = (humanoid.WalkSpeed / 12) * data.speed
			break
		end
	end
end

-- update the sound data
local function update()
	currentSound.SoundId = id
	currentSound.Volume = volume
	currentSound.PlaybackSpeed = playbackSpeed
end

-- Get initial data for client
getFloorMaterial()
getSoundProperties()
update()

-- Update the previous floor material and current floor material
humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
	getFloorMaterial()
	getSoundProperties()
	update()

	if humanoid.MoveDirection.Magnitude > 0.3 then
		currentSound.Playing = true
	end
end)

-- Let the server know our walkspeed has changed
humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
	updateWalkspeedRemote:FireServer(humanoid.WalkSpeed)
end)

-- check if the player is moving and not climbing
humanoid.Running:Connect(function(speed)
	if humanoid.MoveDirection.Magnitude > 0 and speed > 0 and humanoid:GetState() ~= Enum.HumanoidStateType.Climbing then
		getSoundProperties()
		update()
		currentSound.Playing = true
		currentSound.Looped = true
	else
		currentSound:Stop()
	end
end)

serverSound.Changed:Connect(function(Volume)
	if Volume ~= 0 then
		serverSound.Volume = 0
	end
end)

-- Small bug fix where the sound would start playing after the player joined
player.CharacterAdded:Connect(function()
	task.wait(1)
	if currentSound.IsPlaying then
		currentSound:Stop()
	end
end)