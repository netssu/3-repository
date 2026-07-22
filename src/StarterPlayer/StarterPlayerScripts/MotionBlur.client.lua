--//Services
local RunService = game:GetService("RunService")
local Rs = game:GetService("ReplicatedStorage")

--//Settings
local DefaultBlur = 25
local BlurAmount = DefaultBlur -- Change this to increase or decrease the blur size
local GameConfig = UserSettings().GameSettings

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local UpdatePlrOptions = Remotes:WaitForChild("UpdatePlrOptions")

--//Player
local Player = game.Players.LocalPlayer

--//Others
local Camera = game.Workspace.CurrentCamera
local Last = Camera.CFrame.lookVector
local Blur = Instance.new("BlurEffect", Camera)
local Enabled = true

UpdatePlrOptions.OnClientEvent:Connect(function()
	local GameOptions = Player:WaitForChild("GameOptions")
	local MotionBlur = GameOptions:WaitForChild("MotionBlur")
	if GameOptions and MotionBlur then
		if MotionBlur.Value then
			Enabled = true
		else
			Enabled = false
		end
	end
end)

game.Workspace.Changed:connect(function(p) -- Feels a bit hacky. Updates the Camera and Blur if the Camera object is changed.
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
	
	if Enabled then
		if GameConfig.SavedQualityLevel.Value >= 4 then
			BlurAmount = 10 -- Lower blur when the graphics is highter
		else
			BlurAmount = DefaultBlur
		end
	else
		BlurAmount = 0
	end
	
	local magnitude = (Camera.CFrame.lookVector - Last).magnitude -- How much the camera has rotated since the last frame
	Blur.Size = math.abs(magnitude) * BlurAmount -- Set the blur size
	Last = Camera.CFrame.lookVector -- Update the previous camera rotation
end)