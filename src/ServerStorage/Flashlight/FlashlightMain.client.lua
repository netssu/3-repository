--//Services
local RunService = game:GetService("RunService")
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")

--//Modules
local ModulesFolder = Rs:WaitForChild("Modules")
local FlashlightModule = require(ModulesFolder:WaitForChild("FlashlightModule"))
local GameConfigModule = require(ModulesFolder:WaitForChild("GameConfigModule"))

--//Player
local Player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Char = Player.Character or Player.CharacterAdded:Wait()
local Hum = Char:WaitForChild("Humanoid", 30) :: Humanoid
local Animator = Hum:WaitForChild("Animator", 30) :: Animator
local HumanoidRootPart = Char:WaitForChild("HumanoidRootPart", 30)
local Head = Char:WaitForChild("Head", 30)
local DefaultSpeed = GameConfigModule.PlayerDefaultSpeed

--//Tool
local tool = script.Parent
local Flashlight = tool:FindFirstChild("Handle"):FindFirstChild("Flashlight")
local FlashlightModel = Rs:WaitForChild("Flashlight"):Clone()
local ChangeFlashlightEvent = tool:FindFirstChild("ChangeFlashlight")
local UpdateLightPos = tool:FindFirstChild("UpdateLightPos")

if Camera:FindFirstChild("Flashlight") then
	Camera.Flashlight:Destroy()
end

FlashlightModel.FrontPart.FrontLight.Brightness = 0
FlashlightModel.BackPart.BackLight.Brightness = 0
FlashlightModel.Parent = Camera

--//Animations
local PlayerEquippedAnim = tool:FindFirstChild("PlayerEquippedAnim")
local animPlayerEquipped = Animator:LoadAnimation(PlayerEquippedAnim)
animPlayerEquipped:AddTag("itemAnim")
animPlayerEquipped.Priority = Enum.AnimationPriority.Action4

--//Sounds
local EquipSound = tool.EquipSound
local UnequipSound = tool.UnequipSound
local OnSound = tool.OnSound
local OffSound = tool.OffSound

--//Values
local isOn = tool.IsOn
local changeDebounce = true
local State = "Full"

if isOn.Value then
	FlashlightModel.FrontPart.FrontLight.Enabled = true
	FlashlightModel.BackPart.BackLight.Enabled = true
	FlashlightModel.FrontPart.FrontLight.Brightness = 2
	FlashlightModel.BackPart.BackLight.Brightness = 0.2
	FlashlightModel.FrontPart.FrontLight.Range = 60
	FlashlightModel.BackPart.BackLight.Range = 60
end

function Tween(p1, p2, p3)
	p1 = p1 + (p2 - p1) * p3
	return p1
end

function debbug()
	Flashlight.Attachment.SpotLight.Enabled = false
	Flashlight.Beam.Enabled = false
	if not FlashlightModel then
		FlashlightModel = Rs:WaitForChild("Flashlight"):Clone()
		FlashlightModel.FrontPart.FrontLight.Brightness = 0
		FlashlightModel.BackPart.BackLight.Brightness = 0
		FlashlightModel.Parent = Camera
	end
	if tool.Parent ~= Char then
		isOn.Value = false
		animPlayerEquipped:Stop()
		changeDebounce = false
		return
	end
end

tool.Equipped:Connect(function()
	EquipSound:Play()
	animPlayerEquipped:Play()
	Flashlight.Attachment.SpotLight.Enabled = false
	Flashlight.Beam.Enabled = false
	changeDebounce = false
	ChangeFlashlightEvent:FireServer(false)
	debbug()
	changeDebounce = true
end)

tool.Unequipped:Connect(function()
	UnequipSound:Play()
	animPlayerEquipped:Stop(0.3)
end)

tool.Activated:Connect(function()
	if not changeDebounce then return end
	if not Hum or not Char or Hum.Health <= 0 then return end
	changeDebounce = false
	
	local otherValue = not isOn.Value
	
	isOn.Value = otherValue
	ChangeFlashlightEvent:FireServer(otherValue)
	
	debbug()
	
	if isOn.Value then
		OnSound:Play()
	else
		OffSound:Play()
	end
	
	task.wait(0.6)
	changeDebounce = true
end)

isOn:GetPropertyChangedSignal("Value"):Connect(function()
	local Value = isOn.Value
	if not Hum or not Char or Hum.Health <= 0 then
		FlashlightModel.FrontPart.FrontLight.Brightness = 0
		FlashlightModel.FrontPart.FrontLight.Range = 0
		FlashlightModel.BackPart.BackLight.Brightness = 0
		FlashlightModel.BackPart.BackLight.Range = 0
		FlashlightModel.FrontPart.FrontLight.Enabled = false
		FlashlightModel.BackPart.BackLight.Enabled = false
		ChangeFlashlightEvent:FireServer(false)
		return
	end
	if Value then
		FlashlightModel.FrontPart.FrontLight.Enabled = true
		FlashlightModel.BackPart.BackLight.Enabled = true
		if State == "Full" then
			Ts:Create(FlashlightModel.FrontPart.FrontLight, TweenInfo.new(0.6), {Brightness = 2}):Play()
			Ts:Create(FlashlightModel.FrontPart.FrontLight, TweenInfo.new(0.6), {Range = 60}):Play()
			Ts:Create(FlashlightModel.BackPart.BackLight, TweenInfo.new(0.6), {Brightness = 0.2}):Play()
			Ts:Create(FlashlightModel.BackPart.BackLight, TweenInfo.new(0.6), {Range = 60}):Play()
		elseif State == "Medium" then
			Ts:Create(FlashlightModel.FrontPart.FrontLight, TweenInfo.new(0.6), {Brightness = 1}):Play()
			Ts:Create(FlashlightModel.FrontPart.FrontLight, TweenInfo.new(0.6), {Range = 60}):Play()
			Ts:Create(FlashlightModel.BackPart.BackLight, TweenInfo.new(0.6), {Brightness = 0.13}):Play()
			Ts:Create(FlashlightModel.BackPart.BackLight, TweenInfo.new(0.6), {Range = 60}):Play()
		elseif State == "Low" then
			Ts:Create(FlashlightModel.FrontPart.FrontLight, TweenInfo.new(0.6), {Brightness = 0.8}):Play()
			Ts:Create(FlashlightModel.FrontPart.FrontLight, TweenInfo.new(0.6), {Range = 50}):Play()
			Ts:Create(FlashlightModel.BackPart.BackLight, TweenInfo.new(0.6), {Brightness = 0.1}):Play()
			Ts:Create(FlashlightModel.BackPart.BackLight, TweenInfo.new(0.6), {Range = 50}):Play()
		elseif State == "Critical" then
			Ts:Create(FlashlightModel.FrontPart.FrontLight, TweenInfo.new(0.6), {Brightness = 0.5}):Play()
			Ts:Create(FlashlightModel.FrontPart.FrontLight, TweenInfo.new(0.6), {Range = 45}):Play()
			Ts:Create(FlashlightModel.BackPart.BackLight, TweenInfo.new(0.6), {Brightness = 0.05}):Play()
			Ts:Create(FlashlightModel.BackPart.BackLight, TweenInfo.new(0.6), {Range = 45}):Play()
		elseif State == "Dead" then
			FlashlightModel.FrontPart.FrontLight.Brightness = 0
			FlashlightModel.FrontPart.FrontLight.Range = 0
			FlashlightModel.BackPart.BackLight.Brightness = 0
			FlashlightModel.BackPart.BackLight.Range = 0
			ChangeFlashlightEvent:FireServer(false)
		end
	else
		FlashlightModel.FrontPart.FrontLight.Brightness = 0
		FlashlightModel.FrontPart.FrontLight.Range = 0
		FlashlightModel.BackPart.BackLight.Brightness = 0
		FlashlightModel.BackPart.BackLight.Range = 0
		FlashlightModel.FrontPart.FrontLight.Enabled = false
		FlashlightModel.BackPart.BackLight.Enabled = false
		ChangeFlashlightEvent:FireServer(false)
	end
end)

local Pos1 = 0
local Pos2 = 0
local Pos3 = 0
local Pos4 = 0
local Pos5 = 0
local Pos6 = 0
local Pos7 = Head.Position.Y - HumanoidRootPart.Position.Y

RunService.RenderStepped:Connect(function()
	debbug()
	
	if Hum.MoveDirection.Magnitude > 0 then
		if Hum.WalkSpeed > DefaultSpeed then
			animPlayerEquipped:AdjustSpeed(2)
		else
			animPlayerEquipped:AdjustSpeed(1)
		end
	else
		animPlayerEquipped:AdjustSpeed(0.2)
	end
	
	if isOn.Value then
		local LookVector = Camera.CFrame.LookVector
		
		Pos1 = LookVector.x
		Pos2 = LookVector.y
		Pos3 = LookVector.z
		Pos4 = Tween(Pos4, Pos1, 0.25)
		Pos5 = Tween(Pos5, Pos2, 0.25)
		Pos6 = Tween(Pos6, Pos3, 0.25)
	end
	
	if Char:FindFirstChild("Humanoid"):GetState() ~= Enum.HumanoidStateType.Dead then
		if not isOn.Value then
			return
		end
	else
		FlashlightModel.FrontPart.CFrame = Head.CFrame * CFrame.new(0, 0, -2)
		return
	end
	
	local LookPos = Camera.CFrame.LookVector
	UpdateLightPos:FireServer(LookPos)
	FlashlightModel.FrontPart.CFrame = CFrame.new(Flashlight.LightPos.CFrame.p, Flashlight.LightPos.CFrame.p + Vector3.new(Pos4, Pos5, Pos6)) * CFrame.Angles(-0, 0, 2) + Vector3.new(0, Pos7, 0)
end)

Hum.Died:Connect(function()
	FlashlightModel.FrontPart.CFrame = Head.CFrame * CFrame.new(0, 0, -2)
	FlashlightModel.FrontPart.FrontLight.Brightness = 0
	FlashlightModel.BackPart.BackLight.Brightness = 0
end)

while wait() do
	local PlayerValues = Player:WaitForChild("PlayerValues")
	local BatteriesValue = PlayerValues:WaitForChild("Batteries")
	local Battery_10 = FlashlightModule.MaxBattery * 0.10
	local Battery_25 = FlashlightModule.MaxBattery * 0.25
	local Battery_50 = FlashlightModule.MaxBattery * 0.50
	
	if BatteriesValue.Value > Battery_50 then
		State = "Full"
		if isOn.Value then
			isOn.Value = true
		end
	elseif BatteriesValue.Value > Battery_25 and BatteriesValue.Value <= Battery_50 then
		State = "Medium"
		Ts:Create(FlashlightModel.FrontPart.FrontLight, TweenInfo.new(0.6), {Brightness = 1}):Play()
		Ts:Create(FlashlightModel.FrontPart.FrontLight, TweenInfo.new(0.6), {Range = 60}):Play()
		Ts:Create(FlashlightModel.BackPart.BackLight, TweenInfo.new(0.6), {Brightness = 0.13}):Play()
		Ts:Create(FlashlightModel.BackPart.BackLight, TweenInfo.new(0.6), {Range = 60}):Play()
	elseif BatteriesValue.Value > Battery_10 and BatteriesValue.Value <= Battery_25 then
		State = "Low"
		Ts:Create(FlashlightModel.FrontPart.FrontLight, TweenInfo.new(0.6), {Brightness = 0.7}):Play()
		Ts:Create(FlashlightModel.FrontPart.FrontLight, TweenInfo.new(0.6), {Range = 50}):Play()
		Ts:Create(FlashlightModel.BackPart.BackLight, TweenInfo.new(0.6), {Brightness = 0.1}):Play()
		Ts:Create(FlashlightModel.BackPart.BackLight, TweenInfo.new(0.6), {Range = 50}):Play()
	elseif BatteriesValue.Value > 0 and BatteriesValue.Value <= Battery_10 then
		State = "Critical"
		Ts:Create(FlashlightModel.FrontPart.FrontLight, TweenInfo.new(0.6), {Brightness = 0.5}):Play()
		Ts:Create(FlashlightModel.FrontPart.FrontLight, TweenInfo.new(0.6), {Range = 45}):Play()
		Ts:Create(FlashlightModel.BackPart.BackLight, TweenInfo.new(0.6), {Brightness = 0.05}):Play()
		Ts:Create(FlashlightModel.BackPart.BackLight, TweenInfo.new(0.6), {Range = 45}):Play()
	elseif BatteriesValue.Value <= 0 then
		State = "Dead"
		isOn.Value = false
	end
end