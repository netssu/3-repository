local BadgesHandler = {}

function BadgesHandler.Init()
	--//Services
	local Rs = game:GetService("ReplicatedStorage")
	local BadgeService = game:GetService("BadgeService")
	
	--//Modules
	local ModulesFolder = Rs:FindFirstChild("Modules")
	local BadgesModule = require(ModulesFolder:FindFirstChild("Badges"))
	local DataManager = require(game:GetService("ServerScriptService").Data.DataManager)
	
	--//Remotes
	local Remotes = Rs:FindFirstChild("Remotes")
	local ClaimBadgeFunc = Remotes:FindFirstChild("ClaimBadge")
	local CheckForBadgeFunc = Remotes:FindFirstChild("CheckForBadge") or Instance.new("RemoteFunction", Remotes)
	CheckForBadgeFunc.Name = "CheckForBadge"
	
	--//Check if player have badge
	CheckForBadgeFunc.OnServerInvoke = function(plr: Player, badgeId: number)
		local success, hasBadge = pcall(function()
			return BadgeService:UserHasBadgeAsync(plr.UserId, badgeId)
		end)
		if success and hasBadge then
			return hasBadge
		elseif not success then
			print("Can't detect if", plr.Name, "has badge: ", badgeId, hasBadge)
		end
		return false
	end
	
	--//Claim badge reward
	ClaimBadgeFunc.OnServerInvoke = function(plr, badgeID, action)
		if action == "Claim" then
			local plrOtherValues = plr:FindFirstChild("OtherValues")
			local plrAwardedBadges = plrOtherValues:FindFirstChild("AwardedBadges")
			
			local success, result = pcall(function()
				return BadgeService:UserHasBadgeAsync(plr.UserId, badgeID)
			end)
			if success and result then -- Player has badge and can claim rewards if any
				local badgeInstance = plrAwardedBadges:FindFirstChild(badgeID)
				local haveRewards = false
				local foundBadge = false
				local rewards = {}
				
				--//Check if the badge has any rewards
				for _, diff in pairs(BadgesModule.Badges) do
					if foundBadge then break end
					for _, badge in ipairs(diff) do
						if typeof(badge) ~= "table" then continue end
						if tonumber(badgeID) == badge.Id then
							local rewardTable = badge.Reward
							foundBadge = true
							
							if typeof(rewardTable) == "table" and next(rewardTable) ~= nil then
								haveRewards = true
								rewards = badge.Reward
							else
								haveRewards = false
							end
							
							break
						end
					end
				end
				
				if haveRewards and not plrAwardedBadges:FindFirstChild(badgeID).Value then
					local rewardsReceived = {}
					local rewardAmounts = {Coins = 0, Chars = 0}
					
					DataManager.AwardBadge(plr, badgeID)
					
					for rewardType, reward in pairs(rewards) do
						if rewardType == "Character" then
							rewardsReceived["Character"] = true
							rewardAmounts.Chars += 1
						elseif rewardType == "Coins" then
							if plr:FindFirstChild("leaderstats"):FindFirstChild("Coins") then
								DataManager.AddCoins(plr, reward)
								rewardsReceived["Coins"] = true
								rewardAmounts.Coins += reward
							end
						else
							warn("Can't get reward of:", badgeID, "for player:", plr.Name, "| Type:", rewardType)
						end
					end
					
					return true, rewardsReceived, rewardAmounts
				else
					return false
				end
			end
		end
	end
end

return BadgesHandler