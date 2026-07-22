--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local UpdatePlrOptions = Remotes:WaitForChild("UpdatePlrOptions")

--//Modules
local ModulesFolder = Rs:WaitForChild("Modules")
local GameConfigModule = require(ModulesFolder:WaitForChild("GameConfigModule"))

--//Player
local Player = game.Players.LocalPlayer
local PlayerValues = Player:WaitForChild("PlayerValues")
local Char = Player.Character or Player.CharacterAdded:Wait()
local Hum = Char:WaitForChild("Humanoid")

--//UI
local MainFrame = script.Parent
local OptionsFrame = MainFrame.OptionsFrame
local ScrollingFrame = OptionsFrame.ScrollingFrame
local ResetFrame = ScrollingFrame.Option_Reset
local CloseFrame = ScrollingFrame.Option_Close
OptionsFrame.Position = UDim2.fromScale(0.318, -1)

--Visual Options--
local InterfaceStyleFrame = ScrollingFrame.Option_Interface
local GraphicsFrame = ScrollingFrame.Option_Graphics
local MotionBlurFrame = ScrollingFrame.Option_MotionBlur
local GameTipsFrame = ScrollingFrame.Option_Tips

--Gameplay Options--
local RunModeFrame = ScrollingFrame.Option_RunMode
local CrouchModeFrame = ScrollingFrame.Option_CrouchMode
local OpenInventoryFrame = ScrollingFrame.Option_OpenInventory
local DropItemFrame = ScrollingFrame.Option_DropItem
local InteractFrame = ScrollingFrame.Option_Interact

--//Values
local DefaultCC = Lighting:WaitForChild("ColorCorrection"):Clone()
local DefaultBlur = Lighting:WaitForChild("Blur"):Clone()
local OptionsState = false
local changingDebounce = true
local chooseKeyBindFocus = nil
local changeOptionDebounce = true
local selectKeyCodeDebounce = true
local ignoreKeyCodes = { -- Key Codes that are unable to use
	Enum.KeyCode.W;
	Enum.KeyCode.A;
	Enum.KeyCode.S;
	Enum.KeyCode.D;
	Enum.KeyCode.Space;
	Enum.KeyCode.Tab;
	Enum.KeyCode.CapsLock;
	Enum.KeyCode.F1;
	Enum.KeyCode.F2;
	Enum.KeyCode.F3;
	Enum.KeyCode.F4;
	Enum.KeyCode.F5;
	Enum.KeyCode.F6;
	Enum.KeyCode.F7;
	Enum.KeyCode.F8;
	Enum.KeyCode.F9;
	Enum.KeyCode.F10;
	Enum.KeyCode.F11;
	Enum.KeyCode.F12;
	Enum.KeyCode.F13;
	Enum.KeyCode.F14;
	Enum.KeyCode.F15;
	Enum.KeyCode.Zero;
	Enum.KeyCode.One;
	Enum.KeyCode.Two;
	Enum.KeyCode.Three;
	Enum.KeyCode.Four;
	Enum.KeyCode.Five;
	Enum.KeyCode.Six;
	Enum.KeyCode.Seven;
	Enum.KeyCode.Eight;
	Enum.KeyCode.Nine;
	Enum.KeyCode.LeftShift;
	Enum.KeyCode.C;
	Enum.KeyCode.Up;
	Enum.KeyCode.Left;
	Enum.KeyCode.Down;
	Enum.KeyCode.Right;
	Enum.KeyCode.ButtonStart;
	Enum.KeyCode.ButtonL3;
	Enum.KeyCode.ButtonB;
	Enum.KeyCode.DPadRight;
	Enum.KeyCode.Unknown;
}

local function UpdateOptions(OptionName: string, newState, newKeyCode)
	UpdatePlrOptions:FireServer(OptionName, newState, newKeyCode)
end

local function GetCurrentOptionState(OptionName: string, device: string)
	local GameOptions = Player:WaitForChild("GameOptions")
	if GameOptions then
		if GameOptions:FindFirstChild(OptionName) then
			return GameOptions[OptionName].Value
		else
			warn(OptionName.. " not found in GameOptions")
		end
	end
end

local function UpdateInteractButton()
	local GameOptions = Player:WaitForChild("GameOptions")
	local InteractButton = GameOptions:WaitForChild("InteractButton")
	local PcButton3 = InteractButton:WaitForChild("PcButton3")
	local ConsoleButton3 = InteractButton:WaitForChild("ConsoleButton3")
	if GameOptions and PcButton3 and ConsoleButton3 then
		for _, v in workspace:GetDescendants() do
			if v:IsA("ProximityPrompt") then
				v.KeyboardKeyCode = Enum.KeyCode[PcButton3.Value]
				v.GamepadKeyCode = Enum.KeyCode[ConsoleButton3.Value]
			end
		end
	end
end

local function UpdateGraphicsMode()
	local GameOptions = Player:WaitForChild("GameOptions")
	local GraphicsMode= GameOptions:WaitForChild("GraphicsMode")
	if GameOptions and GraphicsMode then
		if GraphicsMode.Value then
			Lighting.GlobalShadows = false
		else
			Lighting.GlobalShadows = true
		end
	end
end

local function UpdateGameOptions()
	UpdateGraphicsMode()
	UpdateInteractButton()
end

local function UpdateGui()
	local plrOptions = {}
	local GameOptions = Player:WaitForChild("GameOptions")
	
	if GameOptions then
		for i, v in GameOptions:GetDescendants() do
			if not v:IsA("Folder") then
				plrOptions[v.Name] = v
			end
		end
	end
	
	if plrOptions["InterfaceStyle"] then
		if plrOptions["InterfaceStyle"].Value then
			InterfaceStyleFrame.TextButton.Text = "Pratical"
			InterfaceStyleFrame.TextButton.TextColor3 = Color3.fromRGB(194, 108, 255)
		else
			InterfaceStyleFrame.TextButton.Text = "Realistic"
			InterfaceStyleFrame.TextButton.TextColor3 = Color3.fromRGB(76, 201, 255)
		end
	end
	if plrOptions["GraphicsMode"] then
		if plrOptions["GraphicsMode"].Value then
			GraphicsFrame.TextButton.Text = "Basic"
			GraphicsFrame.TextButton.TextColor3 = Color3.fromRGB(194, 108, 255)
		else
			GraphicsFrame.TextButton.Text = "Realistic"
			GraphicsFrame.TextButton.TextColor3 = Color3.fromRGB(76, 201, 255)
		end
	end
	if plrOptions["MotionBlur"] then
		if plrOptions["MotionBlur"].Value then
			MotionBlurFrame.TextButton.Text = "Enabled"
			MotionBlurFrame.TextButton.TextColor3 = Color3.fromRGB(76, 201, 255)
		else
			MotionBlurFrame.TextButton.Text = "Disabled"
			MotionBlurFrame.TextButton.TextColor3 = Color3.fromRGB(255, 46, 46)
		end
	end
	if plrOptions["GameTips"] then
		if plrOptions["GameTips"].Value then
			GameTipsFrame.TextButton.Text = "Enabled"
			GameTipsFrame.TextButton.TextColor3 = Color3.fromRGB(76, 201, 255)
		else
			GameTipsFrame.TextButton.Text = "Disabled"
			GameTipsFrame.TextButton.TextColor3 = Color3.fromRGB(255, 46, 46)
		end
	end
	if plrOptions["RunMode"] then
		if plrOptions["RunMode"].Value then
			RunModeFrame.TextButton.Text = "Toggle"
		else
			RunModeFrame.TextButton.Text = "Hold"
		end
	end
	if plrOptions["CrouchMode"] then
		if plrOptions["CrouchMode"].Value then
			CrouchModeFrame.TextButton.Text = "Toggle"
		else
			CrouchModeFrame.TextButton.Text = "Hold"
		end
	end
	
	if UIS.TouchEnabled and not UIS.KeyboardEnabled and not UIS.GamepadEnabled then
		OpenInventoryFrame.Visible = false
		DropItemFrame.Visible = false
		InteractFrame.Visible = false
	elseif UIS.KeyboardEnabled then
		--//Open Inventory Button
		if plrOptions["PcButton1"] then
			OpenInventoryFrame.TextButton.Text = plrOptions["PcButton1"].Value
		end
		
		--//Drop Item Button
		if plrOptions["PcButton2"] then
			DropItemFrame.TextButton.Text = plrOptions["PcButton2"].Value
		end
		
		--//Interact Button
		if plrOptions["PcButton3"] then
			InteractFrame.TextButton.Text = plrOptions["PcButton3"].Value
		end
	elseif UIS.GamepadEnabled then
		--//Open Inventory Button
		if plrOptions["ConsoleButton1"] then
			OpenInventoryFrame.TextButton.Text = plrOptions["ConsoleButton1"].Value
		end
		
		--//Drop Item Button
		if plrOptions["ConsoleButton2"] then
			DropItemFrame.TextButton.Text = plrOptions["ConsoleButton2"].Value
		end
		
		--//Interact Button
		if plrOptions["ConsoleButton3"] then
			InteractFrame.TextButton.Text = plrOptions["ConsoleButton3"].Value
		end
	end
end

local function changeOptionsFrame(state: boolean)
	local OnCutscene = PlayerValues:WaitForChild("OnCutscene")
	if OnCutscene.Value then return end
	if not changingDebounce then return end
	changingDebounce = false
	
	if state then
		OptionsFrame.Visible = true
		UpdateGui()
		Ts:Create(Lighting:WaitForChild("ColorCorrection"), TweenInfo.new(0.5), {Saturation = -0.7}):Play()
		Ts:Create(Lighting:WaitForChild("Blur"), TweenInfo.new(0.3), {Size = 20}):Play()
		task.wait(0.2)
		Ts:Create(OptionsFrame, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {Position = UDim2.fromScale(0.318, 0.136)}):Play()
	else
		chooseKeyBindFocus = nil
		ScrollingFrame.Option_OpenInventory.TextButton.TextColor3 = Color3.fromRGB(76, 201, 255)
		ScrollingFrame.Option_DropItem.TextButton.TextColor3 = Color3.fromRGB(76, 201, 255)
		ScrollingFrame.Option_Interact.TextButton.TextColor3 = Color3.fromRGB(76, 201, 255)
		Ts:Create(Lighting:WaitForChild("ColorCorrection"), TweenInfo.new(0.5), {Saturation = DefaultCC.Saturation}):Play()
		Ts:Create(Lighting:WaitForChild("Blur"), TweenInfo.new(0.7), {Size = DefaultBlur.Size}):Play()
		Ts:Create(OptionsFrame, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {Position = UDim2.fromScale(0.318, -1)}):Play()
	end
	
	task.wait(0.55)
	changingDebounce = true
	if not state then OptionsFrame.Visible = false end
end

CloseFrame.CloseButton.MouseButton1Click:Connect(function()
	OptionsState = false
	changeOptionsFrame(false)
end)

UIS.InputBegan:Connect(function(input, gameprocessed)
	if gameprocessed then return end
	
	if table.find(GameConfigModule.OptionsScreenButton, input.KeyCode) then
		if chooseKeyBindFocus and chooseKeyBindFocus.TextButton then
			chooseKeyBindFocus.TextButton.TextColor3 = Color3.fromRGB(76, 201, 255)
		end
		
		chooseKeyBindFocus = nil
		OptionsState = not OptionsState
		changeOptionsFrame(OptionsState)
	elseif chooseKeyBindFocus and selectKeyCodeDebounce then
		if not table.find(ignoreKeyCodes, input.KeyCode) then
			local device = ""
			changeOptionDebounce = false
			selectKeyCodeDebounce = false
			
			if UIS.TouchEnabled then
				device = "MOBILE"
			elseif UIS.KeyboardEnabled then
				device = "PC"
			elseif UIS.GamepadEnabled then
				device = "CONSOLE"
			end
			
			if chooseKeyBindFocus.TextButton then
				chooseKeyBindFocus.TextButton.TextColor3 = Color3.fromRGB(76, 201, 255)
				chooseKeyBindFocus.TextButton.Text = input.KeyCode.Name
			end
			
			if chooseKeyBindFocus == OpenInventoryFrame then
				UpdateOptions("OpenInventory", device, input.KeyCode.Name)
			elseif chooseKeyBindFocus == DropItemFrame then
				UpdateOptions("DropItem", device, input.KeyCode.Name)
			elseif chooseKeyBindFocus == InteractFrame then
				UpdateOptions("InteractButton", device, input.KeyCode.Name)
				task.wait(0.5)
				UpdateInteractButton()
			end
			
			chooseKeyBindFocus = nil
			task.wait()
			changeOptionDebounce = true
			selectKeyCodeDebounce = true
		else
			selectKeyCodeDebounce = false
			changeOptionDebounce = false
			if chooseKeyBindFocus.TextButton then
				local defaultText = chooseKeyBindFocus.TextButton.Text
				chooseKeyBindFocus.TextButton.Text = "Unavailable"
				task.wait(0.5)
				chooseKeyBindFocus.TextButton.Text = defaultText
				chooseKeyBindFocus.TextButton.TextColor3 = Color3.fromRGB(76, 201, 255)
			end
			chooseKeyBindFocus = nil
			changeOptionDebounce = true
			selectKeyCodeDebounce = true
		end
	end
end)

RunService.RenderStepped:Connect(function()
	if OptionsState then
		UIS.MouseBehavior = Enum.MouseBehavior.Default
	end
end)

local function diedSetup()
	Hum.Died:Connect(function()
		Char = Player.Character or Player.CharacterAdded:Wait()
		Hum = Char:WaitForChild("Humanoid")
		
		if OptionsState then
			OptionsState = false
			changeOptionsFrame(false)
		end
		
		diedSetup()
	end)
end

diedSetup()

-----[OPTIONS]-----
--//Interface Style
InterfaceStyleFrame.TextButton.MouseButton1Click:Connect(function()
	if changeOptionDebounce then
		changeOptionDebounce = false
		
		local currentState = GetCurrentOptionState("InterfaceStyle")
		
		if currentState then -- Pratical --> Realistic
			ScrollingFrame.Option_Interface.TextButton.Text = "Realistic"
			ScrollingFrame.Option_Interface.TextButton.TextColor3 = Color3.fromRGB(76, 201, 255)
			UpdateOptions("InterfaceStyle", false)
		else -- Realistic --> Pratical
			ScrollingFrame.Option_Interface.TextButton.Text = "Pratical"
			ScrollingFrame.Option_Interface.TextButton.TextColor3 = Color3.fromRGB(194, 108, 255)
			UpdateOptions("InterfaceStyle", true)
		end
		
		changeOptionDebounce = true
	end
end)

--//Graphics Mode
GraphicsFrame.TextButton.MouseButton1Click:Connect(function()
	if changeOptionDebounce then
		changeOptionDebounce = false
		
		local currentState = GetCurrentOptionState("GraphicsMode")
		
		if currentState then -- Basic --> Realistic
			ScrollingFrame.Option_Graphics.TextButton.Text = "Realistic"
			ScrollingFrame.Option_Graphics.TextButton.TextColor3 = Color3.fromRGB(76, 201, 255)
			UpdateOptions("GraphicsMode", false)
		else -- Realistic --> Basic
			ScrollingFrame.Option_Graphics.TextButton.Text = "Basic"
			ScrollingFrame.Option_Graphics.TextButton.TextColor3 = Color3.fromRGB(194, 108, 255)
			UpdateOptions("GraphicsMode", true)
		end
		
		task.wait(0.5)
		
		UpdateGraphicsMode()
		changeOptionDebounce = true
	end
end)

--//Motion Blur
MotionBlurFrame.TextButton.MouseButton1Click:Connect(function()
	if changeOptionDebounce then
		changeOptionDebounce = false
		
		local currentState = GetCurrentOptionState("MotionBlur")
		
		if currentState then -- Enabled --> Disabled
			MotionBlurFrame.TextButton.Text = "Disabled"
			MotionBlurFrame.TextButton.TextColor3 = Color3.fromRGB(255, 46, 46)
			UpdateOptions("MotionBlur", false)
		else -- Disabled --> Enabled
			MotionBlurFrame.TextButton.Text = "Enabled"
			MotionBlurFrame.TextButton.TextColor3 = Color3.fromRGB(76, 201, 255)
			UpdateOptions("MotionBlur", true)
		end
		
		changeOptionDebounce = true
	end
end)

--//Game Tips
GameTipsFrame.TextButton.MouseButton1Click:Connect(function()
	if changeOptionDebounce then
		changeOptionDebounce = false
		
		local currentState = GetCurrentOptionState("GameTips")
		
		if currentState then -- Enabled --> Disabled
			GameTipsFrame.TextButton.Text = "Disabled"
			GameTipsFrame.TextButton.TextColor3 = Color3.fromRGB(255, 46, 46)
			UpdateOptions("GameTips", false)
		else -- Disabled --> Enabled
			GameTipsFrame.TextButton.Text = "Enabled"
			GameTipsFrame.TextButton.TextColor3 = Color3.fromRGB(76, 201, 255)
			UpdateOptions("GameTips", true)
		end
		
		changeOptionDebounce = true
	end
end)

--//Run Mode
RunModeFrame.TextButton.MouseButton1Click:Connect(function()
	if changeOptionDebounce then
		changeOptionDebounce = false
		
		local currentState = GetCurrentOptionState("RunMode")
		
		if currentState then -- Toggle --> Hold
			RunModeFrame.TextButton.Text = "Hold"
			UpdateOptions("RunMode", false)
		else -- Hold --> Toggle
			RunModeFrame.TextButton.Text = "Toggle"
			UpdateOptions("RunMode", true)
		end
		
		changeOptionDebounce = true
	end
end)

--//Crouch Mode
CrouchModeFrame.TextButton.MouseButton1Click:Connect(function()
	if changeOptionDebounce then
		changeOptionDebounce = false
		
		local currentState = GetCurrentOptionState("CrouchMode")
		
		if currentState then -- Toggle --> Hold
			CrouchModeFrame.TextButton.Text = "Hold"
			UpdateOptions("CrouchMode", false)
		else -- Hold --> Toggle
			CrouchModeFrame.TextButton.Text = "Toggle"
			UpdateOptions("CrouchMode", true)
		end
		
		changeOptionDebounce = true
	end
end)

--//Open Inventory Button
OpenInventoryFrame.TextButton.MouseButton1Click:Connect(function()
	if changeOptionDebounce then
		changeOptionDebounce = false
		
		if not chooseKeyBindFocus then
			chooseKeyBindFocus = OpenInventoryFrame
			OpenInventoryFrame.TextButton.TextColor3 = Color3.fromRGB(255, 46, 46)
			DropItemFrame.TextButton.TextColor3 = Color3.fromRGB(76, 201, 255)
			InteractFrame.TextButton.TextColor3 = Color3.fromRGB(76, 201, 255)
		elseif chooseKeyBindFocus == ScrollingFrame.Option_OpenInventory then
			chooseKeyBindFocus = nil
			OpenInventoryFrame.TextButton.TextColor3 = Color3.fromRGB(76, 201, 255)
		end
		
		changeOptionDebounce = true
	end
end)

--//Drop Item Button
DropItemFrame.TextButton.MouseButton1Click:Connect(function()
	if changeOptionDebounce then
		changeOptionDebounce = false
		
		if not chooseKeyBindFocus then
			chooseKeyBindFocus = DropItemFrame
			OpenInventoryFrame.TextButton.TextColor3 = Color3.fromRGB(76, 201, 255)
			DropItemFrame.TextButton.TextColor3 = Color3.fromRGB(255, 46, 46)
			InteractFrame.TextButton.TextColor3 = Color3.fromRGB(76, 201, 255)
		elseif chooseKeyBindFocus == ScrollingFrame.Option_DropItem then
			chooseKeyBindFocus = nil
			DropItemFrame.TextButton.TextColor3 = Color3.fromRGB(76, 201, 255)
		end
		
		changeOptionDebounce = true
	end
end)

--//Interact Button
InteractFrame.TextButton.MouseButton1Click:Connect(function()
	if changeOptionDebounce then
		changeOptionDebounce = false
		
		if not chooseKeyBindFocus then
			chooseKeyBindFocus = InteractFrame
			OpenInventoryFrame.TextButton.TextColor3 = Color3.fromRGB(76, 201, 255)
			DropItemFrame.TextButton.TextColor3 = Color3.fromRGB(76, 201, 255)
			InteractFrame.TextButton.TextColor3 = Color3.fromRGB(255, 46, 46)
		elseif chooseKeyBindFocus == ScrollingFrame.Option_Interact then
			chooseKeyBindFocus = nil
			InteractFrame.TextButton.TextColor3 = Color3.fromRGB(76, 201, 255)
		end
		
		changeOptionDebounce = true
	end
end)
-----[OPTIONS]-----

task.wait(6)

-----[BUTTONS ANIMATIONS]-----
for i, v in ScrollingFrame:GetChildren() do
	if v:IsA("Frame") then
		if v:FindFirstChildWhichIsA("TextButton") then
			local Button = v:FindFirstChildWhichIsA("TextButton")
			local DefaultSize = Button.Size
			
			Button.MouseEnter:Connect(function()
				--select sound
				Ts:Create(Button, TweenInfo.new(0.2), {Size = UDim2.fromScale(DefaultSize.X.Scale * 1.2, DefaultSize.Y.Scale * 1.1)}):Play()
			end)
			
			v:FindFirstChildWhichIsA("TextButton").MouseLeave:Connect(function()
				Ts:Create(Button, TweenInfo.new(0.2), {Size = DefaultSize}):Play()
			end)
		end
	end
end
-----[BUTTONS ANIMATIONS]-----

UpdateGui()
UpdateGameOptions()