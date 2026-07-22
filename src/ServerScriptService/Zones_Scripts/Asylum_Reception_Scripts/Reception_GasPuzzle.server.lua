--//Services
local Ts = game:GetService("TweenService")
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local ActiveCutsceneEvent = Remotes:FindFirstChild("ActiveCutscene")

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local GameConfigModule = require(ModulesFolder:FindFirstChild("GameConfigModule"))
local ObjectivesModule = require(ModulesFolder:FindFirstChild("ObjectivesModule"))
local DialogModule = require(ModulesFolder:FindFirstChild("PlayerDialogModule"))
local TeleportModule = require(ModulesFolder:FindFirstChild("TeleportModule"))
local BadgesModule = require(ModulesFolder:FindFirstChild("Badges"))
local MoneyModule = require(ModulesFolder:FindFirstChild("MoneyModule"))

--//Asylum Reception Stuff
local Map = workspace:FindFirstChild("Map")
local AsylumReceptionFolder = Map:FindFirstChild("Area2_AsylumReception")
local InteractStuff = AsylumReceptionFolder:FindFirstChild("InteractStuff")
local ObjectiveBasementPart = InteractStuff:FindFirstChild("ObjectiveBasement")
local Crowbar = Map.Items:WaitForChild("Crowbar")

--//Gaz Puzzle
local GasMachine = InteractStuff:FindFirstChild("Gas_Machine")
local Pressure_Gauge1 = GasMachine.Pressure_Gauge1
local Pressure_Gauge2 = GasMachine.Pressure_Gauge2
local Pressure_Gauge3 = GasMachine.Pressure_Gauge3
local Pressure_Gauge4 = GasMachine.Pressure_Gauge4
local ValvesFolder = GasMachine.Valves
local SoundsFolder = GasMachine.Sounds
local ValveSounds = SoundsFolder.ValveSounds

--//Values
local currentMode = 0
local objectiveDebounce = true
local puzzleReward = math.random(10, 15)

--//Setup
GasMachine.BillboardGui.Enabled = false

ObjectiveBasementPart.Touched:Connect(function(hit)
	if hit.Parent and hit.Parent:FindFirstChild("Humanoid") then
		if hit.Parent:FindFirstChild("Humanoid").Health > 0 and objectiveDebounce then
			objectiveDebounce = false
			DialogModule.Dialog(true, nil, ObjectiveBasementPart.PlrDialog)
			task.wait(5)
			GasMachine.BillboardGui.Enabled = true
			ObjectivesModule.NewObjective(true, "Basement_Bars", ObjectiveBasementPart.Basement_Bars.Title.Value, ObjectiveBasementPart.Basement_Bars.Description.Value)
		end
	end
end)

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

local function changeGauge(Gauge: Model, mode: number)
	if not Gauge or not mode then warn("incorrect instances.") return end
	
	local function changeIndicator()
		if Gauge.State.Value then
			Ts:Create(Gauge.Hinge, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {CFrame = Gauge.max.CFrame}):Play()
		else
			Ts:Create(Gauge.Hinge, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {CFrame = Gauge.min.CFrame}):Play()
		end
	end
	
	if mode == 0 then
		Gauge.State.Value = not Gauge.State.Value
		for i, v: Instance in Gauge.Light1:GetDescendants() do
			if v:IsA("SpotLight") or v:IsA("PointLight") or v:IsA("SurfaceLight") then
				if Gauge.State.Value then
					local newColor = Color3.new(0.356863, 0.85098, 0.243137)
					v.Color = newColor
					Gauge.Light1.LightPart.Color = newColor
				else
					local newColor = Color3.new(0.686275, 0.266667, 0.266667)
					v.Color = newColor
					Gauge.Light1.LightPart.Color = newColor
				end
			end
		end
	else
		Gauge.State.Value = not Gauge.State.Value
		for i, v: Instance in Gauge.Light2:GetDescendants() do
			if v:IsA("SpotLight") or v:IsA("PointLight") or v:IsA("SurfaceLight") then
				if Gauge.State.Value then
					local newColor = Color3.new(0.356863, 0.85098, 0.243137)
					v.Color = newColor
					Gauge.Light2.LightPart.Color = newColor
				else
					local newColor = Color3.new(0.686275, 0.266667, 0.266667)
					v.Color = newColor
					Gauge.Light2.LightPart.Color = newColor
				end
			end
		end
	end
	
	changeIndicator()
end

local function checkState(incorrect: boolean)
	local all = false
	if incorrect then
		if not Pressure_Gauge1.State.Value and not Pressure_Gauge2.State.Value and not Pressure_Gauge3.State.Value and not Pressure_Gauge4.State.Value then
			all = true
		end
	else
		if Pressure_Gauge1.State.Value and Pressure_Gauge2.State.Value and Pressure_Gauge3.State.Value and Pressure_Gauge4.State.Value then
			all = true
		end
	end
	return all
end

local function setupValves(fast)
	local waitTime = 0.2
	
	if fast then
		waitTime = 0
	end
	
	for i=1, 15 do
		local random = math.random(1, 4)
		local selectedGauge = GasMachine:FindFirstChild("Pressure_Gauge"..random)
		changeGauge(selectedGauge, currentMode)
		task.wait(waitTime)
	end
	
	local allTheSame = checkState(true)
	if allTheSame == false then
		allTheSame = checkState(false)
	end
	
	if allTheSame then
		setupValves()
	end
end

task.wait(3)

setupValves()

local proxDebounce = true

for i, v in ValvesFolder:GetChildren() do
	if v:IsA("Model") then
		local interact = v:FindFirstChild("Interact") :: BasePart
		local hinge = v:FindFirstChild("Hinge") :: BasePart
		
		if not interact then warn("Can't find interact part on valve.") break end
		if not hinge then warn("Can't find hinge part on valve.") break end
		
		local proxValve = Instance.new("ProximityPrompt", interact)
		proxValve.MaxActivationDistance = GameConfigModule.InteractDistance
		proxValve.RequiresLineOfSight = false
		proxValve.Style = Enum.ProximityPromptStyle.Custom
		proxValve.HoldDuration = 0.15
		proxValve.ActionText = "Rotate"
		proxValve.ObjectText = "Valve"
		
		local Gauge1 = nil
		local Gauge2 = nil
		local Gauge3 = nil
		
		local lastChar = string.sub(v.Name, -1)
		if tonumber(lastChar) == 1 then
			Gauge1 = Pressure_Gauge4
			Gauge2 = Pressure_Gauge1
			Gauge3 = Pressure_Gauge2
		elseif tonumber(lastChar) == 2 then
			Gauge1 = Pressure_Gauge1
			Gauge2 = Pressure_Gauge2
			Gauge3 = Pressure_Gauge3
		elseif tonumber(lastChar) == 3 then
			Gauge1 = Pressure_Gauge2
			Gauge2 = Pressure_Gauge3
			Gauge3 = Pressure_Gauge4
		elseif tonumber(lastChar) == 4 then
			Gauge1 = Pressure_Gauge3
			Gauge2 = Pressure_Gauge4
			Gauge3 = Pressure_Gauge1
		end
		
		proxValve.Triggered:Connect(function(plr)
			if not proxDebounce then return end
			if plr.Character then
				if plr.Character:FindFirstChild("Humanoid") and plr.Character:FindFirstChild("Humanoid").Health > 0 then
					proxDebounce = false
					local randomValveSound = ValveSounds:GetChildren()[math.random(1, #ValveSounds:GetChildren())]
					
					playSound(randomValveSound, interact)
					changeGauge(Gauge1, currentMode)
					changeGauge(Gauge2, currentMode)
					changeGauge(Gauge3, currentMode)
					Ts:Create(hinge, TweenInfo.new(0.5), {CFrame = hinge.CFrame * CFrame.Angles(0, math.rad(-90), 0)}):Play()
					
					local correct = checkState(false)
					if correct then -- win
						playSound(SoundsFolder.CorrectSound, GasMachine.Machine)
						if currentMode == 1 then
							local gasSound = SoundsFolder.GasSound
							gasSound.Parent = GasMachine.Machine
							gasSound:Play()
							
							for i, v in ValvesFolder:GetChildren() do
								if v:IsA("Model") then
									local interact = v:FindFirstChild("Interact") :: BasePart
									if interact then
										if interact:FindFirstChild("ProximityPrompt") then
											interact:FindFirstChild("ProximityPrompt").Enabled = false
										end
									end
								end
							end
							
							local badge = BadgesModule:FindBadge("Right Pressure")
							BadgesModule:GiveBadge(plr, badge.Id)
							MoneyModule.Give(plr, puzzleReward)
							GasMachine.BillboardGui.Enabled = false
							Crowbar.BillboardGui.Enabled = true
							
							task.wait(1)
							
							--//Start the basement cutscene
							ActiveCutsceneEvent:FireAllClients("BasementBars")
							
							task.delay(3, function()
								local zoneToGo = Map:FindFirstChild("TeleportZones"):FindFirstChild("SewageCutscene").Name
								TeleportModule:Teleport(zoneToGo, script, true, true)
								
								task.wait(0.8)
								
								--//To players don't walk away and fall in the stairs then die
								for _, v in game.Players:GetPlayers() do
									local char = v.Character
									local PlrValues = v:FindFirstChild("PlayerValues")
									local IsAlive = PlrValues:FindFirstChild("IsAlive")
									local HumanoidRootPart = nil
									if char:FindFirstChild("HumanoidRootPart") and IsAlive and IsAlive.Value then
										HumanoidRootPart = char:FindFirstChild("HumanoidRootPart") :: BasePart
										HumanoidRootPart.Anchored = true
										task.delay(6, function()
											HumanoidRootPart.Anchored = false
										end)
									end
								end
							end)
							return
						end
						currentMode = 1
						setupValves(true)
					end
					
					task.wait(0.5)
					proxDebounce = true
				end
			end
		end)
	end
end

local alreadyLaunched = false

ActiveCutsceneEvent.OnServerEvent:Connect(function(plr, event)
	if event == "LaunchBars" and not alreadyLaunched then
		alreadyLaunched = true
		local BasementCutscene = Map:WaitForChild("Cutscenes"):FindFirstChild("BasementCutscene")
		local Bars1 = BasementCutscene.Bars_Sewage1
		local Bars2 = BasementCutscene.Bars_Sewage2
		local Bars3 = BasementCutscene.Bars_Sewage3
		
		for i, v in Bars1:GetChildren() do
			if v:IsA("BasePart") then
				v.CanCollide = false
				v.Transparency = 1
			end
		end
		for i, v in Bars2:GetChildren() do
			if v:IsA("BasePart") then
				v.CanCollide = false
				v.Transparency = 0
			end
		end
		for i, v in Bars3:GetChildren() do
			if v:IsA("BasePart") then
				v.CanCollide = true
				v.Transparency = 0
				v.Anchored = false
				v.AssemblyLinearVelocity = Vector3.new(0, 0, math.random(25, 35))
			end
		end
		
		task.wait(3)
		
		ObjectivesModule.CompleteObjective(true, "Basement_Bars")
	end
end)