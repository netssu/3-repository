return  {
	-- // GroupRank = { RoleID, ChatTag, DefaultName, HasAdmin, AdminLevel, HexCode }
	Founder = { 255, "[Owner]", "Founder", true, 6, "ff97ff" },
	Owner = { 254,  "[Owner]", "Owner", true, 254, "ff97ff"},
	LeadDeveloper = { 10, "[Lead Dev]", "Lead Dev", true, 5, "55ff7f" },
	Developer = { 9, "[Dev]", "Dev", true, 5, "ffa500"},
	Manager = { 8, "[Manager]", "Manager", true, 4, "55aa7f" },
	Admin = { 7, "[Admin]", "Admin", true, 3, "55aa7f" },
	Mod = { 6, "[Mod]", "Mod", true, 2, "55aa7f" },
	Contributer = { 5, "[Contributer]", "Contributer", false, 0, "ffffff" },
	Tester = { 4, "[Tester]", "Tester", false, 1, "ff4747" },
	ContentCreators = { 2, "[ContentCreator]", false, 0, "a020f0"},
	AlphaTester = { 1, "[Alpha]", "AlphaTester", false, 0, "ff00ff" }
--  BetaTester = { 3, "[beta]", "BetaTester", false, 0 },
--  Fan = { 1, "[fan]", "Fan", false, 0 },
}