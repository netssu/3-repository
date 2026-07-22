--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local DataHandlerFunc = Remotes:FindFirstChild("DataHandler")

--//Modules
local Modules = Rs:FindFirstChild("Modules")
local DataHandlerModule = require(Modules:FindFirstChild("DataHandler"))

DataHandlerFunc.OnServerInvoke = function(player: Player)
	return DataHandlerModule:GetProfileData(player)
end