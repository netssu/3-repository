--//Services
local pathFinding = game:GetService("PathfindingService")
local ts = game:GetService("TweenService")
local Rs = game:GetService("ReplicatedStorage")

--//Monster
local npc = script.Parent
local hum = npc.Humanoid
npc.PrimaryPart:SetNetworkOwner(nil)

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local GameConfigModule = require(ModulesFolder:FindFirstChild("GameConfigModule"))

--//Sounds
local randomSounds = script:FindFirstChild("RandomSounds")
local soundsFolder = script:FindFirstChild("Sounds")
local DeathSounds = script:FindFirstChild("DeathSounds")
local HurtSounds = script:FindFirstChild("HurtSounds")
local attackSounds = script:FindFirstChild("AttackSounds")
local FootStepSound = soundsFolder:FindFirstChild("FootStepSound")

--//Values
local state = npc.state
local attackDistance = 4
local died = false
local hurting = false
local chasing = false
local chasedTimes = 0
local chaseDebounce = false
local agentParams = {
	AgentRadius = 2.25,
	AgentHeight = 6,
	AgentCanJump = false,
	AgentCanClimb = false,
	WaypointSpacing = 1.5,
	Costs = {}
}

local config = require(script:FindFirstChild("Config"))

if GameConfigModule.GameMode == "Hard" then
	config.persistence += 30
elseif GameConfigModule.GameMode == "Nightmare" then
	config.persistence += 65
end

--//Setup
hum.WalkSpeed = config.NormalSpeed
FootStepSound.Parent = npc.HumanoidRootPart

local function findTarget()
	local maxDistance = config.DetectionRange
	local target = nil
	for i, plr in game.Players:GetPlayers() do
		if plr.Character and plr.Character:FindFirstChild("Humanoid") then
			if plr.Character:FindFirstChild("Humanoid").Health > 0 and not died then
				local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				local dist = (hrp.Position - npc.HumanoidRootPart.Position).Magnitude
				if dist <= maxDistance then
					target = plr
					maxDistance = dist
				end
			end
		end
	end
	return target
end

local function getPath(destination)
	local path = pathFinding:CreatePath(agentParams)
	path:ComputeAsync(npc.HumanoidRootPart.Position, destination.Position)

	return path
end

local function canSeeTarget(target)
	if died then return end
	if not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end
	
	local origin = npc.HumanoidRootPart.Position
	local direction = (target.Character.HumanoidRootPart.Position - npc.HumanoidRootPart.Position).Unit * 50
	local ray = Ray.new(origin, direction)
	local hit, pos = workspace:FindPartOnRay(ray, npc)
	
	if hit then
		if hit:IsDescendantOf(target.Character) then
			return true
		end
	else
		return false
	end
end

local function enabledChaseDebounce()
	if config.Depuration then
		warn("on chase debounce")
	end
	
	hum.WalkSpeed = 0
	chaseDebounce = true
	task.delay(14, function()
		chaseDebounce = false -- Monster will chase player again
	end)
end

local function chaseTarget(target)
	if not chasing then
		chasing = true
	else
		return
	end
	
	local dist = (npc.HumanoidRootPart.Position - target.Character.HumanoidRootPart.Position).Magnitude
	
	local extraSpeed = 0
	if GameConfigModule.GameMode == "Hard" then
		extraSpeed = 2
	elseif GameConfigModule.GameMode == "Nightmare" then
		extraSpeed = 4.5
	end
	
	hum.WalkSpeed = config.ChasingSpeed + extraSpeed
	state.Value = "chasing"
	
	if config.Depuration then
		print("chasing target: ", target)
	end
	
	if chasedTimes >= config.persistence then
		chasedTimes = 0
		chasing = false
		enabledChaseDebounce()
		wander()
		return
	end
	
	if dist > attackDistance then
		chasedTimes += 1
		
		if dist <= attackDistance + 3 then
			chasedTimes -= -0.7
		end
		if config.Depuration then
			print("Give up percentage: ", math.floor(chasedTimes/config.persistence*100).."%")
		end
		
		hum:MoveTo(target.Character.HumanoidRootPart.Position)
		chasing = false
	else
		if target.Character.Humanoid.Health <= 0 then return end
		
		hum:MoveTo(target.Character.HumanoidRootPart.Position)
		
		if not died then
			for i, v in hum.Animator:GetPlayingAnimationTracks() do
				v:Stop()
			end
			
			local animAttack = hum.Animator:LoadAnimation(npc.Animator.Animations.Attack)
			animAttack.Priority = Enum.AnimationPriority.Action4
			animAttack:Play()
			
			chasedTimes = 0
			state.Value = "attacking"
			if config.Depuration then
				print("attacking")
			end
			
			local sound = attackSounds:GetChildren()[math.random(1, #attackSounds:GetChildren())]:Clone()
			sound.Parent = npc.HumanoidRootPart
			sound:Play()
			game.Debris:AddItem(sound, 5)
			
			--if not died and not hurting then
			target.Character.Humanoid:TakeDamage(config.Damage) -- Apply damage to target
			--end
			
			chasing = false
			
			if target.Character.Humanoid.Health <= 0 then
				task.wait(1)
				wander()
				return
			end
			
			task.wait(config.DamageDelay) -- Attack delay
		end
	end
end

local function followTarget(target)
	local path = getPath(target.Character.HumanoidRootPart)
	hum.WalkSpeed = config.NormalSpeed
	state.Value = "wandering"
	chasedTimes = 0
	if config.Depuration then
		print("folowing target")
	end

	if path.Status == Enum.PathStatus.Success then
		for i, v in path:GetWaypoints() do
			hum:MoveTo(v.Position)

			if canSeeTarget(target) then
				chaseTarget(target)
				break
			end

			hum.MoveToFinished:Wait()
		end
	else
		wander()
	end
end

function wander()
	local initialPos = npc.HumanoidRootPart.Position
	local randomPos = initialPos + Vector3.new(math.random(-20, 20), 0, math.random(-20, 20))
	local randomPos1 = initialPos + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
	local path = pathFinding:CreatePath(agentParams)
	path:ComputeAsync(initialPos, randomPos)
	state.Value = "wandering"
	hum.WalkSpeed = config.NormalSpeed

	hum:MoveTo(randomPos1)

	if path.Status == Enum.PathStatus.Success then
		for i, v in path:GetWaypoints() do
			hum:MoveTo(v.Position)

			local target = findTarget()
			if target and not chaseDebounce then
				if canSeeTarget(target) then
					chaseTarget(target)
				end
				break
			end

			hum.MoveToFinished:Wait()
		end
	end
end

--//Manage the monster states for they animation
coroutine.wrap(function()
	while wait() do
		if died then
			state.Value = "dead"
			ts:Create(FootStepSound, TweenInfo.new(0.01), {Volume = 0}):Play()
			break
		end

		local speed = npc.HumanoidRootPart.AssemblyLinearVelocity.Magnitude

		if speed > 0.1 then
			if FootStepSound.Volume ~= 0.3 then
				FootStepSound.Volume = 0.3
			end
			if not FootStepSound.IsPlaying then
				FootStepSound.Looped = true
				FootStepSound:Play()
			end
			if state.Value == "wandering" then
				FootStepSound.PlaybackSpeed = 1.05
			elseif state.Value == "chasing" then
				FootStepSound.PlaybackSpeed = 1.1
			end
		else
			ts:Create(FootStepSound, TweenInfo.new(0.01), {Volume = 0}):Play()
		end
	end
end)()

local function playSound(sound: Sound, parent: Instance?)
	if not sound:IsA("Sound") then return end
	local snd = sound:Clone()
	if parent then
		snd.Parent = parent
	else
		snd.Parent = npc.HumanoidRootPart
	end
	snd:Play()
	game.Debris:AddItem(snd, 5)
end

local lastSound = nil

--//Random sounds
coroutine.wrap(function()
	while true do
		task.wait(math.random(config.NoisesDelay, config.NoisesDelay + 3))
		local randomSound = randomSounds:GetChildren()[math.random(1, #randomSounds:GetChildren())]

		if died then
			break
		end

		if #randomSounds:GetChildren() > 1 then
			if randomSound == lastSound then
				repeat wait()
					randomSound = randomSounds:GetChildren()[math.random(1, #randomSounds:GetChildren())]
				until randomSound ~= lastSound
			end
		end

		lastSound = randomSound

		if not hurting then
			playSound(randomSound, npc.sndPart)
		end
	end
end)()

local lastHealth = hum.Health
local lastHurtSound = nil

--//When monster is damaged, monster become angry and attack player
hum.HealthChanged:Connect(function(health)
	if health < lastHealth then
		local randomSnd = HurtSounds:GetChildren()[math.random(1, #HurtSounds:GetChildren())]

		if #HurtSounds:GetChildren() > 1 and randomSnd == lastHurtSound then
			repeat wait()
				randomSnd = HurtSounds:GetChildren()[math.random(1, #HurtSounds:GetChildren())]
			until randomSnd ~= lastHurtSound
			lastHurtSound = randomSnd
		end
		
		local randomHurtSound = randomSnd:Clone()
		local rootPart = npc:FindFirstChild("HumanoidRootPart")
		if rootPart then
			randomHurtSound.Parent = npc.HumanoidRootPart
		end
		randomHurtSound:Play()
		game.Debris:AddItem(randomHurtSound, 10)
		
		task.wait(0.5)
		
		lastHealth = health
		hurting = true
		chasedTimes = 0
		chaseDebounce = false
		local extraSpeed = 0
		if GameConfigModule.GameMode == "Hard" then
			extraSpeed = 2
		elseif GameConfigModule.GameMode == "Nightmare" then
			extraSpeed = 4.5
		end
		
		hum.WalkSpeed = config.ChasingSpeed + extraSpeed
		
		task.delay(2, function()
			hurting = false
		end)
	end
end)

hum.Died:Connect(function()
	local randomDeathSound = DeathSounds:GetChildren()[math.random(1, #DeathSounds:GetChildren())]:Clone()
	randomDeathSound.Parent = npc.sndPart
	randomDeathSound:Play()
	npc.Animator.Enabled = false -- Disable the animator script

	for i, v in hum.Animator:GetPlayingAnimationTracks() do
		v:Stop()
	end

	hum.WalkSpeed = 0
	game.Debris:AddItem(randomDeathSound, 10)
	died = true
end)

while true do
	wait()
	if died then break end

	local target = findTarget()
	if target and not chaseDebounce then
		if canSeeTarget(target) then
			chaseTarget(target)
		else
			followTarget(target)
		end
	end

	if config.Wander and not target and not (state.Value == "chasing") and not (state.Value == "attacking") then
		wander()
	elseif chaseDebounce then
		wander()
	end
end