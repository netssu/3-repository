local DataHandler = {}

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Rs = game:GetService("ReplicatedStorage")

local Remotes = Rs:FindFirstChild("Remotes")
local DataHandlerFunc = Remotes:FindFirstChild("DataHandler")

function DataHandler:GetProfileData(player: Player)
	if RunService:IsServer() then
		local DataManager = require(ServerScriptService:FindFirstChild("Data"):FindFirstChild("DataManager"))
		return DataManager.GetProfileData(player)
	else
		local profileData = DataHandlerFunc:InvokeServer()
		return profileData
	end
end

return DataHandler