--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local passesEvent = Remotes:WaitForChild("passesEvent")

--//Player
local plr = game.Players.LocalPlayer

--//Tool
local tool = script.Parent

tool.Activated:Connect(function()
	passesEvent:FireServer("NightGoggles", nil, "changeState") -- change the night goggles state
end)