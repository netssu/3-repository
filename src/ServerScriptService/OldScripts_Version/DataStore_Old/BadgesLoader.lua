local BadgesLoader = {}

--//Get all plr Awarded badges and save
function BadgesLoader.SaveAwardedBadges(plr: Player)
	if not plr then warn("Can't save player awarded badges, no player received.") return end
	
	--//Services
	local Rs = game:GetService("ReplicatedStorage")
	local BadgeService = game:GetService("BadgeService")
	
	--//Modules
	local ModulesFolder = Rs:FindFirstChild("Modules")
	local BadgesModule = require(ModulesFolder:FindFirstChild("Badges"))
	
	--//Plr Stuff
	local OtherValues = plr:FindFirstChild("OtherValues")
	local AwardedBadges = OtherValues:FindFirstChild("AwardedBadges")
	
	for _, diff in pairs(BadgesModule.Badges) do
		for _, badge in ipairs(diff) do
			if AwardedBadges:FindFirstChild(tostring(badge.Id)) then
				continue
			else
				--//Player don't have the badge saved, detect if has Badge to save
				local success, result = pcall(function()
					return BadgeService:UserHasBadgeAsync(plr.UserId, badge.Id)
				end)
				if success then
					local newBadge = Instance.new("BoolValue", AwardedBadges)
					newBadge.Name = tostring(badge.Id)
					newBadge.Value = false -- Player don't claimed reward yet
				else
					warn("Can't detect if player has badge: ", badge.Id)
				end
			end
		end
	end
end

return BadgesLoader