local hum = script.Parent:FindFirstChildWhichIsA("Humanoid")
local idleAnim = script.Parent.IdleAnim
local animator = hum and hum:FindFirstChild("Animator")

local animation = animator and animator:LoadAnimation(idleAnim)
if animation then
	animation:Play()
end