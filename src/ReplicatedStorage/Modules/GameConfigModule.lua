local GameConfig = {
	["PlayerDefaultSpeed"] = 12,
	["PlayerRunSpeed"] = 18,
	["PlayerDefaultJump"] = 3,
	["PlayerDefaultFov"] = 65,
	["PlayerRunFov"] = 80,
	["PlayerCrouchSpeed"] = 8,
	["PlayerChaseSpeed"] = 20, -- The speed of players when in a chase scene. (run speed is used if higher)
	
	["InteractDistance"] = 6.5, -- How far the player can interact with game objects
	["DefaultDamage"] = 30, -- Default player punch damage
	["MaxHealth"] = 100,
	
	["DefaultMouseIcon"] = "rbxasset://textures/MouseLockedCursor.png",
	["ChangingMouseIcon"] = "rbxasset://textures/Cursors/KeyboardMouse/ArrowFarCursor.png",
	["OptionsScreenButton"] = { -- Buttons to open/close the options screen
		Enum.KeyCode.P,
		Enum.KeyCode.ButtonSelect
	},
	
	--//Global configs
	["EnemiesSpawnFactor"] = 20, -- %
	["RandomEventsFactor"] = 20, -- %
	["GameMode"] = "Normal" -- default game mode.
}

GameConfig.UpdateValues = function(valueName, newValue)
	if GameConfig[valueName] then
		GameConfig[valueName] = newValue
	else
		warn("Can't find value:", valueName)
	end
end

return GameConfig
