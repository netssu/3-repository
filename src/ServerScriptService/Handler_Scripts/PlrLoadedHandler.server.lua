--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local PlrLoaded = Remotes:FindFirstChild("PlayerLoaded")

PlrLoaded.OnServerEvent:Connect(function()
	PlrLoaded:FireAllClients() -- Fire all players that a player loaded.
end)