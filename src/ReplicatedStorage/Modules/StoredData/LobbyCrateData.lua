local LobbyCrateData = {}

LobbyCrateData.FolderNames = {
	"TemporaryCrates",
	"LobbyCrates",
}

LobbyCrateData.LegacyModelName = "Crate"
LobbyCrateData.LegacyCrateId = "LobbyGold"

LobbyCrateData.Order = {
	"LobbyGold",
	"LobbySteel",
	"LobbyDiamond",
}

LobbyCrateData.Crates = {
	LobbyGold = {
		DisplayName = "Golden Lobby Crate",
		Cooldown = 14400,
		ReadyText = "CLAIM!",
		ModelAliases = {
			"Crate",
			"GoldenCrate",
			"GoldenLobbyCrate",
		},
		Reward = {
			Type = "Money",
			Amount = 1200,
		},
	},
	LobbySteel = {
		DisplayName = "Steel Lobby Crate",
		Cooldown = 21600,
		ReadyText = "OPEN!",
		ModelAliases = {
			"SteelCrate",
			"SteelLobbyCrate",
		},
		Reward = {
			Type = "InventoryCrate",
			CrateName = "Steel",
			Amount = 1,
		},
	},
	LobbyDiamond = {
		DisplayName = "Diamond Lobby Crate",
		Cooldown = 43200,
		ReadyText = "OPEN!",
		ModelAliases = {
			"DiamondCrate",
			"DiamondLobbyCrate",
		},
		Reward = {
			Type = "InventoryCrate",
			CrateName = "Diamond",
			Amount = 1,
		},
	},
}

function LobbyCrateData.GetConfig(crateId: string)
	return LobbyCrateData.Crates[crateId]
end

function LobbyCrateData.ResolveCrateId(modelName: string?, attributeValue: string?)
	if type(attributeValue) == "string" and LobbyCrateData.Crates[attributeValue] then
		return attributeValue
	end

	if type(modelName) ~= "string" then
		return nil
	end

	for crateId, crateData in pairs(LobbyCrateData.Crates) do
		for _, alias in ipairs(crateData.ModelAliases or {}) do
			if alias == modelName then
				return crateId
			end
		end
	end

	return nil
end

function LobbyCrateData.GetCooldown(crateId: string): number
	local crateData = LobbyCrateData.GetConfig(crateId)
	return crateData and crateData.Cooldown or 0
end

function LobbyCrateData.GetReadyText(crateId: string): string
	local crateData = LobbyCrateData.GetConfig(crateId)
	return crateData and crateData.ReadyText or "CLAIM!"
end

return LobbyCrateData
