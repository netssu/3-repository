local CrateData = {}

CrateData.UnitTiers = {
	["Suzette"] = "Common",
	["Cowboy"] = "Common",
	["Sheriff Pete"] = "Rare",
	["Tim Scientist"] = "Rare",
	["Grenader"] = "Epic",
	["Magician"] = "Epic",
	["General"] = "Epic",
	["Wizard"] = "Legendary",
	["Wobblus"] = "Legendary",
	["Professor"] = "Mythic",
	["Airport"] = "Mythic",
	["Grandma"] = "Mythic",
}

CrateData.TemporaryRotationPeriod = 86400
CrateData.TemporaryBannerOrder = {
	"Basic Weapon Crate",
	"Explosive Crate",
	"Utility Crate",
	"Legendary Arsenal Crate",
	"Event Crate",
	"Mythic Mayhem Crate",
}

CrateData.Banners = {
	["Normal"] = {
		DisplayName = "Normal Banner",
		Price = 1000,
		Currency = "Coins",
		PityThreshold = 50,
		Rates = {
			["Common"] = 6500,
			["Rare"] = 2500,
			["Epic"] = 900,
			["Legendary"] = 100,
			["Mythic"] = 0,
		},
	},

	["Steel"] = {
		DisplayName = "Steel Banner",
		Price = 5000,
		Currency = "Coins",
		PityThreshold = 45,
		Rates = {
			["Common"] = 4000,
			["Rare"] = 4000,
			["Epic"] = 1800,
			["Legendary"] = 200,
			["Mythic"] = 0,
		},
	},

	["Golden"] = {
		DisplayName = "Golden Banner",
		Price = 10000,
		Currency = "Coins",
		PityThreshold = 40,
		Rates = {
			["Common"] = 0,
			["Rare"] = 5000,
			["Epic"] = 4000,
			["Legendary"] = 900,
			["Mythic"] = 100,
		},
	},

	["Diamond"] = {
		DisplayName = "Diamond Banner",
		Price = 500,
		Currency = "Gems",
		PityThreshold = 80,
		Rates = {
			["Common"] = 0,
			["Rare"] = 0,
			["Epic"] = 2000,
			["Legendary"] = 7250,
			["Mythic"] = 750,
		},
	},

	["Basic Weapon Crate"] = {
		DisplayName = "Basic Weapon Crate",
		Price = 1500,
		Currency = "Coins",
		PityThreshold = 50,
		Rates = {
			["Common"] = 7000,
			["Rare"] = 2500,
			["Epic"] = 450,
			["Legendary"] = 50,
			["Mythic"] = 0,
		},
		UnitPoolByRarity = {
			Common = {"Suzette", "Cowboy"},
			Rare = {"Sheriff Pete"},
			Epic = {"General"},
			Legendary = {"Wizard"},
		},
	},

	["Explosive Crate"] = {
		DisplayName = "Explosive Crate",
		Price = 6500,
		Currency = "Coins",
		PityThreshold = 45,
		Rates = {
			["Common"] = 3500,
			["Rare"] = 3500,
			["Epic"] = 2300,
			["Legendary"] = 600,
			["Mythic"] = 100,
		},
		UnitPoolByRarity = {
			Common = {"Cowboy"},
			Rare = {"Sheriff Pete"},
			Epic = {"Grenader", "General"},
			Legendary = {"Wobblus"},
			Mythic = {"Airport"},
		},
	},

	["Utility Crate"] = {
		DisplayName = "Utility Crate",
		Price = 6500,
		Currency = "Coins",
		PityThreshold = 45,
		Rates = {
			["Common"] = 4000,
			["Rare"] = 3500,
			["Epic"] = 2000,
			["Legendary"] = 450,
			["Mythic"] = 50,
		},
		UnitPoolByRarity = {
			Common = {"Suzette"},
			Rare = {"Tim Scientist"},
			Epic = {"Magician"},
			Legendary = {"Wizard"},
			Mythic = {"Professor"},
		},
	},

	["Legendary Arsenal Crate"] = {
		DisplayName = "Legendary Arsenal Crate",
		Price = 15000,
		Currency = "Coins",
		PityThreshold = 35,
		Rates = {
			["Common"] = 0,
			["Rare"] = 3000,
			["Epic"] = 5000,
			["Legendary"] = 1800,
			["Mythic"] = 200,
		},
		UnitPoolByRarity = {
			Rare = {"Sheriff Pete", "Tim Scientist"},
			Epic = {"Grenader", "Magician", "General"},
			Legendary = {"Wizard", "Wobblus"},
			Mythic = {"Professor", "Airport", "Grandma"},
		},
	},

	["Event Crate"] = {
		DisplayName = "Event Crate",
		Price = 20000,
		Currency = "Coins",
		PityThreshold = 35,
		Rates = {
			["Common"] = 2000,
			["Rare"] = 3500,
			["Epic"] = 3000,
			["Legendary"] = 1300,
			["Mythic"] = 200,
		},
		UnitPoolByRarity = {
			Common = {"Suzette", "Cowboy"},
			Rare = {"Sheriff Pete", "Tim Scientist"},
			Epic = {"Grenader", "Magician", "General"},
			Legendary = {"Wizard", "Wobblus"},
			Mythic = {"Professor", "Airport", "Grandma"},
		},
	},

	["Mythic Mayhem Crate"] = {
		DisplayName = "Mythic Mayhem Crate",
		Price = 500,
		Currency = "Gems",
		PityThreshold = 25,
		Rates = {
			["Common"] = 0,
			["Rare"] = 1000,
			["Epic"] = 3500,
			["Legendary"] = 4000,
			["Mythic"] = 1500,
		},
		UnitPoolByRarity = {
			Rare = {"Sheriff Pete", "Tim Scientist"},
			Epic = {"Grenader", "Magician", "General"},
			Legendary = {"Wizard", "Wobblus"},
			Mythic = {"Professor", "Airport", "Grandma"},
		},
	},
}

function CrateData.ResolveBannerName(bannerName, timestamp)
	if bannerName ~= "Temporary" then
		return bannerName
	end

	local order = CrateData.TemporaryBannerOrder
	if type(order) ~= "table" or #order == 0 then
		return bannerName
	end

	local period = tonumber(CrateData.TemporaryRotationPeriod) or 86400
	local rotationIndex = (math.floor((timestamp or os.time()) / period) % #order) + 1
	return order[rotationIndex] or order[1] or bannerName
end

function CrateData.GetBanner(bannerName, timestamp)
	local resolvedBannerName = CrateData.ResolveBannerName(bannerName, timestamp)
	return CrateData.Banners[resolvedBannerName], resolvedBannerName
end

function CrateData.GetSecondsUntilNextTemporaryRotation(timestamp)
	local now = math.max(0, math.floor(timestamp or os.time()))
	local period = tonumber(CrateData.TemporaryRotationPeriod) or 86400
	local elapsed = now % period
	local remaining = period - elapsed
	return remaining == period and 0 or remaining
end

function CrateData.GetUnitsForBanner(bannerName, targetRarity, timestamp)
	local bannerInfo = CrateData.GetBanner(bannerName, timestamp)
	local pool = bannerInfo and bannerInfo.UnitPoolByRarity and bannerInfo.UnitPoolByRarity[targetRarity]
	local candidates = {}

	if type(pool) == "table" then
		for _, unitName in ipairs(pool) do
			table.insert(candidates, unitName)
		end
	elseif type(CrateData.UnitTiers) == "table" then
		for unitName, tier in pairs(CrateData.UnitTiers) do
			if tier == targetRarity then
				table.insert(candidates, unitName)
			end
		end
	end

	table.sort(candidates)
	return candidates
end

return CrateData
