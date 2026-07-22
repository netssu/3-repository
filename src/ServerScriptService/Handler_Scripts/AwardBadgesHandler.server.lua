--//Services
local Rs = game:GetService("ReplicatedStorage")
local BadgeService = game:GetService("BadgeService")

--//Remotes
local AwardBadgeEvent = Rs:FindFirstChild("Remotes"):FindFirstChild("AwardBadge")

AwardBadgeEvent.OnServerEvent:Connect(function(plr, badgeId)
	if not plr or not badgeId then return end
	if not BadgeService:UserHasBadgeAsync(plr.UserId, badgeId) then
		BadgeService:AwardBadge(plr.UserId, badgeId)
	end
end)