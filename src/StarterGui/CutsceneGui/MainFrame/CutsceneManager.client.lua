--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local PlayerValues = Remotes:WaitForChild("PlayerValues")
local ActiveCutsceneEvent = Remotes:WaitForChild("ActiveCutscene")
local UpdatePlrWinEvent = Remotes:WaitForChild("UpdatePlrWins")
local GameStartedEvent = Remotes:WaitForChild("GameStarted")

--//Player
local Player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlayerModule = require(Player.PlayerScripts:WaitForChild("PlayerModule"))
local PlayerControls = PlayerModule:GetControls()

--//Modules
local ModulesFolder = Rs:WaitForChild("Modules")
local SecureSearch = require(ModulesFolder:WaitForChild("SecureSearch"))

--//UI
local MainFrame = script.Parent
local TransitionFrame = MainFrame.Transition
local Bar1 = MainFrame.Bar1
local Bar2 = MainFrame.Bar2
local dialogText = MainFrame.DialogText
local chaseFrame = MainFrame.ChaseFrame
local shakeText = chaseFrame.ShakeText
local CreditsFrame = MainFrame.CreditsFrame

----//[Cutscene Stuff]//----
local Map = workspace:WaitForChild("Map", 3)
local CutscenesFolder = Map:WaitForChild("Cutscenes", 3)

--//Entrance Cutscene
local StarterCutscene = CutscenesFolder:WaitForChild("StarterCutscene", 3)
--[[local CamModel1 = StarterCutscene:WaitForChild("CamModel")
local CamAnimator = CamModel1:WaitForChild("AnimationController"):WaitForChild("Animator")
local StartCutsceneAnim = StarterCutscene:WaitForChild("StartCutsceneAnim")]]

--//Rocks Cutscene
local RocksCutscene = CutscenesFolder:WaitForChild("RocksCutscene", 3)
local RocksTremorSound = RocksCutscene:WaitForChild("TremorSound")
local RocksCutsceneDebounce = true

--//Flayed Appear Cutscene
local MonsterAppearCutscene = CutscenesFolder:WaitForChild("MonsterAppearCutscene")
local CinematicSound = MonsterAppearCutscene:WaitForChild("CinematicSound")
local DramaticAmbience = MonsterAppearCutscene:WaitForChild("DramaticAmbience2")
local ChaseMusic = MonsterAppearCutscene:WaitForChild("ChaseMusic")
local MonsterAppearModel = MonsterAppearCutscene:WaitForChild("Demogorgon_AppearCutscene")

--//Basement Bars Cutscene
local BasementCutscene = CutscenesFolder:WaitForChild("BasementCutscene")
local GasParticlesFolder = BasementCutscene:WaitForChild("Gas_Particles")
local BarsSound1 = BasementCutscene:WaitForChild("BarsSound1")
local BarsSound2 = BasementCutscene:WaitForChild("BarsSound2")
local ScarySound = BasementCutscene:WaitForChild("ScarySound")

--//Secret Statues Cutscene
local StatuesCutscene = CutscenesFolder:WaitForChild("StatuesCutscene")
local StatueEyes = StatuesCutscene:FindFirstChild("Statue_Eyes")

--//Restore Energy Cutscene
local RestoreEnergyCutscene = CutscenesFolder:WaitForChild("RestoreEnergyCutscene")

--//Flayed Chase Start Cutscene
local MonsterStartChaseCutscene = CutscenesFolder:WaitForChild("MonsterStartChaseCutscene")

--//Flayed Chase Final Cutscene
local MonsterChaseFinalCutscene = CutscenesFolder:WaitForChild("MonsterChaseFinalCutscene")
----//[Cutscene Stuff]//----

--//Values
local StartCutsceneValue = script.Parent.StarterCutsceneValue
local EntranceCutsceneStarted = script.Parent.EntranceCutsceneStarted
local CutsceneConnection : RBXScriptConnection = nil
local CutsceneEnabled = false
local Debounce = true
local CamPart = nil
local textShakeConnection : RBXScriptConnection = nil
local textRandomTexts : RBXScriptConnection = nil
local defaultPos = shakeText.Position
local lastText = nil
local randomChaseTexts = {
	"ESCAPE";
	"DON'T LOOK BACK";
	"RUN";
	"DON'T STOP"
}

--//Modules
local ModulesFolder = Rs:WaitForChild("Modules", 30)
local GameConfigModule = require(ModulesFolder:WaitForChild("GameConfigModule"))
local ObjectivesModule = require(ModulesFolder:WaitForChild("ObjectivesModule"))
local CameraShaker = require(ModulesFolder:WaitForChild("CameraShaker"))

local function SetPlayerControlsEnabled(State: boolean)
	if State then
		PlayerControls:Enable()
	else
		PlayerControls:Disable()
	end
end

local function changeShakeText(state: boolean)
	if state then
		if textShakeConnection then
			textShakeConnection:Disconnect()
			textShakeConnection = nil
		end
		if textRandomTexts then
			textRandomTexts:Disconnect()
			textRandomTexts = nil
		end
		textShakeConnection = RunService.RenderStepped:Connect(function(dt: number)
			shakeText.Rotation = math.random(-10, 10)
			shakeText.Position = defaultPos + UDim2.fromOffset(math.random(-7, 7), math.random(-7, 7))
		end)
		textRandomTexts = coroutine.wrap(function()
			while task.wait(math.random(500, 900)/1000) do
				local randomText = nil
				repeat task.wait()
					randomText = randomChaseTexts[math.random(1, #randomChaseTexts)]
				until randomText ~= lastText
				shakeText.TextLabel.Text = randomText
				lastText = randomText
			end
		end)()
	else
		if textShakeConnection then
			textShakeConnection:Disconnect()
			textShakeConnection = nil
		end
		if textRandomTexts then
			textRandomTexts:Disconnect()
			textRandomTexts = nil
		end
	end
end

local function enableCreditsFrame()
	CreditsFrame.Visible = true
	TransitionFrame.Visible = false
	
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	
	local currentPos = CreditsFrame.TextsFrame.Position.Y.Scale
	while currentPos > -3.46 do
		currentPos -= 0.0018
		CreditsFrame.TextsFrame.Position = UDim2.new(CreditsFrame.TextsFrame.Position.X.Scale, 0, currentPos, 0)
		task.wait()
	end
	task.wait(1)
	CreditsFrame.LobbyButton.Visible = true
end

local function cinematicBars(state: boolean)
	if state then
		Ts:Create(Bar1, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
		Ts:Create(Bar2, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
	else
		Ts:Create(Bar1, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
		Ts:Create(Bar2, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
	end
end

-- Higher number equals more fast transition.
local function makeTransition(Type: number)
	if Type == 1 then --Slow transition
		Ts:Create(TransitionFrame, TweenInfo.new(1), {BackgroundTransparency = 0}):Play()
		task.wait(2)
		Ts:Create(TransitionFrame, TweenInfo.new(0.7), {BackgroundTransparency = 1}):Play()
	elseif Type == 2 then --Normal transition
		Ts:Create(TransitionFrame, TweenInfo.new(0.7), {BackgroundTransparency = 0}):Play()
		task.wait(1.5)
		Ts:Create(TransitionFrame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
	elseif Type == 3 then --Fast transition
		Ts:Create(TransitionFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
		task.wait(1)
		Ts:Create(TransitionFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
	end
end

-- Make all ScreenGuis (except the cutscene gui) to invisible or visible. 
local function changeGuis(state: boolean)
	if state then
		for i, v in script.Parent.Parent.Parent:GetChildren() do
			if v ~= script.Parent.Parent then
				if v:IsA("ScreenGui") then
					v.Enabled = true
				end
			end
		end
	else
		for i, v in script.Parent.Parent.Parent:GetChildren() do
			if v ~= script.Parent.Parent then
				if v:IsA("ScreenGui") then
					v.Enabled = false
				end
			end
		end
	end
end

local function StartCutscene(CameraPart: BasePart, Cinematic: boolean)
	Player:SetAttribute("CutsceneCameraLocked", true)
	SetPlayerControlsEnabled(false)
	changeGuis(false)
	
	if (CutsceneConnection) then
		CutsceneConnection:Disconnect()
	end
	
	CamPart = CameraPart
	PlayerValues:FireServer("CutsceneON")
	CutsceneEnabled = true
	if Cinematic then
		cinematicBars(true)
	end
	
	CutsceneConnection = RunService.RenderStepped:Connect(function()
		if CutsceneEnabled then
			if not CamPart then return end
			Camera.CFrame = CamPart.CFrame
		end
	end)
end

local function StopCutscene()
	Ts:Create(TransitionFrame, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
	
	task.wait(1)
	
	if (CutsceneConnection) then
		CutsceneConnection:Disconnect()
	end
	
	CutsceneEnabled = false
	Player:SetAttribute("CutsceneCameraLocked", false)
	PlayerValues:FireServer("CutsceneOFF")
	SetPlayerControlsEnabled(true)
	CamPart = nil
	cinematicBars(false)
	Ts:Create(TransitionFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
	changeGuis(true)
end

local function playSound(sound: Sound, parent: Instance?)
	local snd = sound:Clone()
	if parent then
		snd.Parent = parent
	else
		snd.Parent = MainFrame
	end
	snd:Play()
	game.Debris:AddItem(snd, snd.TimeLength + 1)
end

local function showDialog(text: string, Continue: boolean)
	Ts:Create(dialogText, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
	if Continue then
		local currentText = dialogText.Text
		for i = 1, #text do
			dialogText.Text = currentText..string.sub(text, 1, i)
			playSound(script.BipSound)
			task.wait(0.03)
		end
	else
		for i = 1, #text do
			dialogText.Text = string.sub(text, 1, i)
			playSound(script.BipSound)
			task.wait(0.03)
		end
	end
end

local function unshowDialog()
	Ts:Create(dialogText, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
end

--//Entrance cutscene
StartCutsceneValue:GetPropertyChangedSignal("Value"):Connect(function()
	local NewValue = StartCutsceneValue.Value
	if NewValue and Debounce then
		EntranceCutsceneStarted.Value = true
		Debounce = false
		
		local Cam1 = SecureSearch:WaitForInstance(StarterCutscene, "Cam1", 5) --StarterCutscene:WaitForChild("Cam1")
		local Cam2 = SecureSearch:WaitForInstance(StarterCutscene, "Cam2", 5) --StarterCutscene:WaitForChild("Cam2")
		local EffectSound = SecureSearch:WaitForInstance(StarterCutscene, "EffectSound", 5) --StarterCutscene:WaitForChild("Effect")
		
		if not Cam1 or not Cam2 or RunService:IsStudio() then
			warn("Couldn't find StarterCutscene cameras. Starting game without starter Cutscene. | Or is on Studio.")
			Ts:Create(TransitionFrame, TweenInfo.new(0.7), {BackgroundTransparency = 1}):Play()
			ObjectivesModule.NewObjective(false, "Explore_Asylum", "Explore The Asylum", "Investigate and Explore the Asylum.")
			GameStartedEvent:Fire() -- For the speedrun game mode
			
			if EffectSound then
				EffectSound:Play()
			end
			return
		end
		
		changeGuis(false)
		cinematicBars(true)
		SetPlayerControlsEnabled(false)
		Player:SetAttribute("CutsceneCameraLocked", true)
		PlayerValues:FireServer("CutsceneON")
		
		repeat wait()
			Camera.CameraType = Enum.CameraType.Scriptable
		until Camera.CameraType == Enum.CameraType.Scriptable
		
		Camera.CFrame = Cam1.CFrame
		Ts:Create(TransitionFrame, TweenInfo.new(0.7), {BackgroundTransparency = 1}):Play()
		
		task.wait(1)
		
		local tween = Ts:Create(Camera, TweenInfo.new(1.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), {CFrame = Cam2.CFrame})
		tween:Play()
		
		if EffectSound then
			EffectSound:Play()
		end
		
		tween.Completed:Connect(function()
			showDialog("We have arrived at the old asylum...")
			task.wait(1)
			showDialog(" Let's investigate and see what we have here.", true)
			task.wait(1.5)
			unshowDialog()
			task.wait(0.3)
			Ts:Create(TransitionFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
			task.wait(1)
			Camera.CameraType = Enum.CameraType.Custom
			Player:SetAttribute("CutsceneCameraLocked", false)
			PlayerValues:FireServer("CutsceneOFF")
			SetPlayerControlsEnabled(true)
			changeGuis(true)
			cinematicBars(false)
			Ts:Create(TransitionFrame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
			GameStartedEvent:Fire() -- For the speedrun game mode
			task.wait(2)
			ObjectivesModule.NewObjective(false, "Explore_Asylum", "Explore The Asylum", "Investigate and Explore the Asylum.")
		end)
	end
end)

local function changeCamForCutscene(state: boolean, transitionStyle: number, CinematicBars: boolean)
	if state then
		Player:SetAttribute("CutsceneCameraLocked", true)
		-- The default first-person camera hides the local character's head with
		-- LocalTransparencyModifier. A Scriptable cutscene camera does not always
		-- make it visible again, so force the entire local character visible after
		-- the camera controller has run each frame.
		RunService:UnbindFromRenderStep("CutsceneCharacterVisibility")
		RunService:BindToRenderStep("CutsceneCharacterVisibility", Enum.RenderPriority.Camera.Value + 2, function()
			local character = Player.Character
			if not character then return end

			for _, instance in character:GetDescendants() do
				if instance:IsA("BasePart") then
					instance.LocalTransparencyModifier = instance.Transparency
				end
			end
		end)

		SetPlayerControlsEnabled(false)
		makeTransition(transitionStyle)
		cinematicBars(CinematicBars)
		changeGuis(false)
		PlayerValues:FireServer("CutsceneON")
		PlayerValues:FireServer("CamOFF")
		PlayerValues:FireServer("SafeON")
		Player.CameraMode = Enum.CameraMode.Classic
		Camera.CameraType = Enum.CameraType.Scriptable
		Player.CameraMinZoomDistance = 12
	else
		RunService:UnbindFromRenderStep("CutsceneCharacterVisibility")
		makeTransition(transitionStyle)
		PlayerValues:FireServer("CamON")
		Player.CameraMinZoomDistance = 0.5
		Camera.CameraType = Enum.CameraType.Custom
		Player.CameraMode = Enum.CameraMode.LockFirstPerson
		Player:SetAttribute("CutsceneCameraLocked", false)
		PlayerValues:FireServer("CutsceneOFF")
		SetPlayerControlsEnabled(true)
		PlayerValues:FireServer("SafeOFF")
		changeGuis(true)
		cinematicBars(false)
	end
end

ActiveCutsceneEvent.OnClientEvent:Connect(function(event)
	if event == "RocksFloor" then
		--//Rocks Floor Cutscene
		if not RocksCutsceneDebounce then return end
		
		local RocksCam1 = RocksCutscene:WaitForChild("Cam1")
		
		RocksCutsceneDebounce = false
		changeCamForCutscene(true, 3, true)
		Camera.CFrame = RocksCam1.CFrame
		
		task.wait(1)
		
		local camShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCf)
			Camera.CFrame = Camera.CFrame * shakeCf
		end)
		camShake:Start()
		camShake:StartShake(5, 20, 1, 10)
		RocksTremorSound:Play()
		
		task.wait(0.5)
		showDialog("What? What is happening to this place? ")
		task.wait(0.5)
		showDialog("It seems like there is a tremor in the structure!", true)
		camShake:Stop()
		task.wait(2)
		unshowDialog()
		task.wait(0.5)
		
		showDialog("Well, it looks like the tremor has stopped...")
		task.wait(1)
		ActiveCutsceneEvent:FireServer("RocksFloor") -- Make the floor fall on server
		task.wait(1)
		camShake:Start()
		camShake:ShakeOnce(7, 30, 0.3, 2)
		task.wait(0.2)
		camShake:Stop()
		
		showDialog("WHAT?! THE ENTIRE FLOOR CAME DOWN! ")
		task.wait(1.5)
		showDialog("Now how can I go back?", true)
		task.wait(2)
		showDialog("Well, I think what's left for me is to continue...")
		task.wait(2)
		unshowDialog()
		task.wait(0.5)
		
		changeCamForCutscene(false, 2)
	elseif event == "FlayedAppear" then
		--//Monster Flayed Appear Cutscene
		local CamStart = MonsterAppearCutscene:WaitForChild("CamStart")
		local CamDoor1 = MonsterAppearCutscene:WaitForChild("CamDoor1")
		local CamDoor2 = MonsterAppearCutscene:WaitForChild("CamDoor2")
		local Cam1 = MonsterAppearCutscene:WaitForChild("Cam1")
		local Cam2 = MonsterAppearCutscene:WaitForChild("Cam2")
		local Cam3 = MonsterAppearCutscene:WaitForChild("Cam3")
		
		local CrashSound = MonsterAppearCutscene:WaitForChild("CrashSound")
		local AppearAnim = MonsterAppearModel:WaitForChild("AppearAnim")
		local hum = MonsterAppearModel:FindFirstChild("Humanoid")
		local animator = hum and hum:FindFirstChild("Animator")
		local animAppear = nil
		
		if not animator then
			animAppear = hum:LoadAnimation(AppearAnim)
		else
			animAppear = animator:LoadAnimation(AppearAnim)
		end
		
		
		changeCamForCutscene(true, 3, true)
		Camera.CFrame = CamDoor1.CFrame
		
		task.wait(0.65)
		
		local tweenDoor = Ts:Create(Camera, TweenInfo.new(2.5, Enum.EasingStyle.Cubic), {CFrame = CamDoor2.CFrame})
		tweenDoor:Play()
		
		local tween1 = Ts:Create(Camera, TweenInfo.new(6, Enum.EasingStyle.Sine), {CFrame = Cam1.CFrame})
		
		tweenDoor.Completed:Connect(function()
			showDialog("I'll need to find a code to open this door...")
			task.wait(1.5)
			unshowDialog()
			task.wait(2)
			makeTransition(2)
			Camera.CFrame = CamStart.CFrame
			
			task.wait(1.2)
			CrashSound:Play()
			
			local camShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCf)
				Camera.CFrame = Camera.CFrame * shakeCf
			end)
			camShake:Start()
			camShake:StartShake(16, 25, 0.2, 10)
			task.wait(0.35)
			camShake:Stop()
			
			task.wait(0.3)
			showDialog("What?")
			task.wait(0.5)
			showDialog(" What was that noise?", true)
			task.wait(1.5)
			
			tween1:Play()
			
			task.wait(0.3)
			
			local defaultVolume = DramaticAmbience.Volume
			DramaticAmbience.Volume = 0
			DramaticAmbience:Play()
			Ts:Create(DramaticAmbience, TweenInfo.new(4), {Volume = defaultVolume}):Play()
			task.delay(2, function() unshowDialog() end)
		end)
		
		local function stopChaseMusic()
			Ts:Create(ChaseMusic, TweenInfo.new(3), {Volume = 0}):Play()
		end
		
		--//Stop the animation like this to player don't see the monster floating
		local function stopAnim()
			animAppear.TimePosition = 0.01
			animAppear:Stop()
		end
		
		tween1.Completed:Connect(function()
			local tween2 = Ts:Create(Camera, TweenInfo.new(12), {CFrame = Cam2.CFrame})
			tween2:Play()
			tween2.Completed:Connect(function()
				Ts:Create(Camera, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {CFrame = Cam3.CFrame}):Play()
				CinematicSound:Play()
				animAppear:Play()
				showDialog("OOH!")
				
				animAppear.KeyframeReached:Connect(function(keyName)
					if keyName == "STOP" then
						stopAnim()
					end
				end)
				
				task.wait(1)
				
				makeTransition(3) -- turn plr to right position
				
				--task.wait(1)
				
				Camera.CFrame = CamStart.CFrame
				unshowDialog()
				changeCamForCutscene(false, nil, false)
				
				ActiveCutsceneEvent:FireServer("FlayedAppear")
				ChaseMusic:Play()
				task.delay(ChaseMusic.TimeLength - 3.1, stopChaseMusic)
			end)
		end)
	elseif event == "BasementBars" then
		--//Basement Bars Cutscene
		local Cam1 = BasementCutscene:WaitForChild("Cam1")
		local Cam2 = BasementCutscene:WaitForChild("Cam2")
		local Cam3 = BasementCutscene:WaitForChild("Cam3")
		
		changeCamForCutscene(true, 3, true)
		Camera.CFrame = Cam1.CFrame
		
		local tweenCam1 = Ts:Create(Camera, TweenInfo.new(8, Enum.EasingStyle.Sine), {CFrame = Cam2.CFrame})
		tweenCam1:Play()
		ScarySound:Play()
		
		local function stopSound(sound)
			Ts:Create(sound, TweenInfo.new(0.3), {Volume = 0}):Play()
		end
		
		task.delay(ScarySound.TimeLength - 1, stopSound, ScarySound)
		
		tweenCam1.Completed:Connect(function()
			Camera.CFrame = Cam3.CFrame
			
			task.wait(0.1)
			
			BarsSound1:Play()
			ActiveCutsceneEvent:FireServer("LaunchBars")
			
			task.wait(0.2)
			
			BarsSound2:Play()
			
			for i, v in GasParticlesFolder:GetChildren() do
				if v:IsA("BasePart") then
					local gasSound = nil
					local effect = nil
					if v:FindFirstChild("GasSound") then
						gasSound = v:FindFirstChild("GasSound")
					end
					if v:FindFirstChildWhichIsA("ParticleEmitter") then
						effect = v:FindFirstChildWhichIsA("ParticleEmitter")
					end
					if gasSound then
						Ts:Create(gasSound, TweenInfo.new(0.5), {Volume = 0}):Play()
					end
					if effect then
						effect.Enabled = false
					end
				end
			end
			
			task.wait(1)
			
			changeCamForCutscene(false, 3, false)
		end)
		
		task.wait(2.5)
		
		for i, v in GasParticlesFolder:GetChildren() do
			if v:IsA("BasePart") then
				local gasSound = nil
				local effect = nil
				if v:FindFirstChild("GasSound") then
					gasSound = v:FindFirstChild("GasSound")
				end
				if v:FindFirstChildWhichIsA("ParticleEmitter") then
					effect = v:FindFirstChildWhichIsA("ParticleEmitter")
				end
				if gasSound then
					gasSound:Play()
				end
				if effect then
					effect.Enabled = true
				end
				task.wait(1.5)
			end
		end
	elseif event == "StatuesCutscene" then
		--//Secret Room Statues Cutscene
		local Cam1 = StatuesCutscene:FindFirstChild("Cam1")
		local Cam2 = StatuesCutscene:FindFirstChild("Cam2")
		local Cam3 = StatuesCutscene:FindFirstChild("Cam3")
		local Cam4 = StatuesCutscene:FindFirstChild("Cam4")
		local FireSound = StatuesCutscene:FindFirstChild("FireSound")
		local TensionSound = StatuesCutscene:FindFirstChild("TensionMusic")
		local Stopped = false
		
		changeCamForCutscene(true, 3, true)
		Camera.CFrame = Cam1.CFrame
		
		local tweenCam1 = Ts:Create(Camera, TweenInfo.new(5, Enum.EasingStyle.Sine), {CFrame = Cam2.CFrame})
		tweenCam1:Play()
		TensionSound:Play()
		
		task.wait(3.5)
		
		FireSound:Play()
		for i, v in StatueEyes:GetDescendants() do
			if v:IsA("ParticleEmitter") then
				v.Enabled = true
			end
		end
		
		tweenCam1.Completed:Connect(function()
			local tweenCam2 = Ts:Create(Camera, TweenInfo.new(6, Enum.EasingStyle.Sine), {CFrame = Cam3.CFrame})
			tweenCam2:Play()
			
			task.wait(2)
			
			ActiveCutsceneEvent:FireServer("OpenGate")
			
			task.wait(4)
			
			local tweenCam3 = Ts:Create(Camera, TweenInfo.new(5, Enum.EasingStyle.Sine), {CFrame = Cam4.CFrame})
			tweenCam3:Play()
			
			tweenCam3.Completed:Connect(function()
				Stopped = true
				changeCamForCutscene(false, 1, false)
			end)
			
			task.wait(2)
			
			local tweenSound = Ts:Create(TensionSound, TweenInfo.new(3), {Volume = 0})
			tweenSound:Play()
			tweenSound.Completed:Connect(function()
				TensionSound:Stop()
			end)
			
			task.delay(10, function()
				if not Stopped then
					changeCamForCutscene(false, 1, false)
				end
			end)
		end)
	elseif event == "RestorePowerCutscene" then
		--//Restore Energy Cutscne
		local Cam1 = RestoreEnergyCutscene:FindFirstChild("Cam1")
		local Cam2 = RestoreEnergyCutscene:FindFirstChild("Cam2")
		local Cam3 = RestoreEnergyCutscene:FindFirstChild("Cam3")
		local Cam4 = RestoreEnergyCutscene:FindFirstChild("Cam4")
		local Cam5 = RestoreEnergyCutscene:FindFirstChild("Cam5")
		local Cam6 = RestoreEnergyCutscene:FindFirstChild("Cam6")
		local Cam7 = RestoreEnergyCutscene:FindFirstChild("Cam7")
		local Cam8 = RestoreEnergyCutscene:FindFirstChild("Cam8")
		local ElectricitySound = RestoreEnergyCutscene:WaitForChild("ElectricitySound")
		local PowerRestoreSound = RestoreEnergyCutscene:WaitForChild("PowerRestoreSound")
		local DramaticSound = RestoreEnergyCutscene:WaitForChild("DramaticSound")
		local DramaticSound2 = RestoreEnergyCutscene:WaitForChild("DramaticSound2")
		
		changeCamForCutscene(true, 2, true)
		
		if Cam1 then
			Camera.CFrame = Cam1.CFrame
		end
		
		if not Cam2 then
			changeCamForCutscene(false, 3, false)
			return
		end
		
		local tweenCam1 = Ts:Create(Camera, TweenInfo.new(4, Enum.EasingStyle.Sine), {CFrame = Cam2.CFrame})
		tweenCam1:Play()
		task.wait(0.7)
		ElectricitySound:Play()
		
		task.wait(3)
		
		if not Cam4 then
			changeCamForCutscene(false, 3, false)
			return
		end
		
		local tweenCam2 = Ts:Create(Camera, TweenInfo.new(6, Enum.EasingStyle.Sine), {CFrame = Cam4.CFrame})
		tweenCam1.Completed:Connect(function()
			makeTransition(3)
			
			if not Cam3 then
				changeCamForCutscene(false, 3, false)
				return
			end
			
			Camera.CFrame = Cam3.CFrame
			tweenCam2:Play()
		end)
		
		task.wait(3)
		
		ActiveCutsceneEvent:FireServer("EnableLights1")
		
		if not Cam6 then
			changeCamForCutscene(false, 3, false)
			return
		end
		
		local tweenCam3 = Ts:Create(Camera, TweenInfo.new(4, Enum.EasingStyle.Sine), {CFrame = Cam6.CFrame})
		
		tweenCam2.Completed:Connect(function()
			makeTransition(3)
			
			if not Cam5 then
				changeCamForCutscene(false, 3, false)
				return
			end
			
			Camera.CFrame = Cam5.CFrame
			tweenCam3:Play()
			
			task.wait(1.5)
			
			ActiveCutsceneEvent:FireServer("EnableLights2")
		end)
		
		tweenCam3.Completed:Connect(function()
			makeTransition(1)
			cinematicBars(false)
			
			if not Cam7 then
				changeCamForCutscene(false, 3, false)
				return
			end
			
			Camera.CFrame = Cam7.CFrame
			
			if not Cam8 then
				changeCamForCutscene(false, 3, false)
				return
			end
			
			local tweenCam4 = Ts:Create(Camera, TweenInfo.new(10), {CFrame = Cam8.CFrame})
			tweenCam4:Play()
			DramaticSound:Play()
			
			task.wait(5.5)
			
			DramaticSound2:Play()
			TransitionFrame.BackgroundColor3 = Color3.fromRGB(135, 19, 19)
			
			local tweenFrame = Ts:Create(TransitionFrame, TweenInfo.new(0.05), {BackgroundTransparency = 0.2})
			local tweenFrame2 = Ts:Create(TransitionFrame, TweenInfo.new(2.7), {BackgroundTransparency = 1})
			tweenFrame:Play()
			
			tweenFrame.Completed:Connect(function()
				tweenFrame2:Play()
			end)
			
			tweenFrame2.Completed:Connect(function()
				TransitionFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				changeCamForCutscene(false, 3, false)
			end)
		end)
	elseif event == "ChaseStartFlayed" then
		--//Monster chase start cutscene
		local DemogorgonModel = Rs.Monsters.DemogorgonMonster.ChaseStartCutscene.Demogorgon1
		DemogorgonModel.Parent = workspace
		
		local CamModel = Rs.Monsters.DemogorgonMonster.ChaseStartCutscene["CamRigWithLetterBox 1"]
		CamModel.Parent = workspace
		
		local animDemogorgon = DemogorgonModel:FindFirstChild("Humanoid").Animator:LoadAnimation(DemogorgonModel.cutsceneAnim)
		local animCam = CamModel:FindFirstChild("AnimationController"):LoadAnimation(CamModel:FindFirstChild("cutsceneAnim"))
		
		--[[
		local Cam1 = MonsterStartChaseCutscene:WaitForChild("Cam1", 5)
		local Cam2 = MonsterStartChaseCutscene:WaitForChild("Cam2", 5)
		local FlayedModel = MonsterStartChaseCutscene:FindFirstChild("FlayedChase")
		local FlayedChaseAnimation = FlayedModel:FindFirstChild("appearAnim")
		local animFlayed = FlayedModel:FindFirstChild("Humanoid"):FindFirstChild("Animator"):LoadAnimation(FlayedChaseAnimation)
		]]
		
		local DramaticSound1 = MonsterStartChaseCutscene:FindFirstChild("DramaticSound1")
		local DramaticSound2 = MonsterStartChaseCutscene:FindFirstChild("DramaticSound2")
		local ImpactSound = MonsterStartChaseCutscene:FindFirstChild("ImpactSound")
		local FootStepSound = MonsterStartChaseCutscene:FindFirstChild("FootStepSound"):Clone()
		local IntenseEffectChase = MonsterStartChaseCutscene:FindFirstChild("IntenseEffectChase")
		FootStepSound.Parent = DemogorgonModel:FindFirstChild("HumanoidRootPart")
		
		changeCamForCutscene(true, 2, true)
		animDemogorgon:Play()
		animCam:Play()
		
		local camConnection: RBXScriptConnection? = nil
		local camPart = CamModel:FindFirstChild("CameraPart")
		
		camConnection = RunService.RenderStepped:Connect(function()
			local camBone = camPart and camPart:FindFirstChild("camera")
			if camPart and camBone then
				local finalCF = camPart.CFrame * camBone.Transform
				local cfInvestYAxis = CFrame.Angles(0, math.rad(180), 0)
				finalCF = finalCF * cfInvestYAxis
				Camera.CFrame = finalCF
			end
		end)
		
		DramaticSound1:Play()
		
		--[[
		Camera.CFrame = Cam1.CFrame
		animFlayed:Play()
		animFlayed:AdjustSpeed(0)
		animFlayed.TimePosition = 0.01
		
		DramaticSound1:Play()
		Ts:Create(Camera, TweenInfo.new(8), {CFrame = Cam2.CFrame}):Play()
		
		
		task.wait(5)
		]]
		
		--TODO: make keyName when monster appears to make these sounds
		--playSound(DramaticSound2) -- when monster appears
		--FootStepSound:Play()
		
		animDemogorgon.KeyframeReached:Connect(function(keyName)
			if keyName == "END" then
				playSound(ImpactSound)
				
				task.wait(0.3)
				
				game:GetService("Lighting").ColorCorrection.Contrast = 999999995904
				game:GetService("Lighting").ColorCorrection.Brightness = 290000011264
				FootStepSound:Stop()
				animDemogorgon:AdjustSpeed(0)
				
				task.wait(1)
				
				Ts:Create(TransitionFrame, TweenInfo.new(2), {BackgroundTransparency = 0}):Play()
				
				task.wait(2.1)
				
				if camConnection then
					camConnection:Disconnect()
					camConnection = nil
				end
				
				changeCamForCutscene(false, nil, false)
				
				animDemogorgon:Stop()
				animCam:Stop()
				DemogorgonModel.Parent = Rs.Monsters.DemogorgonMonster.ChaseStartCutscene
				CamModel.Parent = Rs.Monsters.DemogorgonMonster.ChaseStartCutscene
				
				Ts:Create(TransitionFrame, TweenInfo.new(0.7), {BackgroundTransparency = 1}):Play()
				game:GetService("Lighting").ColorCorrection.Contrast = 0.3
				game:GetService("Lighting").ColorCorrection.Brightness = -0.01
				--IntenseEffectChase:Play()
				PlayerValues:FireServer("ChaseON")
				ActiveCutsceneEvent:FireServer("ChaseFlayed1_Start")
				
				task.wait(1)
				
				IntenseEffectChase:Play()
				chaseFrame.Visible = true
				changeShakeText(true)
				
				task.delay(9, function()
					chaseFrame.Visible = false
					changeShakeText(false)
				end)
			elseif keyName == "APPEAR" then
				FootStepSound:Play()
			end
		end)
		
		animCam.KeyframeReached:Connect(function(keyName)
			if keyName == "END" then
				animCam:AdjustSpeed(0)
			end
		end)
		
		--[[
		animFlayed.KeyframeReached:Connect(function(keyName)
			if keyName == "LOOK" then
				
			elseif keyName == "STOPWALK" then
				FootStepSound:Stop()
			elseif keyName == "STARTWALK" then
				FootStepSound:Play()
			elseif keyName == "END" then
				playSound(ImpactSound)
				
				task.wait(0.3)
				
				game:GetService("Lighting").ColorCorrection.Contrast = 999999995904
				game:GetService("Lighting").ColorCorrection.Brightness = 290000011264
				FootStepSound:Stop()
				animFlayed:AdjustSpeed(0)
				
				task.wait(1)
				
				Ts:Create(TransitionFrame, TweenInfo.new(2), {BackgroundTransparency = 0}):Play()
				
				task.wait(2.1)
				
				changeCamForCutscene(false, nil, false)
				animFlayed:Stop()
				Ts:Create(TransitionFrame, TweenInfo.new(0.7), {BackgroundTransparency = 1}):Play()
				game:GetService("Lighting").ColorCorrection.Contrast = 0.3
				game:GetService("Lighting").ColorCorrection.Brightness = -0.01
				--IntenseEffectChase:Play()
				PlayerValues:FireServer("ChaseON")
				ActiveCutsceneEvent:FireServer("ChaseFlayed1_Start")
				
				task.wait(1)
				
				IntenseEffectChase:Play()
				chaseFrame.Visible = true
				changeShakeText(true)
				
				task.delay(9, function()
					chaseFrame.Visible = false
					changeShakeText(false)
				end)
			end
		end)
		]]
	elseif event == "Chase1_FinalCutscene" then
		--//Final Cutscene Chase 1 (flayed)
		--[[
		local Cam1 = MonsterChaseFinalCutscene:FindFirstChild("Cam1")
		local Cam2 = MonsterChaseFinalCutscene:FindFirstChild("Cam2")
		local Cam3 = MonsterChaseFinalCutscene:FindFirstChild("Cam3")
		local Cam4 = MonsterChaseFinalCutscene:FindFirstChild("Cam4")
		local Cam5 = MonsterChaseFinalCutscene:FindFirstChild("Cam5")
		local Cam6 = MonsterChaseFinalCutscene:FindFirstChild("Cam6")
		local Cam7 = MonsterChaseFinalCutscene:FindFirstChild("Cam7")
		local Cam8 = MonsterChaseFinalCutscene:FindFirstChild("Cam8")
		local Cam9 = MonsterChaseFinalCutscene:FindFirstChild("Cam9")
		
		--//Characters
		local plrClone_Rig = MonsterChaseFinalCutscene:FindFirstChild("Plr_CloneRig")
		local cloneAnimator = plrClone_Rig:FindFirstChild("Humanoid"):FindFirstChild("Animator")
		local flayedChaseFinal_Rig = MonsterChaseFinalCutscene:FindFirstChild("FlayedChaseFinal")
		local monsterAnimator = flayedChaseFinal_Rig:FindFirstChild("Humanoid"):FindFirstChild("Animator")
		
		--//Animations
		local plrAnimation = MonsterChaseFinalCutscene:FindFirstChild("plrAnim")
		local monsterAnimation = MonsterChaseFinalCutscene:FindFirstChild("monsterAnim")
		local plrAnim = cloneAnimator:LoadAnimation(plrAnimation)
		local monsterAnim = monsterAnimator:LoadAnimation(monsterAnimation)
		]]
		
		local demogorgan = Rs.Monsters.DemogorgonMonster.ChaseEndCutscene.Demogorgon_EndChase
		demogorgan.Parent = workspace
		
		local camModel = Rs.Monsters.DemogorgonMonster.ChaseEndCutscene.CamRigWithLetterBox
		camModel.Parent = workspace
		
		local r15_plr = Rs.Monsters.DemogorgonMonster.ChaseEndCutscene.R15_Plr
		r15_plr.Parent = workspace
		
		local animDemogorgan = demogorgan.Humanoid.Animator:LoadAnimation(demogorgan.cutsceneAnim) :: AnimationTrack
		local animCam = camModel.AnimationController.Animator:LoadAnimation(camModel.cutsceneAnim) :: AnimationTrack
		local animPlr = r15_plr.Humanoid.Animator:LoadAnimation(r15_plr.cutsceneAnim) :: AnimationTrack
		
		--//Sounds
		local MonsterSound1 = MonsterChaseFinalCutscene:FindFirstChild("MonsterGrrSound")
		local MonsterSound2 = MonsterChaseFinalCutscene:FindFirstChild("MonsterSound2")
		local CinematicSound = MonsterChaseFinalCutscene:FindFirstChild("CinematicSound")
		local SadMusicSound = MonsterChaseFinalCutscene:FindFirstChild("SadMusicSound")
		local IntenseEffectChase = MonsterStartChaseCutscene:FindFirstChild("IntenseEffectChase")
		local plrWalkSound = MonsterChaseFinalCutscene:FindFirstChild("plrWalkSound")
		local HorrorTensionEffect = MonsterChaseFinalCutscene:FindFirstChild("HorrorTensionEffect")
		local fallingSound = MonsterChaseFinalCutscene:FindFirstChild("FallingSound")
		local monsterFootStep = MonsterChaseFinalCutscene:FindFirstChild("FootStepSound")
		local jumpscareSound = demogorgan.HumanoidRootPart.JumpscareSound
		local weirdSound2 = demogorgan.HumanoidRootPart.Sound2
		weirdSound2.Parent = demogorgan.BSurfaceMesh
		jumpscareSound.Parent = demogorgan.BSurfaceMesh
		monsterFootStep.Parent = demogorgan.BSurfaceMesh
		plrWalkSound.Parent = r15_plr.UpperTorso
		
		--//Values
		local startedFinal = false
		local camConnection: RBXScriptConnection? = nil
		
		--//Clone the plr char appearence to the cloneRig
		for i, v in pairs(game:GetService("Players").LocalPlayer.Character:GetChildren()) do
			if v:IsA("Accessory") then
				local accessoryClone = v:Clone()
				accessoryClone.Parent = nil
				
				for _, v in accessoryClone:GetDescendants() do
					if v:IsA("Weld") then
						v.Part1 = r15_plr:FindFirstChild("Head")
						v.Part0 = accessoryClone:FindFirstChild("Handle")
					end
				end
				
				accessoryClone.Parent = r15_plr
			elseif v:IsA("BodyColors") then
				v:Clone().Parent = r15_plr
			elseif v:IsA("Shirt") then
				v:Clone().Parent = r15_plr
			elseif v:IsA("Pants") then
				v:Clone().Parent = r15_plr
			end
			
			if v.Name == "Head" then
				if v:FindFirstChild("face") then
					r15_plr.Head.face.Texture = v:FindFirstChild("face").Texture
				end
			end
		end
		
		changeCamForCutscene(true, 3, true)
		UpdatePlrWinEvent:FireServer(1) -- Add +1 win to plr stats
		
		animPlr:Play()
		animDemogorgan:Play()
		animCam:Play()
		monsterFootStep:Play()
		
		local camPart = camModel:FindFirstChild("CameraPart")
		
		camConnection = RunService.RenderStepped:Connect(function()
			local camBone = camPart.camera
			if camPart and camBone then
				local finalCF = camPart.CFrame * camBone.Transform
				Camera.CFrame = finalCF
			end
		end)
		
		PlayerValues:FireServer("ChaseOFF")
		
		--plrWalkSound:Play()
		Ts:Create(IntenseEffectChase, TweenInfo.new(2), {Volume = 0}):Play()
		
		-- Camera.CFrame = Cam1.CFrame
		-- plrAnim:Play()
		
		task.delay(2, function() HorrorTensionEffect:Play() end)
		
		local function chaseFinal()
			if startedFinal then return end
			
			animDemogorgan:AdjustSpeed(0)
			CinematicSound:Play()
			TransitionFrame.BackgroundTransparency = 0
			startedFinal = true
			
			task.delay(10, function()
				Ts:Create(CinematicSound, TweenInfo.new(4.7), {Volume = 0}):Play()
				SadMusicSound.Volume = 0
				task.wait(2)
				SadMusicSound:Play()
				Ts:Create(SadMusicSound, TweenInfo.new(4), {Volume = 1}):Play()
			end)
			
			task.wait(6)
			
			enableCreditsFrame() -- show credits frame
		end
		
		animDemogorgan.KeyframeReached:Connect(function(keyName)
			if keyName == "FOOTSTEP_START" then
				monsterFootStep:Play()
			elseif keyName == "SCREAM" then
				monsterFootStep:Stop()
				jumpscareSound:Play()
			elseif keyName == "ATTACK" then
				monsterFootStep:stop()
				jumpscareSound:Play()
				task.delay(2, function()
					weirdSound2:Play()
				end)
			end
		end)
		
		animDemogorgan.Stopped:Connect(function()
			Ts:Create(monsterFootStep, TweenInfo.new(0.4), {Volume = 0}):Play()
			task.delay(0.7, function() monsterFootStep:Stop() end)
			chaseFinal()
		end)
		
		animPlr.KeyframeReached:Connect(function(keyName)
			if keyName == "END" then
				animPlr:AdjustSpeed(0)
				task.wait(0.4)
				monsterFootStep.Volume = 1
				monsterFootStep:Play()
			end
		end)
		
		--[[
		plrAnim.KeyframeReached:Connect(function(keyName)
			if keyName == "RUN_STOP" then
				Ts:Create(plrWalkSound, TweenInfo.new(0.2), {Volume = 0}):Play()
				task.delay(0.5, function() plrWalkSound:Stop() end)
				Camera.CFrame = Cam2.CFrame
			elseif keyName == "LOOK" then
				monsterAnim:Play()
				monsterFootStep:Play()
				playSound(MonsterSound1, flayedChaseFinal_Rig.HumanoidRootPart)
				
				task.delay(0.4, function() monsterFootStep:Stop() end)
				
				Camera.CFrame = Cam3.CFrame
				task.wait(0.7)
				Camera.CFrame = Cam4.CFrame
				monsterFootStep:Play()
				task.wait(1.25)
				Camera.CFrame = Cam5.CFrame
				playSound(MonsterSound2, flayedChaseFinal_Rig.HumanoidRootPart)
				
				repeat task.wait() until monsterAnim.Length > 0
				task.delay(monsterAnim.Length, chaseFinal)
			elseif keyName == "LOOK_BEHIND" then
				Camera.CFrame = Cam6.CFrame
			elseif keyName == "FALL" then
				Ts:Create(monsterFootStep, TweenInfo.new(0.4), {Volume = 0}):Play()
				task.delay(0.7, function() monsterFootStep:Stop() end)
				Camera.CFrame = Cam7.CFrame
				fallingSound:Play()
			elseif keyName == "END" then
				plrAnim:AdjustSpeed(0)
				Camera.CFrame = Cam8.CFrame
				Ts:Create(Camera, TweenInfo.new(6), {CFrame = Cam9.CFrame}):Play()
				task.wait(0.4)
				monsterFootStep.Volume = 1
				monsterFootStep:Play()
			end
		end)
		]]
		
		--[[
		monsterAnim.KeyframeReached:Connect(function(keyName)
			if keyName == "END" then
				Ts:Create(monsterFootStep, TweenInfo.new(0.4), {Volume = 0}):Play()
				task.delay(0.7, function() monsterFootStep:Stop() end)
				chaseFinal()
			end
		end)
		]]
	end
end)
