--//Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
	Remotes = Instance.new("Folder")
	Remotes.Name = "Remotes"
	Remotes.Parent = ReplicatedStorage
end

local HintEffectEvent = Remotes:FindFirstChild("InitialEntityHintEffect")
if not HintEffectEvent or not HintEffectEvent:IsA("RemoteEvent") then
	HintEffectEvent = Instance.new("RemoteEvent")
	HintEffectEvent.Name = "InitialEntityHintEffect"
	HintEffectEvent.Parent = Remotes
end

--//Map
local Map = workspace:WaitForChild("Map")
local InteractParts = Map:WaitForChild("InteractParts")
local HintParts = InteractParts:WaitForChild("HintParts")
local InitialEntityHint = HintParts:WaitForChild("InitialEntityHint")

--//Monster
local MonstersFolder = ReplicatedStorage:WaitForChild("Monsters")
local EnemiesFolder = MonstersFolder:FindFirstChild("Enemies")
local CrazyPatientFolder = EnemiesFolder and EnemiesFolder:FindFirstChild("Crazy_Patient")
local PatientEnemyTemplate = CrazyPatientFolder and CrazyPatientFolder:FindFirstChild("Patient_Enemy_Var1")

if not PatientEnemyTemplate or not PatientEnemyTemplate:IsA("Model") then
	PatientEnemyTemplate = MonstersFolder:FindFirstChild("Patient_Enemy")
end

--//Config
local SPAWN_HEIGHT = 7
local MOVE_SPEED = 24
local MAX_FALL_WAIT_SECONDS = 2
local MOVE_TIMEOUT_SECONDS = 9
local DESPAWN_DELAY_SECONDS = 0.3

--//Values
local triggered = false

local function getOrCreateMapMonstersFolder()
	local folder = Map:FindFirstChild("Monsters")
	if folder then
		return folder
	end

	folder = Instance.new("Folder")
	folder.Name = "Monsters"
	folder.Parent = Map
	return folder
end

local function getScenePoints()
	local entityPoints = Map:FindFirstChild("InicialEntity") or Map:FindFirstChild("InitialEntity")
	if not entityPoints then
		warn("[InitialEntityHint] Workspace.Map.InicialEntity was not found.")
		return nil, nil
	end

	local pointA = entityPoints:FindFirstChild("1")
	local pointB = entityPoints:FindFirstChild("2")

	if not pointA or not pointA:IsA("BasePart") then
		warn("[InitialEntityHint] Workspace.Map.InicialEntity.1 was not found or is not a BasePart.")
		return nil, nil
	end

	if not pointB or not pointB:IsA("BasePart") then
		warn("[InitialEntityHint] Workspace.Map.InicialEntity.2 was not found or is not a BasePart.")
		return nil, nil
	end

	return pointA, pointB
end

local function getLookCFrame(position: Vector3, lookAt: Vector3)
	local target = Vector3.new(lookAt.X, position.Y, lookAt.Z)
	if (target - position).Magnitude <= 0.01 then
		return CFrame.new(position)
	end

	return CFrame.lookAt(position, target)
end

local function pivotEnemyRootTo(enemy: Model, rootPart: BasePart, rootCFrame: CFrame)
	local offset = rootCFrame * rootPart.CFrame:Inverse()
	enemy:PivotTo(offset * enemy:GetPivot())
end

local function prepareEnemy(enemy: Model)
	for _, descendant in ipairs(enemy:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
		elseif descendant:IsA("Script") then
			descendant.Enabled = descendant.Name == "Animator"
		elseif descendant:IsA("LocalScript") then
			descendant.Enabled = false
		end
	end

	local humanoid = enemy:FindFirstChildWhichIsA("Humanoid")
	local rootPart = enemy:FindFirstChild("HumanoidRootPart")

	if not humanoid or not rootPart or not rootPart:IsA("BasePart") then
		warn("[InitialEntityHint] Patient_Enemy template is missing Humanoid or HumanoidRootPart.")
		return nil, nil, nil
	end

	local state = enemy:FindFirstChild("state")
	if not state or not state:IsA("StringValue") then
		state = Instance.new("StringValue")
		state.Name = "state"
		state.Parent = enemy
	end

	enemy.PrimaryPart = rootPart
	state.Value = "chasing"
	humanoid.WalkSpeed = MOVE_SPEED
	humanoid.AutoRotate = true

	return humanoid, rootPart, state
end

local function moveToPoint(enemy: Model, humanoid: Humanoid, pointB: BasePart)
	local finished = false
	local reached = false
	local connection = humanoid.MoveToFinished:Connect(function(didReach)
		finished = true
		reached = didReach
	end)

	humanoid:MoveTo(pointB.Position)

	local startedAt = os.clock()
	repeat
		task.wait(0.1)
	until finished or not enemy.Parent or os.clock() - startedAt >= MOVE_TIMEOUT_SECONDS

	connection:Disconnect()
	return reached
end

local function waitUntilLanded(humanoid: Humanoid)
	local startedAt = os.clock()

	repeat
		task.wait(0.1)
	until humanoid.FloorMaterial ~= Enum.Material.Air or os.clock() - startedAt >= MAX_FALL_WAIT_SECONDS
end

local function spawnAndMoveEnemy()
	if not PatientEnemyTemplate or not PatientEnemyTemplate:IsA("Model") then
		warn("[InitialEntityHint] Patient_Enemy template was not found.")
		return
	end

	local pointA, pointB = getScenePoints()
	if not pointA or not pointB then
		return
	end

	local enemy = PatientEnemyTemplate:Clone()
	enemy.Name = "InitialEntityPatient"

	local humanoid, rootPart, state = prepareEnemy(enemy)
	if not humanoid or not rootPart or not state then
		enemy:Destroy()
		return
	end

	enemy.Parent = getOrCreateMapMonstersFolder()

	local spawnPosition = pointA.Position + Vector3.new(0, pointA.Size.Y / 2 + SPAWN_HEIGHT, 0)
	pivotEnemyRootTo(enemy, rootPart, getLookCFrame(spawnPosition, pointB.Position))

	pcall(function()
		rootPart:SetNetworkOwner(nil)
	end)

	waitUntilLanded(humanoid)
	state.Value = "chasing"
	humanoid.WalkSpeed = MOVE_SPEED
	humanoid:ChangeState(Enum.HumanoidStateType.Running)

	moveToPoint(enemy, humanoid, pointB)

	state.Value = "idle"
	humanoid.WalkSpeed = 0

	task.wait(DESPAWN_DELAY_SECONDS)
	if enemy.Parent then
		enemy:Destroy()
	end
end

InitialEntityHint.Touched:Connect(function(hit)
	if triggered then
		return
	end

	local character = hit.Parent
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	local player = character and Players:GetPlayerFromCharacter(character)

	if not humanoid or humanoid.Health <= 0 or not player then
		return
	end

	triggered = true
	HintEffectEvent:FireAllClients()
	task.spawn(spawnAndMoveEnemy)
end)
