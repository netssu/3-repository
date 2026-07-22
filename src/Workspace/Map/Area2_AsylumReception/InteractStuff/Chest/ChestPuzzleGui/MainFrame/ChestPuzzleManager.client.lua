--//Services
local Ts = game:GetService("TweenService")
local Rs = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local ChestPuzzleEvent = Remotes:WaitForChild("chestPuzzle")

--//Modules
local ModulesFolder = Rs:WaitForChild("Modules")
local BadgesModules = require(ModulesFolder:WaitForChild("Badges"))
local MoneyModule = require(ModulesFolder:WaitForChild("MoneyModule"))

--//UI
local MainFrame = script.Parent
local Title = MainFrame.Title
local Bar = MainFrame.Bar
local TriggerBar = Bar.Trigger
local CorrectArea = Bar.CorrectArea

--//Values
local TriggerConnection : RBXScriptConnection = nil
local canStart = false
local triggerEnabled = false
local started = false
local currentLevel = 1
local maxLevel = 7
local puzzleReward = 10

--//Setup
MainFrame.Position = UDim2.fromScale(-1, 0)
local tween = Ts:Create(MainFrame, TweenInfo.new(1), {Position = UDim2.fromScale(0, 0)})
tween:Play()
tween.Completed:Connect(function()
	canStart = true
end)

if UIS.KeyboardEnabled then
	Title.Text = "Click or press Space to start."
elseif UIS.GamepadEnabled then
	Title.Text = "Press X to start."
elseif UIS.TouchEnabled then
	Title.Text = "Tap anywhere to start."
end

local function enableTrigger(multiplier: number)
	if triggerEnabled then return end
	if (TriggerConnection) then
		TriggerConnection:Disconnect()
	end
	triggerEnabled = true
	
	local mode = "right"
	TriggerConnection = RunService.RenderStepped:Connect(function(dt)
		local mult = math.max(multiplier, 1)
		local amount = (0.012 * mult) * 68 * dt
		
		if TriggerBar.Position.X.Scale <= 0 then
			mode = "right"
		elseif TriggerBar.Position.X.Scale >= 1 then
			mode = "left"
		end
		
		if mode == "right" then 
			TriggerBar.Position = UDim2.fromScale(TriggerBar.Position.X.Scale + amount, TriggerBar.Position.Y.Scale)
		else
			TriggerBar.Position = UDim2.fromScale(TriggerBar.Position.X.Scale - amount, TriggerBar.Position.Y.Scale)
		end
	end)
end

local function randomPos()
	local randomX = math.random(1, 700) / 1000
	Ts:Create(CorrectArea, TweenInfo.new(0.1), {Position = UDim2.fromScale(randomX, 0)}):Play()
	Ts:Create(CorrectArea, TweenInfo.new(0.05), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
end

local function checkIfCorrect()
	local correctStart = CorrectArea.AbsolutePosition.X
	local correctEnd = correctStart + CorrectArea.AbsoluteSize.X
	local triggerStart = TriggerBar.AbsolutePosition.X
	local triggerEnd = triggerStart + TriggerBar.AbsoluteSize.X
	if triggerStart >= correctStart and triggerEnd <= correctEnd then
		ChestPuzzleEvent:FireServer("level") -- Click sound on server
		return true
	end
	return false
end

local function startPuzzle(diff: number, completed: boolean)
	if not completed then
		randomPos()
	end
	
	Title.Text = "Stop the bar when it is on top of the white spot."
	currentLevel += 1
	
	if diff == 1 then
		enableTrigger(1)
	elseif diff == 2 then
		CorrectArea.Size = UDim2.fromScale(CorrectArea.Size.X.Scale - (CorrectArea.Size.X.Scale * 0.07), 1)
		enableTrigger(1.2)
	elseif diff == 3 then
		CorrectArea.Size = UDim2.fromScale(CorrectArea.Size.X.Scale - (CorrectArea.Size.X.Scale * 0.12), 1)
		enableTrigger(1.4)
	elseif diff == 4 then
		CorrectArea.Size = UDim2.fromScale(CorrectArea.Size.X.Scale - (CorrectArea.Size.X.Scale * 0.1), 1)
		enableTrigger(1.6)
	elseif diff == 5 then
		CorrectArea.Size = UDim2.fromScale(CorrectArea.Size.X.Scale - (CorrectArea.Size.X.Scale * 0.1), 1)
		enableTrigger(1.7)
	elseif diff == 6 then
		CorrectArea.Size = UDim2.fromScale(CorrectArea.Size.X.Scale - (CorrectArea.Size.X.Scale * 0.07), 1)
		enableTrigger(1.8)
	elseif diff >= 7 then
		ChestPuzzleEvent:FireServer("win")
		Title.Text = "Chest unlocked."
		local badge = BadgesModules:FindBadge("Opened Chest")
		BadgesModules:GiveBadge(game.Players.LocalPlayer, badge.Id)
		MoneyModule.Give(game.Players.LocalPlayer, puzzleReward)
	end
end

local function stopTrigger()
	if (TriggerConnection) then
		TriggerConnection:Disconnect()
	end
	TriggerConnection = nil
	triggerEnabled = false
	
	local correct = checkIfCorrect()
	
	if correct then
		Title.Text = "Correct!"
		CorrectArea.BackgroundColor3 = Color3.fromRGB(90, 255, 65)
		
		task.wait(1)
		
		if currentLevel >= maxLevel then
			startPuzzle(currentLevel, true)
		else
			startPuzzle(currentLevel, false)
		end
	else
		Title.Text = "Broke."
		CorrectArea.BackgroundColor3 = Color3.fromRGB(255, 24, 24)
		ChestPuzzleEvent:FireServer("lose")
		local badge = BadgesModules:FindBadge("Failed Chest")
		BadgesModules:GiveBadge(game.Players.LocalPlayer, badge.Id)
	end
end

UIS.InputBegan:Connect(function(input, gameprocessed)
	if gameprocessed then return end
	if not triggerEnabled and started then return end
	if not canStart then return end
	
	if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonX or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if not started then
			started = true
			startPuzzle(currentLevel)
			return
		end
		stopTrigger()
	end
end)