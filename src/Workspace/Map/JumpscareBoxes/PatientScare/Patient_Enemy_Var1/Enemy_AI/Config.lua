local config = {}

config.NormalSpeed = 5.5
config.ChasingSpeed = 7
config.DetectionRange = 40 -- How far the monster can deterct a player
config.persistence = 140 -- put a value between 50 - 200 (lower value = monster will give up easily)
config.Damage = 15
config.DamageDelay = 1
config.AttackDistance = 3.5
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
