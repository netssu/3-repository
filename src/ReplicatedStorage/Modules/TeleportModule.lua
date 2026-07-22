local TeleportModule = {}

--//Services
local Players = game:GetService("Players")
local Rs = game:GetService("ReplicatedStorage")

--//Teleport Stuff
local TeleportZones = workspace:FindFirstChild("Map"):FindFirstChild("TeleportZones")
local CurrentGameZone = Rs:FindFirstChild("CurrentGameZone")
local ZoneTransitionFunc = Rs:FindFirstChild("Remotes"):FindFirstChild("ZoneTransition")

--//Values
local MaxWaitTime = 15

-- Teleport alive player to a determined game zone. (Ignore value is if are to update CurrentGame Zone)
function TeleportModule:Teleport(Zone: string, Activator: Instance?, QuickTeleport: boolean, Ignore: boolean)
	local zoneTeleport  = TeleportZones:FindFirstChild(Zone)
	if zoneTeleport then
		if not Ignore then
			CurrentGameZone.Value = Zone -- Update current game zone
		end
		
		for i, plr in ipairs(Players:GetPlayers()) do
			task.spawn(function()
				local Char = plr.Character
				local PlrValues = plr:FindFirstChild("PlayerValues")
				local IsAlive = PlrValues:FindFirstChild("IsAlive")
				local HumanoidRootPart = nil
				local teleported = false
				
				if Char:FindFirstChild("HumanoidRootPart") then
					HumanoidRootPart = Char:FindFirstChild("HumanoidRootPart") :: BasePart
				end
				
				if HumanoidRootPart and IsAlive.Value then -- If not IsAlive value is because player is specting.
					local maxTimeReached = false
					local plrTransition = nil
					
					if not QuickTeleport then
						pcall(function()
							plrTransition = ZoneTransitionFunc:InvokeClient(plr, zoneTeleport.Name)
						end)
					end
					
					local function TransitionTime()
						task.wait(MaxWaitTime)
						maxTimeReached = true
						return true
					end
					
					if not QuickTeleport then
						task.spawn(TransitionTime)
						task.wait(2) -- Delay, so the player can't see the teleport
					else
						maxTimeReached = true
					end
					
					for i, v: BasePart in zoneTeleport:GetChildren() do
						local OcupedValue = v:FindFirstChild("Ocuped") :: BoolValue
						if OcupedValue then
							if not OcupedValue.Value then
								HumanoidRootPart.Anchored = true
								HumanoidRootPart.CFrame = v.CFrame
								task.wait()
								OcupedValue.Value = true
								teleported = true
							end
						else
							continue
						end
					end
					
					if not teleported then
						local randomPart = zoneTeleport:GetChildren()[math.random(1, #zoneTeleport:GetChildren())]
						
						if not randomPart:IsA("BasePart") then
							repeat task.wait()
								randomPart = zoneTeleport:GetChildren()[math.random(1, #zoneTeleport:GetChildren())]
							until randomPart:IsA("BasePart")
						end
						
						HumanoidRootPart.Anchored = true
						HumanoidRootPart.CFrame = randomPart.CFrame
						task.wait()
						HumanoidRootPart.Anchored = false
					end
					
					repeat task.wait()
					until plrTransition or maxTimeReached
					
					HumanoidRootPart.Anchored = false
				end
			end)
		end
	else
		if Activator then
			warn(`Incorrect zone name, please check if is correct. Error on script: {Activator:GetFullName()}`)
		else
			warn("Incorrect zone name, please check if is correct. No script related.")
		end
	end
end

-- If not player value will teleport all alive players in game to the current game zone.
function TeleportModule:TeleportToCurrentGameZone(Activator: Instance?, player: Player)
	local zoneTeleport = TeleportZones:FindFirstChild(CurrentGameZone.Value)
	if zoneTeleport then
		if player then
			local Char = player.Character
			local HumanoidRootPart = nil
			
			if Char:WaitForChild("HumanoidRootPart") then
				HumanoidRootPart = Char:FindFirstChild("HumanoidRootPart") :: BasePart
			end
			
			if HumanoidRootPart then
				local randomPart = zoneTeleport:GetChildren()[math.random(1, #zoneTeleport:GetChildren())]
				HumanoidRootPart.Anchored = true
				HumanoidRootPart.CFrame = randomPart.CFrame
				task.wait()
				HumanoidRootPart.Anchored = false
			end
			return
		end
		
		for i, plr in ipairs(Players:GetPlayers()) do
			local Char = plr.Character
			local PlrValues = plr:FindFirstChild("PlayerValues")
			local IsAlive = PlrValues:FindFirstChild("IsAlive")
			local HumanoidRootPart = nil
			local teleported = false
			
			if Char:WaitForChild("HumanoidRootPart") then
				HumanoidRootPart = Char:FindFirstChild("HumanoidRootPart") :: BasePart
			end
			
			if HumanoidRootPart and IsAlive.Value then -- If not IsAlive value is because player is specting.
				for i, v: BasePart in zoneTeleport:GetChildren() do
					local OcupedValue = v:FindFirstChild("Ocuped") :: BoolValue
					if OcupedValue then
						if not OcupedValue.Value then
							HumanoidRootPart.Anchored = true
							HumanoidRootPart.CFrame = v.CFrame
							task.wait()
							HumanoidRootPart.Anchored = false
							OcupedValue.Value = true
							teleported = true
						end
					else
						continue
					end
				end
				
				if not teleported then
					local randomPart = zoneTeleport:GetChildren()[math.random()]
					HumanoidRootPart.Anchored = true
					HumanoidRootPart.CFrame = randomPart.CFrame
					task.wait()
					HumanoidRootPart.Anchored = false
				end
			end
		end
	else
		if Activator then
			warn(`Can't teleport to current Game Zone. Error on script: {Activator:GetFullName()}`)
		else
			warn("Can't teleport to current Game Zone. No script related.")
		end
	end
end

return TeleportModule