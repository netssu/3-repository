--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")
local ContentPrivider = game:GetService("ContentProvider")
local SocialService = game:GetService("SocialService")

--//Player
local Player = game.Players.LocalPlayer

--//Sounds
local SoundsFolder = script.Parent:FindFirstChild("Sounds")
local ClickSound = SoundsFolder:FindFirstChild("ClickSound")
local InteractSound = SoundsFolder:FindFirstChild("InteractSound")

--//UI
local MainFrame = script.Parent
local ShopFrame = MainFrame.ShopFrame
local InventoryFrame = MainFrame.InventoryFrame
local BadgesFrame = MainFrame.BadgesFrame
local StatsFrame = MainFrame.StatsFrame
local SpeedrunFrame = MainFrame.SpeedrunFrame
local DailyRewardsFrame = MainFrame:FindFirstChild("DailyRewardsFrame")

local ButtonsFrame = MainFrame.ButtonsFrame
local LButtonsFrame = MainFrame.LButtonsFrame

local OptionsFrame = ShopFrame.OptionsFrame
local ShopUIFrame = ShopFrame.ShopFrame
local CodesFrame = ShopFrame.CodesFrame
local SkinsFrame = ShopFrame.SkinsFrame

--//Values
local ShopState = false
local InventoryState = false
local BadgeState = false
local StatsState = false
local SpeedrunState = false

--//Setup
ContentPrivider:PreloadAsync(MainFrame:GetChildren())
--ShopFrame.Position = UDim2.fromScale(ShopFrame.Position.X.Scale, -0.5)
InventoryFrame.Position = UDim2.fromScale(InventoryFrame.Position.X.Scale, -0.5)
--BadgesFrame.Position = UDim2.fromScale(BadgesFrame.Position.X.Scale, -0.5)
ShopUIFrame.Visible = true
CodesFrame.Visible = true
SkinsFrame.Visible = true

local function changeShopUI(state: boolean)
	if not state then
		ShopState = true
		Ts:Create(ShopFrame, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {Position = UDim2.fromScale(ShopFrame.Position.X.Scale, 0.458)}):Play()
	else
		ShopState = false
		Ts:Create(ShopFrame, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {Position = UDim2.fromScale(ShopFrame.Position.X.Scale, -0.5)}):Play()
	end
end

local function changeInventoryUI(state: boolean)
	if not state then
		InventoryState = true
		Ts:Create(InventoryFrame, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {Position = UDim2.fromScale(InventoryFrame.Position.X.Scale, 0.524)}):Play()
	else
		InventoryState = false
		Ts:Create(InventoryFrame, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {Position = UDim2.fromScale(InventoryFrame.Position.X.Scale, -0.5)}):Play()
	end
end

local function changeBadgeUI(state: boolean)
	if not state then
		BadgeState = true
		Ts:Create(BadgesFrame, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {Position = UDim2.fromScale(BadgesFrame.Position.X.Scale, 0.524)}):Play()
	else
		BadgeState = false
		Ts:Create(BadgesFrame, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {Position = UDim2.fromScale(BadgesFrame.Position.X.Scale, -0.5)}):Play()
	end
end

local function changeStatsUI(state: boolean)
	if not state then
		StatsState = true
		Ts:Create(StatsFrame, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {Position = UDim2.fromScale(StatsFrame.Position.X.Scale, 0.47)}):Play()
	else
		StatsState = false
		Ts:Create(StatsFrame, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {Position = UDim2.fromScale(StatsFrame.Position.X.Scale, -0.5)}):Play()
	end
end

local defaultSpeedrunSizeUI = SpeedrunFrame.Size

local function changeSpeedrunUI(state: boolean)
	if not state then
		SpeedrunState = true
		SpeedrunFrame.Size = UDim2.new(0, 0, 0, 0)
		SpeedrunFrame.Visible = true
		Ts:Create(SpeedrunFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back), {Size = defaultSpeedrunSizeUI}):Play()
	else
		SpeedrunState = false
		local tween = Ts:Create(SpeedrunFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
		tween:Play()
		tween.Completed:Wait()
		SpeedrunFrame.Visible = false
	end
end

local function disableAllUIs()
	--changeShopUI(true)
	changeInventoryUI(true)
	--changeBadgeUI(true)
	--changeStatsUI(true)
	--changeSpeedrunUI(true)
end

--[[
ButtonsFrame.ShopButton.MouseButton1Click:Connect(function()
	ShopFrame.Visible = true
	changeShopUI(ShopState)
	changeInventoryUI(true)
	--changeBadgeUI(true)
	--changeStatsUI(true)
	changeSpeedrunUI(true)
end)
]]

ButtonsFrame.InventoryButton.MouseButton1Click:Connect(function()
	if DailyRewardsFrame then
		DailyRewardsFrame.Visible = false
	end
	InventoryFrame.Visible = true
	changeInventoryUI(InventoryState)
	--changeShopUI(true)
	--changeBadgeUI(true)
	--changeStatsUI(true)
	--changeSpeedrunUI(true)
end)

--[[
ButtonsFrame.BadgesButton.MouseButton1Click:Connect(function()
	BadgesFrame.Visible = true
	changeBadgeUI(BadgeState)
	changeShopUI(true)
	changeInventoryUI(true)
	changeStatsUI(true)
	changeSpeedrunUI(true)
end)
]]

--[[
ButtonsFrame.PlrInfoButton.MouseButton1Click:Connect(function()
	StatsFrame.Visible = true
	--changeStatsUI(StatsState)
	--changeBadgeUI(true)
	changeShopUI(true)
	changeInventoryUI(true)
	changeSpeedrunUI(true)
end)
]]

local function canSendInvite()
	local success, canInvite = pcall(function()
		return SocialService:CanSendGameInviteAsync(Player)
	end)
	return success and canInvite
end

LButtonsFrame.InviteButton.MouseButton1Click:Connect(function()
	local canInvite = canSendInvite()
	if not canInvite then return end
	SocialService:PromptGameInvite(Player)
end)

--[[
StatsFrame.SpeedrunButton.MouseButton1Click:Connect(function()
	ClickSound:Play()
	changeSpeedrunUI(SpeedrunState)
	changeShopUI(true)
	changeInventoryUI(true)
	--changeBadgeUI(true)
	changeStatsUI(true)
end)

SpeedrunFrame.LeaveButton.MouseButton1Click:Connect(function()
	ClickSound:Play()
	changeSpeedrunUI(true)
end)

SpeedrunFrame.LeaveButton.MouseEnter:Connect(function()
	InteractSound:Play()
end)

StatsFrame.SpeedrunButton.MouseEnter:Connect(function()
	InteractSound:Play()
end)

ButtonsFrame.MenuButton.MouseButton1Click:Connect(function()
	disableAllUIs()
end)
]]

--[[
ButtonsFrame.CharactersButton.MouseButton1Click:Connect(function()
	disableAllUIs()
end)
]]

local function changeFrame(newFrame: Instance)
	if newFrame.Name == "ShopFrame" then
		Ts:Create(newFrame, TweenInfo.new(0.2), {Position = UDim2.fromScale(0.021, 0.228)}):Play()
		Ts:Create(CodesFrame, TweenInfo.new(0.2), {Position = UDim2.fromScale(1.1, 0.228)}):Play()
		Ts:Create(SkinsFrame, TweenInfo.new(0.2), {Position = UDim2.fromScale(2.1, 0.228)}):Play()
	elseif newFrame.Name == "CodesFrame" then
		Ts:Create(newFrame, TweenInfo.new(0.2), {Position = UDim2.fromScale(0.021, 0.228)}):Play()
		Ts:Create(ShopUIFrame, TweenInfo.new(0.2), {Position = UDim2.fromScale(-1, 0.228)}):Play()
		Ts:Create(SkinsFrame, TweenInfo.new(0.2), {Position = UDim2.fromScale(1.1, 0.228)}):Play()
	elseif newFrame.Name == "SkinsFrame" then
		Ts:Create(newFrame, TweenInfo.new(0.2), {Position = UDim2.fromScale(0.021, 0.228)}):Play()
		Ts:Create(ShopUIFrame, TweenInfo.new(0.2), {Position = UDim2.fromScale(-2, 0.228)}):Play()
		Ts:Create(CodesFrame, TweenInfo.new(0.2), {Position = UDim2.fromScale(-1, 0.228)}):Play()
	end
end

changeFrame(ShopUIFrame)

local function unselectAll(except: Instance)
	for i, v in OptionsFrame:GetChildren() do
		if v:IsA("ImageLabel") then
			if v ~= except then
				local highlightFrame = v.HighlightFrame :: Frame
				local tween = Ts:Create(highlightFrame, TweenInfo.new(0.2), {Size = UDim2.fromScale(0, 0.05)})
				tween:Play()
				Ts:Create(v, TweenInfo.new(0.2), {Size = UDim2.fromScale(0.33, 0.8)}):Play()
				tween.Completed:Connect(function()
					highlightFrame.Visible = false
				end)
			else
				local highlightFrame = v.HighlightFrame :: Frame
				highlightFrame.Visible = true
				Ts:Create(v, TweenInfo.new(0.2), {Size = UDim2.fromScale(0.33, 1)}):Play()
				Ts:Create(highlightFrame, TweenInfo.new(0.2), {Size = UDim2.fromScale(0.8, 0.05)}):Play()
			end
		end
	end
end

--//Shop Options
OptionsFrame.Shop.MouseButton1Click:Connect(function()
	ClickSound:Play()
	unselectAll(OptionsFrame.Shop)
	changeFrame(ShopUIFrame)
end)

OptionsFrame.Codes.MouseButton1Click:Connect(function()
	ClickSound:Play()
	unselectAll(OptionsFrame.Codes)
	changeFrame(CodesFrame)
end)

OptionsFrame.Skins.MouseButton1Click:Connect(function()
	ClickSound:Play()
	unselectAll(OptionsFrame.Skins)
	changeFrame(SkinsFrame)
end)

--//UI animations | Middle-down buttons
--[[
for i, v in ButtonsFrame:GetChildren() do
	if v:IsA("TextButton") then
		local defaultSize = v.Size
		local icon = v.Icon :: ImageLabel
		v.MouseButton1Click:Connect(function()
			ClickSound:Play()
		end)
		v.MouseEnter:Connect(function()
			InteractSound:Play()
			--Ts:Create(ButtonsFrame.UIListLayout, TweenInfo.new(0.2), {Padding = UDim.new(0, 12)}):Play()
			Ts:Create(v, TweenInfo.new(0.2), {Size = UDim2.fromScale(defaultSize.X.Scale * 1.1, defaultSize.Y.Scale * 1.1)}):Play()
			Ts:Create(icon, TweenInfo.new(0.2), {ImageColor3 = Color3.new(1, 0.188235, 0.188235)}):Play()
		end)
		v.MouseLeave:Connect(function()
			--Ts:Create(ButtonsFrame.UIListLayout, TweenInfo.new(0.2), {Padding = UDim.new(0, 4)}):Play()
			Ts:Create(v, TweenInfo.new(0.2), {Size = UDim2.fromScale(defaultSize.X.Scale, defaultSize.Y.Scale)}):Play()
			Ts:Create(icon, TweenInfo.new(0.2), {ImageColor3 = Color3.new(1, 1, 1)}):Play()
		end)
	end
end

--//UI animations | Left Buttons
for i, v in LButtonsFrame:GetChildren() do
	if v:IsA("TextButton") then
		local defaultSize = v.Size
		local icon = v.Icon :: ImageLabel
		v.MouseButton1Click:Connect(function()
			ClickSound:Play()
		end)
		v.MouseEnter:Connect(function()
			InteractSound:Play()
			Ts:Create(v, TweenInfo.new(0.2), {Size = UDim2.fromScale(defaultSize.X.Scale * 1.1, defaultSize.Y.Scale * 1.1)}):Play()
			Ts:Create(icon, TweenInfo.new(0.2), {ImageColor3 = Color3.new(1, 0.188235, 0.188235)}):Play()
		end)
		v.MouseLeave:Connect(function()
			Ts:Create(v, TweenInfo.new(0.2), {Size = UDim2.fromScale(defaultSize.X.Scale, defaultSize.Y.Scale)}):Play()
			Ts:Create(icon, TweenInfo.new(0.2), {ImageColor3 = Color3.new(1, 1, 1)}):Play()
		end)
	end
end
]]

--[[
for i, v in OptionsFrame:GetChildren() do
	if v:IsA("Frame") then
		local clicker = v.Clicker :: TextButton
		clicker.MouseEnter:Connect(function()
			InteractSound:Play()
			Ts:Create(v.TextLabel, TweenInfo.new(0.2), {TextColor3 = Color3.new(0.690196, 1, 0.972549)}):Play()
		end)
		clicker.MouseLeave:Connect(function()
			Ts:Create(v.TextLabel, TweenInfo.new(0.2), {TextColor3 = Color3.new(1, 1, 1)}):Play()
		end)
	end
end
]]
