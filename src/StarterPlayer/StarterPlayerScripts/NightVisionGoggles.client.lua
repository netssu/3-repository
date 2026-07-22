--//Services
local UIS = game:GetService("UserInputService")
local Rs = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Ts = game:GetService("TweenService")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local passesEvent = Remotes:WaitForChild("passesEvent")

--//Modules
local ModulesFolder = Rs:WaitForChild("Modules")
local Utils = ModulesFolder:WaitForChild("Utils")
local SoundPlayer = require(Utils:WaitForChild("SoundPlayer"))

--//Player
local plr = game.Players.LocalPlayer
local plrGui = plr.PlayerGui

--//Sounds
local Effects = SoundService:WaitForChild("Effects")

--//Values
local currentState = false :: boolean
local havePass = false :: boolean
local debounce = true :: boolean
local buttonConnection: RBXScriptConnection = nil

local CCE = Lighting:WaitForChild("ColorCorrection")

local originalExposure = Lighting.ExposureCompensation
local originalCCE_TintColor = CCE.TintColor
local originalCCE_Contrast = CCE.Contrast

local function changeVisionEffect()
	local gogglesGui = plrGui:FindFirstChild("GogglesGui")
	local mobileGui = plrGui:FindFirstChild("MobileGui")
	local gogglesButton = mobileGui and mobileGui:FindFirstChild("MainFrame"):FindFirstChild("ChangeNightGogglesButton")
	local mainFrame = gogglesGui and gogglesGui:FindFirstChild("MainFrame")
	local noiseImage = mainFrame and mainFrame:FindFirstChild("NoiseImage")
	local effectFrame = mainFrame and mainFrame:FindFirstChild("EffectFrame")
	local consoleHint = mainFrame and mainFrame:FindFirstChild("ConsoleHint")
	
	if currentState then -- enable goggles
		if noiseImage then
			noiseImage.BackgroundTransparency = 0
			noiseImage.Visible = true
			SoundPlayer:PlaySound(Effects.GoggleEffect1)
			
			task.wait(0.15)
			
			Ts:Create(noiseImage, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
			task.delay(1, function() noiseImage.Visible = false end)
		end
		
		if CCE then
			CCE.TintColor = Color3.fromRGB(112, 255, 80)
			CCE.Contrast = 0.15
		end
		
		Lighting.ExposureCompensation = 0.8
		
		if effectFrame then
			effectFrame.Visible = true
		end
		if buttonConnection then
			buttonConnection:Disconnect()
			buttonConnection = nil
		end
		if gogglesButton then
			gogglesButton.Visible = true
			
			--//Auto disable the night goggles by pressing the mobile button
			buttonConnection = gogglesButton.MouseButton1Click:Connect(function()
				currentState = false
				debounce = false
				passesEvent:FireServer("NightGoggles", currentState)
				
				changeVisionEffect()
				task.delay(0.8, function()
					debounce = true
				end)
			end)
		end
		if UIS.GamepadEnabled and consoleHint then
			consoleHint.Visible = true
		end
	else -- disable goggles
		task.wait(0.1)
		
		if noiseImage then
			noiseImage.BackgroundTransparency = 0
			noiseImage.Visible = true
			SoundPlayer:PlaySound(Effects.GoggleEffect2)
			
			task.wait(0.15)
			
			Ts:Create(noiseImage, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
			task.delay(1, function() noiseImage.Visible = false end)
		end
		
		if CCE then
			CCE.TintColor = originalCCE_TintColor
			CCE.Contrast = originalCCE_Contrast
		end
		
		Lighting.ExposureCompensation = originalExposure
		
		if effectFrame then
			effectFrame.Visible = false
		end
		if gogglesButton then
			gogglesButton.Visible = false
		end
		if buttonConnection then
			buttonConnection:Disconnect()
			buttonConnection = nil
		end
		if consoleHint then
			consoleHint.Visible = false
		end
	end
end

--//Enable/disable night vision by the tool
passesEvent.OnClientEvent:Connect(function(action: string, state: boolean)
	if typeof(state) ~= "boolean" then return end
	if action == "NightGoggles" then
		if state then
			currentState = true
		else
			currentState = false
		end
		changeVisionEffect()
	end
end)

task.wait(5)

if plr:GetAttribute("Night_Vision") then
	havePass = true
end

if not havePass then return end

UIS.InputBegan:Connect(function(input, gameprocessed)
	if gameprocessed or not havePass then return end
	
	--//Enable/Disable night vision effect
	if (input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.ButtonL3) and debounce then
		debounce = false
		currentState = not currentState
		passesEvent:FireServer("NightGoggles", currentState)
		
		if currentState then
			passesEvent.OnClientEvent:Wait()
		end
		
		changeVisionEffect()
		task.delay(0.8, function()
			debounce = true
		end)
	end
end)