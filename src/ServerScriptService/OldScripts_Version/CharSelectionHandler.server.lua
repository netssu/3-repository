--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local UpdateEquipedChar = Remotes:FindFirstChild("UpdateEquipedChar")

--//Characters
local CharactersFolder = Rs:FindFirstChild("GameCharacters")
local DefaultChar = CharactersFolder:FindFirstChild("Larry", true)

UpdateEquipedChar.OnServerInvoke = function(player, action, charName)
	local equipedChar = nil
	local equipedCharValue = player:FindFirstChild("OtherValues"):FindFirstChild("EquipedCharacter") :: StringValue
	local plrOwnedChars = player:FindFirstChild("OtherValues"):FindFirstChild("OwnedCharacters") :: Folder
	if action == "Update" then
		local success, errmsg = pcall(function()
			equipedChar = CharactersFolder:FindFirstChild(equipedCharValue.Value, true)
		end)
		if not success then
			warn("Can't get player equiped Character:", errmsg)
			equipedChar = DefaultChar.Name
			equipedCharValue.Value = DefaultChar.Name
		else
			equipedChar = equipedChar.Name
		end
		--//Get all free characters and put on player inventory if any
		for i, v in CharactersFolder:GetDescendants() do
			if v:IsA("Model") then
				local config = require(v:FindFirstChildWhichIsA("ModuleScript"))
				if config.Price <= 0 then
					if not plrOwnedChars:FindFirstChild(v.Name) then
						local newChar = Instance.new("StringValue", plrOwnedChars)
						newChar.Name = v.Name
					end
				end
			end
		end
	elseif action == "Equip" then
		equipedChar = CharactersFolder:FindFirstChild(charName, true)
		if equipedChar then
			if plrOwnedChars:FindFirstChild(charName) then
				equipedCharValue.Value = charName
				equipedChar = true
			else
				print("Can't equip. Player don't Own the character: "..charName..".")
			end
		else
			warn("Can't find character named: "..charName..".")
		end
	end
	return equipedChar
end