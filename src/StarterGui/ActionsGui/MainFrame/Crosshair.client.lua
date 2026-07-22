--//Services
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

--//Player
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local PlayerValues = Player:WaitForChild("PlayerValues")
local Mouse = Player:GetMouse()

--//UI
local MainFrame = script.Parent
local LOCKED_CURSOR_ICON = "rbxasset://textures/MouseLockedCursor.png"
local UI_CURSOR_ICON = "rbxasset://textures/Cursors/KeyboardMouse/ArrowFarCursor.png"

local oldCrosshair = MainFrame:FindFirstChild("CustomCrosshair")
if oldCrosshair then
	oldCrosshair:Destroy()
end

local crosshair = Instance.new("Frame")
crosshair.Name = "CustomCrosshair"
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
crosshair.BackgroundTransparency = 0
crosshair.BorderSizePixel = 0
crosshair.Position = UDim2.fromScale(0.5, 0.5)
crosshair.Size = UDim2.fromOffset(4, 4)
crosshair.Visible = false
crosshair.ZIndex = 100
crosshair.Parent = MainFrame

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = crosshair

local function isInventoryOpen()
	local inventoryGui = PlayerGui:FindFirstChild("InventoryGui")
	local inventoryMain = inventoryGui and inventoryGui:FindFirstChild("MainFrame")
	local invOpen = inventoryMain and inventoryMain:FindFirstChild("InvOpen")
	return invOpen and invOpen.Value
end

local function isOptionsOpen()
	local optionsGui = PlayerGui:FindFirstChild("OptionsGui")
	local optionsMain = optionsGui and optionsGui:FindFirstChild("MainFrame")
	local optionsFrame = optionsMain and optionsMain:FindFirstChild("OptionsFrame")
	return optionsFrame and optionsFrame:IsA("GuiObject") and optionsFrame.Visible
end

local function isInCutscene()
	local onCutscene = PlayerValues:FindFirstChild("OnCutscene")
	local camera = workspace.CurrentCamera
	return (onCutscene and onCutscene.Value)
		or Player:GetAttribute("CutsceneCameraLocked")
		or (camera and camera.CameraType == Enum.CameraType.Scriptable)
end

local function isInspecting()
	local onInspect = PlayerValues:FindFirstChild("OnInspect")
	return onInspect and onInspect.Value
end

local function isAlive()
	local character = Player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid and humanoid.Health > 0
end

local function shouldShowUiCursor()
	return GuiService.MenuIsOpen
		or isInventoryOpen()
		or isOptionsOpen()
		or isInspecting()
		or UserInputService.MouseBehavior == Enum.MouseBehavior.Default
end

local function shouldShowCustomCrosshair()
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return false
	end

	if isInCutscene() or not isAlive() or shouldShowUiCursor() then
		return false
	end

	return true
end

RunService:UnbindFromRenderStep("CustomDotCrosshair")
RunService:BindToRenderStep("CustomDotCrosshair", Enum.RenderPriority.Last.Value + 1, function()
	local showCrosshair = shouldShowCustomCrosshair()
	crosshair.Visible = showCrosshair

	if showCrosshair then
		UserInputService.MouseIconEnabled = false
	elseif shouldShowUiCursor() and not isInCutscene() and isAlive() then
		if Mouse.Icon == "" or Mouse.Icon == LOCKED_CURSOR_ICON then
			Mouse.Icon = UI_CURSOR_ICON
		end
		UserInputService.MouseIconEnabled = true
	else
		UserInputService.MouseIconEnabled = false
	end
end)
