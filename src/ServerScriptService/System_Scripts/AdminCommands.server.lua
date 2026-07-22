--//lua was here
local Players = game:GetService("Players")
local AdminCommands = {}
AdminCommands.__index = AdminCommands

local ADMIN_USER_IDS = {
	[3296469635] = true,
	[1501440119] = true,
}

function AdminCommands.new()
	local self = setmetatable({}, AdminCommands)
	self.commands = {}
	self.connections = {}
	self:registerDefaultCommands()
	self:listen()
	print("AdminCommands started successfully")
	return self
end

function AdminCommands:isAdmin(plr)
	return ADMIN_USER_IDS[plr.UserId] == true
end

function AdminCommands:registerCommand(name, func)
	self.commands[name] = func
end

function AdminCommands:registerDefaultCommands()
	self:registerCommand("kick", function(plr, args)
		local target = Players:FindFirstChild(args[1])
		if target and target ~= plr then
			target:Kick("Kicked by admin.")
			print("kick command executed by", plr.Name, "on", target.Name)
		end
	end)
	self:registerCommand("heal", function(plr, args)
		local target = Players:FindFirstChild(args[1])
		if target and target.Character and target.Character:FindFirstChild("Humanoid") then
			target.Character.Humanoid.Health = target.Character.Humanoid.MaxHealth
			print("heal command executed by", plr.Name, "on", target.Name)
		end
	end)
	self:registerCommand("respawn", function(plr, args)
		local target = Players:FindFirstChild(args[1])
		if target then
			pcall(function()
				target:LoadCharacter()
			end)
			print("respawn command executed by", plr.Name, "on", target.Name)
		end
	end)
	self:registerCommand("teleport", function(plr, args)
		local target = Players:FindFirstChild(args[1])
		local dest = Players:FindFirstChild(args[2])
		if target and dest and dest.Character and dest.Character.PrimaryPart then
			pcall(function()
				if target.Character and target.Character.PrimaryPart then
					target.Character:SetPrimaryPartCFrame(dest.Character.PrimaryPart.CFrame)
					print("teleport command executed by", plr.Name, "from", target.Name, "to", dest.Name)
				end
			end)
		end
	end)
	self:registerCommand("setalive", function(plr, args)
		local target = Players:FindFirstChild(args[1])
		if target then
			local pv = target:FindFirstChild("PlayerValues")
			if pv then
				local alive = pv:FindFirstChild("IsAlive")
				if alive then
					alive.Value = args[2] == "true"
					print("setalive command executed by", plr.Name, "on", target.Name, "to", tostring(alive.Value))
				end
			end
		end
	end)
end

function AdminCommands:listen()
	local function onChatted(plr, msg)
		if not self:isAdmin(plr) then print("Non-admin attempt:", plr.Name, msg) return end
		if msg:sub(1,1) ~= ";" then return end
		local split = msg:sub(2):split(" ")
		local cmd = split[1]:lower()
		table.remove(split, 1)
		local fn = self.commands[cmd]
		if fn then
			local ok, err = pcall(function()
				fn(plr, split)
			end)
			if ok then
				print("Admin command executed:", cmd, "by", plr.Name)
			else
				print("Admin command error:", cmd, "by", plr.Name, err)
			end
		end
	end
	for _,plr in ipairs(Players:GetPlayers()) do
		table.insert(self.connections, plr.Chatted:Connect(function(msg)
			onChatted(plr, msg)
		end))
	end
	self.connections[#self.connections+1] = Players.PlayerAdded:Connect(function(plr)
		table.insert(self.connections, plr.Chatted:Connect(function(msg)
			onChatted(plr, msg)
		end))
	end)
end

function AdminCommands:destroy()
	for _,conn in ipairs(self.connections) do
		if conn.Disconnect then conn:Disconnect() end
	end
	self.connections = {}
end

return AdminCommands
