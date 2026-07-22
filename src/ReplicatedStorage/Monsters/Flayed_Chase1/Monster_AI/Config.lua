local config = {}

config.NormalSpeed = 12
config.FollowingSpeed = 15
config.ChasingSpeed = 21 -- THE CHASE SPEED
config.DetectionRange = 200 -- How far the monster can deterct a player
config.DetectionFov = 160 --  Monster vision
config.MaxTries = 2 -- How many times the monster will try to find a lost target, above 2 the monster will be extremely smart
config.Jumpscare = true
config.Damage = 100
config.DamageDelay = 1
config.KillDelay = 3 -- How long the monster will wait after killing a player
config.HitKill = true -- Will kill a target with 1 hit and will jumpscare
config.AttackDistance = 18
config.NoisesDelay = 6 -- How long between each random monster noise
config.Wander = true
config.Visualize = false -- Testing

config.agentParams = {
	["AgentRadius"] = 2.25,
	["AgentHeight"] = 9,
	["AgentCanJump"] = false,
	["AgentCanClimb"] = false,
}

return config
