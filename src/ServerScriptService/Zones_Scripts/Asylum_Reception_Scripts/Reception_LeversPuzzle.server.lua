--//Services
local Ts = game:GetService("TweenService")
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local InspectEvent = Remotes:FindFirstChild("Inspect")
local GamePuzzlesEvent = Remotes:FindFirstChild("gamePuzzles")

--//Asylum Reception Stuff
local Map = workspace:FindFirstChild("Map")
local AsylumReceptionFolder = Map:FindFirstChild("Area2_AsylumReception")
local InteractStuff = AsylumReceptionFolder:FindFirstChild("InteractStuff")

--//Levers machine stuff
local Storage_Machine = InteractStuff:FindFirstChild("Storage_Machine")
local Levers = Storage_Machine:FindFirstChild("Levers")
local Hatch = Storage_Machine:FindFirstChild("Hatch")
local proxLevers = Instance.new("ProximityPrompt", Levers.Interact)
local proxHatch = Instance.new("ProximityPrompt", Hatch.Interact)
local LeversPuzzle_ConsoleGui = Storage_Machine.LeverPuzzle_ConsoleGui
local BlockVentMachine = InteractStuff:FindFirstChild("BlockVentMachine")

--//Levers
local Lever_1 = Levers.Lever_1
local Lever_2 = Levers.Lever_2
local Lever_3 = Levers.Lever_3
local Lever_4 = Levers.Lever_4
local Lever_5 = Levers.Lever_5
local Lever_6 = Levers.Lever_6
local Lever_7 = Levers.Lever_7

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local GameConfigModule = require(ModulesFolder:FindFirstChild("GameConfigModule"))
local DialogModule = require(ModulesFolder:FindFirstChild("PlayerDialogModule"))
local ObjectivesModule = require(ModulesFolder:FindFirstChild("ObjectivesModule"))
local SecureSearch = require(ModulesFolder:WaitForChild("SecureSearch"))
local MoneyModule = require(ModulesFolder:WaitForChild("MoneyModule"))

--//Values
local correctLevers = false
local currentPlrInspect = nil
local hatchDebounce = true
local depuration = false -- If true will show depuration messages
local leversDebounce = true
local puzzleReward = 5
local allLevers = {Lever_1, Lever_2, Lever_3, Lever_4, Lever_5, Lever_6, Lever_7}

--//Setup
proxLevers.MaxActivationDistance = GameConfigModule.InteractDistance
proxLevers.RequiresLineOfSight = false
proxLevers.Style = Enum.ProximityPromptStyle.Custom
proxLevers.HoldDuration = 0.15
proxLevers.ActionText = "Inspect"
proxLevers.ObjectText = "Levers"

proxHatch.MaxActivationDistance = GameConfigModule.InteractDistance
proxHatch.RequiresLineOfSight = false
proxHatch.Style = Enum.ProximityPromptStyle.Custom
proxHatch.HoldDuration = 0.15
proxHatch.ActionText = "Inspect"
proxHatch.ObjectText = "Hatch"

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

local function checkFreeSpot()
	local freeSpot = nil
	for i, v in Levers.LeverPositions:GetChildren() do
		if v:FindFirstChild("Ocuped") then
			if v.Ocuped.Value == "" then
				freeSpot = v
			end
		end
	end
	return freeSpot
end

local function checkLeverSpot(leverModel: Model)
	for i, v in Levers.LeverPositions:GetChildren() do
		if v:FindFirstChild("Ocuped") then
			if v.Ocuped.Value == leverModel.Name then
				return v
			end
		end
	end
end

local function checkLeverInThatSpot(spot)
	for i, v in Levers.LeverPositions:GetChildren() do
		if v:FindFirstChild("Ocuped") then
			if v.Ocuped.Value == spot then
				return v
			end
		end
	end
end

local function makeRayCastVisible(origin: Vector3, direction: Vector3)
	if not depuration then return end
	local ray = Ray.new(origin, direction)
	local hit, position = workspace:FindPartOnRay(ray)
	if hit then
		local distance = (origin - position).Magnitude
		local p = Instance.new("Part")
		p.CanQuery = false
		p.CanTouch = false
		p.Size = Vector3.new(0.02, 0.02, distance)
		p.CFrame = CFrame.new(origin, position) * CFrame.new(0, 0, -distance / 2)
		p.Anchored = true
		p.CanCollide = false
		p.Transparency = 0.5
		p.Material = Enum.Material.Neon
		p.Color = Color3.fromRGB(255, 0, 0)
		p.Parent = workspace
		game.Debris:AddItem(p, 12)
	end
end

local function moveLever(leverModel: Model, setup: boolean)
	if not leverModel then return end
	local hinge = leverModel:FindFirstChild("Hinge") :: BasePart
	if hinge then
		local spot = checkFreeSpot()
		local leverSpot = checkLeverSpot(leverModel)
		local debugInfo = {
			["Go To: "] = spot,
			["Current Spot: "] = leverSpot
		}
		if depuration then
			warn(debugInfo)
		end
		
		local function UpdateOcupedValues()
			if leverSpot then
				leverSpot.Ocuped.Value = ""
			end
			spot.Ocuped.Value = leverModel.Name
		end
		
		if spot then
			if spot.Name == "Pos_0" then
				local rayCastParams = RaycastParams.new()
				rayCastParams.FilterType = Enum.RaycastFilterType.Exclude
				rayCastParams.FilterDescendantsInstances = {leverModel}
				
				makeRayCastVisible(hinge.Position, Vector3.new(-3, 0, 0))
				
				local raycastResult = workspace:Raycast(hinge.Position, Vector3.new(-3, 0, 0), rayCastParams)
				
				if raycastResult then
					if raycastResult.Instance then
						UpdateOcupedValues()
						if setup then
							hinge.CFrame = spot.CFrame
							return
						end
						playSound(Storage_Machine.MoveLeverSound, hinge)
						Ts:Create(hinge, TweenInfo.new(0.3, Enum.EasingStyle.Back), {CFrame = raycastResult.Instance.CFrame}):Play()
						task.wait(0.3)
						playSound(Storage_Machine.MoveLeverSound2, hinge)
						Ts:Create(hinge, TweenInfo.new(0.5, Enum.EasingStyle.Back), {CFrame = spot.CFrame}):Play()
						task.wait(0.5)
					end
				end
			else
				if leverSpot.Name == "Pos_0" then
					local way1 = Levers.LeverPositions:FindFirstChild(spot.Name.."a")
					
					if way1 then
						UpdateOcupedValues()
						if setup then
							hinge.CFrame = spot.CFrame
							return
						end
						playSound(Storage_Machine.MoveLeverSound, hinge)
						Ts:Create(hinge, TweenInfo.new(0.3, Enum.EasingStyle.Back), {CFrame = way1.CFrame}):Play()
						task.wait(0.3)
						playSound(Storage_Machine.MoveLeverSound2, hinge)
						Ts:Create(hinge, TweenInfo.new(0.5, Enum.EasingStyle.Back), {CFrame = spot.CFrame}):Play()
						task.wait(0.5)
					end
					return
				end
				
				local rayCastParams1 = RaycastParams.new()
				rayCastParams1.FilterType = Enum.RaycastFilterType.Exclude
				rayCastParams1.FilterDescendantsInstances = {leverModel}
				
				local sideToGo = nil
				local ignoreList_ = {}
				table.insert(ignoreList_, leverModel)
				
				for i, v in Levers.LeverPositions:GetChildren() do
					if v ~= spot then
						table.insert(ignoreList_, v)
					end
				end
				for i, v in Levers:GetChildren() do
					if v:IsA("Model") then
						table.insert(ignoreList_, v)
					end
				end
				
				local rayCastParams2 = RaycastParams.new()
				rayCastParams2.FilterType = Enum.RaycastFilterType.Exclude
				rayCastParams2.FilterDescendantsInstances = ignoreList_
				local raycastResult2 = workspace:Raycast(hinge.Position, Vector3.new(0, 0, -10), rayCastParams2)
				if raycastResult2 then
					if raycastResult2.Instance then
						if depuration then
							print("pos to go:", raycastResult2.Instance)
						end
						if raycastResult2.Instance == spot then
							sideToGo = "right"
						else
							sideToGo = "left"
						end
					end
				end
				
				local raycastResult1 = workspace:Raycast(hinge.Position, Vector3.new(-3, 0, 0), rayCastParams1)
				makeRayCastVisible(hinge.Position, Vector3.new(-3, 0, 0))
				
				if raycastResult1 then
					if raycastResult1.Instance then
						local way1 = raycastResult1.Instance
						local way2 = nil
						local ignoreList = {leverModel}
						
						local function calculateWay2(side: string)
							local rayCastParams_ = RaycastParams.new()
							rayCastParams_.FilterType = Enum.RaycastFilterType.Exclude
							rayCastParams_.FilterDescendantsInstances = ignoreList
							
							local direction = nil
							if side == "right" then
								direction = Vector3.new(0, 0, -10)
							else
								direction = Vector3.new(0, 0, 10)
							end
							
							local raycastResult_ = workspace:Raycast(way1.CFrame.Position, direction, rayCastParams_)
							makeRayCastVisible(way1.CFrame.Position, direction)
							if raycastResult_ then
								if raycastResult_.Instance then
									local rayCastParams__ = RaycastParams.new()
									rayCastParams__.FilterType = Enum.RaycastFilterType.Exclude
									rayCastParams__.FilterDescendantsInstances = ignoreList
									local raycastResult__ = workspace:Raycast(raycastResult_.Instance.CFrame.Position, Vector3.new(3, 0, 0), rayCastParams__)
									makeRayCastVisible(raycastResult_.Instance.CFrame.Position, direction)
									
									if raycastResult__ then
										if raycastResult__.Instance then
											if raycastResult__.Instance.Name == spot.Name then
												way2 = raycastResult_.Instance
											else
												table.insert(ignoreList, raycastResult_.Instance)
												task.wait()
												calculateWay2(side)
											end
										end
									end
								end
							end
						end
						
						if sideToGo == "left" then
							calculateWay2("left")
						else
							calculateWay2("right")
						end
						
						if way1 and way2 then
							UpdateOcupedValues()
							
							if setup then
								hinge.CFrame = spot.CFrame
								return
							end
							
							playSound(Storage_Machine.MoveLeverSound, hinge)
							Ts:Create(hinge, TweenInfo.new(0.3, Enum.EasingStyle.Back), {CFrame = way1.CFrame}):Play()
							task.wait(0.3)
							playSound(Storage_Machine.MoveLeverSound, hinge)
							Ts:Create(hinge, TweenInfo.new(0.5, Enum.EasingStyle.Back), {CFrame = way2.CFrame}):Play()
							task.wait(0.5)
							playSound(Storage_Machine.MoveLeverSound2, hinge)
							Ts:Create(hinge, TweenInfo.new(0.3, Enum.EasingStyle.Back), {CFrame = spot.CFrame}):Play()
							task.wait(0.3)
						else
							if depuration then
								warn("not way2 - levers puzzle script")
							end
						end
					end
				end
			end
		end
	end
end

local function checkIfCorrectOrder()
	local lever1 = false
	local lever2 = false
	local lever3 = false
	local lever4 = false
	local lever5 = false
	local lever6 = false
	local lever7 = false
	local correct = false
	
	local spot1 = checkLeverSpot(Lever_1)
	if string.sub(spot1.Name, -1, -1) == Lever_1.Name:sub(-1, -1) then
		lever1 = true
	end
	local spot2 = checkLeverSpot(Lever_2)
	if string.sub(spot2.Name, -1, -1) == Lever_2.Name:sub(-1, -1) then
		lever2 = true
	end
	local spot3 = checkLeverSpot(Lever_3)
	if string.sub(spot3.Name, -1, -1) == Lever_3.Name:sub(-1, -1) then
		lever3 = true
	end
	local spot4 = checkLeverSpot(Lever_4)
	if string.sub(spot4.Name, -1, -1) == Lever_4.Name:sub(-1, -1) then
		lever4 = true
	end
	local spot5 = checkLeverSpot(Lever_5)
	if string.sub(spot5.Name, -1, -1) == Lever_5.Name:sub(-1, -1) then
		lever5 = true
	end
	local spot6 = checkLeverSpot(Lever_6)
	if string.sub(spot6.Name, -1, -1) == Lever_6.Name:sub(-1, -1) then
		lever6 = true
	end
	local spot7 = checkLeverSpot(Lever_7)
	if string.sub(spot7.Name, -1, -1) == Lever_7.Name:sub(-1, -1) then
		lever7 = true
	end
	
	correct = lever1 and lever2 and lever3 and lever4 and lever5 and lever6 and lever7
	return correct
end

local function setupLevers()
	local levers = {}
	
	for i, v in Levers:GetChildren() do
		if v:IsA("Model") then
			table.insert(levers, v)
		end
	end
	
	for i=1, 50 do
		local randomLever = math.random(1, #levers)
		local lever = levers[randomLever]
		moveLever(lever, true)
		task.wait()
	end
	
	local correct = checkIfCorrectOrder()
	if correct then
		setupLevers()
	end
end

setupLevers()

local proxInteractBarrier = Instance.new("ProximityPrompt", BlockVentMachine.BarrierPart)
proxInteractBarrier.MaxActivationDistance = GameConfigModule.InteractDistance
proxInteractBarrier.RequiresLineOfSight = false
proxInteractBarrier.ActionText = "Inspect"
proxInteractBarrier.ObjectText = "Vent"

proxInteractBarrier.Triggered:Connect(function(plr)
	local char = plr.Character
	if not char then return end
	
	local hum = char:FindFirstChild("Humanoid") :: Humanoid
	if not hum or hum.Health <= 0 then return end
	
	DialogModule.Dialog(false, plr, nil, "I have to figure out a way to turn off this gas.")
end)

local function moveLeverMain(lever: Model, plr: Player, clicker: ClickDetector?)
	if not leversDebounce then return end
	leversDebounce = false
	moveLever(lever)
	correctLevers = checkIfCorrectOrder()
	
	if not correctLevers then
		leversDebounce = true
	else -- Win
		--//Enable vent patch
		BlockVentMachine.GasParticle.GasSound:Stop()
		BlockVentMachine.GasParticle.ParticleEmitter.Enabled = false
		BlockVentMachine.BarrierPart.CanCollide = false
		BlockVentMachine.PuzzleRoomVentLight.PointLight.Color = Color3.fromRGB(62, 255, 3)
		BlockVentMachine.BarrierPart.BillboardGui.Enabled = false
		proxInteractBarrier.Enabled = false
		
		if clicker then
			clicker.MaxActivationDistance = 0
		end
		
		MoneyModule.Give(plr, puzzleReward)
		
		for i, v in Storage_Machine.MachineLights:GetChildren() do
			v.LightPart.Color = Color3.new(0.439216, 1, 0.352941)
			for i, lightInstance: Instance in v.LightPart:GetDescendants() do
				if lightInstance:IsA("SpotLight") or lightInstance:IsA("PointLight") or lightInstance:IsA("SurfaceLight") then
					lightInstance.Color = Color3.new(0.439216, 1, 0.352941)
				end
			end
			playSound(v.LightPart.CorrectSound)
		end
		
		InspectEvent:FireClient(plr, "InspectOFF")
	end
end

for i, v in pairs(allLevers) do
	local clicker = v.ClickDetector
	local highlight = v.Highlight
	
	clicker.MouseClick:Connect(function(plr)
		if not (plr == currentPlrInspect) then return end
		moveLeverMain(v, plr, clicker)
	end)
	
	clicker.MouseHoverEnter:Connect(function(plr)
		if plr == currentPlrInspect then
			Ts:Create(highlight, TweenInfo.new(0.2), {OutlineTransparency = 0.5}):Play()
		end
	end)
	
	clicker.MouseHoverLeave:Connect(function(plr)
		if plr == currentPlrInspect then
			Ts:Create(highlight, TweenInfo.new(0.2), {OutlineTransparency = 1}):Play()
		end
	end)
end

--//Move on console
GamePuzzlesEvent.OnServerEvent:Connect(function(plr, action)
	if not plr or plr ~= currentPlrInspect then return end
	if action == "Levers_1" then
		moveLeverMain(Lever_1, plr)
	elseif action == "Levers_2" then
		moveLeverMain(Lever_2, plr)
	elseif action == "Levers_3" then
		moveLeverMain(Lever_3, plr)
	elseif action == "Levers_4" then
		moveLeverMain(Lever_4, plr)
	elseif action == "Levers_5" then
		moveLeverMain(Lever_5, plr)
	elseif action == "Levers_6" then
		moveLeverMain(Lever_6, plr)
	elseif action == "Levers_7" then
		moveLeverMain(Lever_7, plr)
	end
end)

--//Join in the puzzle
proxLevers.Triggered:Connect(function(plr)
	if not currentPlrInspect and plr.Character then
		local hum = plr.Character:WaitForChild("Humanoid")
		if hum and hum.Health > 0 then
			currentPlrInspect = plr
			InspectEvent:FireClient(plr, "InspectON", Levers.CamPos, false, true)
			proxLevers.Enabled = false
			
			local toolOnHand = plr.Character:FindFirstChildWhichIsA("Tool")
			if toolOnHand then
				toolOnHand.Parent = plr.Backpack
			end
			
			local gui = LeversPuzzle_ConsoleGui:Clone()
			gui.Parent = plr.PlayerGui
			gui.Name = "LEVERS_PUZZLE_CONSOLE_GUI"
		end
	end
end)

InspectEvent.OnServerEvent:Connect(function(plr, event)
	if event == "InspectOFF" then
		if plr == currentPlrInspect then
			currentPlrInspect = nil
			proxLevers.Enabled = true
			
			--//Remove the old gui from player gui
			if plr.PlayerGui:FindFirstChild("LEVERS_PUZZLE_CONSOLE_GUI") then
				plr.PlayerGui["LEVERS_PUZZLE_CONSOLE_GUI"]:Destroy()
			end
			
			for i, v in pairs(allLevers) do
				Ts:Create(v.Highlight, TweenInfo.new(0.2), {OutlineTransparency = 1}):Play()
			end
		end
	end
end)

proxHatch.Triggered:Connect(function(plr)
	if not hatchDebounce then return end
	hatchDebounce = false
	if not correctLevers then
		playSound(Hatch.Interact.LockedSound)
		Ts:Create(Hatch.Hinge, TweenInfo.new(0.1), {CFrame = Hatch.FlickPos.CFrame}):Play()
		task.wait(0.1)
		Ts:Create(Hatch.Hinge, TweenInfo.new(0.07, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {CFrame = Hatch.ClosedPos.CFrame}):Play()
		task.wait(0.1)
	else
		playSound(Hatch.Interact.OpenSound)
		Ts:Create(Hatch.Hinge, TweenInfo.new(0.1), {CFrame = Hatch.OpenedPos.CFrame}):Play()
		proxHatch.Enabled = false
		
		local paper3 = SecureSearch:GetInstance(Map.Items, "Paper 3")
		if paper3 then
			local prox = paper3.PrimaryPart.ProximityPrompt :: ProximityPrompt
			prox.RequiresLineOfSight = false
		end
		
		local function backToNormal()
			playSound(Hatch.Interact.CloseSound, Hatch.Interact)
			Ts:Create(Hatch.Hinge, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {CFrame = Hatch.ClosedPos.CFrame}):Play()
			hatchDebounce = true
			proxHatch.Enabled = true
			local paper3 = SecureSearch:GetInstance(Map.Items, "Paper 3")
			if paper3 then
				local prox = paper3.PrimaryPart.ProximityPrompt :: ProximityPrompt
				prox.RequiresLineOfSight = true
			end
		end
		task.delay(5, backToNormal)
		return
	end
	hatchDebounce = true
end)
