local RagdollModule = {}

local Players = game:GetService("Players")
local ragdollStates = {}

function RagdollModule.enabledRagdoll(player: Player, pushOrigin: Vector3?)
	if not player or not player.Character then return end
	local character = player.Character
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	if ragdollStates[player] and ragdollStates[player].active then
		return
	end

	ragdollStates[player] = {
		active = true,
		connections = {},
	}

	humanoid.AutoRotate = false
	humanoid.PlatformStand = true

	for _, desc in ipairs(character:GetDescendants()) do
		if desc:IsA("Motor6D") then
			local part0 = desc.Part0
			local part1 = desc.Part1
			if part0 and part1 then
				local attachment0 = Instance.new("Attachment")
				attachment0.CFrame = desc.C0
				attachment0.Parent = part0

				local attachment1 = Instance.new("Attachment")
				attachment1.CFrame = desc.C1
				attachment1.Parent = part1

				local socket = Instance.new("BallSocketConstraint")
				socket.Attachment0 = attachment0
				socket.Attachment1 = attachment1
				socket.LimitsEnabled = true
				socket.TwistLimitsEnabled = true
				socket.UpperAngle = 45
				socket.TwistLowerAngle = -45
				socket.TwistUpperAngle = 45
				socket.Parent = part0

				desc.Enabled = false
				table.insert(ragdollStates[player].connections, {motor = desc, socket = socket, att0 = attachment0, att1 = attachment1})
			end
		end
	end

	if pushOrigin then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp and hrp:IsA("BasePart") then
			local direction = (hrp.Position - pushOrigin).Unit
			hrp:ApplyImpulse(direction * 2000)
			hrp:ApplyAngularImpulse(Vector3.new(math.random(-40, 40), math.random(-20, 20), math.random(-40, 40)))
		end
	end

	local deathConn = humanoid.Died:Connect(function()
		RagdollModule.disabledRagdoll(player)
	end)
	table.insert(ragdollStates[player].connections, deathConn)
end

function RagdollModule.disabledRagdoll(player: Player)
	if not ragdollStates[player] or not ragdollStates[player].active then
		return
	end

	local state = ragdollStates[player]
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if humanoid then
		humanoid.PlatformStand = false
		humanoid.AutoRotate = true
	end

	for _, ref in ipairs(state.connections) do
		if typeof(ref) == "RBXScriptConnection" then
			ref:Disconnect()
		elseif typeof(ref) == "table" then
			if ref.motor then
				ref.motor.Enabled = true
			end
			if ref.socket then
				ref.socket:Destroy()
			end
			if ref.att0 then
				ref.att0:Destroy()
			end
			if ref.att1 then
				ref.att1:Destroy()
			end
		end
	end

	ragdollStates[player] = nil
end

return RagdollModule