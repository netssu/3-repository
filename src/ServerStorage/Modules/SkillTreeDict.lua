local SkillTreeDict = {}

--[[
	FILOSOFIA DE REBALANCEAMENTO
	
	Early game (0-15 min):
	  - UnlockFarmersMarket e seus nós iniciais custam ~20-40x menos
	  - UnlockRestaurant e a construção básica custam ~30-40x menos
	  - Nós de x1.5 são acessíveis assim que o player desbloqueia a área
	
	Mid game (15-60 min):
	  - Nós de x3, "Per Food/Per GourmetFood" mantêm custo moderado
	  - Servem como objetivos claros após o unlock inicial
	
	Late game (60+ min):
	  - BoostedByPlayTime, MultipliedByLevel, x5 mantidos altos
	  - São a progressão de longo prazo — não devem ser triviais
]]

SkillTreeDict.FarmersMarketSkillTree = {

	-- UNLOCK — meta principal dos primeiros ~8 minutos
	["UnlockFarmersMarket"] = {
		Value = 0,
		Description = "Unlock Farmers Market Spot.",
		Cost = 50_000,        -- era 1_000_000 (20x mais barato)
		Currency = "Food",
		ValueType = "Stagnant",
	},

	-- NÓS INICIAIS — desbloqueáveis nos primeiros 10-15 min
	["x1.5Ingredients"] = {
		Value = 1.5,
		Description = "x1.5 Ingredients",
		Cost = 30_000,        -- era 1_000_000 (33x mais barato)
		Currency = "Ingredients",
		ValueType = "Stagnant",
	},
	["x1.5Rebirths"] = {
		Value = 1.5,
		Description = "x1.5 Rebirths",
		Cost = 15_000,        -- era 500_000 (33x mais barato)
		Currency = "Rebirths",
		ValueType = "Stagnant",
	},
	["x1.5Food"] = {
		Value = 1.5,
		Description = "x1.5 Food",
		Cost = 75_000,        -- era 2_500_000 (33x mais barato)
		Currency = "Food",
		ValueType = "Stagnant",
	},
	["x1.5Cash"] = {
		Value = 1.5,
		Description = "x1.5 Cash",
		Cost = 250_000,       -- era 10_000_000 (40x mais barato)
		Currency = "Cash",
		ValueType = "Stagnant",
	},
	["x1.5WalkSpeed"] = {
		Value = 1.5,
		Description = "x1.5 WalkSpeed",
		Cost = 25_000,        -- era 1_000_000 (40x mais barato)
		Currency = "Rebirths",
		ValueType = "Stagnant",
	},

	-- NÓS DE CONVERSÃO — mid game (~20-40 min após unlock)
	["20IngredientsPerFood"] = {
		Value = 20,
		Description = "20 Ingredients Per Food.",
		Cost = 200_000,       -- era 5_000_000 (25x mais barato)
		Currency = "Food",
		ValueType = "Stagnant",
	},
	["10IngredientsPerFood"] = {
		Value = 10,
		Description = "10 Ingredients Per Food.",
		Cost = 5_000_000,     -- era 50_000_000 (10x mais barato)
		Currency = "Food",
		ValueType = "Stagnant",
	},
	["2IngredientsPerFood"] = {
		Value = 2,
		Description = "2 Ingredients Per Food.",
		Cost = 50_000_000,    -- era 500_000_000 (10x mais barato)
		Currency = "Food",
		ValueType = "Stagnant",
	},

	-- NÓS DE x3 — mid-late game (~30-60 min após unlock)
	["x3Ingredients"] = {
		Value = 3,
		Description = "x3 Ingredients",
		Cost = 25_000_000,    -- era 250_000_000 (10x mais barato)
		Currency = "Ingredients",
		ValueType = "Stagnant",
	},
	["x3Food"] = {
		Value = 3,
		Description = "x3 Food",
		Cost = 3_000_000,     -- era 25_000_000 (~8x mais barato)
		Currency = "Food",
		ValueType = "Stagnant",
	},
	["x3Cash"] = {
		Value = 3,
		Description = "x3 Cash",
		Cost = 3_500_000,     -- era 30_000_000 (~8x mais barato)
		Currency = "Cash",
		ValueType = "Stagnant",
	},

	-- NÓS LATE GAME — progressão de longo prazo, custos reduzidos mas ainda altos
	["FoodBoostedByPlayTime"] = {
		Value = 0,
		Description = "Food Boosted By PlayTime.",
		Cost = 50_000_000,    -- era 250_000_000 (5x mais barato)
		Currency = "Food",
		ValueType = "Variable",
	},
	["RebirthsBoostedByPlayTime"] = {
		Value = 0,
		Description = "Rebirths Boosted By PlayTime.",
		Cost = 50_000_000,    -- era 250_000_000 (5x mais barato)
		Currency = "Rebirths",
		ValueType = "Variable",
	},
	["IngredientsBoostedByPlayTime"] = {
		Value = 0,
		Description = "Ingredients Boosted By PlayTime.",
		Cost = 200_000_000,   -- era 1_000_000_000 (5x mais barato)
		Currency = "Ingredients",
		ValueType = "Variable",
	},
	["FoodMultipliedByLevel"] = {
		Value = 0,
		Description = "Food Multiplied By Level.",
		Cost = 200_000_000,   -- era 1_000_000_000 (5x mais barato)
		Currency = "Food",
		ValueType = "Variable",
	},
}

SkillTreeDict.RestaurantSkillTree = {

	-- UNLOCK — meta principal dos primeiros ~12-15 minutos
	["UnlockRestaurant"] = {
		Value = 0,
		Description = "Start Your Restaurant.",
		Cost = 250_000,       -- era 10_000_000 (40x mais barato)
		Currency = "Cash",
		ValueType = "Stagnant",
	},

	-- CONSTRUÇÃO — sequência de objetivos rápidos logo após unlock (~15-20 min)
	["BuildWalls"] = {
		Value = 1.5,
		Description = "Build Restaurant Walls",
		Cost = 100_000,       -- era 2_000_000 (20x mais barato)
		Currency = "Cash",
		ValueType = "Stagnant",
	},
	["BuildKitchen"] = {
		Value = 1.5,
		Description = "Build Restaurant Kitchen",
		Cost = 150_000,       -- era 3_000_000 (20x mais barato)
		Currency = "Cash",
		ValueType = "Stagnant",
	},
	["BuildCeiling"] = {
		Value = 20,
		Description = "Build Restaurant Ceiling",
		Cost = 100_000,       -- era 2_000_000 (20x mais barato)
		Currency = "Cash",
		ValueType = "Stagnant",
	},
	["PurchaseFurniture"] = {
		Value = 10,
		Description = "Purchase Restaurant Furniture",
		Cost = 200_000,       -- era 4_000_000 (20x mais barato)
		Currency = "Cash",
		ValueType = "Stagnant",
	},
	["BuildDoors"] = {
		Value = 0,
		Description = "Build Restaurant Doors",
		Cost = 150_000,       -- era 3_000_000 (20x mais barato)
		Currency = "Cash",
		ValueType = "Stagnant",
	},

	-- NÓS INICIAIS DE GOURMET — acessíveis nos primeiros minutos dentro do restaurant
	["x1.5GourmetFood"] = {
		Value = 1.5,
		Description = "x1.5 Gourmet Food",
		Cost = 50_000,        -- era 500_000 (10x mais barato)
		Currency = "Gourmet Food",
		ValueType = "Stagnant",
	},
	["x3GourmetFood"] = {
		Value = 3,
		Description = "x3 Gourmet Food",
		Cost = 500_000,       -- era 2_500_000 (5x mais barato)
		Currency = "Gourmet Food",
		ValueType = "Stagnant",
	},
	["10FoodPerGourmetFood"] = {
		Value = 10,
		Description = "Use 10 Food Per Gourmet Food Cooked",
		Cost = 150_000,       -- era 2_000_000 (~13x mais barato)
		Currency = "Gourmet Food",
		ValueType = "Stagnant",
	},

	-- NÓS MID GAME — 30-60 min dentro do restaurant
	["5GourmetFoodPerSale"] = {
		Value = 1,
		Description = "5 Gourmet Food Per Sale",
		Cost = 10_000_000,    -- era 100_000_000 (10x mais barato)
		Currency = "Cash",
		ValueType = "Stagnant",
	},
	["5FoodPerGourmetFood"] = {
		Value = 5,
		Description = "Use 5 Food Per Gourmet Food Cooked",
		Cost = 25_000_000,    -- era 250_000_000 (10x mais barato)
		Currency = "Gourmet Food",
		ValueType = "Stagnant",
	},

	-- NÓS LATE GAME — progressão de longo prazo
	["2GourmetFoodPerSale"] = {
		Value = 1,
		Description = "2 Gourmet Food Per Sale",
		Cost = 75_000_000,    -- era 500_000_000 (~7x mais barato)
		Currency = "Cash",
		ValueType = "Stagnant",
	},
	["x5Food"] = {
		Value = 5,
		Description = "x5 Food",
		Cost = 250_000_000,   -- era 1_250_000_000 (5x mais barato)
		Currency = "Food",
		ValueType = "Stagnant",
	},
	["x5Cash"] = {
		Value = 5,
		Description = "x5 Cash",
		Cost = 200_000_000,   -- era 1_000_000_000 (5x mais barato)
		Currency = "Cash",
		ValueType = "Stagnant",
	},
	["GourmetFoodBoostedByPlayTime"] = {
		Value = 1,
		Description = "Gourmet Food Boosted By PlayTime",
		Cost = 150_000_000,   -- era 750_000_000 (5x mais barato)
		Currency = "Cash",
		ValueType = "Variable",
	},
	["GourmetFoodMultipliedByLevel"] = {
		Value = 1,
		Description = "Gourmet Food Multiplied By Level",
		Cost = 400_000_000,   -- era 1_500_000_000 (~4x mais barato)
		Currency = "Cash",
		ValueType = "Variable",
	},
}

return SkillTreeDict