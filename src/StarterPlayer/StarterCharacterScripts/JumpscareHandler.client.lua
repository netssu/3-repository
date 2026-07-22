--//Services
local RunService = game:GetService("RunService")
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local JumpscareEvent = Remotes:WaitForChild("Jumpscare")
local ProductJumpscareEvent = Remotes:WaitForChild("ProductJumpscare")

--//Player
local Player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera

--//Assets
local Monsters = Rs:WaitForChild("Monsters")
local DemogorgonMonster = Monsters:WaitForChild("DemogorgonMonster")
local CamRigAnim = DemogorgonMonster:WaitForChild("CamRigWithLetterBox ")

--//Values
local JumpscareConnection: RBXScriptConnection = nil

local function playSound(sound: Sound)
	if not sound or not sound:IsA("Sound") then return end
	local snd = sound:Clone()
	snd.Parent = game:GetService("SoundService")
	snd:Play()
	game.Debris:AddItem(snd, 10)
end

local function hidePlrChar()
	for i, v in Player.Character:GetDescendants() do
		if v:IsA("BasePart") then
			v.Transparency = 1
		end
	end
end

JumpscareEvent.OnClientEvent:Connect(function(Monster: Model, ScreamSound: Sound, CamPart: BasePart, JumpscareAnim: Animation, IntenseSound: Sound)
	if (JumpscareConnection) then
		JumpscareConnection:Disconnect()
	end
	
	JumpscareConnection = RunService.RenderStepped:Connect(function()
		Camera.CameraType = Enum.CameraType.Scriptable
		if CamPart then
			Camera.CFrame = CamPart.CFrame
		end
	end)
	
	local Humanoid = Monster:FindFirstChildWhichIsA("Humanoid") :: Humanoid
	local Animator = Humanoid:FindFirstChildWhichIsA("Animator") :: Animator
	local LoadedAnim = Animator:LoadAnimation(JumpscareAnim)
	
	for i, v in Animator:GetPlayingAnimationTracks() do
		v:Stop()
	end
	
	local CamJumpscare = nil
	
	if Monster.Name == "Demogorgon" or Monster.Name == "Demogorgon_Chase" then
		local camRig = CamRigAnim:Clone()
		camRig.Parent = workspace
		
		camRig:PivotTo(
			Monster:GetPivot() * CFrame.Angles(math.rad(-12), 0, 0)
		)
		
		CamJumpscare = camRig.AnimationController.Animator:LoadAnimation(camRig.CamJumpscare)
		game.Debris:AddItem(camRig, 10)
		
		if JumpscareConnection then
			JumpscareConnection:Disconnect()
			JumpscareConnection = nil
		end
		
		local camBone = camRig.CameraPart.camera
		local camPart = camRig.CameraPart
		
		-- Offset relative to camera orientation
		local CAMERA_OFFSET = CFrame.new(0, -4, 9.1) --CFrame.new(0, -4, 9.1) -- wait 0.7
		
		JumpscareConnection = RunService.RenderStepped:Connect(function()
			Camera.CameraType = Enum.CameraType.Scriptable
			if Monster and camRig then
				camRig:PivotTo(
					Monster:GetPivot() * CFrame.Angles(math.rad(-12), 0, 0)
				)
			end
			
			if camRig and camBone and camPart then
				local boneWorld = camPart.CFrame * camBone.Transform
				Camera.CFrame = boneWorld * CAMERA_OFFSET
			end
		end)
	end
	
	hidePlrChar()
	
	LoadedAnim.Priority = Enum.AnimationPriority.Action4
	LoadedAnim:Play() -- play animation on monster model
	if CamJumpscare then
		task.delay(0.8, function()
			CamJumpscare:Play() -- play animation on camrig
		end)
	end
	
	playSound(IntenseSound)
	
	LoadedAnim.KeyframeReached:Connect(function(keyName)
		if keyName == "SCREAM" then
			playSound(ScreamSound)
		end
	end)
	
	LoadedAnim.Stopped:Once(function()
		if (JumpscareConnection) then
			JumpscareConnection:Disconnect()
		end
		task.wait()
		Camera.CameraType = Enum.CameraType.Custom
	end)
end)

local onProductJumpscare = false

ProductJumpscareEvent.OnClientEvent:Connect(function(...)
	if onProductJumpscare then return end
	onProductJumpscare = true
	
	local charModel = select(1, ...)
	local ScreamSound = select(2, ...)
	local CamPart = select(3, ...)
	local JumpscareAnimID = select(4, ...)
	local HitSound = select(5, ...)
	
	if JumpscareConnection then
		JumpscareConnection:Disconnect()
	end
	
	JumpscareConnection = RunService.RenderStepped:Connect(function()
		Camera.CameraType = Enum.CameraType.Scriptable
		if CamPart then
			Camera.CFrame = CamPart.CFrame
		end
	end)
	
	local Humanoid = charModel:FindFirstChildWhichIsA("Humanoid") :: Humanoid
	local Animator = Humanoid:FindFirstChildWhichIsA("Animator") :: Animator
	
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://"..JumpscareAnimID
	
	local LoadedAnim = Animator:LoadAnimation(animation)
	
	for i, v in Animator:GetPlayingAnimationTracks() do
		v:Stop()
	end
	
	LoadedAnim:Play()
	
	LoadedAnim.KeyframeReached:Connect(function(keyName)
		if keyName == "SCREAM" then
			playSound(ScreamSound)
		elseif keyName == "HIT" then
			playSound(HitSound)
		end
	end)
	
	LoadedAnim.Stopped:Once(function()
		if (JumpscareConnection) then
			JumpscareConnection:Disconnect()
		end
		Camera.CameraType = Enum.CameraType.Custom
		animation:Destroy()
		onProductJumpscare = false
	end)
end)