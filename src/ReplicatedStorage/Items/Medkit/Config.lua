----//[MEDKIT]//----

local config = {
	["Name"] = script.Parent.Name,
	["Description"] = "Medkit, when used, heals your health to 100%!",
	["CanEquip"] = true,
	["CanUse"] = true,
	["CanBeDroped"] = true,
	["Image"] = "rbxassetid://70656496005263",
	["EquipSound"] = "rbxassetid://0",
	["UseSound"] = "rbxassetid://9121003784",
}

config.Use = function(plr: Player) -- client-side
	local ChangePlrLife = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes"):FindFirstChild("ChangePlrLife")
	local char = plr.Character
	local hum = char:WaitForChild("Humanoid") :: Humanoid
	
	if hum.Health >= hum.MaxHealth then
		return "errmsg", "Life is already full."
	end
	
	ChangePlrLife:FireServer(hum.MaxHealth * 1) -- heal by 100% the max hp
end

return config