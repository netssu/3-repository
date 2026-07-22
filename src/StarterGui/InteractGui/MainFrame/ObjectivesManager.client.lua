--//Services
local Ts = game:GetService("TweenService")
local Rs = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")

--//Player
local Player = game.Players.LocalPlayer
local PlayerValues = Player:WaitForChild("PlayerValues")
local OnCutscene = PlayerValues:WaitForChild("OnCutscene") :: BoolValue
local Camera = workspace.CurrentCamera
local PlayerControls = require(Player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()

-- Objective cutscenes use their own camera sequence instead of CutsceneManager,
-- so they must explicitly enter the same local/server cutscene state.
local PlayerValuesRemote = Rs:WaitForChild("Remotes"):WaitForChild("PlayerValues")

--//Modules
local ModulesFolder = Rs:WaitForChild("Modules")
local SoundPlayer = require(ModulesFolder.Utils:WaitForChild("SoundPlayer"))
local GameConfig = require(ModulesFolder:WaitForChild("GameConfigModule"))

--//UI
local MainFrame = script.Parent
local ObjectivesFrame = MainFrame.ObjectivesFrame
local ObjectivesList = ObjectivesFrame.ObjectivesList
local OBJECTIVE_EXAMPLE = ObjectivesList.ObjectiveExample
local ObjectivesButton = ObjectivesFrame.ObjectivesButton
local NotificationFrame = MainFrame.NotificationFrame
local NOTIFICATION_EXAMPLE = NotificationFrame.NotificationText_Example
local TransitionFrame = MainFrame.TransitionFrame

--//Sounds
local ClickSound = script:FindFirstChild("ClickSound")
local NewObjectiveSound = script:FindFirstChild("NewObjectiveSound")
local CompleteObjectiveSound = script:FindFirstChild("CompleteObjectiveSound")

--//Objectives Stuff
local CurrentObjectives = Rs:WaitForChild("CurrentGameObjectives")
local CompletedObjectives = CurrentObjectives:WaitForChild("CompletedObjectives")
local ObjectivesCutscenes = workspace:WaitForChild("Map"):WaitForChild("ObjsCutscenes")

--//Values
local currentState = false

--//Quick Setup
OBJECTIVE_EXAMPLE.Parent = Rs
NOTIFICATION_EXAMPLE.Parent = Rs
ObjectivesFrame.Position = UDim2.fromScale(1, 0.173)
ObjectivesFrame.Visible = true
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

local function changeObjectives(state: boolean)
	if OnCutscene.Value then return end
	ClickSound:Play()
	if state then
		ObjectivesButton.Text = ">"
		Ts:Create(ObjectivesFrame, TweenInfo.new(0.15), {Position = UDim2.fromScale(0.809, 0.173)}):Play()
	else
		ObjectivesButton.Text = "<"
		Ts:Create(ObjectivesFrame, TweenInfo.new(0.15), {Position = UDim2.fromScale(1, 0.173)}):Play()
	end
end

local function objectiveCutscene(cutsceneFolderName: string)
	if OnCutscene.Value or Player:GetAttribute("CutsceneCameraLocked") then return end
	if not ObjectivesCutscenes then return end
	if typeof(cutsceneFolderName) ~= "string" then return end
	
	local cutsceneFolder = ObjectivesCutscenes:WaitForChild(cutsceneFolderName)
	if not cutsceneFolder then
		warn("[ObjectivesManager] Objective Cutscene Folder", cutsceneFolderName, "Doesn't exists.")
	end
	
	local camParts = {}
	local prefix = "Cam"
	for i=1, #cutsceneFolder:GetChildren() do
		local camPart = cutsceneFolder:FindFirstChild(prefix..i)
		if camPart then
			table.insert(camParts, i, camPart)
		end
	end
	
	--//No cutscene cam parts found
	if #camParts == 0 then
		warn("[ObjectivesManager] No cam parts for objective cutscene:", cutsceneFolderName)
		return
	end
	
	local sndPlayed = false
	Player:SetAttribute("CutsceneCameraLocked", true)
	PlayerControls:Disable()
	PlayerValuesRemote:FireServer("CutsceneON")
	
	local function makeTransition(state: boolean, complete: boolean)
		if state then -- show transition frame
			local tween1 = Ts:Create(TransitionFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0})
			tween1:Play()
			tween1.Completed:Wait()
			
			task.wait(0.7)
		else -- unshow transition frame
			if not sndPlayed then
				sndPlayed = true
				SoundPlayer:PlaySound(SoundService.Effects.HorrorEffect)
			else
				SoundPlayer:PlaySound(SoundService.Effects.HorrorEffect2)
			end
			local tween2 = Ts:Create(TransitionFrame, TweenInfo.new(0.7), {BackgroundTransparency = complete and 1 or 0.65})
			tween2:Play()
		end
	end
	
	for i=1, #camParts do
		makeTransition(true)
		makeTransition(false)
		
		local camPart = camParts[i]
		Camera.CameraType = Enum.CameraType.Scriptable
		Camera.CFrame = camPart.CFrame
		task.wait(2.3)
	end
	
	makeTransition(true)
	
	Camera.CameraType = Enum.CameraType.Custom -- back to normal
	Player:SetAttribute("CutsceneCameraLocked", false)
	PlayerValuesRemote:FireServer("CutsceneOFF")
	PlayerControls:Enable()
	
	makeTransition(false, true) -- make the transition frame full transparent
end

local function UpdateObjectives()
	--//Delete old objectives
	for i, v in ObjectivesList:GetChildren() do
		if v:IsA("Frame") then
			v:Destroy()
		end
	end
	
	--//Create new objectives
	for i, v in CurrentObjectives:GetChildren() do
		if v.Name ~= "CompletedObjectives" then
			local clone = OBJECTIVE_EXAMPLE:Clone()
			clone.Parent = ObjectivesList
			clone.Title.Text = v.Title.Value
			clone.Desc.Text = v.Description.Value
		end
	end
end

local function notificationText(text: string)
	local clone = NOTIFICATION_EXAMPLE:Clone()
	local DefaultSize = NOTIFICATION_EXAMPLE.Size
	clone.Parent = NotificationFrame
	clone.Size = UDim2.new(0, 0)
	clone.Text = text
	
	Ts:Create(clone, TweenInfo.new(0.2), {Size = DefaultSize}):Play()
	Ts:Create(clone, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
	
	local function unshowText()
		local tween = Ts:Create(clone, TweenInfo.new(0.5), {TextTransparency = 1})
		tween:Play()
		tween.Completed:Connect(function()
			clone.Visible = false
		end)
		game.Debris:AddItem(clone, 3)
	end
	
	task.delay(3, unshowText)
end

--//Detect when a new objective is added
CurrentObjectives.ChildAdded:Connect(function(child)
	if child:FindFirstChild("CutsceneFolder") and GameConfig.GameMode ~= "Speedrun" then
		task.spawn(objectiveCutscene, child.CutsceneFolder.Value) -- start objective cutscene if exists
		task.wait(1.2)
	end
	
	NewObjectiveSound:Play()
	notificationText("New Objective: "..child.Title.Value)
	UpdateObjectives()
	
	if not currentState then
		currentState = true
		changeObjectives(currentState)
	end
end)

--//Detect when a objective is completed
CurrentObjectives.ChildRemoved:Connect(function(child)
	CompleteObjectiveSound:Play()
	notificationText("Objective Completed: "..child.Title.Value)
	UpdateObjectives()
	if not currentState then
		currentState = true
		changeObjectives(currentState)
	end
end)

--//PC & Console
UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.Tab or input.KeyCode == Enum.KeyCode.DPadRight then
		currentState = not currentState
		changeObjectives(currentState)
	end
end)

if UIS.TouchEnabled then
	ObjectivesButton.Visible = true
end

--//Mobile
ObjectivesButton.MouseButton1Click:Connect(function()
	currentState = not currentState
	changeObjectives(currentState)
end)
