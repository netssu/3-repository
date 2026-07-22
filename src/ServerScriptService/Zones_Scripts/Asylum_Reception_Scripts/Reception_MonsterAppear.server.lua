--//Services
local Ts = game:GetService("TweenService")
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local ActiveCutsceneEvent = Remotes:FindFirstChild("ActiveCutscene")

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local ObjectivesModule = require(ModulesFolder:FindFirstChild("ObjectivesModule"))
local TeleportModule = require(ModulesFolder:FindFirstChild("TeleportModule"))
local DialogModule = require(ModulesFolder:FindFirstChild("PlayerDialogModule"))

--//Asylum Reception Stuff
local Map = workspace:FindFirstChild("Map")
local AsylumReceptionFolder = Map:FindFirstChild("Area2_AsylumReception")
local InteractStuff = AsylumReceptionFolder:FindFirstChild("InteractStuff")

local Chest = InteractStuff:FindFirstChild("Chest")
local EletricBox = InteractStuff:FindFirstChild("EletricBox")
local PaperCodes = InteractStuff:FindFirstChild("PaperCode_SectionB"):FindFirstChild("Interact_PaperCode")
local RollPad = InteractStuff:FindFirstChild("BlockB_Panel")

--//Monster Appear
local Monster_AI = Rs:FindFirstChild("Monsters"):FindFirstChild("DemogorgonMonster"):FindFirstChild("Demogorgon")
local ActiveMonster = InteractStuff:FindFirstChild("MonsterActive")
local MonsterSpawn = InteractStuff:FindFirstChild("MonsterSpawn")
local MonsterBarrier1 = InteractStuff:FindFirstChild("MonsterBarrier1")
local MonsterBarrier2 = InteractStuff:FindFirstChild("MonsterBarrier2")

--//Values
local ActiveDebounce = true
local SpawnMonsterDebounce = true

ActiveMonster.Touched:Connect(function(hit)
	if hit and hit.Parent:FindFirstChildWhichIsA("Humanoid") then
		if hit.Parent:FindFirstChildWhichIsA("Humanoid").Health > 0 then
			local plr = game.Players:GetPlayerFromCharacter(hit.Parent)
			if plr and ActiveDebounce then
				ActiveDebounce = false
				ActiveCutsceneEvent:FireAllClients("FlayedAppear")
				MonsterBarrier1.CanCollide = true
				MonsterBarrier2.CanCollide = true
				
				task.delay(1.5, function()
					TeleportModule:Teleport("FlayedAppear", script, true, true)
					task.wait(1.2)
					ObjectivesModule.NewObjective(true, "SectionB_Door", "Section B", "Search for the correct code and open the door to Section B.")
				end)
			end
		end
	end
end)

ActiveCutsceneEvent.OnServerEvent:Connect(function(plr, event)
	if event == "FlayedAppear" and SpawnMonsterDebounce then
		SpawnMonsterDebounce = false
		MonsterBarrier1.CanCollide = false
		
		local Monster = Monster_AI:Clone()
		Monster.Parent = Map:FindFirstChild("Monsters")
		Monster.PrimaryPart:PivotTo(MonsterSpawn.CFrame)
		Monster.Humanoid.WalkSpeed = 0
		
		--//Delay, so players can run from the monster
		task.delay(1, function()
			Monster.Humanoid.WalkSpeed = 14
		end)
		
		task.wait(1.7)
		
		DialogModule.Dialog(false, plr, nil, "I have to hide quickly!")
		
		task.wait(1)
		
		MonsterBarrier2.CanCollide = false
		
		--//Show objectives prompts
		Chest.BillboardGui.Enabled = true
		EletricBox.BillboardGui.Enabled = true
		PaperCodes.BillboardGui.Enabled = true
		RollPad.BillboardGui.Enabled = true
	end
end)