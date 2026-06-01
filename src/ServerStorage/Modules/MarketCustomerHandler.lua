-- SERVICES
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

--OTHERMODULES
local PathfinderModule = require(RS:WaitForChild("Modules").NoobPath)

local NPCHandler = {}

NPCHandler.ActiveCustomers = {}

-- [[ FIX: Safe Network Ownership Setter to stop crashing loops ]]
local function SafeSetNetworkOwner(model)
	local primary = model and model.PrimaryPart
	if primary then
		pcall(function()
			-- CanSetNetworkOwnership ensures it isn't anchored or welded to an anchored part
			if primary:CanSetNetworkOwnership() then
				primary:SetNetworkOwner(nil)
			end
		end)
	end
end

local function onPathReached(NpcModel)
	local NpcData = NPCHandler.ActiveCustomers[NpcModel]
	if not NpcData then return end 
end

local function onWaypointReached(NpcModel)
	local NpcData = NPCHandler.ActiveCustomers[NpcModel]
	if not NpcData then return end 
end

local function onPathError(NpcModel, errorType)
	local NpcData = NPCHandler.ActiveCustomers[NpcModel]
	if not NpcData or not NpcData.CurrentDestination then return end

	--print("Path Error for " .. NpcModel.Name .. ": " .. errorType)
	if NpcData.Humanoid:GetState() ~= Enum.HumanoidStateType.Climbing then
		if type(NpcData.Path.Jump) == "function" then
			NpcData.Path.Jump()
		end
	end

	SafeSetNetworkOwner(NpcModel) -- Disable control by the player SAFELY

	NpcData.Path:Run(NpcData.CurrentDestination)
end

local function onPathTrapped(NpcModel)
	local NpcData = NPCHandler.ActiveCustomers[NpcModel]
	if not NpcData or not NpcData.CurrentDestination then return end

	if NpcData.Humanoid:GetState() ~= Enum.HumanoidStateType.Climbing then
		if type(NpcData.Path.Jump) == "function" then
			NpcData.Path.Jump()
		end
	end

	SafeSetNetworkOwner(NpcModel) -- Disable control by the player SAFELY

	NpcData.Path:Run(NpcData.CurrentDestination)
end

function NPCHandler.SetupNPC(NpcModel,Plot,StartPoint,player)
	if NPCHandler.ActiveCustomers[NpcModel] then return end 

	local Humanoid = NpcModel:FindFirstChildWhichIsA("Humanoid")
	local Hrp = NpcModel:FindFirstChildWhichIsA("HumanoidRootPart")
	if not Humanoid then return end

	local path = PathfinderModule.Humanoid(NpcModel, {
		AgentRadius = Humanoid.HipHeight / 2,
		AgentHeight = Humanoid.HipHeight,
		WaypointSpacing = 3,
		AgentCanJump = true,
		Costs = { Water = 30 },
	})
	path.Visualize = false
	path.Speed = Humanoid.WalkSpeed

	NPCHandler.ActiveCustomers[NpcModel] = {
		Path = path,
		Humanoid = Humanoid,
		HRP = Hrp,
		State = "Walking",
		Plr = player,
		TargetPlot = Plot,
		CurrentNode = StartPoint,
		WaitTimer = 0,
		Connections = {}, 
		VisitedPlots = {Plot.Name},
		Animations = {},
		CurrentDestination = nil 
	}

	table.insert(NPCHandler.ActiveCustomers[NpcModel].Connections, 
		path.Reached:Connect(function() 
			if NPCHandler.ActiveCustomers[NpcModel].TargetPlot ~= nil  then
				return
			end
			onPathReached(NpcModel) 
		end)
	)
	table.insert(NPCHandler.ActiveCustomers[NpcModel].Connections, 
		path.WaypointReached:Connect(function() 
			if NPCHandler.ActiveCustomers[NpcModel].TargetPlot ~= nil then
				return
			end
			onWaypointReached(NpcModel) 
		end)
	)

	table.insert(NPCHandler.ActiveCustomers[NpcModel].Connections, 
		path.Error:Connect(function(errorType)
			onPathError(NpcModel, errorType) 
		end)
	)
	table.insert(NPCHandler.ActiveCustomers[NpcModel].Connections, 
		path.Trapped:Connect(function() 
			onPathTrapped(NpcModel) 
		end)
	)

	table.insert(NPCHandler.ActiveCustomers[NpcModel].Connections, 
		NpcModel.Destroying:Connect(function()
			NPCHandler.CleanupNPC(NpcModel) 
		end)
	)
end

function NPCHandler.Go(NpcModel,Position)
	local NpcData = NPCHandler.ActiveCustomers[NpcModel]
	if not NpcData then return end 

	SafeSetNetworkOwner(NpcModel) -- SAFELY set owner

	NpcData.CurrentDestination = Position 
	NpcData.Path:Run(Position)
	NpcData.Path.Speed = NpcModel.Humanoid.WalkSpeed
end

function NPCHandler.Stop(NpcModel)
	local NpcData = NPCHandler.ActiveCustomers[NpcModel]
	if not NpcData then return end 

	NpcData.CurrentDestination = nil
	NpcData.Path:Stop()
end

function NPCHandler.Intercepted(NpcModel,Position)
	local NpcData = NPCHandler.ActiveCustomers[NpcModel]
	if not NpcData then return end 

	SafeSetNetworkOwner(NpcModel) -- SAFELY set owner

	NpcData.CurrentDestination = Position 
	NpcData.Path:Stop()
	NpcData.Path:Run(Position)
	NpcData.Path.Speed = NpcModel.Humanoid.WalkSpeed
end

function NPCHandler.CleanupNPC(NpcModel)
	local NpcData = NPCHandler.ActiveCustomers[NpcModel]
	if not NpcData then return end 

	for _, connection in ipairs(NpcData.Connections) do
		connection:Disconnect()
	end
	pcall(function()
		if NpcData.Path then
			NpcData.Path:Destroy()
		end
		if NpcModel and NpcModel ~= nil then
			Debris:AddItem(NpcModel,5)
		end
	end)
	if NPCHandler.ActiveCustomers[NpcModel] then
		NPCHandler.ActiveCustomers[NpcModel] = nil
	end
end

return NPCHandler