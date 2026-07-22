--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local GameConfigModule = require(ModulesFolder:FindFirstChild("GameConfigModule"))
local DialogModule = require(ModulesFolder:FindFirstChild("PlayerDialogModule"))

--//Asylum Reception Stuff
local Map = workspace:FindFirstChild("Map")
local AsylumReceptionFolder = Map:FindFirstChild("Area2_AsylumReception")
local InteractStuff = AsylumReceptionFolder:FindFirstChild("InteractStuff")

--//Npc's
local BathroomDeadGuy_Door = Map:FindFirstChild("Doors"):FindFirstChild("BathroomDeadGuy_Door")
local DeadGuyInteract = InteractStuff:FindFirstChild("DeadGuyInteract")

--//Values
local openedBathroomDoor = false
local plrsOnDebounceDeadGuy = {}

BathroomDeadGuy_Door.State.Changed:Connect(function(newValue)
	if newValue then
		if not openedBathroomDoor then
			openedBathroomDoor = true
			if DeadGuyInteract:FindFirstChildWhichIsA("Sound") then
				DeadGuyInteract:FindFirstChildWhichIsA("Sound"):Play()
			end
		end
	end
end)

local proxDeadGuy = Instance.new("ProximityPrompt", DeadGuyInteract)
proxDeadGuy.MaxActivationDistance = GameConfigModule.InteractDistance
proxDeadGuy.RequiresLineOfSight = false
proxDeadGuy.ActionText = "Inspect"
proxDeadGuy.ObjectText = "Dead Patient"
proxDeadGuy.Style = Enum.ProximityPromptStyle.Custom
proxDeadGuy.HoldDuration = 0.2

proxDeadGuy.Triggered:Connect(function(plr)
	if table.find(plrsOnDebounceDeadGuy, plr) then return end
	
	local function removeDebounce()
		for i, v in ipairs(plrsOnDebounceDeadGuy) do
			if v == plr then
				table.remove(plrsOnDebounceDeadGuy, i)
			end
		end
	end
	
	table.insert(plrsOnDebounceDeadGuy, plr)
	DialogModule.Dialog(false, plr, DeadGuyInteract.PlrDialog)
	task.delay(6, removeDebounce)
end)