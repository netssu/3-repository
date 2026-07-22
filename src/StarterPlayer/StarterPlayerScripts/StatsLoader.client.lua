--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local UpdateGameModeEvent = Remotes:WaitForChild("UpdateGameMode")

--//Modules
local ModulesFolder = Rs:WaitForChild("Modules")
local GameConfigModule = require(ModulesFolder:WaitForChild("GameConfigModule"))

--//Characters Stuff
local CharactersFolder = Rs:WaitForChild("GameCharacters")

--//Player
local Player = game.Players.LocalPlayer
local CanLoadChar = Rs:WaitForChild("CanLoadChar")

--//Values
local loaded = false

repeat task.wait()
until CanLoadChar.Value == true -- wait until server loaded plr data

local function updatePlrStats()
	local OtherValues = Player:WaitForChild("OtherValues")
	local EquipedCharacter = OtherValues:WaitForChild("EquipedCharacter") :: StringValue
	local charModel = CharactersFolder:FindFirstChild(EquipedCharacter.Value, true)
	if charModel then
		local moduleScript = charModel:FindFirstChild("Config") or charModel:FindFirstChildWhichIsA("ModuleScript")
		local config = require(moduleScript)
		GameConfigModule.UpdateValues("DefaultDamage", config.Damage)
		GameConfigModule.UpdateValues("PlayerDefaultSpeed", config.Speed)
		GameConfigModule.UpdateValues("PlayerRunSpeed", config.RunSpeed)
		GameConfigModule.UpdateValues("MaxHealth", config.Health)
		GameConfigModule.UpdateValues("PlayerCrouchSpeed", config.CrouchSpeed)
		GameConfigModule.UpdateValues("PlayerDefaultJump", config.Jump)
		loaded = true
	end
end

updatePlrStats()

task.delay(30, function()
	if not loaded then
		updatePlrStats()
	end
end)

UpdateGameModeEvent.OnClientEvent:Connect(function(newGameMode: string)
	GameConfigModule.UpdateValues("GameMode", newGameMode)
	print("[CLIENT] SESSION GAME MODE:", GameConfigModule.GameMode)
end)