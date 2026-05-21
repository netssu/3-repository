-- SERVICES
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

--OTHERMODULES
local PathfinderModule = require(RS:WaitForChild("Modules").NoobPath)

local NPCHandler = {}

NPCHandler.ActiveRestaurants = {}

-- [[ THE FIX: A Helper function to find any NPC safely ]]
local function GetNpcData(NpcModel, Plr)
	-- Safety check: Ensure the player actually exists
	if not Plr or not Plr.Parent then return nil end

	local RestData = NPCHandler.ActiveRestaurants[Plr.UserId]
	if not RestData then return nil end

	return (RestData.Customers and RestData.Customers[NpcModel]) 
		or (RestData.Waiters and RestData.Waiters[NpcModel]) 
		or (RestData.Hosts and RestData.Hosts[NpcModel])
		or (RestData.Chefs and RestData.Chefs[NpcModel])
end

local function onPathReached(NpcModel,Plr)
	local NpcData = GetNpcData(NpcModel, Plr)
	if not NpcData then return end 
end

local function onWaypointReached(NpcModel,Plr)
	local NpcData = GetNpcData(NpcModel, Plr)
	if not NpcData then return end 
end

-- This function is called when the pathfinder runs into an error
local function onPathError(NpcModel, errorType,Plr)
	local NpcData = GetNpcData(NpcModel, Plr)
	if not NpcData or not NpcData.CurrentDestination then return end

	if NpcData.Humanoid:GetState() ~= Enum.HumanoidStateType.Climbing then
		if type(NpcData.Path.Jump) == "function" then
			--NpcData.Path.Jump()
		end
	end

	-- [[ FIX: Safe Network Ownership Check ]]
	if NpcModel.PrimaryPart and not NpcModel.PrimaryPart.Anchored then
		pcall(function() NpcModel.PrimaryPart:SetNetworkOwner(nil) end)
	end

	-- Try to run to the saved destination again
	NpcData.Path:Run(NpcData.CurrentDestination)
end

-- This function is called when the NPC gets stuck
local function onPathTrapped(NpcModel,Plr)
	local NpcData = GetNpcData(NpcModel, Plr)
	if not NpcData or not NpcData.CurrentDestination then return end

	if NpcData.Humanoid:GetState() ~= Enum.HumanoidStateType.Climbing then
		if type(NpcData.Path.Jump) == "function" then
			--NpcData.Path.Jump()
		end
	end

	-- [[ FIX: Safe Network Ownership Check ]]
	if NpcModel.PrimaryPart and not NpcModel.PrimaryPart.Anchored then
		pcall(function() NpcModel.PrimaryPart:SetNetworkOwner(nil) end)
	end

	-- Re-run the path to the saved destination to try to get unstuck
	NpcData.Path:Run(NpcData.CurrentDestination)
end

-- ========================================================
-- CUSTOMERS
-- ========================================================
function NPCHandler.SetupNPC(NpcModel,Plot,StartPoint,Plr,GroupId,IsLeader,GroupOffset)
	if not NPCHandler.ActiveRestaurants[Plr.UserId] then
		NPCHandler.ActiveRestaurants[Plr.UserId] = {}
	end
	if not NPCHandler.ActiveRestaurants[Plr.UserId].Customers then
		NPCHandler.ActiveRestaurants[Plr.UserId].Customers = {}
		NPCHandler.ActiveRestaurants[Plr.UserId].CustomerSpawnTimer = 0
	end

	if NPCHandler.ActiveRestaurants[Plr.UserId].Customers[NpcModel] then return end 

	local Humanoid = NpcModel:FindFirstChildWhichIsA("Humanoid")
	local Hrp = NpcModel:FindFirstChildWhichIsA("HumanoidRootPart")
	if not Humanoid then return end

	task.delay(1.5,function()
		for i,v in pairs(NpcModel:GetDescendants()) do
			if v:IsA("BasePart") or v:IsA("MeshPart") then
				v.CollisionGroup = "Customers"
				v.CanTouch = false
			end
		end	
	end)

	-- Create the pathfinding object for this specific NPC
	local path = PathfinderModule.Humanoid(NpcModel, {
		AgentRadius = Humanoid.HipHeight / 2,
		AgentHeight = Humanoid.HipHeight,
		WaypointSpacing = 3,
		AgentCanJump = false,
		Costs = {Water = 30},
	})
	path.Visualize = false
	path.Speed = Humanoid.WalkSpeed

	-- Store all the important NpcData for this NPC in our tracking table
	NPCHandler.ActiveRestaurants[Plr.UserId].Customers[NpcModel] = {
		Path = path,
		Humanoid = Humanoid,
		HRP = Hrp,
		State = "WalkingToHost", -- NEW STARTING STATE
		Plr = Plr,
		TargetPlot = Plot,
		CurrentNode = StartPoint,
		WaitTimer = 0,
		Connections = {}, 
		Animations = {},
		CurrentDestination = nil,
		GroupOffset = GroupOffset, -- Save the offset here!
		GroupId = GroupId,
		IsLeader = IsLeader,
		TargetSeat = nil
	}
	for i,Anim in pairs(RS:WaitForChild("Assets").Animations.Customers:GetChildren()) do
		if Anim:IsA("Animation") then
			table.insert(NPCHandler.ActiveRestaurants[Plr.UserId].Customers[NpcModel].Animations,Humanoid.Animator:LoadAnimation(Anim))
		end
	end

	-- [[ FIX: Corrected path.Reached and path.WaypointReached for Customers ]]
	table.insert(NPCHandler.ActiveRestaurants[Plr.UserId].Customers[NpcModel].Connections, 
		path.Reached:Connect(function() 
			local npcData = NPCHandler.ActiveRestaurants[Plr.UserId] and NPCHandler.ActiveRestaurants[Plr.UserId].Customers and NPCHandler.ActiveRestaurants[Plr.UserId].Customers[NpcModel]
			if not npcData or npcData.TargetPlot == nil or npcData.TargetPlot.Parent == nil then
				return
			end
			onPathReached(NpcModel,Plr) 
		end)
	)

	table.insert(NPCHandler.ActiveRestaurants[Plr.UserId].Customers[NpcModel].Connections, 
		path.WaypointReached:Connect(function() 
			local npcData = NPCHandler.ActiveRestaurants[Plr.UserId] and NPCHandler.ActiveRestaurants[Plr.UserId].Customers and NPCHandler.ActiveRestaurants[Plr.UserId].Customers[NpcModel]
			if not npcData or npcData.TargetPlot == nil or npcData.TargetPlot.Parent == nil then
				return
			end
			onWaypointReached(NpcModel,Plr) 
		end)
	)

	table.insert(NPCHandler.ActiveRestaurants[Plr.UserId].Customers[NpcModel].Connections, 
		path.Error:Connect(function(errorType)
			onPathError(NpcModel, errorType,Plr) 
		end)
	)

	table.insert(NPCHandler.ActiveRestaurants[Plr.UserId].Customers[NpcModel].Connections, 
		path.Trapped:Connect(function() 
			onPathTrapped(NpcModel,Plr) 
		end)
	)

	table.insert(NPCHandler.ActiveRestaurants[Plr.UserId].Customers[NpcModel].Connections, 
		NpcModel.Destroying:Connect(function()
			NPCHandler.CleanupNPC(NpcModel,Plr) 
		end)
	)
end

-- ========================================================
-- WAITERS
-- ========================================================
function NPCHandler.SetupWaiter(WaiterModel, Plot, IdlePosition, Plr)
	if not NPCHandler.ActiveRestaurants[Plr.UserId] then
		NPCHandler.ActiveRestaurants[Plr.UserId] = {}
	end
	-- Create a separate table just for Waiters!
	if not NPCHandler.ActiveRestaurants[Plr.UserId].Waiters then
		NPCHandler.ActiveRestaurants[Plr.UserId].Waiters = {}
	end

	if NPCHandler.ActiveRestaurants[Plr.UserId].Waiters[WaiterModel] then return end 

	local Humanoid = WaiterModel:FindFirstChildWhichIsA("Humanoid")
	local Hrp = WaiterModel:FindFirstChildWhichIsA("HumanoidRootPart")
	if not Humanoid then return end

	for i,v in pairs(WaiterModel:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CollisionGroup = "Workers"
			v.CanTouch = false
		end
	end

	local path = PathfinderModule.Humanoid(WaiterModel, {
		AgentRadius = Humanoid.HipHeight / 2,
		AgentHeight = Humanoid.HipHeight,
		WaypointSpacing = 3,
		AgentCanJump = false,
		Costs = {Water = 30},
	})
	path.Visualize = false
	path.Speed = Humanoid.WalkSpeed

	NPCHandler.ActiveRestaurants[Plr.UserId].Waiters[WaiterModel] = {
		Path = path,
		Humanoid = Humanoid,
		HRP = Hrp,
		State = "Idle",
		Plr = Plr,
		TargetPlot = Plot,
		IdlePosition = IdlePosition, -- Where they stand when not working
		HeldPlates = {},
		Connections = {},
		Animations = {RHandHeldUp =Humanoid.Animator:LoadAnimation(RS.Assets.Animations["Gourmet Food"].RHandIdle),LHandHeldUp =Humanoid.Animator:LoadAnimation(RS.Assets.Animations["Gourmet Food"].LHandIdle) },
		TargetCustomer = nil,
		CurrentDestination = nil
	}

	-- [[ FIX: Corrected path.Reached and path.WaypointReached for Waiters ]]
	table.insert(NPCHandler.ActiveRestaurants[Plr.UserId].Waiters[WaiterModel].Connections, 
		path.Reached:Connect(function() 
			local npcData = NPCHandler.ActiveRestaurants[Plr.UserId] and NPCHandler.ActiveRestaurants[Plr.UserId].Waiters and NPCHandler.ActiveRestaurants[Plr.UserId].Waiters[WaiterModel]
			if not npcData or npcData.TargetPlot == nil or npcData.TargetPlot.Parent == nil then
				return
			end
			onPathReached(WaiterModel,Plr) 
		end)
	)

	table.insert(NPCHandler.ActiveRestaurants[Plr.UserId].Waiters[WaiterModel].Connections, 
		path.WaypointReached:Connect(function() 
			local npcData = NPCHandler.ActiveRestaurants[Plr.UserId] and NPCHandler.ActiveRestaurants[Plr.UserId].Waiters and NPCHandler.ActiveRestaurants[Plr.UserId].Waiters[WaiterModel]
			if not npcData or npcData.TargetPlot == nil or npcData.TargetPlot.Parent == nil then
				return
			end
			onWaypointReached(WaiterModel,Plr) 
		end)
	)

	table.insert(NPCHandler.ActiveRestaurants[Plr.UserId].Waiters[WaiterModel].Connections, 
		path.Error:Connect(function(errorType)
			onPathError(WaiterModel, errorType,Plr) 
		end)
	)

	table.insert(NPCHandler.ActiveRestaurants[Plr.UserId].Waiters[WaiterModel].Connections, 
		path.Trapped:Connect(function() 
			onPathTrapped(WaiterModel,Plr) 
		end)
	)

	table.insert(NPCHandler.ActiveRestaurants[Plr.UserId].Waiters[WaiterModel].Connections, 
		WaiterModel.Destroying:Connect(function()
			NPCHandler.CleanupNPC(WaiterModel,Plr) 
		end)
	)
end

-- ========================================================
-- HOSTS
-- ========================================================
function NPCHandler.SetupHost(HostModel, Plot, IdlePosition, Plr)
	if not NPCHandler.ActiveRestaurants[Plr.UserId] then
		NPCHandler.ActiveRestaurants[Plr.UserId] = {}
	end

	-- Create a separate table just for Hosts!
	if not NPCHandler.ActiveRestaurants[Plr.UserId].Hosts then
		NPCHandler.ActiveRestaurants[Plr.UserId].Hosts = {}
	end

	if NPCHandler.ActiveRestaurants[Plr.UserId].Hosts[HostModel] then return end 

	local Humanoid = HostModel:FindFirstChildWhichIsA("Humanoid")
	local Hrp = HostModel:FindFirstChildWhichIsA("HumanoidRootPart")
	if not Humanoid then return end

	for i,v in pairs(HostModel:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CollisionGroup = "Workers"
			v.CanTouch = false
		end
	end

	local path = PathfinderModule.Humanoid(HostModel, {
		AgentRadius = Humanoid.HipHeight / 2,
		AgentHeight = Humanoid.HipHeight,
		WaypointSpacing = 1,
		AgentCanJump = false,
		Costs = {Water = 30},
	})
	path.Visualize = false
	path.Speed = Humanoid.WalkSpeed

	NPCHandler.ActiveRestaurants[Plr.UserId].Hosts[HostModel] = {
		Path = path,
		Humanoid = Humanoid,
		HRP = Hrp,
		State = "Idle",
		Plr = Plr,
		TargetPlot = Plot,
		IdlePosition = IdlePosition, -- This will be Node 11
		Connections = {},
		WaitAtTableTimer = 3,
		TargetTable = nil,
		TargetGroupData = nil,
		CurrentDestination = nil
	}

	-- [[ FIX: Corrected path.Reached and path.WaypointReached for Hosts ]]
	table.insert(NPCHandler.ActiveRestaurants[Plr.UserId].Hosts[HostModel].Connections, 
		path.Reached:Connect(function() 
			local npcData = NPCHandler.ActiveRestaurants[Plr.UserId] and NPCHandler.ActiveRestaurants[Plr.UserId].Hosts and NPCHandler.ActiveRestaurants[Plr.UserId].Hosts[HostModel]
			if not npcData or npcData.TargetPlot == nil or npcData.TargetPlot.Parent == nil then
				return
			end
			onPathReached(HostModel,Plr) 
		end)
	)

	table.insert(NPCHandler.ActiveRestaurants[Plr.UserId].Hosts[HostModel].Connections, 
		path.WaypointReached:Connect(function() 
			local npcData = NPCHandler.ActiveRestaurants[Plr.UserId] and NPCHandler.ActiveRestaurants[Plr.UserId].Hosts and NPCHandler.ActiveRestaurants[Plr.UserId].Hosts[HostModel]
			if not npcData or npcData.TargetPlot == nil or npcData.TargetPlot.Parent == nil then
				return
			end
			onWaypointReached(HostModel,Plr) 
		end)
	)

	table.insert(NPCHandler.ActiveRestaurants[Plr.UserId].Hosts[HostModel].Connections, 
		path.Error:Connect(function(errorType)
			onPathError(HostModel, errorType,Plr) 
		end)
	)

	table.insert(NPCHandler.ActiveRestaurants[Plr.UserId].Hosts[HostModel].Connections, 
		path.Trapped:Connect(function() 
			onPathTrapped(HostModel,Plr) 
		end)
	)

	table.insert(NPCHandler.ActiveRestaurants[Plr.UserId].Hosts[HostModel].Connections, 
		HostModel.Destroying:Connect(function()
			NPCHandler.CleanupNPC(HostModel,Plr) 
		end)
	)
end

-- ========================================================
-- CHEFS
-- ========================================================
function NPCHandler.SetupChef(ChefModel, Plot, IdlePosition,CookingPosition ,Plr)
	if not NPCHandler.ActiveRestaurants[Plr.UserId] then
		NPCHandler.ActiveRestaurants[Plr.UserId] = {}
	end

	-- Create a separate table just for Chefs!
	if not NPCHandler.ActiveRestaurants[Plr.UserId].Chefs then
		NPCHandler.ActiveRestaurants[Plr.UserId].Chefs = {}
	end

	if NPCHandler.ActiveRestaurants[Plr.UserId].Chefs[ChefModel] then return end 

	local Humanoid = ChefModel:FindFirstChildWhichIsA("Humanoid")
	local Hrp = ChefModel:FindFirstChildWhichIsA("HumanoidRootPart")
	if not Humanoid then return end

	for i,v in pairs(ChefModel:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CollisionGroup = "Workers"
			v.CanTouch = false
		end
	end

	local path = PathfinderModule.Humanoid(ChefModel, {
		AgentRadius = Humanoid.HipHeight / 2,
		AgentHeight = Humanoid.HipHeight,
		WaypointSpacing = 3,
		AgentCanJump = false,
		Costs = {Water = 30},
	})
	path.Visualize = false
	path.Speed = Humanoid.WalkSpeed

	NPCHandler.ActiveRestaurants[Plr.UserId].Chefs[ChefModel] = {
		Path = path,
		Humanoid = Humanoid,
		HRP = Hrp,
		State = "Idle",
		Plr = Plr,
		TargetPlot = Plot,
		IdlePosition = IdlePosition, -- This will be Node 11
		CookingPosition = CookingPosition,
		Connections = {},
		HeldPlates = {},
		Animations = {RHandHeldUp =Humanoid.Animator:LoadAnimation(RS.Assets.Animations["Gourmet Food"].RHandIdle),LHandHeldUp =Humanoid.Animator:LoadAnimation(RS.Assets.Animations["Gourmet Food"].LHandIdle) },
		Cooking = false,
		CurrentDestination = nil
	}

	-- [[ FIX: Corrected path.Reached and path.WaypointReached for Chefs ]]
	table.insert(NPCHandler.ActiveRestaurants[Plr.UserId].Chefs[ChefModel].Connections, 
		path.Reached:Connect(function() 
			local npcData = NPCHandler.ActiveRestaurants[Plr.UserId] and NPCHandler.ActiveRestaurants[Plr.UserId].Chefs and NPCHandler.ActiveRestaurants[Plr.UserId].Chefs[ChefModel]
			if not npcData or npcData.TargetPlot == nil or npcData.TargetPlot.Parent == nil then
				return
			end
			onPathReached(ChefModel,Plr) 
		end)
	)

	table.insert(NPCHandler.ActiveRestaurants[Plr.UserId].Chefs[ChefModel].Connections, 
		path.WaypointReached:Connect(function() 
			local npcData = NPCHandler.ActiveRestaurants[Plr.UserId] and NPCHandler.ActiveRestaurants[Plr.UserId].Chefs and NPCHandler.ActiveRestaurants[Plr.UserId].Chefs[ChefModel]
			if not npcData or npcData.TargetPlot == nil or npcData.TargetPlot.Parent == nil then
				return
			end
			onWaypointReached(ChefModel,Plr) 
		end)
	)

	table.insert(NPCHandler.ActiveRestaurants[Plr.UserId].Chefs[ChefModel].Connections, 
		path.Error:Connect(function(errorType)
			onPathError(ChefModel, errorType,Plr) 
		end)
	)

	table.insert(NPCHandler.ActiveRestaurants[Plr.UserId].Chefs[ChefModel].Connections, 
		path.Trapped:Connect(function() 
			onPathTrapped(ChefModel,Plr) 
		end)
	)

	table.insert(NPCHandler.ActiveRestaurants[Plr.UserId].Chefs[ChefModel].Connections, 
		ChefModel.Destroying:Connect(function()
			NPCHandler.CleanupNPC(ChefModel,Plr) 
		end)
	)
end

-- ========================================================
-- MOVEMENT HANDLERS
-- ========================================================
function NPCHandler.Go(NpcModel, Position, Plr)
	local NpcData = GetNpcData(NpcModel, Plr)
	if not NpcData then return end 
	if not NpcModel.Humanoid or not NpcModel.PrimaryPart then return end

	-- Anti-Spam: Prevents NoobPath from stuttering if already heading to the exact spot
	if NpcData.CurrentDestination then
		local diff = (NpcData.CurrentDestination - Position).Magnitude
		if diff < 0.5 then return end 
	end

	-- [[ FIX: Safe Network Ownership Check ]]
	if NpcModel.PrimaryPart and not NpcModel.PrimaryPart.Anchored then 
		pcall(function() NpcModel.PrimaryPart:SetNetworkOwner(nil) end)
	end 

	NpcData.CurrentDestination = Position 
	NpcData.Path:Run(Position)
	NpcData.Path.Speed = NpcModel.Humanoid.WalkSpeed
end

function NPCHandler.Stop(NpcModel, Plr)
	local NpcData = GetNpcData(NpcModel, Plr)
	if not NpcData then return end 

	NpcData.CurrentDestination = nil
	NpcData.Path:Stop()
end

function NPCHandler.Intercepted(NpcModel, Position, Plr)
	local NpcData = GetNpcData(NpcModel, Plr)
	if not NpcData then return end 

	-- [[ FIX: Safe Network Ownership Check ]]
	if NpcModel.PrimaryPart and not NpcModel.PrimaryPart.Anchored then 
		pcall(function() NpcModel.PrimaryPart:SetNetworkOwner(nil) end)
	end 

	NpcData.CurrentDestination = Position 
	NpcData.Path:Stop()
	NpcData.Path:Run(Position)
	NpcData.Path.Speed = NpcModel.Humanoid.WalkSpeed
end

function NPCHandler.CleanupNPC(NpcModel, Plr)
	local NpcData = GetNpcData(NpcModel, Plr)
	if not NpcData then return end 

	print("NPCHandler is cleaning up:", NpcModel.Name)

	for _, connection in ipairs(NpcData.Connections or {}) do
		connection:Disconnect()
	end

	pcall(function()
		if NpcData.Path then NpcData.Path:Destroy() end
		if NpcModel then Debris:AddItem(NpcModel, 5) end
	end)

	-- Remove from whichever table they belonged to
	local RestData = NPCHandler.ActiveRestaurants[Plr.UserId]
	if RestData then
		if RestData.Customers and RestData.Customers[NpcModel] then RestData.Customers[NpcModel] = nil end
		if RestData.Waiters and RestData.Waiters[NpcModel] then RestData.Waiters[NpcModel] = nil end
		if RestData.Hosts and RestData.Hosts[NpcModel] then RestData.Hosts[NpcModel] = nil end
		if RestData.Chefs and RestData.Chefs[NpcModel] then RestData.Chefs[NpcModel] = nil end
	end
end

return NPCHandler