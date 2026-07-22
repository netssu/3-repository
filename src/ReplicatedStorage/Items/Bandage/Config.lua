----//[BANDAGE]//----

local config = {
	["Name"] = script.Parent.Name,
	["Description"] = "You can use this bandage to recover your health.",
	["CanEquip"] = true,
	["CanUse"] = true,
	["CanBeDroped"] = true,
	["Image"] = "rbxassetid://5296816619",
	["EquipSound"] = "rbxassetid://8022960947",
	["UseSound"] = "rbxassetid://9113419964"
}

config.Use = function(plr: Player)
	local ChangePlrLife = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes"):FindFirstChild("ChangePlrLife")
	local char = plr.Character
	local hum = char:WaitForChild("Humanoid") :: Humanoid
	
	if hum.Health >= hum.MaxHealth then
		return "errmsg", "Life is already full."
	end
	
	ChangePlrLife:FireServer(hum.MaxHealth * 0.35, "bandage") -- heal by 35% the max hp
end

return config