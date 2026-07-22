--//Services
local Ts = game:GetService("TweenService")
local Rs = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

--//Player
local Player = game.Players.LocalPlayer
local Char = Player.Character or Player.CharacterAdded:Wait()
local Hum = Char:WaitForChild("Humanoid") :: Humanoid

--//Modules
local ModulesFolder = Rs:WaitForChild("Modules")
local CameraShaker = require(ModulesFolder:WaitForChild("CameraShaker"))

--//UI
local MainFrame = script.Parent
local VignetteBlood = MainFrame.VignetteBlood

--//Sounds
local HeartBeatSound = MainFrame.HeartSound

--//Values
local lastHealth = Hum.Health
local tweens = {}
local currenCamShake = nil

ContentProvider:PreloadAsync({MainFrame})

Hum.HealthChanged:Connect(function(health)
	if health < lastHealth then
		lastHealth = health
		
		for i, v in pairs(tweens) do
			v:Cancel()
		end
		
		Ts:Create(VignetteBlood, TweenInfo.new(0.03), {ImageTransparency = health/Hum.MaxHealth}):Play()
		HeartBeatSound.Volume = 0.5
		HeartBeatSound:Play()
		
		local camShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCFrame)
			workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame * shakeCFrame
		end)
		
		if currenCamShake then
			currenCamShake:Stop()
		end
		
		camShake:StartShake(0.6, 8, 0.1, 0.4, 0.5)
		camShake:Start()
		
		task.delay(4, function()
			tweens[1] = Ts:Create(VignetteBlood, TweenInfo.new(7), {ImageTransparency = 1}):Play()
			tweens[2] = Ts:Create(HeartBeatSound, TweenInfo.new(7), {Volume = 0}):Play()
		end)
		task.delay(9, function()
			camShake:Stop()
		end)
	end
end)