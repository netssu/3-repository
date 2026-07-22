--//Services
local ContentProvider = game:GetService("ContentProvider")
local Rs = game:FindFirstChild("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Ts = game:GetService("TweenService")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local PlayerValuesEvent = Remotes:WaitForChild("PlayerValues")

--//Modules
local ModulesFolder = Rs:WaitForChild("Modules", 30)
local ShopModule = require(ModulesFolder:WaitForChild("ShopModule"))
local GameConfigModule = require(ModulesFolder:WaitForChild("GameConfigModule"))

--//Player
local Plr = game.Players.LocalPlayer
local Mouse = Plr:GetMouse()
local Char = Plr.Character or Plr.CharacterAdded:Wait()
local Hum = Char:WaitForChild("Humanoid") :: Humanoid
local Animator = Hum:WaitForChild("Animator") :: Animator
local RootPart = Char:WaitForChild("HumanoidRootPart", 10) :: BasePart

--//UI
local MainFrame = script.Parent.MainFrame
local EmoteBG = MainFrame.EmoteBG
local LeaveButton = MainFrame.LeaveButton
local EmotesButton = MainFrame.Parent.Parent:FindFirstChild("MobileGui"):FindFirstChild("MainFrame"):FindFirstChild("EmotesButton")

--//Sounds
local ClickSound = script.Parent.ClickSound
local InteractSound = script.Parent.InteractSound

--//Values
local emotes = {} :: {AnimationTrack}
local mouseConnection: RBXScriptConnection = nil
local playingEmote = false
local canOpen = true
local died = false

local PlrEquipedEmotes = Plr:WaitForChild("OtherValues"):WaitForChild("EquipedEmotes")
local PlayerValues = Plr:WaitForChild("PlayerValues")
local PlrOnChase = PlayerValues:WaitForChild("OnChase")
local PlrOnInspect = PlayerValues:WaitForChild("OnInspect")
local PlrOnCutscene = PlayerValues:WaitForChild("OnCutscene")
local PlrCrouching = PlayerValues:WaitForChild("Crouching")

local function playSound(snd: Sound)
	local sound = snd:Clone()
	sound.Parent = snd.Parent
	sound:Play()
	game.Debris:AddItem(sound, sound.TimeLength + 1)
end

--//Setup
for _, v in pairs(ShopModule.Items.Emotes) do
	for _, emote in PlrEquipedEmotes:GetChildren() do
		if v.Name == emote.Name then
			if v.AnimId ~= nil and v.AnimId ~= 0 then
				local animation = Instance.new("Animation")
				animation.AnimationId = "rbxassetid://"..v.AnimId
				emotes[emote.Value] = Animator:LoadAnimation(animation)
				ContentProvider:PreloadAsync({animation})
				
				--//Update emote wheel
				if EmoteBG:FindFirstChild("EmoteButton_"..emote.Value) then
					local emoteButton = EmoteBG:FindFirstChild("EmoteButton_"..emote.Value)
					emoteButton.Visible = true
					emoteButton.Image = "rbxassetid://"..v.Img
					emoteButton.EmoteName.Text = emote.Name
				end
			else
				emotes[emote.Value] = false
			end
		end
	end
end

local function changeEmoteUI()
	MainFrame.Visible = not MainFrame.Visible
	if MainFrame.Visible then
		if (mouseConnection) then
			mouseConnection:Disconnect()
		end
		Mouse.Icon = GameConfigModule.ChangingMouseIcon
		mouseConnection = RunService.RenderStepped:Connect(function()
			UIS.MouseBehavior = Enum.MouseBehavior.Default
		end)
	else
		if (mouseConnection) then
			mouseConnection:Disconnect()
		end
		Mouse.Icon = GameConfigModule.DefaultMouseIcon
		UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
	end
end

UIS.InputBegan:Connect(function(input, gameprocessed)
	if gameprocessed or died then return end
	if PlrOnChase.Value or PlrOnInspect.Value or PlrOnCutscene.Value then return end
	
	if input.KeyCode == Enum.KeyCode.Z or input.KeyCode == Enum.KeyCode.DPadLeft and canOpen then
		changeEmoteUI()
	end
end)

--//Mobile
EmotesButton.MouseButton1Click:Connect(function()
	if died or not canOpen then return end
	changeEmoteUI()
end)

local function stopAll()
	if died then return end
	if (mouseConnection) then
		mouseConnection:Disconnect()
	end
	--//Stop all emotes
	for i, v in pairs(emotes) do
		if v ~= false then
			v:Stop()
		end
	end
	MainFrame.Visible = false
	playingEmote = false
	Plr.CameraMinZoomDistance = 0.5
	PlayerValuesEvent:FireServer("CamON")
	Mouse.Icon = GameConfigModule.DefaultMouseIcon
	Plr.CameraMode = Enum.CameraMode.LockFirstPerson
end

RunService.RenderStepped:Connect(function()
	if died then return end
	if RootPart then
		local speed = RootPart.AssemblyLinearVelocity.Magnitude
		if speed > 0.1 and playingEmote then
			canOpen = false
			stopAll()
		end
	end
	if PlrOnChase.Value or PlrOnInspect.Value or PlrOnCutscene.Value or PlrCrouching.Value then
		if playingEmote then
			canOpen = false
			stopAll()
		end
	end
	canOpen = true
end)

for _, button in EmoteBG:GetChildren() do
	if button:IsA("ImageButton") then
		local NumberOnName = button.Name:match("%d+")
		local EmoteTrack = emotes[tostring(NumberOnName)]
		if not EmoteTrack then continue end

		button.MouseButton1Click:Connect(function()
			playSound(ClickSound)
			
			--//Stop all emotes
			for i, v in pairs(emotes) do
				if v ~= false then
					v:Stop()
				end
			end
			
			playingEmote = true
			EmoteTrack:Play()
			PlayerValuesEvent:FireServer("CamOFF")
			Plr.CameraMode = Enum.CameraMode.Classic
			Plr.CameraMinZoomDistance = 8

			if (mouseConnection) then
				mouseConnection:Disconnect()
			end
			mouseConnection = RunService.RenderStepped:Connect(function()
				UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
				if playingEmote == false then
					if (mouseConnection) then
						mouseConnection:Disconnect()
					end
				end
			end)
			MainFrame.Visible = false

			task.delay(EmoteTrack.Length, function()
				playingEmote = false
				Plr.CameraMinZoomDistance = 0.5
				PlayerValuesEvent:FireServer("CamON")
				Plr.CameraMode = Enum.CameraMode.LockFirstPerson
			end)
		end)
		button.MouseEnter:Connect(function()
			playSound(InteractSound)
			Ts:Create(button, TweenInfo.new(0.2), {ImageTransparency = 0}):Play()
		end)
		button.MouseLeave:Connect(function()
			Ts:Create(button, TweenInfo.new(0.15), {ImageTransparency = 0.5}):Play()
		end)
	end
end

LeaveButton.MouseButton1Click:Connect(function()
	playSound(ClickSound)
	MainFrame.Visible = false
	if (mouseConnection) then
		mouseConnection:Disconnect()
	end
	UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
end)

LeaveButton.MouseEnter:Connect(function()
	local newSize = UDim2.fromScale(0.96, 0.96)
	Ts:Create(LeaveButton.TextLabel, TweenInfo.new(0.15), {Size = newSize}):Play()
end)

LeaveButton.MouseLeave:Connect(function()
	local defaultSize = UDim2.fromScale(0.85, 0.85)
	Ts:Create(LeaveButton.TextLabel, TweenInfo.new(0.1), {Size = defaultSize}):Play()
end)

--//Unlock mouse
Hum.Died:Connect(function()
	died = true
	if (mouseConnection) then
		mouseConnection:Disconnect()
	end
	--[[task.wait(2) -- moved to SpectateMain
	mouseConnection = RunService.RenderStepped:Connect(function()
		Plr.CameraMode = Enum.CameraMode.Classic
		Plr.CameraMinZoomDistance = 6
	end)]]
end)
