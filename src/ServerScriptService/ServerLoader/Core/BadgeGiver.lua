local badgeGiver = {}

function badgeGiver.Init()
	--//Services
	local badgeService = game:GetService("BadgeService")
	local rs = game:GetService("ReplicatedStorage")
	
	--//Modules
	local modulesFolder = rs:FindFirstChild("Modules")
	local gameConfig = require(rs:FindFirstChild("GameConfig"))
	local badgesModule = require(modulesFolder:FindFirstChild("Badges"))
	
	local function findBadge(badgeName)
		for i, badgeTable in pairs(badgesModule.Badges) do
			for i, badge in ipairs(badgeTable) do
				if badge.Name == badgeName then
					return badge
				end
			end
		end
		return nil
	end
	
	--//Give the group badge
	local function checkGroupBadge(player)
		local badge = findBadge("Join Group")
		if not badge or not badge.Enabled or not player then return end
		if badgeService:UserHasBadgeAsync(player.UserId, badge.Id) then
			return
		elseif player:IsInGroup(gameConfig.groupid) then
			badgeService:AwardBadge(player.UserId, badge.Id)
		end
	end
	
	--//Give the alpha tester badge
	local function checkAlphaBadge(player)
		local badge = findBadge("Alpha Tester")
		if not badge or not badge.Enabled or not player then return end
		if badgeService:UserHasBadgeAsync(player.UserId, badge.Id) then
			return
		else
			badgeService:AwardBadge(player.UserId, badge.Id)
		end
	end
	
	--//Give the welcome badge
	local function checkWelcomeBadge(player)
		local badge = findBadge("Welcome")
		if not badge or not badge.Enabled or not player then return end
		if badgeService:UserHasBadgeAsync(player.UserId, badge.Id) then
			return
		else
			badgeService:AwardBadge(player.UserId, badge.Id)
		end
	end
	
	--//Give the met a dev badge
	local function checkDevsBadge(player)
		local badge_Owner = findBadge("Met Owner")
		local badge_Dev1 = findBadge("Met Thurzin")
		local badge_Dev2 = findBadge("Met yungbasco")
		local badge_Dev3 = findBadge("Met overkillexo")
		
		local ownerId = 6011988811
		local dev1Id = 1436215361
		local dev2Id = 33840268
		local dev3Id = 1751925923
		
		for _, plr in game.Players:GetPlayers() do
			if plr.UserId == ownerId then
				for i, v in game.Players:GetPlayers() do
					badgesModule:GiveBadge(v, badge_Owner.Id)
				end
			elseif plr.UserId == dev1Id then
				for i, v in game.Players:GetPlayers() do
					badgesModule:GiveBadge(v, badge_Dev1.Id)
				end
			elseif plr.UserId == dev2Id then
				for i, v in game.Players:GetPlayers() do
					badgesModule:GiveBadge(v, badge_Dev2.Id)
				end
			elseif plr.UserId == dev3Id then
				for i, v in game.Players:GetPlayers() do
					badgesModule:GiveBadge(v, badge_Dev3.Id)
				end
			end
		end
	end
	
	--//Is in group badge
	game.Players.PlayerAdded:Connect(function(player)
		checkGroupBadge(player)
		checkAlphaBadge(player)
		checkWelcomeBadge(player)
		coroutine.wrap(function()
			while task.wait(20) do
				checkDevsBadge(player)
			end
		end)()
	end)
end

return badgeGiver