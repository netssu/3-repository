-----//[ELF]//-----

local config = {
	["Name"] = script.Parent.Name;
	["Price"] = 0; -- 0 for default characters
	["Health"] = 100;
	["Damage"] = 22;
	["Jump"] = 5;
	["Speed"] = 12;
	["RunSpeed"] = 25;
	["CrouchSpeed"] = 8;
	["Order"] = 9;
	["Desc"] =
		"Exclusive Candy cane bat only for this character for very first Christmas Event in Horror Outbreaks (2025)!";
	["StarterItems"] = {
		["Flashlight"] = 1;
		["Candy Cane Bat"] = 1;
	};
	["Limited"] = true, -- this character can't be purchased, players award this character by other ways
}

return config