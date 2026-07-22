--//Services
local Rs = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local PathfindingService = game:GetService("PathfindingService")
local HandrailRaycast = require(Rs:WaitForChild("Modules"):WaitForChild("HandrailRaycast"))

--//Monster
local NPC = script.Parent
local Hum = NPC:FindFirstChild("Humanoid")
local MonsterWaypoints = workspace.Map.Monsters.Flayed_Nodes
NPC.PrimaryPart:SetNetworkOwner(nil)

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local JumpscareEvent = Remotes:WaitForChild("Jumpscare")

--//Modules
local ModulesFolder = Rs:WaitForChild("Modules")
local BadgesModule = require(ModulesFolder:FindFirstChild("Badges"))
local GameConfigModule = require(ModulesFolder:FindFirstChild("GameConfigModule"))

--//Sounds
local RandomSounds = script:FindFirstChild("RandomSounds")
local SoundsFolder = script:FindFirstChild("Sounds")
local AttackSound = SoundsFolder:FindFirstChild("AttackSound")
local FootStepSound = SoundsFolder:FindFirstChild("FootStepSound")
local JumpscareSound = SoundsFolder:FindFirstChild("JumpscareSound")
local IntenseSound = SoundsFolder:FindFirstChild("IntenseSound")

--//Module
local config = require(script:FindFirstChild("Config"))

--//Values
local chasing = false -- when the monster is chasing a player
local wandering = false -- when the monster is just walking around
local searching = false -- true if the monster can't see the player, then start searching
local LastLocation = nil -- Last random waypoint choosen
local chasingPlr = nil -- current player being chased
local stuckTimes = 0
local maxStuck = 20
local onDollCurse = false
local Tries = 0 -- Current Tries to find a lost player (can change maxTries on Config module)
local firstTime = true -- When the monster lost the player for the first time, this value reset
local OnChaseDebounce = false -- current useless (on use only in line 188)
local state = NPC:FindFirstChild("state") -- For monster animations

--//Setup
Hum.WalkSpeed = config.NormalSpeed
FootStepSound.Parent = NPC.HumanoidRootPart

local animationsFolder = NPC.Animator.Animations

ContentProvider:PreloadAsync(animationsFolder:GetChildren())
for i, v in animationsFolder:GetChildren() do
	if v:IsA("Animation") then
		Hum.Animator:LoadAnimation(v)
	end
end

local function playSound(sound: Sound)
	if not sound:IsA("Sound") then return end
	local snd = sound:Clone()
	snd.Parent = NPC.HumanoidRootPart
	snd:Play()
	game.Debris:AddItem(snd, 5)
end

local function getPath(destination, unstuck: boolean)
	local path = PathfindingService:CreatePath(config.agentParams)

	if unstuck then
		path = PathfindingService:CreatePath()
	end

	path:ComputeAsync(NPC.HumanoidRootPart.Position, destination.Position)
	return path
end

local function canSeeTarget(target)
	if not target or not target:FindFirstChild("HumanoidRootPart") then return end

	local origin = NPC.HumanoidRootPart.Position
	local direction = (target.HumanoidRootPart.Position - NPC.HumanoidRootPart.Position).Unit * 40
	local raycastParams = HandrailRaycast.newParams(NPC)

	local hit = workspace:Raycast(origin, direction, raycastParams)

	if hit then
		if hit.Instance:IsDescendantOf(target) then
			return true
		end
	else
		return false
	end
end

local function isInView(target)
	if not target or not target:FindFirstChild("HumanoidRootPart") then return false end

	local origin = NPC.HumanoidRootPart.Position
	local targetPosition = target.HumanoidRootPart.Position
	local direction = (targetPosition - origin).Unit * config.DetectionRange

	local forwardVector = NPC.HumanoidRootPart.CFrame.LookVector
	local toTargetVector = (targetPosition - origin).Unit

	local dotProduct = forwardVector:Dot(toTargetVector)
	local fov = math.cos(math.rad(config.DetectionFov) / 2)

	if dotProduct < fov then
		return false
	end

	local raycastParams = HandrailRaycast.newParams(NPC)

	local hit = workspace:Raycast(origin, direction, raycastParams)

	if hit and hit.Instance:IsDescendantOf(target) then
		return true -- See a player
	end

	return false -- Don't see a player
end

local function findTarget()
	local maxDistance = config.DetectionRange
	local target

	for i, v in game.Players:GetPlayers() do
		if v.Character then
			local char = v.Character
			if not char then return end
			local hum = char:WaitForChild("Humanoid")
			local rootPart = char:FindFirstChild("HumanoidRootPart")
			local playerValues = v:WaitForChild("PlayerValues")
			if hum and hum.Health > 0 and not playerValues:FindFirstChild("OnSafe").Value and rootPart then
				local distance = (rootPart.CFrame.Position - NPC.HumanoidRootPart.Position).Magnitude
				if distance < maxDistance and canSeeTarget(v.Character) then
					maxDistance = distance
					target = v
				end
			end
		end
	end
	return target
end

-- If found a closer cursed doll, then be inative for 10 seconds.
local function getCursedDoll()
	local maxDistance = config.DetectionRange
	local target
	for i, v in workspace:GetDescendants() do
		if v:IsA("MeshPart") and v.Name == "CursedDoll" then
			if not v:GetAttribute("Enabled") then return end -- Check if the doll curse is enabled
			local distance = (v.CFrame.Position - NPC.HumanoidRootPart.Position).Magnitude
			if distance < maxDistance then
				maxDistance = distance
				target = v
				break
			end
		end
	end
	return target
end

local function getUnstuck(destination)
	if stuckTimes >= maxStuck then
		stuckTimes = 0
		local randomLocation = MonsterWaypoints:GetChildren()[math.random(1, #MonsterWaypoints:GetChildren())]
		local path = getPath(randomLocation, true)

		if path.Status == Enum.PathStatus.Success then
			for i, waypoint in pairs(path:GetWaypoints()) do
				Hum:MoveTo(waypoint.Position)
				local target = findTarget()
				if target and canSeeTarget(target.Character) then
					chasingPlr = target
					chasing = true
					searching = false
					wandering = false
					Tries = 0
					break
				end
				Hum.MoveToFinished:Wait()
			end
		end
		return
	end

	--[[
	local newPosition = NPC.HumanoidRootPart.Position + Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
	
	local path = getPath({Position = newPosition})
	if path.Status == Enum.PathStatus.Success then
		Hum:MoveTo(newPosition)
	else
		Hum:MoveTo(NPC.HumanoidRootPart.Position + Vector3.new(0, 5, 0))
	end
	]]--

	NPC.Humanoid:MoveTo(NPC.HumanoidRootPart.Position + (NPC.HumanoidRootPart.Position - destination.Position).Unit * 10)
	stuckTimes += 1
end

local function Jumpscare(target)
	Hum.WalkSpeed = 0
	state.Value = "idle"

	local CamPart= NPC:FindFirstChild("Cam")
	local JumpscareAnim = NPC:FindFirstChild("Animator"):FindFirstChild("Animations"):FindFirstChild("Jumpscare")

	JumpscareEvent:FireClient(target, NPC, JumpscareSound, CamPart, JumpscareAnim, IntenseSound)

	task.delay(2.3, function()
		target.Character.Humanoid.Health = 0
	end)

	local badge = BadgesModule:FindBadge("Bob-a-Scare")
	BadgesModule:GiveBadge(target, badge.Id)

	if config.KillDelay > 0 then
		task.wait(config.KillDelay)
	end

	return true
end

local function attack(target)
	if not target or not target.Character then return end
	local char = target.Character
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChild("Humanoid")

	if not hrp or not hum or hum.Health <= 0 then
		chasing = false
		return
	end

	-- distância exata
	local distance = (hrp.Position - NPC.HumanoidRootPart.Position).Magnitude

	-- ATACAR INSTANTANEAMENTE (sem esperar path)
	if distance <= config.AttackDistance then
		playSound(AttackSound)

		pcall(function()
			local attackAnim = Hum.Animator:LoadAnimation(animationsFolder.Attack)
			attackAnim.Priority = Enum.AnimationPriority.Action3
			attackAnim:Play()
		end)

		-- JUMPSCARE / DAMAGE
		if config.Jumpscare and (config.HitKill or hum.Health - config.Damage <= 0) then
			Jumpscare(target)
		else
			hum.Health -= config.Damage
		end

		-- reset chase
		chasing = false
		chasingPlr = nil
		wandering = true
		searching = false
		Tries = 0

		-- respeita delay do config
		if config.DamageDelay > 0 then
			task.wait(config.DamageDelay)
		end

		return
	end

	-- Se NÃO estiver no alcance, apenas mover normalmente
	-- (o resto do seu comportamento permanece igual)
	Hum:MoveTo(hrp.Position)
end


local function showWayPoints(WayPoints)
	if not WayPoints then return end
	local randomColor = BrickColor.random()
	for i, waypoint in pairs(WayPoints) do
		local p = Instance.new("Part", workspace)
		p.Name = "Path"
		p.Anchored = true
		p.CanCollide = false
		p.Size = Vector3.new(0.6, 0.6, 0.6)
		p.Position = waypoint.Position
		p.Shape = Enum.PartType.Ball
		p.BrickColor = randomColor
		p.Transparency = 0.5
		p.Material = Enum.Material.Neon
		p.Transparency = 0.5
		local function hide()
			game:GetService("TweenService"):Create(p, TweenInfo.new(1), {Transparency = 1}):Play()
		end
		task.delay(8, hide)
		game.Debris:AddItem(p, 10)
	end
end

local function moveTo(destination)
	local path = getPath(destination)

	-- Go to a current target if any
	if chasing and chasingPlr and not onDollCurse then
		-- Check for a target more closer
		local target = findTarget()
		if searching and target ~= chasingPlr then
			if not chasingPlr or not chasingPlr.Character or not chasingPlr.Character.HumanoidRootPart then return end
			if not target or not target.Character or not target.Character.HumanoidRootPart then return end

			local currentTargetDis = (chasingPlr.Character.HumanoidRoot.Part.Position - NPC.HumanoidRootPart.Position).Magnitude
			local newTargetDis = (target.Character.HumanoidRoot.Part.Position - NPC.HumanoidRootPart.Position).Magnitude

			if newTargetDis < currentTargetDis then
				chasingPlr = target
				Tries = 0
			end
		end

		if canSeeTarget(chasingPlr.Character) then
			firstTime = false
			Tries = 0
			searching = false
			attack(chasingPlr)
			return
		elseif not canSeeTarget(chasingPlr.Character) and Tries < config.MaxTries and not firstTime then
			attack(chasingPlr)
			Tries += 1
			searching = true
			return
		else
			chasing = false
			chasingPlr = nil
		end
	end

	if path.Status == Enum.PathStatus.Success then
		stuckTimes = 0
		if config.Visualize then
			showWayPoints(path:GetWaypoints())
		end
		for i, waypoint in pairs(path:GetWaypoints()) do
			local target = findTarget()
			if target and not onDollCurse then
				local hrp = target.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					local dist = (hrp.Position - NPC.HumanoidRootPart.Position).Magnitude

					if dist <= config.AttackDistance then
						attack(target)
						--break
					end
				end

				if canSeeTarget(target.Character) then
					firstTime = false
					Tries = 0
					searching = false
					attack(target)
					break
				elseif not canSeeTarget(target.Character) and Tries < config.MaxTries and not firstTime then
					Tries += 1
					searching = true
					Hum.WalkSpeed = config.FollowingSpeed
					attack(target)
					break
				end
			elseif target and not canSeeTarget(target.Character) and Tries < config.MaxTries and not firstTime and not onDollCurse then
				Tries += 1
				searching = true
				--chasingPlr = target ---
				Hum.WalkSpeed = config.FollowingSpeed
				attack(target)
				break
			elseif target and not canSeeTarget(target.Character) and Tries >= config.MaxTries and not onDollCurse then -- Target lost, start searching
				firstTime = true
				Tries = 0
				chasing = false
				chasingPlr = target
				searching = true
				Hum.WalkSpeed = config.FollowingSpeed
				attack(target)
				break
			else -- only go to the doll pos and ignore players if dollCurse is true.
				chasingPlr = nil
				Hum.WalkSpeed = config.NormalSpeed
				chasing = false
				wandering = true
				Hum:MoveTo(waypoint.Position)

				local distance2 = (destination.Position - NPC.HumanoidRootPart.Position).Magnitude
				if distance2 <= 3 then
					break
				end

				Hum.MoveToFinished:Wait()
			end
		end
	else
		getUnstuck(destination)
	end
end

local function wander()
	local randomLocation = MonsterWaypoints:GetChildren()[math.random(1, #MonsterWaypoints:GetChildren())]

	if #MonsterWaypoints:GetChildren() > 1 then
		if randomLocation == LastLocation then
			repeat wait()
				randomLocation = MonsterWaypoints:GetChildren()[math.random(1, #MonsterWaypoints:GetChildren())]
			until randomLocation ~= LastLocation
		end
	end

	local Path = getPath(randomLocation)
	if Path.Status ~= Enum.PathStatus.Success then
		repeat wait()
			randomLocation = MonsterWaypoints:GetChildren()[math.random(1, #MonsterWaypoints:GetChildren())]
			Path = getPath(randomLocation)
		until Path.Status == Enum.PathStatus.Success
	end

	LastLocation = randomLocation

	if not chasing then
		wandering = true
	else
		wandering = false
	end

	moveTo(randomLocation)
end

--//Manage the monster states for they animation
coroutine.wrap(function()
	while task.wait() do
		if wandering then
			state.Value = "wandering"
		elseif chasing then
			state.Value = "chasing"
		else
			state.Value = "idle"
		end

		local speed = NPC.HumanoidRootPart.AssemblyLinearVelocity.Magnitude

		if speed > 0.1 then
			if FootStepSound.Volume ~= 0.3 then
				FootStepSound.Volume = 0.3
			end
			if not FootStepSound.IsPlaying then
				FootStepSound.Looped = true
				FootStepSound:Play()
			end
			if state.Value == "wandering" then
				FootStepSound.PlaybackSpeed = 0.8
			elseif state.Value == "chasing" then
				FootStepSound.PlaybackSpeed = 1
			end
		else
			game:GetService("TweenService"):Create(FootStepSound, TweenInfo.new(0.01), {Volume = 0}):Play()
		end
	end
end)()

local lastSound = nil

--//Random sounds
coroutine.wrap(function()
	while true do
		task.wait(math.random(config.NoisesDelay, config.NoisesDelay + 3))
		local randomSound = RandomSounds:GetChildren()[math.random(1, #RandomSounds:GetChildren())]

		if #RandomSounds:GetChildren() > 1 then
			if randomSound == lastSound then
				repeat task.wait()
					randomSound = RandomSounds:GetChildren()[math.random(1, #RandomSounds:GetChildren())]
				until randomSound ~= lastSound
			end
		end

		lastSound = randomSound

		playSound(randomSound)
	end
end)()

while true do
	task.wait()

	local cursedDoll = getCursedDoll()
	if cursedDoll then
		onDollCurse = true
		moveTo(cursedDoll, true) -- ignore any player
		onDollCurse = false
	else
		if config.Wander then
			wander()
		else
			local target = findTarget()
			if target then
				moveTo(target.Character.HumanoidRootPart)
			end
		end
	end
end
