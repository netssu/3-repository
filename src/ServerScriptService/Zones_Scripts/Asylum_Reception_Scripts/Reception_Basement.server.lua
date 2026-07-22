--//Services
local Ts = game:GetService("TweenService")
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local InspectEvent = Remotes:FindFirstChild("Inspect")

--//Asylum Reception Stuff
local Map = workspace:FindFirstChild("Map")
local AsylumReceptionFolder = Map:FindFirstChild("Area2_AsylumReception")
local InteractStuff = AsylumReceptionFolder:FindFirstChild("InteractStuff")

--//Management Room
local RoomBlock = InteractStuff:FindFirstChild("ManagementRoom_Block")
local proxRoomBlock = Instance.new("ProximityPrompt", RoomBlock.Interact)
local BasementKey = Map.Items:FindFirstChild("Basement Key")
local proxKey = BasementKey.PrimaryPart:WaitForChild("ProximityPrompt", 30) :: ProximityPrompt
local Locker_137 = Map.Doors:FindFirstChild("Locker_137")

--//Basement
local InteractDoors = InteractStuff:FindFirstChild("BasementDoors_Interact")
local proxDoors = Instance.new("ProximityPrompt", InteractDoors)
local Door1 = Map.Doors:FindFirstChild("Basemant_Door1")
local Door2 = Map.Doors:FindFirstChild("Basemant_Door2")
local proxDoor1 = Door1.MainDoor:WaitForChild("ProximityPrompt", 30)
local proxDoor2 = Door2.MainDoor:WaitForChild("ProximityPrompt", 30)

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local GameConfigModule = require(ModulesFolder:FindFirstChild("GameConfigModule"))
local DialogModule = require(ModulesFolder:FindFirstChild("PlayerDialogModule"))
local ObjectivesModule = require(ModulesFolder:FindFirstChild("ObjectivesModule"))
local InventoryModule = require(ModulesFolder:FindFirstChild("InventoryModule"))

--//Values
local roomDebounce = true
local givenObjective = false
local openedBasement = false
local planksState = 1

--//Setup
InteractDoors.BillboardGui.Enabled = false
proxRoomBlock.MaxActivationDistance = GameConfigModule.InteractDistance
proxRoomBlock.RequiresLineOfSight = false
proxRoomBlock.Style = Enum.ProximityPromptStyle.Custom
proxRoomBlock.HoldDuration = 0.15
proxRoomBlock.ActionText = "Inspect"
proxRoomBlock.ObjectText = "Planks"

proxDoors.MaxActivationDistance = GameConfigModule.InteractDistance
proxDoors.RequiresLineOfSight = false
proxDoors.Style = Enum.ProximityPromptStyle.Custom
proxDoors.HoldDuration = 0.15
proxDoors.ActionText = "Inspect"
proxDoors.ObjectText = "Basement Door"

if proxDoor1 then
	proxDoor1.Enabled = false
end
if proxDoor2 then
	proxDoor2.Enabled = false
end

local function playSound(sound: Sound, parent: Instance)
	if not sound or not sound:IsA("Sound") then return end
	local snd = sound:Clone()
	if not parent then
		snd.Parent = sound.Parent
	else
		snd.Parent = parent
	end
	snd:Play()
	game.Debris:AddItem(snd, snd.TimeLength + 1)
end

proxKey.Triggered:Connect(function(plr)
	InteractDoors.BillboardGui.Enabled = true
end)

proxRoomBlock.Triggered:Connect(function(plr)
	if plr.Character then
		local char = plr.Character
		local hum = char:WaitForChild("Humanoid")
		if hum and hum.Health > 0 and roomDebounce then
			roomDebounce = false
			
			if char:FindFirstChild("Crowbar") then
				local plankToRemove = RoomBlock.Planks:FindFirstChild("Plank_"..tostring(planksState)) :: BasePart
				
				local function disappearAnim()
					plankToRemove.Anchored = true
					plankToRemove.CanCollide = false
					Ts:Create(plankToRemove, TweenInfo.new(3), {Transparency = 1}):Play()
					game.Debris:AddItem(plankToRemove, 5)
				end
				
				if plankToRemove then
					local randomSound = RoomBlock.PlankSounds:GetChildren()[math.random(1, #RoomBlock.PlankSounds:GetChildren())]
					playSound(randomSound, plankToRemove)
					plankToRemove.Anchored = false
					planksState += 1
					task.delay(2, disappearAnim)
				end
				
				--//If there no more planks, disable the barrier
				if planksState > #RoomBlock.Planks:GetChildren() then
					for i, v in RoomBlock.Planks:GetChildren() do
						if v:IsA("BasePart") then v.Anchored = false end
					end
					givenObjective = true
					proxRoomBlock.Enabled = false
					InventoryModule.DeleteItem("Crowbar")
					RoomBlock.Barrier.CanCollide = false
					ObjectivesModule.CompleteObjective(true, "Management_Room")
					RoomBlock.BillboardGui.Enabled = false
					Locker_137.BillboardGui.Enabled = true
				end
				roomDebounce = true
				return
			end
			
			if not givenObjective then
				givenObjective = true
				ObjectivesModule.NewObjective(true, "Management_Room", "Management Room", "Find a way to clear the passage.")
			end
			
			DialogModule.Dialog(false, plr, nil, "Maybe I can find some tool to unlock this...")
			
			task.wait(0.5)
			
			roomDebounce = true
		end
	end
end)

proxDoors.Triggered:Connect(function(plr)
	if plr.Character then
		local char = plr.Character
		local hum = char:WaitForChild("Humanoid")
		if hum and hum.Health > 0 and not openedBasement then
			if char:FindFirstChild("Basement Key") then
				proxDoors.Enabled = false
				InventoryModule.DeleteItem("Basement Key")
				DialogModule.Dialog(true, nil, nil, "Basement Door Unlocked.", true)
				Door1.MainDoor.UnlockSound:Play()
				Door2.MainDoor.UnlockSound:Play()
				Door1.Locked.Value = false
				Door2.Locked.Value = false
				proxDoor1.Enabled = true
				proxDoor2.Enabled = true
				openedBasement = true
				InteractDoors.BillboardGui.Enabled = false
			else
				DialogModule.Dialog(false, plr, nil, "Locked, I'll need a key to open this.")
			end
		end
	end
end)