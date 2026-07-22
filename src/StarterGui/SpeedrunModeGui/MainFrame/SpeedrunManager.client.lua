--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local GameStartedEvent = Remotes:WaitForChild("GameStarted")
local SpeedrunStartEvent = Remotes:WaitForChild("SpeedrunStart")

--//Modules
local Modules = Rs:WaitForChild("Modules")
local GameConfig = require(Modules:WaitForChild("GameConfigModule"))
local DataHandler = require(Modules:WaitForChild("DataHandler"))

local Utils = Modules:WaitForChild("Utils")
local FormatString = require(Utils:WaitForChild("FormatString"))

--//UI
local MainFrame = script.Parent
local OldTimeText = MainFrame.OldTimeText
local CurrentTimeText = MainFrame.CurrentTimeText

--//Values
local running = false
local timerCounter = nil
local startTimer = 0

GameStartedEvent.Event:Connect(function()
	if GameConfig.GameMode == "Speedrun" then
		MainFrame.Visible = true
		SpeedrunStartEvent:FireServer() -- Start the timer on server
		
		if running and timerCounter then
			running = false
			task.wait()
		end
		
		startTimer = time()
		running = true
		
		timerCounter = coroutine.create(function()
			while running do
				local timeSpent = time() - startTimer
				local formattedTime = FormatString:TimeString(timeSpent)
				CurrentTimeText.Text = formattedTime
				task.wait(0.025)
			end
		end)
		coroutine.resume(timerCounter)
		
		pcall(function()
			local plrData = DataHandler:GetProfileData(game.Players.LocalPlayer)
			if plrData and plrData["Speedruns"] then
				if plrData["Speedruns"]["Chapter1"] then
					local oldTime = plrData["Speedruns"]["Chapter1"]
					local formattedOldTime = FormatString:TimeString(oldTime)
					OldTimeText.Text = "Old Time: "..formattedOldTime
				end
			end
		end)
	else
		MainFrame.Visible = false
		running = false
	end
end)