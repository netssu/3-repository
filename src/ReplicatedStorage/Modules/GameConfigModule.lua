local GameConfig = {
	["PlayerDefaultSpeed"] = 12,
	["PlayerRunSpeed"] = 18,
	["PlayerDefaultJump"] = 3,
	["PlayerDefaultFov"] = 65,
	["PlayerRunFov"] = 80,
	["PlayerCrouchSpeed"] = 8,
	["InteractDistance"] = 7, -- How far the player can interact with game objects
	["DefaultMouseIcon"] = "http://www.roblox.com/asset/?id=13593261200",
	["ChangingMouseIcon"] = "http://www.roblox.com/asset/?id=13121776385",
	["OptionsScreenButton"] = { -- Buttons to open/close the options screen
		Enum.KeyCode.P,
		Enum.KeyCode.ButtonSelect
	},
	["DefaultDamage"] = 30, -- Default player punch damage
	["MaxHealth"] = 100,
	["EnemiesSpawnFactor"] = 17 -- %
}

GameConfig.UpdateValues = function(valueName, newValue)
	if GameConfig[valueName] then
		GameConfig[valueName] = newValue
	else
		warn("Can't find value:", valueName)
	end
end

return GameConfig
