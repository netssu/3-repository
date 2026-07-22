--//Services
local pathFinding = game:GetService("PathfindingService")
local ts = game:GetService("TweenService")
local Rs = game:GetService("ReplicatedStorage")
local HandrailRaycast = require(Rs:WaitForChild("Modules"):WaitForChild("HandrailRaycast"))

--//Monster
local npc = script.Parent
local hum = npc.Humanoid
npc.PrimaryPart:SetNetworkOwner(nil)

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local GameConfigModule = require(ModulesFolder:FindFirstChild("GameConfigModule"))

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local ProductJumpscareEvent = Remotes:FindFirstChild("ProductJumpscare")

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
local WAYPOINT_TIMEOUT = 2.5
local PATH_RETRY_DELAY = 0.2
local TARGET_REPATH_DISTANCE = 6
local agentParams = {
	AgentRadius = 2.25,
	AgentHeight = 6,
	AgentCanJump = true,
	AgentCanClimb = false,
	WaypointSpacing = 1.5,
	Costs = {}
}

local function moveToWaypoint(waypoint, shouldInterrupt)
	local movementFinished = false
	local reachedWaypoint = false
	local interrupted = false
	local movementConnection = hum.MoveToFinished:Connect(function(reached)
		movementFinished = true
		reachedWaypoint = reached
	end)

	if waypoint.Action == Enum.PathWaypointAction.Jump then
		hum.Jump = true
	end

	hum:MoveTo(waypoint.Position)

	local startedAt = os.clock()
	repeat
		if shouldInterrupt and shouldInterrupt() then
			interrupted = true
			break
		end
		task.wait(0.05)
	until movementFinished or died or os.clock() - startedAt >= WAYPOINT_TIMEOUT

	movementConnection:Disconnect()

	if interrupted or not movementFinished or not reachedWaypoint then
		hum:MoveTo(npc.HumanoidRootPart.Position)
	end

	return movementFinished and reachedWaypoint, interrupted
end

local function moveDirectlyTo(destination: Vector3)
	local rootPart = npc.HumanoidRootPart
	local offset = destination - rootPart.Position
	local horizontalOffset = Vector3.new(offset.X, 0, offset.Z)
	if horizontalOffset.Magnitude > 0 then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { npc }
		local hit = workspace:Raycast(rootPart.Position, horizontalOffset.Unit * math.min(horizontalOffset.Magnitude, 4), params)
		if hit and HandrailRaycast.isEntranceHandrail(hit.Instance) then
			hum.Jump = true
		end
	end

	hum:MoveTo(destination)
end

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

local function getPath(destination: Vector3)
	local path = pathFinding:CreatePath(agentParams)
	local computed = pcall(function()
		path:ComputeAsync(npc.HumanoidRootPart.Position, destination)
	end)

	if not computed then
		return nil
	end

	return path
end

local function followPath(path, shouldInterrupt)
	if not path or path.Status ~= Enum.PathStatus.Success then
		return false
	end

	local waypoints = path:GetWaypoints()
	local nextWaypointIndex = 2
	local pathBlocked = false
	local blockedConnection = path.Blocked:Connect(function(blockedWaypointIndex)
		if blockedWaypointIndex >= nextWaypointIndex then
			pathBlocked = true
		end
	end)
	local completed = true

	for waypointIndex = 2, #waypoints do
		nextWaypointIndex = waypointIndex
		local reachedWaypoint, waypointInterrupted = moveToWaypoint(waypoints[waypointIndex], function()
			return pathBlocked or (shouldInterrupt and shouldInterrupt())
		end)

		if waypointInterrupted or not reachedWaypoint then
			completed = false
			break
		end
	end

	blockedConnection:Disconnect()
	return completed
end

local function canSeeTarget(target)
	if died then return end
	if not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end
	
	local origin = npc.HumanoidRootPart.Position
	local direction = (target.Character.HumanoidRootPart.Position - npc.HumanoidRootPart.Position).Unit * 50
	local hit = workspace:Raycast(origin, direction, HandrailRaycast.newParams(npc))
	
	if hit then
		if hit.Instance:IsDescendantOf(target.Character) then
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
		
		moveDirectlyTo(target.Character.HumanoidRootPart.Position)
		chasing = false
	else
		if target.Character.Humanoid.Health <= 0 then return end
		
		moveDirectlyTo(target.Character.HumanoidRootPart.Position)
		
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
			
			chasing = false
			
			if target.Character.Humanoid.Health - config.Damage <= 0 then
				local plr = game.Players:GetPlayerFromCharacter(target.Character)
				pcall(function()
					if plr and not plr:GetAttribute("OnJumpscare") then
						plr:SetAttribute("OnJumpscare", true)
						
						local PatientModel = workspace.Map.JumpscareBoxes.PatientScare.Patient_Enemy_Var1
						local SoundsFolder = PatientModel.Sounds
						ProductJumpscareEvent:FireClient(plr, PatientModel, SoundsFolder.ScreamSound, PatientModel.CamPart, 129728063187402, SoundsFolder.HitSound)
					end
				end)
				
				task.wait(2)
				
				if plr then
					plr:SetAttribute("OnJumpscare", nil)
				end
				target.Character.Humanoid.Health = 0
				wander()
				return
			else
				target.Character.Humanoid:TakeDamage(config.Damage) -- Apply damage to target
			end
			
			task.wait(config.DamageDelay) -- Attack delay
		end
	end
end

local function followTarget(target)
	local targetRootPart = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	if not targetRootPart then return end

	local pathDestination = targetRootPart.Position
	local path = getPath(pathDestination)
	hum.WalkSpeed = config.NormalSpeed
	state.Value = "wandering"
	chasedTimes = 0
	if config.Depuration then
		print("folowing target")
	end

	if not path or path.Status ~= Enum.PathStatus.Success then
		task.wait(PATH_RETRY_DELAY)
		return
	end

	local pathCompleted = followPath(path, function()
		local currentRootPart = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
		if not currentRootPart then
			return true
		end

		return canSeeTarget(target)
			or (currentRootPart.Position - pathDestination).Magnitude >= TARGET_REPATH_DISTANCE
	end)

	if canSeeTarget(target) then
		chaseTarget(target)
	elseif not pathCompleted then
		task.wait(PATH_RETRY_DELAY)
	end
end

function wander()
	local initialPos = npc.HumanoidRootPart.Position
	local randomPos = initialPos + Vector3.new(math.random(-20, 20), 0, math.random(-20, 20))
	local path = getPath(randomPos)
	state.Value = "wandering"
	hum.WalkSpeed = config.NormalSpeed

	if not path or path.Status ~= Enum.PathStatus.Success then
		task.wait(PATH_RETRY_DELAY)
		return
	end

	local detectedTarget = nil
	local pathCompleted = followPath(path, function()
		detectedTarget = findTarget()
		return detectedTarget ~= nil and not chaseDebounce
	end)

	if detectedTarget and not chaseDebounce and canSeeTarget(detectedTarget) then
		chaseTarget(detectedTarget)
	elseif not detectedTarget and not pathCompleted then
		task.wait(PATH_RETRY_DELAY)
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
