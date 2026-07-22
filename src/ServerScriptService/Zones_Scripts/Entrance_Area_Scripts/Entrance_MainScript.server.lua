--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local StopAmbienceSound = Remotes:FindFirstChild("StopAmbienceSound")
local ChangeCamEvent = Remotes:WaitForChild("ChangeCam")

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local GameConfigModule = require(ModulesFolder:FindFirstChild("GameConfigModule"))
local InventoryModule = require(ModulesFolder:FindFirstChild("InventoryModule"))
local ObjectivesModule = require(ModulesFolder:FindFirstChild("ObjectivesModule"))
local DialogModule = require(ModulesFolder:FindFirstChild("PlayerDialogModule"))
local TeleportModule = require(ModulesFolder:FindFirstChild("TeleportModule"))
local MoneyModule = require(ModulesFolder:FindFirstChild("MoneyModule"))
local DoorCollision = require(ModulesFolder:FindFirstChild("DoorCollision"))

--//Entrance Area Stuff
local Map = workspace:FindFirstChild("Map")
local Area1_Entrance = Map:FindFirstChild("Area1_Entrance")
local InteractStuff = Area1_Entrance:FindFirstChild("InteractStuff")

local EntranceDoor = InteractStuff:FindFirstChild("Entrance_Door")
local AsylumEntrance_Door = Map.Doors:FindFirstChild("AsylumEntrance_Door")
local GridDoor_Right = Map.Doors:FindFirstChild("Grid_Door_Right")
local CareTakerDoor = Map.Doors:FindFirstChild("CareTaker_Door")

local CareTaker_Chains_Door = InteractStuff:FindFirstChild("CareTaker_Chains_Door")
local ChainsInteraction = CareTaker_Chains_Door:FindFirstChild("Interaction")

local ObjectiveDoorEntrance = InteractStuff.ObjectiveDoorEntrance
local BarrelPush = InteractStuff:FindFirstChild("Barrel_Push")
local CompletionZone = InteractStuff:FindFirstChild("CompletionZone")

local PlrCutAnimation = ChainsInteraction:FindFirstChild("PlrCutAnimation")
local PlrPlierCutAnim = CareTaker_Chains_Door:FindFirstChild("PlrPlierCutAnim")
local GridDoor_Prox = GridDoor_Right.MainDoor:WaitForChild("ProximityPrompt", 30) :: ProximityPrompt

local PlierItem = Map.Items:FindFirstChild("Plier")
local PlierProx = PlierItem.PrimaryPart:WaitForChild("ProximityPrompt", 30) :: ProximityPrompt

local KeyItem = Map.Items:FindFirstChild("Back door Keys")
local KeyProx = KeyItem.PrimaryPart:WaitForChild("ProximityPrompt", 30) :: ProximityPrompt

local JanitorKeyItem = Map.Items:FindFirstChild("Janitor Keys")
local JanitorKeyProx = JanitorKeyItem.PrimaryPart:WaitForChild("ProximityPrompt", 30) :: ProximityPrompt

local JanitorDoor = Map.Doors:FindFirstChild("Asylum_Door_Janitor")
local JanitorDoorProx = JanitorDoor.MainDoor:WaitForChild("ProximityPrompt", 30)

local BoxFall = InteractStuff:FindFirstChild("Wooden_Box_Fall")

ContentProvider:PreloadAsync({PlrCutAnimation, PlrPlierCutAnim, ChainsInteraction.ChainCut})

--//Setup
local State = Instance.new("BoolValue", EntranceDoor)
local Prox = Instance.new("ProximityPrompt", EntranceDoor.Door_Right.Locker)
Prox.MaxActivationDistance = GameConfigModule.InteractDistance
Prox.Style = Enum.ProximityPromptStyle.Custom
Prox.HoldDuration = 0.2
Prox.RequiresLineOfSight = false
Prox.ActionText = "Open"
Prox.ObjectText = "Door"
JanitorDoor.BillboardGui.Enabled = false
GridDoor_Right.BillboardGui.Enabled = false
ChainsInteraction.ProximityPrompt.MaxActivationDistance = GameConfigModule.InteractDistance

local careTakerProx = CareTakerDoor.MainDoor:WaitForChild("ProximityPrompt")
if careTakerProx then
	careTakerProx.Enabled = false
end

local asylumEntranceProx = AsylumEntrance_Door.MainDoor:WaitForChild("ProximityPrompt", 10)
if asylumEntranceProx then
	asylumEntranceProx.Enabled = false
end

--//Values
local chainsInteractions = 5
local currentChains = 1
local chainsDebounce = true
local objectiveDebounce = true

JanitorDoorProx.Triggered:Connect(function(plr)
	local char = plr.Character
	if not char then return end
	
	if char:FindFirstChild("Janitor Keys") and char:FindFirstChild("Janitor Keys"):IsA("Tool") then
		JanitorDoor.BillboardGui.Enabled = false
	end
end)

JanitorKeyProx.Triggered:Connect(function(plr)
	JanitorDoor.BillboardGui.Enabled = true
	task.delay(0.6, function()
		BoxFall.Anchored = false
		
		if BoxFall:FindFirstChildWhichIsA("Weld") then
			BoxFall:FindFirstChildWhichIsA("Weld"):Destroy()
		end
		
		BoxFall.FallSound:Play()
		
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = Vector3.new(0, 30, 200)
		bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
		bodyVelocity.Parent = BoxFall
		game.Debris:AddItem(bodyVelocity, 0.1)
	end)
end)

PlierProx.Triggered:Connect(function()
	CareTaker_Chains_Door.BillboardGui.Enabled = true
end)

KeyProx.Triggered:Connect(function()
	GridDoor_Right.BillboardGui.Enabled = true
end)

ObjectiveDoorEntrance.Touched:Connect(function(hit)
	if hit.Parent:FindFirstChildWhichIsA("Humanoid") then
		local player = game.Players:GetPlayerFromCharacter(hit.Parent)
		if player and objectiveDebounce then
			objectiveDebounce = false
			
			local ObjectiveFolder = ObjectiveDoorEntrance:FindFirstChild("Barred_Door")
			local ObjectiveDesc = ObjectiveFolder.Description
			local ObjectiveName = ObjectiveFolder.Title
			local ObjectiveCutscene = ObjectiveFolder.CutsceneFolder
			
			DialogModule.Dialog(true, nil, ObjectiveDoorEntrance.PlrDialog)
			
			task.wait(5)
			
			ObjectivesModule.NewObjective(true, ObjectiveFolder.Name, ObjectiveName.Value, ObjectiveDesc.Value, ObjectiveCutscene.Value)
		end
	end
end)

local function changeDoor(state: boolean)
	DoorCollision.setEnabled(EntranceDoor, not state)
	local RightHinge = EntranceDoor.Door_Right.Hinge
	local LeftHinge = EntranceDoor.Door_Left.Hinge
	local OpenedPosRight = EntranceDoor.Door_Right.OpenedPos
	local OpenedPosLeft = EntranceDoor.Door_Left.OpenedPos
	local ClosedPosRight = EntranceDoor.Door_Right.ClosedPos
	local ClosedPosLeft = EntranceDoor.Door_Left.ClosedPos
	local OpenSound = EntranceDoor.Door_Right.Locker.OpenSound
	local CloseSound = EntranceDoor.Door_Right.Locker.CloseSound
	
	local function playSound(sound: Sound)
		sound:Play()
	end
	
	if state then
		task.delay(1, playSound, OpenSound)
		Ts:Create(RightHinge, TweenInfo.new(4, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), {CFrame = OpenedPosRight.CFrame}):Play()
		Ts:Create(LeftHinge, TweenInfo.new(4, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), {CFrame = OpenedPosLeft.CFrame}):Play()
	else
		CloseSound:Play()
		Ts:Create(RightHinge, TweenInfo.new(0.7, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {CFrame = ClosedPosRight.CFrame}):Play()
		Ts:Create(LeftHinge, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {CFrame = ClosedPosLeft.CFrame}):Play()
	end
end

Prox.Triggered:Connect(function()
	if not State.Value then
		Prox.MaxActivationDistance = 0
		State.Value = true
		changeDoor(State.Value)
	end
end)

--//Entrance door closing
coroutine.wrap(function()
	while task.wait() do
		if State.Value then
			task.wait(math.random(13, 17))
			changeDoor(false)
			task.wait(3)
			State.Value = false
			Prox.MaxActivationDistance = GameConfigModule.InteractDistance
		end
	end
end)()

ChainsInteraction.ProximityPrompt.Triggered:Connect(function(plr)
	local char = plr.Character
	local hum = char:WaitForChild("Humanoid") :: Humanoid
	
	if not char or not hum or hum.Health <= 0 then return end
	
	if char:FindFirstChild("Plier") and chainsDebounce then
		local HRP = char:FindFirstChild("HumanoidRootPart") :: BasePart
		local Animator = hum:WaitForChild("Animator") :: Animator
		local PlrCutAnim = Animator:LoadAnimation(PlrPlierCutAnim)
		local deletedItem = false
		chainsDebounce = false
		
		local pos = Vector3.new(CareTaker_Chains_Door.AnimPos.Position.X, HRP.Position.Y, CareTaker_Chains_Door.AnimPos.Position.Z)
		local lookPos = CareTaker_Chains_Door.AnimPos.CFrame.LookVector
		HRP.Anchored = true
		HRP.CFrame = CFrame.new(pos, pos + lookPos)
		
		--//Disaple plr camera
		ChangeCamEvent:FireClient(plr, true)
		
		PlrCutAnim:Play()
		PlrCutAnim:AdjustSpeed(0.7)
		CareTaker_Chains_Door.BillboardGui.Enabled = false
		ChainsInteraction.ProximityPrompt.Enabled = false
		MoneyModule.Give(plr, 10)
		
		task.delay(0.5, function() ChainsInteraction.ClotheSound:Play() end)
		
		local function unanchorChain(chainsModelToRemove)
			task.wait(0.1)
			ChainsInteraction.PlierEffect:Play()
			ChainsInteraction.ChainCut:Play()
			for i, v in chainsModelToRemove:GetChildren() do
				if v:IsA("BasePart") then
					v.Anchored = false
					task.delay(10, function()
						v.Anchored = true
						v.CanCollide = false
						Ts:Create(v, TweenInfo.new(3), {Transparency = 1}):Play()
						game.Debris:AddItem(v, 5)
					end)
				end
			end
		end
		
		local function openCaretakerDoor()
			CareTakerDoor.Locked.Value = false
			InventoryModule.DeleteItem("Plier")
			CareTakerDoor.MainDoor:WaitForChild("ProximityPrompt").Enabled = true
			ChainsInteraction.ProximityPrompt.Enabled = false
			BarrelPush.BillboardGui.Enabled = true
		end
		
		PlrCutAnim.KeyframeReached:Connect(function(keyName)
			if keyName == "CHAIN_1" then
				unanchorChain(CareTaker_Chains_Door.Chains1)
			elseif keyName == "CHAIN_2" then
				unanchorChain(CareTaker_Chains_Door.Chains2)
			elseif keyName == "CHAIN_3" then
				unanchorChain(CareTaker_Chains_Door.Chains3)
			end
		end)
		
		PlrCutAnim.Stopped:Connect(function()
			HRP.Anchored = false
			ChangeCamEvent:FireClient(plr, false)
			openCaretakerDoor()
			deletedItem = true
		end)
		
		task.delay(7, function()
			if not deletedItem then
				deletedItem = true
				HRP.Anchored = false
				ChangeCamEvent:FireClient(plr, false)
				openCaretakerDoor()
				deletedItem = true
			end
		end)
	else
		DialogModule.Dialog(false, plr, nil, "I need a tool to be able to break this..")
	end
end)

local openedGridDoor = false

GridDoor_Prox.Triggered:Connect(function(plr)
	if openedGridDoor then return end
	if not plr.Character or not plr.Character:FindFirstChild("Humanoid") then return end
	if plr.Character:FindFirstChild("Humanoid").Health <= 0 then return end
	
	if plr.Character:FindFirstChild("Back door Keys") then
		if plr.Character:FindFirstChild("Back door Keys"):IsA("Tool") then
			openedGridDoor = true
			DoorCollision.disable(GridDoor_Right)
			GridDoor_Right.BillboardGui.Enabled = false
			--GridDoor_Right.Locked.Value = false
			
			local function disappear(part: BasePart)
				part.Anchored = true
				part.CanCollide = false
				Ts:Create(part, TweenInfo.new(5), {Transparency = 1}):Play()
				game.Debris:AddItem(part, 5)
			end
			
			GridDoor_Right.PadLock.PrimaryPart.Anchored = false
			
			for _, v in GridDoor_Right.Chains:GetChildren() do
				if v:IsA("BasePart") then
					v.Anchored = false
					task.delay(3, disappear, v)
				end
			end
		end
	end
end)

local barrelPush = false

BarrelPush.Barrel.ProximityPrompt.Triggered:Connect(function(plr)
	BarrelPush.Barrel.PushingSound:Stop()
	barrelPush = true
	BarrelPush.hitBox.CanCollide = false
	BarrelPush.BillboardGui.Enabled = false
	BarrelPush.Barrel.ProximityPrompt.Enabled = false
	Ts:Create(BarrelPush.Barrel, TweenInfo.new(BarrelPush.Barrel.ProximityPrompt.HoldDuration), {CFrame = BarrelPush.endPos.CFrame}):Play()
	local prox = AsylumEntrance_Door.MainDoor:WaitForChild("ProximityPrompt") :: ProximityPrompt
	if prox then
		prox.Enabled = true
	end
	AsylumEntrance_Door.Locked.Value = false
end)

local CompletionDebounce = true

CompletionZone.Touched:Connect(function(hit)
	if hit.Parent:FindFirstChildWhichIsA("Humanoid") then
		local player = game.Players:GetPlayerFromCharacter(hit.Parent)
		if player and CompletionDebounce then
			CompletionDebounce = false
			ObjectivesModule.CompleteObjective(true, "Barred_Door")
			task.wait(1.5)
			TeleportModule:Teleport("AsylumReception", script) -- Send the script in case of bug for debug.
			StopAmbienceSound:FireAllClients()
		end
	end
end)
