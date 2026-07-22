--//Services
local Rs = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local HandrailRaycast = require(Rs:WaitForChild("Modules"):WaitForChild("HandrailRaycast"))

--//Monster
local NPC = script.Parent
local Hum = NPC:FindFirstChild("Humanoid")
local trigger = NPC:FindFirstChild("Trigger")
local MonsterWaypoints = workspace.Map.Monsters.FlayedChase1_Nodes
local MonsterChaseZones = workspace.Map.Area2_AsylumReception.InteractStuff.MonsterChaseZones
NPC.PrimaryPart:SetNetworkOwner(nil)

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local JumpscareEvent = Remotes:WaitForChild("Jumpscare")

--//Modules
local ModulesFolder = Rs:WaitForChild("Modules")
local BadgesModule = require(ModulesFolder:FindFirstChild("Badges"))

--//Sounds
local RandomSounds = script:FindFirstChild("RandomSounds")
local SoundsFolder = script:FindFirstChild("Sounds")
local HitSounds = script:FindFirstChild("HitSounds")
local AttackSound = SoundsFolder:FindFirstChild("AttackSound")
local FootStepSound = SoundsFolder:FindFirstChild("FootStepSound")
local JumpscareSound = SoundsFolder:FindFirstChild("JumpscareSound")
local IntenseSound = SoundsFolder:FindFirstChild("IntenseSound")

--//Anims
local PushAnim = script.Parent.Animator.Animations:FindFirstChild("Attack")
local animPush = Hum.Animator:LoadAnimation(PushAnim)

--//Module
local config = require(script:FindFirstChild("Config"))

--//Values
local chasing = true -- when the monster is chasing a player
local searching = false -- true if the monster can't see the player, then start searching
local LastLocation = nil -- Last random waypoint choosen
local chasingPlr = nil -- current player being chased
local stuckTimes = 0
local maxStuck = 20
local Tries = 0 -- Current Tries to find a lost player (can change maxTries on Config module)
local firstTime = true -- When the monster lost the player for the first time, this value reset
local OnChaseDebounce = false -- current useless (on use only in line 188)
local currentAttempt = 0
local maxAttempts = 50
local state = NPC:FindFirstChild("state") -- For monster animations

--//Setup
Hum.WalkSpeed = config.NormalSpeed
FootStepSound.Parent = NPC.HumanoidRootPart
game:GetService("ContentProvider"):PreloadAsync(NPC.Animator.Animations:GetChildren())

local function playSound(sound: Sound, parent: Instance?)
	if not sound:IsA("Sound") then return end
	local snd = sound:Clone()
	if parent then
		snd.Parent = parent
	else
		snd.Parent = NPC.HumanoidRootPart
	end
	snd:Play()
	game.Debris:AddItem(snd, snd.TimeLength + 2)
end

local function getPath(destination)
	local path = PathfindingService:CreatePath(config.agentParams)
	
	path:ComputeAsync(NPC.HumanoidRootPart.Position, destination.Position)
	return path
end

local function Jumpscare(target: Player)
	if target:FindFirstChild("PlayerValues") then
		if target:FindFirstChild("PlayerValues"):FindFirstChild("OnSafe") then
			if target:FindFirstChild("PlayerValues"):FindFirstChild("OnSafe").Value then
				return false
			end
		end
	end
	
	local CamPart = NPC:FindFirstChild("Cam")
	local JumpscareAnim = NPC:FindFirstChild("Animator"):FindFirstChild("Animations"):FindFirstChild("Jumpscare")
	
	JumpscareEvent:FireClient(target, NPC, JumpscareSound, CamPart, JumpscareAnim, IntenseSound)
	task.delay(1.7, function()
		target.Character.Humanoid.Health = 0
	end)
	
	local badge = BadgesModule:FindBadge("Bob-a-Scare")
	BadgesModule:GiveBadge(target, badge.Id)
	
	return true
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

local function detectClosePlrs()
	for i, plr in pairs(game.Players:GetPlayers()) do
		if plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 and plr.Character:FindFirstChild("HumanoidRootPart") then
			local distance = (NPC.HumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude
			if distance <= config.AttackDistance then
				if canSeeTarget(plr.Character) then
					Jumpscare(plr)
				end
			end
		end
	end
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

local function moveTo(pos)
	local path = getPath(pos)
	if path and path.Status == Enum.PathStatus.Success then
		print("path success, moving to waypoint..")
		for i, waypoint in pairs(path:GetWaypoints()) do
			Hum:MoveTo(waypoint.Position)
			Hum.MoveToFinished:Wait()
		end
		return true
	end
	return false
end

--//Push objects with "Destroyable" tag.
trigger.Touched:Connect(function(hit)
	if not hit or not hit.Parent then return end
	
	if hit.Parent:IsA("Model") and hit.Parent:HasTag("Destroyable") then
		hit.Parent:RemoveTag("Destroyable")
		
		local mainPart = hit.Parent.PrimaryPart
		
		if mainPart then
			local randomHitSound = HitSounds:GetChildren()[math.random(1, #HitSounds:GetChildren())]
			playSound(randomHitSound, mainPart)
			
			if not animPush.IsPlaying and state.Value ~= "Push" then
				state.Value = "Push"
				
				for _, v in Hum.Animator:GetPlayingAnimationTracks() do
					v:Stop()
				end
				
				animPush:Play()
				
				Hum.WalkSpeed = 2
				task.delay(0.12, function() state.Value = "chasing" Hum.WalkSpeed = config.ChasingSpeed end)
			end
			
			mainPart.Anchored = false
			mainPart:ApplyImpulse(trigger.CFrame.LookVector * 1800 + Vector3.new(0, 200, 0))
		end
	elseif hit.Parent:IsA("Model") and hit.Parent:HasTag("ActionZone") then
		hit.Parent:RemoveTag("ActionZone")
		for _, v in hit.Parent:GetChildren() do
			if v:IsA("BasePart") then
				v:Destroy()
			end
		end
	end
end)

--//Manage the monster states for they animation
coroutine.wrap(function()
	while task.wait() do
		if chasing then
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
		
		playSound(randomSound, NPC.HumanoidRootPart)
	end
end)()

--//Setup
local currentSpot = 0
Hum.WalkSpeed = config.ChasingSpeed
state.Value = "chasing"

RunService.Heartbeat:Connect(function(dt: number)
	detectClosePlrs()
end)

for _, killZone in MonsterChaseZones:GetChildren() do
	if killZone:IsA("BasePart") then
		killZone.CanTouch = false
		killZone.Touched:Connect(function(hit: BasePart)
			if not hit or not hit.Parent then return end
			if hit.Parent:FindFirstChild("Humanoid") then
				if hit.Parent:FindFirstChild("Humanoid").Health > 0 then
					local plr = game.Players:GetPlayerFromCharacter(hit.Parent)
					if plr then
						if plr.Character == hit.Parent then
							if plr.Character:FindFirstChild("Humanoid") then
								plr.Character.Humanoid.Health = 0
							end
						end
					end
				end
			end
		end)
	end
end

task.wait(1) -- delay before start chasing

local completedSpots = 0

while completedSpots < #MonsterWaypoints:GetChildren() do
	for _, spot in pairs(MonsterWaypoints:GetChildren()) do
		print("moving to spot:", spot)
		if spot:IsA("BasePart") and spot.Name == tostring(currentSpot) then
			local pathMonster = moveTo(spot)
			
			if not pathMonster then
				print("no path, moving directly.")
				Hum:MoveTo(spot.Position, spot)
				Hum.MoveToFinished:Wait()
			end
			
			local previousZone = MonsterChaseZones:FindFirstChild(tostring(currentSpot - 1))
			if previousZone then
				task.delay(8, function()
					previousZone.CanTouch = true
				end)
			end
			
			currentSpot += 1
			completedSpots = currentSpot
		end
	end
end
