--SERVICES
local RS = game:GetService("ReplicatedStorage")
local CS = game:GetService("CollectionService")
local MS = game:GetService("MarketplaceService")
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

--REFERENCES
local Player = Players.LocalPlayer
local FarmersMarketRem = RS:WaitForChild("Remotes").FarmersMarketRemote
local UpgradeRem = RS:WaitForChild("Remotes").UpgradeRemote
local LayoutBtnBindable = RS:WaitForChild("Remotes").LayoutBtnBindable
local Camera = workspace.CurrentCamera

--MODULES
local UpgradesDictionary = require(RS:WaitForChild("Modules").UpgradesDictionary)
local NotifModule = require(RS:WaitForChild("Modules").NotifModule)

local CashCollectionFolder = workspace.Map.CenterPoint.CashCollection

local Character = script.Parent
repeat task.wait(1) until Player:FindFirstChild("PlayerInfo") and Player.Character:FindFirstChild("ToolFolder")

local PlayerGui = Player:WaitForChild("PlayerGui")
local HUD = PlayerGui:WaitForChild("HUD")
local MarketButtons:Frame = PlayerGui:WaitForChild("HUD").FarmersMarketButtons
local MarketUpgrades:Frame = PlayerGui:WaitForChild("HUD").FarmersMarketUpgrades
local StorageBoxframe:Frame = PlayerGui:WaitForChild("HUD").StorageBoxFrame

--CHARACTER
local HRP = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid") 

local LeaderstatValues = Player:FindFirstChild("leaderstatValues")
local PlayerStats = Player:FindFirstChild("PlayerStats")
local PlayerInfo = Player:WaitForChild("PlayerInfo")

local Upgrades = PlayerStats.Upgrades
local FarmersMarketSkillTree = PlayerStats.FarmersMarketSkillTree

local Rebirths:NumberValue = PlayerStats.Rebirths
local CashVal:NumberValue = LeaderstatValues.Cash
local FoodVal:NumberValue = LeaderstatValues.Food
local LevelVal:NumberValue = LeaderstatValues.Level

--INGREDIENTS
local IngredientsSpawnSpeed = Upgrades.IngredientsSpawnSpeed
local MaxAmountofIngredients = Upgrades.MaxAmountofIngredients
local ChanceOfGoldenIngredients = Upgrades.ChanceOfGoldenIngredients

local IngredientsPerCollect = Upgrades.IngredientsPerCollect
local MultiIngredientsPerCollect = Upgrades.MultiplyIngredientsPerCollect

local IngredientsStorage = RS:WaitForChild("Assets").Ingredients

local MarketDetectionZone = workspace.Map.CenterPoint.CashCollection.FarmerPlots:WaitForChild("DetectionZone")

local FoodCollection = workspace.Map.CenterPoint.FoodCollection
local CookingPot = FoodCollection.CookingPot
local FoodUpgradeBoards = FoodCollection.UpgradeBoards
local UpgradeBoardsOriginalPos = FoodCollection:WaitForChild("UpgradeBoardsOriginalPos")

--VARIABLES
local InFarmersMarketZone = false

local CurrentSpot = nil

local MarketZoneOParams = OverlapParams.new()
MarketZoneOParams.FilterType = Enum.RaycastFilterType.Include
MarketZoneOParams.FilterDescendantsInstances = {Character}
MarketZoneOParams.MaxParts = 1

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
	--CASH
	["CashPerFood"] = 3538792865,
	["SaleSpeed"] = 3538793145,
	["MultiplyCashPerFood"] = 3538793654,
	["ChanceOfGoldenSale"] = 3538794137,
	
	["300"] = 3576970515,
	["175"] = 3576970285,
}

for i,Seat in pairs(CashCollectionFolder.Decorations.PicnicTables:GetDescendants()) do
	if Seat:IsA("Seat") then
		Seat.CanTouch = true
	end
end

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


local function SetupFarmersMarketSpot()
	if FarmersMarketSkillTree.UnlockFarmersMarket.Value == true then
		local PlrMarketSpot = PlayerInfo.MarketSpot
		local ChosenFarmersPlot = nil
		for i,v in pairs(CashCollectionFolder.FarmerPlots:GetDescendants()) do
			if v:IsA("StringValue") then
				if v.Value == Player.Name then
					ChosenFarmersPlot = v.Parent
					break
				end
			end
		end
		if ChosenFarmersPlot then
			for i,v in pairs(CashCollectionFolder.FarmerPlots:GetDescendants()) do
				if v:IsA("BillboardGui")  and v.Name == "NameDisplay" then
					if v.Parent.Parent == ChosenFarmersPlot then
						local AboveArrow = RS:WaitForChild("UIAssets").AboveArrow:Clone()
						AboveArrow.Parent = v.Frame
						Debris:AddItem(AboveArrow,6)
						TS:Create(AboveArrow,TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,-1,true,0),{Position = UDim2.fromScale(0.5,-0.35)}):Play()
						continue
					end
					if v.Parent.Parent.Parent.Parent == ChosenFarmersPlot then
						continue
					end
					v.PlayerToHideFrom = Player
				end
				if v:IsA("ProximityPrompt") then
					if v.Parent.Parent.Parent.Parent == ChosenFarmersPlot then
						continue
					end
					v.Enabled = false
				end	
			end
		end	
	end	
end

local function UpdateUpgradeBoard(BoardUI)
	local UpgradeName = BoardUI.Name
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
	local CanAfford = false
	if CurrencyObj and CurrencyObj.Value >= Price then
		CanAfford = true
	end

	-- 2. UPDATE UI ELEMENTS
	local Frame = BoardUI.UpgradeFrame

	-- Text Updates
	Frame.UpgradeDescription.Text = UpgradeData.Description
	Frame.UpgradeLevel.Text = "Upgrades: " .. CurrentLevel .. "/" .. UpgradeData.MaxLevel
	Frame.Cost.Text = FrmtNum(Price, 2) .. " " .. UpgradeData.Currency
	Frame.Value.Text = FrmtNum(CurrStat, 2) .. UnitMeasure(UpgradeData.UnitofMeasure) .. " --> " .. FrmtNum(NextStat, 2) .. UnitMeasure(UpgradeData.UnitofMeasure)

	-- 3. BUTTON TRANSPARENCY (Affordability)
	-- If Maxed, hide buttons. If not, check price.
	if CurrentLevel >= UpgradeData.MaxLevel then
		Frame.Value.Text = "MAXED: (" .. string.format("%.1f",Upgrades[UpgradeName].Value) ..UnitMeasure(UpgradeData.UnitofMeasure) .. ")"
		Frame.Buy.Title.Text = "MAXED"
		Frame.Buy.BackgroundTransparency = 1
		Frame.Max.BackgroundTransparency = 1
		Frame.RobuxMax.BackgroundTransparency = 1
	else
		-- Reset Title
		Frame.Buy.Title.Text = "Buy 1"
		Frame.RobuxMax.BackgroundTransparency = 0 -- Always show Robux button unless maxed

		if CanAfford then
			Frame.Buy.BackgroundTransparency = 0
			Frame.Max.BackgroundTransparency = 0
		else
			Frame.Buy.BackgroundTransparency = 1 -- Gray out instead of invisible? Or 1 if you want hidden
			Frame.Max.BackgroundTransparency = 1
		end
	end
end

local function MarketAreaDetection(deltaTime)
	if not (Character and Character.Parent) then return end
	if not HRP or not HRP.Parent then return end
	if Character:GetAttribute("UsingCooker") == true then return end
	if Character:GetAttribute("CookingSpotOccupying") ~= "None" then return end
	if FarmersMarketSkillTree.UnlockFarmersMarket.Value == false then
		return
	end
	local partsFound = workspace:GetPartsInPart(MarketDetectionZone, MarketZoneOParams)
	
	-- PLAYER IS INSIDE ZONE
	if #partsFound >= MarketZoneOParams.MaxParts then
		if InFarmersMarketZone == false then
			InFarmersMarketZone = true
			TS:Create(HUD.RightSideButtons,TweenInfo.new(0.25,Enum.EasingStyle.Cubic,Enum.EasingDirection.InOut,0,false,0),{Position = UDim2.fromScale(0.89,0.6)}):Play()
			MarketButtons.Position = UDim2.fromScale(1.2,0.5)
			MarketButtons.Visible = true
			MarketButtons.CashUpgradesButton.ImageColor3 = Color3.new(0, 0.784314, 1)
			TS:Create(MarketButtons,TweenInfo.new(0.55,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,false,0),{Position = UDim2.fromScale(0.89,0.5)}):Play()
		end
	else
		
		if InFarmersMarketZone == true then
			InFarmersMarketZone = false
			if MarketUpgrades.Visible == true then
				local Tween = TS:Create(MarketUpgrades,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.In,0,false,0),{Position = UDim2.fromScale(1.5,0.5)})
				Tween:Play()
				Tween.Completed:Once(function()
					MarketUpgrades.Visible = false
					MarketButtons.CashUpgradesButton.Visible = true
				end)	
			end
			TS:Create(HUD.RightSideButtons,TweenInfo.new(0.25,Enum.EasingStyle.Cubic,Enum.EasingDirection.InOut,0,false,0),{Position = UDim2.fromScale(0.89,0.5)}):Play()
			local Tween = TS:Create(MarketButtons,TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.In,0,false,0),{Position = UDim2.fromScale(1.2,0.5)})
			Tween:Play()
			Tween.Completed:Once(function()
				MarketButtons.Visible = false
			end)	
			
		end
	end
end

for i,BoardFrame in pairs(MarketUpgrades.ScrollingFrame:GetChildren()) do
	if BoardFrame:IsA("Frame") then
		local UpgradeName = BoardFrame.Name
		local UpgradeData = UpgradesDictionary.Upgrades[UpgradeName]
		local UpgradeValueObj = Upgrades:FindFirstChild(UpgradeName)

		if UpgradeData and UpgradeValueObj then

			-- A. Initial UI Update
			UpdateUpgradeBoard(BoardFrame)

			-- B. Listen for STAT Changes (Level Up)
			UpgradeValueObj:GetPropertyChangedSignal("Value"):Connect(function()
				UpdateUpgradeBoard(BoardFrame)
			end)

			-- C. Listen for CURRENCY Changes (To update affordability visuals)
			local CurrencyObj = GetCurrencyObject(UpgradeData.Currency)
			if CurrencyObj then
				CurrencyObj:GetPropertyChangedSignal("Value"):Connect(function()
					UpdateUpgradeBoard(BoardFrame)
				end)
			end
		end	
	end
end

for i,BTN in pairs(MarketButtons:GetDescendants()) do
	if BTN:IsA("GuiButton") then
		BTN.MouseButton1Click:Connect(function()
			if BTN.Name == "CashUpgradesButton" and InFarmersMarketZone == true then
				BTN.Visible = false
				MarketUpgrades.Position = UDim2.fromScale(1.5,0.5)
				MarketUpgrades.Visible = true
				TS:Create(MarketUpgrades,TweenInfo.new(0.6,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,false,0),{Position = UDim2.fromScale(0.685,0.5)}):Play()
				HUD.Gift.Visible = false	
			end
		end)
	end
end

for i,BTN in pairs(MarketUpgrades:GetDescendants()) do
	if BTN:IsA("GuiButton") then
		BTN.MouseButton1Click:Connect(function()
		if BTN.Name == "Buy" or BTN.Name == "Max" or BTN.Name == "RobuxMax" then
				local UpgradeName = BTN.Parent.Parent.Name
				local UpgradeData = UpgradesDictionary.Upgrades[UpgradeName]
				local UpgradeValueObj = Upgrades:FindFirstChild(UpgradeName)

				local CurrentVal = UpgradeValueObj.Value
				local Currency = GetCurrencyObject(UpgradeData.Currency)
				if not Currency then return end

				local CurrentLevel = UpgradeData.GetLevelFromValue(CurrentVal)
				local NextLevel = CurrentLevel + 1
				local Price = UpgradeData.CostScaleFormula(UpgradeData.BaseCost, NextLevel)
			if BTN.Name == "Buy" then
				if CurrentLevel >= UpgradeData.MaxLevel then return end
				if Currency.Value >= Price then
					print("purchased upgrade")
					UpgradeRem:FireServer("PurchaseBuy", {["UpgradeName"] = UpgradeName})
				end

			elseif BTN.Name == "Max" then
				if CurrentLevel >= UpgradeData.MaxLevel then return end
				-- Calculate on client just to check count > 0, server verifies
				local Buying, _, _ = UpgradesDictionary.CalculateMaxBuy(UpgradeData, CurrentVal, Currency.Value)
				if Buying > 0 then
					UpgradeRem:FireServer("PurchaseMAX", {["UpgradeName"] = UpgradeName})
				end

			elseif BTN.Name == "RobuxMax" then
				if CurrentLevel >= UpgradeData.MaxLevel then return end

				-- Simulation Check
				local _, _, OptimizedVal = UpgradesDictionary.CalculateMaxBuy(UpgradeData, CurrentVal, Currency.Value)

				local PredictedValue
				if UpgradeName == "SaleSpeed" then
					PredictedValue = OptimizedVal / 2.5
				else
					PredictedValue = OptimizedVal * 2.5
				end

				local PredictedLevel = UpgradeData.GetLevelFromValue(PredictedValue)
				if PredictedLevel > UpgradeData.MaxLevel then
						NotifModule.Notify(Player,"MAX x2.5 Would Exceed Max Level!")
					warn("MAX x2.5 would exceed max level")
					return 
				end

				local PID = DEV_PRODUCTS[UpgradeName]
				if PID then MS:PromptProductPurchase(Player, PID) end
			end
		end
		
			if BTN.Name == "Close" then
				local Tween = TS:Create(MarketUpgrades,TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.In,0,false,0),{Position = UDim2.fromScale(1.5,0.5)})
				Tween:Play()
				Tween.Completed:Once(function()
					MarketUpgrades.Visible = false
					MarketButtons.CashUpgradesButton.Visible = true
				end)
				HUD.Gift.Visible = true
			elseif BTN.Name == "Layout" then
				BTN.ImageTransparency = 0
				task.delay(0.15,function()
					BTN.ImageTransparency = 0.35
				end)
				if BTN:GetAttribute("CurrentLayout") == "Single" then
					TS:Create(MarketUpgrades.ScrollingFrame.UIGridLayout,TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out,0,false,0),{CellPadding = UDim2.fromScale(0.05,0.006)}):Play()
					TS:Create(MarketUpgrades.ScrollingFrame.UIGridLayout,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out,0,false,0),{CellSize = UDim2.fromScale(0.46,0.13)}):Play()
					BTN.Image = "rbxassetid://138808955381977"
					BTN.Size = UDim2.fromScale(0.055,0.126)
					BTN.Position = UDim2.fromScale(0.44,0.875)
					MarketUpgrades.ScrollingFrame.ClipsDescendants = false
					MarketUpgrades.ScrollingFrame.CanvasPosition = Vector2.new(0,0)
					MarketUpgrades.ScrollingFrame.ScrollingEnabled = false
					MarketUpgrades.ScrollingFrame.ScrollBarImageTransparency = 1
					MarketUpgrades.ScrollArrow.Visible = false
					LayoutBtnBindable:Fire(BTN)
					BTN:SetAttribute("CurrentLayout","Multi")
					
				elseif BTN:GetAttribute("CurrentLayout") == "Multi" then
					TS:Create(MarketUpgrades.ScrollingFrame.UIGridLayout,TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out,0,false,0),{CellPadding = UDim2.fromScale(0.05,0.01)}):Play()
					TS:Create(MarketUpgrades.ScrollingFrame.UIGridLayout,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out,0,false,0),{CellSize = UDim2.fromScale(0.9,0.241)}):Play()
					BTN.Image = "rbxassetid://108476166112892"
					BTN.Size = UDim2.fromScale(0.097,0.126)
					BTN.Position = UDim2.fromScale(0.415,0.875)
					MarketUpgrades.ScrollingFrame.ClipsDescendants = true
					MarketUpgrades.ScrollingFrame.CanvasPosition = Vector2.new(0,0)
					MarketUpgrades.ScrollingFrame.ScrollingEnabled = true
					MarketUpgrades.ScrollingFrame.ScrollBarImageTransparency = 0.25
					MarketUpgrades.ScrollArrow.Visible = true
					LayoutBtnBindable:Fire(BTN)
					BTN:SetAttribute("CurrentLayout","Single")

				end
				
			elseif BTN.Name == "ScrollArrow" then
				BTN.ImageTransparency = 0
				BTN.Position = UDim2.fromScale(0.404,0.249)
				TS:Create(BTN,TweenInfo.new(0.25,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,true,0),{Position = UDim2.fromScale(0.404,0.275)}):Play()
				task.delay(0.2,function()
					BTN.ImageTransparency = 0.35
				end)

				local ScrollingFrame: ScrollingFrame = MarketUpgrades.ScrollingFrame

				-- Calculates exactly how tall one "page" of upgrades is on their screen
				local PageHeight = ScrollingFrame:FindFirstChildWhichIsA("Frame").AbsoluteSize.Y
				local CurrentY = ScrollingFrame.CanvasPosition.Y

				-- We add a tiny offset to account for rounding errors in UI rendering
				local TargetY = CurrentY + ScrollingFrame.AbsoluteWindowSize.Y
				local MaxScroll = ScrollingFrame.AbsoluteCanvasSize.Y - PageHeight

				local Pos = Vector2.new(0, 0)
				-- If scrolling down would push them past the bottom of the list
				if TargetY >= MaxScroll - 5 then
					-- Send them back to the top
					Pos = Vector2.new(0, 0) 
					TS:Create(BTN,TweenInfo.new(0.15,Enum.EasingStyle.Cubic,Enum.EasingDirection.InOut,0,false,0),{Rotation = 0}):Play()
				else
					-- Scroll down exactly one page
					Pos = Vector2.new(0, TargetY)

					-- If they are about to reach the bottom on the next click, flip the arrow
					if TargetY + PageHeight >= MaxScroll - 5 then
						TS:Create(BTN,TweenInfo.new(0.15,Enum.EasingStyle.Cubic,Enum.EasingDirection.InOut,0,false,0),{Rotation = 180}):Play()
					end
				end

				TS:Create(ScrollingFrame,TweenInfo.new(0.5,Enum.EasingStyle.Cubic,Enum.EasingDirection.InOut,0,false,0),{CanvasPosition = Pos}):Play()
			end
		end)
	end
end

for i,BTN in pairs(StorageBoxframe:GetDescendants()) do
	if BTN:IsA("GuiButton") then
		BTN.MouseButton1Click:Connect(function()
			if BTN.Name == "100" or BTN.Name == "50" or BTN.Name == "25" then
				FarmersMarketRem:FireServer("RestockStorageBox",{Percent = BTN.Name,InFarmersMarket = InFarmersMarketZone})
			elseif BTN.Name == "300" or BTN.Name == "175" then
				if InFarmersMarketZone == true then
					local ProductID = DEV_PRODUCTS[BTN.Name]
					MS:PromptProductPurchase(Player, ProductID)
				end
			elseif BTN.Name == "PutInFoodStat" then
				FarmersMarketRem:FireServer("GivePlayerFoodFromFoodBoxes",InFarmersMarketZone)
			elseif BTN.Name == "Close" then
				local Tween = TS:Create(StorageBoxframe,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.In,0,false,0),{Position = UDim2.fromScale(0.5,1.5)})
				Tween:Play()
				Tween.Completed:Once(function()
					StorageBoxframe.Visible = false
				end)
				HUD.Gift.Visible = true
			elseif BTN.Name == "ExpandArrow" and BTN.Title.Rotation == 0 then
				TS:Create(BTN.Title,TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out,0,false,0),{Rotation = 180}):Play()
				TS:Create(StorageBoxframe.ImageFrame.UIGridLayout,TweenInfo.new(0.35,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,false,0),{CellSize = UDim2.fromScale(0.2,0.8)}):Play()
				StorageBoxframe.ImageFrame["300"].Visible = true
			elseif BTN.Name == "ExpandArrow" and BTN.Title.Rotation == 180 then
				TS:Create(BTN.Title,TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.In,0,false,0),{Rotation = 0}):Play()
				TS:Create(StorageBoxframe.ImageFrame.UIGridLayout,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.In,0,false,0),{CellSize = UDim2.fromScale(0.25,1)}):Play()
				StorageBoxframe.ImageFrame["300"].Visible = false
			end
		end)
	end
end


--STORAGE BOX ORGINAL UIGRIDLAYOUTSIZE:{0.25, 0},{1, 0}
--STORAGE BOX EXPANDED UIGRIDLAYOUTSIZE{0.2, 0},{0.8, 0}
SetupFarmersMarketSpot()
FarmersMarketSkillTree.UnlockFarmersMarket:GetPropertyChangedSignal("Value"):Connect(SetupFarmersMarketSpot)

RunService.Heartbeat:Connect(function(deltaTime)
	MarketAreaDetection(deltaTime)
	--
end)

FarmersMarketRem.OnClientEvent:Connect(function(Action,Data)
	if Action == "OpenStorageBoxRestockMenu" then
		HUD.StorageBoxFrame.Position = UDim2.fromScale(0.5,1.5)
		HUD.StorageBoxFrame.Visible = true
		TS:Create(HUD.StorageBoxFrame,TweenInfo.new(0.45,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,false,0),{Position = UDim2.fromScale(0.5,0.89)}):Play()	
		local TotalAdded = PlayerStats.FoodBoxesValue
		local Remainder = 0
		for i,v in pairs(StorageBoxframe.ImageFrame:GetChildren()) do
			if v:IsA("ImageButton") then
				if v.Name == "300" then
					StorageBoxframe.ImageFrame[v.Name].Amount.Text = FrmtNum((TotalAdded.Value * 3),2).." Food"
				end
				if v.Name == "175" then
					StorageBoxframe.ImageFrame[v.Name].Amount.Text = FrmtNum((TotalAdded.Value * 1.75),2).." Food"
				end
				if v.Name == "100" then
					StorageBoxframe.ImageFrame[v.Name].Amount.Text = FrmtNum((TotalAdded.Value * 1),2).." Food"
				end
				if v.Name == "50" then
					StorageBoxframe.ImageFrame[v.Name].Amount.Text = FrmtNum((TotalAdded.Value * 0.5),2).." Food"
				end
				if v.Name == "25" then
					StorageBoxframe.ImageFrame[v.Name].Amount.Text = FrmtNum((TotalAdded.Value * 0.25),2).." Food"
				end
			end
		end
		StorageBoxframe.PutInFoodStat.Amount.Text = FrmtNum(TotalAdded.Value,2).." Food"
		
	elseif Action == "CloseStorageBoxRestockMenu" then
		local Tween = TS:Create(HUD.StorageBoxFrame,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.In,0,false,0),{Position = UDim2.fromScale(0.5,1.5)})
		Tween:Play()
		Tween.Completed:Once(function()
			HUD.StorageBoxFrame.Visible = false
		end)
	elseif Action == "NotEnoughFood" then
		NotifModule.Notify(Player,"Not Enough Food In Storage Box!")
	elseif Action == "MoneySplash" and Data then
		local Customer:Model = Data[1]
		local IsGoldenSale:boolean = Data[2]
		local MoneySplashVFX = RS:WaitForChild("Assets").VFX.MoneySplash:Clone()
		if IsGoldenSale == true then
			MoneySplashVFX = RS:WaitForChild("Assets").VFX.GoldenMoneySplash:Clone()
		end
		MoneySplashVFX.Parent = workspace.Debris
		if Customer then
			MoneySplashVFX.CFrame = Customer.HumanoidRootPart.CFrame
		end
		for i,v in pairs(MoneySplashVFX:GetChildren()) do
			if v:IsA("ParticleEmitter") then
				v:Emit(v:GetAttribute("EmitCount"))
			end
		end
		Debris:AddItem(MoneySplashVFX,2.5)
		
	end
end)