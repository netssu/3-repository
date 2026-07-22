--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local loadCharScriptsEvent = Remotes:WaitForChild("loadPlrCharScripts")

loadCharScriptsEvent.OnClientEvent:Connect(function()
	for _, v in game.StarterPlayer.StarterCharacterScripts:GetChildren() do
		if v:IsA("LocalScript") and v.Name ~= "Animate" then
			v:Clone().Parent = game.Players.LocalPlayer.Character
		end
	end
end)