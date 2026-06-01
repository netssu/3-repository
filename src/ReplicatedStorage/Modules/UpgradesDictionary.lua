local UpgradeDictionary = {}

-- Helper function to calculate cost easily
-- BaseCost * (Multiplier ^ Level)
local function GetCost(BaseCost, Multiplier, Level)
	return math.floor(BaseCost * (Multiplier ^ (Level)))
end

--module function
function UpgradeDictionary.CalculateMaxBuy(UpgradeData, CurrentValue, AvailableCurrency)
	-- FIX: Garante que AvailableCurrency nunca seja negativo
	AvailableCurrency = math.max(0, AvailableCurrency)

	local CurrentLevel = UpgradeData.GetLevelFromValue(CurrentValue)

	if CurrentLevel >= UpgradeData.MaxLevel then
		return 0, 0, CurrentValue
	end

	local TotalCost = 0
	local LevelsToBuy = 0
	local SimLevel = CurrentLevel + 1

	while SimLevel <= UpgradeData.MaxLevel do
		local CostForThisLevel = UpgradeData.CostScaleFormula(UpgradeData.BaseCost, SimLevel)

		if (TotalCost + CostForThisLevel) <= AvailableCurrency then
			TotalCost = TotalCost + CostForThisLevel
			LevelsToBuy = LevelsToBuy + 1
			SimLevel = SimLevel + 1
		else
			break
		end
	end

	-- FIX: Garante que TotalCost nunca ultrapasse o disponível
	TotalCost = math.min(TotalCost, AvailableCurrency)

	local FinalLevel = CurrentLevel + LevelsToBuy
	local NewValue = UpgradeData.ValueScaleFormula(UpgradeData.BaseValue, FinalLevel)

	return LevelsToBuy, TotalCost, NewValue
end

function UpgradeDictionary.GetRebirthsForCurrency(Player: Player, Currency: number)
	if Player and Currency and Currency > 0 then
		local PlayerStats = Player:FindFirstChild("PlayerStats")
		if not PlayerStats then return 0, 0 end

		local REBIRTH_PRICE = 1000

		local Multiplier = 1
		local MultiStat = PlayerStats.Upgrades:FindFirstChild("MultiplyRebirthAmount")

		if MultiStat then
			Multiplier = MultiStat.Value
		end

		local RebirthSets = math.floor(Currency / REBIRTH_PRICE)

		if RebirthSets <= 0 then
			return 0, 0
		end

		local RebirthsToGive = RebirthSets * Multiplier
		local CostOfRebirths = RebirthSets * REBIRTH_PRICE

		return RebirthsToGive, CostOfRebirths
	end
	return 0, 0
end

function UpgradeDictionary.GetFoodRebirthsForCurrency(Player: Player, Currency: number)
	if Player and Currency and Currency > 0 then
		local PlayerStats = Player:FindFirstChild("PlayerStats")
		if not PlayerStats then return 0, 0 end

		local REBIRTH_PRICE = 1000

		local Multiplier = 1
		local MultiStat = PlayerStats.Upgrades:FindFirstChild("MultiplyFoodRebirthAmount")

		if MultiStat then
			Multiplier = MultiStat.Value
		end

		local RebirthSets = math.floor(Currency / REBIRTH_PRICE)

		if RebirthSets <= 0 then
			return 0, 0
		end

		local RebirthsToGive = RebirthSets * Multiplier
		local CostOfRebirths = RebirthSets * REBIRTH_PRICE

		return RebirthsToGive, CostOfRebirths
	end
	return 0, 0
end

UpgradeDictionary.Upgrades = {
	--[[ 
		REBIRTH UPGRADES 
		Currency: Rebirths
	]]
	["MultiplyRebirthAmount"] = {
		MaxLevel = 50,
		Description = "Multiply Rebirth Amount",
		BaseValue = 1,
		BaseCost = 1,
		UnitofMeasure = "Multiply",
		Currency = "Rebirths",

		ValueScaleFormula = function(BaseValue, Level)
			return BaseValue + Level
		end,

		GetLevelFromValue = function(CurrentValue)
			return math.round(CurrentValue - 1)
		end,

		CostScaleFormula = function(BaseCost, Level)
			return GetCost(BaseCost, 1.28, Level)
		end,
	},

	["MultiplyFoodRebirthAmount"] = {
		MaxLevel = 50,
		Description = "Multiply Food Rebirth Amount",
		BaseValue = 1,
		BaseCost = 1,
		UnitofMeasure = "Multiply",
		Currency = "Rebirths",

		ValueScaleFormula = function(BaseValue, Level)
			return BaseValue + Level
		end,

		GetLevelFromValue = function(CurrentValue)
			return math.round(CurrentValue - 1)
		end,

		CostScaleFormula = function(BaseCost, Level)
			return GetCost(BaseCost, 1.28, Level)
		end,
	},

	--[[ 
		INGREDIENT UPGRADES 
		Currency: Ingredients
	--]]

	["IngredientsPerCollect"] = {
		MaxLevel = 100,
		Description = "Increase Ingredient Per Collect",
		BaseValue = 2,
		BaseCost = 1,
		UnitofMeasure = "Normal",
		Currency = "Ingredients",

		ValueScaleFormula = function(BaseValue, Level)
			return BaseValue + Level
		end,

		GetLevelFromValue = function(CurrentValue)
			return math.max(0, math.round(CurrentValue - 2))
		end,

		CostScaleFormula = function(BaseCost, Level)
			return GetCost(BaseCost, 1.08, Level)
		end,
	},

	["IngredientsSpawnSpeed"] = {
		MaxLevel = 15,
		Description = "Decrease Ingredient Spawn Time",
		BaseValue = 2.0,
		BaseCost = 1,
		UnitofMeasure = "Seconds",
		Currency = "Ingredients",

		ValueScaleFormula = function(BaseValue, Level)
			-- FIX: math.max garante que nunca fique negativo
			return math.max(0.2, BaseValue - (Level * 0.12))
		end,
		GetLevelFromValue = function(CurrentValue)
			return math.max(0, math.round((2.0 - CurrentValue) / 0.12))
		end,

		CostScaleFormula = function(BaseCost, Level)
			return GetCost(BaseCost, 1.50, Level)
		end,
	},

	["MaxAmountofIngredients"] = {
		MaxLevel = 50,
		Description = "Increase Max Amount of Ingredients",
		BaseValue = 1,
		BaseCost = 1,
		UnitofMeasure = "Normal",
		Currency = "Ingredients",

		ValueScaleFormula = function(BaseValue, Level)
			return BaseValue + Level
		end,

		GetLevelFromValue = function(CurrentValue)
			return math.round(CurrentValue - 1)
		end,

		CostScaleFormula = function(BaseCost, Level)
			return GetCost(BaseCost, 1.28, Level)
		end,
	},

	["MultiplyIngredientsPerCollect"] = {
		MaxLevel = 75,
		Description = "Multiply Ingredients Per Collect",
		BaseValue = 1,
		BaseCost = 1,
		UnitofMeasure = "Multiply",
		Currency = "Rebirths",

		ValueScaleFormula = function(BaseValue, Level)
			return BaseValue + Level
		end,

		GetLevelFromValue = function(CurrentValue)
			return math.round(CurrentValue - 1)
		end,

		CostScaleFormula = function(BaseCost, Level)
			return GetCost(BaseCost, 1.195, Level)
		end,
	},

	["ChanceOfGoldenIngredients"] = {
		MaxLevel = 30,
		Description = "Increase Chance of Golden Ingredient",
		BaseValue = 1,
		BaseCost = 1,
		UnitofMeasure = "Percent",
		Currency = "Rebirths",

		ValueScaleFormula = function(BaseValue, Level)
			return BaseValue + Level
		end,

		GetLevelFromValue = function(CurrentValue)
			return math.round(CurrentValue - 1)
		end,

		CostScaleFormula = function(BaseCost, Level)
			return GetCost(BaseCost, 1.40, Level)
		end,
	},

	--[[ 
		FOOD UPGRADES 
		Currency: Food
	--]]

	["FoodPerIngredients"] = {
		MaxLevel = 100,
		Description = "Increase Food Per 25 Ingredients",
		BaseValue = 2,
		BaseCost = 1,
		UnitofMeasure = "Normal",
		Currency = "Food",

		ValueScaleFormula = function(BaseValue, Level)
			return BaseValue + Level
		end,

		GetLevelFromValue = function(CurrentValue)
			return math.round(CurrentValue - 2)
		end,

		CostScaleFormula = function(BaseCost, Level)
			return GetCost(BaseCost, 1.08, Level)
		end,
	},

	["CookingSpeed"] = {
		MaxLevel = 15,
		Description = "Increase Food Cooking Speed",
		BaseValue = 1.8,
		BaseCost = 1,
		UnitofMeasure = "Seconds",
		Currency = "Food",

		ValueScaleFormula = function(BaseValue, Level)
			-- FIX: math.max garante que nunca fique negativo
			return math.max(0.2, BaseValue - (Level * 0.1))
		end,
		GetLevelFromValue = function(CurrentValue)
			return math.max(0, math.round((1.8 - CurrentValue) / 0.1))
		end,

		CostScaleFormula = function(BaseCost, Level)
			return GetCost(BaseCost, 1.50, Level)
		end,
	},

	["MultiplyFoodPerIngredients"] = {
		MaxLevel = 75,
		Description = "Multiply Food Per 25 Ingredients",
		BaseValue = 1,
		BaseCost = 1,
		UnitofMeasure = "Multiply",
		Currency = "Rebirths",

		ValueScaleFormula = function(BaseValue, Level)
			return BaseValue + Level
		end,

		GetLevelFromValue = function(CurrentValue)
			return math.round(CurrentValue - 1)
		end,

		CostScaleFormula = function(BaseCost, Level)
			return GetCost(BaseCost, 1.195, Level)
		end,
	},

	["ChanceOfGoldenFood"] = {
		MaxLevel = 30,
		Description = "Increase Chance of Golden Food",
		BaseValue = 1,
		BaseCost = 1,
		UnitofMeasure = "Percent",
		Currency = "Rebirths",

		ValueScaleFormula = function(BaseValue, Level)
			return BaseValue + Level
		end,

		GetLevelFromValue = function(CurrentValue)
			return math.round(CurrentValue - 1)
		end,

		CostScaleFormula = function(BaseCost, Level)
			return GetCost(BaseCost, 1.40, Level)
		end,
	},

	["SpeedWithRebirths"] = {
		MaxLevel = 49,
		Description = "Increase your Velocity with Rebirths",
		BaseValue = 16,
		BaseCost = 1,
		UnitofMeasure = "Normal",
		Currency = "Rebirths",

		ValueScaleFormula = function(BaseValue, Level)
			return BaseValue + Level
		end,

		GetLevelFromValue = function(CurrentValue)
			return math.round(CurrentValue - 16)
		end,

		CostScaleFormula = function(BaseCost, Level)
			return GetCost(BaseCost, 1.3, Level)
		end,
	},

	--[[ 
		CASH UPGRADES 
		Currency: CASH
	--]]

	["CashPerFood"] = {
		MaxLevel = 100,
		Description = "Increase Cash Per Food Sold",
		BaseValue = 2,
		BaseCost = 1,
		UnitofMeasure = "Normal",
		Currency = "Cash",

		ValueScaleFormula = function(BaseValue, Level)
			return BaseValue + Level
		end,

		GetLevelFromValue = function(CurrentValue)
			return math.round(CurrentValue - 2)
		end,

		CostScaleFormula = function(BaseCost, Level)
			return GetCost(BaseCost, 1.08, Level)
		end,
	},

	["SaleSpeed"] = {
		MaxLevel = 15,
		Description = "Increase Sales Speed",
		BaseValue = 1.8,
		BaseCost = 1,
		UnitofMeasure = "Seconds",
		Currency = "Cash",

		ValueScaleFormula = function(BaseValue, Level)
			-- FIX: math.max garante que nunca fique negativo
			return math.max(0.3, BaseValue - (Level * 0.1))
		end,
		GetLevelFromValue = function(CurrentValue)
			return math.round((1.8 - CurrentValue) / 0.1)
		end,

		CostScaleFormula = function(BaseCost, Level)
			return GetCost(BaseCost, 1.50, Level)
		end,
	},

	["MultiplyCashPerFood"] = {
		MaxLevel = 75,
		Description = "Multiply Cash Per Food Sold",
		BaseValue = 1,
		BaseCost = 25,
		UnitofMeasure = "Multiply",
		Currency = "Cash",

		ValueScaleFormula = function(BaseValue, Level)
			return BaseValue + Level
		end,

		GetLevelFromValue = function(CurrentValue)
			return math.round(CurrentValue - 1)
		end,

		CostScaleFormula = function(BaseCost, Level)
			return GetCost(BaseCost, 1.21, Level)
		end,
	},

	["ChanceOfGoldenSale"] = {
		MaxLevel = 30,
		Description = "Increase Chance of Golden Sale",
		BaseValue = 1,
		BaseCost = 25,
		UnitofMeasure = "Percent",
		Currency = "Cash",

		ValueScaleFormula = function(BaseValue, Level)
			return BaseValue + Level
		end,

		GetLevelFromValue = function(CurrentValue)
			return math.round(CurrentValue - 1)
		end,

		CostScaleFormula = function(BaseCost, Level)
			return GetCost(BaseCost, 1.52, Level)
		end,
	},

	--[[ 
		GOURMET UPGRADES 
		Currency: GOURMET FOOD
	--]]

	["GourmetFoodPerFood"] = {
		MaxLevel = 100,
		Description = "Increase Gourmet Food Per Food",
		BaseValue = 1,
		BaseCost = 1,
		UnitofMeasure = "Normal",
		Currency = "Gourmet Food",

		ValueScaleFormula = function(BaseValue, Level)
			return BaseValue + Level
		end,

		GetLevelFromValue = function(CurrentValue)
			return math.round(CurrentValue - 1)
		end,

		CostScaleFormula = function(BaseCost, Level)
			return GetCost(BaseCost, 1.10, Level)
		end,
	},

	["MultiplyGourmetFoodPerFood"] = {
		MaxLevel = 75,
		Description = "Multiply Gourmet Food Per Food",
		BaseValue = 1,
		BaseCost = 25,
		UnitofMeasure = "Multiply",
		Currency = "Cash",

		ValueScaleFormula = function(BaseValue, Level)
			return BaseValue + Level
		end,

		GetLevelFromValue = function(CurrentValue)
			return math.round(CurrentValue - 1)
		end,

		CostScaleFormula = function(BaseCost, Level)
			return GetCost(BaseCost, 1.22, Level)
		end,
	},

	["GourmetCookingSpeed"] = {
		MaxLevel = 15,
		Description = "Decrease Gourmet Food Cooking Time",
		BaseValue = 2,
		BaseCost = 1,
		UnitofMeasure = "Seconds",
		Currency = "Gourmet Food",

		ValueScaleFormula = function(BaseValue, Level)
			local reduction = Level * (1.8 / 15)
			-- FIX: math.max garante que nunca fique negativo
			return math.max(0.2, BaseValue - reduction)
		end,

		GetLevelFromValue = function(CurrentValue)
			return math.round((2 - CurrentValue) / (1.8 / 15))
		end,

		CostScaleFormula = function(BaseCost, Level)
			return GetCost(BaseCost, 1.50, Level)
		end,
	},

	["CashPerGourmetFood"] = {
		MaxLevel = 100,
		Description = "Increase Cash Per Gourmet Food",
		BaseValue = 1,
		BaseCost = 1,
		UnitofMeasure = "Normal",
		Currency = "Gourmet Food",

		ValueScaleFormula = function(BaseValue, Level)
			return BaseValue + Level
		end,

		GetLevelFromValue = function(CurrentValue)
			return math.round(CurrentValue - 1)
		end,

		CostScaleFormula = function(BaseCost, Level)
			return GetCost(BaseCost, 1.10, Level)
		end,
	},

	["MultiplyCashPerGourmetFood"] = {
		MaxLevel = 75,
		Description = "Multiply Cash Per Gourmet Food",
		BaseValue = 1,
		BaseCost = 25,
		UnitofMeasure = "Multiply",
		Currency = "Cash",

		ValueScaleFormula = function(BaseValue, Level)
			return BaseValue + Level
		end,

		GetLevelFromValue = function(CurrentValue)
			return math.round(CurrentValue - 1)
		end,

		CostScaleFormula = function(BaseCost, Level)
			return GetCost(BaseCost, 1.21, Level)
		end,
	},

	["CustomerRate"] = {
		MaxLevel = 50,
		Description = "Increases max customers in-store and spawn speed",
		BaseValue = 1,
		BaseCost = 5,
		UnitofMeasure = "Normal",
		Currency = "Cash",

		ValueScaleFormula = function(BaseValue, Level)
			return BaseValue + Level
		end,

		GetLevelFromValue = function(CurrentValue)
			return math.round(CurrentValue - 1)
		end,

		CostScaleFormula = function(BaseCost, Level)
			return GetCost(BaseCost, 1.33, Level)
		end,
	},

	["ChanceOfGoldenGourmet"] = {
		MaxLevel = 30,
		Description = "Increase Chance of Golden Gourmet Food",
		BaseValue = 1,
		BaseCost = 15,
		UnitofMeasure = "Percent",
		Currency = "Gourmet Food",

		ValueScaleFormula = function(BaseValue, Level)
			return BaseValue + Level
		end,

		GetLevelFromValue = function(CurrentValue)
			return math.round(CurrentValue - 1)
		end,

		CostScaleFormula = function(BaseCost, Level)
			return GetCost(BaseCost, 1.45, Level)
		end,
	},
}

return UpgradeDictionary