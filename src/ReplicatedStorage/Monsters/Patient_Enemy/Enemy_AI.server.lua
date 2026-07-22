--!strict

type PathParams = {
	AgentRadius: number,
	AgentHeight: number,
	AgentCanJump: boolean,
	AgentCanClimb: boolean,
	WaypointSpacing: number,
	Costs: {[string]: number}
}

type EnemyState = "idle" | "wandering" | "chasing" | "attacking" | "dead"

local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

export type EnemyAI = {
	npc: Model,
	hum: Humanoid,
	state: StringValue?,
	config: {[string]: any},
	pathfindingSvc: PathfindingService,
	twSvc: TweenService,
	debris: Debris,
	playersSvc: Players,
	soundSets: {
		footStep: Sound,
		attack: Folder?,
		hurt: Folder?,
		death: Folder?,
		random: Folder?
	},
	isDeceased: boolean,
	damageFlag: boolean,
	currentTarget: Player?,
	connections: {[string]: RBXScriptConnection},
	lastHealth: number,
	chaseDebounce: boolean,
	lastRandSnd: Sound?,
	initialize: (self: EnemyAI) -> (),
	destroy: (self: EnemyAI) -> (),
	playAudio: (self: EnemyAI, sound: Sound, parent: Instance?) -> (),
	manageSoundEffects: (self: EnemyAI) -> (),
	manageAnimState: (self: EnemyAI) -> (),
	handleDamaged: (self: EnemyAI, health: number) -> (),
	handleDeath: (self: EnemyAI) -> (),
	mainLoop: (self: EnemyAI) -> (),
	findTarget: (self: EnemyAI) -> Player?,
	followPlayer: (self: EnemyAI, targetPlayer: Player) -> (),
	wanderBehavior: (self: EnemyAI) -> (),
	attackTarget: (self: EnemyAI, targetPlayer: Player) -> ()
}

local PatientEnemy = {} :: EnemyAI
PatientEnemy.__index = PatientEnemy

function PatientEnemy.new(character: Model)
	local self = setmetatable({}, PatientEnemy) :: EnemyAI
	self.npc = character
	self.hum = self.npc:FindFirstChildOfClass("Humanoid") or error("Humanoid not found for " .. character.Name)

	local configModule = character:FindFirstChild("config")
	if configModule and configModule:IsA("ModuleScript") then
		self.config = require(configModule)
	else
		self.config = {}
		warn("Config module not found for " .. character.Name .. ", using default empty config.")
	end

	local stateValue = self.npc:FindFirstChild("State")
	if stateValue and stateValue:IsA("StringValue") then
		self.state = stateValue
	else
		self.state = nil
		warn("State StringValue not found for " .. character.Name)
	end

	self.soundSets = {
		footStep = self.npc:FindFirstChild("FootStep", true) :: Sound or Instance.new("Sound"),
		attack = self.npc:FindFirstChild("AttackSounds", true) :: Folder?,
		hurt = self.npc:FindFirstChild("HurtSounds", true) :: Folder?,
		death = self.npc:FindFirstChild("DeathSounds", true) :: Folder?,
		random = self.npc:FindFirstChild("RandomSounds", true) :: Folder?,
	}
	if not (self.npc:FindFirstChild("FootStep", true) :: Sound) then
		warn("FootStep sound not found for " .. character.Name .. ", a dummy sound has been created.")
	end

	self.pathfindingSvc = PathfindingService
	self.twSvc = TweenService
	self.debris = Debris
	self.playersSvc = Players

	if self.npc.PrimaryPart then self.npc.PrimaryPart:SetNetworkOwner(nil) end

	self.isDeceased = false
	self.damageFlag = false
	self.currentTarget = nil
	self.connections = {}
	self.lastHealth = self.hum.Health
	self.chaseDebounce = false
	self.lastRandSnd = nil

	self:initialize()
	return self
end

function PatientEnemy:initialize()
	if not self.hum then return end
	self.connections.died = self.hum.Died:Connect(function() self:handleDeath() end)
	self.connections.healthChanged = self.hum.HealthChanged:Connect(function(health) self:handleDamaged(health) end)

	coroutine.wrap(function() self:mainLoop() end)()
	coroutine.wrap(function() self:manageAnimState() end)()
	coroutine.wrap(function() self:manageSoundEffects() end)()

	local characterRemovingConn
	characterRemovingConn = self.npc.AncestryChanged:Connect(function(_, parent)
		if not parent then
			self:destroy()
			if characterRemovingConn then
				characterRemovingConn:Disconnect()
			end
		end
	end)
	self.connections.ancestryChanged = characterRemovingConn
end

function PatientEnemy:getTarget(): Player?
	local maxDistance = self.config.DetectionRange
	local target = nil
	
	for _, plr in self.playersSvc:GetPlayers() do
		if plr.Character and plr.Character:FindFirstChild("Humanoid") then
			if plr.Character.Humanoid.Health > 0 and not self.isDeceased then
				local dist = (plr.Character.HumanoidRootPart.Position - self.npc.HumanoidRootPart.Position).Magnitude
				if dist <= maxDistance then
					target = plr
					maxDistance = dist
				end
			end
		end
	end
	return target
end

function PatientEnemy:getNavPath(destination: Vector3): Path
	local path = self.pathfindingSvc:CreatePath(self.config)
	path:ComputeAsync(self.npc.HumanoidRootPart.Position, destination)
	return path
end

function PatientEnemy:canDetectTarget(target: Player): boolean
	if self.isDeceased then return false end
	
	local origin = self.npc.HumanoidRootPart.Position
	local direction = (target.Character.HumanoidRootPart.Position - origin).Unit * 50
	local ray = Ray.new(origin, direction)
	local hit = workspace:FindPartOnRay(ray, self.npc)
	
	if hit and hit:IsDescendantOf(target.Character) then
		return true
	end
	
	return false
end

function PatientEnemy:startChaseCooldown()
	if self.config.Depuration then
		warn("Starting chase cooldown")
	end
	
	self.hum.WalkSpeed = 0
	self.chaseResting = true
	task.delay(14, function()
		self.chaseResting = false
	end)
end

function PatientEnemy:chasePlayer(target: Player)
	if self.chasingTarget then return end
	self.chasingTarget = true
	
	local targetRoot = target.Character.HumanoidRootPart
	local dist = (self.npc.HumanoidRootPart.Position - targetRoot.Position).Magnitude
	
	self.hum.WalkSpeed = self.config.ChasingSpeed
	self.state.Value = "chasing"
	
	if self.config.Depuration then
		print("Chasing target: ", target.Name)
	end
	
	if self.persistenceCounter >= self.config.persistence then
		self.persistenceCounter = 0
		self.chasingTarget = false
		self:startChaseCooldown()
		self:wanderBehavior()
		return
	end
	
	if dist > self.attackDistance then
		self.persistenceCounter += 1
		
		if dist <= self.attackDistance + 3 then
			self.persistenceCounter -= -0.7
		end
		
		if self.config.Depuration then
			print("Give up percentage: ", math.floor(self.persistenceCounter/self.config.persistence*100).."%")
		end
		
		self.hum:MoveTo(targetRoot.Position)
		self.chasingTarget = false
	else
		if target.Character.Humanoid.Health <= 0 then return end
		
		self.hum:MoveTo(target.Character.HumanoidRootPart.Position)
		
		if not self.isDeceased then
			for _, track in self.hum.Animator:GetPlayingAnimationTracks() do
				track:Stop()
			end
			
			if not self.isDeceased then
			
			local animAttack = self.hum.Animator:LoadAnimation(self.npc.Animator.Animations.Attack)
			animAttack.Priority = Enum.AnimationPriority.Action4
			animAttack:Play()
			
			self.persistenceCounter = 0
			self.state.Value = "attacking"
			if self.config.Depuration then
				print("attacking")
			end
			
			local sound = self.soundSets.attack:GetChildren()[math.random(1, #self.soundSets.attack:GetChildren())]:Clone()
			sound.Parent = self.npc.HumanoidRootPart
			sound:Play()
			game.Debris:AddItem(sound, 5)
				
				target.Character.Humanoid:TakeDamage(self.config.Damage)
			
				self.chasingTarget = false
				
				if target.Character.Humanoid.Health <= 0 then
					task.wait(1)
					self:wanderBehavior()
					return
				end
				
				task.wait(self.config.DamageDelay)
			end
		end
	end
end

function PatientEnemy:handleDamaged(health: number)
	if health < self.lastHealth then
		if self.soundSets.hurt and #self.soundSets.hurt:GetChildren() > 0 then
			local hurtSoundsChildren = self.soundSets.hurt:GetChildren()
			local randomSnd = hurtSoundsChildren[math.random(1, #hurtSoundsChildren)]

			if #hurtSoundsChildren > 1 and randomSnd == self.lastHurtSnd then
				repeat
					task.wait()
					randomSnd = hurtSoundsChildren[math.random(1, #hurtSoundsChildren)]
				until randomSnd ~= self.lastHurtSnd
			end
			self.lastHurtSnd = randomSnd

			if randomSnd and randomSnd:IsA("Sound") then
				local randomHurtSound = randomSnd:Clone()
				randomHurtSound.Parent = self.npc.HumanoidRootPart
				randomHurtSound:Play()
				game.Debris:AddItem(randomHurtSound, 10)
			end
		end

		self.lastHealth = health
		self.damageFlag = true
		self.persistenceCounter = 0
		self.chaseDebounce = false
		self.hum.WalkSpeed = self.config.ChasingSpeed

		task.delay(2, function()
			self.damageFlag = false
		end)
	end
end

function PatientEnemy:handleDeath()
	if self.isDeceased then return end
	self.isDeceased = true

	if self.soundSets.death and #self.soundSets.death:GetChildren() > 0 then
		local deathSoundsChildren = self.soundSets.death:GetChildren()
		local randomDeathSound = deathSoundsChildren[math.random(1, #deathSoundsChildren)]:Clone()
		if randomDeathSound and self.npc:FindFirstChild("sndPart") then 
            randomDeathSound.Parent = self.npc:FindFirstChild("sndPart") 
        elseif randomDeathSound then
            randomDeathSound.Parent = self.npc.HumanoidRootPart
        end
		if randomDeathSound then randomDeathSound:Play() end
		game.Debris:AddItem(randomDeathSound, 10)
	end

	if self.npc:FindFirstChild("Animator") and self.npc.Animator:IsA("Animator") then
		self.npc.Animator.Enabled = false
	end

	for _, track in self.hum.Animator:GetPlayingAnimationTracks() do
		track:Stop()
	end

	self.hum.WalkSpeed = 0
	if self.state then self.state.Value = "dead" end
end

function PatientEnemy:mainLoop()
	while true do
		task.wait(self.config.TickRate or 0.1) -- Use configurable tick rate or default
		if self.isDeceased then break end
		if not self.npc or not self.npc.Parent or not self.npc:FindFirstChild("HumanoidRootPart") then 
			self:destroy() -- NPC is no longer valid or fully loaded
			break 
		end

		local target = self:findTarget()

		if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and target.Character:FindFirstChildOfClass("Humanoid") then
			local targetHum = target.Character:FindFirstChildOfClass("Humanoid")
			local targetRoot = target.Character:FindFirstChild("HumanoidRootPart") :: BasePart -- Type assertion for safety

			if targetHum and targetHum.Health > 0 and targetRoot then
				local distanceToTarget = (self.npc.HumanoidRootPart.Position - targetRoot.Position).Magnitude
				local attackDistance = self.config.AttackDistance or 4

				if distanceToTarget <= attackDistance then
					if self.state then self.state.Value = "attacking" end
					self:attackTarget(target)
					task.wait(self.config.AttackCooldown or 1) 
				elif not self.chaseDebounce then
					self:followPlayer(target)
				else -- In chase debounce, briefly pause or idle
					if self.state then self.state.Value = "idle" end -- Or chasing
					task.wait(0.1)
				end
			else -- Target is dead or invalid
				self:wanderBehavior()
			end
		else
			self:wanderBehavior()
		end
	end
end

function PatientEnemy:playAudio(sound: Sound, parent: Instance?)
	if not sound:IsA("Sound") then return end
	local snd = sound:Clone()
	if parent then
		snd.Parent = parent
	elseif self.npc then
		snd.Parent = self.npc.HumanoidRootPart
	end
	if snd.Parent then
		snd:Play()
		game.Debris:AddItem(snd, 5)
	end
end

function PatientEnemy:manageAnimState()
	while true do
		task.wait(0.1) -- Added a small wait to prevent tight loop
		if self.isDeceased then
			if self.state then self.state.Value = "dead" end
			if self.twSvc and self.soundSets.footStep then
				self.twSvc:Create(self.soundSets.footStep, TweenInfo.new(0.01), {Volume = 0}):Play()
			end
			break
		end

		if not self.npc or not self.npc.HumanoidRootPart or not self.soundSets.footStep then 
			continue 
		end

		local speed = self.npc.HumanoidRootPart.AssemblyLinearVelocity.Magnitude

		if speed > 0.1 then
			if self.soundSets.footStep.Volume ~= 0.3 then
				self.soundSets.footStep.Volume = 0.3
			end
			if not self.soundSets.footStep.IsPlaying then
				self.soundSets.footStep.Looped = true
				self.soundSets.footStep:Play()
			end
			if self.state and self.state.Value == "wandering" then
				self.soundSets.footStep.PlaybackSpeed = 1.05
			elseif self.state and self.state.Value == "chasing" then
				self.soundSets.footStep.PlaybackSpeed = 1.1
			end
		else
			if self.twSvc and self.soundSets.footStep then
				self.twSvc:Create(self.soundSets.footStep, TweenInfo.new(0.01), {Volume = 0}):Play()
			end
		end
	end
end

function PatientEnemy:manageSoundEffects()
	while true do
		if not self.config or not self.config.NoisesDelay then 
			task.wait(5) -- Default wait if config is missing
			continue -- Changed from return
		else
			task.wait(math.random(self.config.NoisesDelay, self.config.NoisesDelay + 3))
		end

		if self.isDeceased then break end

		if not self.soundSets.random or #self.soundSets.random:GetChildren() == 0 then 
			continue 
		end
		
		local randomSoundsChildren = self.soundSets.random:GetChildren()
		local randomSound = randomSoundsChildren[math.random(1, #randomSoundsChildren)]

		if #randomSoundsChildren > 1 and randomSound == self.lastRandSnd then
			repeat
				task.wait()
				randomSound = randomSoundsChildren[math.random(1, #randomSoundsChildren)]
			until randomSound ~= self.lastRandSnd
		end
		self.lastRandSnd = randomSound

		if not self.damageFlag and randomSound:IsA("Sound") then
			local sndPart = self.npc:FindFirstChild("sndPart")
			self:playAudio(randomSound, sndPart)
		end
	end
end

function PatientEnemy:followPlayer(targetPlayer: Player)
	if self.state then self.state.Value = "chasing" end
	if not targetPlayer or not targetPlayer.Character or not self.npc or not self.npc.HumanoidRootPart then return end

	local path = self.pathfindingSvc:CreatePath(self.config)
	local success, errorMessage = pcall(function()
		path:ComputeAsync(self.npc.HumanoidRootPart.Position, targetPlayer.Character.HumanoidRootPart.Position)
	end)

	if not success then
		warn("Path computation failed for followPlayer: " .. tostring(errorMessage))
		task.wait(1)
		return
	end

	if path.Status == Enum.PathStatus.Success then
		local waypoints = path:GetWaypoints()
		local pathBlockedConn: RBXScriptConnection?
		local moveFinishedStatus = true

		pathBlockedConn = path.Blocked:Connect(function(blockedWaypointIndex)
			if pathBlockedConn then pathBlockedConn:Disconnect() pathBlockedConn = nil end
			moveFinishedStatus = false -- Consider path blocked as a failed move for the current segment
			-- No recursive call here to prevent stack overflow; mainLoop will re-evaluate
		end)

		for _, waypoint in ipairs(waypoints) do
			if self.isDeceased or not targetPlayer.Parent or not targetPlayer.Character then break end
			if not moveFinishedStatus then break end -- Stop if path was marked as blocked

			if waypoint.Action == Enum.PathWaypointAction.Jump then
				self.hum.Jump = true
			end
			self.hum:MoveTo(waypoint.Position)
			
			local currentMoveFinishedConn = self.hum.MoveToFinished:Connect(function(reached)
				moveFinishedStatus = reached
			end)
			
			while moveFinishedStatus == true and currentMoveFinishedConn.Connected do
				if self.isDeceased or not targetPlayer.Parent or not targetPlayer.Character then 
					if currentMoveFinishedConn.Connected then currentMoveFinishedConn:Disconnect() end
					break 
				end
				task.wait(0.05)
			end
			if currentMoveFinishedConn.Connected then currentMoveFinishedConn:Disconnect() end

			if not moveFinishedStatus then break end
		end

		if pathBlockedConn and pathBlockedConn.Connected then pathBlockedConn:Disconnect() end
	else
		-- Path computation failed (e.g. NoPath, Fail)
		task.wait(math.random(50,100)/100) -- Wait 0.5 to 1 second before mainLoop re-evaluates
	end

	if not self.chaseDebounce then
		self.chaseDebounce = true
		task.wait(self.config.ChasePathRecalculateDelay or 0.2)
		self.chaseDebounce = false
	end
end

function PatientEnemy:wanderBehavior()
	if self.state then self.state.Value = "wandering" end
	if not self.npc or not self.npc.HumanoidRootPart then return end

	local path = self.pathfindingSvc:CreatePath(self.config)
	local randomX = math.random(self.config.WanderMinDistance or -50, self.config.WanderMaxDistance or 50)
	local randomZ = math.random(self.config.WanderMinDistance or -50, self.config.WanderMaxDistance or 50)
	local goalPos = self.npc.HumanoidRootPart.Position + Vector3.new(randomX, 0, randomZ)
	
	local success, errorMessage = pcall(function()
		path:ComputeAsync(self.npc.HumanoidRootPart.Position, goalPos)
	end)

	if not success then
		warn("Path computation failed for wanderBehavior: " .. tostring(errorMessage))
		task.wait(1)
		return
	end

	if path.Status == Enum.PathStatus.Success then
		local waypoints = path:GetWaypoints()
		if #waypoints > 0 then
			local targetPoint = waypoints[#waypoints].Position -- Go to the last point of the path
			local pathBlockedConn: RBXScriptConnection?
			local moveFinishedStatus = true

			pathBlockedConn = path.Blocked:Connect(function(blockedWaypointIndex)
				if pathBlockedConn then pathBlockedConn:Disconnect() pathBlockedConn = nil end
				moveFinishedStatus = false
			end)

			self.hum:MoveTo(targetPoint)

			local currentMoveFinishedConn = self.hum.MoveToFinished:Connect(function(reached)
				moveFinishedStatus = reached
			end)

			while moveFinishedStatus == true and currentMoveFinishedConn.Connected do
				if self.isDeceased then 
					if currentMoveFinishedConn.Connected then currentMoveFinishedConn:Disconnect() end
					break 
				end
				task.wait(0.05)
			end
			if currentMoveFinishedConn.Connected then currentMoveFinishedConn:Disconnect() end

			if pathBlockedConn and pathBlockedConn.Connected then pathBlockedConn:Disconnect() end

			if moveFinishedStatus then
				task.wait(math.random((self.config.WaitAtDestinationMin or 1) * 100, (self.config.WaitAtDestinationMax or 3) * 100) / 100)
			else
				task.wait(0.5) -- Short wait if move failed/blocked
			end
		else
			task.wait(self.config.WanderRecalculateDelayShort or 1) -- No waypoints found
		end
	else
		task.wait(self.config.WanderRecalculateDelayFail or 1) -- Path computation failed
	end
end

function PatientEnemy:findTarget()
	local closestPlayer: Player? = nil
	local visionDistance = self.config.VisionDistance or 50 -- Default if not in config
	local losCheck = self.config.LOSTarget or true -- Default if not in config
	local minDistance = visionDistance
	local humRootPart = self.npc:FindFirstChild("HumanoidRootPart")
	if not humRootPart then return nil end

	for _, player in ipairs(self.playersSvc:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid") then
			local targetHum = player.Character:FindFirstChildOfClass("Humanoid")
			if targetHum and targetHum.Health > 0 then
				local distance = (humRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
				if distance < minDistance then
					if losCheck then
						local rayOrigin = humRootPart.Position
						local rayDirection = (player.Character.HumanoidRootPart.Position - rayOrigin).Unit * visionDistance
						local raycastParams = RaycastParams.new()
						raycastParams.FilterDescendantsInstances = {self.npc, player.Character}
						raycastParams.FilterType = Enum.RaycastFilterType.Exclude
						local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

						if not raycastResult then -- No obstructions
							closestPlayer = player
							minDistance = distance
						end
					else
						closestPlayer = player
						minDistance = distance
					end
				end
			end
		end
	end
	return closestPlayer
end

function PatientEnemy:attackTarget(targetPlayer: Player)
	-- Basic attack logic: Play sound, maybe an animation trigger later
	if self.isDeceased or not targetPlayer or not targetPlayer.Character then return end
	
	-- Make NPC face the target
	local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
	if targetRoot and self.npc.HumanoidRootPart then
		local lookVector = Vector3.new(targetRoot.Position.X, self.npc.HumanoidRootPart.Position.Y, targetRoot.Position.Z)
		self.npc.HumanoidRootPart.CFrame = CFrame.lookAt(self.npc.HumanoidRootPart.Position, lookVector)
	end

	if self.soundSets.attack then
		local attackSounds = self.soundSets.attack:GetChildren()
		if #attackSounds > 0 then
			local randomAttackSound = attackSounds[math.random(1, #attackSounds)]
			if randomAttackSound:IsA("Sound") then self:playAudio(randomAttackSound) end
		end
	end
	-- Placeholder for actual damage dealing or animation calls
	-- Example: targetPlayer.Character.Humanoid:TakeDamage(self.config.AttackDamage or 10)
	print(self.npc.Name .. " is attacking " .. targetPlayer.Name)
end

return PatientEnemy
