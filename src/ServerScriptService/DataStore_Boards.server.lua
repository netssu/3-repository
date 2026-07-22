--|| SERVICES ||--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--|| MODULES ||--
local Datastore = require(script.Datastore)

Players.PlayerAdded:Connect(function(Player)
	Datastore:startData(Player)
end)

Players.PlayerRemoving:Connect(function(Player)
	Datastore:endData(Player)
end)

local getData = Instance.new("RemoteFunction")
getData.Name = "getData"
getData.Parent = ReplicatedStorage

getData.OnServerInvoke = function(Player)
	return Datastore:getData(Player)
end