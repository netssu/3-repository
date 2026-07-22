--//Services
local Rs = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

--//Player
local plr = Players.LocalPlayer

--//UI
local button = script.Parent.StarterPack

--//Modules
local Modules = Rs:WaitForChild("Modules")
local ShopModule = require(Modules.ShopModule)

--//Assets
local elevenPass = ShopModule:GetPass("Eleven")

--//Constants
local totalTime = 60 * 10 -- 10 minutes

local function checkIfOwnPass()
	local success, hasPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(game.Players.LocalPlayer.UserId, elevenPass.ID)
	end)
	
	if success and hasPass then
		button.Visible = false
	end
end

local function formatMS(seconds: number)
	local minutes = math.floor(seconds / 60)
	local remainingSeconds = seconds % 60
	return string.format("%02d:%02d", minutes, remainingSeconds)
end

local function startTimer()
	local timeLeft = totalTime
	while timeLeft > 0 do
		button.TimerText.Text = "Starter Pack: " .. formatMS(timeLeft)
		task.wait(1)
		timeLeft -= 1
	end
	button.Visible = false
end

checkIfOwnPass()

if button.Visible then
	task.spawn(startTimer)
end

button.MouseButton1Click:Connect(function()
	MarketplaceService:PromptGamePassPurchase(plr, elevenPass.ID)
end)