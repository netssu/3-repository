local set = script.Settings
local sp = set.Speed
local enabled = set.Enabled
local hum = script.Parent:WaitForChild("Humanoid")

if not hum then
	print("No Humanoid")
	return
end

local animations = {
	{name = "Monkey", id = 3333499508},
	{name = "Happy", id = 4841405708},
	{name = "Floss Dance", id = 5917459365},
	{name = "High Wave", id = 5915690960},
	{name = "Hero Landing", id = 5104344710},
	{name = "Tilt", id = 3334538554},
	{name = "Old Town Road", id = 5937560570},
	{name = "Samba", id = 6869766175},
	{name = "Hips Poppin'", id = 6797888062},
	{name = "Side to Side", id = 3333136415},
	{name = "Break Dance", id = 5915648917},
	{name = "Wake Up Call", id = 7199000883},
	{name = "On The Outside", id = 7422779536},
	{name = "Dolphin Dance", id = 5918726674},
	{name = "Stadium", id = 3338055167},
	{name = "Wave", id = 3344650532},
	{name = "HOLIDAY Dance", id = 5937558680}
}

local animationTemplate = script:WaitForChild("Animation")
local currentAnimTrack
local currentAnimationId

local function playAnimation(animationId)
	animationTemplate.AnimationId = "rbxassetid://" .. animationId
	local animTrack = hum:LoadAnimation(animationTemplate) 
	animTrack.Looped = true
	animTrack:AdjustSpeed(sp.Value)
	animTrack:Play()
	currentAnimationId = animationId  -- Track current animation ID
	return animTrack
end

local function getRandomAnimation()
	return animations[math.random(1, #animations)].id
end

local function refreshAnimation()
	if currentAnimTrack then
		currentAnimTrack:Stop()
	end
	currentAnimTrack = playAnimation(currentAnimationId or getRandomAnimation())
end

if enabled.Value == true then
	currentAnimTrack = playAnimation(getRandomAnimation())

	-- Change animation every 2 minutes
	while enabled.Value do
		task.wait(120)
		refreshAnimation()
	end
end
script.Parent.AncestryChanged:Connect(function()
	if enabled.Value then
		refreshAnimation()
	end
end)