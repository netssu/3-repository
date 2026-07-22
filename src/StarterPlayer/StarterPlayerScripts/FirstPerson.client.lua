--//Services
local Rs = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Ts = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

--//Player
local Plr = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Char = Plr.Character or Plr.CharacterAdded:Wait()
local Hum = Char:WaitForChild("Humanoid") :: Humanoid
local Mouse = Plr:GetMouse()

--//Values
local IsRunning = Plr:WaitForChild("PlayerValues").Running :: BoolValue
local IsCrouching = Plr:WaitForChild("PlayerValues").Crouching :: BoolValue
local CameraConnection: RBXScriptConnection = nil
local DefaultOffSet = Vector3.new(0, 0, -0.7)
local MouseUnlocked = false

local function hasOpenOverlay(): boolean
	if Camera.CameraType == Enum.CameraType.Scriptable
		or Plr:GetAttribute("CutsceneCameraLocked")
		or Plr:WaitForChild("PlayerValues").OnCutscene.Value
		or Plr:WaitForChild("PlayerValues").OnInspect.Value then
		return true
	end

	local PlayerGui = Plr:FindFirstChildOfClass("PlayerGui")
	if not PlayerGui then return true end

	local inventoryGui = PlayerGui:FindFirstChild("InventoryGui")
	local inventoryFrame = inventoryGui and inventoryGui:FindFirstChild("MainFrame")
	local inventoryOpen = inventoryFrame and inventoryFrame:FindFirstChild("InvOpen")
	if inventoryOpen and inventoryOpen:IsA("BoolValue") and inventoryOpen.Value then
		return true
	end

	return false
end

UIS.InputBegan:Connect(function(input)
	if input.KeyCode ~= Enum.KeyCode.V or UIS:GetFocusedTextBox() or hasOpenOverlay() then return end
	MouseUnlocked = not MouseUnlocked
	UIS.MouseIconEnabled = MouseUnlocked
end)

RunService:BindToRenderStep("FirstPersonMouseUnlock", Enum.RenderPriority.Last.Value, function()
	if MouseUnlocked and hasOpenOverlay() then
		MouseUnlocked = false
	end
	if MouseUnlocked then
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		UIS.MouseIconEnabled = true
	end
end)

--//Modules
local ModulesFolder = Rs:WaitForChild("Modules")
local GameConfigModule = require(ModulesFolder:WaitForChild("GameConfigModule"))

--//For testing
if script:FindFirstChild("Enabled").Value then
	Plr.CameraMode = Enum.CameraMode.LockFirstPerson
end

local function setCameraConnection()
	if (CameraConnection) then
		CameraConnection:Disconnect()
	end
	
	Char = Plr.Character or Plr.CharacterAdded:Wait()
	Hum = Char:WaitForChild("Humanoid") :: Humanoid
	Camera.FieldOfView = GameConfigModule.PlayerDefaultFov
	Mouse.Icon = GameConfigModule.DefaultMouseIcon
	
	local Head = Char:WaitForChild("Head")
	
	--//Make the player char visible
	for i, v in pairs(Char:GetChildren()) do
		if v:IsA("BasePart") and v.Name ~= "Head" then
			
			v:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
				v.LocalTransparencyModifier = v.Transparency
			end)
			
			v.LocalTransparencyModifier = v.Transparency
		end
	end
	
	local Offset = DefaultOffSet
	
	if CameraConnection then
		CameraConnection:Disconnect()
	end
	
	CameraConnection = RunService.RenderStepped:Connect(function(delta)
		-- A cutscene switches the camera to Scriptable locally. This check must
		-- happen before PlayerValues.OnCutscene replicates from the server.
		if Camera.CameraType == Enum.CameraType.Scriptable or Plr:GetAttribute("CutsceneCameraLocked") then
			return
		end

		if Plr:WaitForChild("PlayerValues"):WaitForChild("CamState") then
			if not Plr:WaitForChild("PlayerValues"):WaitForChild("CamState").Value then return end
		end
		if Plr:WaitForChild("PlayerValues"):WaitForChild("Crouching") then
			if Plr:WaitForChild("PlayerValues"):WaitForChild("Crouching").Value then return end
		end
		if Plr:WaitForChild("PlayerValues"):WaitForChild("OnCutscene") then
			if Plr:WaitForChild("PlayerValues"):WaitForChild("OnCutscene").Value then return end
		end
		if Plr:WaitForChild("PlayerValues"):WaitForChild("OnInspect").Value then return end
		
		local ray = Ray.new(Head.Position, ((Head.CFrame + Head.CFrame.LookVector * 2) - Head.Position).Position.Unit)
		local ignoreList = Char:GetDescendants()
		
		local hit, pos = game.Workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
		
		--//To avoid camera bugs
		if hit then
			if hit:IsA("BasePart") or hit:Isa("MeshPart") then
				if hit.CanCollide == false then
					Hum.CameraOffset = Offset
					return
				end
			end
			
			local CamOffset = Vector3.new(0, 0, -(Head.Position - pos).magnitude)
			Ts:Create(Hum, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {CameraOffset = CamOffset}):Play()
		else
			if Plr:WaitForChild("PlayerValues"):WaitForChild("Crouching") then
				if Plr:WaitForChild("PlayerValues"):WaitForChild("Crouching").Value then return end
			end
			Ts:Create(Hum, TweenInfo.new(0.15), {CameraOffset = Offset}):Play()
		end
		
		if Hum.MoveDirection.Magnitude > 0 then
			Offset = Vector3.new(0, 0, -1.3)
			if IsRunning.Value and not IsCrouching.Value then
				local sin = math.sin(tick() * 14) * 1.2
				local cos = math.cos(tick() * 12) * 1
				
				Camera.CFrame *= CFrame.Angles(math.rad(sin * 0.09), math.rad(cos * 0.1), math.rad(sin * 0.3))
			else
				local sin = math.sin(tick() * 9) * 0.8
				local cos = math.cos(tick() * 7) * 0.3
				
				Camera.CFrame *= CFrame.Angles(math.rad(sin * 0.07), math.rad(cos * 0.1), math.rad(sin * 0.2))
			end
		else
			Offset = DefaultOffSet
			local sin = math.sin(tick() * 0.5) * 0.1
			local cos = math.cos(tick() * 1) * 0.1
			
			Camera.CFrame *= CFrame.Angles(math.rad(sin * 0.1), math.rad(cos * 0.07), math.rad(sin * 0.1))
		end
	end)
	
	--//Make a infinite loop, so every time the player dies, reload the first person function
	Hum.Died:Connect(function()
		Plr.CharacterAdded:Wait()
		setCameraConnection()
	end)
end

setCameraConnection()
