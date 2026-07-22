local DoorCollision = {}

-- CollisionPart is an invisible safety collider added inside a door model.
-- Keep it as an instance (instead of destroying it) so doors that close again
-- can safely restore their collision.
function DoorCollision.setEnabled(door: Instance?, enabled: boolean)
	if not door then return end

	for _, instance in door:GetDescendants() do
		if instance.Name == "CollisionPart" and instance:IsA("BasePart") then
			instance.CanCollide = enabled
			instance.CanTouch = enabled
			instance.CanQuery = enabled
		end
	end
end

function DoorCollision.disable(door: Instance?)
	DoorCollision.setEnabled(door, false)
end

return DoorCollision
