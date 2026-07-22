local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("[Cmdr] Server bootstrap started")

local package = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Cmdr")
print("[Cmdr] Server found package:", package:GetFullName())

local okCmdr, CmdrOrError = pcall(require, package)
if not okCmdr then
	warn("[Cmdr] Server failed to require Cmdr:", CmdrOrError)
	return
end
local Cmdr = CmdrOrError
print("[Cmdr] Server required Cmdr; CmdrClient exists:", ReplicatedStorage:FindFirstChild("CmdrClient") ~= nil)

local okState, AdminStateOrError = pcall(require, script:WaitForChild("AdminState"))
if not okState then
	warn("[Cmdr] Server failed to require AdminState:", AdminStateOrError)
	return
end
local AdminState = AdminStateOrError

local ADMIN_USER_IDS = {
	[3296469635] = true,
	[1501440119] = true,
}

local function configurePlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		AdminState.applyCharacterState(player, character)
	end)

	if player.Character then
		AdminState.applyCharacterState(player, player.Character)
	end
end

for _, player in Players:GetPlayers() do
	configurePlayer(player)
end
Players.PlayerAdded:Connect(configurePlayer)

local okCommands, commandsError = pcall(function()
	Cmdr.Registry:RegisterDefaultCommands({ "DefaultAdmin" })
	Cmdr.Registry:RegisterTypesIn(script.Parent:WaitForChild("CmdrTypes"))
	Cmdr.Registry:RegisterCommandsIn(script.Parent:WaitForChild("CmdrCommands"))
end)
if not okCommands then
	warn("[Cmdr] Server failed to register commands:", commandsError)
	return
end
Cmdr.Registry:RegisterHook("BeforeRun", function(context)
	if not ADMIN_USER_IDS[context.Executor.UserId] then
		return "You do not have permission to use admin commands."
	end
end)
Cmdr.ReplicatedRoot:SetAttribute("CmdrCommandsReady", true)
print("[Cmdr] Server bootstrap complete")
