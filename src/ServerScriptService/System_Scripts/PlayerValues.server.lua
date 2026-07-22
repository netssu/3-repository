--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local PlayerValues = Remotes:FindFirstChild("PlayerValues")

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local GameConfigModule = require(ModulesFolder:FindFirstChild("GameConfigModule"))
local FlashlightModule = require(ModulesFolder:FindFirstChild("FlashlightModule"))
local DataManager = require(game:GetService("ServerScriptService").Data.DataManager)

game.Players.PlayerAdded:Connect(function(Player)
	local PlayerValues = Instance.new("Folder", Player)
	PlayerValues.Name = "PlayerValues"
	
	local Running = Instance.new("BoolValue", PlayerValues)
	Running.Name = "Running"
	Running.Value = false
	
	local Crouching = Instance.new("BoolValue", PlayerValues)
	Crouching.Name = "Crouching"
	Crouching.Value = false
	
	local OnCutscene = Instance.new("BoolValue", PlayerValues)
	OnCutscene.Name = "OnCutscene"
	OnCutscene.Value = false
	
	local IsAlive = Instance.new("BoolValue", PlayerValues)
	IsAlive.Name = "IsAlive"
	IsAlive.Value = true
	
	local OnInspect = Instance.new("BoolValue", PlayerValues)
	OnInspect.Name = "OnInspect"
	OnInspect.Value = false
	
	local OnChase = Instance.new("BoolValue", PlayerValues) -- used in chase scenes
	OnChase.Name = "OnChase"
	OnChase.Value = false
	
	--//When enabled, monsters will can't chase this player
	local OnSafe = Instance.new("BoolValue", PlayerValues)
	OnSafe.Name = "OnSafe"
	OnSafe.Value = false
	
	local Batteries = Instance.new("NumberValue", PlayerValues)
	Batteries.Name = "Batteries"
	Batteries.Value = FlashlightModule.MaxBattery
	
	--//Enable and Activate the first person (for testing purposes)
	local CamState = Instance.new("BoolValue", PlayerValues)
	CamState.Name = "CamState"
	CamState.Value = true
	
	--//Selected Push Player -- for product
	local selectedPushPlayer = Instance.new("StringValue", PlayerValues)
	selectedPushPlayer.Name = "SelectedPushPlayer"
	
	--//Function to set the players char to default walk speed
	Player.CharacterAdded:Connect(function(char)
		local Character = char
		
		--//Set the default values on player every time the char spawns
		local function setDefaultValues()
			local Humanoid = Character:WaitForChild("Humanoid") :: Humanoid
			Humanoid.WalkSpeed = GameConfigModule.PlayerDefaultSpeed
			Humanoid.JumpHeight = GameConfigModule.PlayerDefaultJump
			Humanoid.NameDisplayDistance = 0
			
			Humanoid.Died:Connect(function()
				Player.CharacterAdded:Wait()
				Character = Player.Character
				setDefaultValues()
			end)
		end
		
		setDefaultValues()
	end)
end)

--//Update player values
PlayerValues.OnServerEvent:Connect(function(Player, event)
	local function stopPlayerMovement()
		local values = Player:WaitForChild("PlayerValues")
		local running = values:FindFirstChild("Running")
		if running then
			running.Value = false
		end

		local character = Player.Character
		local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 0
			humanoid:Move(Vector3.zero, false)
		end
	end

	if event == "CutsceneON" then
		local OnCutscene = Player:WaitForChild("PlayerValues"):FindFirstChild("OnCutscene")
		if OnCutscene then
			OnCutscene.Value = true
		end
		stopPlayerMovement()
	elseif event == "CutsceneOFF" then
		local OnCutscene = Player:WaitForChild("PlayerValues"):FindFirstChild("OnCutscene")
		if OnCutscene then
			OnCutscene.Value = false
		end
	elseif event == "RunningON" then
		local values = Player:WaitForChild("PlayerValues")
		if values.OnCutscene.Value or values.OnInspect.Value then
			stopPlayerMovement()
			return
		end
		local Running = Player:WaitForChild("PlayerValues"):FindFirstChild("Running")
		if Running then
			Running.Value = true
		end
	elseif event == "RunningOFF" then
		local Running = Player:WaitForChild("PlayerValues"):FindFirstChild("Running")
		if Running then
			Running.Value = false
		end
	elseif event == "CrouchingON" then 
		local Crouching = Player:WaitForChild("PlayerValues"):FindFirstChild("Crouching")
		if Crouching then
			Crouching.Value = true
		end
	elseif event == "CrouchingOFF" then
		local Crouching = Player:WaitForChild("PlayerValues"):FindFirstChild("Crouching")
		if Crouching then
			Crouching.Value = false
		end
	elseif event == "DecayLight" then
		local BatteriesValue = Player:WaitForChild("PlayerValues"):FindFirstChild("Batteries")
		if BatteriesValue then
			if BatteriesValue.Value > 0 then
				BatteriesValue.Value -= FlashlightModule.Decay
				if BatteriesValue.Value < 0 then
					BatteriesValue.Value = 0
				end
			end
		end
	elseif event == "Recharge" then
		local BatteriesValue = Player:WaitForChild("PlayerValues"):FindFirstChild("Batteries")
		if BatteriesValue then
			local HalfValue = FlashlightModule.MaxBattery / 2
			BatteriesValue.Value += HalfValue
			if BatteriesValue.Value > FlashlightModule.MaxBattery then
				BatteriesValue.Value = FlashlightModule.MaxBattery
			end
		end
	elseif event == "ResetFlashlight" then
		local BatteriesValue = Player:WaitForChild("PlayerValues"):FindFirstChild("Batteries")
		if BatteriesValue then
			BatteriesValue.Value = FlashlightModule.MaxBattery 
		end
	elseif event == "CamOFF" then
		local CamState = Player:WaitForChild("PlayerValues"):FindFirstChild("CamState")
		if CamState then
			CamState.Value = false
		end
	elseif event == "CamON" then
		local CamState = Player:WaitForChild("PlayerValues"):FindFirstChild("CamState")
		if CamState then
			CamState.Value = true
		end
	elseif event == "SafeON" then
		local OnSafe = Player:WaitForChild("PlayerValues"):FindFirstChild("OnSafe")
		if OnSafe then
			OnSafe.Value = true
		end
	elseif event == "SafeOFF" then
		local OnSafe = Player:WaitForChild("PlayerValues"):FindFirstChild("OnSafe")
		if OnSafe then
			OnSafe.Value = false
		end
	elseif event == "InspectON" then
		local OnInspect = Player:WaitForChild("PlayerValues"):FindFirstChild("OnInspect")
		if OnInspect then
			OnInspect.Value = true
		end
		stopPlayerMovement()
	elseif event == "InspectOFF" then
		local OnInspect = Player:WaitForChild("PlayerValues"):FindFirstChild("OnInspect")
		if OnInspect then
			OnInspect.Value = false
		end
	elseif event == "ChaseON" then
		local OnChase = Player:WaitForChild("PlayerValues"):FindFirstChild("OnChase")
		if OnChase then
			OnChase.Value = true
		end
	elseif event == "ChaseOFF" then
		local OnChase = Player:WaitForChild("PlayerValues"):FindFirstChild("OnChase")
		if OnChase then
			OnChase.Value = false
		end
	elseif event == "KillEnemy" then
		local Kills = Player:WaitForChild("leaderstats"):FindFirstChild("Kills")
		if Kills then
			DataManager.AddKills(Player, 1)
		end
	end
end)
