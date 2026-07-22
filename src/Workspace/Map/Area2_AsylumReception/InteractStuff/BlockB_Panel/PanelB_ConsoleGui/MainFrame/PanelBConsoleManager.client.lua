--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local GamePuzzlesEvent = Remotes:WaitForChild("gamePuzzles")

--//UI
local MainFrame = script.Parent
local button1 = MainFrame.Button_1
local button2 = MainFrame.Button_2
local button3 = MainFrame.Button_3
local button4 = MainFrame.Button_4

button1.Activated:Connect(function()
	GamePuzzlesEvent:FireServer("PanelB_Button1")
end)

button2.Activated:Connect(function()
	GamePuzzlesEvent:FireServer("PanelB_Button2")
end)

button3.Activated:Connect(function()
	GamePuzzlesEvent:FireServer("PanelB_Button3")
end)

button4.Activated:Connect(function()
	GamePuzzlesEvent:FireServer("PanelB_Button4")
end)