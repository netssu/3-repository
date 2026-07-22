----//[BATTERY]//----

local config = {
	["Name"] = script.Parent.Name,
	["Description"] = "Recharges your flashlight battery by 50%.",
	["CanEquip"] = false,
	["CanUse"] = true,
	["CanBeDroped"] = true,
	["Image"] = "rbxassetid://75150709",
	["EquipSound"] = "rbxassetid://0",
	["UseSound"] = "rbxassetid://9120875319"
}

local Rs = game:GetService("ReplicatedStorage")
local Remotes = Rs:WaitForChild("Remotes")
local Modules = Rs:WaitForChild("Modules")
local FlashlightModule = require(Modules:WaitForChild("FlashlightModule"))
local PlayerValuesEvent = Remotes:WaitForChild("PlayerValues")

config.Use = function(plr: Player)
	local PlrValues = plr:WaitForChild("PlayerValues")
	local Batteries = PlrValues:WaitForChild("Batteries") :: IntValue
	
	if Batteries.Value >= FlashlightModule.MaxBattery then
		return "errmsg", "The Flashlight battery is already full."
	end
	
	PlayerValuesEvent:FireServer("Recharge")
end

return config