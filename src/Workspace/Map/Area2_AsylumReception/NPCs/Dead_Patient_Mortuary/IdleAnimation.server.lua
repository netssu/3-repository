local hum = script.Parent:FindFirstChild("Humanoid")
local animator = hum:WaitForChild("Animator")
local idleAnim = script:FindFirstChild("IdleAnim")
local animIdle = animator:LoadAnimation(idleAnim)

repeat wait()
	animIdle:Play()
until animIdle.IsPlaying

animIdle:AdjustSpeed(idleAnim.speed.Value)