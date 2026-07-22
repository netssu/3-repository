--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local gamePuzzlesEvent = Remotes:WaitForChild("gamePuzzles")

--//Player
local Plr = game.Players.LocalPlayer

--//UI
local ButtonsFrame = script.Parent.ButtonsFrame
local defaultPos = ButtonsFrame.Position
local hiddenPos = UDim2.fromScale(1.5, 0.5)
local buttonsFrameTween = nil

--//Values
local maxGreen = math.random(5, 7)
local currentGreen = 0
local puzzleSolved = false

local function isGamepadInput(inputType: Enum.UserInputType): boolean
	return string.find(inputType.Name, "Gamepad", 1, true) == 1
end

local function shouldUseConsoleButtons(inputType: Enum.UserInputType?): boolean
	if not UIS.GamepadEnabled then
		return false
	end

	return isGamepadInput(inputType or UIS:GetLastInputType())
end

local function setConsoleButtonsEnabled(enabled: boolean)
	enabled = enabled and not puzzleSolved

	if buttonsFrameTween then
		buttonsFrameTween:Cancel()
		buttonsFrameTween = nil
	end

	ButtonsFrame.Visible = enabled
	ButtonsFrame.Active = enabled

	for _, guiObject in ButtonsFrame:GetDescendants() do
		if guiObject:IsA("GuiButton") then
			guiObject.Active = enabled
			guiObject.Selectable = enabled
		end
	end

	if enabled then
		ButtonsFrame.Position = hiddenPos
		buttonsFrameTween = Ts:Create(ButtonsFrame, TweenInfo.new(1, Enum.EasingStyle.Sine), {Position = defaultPos})
		buttonsFrameTween:Play()
	else
		ButtonsFrame.Position = defaultPos
	end
end

--//Setup
setConsoleButtonsEnabled(false)

UIS.LastInputTypeChanged:Connect(function(inputType)
	setConsoleButtonsEnabled(shouldUseConsoleButtons(inputType))
end)

local function checkIfAllCorrect()
	local correct = true
	for _, button in ButtonsFrame:GetChildren() do
		if button:IsA("TextButton") then
			local isEnabled = button:FindFirstChild("IsEnabled")
			if not isEnabled then continue end
			if not isEnabled.Value then
				correct = false
				break
			end
		end
	end
	return correct
end

for _, button in ButtonsFrame:GetChildren() do
	if button:IsA("TextButton") then
		local enabledValue = math.random(1, 5)
		local isEnabled = Instance.new("BoolValue", button)
		isEnabled.Name = "IsEnabled"
		isEnabled.Value = false
		
		if enabledValue == 1 and currentGreen < maxGreen then
			currentGreen += 1
			isEnabled.Value = true
			button.BackgroundColor3 = Color3.fromRGB(60, 255, 0)
		end
		
		button.Activated:Connect(function()
			if puzzleSolved then return end
			
			script.Parent.ClickSound:Play()
			isEnabled.Value = not isEnabled.Value
			
			if isEnabled.Value then
				button.BackgroundColor3 = Color3.fromRGB(60, 255, 0)
			else
				button.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
			end
			
			local completed = checkIfAllCorrect()
			if completed then
				puzzleSolved = true
				setConsoleButtonsEnabled(false)
				gamePuzzlesEvent:FireServer("eletricity_SOLVED")
			end
		end)
	end
end

setConsoleButtonsEnabled(shouldUseConsoleButtons())
