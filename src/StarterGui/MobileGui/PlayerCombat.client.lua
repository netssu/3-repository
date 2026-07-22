--//Services
local Rs = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

--//Player
local Player = game.Players.LocalPlayer
local Char = Player.Character or Player.CharacterAdded:Wait()
local Hum = Char:WaitForChild("Humanoid") :: Humanoid
local Camera = workspace.CurrentCamera

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local AttackEvent = Remotes:FindFirstChild("Attack")
local PlayerValuesEvent = Remotes:FindFirstChild("PlayerValues") -- for killer badge (moved to attack manager)

--//Modules
local ModulesFolder = Rs:WaitForChild("Modules")
local GameConfigModule = require(ModulesFolder:WaitForChild("GameConfigModule"))
local MeleeModule = require(ModulesFolder:WaitForChild("MeleeModule"))
local BadgesModule = require(ModulesFolder:WaitForChild("Badges"))

--//UI
local AttackButton = script.Parent.MainFrame:FindFirstChild("AttackButton")

--//Animations
local PunchAnimationsFolder = script:FindFirstChild("PunchAnims")

--//Sounds
local AttackSoundsFolder = script:FindFirstChild("AttackSounds")
local HitSoundsFolder = script:FindFirstChild("HitSounds")

--//Particles
local ParticlesFolder = script:FindFirstChild("Particles")
local VFXFolder = Rs:WaitForChild("VFX")

--//Values
local lastAnim = nil
local attackDelay = 0.5
local debounce = true
local range = 5
local maxHit = 1
local hitBoxSize = Vector3.new(2.5, 2.5, 3)
local hitBoxOffset = Vector3.new(0, 0, hitBoxSize.Z/2)

function createHitBox()
	local HB = Instance.new("Part")
	HB.Size = hitBoxSize
	HB.CFrame = Char.HumanoidRootPart.CFrame + Camera.CFrame.LookVector * hitBoxOffset.Z
	HB.Anchored = true
	HB.CanCollide = false
	HB.Color = Color3.new(1, 0.101961, 0.101961)
	HB.Transparency = 1
	HB.Parent = game.Workspace
	game.Debris:AddItem(HB, 5)
	return HB
end

function showRaycast(origin, direction)
	local part = Instance.new("Part", workspace)
	local posOffSet = Vector3.new(0, 0, range/2)
	part.Size = Vector3.new(0.2, 0.2, direction.Magnitude)
	part.CFrame = CFrame.new(origin, origin + direction) * CFrame.new(0, 0, posOffSet.Z)
	part.Anchored = true
	part.CanCollide = false
	part.Color = Color3.new(1, 0.466667, 0.466667)
	part.Transparency = 0.5
	game.Debris:AddItem(part, 0.2)
end

local function plrAttack()
	debounce = false
	
	local randomPunchSound = AttackSoundsFolder:GetChildren()[math.random(1, #AttackSoundsFolder:GetChildren())]
	
	if randomPunchSound then
		randomPunchSound:Play()
	end
	
	local animToPlay = nil
	
	if #PunchAnimationsFolder:GetChildren() > 1 then
		local randomAnim = PunchAnimationsFolder:GetChildren()[math.random(1, #PunchAnimationsFolder:GetChildren())]
		animToPlay = Hum.Animator:LoadAnimation(randomAnim)
		
		if randomAnim.Name == lastAnim then
			repeat wait()
				local randomAnim = PunchAnimationsFolder:GetChildren()[math.random(1, #PunchAnimationsFolder:GetChildren())]
				animToPlay = Hum.Animator:LoadAnimation(randomAnim)
			until randomAnim.Name ~= lastAnim
		end
		
		lastAnim = randomAnim.Name
	else
		local randomAnim = PunchAnimationsFolder:GetChildren()[math.random(1, #PunchAnimationsFolder:GetChildren())]
		animToPlay = Hum.Animator:LoadAnimation(randomAnim)
		lastAnim = randomAnim.Name
	end
	
	if animToPlay then
		animToPlay:Play()
	end
	
	--[[local hitBox = createHitBox()
	local hitBoxDebounce = true
	local rayCastParams = RaycastParams.new()
	rayCastParams.FilterDescendantsInstances = {Char}
	rayCastParams.FilterType = Enum.RaycastFilterType.Exclude
	]]
	
	if not Char:FindFirstChild("HumanoidRootPart") then return end
	
	local origin, direction = Char.HumanoidRootPart.Position, Camera.CFrame.LookVector * range
	
		--[[local rayCast = workspace:Raycast(origin, direction, rayCastParams)
		--showRaycast(origin, direction)
		
		if rayCast and rayCast.Instance then
			if rayCast.Instance.Parent:FindFirstChild("Humanoid") then
				local plr = game.Players:GetPlayerFromCharacter(rayCast.Instance.Parent)
				if not plr then
					local agent = rayCast.Instance.Parent
					local damage = GameConfigModule.DefaultDamage
					local hitSound = HitSoundsFolder:GetChildren()[math.random(1, #HitSoundsFolder:GetChildren())]
					
					AttackEvent:FireServer(agent, damage, hitSound, ParticlesFolder.BloodHit3, 12)
				end
			end
		end
		]]
	
	local agentsHits = MeleeModule.DetectAttack(Char, origin, direction, hitBoxSize)
	local hitCount = 0
	
	if agentsHits then
		local damage = MeleeModule:GetPlrDamage(Player) or GameConfigModule.DefaultDamage
		local currentMutliplier = 1
		
		local hitSound = HitSoundsFolder:GetChildren()[math.random(1, #HitSoundsFolder:GetChildren())]
		for _, agent in ipairs(agentsHits) do
			if hitCount >= maxHit then break end
			
			hitCount += 1
			AttackEvent:FireServer(agent, damage, hitSound, VFXFolder.BloodSplatter, 20)
			
			task.delay(2, function()
				if agent.Humanoid.Health <= 0 then
					task.wait(1)
					if Player:FindFirstChild("leaderstats") then
						if Player:FindFirstChild("leaderstats"):FindFirstChild("Kills") then
							if Player:FindFirstChild("leaderstats"):FindFirstChild("Kills").Value >= 10 then
								local badge = BadgesModule:FindBadge("The Killer")
								BadgesModule:GiveBadge(Player, badge.Id)
							end
						end
					end
				end
			end)
		end
	end
	
	--[[if agentHit then
		local damage = GameConfigModule.DefaultDamage
		local hitSound = HitSoundsFolder:GetChildren()[math.random(1, #HitSoundsFolder:GetChildren())]
		
		AttackEvent:FireServer(agentHit, damage, hitSound, ParticlesFolder.BloodHit3, 12)
	end]]
	
		--[[
		hitBox.Touched:Connect(function(hit)
			if hit and hit.Parent then
				if hit.Parent:FindFirstChild("Humanoid") then
					local plr = game.Players:GetPlayerFromCharacter(hit.Parent)
					if hitBoxDebounce and not plr then
						hitBoxDebounce = false
						
						local agent = hit.Parent
						local damage = GameConfigModule.DefaultDamage
						local hitSound = HitSoundsFolder:GetChildren()[math.random(1, #HitSoundsFolder:GetChildren())]
						
						AttackEvent:FireServer(agent, damage, hitSound, ParticlesFolder.BloodHit3, 12)
					end
				end
			end
		end)
		]]
	
	--game.Debris:AddItem(hitBox, 0.3)
	
	task.wait(attackDelay)
	
	debounce = true
end

UIS.InputBegan:Connect(function(input, gameprocessed)
	if gameprocessed then return end
	if Hum.Health <= 0 then return end
	if Player.PlayerValues.OnCutscene.Value then return end
	if Player.PlayerValues.Crouching.Value then return end
	if Player.PlayerValues.OnInspect.Value then return end
	if Char:FindFirstChildWhichIsA("Tool") then return end
	
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2) and debounce then
		plrAttack()
	end
end)

Char.ChildAdded:Connect(function(child)
	if child:IsA("Tool") then
		AttackButton.Visible = false
	end
end)

Char.ChildRemoved:Connect(function()
	if not Char:FindFirstChildWhichIsA("Tool") then
		AttackButton.Visible = true
	end
end)

--//Mobile
AttackButton.MouseButton1Click:Connect(function()
	if not Player or not Player.Character then return end
	
	if Char:FindFirstChildWhichIsA("Tool") then AttackButton.Visible = false return end
	
	if debounce then
		plrAttack()
	end
end)