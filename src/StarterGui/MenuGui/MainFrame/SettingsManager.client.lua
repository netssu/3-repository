--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

--//Modules
local ModulesFolder = Rs:WaitForChild("Modules")
local AbbModule = require(ModulesFolder:WaitForChild("AbbreviationModule"))
local FactorUtil = require(ModulesFolder:WaitForChild("FactorUtil"))

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local UpdatePlrSettingsEvent = Remotes:WaitForChild("UpdatePlrSettings")
local PlrLoadedEvent = Remotes:WaitForChild("PlrLoaded")

--//Player
local Plr = game.Players.LocalPlayer
local plrSettings = Plr:WaitForChild("PlrSettings", 10) :: Folder

--//UI
local MainFrame = script.Parent
local SettingsFrame = MainFrame.SettingsFrame
local LoadingFrame = SettingsFrame.LoadingFrame
local SettingsListFrame = SettingsFrame.SettingsList

local Session1 = SettingsListFrame.SessionList1
local Session2 = SettingsListFrame.SessionList2
local Session3 = SettingsListFrame.SessionList3

SettingsFrame.Interactable = false
LoadingFrame.Visible = true

-- General Settings --
local plrTitles = Session1.Setting_PlrTitle
local gameTips = Session1.Setting_GameTips
local toggleCrouch = Session1.Setting_ToggleCrouch

-- Visual Settings --
local contrast = Session2.Setting_Constrast
local brightness = Session2.Setting_Brightness
local globalShadows = Session2.Setting_GlobalShadows
local ColorCorrection = Lighting:WaitForChild("ColorCorrection")

-- Audio Settings --
local masterVolume = Session3.Setting_MasterVolume
local ambientSounds = Session3.Setting_AmbientSounds

--//Sounds
local SoundsFolder = MainFrame.Sounds

--//Values
local draggingConnection: RBXScriptConnection = nil
local currentDragging = nil
local incrementValue = 0.1
local maxBrightness = 1
local minBrightness = 0
local maxContrast = 1
local minContrast = 0

local function updateBoolSetting(setting: Frame, value: boolean)
	local optionBtn = setting.Option_Button
	local optionBtnImage = optionBtn:FindFirstChild("ImageLabel")
	
	if typeof(value) == "boolean" then
		optionBtnImage.Visible = value
	end
end

local function updateVisualSettings()
	local GlobalShadows = plrSettings:WaitForChild("GlobalShadows", 30) :: BoolValue
	local ContrastValue = plrSettings:WaitForChild("Contrast", 30) :: NumberValue
	local BrightnessValue = plrSettings:WaitForChild("Brightness", 30) :: NumberValue
	
	local constrastFactor = FactorUtil.CalcFactor(ContrastValue.Value)
	local brightnessFactor = FactorUtil.CalcFactor(BrightnessValue.Value)
	local contrastIncrement = 0.2 + (ColorCorrection.Contrast * constrastFactor / 1.25)
	local brightnessIncrement = -0.01 + (ColorCorrection.Brightness * brightnessFactor / 1.25)
	
	Lighting.GlobalShadows = GlobalShadows.Value
	ColorCorrection.Contrast = contrastIncrement
	ColorCorrection.Brightness = brightnessIncrement
end

local function updatePlrTitles(state: boolean)
	print("updating plr titles to:", state)
	for _, plr in Players:GetPlayers() do
		local char = plr.Character
		if char then
			local head = char:FindFirstChild("Head")
			if head then
				local plrBillBoard = head:FindFirstChild("BillboardGui")
				local PlrTitleText = nil
				
				if not plrBillBoard then continue end
				
				for _, textLabel in plrBillBoard:GetChildren() do
					if textLabel:IsA("TextLabel") and textLabel:HasTag("PlayerTitle") then
						PlrTitleText = textLabel
						break
					end
				end
				
				if PlrTitleText then
					PlrTitleText.Visible = state
				end
				
				print("updated text?:", plrBillBoard, PlrTitleText)
			end
		end
	end
end

--//General Settings//--
local function setupGeneralSettings()
	local plrTitlesValue = plrSettings:WaitForChild("PlrTitles", 30) :: BoolValue
	local gameTipsValue = plrSettings:WaitForChild("GameTips", 30) :: BoolValue
	local toggleCrouchValue = plrSettings:WaitForChild("ToggleCrouch", 30) :: BoolValue
	
	if plrTitlesValue then
		updateBoolSetting(plrTitles, plrTitlesValue.Value)
		updatePlrTitles(plrTitlesValue.Value)
		
		plrTitlesValue:GetPropertyChangedSignal("Value"):Connect(function()
			updatePlrTitles(plrTitlesValue.Value)
		end)
		
		--// when a player equip / unequip a title
		workspace.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("BillboardGui") then
				local player = Players:GetPlayerFromCharacter(descendant.Parent.Parent)
				if player then
					updatePlrTitles(plrTitlesValue.Value)
				end
			end
		end)
	end
	if gameTipsValue then
		updateBoolSetting(gameTips, gameTipsValue.Value)
	end
	if toggleCrouchValue then
		updateBoolSetting(toggleCrouch, toggleCrouchValue.Value)
	end
end

plrTitles.Option_Button.MouseButton1Click:Connect(function()
	SoundsFolder.ClickSound:Play()
	plrTitles.Option_Button.ImageLabel.Visible = not plrTitles.Option_Button.ImageLabel.Visible
	local value = plrTitles.Option_Button.ImageLabel.Visible
	UpdatePlrSettingsEvent:FireServer(plrTitles.Option_Button.SettingName.Value, value)
end)

gameTips.Option_Button.MouseButton1Click:Connect(function()
	SoundsFolder.ClickSound:Play()
	gameTips.Option_Button.ImageLabel.Visible = not gameTips.Option_Button.ImageLabel.Visible
	local value = gameTips.Option_Button.ImageLabel.Visible
	UpdatePlrSettingsEvent:FireServer(gameTips.Option_Button.SettingName.Value, value)
end)

toggleCrouch.Option_Button.MouseButton1Click:Connect(function()
	SoundsFolder.ClickSound:Play()
	toggleCrouch.Option_Button.ImageLabel.Visible = not toggleCrouch.Option_Button.ImageLabel.Visible
	local value = toggleCrouch.Option_Button.ImageLabel.Visible
	UpdatePlrSettingsEvent:FireServer(toggleCrouch.Option_Button.SettingName.Value, value)
end)

--//Visual Settings//--
local function updateNumberSetting(setting: Frame, value: number)
	local amount = setting:FindFirstChild("amountValue") :: NumberValue
	if typeof(value) == "number" then
		amount.Value = value*10
		setting.AmountText.Text = AbbModule.abbreviate(value)
	end
end

local function setupVisualSettings()
	local plrGlobalShadows = plrSettings:WaitForChild("GlobalShadows", 30) :: BoolValue
	local plrContrast = plrSettings:WaitForChild("Contrast", 30) :: NumberValue
	local plrBrightness = plrSettings:WaitForChild("Brightness", 30) :: NumberValue
	
	if plrGlobalShadows then
		plrGlobalShadows:GetPropertyChangedSignal("Value"):Connect(function()
			updateVisualSettings()
		end)
		updateBoolSetting(globalShadows, plrGlobalShadows.Value)
	end
	if plrContrast then
		plrContrast:GetPropertyChangedSignal("Value"):Connect(function()
			updateVisualSettings()
		end)
		updateNumberSetting(contrast, plrContrast.Value)
	end
	if plrBrightness then
		plrBrightness:GetPropertyChangedSignal("Value"):Connect(function()
			updateVisualSettings()
		end)
		updateNumberSetting(brightness, plrBrightness.Value)
	end
	updateVisualSettings()
end

local function updateConstrastValue(incrementState: boolean)
	if incrementState then
		if contrast.amountValue.Value >= maxContrast * 10 then return end
		contrast.amountValue.Value += incrementValue * 10
	else
		if contrast.amountValue.Value <= minContrast * 10 then return end
		contrast.amountValue.Value -= incrementValue * 10
	end
	UpdatePlrSettingsEvent:FireServer("Contrast", contrast.amountValue.Value/10)
	updateNumberSetting(contrast, contrast.amountValue.Value/10)
end

local function updateBrightnessValue(incrementState: boolean)
	if incrementState then
		if brightness.amountValue.Value >= maxBrightness * 10 then return end
		brightness.amountValue.Value += incrementValue * 10
	else
		if brightness.amountValue.Value <= minBrightness * 10 then return end
		brightness.amountValue.Value -= incrementValue * 10
	end
	UpdatePlrSettingsEvent:FireServer("Brightness", brightness.amountValue.Value/10)
	updateNumberSetting(brightness, brightness.amountValue.Value/10)
end

contrast.highButton.MouseButton1Click:Connect(function()
	SoundsFolder.ClickSound:Play()
	updateConstrastValue(true)
end)

contrast.lowButton.MouseButton1Click:Connect(function()
	SoundsFolder.ClickSound:Play()
	updateConstrastValue(false)
end)

brightness.highButton.MouseButton1Click:Connect(function()
	SoundsFolder.ClickSound:Play()
	updateBrightnessValue(true)
end)

brightness.lowButton.MouseButton1Click:Connect(function()
	SoundsFolder.ClickSound:Play()
	updateBrightnessValue(false)
end)

globalShadows.Option_Button.MouseButton1Click:Connect(function()
	SoundsFolder.ClickSound:Play()
	globalShadows.Option_Button.ImageLabel.Visible = not globalShadows.Option_Button.ImageLabel.Visible
	local value = globalShadows.Option_Button.ImageLabel.Visible
	UpdatePlrSettingsEvent:FireServer(globalShadows.Option_Button.SettingName.Value, value)
end)

local function changeUIButtonAnim(state: boolean, button: TextButton)
	if state then
		Ts:Create(button, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 43, 43)}):Play()
	else
		Ts:Create(button, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
	end
end

-- UI animations --
contrast.highButton.MouseEnter:Connect(function()
	SoundsFolder.InteractSound:Play()
	changeUIButtonAnim(true, contrast.highButton)
end)
contrast.lowButton.MouseEnter:Connect(function()
	SoundsFolder.InteractSound:Play()
	changeUIButtonAnim(true, contrast.lowButton)
end)
contrast.highButton.MouseLeave:Connect(function()
	changeUIButtonAnim(false, contrast.highButton)
end)
contrast.lowButton.MouseLeave:Connect(function()
	changeUIButtonAnim(false, contrast.lowButton)
end)

brightness.highButton.MouseEnter:Connect(function()
	SoundsFolder.InteractSound:Play()
	changeUIButtonAnim(true, brightness.highButton)
end)
brightness.lowButton.MouseEnter:Connect(function()
	SoundsFolder.InteractSound:Play()
	changeUIButtonAnim(true, brightness.lowButton)
end)
brightness.highButton.MouseLeave:Connect(function()
	changeUIButtonAnim(false, brightness.highButton)
end)
brightness.lowButton.MouseLeave:Connect(function()
	changeUIButtonAnim(false, brightness.lowButton)
end)

--//Audio Settings//--
local function setupDragButtons()
	local function updateSetting(setting: Frame, value: number)
		local bar = setting.Bar
		local dragBtn = bar.DragButton
		local amountText = setting.amountText
		amountText.Text = tostring(value)
		dragBtn.Position = UDim2.fromScale(value / 100, 0.5)
	end
	
	local plrMasterVolume = plrSettings:WaitForChild("MasterVolume", 30) :: IntValue
	local plrAmbientSounds = plrSettings:WaitForChild("AmbientSounds", 30) :: IntValue
	if plrMasterVolume then
		updateSetting(masterVolume, plrMasterVolume.Value)
	end
	if plrAmbientSounds then
		updateSetting(ambientSounds, plrAmbientSounds.Value)
	end
end

local function stopDragging()
	if currentDragging then
		local amount = tonumber(currentDragging.Parent.Parent.amountText.Text)
		UpdatePlrSettingsEvent:FireServer(currentDragging.SettingName.Value, amount)
		currentDragging.BackgroundColor3 = Color3.fromRGB(156, 156, 156)
		currentDragging = nil
	end
end

masterVolume.Bar.DragButton.MouseButton1Down:Connect(function()
	SoundsFolder.ClickSound:Play()
	currentDragging = masterVolume.Bar.DragButton
end)

masterVolume.Bar.DragButton.MouseButton1Up:Connect(function()
	stopDragging()
end)

ambientSounds.Bar.DragButton.MouseButton1Down:Connect(function()
	SoundsFolder.ClickSound:Play()
	currentDragging = ambientSounds.Bar.DragButton
end)

ambientSounds.Bar.DragButton.MouseButton1Up:Connect(function()
	stopDragging()
end)

local function moveSlider()
	if currentDragging then
		local mousePos = UIS:GetMouseLocation()
		local relativePos = mousePos - masterVolume.Bar.AbsolutePosition
		local normalizedPos = math.clamp(relativePos.X / masterVolume.Bar.AbsoluteSize.X, 0, 1)
		currentDragging.Parent.Parent.amountText.Text = math.floor(normalizedPos * 100)
		currentDragging.Position = UDim2.new(normalizedPos, 0, 0.5, 0)
		currentDragging.BackgroundColor3 = Color3.fromRGB(255, 49, 49)
	end
end

UIS.InputEnded:Connect(function(input, gameprocessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		stopDragging()
	end
end)

--//Wait for plr settings data to load the UI
PlrLoadedEvent.OnClientEvent:Connect(function(loaded)
	if loaded then
		SettingsFrame.Interactable = true
		LoadingFrame.Visible = false
		
		setupGeneralSettings()
		setupVisualSettings()
		setupDragButtons()
	end
end)

RunService.RenderStepped:Connect(moveSlider)