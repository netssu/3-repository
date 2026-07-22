local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CUTSCENES = {
	RocksFloor = true,
	FlayedAppear = true,
	BasementBars = true,
	StatuesCutscene = true,
	RestorePowerCutscene = true,
	ChaseStartFlayed = true,
	Chase1_FinalCutscene = true,
}

local function getCutsceneNames(): { string }
	local names = {}
	for name in CUTSCENES do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

return function(_, players: { Player }, cutsceneName: string)
	if not CUTSCENES[cutsceneName] then
		return ("Unknown cutscene %q. Available: %s"):format(cutsceneName, table.concat(getCutsceneNames(), ", "))
	end

	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local activeCutscene = remotes and remotes:FindFirstChild("ActiveCutscene")
	if not activeCutscene or not activeCutscene:IsA("RemoteEvent") then
		return "Remotes.ActiveCutscene was not found."
	end

	for _, player in players do
		activeCutscene:FireClient(player, cutsceneName)
	end

	return ("Playing %q for %d player(s). Some cutscenes also trigger their normal game events."):format(cutsceneName, #players)
end
