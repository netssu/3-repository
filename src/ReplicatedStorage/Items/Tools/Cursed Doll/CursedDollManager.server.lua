--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Modules
local Modules = Rs:FindFirstChild("Modules")
local InventoryModules = require(Modules:FindFirstChild("InventoryModule"))

--//Tool
local cursedDollTool = script.Parent
local DropItemEvent = cursedDollTool.DropItem
local DollModel = cursedDollTool.Handle.CursedDoll
local CursedDollModule = require(DollModel.DollMain)

DropItemEvent.OnServerEvent:Connect(function(plr, dollCFrame)
	CursedDollModule.Init(plr, dollCFrame)
end)