local NPC = script.Parent
local Hum = NPC:FindFirstChild("Humanoid")
local animator = Hum:FindFirstChild("Animator")
local anim = animator:LoadAnimation(script:FindFirstChild("Idle"))

repeat wait()
	anim:Play()
until anim.IsPlaying