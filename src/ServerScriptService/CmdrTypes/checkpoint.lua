local function getCheckpointNames(): { string }
	local map = workspace:FindFirstChild("Map")
	local teleportZones = map and map:FindFirstChild("TeleportZones")
	local names = {}

	if teleportZones then
		for _, zone in teleportZones:GetChildren() do
			if zone:IsA("Folder") or zone:IsA("Model") then
				table.insert(names, zone.Name)
			end
		end
	end

	table.sort(names)
	return names
end

local function findMatches(text: string): { string }
	local matches = {}
	for _, name in getCheckpointNames() do
		if name:lower() == text:lower() then
			table.insert(matches, 1, name)
		elseif name:lower():find(text:lower(), 1, true) then
			table.insert(matches, name)
		end
	end
	return matches
end

return function(registry)
	registry:RegisterType("checkpoint", {
		Transform = findMatches,
		Validate = function(matches)
			return #matches > 0, "No checkpoint with that name exists."
		end,
		Autocomplete = function(matches)
			return matches
		end,
		Parse = function(matches)
			return matches[1]
		end,
	})
end
