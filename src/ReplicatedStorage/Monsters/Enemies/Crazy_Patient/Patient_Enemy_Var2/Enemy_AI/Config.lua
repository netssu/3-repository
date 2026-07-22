local config = {}

config.NormalSpeed = 6
config.ChasingSpeed = 12
config.DetectionRange = 35 -- How far the monster can deterct a player
config.persistence = 150 -- put a value between 50 - 200 (lower value = monster will give up easily)
config.Damage = 6
config.DamageDelay = 0.8
config.AttackDistance = 2.5
config.NoisesDelay = math.random(6, 10) -- How long between each random monster noise
config.Wander = true
config.Visualize = false -- Testing
config.Depuration = false

config.agentParams = {
	["AgentRadius"] = 3,
	["AgentHeight"] = 4,
	["AgentCanJump"] = false,
	["AgentCanClimb"] = false,
}

return config
