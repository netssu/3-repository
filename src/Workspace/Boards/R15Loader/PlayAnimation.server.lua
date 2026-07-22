--Variables--
local set = script.Settings
local sp = set.Speed
local enabled = set.Enabled
local hum = script.Parent:WaitForChild("Humanoid")
if hum then
--	print("Success")
else
	print("No Humanoid")
end
local humanim = hum:LoadAnimation(script:FindFirstChildOfClass("Animation"))

--Playing Animation--
if enabled.Value == true then
	humanim:Play()
	humanim.Looped = true
	humanim:AdjustSpeed(sp.Value)
end 
