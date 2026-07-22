--//Give group badge if player is in group

local badgeService = game:GetService("BadgeService")
local gameConfig = require(game:GetService("ReplicatedStorage"):FindFirstChild("GameConfig"))

game.Players.PlayerAdded:Connect(function(player)
	if badgeService:UserHasBadgeAsync(player.UserId, 428089155703396) then
		return
	elseif player:IsInGroup(gameConfig.groupid) then
		badgeService:AwardBadge(player.UserId, 428089155703396)
	end
end)