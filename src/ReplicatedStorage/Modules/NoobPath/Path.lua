local PFS = game:GetService("PathfindingService")

local module = {}

local Path = {}
Path.__index = Path

local VisualWaypoint = script.VisualWaypoint

export type Route = {PathWaypoint}
export type AgentParams = {
	AgentRadius : number, --(The Radius Of The Object(Half Its width))
	AgentHeight : number, --(The Height Of The Object)
	AgentCanClimb : boolean, --(Whether or not it can climb)
	AgentCanJump : boolean, --(Whether or not it allows jumps)
	Costs : {}, --(What Material or Pathfinding Modifiers should be avoided(High = Avoid, Low = Okay))
	WaypointSpacing : number, --(Spacing between Waypoints)
	PathSettings : {SupportPartialPath : boolean}
}

function module.new(AgentParams: AgentParams)
	local self = setmetatable({
		Path = PFS:CreatePath(AgentParams),
		Visual = {},
		Destroying = false,
	}, Path)

	return self
end

-- Generate a Path from PointA to PointB, Return Route, IsPartialPath
function Path:Generate(PointA : Vector3, PointB : Vector3) : Route & boolean
	local Success, Message = pcall(function()
		self.Path:ComputeAsync(PointA, PointB)
	end)
	if not Success then
		return warn(Message)
	end
	
	if self.Destroying ~= false then
		return
	end

	local Route : Route = self.Path:GetWaypoints()

	for i = #Route - 1, 1, -1 do
		local Waypoint = Route[i]
		local NextWaypoint = Route[i + 1]
		local Distance = (Waypoint.Position - NextWaypoint.Position).Magnitude

		if Waypoint.Action ~= Enum.PathWaypointAction.Jump and Distance < 2 then
			table.remove(Route, i)
		end
	end
	return Route, self.Path.Status == Enum.PathStatus.ClosestNoPath
end

local VisualFolder = workspace:FindFirstChild("VisualWaypoints")
if not VisualFolder then
	VisualFolder = Instance.new("Folder")
	VisualFolder.Name = "VisualWaypoints"
	VisualFolder.Parent = workspace
end

local NoobPath = script.Parent

-- Visualize the given Route
function Path:Show(Route)
	self:Hide()
	local Visual = self.Visual

	if NoobPath:GetAttribute("GraphPath") then
		for i = 1, #Route - 1 do
			local Waypoint = Route[i]
			local Position = Waypoint.Position

			local Point = VisualWaypoint:Clone()
			Point.Position = Position

			if Waypoint.Action == Enum.PathWaypointAction.Jump then
				Point.BrickColor = BrickColor.new("Bright yellow")
			end

			Point.Parent = VisualFolder
			Visual[i] = Point

			local Direction = Route[i + 1].Position - Position

			local Line = Instance.new("LineHandleAdornment")
			Line.Parent = Point
			Line.Adornee = Point
			Line.CFrame = CFrame.new(Vector3.new(0, 0, 0), Direction)
			Line.Length = Direction.Magnitude
			Line.Color3 = BrickColor.new("Bright blue").Color

			Line.Thickness = 3
		end
	else
		for i = 1, #Route - 1 do
			local Waypoint = Route[i]
			local Position = Waypoint.Position

			local Point = VisualWaypoint:Clone()
			Point.Position = Position

			if Waypoint.Action == Enum.PathWaypointAction.Jump then
				Point.BrickColor = BrickColor.new("Bright yellow")
			end

			Point.Parent = VisualFolder
			Visual[i] = Point
		end
	end

	local LastWaypoint = Route[#Route]
	local Point = VisualWaypoint:Clone()
	Point.Position = LastWaypoint.Position
	Point.BrickColor = BrickColor.new("Bright red")

	Point.Parent = VisualFolder
	Visual[#Route] = Point
end

-- Hide all Path Visualizations
function Path:Hide()
	local Visual = self.Visual
	for i = 1, #Visual do
		Visual[i]:Destroy()
	end
end

-- Estimate time required to travel the given Route based on given Speed
function Path:Estimate(Route, Speed)
	local Estimate : {number} = {}
	
	for i = 1, #Route - 1 do
		local Waypoint = Route[i]
		local NextWaypoint = Route[i + 1]

		local Distance = (Waypoint.Position - NextWaypoint.Position).Magnitude
		local Time = Distance / Speed -- Estimated time
		
		Estimate[i] = Time
	end

	return Estimate
end

-- Get the current status of the Path
function Path:GetStatus() : Enum.PathStatus
	return self.Path.Status
end

-- Destroy the Object
function Path:Destroy()
	self.Destroying = true
	self:Hide()
	self.Path:Destroy()
	table.clear(self)
	setmetatable(self, nil)
	self = nil
end

return module
