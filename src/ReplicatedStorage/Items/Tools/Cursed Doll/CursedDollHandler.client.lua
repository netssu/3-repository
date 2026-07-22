--//Services
local RunService = game:GetService("RunService")
local Rs = game:GetService("ReplicatedStorage")

--//Player
local Plr = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera

--//Tool
local cursedDollTool = script.Parent
local DollModel = cursedDollTool.Handle.CursedDoll
local DropEvent = cursedDollTool.DropItem

--//Values
local previewModel: MeshPart = nil
local modelConnection: RBXScriptConnection = nil
local placeDistance = 10
local offsetPos = Vector3.new(0, 1, 0)
local used = false

cursedDollTool.Equipped:Connect(function()
	if previewModel then
		previewModel:Destroy()
	end
	
	local function setupPreviewModel()
		previewModel = DollModel:Clone()
		previewModel.Anchored = true
		previewModel.CanCollide = false
		previewModel.Transparency = 0.5
		previewModel:SetAttribute("PreviewModel", true)
		
		for _, v in previewModel:GetChildren() do
			if v:IsA("WeldConstraint") or v:IsA("Weld") then
				v:Destroy()
			end
		end
		
		local highlight = Instance.new("Highlight", previewModel)
		highlight.FillColor = Color3.fromRGB(71, 236, 26)
		highlight.OutlineTransparency = 1
		highlight.FillTransparency = 0.5
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.Adornee = previewModel
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
			previewModel.CFrame = CFrame.new(ray.Position + offsetPos) * CFrame.Angles(math.rad(-15), math.rad(0), 0)
			previewModel.Parent = workspace
		else
			previewModel.Parent = Rs
		end
	end)
end)

cursedDollTool.Unequipped:Connect(function()
	if previewModel then
		previewModel:Destroy()
	end
	if modelConnection then
		modelConnection:Disconnect()
		modelConnection = nil
	end
end)

cursedDollTool.Activated:Connect(function()
	if previewModel and previewModel.Parent == workspace then
		DropEvent:FireServer(previewModel.CFrame) -- tool event / use tool
		
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