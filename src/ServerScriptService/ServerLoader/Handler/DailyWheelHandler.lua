local DailyRewardHandler = {}

function DailyRewardHandler.Init()
	--//Services
	local Rs = game:GetService("ReplicatedStorage")
	local ServerScriptService = game:GetService("ServerScriptService")
	
	--//Remotes
	local Remotes = Rs:FindFirstChild("Remotes")
	local CheckDailyRewardFunc = Remotes:FindFirstChild("CheckDailyReward")
	local RewardWarnEvent = Remotes:FindFirstChild("RewardWarnEvent")
	local UpdatePerkFunc = Remotes:FindFirstChild("UpdatePerk")
	
	--//Modules
	local ModulesFolder = Rs:FindFirstChild("Modules")
	local DataHandler = require(ModulesFolder:FindFirstChild("DataHandler"))
	local DataManager = require(ServerScriptService.Data:FindFirstChild("DataManager"))
	
	CheckDailyRewardFunc.OnServerInvoke = function(player: Player, action: string?, reward: {}?, purchased: boolean)
		local profileData = DataHandler:GetProfileData(player)
		if not profileData then
			return
		end
		
		if action == "GiveReward" and (profileData.DailyReward or purchased) then
			for rewardType, rewardValue in reward.Rewards do
				if rewardType == "Coins" then
					RewardWarnEvent:FireClient(player, "Coins", rewardValue)
					DataManager.AddCoins(player, rewardValue)
				elseif rewardType == "Perk" then
					DataManager.AddPerk(player, rewardValue, 1) -- +1 perk item
					UpdatePerkFunc:InvokeClient(player, "update") -- update perk items on inventory
				elseif rewardType == "Titles" then
					DataManager.AddItem(player, rewardValue, rewardType)
				end
			end
			if not purchased then -- player don't purchased to have the spin reward, claimed by daily time, so disable it
				profileData.DailyReward = false
				profileData.DailyTime = 0
			end
			return true
		end
		
		--[[local claimed = false
		if profileData.DailyReward == true then
			profileData.DailyTime = 0
			claimed = true
		end
		profileData.DailyReward = false
		
		return claimed -- return if player claimed or not the daily reward]]
		
		if profileData.DailyReward == true then
			return true -- can claim
		end
		return false -- can't claim
	end
end

return DailyRewardHandler