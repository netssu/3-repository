--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local ActiveCutsceneEvent = Remotes:FindFirstChild("ActiveCutscene")

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local BadgesModule = require(ModulesFolder:FindFirstChild("Badges"))
local MoneyModule = require(ModulesFolder:FindFirstChild("MoneyModule"))

--//Asylum Reception Stuff
local Map = workspace:FindFirstChild("Map")
local AsylumReceptionFolder = Map:FindFirstChild("Area2_AsylumReception")
local InteractStuff = AsylumReceptionFolder:FindFirstChild("InteractStuff")

--//Chase Stuff
local ChaseEnd_Part = InteractStuff:FindFirstChild("Chase1_End")

--//Values
local alreadyPlrs = {}

local function enableFinalCutscene(plr: Player)
	if not plr then return end
	
	ActiveCutsceneEvent:FireClient(plr, "Chase1_FinalCutscene")
end

ChaseEnd_Part.Touched:Connect(function(hit)
	if not hit or not hit.Parent then return end
	
	if hit.Parent:FindFirstChild("Humanoid") and hit.Parent:FindFirstChild("Humanoid").Health > 0 then
		local plr = game.Players:GetPlayerFromCharacter(hit.Parent)
		if plr and not alreadyPlrs[plr.Name] then
			enableFinalCutscene(plr)
			alreadyPlrs[plr.Name] = true
			local badge = BadgesModule:FindBadge("Escape Chapter 1")
			BadgesModule:GiveBadge(plr, badge.Id)
			MoneyModule.Give(plr, math.random(50, 80))
		end
	end
end)