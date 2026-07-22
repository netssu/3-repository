-----//[RAMPART]//-----

local config = {
	["Name"] = script.Parent.Name;
	["Price"] = 0; -- 0 for default characters
	["RobuxId"] = 1551626708;
	["Health"] = 130;
	["Damage"] = 40;
	["Jump"] = 4;
	["Speed"] = 12;
	["RunSpeed"] = 20;
	["CrouchSpeed"] = 8;
	["Order"] = 8;
	["Desc"] =
		"Rampart, a strong army agent with excellent training.";
	["StarterItems"] = {
		["Flashlight"] = 1;
		["Baton"] = 1;
		["Flashbang"] = 3;
	};
	["Limited"] = false, -- this character can't be purchased, players award this character by other ways
}

return config