local DataManager = {}

--//Store players profiles from ProfileStore
DataManager.Profiles = {}

function DataManager.GetProfileData(player: Player)
	local profile = DataManager.Profiles[player]
	local profileData = profile and profile.Data
	return profileData
end

--//Manipulating data | Examples:

function DataManager.AddTimePlayed(player: Player, timeAmount: number)
	local profile = DataManager.Profiles[player]
	if not profile then return end
	
	profile.Data.TimePlayed += timeAmount -- Update player data
	player.OtherValues.TimePlayed.Value = profile.Data.TimePlayed
end

function DataManager.AddCoins(player: Player, coinsAmount: number)
	local profile = DataManager.Profiles[player]
	if not profile then return end
	
	profile.Data.Coins += coinsAmount -- Update player data
	player.leaderstats.Coins.Value = profile.Data.Coins -- Update player UI InGame
	
	--Update plr UI:
	--EventName:FireClient(Player, profile.Data.Coins) -- Update UI on client
end

function DataManager.RemoveCoins(player: Player, coinsAmount: number)
	local profile = DataManager.Profiles[player]
	if not profile then return end
	
	profile.Data.Coins = math.max(profile.Data.Coins - coinsAmount, 0) -- Update player data
	player.leaderstats.Coins.Value = profile.Data.Coins
end

function DataManager.AddFreeRevive(player: Player, reviveAmount: number)
	local profile = DataManager.Profiles[player]
	if not profile then return end
	
	profile.Data.FreeRevives += reviveAmount -- Update player data
	player.OtherValues.FreeRevives.Value = profile.Data.FreeRevives
end

function DataManager.SetGroupReward(player: Player, newValue: boolean)
	local profile = DataManager.Profiles[player]
	if not profile then return end
	
	profile.Data.GroupReward = newValue -- Update player data
	player.OtherValues.GroupReward.Value = newValue
end

function DataManager.EquipChar(player: Player, newChar: string)
	local profile = DataManager.Profiles[player]
	if not profile then return end
	
	profile.Data.EquipedCharacter = newChar
	
	pcall(function()
		local equipedCharacter = player:FindFirstChild("OtherValues") and player.OtherValues:FindFirstChild("EquipedCharacter")
		if equipedCharacter then
			equipedCharacter.Value = newChar
		end
	end)
end

function DataManager.AddNewChar(player: Player, CharName: string)
	local profile = DataManager.Profiles[player]
	if not profile then return end
	
	if not profile.Data.OwnedCharacters[CharName] then
		profile.Data.OwnedCharacters[CharName] = CharName
	end
	
	local newChar = Instance.new("StringValue", player.OtherValues.OwnedCharacters)
	newChar.Name = CharName
end

function DataManager.AwardBadge(player: Player, badgeName: string)
	local profile = DataManager.Profiles[player]
	if not profile then return end
	
	profile.Data.AwardedBadges[badgeName] = true
	player.OtherValues.AwardedBadges[badgeName].Value = true
end

function DataManager.UpdBadges(player: Player, badgeName: string)
	local profile = DataManager.Profiles[player]
	if not profile then return end
	
	if profile.Data.AwardedBadges[badgeName] == nil then
		profile.Data.AwardedBadges[badgeName] = false
	end
	
	local newBadge = Instance.new("BoolValue", player.OtherValues.AwardedBadges)
	newBadge.Name = badgeName
	newBadge.Value = false -- Player don't claimed reward yet
end

function DataManager.AddItem(player: Player, itemName: string, itemType: string)
	local profile = DataManager.Profiles[player]
	if not profile then return end
	
	if not profile.Data.OwnedItems[itemName] then
		profile.Data.OwnedItems[itemName] = itemType
	end
	
	local item = Instance.new("StringValue", player.OtherValues.OwnedItems)
	item.Name = itemName
	item.Value = itemType
end

function DataManager.AddCode(player: Player, codeName: string)
	local profile = DataManager.Profiles[player]
	if not profile then return end
	
	profile.Data.AwardedCodes[codeName] = true
	
	if player.OtherValues.AwardedCodes:FindFirstChild(codeName) then
		player.OtherValues.AwardedCodes[codeName].Value = true
	else
		local newCode = Instance.new("BoolValue", player.OtherValues.AwardedCodes)
		newCode.Name = codeName
		newCode.Value = true
	end
end

function DataManager.EquipTitle(player, titleName: string)
	local profile = DataManager.Profiles[player]
	if not profile then return end
	
	profile.Data.EquipedTitle = titleName
	player.OtherValues.EquipedTitle.Value = titleName
end

function DataManager.EquipEmote(player: Player, emoteName: string, emotePos: string)
	local profile = DataManager.Profiles[player]
	if not profile then return end
	
	profile.Data.EquipedEmotes[emotePos] = emoteName
	
	if not player.OtherValues.EquipedEmotes:FindFirstChild(emotePos) then
		local newEmote = Instance.new("StringValue", player.OtherValues.EquipedEmotes)
		newEmote.Name = emotePos
		newEmote.Value = emoteName
	else
		player.OtherValues.EquipedEmotes[emotePos].Value = emoteName
	end
	
	for pos, emote in pairs(profile.Data.EquipedEmotes) do
		if pos == emotePos then continue end
		if emote == emoteName then
			profile.Data.EquipedEmotes[pos] = "" -- Unequip emote from past pos
			if player.OtherValues.EquipedEmotes:FindFirstChild(pos) then
				player.OtherValues.EquipedEmotes[pos].Value = ""
			end
		end
	end
end

function DataManager.UpdateSetting(player: Player, settingName: string, newValue: any)
	local profile = DataManager.Profiles[player]
	if not profile then return end
	
	profile.Data[settingName] = newValue
	
	if player.PlrSettings:FindFirstChild(settingName) then
		player.PlrSettings[settingName].Value = newValue
	end
end

function DataManager.AddPerk(player: Player, perkName: string, amount: number)
	local profile = DataManager.Profiles[player]
	if not profile then return end
	
	if profile.Data.OwnedPerks[perkName] then
		profile.Data.OwnedPerks[perkName] += amount
	else
		profile.Data.OwnedPerks[perkName] = amount
	end
end

function DataManager.EquipPerk(player: Player, perkName: string, amount: number, state: boolean)
	local profile = DataManager.Profiles[player]
	if not profile then return end
	
	if state then
		profile.Data.EquipedPerks[perkName] = true
	else
		profile.Data.EquipedPerks[perkName] = nil
	end
end

return DataManager