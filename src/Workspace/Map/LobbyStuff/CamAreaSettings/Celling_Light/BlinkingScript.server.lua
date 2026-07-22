local LightModel = script.Parent
local BlinkSound = LightModel.Base.LightBlink
local lights = {}

for i, v in LightModel:GetDescendants() do
	if v:IsA("SurfaceLight") or v:IsA("SpotLight") or v:IsA("PointLight") then
		table.insert(lights, v)
	end
end

for i, v in ipairs(lights) do
	coroutine.wrap(function()
		while wait() do
			v.Enabled = true
			wait(math.random(0.5, 1))
			if not BlinkSound.IsPlaying then
				BlinkSound:Play()
			end
			v.Enabled = false
			wait(0.1)
		end
	end)()
end