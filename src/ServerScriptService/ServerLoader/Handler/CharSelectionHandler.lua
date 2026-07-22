local CharSelectionHandler = {}

function CharSelectionHandler.Init()
	--//Services
	local Rs = game:GetService("ReplicatedStorage")
	
	--//Remotes
	local Remotes = Rs:FindFirstChild("Remotes")
	local UpdateEquipedChar = Remotes:FindFirstChild("UpdateEquipedChar")
	
	--//Modules
	local DataManager = require(game:GetService("ServerScriptService").Data.DataManager)
	
	--//Characters
	local CharactersFolder = Rs:FindFirstChild("GameCharacters")
	local DefaultChar = CharactersFolder:FindFirstChild("Larry", true)
	
	UpdateEquipedChar.OnServerInvoke = function(player, action, charName)
		local equipedChar = false
		local plrOwnedChars = player:WaitForChild("OtherValues"):WaitForChild("OwnedCharacters") :: Folder
		
		if action == "Update" then
			local equipedCharValue = player:WaitForChild("OtherValues", 30):WaitForChild("EquipedCharacter", 30) :: StringValue
			
			local success, errmsg = pcall(function()
				equipedChar = CharactersFolder:FindFirstChild(equipedCharValue.Value, true)
			end)
			if not success then
				warn("Can't get player equiped Character:", errmsg)
				equipedChar = DefaultChar.Name
			else
				if not equipedChar then
					equipedChar = "Mike Wheeler" -- default character
				else
					equipedChar = equipedChar.Name
				end
			end
			
			DataManager.EquipChar(player, equipedChar)
			
			--//Get all free characters and put on player inventory if any
			for i, v in CharactersFolder:GetDescendants() do
				if v:IsA("Model") then
					local config = require(v:FindFirstChildWhichIsA("ModuleScript"))
					if config.Price <= 0 and not config.Limited then
						--//Check if player have the character gamepass, if have, give the character to the player if they don't have it yet
						if config.RobuxId then
							local success, ownPass = pcall(function()
								return game:GetService("MarketplaceService"):UserOwnsGamePassAsync(player.UserId, config.RobuxId)
							end)
							if success and ownPass then
								if not plrOwnedChars:FindFirstChild(v.Name) then
									DataManager.AddNewChar(player, v.Name)
								end
							end
							continue
						end
						
						--//If player don't have this character and the character is free, then give it to the player
						if not plrOwnedChars:FindFirstChild(v.Name) then
							DataManager.AddNewChar(player, v.Name)
						end
					end
				end
			end
		elseif action == "Equip" then
			equipedChar = CharactersFolder:FindFirstChild(charName, true)
			if equipedChar then
				if plrOwnedChars:FindFirstChild(charName) then
					DataManager.EquipChar(player, charName)
					equipedChar = true
				else
					print("Can't equip. Player don't Own the character: "..charName..".")
				end
			else
				warn("Can't find character named: "..charName..".")
			end
		elseif action == "Buy" then
			local charToBuy = CharactersFolder:FindFirstChild(charName, true)
			local plrCoins = player:FindFirstChild("leaderstats"):FindFirstChild("Coins") :: IntValue
			if charToBuy then
				local charConfig = require(charToBuy:FindFirstChildWhichIsA("ModuleScript"))
				if charConfig then
					if plrCoins.Value >= charConfig.Price then
						DataManager.RemoveCoins(player, charConfig.Price)
						DataManager.AddNewChar(player, charToBuy.Name)
						equipedChar = true
					else
						print("Player don't have enough coins to buy the character: ", charName)
					end
				end
			end
		end
		return equipedChar
	end
end

return CharSelectionHandler