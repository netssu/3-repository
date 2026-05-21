--SERVICES
local RS = game:GetService("ReplicatedStorage")
local CS = game:GetService("CollectionService")
local TS = game:GetService("TweenService")
local MS = game:GetService("MarketplaceService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

--REFERENCES
local Player = Players.LocalPlayer
local IncrementalRem = RS:WaitForChild("Remotes").IncrementalRemote
local Camera = workspace.CurrentCamera

local Character = script.Parent
repeat task.wait(1) until Player:FindFirstChild("PlayerInfo") and Player.Character:FindFirstChild("ToolFolder")

local PlayerGui = Player:WaitForChild("PlayerGui")
local HUD = PlayerGui:WaitForChild("HUD")

local PlayerStats = Player.PlayerStats
local Upgrades = PlayerStats.Upgrades
local FarmersMarketSkillTree = PlayerStats.FarmersMarketSkillTree

--CHARACTER
local HRP = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid") 

local LeaderstatValues = Player:FindFirstChild("leaderstatValues")
local PlayerStats = Player:FindFirstChild("PlayerStats")

local Rebirths:NumberValue = PlayerStats.Rebirths
local CashVal:NumberValue = LeaderstatValues.Cash
local FoodVal:NumberValue = LeaderstatValues.Food
local LevelVal:NumberValue = LeaderstatValues.Level
local FoodBoxesVal:NumberValue = PlayerStats.FoodBoxesValue

--MODULES
local NotifModule = require(RS:WaitForChild("Modules").NotifModule)

--INGREDIENTS
local IngredientsSpawnSpeed = Upgrades.IngredientsSpawnSpeed
local MaxAmountofIngredients = Upgrades.MaxAmountofIngredients
local ChanceOfGoldenIngredients = Upgrades.ChanceOfGoldenIngredients

local IngredientsPerCollect = Upgrades.IngredientsPerCollect
local MultiIngredientsPerCollect = Upgrades.MultiplyIngredientsPerCollect

local IngredientsStorage = RS:WaitForChild("Assets").Ingredients
local IngredientCollection = workspace.Map.CenterPoint.IngredientCollection
local IngredientUpgradeBoards = IngredientCollection:WaitForChild("UpgradeBoards")
local IngredientsDetectionZone = IngredientCollection:WaitForChild("DetectionZone")
local IngredientsCollectionZone = IngredientCollection:WaitForChild("CollectionZone")

local IngredientsGamepasses = IngredientCollection:WaitForChild("Gamepasses")

local FoodCollection = workspace.Map.CenterPoint.FoodCollection
local CookingPot = FoodCollection.CookingPot
local FoodUpgradeBoards = FoodCollection.UpgradeBoards
local UpgradeBoardsOriginalPos = FoodCollection:WaitForChild("UpgradeBoardsOriginalPos")

-- INGREDIENT VARIABLES
local PlayerFoodBoxes = workspace.PlayerFoodBoxes
local PlayerIngredients = workspace.PlayerIngredients
local MyIngredients = PlayerIngredients:WaitForChild(Player.UserId)

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
	if ab < 1000 then
		return roundToDecimals(x, decimalPlaces)
	end 
	local num = roundToDecimals(ab / Nums[p], decimalPlaces)
	return num * math.sign(x) .. names[p]
end

local DEV_PRODUCTS = {
	-- EXISTING PRODUCTS --
	["x3RebirthFood"] = 3536596994,
	["x3RebirthIngredients"] = 3519178993,
	["MultiplyRebirthAmount"] = 3519178218,
	["MultiplyFoodRebirthAmount"] = 3536596696,
	["IngredientsPerCollect"] = 3519176434,
	["IngredientsSpawnSpeed"] = 3519176811,
	["MaxAmountofIngredients"] = 3519177099,
	["MultiplyIngredientsPerCollect"] = 3519177345,
	["ChanceOfGoldenIngredients"] = 3519177702,
	["FoodPerIngredients"] = 3532871149,
	["CookingSpeed"] = 3536595502,
	["MultiplyFoodPerIngredients"] = 3536595737,
	["ChanceOfGoldenFood"] = 3536595954,
	["CashPerFood"] = 3538792865,
	["SaleSpeed"] = 3538793145,
	["MultiplyCashPerFood"] = 3538793654,
	["ChanceOfGoldenSale"] = 3538794137,
	["AllGoldIngredients"] = 3521204295,
	["AllGoldFood"] = 3573056951,
	["StarterPack"] = 3572470751,
	["GamepassBundle"] = 3572473395,
	
	-- [[ NEW: SHOP CURRENCY PACKS ]] --
	-- Food
	["10kFood"] = 3572436932,
	["100kFood"] = 3572437050,
	["1mFood"] = 3572437171,
	["100mFood"] = 3572437284,

	-- Cash
	["10kCash"] = 3572438619,
	["100kCash"] = 3572438708,
	["1mCash"] = 3572438849,
	["100mCash"] = 3572438950,

	-- Ingredients
	["30kIngredients"] = 3572437461,
	["250kIngredients"] = 3572437936,
	["2.5mIngredients"] = 3572438321,
	["250mIngredients"] = 3572438478,

	-- Rebirths
	["150Rebirths"] = 3572439093,
	["2000Rebirths"] = 3572439237,
	["100kRebirths"] = 3572439405,
	["5mRebirths"] = 3572439503,

	-- Gourmet Food 
	-- (Double check your Explorer names for these, using standard names here!)
	["15kGourmetFood"] = 3572439702,
	["200kGourmetFood"] = 3572442137,
	["2.5mGourmetFood"] = 3572442377,
	["200mGourmetFood"] = 3572442568,
}

local PASSES = {
	["x3TimesRadius"] = 1683505672,
	["Magnet"] = 1683645969,
	["x2Cash"] = 1778736163,
	["x2Food"] = 1780493951,
	["x2Ingredients"] = 1779810015,
	["x2Rebirths"] = 1779204083,
	["x2GourmetFood"] = 1779498046,
}

-- Prompt pass purchase
local function promptPurchase(passID)
	local player = Players.LocalPlayer
	local hasPass = false

	local success, message = pcall(function()
		hasPass = MS:UserOwnsGamePassAsync(player.UserId, passID)
	end)

	if not success then
		warn("Error while checking if player has pass: " .. tostring(message))
		return
	end

	if hasPass then
		NotifModule.Notify(Player,"You Already Own This Pass!")
		-- Show a message telling user they already own the pass
	else
		-- Prompt pass purchase
		MS:PromptGamePassPurchase(player, passID)
	end
end

-- Prompt dev product purchase safely
local function promptProduct(productName, productID)
	-- Guard check for the Gamepass Bundle
	if productName == "GamepassBundle" or productName == "GampassBundle" then
		local allOwned = true
		for passName, _ in pairs(PASSES) do
			if not Player:GetAttribute(passName) then
				allOwned = false
				break
			end
		end

		if allOwned then
			-- Stop the purchase and tell them they have everything
			if NotifModule and NotifModule.Notify then
				NotifModule.Notify("You already own all the Gamepasses in this bundle!")
			end
			return
		end
	end

	-- Prompt the product normally
	MS:PromptProductPurchase(Player, productID)
end

for i,Btn in pairs(IngredientsGamepasses:GetDescendants()) do
	if Btn:IsA("TextButton") and Btn.Name == "Robux" then
		Btn.MouseButton1Click:Connect(function()
			local IsProduct = false
			local IsPass = false
			for i,v in pairs(DEV_PRODUCTS) do
				if Btn.Parent.Name == i then
					IsProduct = true
					break
				end
			end
			for i,v in pairs(PASSES) do
				if Btn.Parent.Name == i then
					IsPass = true
					break
				end
			end

			local ChosenPass = Btn.Parent.Name

			if IsProduct == true and IsPass == false then
				local PID = DEV_PRODUCTS[ChosenPass]
				if PID then promptProduct(ChosenPass, PID) end
				
			elseif IsPass == true and IsProduct == false then
				
				local PID = PASSES[ChosenPass]
				if PID then promptPurchase(PID) end
			end

		end)
	end
end

for i,Btn in pairs(HUD.IngredientCollectionHUD:GetDescendants()) do
	if Btn:IsA("GuiButton") then
		Btn.MouseButton1Click:Connect(function()
			local IsProduct = false
			local IsPass = false
			for i,v in pairs(DEV_PRODUCTS) do
				if Btn.Name == i then
					IsProduct = true
					break
				end
			end
			for i,v in pairs(PASSES) do
				if Btn.Name == i then
					IsPass = true
					break
				end
			end

			local ChosenPass = Btn.Name

			if IsProduct == true and IsPass == false then
				local PID = DEV_PRODUCTS[ChosenPass]
				if PID then promptProduct(ChosenPass, PID) end

			elseif IsPass == true and IsProduct == false then

				local PID = PASSES[ChosenPass]
				if PID then promptPurchase(PID) end
			end

		end)
	end
end

for i,Btn in pairs(HUD.FoodCollectionHUD:GetDescendants()) do
	if Btn:IsA("GuiButton") then
		Btn.MouseButton1Click:Connect(function()
			local IsProduct = false
			local IsPass = false
			for i,v in pairs(DEV_PRODUCTS) do
				if Btn.Name == i then
					IsProduct = true
					break
				end
			end
			for i,v in pairs(PASSES) do
				if Btn.Name == i then
					IsPass = true
					break
				end
			end

			local ChosenPass = Btn.Name

			if IsProduct == true and IsPass == false then
				local PID = DEV_PRODUCTS[ChosenPass]
				if PID then promptProduct(ChosenPass, PID) end

			elseif IsPass == true and IsProduct == false then

				local PID = PASSES[ChosenPass]
				if PID then promptPurchase(PID) end
			end

		end)
	end
end

for i,Btn in pairs(HUD.RightSideButtons:GetDescendants()) do
	if Btn:IsA("GuiButton") then
		Btn.MouseButton1Click:Connect(function()
			local IsProduct = false
			local IsPass = false
			if not Btn:FindFirstChild("GamepassInfo") then return end
			local ChosenPass = Btn.GamepassInfo.Value
			for i,v in pairs(DEV_PRODUCTS) do
				if ChosenPass == i then
					IsProduct = true
					break
				end
			end
			for i,v in pairs(PASSES) do
				if ChosenPass == i then
					IsPass = true
					break
				end
			end

			if IsProduct == true and IsPass == false then
				local PID = DEV_PRODUCTS[ChosenPass]
				if PID then promptProduct(ChosenPass, PID) end

			elseif IsPass == true and IsProduct == false then

				local PID = PASSES[ChosenPass]
				if PID then promptPurchase(PID) end
			end

		end)
	end
end


for i,Btn in pairs(HUD:GetDescendants()) do
	if Btn:IsA("GuiButton") then
		Btn.MouseButton1Click:Connect(function()
			if Btn.Name == "Purchase" then
				local IsProduct = false
				local IsPass = false
				for i,v in pairs(DEV_PRODUCTS) do
					if Btn.Parent.Name == i then
						IsProduct = true
						break
					end
				end
				for i,v in pairs(PASSES) do
					if Btn.Parent.Name == i then
						IsPass = true
						break
					end
				end

				local ChosenPass = Btn.Parent.Name

				if IsProduct == true and IsPass == false then
					local PID = DEV_PRODUCTS[ChosenPass]
					if PID then promptProduct(ChosenPass, PID) end

				elseif IsPass == true and IsProduct == false then

					local PID = PASSES[ChosenPass]
					if PID then promptPurchase(PID) end
				end
				
			elseif Btn.Name == "Close" then
				local Tween = TS:Create(Btn.Parent,TweenInfo.new(0.45,Enum.EasingStyle.Back,Enum.EasingDirection.In,0,false,0),{Position = UDim2.fromScale(1.5,0.5)})
				Tween:Play()
				Tween.Completed:Once(function()
					Btn.Parent.Visible = false
				end)
			end 
		end)
	end
end

-- [[ GOLD BUFF TIMER DISPLAY ]]
-- Reference the new TextLabel you just made
local GoldBuffTimerLabel = HUD:FindFirstChild("IngredientCollectionHUD").AllGoldIngredients.Timer

RunService.Heartbeat:Connect(function()
	-- Read the exact end time the server gave us
	local endTime = Player:GetAttribute("GoldBuffEndTime")

	if endTime then
		-- Calculate how much time is left right now
		local timeLeft = endTime - workspace:GetServerTimeNow()

		if timeLeft > 0 then
			-- Show the UI and format the math into MM:SS
			GoldBuffTimerLabel.Visible = true

			local minutes = math.floor(timeLeft / 60)
			local seconds = math.floor(timeLeft % 60)

			-- string.format("%02d") ensures single digits have a leading zero (e.g., 05 instead of 5)
			GoldBuffTimerLabel.Text = string.format("All Gold: %02d:%02d", minutes, seconds)
		else
			-- Timer hit 0, hide the UI
			GoldBuffTimerLabel.Visible = false
		end
	else
		-- The player doesn't have the attribute yet, keep UI hidden
		GoldBuffTimerLabel.Visible = false
	end
end)

local GamepassShopIcon = HUD.SideButtons.GamepassShop.Icon
task.spawn(function()
	-- Save the original state so it always returns to normal
	local origPos = GamepassShopIcon.Position
	local origRot = GamepassShopIcon.Rotation

	while true do
		task.wait(3) -- Wait 1.5 seconds between each jump

		if HUD.SideButtons.GamepassShop.Visible then
			-- A. Jump Up (Moves the Y Offset up by 15 pixels)
			TS:Create(GamepassShopIcon, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				Position = UDim2.new(origPos.X.Scale, origPos.X.Offset, origPos.Y.Scale, origPos.Y.Offset - 15)
			}):Play()

			task.wait(0.15)

			-- B. Wiggle Left and Right
			TS:Create(GamepassShopIcon, TweenInfo.new(0.05, Enum.EasingStyle.Sine), {Rotation = origRot - 15}):Play()
			task.wait(0.05)
			TS:Create(GamepassShopIcon, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {Rotation = origRot + 15}):Play()
			task.wait(0.1)
			TS:Create(GamepassShopIcon, TweenInfo.new(0.05, Enum.EasingStyle.Sine), {Rotation = origRot}):Play()

			-- C. Fall Back Down
			TS:Create(GamepassShopIcon, TweenInfo.new(0.15, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
				Position = origPos
			}):Play()
		end
	end
end)

-- [[ AUTOMATED GAMEPASS & DEV PRODUCT SHUFFLE UI ]] --

-- 1. Reference the UI
local GamepassShuffle = HUD:WaitForChild("GamepassShuffle")
local PassIcon = GamepassShuffle:WaitForChild("PassIcon")
local PassNameLabel = GamepassShuffle:WaitForChild("Timer") 
local PassPrice = GamepassShuffle:WaitForChild("PassPrice")
local Sunburst = GamepassShuffle:WaitForChild("Sunburst") -- Get the Sunburst from your UI

-- 2. Define exactly which Dev Products you want in the rotation
local SHUFFLE_DEV_PRODUCTS = {
	["100k Rebirths"] = 3572439405,
	["150 Rebirths"] = 3572439093,
	["100kFood"] = 3572437050,
	["1mCash"] = 3572438849,
	["StarterPack"] = 3572470751,
	["10kFood"] = 3572436932,
	["100kCash"] = 3572438708,
	["15k Gourmet Food"] = 3572439702,
	["250k Ingredients"] = 3572437936,
	["30k Ingredients"] = 3572437461,
	["HireShopper"] = 3579906145,
	["HireSeller"] = 3579906391,
	-- Add any others you want to show up in the corner!
}

-- 3. Build the Master Shuffle List
local ShuffleItems = {}

-- Add Gamepasses to the list
for passName, passID in pairs(PASSES) do
	table.insert(ShuffleItems, {
		Name = passName, 
		ID = passID, 
		ItemType = Enum.InfoType.GamePass
	})
end

-- Add specific Dev Products to the list
for prodName, prodID in pairs(SHUFFLE_DEV_PRODUCTS) do
	table.insert(ShuffleItems, {
		Name = prodName, 
		ID = prodID, 
		ItemType = Enum.InfoType.Product
	})
end

-- Variables to keep track of the current rotation
local currentShuffleIndex = 1
local currentShuffleItem = nil

-- 4. The 3-Minute Shuffle Loop
task.spawn(function()
	while true do
		-- Grab the current item's data table from our master list
		currentShuffleItem = ShuffleItems[currentShuffleIndex]

		-- Fetch the exact Data from the Roblox Website using the correct ItemType
		local success, itemInfo = pcall(function()
			return MS:GetProductInfoAsync(currentShuffleItem.ID, currentShuffleItem.ItemType)
		end)

		if success and itemInfo then
			-- Update the UI
			PassIcon.Image = "rbxassetid://" .. itemInfo.IconImageAssetId
			PassPrice.Text = "R$" .. tostring(itemInfo.PriceInRobux)
			PassNameLabel.Text = itemInfo.Name 
		else
			warn("Failed to load info for ID: " .. tostring(currentShuffleItem.ID))
		end

		-- Wait 16 Seconds (16 seconds)
		task.wait(16)

		-- Move to the next item, loop back to 1 if we hit the end
		currentShuffleIndex += 1
		if currentShuffleIndex > #ShuffleItems then
			currentShuffleIndex = 1
		end
	end
end)

-- [[ VISUAL EFFECTS: SUNBURST & WIGGLE ]]

-- 1. Continuous Sunburst Spin
RunService.RenderStepped:Connect(function(deltaTime)
	if GamepassShuffle.Visible then
		Sunburst.Rotation = Sunburst.Rotation + (deltaTime * 45) -- 45 degrees per second
	end
end)

-- 2. Jump and Wiggle Sequence for the PassIcon
task.spawn(function()
	-- Save the original state so it always returns to normal
	local origPos = PassIcon.Position
	local origRot = PassIcon.Rotation

	while true do
		task.wait(3.5) -- Wait 1.5 seconds between each jump

		if GamepassShuffle.Visible then
			-- A. Jump Up (Moves the Y Offset up by 15 pixels)
			TS:Create(PassIcon, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				Position = UDim2.new(origPos.X.Scale, origPos.X.Offset, origPos.Y.Scale, origPos.Y.Offset - 15)
			}):Play()

			task.wait(0.15)

			-- B. Wiggle Left and Right
			TS:Create(PassIcon, TweenInfo.new(0.05, Enum.EasingStyle.Sine), {Rotation = origRot - 15}):Play()
			task.wait(0.05)
			TS:Create(PassIcon, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {Rotation = origRot + 15}):Play()
			task.wait(0.1)
			TS:Create(PassIcon, TweenInfo.new(0.05, Enum.EasingStyle.Sine), {Rotation = origRot}):Play()

			-- C. Fall Back Down
			TS:Create(PassIcon, TweenInfo.new(0.15, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
				Position = origPos
			}):Play()
		end
	end
end)

-- 5. Handle the clicking dynamically
if GamepassShuffle:IsA("GuiButton") then
	GamepassShuffle.MouseButton1Click:Connect(function()
		if not currentShuffleItem then return end

		-- Check the ItemType and fire the correct existing prompt function!
		if currentShuffleItem.ItemType == Enum.InfoType.GamePass then
			promptPurchase(currentShuffleItem.ID)
		elseif currentShuffleItem.ItemType == Enum.InfoType.Product then
			promptProduct(currentShuffleItem.Name, currentShuffleItem.ID)
		end
	end)
end