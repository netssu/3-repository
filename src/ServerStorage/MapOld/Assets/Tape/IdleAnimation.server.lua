local animController = script.Parent:WaitForChild("AnimationController")
local animator = animController:WaitForChild("Animator")
local idleAnim = script:FindFirstChild("IdleAnim")
local animIdle = animator:LoadAnimation(idleAnim)

repeat wait()
	animIdle:Play()
until animIdle.IsPlaying

animIdle:AdjustSpeed(idleAnim.speed.Value)