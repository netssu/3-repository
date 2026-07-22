local meleeModule = {}

--//Services
local MarketPlaceService = game:GetService("MarketplaceService")
local Rs = game:GetService("ReplicatedStorage")

--//Modules
local ModulesFolder = Rs:WaitForChild("Modules")
local GameConfigModule = require(ModulesFolder:FindFirstChild("GameConfigModule"))

--//Values - Pass
local ExtraStrength_20 = 1328376906 -- 20% Extra Strength

meleeModule.DetectAttack = function(playerChar, origin: Vector3, direction: Vector3, hitboxSize: Vector3)
	local hitTargets = {}
	
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {playerChar}
	overlapParams.MaxParts = 0
	
	local center = origin + (direction / 2)
	local parts = workspace:GetPartBoundsInBox(CFrame.new(center, center + direction), hitboxSize, overlapParams)
	
	for _, part in ipairs(parts) do
		if not part or not part.Parent then continue end
		local model = part.Parent
		if model and model:FindFirstChild("Humanoid") and not model:HasTag("Monster") then
			local isPlayer = game.Players:GetPlayerFromCharacter(model)
			if not isPlayer then
				local rayParams = RaycastParams.new()
				rayParams.FilterDescendantsInstances = {playerChar, model}
				rayParams.FilterType = Enum.RaycastFilterType.Exclude
				
				local modelOrigin = model.PrimaryPart
				if not modelOrigin then continue end
				local ray = workspace:Raycast(origin, modelOrigin.Position - origin, rayParams)
				if not ray then
					if not table.find(hitTargets, model) then
						table.insert(hitTargets, model)
					end
				end
			end
		end
	end
	
	return hitTargets
end

function meleeModule:GetPlrDamage(Plr: Player) : number
	local defaultDamage = GameConfigModule.DefaultDamage
	local multiplier = 1
	
	pcall(function()
		if MarketPlaceService:UserOwnsGamePassAsync(Plr.UserId, ExtraStrength_20) then
			multiplier += 0.2 -- 20% Extra Strength
		end
	end)
	
	return defaultDamage * multiplier
end

meleeModule.Attack = function(playerChar, origin, direction, plrAnim, attackSnd, hitSnd, damage, hitParticle, maxHit, hbSize)
	maxHit = maxHit or 1
	
	local animAttack = playerChar.Humanoid.Animator:LoadAnimation(plrAnim)
	local AttackEvent = Rs:WaitForChild("Remotes"):WaitForChild("Attack")
	
	animAttack:Play()
	attackSnd:Play()
	
	local hitboxSize = hbSize or Vector3.new(2.5, 2.5, 3)
	local hitTargets = meleeModule.DetectAttack(playerChar, origin, direction, hitboxSize)
	
	local hitCount = 0
	for _, target in ipairs(hitTargets) do
		if hitCount >= maxHit then break end
		hitCount += 1
		AttackEvent:FireServer(target, damage, hitSnd, hitParticle, 12)
	end
end

return meleeModule