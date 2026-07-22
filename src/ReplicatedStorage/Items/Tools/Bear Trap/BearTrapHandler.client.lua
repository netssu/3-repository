--//Services
local RunService = game:GetService("RunService")
local Rs = game:GetService("ReplicatedStorage")

--//Player
local Plr = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera

--//Tool
local bearTrapTool = script.Parent
local BearTrapModel = bearTrapTool.Handle.BearTrapModel
local DropEvent = bearTrapTool.DropItem

--//Values
local previewModel: MeshPart = nil
local modelConnection: RBXScriptConnection = nil
local placeDistance = 10
local offsetPos = Vector3.new(0, 0.2, 0)
local used = false

bearTrapTool.Equipped:Connect(function()
	if previewModel then
		previewModel:Destroy()
	end
	
	local function setupPreviewModel()
		previewModel = BearTrapModel:Clone()
		previewModel.Base.Anchored = true
		
		for _, v in previewModel:GetDescendants() do
			if v:IsA("BasePart") then
				v.CanCollide = false
				v.Transparency = 0.5
			end
		end
		
		previewModel:SetAttribute("PreviewModel", true)
		
		for _, v in previewModel:GetDescendants() do
			if v:IsA("WeldConstraint") or v:IsA("Weld") then
				if v:GetAttribute("ignore") then continue end
				v:Destroy()
			end
		end
	end
	
	setupPreviewModel()
	
	if modelConnection then
		modelConnection:Disconnect()
		modelConnection = nil
	end
	
	modelConnection = RunService.RenderStepped:Connect(function(dt)
		if used then return end
		
		if not previewModel then
			setupPreviewModel()
			return
		end
		
		local raycast = RaycastParams.new()
		raycast.FilterType = Enum.RaycastFilterType.Exclude
		raycast.FilterDescendantsInstances = {Plr.Character, previewModel}
		
		local ray = workspace:Raycast(Camera.CFrame.Position, Camera.CFrame.LookVector * placeDistance, raycast)
		
		if ray then
			previewModel:PivotTo(CFrame.new(ray.Position + offsetPos))
			previewModel.Parent = workspace
		else
			previewModel.Parent = Rs
		end
	end)
end)

bearTrapTool.Unequipped:Connect(function()
	if previewModel then
		previewModel:Destroy()
	end
	if modelConnection then
		modelConnection:Disconnect()
		modelConnection = nil
	end
end)

bearTrapTool.Activated:Connect(function()
	if previewModel and previewModel.Parent == workspace then
		DropEvent:FireServer(previewModel:GetPivot()) -- tool event / use tool
		
		task.spawn(function()
			used = true
			if previewModel then
				previewModel:Destroy()
			end
			if modelConnection then
				modelConnection:Disconnect()
				modelConnection = nil
			end
		end)
	end
end)