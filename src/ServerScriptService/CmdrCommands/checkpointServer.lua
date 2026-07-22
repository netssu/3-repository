local Workspace = game:GetService("Workspace")

local function getCheckpointNames(teleportZones: Instance): { string }
	local names = {}
	for _, zone in teleportZones:GetChildren() do
		if zone:IsA("Folder") or zone:IsA("Model") then
			table.insert(names, zone.Name)
		end
	end
	table.sort(names)
	return names
end

return function(_, players: { Player }, checkpointName: string)
	local map = Workspace:FindFirstChild("Map")
	local teleportZones = map and map:FindFirstChild("TeleportZones")
	if not teleportZones then
		return "Map.TeleportZones was not found."
	end

	local checkpoint = teleportZones:FindFirstChild(checkpointName)
	if not checkpoint then
		local available = getCheckpointNames(teleportZones)
		return ("Unknown checkpoint %q. Available: %s"):format(checkpointName, table.concat(available, ", "))
	end

	local spawnParts = {}
	for _, instance in checkpoint:GetChildren() do
		if instance:IsA("BasePart") then
			table.insert(spawnParts, instance)
		end
	end
	if #spawnParts == 0 then
		return ("Checkpoint %q has no spawn parts."):format(checkpointName)
	end

	local teleported = 0
	for _, player in players do
		local character = player.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
		if rootPart and humanoid and humanoid.Health > 0 then
			rootPart.CFrame = spawnParts[math.random(1, #spawnParts)].CFrame + Vector3.new(0, 3, 0)
			teleported += 1
		end
	end

	return ("Teleported %d player(s) to checkpoint %q."):format(teleported, checkpointName)
end
