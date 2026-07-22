--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local GamePuzzlesEvent = Remotes:WaitForChild("gamePuzzles")

--//UI
local MainFrame = script.Parent
local buttonsList = MainFrame.ButtonsList
local button1 = buttonsList.Button_1
local button2 = buttonsList.Button_2
local button3 = buttonsList.Button_3
local button4 = buttonsList.Button_4
local button5 = buttonsList.Button_5
local button6 = buttonsList.Button_6
local button7 = buttonsList.Button_7

if not UIS.GamepadEnabled then
	MainFrame.Visible = false
end

button1.Activated:Connect(function()
	GamePuzzlesEvent:FireServer("Levers_1")
end)

button2.Activated:Connect(function()
	GamePuzzlesEvent:FireServer("Levers_2")
end)

button3.Activated:Connect(function()
	GamePuzzlesEvent:FireServer("Levers_3")
end)

button4.Activated:Connect(function()
	GamePuzzlesEvent:FireServer("Levers_4")
end)

button5.Activated:Connect(function()
	GamePuzzlesEvent:FireServer("Levers_5")
end)

button6.Activated:Connect(function()
	GamePuzzlesEvent:FireServer("Levers_6")
end)

button7.Activated:Connect(function()
	GamePuzzlesEvent:FireServer("Levers_7")
end)