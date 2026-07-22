--!strict

local StarterGui = game:GetService("StarterGui")

local RETRY_DELAY = 0.25

while true do
	local Success = pcall(StarterGui.SetCore, StarterGui, "ResetButtonCallback", false)
	if Success then
		break
	end
	task.wait(RETRY_DELAY)
end
