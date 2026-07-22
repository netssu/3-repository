--//Services
local Rs = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local Ts = game:GetService("TweenService")

--//Player
local Player = game.Players.LocalPlayer
local PlrSettings = Player:WaitForChild("PlrSettings", 10)
local character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = character:WaitForChild("Humanoid") :: Humanoid
local Animator = Humanoid:WaitForChild("Animator") :: Animator
local HumanoidRootPart = character:WaitForChild("HumanoidRootPart", 5) :: BasePart
local CollisionPart = character:WaitForChild("CollisionPart", 5) :: BasePart
local UpperTorso = character:WaitForChild("UpperTorso", 5) :: BasePart
local CurrentCamera = workspace.CurrentCamera
Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local UpdatePlrOptions = Remotes:WaitForChild("UpdatePlrOptions")
local PlayerValues = Remotes:WaitForChild("PlayerValues")
local PlrLoaded = Remotes:WaitForChild("PlrDataLoaded")
--local Crouching = Player:WaitForChild("PlayerValues"):WaitForChild("Crouching") :: BoolValue

--//Modules
local ModulesFolder = Rs:WaitForChild("Modules")
local GameConfigModule = require(ModulesFolder:WaitForChild("GameConfigModule"))

--//Animations
local AnimationFolder = script:WaitForChild("Animations")
local Animations = {} :: {
	[string]: AnimationTrack
}

--//Values
local UpVector = Vector3.new(0, 1, 0)
local CrouchConnection: RBXScriptConnection = nil
local PlrOnInspect = Player:WaitForChild("PlayerValues"):WaitForChild("OnInspect") :: BoolValue
local PlrOnCutscene = Player:WaitForChild("PlayerValues"):WaitForChild("OnCutscene") :: BoolValue
local States = {
	["Crouching"] = Instance.new("BoolValue")
}

--//UI
local PlayerGui = Player:WaitForChild("PlayerGui")
local MobileGui = PlayerGui:WaitForChild("MobileGui"):WaitForChild("MainFrame")
local CrouchUI = MobileGui:WaitForChild("CrouchButton")

-----//[Settings]//-----
local HoldCrouching = false --If true is necessary to hold the button to crouch (inverse)

local range = 1.5 --Range above player head to be able to uncrouch
local WalkSpeed = GameConfigModule.PlayerDefaultSpeed
local CrouchSpeed = GameConfigModule.PlayerCrouchSpeed

local CameraCrouchPosition = Vector3.new(0, -2, -1.2) --Camera Offset when crouched
local CameraStandPosition = Vector3.new(0, 0, -1) --Camera Offset when standing 

local ChangeFOV = false --If Fov can change when crouched
local CrouchFOV = GameConfigModule.PlayerCrouchedFov --Fov when crouched
local StandFOV = GameConfigModule.PlayerDefaultFov

local CameraCrouchPositionTI = TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local CameraStandPositionTI = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

local FOVCrouchTI = TweenInfo.new(0.25, Enum.EasingStyle.Cubic)
local FOVStandTI = TweenInfo.new(0.25, Enum.EasingStyle.Cubic)

local Keybind = Enum.KeyCode.C  --Button to crouch. (On KeybBoard)
local Keybind2 = Enum.KeyCode.ButtonB --Button to crouch (On GamePad)

local CrouchStatus = "Normal"
-----//[Settings]//-----

PlrLoaded.OnClientEvent:Connect(function(event)
	local CrouchMode = PlrSettings:FindFirstChild("ToggleCrouch") :: BoolValue
	if CrouchMode then
		if CrouchMode.Value then
			HoldCrouching = false
		else
			HoldCrouching = true
		end
	end
end)

UpdatePlrOptions.OnClientEvent:Connect(function()
	local CrouchMode = PlrSettings:WaitForChild("CrouchMode")
	if CrouchMode then
		if CrouchMode.Value then
			HoldCrouching = false
		else
			HoldCrouching = true
		end
	end
end)

for i: number, v: Animation in ipairs(AnimationFolder:GetChildren()) do
	if v:IsA("Animation") then
		Animations[v.Name] = Animator:LoadAnimation(v)
		Animations[v.Name].Priority = Enum.AnimationPriority.Action2
	end
end

function isBelowAnObject(character: Model, range: number): (boolean?)
	local RParams = RaycastParams.new()
	RParams.FilterType = Enum.RaycastFilterType.Exclude
	RParams.IgnoreWater = true
	RParams.RespectCanCollide = true
	RParams.FilterDescendantsInstances = {character}
	
	if not HumanoidRootPart then return end
	
	local result = workspace:Raycast(HumanoidRootPart.Position, UpVector * range, RParams)
	
	if result then
		if result.Instance ~= nil then
			return true
		end
	end
	
	return false
end

function Crouch(ActionName: string, InputState: Enum.UserInputState, InputObject: InputObject): ()
	if not (Humanoid.Health > 0) then return end
	if PlrOnInspect.Value or PlrOnCutscene.Value then return end
	if (ActionName == "CrouchPlayer") then
		if (HoldCrouching) then
			if (InputState == Enum.UserInputState.Begin) then
				CrouchStatus = "Crouched"
				States["Crouching"].Value = true
				PlayerValues:FireServer("CrouchingON")
				
				if (CrouchConnection) then
					CrouchConnection:Disconnect()
				end
				
				CrouchConnection = RunService.Heartbeat:Connect(function(dt: number)
					local ray = Ray.new(character.Head.Position, ((character.Head.CFrame + character.Head.CFrame.LookVector * 2) - character.Head.Position).Position.Unit)
					local ignoreList = character:GetChildren()
					
					local hit, pos = game.Workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
					
					--//To avoid camera bugs
					if hit then
						if hit:IsA("BasePart") or hit:Isa("MeshPart") then
							if hit.CanCollide == false then
								Humanoid.CameraOffset = CameraCrouchPosition
								return
							end
						end
						
						local CamOffSet = Vector3.new(0, -1.9, -(character.Head.Position - pos).magnitude)
						Ts:Create(Humanoid, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {CameraOffset = CamOffSet}):Play()
					else
						Ts:Create(Humanoid, CameraCrouchPositionTI, {CameraOffset = CameraCrouchPosition}):Play()
					end
					
					if (isBelowAnObject(character, range)) and not PlrOnInspect.Value then
						States["Crouching"].Value = true
						PlayerValues:FireServer("CrouchingON")
					end
				end)
			else
				CrouchStatus = "Normal"
				
				if (CrouchConnection) then
					CrouchConnection:Disconnect()
				end
				
				CrouchConnection = RunService.Heartbeat:Connect(function(dt: number)
					if (not isBelowAnObject(character, range)) or PlrOnInspect.Value then
						PlayerValues:FireServer("CrouchingOFF")
						States["Crouching"].Value = false
					end
				end)
			end
		else
			if (InputState == Enum.UserInputState.Begin) then
				if CrouchStatus == "Normal" then
					CrouchStatus = "Crouched"
					States["Crouching"].Value = true
					PlayerValues:FireServer("CrouchingON")
					
					if (CrouchConnection) then
						CrouchConnection:Disconnect()
					end
					
					CrouchConnection = RunService.Heartbeat:Connect(function(dt: number)
						local ray = Ray.new(character.Head.Position, ((character.Head.CFrame + character.Head.CFrame.LookVector * 2) - character.Head.Position).Position.Unit)
						local ignoreList = character:GetChildren()
						
						local hit, pos = game.Workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
						
						--//To avoid camera bugs
						if hit then
							if hit:IsA("BasePart") or hit:Isa("MeshPart") then
								if hit.CanCollide == false then
									Humanoid.CameraOffset = CameraCrouchPosition
									return
								end
							end
							
							local CamOffSet = Vector3.new(0, -1.9, -(character.Head.Position - pos).magnitude)
							Ts:Create(Humanoid, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {CameraOffset = CamOffSet}):Play()
						else
							Ts:Create(Humanoid, CameraCrouchPositionTI, {CameraOffset = CameraCrouchPosition}):Play()
						end
						
						if (isBelowAnObject(character, range)) and not PlrOnInspect.Value then
							States["Crouching"].Value = true
							PlayerValues:FireServer("CrouchingON")
						end
					end)
				else
					CrouchStatus = "Normal"
					
					if (CrouchConnection) then
						CrouchConnection:Disconnect()
					end
					
					CrouchConnection = RunService.Heartbeat:Connect(function(dt: number)
						if (not isBelowAnObject(character, range)) or PlrOnInspect.Value then
							PlayerValues:FireServer("CrouchingOFF")
							States["Crouching"].Value = false
						end
					end)
				end
			end
		end
	end
end

States["Crouching"]:GetPropertyChangedSignal("Value"):Connect(function()
	local Value = States["Crouching"].Value
	
	RunService.Heartbeat:Connect(function(dt: number)
		if (Humanoid.MoveDirection.Magnitude > 0) then
			Animations["Crouch"]:AdjustSpeed(1)
		else
			Animations["Crouch"]:AdjustSpeed(0)
		end
	end)
	
	if (Value) then
		Animations["Crouch"]:Play()
		Humanoid.WalkSpeed = CrouchSpeed
		Humanoid.JumpHeight = 0
		if HumanoidRootPart then
			HumanoidRootPart.CanCollide = false
		end
		if CollisionPart then
			CollisionPart.CanCollide = false
		end
		if UpperTorso then
			UpperTorso.CanCollide = true
		end
		Ts:Create(Humanoid, CameraCrouchPositionTI, {CameraOffset = CameraCrouchPosition}):Play()
		
		if ChangeFOV then
			Ts:Create(CurrentCamera, FOVCrouchTI, {FieldOfView = CrouchFOV}):Play()
		end
	else
		Animations["Crouch"]:Stop()
		Humanoid.WalkSpeed = WalkSpeed
		Humanoid.JumpHeight = GameConfigModule.PlayerDefaultJump
		if HumanoidRootPart then
			HumanoidRootPart.CanCollide = true
		end
		if CollisionPart then
			CollisionPart.CanCollide = true
		end
		Ts:Create(Humanoid, CameraStandPositionTI, {CameraOffset = CameraStandPosition}):Play()
		
		if ChangeFOV then
			Ts:Create(CurrentCamera, FOVStandTI, {FieldOfView = StandFOV}):Play()
		end
	end
end)

--//Disable crouch when on first person animation
PlrOnInspect:GetPropertyChangedSignal("Value"):Connect(function()
	if (PlrOnInspect.Value) then
		States["Crouching"].Value = false
	end
end)

PlrOnCutscene:GetPropertyChangedSignal("Value"):Connect(function()
	if PlrOnCutscene.Value then
		States["Crouching"].Value = false
	end
end)

Humanoid.Died:Connect(function()
	PlayerValues:FireServer("CrouchingOFF")
	if (CrouchConnection) then
		CrouchConnection:Disconnect()
		CrouchConnection = nil
	end
end)

ContextActionService:BindAction("CrouchPlayer", Crouch, false, Keybind, Keybind2)

---------//[MOBILE]//----------
if game.UserInputService.TouchEnabled then
	CrouchUI.Visible = true
end

CrouchUI.Activated:Connect(function(Input, click)
	if HoldCrouching then return end
	if not (Humanoid.Health > 0) then return end
	
	if CrouchStatus == "Normal" then
		CrouchStatus = "Crouched"
		States["Crouching"].Value = true
		PlayerValues:FireServer("CrouchingON")
		
		if (CrouchConnection) then
			CrouchConnection:Disconnect()
		end
		
		CrouchConnection = RunService.Heartbeat:Connect(function(dt: number)
			if not character or not character:FindFirstChild("Head") then return end
			
			local ray = Ray.new(character.Head.Position, ((character.Head.CFrame + character.Head.CFrame.LookVector * 2) - character.Head.Position).Position.Unit)
			local ignoreList = character:GetChildren()
			
			local hit, pos = game.Workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
			
			--//To avoid camera bugs
			if hit then
				if hit:IsA("BasePart") or hit:Isa("MeshPart") then
					if hit.CanCollide == false then
						Humanoid.CameraOffset = CameraCrouchPosition
						return
					end
				end
				
				local CamOffSet = Vector3.new(0, -1.9, -(character.Head.Position - pos).magnitude)
				Ts:Create(Humanoid, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {CameraOffset = CamOffSet}):Play()
			else
				Ts:Create(Humanoid, CameraCrouchPositionTI, {CameraOffset = CameraCrouchPosition}):Play()
			end
			
			if (isBelowAnObject(character, range)) and not PlrOnInspect.Value then
				States["Crouching"].Value = true
				PlayerValues:FireServer("CrouchingON")
			end
		end)
	else
		CrouchStatus = "Normal"
		
		if (CrouchConnection) then
			CrouchConnection:Disconnect()
		end
		
		CrouchConnection = RunService.Heartbeat:Connect(function(dt: number)
			if (not isBelowAnObject(character, range)) or PlrOnInspect.Value then
				PlayerValues:FireServer("CrouchingOFF")
				States["Crouching"].Value = false
			end
		end)
	end
end)

CrouchUI.MouseEnter:Connect(function()
	if not HoldCrouching then return end
	if not (Humanoid.Health > 0) then return end
	
	CrouchStatus = "Crouched"
	States["Crouching"].Value = true
	PlayerValues:FireServer("CrouchingON")
	
	if (CrouchConnection) then
		CrouchConnection:Disconnect()
	end
	
	CrouchConnection = RunService.Heartbeat:Connect(function(dt: number)
		local ray = Ray.new(character.Head.Position, ((character.Head.CFrame + character.Head.CFrame.LookVector * 2) - character.Head.Position).Position.Unit)
		local ignoreList = character:GetChildren()
		
		local hit, pos = game.Workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
		
		--//To avoid camera bugs
		if hit then
			if hit:IsA("BasePart") or hit:Isa("MeshPart") then
				if hit.CanCollide == false then
					Humanoid.CameraOffset = CameraCrouchPosition
					return
				end
			end
			
			local CamOffSet = Vector3.new(0, -1.9, -(character.Head.Position - pos).magnitude)
			Ts:Create(Humanoid, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {CameraOffset = CamOffSet}):Play()
		else
			Ts:Create(Humanoid, CameraCrouchPositionTI, {CameraOffset = CameraCrouchPosition}):Play()
		end
		
		if (isBelowAnObject(character, range)) and not PlrOnInspect.Value then
			States["Crouching"].Value = true
			PlayerValues:FireServer("CrouchingON")
		end
	end)
end)

CrouchUI.MouseLeave:Connect(function(leave)
	if not HoldCrouching then return end
	if not (Humanoid.Health > 0) then return end
	
	CrouchStatus = "Normal"
	
	if (CrouchConnection) then
		CrouchConnection:Disconnect()
	end
	
	CrouchConnection = RunService.Heartbeat:Connect(function(dt: number)
		if (not isBelowAnObject(character, range)) or PlrOnInspect.Value then
			PlayerValues:FireServer("CrouchingOFF")
			States["Crouching"].Value = false
		end
	end)
end)
---------//[MOBILE]//----------
