--//Services
local RunService = game:GetService("RunService")
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

--//UI
local MainFrame = script.Parent
local GameTitle = MainFrame.GameTitle
local ShadowFrame = MainFrame.Shadow
local Transition = MainFrame.Transition

local MainButtons = MainFrame.MainButtons
local PlayButton = MainButtons.Play
local UpdatesButton = MainButtons.Updates
local CharactersButton = MainButtons.Characters
local CreditsButton = MainButtons.Credits
local SettingsButton = MainButtons.Settings

local UpdatesFrame = MainFrame.UpdatesFrame
local CharactersFrame = MainFrame.CharactersFrame
local PlayFrame = MainFrame.PlayFrame
local CreditsFrame = MainFrame.CreditsFrame
local SettingsFrame = MainFrame.SettingsFrame

local ButtonsFrame = MainFrame.Parent.InGameFrame.ButtonsFrame
local LButtonsFrame = MainFrame.Parent.InGameFrame.LButtonsFrame
local DailyRewardsFrame = MainFrame.Parent.InGameFrame:FindFirstChild("DailyRewardsFrame")

--//Sounds
local SoundsFolder = MainFrame:FindFirstChild("Sounds")
local InteractSound = SoundsFolder:FindFirstChild("InteractSound")
local ClickSound = SoundsFolder:FindFirstChild("ClickSound")
local TransitionEffect = SoundsFolder:FindFirstChild("TransitionEffect")

--//Player
local Player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = Player:GetMouse()

--[[
repeat task.wait()
	Camera.CameraType = Enum.CameraType.Scriptable
until Camera.CameraType == Enum.CameraType.Scriptable
]]

--//Lobby Stuff
local Map = workspace:WaitForChild("Map", 10)
local LobbyStuff = Map:WaitForChild("LobbyStuff", 10)
local Chapter1_Spawn = LobbyStuff:WaitForChild("Chapter1_Spawn", 10)
local Cam1 = LobbyStuff:WaitForChild("Cam1", 10)
local Cam2 = LobbyStuff:WaitForChild("Cam2", 10)
local Cam3 = LobbyStuff:WaitForChild("Cam3", 10)
local Cam4 = LobbyStuff:WaitForChild("Cam4", 10)
local Cam5 = LobbyStuff:WaitForChild("Cam5", 10)
local Cam6 = LobbyStuff:WaitForChild("Cam6", 10)
local CamPart = Cam1

--//Values
local defaultFov = Camera.FieldOfView
local maxTilt = 20
local buttonsDebounce = true
local camEnabled = false

--//Setup
local function setupButtonsFrames()
	ButtonsFrame.Visible = false
	ButtonsFrame.Position = UDim2.fromScale(0.5, 1.15)
	
	LButtonsFrame.Visible = false
	LButtonsFrame.Position = UDim2.fromScale(-0.057, 0.2)
	
	MainFrame.Parent.InGameFrame.TipText.Visible = false
end

local function CloseDailyRewards()
	if DailyRewardsFrame then
		DailyRewardsFrame.Visible = false
	end
end

local function changeStartFrame(State: boolean)
	if State then
		GameTitle.Visible = true
		MainButtons.Visible = true
		ShadowFrame.Visible = true
	else
		GameTitle.Visible = false
		MainButtons.Visible = false
		ShadowFrame.Visible = false
	end
end

changeStartFrame(false)

MainFrame.Visible = true
Transition.BackgroundTransparency = 0
RunService.Heartbeat:Wait()
Transition.BackgroundTransparency = 1

--//Disable some of default roblox UI
StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

--//Camera lobby Movement
RunService.RenderStepped:Connect(function()
	if not CamPart or not camEnabled then return end
	if not (Camera.CameraType == Enum.CameraType.Scriptable) then Camera.CameraType = Enum.CameraType.Scriptable end
	local newCFrame = CamPart.CFrame * CFrame.Angles(math.rad((((Mouse.Y - Mouse.ViewSizeX / 2) / Mouse.ViewSizeX)) * -maxTilt), math.rad((((Mouse.X - Mouse.ViewSizeX / 2) / Mouse.ViewSizeX)) * -maxTilt), 0)
	Ts:Create(Camera, TweenInfo.new(0.15), {CFrame = newCFrame}):Play()
end)

local function changeTransition(State: boolean)
	if State then
		TransitionEffect:Play()
		Ts:Create(Camera, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {FieldOfView = defaultFov - 20}):Play()
		Ts:Create(Transition, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
	else
		Ts:Create(Camera, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {FieldOfView = defaultFov}):Play()
		Ts:Create(Transition, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
	end
end

local function teleportPlr(state: number)
	RunService.RenderStepped:Wait()
	if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then return end
	if not Player.Character:FindFirstChild("Humanoid") or Player.Character:FindFirstChild("Humanoid").Health <= 0 then return end
	changeTransition(true)
	
	task.wait(0.3)
	
	PlayFrame.Visible = false
	CamPart = Cam1
	camEnabled = false
	Camera.CameraType = Enum.CameraType.Custom
	Camera.CameraSubject = Player.Character:FindFirstChild("Humanoid")
	
	if state == 1 then -- Chapter1
		local randomSpawn = Chapter1_Spawn:GetChildren()[math.random(1, #Chapter1_Spawn:GetChildren())]
		Player.Character.HumanoidRootPart.Anchored = true
		Player.Character.HumanoidRootPart.CFrame = randomSpawn.CFrame
		Player.Character.HumanoidRootPart.Anchored = false
	elseif state == 2 then -- Charpter2
	
	elseif state == 3 then -- Charpter3
	
	end
	
	task.wait(0.2)
	
	changeTransition(false)
	CharactersFrame.Visible = false
	SettingsFrame.Visible = false
	MainFrame.Parent.InGameFrame.TipText.Visible = true
	
	task.wait(0.5)
	
	MainFrame.Visible = false
	
	--task.wait(0.3) -- In game buttons
	
				--[[LButtonsFrame.Visible = true
				RButtonsFrame.Visible = true
				task.wait(0.3)
				Ts:Create(LButtonsFrame, TweenInfo.new(1, Enum.EasingStyle.Sine), {Position = UDim2.fromScale(0.005, LButtonsFrame.Position.Y.Scale)}):Play()
				Ts:Create(RButtonsFrame, TweenInfo.new(1, Enum.EasingStyle.Sine), {Position = UDim2.fromScale(0.95, RButtonsFrame.Position.Y.Scale)}):Play()]]
	
	ButtonsFrame.Visible = true
	LButtonsFrame.Visible = true
	
	Ts:Create(LButtonsFrame, TweenInfo.new(0.7, Enum.EasingStyle.Sine), {Position = UDim2.fromScale(0.007, 0.2)}):Play()
	Ts:Create(ButtonsFrame, TweenInfo.new(0.7, Enum.EasingStyle.Sine), {Position = UDim2.fromScale(0.5, 0.985)}):Play()
end

PlayButton.MouseButton1Click:Connect(function()
	if buttonsDebounce then
		buttonsDebounce = false
		changeTransition(true)
		
		task.wait(0.3)
		
		changeStartFrame(false)
		PlayFrame.Visible = true
		CamPart = Cam2
		
		task.wait(0.2)
		
		changeTransition(false)
		
		task.wait(0.5)
		
		buttonsDebounce = true
	end
end)

UpdatesButton.MouseButton1Click:Connect(function()
	if buttonsDebounce then
		buttonsDebounce = false
		changeTransition(true)
		
		task.wait(0.3)
		
		changeStartFrame(false)
		UpdatesFrame.Visible = true
		CamPart = Cam3
		
		task.wait(0.2)
		
		changeTransition(false)
		
		task.wait(0.5)
		
		buttonsDebounce = true
	end
end)

CharactersButton.MouseButton1Click:Connect(function()
	if buttonsDebounce then
		buttonsDebounce = false
		changeTransition(true)
		
		task.wait(0.3)
		
		changeStartFrame(false)
		CharactersFrame.Visible = true
		CamPart = Cam5
		
		task.wait(0.2)
		
		changeTransition(false)
		
		task.wait(0.5)
		
		buttonsDebounce = true
	end
end)

CreditsButton.MouseButton1Click:Connect(function()
	if buttonsDebounce then
		buttonsDebounce = false
		changeTransition(true)
		
		task.wait(0.3)
		
		changeStartFrame(false)
		CreditsFrame.Visible = true
		CamPart = Cam4
		
		task.wait(0.2)
		
		changeTransition(false)
		
		task.wait(0.5)
		
		buttonsDebounce = true
	end
end)

--[[
SettingsButton.MouseButton1Click:Connect(function()
	if buttonsDebounce then
		buttonsDebounce = false
		changeTransition(true)
		
		task.wait(0.3)
		
		changeStartFrame(false)
		SettingsFrame.Visible = true
		CamPart = Cam6
		
		task.wait(0.2)
		
		changeTransition(false)
		
		task.wait(0.5)
		
		buttonsDebounce = true
	end
end)
]]

LButtonsFrame.SettingsButton.MouseButton1Click:Connect(function()
	if buttonsDebounce then
		buttonsDebounce = false
		CloseDailyRewards()
		MainFrame.Visible = true
		changeTransition(true)
		
		task.wait(0.3)
		
		--changeStartFrame(true)
		--returnToSpawnLocation()
		MainFrame.SettingsFrame.Visible = true
		
		setupButtonsFrames()
		
		Camera.CameraType = Enum.CameraType.Scriptable
		CamPart = Cam6
		camEnabled = true
		
		task.wait(0.2)
		
		changeTransition(false)
		
		task.wait(0.5)
		
		buttonsDebounce = true
	end
end)

--//UI Animations
ShadowFrame.MouseEnter:Connect(function()
	Ts:Create(ShadowFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
end)

ShadowFrame.MouseLeave:Connect(function()
	Ts:Create(ShadowFrame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
end)

--//PlayFrame UI
PlayFrame.Back.MouseEnter:Connect(function()
	InteractSound:Play()
	Ts:Create(PlayFrame.Back, TweenInfo.new(0.1), {Size = UDim2.fromScale(0.183, 0.071)}):Play()
end)

PlayFrame.Back.MouseLeave:Connect(function()
	Ts:Create(PlayFrame.Back, TweenInfo.new(0.1), {Size = UDim2.fromScale(0.173, 0.061)}):Play()
end)

PlayFrame.Back.MouseButton1Click:Connect(function()
	ClickSound:Play()
	if buttonsDebounce then
		buttonsDebounce = false
		changeTransition(true)
		
		task.wait(0.3)
		
		changeStartFrame(true)
		PlayFrame.Visible = false
		CamPart = Cam1
		
		task.wait(0.2)
		
		changeTransition(false)
		
		task.wait(0.5)
		
		buttonsDebounce = true
	end
end)

--//Updates UI
UpdatesFrame.Back.MouseEnter:Connect(function()
	InteractSound:Play()
	Ts:Create(UpdatesFrame.Back, TweenInfo.new(0.1), {Size = UDim2.fromScale(0.183, 0.071)}):Play()
end)

UpdatesFrame.Back.MouseLeave:Connect(function()
	Ts:Create(UpdatesFrame.Back, TweenInfo.new(0.1), {Size = UDim2.fromScale(0.173, 0.061)}):Play()
end)

UpdatesFrame.Back.MouseButton1Click:Connect(function()
	ClickSound:Play()
	if buttonsDebounce then
		buttonsDebounce = false
		changeTransition(true)
		
		task.wait(0.3)
		
		changeStartFrame(true)
		UpdatesFrame.Visible = false
		CamPart = Cam1
		
		task.wait(0.2)
		
		changeTransition(false)
		
		task.wait(0.5)
		
		buttonsDebounce = true
	end
end)

--//Characters UI
--[[
CharactersFrame.Back.MouseEnter:Connect(function()
	InteractSound:Play()
	Ts:Create(CharactersFrame.Back, TweenInfo.new(0.1), {Size = UDim2.fromScale(0.183, 0.071)}):Play()
end)

CharactersFrame.Back.MouseLeave:Connect(function()
	Ts:Create(CharactersFrame.Back, TweenInfo.new(0.1), {Size = UDim2.fromScale(0.173, 0.061)}):Play()
end)
]]

CharactersFrame.Back.MouseButton1Click:Connect(function()
	ClickSound:Play()
	--[[ -- turn back to main menu
	if buttonsDebounce then
		buttonsDebounce = false
		changeTransition(true)
		
		task.wait(0.3)
		
		changeStartFrame(true)
		CharactersFrame.Visible = false
		CamPart = Cam1
		
		task.wait(0.2)
		
		changeTransition(false)
		
		task.wait(0.5)
		
		buttonsDebounce = true
	end
	]]
	
	teleportPlr(0) -- back to default ui
end)

--//Credits UI
CreditsFrame.Back.MouseEnter:Connect(function()
	InteractSound:Play()
	Ts:Create(CreditsFrame.Back, TweenInfo.new(0.1), {Size = UDim2.fromScale(0.183, 0.071)}):Play()
end)

CreditsFrame.Back.MouseLeave:Connect(function()
	Ts:Create(CreditsFrame.Back, TweenInfo.new(0.1), {Size = UDim2.fromScale(0.173, 0.061)}):Play()
end)

CreditsFrame.Back.MouseButton1Click:Connect(function()
	ClickSound:Play()
	if buttonsDebounce then
		buttonsDebounce = false
		changeTransition(true)
		
		task.wait(0.3)
		
		changeStartFrame(true)
		CreditsFrame.Visible = false
		CamPart = Cam1
		
		task.wait(0.2)
		
		changeTransition(false)
		
		task.wait(0.5)
		
		buttonsDebounce = true
	end
end)

--//Settings UI
SettingsFrame.Back.MouseEnter:Connect(function()
	InteractSound:Play()
	Ts:Create(SettingsFrame.Back, TweenInfo.new(0.1), {Size = UDim2.fromScale(0.183, 0.071)}):Play()
end)

SettingsFrame.Back.MouseLeave:Connect(function()
	Ts:Create(SettingsFrame.Back, TweenInfo.new(0.1), {Size = UDim2.fromScale(0.173, 0.061)}):Play()
end)

SettingsFrame.Back.MouseButton1Click:Connect(function()
	ClickSound:Play()
	--[[if buttonsDebounce then
		buttonsDebounce = false
		changeTransition(true)
		
		task.wait(0.3)
		
		changeStartFrame(true)
		SettingsFrame.Visible = false
		CamPart = Cam1
		
		task.wait(0.2)
		
		changeTransition(false)
		
		task.wait(0.5)
		
		buttonsDebounce = true
	end]]
	teleportPlr(0)
end)

local function returnToSpawnLocation()
	if not Player.Character then warn("Can't get back to spawn location, no character found on: ", Player.Name) return end
	Player.Character.HumanoidRootPart.Anchored = true
	Player.Character.HumanoidRootPart.CFrame = workspace.SpawnLocation.CFrame + Vector3.new(0, 2.5, 0)
	Player.Character.HumanoidRootPart.Anchored = false
end

--//Button to get back to the lobby
ButtonsFrame.MenuButton.MouseButton1Click:Connect(function()
	ClickSound:Play()
	if buttonsDebounce then
		buttonsDebounce = false
		CloseDailyRewards()
		MainFrame.Visible = true
		changeTransition(true)
		
		task.wait(0.3)
		
		changeStartFrame(true)
		returnToSpawnLocation()
		
		MainFrame.Parent.Enabled = true
		
		setupButtonsFrames()
		
		Camera.CameraType = Enum.CameraType.Scriptable
		CamPart = Cam1
		camEnabled = true
		
		task.wait(0.2)
		
		changeTransition(false)
		
		task.wait(0.5)
		
		buttonsDebounce = true
	end
end)

ButtonsFrame.CharactersButton.MouseButton1Click:Connect(function()
	ClickSound:Play()
	if buttonsDebounce then
		buttonsDebounce = false
		CloseDailyRewards()
		MainFrame.Visible = true
		changeTransition(true)
		
		task.wait(0.3)
		
		changeStartFrame(false)
		--returnToSpawnLocation()
		CharactersFrame.Visible = true
		
		setupButtonsFrames()
		
		Camera.CameraType = Enum.CameraType.Scriptable
		CamPart = Cam5
		camEnabled = true
		
		task.wait(0.2)
		
		changeTransition(false)
		
		task.wait(0.5)
		
		buttonsDebounce = true
	end
end)

for i, v in MainButtons:GetChildren() do
	if v:IsA("ImageButton") then
		local defaultSize = v.Size
		local interactSize = UDim2.fromScale(defaultSize.X.Scale * 1.25, defaultSize.Y.Scale * 1.2)
		local TextLabel = v:FindFirstChildWhichIsA("TextLabel")
		
		v.MouseEnter:Connect(function()
			Ts:Create(TextLabel, TweenInfo.new(0.1), {TextColor3 = Color3.fromRGB(255, 213, 0)}):Play()
			InteractSound:Play()
			Ts:Create(v, TweenInfo.new(0.1), {Size = interactSize}):Play()
		end)
		
		v.MouseLeave:Connect(function()
			Ts:Create(TextLabel, TweenInfo.new(0.1), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
			Ts:Create(v, TweenInfo.new(0.3), {Size = defaultSize}):Play()
		end)
		
		v.MouseButton1Click:Connect(function()
			ClickSound:Play()
		end)
	end
end

for i, v in PlayFrame.ChapterSelection:GetChildren() do
	if v:IsA("Frame") then
		local defaultSize = v.Size
		local interactSize = UDim2.fromScale(defaultSize.X.Scale * 1.1, defaultSize.Y.Scale * 1.1)
		local Clicker = v:FindFirstChild("Clicker") :: TextButton
		local ChapterImage = v:FindFirstChild("ChapterImage") :: ImageLabel
		local TitleText = v:FindFirstChild("Title") :: TextLabel
		local DescText = v:FindFirstChild("Desc") :: TextLabel
		local UIStroke = v:FindFirstChild("UIStroke")
		
		Clicker.MouseEnter:Connect(function()
			InteractSound:Play()
			Ts:Create(UIStroke, TweenInfo.new(0.3), {Transparency = 0}):Play()
			Ts:Create(TitleText, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
			Ts:Create(DescText, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
			Ts:Create(ChapterImage, TweenInfo.new(0.3), {ImageTransparency = 0}):Play()
			Ts:Create(v, TweenInfo.new(0.1), {Size = interactSize}):Play()
		end)
		
		Clicker.MouseLeave:Connect(function()
			Ts:Create(UIStroke, TweenInfo.new(0.3), {Transparency = 0.5}):Play()
			Ts:Create(TitleText, TweenInfo.new(0.3), {TextTransparency = 0.5}):Play()
			Ts:Create(DescText, TweenInfo.new(0.3), {TextTransparency = 0.5}):Play()
			Ts:Create(ChapterImage, TweenInfo.new(0.3), {ImageTransparency = 0.5}):Play()
			Ts:Create(v, TweenInfo.new(0.4), {Size = defaultSize}):Play()
		end)
		
		--//Function to teleport the player to main lobby
		Clicker.MouseButton1Click:Connect(function()
			ClickSound:Play()
			
			if v:FindFirstChild("Locked") then
				--Chapter locked/not done
				return
			end
			
			if buttonsDebounce then
				buttonsDebounce = false
				
				if v.Name == "Chapter1" then
					teleportPlr(1)
				elseif v.Name == "Chapter2" then
					teleportPlr(2)
				elseif v.Name == "Chapter3" then
					teleportPlr(3)
				end
				
				task.wait(0.5)
				buttonsDebounce = true
			end
		end)
	end
end
