local DailyRewardHandler = {}

function DailyRewardHandler.Init()
	--//Services
	local Rs = game:GetService("ReplicatedStorage")
	local ServerScriptService = game:GetService("ServerScriptService")
	
	--//Remotes
	local Remotes = Rs:FindFirstChild("Remotes")
	local ClaimDailyReward = Remotes:FindFirstChild("ClaimDailyReward")
	local ClaimAllDailyRewards = Remotes:FindFirstChild("ClaimAllDailyRewards")
	local RewardWarnEvent = Remotes:FindFirstChild("RewardWarnEvent")
	local UpdatePerkFunc = Remotes:FindFirstChild("UpdatePerk")
	
	--//Modules
	local ModulesFolder = Rs:FindFirstChild("Modules")
	local DataHandler = require(ModulesFolder:FindFirstChild("DataHandler"))
	local DailyRewards = require(ModulesFolder.Configs:FindFirstChild("DailyRewards"))
	local DataManager = require(ServerScriptService.Data:FindFirstChild("DataManager"))
	
	--//give the daily reward to player
	local function giveReward(player: Player, rewardName: string, rewardValue: any)
		print("giving daily reward: ", rewardName, rewardValue)
		if rewardName == "Coins" then
			RewardWarnEvent:FireClient(player, "Coins", rewardValue)
			DataManager.AddCoins(player, rewardValue)
		elseif rewardName == "Perk" then
			DataManager.AddPerk(player, rewardValue, 1) -- +1 perk item
			UpdatePerkFunc:InvokeClient(player, "update") -- update perk items on inventory
			RewardWarnEvent:FireClient(player, "Perk", 1, rewardValue) -- warn to client ta awarded a perk
		elseif rewardName == "Titles" then
			RewardWarnEvent:FireClient(player, "Title", 0, rewardValue)
			DataManager.AddItem(player, rewardValue, rewardName)
		elseif rewardName == "Character" then
			RewardWarnEvent:FireClient(player, "Character", 0, rewardValue)
			DataManager.AddNewChar(player, rewardValue)
		end
	end
	
	ClaimDailyReward.OnServerInvoke = function(player, dayReward)
		local plrProfile = DataHandler:GetProfileData(player)
		if not plrProfile then
			return
		end
		
		if plrProfile.CurrentDay == dayReward and not plrProfile.ClaimedDailyReward then
			plrProfile.ClaimedDailyReward = true
			plrProfile.RewardTime = 0
			
			--obs: the currentDay value is updated on DataStore script (CurrentDay += 1)
			
			if plrProfile.RewardType <= 1 then
				for rewardName, reward in pairs(DailyRewards.Rewards_1[dayReward]) do
					giveReward(player, rewardName, reward)
				end
			else
				for rewardName, reward in pairs(DailyRewards.Rewards_2[dayReward]) do
					giveReward(player, rewardName, reward)
				end
			end
			
			return true
		end
		
		return false
	end
	
	--//Player purchased claim all daily rewards product
	ClaimAllDailyRewards.Event:Connect(function(player: Player)
		local plrProfile = DataHandler:GetProfileData(player)
		if not plrProfile then
			return
		end
		
		local alreadyClaimed = 0
		if plrProfile.ClaimedDailyReward then
			alreadyClaimed = plrProfile.CurrentDay
		else
			alreadyClaimed = plrProfile.CurrentDay - 1
		end
		
		print("player already claimed reward to day: ", alreadyClaimed)
		
		if plrProfile.RewardType <= 1 then
			for i, v in DailyRewards.Rewards_1 do
				for rewardName, reward in pairs(v) do
					if i <= alreadyClaimed then continue end
					giveReward(player, rewardName, reward)
				end
			end
		else
			for i, v in DailyRewards.Rewards_2 do
				for rewardName, reward in pairs(v) do
					if i <= alreadyClaimed then continue end
					giveReward(player, rewardName, reward)
				end
			end
		end
		
		plrProfile.CurrentDay = 7
		plrProfile.ClaimedDailyReward = true
		plrProfile.RewardTime = 0
		
		ClaimDailyReward:InvokeClient(player, "Update") -- update daily rewards UI
	end)
end

return DailyRewardHandler