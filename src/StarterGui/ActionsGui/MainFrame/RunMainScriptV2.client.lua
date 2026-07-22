--// Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

--// Remotes & Modules
local Remotes = Rs:WaitForChild("Remotes")
local PlayerValuesEvent = Remotes:WaitForChild("PlayerValues")
local UpdatePlrOptions = Remotes:WaitForChild("UpdatePlrOptions")
local Modules = Rs:WaitForChild("Modules")
local GameConfig = require(Modules:WaitForChild("GameConfigModule"))
local ShopModule = require(Modules:WaitForChild("ShopModule"))
local SecureSearch = require(Modules:WaitForChild("SecureSearch"))

--// Player
local Player = game.Players.LocalPlayer
local Char = Player.Character or Player.CharacterAdded:Wait()
local Hum = Char:WaitForChild("Humanoid")
local Camera = workspace.CurrentCamera

--// UI
local PlayerGui = Player:WaitForChild("PlayerGui")
local MobileGui = PlayerGui:WaitForChild("MobileGui"):WaitForChild("MainFrame")
local MainFrame = script.Parent
local StaminaBar = MainFrame.StaminaFrame
local Vignette = MainFrame.Vignette
local RunButton = MobileGui:WaitForChild("RunButton")
local PantingSound = MainFrame.PantingSound
local SPRINT_LABEL_TEXT_SIZE = 18

--// Values
local DefaultFov = GameConfig.PlayerDefaultFov
local RunFov = GameConfig.PlayerRunFov
local MaxStamina = 100
local StaminaLoss = 0.8
local RegainStamina = 3.25
local PassIncrease = 0.20 -- 20% bonus
local Stamina = MaxStamina
local CanRun = true
local Running = Player:WaitForChild("PlayerValues"):WaitForChild("Running")
local Crouching = Player:WaitForChild("PlayerValues"):WaitForChild("Crouching")
local PlayerOnCutscene = Player:WaitForChild("PlayerValues"):WaitForChild("OnCutscene")
local PlayerOnInspect = Player:WaitForChild("PlayerValues"):WaitForChild("OnInspect")
local PlayerOnChase = Player:WaitForChild("PlayerValues"):WaitForChild("OnChase")
local onChase = false
local ownPass = false

local function createSprintLabel()
	StaminaBar.ClipsDescendants = false

	local oldLabel = StaminaBar:FindFirstChild("SprintLabel")
	if oldLabel then
		oldLabel:Destroy()
	end

	local existingLabel = MainFrame:FindFirstChild("SprintLabel")
	if existingLabel and existingLabel:IsA("TextLabel") then
		return existingLabel
	end

	local inventoryGui = PlayerGui:FindFirstChild("InventoryGui") or PlayerGui:WaitForChild("InventoryGui", 5)
	local inventoryMain = inventoryGui and inventoryGui:FindFirstChild("MainFrame")
	local dropHint = inventoryMain and inventoryMain:FindFirstChild("DropHint")

	local label = nil
	if dropHint and dropHint:IsA("TextLabel") then
		label = dropHint:Clone()
	else
		label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamSemibold
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		label.TextStrokeTransparency = 0.35
	end

	label.Name = "SprintLabel"
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.AutomaticSize = Enum.AutomaticSize.None
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0.5, 0, 0, -4)
	label.Size = UDim2.new(2, 0, 0, 20)
	label.Text = "Sprint"
	label.TextScaled = false
	label.TextSize = SPRINT_LABEL_TEXT_SIZE
	label.TextTransparency = 1
	label.TextStrokeTransparency = 1
	label.TextWrapped = false
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.Visible = true
	label.ZIndex = StaminaBar.ZIndex + 1
	label.Parent = MainFrame

	return label
end

local SprintLabel = createSprintLabel()
local function updateSprintLabelLayout()
	local mainFramePosition = MainFrame.AbsolutePosition
	local staminaPosition = StaminaBar.AbsolutePosition
	local staminaSize = StaminaBar.AbsoluteSize
	local labelWidth = math.max(staminaSize.X * 2, 160)

	SprintLabel.Size = UDim2.fromOffset(labelWidth, 20)
	SprintLabel.Position = UDim2.fromOffset(
		staminaPosition.X - mainFramePosition.X + (staminaSize.X / 2),
		staminaPosition.Y - mainFramePosition.Y - 4
	)
end

local function tweenStaminaVisibility(visible: boolean)
	updateSprintLabelLayout()
	local tweenInfo = TweenInfo.new(0.15)
	Ts:Create(StaminaBar.UIStroke, tweenInfo, {Transparency = visible and 0.5 or 1}):Play()
	Ts:Create(StaminaBar.Bar, tweenInfo, {BackgroundTransparency = visible and 0.2 or 1}):Play()
	Ts:Create(SprintLabel, tweenInfo, {
		TextTransparency = visible and 0 or 1,
		TextStrokeTransparency = visible and 0.35 or 1,
	}):Play()
end

local function movementLocked(): boolean
	return PlayerOnCutscene.Value or PlayerOnInspect.Value
end

--// GamePass Check
local ExtraSpeedPass = nil
for i, v in pairs(ShopModule.Passes) do
	if v.Name == "Extra Speed" then
		ExtraSpeedPass = v.ID
	end
end
if ExtraSpeedPass then
	pcall(function()
		ownPass = MarketplaceService:UserOwnsGamePassAsync(Player.UserId, ExtraSpeedPass)
	end)
end

--// Helper Functions
local function ChangeSpeed()
	local speed = GameConfig.PlayerRunSpeed
	if ownPass then speed *= (1 + PassIncrease) end
	Hum.WalkSpeed = speed
	return speed
end

local function GetPlrSpeed()
	local speed = GameConfig.PlayerRunSpeed
	if ownPass then speed *= (1 + PassIncrease) end
	return speed
end

local function Run(onlySpeed: boolean)
	if Crouching.Value or movementLocked() then return end
	if onlySpeed then
		ChangeSpeed()
		return
	end
	Ts:Create(Camera, TweenInfo.new(0.5), {FieldOfView = RunFov}):Play()
	ChangeSpeed()
end

local function Normal()
	Ts:Create(Camera, TweenInfo.new(0.5), {FieldOfView = DefaultFov}):Play()
	Hum.WalkSpeed = GameConfig.PlayerDefaultSpeed
end

local function UpdateStaminaUI()
	local ratio = Stamina / MaxStamina
	local red = 1 - ratio
	StaminaBar.Bar.Size = UDim2.new(ratio, 0, 1, 0)
	StaminaBar.Bar.BackgroundColor3 = Color3.fromHSV(1, red, 1)
	StaminaBar.UIStroke.Color = Color3.fromHSV(1, red, 1)
	--[[StaminaBar.Bar.BackgroundTransparency = 0.2 + (0.8 * (1-ratio))
	StaminaBar.UIStroke.Transparency = 0.5 + (0.5 * (1-ratio))
	Vignette.ImageTransparency = 1 - ratio]]
end

local function ApplyChaseSpeed()
	local chaseSpeed = math.max(GameConfig.PlayerChaseSpeed, GameConfig.PlayerRunSpeed)
	if ownPass then chaseSpeed *= (1 + PassIncrease) end
	if not Crouching.Value then
		Hum.WalkSpeed = chaseSpeed
		Ts:Create(Camera, TweenInfo.new(0.5), {FieldOfView = RunFov + 7}):Play()
	else
		Hum.WalkSpeed = GameConfig.PlayerCrouchSpeed
		Ts:Create(Camera, TweenInfo.new(0.3), {FieldOfView = DefaultFov}):Play()
	end
	onChase = true
end

--// PC & Console: hold to sprint
local function startRunning()
	if movementLocked() or Crouching.Value or onChase or not Hum or Hum.Health <= 0 or not CanRun then return end
	PlayerValuesEvent:FireServer("RunningON")
	if Hum.MoveDirection.Magnitude > 0 then
		Run(false)
	else
		Run(true)
	end
end

local function stopRunning()
	if movementLocked() or Crouching.Value or onChase or not Hum or Hum.Health <= 0 then return end
	PlayerValuesEvent:FireServer("RunningOFF")
	Normal()
end

--// Mobile: tap to toggle sprint
local function toggleRun()
	if movementLocked() or Crouching.Value or onChase or not Hum or Hum.Health <= 0 then return end

	if Running.Value then
		PlayerValuesEvent:FireServer("RunningOFF")
		Normal()
		return
	end

	if not CanRun then return end
	PlayerValuesEvent:FireServer("RunningON")
	if Hum.MoveDirection.Magnitude > 0 then
		Run(false)
	else
		Run(true)
	end
end

UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL2 then
		startRunning()
	end
end)

UIS.InputEnded:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL2 then
		stopRunning()
	end
end)

--// Mobile
if UIS.TouchEnabled then
	RunButton.Visible = true
	RunButton.Activated:Connect(toggleRun)
end

Hum.Died:Connect(function()
	PlayerValuesEvent:FireServer("RunningOFF")
	Normal()
end)

local function stopRunningForLock()
	PlayerValuesEvent:FireServer("RunningOFF")
	Normal()
end

PlayerOnCutscene:GetPropertyChangedSignal("Value"):Connect(function()
	if PlayerOnCutscene.Value then
		stopRunningForLock()
	end
end)

PlayerOnInspect:GetPropertyChangedSignal("Value"):Connect(function()
	if PlayerOnInspect.Value then
		stopRunningForLock()
	end
end)

--// Main loop
RunService.RenderStepped:Connect(function(dt)
	local dtMult = dt * 12
	if movementLocked() then
		Hum.WalkSpeed = 0
		tweenStaminaVisibility(false)
		return
	end
	
	if PlayerOnChase.Value then
		ApplyChaseSpeed()
		return
	else
		onChase = false
	end
	
	--//Manage run and stamina
	if Running.Value and not PlayerOnCutscene.Value and not Crouching.Value then
		if Hum.MoveDirection.Magnitude > 0 then
			Run(false)
			tweenStaminaVisibility(true)
			Stamina -= StaminaLoss * dtMult
			if Stamina <= 0 then
				Stamina = 0
				CanRun = false
				PlayerValuesEvent:FireServer("RunningOFF")
				Normal()
				tweenStaminaVisibility(false)
				PantingSound.Volume = 0.2
				PantingSound:Play()
				task.delay(math.random(4,5), function()
					Ts:Create(PantingSound, TweenInfo.new(1), {Volume = 0}):Play()
					CanRun = true
				end)
			end
		else
			-- Regain stamina if idle
			Stamina = math.min(Stamina + RegainStamina * dtMult, MaxStamina)
		end
	else
		-- Regain stamina while not running
		Stamina = math.min(Stamina + RegainStamina * dtMult, MaxStamina)
		if Crouching.Value then
			Hum.WalkSpeed = GameConfig.PlayerCrouchSpeed
		else
			Hum.WalkSpeed = GameConfig.PlayerDefaultSpeed
		end
		Ts:Create(Camera, TweenInfo.new(0.3), {FieldOfView = DefaultFov}):Play()
		tweenStaminaVisibility(false)
	end
	
	UpdateStaminaUI()
end)
