--//Services
local Rs = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local UpdateGameMode = Remotes:FindFirstChild("UpdateGameMode")

local Modules = Rs:FindFirstChild("Modules")
local GameConfigModule = require(Modules:FindFirstChild("GameConfigModule"))

--//Values
local newGameMode = "Normal"

Players.PlayerAdded:Connect(function(plr)
	local teleportData = plr:GetJoinData().TeleportData
	if teleportData and teleportData["GameMode"] then
		newGameMode = teleportData["GameMode"]
	end
	
	task.defer(function()
		UpdateGameMode:FireClient(plr, newGameMode)
		GameConfigModule.UpdateValues("GameMode", newGameMode)
		
		print("[Server] SESSION GAME MODE: ", GameConfigModule.GameMode)
		
		local otherValues = plr:WaitForChild("OtherValues")
		local freeRevives = otherValues and otherValues:WaitForChild("FreeRevives")
		
		if GameConfigModule.GameMode == "Hard" then
			if freeRevives then
				freeRevives.Value = 2 -- only 2 life in the hard mode
			end
		elseif GameConfigModule.GameMode == "Nightmare" then
			if freeRevives then
				freeRevives.Value = 1 -- only 1 life in the nightmare mode
			end
		end
	end)
end)