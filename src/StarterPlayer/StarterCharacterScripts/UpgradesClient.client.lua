--SERVICES
local RS = game:GetService("ReplicatedStorage")
local CS = game:GetService("CollectionService")
local TS = game:GetService("TweenService")
local MS = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

--REFERENCES
local Player = Players.LocalPlayer
local UpgradeRem = RS:WaitForChild("Remotes").UpgradeRemote
local Camera = workspace.CurrentCamera

--MODULES
local UpgradesDictionary = require(RS:WaitForChild("Modules").UpgradesDictionary)
local NotifModule = require(RS:WaitForChild("Modules").NotifModule)

local Character = script.Parent
repeat task.wait(1) until Player:FindFirstChild("PlayerInfo") and Player.Character:FindFirstChild("ToolFolder")

--PLAYER DATA
local PlayerStats = Player.PlayerStats
local LeaderstatValues = Player.leaderstatValues
local Upgrades = PlayerStats.Upgrades
local FarmersMarketSkillTree = PlayerStats.FarmersMarketSkillTree

-- DEV PRODUCTS CONFIG
local DEV_PRODUCTS = {
	--REBIRTHS
	["x3RebirthFood"] = 3536596994,
	["x3RebirthIngredients"] = 3519178993,
	["MultiplyRebirthAmount"] = 3519178218,
	["MultiplyFoodRebirthAmount"] = 3536596696,
	--INGREDIENTS
	["IngredientsPerCollect"] = 3519176434,
	["IngredientsSpawnSpeed"] = 3519176811,
	["MaxAmountofIngredients"] = 3519177099,
	["MultiplyIngredientsPerCollect"] = 3519177345,
	["ChanceOfGoldenIngredients"] = 3519177702,
	--FOOD
	["FoodPerIngredients"] = 3532871149,
	["CookingSpeed"] = 3536595502,
	["MultiplyFoodPerIngredients"] = 3536595737,
	["ChanceOfGoldenFood"] = 3536595954,
}

-- FORMATTING HELPERS
local names = {"K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dd", "Ud", "Dd", "Td", "Qad", "Qid", 
	"Sxd", "Spd", "Ocd", "Nod", "Vg", "Uvg", "Dvg", "Tvg", "Qavg", "Qivg", "Sxvg", "Spvg", "Ocvg"}
local Nums = {}
for i = 1, #names do table.insert(Nums, 1000^i) end

local function FrmtNum(x: number, decimalPlaces: number)
	local function roundToDecimals(num, decimalPlaces)
		local formatString = string.format("%%.%df", decimalPlaces)
		return tonumber(string.format(formatString, num))
	end
	local ab = math.abs(x)
	local p = math.min(math.floor(math.log10(ab)/3), #names)
	if ab < 1000 then return roundToDecimals(x, decimalPlaces) end 
	local num = roundToDecimals(ab / Nums[p], decimalPlaces)
	return num * math.sign(x) .. names[p]
end

local function UnitMeasure(UoM)
	if UoM == "Multiply" then return "x"
	elseif UoM == "Percent" then return "%"
	elseif UoM == "Seconds" then return "s"
	else return "" end
end

-- HELPER: Find Currency Object Efficiently
local function GetCurrencyObject(Name)
	return LeaderstatValues:FindFirstChild(Name) or PlayerStats:FindFirstChild(Name)
end

-- [[ CORE UI UPDATE FUNCTION ]] 
-- This handles ALL visual updates for Upgrade Boards
local function UpdateUpgradeBoard(BoardModel)
	local UpgradeName = BoardModel.Name
	local UpgradeValueObj = Upgrades:FindFirstChild(UpgradeName)
	local UpgradeData = UpgradesDictionary.Upgrades[UpgradeName]

	if not UpgradeValueObj or not UpgradeData then return end

	-- 1. MATH CALCULATIONS
	local CurrentVal = UpgradeValueObj.Value
	local CurrentLevel = UpgradeData.GetLevelFromValue(CurrentVal)
	local NextLevel = CurrentLevel + 1

	-- Calculate Stats
	local Price = UpgradeData.CostScaleFormula(UpgradeData.BaseCost, NextLevel)
	local CurrStat = UpgradeData.ValueScaleFormula(UpgradeData.BaseValue, CurrentLevel)
	local NextStat = UpgradeData.ValueScaleFormula(UpgradeData.BaseValue, NextLevel)

	-- Check Currency
	local CurrencyObj = GetCurrencyObject(UpgradeData.Currency)
	if UpgradeData.Currency ~= "Rebirths" and (PlayerStats.FarmersMarketSkillTree.UnlockFarmersMarket.Value == true or PlayerStats.RestaurantSkillTree.UnlockRestaurant.Value == true) and Character:GetAttribute("UsingCooker") == true then
		CurrencyObj = PlayerStats.FoodBoxesValue
	end

	local CanAfford = false
	if CurrencyObj and CurrencyObj.Value >= Price then
		CanAfford = true
	end

	-- 2. UPDATE UI ELEMENTS (Added Safeties!)
	local PrimaryPart = BoardModel.PrimaryPart
	if not PrimaryPart or not PrimaryPart:FindFirstChild("SurfaceGui") then return end

	local Frame = PrimaryPart.SurfaceGui:FindFirstChild("UpgradeFrame")
	if not Frame then return end

	-- Text Updates
	Frame.UpgradeLevel.Text = "Upgrades: " .. CurrentLevel .. "/" .. UpgradeData.MaxLevel
	Frame.Cost.Text = FrmtNum(Price, 2) .. " " .. UpgradeData.Currency
	Frame.Value.Text = FrmtNum(CurrStat, 2) .. UnitMeasure(UpgradeData.UnitofMeasure) .. " --> " .. FrmtNum(NextStat, 2) .. UnitMeasure(UpgradeData.UnitofMeasure)

	-- 3. BUTTON TRANSPARENCY (Affordability)
	if CurrentLevel >= UpgradeData.MaxLevel then
		Frame.Value.Text = "MAXED: (" .. string.format("%.1f",Upgrades[UpgradeName].Value) ..UnitMeasure(UpgradeData.UnitofMeasure) .. ")"
		Frame.Buy.Title.Text = "MAXED"
		Frame.Buy.BackgroundTransparency = 1
		Frame.Max.BackgroundTransparency = 1
		Frame.RobuxMax.BackgroundTransparency = 1
	else
		Frame.Buy.Title.Text = "Buy 1"
		Frame.RobuxMax.BackgroundTransparency = 0 

		if CanAfford == true then
			Frame.Buy.BackgroundTransparency = 0
			Frame.Max.BackgroundTransparency = 0
		else
			Frame.Buy.BackgroundTransparency = 1 
			Frame.Max.BackgroundTransparency = 1
		end
	end
end

-- [[ REBIRTH BOARD UPDATE FUNCTION ]]
local function UpdateRebirthBoard(BoardModel)
	-- Added Safeties
	local PrimaryPart = BoardModel.PrimaryPart
	if not PrimaryPart or not PrimaryPart:FindFirstChild("SurfaceGui") then return end

	local Frame = PrimaryPart.SurfaceGui:FindFirstChild("UpgradeFrame")
	if not Frame then return end

	-- Determine Currency based on board name/location
	local CollectionFolder = BoardModel.Parent.Parent
	local CurrencyObj = nil

	if string.find(CollectionFolder.Name, "Ingredient") then
		CurrencyObj = PlayerStats.Ingredients
	elseif string.find(CollectionFolder.Name, "Food") then
		CurrencyObj = LeaderstatValues.Food
	end
	if (PlayerStats.FarmersMarketSkillTree.UnlockFarmersMarket.Value == true or PlayerStats.RestaurantSkillTree.UnlockRestaurant.Value == true) and Character:GetAttribute("UsingCooker") == true then
		CurrencyObj = PlayerStats.FoodBoxesValue
	end
	if not CurrencyObj then return end

	local RebirthsToAdd, Price = UpgradesDictionary.GetRebirthsForCurrency(Player, CurrencyObj.Value)
	local CanAfford = false
	if CurrencyObj and CurrencyObj.Value >= Price then
		CanAfford = true
	end

	if CanAfford == true then
		Frame.Buy.BackgroundTransparency = 0
	else
		Frame.Buy.BackgroundTransparency = 1 
	end
	if RebirthsToAdd > 0 then
		Frame.Value.Text = "+" .. FrmtNum(RebirthsToAdd, 2) .. " Rebirths"
		Frame.Cost.Text = FrmtNum(Price, 2) .. " " .. CurrencyObj.Name
	else
		-- Show cost for 1 Rebirth as default
		local CostForOne = 1000 
		Frame.Value.Text = "+1 Rebirth"
		Frame.Cost.Text = FrmtNum(CostForOne, 2) .. " " .. CurrencyObj.Name
	end
end


-- [[ INITIALIZATION LOOP ]]
-- Sets up all boards, click events, and property listeners

-- 1. SETUP UPGRADE BOARDS
for _, Board in pairs(CS:GetTagged("UpgradeBoard")) do
	if Board:IsA("Model") then
		-- [[ FIX: SPANNING SO IT CAN WAIT SAFELY FOR PRIMARYPART TO LOAD ]]
		task.spawn(function()
			while not Board.PrimaryPart do
				task.wait(0.1)
			end

			-- Make sure UI actually exists inside the PrimaryPart before continuing
			local SurfaceGui = Board.PrimaryPart:WaitForChild("SurfaceGui", 5)
			if not SurfaceGui then return end

			local UpgradeName = Board.Name
			local UpgradeData = UpgradesDictionary.Upgrades[UpgradeName]
			local UpgradeValueObj = Upgrades:FindFirstChild(UpgradeName)

			if UpgradeData and UpgradeValueObj then

				-- A. Initial UI Update
				UpdateUpgradeBoard(Board)

				-- B. Listen for STAT Changes (Level Up)
				UpgradeValueObj:GetPropertyChangedSignal("Value"):Connect(function()
					UpdateUpgradeBoard(Board)
				end)

				-- C. Listen for CURRENCY Changes (To update affordability visuals)
				local CurrencyObj = GetCurrencyObject(UpgradeData.Currency)
				if CurrencyObj then
					CurrencyObj:GetPropertyChangedSignal("Value"):Connect(function()
						UpdateUpgradeBoard(Board)
					end)
				end

				PlayerStats.FoodBoxesValue:GetPropertyChangedSignal("Value"):Connect(function()
					UpdateUpgradeBoard(Board)
				end)

				Character:GetAttributeChangedSignal("UsingCooker"):Connect(function()
					UpdateUpgradeBoard(Board)
				end)

				-- D. Button Clicking Logic
				for _, BTN in pairs(SurfaceGui:GetDescendants()) do
					if BTN:IsA("GuiButton") then
						-- Tweening Effects
						local UIScale = Instance.new("UIScale", BTN)
						BTN.MouseEnter:Connect(function() TS:Create(UIScale,TweenInfo.new(0.6,Enum.EasingStyle.Elastic),{Scale = 1.15}):Play() end)
						BTN.MouseLeave:Connect(function() TS:Create(UIScale,TweenInfo.new(0.2,Enum.EasingStyle.Cubic),{Scale = 1}):Play() end)
						BTN.MouseButton1Down:Connect(function() TS:Create(UIScale,TweenInfo.new(0.125,Enum.EasingStyle.Cubic),{Scale = 0.85}):Play() end)
						BTN.MouseButton1Up:Connect(function() TS:Create(UIScale,TweenInfo.new(0.4,Enum.EasingStyle.Elastic),{Scale = 1}):Play() end)

						-- Click Logic
						BTN.MouseButton1Click:Connect(function()
							local CurrentVal = UpgradeValueObj.Value

							local Currency = GetCurrencyObject(UpgradeData.Currency)
							if UpgradeData.Currency ~= "Rebirths" and (PlayerStats.FarmersMarketSkillTree.UnlockFarmersMarket.Value == true or PlayerStats.RestaurantSkillTree.UnlockRestaurant.Value == true) and Character:GetAttribute("UsingCooker") == true then
								Currency = PlayerStats.FoodBoxesValue
							end

							if not Currency then return end

							local CurrentLevel = UpgradeData.GetLevelFromValue(CurrentVal)
							local NextLevel = CurrentLevel + 1
							local Price = UpgradeData.CostScaleFormula(UpgradeData.BaseCost, NextLevel)

							if BTN.Name == "Buy" then
								if CurrentLevel >= UpgradeData.MaxLevel then return end

								if Currency.Value >= Price then
									print("purchased upgrade")
									UpgradeRem:FireServer("PurchaseBuy", {["UpgradeName"] = UpgradeName})
									game.ReplicatedStorage.Assets.SFX.Purchase:Play()
								end

							elseif BTN.Name == "Max" then
								if CurrentLevel >= UpgradeData.MaxLevel then return end
								local Buying, _, _ = UpgradesDictionary.CalculateMaxBuy(UpgradeData, CurrentVal, Currency.Value)
								if Buying > 0 then
									UpgradeRem:FireServer("PurchaseMAX", {["UpgradeName"] = UpgradeName})
									game.ReplicatedStorage.Assets.SFX.Purchase:Play()
								end

							elseif BTN.Name == "RobuxMax" then
								if CurrentLevel >= UpgradeData.MaxLevel then return end

								local LevelsBought, _, _ = UpgradesDictionary.CalculateMaxBuy(UpgradeData, CurrentVal, Currency.Value)
								if LevelsBought <= 0 then LevelsBought = 1 end
								local BoostedLevels = math.floor(LevelsBought * 2.5)
								local PredictedLevel = CurrentLevel + BoostedLevels

								if PredictedLevel > UpgradeData.MaxLevel then
									NotifModule.Notify(Player,"MAX x2.5 Would Exceed Max Level!")
									warn("MAX x2.5 would exceed max level")
									return 
								end

								local PID = DEV_PRODUCTS[UpgradeName]
								if PID then MS:PromptProductPurchase(Player, PID) end
							end
						end)
					end
				end
			end
		end)
	end
end

-- 2. SETUP PURCHASE (REBIRTH) BOARDS
for _, Board in pairs(CS:GetTagged("PurchaseBoard")) do
	if Board:IsA("Model") then
		task.spawn(function()
			while not Board.PrimaryPart do
				task.wait(0.1)
			end

			local SurfaceGui = Board.PrimaryPart:WaitForChild("SurfaceGui", 5)
			if not SurfaceGui then return end

			-- Identify Currency & Setup Listeners
			local CollectionFolder = Board.Parent.Parent
			local CurrencyObj = nil
			if string.find(CollectionFolder.Name, "Ingredient") then
				CurrencyObj = PlayerStats.Ingredients
			elseif string.find(CollectionFolder.Name, "Food") then
				CurrencyObj = LeaderstatValues.Food
			end

			if CurrencyObj then
				-- Update Initially
				UpdateRebirthBoard(Board)
				-- Update on Change
				CurrencyObj:GetPropertyChangedSignal("Value"):Connect(function()
					UpdateRebirthBoard(Board)
				end)

				PlayerStats.FoodBoxesValue:GetPropertyChangedSignal("Value"):Connect(function()
					UpdateRebirthBoard(Board)
				end)

				Character:GetAttributeChangedSignal("UsingCooker"):Connect(function()
					UpdateRebirthBoard(Board)
				end)
				-- Also Update if Rebirth Multiplier Changes
				if Upgrades:FindFirstChild("MultiplyRebirthAmount") then
					Upgrades.MultiplyRebirthAmount:GetPropertyChangedSignal("Value"):Connect(function()
						UpdateRebirthBoard(Board)
					end)
				end
			end

			-- Button Logic
			for _, BTN in pairs(SurfaceGui:GetDescendants()) do
				if BTN:IsA("GuiButton") then
					-- Tweening
					local UIScale = Instance.new("UIScale", BTN)
					BTN.MouseEnter:Connect(function() TS:Create(UIScale,TweenInfo.new(0.6,Enum.EasingStyle.Elastic),{Scale = 1.15}):Play() end)
					BTN.MouseLeave:Connect(function() TS:Create(UIScale,TweenInfo.new(0.2,Enum.EasingStyle.Cubic),{Scale = 1}):Play() end)
					BTN.MouseButton1Down:Connect(function() TS:Create(UIScale,TweenInfo.new(0.125,Enum.EasingStyle.Cubic),{Scale = 0.85}):Play() end)
					BTN.MouseButton1Up:Connect(function() TS:Create(UIScale,TweenInfo.new(0.4,Enum.EasingStyle.Elastic),{Scale = 1}):Play() end)

					BTN.MouseButton1Click:Connect(function()
						if not CurrencyObj then return end

						if BTN.Name == "Buy" then
							local RebirthsToAdd, _ = UpgradesDictionary.GetRebirthsForCurrency(Player, CurrencyObj.Value)
							if RebirthsToAdd > 0 then
								UpgradeRem:FireServer("PurchaseRebirths", {["CurrencyName"] = CurrencyObj.Name})
								game.ReplicatedStorage.Assets.SFX.Purchase:Play()
							end
						elseif BTN.Name == "RobuxMax" then
							local RebirthsToAdd, _ = UpgradesDictionary.GetRebirthsForCurrency(Player, CurrencyObj.Value)
							if RebirthsToAdd > 0 then
								local PID = DEV_PRODUCTS["x3Rebirth"..CurrencyObj.Name]
								if PID then MS:PromptProductPurchase(Player, PID) end
							end
						end
					end)
				end
			end
		end)
	end
end