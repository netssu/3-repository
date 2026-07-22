--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local InspectEvent = Remotes:FindFirstChild("Inspect")
local ActiveCutsceneEvent = Remotes:FindFirstChild("ActiveCutscene")
local GamePuzzlesEvent = Remotes:FindFirstChild("gamePuzzles")

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local GameConfigModule = require(ModulesFolder:FindFirstChild("GameConfigModule"))
local ObjectivesModule = require(ModulesFolder:FindFirstChild("ObjectivesModule"))
local TeleportModule = require(ModulesFolder:FindFirstChild("TeleportModule"))
local BadgesModule = require(ModulesFolder:FindFirstChild("Badges"))

--//Asylum Reception Stuff
local Map = workspace:FindFirstChild("Map")
local AsylumReceptionFolder = Map:FindFirstChild("Area2_AsylumReception")
local InteractStuff = AsylumReceptionFolder:FindFirstChild("InteractStuff")
local LightsFolder = AsylumReceptionFolder:FindFirstChild("Light"):FindFirstChild("Off_Lights")
local ButtonMetalDoor = InteractStuff:FindFirstChild("ButtonMetalDoor")

--//Energy Machine Puzzle
local EnergyMachine = InteractStuff:FindFirstChild("Energy_Machine")
local CombinationButtons = EnergyMachine:FindFirstChild("Combination_Buttons")
local ProxMachine = Instance.new("ProximityPrompt", EnergyMachine.Interact)
local EnergyRestored = InteractStuff:FindFirstChild("ButtonMetalDoor"):FindFirstChild("EnergyRestored")
local puzzleGui = EnergyMachine:FindFirstChild("EnergyPuzzleGui") :: ScreenGui

--//Sounds
local SoundsFolder = EnergyMachine:FindFirstChild("Sounds")

--//Values
local completedPuzzle = false
local onPuzzleDebounce = false
local currentPlr = nil
local blinkSpeed = 0.12
local maxLevel = 5 -- Change this number between 1-9 to increate/decrease the puzzle difficulty
local currentLevel = 0
local currentOrder = {}
local plrSelectedOrder = {}

--//Setup
EnergyMachine.BillboardGui.Enabled = false
ProxMachine.Style = Enum.ProximityPromptStyle.Custom
ProxMachine.MaxActivationDistance = GameConfigModule.InteractDistance
ProxMachine.ActionText = "Inspect"
ProxMachine.ObjectText = "General Energy Machine"
ProxMachine.RequiresLineOfSight = false
ProxMachine.HoldDuration = 0.2

local function playSound(sound: Sound, parent: Instance?)
	local snd = sound:Clone()
	if parent then
		snd.Parent = parent
	else
		snd.Parent = sound.Parent
	end
	snd:Play()
	game.Debris:AddItem(snd, snd.TimeLength + 1)
end

local function resetButtons()
	for i, v in CombinationButtons:GetChildren() do
		if v:FindFirstChildWhichIsA("BoolValue") then
			local boolVal = v:FindFirstChildWhichIsA("BoolValue")
			boolVal.Value = false
		end
	end
end

local function resetPuzzle(skipAnimation: boolean?)
	currentLevel = 0
	onPuzzleDebounce = true
	currentOrder = {}
	plrSelectedOrder = {}
	resetButtons()
	
	if skipAnimation then return end
	
	task.wait(blinkSpeed)
	playSound(SoundsFolder.ButtonBip, EnergyMachine.Interact)
	
	for i, v in CombinationButtons:GetChildren() do
		if v:IsA("BasePart") then
			v.Color = Color3.fromRGB(147, 146, 149)
		end
	end
	
	task.wait(blinkSpeed)
	
	for i, v in CombinationButtons:GetChildren() do
		if v:IsA("BasePart") then
			v.Color = Color3.fromRGB(78, 77, 79)
		end
	end
	
	task.wait(blinkSpeed)
	playSound(SoundsFolder.ButtonBip, EnergyMachine.Interact)
	
	for i, v in CombinationButtons:GetChildren() do
		if v:IsA("BasePart") then
			v.Color = Color3.fromRGB(147, 146, 149)
		end
	end
	
	task.wait(blinkSpeed)
	
	for i, v in CombinationButtons:GetChildren() do
		if v:IsA("BasePart") then
			v.Color = Color3.fromRGB(78, 77, 79)
		end
	end
	
	task.wait(blinkSpeed)
	playSound(SoundsFolder.ButtonBip, EnergyMachine.Interact)
	
	for i, v in CombinationButtons:GetChildren() do
		if v:IsA("BasePart") then
			v.Color = Color3.fromRGB(147, 146, 149)
		end
	end
	
	task.wait(blinkSpeed)
	
	for i, v in CombinationButtons:GetChildren() do
		if v:IsA("BasePart") then
			v.Color = Color3.fromRGB(78, 77, 79)
		end
	end
	
	task.wait(0.25)
	onPuzzleDebounce = false
end

local function puzzleIncorrect()
	currentLevel = 0
	onPuzzleDebounce = true
	currentOrder = {}
	plrSelectedOrder = {}
	resetButtons()
	
	task.wait(blinkSpeed)
	playSound(SoundsFolder.ButtonBip, EnergyMachine.Interact)
	
	for i, v in CombinationButtons:GetChildren() do
		if v:IsA("BasePart") then
			v.Color = Color3.fromRGB(149, 48, 48)
		end
	end
	
	task.wait(blinkSpeed)
	
	for i, v in CombinationButtons:GetChildren() do
		if v:IsA("BasePart") then
			v.Color = Color3.fromRGB(78, 77, 79)
		end
	end
	
	task.wait(blinkSpeed)
	playSound(SoundsFolder.ButtonBip, EnergyMachine.Interact)
	
	for i, v in CombinationButtons:GetChildren() do
		if v:IsA("BasePart") then
			v.Color = Color3.fromRGB(149, 48, 48)
		end
	end
	
	task.wait(blinkSpeed)
	
	for i, v in CombinationButtons:GetChildren() do
		if v:IsA("BasePart") then
			v.Color = Color3.fromRGB(78, 77, 79)
		end
	end
	
	task.wait(blinkSpeed)
	playSound(SoundsFolder.ButtonBip, EnergyMachine.Interact)
	
	for i, v in CombinationButtons:GetChildren() do
		if v:IsA("BasePart") then
			v.Color = Color3.fromRGB(149, 48, 48)
		end
	end
	
	task.wait(blinkSpeed)
	
	for i, v in CombinationButtons:GetChildren() do
		if v:IsA("BasePart") then
			v.Color = Color3.fromRGB(78, 77, 79)
		end
	end
	
	task.wait(0.25)
	onPuzzleDebounce = false
end

local function blinkPattern()
	onPuzzleDebounce = true
	
	local function resetButtonsDefaultColor()
		for _, v in CombinationButtons:GetChildren() do
			if v:IsA("BasePart") then
				v.Color = Color3.fromRGB(78, 77, 79)
			end
		end
	end
	
	resetButtonsDefaultColor()
	
	task.wait(0.3)
	
	resetButtons()
	
	--//Blink current order
	for _, v in ipairs(currentOrder) do
		local buttonSelected = nil :: BasePart
		for _, button in ipairs(CombinationButtons:GetChildren()) do
			local number = button.Name:match("%d+")
			if number and v.Name:find(number, 1, true) then
				buttonSelected = button
				break
			end
		end
		if buttonSelected then
			buttonSelected.Color = Color3.fromRGB(147, 146, 149)
			playSound(SoundsFolder.ButtonBip, EnergyMachine.Interact)
			task.wait(0.25)
			--buttonSelected.Color = Color3.fromRGB(78, 77, 79)
		end
		task.wait(0.25)
	end
	
	resetButtonsDefaultColor()
	onPuzzleDebounce = false
end

local function alreadyInCurrentOrder(button)
	for _, b in ipairs(currentOrder) do
		if b == button then
			return true
		end
	end
	return false
end

local function addNewInter()
	local newInter
	
	repeat
		local allButtons = CombinationButtons:GetChildren()
		newInter = allButtons[math.random(1, #allButtons)]
	until not alreadyInCurrentOrder(newInter)
	
	table.insert(currentOrder, newInter)
end

local function compareTables(t1, t2)
	if #t1 ~= #t2 then
		return false
	end
	
	for i = 1, #t1 do
		if t1[i] ~= t2[i] then
			return false
		end
	end
	
	return true
end

local function startPuzzle()
	resetPuzzle()
	addNewInter()
	blinkPattern()
end

local function completePuzzle(plr: Player)
	if not completedPuzzle then
		onPuzzleDebounce = true
		completedPuzzle = true
		currentPlr = nil
		playSound(SoundsFolder.CorrectSound, EnergyMachine.Interact)
		
		InspectEvent:FireClient(plr, "InspectOFF")
		
		task.wait(0.5)
		
		if plr.PlayerGui:FindFirstChild("EnergyPuzzleGui") then
			plr.PlayerGui.EnergyPuzzleGui:Destroy() -- Remove puzzle from player gui
		end
		
		ActiveCutsceneEvent:FireAllClients("RestorePowerCutscene")
		
		EnergyRestored.Value = true
		EnergyMachine.BillboardGui.Enabled = false
		ButtonMetalDoor.BillboardGui.Enabled = true
		
		local badge = BadgesModule:FindBadge("Restore Energy")
		BadgesModule:GiveBadge(plr, badge.Id)
		
		local zoneToGo = Map:FindFirstChild("TeleportZones"):FindFirstChild("EnergyRoomCutscene").Name
		TeleportModule:Teleport(zoneToGo, script, true, true)
		
		warn("Restaured Asylum Energy.")
	end
end

local function enableLights(folder: Folder)
	local blinkSound = Map.Cutscenes.RestoreEnergyCutscene:FindFirstChild("LightBlinkSound")
	for i, v in folder:GetChildren() do
		if v:IsA("Model") then
			local lightPart = v:FindFirstChild("LightPart") :: BasePart
			if lightPart then
				lightPart.Color = Color3.fromRGB(147, 163, 165)
				lightPart.Material = Enum.Material.Neon
				for _, lightInstance in lightPart:GetChildren() do
					if lightInstance:IsA("Light") then
						lightInstance.Enabled = true
					end
				end
				playSound(blinkSound, lightPart)
				task.wait(math.random(60, 80)/100)
			end
		end
	end
end

local lights1 = true
local lights2 = true

ActiveCutsceneEvent.OnServerEvent:Connect(function(plr, event)
	if event == "EnableLights1" and lights1 then
		lights1 = false
		local lights1 = LightsFolder:FindFirstChild("Lights1")
		enableLights(lights1)
	elseif event == "EnableLights2" and lights2 then
		lights2 = false
		local lights2 = LightsFolder:FindFirstChild("Lights2")
		enableLights(lights2)
	end
end)

ProxMachine.Triggered:Connect(function(plr)
	if not plr or not plr.Character then return end
	
	local char = plr.Character
	local hum = char:WaitForChild("Humanoid") :: Humanoid
	
	if not hum or hum.Health <= 0 then return end
	
	if not currentPlr then
		currentPlr = plr
		ProxMachine.Enabled = false
		EnergyMachine.BillboardGui.Enabled = false
		InspectEvent:FireClient(plr, "InspectON", EnergyMachine.CamPart)
		
		local guiClone = puzzleGui:Clone()
		guiClone.Parent = plr.PlayerGui
		guiClone.Name = "EnergyPuzzleGui"
		
		--startPuzzle()
	end
end)

InspectEvent.OnServerEvent:Connect(function(plr, event)
	if event == "InspectOFF" and currentPlr then
		currentPlr = nil
		if not completedPuzzle then
			if plr.PlayerGui:FindFirstChild("EnergyPuzzleGui") then
				plr.PlayerGui.EnergyPuzzleGui:Destroy() -- Remove puzzle from player gui
			end
			if EnergyMachine:FindFirstChild("BillboardGui") then
				EnergyMachine.BillboardGui.Enabled = true
			end
			if ProxMachine then
				ProxMachine.Enabled = true
			end
			resetPuzzle(true)
		end
	end
end)

task.wait(0.5)

GamePuzzlesEvent.OnServerEvent:Connect(function(plr, action, newOrder)
	if action == "energyMachine_sndClick" then
		if plr ~= currentPlr then return end
		playSound(SoundsFolder.ButtonBip, EnergyMachine.Interact)
	elseif action == "energyMachine_win" then
		if plr ~= currentPlr then return end
		completePuzzle(plr)
	end
	--[[elseif action == "energyMachine_blinkPattern" then
		if plr ~= currentPlr then return end
		blinkPattern()
	elseif action == "energyMachine_incorrect" then
		if plr ~= currentPlr then return end
		puzzleIncorrect()
		--blinkPattern()
	elseif action == "energyMachine_updateOrder" then
		if plr ~= currentPlr then return end
		currentOrder = newOrder
	elseif action == "energyMachine_leaveGui" then
		if plr ~= currentPlr then return end
		currentPlr = nil
		EnergyMachine.BillboardGui.Enabled = true
		ProxMachine.Enabled = true
		resetPuzzle(true)
	end]]
end)

--[[
	**Puzzle moved to the client (puzzle UI)**
]]

--[[for i, v in CombinationButtons:GetChildren() do
	if v:IsA("BasePart") and v:FindFirstChildWhichIsA("ClickDetector") then
		local clicker = v:FindFirstChildWhichIsA("ClickDetector")
		local alreadyClicked = Instance.new("BoolValue", v)
		alreadyClicked.Name = "alreadyClicked"
		alreadyClicked.Value = false
		
		clicker.MouseClick:Connect(function(plr)
			if not (plr == currentPlr) or alreadyClicked.Value or onPuzzleDebounce then return end
			
			onPuzzleDebounce = true
			alreadyClicked.Value = true
			table.insert(plrSelectedOrder, v)
			
			playSound(SoundsFolder.ButtonBip, EnergyMachine.Interact)
			v.Color = Color3.fromRGB(33, 158, 24)
			
			task.wait(0.25)
			
			if compareTables(plrSelectedOrder, currentOrder) then
				currentLevel += 1
				if currentLevel < maxLevel then
					plrSelectedOrder = {}
					addNewInter()
					blinkPattern()
				else -- win
					completePuzzle(plr)
					return
				end
			elseif #plrSelectedOrder >= #currentOrder and not (plrSelectedOrder == currentOrder) then
				puzzleIncorrect()
				--//Restart the puzzle automatically
				addNewInter()
				blinkPattern()
			end
			onPuzzleDebounce = false
		end)
	end
end]]