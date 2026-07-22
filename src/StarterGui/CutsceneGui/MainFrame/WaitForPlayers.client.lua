--//Services
local TeleportService = game:GetService("TeleportService")
local Ts = game:GetService("TweenService")
local Rs = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local PlayerLoaded = Remotes:WaitForChild("PlayerLoaded")

--//UI
local MainFrame = script.Parent
local LoadingFrame = MainFrame.LoadingFrame
local TipText = LoadingFrame.TipText
local LoopText = LoadingFrame.LoopText
local PlrsLoaded = LoadingFrame.PlrsLoaded
local TransitionFrame = MainFrame.Transition
LoadingFrame.Visible = true

--//Values
local LoopTextConnection : RBXScriptConnection = nil --For game optimization
local PlrsLoadedConnection : RBXScriptConnection = nil
local TipsConnection : RBXScriptConnection = nil
local MaxElapsedTime = 60
local TotalPlrs = 1
local CurrentPlrs = #game.Players:GetPlayers() - 1 -- Ignore the current plr
local CanStart = false
local Tips = {
	"If you hear something strange then hide.",
	"Share your resources with others players.",
	`If all players don't load in {MaxElapsedTime/60} minute, the game will start automatically.`
}

local TeleportData = TeleportService:GetLocalPlayerTeleportData()
if TeleportData then
	TotalPlrs = TeleportData.TotalPlayers
end

PlayerLoaded.OnClientEvent:Connect(function()
	CurrentPlrs += 1
end)

--//Loop Text Animation
LoopTextConnection = coroutine.wrap(function()
	while true do
		LoopText.Text = "Waiting For Players."
		task.wait(0.5)
		LoopText.Text = "Waiting For Players.."
		task.wait(0.5)
		LoopText.Text = "Waiting For Players..."
		task.wait(0.5)
	end
end)()

--//Tips Text Connection
TipsConnection = coroutine.wrap(function()
	while true do
		local currentTip = Tips[math.random(1, #Tips)]
		TipText.Text = currentTip
		task.wait(4)
	end
end)()

--//Players Loaded Connection
PlrsLoadedConnection = coroutine.wrap(function()
	while wait() do
		PlrsLoaded.Text = CurrentPlrs.."/"..TotalPlrs
		if CurrentPlrs >= TotalPlrs then
			PlrsLoaded.Text = CurrentPlrs.."/"..CurrentPlrs
			CanStart = true
		end
		if CanStart then
			CanStart = false
			local tween = Ts:Create(TransitionFrame, TweenInfo.new(0.3), {BackgroundTransparency = 0})
			tween:Play()
			tween.Completed:Connect(function()
				LoadingFrame.Visible = false
				if (LoopTextConnection) then
					LoopTextConnection:Disconnect()
				end
				if (PlrsLoadedConnection) then
					PlrsLoadedConnection:Disconnect()
				end
				if (TipsConnection) then
					TipsConnection:Disconnect()
				end
				
				task.wait(1)
				
				-- Start the initial cutscene
				local function startEntranceCutscene()
					script.Parent.StarterCutsceneValue.Value = true
					task.wait(3)
					--//Creates a loop in case the CutsceneScript don't load properly
					if not script.Parent.EntranceCutsceneStarted.Value then
						startEntranceCutscene()
					end
				end
				
				startEntranceCutscene()
			end)
			break
		end
	end
end)()

task.wait(3)

if not game:IsLoaded() then
	game.Loaded:Wait()
end

PlayerLoaded:FireServer()

--//Elapsed Time
local function waitForPlrs()
	task.wait(MaxElapsedTime)
	CanStart = true
end
waitForPlrs()