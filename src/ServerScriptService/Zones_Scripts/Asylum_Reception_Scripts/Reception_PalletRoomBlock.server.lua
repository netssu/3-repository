--//Services
local Ts = game:GetService("TweenService")
local Rs = game:GetService("ReplicatedStorage")

--//Asylum Reception Stuff
local Map = workspace:FindFirstChild("Map")
local AsylumReceptionFolder = Map:FindFirstChild("Area2_AsylumReception")
local InteractStuff = AsylumReceptionFolder:FindFirstChild("InteractStuff")

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local GameConfigModule = require(ModulesFolder:FindFirstChild("GameConfigModule"))

--//Pallet Block
local PalletBlock = InteractStuff:FindFirstChild("Pallet_Block")
local OpenPos = PalletBlock.OpenPos
local DoorTo_EnergyRoom = Map.Doors:FindFirstChild("DoorTo_EnergyRoom")
local ProxPallet = Instance.new("ProximityPrompt", PalletBlock.Wooden_Pallet)

--//Values
local Opened = false

--//Setup
ProxPallet.MaxActivationDistance = GameConfigModule.InteractDistance
ProxPallet.RequiresLineOfSight = true
ProxPallet.Style = Enum.ProximityPromptStyle.Custom
ProxPallet.HoldDuration = 0.15
ProxPallet.ActionText = "Push"
ProxPallet.ObjectText = "Wooden Pallet"

ProxPallet.Triggered:Connect(function(plr)
	if not plr or not plr.Character then return end
	
	local char = plr.Character
	local hum = char:WaitForChild("Humanoid") :: Humanoid
	
	if hum.Health <= 0 then return end
	
	if not Opened then
		Opened = true
		ProxPallet.Enabled = false
		PalletBlock.Wooden_Pallet.PushSound:Play()
		
		local tween = Ts:Create(PalletBlock.Wooden_Pallet, TweenInfo.new(PalletBlock.Wooden_Pallet.PushSound.TimeLength, Enum.EasingStyle.Exponential), {CFrame = OpenPos.CFrame})
		tween:Play()
		
		tween.Completed:Connect(function()
			DoorTo_EnergyRoom.Locked.Value = false
		end)
	end
end)