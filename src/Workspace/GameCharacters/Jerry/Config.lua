-----//[JERRY]//-----

local config = {
	["Name"] = script.Parent.Name;
	["Price"] = 400; -- 0 for default characters
	["Health"] = 90;
	["Damage"] = 28;
	["Jump"] = 2;
	["Speed"] = 12;
	["RunSpeed"] = 16;
	["CrouchSpeed"] = 8;
	["Order"] = 5; -- LayoutOrder inside of the UI
	["Desc"] =
		"Jerry is obsessed with the asylum and its various theories, he has a backpackthat increases his inventory capacity from 8 to 16.";
	["StarterItems"] = {
		["Lantern"] = 1;
	},
	["InvCapacity"] = 16,
}

return config