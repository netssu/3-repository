local RunService = game:GetService("RunService")
local Player = game.Players.LocalPlayer
local character = script.Parent

local anims = {
	["Walk"] = "rbxassetid://97950135219959",
	["Idle"] = "rbxassetid://97822033598956",
	["Run"] = "rbxassetid://97950135219959",
	["Jump"] = "rbxassetid://99366001267688",
	["Fall"] = "rbxassetid://136956437345922"
}

local function loadCustomAnims()
	local animateScript = character:WaitForChild("Animate")
	
	--//Walk
	local walkAnimation = animateScript:WaitForChild("walk")
	for i, v: Animation in walkAnimation:GetChildren() do
		v.AnimationId = anims.Walk
	end
	
	--//Idle
	local idleAnimation = animateScript:WaitForChild("idle")
	for i, v: Animation in idleAnimation:GetChildren() do
		v.AnimationId = anims.Idle
	end
	
	--//Run
	local runAnimation = animateScript:WaitForChild("run")
	for i, v: Animation in runAnimation:GetChildren() do
		v.AnimationId = anims.Run
	end
	
	--//Jump
	local jumpAnimation = animateScript:WaitForChild("jump")
	for i, v: Animation in jumpAnimation:GetChildren() do
		v.AnimationId = anims.Jump
	end
	
	--//Fall
	local fallAnimation = animateScript:WaitForChild("fall")
	for i, v: Animation in fallAnimation:GetChildren() do
		v.AnimationId = anims.Fall
	end
end

loadCustomAnims()