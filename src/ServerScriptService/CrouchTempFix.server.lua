------------------//SERVICES
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService: PhysicsService = game:GetService("PhysicsService")

------------------//CONSTANTS
local GROUP_STAND: string = "PlayersStand"
local GROUP_CROUCH: string = "PlayersCrouch"
local GROUP_WORLD: string = "World"
local GROUP_WALL: string = "Wall"

------------------//VARIABLES
local Remotes: Folder = ReplicatedStorage:WaitForChild("Remotes")
local PlayerValues: RemoteEvent = Remotes:WaitForChild("PlayerValues") :: RemoteEvent

------------------//FUNCTIONS
local function safe_create_group(name: string): ()
	pcall(function()
		PhysicsService:RegisterCollisionGroup(name)
	end)
end

local function ensure_collision_groups(): ()
	safe_create_group(GROUP_STAND)
	safe_create_group(GROUP_CROUCH)
	safe_create_group(GROUP_WORLD)
	safe_create_group(GROUP_WALL)

	PhysicsService:CollisionGroupSetCollidable(GROUP_STAND, GROUP_WORLD, true)
	PhysicsService:CollisionGroupSetCollidable(GROUP_STAND, GROUP_WALL, true)

	PhysicsService:CollisionGroupSetCollidable(GROUP_CROUCH, GROUP_WALL, true)
	PhysicsService:CollisionGroupSetCollidable(GROUP_CROUCH, GROUP_WORLD, false)
end

local function is_inside_wall_folder(inst: Instance): boolean
	local cur: Instance? = inst
	while cur do
		if cur:IsA("Folder") and cur.Name == "Wall" then
			return true
		end
		cur = cur.Parent
	end
	return false
end

local function set_model_collision_group(model: Model, groupName: string): ()
	for _, inst in model:GetDescendants() do
		if inst:IsA("BasePart") then
			inst.ColisionGroup = groupName
		end
	end
end

local function apply_world_groups(root: Instance): ()
	for _, inst in root:GetDescendants() do
		if inst:IsA("BasePart") then
			if is_inside_wall_folder(inst) then
				inst.ColisionGroup = GROUP_WALL
			else
				inst.ColisionGroup = GROUP_WORLD
			end
		end
	end

	root.DescendantAdded:Connect(function(inst: Instance)
		if inst:IsA("BasePart") then
			if is_inside_wall_folder(inst) then
				inst.ColisionGroup = GROUP_WALL
			else
				inst.ColisionGroup = GROUP_WORLD
			end
		end
	end)
end

local function on_character_added(character: Model): ()
	set_model_collision_group(character, GROUP_STAND)
end

local function on_player_added(player: Player): ()
	player.CharacterAdded:Connect(on_character_added)
	if player.Character then
		on_character_added(player.Character)
	end
end

------------------//INIT
ensure_collision_groups()
apply_world_groups(workspace)

for _, player in Players:GetPlayers() do
	on_player_added(player)
end
Players.PlayerAdded:Connect(on_player_added)

PlayerValues.OnServerEvent:Connect(function(player: Player, action: string)
	local character = player.Character
	if not character then
		return
	end

	if action == "CrouchingON" then
		set_model_collision_group(character, GROUP_CROUCH)
	elseif action == "CrouchingOFF" then
		set_model_collision_group(character, GROUP_STAND)
	end
end)
