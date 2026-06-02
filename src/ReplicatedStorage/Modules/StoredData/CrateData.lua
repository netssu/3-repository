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
	"BananaBomb",
	"HolyHand",
	"BunkerBuster",
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

	["BananaBomb"] = {
		DisplayName = "Banana Bomb Crate",
		Price = 7500,
		Currency = "Coins",
		PityThreshold = 35,
		ThemeColor = Color3.fromRGB(226, 194, 64),
		DisableHourlyRotation = true,
		Rates = {
			["Common"] = 0,
			["Rare"] = 4200,
			["Epic"] = 3500,
			["Legendary"] = 1900,
			["Mythic"] = 400,
		},
		UnitPoolByRarity = {
			["Rare"] = {"Sheriff Pete", "Tim Scientist"},
			["Epic"] = {"Grenader", "Magician"},
			["Legendary"] = {"Wobblus"},
			["Mythic"] = {"Grandma"},
		},
	},

	["HolyHand"] = {
		DisplayName = "Holy Hand Crate",
		Price = 9000,
		Currency = "Coins",
		PityThreshold = 32,
		ThemeColor = Color3.fromRGB(119, 171, 255),
		DisableHourlyRotation = true,
		Rates = {
			["Common"] = 0,
			["Rare"] = 2600,
			["Epic"] = 4300,
			["Legendary"] = 2600,
			["Mythic"] = 500,
		},
		UnitPoolByRarity = {
			["Rare"] = {"Sheriff Pete", "Tim Scientist"},
			["Epic"] = {"General", "Grenader"},
			["Legendary"] = {"Wizard"},
			["Mythic"] = {"Professor"},
		},
	},

	["BunkerBuster"] = {
		DisplayName = "Bunker Buster Crate",
		Price = 12000,
		Currency = "Coins",
		PityThreshold = 28,
		ThemeColor = Color3.fromRGB(255, 118, 88),
		DisableHourlyRotation = true,
		Rates = {
			["Common"] = 0,
			["Rare"] = 1800,
			["Epic"] = 4200,
			["Legendary"] = 3200,
			["Mythic"] = 800,
		},
		UnitPoolByRarity = {
			["Rare"] = {"Tim Scientist"},
			["Epic"] = {"General", "Magician"},
			["Legendary"] = {"Wizard", "Wobblus"},
			["Mythic"] = {"Airport", "Professor"},
		},
	},
}

local function copyArray(list)
	local result = {}
	if type(list) ~= "table" then
		return result
	end

	for _, value in ipairs(list) do
		table.insert(result, value)
	end

	return result
end

function CrateData.GetActiveTemporaryBannerId(timestamp: number?)
	local order = CrateData.TemporaryBannerOrder
	if #order == 0 then
		return nil
	end

	local now = math.max(0, math.floor(timestamp or os.time()))
	local rotationIndex = (math.floor(now / CrateData.TemporaryRotationPeriod) % #order) + 1
	return order[rotationIndex]
end

function CrateData.GetSecondsUntilNextTemporaryRotation(timestamp: number?)
	local now = math.max(0, math.floor(timestamp or os.time()))
	local period = CrateData.TemporaryRotationPeriod
	local elapsed = now % period
	local remaining = period - elapsed
	if remaining == period then
		return 0
	end
	return remaining
end

function CrateData.ResolveBannerName(boxType: string, timestamp: number?)
	if boxType == "Temporary" then
		return CrateData.GetActiveTemporaryBannerId(timestamp) or "Temporary"
	end

	return boxType
end

function CrateData.GetBanner(boxType: string, timestamp: number?)
	local resolvedBannerName = CrateData.ResolveBannerName(boxType, timestamp)
	return CrateData.Banners[resolvedBannerName], resolvedBannerName
end

function CrateData.GetUnitsForBanner(boxType: string, rarity: string, timestamp: number?)
	local bannerInfo = CrateData.GetBanner(boxType, timestamp)
	local candidates = {}

	if bannerInfo and bannerInfo.UnitPoolByRarity and bannerInfo.UnitPoolByRarity[rarity] then
		candidates = copyArray(bannerInfo.UnitPoolByRarity[rarity])
	else
		for unitName, tier in pairs(CrateData.UnitTiers) do
			if tier == rarity then
				table.insert(candidates, unitName)
			end
		end
	end

	table.sort(candidates)
	return candidates
end

return CrateData
