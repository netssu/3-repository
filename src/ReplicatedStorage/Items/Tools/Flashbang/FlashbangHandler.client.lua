--//Tool
local Tool = script.Parent
local Handle = Tool.Handle

--//Player
local plr = game.Players.LocalPlayer
local camera = workspace.CurrentCamera

--//Remotes
local activeEvent = Tool.activeEvent

Tool.Activated:Connect(function()
	local lookVector = camera.CFrame.LookVector * 1000
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {plr.Character, Tool}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local result = workspace:Raycast(camera.CFrame.Position, lookVector, raycastParams)
	if result then
		local targetPos = result.Position
		activeEvent:FireServer(targetPos)
	end
end)