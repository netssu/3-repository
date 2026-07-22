--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")
local RunService = game:GetService("RunService")

--//Player
local Player = game.Players.LocalPlayer
local PlayerValues = Player:WaitForChild("PlayerValues", 10)
local Char = Player.Character or Player.CharacterAdded:Wait()
local Hum = Char:WaitForChild("Humanoid") :: Humanoid

--//UI
local FlashlightFrame = script.Parent.FlashLightFrame

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local PlayerValuesEvent = Remotes:WaitForChild("PlayerValues")

--//Values
local FlashlightOn = false
local FlashlightUI = false
local PlrDied = false

--//Modules
local ModulesFolder = Rs:WaitForChild("Modules")
local FlashlightModule = require(ModulesFolder:WaitForChild("FlashlightModule"))
local SecureSearch = require(ModulesFolder:WaitForChild("SecureSearch"))

--//Values
--[[local GameOptions = SecureSearch:GetInstance(Player, "GameOptions")
local InterfaceStyle = SecureSearch:GetInstance(GameOptions, "InterfaceStyle")
local PlayerValues = SecureSearch:GetInstance(Player, "PlayerValues")]]
--The same of: Player:WaitForChild("Playervalues"), but with a pcall function.

--//Function for Flashlight Battery decay
coroutine.wrap(function()
	while task.wait(FlashlightModule.Time) do
		local onCutscene = nil
		if PlayerValues then
			onCutscene = SecureSearch:GetInstance(PlayerValues, "OnCutscene")
		end

		if FlashlightOn and not (onCutscene and onCutscene.Value) then
			PlayerValuesEvent:FireServer("DecayLight")
		end
	end
end)()

Hum.Died:Connect(function()
	PlayerValuesEvent:FireServer("ResetFlashlight")
	PlrDied = true
end)

RunService.RenderStepped:Connect(function(dt: number)
	--//Detect when the player is using the flashlight
	if Char:FindFirstChild("Flashlight") then
		local isOn = Char:FindFirstChild("Flashlight"):WaitForChild("IsOn") :: BoolValue
		if isOn.Value then
			FlashlightOn = true
		else
			FlashlightOn = false
		end
	else
		FlashlightOn = false
	end
	
	--//Detect if the Flash Light is visible when the flashlight is on
	if FlashlightOn and not FlashlightUI and not PlrDied then
		FlashlightUI = true
		Ts:Create(FlashlightFrame.Icon, TweenInfo.new(0.1), {ImageTransparency = 0}):Play()
		Ts:Create(FlashlightFrame.BatteryAmount, TweenInfo.new(0.1), {TextTransparency = 0}):Play()
	elseif not FlashlightOn or PlrDied then
		FlashlightUI = false
		Ts:Create(FlashlightFrame.Icon, TweenInfo.new(0.1), {ImageTransparency = 1}):Play()
		Ts:Create(FlashlightFrame.BatteryAmount, TweenInfo.new(0.1), {TextTransparency = 1}):Play()
	end
	
	local currentBattery = Player:WaitForChild("PlayerValues") and Player.PlayerValues:FindFirstChild("Batteries")
	if currentBattery then
		FlashlightFrame.BatteryAmount.Text = tostring(currentBattery.Value).."%"
	end
end)