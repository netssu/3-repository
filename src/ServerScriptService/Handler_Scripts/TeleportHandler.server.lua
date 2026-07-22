--//Services
local TeleportService = game:GetService("TeleportService")
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local TeleportLobbyFunc = Remotes:FindFirstChild("TeleportLobby")
local JoinParty = Remotes:FindFirstChild("JoinParty")
local PlrDied = Remotes:FindFirstChild("PlrDied")
local PlrJoinedParty = Remotes:FindFirstChild("PlrJoinedParty")

--//Values
local starterPlaceId = 134201953034119
local chap1_placeId = 84026602906595
local plrsParty = {}

TeleportLobbyFunc.OnServerInvoke = function(plr)
	local success, errmsg = pcall(function()
		TeleportService:TeleportAsync(starterPlaceId, {plr})
	end)
	if success then
		return true
	else
		warn("Can't teleport "..plr.Name.." | error:", errmsg)
		return false
	end
end

local function teleportToNewServer(plr)
	local plrsInGame = #game.Players:GetPlayers()
	if #plrsParty >= plrsInGame and plrsInGame >= 1 then
		local reserveServer = TeleportService:ReserveServer(chap1_placeId)
		local success, errmsg = pcall(function()
			TeleportService:TeleportToPrivateServer(chap1_placeId, reserveServer, plrsParty)
		end)
		if success then
			return true -- plrs teleported
		else
			warn("Can't teleport "..plr.Name.." | error:", errmsg)
			return "errmsg"
		end
	end
end

game.Players.PlayerRemoving:Connect(function(plr)
	if table.find(plrsParty, plr) then
		table.remove(plrsParty, table.find(plrsParty, plr))
		PlrDied:FireAllClients(true, true)
		teleportToNewServer(plr)
	else
		PlrDied:FireAllClients(true, false)
		teleportToNewServer(plr)
	end
end)

PlrDied.OnServerEvent:Connect(function(plr)
	PlrDied:FireAllClients() --warn for all clients that a player died.
end)

JoinParty.OnServerInvoke = function(plr)
	local plrInParty = false
	for i, v in pairs(plrsParty) do
		if v == plr then
			plrInParty = true
		end
	end
	if not plrInParty then
		table.insert(plrsParty, plr)
		PlrJoinedParty:FireAllClients()
		task.spawn(function()
			teleportToNewServer(plr)
		end)
		return true -- plr joined party
	else
		return false -- Plr dont joined in party or already in party
	end
end