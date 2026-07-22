--//Services
local Rs = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local TeleportModule = require(ModulesFolder:FindFirstChild("TeleportModule"))
local BadgesModule = require(ModulesFolder:FindFirstChild("Badges"))
local DataManager = require(ServerScriptService:FindFirstChild("Data"):FindFirstChild("DataManager"))

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local AllPlrsDied = Remotes:FindFirstChild("AllPlrsDied")

--//Respawn the player to the current game area
game.Players.PlayerAdded:Connect(function(player)
	local firstTime = true
	
	player.CharacterAdded:Connect(function(char)
		if not firstTime then
			TeleportModule:TeleportToCurrentGameZone(script, player)
		else
			firstTime = false
		end
		
		local hum = char:WaitForChild("Humanoid") :: Humanoid
		
		hum.Died:Connect(function()
			local PlayerValues = player:WaitForChild("PlayerValues")
			local OtherValues = player:WaitForChild("OtherValues")
			local Deaths = OtherValues:FindFirstChild("Deaths") :: IntValue
			local IsAlive = PlayerValues:FindFirstChild("IsAlive") :: BoolValue
			local OnSafe = PlayerValues:FindFirstChild("OnSafe") :: BoolValue
			
			if IsAlive then
				IsAlive.Value = false
			end
			if OnSafe then
				OnSafe.Value = false
			end
			
			if Deaths then
				DataManager.AddDeath(player, 1)
				wait()
				Deaths.Value += 1
				if Deaths.Value >= 10 then
					local badge = BadgesModule:FindBadge("Focused")
					BadgesModule:GiveBadge(player, badge.Id)
				end
			end
			
			 -- // TODO: Fix this as its bugging as not all players have died
			-- //Check if all plrs died
			for i, plr in pairs(game.Players:GetPlayers()) do
				local IsAlive = plr:FindFirstChild("PlayerValues"):FindFirstChild("IsAlive") :: BoolValue
				if IsAlive.Value then
					return
				end
			end
			
			AllPlrsDied:FireAllClients()
		end)
	end)
end)