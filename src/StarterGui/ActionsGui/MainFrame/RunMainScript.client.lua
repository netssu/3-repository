--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local MarketPlaceService = game:GetService("MarketplaceService")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local PlayerValuesEvent = Remotes:WaitForChild("PlayerValues")

--//Modules
local ModulesFolder = Rs:WaitForChild("Modules")
local GameConfigModule = require(ModulesFolder:FindFirstChild("GameConfigModule"))
local ShopModule = require(ModulesFolder:FindFirstChild("ShopModule"))

--//Player
local Player = game.Players.LocalPlayer
local Char = Player.Character or Player.CharacterAdded:Wait()
local Hum = Char:WaitForChild("Humanoid") :: Humanoid

--//UI
local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local MobileGui = PlayerGui:WaitForChild("MobileGui"):WaitForChild("MainFrame")
local MainFrame = script.Parent
local Vignette = MainFrame.Vignette
local RunButton = MobileGui:WaitForChild("RunButton") :: ImageButton
local StaminaBar = MainFrame.StaminaFrame
local SPRINT_LABEL_TEXT_SIZE = 18

--//Sound
local PantingSound = MainFrame.PantingSound

--//Modules
local Modules = Rs:WaitForChild("Modules")
local GameConfigModule = require(Modules:WaitForChild("GameConfigModule"))
local SecureSearch = require(Modules:WaitForChild("SecureSearch"))

--//Player
local Player = game.Players.LocalPlayer
--local GameOptions = SecureSearch:GetInstance(Player, "GameOptions")
local PlayerOnCutscene = Player:WaitForChild("PlayerValues"):WaitForChild("OnCutscene") :: BoolValue
local PlayerOnInspect = Player:WaitForChild("PlayerValues"):WaitForChild("OnInspect") :: BoolValue
local PlayerOnChase = Player:WaitForChild("PlayerValues"):WaitForChild("OnChase") :: BoolValue
local Char = Player.Character or Player.CharacterAdded:Wait()
local Hum = Char:WaitForChild("Humanoid") :: Humanoid
local Camera = workspace.CurrentCamera
--local InsterfaceStyle = SecureSearch:GetInstance(GameOptions, "InterfaceStyle")

--//Values
local DefaultFov = GameConfigModule.PlayerDefaultFov
local RunFov = GameConfigModule.PlayerRunFov
local onChase = false

local MaxStamina = 100
local Stamina = MaxStamina
local StaminaLoss = 0.8
local RegainStamina = 3.25
local passIncrease = 0.20 -- 20%

local CanRun = true
local Running = Player:WaitForChild("PlayerValues"):WaitForChild("Running") :: BoolValue
local Crouching = Player:WaitForChild("PlayerValues"):WaitForChild("Crouching") :: BoolValue
local loadedPass = false

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

local ExtraSpeedPass = nil
for i, v in pairs(ShopModule.Passes) do
	if v.Name == "Extra Speed" then
		ExtraSpeedPass = v.ID
	end
end

--//Check for extra speed GamePass
local success, ownPass = pcall(function()
	return MarketPlaceService:UserOwnsGamePassAsync(Player.UserId, ExtraSpeedPass)
end)
if ownPass then
	print(Player.Name.." have speed boost pass!")
end

local function changeToRunSpeed()
	local newSpeed = GameConfigModule.PlayerRunSpeed
	if ownPass then
		newSpeed *= (1 + passIncrease)
	end
	Hum.WalkSpeed = newSpeed
end

local function getPlrSpeed()
	local newSpeed = GameConfigModule.PlayerRunSpeed
	if ownPass then
		newSpeed *= (1 + passIncrease)
	end
	return newSpeed
end

local function Run(OnlySpeed:  boolean)
	if Crouching.Value then return end
	if OnlySpeed then
		changeToRunSpeed()
		return
	end
	Ts:Create(Camera, TweenInfo.new(0.5), {FieldOfView = RunFov}):Play()
	changeToRunSpeed()
end

local function Normal()
	Ts:Create(Camera, TweenInfo.new(0.5), {FieldOfView = DefaultFov}):Play()
	Hum.WalkSpeed = GameConfigModule.PlayerDefaultSpeed
end

--//Mobile Button
if UIS.TouchEnabled then
	RunButton.Visible = true
end

--// PC & Console: hold to sprint
local function startRunning()
	if movementLocked() or Crouching.Value or onChase or not Char or not Hum or Hum.Health <= 0 or not CanRun then return end
	PlayerValuesEvent:FireServer("RunningON")
	if Hum.MoveDirection.Magnitude > 0 then
		Run(false)
	else
		Run(true)
	end
end

local function stopRunning()
	if movementLocked() or Crouching.Value or onChase or not Char or not Hum or Hum.Health <= 0 then return end
	PlayerValuesEvent:FireServer("RunningOFF")
	Normal()
end

--// Mobile: tap to toggle sprint
local function toggleRun()
	if movementLocked() or Crouching.Value or onChase or not Char or not Hum or Hum.Health <= 0 then return end

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

--//PC & Console
UIS.InputBegan:Connect(function(input, gameprocessed)
	if gameprocessed then return end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL2 then
		startRunning()
	end
end)

UIS.InputEnded:Connect(function(input, gameprocessed)
	if gameprocessed then return end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL2 then
		stopRunning()
	end
end)

--//Mobile
RunButton.Activated:Connect(toggleRun)

Hum.Died:Connect(function()
	PlayerValuesEvent:FireServer("RunningOFF")
	Normal()
end)

local function stopRunningForLock()
	PlayerValuesEvent:FireServer("RunningOFF")
	Normal()
end

PlayerOnCutscene:GetPropertyChangedSignal("Value"):Connect(function()
	if PlayerOnCutscene.Value then stopRunningForLock() end
end)
PlayerOnInspect:GetPropertyChangedSignal("Value"):Connect(function()
	if PlayerOnInspect.Value then stopRunningForLock() end
end)

RunService.RenderStepped:Connect(function(dt: number)
	if movementLocked() then
		Hum.WalkSpeed = 0
		tweenStaminaVisibility(false)
		return
	end
	if PlayerOnChase.Value then
		local newSpeed = GameConfigModule.PlayerChaseSpeed
		if GameConfigModule.PlayerRunSpeed > newSpeed then
			newSpeed = GameConfigModule.PlayerRunSpeed
		end
		
		if ownPass then
			newSpeed = newSpeed * (1 + passIncrease)
		end
		
		if not Crouching.Value then
			Hum.WalkSpeed = newSpeed
			Ts:Create(Camera, TweenInfo.new(0.5), {FieldOfView = RunFov + 7}):Play()
		else
			Hum.WalkSpeed = GameConfigModule.PlayerCrouchSpeed
			Ts:Create(Camera, TweenInfo.new(0.3), {FieldOfView = DefaultFov}):Play()
		end
		
		onChase = true
		return
	else
		onChase = false
	end
	
	local dtMult = dt * 12
	if Running.Value and not movementLocked() and not Crouching.Value then
		if Hum.MoveDirection.Magnitude > 0 then
			Ts:Create(Camera, TweenInfo.new(0.5), {FieldOfView = RunFov}):Play()
			
			--//UI tweens
			tweenStaminaVisibility(true)
			
			local plrSpeed = getPlrSpeed()
			if Hum.WalkSpeed ~= plrSpeed then
				changeToRunSpeed()
			end
			
			if Stamina > 0 then
				Stamina -= StaminaLoss * dtMult
				if Stamina <= 0 then
					local TiredDelay = math.random(4, 5)
					
					Normal()
					CanRun = false
					PlayerValuesEvent:FireServer("RunningOFF")
					tweenStaminaVisibility(false)
					
					Stamina = 0
					PantingSound.Volume = 0.2
					PantingSound:Play()
					
					task.wait(TiredDelay)
					
					Ts:Create(PantingSound, TweenInfo.new(1), {Volume = 0}):Play()
					
					task.wait(0.5)
					
					CanRun = true
				end
				
				wait(0.01)
			else
				PlayerValuesEvent:FireServer("RunningOFF")
				Normal()
			end
		else
			Ts:Create(Camera, TweenInfo.new(0.3), {FieldOfView = DefaultFov}):Play()
			
			if Hum.MoveDirection.Magnitude > 0.3 and Stamina < MaxStamina then
				Stamina += (RegainStamina * 0.70) * dtMult
				wait(0.01)
			elseif Stamina < MaxStamina then
				Stamina += RegainStamina * dtMult
				wait(0.01)
			end
		end
	else
		if Hum.MoveDirection.Magnitude > 0.3 and Stamina < MaxStamina then
			Stamina += (RegainStamina * 0.70) * dtMult
			wait(0.01)
		elseif Stamina < MaxStamina then
			Stamina += RegainStamina * dtMult
			wait(0.01)
		end
		
		if Crouching.Value then
			PlayerValuesEvent:FireServer("RunningOFF")
			Hum.WalkSpeed = GameConfigModule.PlayerCrouchSpeed
		elseif not movementLocked() and not Crouching.Value then
			Hum.WalkSpeed = GameConfigModule.PlayerDefaultSpeed
		end
		
		Ts:Create(Camera, TweenInfo.new(0.3), {FieldOfView = DefaultFov}):Play()
		tweenStaminaVisibility(false)
	end
	
	local red = 1 - (Stamina / MaxStamina)
	Ts:Create(StaminaBar.UIStroke, TweenInfo.new(0.07), {Color = Color3.fromHSV(1, red, 1)}):Play()
	Ts:Create(StaminaBar.Bar, TweenInfo.new(0.07), {BackgroundColor3 = Color3.fromHSV(1, red, 1)}):Play()
	Ts:Create(StaminaBar.Bar, TweenInfo.new(0.1), {Size = UDim2.new(Stamina/MaxStamina, 0, 1, 0)}):Play()
	Vignette.ImageTransparency = Stamina / MaxStamina
end)
