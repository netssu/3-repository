--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local InspectEvent = Remotes:FindFirstChild("Inspect")
local VaultPuzzleEvent = Remotes:FindFirstChild("vaultPuzzle")

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local GameConfigModule = require(ModulesFolder:FindFirstChild("GameConfigModule"))
local InventoryModule = require(ModulesFolder:FindFirstChild("InventoryModule"))
local DialogModule = require(ModulesFolder:FindFirstChild("PlayerDialogModule"))
local ObjectivesModule = require(ModulesFolder:FindFirstChild("ObjectivesModule"))
local MoneyModule = require(ModulesFolder:FindFirstChild("MoneyModule"))
local DoorCollision = require(ModulesFolder:FindFirstChild("DoorCollision"))

--//Asylum Reception Stuff
local Map = workspace:FindFirstChild("Map")
local AsylumReceptionFolder = Map:FindFirstChild("Area2_AsylumReception")
local InteractStuff = AsylumReceptionFolder:FindFirstChild("InteractStuff")
local CardDetector = InteractStuff:FindFirstChild("Card_Detector")

--//Vault Stuff
local VaultModel = InteractStuff:FindFirstChild("Vault")
local VaultHinge = VaultModel.VaultDoor:FindFirstChild("DoorHinge")
local LockPickTool = VaultModel.Lockpick
local ProxVault = Instance.new("ProximityPrompt", VaultModel.Interact)

--//Sounds
local SoundsFolder = VaultModel:FindFirstChild("Sounds")

--//Values
local currentPlr = nil
local givenObjective = false
local puzzleSolved = false
local toolConnection: RBXScriptConnection = nil
local puzzleReward = math.random(5, 15)

--//Setup
CardDetector.BillboardGui.Enabled = false
ProxVault.Style = Enum.ProximityPromptStyle.Custom
ProxVault.MaxActivationDistance = GameConfigModule.InteractDistance
ProxVault.ActionText = "Unlock"
ProxVault.ObjectText = "Vault"
ProxVault.RequiresLineOfSight = false
ProxVault.HoldDuration = 0.15

local function changeLockpickState(state: boolean)
	if state then
		LockPickTool.CFrame = VaultModel.ToolAppearPos.CFrame
		Ts:Create(LockPickTool, TweenInfo.new(0.5), {Transparency = 0, CFrame = VaultModel.ToolDefaultPos.CFrame}):Play()
	else
		Ts:Create(LockPickTool, TweenInfo.new(0.5), {Transparency = 1, CFrame = VaultModel.ToolAppearPos.CFrame}):Play()
	end
end

local function playSound(sound: Sound, parent: Instance?)
	local snd = sound:Clone()
	if parent then
		snd.Parent = parent
	else
		snd.Parent = sound.Parent
	end
	snd:Play()
	game.Debris:AddItem(snd, snd.TimeLength + 1)
end

local function createToolConnection()
	if toolConnection then
		toolConnection:Disconnect()
	end
	toolConnection = coroutine.wrap(function()
		while true do
			wait()
			Ts:Create(LockPickTool, TweenInfo.new(2.5), {CFrame = VaultModel.ToolDefaultPos.CFrame}):Play()
		end
	end)()
end

local function removePuzzleUI(plr: Player)
	if not plr then return end
	if not VaultModel:FindFirstChild("VaultPuzzleGui") then return end
	if plr.PlayerGui:FindFirstChild(VaultModel.VaultPuzzleGui.Name) then
		plr.PlayerGui:FindFirstChild(VaultModel.VaultPuzzleGui.Name):Destroy()
	end
end

ProxVault.Triggered:Connect(function(plr)
	if not plr.Character or puzzleSolved then return end
	
	local char = plr.Character
	local hum = char:WaitForChild("Humanoid") :: Humanoid
	
	if not hum or hum.Health <= 0 then return end
	
	if not givenObjective then
		givenObjective = true
		ObjectivesModule.NewObjective(true, "Unlock_Vault", "Unlock the Vault", "Search for a lockpick to unlock the Vault.")
	else
		if char:FindFirstChild("Lockpick") and char:FindFirstChild("Lockpick"):IsA("Tool") then
			ProxVault.Enabled = false
			VaultModel.BillboardGui.Enabled = false
			currentPlr = plr
			InspectEvent:FireClient(plr, "InspectON", VaultModel.CamPart)
			
			local puzzleGui = VaultModel.VaultPuzzleGui:Clone()
			puzzleGui.Parent = plr.PlayerGui
			
			changeLockpickState(true)
			
			task.wait(0.5)
			
			createToolConnection()
		else
			DialogModule.Dialog(false, plr, nil, "I need a Lockpick to unlock this.")
		end
	end
end)

InspectEvent.OnServerEvent:Connect(function(plr, event)
	if event == "InspectOFF" and currentPlr then
		removePuzzleUI(plr)
		currentPlr = nil
		changeLockpickState(false)
		if not puzzleSolved then
			VaultModel.BillboardGui.Enabled = true
			ProxVault.Enabled = true
		end
		if toolConnection then
			toolConnection:Disconnect()
		end
	end
end)

VaultPuzzleEvent.OnServerEvent:Connect(function(plr, event)
	if event == "Up" then
		playSound(SoundsFolder.ClickingSound, VaultModel.Interact)
		Ts:Create(LockPickTool, TweenInfo.new(0.3), {CFrame = VaultModel.ToolUpPos.CFrame}):Play()
	elseif event == "LevelUp" then
		Ts:Create(LockPickTool, TweenInfo.new(0.1), {CFrame = VaultModel.ToolDefaultPos.CFrame}):Play()
		playSound(SoundsFolder.ClickSound, VaultModel.Interact)
	elseif event == "Completed" then -- win
		if toolConnection then
			toolConnection:Disconnect()
		end
		
		puzzleSolved = true
		currentPlr = nil
		removePuzzleUI(plr)
		changeLockpickState(false)
		ObjectivesModule.CompleteObjective(true, "Unlock_Vault")
		InventoryModule.DeleteItem("Lockpick")
		InspectEvent:FireClient(plr, "InspectOFF") -- camera back to normal
		playSound(SoundsFolder.UnlockSound, VaultModel.Interact)
		MoneyModule.Give(plr, puzzleReward)
		CardDetector.BillboardGui.Enabled = true
		
		for i, v in VaultModel.Chains:GetChildren() do
			if v:IsA("BasePart") then
				v.Anchored = false
				task.delay(10, function()
					v.Anchored = true
					v.CanCollide = false
					Ts:Create(v, TweenInfo.new(4), {Transparency = 1}):Play()
					game.Debris:AddItem(v, 5)
				end)
				task.wait()
			end
		end
		
		task.delay(10, function()
			for i, v in VaultModel.PadLock:GetDescendants() do
				if v:IsA("BasePart") then
					v.Anchored = true
					v.CanCollide = false
					Ts:Create(v, TweenInfo.new(3), {Transparency = 1}):Play()
					game.Debris:AddItem(v, 4)
					task.wait()
				end
			end
		end)
		
		VaultModel.PadLock.Base.Anchored = false
		DoorCollision.disable(VaultModel)
		playSound(SoundsFolder.DoorOpeningSound, VaultModel.Interact)
		Ts:Create(VaultHinge, TweenInfo.new(SoundsFolder.DoorOpeningSound.TimeLength, Enum.EasingStyle.Cubic), {CFrame = VaultModel.VaultDoor.DoorOpen.CFrame}):Play()
	end
end)
