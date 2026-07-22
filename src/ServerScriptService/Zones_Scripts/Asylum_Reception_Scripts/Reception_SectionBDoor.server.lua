--//Services
local Ts = game:GetService("TweenService")
local Rs = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local GameConfigModule = require(ModulesFolder:FindFirstChild("GameConfigModule"))
local DialogModule = require(ModulesFolder:FindFirstChild("PlayerDialogModule"))
local ObjectivesModule = require(ModulesFolder:FindFirstChild("ObjectivesModule"))
local InventoryModule = require(ModulesFolder:FindFirstChild("InventoryModule"))
local DoorCollision = require(ModulesFolder:FindFirstChild("DoorCollision"))

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local InspectEvent = Remotes:FindFirstChild("Inspect")
local GamePuzzlesEvent = Remotes:FindFirstChild("gamePuzzles")

--//Asylum Reception Stuff
local Map = workspace:FindFirstChild("Map")
local AsylumReceptionFolder = Map:FindFirstChild("Area2_AsylumReception")
local InteractStuff = AsylumReceptionFolder:FindFirstChild("InteractStuff")

--//Section-B Entrance
local MetalDoor = InteractStuff:FindFirstChild("BlockBDoor")
local PanelCode = InteractStuff:FindFirstChild("BlockB_Panel")
local ButtonDoor = InteractStuff:FindFirstChild("ButtonBlockB")
local Panel_Light = InteractStuff:FindFirstChild("Panel_Light")
local proxButton = Instance.new("ProximityPrompt", ButtonDoor.Interact)
local proxPanel = Instance.new("ProximityPrompt", PanelCode.Interact)
local PanelB_ConsoleGui =PanelCode.PanelB_ConsoleGui

--//Paper Code
local Items = Map:FindFirstChild("Items")
local PaperCodes = InteractStuff:FindFirstChild("PaperCode_SectionB")
local InteractPaperCode = PaperCodes:FindFirstChild("Interact_PaperCode")
local Paper1_Correct = PaperCodes:FindFirstChild("Paper_1_Correct")
local Paper2_Correct = PaperCodes:FindFirstChild("Paper_2_Correct")
local Paper3_Correct = PaperCodes:FindFirstChild("Paper_3_Correct")
local Paper4_Correct = PaperCodes:FindFirstChild("Paper_4_Correct")
local Paper1 = Items:FindFirstChild("Paper 1")
local Paper2 = Items:FindFirstChild("Paper 2")
local Paper3 = Items:FindFirstChild("Paper 3")
local Paper4 = Items:FindFirstChild("Paper 4")
local proxPaperCode = Instance.new("ProximityPrompt", InteractPaperCode)

--//Values
local ButtonDebounce = true
local RollDebounce = true
local OpenedDoor = false
local canInspect = true
local givenObjective = false
local PlrOnPanel = PanelCode.currentPlr
local CorrectCode = PanelCode.CODE

--//Setup
PanelCode.BillboardGui.Enabled = false
InteractPaperCode.BillboardGui.Enabled = false
proxButton.MaxActivationDistance = GameConfigModule.InteractDistance
proxButton.RequiresLineOfSight = false
proxButton.Style = Enum.ProximityPromptStyle.Custom
proxButton.HoldDuration = 0.15
proxButton.ActionText = "Active"
proxButton.ObjectText = "Button"

proxPanel.MaxActivationDistance = GameConfigModule.InteractDistance
proxPanel.RequiresLineOfSight = false
proxPanel.Style = Enum.ProximityPromptStyle.Custom
proxPanel.HoldDuration = 0.15
proxPanel.ActionText = "Inspect"
proxPanel.ObjectText = "Panel"

proxPaperCode.MaxActivationDistance = GameConfigModule.InteractDistance
proxPaperCode.RequiresLineOfSight = true
proxPaperCode.Style = Enum.ProximityPromptStyle.Custom
proxPaperCode.HoldDuration = 0.15
proxPaperCode.ActionText = "Inspect"
proxPaperCode.ObjectText = "Note"

local function getCurrentCode()
	local num1 = tostring(PanelCode.Selector1.currentState.Value)
	local num2 = tostring(PanelCode.Selector2.currentState.Value)
	local num3 = tostring(PanelCode.Selector3.currentState.Value)
	local num4 = tostring(PanelCode.Selector4.currentState.Value)
	local finalCode = num1..num2..num3..num4
	return finalCode
end

proxButton.Triggered:Connect(function(plr)
	if ButtonDebounce then
		ButtonDebounce = false
		
		local function animButton()
			local tween = Ts:Create(ButtonDoor.Button, TweenInfo.new(0.07), {CFrame = ButtonDoor.ClickedPos.CFrame})
			tween:Play()
			ButtonDoor.Interact.ClickSound:Play()
			
			tween.Completed:Connect(function()
				Ts:Create(ButtonDoor.Button, TweenInfo.new(0.03), {CFrame = ButtonDoor.NormalPos.CFrame}):Play()
			end)
		end
		
		animButton()
		
		local currentCode = getCurrentCode()
		
		--//If the code is correct, open the door
		if currentCode == CorrectCode.Value and not OpenedDoor then
			Panel_Light.LightPart.Color = Color3.fromRGB(97, 255, 61)
			for i, v in Panel_Light:GetDescendants() do
				if v:IsA("SpotLight") or v:IsA("PointLight") or v:IsA("SurfaceLight") then
					v.Color = Color3.fromRGB(97, 255, 61)
				end
			end
			
			if Panel_Light.LightPart:FindFirstChildWhichIsA("Sound") then
				Panel_Light.LightPart:FindFirstChildWhichIsA("Sound"):Play()
			end
			
			task.wait(1)
			
			local openSound = MetalDoor.MainDoor.OpenSound
			openSound:Play()
			DoorCollision.disable(MetalDoor)
			Ts:Create(MetalDoor.Hinge, TweenInfo.new(openSound.TimeLength), {CFrame = MetalDoor.OpenedPos.CFrame}):Play()
			OpenedDoor = true
			canInspect = false
			proxPanel.Enabled = false
			PanelCode.BillboardGui.Enabled = false
			MetalDoor.Collider.CanCollide = false
			MetalDoor.Collider.Transparency = 1
			
			task.wait(1)
			
			ObjectivesModule.CompleteObjective(true, "SectionB_Door")
		elseif not givenObjective and not OpenedDoor then
			--//Give the objective that need to find a code to open the door
			--givenObjective = true
			--objective moved to the CutscneManager [FlayedCutscene] --> Moved o Reception_MonsterAppear
			--ObjectivesModule.NewObjective(true, "SectionB_Door", "Section B", "Search for the correct code and open the door to Section B.")
			DialogModule.Dialog(false, plr, nil, "I'll need to find a code to open the door to Section B.")
		end
		
		task.wait(0.2)
		
		ButtonDebounce = true
	end
end)

local function changeRollPad(RollPad: Model, currentState, random)
	if not RollPad.PrimaryPart then return end
	
	local function roll(noTween: boolean)
		local rotationAmount = math.rad(36)
		if noTween then
			RollPad.PrimaryPart.CFrame *= CFrame.Angles(0, rotationAmount, 0)
		else
			Ts:Create(RollPad.PrimaryPart, TweenInfo.new(0.2, Enum.EasingStyle.Back), {CFrame = RollPad.PrimaryPart.CFrame * CFrame.Angles(0 , rotationAmount, 0)}):Play()
		end
	end
	
	if random then
		local rollTimes = math.random(0, 9)
		for i=1, rollTimes do
			roll(true)
			currentState += 1
			task.wait(0.1)
		end
	else
		roll()
		PanelCode.Interact.ClickSound:Play()
		currentState += 1
	end
	
	local function correctToRightNumber()
		if currentState > 9 then
			local rest = currentState - 9
			currentState = 0 + rest - 1
		end
	end
	
	if currentState > 9 then
		repeat wait() correctToRightNumber() until currentState <= 9
	end
	
	return currentState
end

local function putCodeOnPaper(paper: BasePart, number: number)
	if paper:FindFirstChildWhichIsA("SurfaceGui") then
		if paper:FindFirstChildWhichIsA("SurfaceGui"):FindFirstChildWhichIsA("TextLabel") then
			paper:FindFirstChildWhichIsA("SurfaceGui"):FindFirstChildWhichIsA("TextLabel").Text = number
		end
	end
end

local function changePaperCode(paper: BasePart, state: boolean)
	if state then
		paper.Parent = PaperCodes
	else
		paper.Parent = Rs
	end
end

local function setupPanel()
	local randomCode = math.random(0, 9999)
	
	if randomCode >= 0 and randomCode < 10 then
		randomCode = "000"..randomCode
	elseif randomCode >= 10 and randomCode < 100 then
		randomCode = "00"..randomCode
	elseif randomCode >= 100 and randomCode < 1000 then
		randomCode = "0"..randomCode
	end
	
	CorrectCode.Value = tostring(randomCode)
	
	local function putRandomCode()
		PanelCode.Selector1.currentState.Value = changeRollPad(PanelCode.Selector1.RollPad1, PanelCode.Selector1.currentState.Value, true)
		PanelCode.Selector2.currentState.Value = changeRollPad(PanelCode.Selector2.RollPad2, PanelCode.Selector2.currentState.Value, true)
		PanelCode.Selector3.currentState.Value = changeRollPad(PanelCode.Selector3.RollPad3, PanelCode.Selector3.currentState.Value, true)
		PanelCode.Selector4.currentState.Value = changeRollPad(PanelCode.Selector4.RollPad4, PanelCode.Selector4.currentState.Value, true)
	end
	
	putRandomCode()
	
	local currentCode = getCurrentCode()
	
	if currentCode == CorrectCode.Value then
		repeat wait() putRandomCode() currentCode = getCurrentCode() until currentCode ~= CorrectCode.Value
	end
	
	local firstNumber = string.sub(CorrectCode.Value, 1, 1)
	local secondNumber = string.sub(CorrectCode.Value, 2, 2)
	local thirdNumber = string.sub(CorrectCode.Value, 3, 3)
	local fourthNumber = string.sub(CorrectCode.Value, 4, 4)
	putCodeOnPaper(Paper1_Correct, tonumber(firstNumber))
	putCodeOnPaper(Paper2_Correct, tonumber(secondNumber))
	putCodeOnPaper(Paper3_Correct, tonumber(thirdNumber))
	putCodeOnPaper(Paper4_Correct, tonumber(fourthNumber))
	
	--//Remove the correct codes from workspace
	changePaperCode(Paper1_Correct, false)
	changePaperCode(Paper2_Correct, false)
	changePaperCode(Paper3_Correct, false)
	changePaperCode(Paper4_Correct, false)
	
	--//Put the correct code on Paper codes that can be found in map
	putCodeOnPaper(Paper1, tonumber(firstNumber))
	putCodeOnPaper(Paper2, tonumber(secondNumber))
	putCodeOnPaper(Paper3, tonumber(thirdNumber))
	putCodeOnPaper(Paper4, tonumber(fourthNumber))
	
	--
	print("------------------------------------")
	print("Block-B Code:", CorrectCode.Value:reverse())
	print("------------------------------------")
	--print("OldCode:", getCurrentCode())
	--]]
end

local interactPaperDebounce = true
local withPaper1 = false
local withPaper2 = false
local withPaper3 = false
local withPaper4 = false

proxPaperCode.Triggered:Connect(function(plr)
	if interactPaperDebounce then
		interactPaperDebounce = false
		local char = plr.Character
		
		if withPaper1 and withPaper2 and withPaper3 and withPaper4 then
			InteractPaperCode.BillboardGui.Enabled = false
			local text = "The Section B code is "..CorrectCode.Value.."..."
			DialogModule.Dialog(false, plr, nil, text)
			interactPaperDebounce = true
			return
		end
		
		if char then
			if char:FindFirstChild("Paper 1") and char:FindFirstChild("Paper 1"):IsA("Tool") then
				InventoryModule.DeleteItem("Paper 1")
				changePaperCode(Paper1_Correct, true)
				withPaper1 = true
			elseif char:FindFirstChild("Paper 2") and char:FindFirstChild("Paper 2"):IsA("Tool") then
				InventoryModule.DeleteItem("Paper 2")
				changePaperCode(Paper2_Correct, true)
				withPaper2 = true
			elseif char:FindFirstChild("Paper 3") and char:FindFirstChild("Paper 3"):IsA("Tool") then
				InventoryModule.DeleteItem("Paper 3")
				changePaperCode(Paper3_Correct, true)
				withPaper3 = true
			elseif char:FindFirstChild("Paper 4") and char:FindFirstChild("Paper 4"):IsA("Tool") then
				InventoryModule.DeleteItem("Paper 4")
				changePaperCode(Paper4_Correct, true)
				withPaper4 = true
			else
				DialogModule.Dialog(false, plr, nil, "I need to find the other pieces of code.")
			end
		end
		
		task.wait(0.3)
		
		interactPaperDebounce = true
	end
end)

proxPanel.Triggered:Connect(function(plr)
	if PlrOnPanel.Value ~= "nil" then DialogModule.Dialog(false, plr, nil, "Someone is already inspecting here.") return end
	if not canInspect then return end
	
	proxPanel.Enabled = false
	PlrOnPanel.Value = plr.Name
	PanelCode.BillboardGui.Enabled = false
	InspectEvent:FireClient(plr, "InspectON", PanelCode.CamPart)
	
	if UIS.GamepadEnabled then
		local consoleGui = PanelB_ConsoleGui:Clone()
		consoleGui.Parent = plr.PlayerGui
		consoleGui.Name = "PANEL_B_CONSOLE_GUI"
	end
end)

InspectEvent.OnServerEvent:Connect(function(plr, event)
	if event == "InspectOFF" then
		PlrOnPanel.Value = "nil"
		proxPanel.Enabled = true
		
		if not OpenedDoor then
			if PanelCode:FindFirstChild("BillboardGui") then
				PanelCode.BillboardGui.Enabled = true
			end
		end
		
		--//Remove old gui
		if plr.PlayerGui:FindFirstChild("PANEL_B_CONSOLE_GUI") then
			plr.PlayerGui["PANEL_B_CONSOLE_GUI"]:Destroy()
		end
		
		--//Make the outlines invisible in case of a visual bug
		Ts:Create(PanelCode.Selector1.Highlight, TweenInfo.new(0.2), {OutlineTransparency = 1}):Play()
		Ts:Create(PanelCode.Selector2.Highlight, TweenInfo.new(0.2), {OutlineTransparency = 1}):Play()
		Ts:Create(PanelCode.Selector3.Highlight, TweenInfo.new(0.2), {OutlineTransparency = 1}):Play()
		Ts:Create(PanelCode.Selector4.Highlight, TweenInfo.new(0.2), {OutlineTransparency = 1}):Play()
	end
end)

local function moveSelector(selectorNum: number)
	local selector = PanelCode["Selector"..tostring(selectorNum)]
	if not selector then return end
	local rollPad = selector["RollPad"..tostring(selectorNum)]
	if not rollPad then return end
	
	RollDebounce = false
	selector.currentState.Value = changeRollPad(rollPad, selector.currentState.Value)
	
	task.wait(0.25)
	
	RollDebounce = true
end

PanelCode.Selector1.Clicker.ClickDetector.MouseClick:Connect(function(plr) --button1
	if not RollDebounce or PlrOnPanel.Value ~= plr.Name then return end
	moveSelector(1)
end)

PanelCode.Selector2.Clicker.ClickDetector.MouseClick:Connect(function(plr) --button2
	if not RollDebounce or PlrOnPanel.Value ~= plr.Name then return end
	moveSelector(2)
end)

PanelCode.Selector3.Clicker.ClickDetector.MouseClick:Connect(function(plr) --button3
	if not RollDebounce or PlrOnPanel.Value ~= plr.Name then return end
	moveSelector(3)
end)

PanelCode.Selector4.Clicker.ClickDetector.MouseClick:Connect(function(plr) --button4
	if not RollDebounce or PlrOnPanel.Value ~= plr.Name then return end
	moveSelector(4)
end)

GamePuzzlesEvent.OnServerEvent:Connect(function(plr, action)
	if plr.Name ~= PlrOnPanel.Value or not RollDebounce then return end
	
	if action == "PanelB_Button1" then
		moveSelector(1)
	elseif action == "PanelB_Button2" then
		moveSelector(2)
	elseif action == "PanelB_Button3" then
		moveSelector(3)
	elseif action == "PanelB_Button4" then
		moveSelector(4)
	end
end)

local hoverTransparency = 0.6

--//Interactions Animations
PanelCode.Selector1.Clicker.ClickDetector.MouseHoverEnter:Connect(function(plr)
	if PlrOnPanel.Value ~= plr.Name then return end
	Ts:Create(PanelCode.Selector1.Highlight, TweenInfo.new(0.2), {OutlineTransparency = hoverTransparency}):Play()
end)

PanelCode.Selector1.Clicker.ClickDetector.MouseHoverLeave:Connect(function(plr)
	if PlrOnPanel.Value ~= plr.Name then return end
	Ts:Create(PanelCode.Selector1.Highlight, TweenInfo.new(0.2), {OutlineTransparency = 1}):Play()
end)

PanelCode.Selector2.Clicker.ClickDetector.MouseHoverEnter:Connect(function(plr)
	if PlrOnPanel.Value ~= plr.Name then return end
	Ts:Create(PanelCode.Selector2.Highlight, TweenInfo.new(0.2), {OutlineTransparency = hoverTransparency}):Play()
end)

PanelCode.Selector2.Clicker.ClickDetector.MouseHoverLeave:Connect(function(plr)
	if PlrOnPanel.Value ~= plr.Name then return end
	Ts:Create(PanelCode.Selector2.Highlight, TweenInfo.new(0.2), {OutlineTransparency = 1}):Play()
end)

PanelCode.Selector3.Clicker.ClickDetector.MouseHoverEnter:Connect(function(plr)
	if PlrOnPanel.Value ~= plr.Name then return end
	Ts:Create(PanelCode.Selector3.Highlight, TweenInfo.new(0.2), {OutlineTransparency = hoverTransparency}):Play()
end)

PanelCode.Selector3.Clicker.ClickDetector.MouseHoverLeave:Connect(function(plr)
	if PlrOnPanel.Value ~= plr.Name then return end
	Ts:Create(PanelCode.Selector3.Highlight, TweenInfo.new(0.2), {OutlineTransparency = 1}):Play()
end)

PanelCode.Selector4.Clicker.ClickDetector.MouseHoverEnter:Connect(function(plr)
	if PlrOnPanel.Value ~= plr.Name then return end
	Ts:Create(PanelCode.Selector4.Highlight, TweenInfo.new(0.2), {OutlineTransparency = hoverTransparency}):Play()
end)

PanelCode.Selector4.Clicker.ClickDetector.MouseHoverLeave:Connect(function(plr)
	if PlrOnPanel.Value ~= plr.Name then return end
	Ts:Create(PanelCode.Selector4.Highlight, TweenInfo.new(0.2), {OutlineTransparency = 1}):Play()
end)

task.wait(3)

setupPanel()
