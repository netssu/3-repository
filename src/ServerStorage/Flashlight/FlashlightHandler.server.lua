--//Tool
local tool = script.Parent
local FlashlightModel = tool:FindFirstChild("Handle"):FindFirstChild("Flashlight")
local LightPart = FlashlightModel:FindFirstChild("Part")

--//Events
local changeFlashlightEvent = tool:FindFirstChild("ChangeFlashlight")
local updateLightPos = tool:FindFirstChild("UpdateLightPos")

changeFlashlightEvent.OnServerEvent:Connect(function(plr, event: boolean)
	if plr then
		if event then
			LightPart.Color = Color3.new(1, 1, 1)
			LightPart.Material = Enum.Material.Neon
			LightPart.Transparency = 0
			FlashlightModel.Attachment.SpotLight.Enabled = true
			FlashlightModel.Attachment.SpotLight.Brightness = 2.5
			FlashlightModel.Attachment.SpotLight.Range = 30
			FlashlightModel.Attachment.SpotLight.Angle = 60
			FlashlightModel.Particle.ParticleEmitter.Enabled = true
			FlashlightModel.Beam.Enabled = true
			FlashlightModel.Beam.Width0 = 2
			FlashlightModel.Beam.Width1 = 6
		else
			LightPart.Color = Color3.new(0.247059, 0.290196, 0.32549)
			LightPart.Material = Enum.Material.Glacier
			LightPart.Transparency = 0.5
			FlashlightModel.Attachment.SpotLight.Enabled = false
			FlashlightModel.Particle.ParticleEmitter.Enabled = false
			FlashlightModel.Beam.Enabled = false
		end
	end
end)

local cameraOffset = Vector3.new(0, -5, 0)

updateLightPos.OnServerEvent:Connect(function(plr, CameraLookVector)
	if plr then
		FlashlightModel.Beam0.WorldCFrame = CFrame.new(FlashlightModel.Beam0.WorldPosition, FlashlightModel.Beam0.WorldPosition + CameraLookVector) + cameraOffset
		FlashlightModel.Beam1.WorldCFrame = CFrame.new(FlashlightModel.Beam0.WorldPosition + CameraLookVector * FlashlightModel.Attachment.SpotLight.Range, FlashlightModel.Beam1.WorldPosition + CameraLookVector) + cameraOffset
		FlashlightModel.Attachment.WorldCFrame = CFrame.new(FlashlightModel.Attachment.WorldPosition, FlashlightModel.Attachment.WorldPosition + CameraLookVector) + cameraOffset
	end
end)