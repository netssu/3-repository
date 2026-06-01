local SS = game:GetService("ServerStorage")
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local CS = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local HTTPs = game:GetService("HttpService")
local Players = game:GetService("Players")

--MODULES
local DataStoreModule = require(SS:WaitForChild("Modules").MainDataModule)
local UpgradesDictionary = require(RS:WaitForChild("Modules").UpgradesDictionary)

local UpgradeRem = RS:WaitForChild("Remotes").UpgradeRemote

local FoodCollection = workspace.Map.CenterPoint.FoodCollection

local ActiveIncrementals = {}

-- FIX: Debounce por player para evitar spam de FireServer causando negativos
local PurchaseDebounce = {}

-- [[ HELPER FUNCTIONS ]]

for i,v in pairs(CS:GetTagged("UpgradeBoard")) do
	if v:IsA("Model") then
		v.PrimaryPart.SurfaceGui.UpgradeFrame.UpgradeDescription.Text = UpgradesDictionary.Upgrades[v.Name].Description
		v.PrimaryPart.SurfaceGui.UpgradeFrame.UpgradeLevel.Text = "Upgrades: 0/"..UpgradesDictionary.Upgrades[v.Name].MaxLevel
	end
end

-- FIX: Helper para deduzir moeda com segurança (nunca deixa negativo)
local function DeductCurrency(DataStore, PlayerStats, CurrencyName, Price, UsingCooker, IsFarmersMarket)
	if IsFarmersMarket and UsingCooker then
		DataStore.Value.FoodBoxesValue = math.max(0, DataStore.Value.FoodBoxesValue - Price)
		PlayerStats.FoodBoxesValue.Value = DataStore.Value.FoodBoxesValue
	else
		DataStore.Value[CurrencyName] = math.max(0, DataStore.Value[CurrencyName] - Price)
		-- Atualiza o NumberValue correspondente no Player
		for _, v in pairs(PlayerStats.Parent:GetDescendants()) do
			if v:IsA("NumberValue") and v.Name == CurrencyName then
				if v.Parent.Name == "leaderstatValues" or v.Parent.Name == "PlayerStats" then
					v.Value = DataStore.Value[CurrencyName]
					break
				end
			end
		end
	end
end

UpgradeRem.OnServerEvent:Connect(function(Player, Action, Data)
	-- FIX: Debounce por player — impede spam de compras que causam negativos
	if PurchaseDebounce[Player.UserId] then return end
	PurchaseDebounce[Player.UserId] = true
	task.delay(0.2, function()
		PurchaseDebounce[Player.UserId] = nil
	end)

	local Character = Player.Character
	if not Character then return end

	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
	if not DataStore then return end

	local HRP = Character:FindFirstChild("HumanoidRootPart")
	local Humanoid = Character:FindFirstChild("Humanoid")

	local PlayerStats = Player.PlayerStats
	local PlayerInfo = Player.PlayerInfo
	local LeaderstatValues = Player.leaderstatValues
	local Upgrades = DataStore.Value.Upgrades
	local PlayerStatsUpgrades = PlayerStats.Upgrades
	local FarmersMarketSkillTree = PlayerStats.FarmersMarketSkillTree

	local Ingredients = PlayerStats.Ingredients
	local Rebirths = PlayerStats.Rebirths
	local Food = LeaderstatValues.Food
	local Cash = LeaderstatValues.Cash

	-- FIX: Helper local para checar se deve usar FoodBoxes como moeda
	local function ShouldUseFoodBoxes(UpgradeData)
		if not UpgradeData then return false end
		return UpgradeData.Currency ~= "Rebirths"
			and (DataStore.Value.FarmersMarketSkillTree["UnlockFarmersMarket"].Unlocked == true
				or DataStore.Value.RestaurantSkillTree["UnlockRestaurant"].Unlocked == true)
			and Character:GetAttribute("UsingCooker") == true
	end

	if Action == "PurchaseBuy" and Data then
		local UpgradeName = Data.UpgradeName
		local ClickedUpgrade = Upgrades[UpgradeName]
		local UpgradeData = UpgradesDictionary.Upgrades[UpgradeName]
		if not UpgradeData then return end

		local CurrentLevel = UpgradeData.GetLevelFromValue(ClickedUpgrade)
		local NextLevel = CurrentLevel + 1
		local Price = UpgradeData.CostScaleFormula(UpgradeData.BaseCost, NextLevel)
		local NewValue = UpgradeData.ValueScaleFormula(UpgradeData.BaseValue, NextLevel)
		local CurrencyName = UpgradeData.Currency

		if CurrentLevel >= UpgradeData.MaxLevel then
			print("Max Level Reached")
			return
		end

		-- Determina moeda efetiva
		local EffectiveCurrency = nil
		local UsingFoodBoxes = ShouldUseFoodBoxes(UpgradeData)
		if UsingFoodBoxes then
			EffectiveCurrency = DataStore.Value.FoodBoxesValue
		else
			EffectiveCurrency = DataStore.Value[CurrencyName]
		end

		-- FIX: Valida se tem saldo suficiente antes de deduzir
		if not EffectiveCurrency or EffectiveCurrency < Price then
			return
		end

		-- Deduz com proteção contra negativos
		if UsingFoodBoxes then
			DataStore.Value.FoodBoxesValue = math.max(0, DataStore.Value.FoodBoxesValue - Price)
			PlayerStats.FoodBoxesValue.Value = DataStore.Value.FoodBoxesValue
		else
			DataStore.Value[CurrencyName] = math.max(0, DataStore.Value[CurrencyName] - Price)
			for _, v in pairs(Player:GetDescendants()) do
				if v:IsA("NumberValue") and v.Name == CurrencyName then
					if v.Parent.Name == "leaderstatValues" or v.Parent.Name == "PlayerStats" then
						v.Value = DataStore.Value[CurrencyName]
						break
					end
				end
			end
		end

		-- FIX: Garante que o novo valor do upgrade nunca seja negativo
		NewValue = math.max(0, NewValue)
		PlayerStatsUpgrades[UpgradeName].Value = NewValue
		DataStore.Value.Upgrades[UpgradeName] = NewValue

		if UpgradeName == "SpeedWithRebirths" and Humanoid then
			Humanoid.WalkSpeed = NewValue
		end

		print("Bought: ".. UpgradeName)

	elseif Action == "PurchaseMAX" and Data then
		local UpgradeName = Data.UpgradeName
		local ClickedUpgrade = Upgrades[UpgradeName]
		local UpgradeData = UpgradesDictionary.Upgrades[UpgradeName]
		if not UpgradeData then return end

		local CurrentLevel = UpgradeData.GetLevelFromValue(ClickedUpgrade)
		local CurrencyName = UpgradeData.Currency

		if CurrentLevel >= UpgradeData.MaxLevel then
			print("Max Level Reached")
			return
		end

		-- Determina moeda efetiva
		local EffectiveCurrency = nil
		local UsingFoodBoxes = ShouldUseFoodBoxes(UpgradeData)
		if UsingFoodBoxes then
			EffectiveCurrency = DataStore.Value.FoodBoxesValue
		else
			EffectiveCurrency = DataStore.Value[CurrencyName]
		end

		-- FIX: Garante que não calcula MAX com moeda negativa
		EffectiveCurrency = math.max(0, EffectiveCurrency or 0)

		local LevelsBuying, Price, NewStatValue = UpgradesDictionary.CalculateMaxBuy(UpgradeData, ClickedUpgrade, EffectiveCurrency)

		if LevelsBuying > 0 then
			-- FIX: Valida novamente antes de deduzir (double-check)
			if EffectiveCurrency < Price then
				print("Saldo insuficiente no double-check do MAX!")
				return
			end

			if UsingFoodBoxes then
				DataStore.Value.FoodBoxesValue = math.max(0, DataStore.Value.FoodBoxesValue - Price)
				PlayerStats.FoodBoxesValue.Value = DataStore.Value.FoodBoxesValue
			else
				DataStore.Value[CurrencyName] = math.max(0, DataStore.Value[CurrencyName] - Price)
				for _, v in pairs(Player:GetDescendants()) do
					if v:IsA("NumberValue") and v.Name == CurrencyName then
						if v.Parent.Name == "leaderstatValues" or v.Parent.Name == "PlayerStats" then
							v.Value = DataStore.Value[CurrencyName]
							break
						end
					end
				end
			end

			-- FIX: Garante que o novo valor do upgrade nunca seja negativo
			NewStatValue = math.max(0, NewStatValue)
			PlayerStatsUpgrades[UpgradeName].Value = NewStatValue
			DataStore.Value.Upgrades[UpgradeName] = NewStatValue

			if UpgradeName == "SpeedWithRebirths" and Humanoid then
				Humanoid.WalkSpeed = NewStatValue
			end

			print("Bought " .. LevelsBuying .. " levels for " .. Price)
		else
			print("Can't afford any more levels!")
		end

	elseif Action == "PurchaseRebirths" and Data then
		-- Determina moeda efetiva
		local UsingFoodBoxes = (DataStore.Value.FarmersMarketSkillTree["UnlockFarmersMarket"].Unlocked == true
			or DataStore.Value.RestaurantSkillTree["UnlockRestaurant"].Unlocked == true)
			and Character:GetAttribute("UsingCooker") == true

		local Currency = nil
		if UsingFoodBoxes then
			Currency = DataStore.Value.FoodBoxesValue
		else
			Currency = DataStore.Value[Data.CurrencyName]
		end

		-- FIX: Nunca calcula rebirths com moeda negativa
		Currency = math.max(0, Currency or 0)

		local PlrCurrency = nil
		if Data.CurrencyName == "Ingredients" then
			PlrCurrency = PlayerStats.Ingredients
		elseif Data.CurrencyName == "Food" then
			PlrCurrency = LeaderstatValues.Food
		end

		local RebirthsToAdd, Price = UpgradesDictionary.GetRebirthsForCurrency(Player, Currency)
		if Data.CurrencyName == "Food" then
			RebirthsToAdd, Price = UpgradesDictionary.GetFoodRebirthsForCurrency(Player, Currency)
		end

		if DataStore.Value.FarmersMarketSkillTree["x1.5Rebirths"].Unlocked == true then
			RebirthsToAdd *= 1.5
		end

		if DataStore.Value.FarmersMarketSkillTree["RebirthsBoostedByPlayTime"].Unlocked == true then
			RebirthsToAdd *= PlayerInfo.Playtime.Value
		end
		if Player:GetAttribute("x2Rebirths") == true then
			RebirthsToAdd *= 2
		end

		if RebirthsToAdd > 0 then
			-- FIX: Valida saldo antes de deduzir
			if Currency < Price then
				print("Saldo insuficiente para Rebirth!")
				return
			end

			if UsingFoodBoxes then
				DataStore.Value.FoodBoxesValue = math.max(0, DataStore.Value.FoodBoxesValue - Price)
				PlayerStats.FoodBoxesValue.Value = DataStore.Value.FoodBoxesValue
			else
				DataStore.Value[Data.CurrencyName] = math.max(0, DataStore.Value[Data.CurrencyName] - Price)
				if PlrCurrency then
					PlrCurrency.Value = DataStore.Value[Data.CurrencyName]
				end
			end

			-- FIX: Rebirths nunca podem ser negativos
			DataStore.Value.Rebirths = math.max(0, DataStore.Value.Rebirths + RebirthsToAdd)
			Player.PlayerStats.Rebirths.Value = DataStore.Value.Rebirths

			if Data.CurrencyName == "Ingredients" then
				DataStore.Value.Upgrades.IngredientsSpawnSpeed = 2.0  -- era 2.75, deve ser o BaseValue
				PlayerStatsUpgrades.IngredientsSpawnSpeed.Value = 2.0
			elseif Data.CurrencyName == "Food" then
				DataStore.Value.Upgrades.CookingSpeed = 1.8  -- era 2.5, deve ser o BaseValue
				PlayerStatsUpgrades.CookingSpeed.Value = 1.8
			end

			print("Rebirthed! Gained " .. RebirthsToAdd .. " for " .. Price)
		else
			print("Not enough currency to Rebirth (Need at least 1,000).")
		end
	end
end)