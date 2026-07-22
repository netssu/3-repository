-----//[BOB]//-----

local config = {
	["Name"] = script.Parent.Name;
	["Price"] = 0; -- 0 for default characters
	["Health"] = 100;
	["Damage"] = 26;
	["Jump"] = 3;
	["Speed"] = 12;
	["RunSpeed"] = 18;
	["CrouchSpeed"] = 7;
	["Order"] = 7;
	["Desc"] =
		"Bob is a naive and fearful young man. His father, Wilson, once worked at the asylum, but disappeared. To overcome his fear, Bob carries a toy sword his father gave him.";
	["StarterItems"] = {
		["Flashlight"] = 1;
		["Toy Sword"] = 1;
	};
	["Limited"] = true -- this character can't be purchased, players award this character by other ways
}

return config