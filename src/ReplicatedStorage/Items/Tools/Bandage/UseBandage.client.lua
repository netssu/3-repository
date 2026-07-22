--//Services
local Rs = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--//Modules
local Modules = Rs:WaitForChild("Modules")
local InventoryModule = require(Modules:WaitForChild("InventoryModule"))

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local ChangePlrLife = Remotes:WaitForChild("ChangePlrLife")
local useItemEvent = Remotes:WaitForChild("UseItem")

--//Player
local plr = Players.LocalPlayer
local char = plr.Character
local hum = char:WaitForChild("Humanoid") :: Humanoid

--//Tool
local tool = script.Parent

tool.Activated:Connect(function()
	if not hum or hum.Health >= hum.MaxHealth then
		return
	end
	
	ChangePlrLife:FireServer(hum.MaxHealth * 0.35, "bandage") -- heal by 35% the max hp
	useItemEvent:FireServer(tool.Name)
end)