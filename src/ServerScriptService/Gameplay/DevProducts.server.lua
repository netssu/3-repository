local MS = game:GetService("MarketplaceService")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local DataStoreModule = require(SS:WaitForChild("Modules").MainDataModule)
local UpgradesDictionary = require(RS:WaitForChild("Modules").UpgradesDictionary)
local FarmersMarketRem = RS:WaitForChild("Remotes").FarmersMarketRemote
local PlayerPlotRem = RS:WaitForChild("Remotes").FarmersMarketRemote


local ProductFunctions = {}

-- NEW: Table to track active "All Gold" buffs
local ActiveGoldBuffs = {}

-- Helper function to check if a player has the buff
local function HasGoldBuff(player,BuffType)
	if not ActiveGoldBuffs[player.UserId] then
		ActiveGoldBuffs[player.UserId] = {}
	end
	local buffEndTime = ActiveGoldBuffs[player.UserId][BuffType]
	if buffEndTime and os.clock() < buffEndTime then
		return true
	elseif buffEndTime then
		-- Timer expired, clean it up
		ActiveGoldBuffs[player.UserId][BuffType] = nil
		return false
	end
	return false
end

local function x3Rebirths(Player,CurrencyName)
	-- 1. GET REFERENCES
	local PlayerStats = Player:FindFirstChild("PlayerStats")
	local Leaderstats = Player:FindFirstChild("leaderstatValues")
	if not PlayerStats or not Leaderstats then return false end

	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)

	-- 2. FIND CURRENCY
	local Currency = nil
	if Leaderstats:FindFirstChild(CurrencyName) then
		Currency = Leaderstats[CurrencyName]
	elseif PlayerStats:FindFirstChild(CurrencyName) then
		Currency = PlayerStats[CurrencyName]
	end

	if not Currency then return false end

	local RebirthsToAdd, Price = UpgradesDictionary.GetRebirthsForCurrency(Player, Currency)

	if RebirthsToAdd > 0 then
		DataStore.Value[CurrencyName] -= Price
		PlayerStatsUpgrades[CurrencyName] = DataStore.Value[CurrencyName]

		DataStore.Value.Rebirths += RebirthsToAdd * 3
		Player.PlayerStats.Rebirths.Value = DataStore.Value.Rebirths
		print("Rebirthed! Gained " .. RebirthsToAdd .. " for " .. Price .. " Ingredients.")
	else
		print("Not enough ingredients to Rebirth (Need at least 1,000).")
		return false -- Cancel Purchase
	end
	
	return true 
end

local function MAX2_5(Player, UpgradeName)
	-- 1. GET REFERENCES
	local PlayerStats = Player:FindFirstChild("PlayerStats")
	local Leaderstats = Player:FindFirstChild("leaderstatValues")
	if not PlayerStats or not Leaderstats then return false end

	local UpgradeFolder = PlayerStats.Upgrades:FindFirstChild(UpgradeName)
	if not UpgradeFolder then return false end

	local UpgradeData = UpgradesDictionary.Upgrades[UpgradeName]
	if not UpgradeData then return false end
	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)

	-- 2. FIND CURRENCY
	local CurrencyName = UpgradeData.Currency
	local CurrencyVal = nil
	if Leaderstats:FindFirstChild(CurrencyName) then
		CurrencyVal = Leaderstats[CurrencyName]
	elseif PlayerStats:FindFirstChild(CurrencyName) then
		CurrencyVal = PlayerStats[CurrencyName]
	end

	if not CurrencyVal then return false end

	-- 3. SIMULATE THE OUTCOME PROPERLY VIA LEVELS
	local CurrentLevel = UpgradeData.GetLevelFromValue(UpgradeFolder.Value)

	local LevelsBought, TotalCost, _ = UpgradesDictionary.CalculateMaxBuy(
		UpgradeData, 
		UpgradeFolder.Value, 
		CurrencyVal.Value
	)

	-- SAFETY NET: If they can't afford anything but paid Robux, give them at least 1 base level
	if LevelsBought <= 0 then
		LevelsBought = 1
		TotalCost = 0
	end

	-- Apply the x2.5 Boost to the amount of LEVELS bought
	local BoostedLevels = math.floor(LevelsBought * 2.5)
	local PredictedLevel = CurrentLevel + BoostedLevels

	-- Cap at Max Level
	if PredictedLevel > UpgradeData.MaxLevel then
		PredictedLevel = UpgradeData.MaxLevel
	end

	-- Get the exact, mathematically correct stat value for the new level!
	local PredictedValue = math.round(UpgradeData.ValueScaleFormula(UpgradeData.BaseValue, PredictedLevel))
	
	if TotalCost > 0 then
		DataStore.Value[CurrencyName] -= TotalCost
		CurrencyVal.Value = DataStore.Value[CurrencyName]
	end

	UpgradeFolder.Value = PredictedValue -- The "Level Skip"
	return true 
end

-- [[ NEW HELPER: GENERIC CURRENCY REWARD ]]
local function RewardCurrency(Player, CurrencyName, Amount)
	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
	local Leaderstats = Player:FindFirstChild("leaderstatValues")
	local PlayerStats = Player:FindFirstChild("PlayerStats")

	if not DataStore or not Leaderstats or not PlayerStats then return false end

	-- Update DataStore
	DataStore.Value[CurrencyName] += Amount

	-- Auto-detect where the currency is stored and update the ValueObject
	if Leaderstats:FindFirstChild(CurrencyName) then
		Leaderstats[CurrencyName].Value = DataStore.Value[CurrencyName]
	elseif PlayerStats:FindFirstChild(CurrencyName) then
		PlayerStats[CurrencyName].Value = DataStore.Value[CurrencyName]
	end

	print(Player.Name .. " successfully purchased " .. Amount .. " " .. CurrencyName .. "!")
	return true
end

local function PercentageIncreaseMarketFoodBoxes(Player, Percent:number)
	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
	local Leaderstats = Player:FindFirstChild("leaderstatValues")
	local PlayerStats = Player:FindFirstChild("PlayerStats")
	local PlayerFoodBoxes = workspace.PlayerFoodBoxes

	if not DataStore or not Leaderstats or not PlayerStats then return false end

	-- Update DataStore
	local AmountToBeAdded = DataStore.Value["FoodBoxesValue"]
	
	if Percent == 300  then
		DataStore.Value["StoredMarketFood"] += math.ceil((AmountToBeAdded * 3))
	elseif Percent == 175 then
		DataStore.Value["StoredMarketFood"] += math.ceil((AmountToBeAdded * 1.75))
	else
		DataStore.Value["StoredMarketFood"] += math.ceil(AmountToBeAdded) 
	end
	PlayerStats["StoredMarketFood"].Value = DataStore.Value["StoredMarketFood"]
	
	DataStore.Value["FoodBoxesValue"] = 0
	PlayerStats["FoodBoxesValue"].Value = DataStore.Value["FoodBoxesValue"]
	
	DataStore.Value.CurrentFoodBoxes = 0
	DataStore.playerstats.CurrentFoodBoxes.Value = DataStore.Value.CurrentFoodBoxes
	
	print(AmountToBeAdded," Was Added to StoredMarketFood")
	
	local PlrsFoodBoxFolder = PlayerFoodBoxes:WaitForChild(Player.UserId):FindFirstChild("FoodBoxes")
	if PlrsFoodBoxFolder then
		PlrsFoodBoxFolder:Destroy()
	end
	FarmersMarketRem:FireClient(Player,"CloseStorageBoxRestockMenu")
	return true
end

local function PercentageIncreaseRestaurantFoodBoxes(Player, Percent:number)
	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
	local Leaderstats = Player:FindFirstChild("leaderstatValues")
	local PlayerStats = Player:FindFirstChild("PlayerStats")
	local PlayerFoodBoxes = workspace.PlayerFoodBoxes

	if not DataStore or not Leaderstats or not PlayerStats then return false end

	-- Update DataStore
	local AmountToBeAdded = DataStore.Value["FoodBoxesValue"]

	if Percent == 300  then
		DataStore.Value["StoredRestaurantFood"] += math.ceil((AmountToBeAdded * 3))
	elseif Percent == 175 then
		DataStore.Value["StoredRestaurantFood"] += math.ceil((AmountToBeAdded * 1.75))
	else
		DataStore.Value["StoredRestaurantFood"] += math.ceil(AmountToBeAdded) 
	end
	PlayerStats["StoredRestaurantFood"].Value = DataStore.Value["StoredRestaurantFood"]
	
	DataStore.Value["FoodBoxesValue"] = 0
	PlayerStats["FoodBoxesValue"].Value = DataStore.Value["FoodBoxesValue"]
	
	DataStore.Value.CurrentFoodBoxes = 0
	DataStore.playerstats.CurrentFoodBoxes.Value = DataStore.Value.CurrentFoodBoxes
	
	print(AmountToBeAdded," Was Added to StoredRestaurantFood")

	local PlrsFoodBoxFolder = PlayerFoodBoxes:WaitForChild(Player.UserId):FindFirstChild("FoodBoxes")
	if PlrsFoodBoxFolder then
		PlrsFoodBoxFolder:Destroy()
	end
	PlayerPlotRem:FireClient(Player,"CloseStorageBoxRestockMenu")
	
	return true
end

-- HIRE WORKERS
--SHOPPER!!
ProductFunctions[3579906145] = function(Receipt, Player)
	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
	if not DataStore then return false end
	if DataStore.Value["Shopper"] == true then
		return false
	end
	DataStore.Value.HiredWorkers.Shopper.Unlocked = true
	DataStore.hiredworkers.Shopper.Value = DataStore.Value.HiredWorkers.Shopper.Unlocked

	DataStore.Value.HiredWorkers.Shopper.Active = true
	DataStore.hiredworkers.Shopper:SetAttribute("Active",DataStore.Value.HiredWorkers.Shopper.Active)
	return true
end
--SELLER!!
ProductFunctions[3579906391] = function(Receipt, Player)
	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
	if not DataStore then return false end
	if DataStore.Value["Seller"] == true then
		return false
	end
	DataStore.Value.HiredWorkers.Seller.Unlocked = true
	DataStore.hiredworkers.Seller.Value = DataStore.Value.HiredWorkers.Seller.Unlocked

	DataStore.Value.HiredWorkers.Seller.Active = true
	DataStore.hiredworkers.Seller:SetAttribute("Active",DataStore.Value.HiredWorkers.Seller.Active)
	return true
end

--PERCENTAGES INCREASE FOR FOODBOXES IN STORAGEBOXES>>

--FARMERS MARKET!!
--300% of Market Current FoodBoxesValue
ProductFunctions[3576970515] = function(Receipt, Player) return PercentageIncreaseMarketFoodBoxes(Player, 300) end
--175% of Market Current FoodBoxesValue
ProductFunctions[3576970285] = function(Receipt, Player) return PercentageIncreaseMarketFoodBoxes(Player, 175) end

--RESTAURANT!!
--300% of Market Current FoodBoxesValue
ProductFunctions[3576977029] = function(Receipt, Player) return PercentageIncreaseRestaurantFoodBoxes(Player, 300) end
--175% of Market Current FoodBoxesValue
ProductFunctions[3576976780] = function(Receipt, Player) return PercentageIncreaseRestaurantFoodBoxes(Player, 175) end


-- ==========================================
-- [[ CURRENCY PACK DEV PRODUCT HANDLERS ]]
-- ==========================================

-- 🍲 FOOD PACKS
ProductFunctions[3572436932] = function(Receipt, Player) return RewardCurrency(Player, "Food", 10000) end
ProductFunctions[3572437050] = function(Receipt, Player) return RewardCurrency(Player, "Food", 100000) end
ProductFunctions[3572437171] = function(Receipt, Player) return RewardCurrency(Player, "Food", 1000000) end
ProductFunctions[3572437284] = function(Receipt, Player) return RewardCurrency(Player, "Food", 100000000) end

-- 💰 CASH PACKS
ProductFunctions[3572438619] = function(Receipt, Player) return RewardCurrency(Player, "Cash", 10000) end
ProductFunctions[3572438708] = function(Receipt, Player) return RewardCurrency(Player, "Cash", 100000) end
ProductFunctions[3572438849] = function(Receipt, Player) return RewardCurrency(Player, "Cash", 1000000) end
ProductFunctions[3572438950] = function(Receipt, Player) return RewardCurrency(Player, "Cash", 100000000) end

-- 🥬 INGREDIENT PACKS
ProductFunctions[3572437461] = function(Receipt, Player) return RewardCurrency(Player, "Ingredients", 30000) end
ProductFunctions[3572437936] = function(Receipt, Player) return RewardCurrency(Player, "Ingredients", 250000) end
ProductFunctions[3572438321] = function(Receipt, Player) return RewardCurrency(Player, "Ingredients", 2500000) end
ProductFunctions[3572438478] = function(Receipt, Player) return RewardCurrency(Player, "Ingredients", 250000000) end

-- 🔄 REBIRTH PACKS
ProductFunctions[3572439093] = function(Receipt, Player) return RewardCurrency(Player, "Rebirths", 150) end
ProductFunctions[3572439237] = function(Receipt, Player) return RewardCurrency(Player, "Rebirths", 2000) end
ProductFunctions[3572439405] = function(Receipt, Player) return RewardCurrency(Player, "Rebirths", 100000) end
ProductFunctions[3572439503] = function(Receipt, Player) return RewardCurrency(Player, "Rebirths", 5000000) end

-- 🍽️ GOURMET FOOD PACKS
ProductFunctions[3572439702] = function(Receipt, Player) return RewardCurrency(Player, "Gourmet Food", 15000) end
ProductFunctions[3572442137] = function(Receipt, Player) return RewardCurrency(Player, "Gourmet Food", 200000) end
ProductFunctions[3572442377] = function(Receipt, Player) return RewardCurrency(Player, "Gourmet Food", 2500000) end
ProductFunctions[3572442568] = function(Receipt, Player) return RewardCurrency(Player, "Gourmet Food", 200000000) end

local function AllGoldIngredientsBuff(Player)
	-- 5 minutes = 300 seconds
	local duration = 300 

	-- Check if the player already has an active buff
	local currentEndTime = ActiveGoldBuffs[Player.UserId].Ingredients

	if currentEndTime and currentEndTime > os.clock() then
		-- STACKING: They already have the buff, so add 5 minutes to their remaining time
		ActiveGoldBuffs[Player.UserId].Ingredients = currentEndTime + duration
		print(Player.Name .. " stacked All Gold! Added 5 more minutes.")
	else
		-- FRESH START: They don't have the buff (or it expired), so start a new 5-minute timer
		ActiveGoldBuffs[Player.UserId].Ingredients = os.clock() + duration
		print(Player.Name .. " bought All Gold Ingredients for 5 minutes!")
	end

	-- [[ NEW: SYNCING TO THE CLIENT ]]
	-- Find out exactly how many seconds are left in total
	local totalTimeLeft =  ActiveGoldBuffs[Player.UserId].Ingredients - os.clock()

	-- workspace:GetServerTimeNow() is the same exact number on both the server and client!
	local syncedEndTime = workspace:GetServerTimeNow() + totalTimeLeft

	-- Attach this end time to the player so their local script can read it
	Player:SetAttribute("IngredientsGoldBuffEndTime", syncedEndTime)

	return true
end

local function AllGoldFoodBuff(Player)
	-- 5 minutes = 300 seconds
	local duration = 300 

	-- Check if the player already has an active buff
	local currentEndTime = ActiveGoldBuffs[Player.UserId].Food

	if currentEndTime and currentEndTime > os.clock() then
		-- STACKING: They already have the buff, so add 5 minutes to their remaining time
		ActiveGoldBuffs[Player.UserId].Food = currentEndTime + duration
		print(Player.Name .. " stacked All Gold! Added 5 more minutes.")
	else
		-- FRESH START: They don't have the buff (or it expired), so start a new 5-minute timer
		ActiveGoldBuffs[Player.UserId].Food = os.clock() + duration
		print(Player.Name .. " bought All Gold Ingredients for 5 minutes!")
	end

	-- [[ NEW: SYNCING TO THE CLIENT ]]
	-- Find out exactly how many seconds are left in total
	local totalTimeLeft =  ActiveGoldBuffs[Player.UserId].Food - os.clock()

	-- workspace:GetServerTimeNow() is the same exact number on both the server and client!
	local syncedEndTime = workspace:GetServerTimeNow() + totalTimeLeft

	-- Attach this end time to the player so their local script can read it
	Player:SetAttribute("FoodGoldBuffEndTime", syncedEndTime)

	return true
end

local PASSES = {
	["x3TimesRadius"] = 1683505672,
	["Magnet"] = 1683645969,
	["x2Rebirths"] = 1779204083,
	["x2Cash"] = 1778736163,
	["x2Food"] = 1780493951,
	["x2GourmetFood"] = 1779498046,
	["x2Ingredients"] = 1779810015,
}

-- 1. Cache on Join

-- 1. Cache on Join (UPDATED FOR BUNDLE SAVING)
Players.PlayerAdded:Connect(function(Player)
	task.spawn(function()
		-- Wait for DataStore to load
		local DataStore
		repeat
			task.wait(1)
			DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
		until (DataStore and DataStore.State == true) or not Player.Parent

		if not Player.Parent then return end

		-- Ensure the save table exists for bundle purchases
		if not DataStore.Value.OwnedBundlePasses then
			DataStore.Value.OwnedBundlePasses = {}
		end

		for passName, passId in pairs(PASSES) do
			local success, owns = pcall(function()
				return MS:UserOwnsGamePassAsync(Player.UserId, passId)
			end)

			-- Check if they officially own it OR if they bought it via the DevProduct Bundle
			if (success and owns) or table.find(DataStore.Value.OwnedBundlePasses, passName) then
				Player:SetAttribute(passName, true)
			else
				Player:SetAttribute(passName, false)
			end
		end
	end)
end)

-- 2. Instant Activation if bought in-game
MS.PromptGamePassPurchaseFinished:Connect(function(Player, passId, wasPurchased)
	if wasPurchased then
		for passName, id in pairs(PASSES) do
			if id == passId then
				Player:SetAttribute(passName, true)
				print(Player.Name .. " instantly activated " .. passName .. "!")
				break
			end
		end
	end
end)

-- 🌟 STARTER PACK
ProductFunctions[3572470751] = function(Receipt, Player)
	-- Grant all 4 currencies using our helper function
	local cashSuccess = RewardCurrency(Player, "Cash", 2000)
	local foodSuccess = RewardCurrency(Player, "Food", 2000)
	local rebirthsSuccess = RewardCurrency(Player, "Rebirths", 15)
	local ingredientsSuccess = RewardCurrency(Player, "Ingredients", 3000)

	-- If everything went through safely, return true!
	if cashSuccess and foodSuccess and rebirthsSuccess and ingredientsSuccess then
		print(Player.Name .. " successfully claimed their Starter Pack!")
		return true
	else
		warn("Something went wrong giving Starter Pack to " .. Player.Name)
		return false
	end
end

-- 🎁 GAMEPASS BUNDLE
ProductFunctions[3572473395] = function(Receipt, Player)
	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
	if not DataStore then return false end

	-- Safety check for the save table
	if not DataStore.Value.OwnedBundlePasses then
		DataStore.Value.OwnedBundlePasses = {}
	end

	local passesGranted = 0

	for passName, passId in pairs(PASSES) do
		local hasPass = Player:GetAttribute(passName)

		if not hasPass then
			-- Grant the pass!
			Player:SetAttribute(passName, true)

			-- Save it to their DataStore so they keep it forever
			table.insert(DataStore.Value.OwnedBundlePasses, passName)
			passesGranted += 1
		end
	end

	-- If they received at least one pass, the purchase is successful
	if passesGranted > 0 then
		print(Player.Name .. " bought the Gamepass Bundle and unlocked " .. passesGranted .. " missing passes!")
		return true
	else
		-- They already own all the passes, fail the purchase so they don't lose Robux
		warn(Player.Name .. " tried to buy the Gamepass Bundle but already owns everything!")
		return false
	end
end

--INGREDIENTS
--MAX x2.5 INGREDIENTS PER COLLECT
ProductFunctions[3519176434] = function(Receipt, Player)
	return MAX2_5(Player, "IngredientsPerCollect")
end

--MAX x2.5 INGREDIENTS SPAWN SPEED
ProductFunctions[3519176811] = function(Receipt, Player)
	return MAX2_5(Player, "IngredientsSpawnSpeed")
end

--MAX x2.5 MAX AMOUNT OF INGREDIENTS
ProductFunctions[3519177099] = function(Receipt, Player)
	return MAX2_5(Player, "MaxAmountofIngredients")
end

--MAX x2.5 MULTIPLY INGREDIENTS PER COLLECT
ProductFunctions[3519177345] = function(Receipt, Player)
	return MAX2_5(Player, "MultiplyIngredientsPerCollect")
end

--MAX x2.5 CHANCE OF GOLDEN INGREDIENTS
ProductFunctions[3519177702] = function(Receipt, Player)
	return MAX2_5(Player, "ChanceOfGoldenIngredients")
end

--MAX x2.5 MULTIPLY REBIRTH AMOUNT
ProductFunctions[3519178218] = function(Receipt, Player)
	return MAX2_5(Player, "MultiplyRebirthAmount")
end

--x3 REBIRTHS FOR INGREDIENTS
ProductFunctions[3519178993] = function(Receipt, Player)
	return x3Rebirths(Player, "Ingredients")
end

-- NEW: ALL GOLD INGREDIENTS BUFF (5 MINUTES)
ProductFunctions[3521204295] = function(Receipt, Player)
	return AllGoldIngredientsBuff(Player)
end

-- NEW: ALL GOLD FOODS BUFF (5 MINUTES)
ProductFunctions[3573056951] = function(Receipt, Player)
	return AllGoldFoodBuff(Player)
end


---->>

--FOOD
--MAX x2.5 FOOD PER INGREDIENTS
ProductFunctions[3532871149] = function(Receipt, Player)
	return MAX2_5(Player, "FoodPerIngredients")
end

--MAX x2.5 COOKING SPEED
ProductFunctions[3536595502] = function(Receipt, Player)
	return MAX2_5(Player, "CookingSpeed")
end

--MAX x2.5 MULTIPLY FOOD PER INGREDIENTS
ProductFunctions[3536595737] = function(Receipt, Player)
	return MAX2_5(Player, "MultiplyFoodPerIngredients")
end

--MAX x2.5 CHANCE OF GOLDEN FOOD
ProductFunctions[3536595954] = function(Receipt, Player)
	return MAX2_5(Player, "ChanceOfGoldenFood")
end

--MAX x2.5 MULTIPLY FOOD REBIRTH AMOUNT
ProductFunctions[3536596696] = function(Receipt, Player)
	return MAX2_5(Player, "MultiplyFoodRebirthAmount")
end

--x3 REBIRTHS FOR FOOD
ProductFunctions[3536596994] = function(Receipt, Player)
	return x3Rebirths(Player, "Food")
end


---->>

--CASH
--MAX x2.5 CASH PER FOOD
ProductFunctions[3538792865] = function(Receipt, Player)
	return MAX2_5(Player, "CashPerFood")
end

--MAX x2.5 SALES SPEED
ProductFunctions[3538793145] = function(Receipt, Player)
	return MAX2_5(Player, "SaleSpeed")
end

--MAX x2.5 MULTIPLY CASH PER FOOD
ProductFunctions[3538793654] = function(Receipt, Player)
	return MAX2_5(Player, "MultiplyCashPerFood")
end

--MAX x2.5 CHANCE OF GOLDEN SALE
ProductFunctions[3538794137] = function(Receipt, Player)
	return MAX2_5(Player, "ChanceOfGoldenSale")
end


---->>

--GOURMET FOOD
--GOURMET FOOD AND CASH!
--MAX x2.5 GOURMET FOOD PER FOOD
ProductFunctions[3562385273] = function(Receipt, Player)
	return MAX2_5(Player, "GourmetFoodPerFood")
end

--MAX x2.5 MULTIPLY GOURMET FOOD PER FOOD
ProductFunctions[3562386003] = function(Receipt, Player)
	return MAX2_5(Player, "MultiplyGourmetFoodPerFood")
end

--MAX x2.5 CASH PER GOURMET FOOD
ProductFunctions[3562384451] = function(Receipt, Player)
	return MAX2_5(Player, "CashPerGourmetFood")
end

--MAX x2.5 MULTIPLY CASH PER GOURMET FOOD
ProductFunctions[3562386277] = function(Receipt, Player)
	return MAX2_5(Player, "MultiplyCashPerGourmetFood")
end

--MAX x2.5 CUSTOMER RATE
ProductFunctions[3562384739] = function(Receipt, Player)
	return MAX2_5(Player, "CustomerRate")
end

--MAX x2.5 GOURMET COOKING SPEED
ProductFunctions[3562386881] = function(Receipt, Player)
	return MAX2_5(Player, "GourmetCookingSpeed")
end

--MAX x2.5 CHANCE OF GOLDEN GOURMET
ProductFunctions[3562387147] = function(Receipt, Player)
	return MAX2_5(Player, "ChanceOfGoldenGourmet")
end


-- CLAIM ALL DAILY REWARDS
ProductFunctions[3571641377] = function(Receipt, Player)
	-- Get references based on your main data script
	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
	local leaderstatValues = Player:FindFirstChild("leaderstatValues")
	local PlayerStats = Player:FindFirstChild("PlayerStats")

	-- Safety check
	if not DataStore or not leaderstatValues or not PlayerStats then return false end

	-- 1. Define the Rewards List (Actual sums of Days 1-7 for NotifModule)
	local RewardsGranted = {
		"3 Rebirths", 
		"50,000 Ingredients", 
		"575,000 Food", 
		"1,500,000 Cash", 
		"Chef Red Shirt"
	}

	-- [[ 2. UPDATE THE PLAYER'S STATS WITH THE ACTUAL REWARDS ]]

	-- Rebirths (Day 1)
	DataStore.Value.Rebirths += 3
	PlayerStats.Rebirths.Value = DataStore.Value.Rebirths

	-- Ingredients (Day 2)
	DataStore.Value.Ingredients += 50000
	PlayerStats.Ingredients.Value = DataStore.Value.Ingredients

	-- Food (Days 3 + 5)
	DataStore.Value.Food += 575000
	leaderstatValues.Food.Value = DataStore.Value.Food

	-- Cash (Days 4 + 6)
	DataStore.Value.Cash += 1_500_000
	leaderstatValues.Cash.Value = DataStore.Value.Cash

	-- Day 7 Milestone Reward 
	if DataStore.Value.Milestones and DataStore.Value.Milestones["Day7Reward"] then
		DataStore.Value.Milestones["Day7Reward"].Unlocked = true
		PlayerStats.Milestones.Day7Reward.Value = true
	end

	-- [[ 3. RESET THEIR STREAK ]]
	DataStore.Value.DailyStreak = 1
	DataStore.Value.LastDailyDay = 0 

	-- 4. Tell the client the purchase was successful and send the reward names for the Notifs
	local DailyRewardRem = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("DailyRewardRem")
	if DailyRewardRem then
		DailyRewardRem:FireClient(Player, "ClaimAllSuccess", {
			Rewards = RewardsGranted
		})
	end

	print(Player.Name .. " bought Claim All Daily Rewards and received their actual loot!")
	return true
end

-- DOUBLE OFFLINE EARNINGS
ProductFunctions[3591446724] = function(Receipt, Player)
	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
	local PlayerStats = Player:FindFirstChild("PlayerStats")
	local leaderstatValues = Player:FindFirstChild("leaderstatValues")

	if not DataStore or not PlayerStats or not leaderstatValues then return false end

	-- Grab current waiting offline earnings
	local ingOff = DataStore.Value.OfflineEarnings.IngredientsOffline
	local cashOff = DataStore.Value.OfflineEarnings.CashOffline
	local gfOff = DataStore.Value.OfflineEarnings["Gourmet FoodOffline"]

	-- Safety: Make sure they actually have something to double
	if ingOff <= 0 and cashOff <= 0 and gfOff <= 0 then
		return false
	end

	-- [[ GIVE DOUBLE THE REWARDS ]]
	DataStore.Value.Ingredients += (ingOff * 2)
	PlayerStats.Ingredients.Value = DataStore.Value.Ingredients

	DataStore.Value.Cash += (cashOff * 2)
	leaderstatValues.Cash.Value = DataStore.Value.Cash

	DataStore.Value["Gourmet Food"] += (gfOff * 2)
	PlayerStats["Gourmet Food"].Value = DataStore.Value["Gourmet Food"]

	-- [[ WIPE WAITING EARNINGS TO 0 ]]
	DataStore.Value.OfflineEarnings.IngredientsOffline = 0
	DataStore.Value.OfflineEarnings.CashOffline = 0
	DataStore.Value.OfflineEarnings["Gourmet FoodOffline"] = 0

	PlayerStats.OfflineEarnings.IngredientsOffline.Value = 0
	PlayerStats.OfflineEarnings.CashOffline.Value = 0
	PlayerStats.OfflineEarnings["Gourmet FoodOffline"].Value = 0

	-- Tell the Client it was successful so it can play sounds/notifications
	local OfflineEarningsRem = RS:WaitForChild("Remotes"):WaitForChild("OfflineEarningsRem")
	if OfflineEarningsRem then
		OfflineEarningsRem:FireClient(Player, "DoubledSuccess", {
			Ing = (ingOff * 2),
			Cash = (cashOff * 2),
			GF = (gfOff * 2)
		})
	end

	-- [[ THE FIX: UPDATE THE 3D BILLBOARD ON THE PLOT ]]
	local PlayerInfo = Player:FindFirstChild("PlayerInfo")
	if PlayerInfo and PlayerInfo:FindFirstChild("PlayerSpot") and PlayerInfo.PlayerSpot.Value ~= "None" then
		local Plot = workspace.Plots:FindFirstChild(PlayerInfo.PlayerSpot.Value)
		if Plot then
			local SurfaceGui = Plot.Base.OfflineReward.SecondaryBuildingColorPart.SurfaceGui

			-- Hide the numbers and title
			SurfaceGui.Stats.Visible = false
			SurfaceGui.Title.Visible = false

			-- Show the info message
			SurfaceGui.Info.Visible = true

			-- Check workers to display the correct message
			local hasShopper = DataStore.Value.HiredWorkers.Shopper.Unlocked
			local hasSeller = DataStore.Value.HiredWorkers.Seller.Unlocked
			local hasChef = DataStore.Value.RestaurantUnlocks.ChefUnlocked

			if hasShopper or hasSeller or hasChef then
				SurfaceGui.Info.Text = "Come Back Tomorrow for your Offline Earnings!"
			else
				SurfaceGui.Info.Text = "Unlock Workers To Start Earning Offline!"
			end
		end
	end

	print(Player.Name .. " successfully DOUBLED their offline earnings!")
	return true
end

--->
--------->>
--->

local function ProccessReceipt(ReceiptInfo)
	local UserId = ReceiptInfo.PlayerId
	local ProductId = ReceiptInfo.ProductId
	
	local Player = Players:GetPlayerByUserId(UserId)
	if Player then
		local Handler = ProductFunctions[ProductId]
		
		if Handler then
			local success, result = pcall(Handler, ReceiptInfo, Player)
			
			-- Only grant if the function returned TRUE
			if success and result == true then
				return Enum.ProductPurchaseDecision.PurchaseGranted
			else
				warn("Failed To Purchase Dev Product or Logic Returned False")
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end
		end
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end



MS.ProcessReceipt = ProccessReceipt

-- NEW: Allow other server scripts to ask if a player has the buff
local CheckGoldBuffBindable = SS:WaitForChild("Modules"):FindFirstChild("CheckGoldBuff")

CheckGoldBuffBindable.OnInvoke = function(Player, BuffType)
	return HasGoldBuff(Player,BuffType)
end