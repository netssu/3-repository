--!strict

--//Services
local Ts = game:GetService("TweenService")
local Rs = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local ChangeCamEvent = Remotes:WaitForChild("ChangeCam")

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local GameConfigModule = require(ModulesFolder:FindFirstChild("GameConfigModule"))
local DialogModule = require(ModulesFolder:FindFirstChild("PlayerDialogModule"))
local InventoryModule = require(ModulesFolder:FindFirstChild("InventoryModule"))
local MoneyModule = require(ModulesFolder:FindFirstChild("MoneyModule"))
local DoorCollision = require(ModulesFolder:FindFirstChild("DoorCollision"))

--//Asylum Reception Stuff
local Map = workspace:FindFirstChild("Map")
local AsylumReceptionFolder = Map:FindFirstChild("Area2_AsylumReception")
local InteractStuff = AsylumReceptionFolder:FindFirstChild("InteractStuff")

--//Energy Room
local CardDetector = InteractStuff:FindFirstChild("Card_Detector")
local EnergyRoom_Door = InteractStuff:FindFirstChild("EnergyRoom_Door")
local ProxCard = Instance.new("ProximityPrompt", CardDetector.Interact)
local PlrKeycardAnim = CardDetector:FindFirstChild("PlrKeycardAnim")
local EnergyMachine = InteractStuff:FindFirstChild("Energy_Machine")

--//Sounds
local SoundsFolder = CardDetector:FindFirstChild("Sounds")

--//Values
local reward = math.random(5, 10)
local alreadyOpened = false

--//Setup
EnergyMachine.BillboardGui.Enabled = false
ProxCard.MaxActivationDistance = GameConfigModule.InteractDistance
ProxCard.RequiresLineOfSight = false
ProxCard.Style = Enum.ProximityPromptStyle.Custom
ProxCard.HoldDuration = 0.15
ProxCard.ActionText = "Interact"
ProxCard.ObjectText = "Card Detector"

ContentProvider:PreloadAsync({PlrKeycardAnim})

function playSound(sound: Sound, parent: Instance?)
	local snd = sound:Clone()
	if parent then
		snd.Parent = parent
	else
		snd.Parent = sound.Parent
	end
	snd:Play()
	game.Debris:AddItem(snd, snd.TimeLength + 1)
end

function openDoor()
	DoorCollision.disable(EnergyRoom_Door)
	for i, v in CardDetector.Light_Parts:GetChildren() do
		if v:IsA("BasePart") then
			v.Color = Color3.fromRGB(82, 255, 52)
		end
	end
	playSound(SoundsFolder.CorrectSound, CardDetector.Interact)
	
	task.wait(0.65)
	
	EnergyRoom_Door.MainDoor.OpenSound:Play()
	Ts:Create(EnergyRoom_Door.Hinge, TweenInfo.new(EnergyRoom_Door.MainDoor.OpenSound.TimeLength, Enum.EasingStyle.Linear), {CFrame = EnergyRoom_Door.OpenedPos.CFrame}):Play()
	EnergyRoom_Door.Collider:Destroy()
end

ProxCard.Triggered:Connect(function(plr)
	if not plr or not plr.Character then return end
	local char = plr.Character
	local hum = char:WaitForChild("Humanoid") :: Humanoid
	if char:FindFirstChild("Keycard") and char:FindFirstChild("Keycard"):IsA("Tool") and not alreadyOpened then
		alreadyOpened = true
		
		local HRP = char:FindFirstChild("HumanoidRootPart") :: BasePart
		local Animator = hum:WaitForChild("Animator") :: Animator
		local PlayerKeycardAnim = Animator:LoadAnimation(PlrKeycardAnim)
		local opened = false
		local deletedItem = false
		
		EnergyMachine.BillboardGui.Enabled = true
		CardDetector.BillboardGui.Enabled = false
		HRP.Anchored = true
		local pos = Vector3.new(CardDetector.AnimPos.Position.X, HRP.Position.Y, CardDetector.AnimPos.Position.Z)
		local lookPos = CardDetector.AnimPos.CFrame.LookVector
		HRP.CFrame = CFrame.new(pos, pos + lookPos)
		
		--//Disable plr cam
		ChangeCamEvent:FireClient(plr, true)
		
		MoneyModule.Give(plr, reward)
		PlayerKeycardAnim:Play()
		ProxCard.MaxActivationDistance = 0
		
		task.delay(1, function()
			playSound(SoundsFolder.ClotheSound, HRP)
		end)
		
		PlayerKeycardAnim.KeyframeReached:Connect(function(KeyName)
			if KeyName == "KEYCARD" then
				playSound(SoundsFolder.KeycardSwapSound, HRP)
			elseif KeyName == "OPEN" then
				opened = true
				openDoor()
			end
		end)
		
		PlayerKeycardAnim.Stopped:Connect(function()
			--//Enable plr cam
			ChangeCamEvent:FireClient(plr, false)
			HRP.Anchored = false
			InventoryModule.DeleteItem("Keycard")
			deletedItem = true
		end)
		
		task.wait(8)
		
		if not opened then
			opened = true
			openDoor()
		end
		if not deletedItem then
			ChangeCamEvent:FireClient(plr, false)
			HRP.Anchored = false
			InventoryModule.DeleteItem("Keycard")
		end
	else
		DialogModule.Dialog(false, plr, nil, "I need a Keycard to open this door.")
	end
end)
