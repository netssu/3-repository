local CUTSCENES = {
	"BasementBars",
	"Chase1_FinalCutscene",
	"ChaseStartFlayed",
	"FlayedAppear",
	"RestorePowerCutscene",
	"RocksFloor",
	"StatuesCutscene",
}

local function findMatches(text: string): { string }
	local matches = {}
	for _, name in CUTSCENES do
		if name:lower() == text:lower() then
			table.insert(matches, 1, name)
		elseif name:lower():find(text:lower(), 1, true) then
			table.insert(matches, name)
		end
	end
	return matches
end

return function(registry)
	registry:RegisterType("cutscene", {
		Transform = findMatches,
		Validate = function(matches)
			return #matches > 0, "No cutscene with that name exists."
		end,
		Autocomplete = function(matches)
			return matches
		end,
		Parse = function(matches)
			return matches[1]
		end,
	})
end
