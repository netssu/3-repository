local WaveCrateData = {}

WaveCrateData.DropChancePerWave = 0.35

WaveCrateData.Rarities = {
	Common = {
		Weight = 6200,
	},
	Rare = {
		Weight = 2600,
	},
	Epic = {
		Weight = 950,
	},
	Legendary = {
		Weight = 250,
	},
}

WaveCrateData.CrateFamilies = {
	"Basic Weapon Crate",
	"Explosive Crate",
	"Utility Crate",
	"Legendary Arsenal Crate",
	"Event Crate",
	"Mythic Mayhem Crate",
}

WaveCrateData.Crates = {
	DamageCrate = {
		DisplayName = "Damage Crate",
		Family = "Basic Weapon Crate",
		DropWeight = 40,
		AllowedRarities = {
			Common = true,
			Rare = true,
			Epic = true,
			Legendary = true,
		},
		EffectsByRarity = {
			Common = { Multiplier = 1.15, Duration = 16 },
			Rare = { Multiplier = 1.25, Duration = 20 },
			Epic = { Multiplier = 1.35, Duration = 24 },
			Legendary = { Multiplier = 1.5, Duration = 28 },
		},
	},
	AirStrikeCrate = {
		DisplayName = "Air Strike Crate",
		Family = "Explosive Crate",
		DropWeight = 25,
		AllowedRarities = {
			Common = true,
			Rare = true,
			Epic = true,
			Legendary = true,
		},
		EffectsByRarity = {
			Common = { Damage = 90 },
			Rare = { Damage = 140 },
			Epic = { Damage = 220 },
			Legendary = { Damage = 340 },
		},
	},
	CoinCrate = {
		DisplayName = "Coin Crate",
		Family = "Utility Crate",
		DropWeight = 35,
		AllowedRarities = {
			Common = true,
			Rare = true,
			Epic = true,
			Legendary = true,
		},
		EffectsByRarity = {
			Common = { Coins = 350, Lifetime = 8 },
			Rare = { Coins = 650, Lifetime = 8 },
			Epic = { Coins = 1100, Lifetime = 10 },
			Legendary = { Coins = 1800, Lifetime = 12 },
		},
	},
}

return WaveCrateData
