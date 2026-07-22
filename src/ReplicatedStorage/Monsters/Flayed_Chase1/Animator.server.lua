local MonsterModel = script.Parent
local MonsterHum = MonsterModel:FindFirstChild("Humanoid")
local rootPart = script.Parent:FindFirstChild("HumanoidRootPart")
local MonsterState = MonsterModel:FindFirstChild("state")
local AnimationsFolder = script:FindFirstChild("Animations")

local canPlayAnims = true

local animations = {
	["idle"] = MonsterHum.Animator:LoadAnimation(AnimationsFolder.Idle),
	["run"] = MonsterHum.Animator:LoadAnimation(AnimationsFolder.Run),
	["walk"] = MonsterHum.Animator:LoadAnimation(AnimationsFolder.Walk),
}

local function playAnim(animName)
	for i, v in pairs(animations) do
		if i == animName then
			if not v.IsPlaying then
				v:Play()
			end
		else
			v:Stop()
		end
	end
end

game:GetService("RunService").Heartbeat:Connect(function()
	if rootPart then
		local speed = rootPart.AssemblyLinearVelocity.Magnitude
		
		if MonsterState.Value == "Jumpscare" or MonsterState.Value == "Push" then
			canPlayAnims = false
		elseif not (MonsterState.Value == "Jumpscare") and not (MonsterState.Value == "Push") then
			canPlayAnims = true
		end
		
		if canPlayAnims then
			if speed < 0.1 then
				playAnim("idle")
			else
				if MonsterState.Value == "wandering" then
					playAnim("walk")
				elseif MonsterState.Value == "chasing" then
					playAnim("run")
				else -- In case of a incorrect value
					playAnim("walk")
				end
			end
		else
			playAnim("none") -- Stop all animations
		end
	end
end)