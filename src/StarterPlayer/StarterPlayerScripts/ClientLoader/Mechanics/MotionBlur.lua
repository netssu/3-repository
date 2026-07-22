local MotionBlur = {}

function MotionBlur.Init()
	--//Services
	local RunService = game:GetService("RunService")

	--//Settings
	local DefaultBlur = 25 -- Change this to increase or decrease the blur size
	local BlurAmount = DefaultBlur
	local GameConfig = UserSettings().GameSettings

	--//Others
	local Camera = game.Workspace.CurrentCamera
	local Last = Camera.CFrame.lookVector
	local Blur = Instance.new("BlurEffect", Camera)

	--//Main
	game.Workspace.Changed:connect(function(p) -- Updates the Camera and Blur if the Camera object is changed.
		if p == "CurrentCamera" then
			Camera = game.Workspace.CurrentCamera
			if Blur and Blur.Parent then
				Blur.Parent = Camera
			else
				Blur = Instance.new("BlurEffect", Camera)
			end
		end
	end)

	RunService.Heartbeat:connect(function()
		if not Blur or Blur.Parent == nil then Blur = Instance.new("BlurEffect", Camera) end -- Creates a new Blur if it is destroyed.

		if GameConfig.SavedQualityLevel.Value >= 4 then
			BlurAmount = 10 -- Lower blur when the graphics is highter
		else
			BlurAmount = DefaultBlur
		end

		local magnitude = (Camera.CFrame.lookVector - Last).magnitude -- How much the camera has rotated since the last frame
		Blur.Size = math.abs(magnitude) * BlurAmount -- Set the blur size
		Last = Camera.CFrame.lookVector -- Update the previous camera rotation
	end)
end

return MotionBlur