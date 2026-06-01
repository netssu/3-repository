--SERVICES
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local TS = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local BadgeService = game:GetService("BadgeService")

--REMOTES
local LoadRemote = RS:WaitForChild("Remotes").LoadRemote
local TutorialRemote = RS:WaitForChild("Remotes").TutorialRemote
local QuickRemote = RS:WaitForChild("Remotes").QuickRemote

local DataStoreModule = require(SS:WaitForChild("Modules").MainDataModule)

TutorialRemote.OnServerEvent:Connect(function(Plr, Action, StepName)
	-- 1. Grab the custom DataStore for the player
	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Plr.UserId)
	if not DataStore then return end

	-- 2. Verify physical folders exist
	local PlayerStats = Plr:FindFirstChild("PlayerStats")
	if not PlayerStats then return end

	local ExtendedTutorialSteps = PlayerStats:FindFirstChild("ExtendedTutorial")
	if not ExtendedTutorialSteps then return end

	-- 3. Process the Tutorial Step
	if Action == "CompleteStep" or Action == "CompleteSubStep" then
		local TargetStep = ExtendedTutorialSteps:FindFirstChild(StepName)

		if TargetStep then
			if Action == "CompleteStep" then
				-- Updates physical value (MainData has a connection to auto-save this)
				TargetStep.Value = true 

			elseif Action == "CompleteSubStep" then
				-- Updates physical attribute so the client knows to move on
				TargetStep:SetAttribute("SubStepComplete", true)

				-- CRITICAL FIX: Manually update the Datastore table because 
				-- MainData doesn't have a listener for GetAttributeChangedSignal!
				if DataStore.Value.ExtendedTutorial[StepName] then
					DataStore.Value.ExtendedTutorial[StepName].SubStepComplete = true
				end
				if StepName == "FifthStep" then
					if BadgeService:UserHasBadgeAsync(Plr.UserId, 3942085166248073) == false then
						BadgeService:AwardBadgeAsync(Plr.UserId, 3942085166248073)
					end
				end
			end
		end
	end

	-- Existing basic tutorial logic
	if Action == "TutorialComplete" then
		if DataStore.Value.FirstGame == true then
			if DataStore.Value.TutorialComplete == false then
				print("Tutorial Now Officially Complete!")
				DataStore.Value.TutorialComplete = true
				DataStore.playerstats.TutorialComplete.Value = true
				
				DataStore.Value.FirstGame = false
				DataStore.playerstats.FirstGame.Value = false
				
				if BadgeService:UserHasBadgeAsync(Plr.UserId, 2156879421600225) == false then
					BadgeService:AwardBadgeAsync(Plr.UserId, 2156879421600225)
				end
			end
		end
	end
end)

