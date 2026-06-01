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
local PlayerPlotRem = RS:WaitForChild("Remotes").PlayerPlotRemote
local MilestonesRem = RS:WaitForChild("Remotes").MilestonesRemote
local LayoutBtnBindable = RS:WaitForChild("Remotes").LayoutBtnBindable
local Camera = workspace.CurrentCamera

--MODULES
local UpgradesDictionary = require(RS:WaitForChild("Modules").UpgradesDictionary)
local MilestonesDictionary = require(RS:WaitForChild("Modules").MilestonesDictionary)
local NotifModule = require(RS:WaitForChild("Modules").NotifModule)

local CashCollectionFolder = workspace.Map.CenterPoint.CashCollection

local Character = script.Parent
repeat task.wait(1) until Player:FindFirstChild("PlayerInfo") and Player.Character:FindFirstChild("ToolFolder")

local PlayerGui = Player:WaitForChild("PlayerGui")
local HUD = PlayerGui:WaitForChild("HUD")
local ItemsUI = PlayerGui:WaitForChild("HUD").Items
local MarketButtons:Frame = PlayerGui:WaitForChild("HUD").FarmersMarketButtons
local RestaurantUpgradesUI:Frame = PlayerGui:WaitForChild("HUD").RestaurantUpgrades
local StorageBoxframe:Frame = PlayerGui:WaitForChild("HUD").StorageBoxFrame

--CHARACTER
local HRP = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid") 

local LeaderstatValues = Player:FindFirstChild("leaderstatValues")
local PlayerStats = Player:FindFirstChild("PlayerStats")
local PlayerInfo = Player:WaitForChild("PlayerInfo")

local Upgrades = PlayerStats.Upgrades
local FarmersMarketSkillTree = PlayerStats.FarmersMarketSkillTree
local Milestones = PlayerStats.Milestones

local Rebirths:NumberValue = PlayerStats.Rebirths
local CashVal:NumberValue = LeaderstatValues.Cash
local FoodVal:NumberValue = LeaderstatValues.Food
local LevelVal:NumberValue = LeaderstatValues.Level

local Plots = workspace.Plots
local PlayerInfo = Player.PlayerInfo
local PlayerSpotVal = PlayerInfo.PlayerSpot
local PlayerPlot = Plots:FindFirstChild(PlayerSpotVal.Value,true)
local RestaurantSkillTree = PlayerStats.RestaurantSkillTree

--INGREDIENTS
local IngredientsSpawnSpeed = Upgrades.IngredientsSpawnSpeed
local MaxAmountofIngredients = Upgrades.MaxAmountofIngredients
local ChanceOfGoldenIngredients = Upgrades.ChanceOfGoldenIngredients

local IngredientsPerCollect = Upgrades.IngredientsPerCollect
local MultiIngredientsPerCollect = Upgrades.MultiplyIngredientsPerCollect

local IngredientsStorage = RS:WaitForChild("Assets").Ingredients

local FoodCollection = workspace.Map.CenterPoint.FoodCollection
local CookingPot = FoodCollection.CookingPot
local FoodUpgradeBoards = FoodCollection.UpgradeBoards

--VARIABLES

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

for i,Milestone in pairs(MilestonesDictionary.Milestones) do
	local ItemSlot = RS:WaitForChild("UIAssets").ItemsSlot:Clone()
	ItemSlot.Parent = ItemsUI.ScrollingFrame
	ItemSlot.Name = i
	ItemSlot.Title.Text = Milestone.Description
	ItemSlot.LayoutOrder = Milestone.LayoutOrder
	ItemSlot.Icon.Image = Milestone.Image
	ItemSlot.Equip.Visible = false
	ItemSlot.ExpFrame.Visible = true
	if Milestones[ItemSlot.Name].Value == true then
		ItemSlot.Equip.Visible = true
		ItemSlot.ExpFrame.Visible = false
	end
end

-- [[ 1. TRACK STAT PROGRESS & UI SWAP FIX ]]
for i , Milestone:BoolValue in pairs(Milestones:GetChildren()) do
	for _,Stat in pairs(Player:GetDescendants()) do
		if Stat:IsA("NumberValue") then
			if Stat.Name == MilestonesDictionary.Milestones[Milestone.Name].Stat and Milestone.Value == false then

				local StatConnection -- Create a variable to hold the connection

				local function UpdateMilestone()
					local StatSlot = ItemsUI.ScrollingFrame:FindFirstChild(Milestone.Name)
					if not StatSlot then return end

					local EXPFrame = StatSlot:FindFirstChild("ExpFrame")
					if not EXPFrame then return end

					if Stat.Value >= MilestonesDictionary.Milestones[Milestone.Name].Value then
						EXPFrame.ExpBar.Position = UDim2.fromScale(0.989,0.5)
						EXPFrame.WhitePart.Position = UDim2.fromScale(0.989,0.5)
						EXPFrame.Experience.Text = FrmtNum(MilestonesDictionary.Milestones[Milestone.Name].Value,2).."/"..FrmtNum(MilestonesDictionary.Milestones[Milestone.Name].Value,2)

						local ImageId = MilestonesDictionary.Milestones[Milestone.Name].Image
						local Reward = MilestonesDictionary.Milestones[Milestone.Name].Reward
						NotifModule.ItemNotify(Player,ImageId,"ITEM RECEIVED: "..Reward)

						-- FIX: Disconnect the event so it stops spamming forever!
						if StatConnection then
							StatConnection:Disconnect()
						end
						return	
					end

					EXPFrame.ExpBar.Position = UDim2.fromScale(Stat.Value/MilestonesDictionary.Milestones[Milestone.Name].Value,0.5)
					EXPFrame.WhitePart.Position = UDim2.fromScale(Stat.Value/MilestonesDictionary.Milestones[Milestone.Name].Value,0.5)
					EXPFrame.Experience.Text = FrmtNum(Stat.Value,2).."/"..FrmtNum(MilestonesDictionary.Milestones[Milestone.Name].Value,2)
				end

				UpdateMilestone()

				-- Assign the connection to the variable we made above
				StatConnection = Stat:GetPropertyChangedSignal("Value"):Connect(UpdateMilestone)
			end	
		end
	end

	-- [[ FIX: UI DOESN'T SWAP TO EQUIP WHEN UNLOCKED IN-GAME ]]
	Milestone:GetPropertyChangedSignal("Value"):Connect(function()
		local StatSlot = ItemsUI.ScrollingFrame:FindFirstChild(Milestone.Name)
		if StatSlot then
			if Milestone.Value == true then
				StatSlot.Equip.Visible = true
				StatSlot.ExpFrame.Visible = false

				-- Optional: Quick pop animation so they notice they unlocked it!
				local UIScale = StatSlot.Equip:FindFirstChild("UIScale") or Instance.new("UIScale", StatSlot.Equip)
				TS:Create(UIScale, TweenInfo.new(0.3, Enum.EasingStyle.Bounce), {Scale = 1.1}):Play()
				task.delay(0.3, function()
					TS:Create(UIScale, TweenInfo.new(0.2), {Scale = 1}):Play()
				end)
			elseif Milestone.Value == false then
				StatSlot.Equip.Visible = false
				StatSlot.ExpFrame.Visible = true
			end
		end
	end)
end

-- [[ 2. SYNC BUTTON COLORS TO ATTRIBUTES ]]
for _, Milestone in pairs(Milestones:GetChildren()) do
	local function UpdateButtonVisuals()
		local StatSlot = ItemsUI.ScrollingFrame:FindFirstChild(Milestone.Name)
		if not StatSlot then return end

		local EquipBtn = StatSlot:FindFirstChild("Equip")
		if not EquipBtn then return end

		local isEquipped = Milestone:GetAttribute("Equipped")

		if isEquipped then
			EquipBtn.Title.Text = "Unequip"
			EquipBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50) -- Red
		else
			EquipBtn.Title.Text = "Equip"
			EquipBtn.BackgroundColor3 = Color3.fromRGB(50, 220, 50) -- Green
		end
	end

	-- Listen for changes sent from the server (Automatically fixes previously equipped items in the same category turning back to green!)
	Milestone:GetAttributeChangedSignal("Equipped"):Connect(UpdateButtonVisuals)

	-- Set initial state
	UpdateButtonVisuals()
end

-- [[ 3. BUTTON CLICK LOGIC ]]
for i, BTN in pairs(ItemsUI:GetDescendants()) do
	if BTN:IsA("GuiButton") then
		BTN.MouseButton1Click:Connect(function()
			if BTN.Name == "Equip" then
				local ClickedMilestone = BTN.Parent.Name
				local MilestoneVal = Milestones:FindFirstChild(ClickedMilestone)

				if MilestoneVal and MilestoneVal.Value == true then
					local isEquipped = MilestoneVal:GetAttribute("Equipped")

					-- Button Bounce Animation
					local UIScale = BTN:FindFirstChild("UIScale") or Instance.new("UIScale", BTN)
					TS:Create(UIScale, TweenInfo.new(0.1, Enum.EasingStyle.Bounce), {Scale = 0.9}):Play()
					task.delay(0.1, function()
						TS:Create(UIScale, TweenInfo.new(0.1, Enum.EasingStyle.Bounce), {Scale = 1}):Play()
					end)

					-- Fire the appropriate state to the server
					if not isEquipped then
						MilestonesRem:FireServer("EquipItem", {MilestoneName = ClickedMilestone})
					else
						MilestonesRem:FireServer("UnEquipItem", {MilestoneName = ClickedMilestone})
					end
				end

			elseif BTN.Name == "Close" then
				local Tween = TS:Create(BTN.Parent, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In, 0, false, 0), {Position = UDim2.fromScale(1.5, 0.5)})
				Tween:Play()
				Tween.Completed:Once(function()
					BTN.Parent.Visible = false
				end)
			end
		end)
	end
end