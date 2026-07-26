--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local InspectEvent = Remotes:WaitForChild("Inspect")
local PlayerValues = Remotes:WaitForChild("PlayerValues")

--//Player
local Player = game.Players.LocalPlayer 
local Char = Player.Character or Player.CharacterAdded:Wait()
local Hum = Char:WaitForChild("Humanoid") :: Humanoid
local Camera = workspace.CurrentCamera

--//Modules
local ModulesFolder = Rs:WaitForChild("Modules")
local GameConfigModule = require(ModulesFolder:WaitForChild("GameConfigModule"))

--//UI
local MainFrame = script.Parent
local InspectFrame = MainFrame.InspectFrame
local LeaveButton = InspectFrame.LeaveButton
LeaveButton.Visible = false

--//Sounds
local ClickSound = script:FindFirstChild("ClickSound")
local SelectSound = script:FindFirstChild("SelectSound")

--//Values
local mouseConnection: RBXScriptConnection = nil
local OnInspect = false
local FORCE_INSPECT_CURSOR_ATTRIBUTE = "ForceInspectCursor"

local function changeInspectGui(state: boolean)
	if state then
		LeaveButton.Visible = true
		Ts:Create(LeaveButton, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
		Ts:Create(LeaveButton, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
	else
		LeaveButton.BackgroundTransparency = 1
		LeaveButton.TextTransparency = 1
		LeaveButton.Visible = false
	end
end

local function changeCam(state: boolean)
	if not state then
		PlayerValues:FireServer("CamOFF")
	else
		PlayerValues:FireServer("CamON")
		Player.CameraMode = Enum.CameraMode.LockFirstPerson
	end
end

local function backToNormal()
	changeInspectGui(false)
	Player:SetAttribute(FORCE_INSPECT_CURSOR_ATTRIBUTE, false)
	Player:GetMouse().Icon = GameConfigModule.DefaultMouseIcon
	UIS.MouseIconEnabled = false
	OnInspect = false
	InspectEvent:FireServer("InspectOFF")
	PlayerValues:FireServer("InspectOFF")
	Camera.CameraType = Enum.CameraType.Custom
	changeCam(true)
	if (mouseConnection) then
		mouseConnection:Disconnect()
	end
	UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
end

InspectEvent.OnClientEvent:Connect(function(event, CamPart: BasePart, disableFirstPerson: boolean, forceMouseCursor: boolean)
	if event == "InspectON" and CamPart ~= nil then
		changeInspectGui(true)
		Player:GetMouse().Icon = GameConfigModule.ChangingMouseIcon
		Player:SetAttribute(FORCE_INSPECT_CURSOR_ATTRIBUTE, forceMouseCursor == true)
		UIS.MouseIconEnabled = forceMouseCursor == true
		OnInspect = true
		
		if (mouseConnection) then
			mouseConnection:Disconnect()
		end
		mouseConnection = RunService.RenderStepped:Connect(function()
			UIS.MouseBehavior = Enum.MouseBehavior.Default
		end)
		
		PlayerValues:FireServer("InspectON")
		Camera.CameraType = Enum.CameraType.Scriptable
		Ts:Create(Camera, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {CFrame = CamPart.CFrame}):Play()
		
		if disableFirstPerson then
			changeCam(false)
		end
	elseif event == "InspectOFF" then
		backToNormal()
	end
end)

local function setupWhenDie()
	Hum.Died:Connect(function()
		OnInspect = false
		Player:SetAttribute(FORCE_INSPECT_CURSOR_ATTRIBUTE, false)
		InspectEvent:FireServer("InspectOFF")
		PlayerValues:FireServer("InspectOFF")
		changeInspectGui(false)
		Player:GetMouse().Icon = GameConfigModule.DefaultMouseIcon
		UIS.MouseIconEnabled = false
		Camera.CameraType = Enum.CameraType.Custom
		changeCam(true)
		
		Char = Player.Character or Player.CharacterAdded:Wait()
		Hum = Char:WaitForChild("Humanoid")
		setupWhenDie()
	end)
end

game.Players.PlayerRemoving:Connect(function(Plr)
	if Plr == Player then
		OnInspect = false
		InspectEvent:FireServer("InspectOFF")
		PlayerValues:FireServer("InspectOFF")
	end
end)

setupWhenDie()

LeaveButton.MouseButton1Click:Connect(function()
	ClickSound:Play()
	if OnInspect then
		backToNormal()
	end
end)

LeaveButton.MouseEnter:Connect(function()
	SelectSound:Play()
	Ts:Create(LeaveButton, TweenInfo.new(0.2), {TextColor3 = Color3.new(0.662745, 0.996078, 1)}):Play()
end)

LeaveButton.MouseLeave:Connect(function()
	Ts:Create(LeaveButton, TweenInfo.new(0.15), {TextColor3 = Color3.new(1, 1, 1)}):Play()
end)
