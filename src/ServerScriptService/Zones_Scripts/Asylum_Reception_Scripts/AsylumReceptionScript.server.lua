--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local ActiveCutsceneEvent = Remotes:FindFirstChild("ActiveCutscene")

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local GameConfigModule = require(ModulesFolder:FindFirstChild("GameConfigModule"))
local TeleportModule = require(ModulesFolder:FindFirstChild("TeleportModule"))
local DoorCollision = require(ModulesFolder:FindFirstChild("DoorCollision"))
local DialogModule = require(ModulesFolder:FindFirstChild("PlayerDialogModule"))
local ObjectivesModule = require(ModulesFolder:FindFirstChild("ObjectivesModule"))

--//Asylum Reception Stuff
local Map = workspace:FindFirstChild("Map")
local AsylumReceptionFolder = Map:FindFirstChild("Area2_AsylumReception")
local InteractStuff = AsylumReceptionFolder:FindFirstChild("InteractStuff")

--//Entrance
local BrokenWall = InteractStuff:FindFirstChild("BrokenWall")
local PlayerPushAnim = BrokenWall:FindFirstChild("PlrPushAnim")
local BrokenWallPrompt = Instance.new("ProximityPrompt", BrokenWall.InteractPart)
local ObjectiveRestrictedArea = InteractStuff:FindFirstChild("ObjectiveRestrictedArea")

--//Npc's
local BathroomDeadGuy_Door = Map:FindFirstChild("Doors"):FindFirstChild("BathroomDeadGuy_Door")
local DeadGuyInteract = InteractStuff:FindFirstChild("DeadGuyInteract")
local DeadGuyFalling = InteractStuff:FindFirstChild("DeadGuyFalling")

--//Next area
local MetalDoor = InteractStuff:FindFirstChild("MetalDoor") -- The door for the next area
local ButtonMetalDoor = InteractStuff:FindFirstChild("ButtonMetalDoor")

BrokenWallPrompt.Style = Enum.ProximityPromptStyle.Custom
BrokenWallPrompt.MaxActivationDistance = GameConfigModule.InteractDistance
BrokenWallPrompt.ActionText = "Push"
BrokenWallPrompt.ObjectText = "Broken Wall"
BrokenWallPrompt.RequiresLineOfSight = false
BrokenWallPrompt.HoldDuration = 0.2

---//Rocks Area//---
local FallFloors = InteractStuff:FindFirstChild("FallFloors")
local BrokenFloors = InteractStuff:FindFirstChild("BrokenFloors")
local KillPart = InteractStuff:FindFirstChild("KillPart")
local RocksEndPart = InteractStuff:FindFirstChild("RocksEndPart")
local RocksEndPart2 = InteractStuff:FindFirstChild("RocksEndPart2")
local RocksBarrier = InteractStuff:FindFirstChild("RocksBarrier")

--//Sounds
local HitSounds = FallFloors.HitSounds
local FallingSound = FallFloors.FallingSound
local RocksSound = FallFloors.RocksSound
---//Rocks Area//---

local function loadFallRocksFunc()
	for i, v in FallFloors:GetChildren() do
		if v:IsA("Model") and v.PrimaryPart then
			if not v:HasTag("markedFallRock") then
				v:AddTag("markedFallRock")
				
				local Collider = v.PrimaryPart
				local debounce = true 
				
				Collider.Touched:Connect(function(hit)
					if hit.Parent:FindFirstChildWhichIsA("Humanoid") then
						local player = game.Players:GetPlayerFromCharacter(hit.Parent)
						if hit.Parent:FindFirstChildWhichIsA("Humanoid").Health > 0 and debounce and player then
							debounce = false
							
							local TouchSnd = RocksSound:Clone()
							TouchSnd.Parent = Collider
							TouchSnd:Play()
							game.Debris:AddItem(TouchSnd, TouchSnd.TimeLength + 1)
							
							task.wait(0.5)
							
							local FallSnd = FallingSound:Clone()
							FallSnd.Parent = Collider
							FallSnd:Play()
							game.Debris:AddItem(FallSnd, FallSnd.TimeLength + 1)
							
							for i, part in v:GetChildren() do
								if part:IsA("BasePart") then
									local function disappearAnim()
										local tween = Ts:Create(part, TweenInfo.new(2.5), {Transparency = 1})
										tween:Play()
										tween.Completed:Connect(function()
											part.CanCollide = false
										end)
									end
									local function unanchor()
										part.Anchored = false
									end
									if part == v.PrimaryPart then
										task.delay(0.6, unanchor)
									else
										unanchor()
									end
									task.delay(6, disappearAnim)
								end
							end
							
							task.wait(0.9)
							
							local randomHitSnd = HitSounds:GetChildren()[math.random(1, #HitSounds:GetChildren())]:Clone()
							randomHitSnd.Parent = Collider
							randomHitSnd:Play()
							game.Debris:AddItem(randomHitSnd, randomHitSnd.TimeLength + 1)
							game.Debris:AddItem(v, 10)
						end
					end
				end)
			end
		end
	end
end

FallFloors.ChildAdded:Connect(function(child)
	loadFallRocksFunc()
end)

KillPart.Touched:Connect(function(hit)
	if hit.Parent:FindFirstChildWhichIsA("Humanoid") then
		local Humanoid = hit.Parent:FindFirstChildWhichIsA("Humanoid")
		local player = game.Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			Humanoid.Health = 0
		end
	end
end)

local plrsInSafe = {}
local rocksCutscenePlayed = false

local function activeRocksCutscene()
	RocksBarrier.CanCollide = true
	rocksCutscenePlayed = true
	ActiveCutsceneEvent:FireAllClients("RocksFloor") -- Active rocks cutscene
	task.wait(2)
	TeleportModule:Teleport("RocksSafe", script, true)
end

RocksEndPart.Touched:Connect(function(hit)
	if hit.Parent:FindFirstChildWhichIsA("Humanoid") then
		local player = game.Players:GetPlayerFromCharacter(hit.Parent)
		
		if player and not table.find(plrsInSafe, player.Name) and not rocksCutscenePlayed then
			local totalPlrsInGame = {}
			
			for i, v in game.Players:GetPlayers() do
				if v.PlayerValues.IsAlive.Value then
					table.insert(totalPlrsInGame, v.Name)
				end
			end
			
			if #plrsInSafe >= #totalPlrsInGame then
				activeRocksCutscene()
			else
				table.insert(plrsInSafe, player.Name)
			end
		elseif not rocksCutscenePlayed then
			local totalPlrsInGame = {}
			
			for i, v in game.Players:GetPlayers() do
				if v.PlayerValues.IsAlive.Value then
					table.insert(totalPlrsInGame, v.Name)
				end
			end
			
			if #plrsInSafe >= #totalPlrsInGame then
				activeRocksCutscene()
			end
		end
	end
end)

--//This is for the players that don't wait for others players
RocksEndPart2.Touched:Connect(function(hit)
	if hit.Parent:FindFirstChildWhichIsA("Humanoid") then
		local Humanoid = hit.Parent:FindFirstChildWhichIsA("Humanoid")
		local Player = game.Players:GetPlayerFromCharacter(hit.Parent)
		if Humanoid.Health > 0 and Player and not rocksCutscenePlayed then
			activeRocksCutscene()
		end
	end
end)

ActiveCutsceneEvent.OnServerEvent:Connect(function(plr, event)
	if event == "RocksFloor" then
		for i, v in BrokenFloors:GetDescendants() do
			if v:IsA("BasePart") then
				v.Anchored = false
				v.CanCollide = false -- Disable the CanCollide to don't lag the game
				local function disappearAnim()
					local tween = Ts:Create(v, TweenInfo.new(2.5), {Transparency = 1})
					tween:Play()
					tween.Completed:Connect(function()
						v.CanCollide = false
					end)
				end
				task.delay(6, disappearAnim)
				game.Debris:AddItem(v, 10)
			end
		end
		
		task.wait()
		
		for i, v in FallFloors:GetDescendants() do
			if v:IsA("BasePart") then
				v.Anchored = false
				v.CanCollide = false -- Disable the CanCollide to don't lag the game
				local function disappearAnim()
					local tween = Ts:Create(v, TweenInfo.new(2.5), {Transparency = 1})
					tween:Play()
					tween.Completed:Connect(function()
						v.CanCollide = false
					end)
				end
				task.delay(6, disappearAnim)
				game.Debris:AddItem(v, 10)
			end
		end
		
		local fallSound = FallingSound:Clone()
		fallSound.Parent = InteractStuff:FindFirstChild("RocksSoundPart")
		fallSound.Volume = 3
		fallSound.RollOffMaxDistance = 150
		fallSound:Play()
		game.Debris:AddItem(fallSound, fallSound.TimeLength + 1)
		
		task.wait(1)
		
		local randomHitSound = HitSounds:GetChildren()[math.random(1, #HitSounds:GetChildren())]:Clone()
		randomHitSound.Parent = InteractStuff:FindFirstChild("RocksSoundPart")
		randomHitSound.Volume = 4
		randomHitSound.RollOffMinDistance = 100
		randomHitSound.RollOffMaxDistance = 170
		randomHitSound:Play()
		game.Debris:AddItem(randomHitSound, randomHitSound.TimeLength + 1)
	end
end)

BrokenWallPrompt.Triggered:Connect(function(Plr)
	local char = Plr.Character
	local hum = char:WaitForChild("Humanoid") :: Humanoid
	if char and hum.Health > 0 then
		local Animator = hum:WaitForChild("Animator") :: Animator
		local PlrPushAnim = Animator:LoadAnimation(PlayerPushAnim)
		local Pushed = false
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
		
		task.wait(3)
		
		if not Pushed then
			PushWall()
			Pushed = true
		end
	end
end)

local objectiveDebounce = true

ObjectiveRestrictedArea.Touched:Connect(function(hit)
	if hit.Parent:FindFirstChildWhichIsA("Humanoid") then
		if hit.Parent:FindFirstChildWhichIsA("Humanoid").Health > 0 then
			local player = game.Players:GetPlayerFromCharacter(hit.Parent)
			if player and objectiveDebounce then
				objectiveDebounce = false
				
				local ObjectiveFolder = ObjectiveRestrictedArea:FindFirstChild("Restricted_Area")
				local ObjectiveDesc = ObjectiveFolder.Description
				local ObjectiveName = ObjectiveFolder.Title
				
				DialogModule.Dialog(true, nil, ObjectiveRestrictedArea.PlrDialog)
				
				task.wait(7)
				
				ObjectivesModule.NewObjective(true, ObjectiveFolder.Name, ObjectiveName.Value, ObjectiveDesc.Value)
			end
		end
	end
end)

local openedBathroomDoor = false

BathroomDeadGuy_Door.State.Changed:Connect(function(newValue)
	if newValue then
		if not openedBathroomDoor then
			openedBathroomDoor = true
			if DeadGuyInteract:FindFirstChildWhichIsA("Sound") then
				DeadGuyInteract:FindFirstChildWhichIsA("Sound"):Play()
			end
		end
	end
end)

local proxDeadGuy = Instance.new("ProximityPrompt", DeadGuyInteract)
proxDeadGuy.MaxActivationDistance = GameConfigModule.InteractDistance
proxDeadGuy.RequiresLineOfSight = false
proxDeadGuy.ActionText = "Inspect"
proxDeadGuy.ObjectText = "Dead Patient"
proxDeadGuy.Style = Enum.ProximityPromptStyle.Custom
proxDeadGuy.HoldDuration = 0.2

local plrsOnDebounceDeadGuy = {}

proxDeadGuy.Triggered:Connect(function(plr)
	if table.find(plrsOnDebounceDeadGuy, plr) then return end
	
	local function removeDebounce()
		for i, v in ipairs(plrsOnDebounceDeadGuy) do
			if v == plr then
				table.remove(plrsOnDebounceDeadGuy, i)
			end
		end
	end
	
	table.insert(plrsOnDebounceDeadGuy, plr)
	DialogModule.Dialog(false, plr, DeadGuyInteract.PlrDialog)
	task.delay(6, removeDebounce)
end)

local guyFallingDebounce = true
local DeadGuyFall = AsylumReceptionFolder.NPCs:FindFirstChild("Dead_Patient_Elevator")
local FallAnim = DeadGuyFall:FindFirstChild("FallingAnim")
local npcAnimator = DeadGuyFall:FindFirstChild("Humanoid"):FindFirstChild("Animator")
local animFall = npcAnimator:LoadAnimation(FallAnim)
animFall:Play()
animFall:AdjustSpeed(0)
animFall.TimePosition = 0.01

DeadGuyFalling.Touched:Connect(function(hit)
	if hit.Parent:FindFirstChildWhichIsA("Humanoid") then
		if hit.Parent:FindFirstChildWhichIsA("Humanoid").Health > 0 then
			local plr = game.Players:GetPlayerFromCharacter(hit.Parent)
			if plr and guyFallingDebounce then
				guyFallingDebounce = false
				
				animFall:AdjustSpeed(0.5)
				
				animFall.KeyframeReached:Connect(function(keyFrame)
					if keyFrame == "APPEAR" then
						DeadGuyFalling:FindFirstChild("IntenseSound"):Play()
					end
				end)
				
				task.wait(3.7)
				
				DialogModule.Dialog(false, plr, nil, "This place just keeps getting worse...")
			end
		end
	end
end)

local metalDoorDebounce = true
local proxButton = Instance.new("ProximityPrompt", ButtonMetalDoor.Interact)
proxButton.MaxActivationDistance = GameConfigModule.InteractDistance
proxButton.Style = Enum.ProximityPromptStyle.Custom
proxButton.RequiresLineOfSight = false
proxButton.ActionText = "Active"
proxButton.ObjectText = "Button"
proxButton.HoldDuration = 0.25

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
			
			if state == "open" then
				DoorCollision.disable(MetalDoor)
				openSound:Play()
				Ts:Create(leftDoor.Hinge, TweenInfo.new(openSound.TimeLength), {CFrame = leftDoor.OpenedPos}):Play()
				Ts:Create(rightDoor.Hinge, TweenInfo.new(openSound.TimeLength), {CFrame = rightDoor.OpenedPos}):Play()
			elseif state == "flick" then
				lockedSound:Play()
				Ts:Create(leftDoor.Hinge, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {CFrame = leftDoor.FlickPos.CFrame}):Play()
				Ts:Create(rightDoor.Hinge, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {CFrame = rightDoor.FlickPos.CFrame}):Play()
				task.wait(0.2)
				Ts:Create(leftDoor.Hinge, TweenInfo.new(0.1), {CFrame = leftDoor.ClosedPos.CFrame}):Play()
				Ts:Create(rightDoor.Hinge, TweenInfo.new(0.07), {CFrame = rightDoor.ClosedPos.CFrame}):Play()
			end
		end
		
		--check if the energy is on
		
		animButton()
		changeDoor("flick")
		
		task.wait(0.2)
		
		metalDoorDebounce = true
	end
end)

task.wait(3) -- Delay to don't bug

loadFallRocksFunc()
