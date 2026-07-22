local XmasEvent_2025 = {}

--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Modules
local Packages = Rs:FindFirstChild("Packages")
local Trove = require(Packages.Trove)
local Component = require(Packages.Component)
local DataHandler = require(Rs.Modules.DataHandler)

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local PlrDialog = Remotes:FindFirstChild("PlrDialog")

function XmasEvent_2025:Init()
	local ElfPlush = Component.new({
		Tag = "Elf_Plush",
		Ancestors = { workspace },
		Extensions = {},
	})
	
	function ElfPlush:Construct()
		self._trove = Trove.new()
	end
	
	ElfPlush.Started:Connect(function(component)
		local plushModel = component.Instance :: Model
		--print(component)
		
		local torsoPart = plushModel:FindFirstChild("Torso") :: BasePart
		local prox = torsoPart:FindFirstChildWhichIsA("ProximityPrompt")
		
		if not prox then
			warn("[XmasEvent2025] No prox on plush model: ", plushModel)
			return
		end
		
		component._trove:Connect(prox.Triggered, function(plr)
			local plushId = string.match(plushModel.Name, "%d+") :: number
			
			local plrData = DataHandler:GetProfileData(plr)
			if not plrData then
				return
			end
			
			for _, v: BasePart in plushModel:GetDescendants() do
				if v:IsA("BasePart") then
					v.Transparency = 1
					v.CanCollide = false
				end
			end
			
			local sndPart = Instance.new("Part")
			sndPart.Transparency = 1
			sndPart.Anchored = true
			sndPart.CanCollide = false
			sndPart.CFrame = torsoPart.CFrame
			sndPart.Parent = workspace
			
			local snd = game:GetService("SoundService").Effects.GiftSound:Clone()
			snd.Parent = sndPart
			snd:Play()
			
			game:GetService("Debris"):AddItem(snd, 10)
			game:GetService("Debris"):AddItem(sndPart, 10)
			
			if not plrData.Events.Xmas_2025.Plushies then
				plrData.Events.Xmas_2025.Plushies = {}
			end
			
			PlrDialog:FireClient(plr, nil, "[#"..plushId.."] Elf collected!")
			plrData.Events.Xmas_2025.Plushies[plushId] = true
			plushModel:Destroy()
		end)
	end)
	
	ElfPlush.Stopped:Connect(function(component)
		component._trove:Destroy()
	end)
end

function XmasEvent_2025:Start()
	
end

return XmasEvent_2025