local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DoorCollision = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DoorCollision"))
local map = workspace:WaitForChild("Map")

local function updateDoorFromValue(value: BoolValue)
	local door = value.Parent
	if value.Name == "Locked" then
		DoorCollision.setEnabled(door, value.Value)
	elseif value.Name == "State" then
		DoorCollision.setEnabled(door, not value.Value)
	end
end

local function watchValue(instance: Instance)
	if not instance:IsA("BoolValue") then return end
	if instance.Name ~= "Locked" and instance.Name ~= "State" then return end

	updateDoorFromValue(instance)
	instance:GetPropertyChangedSignal("Value"):Connect(function()
		updateDoorFromValue(instance)
	end)
end

for _, instance in map:GetDescendants() do
	watchValue(instance)
end

map.DescendantAdded:Connect(watchValue)
