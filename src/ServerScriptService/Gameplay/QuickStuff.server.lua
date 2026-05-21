--SERVICES
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local TS = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local BadgeService = game:GetService("BadgeService")

--REMOTES
local LoadRemote = RS:WaitForChild("Remotes").LoadRemote
local QuickRemote = RS:WaitForChild("Remotes").QuickRemote

local DataStoreModule = require(SS:WaitForChild("Modules").MainDataModule)

QuickRemote.OnServerEvent:Connect(function(plr,Action,StatName,Amount)
	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, plr.UserId)
	if Action == "Give" and plr and StatName and Amount then
		local StatVal = nil
		if plr.leaderstatValues:FindFirstChild(StatName) then
			StatVal = plr.leaderstatValues:FindFirstChild(StatName)
		elseif plr.PlayerStats:FindFirstChild(StatName) then
			StatVal = plr.PlayerStats:FindFirstChild(StatName)
		end
		if StatVal == nil then
			return
		end
		if string.find(Amount,"%d+") then
			DataStore.Value[StatVal.Name] += Amount
			StatVal.Value = DataStore.Value[StatVal.Name] 
			return
		end
	end
end)

