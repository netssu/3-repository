--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Modules
local Modules = Rs:FindFirstChild("Modules")
local InventoryModules = require(Modules:FindFirstChild("InventoryModule"))

--//Tool
local bearTrapTool = script.Parent
local DropItemEvent = bearTrapTool.DropItem
local BearTrapModel = bearTrapTool.Handle.BearTrapModel
local BearTrapModule = require(BearTrapModel.Base.BearTrapMain)

DropItemEvent.OnServerEvent:Connect(function(plr, trapCFrame)
	BearTrapModule.Init(plr, trapCFrame)
end)