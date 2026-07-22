--//Services
local Ts = game:GetService("TweenService")
local Rs = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes", 30)
local VaultPuzzleEvent = Remotes:WaitForChild("vaultPuzzle", 30)

--//UI
local MainFrame = script.Parent
local Title = MainFrame.Title
local LevelsFrame = MainFrame.LevelsFrame
local LevelFrame_EXAMPLE = LevelsFrame.LevelFrame_Example
local ProgressBar = MainFrame.ProgressBar
local ColorFrame = MainFrame.ColorFrame

--//Values
local puzzleLevels = 5
local currentLevel = 1
local currentValue = 0
local valueToReach = 150
local defaultGain = 15
local defaultLost = 20
local currentState = true
local canStart = false
local withRandomState = false
local completed = false
local minRandomTime, maxRandomTime = 250, 400
local lossConnection: RBXScriptConnection = nil

--//Setup
LevelFrame_EXAMPLE.Parent = Rs
for i=1, puzzleLevels do
	local newLevelFrame = LevelFrame_EXAMPLE:Clone()
	newLevelFrame.Parent = LevelsFrame
	newLevelFrame.Name = "Level_"..i
end
MainFrame.Position = UDim2.fromScale(-1, 0)

local function updateCurrentLevel()
	if LevelsFrame:FindFirstChild("Level_"..tostring(currentLevel-1)) then
		VaultPuzzleEvent:FireServer("LevelUp")
		LevelsFrame:FindFirstChild("Level_"..tostring(currentLevel-1)).BackgroundColor3 = Color3.fromRGB(78, 232, 51)
	end
end

local function createLossConnection()
	if lossConnection then
		lossConnection:Disconnect()
	end
	lossConnection = RunService.RenderStepped:Connect(function(dt: number)
		if currentValue > 0 then
			if currentState then
				currentValue -= (dt * defaultLost)
			end
			if currentValue >= valueToReach then
				currentValue = 0
				ProgressBar.Bar.Size = UDim2.fromScale(currentValue/valueToReach, 1)
				currentLevel += 1
				valueToReach += valueToReach * 0.1
				minRandomTime -= minRandomTime * 0.1
				maxRandomTime -= maxRandomTime * 0.15
				defaultLost += defaultLost * 0.1
				updateCurrentLevel()
				if currentLevel > puzzleLevels then
					VaultPuzzleEvent:FireServer("Completed") -- Puzzle Completed
					ProgressBar.Bar.Size = UDim2.fromScale(1, 1)
					ColorFrame.BackgroundColor3 = Color3.fromRGB(86, 255, 67)
					completed = true
					Title.Text = "Vault Unlocked!"
					if lossConnection then
						lossConnection:Disconnect()
					end
				end
			end
		end
		Ts:Create(ProgressBar.Bar, TweenInfo.new(0.1), {Size = UDim2.fromScale(currentValue/valueToReach, 1)}):Play()
	end)
end

local function enableRandomState()
	while true do
		task.wait(math.random(minRandomTime/100, maxRandomTime/100))
		currentState = false
		ColorFrame.BackgroundColor3 = Color3.fromRGB(255, 51, 51)
		task.wait(math.random(500, 1000)/1000)
		currentState = true
		ColorFrame.BackgroundColor3 = Color3.fromRGB(86, 255, 67)
	end
end

local tween = Ts:Create(MainFrame, TweenInfo.new(1), {Position = UDim2.fromScale(0, 0)})
tween:Play()
tween.Completed:Connect(function()
	canStart = true
	createLossConnection()
end)

if UIS.KeyboardEnabled then
	Title.Text = "Click when is green to unlock."
elseif UIS.GamepadEnabled then
	Title.Text = "Press X when is green to unlock."
elseif UIS.TouchEnabled then
	Title.Text = "Click anywhere when is green to unlock."
end

UIS.InputBegan:Connect(function(Input, gameprocessed)
	if gameprocessed or not canStart or completed then return end
	
	if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.KeyCode == Enum.KeyCode.ButtonX or Input.UserInputType == Enum.UserInputType.Touch then
		if not withRandomState then
			withRandomState = true
			enableRandomState()
		end
		if currentState == true then
			currentValue += defaultGain
			VaultPuzzleEvent:FireServer("Up")
		else
			currentValue -= defaultGain * 0.7
		end
	end
end)