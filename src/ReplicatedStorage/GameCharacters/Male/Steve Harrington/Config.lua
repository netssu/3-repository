-----//[STEVE HARRIGNTON]//-----

local config = {
	["Name"] = script.Parent.Name;
	["Price"] = 0; -- 0 for default characters
	["Health"] = 130;
	["Damage"] = 26;
	["Jump"] = 3;
	["Speed"] = 12;
	["RunSpeed"] = 21;
	["CrouchSpeed"] = 7;
	["Order"] = 7;
	["Desc"] =
		"A tough frontline protector, using experience and grit to shield others from danger.";
	["StarterItems"] = {
		["Flashlight"] = 1;
		["Baseball Bat"] = 1;
	};
	["Limited"] = true -- this character can't be purchased, players award this character by other ways
}

return config