local Rs = game:GetService("ReplicatedStorage")
local ModulesFolder = Rs:FindFirstChild("Modules")
local BadgesModule = require(ModulesFolder:FindFirstChild("Badges"))
local Brick = script.Parent

local function PlayerTouched(Part)
	if not Part or not Part.Parent then return end
	local Parent = Part.Parent
	local plr = game.Players:GetPlayerFromCharacter(Parent)
	if plr then
		local badge = BadgesModule:FindBadge("Die Staircase")
		BadgesModule:GiveBadge(plr, badge.Id)
		Parent.Humanoid.Health = 0
	end
end

Brick.Touched:connect(PlayerTouched)