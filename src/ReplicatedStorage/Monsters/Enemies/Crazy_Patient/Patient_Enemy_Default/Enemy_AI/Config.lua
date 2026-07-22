local config = {}

config.NormalSpeed = 6
config.ChasingSpeed = 8
config.DetectionRange = 40 -- How far the monster can deterct a player
config.persistence = 120 -- put a value between 50 - 200 (lower value = monster will give up easily)
config.Damage = 10
config.DamageDelay = 1
config.AttackDistance = 3
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
