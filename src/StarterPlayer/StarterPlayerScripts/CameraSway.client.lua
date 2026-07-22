local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local Plr = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Turn = 0

local Lerp = function(a, b, t)
	return a + (b - a) * t
end

RunService:BindToRenderStep("CameraSway", Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
	-- Cutscenes own a Scriptable camera. Do not apply player mouse sway while
	-- another controller is responsible for the camera, even before the server
	-- replicates PlayerValues.OnCutscene back to this client.
	if Camera.CameraType == Enum.CameraType.Scriptable or Plr:GetAttribute("CutsceneCameraLocked") then
		return
	end

	local MouseDelta = UIS:GetMouseDelta()
	local enabled = true
	
	if Plr:FindFirstChild("PlayerValues") then
		if Plr:FindFirstChild("PlayerValues"):FindFirstChild("OnCutscene") then
			if Plr:FindFirstChild("PlayerValues"):FindFirstChild("OnCutscene").Value then
				enabled = false
			end
		end
		if Plr.PlayerValues:FindFirstChild("OnInspect") and Plr.PlayerValues.OnInspect.Value then
			enabled = false
		end
	end
	
	if not enabled then return end
	
	Turn = Lerp(Turn, math.clamp(MouseDelta.X, -6, 6), (6 * deltaTime))
	Camera.CFrame = Camera.CFrame * CFrame.Angles(0, 0, math.rad(Turn))
end)
