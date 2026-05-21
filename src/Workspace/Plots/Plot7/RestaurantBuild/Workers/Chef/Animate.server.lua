local NpcModel = script.Parent
local Humanoid = NpcModel:WaitForChild("Humanoid")
local Animator = Humanoid:WaitForChild("Animator")
local HRP = NpcModel:WaitForChild("HumanoidRootPart")

local WALK_ANIM_ID = "rbxassetid://507777826"
local IDLE_ANIM_ID = "rbxassetid://507766388"

local walkAnim = Instance.new("Animation")
walkAnim.AnimationId = WALK_ANIM_ID
local idleAnim = Instance.new("Animation")
idleAnim.AnimationId = IDLE_ANIM_ID

local walkTrack = Animator:LoadAnimation(walkAnim)
local idleTrack = Animator:LoadAnimation(idleAnim)
walkTrack.Priority = Enum.AnimationPriority.Movement
idleTrack.Priority = Enum.AnimationPriority.Idle
idleTrack:Play()

local lastSpeed = 0
local idleDebounce = false  -- CHAVE DA FIX

game:GetService("RunService").Heartbeat:Connect(function()
	if not HRP or not HRP.Parent then return end

	local velocity = HRP.AssemblyLinearVelocity
	local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude

	if speed > 0.5 then
		-- Cancela qualquer timer de idle pendente
		idleDebounce = false

		if not walkTrack.IsPlaying then
			idleTrack:Stop(0.15)
			walkTrack:Play(0.15)
		end
		walkTrack:AdjustSpeed(math.clamp(speed / 16, 0.5, 2))

	elseif lastSpeed > 0.5 then
		-- Velocidade caiu: espera 0.25s antes de trocar pra idle
		-- Isso cobre a pausa entre waypoints do NoobPath
		idleDebounce = true
		task.delay(0.25, function()
			if idleDebounce then
				idleDebounce = false
				if not idleTrack.IsPlaying then
					walkTrack:Stop(0.2)
					idleTrack:Play(0.2)
				end
			end
		end)
	end

	lastSpeed = speed
end)