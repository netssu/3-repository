local AnimModule = {}
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera

AnimModule.ServerAnims = {}
local Connections = {}
local function getAnimator(Char)
	local humanoid = Char:FindFirstChildOfClass("Humanoid")
	return humanoid and humanoid:FindFirstChildOfClass("Animator")
end

function AnimModule.LoadClientAnimTracks(Plr)
	if not Plr then return end
	local Char = Plr.Character

	local Animator = getAnimator(Char)
	if not Animator then return end

	-- Clear previous animations if character changed
	if AnimModule.ServerAnims[Plr.UserId] then
		for _, track in pairs(AnimModule.ServerAnims[Plr.UserId]) do
			track:Stop()
		end
	end

	AnimModule.ServerAnims[Plr.UserId] = {}

	for _, Anim in pairs(RS.Animations:GetDescendants()) do
		if Anim:IsA("Animation") then
			local AnimTrack = Animator:LoadAnimation(Anim)
			--AnimTrack.Priority = Enum.AnimationPriority.Action
			AnimModule.ServerAnims[Plr.UserId][Anim.Name] = AnimTrack
			if Anim.Name == "CustomWalk" then
				AnimTrack:AdjustSpeed(1.35)
			end
		end
	end
	print(AnimModule.ServerAnims)
end

function AnimModule.PlayClientAnim(Plr, Char, AnimName)
	if not (Plr and Char and AnimName) then return end

	-- Reload animations if not loaded
	if not AnimModule.ServerAnims[Plr.UserId] then
		AnimModule.LoadClientAnimTracks(Plr)
	end

	local animTrack = AnimModule.ServerAnims[Plr.UserId][AnimName]
	if animTrack then
		animTrack:Play()
		if animTrack.Name == "CustomWalk" then
			animTrack:AdjustSpeed(1.35)
		end
	else
		warn("Animation track not found:", AnimName)
	end
end

function AnimModule.StopClientAnim(Plr, Char, AnimName)
	if not (Plr and Char and AnimName) then return end

	-- Reload animations if not loaded
	if not AnimModule.ServerAnims[Plr.UserId] then
		AnimModule.LoadClientAnimTracks(Plr)
	end

	local animTrack = AnimModule.ServerAnims[Plr.UserId][AnimName]
	if animTrack then
		animTrack:Stop()
	else
		warn("Animation track not found:", AnimName)
	end
end

function AnimModule.IsClientPlaying(Plr,Char,AnimName)
	if not (Plr and Char and AnimName) then return end
	if not AnimModule.ServerAnims[Plr.UserId] then
		AnimModule.LoadClientAnimTracks(Plr)
	end
	local animTrack = AnimModule.ServerAnims[Plr.UserId][AnimName]

	if animTrack then
		return animTrack.IsPlaying
	else
		return false
	end
end

function AnimModule.StopOtherIdles(Plr,Char,AnimName)
	if not (Plr and Char and AnimName) then return end
	if not AnimModule.ServerAnims[Plr.UserId] then
		AnimModule.LoadClientAnimTracks(Plr)
	end
	
	for i,IdleAnim in pairs(AnimModule.ServerAnims[Plr.UserId]) do
		if i == AnimName then
			continue
		end
		if string.find(i,"Idle") then
			IdleAnim:Stop()
		end
	end
end


return AnimModule