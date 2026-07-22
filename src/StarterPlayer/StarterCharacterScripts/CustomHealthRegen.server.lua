-- Gradually regenerates the Humanoid's Health over time.

local REGEN_RATE = 1/400 -- Regenerate this fraction of MaxHealth per second.
local REGEN_STEP = 1.6 -- Wait this long between each regeneration step.

--------------------------------------------------------------------------------

local Character = script.Parent
local Humanoid = Character:WaitForChild("Humanoid")
local originalHealth = Character:FindFirstChild("Health") :: Script or nil
if originalHealth then
	originalHealth.Enabled = false
end

--------------------------------------------------------------------------------

while true do
	if Humanoid.Health <= 0 then
		Humanoid.Health = 0
		break
	end
	while Humanoid.Health < Humanoid.MaxHealth do
		local dt = wait(REGEN_STEP)
		local dh = dt*REGEN_RATE*Humanoid.MaxHealth
		Humanoid.Health = math.min(Humanoid.Health + dh, Humanoid.MaxHealth)
	end
	Humanoid.HealthChanged:Wait()
	if Humanoid.Health <= 0 then
		break
	end
end