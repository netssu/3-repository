--//Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

--//Player
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local PlayerValues = Player:WaitForChild("PlayerValues")

--//UI
local MainFrame = script.Parent

local HINTS = {
	"Press [R] to open your Backpack.",
	"Hold [Shift] to Sprint.",
}
local HINT_TEXT_SIZE = 18

local oldHints = MainFrame:FindFirstChild("ControlHints")
if oldHints then
	oldHints:Destroy()
end

local hintsFrame = Instance.new("Frame")
hintsFrame.Name = "ControlHints"
hintsFrame.AnchorPoint = Vector2.new(1, 1)
hintsFrame.BackgroundTransparency = 1
hintsFrame.BorderSizePixel = 0
hintsFrame.Position = UDim2.new(1, -76, 1, -54)
hintsFrame.Size = UDim2.fromOffset(420, 42)
hintsFrame.Visible = false
hintsFrame.Parent = MainFrame

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
layout.Padding = UDim.new(0, 2)
layout.Parent = hintsFrame

local function waitForDropHint()
	local inventoryGui = PlayerGui:WaitForChild("InventoryGui", 10)
	if not inventoryGui then return nil end

	local inventoryMain = inventoryGui:WaitForChild("MainFrame", 10)
	if not inventoryMain then return nil end

	return inventoryMain:WaitForChild("DropHint", 10)
end

local function createFallbackHint()
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamSemibold
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextStrokeTransparency = 0.35
	label.TextSize = 20
	return label
end

local dropHintTemplate = waitForDropHint()

for index, text in ipairs(HINTS) do
	local hint = nil
	if dropHintTemplate and dropHintTemplate:IsA("GuiObject") then
		hint = dropHintTemplate:Clone()
	else
		hint = createFallbackHint()
	end

	hint.Name = "ControlHint_" .. index
	hint.AnchorPoint = Vector2.new(0, 0)
	hint.AutomaticSize = Enum.AutomaticSize.Y
	hint.LayoutOrder = index
	hint.Position = UDim2.fromScale(0, 0)
	hint.Size = UDim2.new(1, 0, 0, 18)
	hint.Text = text
	hint.TextScaled = false
	hint.TextSize = HINT_TEXT_SIZE
	hint.TextWrapped = false
	hint.TextXAlignment = Enum.TextXAlignment.Right
	hint.Visible = true
	hint.Parent = hintsFrame
end

local function isInventoryOpen()
	local inventoryGui = PlayerGui:FindFirstChild("InventoryGui")
	local inventoryMain = inventoryGui and inventoryGui:FindFirstChild("MainFrame")
	local invOpen = inventoryMain and inventoryMain:FindFirstChild("InvOpen")
	return invOpen and invOpen.Value
end

local function hasVisibleNotification(guiName: string, containerPath: { string })
	local current = PlayerGui:FindFirstChild(guiName)
	if not current then return false end

	for _, childName in ipairs(containerPath) do
		current = current:FindFirstChild(childName)
		if not current then return false end
	end

	if current:IsA("GuiObject") and not current.Visible then
		return false
	end

	for _, child in current:GetChildren() do
		if child:IsA("GuiObject") and child.Visible and not child.Name:match("_Example$") then
			return true
		end
	end

	return false
end

local function hasLargeMessage()
	return hasVisibleNotification("InventoryGui", {"MainFrame", "NotificationFrame"})
		or hasVisibleNotification("InteractGui", {"MainFrame", "NotificationFrame"})
end

local function isOptionsOpen()
	local optionsGui = PlayerGui:FindFirstChild("OptionsGui")
	local optionsMain = optionsGui and optionsGui:FindFirstChild("MainFrame")
	local optionsFrame = optionsMain and optionsMain:FindFirstChild("OptionsFrame")
	return optionsFrame and optionsFrame:IsA("GuiObject") and optionsFrame.Visible
end

local function playerHasControl()
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return false
	end

	if GuiService.MenuIsOpen then
		return false
	end

	if not PlayerValues then
		return false
	end

	local onCutscene = PlayerValues:FindFirstChild("OnCutscene")
	local onInspect = PlayerValues:FindFirstChild("OnInspect")
	if (onCutscene and onCutscene.Value) or (onInspect and onInspect.Value) then
		return false
	end

	local camera = workspace.CurrentCamera
	if Player:GetAttribute("CutsceneCameraLocked") or (camera and camera.CameraType == Enum.CameraType.Scriptable) then
		return false
	end

	local character = Player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	if isInventoryOpen() or isOptionsOpen() or hasLargeMessage() then
		return false
	end

	return true
end

RunService.RenderStepped:Connect(function()
	hintsFrame.Visible = playerHasControl()
end)
