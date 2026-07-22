--//Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--//Tool Stuff
local tool = script.Parent
local shootEvent = tool:WaitForChild("shootEvent")

--//Config
local fireDelay = 0.25
local firing = false

local function shoot()
	local lookPos = camera.CFrame.LookVector * 10000
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {player.Character, tool}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local result = workspace:Raycast(camera.CFrame.Position, lookPos, raycastParams)
	if result then
		local targetPos = result.Position
		shootEvent:FireServer(targetPos, player)
	end
end

tool.Activated:Connect(function()
	if firing then return end
	firing = true
	while firing do
		shoot()
		task.wait(fireDelay)
	end
end)

tool.Deactivated:Connect(function()
	firing = false
end)

tool.Unequipped:Connect(function()
	firing = false
end)