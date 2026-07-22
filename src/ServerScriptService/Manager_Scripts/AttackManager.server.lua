--//Services
local Rs = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local AttackEvent = Remotes:FindFirstChild("Attack")

--//Modules
local DataFolder = ServerScriptService:FindFirstChild("Data")
local DataManager = require(DataFolder:FindFirstChild("DataManager"))

--//Others
local DefaultEffectAmount = 10

AttackEvent.OnServerEvent:Connect(function(plr, agentToAttack: Model, Damage: number, HitSound: Sound, HitEffect: ParticleEmitter, EffectAmount: number)
	if not agentToAttack then return end
	if not Damage then return end
	
	local Hum = agentToAttack:FindFirstChildWhichIsA("Humanoid")
	local RootPart = agentToAttack:FindFirstChild("HumanoidRootPart") :: BasePart
	local Hit = nil
	
	if agentToAttack:FindFirstChild("sndPart") then
		RootPart = agentToAttack:FindFirstChild("sndPart")
	end
	
	if HitSound then
		Hit = HitSound:Clone()
	end
	
	local debounce = true
	local HitParticle = nil
	local HitAmount = 0
	
	if HitEffect then
		HitParticle = HitEffect:Clone()
	end
	if EffectAmount then
		if EffectAmount > 0 then
			HitAmount = EffectAmount
		end
	end
	
	if Hit then
		Hit.Parent = RootPart
		Hit:Play()
	end
	
	if HitParticle then
		HitParticle.Parent = RootPart
	end
	
	Hum:TakeDamage(Damage)
	
	if HitAmount > 0 and HitParticle then
		HitParticle:Emit(EffectAmount)
	elseif HitParticle then
		HitParticle:Emit(DefaultEffectAmount)
	end
	
	if HitParticle then
		game.Debris:AddItem(HitParticle, 2)
	end
	
	if Hit then
		game.Debris:AddItem(Hit, 2)
	end
	
	if Hum.Health <= 0 then
		DataManager.AddKills(plr, 1)
	end
end)