--//Services
local Rs = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Ts = game:GetService("TweenService")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local PlayerValues = Remotes:WaitForChild("PlayerValues")
local ChangeCam = Remotes:WaitForChild("ChangeCam")
local CamAnim = Remotes:WaitForChild("CamAnim")

--//Player
local Player = game.Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera
local Char = Player.Character or Player.CharacterAdded:Wait()
local hum = Char:WaitForChild("Humanoid") :: Humanoid
local PlayerControls = require(Player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()

--//Values
local camConnection : RBXScriptConnection = nil

-- Make all ScreenGuis (except the cutscene gui and Interact gui) to invisible or visible. 
local function changeGuis(state: boolean)
	if state then
		for i, v in script.Parent.Parent.Parent:GetChildren() do
			if v.Name ~= "CutsceneGui" and v.Name ~= "InteractGui" then
				if v:IsA("ScreenGui") then
					v.Enabled = true
				end
			end
		end
	else
		for i, v in script.Parent.Parent.Parent:GetChildren() do
			if v.Name ~= "CutsceneGui" and v.Name ~= "InteractGui" then
				if v:IsA("ScreenGui") then
					v.Enabled = false
				end
			end
		end
	end
end

local function makeCustomCam()
	PlayerControls:Disable()
	PlayerValues:FireServer("CamOFF")
	PlayerValues:FireServer("SafeON")
	PlayerValues:FireServer("InspectON")
	changeGuis(false)
	Player.CameraMode = Enum.CameraMode.Classic
	CurrentCamera.CameraType = Enum.CameraType.Scriptable

	if camConnection then
		camConnection:Disconnect()
	end
end

local function changeCam(state: boolean, camPart: BasePart?, charModel: Model?)
	if state then
		makeCustomCam()
		
		Player.CameraMinZoomDistance = 12
		
		local char = Player.Character or Player.CharacterAdded:Wait()
		local head = char:WaitForChild("Head") :: BasePart
		local partCam = camPart or head
		
		if camPart then
			camPart.Transparency = 1
		end
		
		if charModel then
			for _, v in charModel:GetChildren() do
				if v:IsA("Accessory") then
					v:Destroy()
				end
			end
		end
		
		camConnection = RunService.RenderStepped:Connect(function(dt: number)
			CurrentCamera.CFrame = partCam.CFrame
		end)
	else
		PlayerControls:Enable()
		PlayerValues:FireServer("CamON")
		PlayerValues:FireServer("SafeOFF")
		PlayerValues:FireServer("InspectOFF")
		changeGuis(true)
		if camConnection then
			camConnection:Disconnect()
		end
		Player.CameraMinZoomDistance = 0.5
		CurrentCamera.CameraType = Enum.CameraType.Custom
		Player.CameraMode = Enum.CameraMode.LockFirstPerson
	end
end

local function changeCharVisibility(state: boolean)
	if state then -- visible
		for _, v in Player.Character:GetChildren() do
			if v:IsA("BasePart") then
				if v:GetAttribute("ignore") then
					v:SetAttribute("ignore", nil)
					continue
				end
				v.Transparency = 0
			elseif v:IsA("Accessory") then
				local handle = v:FindFirstChild("Handle") :: BasePart
				if handle then
					handle.Transparency = 0
				end
			end
		end
	else -- invisible
		for _, v in Player.Character:GetChildren() do
			if v:IsA("BasePart") then
				if v.Transparency == 1 then
					v:SetAttribute("ignore", true)
					continue
				end
				v.Transparency = 1
			elseif v:IsA("Accessory") then
				local handle = v:FindFirstChild("Handle") :: BasePart
				if handle then
					handle.Transparency = 1
				end
			end
		end
	end
end

local function animCam(camCF: CFrame)
	if typeof(camCF) ~= "CFrame" then warn("[CamChangeHandler] Incorrect Camera CFrame received to animate.") end
	
	changeCharVisibility(false)
	makeCustomCam()
	
	local tween = Ts:Create(CurrentCamera, TweenInfo.new(0.35, Enum.EasingStyle.Sine), {CFrame = camCF})
	tween:Play()
	tween.Completed:Wait()
	
	camConnection = RunService.RenderStepped:Connect(function(dt: number)
		CurrentCamera.CFrame = camCF
	end)
end

ChangeCam.OnClientEvent:Connect(function(event: boolean, camPartName: string?)
	local camPart = nil
	local charModel = nil
	if camPartName then
		local char = workspace:FindFirstChild(camPartName)
		if char and char:FindFirstChild("Head") then
			charModel = char
			camPart = char:FindFirstChild("Head")
		end
	end
	changeCam(event, camPart, charModel)
end)

CamAnim.OnClientEvent:Connect(function(action: string, newCamCFrame: CFrame)
	if action == "MakeAnim" then
		if newCamCFrame then
			animCam(newCamCFrame)
		end
	elseif action == "NormalCam" then
		changeCharVisibility(true)
		changeCam(false)
	end
end)

--//Player died
Player.CharacterAdded:Connect(function(char)
	Char = char
	hum = char:WaitForChild("Humanoid") :: Humanoid
	changeCam(false)
end)

hum.Died:Connect(function()
	changeCam(false)
end)
