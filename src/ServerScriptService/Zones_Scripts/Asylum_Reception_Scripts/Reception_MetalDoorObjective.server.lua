--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local ChangeCamEvent = Remotes:WaitForChild("ChangeCam")
local ActiveCutsceneEvent = Remotes:FindFirstChild("ActiveCutscene")
local PlrValuesEvent = Remotes:FindFirstChild("PlayerValues")

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local GameConfigModule = require(ModulesFolder:FindFirstChild("GameConfigModule"))
local DialogModule = require(ModulesFolder:FindFirstChild("PlayerDialogModule"))
local ObjectivesModule = require(ModulesFolder:FindFirstChild("ObjectivesModule"))
local TeleportModule = require(ModulesFolder:FindFirstChild("TeleportModule"))
local DoorCollision = require(ModulesFolder:FindFirstChild("DoorCollision"))

--//Asylum Reception Stuff
local Map = workspace:FindFirstChild("Map")
local AsylumReceptionFolder = Map:FindFirstChild("Area2_AsylumReception")
local InteractStuff = AsylumReceptionFolder:FindFirstChild("InteractStuff")

--//Entrance - Broken Wall
local BrokenWall = InteractStuff:FindFirstChild("BrokenWall")
local PlayerPushAnim = BrokenWall:FindFirstChild("PlrPushAnim")
local PlayerPushAnim2 = BrokenWall:FindFirstChild("PlrPushAnim2")
local BrokenWallPrompt = Instance.new("ProximityPrompt", BrokenWall.InteractPart)
local ObjectiveRestrictedArea = InteractStuff:FindFirstChild("ObjectiveRestrictedArea")

--//Next area
local MetalDoor = InteractStuff:FindFirstChild("MetalDoor") -- The door for the next area
local ButtonMetalDoor = InteractStuff:FindFirstChild("ButtonMetalDoor")
local CutsceneFlayedChase1 = Map:FindFirstChild("Cutscenes"):FindFirstChild("FlayedChaseCutscene")
local proxButton = Instance.new("ProximityPrompt", ButtonMetalDoor.Interact)
local MonsterSpawn = InteractStuff:FindFirstChild("MonsterSpawnChase1")
local MonsterAI = Rs:FindFirstChild("Monsters"):FindFirstChild("DemogorgonMonster"):FindFirstChild("Demogorgon_Chase")
local chaseBlocks = InteractStuff:FindFirstChild("Chase1_Blocks")

--//Values
local objectiveDebounce = true
local metalDoorDebounce = true
local opened = false
local enabledChase = false
local EnergyRestored = ButtonMetalDoor:FindFirstChild("EnergyRestored")

--//Setup
ButtonMetalDoor.BillboardGui.Enabled = false
BrokenWallPrompt.Style = Enum.ProximityPromptStyle.Custom
BrokenWallPrompt.MaxActivationDistance = GameConfigModule.InteractDistance
BrokenWallPrompt.ActionText = "Push"
BrokenWallPrompt.ObjectText = "Broken Wall"
BrokenWallPrompt.RequiresLineOfSight = false
BrokenWallPrompt.HoldDuration = 0.2

proxButton.MaxActivationDistance = GameConfigModule.InteractDistance
proxButton.Style = Enum.ProximityPromptStyle.Custom
proxButton.RequiresLineOfSight = false
proxButton.ActionText = "Active"
proxButton.ObjectText = "Button"
proxButton.HoldDuration = 0.25

--[[
local callback = function(assetId, assetFetchStatus)
	print("Asset ID:", assetId)
	print("AssetFetchStatus:", assetFetchStatus)
end
]]

ContentProvider:PreloadAsync({PlayerPushAnim, PlayerPushAnim2})

BrokenWallPrompt.Triggered:Connect(function(Plr)
	local char = Plr.Character
	local hum = char:WaitForChild("Humanoid") :: Humanoid
	
	if char and hum.Health > 0 then
		local HRP = char:FindFirstChild("HumanoidRootPart") :: BasePart
		local Animator = hum:WaitForChild("Animator") :: Animator
		local PlrPushAnim = Animator:LoadAnimation(PlayerPushAnim2)
		local Pushed = false
		
		HRP.Anchored = true
		HRP.CFrame = CFrame.new(Vector3.new(BrokenWall.AnimPos.Position.X, HRP.Position.Y, BrokenWall.AnimPos.Position.Z), BrokenWall.InteractPart.Position)
		
		--//Disable plr cam
		ChangeCamEvent:FireClient(Plr, true)
		
		BrokenWall.BillboardGui.Enabled = false
		PlrPushAnim:Play()
		BrokenWallPrompt.MaxActivationDistance = 0
		
		local function PushWall()
			for i, v: BasePart in BrokenWall:GetDescendants() do
				if v.Name ~= "InteractPart" and v:IsA("BasePart") then
					v.Anchored = false
					
					local function disappearAnim()
						v.Anchored = true
						v.CanCollide = false
						local tween = Ts:Create(v, TweenInfo.new(3), {Transparency = 1})
						tween:Play()
						tween.Completed:Connect(function()
							v.CanCollide = false
							game.Debris:AddItem(v, 1)
						end)
					end
					
					local VectorForce = Instance.new("VectorForce", v)
					VectorForce.ApplyAtCenterOfMass = true
					VectorForce.Force = -BrokenWall.InteractPart.CFrame.LookVector * 888000
					game.Debris:AddItem(VectorForce, 0.1)
					
					task.delay(2.3, disappearAnim)
				end
			end
			BrokenWall.InteractPart.HitSound:Play()
		end
		
		PlrPushAnim.KeyframeReached:Connect(function(KeyName)
			if KeyName == "HIT" then
				PushWall()
				Pushed = true
			end
		end)
		
		PlrPushAnim.Stopped:Connect(function()
			--//Enable plr cam
			ChangeCamEvent:FireClient(Plr, false)
			HRP.Anchored = false
		end)
		
		task.wait(8)
		
		if not Pushed then
			PushWall()
			Pushed = true
		end
		
		HRP.Anchored = false
	end
end)

ObjectiveRestrictedArea.Touched:Connect(function(hit)
	if hit.Parent:FindFirstChildWhichIsA("Humanoid") then
		if hit.Parent:FindFirstChildWhichIsA("Humanoid").Health > 0 then
			local player = game.Players:GetPlayerFromCharacter(hit.Parent)
			if player and objectiveDebounce then
				objectiveDebounce = false
				
				local ObjectiveFolder = ObjectiveRestrictedArea:FindFirstChild("Restricted_Area")
				local ObjectiveDesc = ObjectiveFolder.Description
				local ObjectiveName = ObjectiveFolder.Title
				local ObjectiveCutsceneFolder = ObjectiveFolder.CutsceneFolder
				
				DialogModule.Dialog(true, nil, ObjectiveRestrictedArea.PlrDialog)
				
				task.wait(7)
				
				ObjectivesModule.NewObjective(true, ObjectiveFolder.Name, ObjectiveName.Value, ObjectiveDesc.Value, ObjectiveCutsceneFolder.Value)
			end
		end
	end
end)

local function startFinalChase()
	task.delay(2, function()
		TeleportModule:Teleport("FlayedChase1", script, true, true)
	end)
	ActiveCutsceneEvent:FireAllClients("ChaseStartFlayed")
	warn("Starting chase scene 1.")
end

ActiveCutsceneEvent.OnServerEvent:Connect(function(plr, event)
	if event == "ChaseFlayed1_Start" and not enabledChase then
		enabledChase = true
		
		for i, v in chaseBlocks:GetChildren() do
			if v:IsA("BasePart") then
				v.CanCollide = true
			end
		end
		
		local flayedAI = MonsterAI:Clone()
		flayedAI.Parent = Map:FindFirstChild("Monsters")
		flayedAI.PrimaryPart:PivotTo(MonsterSpawn.CFrame)
	end
end)

local TestMode = false

--//Open the metal door when the energy is restored
proxButton.Triggered:Connect(function(plr)
	if metalDoorDebounce then
		metalDoorDebounce = false
		
		local function animButton()
			local tween = Ts:Create(ButtonMetalDoor.Button, TweenInfo.new(0.07), {CFrame = ButtonMetalDoor.ClickedPos.CFrame})
			tween:Play()
			ButtonMetalDoor.Interact.ClickSound:Play()
			
			tween.Completed:Connect(function()
				Ts:Create(ButtonMetalDoor.Button, TweenInfo.new(0.03), {CFrame = ButtonMetalDoor.NormalPos.CFrame}):Play()
			end)
		end
		
		local function changeDoor(state: string)
			local leftDoor = MetalDoor.LeftDoor
			local rightDoor = MetalDoor.RightDoor
			local openSound = MetalDoor.MainPart.OpenSound
			local lockedSound = MetalDoor.MainPart.LockedSound
			
			if state == "open" and not opened then
				opened = true
				DoorCollision.disable(MetalDoor)
				openSound:Play()
				Ts:Create(leftDoor.Hinge, TweenInfo.new(openSound.TimeLength), {CFrame = leftDoor.OpenedPos.CFrame}):Play()
				Ts:Create(rightDoor.Hinge, TweenInfo.new(openSound.TimeLength), {CFrame = rightDoor.OpenedPos.CFrame}):Play()
				task.wait(3.5)
				startFinalChase()
			elseif state == "flick" then
				lockedSound:Play()
				Ts:Create(leftDoor.Hinge, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {CFrame = leftDoor.FlickPos.CFrame}):Play()
				Ts:Create(rightDoor.Hinge, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {CFrame = rightDoor.FlickPos.CFrame}):Play()
				task.wait(0.2)
				Ts:Create(leftDoor.Hinge, TweenInfo.new(0.1), {CFrame = leftDoor.ClosedPos.CFrame}):Play()
				Ts:Create(rightDoor.Hinge, TweenInfo.new(0.07), {CFrame = rightDoor.ClosedPos.CFrame}):Play()
			end
		end
		
		animButton()
		
		if TestMode and game:GetService("RunService"):IsStudio() then --> TESTING
			changeDoor("open")
			return
		end
		
		if EnergyRestored.Value then
			ButtonMetalDoor.BillboardGui.Enabled = false
			changeDoor("open")
		else
			changeDoor("flick")
		end
		
		task.wait(0.2)
		
		metalDoorDebounce = true
	end
end)

--//TESTING\\--

--[[
warn("Going to spawn chase monster: ")
task.wait(7)
print("spawned chase monster.")
local flayedAI = MonsterAI:Clone()
flayedAI.Parent = Map:FindFirstChild("Monsters")
flayedAI.PrimaryPart:PivotTo(workspace.monsterSpawnTest.CFrame)
]]
