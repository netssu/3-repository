-- Makes the entrance handrails transparent to enemy line-of-sight raycasts.
-- This deliberately does not change collision or PathfindingService navigation.
local HandrailRaycast = {}

local ignoredNames = {
	Handrail = true,
	Handrail2 = true,
}

local function getAssets(): Instance?
	local map = workspace:FindFirstChild("Map")
	local entrance = map and map:FindFirstChild("Area1_Entrance")
	return entrance and entrance:FindFirstChild("Assets")
end

function HandrailRaycast.isEntranceHandrail(instance: Instance): boolean
	local assets = getAssets()
	return assets ~= nil
		and instance:IsA("BasePart")
		and ignoredNames[instance.Name] == true
		and instance:IsDescendantOf(assets)
end

function HandrailRaycast.newParams(npc: Instance): RaycastParams
	local ignoredInstances = { npc }
	local assets = getAssets()

	if assets then
		for _, instance in assets:GetDescendants() do
			if HandrailRaycast.isEntranceHandrail(instance) then
				table.insert(ignoredInstances, instance)
			end
		end
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignoredInstances
	return params
end

return HandrailRaycast
