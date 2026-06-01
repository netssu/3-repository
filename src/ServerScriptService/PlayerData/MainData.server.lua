--SERVICES
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local BadgeService = game:GetService("BadgeService")

--MODULES
local DataStoreModule = require(SS:WaitForChild("Modules").MainDataModule)
local SkillTreeDict = require(SS:WaitForChild("Modules").SkillTreeDict)

--REMOTES
local LoadRemote = RS:WaitForChild("Remotes").LoadRemote
local TutorialRemote = RS:WaitForChild("Remotes").TutorialRemote
local LoadBindable = RS:WaitForChild("Remotes").LoadBindable

local CashCollectionFolder = workspace.Map.CenterPoint.CashCollection
local FarmersMarketFoodStorage = SS:WaitForChild("Assets").FarmersMarketFoods


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


local LeaderStatsKeys = {
	"⬆Level",
	"🍲Food",
	"💰Cash",
}
local LeaderStatsValuesKeys = {
	"Level",
	"Food",
	"Cash",
}

local PlayerStatsKeys = {
	"Rebirths",
	"Ingredients",
	"Mastery",
	"Gourmet Food",
	"Experience",
	"MaxExperience",
	"StoredMarketFood",
	"StoredRestaurantFood",
	"CurrentFoodBoxes",
	"FoodBoxesValue",
	"TutorialComplete",
	"FirstGame",
}
local MilestoneKeys = {
	"ReachLevel5",
	"ReachLevel15",
	"ReachLevel30",
	"1kIngredients",
	"10kFood",
	"100kFood",
	"10kCash",
	"100kCash",
}
local OfflineEarningsKeys = {
	"IngredientsOffline",
	"CashOffline",
	"Gourmet FoodOffline",
}

local UpgradesKeys = {
	"MultiplyRebirthAmount",
	"MultiplyFoodRebirthAmount",
	"SpeedWithRebirths",

	--Ingredients
	"IngredientsPerCollect",
	"IngredientsSpawnSpeed",
	"MaxAmountofIngredients",
	"MultiplyIngredientsPerCollect",
	"ChanceOfGoldenIngredients",

	--Foods
	"FoodPerIngredients",
	"CookingSpeed",
	"MultiplyFoodPerIngredients",
	"ChanceOfGoldenFood",

	--CASH
	"CashPerFood",
	"SaleSpeed",
	"MultiplyCashPerFood",
	"ChanceOfGoldenSale",

	--GOURMET FOOD
	"GourmetFoodPerFood",
	"MultiplyGourmetFoodPerFood",
	"GourmetCookingSpeed",
	"CashPerGourmetFood",
	"MultiplyCashPerGourmetFood",
	"CustomerRate",
	"ChanceOfGoldenGourmet",
}

local FarmersMarketSkillKeys = {
	--Food
	"UnlockFarmersMarket",
	"20IngredientsPerFood",
	"10IngredientsPerFood",
	"2IngredientsPerFood",
	"x1.5Food",
	"x3Food",
	--Rebirths
	"x1.5Rebirths",
	"x1.5WalkSpeed",
	"FoodBoostedByPlayTime",
	"RebirthsBoostedByPlayTime",
	"IngredientsBoostedByPlayTime",
	"FoodMultipliedByLevel",
	--Cash
	"x1.5Cash",
	"x3Cash",
	"x1.5Ingredients",
	"x3Ingredients",
}

local RestaurantSkillKeys = {
	"UnlockRestaurant", --Cash
	"BuildWalls", --Cash
	"BuildKitchen", --Cash
	"BuildCeiling", --Cash
	"PurchaseFurniture", --Cash
	"BuildDoors", --Cash
	"x5Food", --Food
	"x1.5GourmetFood", --GourmetFood
	"x3GourmetFood", --GourmetFood
	"x5Cash", --Cash
	"GourmetFoodBoostedByPlayTime", --GourmetFood
	"GourmetFoodMultipliedByLevel", --Cash
	"10FoodPerGourmetFood", --Cash
	"5FoodPerGourmetFood", --Cash
	"5GourmetFoodPerSale", --Cash
	"2GourmetFoodPerSale", --Cash
}

local RestaurantUnlocksKeys = {
	"ChefUnlocked",
	"CustomizationUnlocked",
}

local HiredWorkersKeys = {
	"Shopper",
	"Seller",
}

local RestaurantCustomizationKeys = {
	"PrimaryBuildingColor",
	"SecondaryBuildingColor",
	"TableColor",
	"ChairColor",
}

local ExtendedTutorialKeys = {
	"FirstStep" ,
	"SecondStep",
	"ThirdStep",
	"FourthStep",
	"FifthStep",
}

local ValuesToSave = {
	["💰Cash"] = 0,
	["🍲Food"] = 0,
	["⬆Level"] = 1,
	["Cash"] = 0,
	["Food"] = 0,
	["Level"] = 1,
	["Gourmet Food"] = 0,
	StoredMarketFood = 0,
	StoredRestaurantFood = 0,
	CurrentFoodBoxes = 0,
	FoodBoxesValue = 0,
	Rebirths = 0,
	Ingredients = 0,
	Experience = 0,
	MaxExperience = 0,
	Mastery = 0,
	EquippedTool = nil,
	FirstGame = true,
	TutorialComplete = false,
	ExtendedTutorialComplete = false,
	TimePlrLeft = 0,
	TotalTimePlayed = 0,
	ActivePorts = 0,
	PlatesInHand = 0,
	PlatesPlaced = 0,
	
	DailyStreak = 1,  
	LastDailyDay = 0,
	
	OfflineEarnings = {
		CashOffline = 0,
		IngredientsOffline = 0,
		["Gourmet FoodOffline"] = 0,
	},
	
	HiredWorkers = {
		Shopper = {Active = false,Unlocked = false},
		Seller = {Active = false,Unlocked = false},
	},
	
	RestaurantUnlocks = {
		ChefUnlocked = false,
		CustomizationUnlocked = false,
	},
	RestaurantCustomization = {
		-- Store as tables of numbers instead of Color3 objects
		PrimaryBuildingColor = {0.533333, 0.329412, 0.152941},
		SecondaryBuildingColor = {0.780392, 0.67451, 0.470588},
		TableColor = {0.627451, 0.372549, 0.207843},
		ChairColor = {0.627451, 0.372549, 0.207843},
	},
	
	ExtendedTutorial = {
		FirstStep = {SubStepComplete = false, Complete = false},
		SecondStep = {SubStepComplete = false, Complete = false},
		ThirdStep = {SubStepComplete = false, Complete = false},
		FourthStep = {SubStepComplete = false, Complete = false},
		FifthStep = {SubStepComplete = false, Complete = false},
	},

	Milestones = {
		["ReachLevel5"] = {
			Unlocked = false,
			Equipped = false,
		},
		["ReachLevel15"] = {
			Unlocked = false,
			Equipped = false,
		},
		["ReachLevel30"] = {
			Unlocked = false,
			Equipped = false,
		},
		["1kIngredients"] = {
			Unlocked = false,
			Equipped = false,
		},
		["10kFood"] = {
			Unlocked = false,
			Equipped = false,
		},
		["100kFood"] = {
			Unlocked = false,
			Equipped = false,
		},
		["10kCash"] = {
			Unlocked = false,
			Equipped = false,
		},
		["100kCash"] = {
			Unlocked = false,
			Equipped = false,
		},
		["500kCash"] = {
			Unlocked = false,
			Equipped = false,
		},
		["500kGourmetFood"] = {
			Unlocked = false,
			Equipped = false,
		},
		["Day7Reward"] = {
			Unlocked = false,
			Equipped = false,
		},
	},
	--UPGRADES--
	Upgrades = {
		["MultiplyRebirthAmount"] = 1,
		["MultiplyFoodRebirthAmount"] = 1,
		["SpeedWithRebirths"] = 16,

		["IngredientsPerCollect"] = 2,       -- era 1
		["IngredientsSpawnSpeed"] = 2.0,     -- era 2.75
		["MaxAmountofIngredients"] = 1,
		["MultiplyIngredientsPerCollect"] = 1,
		["ChanceOfGoldenIngredients"] = 1,

		["FoodPerIngredients"] = 2,          -- era 1
		["CookingSpeed"] = 1.8,             -- era 2.5
		["MultiplyFoodPerIngredients"] = 1,
		["ChanceOfGoldenFood"] = 1,

		["CashPerFood"] = 2,                 -- era 1
		["SaleSpeed"] = 1.8,                -- era 2.5
		["MultiplyCashPerFood"] = 1,
		["ChanceOfGoldenSale"] = 1,

		["GourmetFoodPerFood"] = 1,
		["MultiplyGourmetFoodPerFood"] = 1,
		["GourmetCookingSpeed"] = 2.0,      -- BaseValue do GourmetCookingSpeed
		["CashPerGourmetFood"] = 1,
		["MultiplyCashPerGourmetFood"] = 1,
		["CustomerRate"] = 1,
		["ChanceOfGoldenGourmet"] = 1,
	},
	--FarmersMarket SkillTree
	FarmersMarketSkillTree = {
		["UnlockFarmersMarket"] = {Unlocked = false,Price = 1_000_000},--Food
		["20IngredientsPerFood"] = {Unlocked = false,Price = 5_000_000},--Food
		["10IngredientsPerFood"] = {Unlocked = false,Price = 50_000_000},--Food
		["2IngredientsPerFood"] = {Unlocked = false,Price = 500_000_000},--Food
		["x1.5Rebirths"] = {Unlocked = false,Price = 500_000},--Rebirths
		["x1.5Ingredients"] = {Unlocked = false,Price = 1_000_000},--Food
		["x3Ingredients"] = {Unlocked = false,Price = 250_000_000},--Food
		["x1.5Food"] = {Unlocked = false,Price = 10_000_000},--Food
		["x3Food"] = {Unlocked = false,Price = 500_000_000},--Food
		["x1.5Cash"] = {Unlocked = false,Price = 10_000_000},--Cash
		["x3Cash"] = {Unlocked = false,Price = 250_000_000},--Cash
		["x1.5WalkSpeed"] = {Unlocked = false,Price = 5_000_000},--Rebirths
		["FoodBoostedByPlayTime"] = {Unlocked = false,Price = 750_000_000},--Rebirths
		["RebirthsBoostedByPlayTime"] = {Unlocked = false,Price = 250_000_000},--Rebirths
		["IngredientsBoostedByPlayTime"] = {Unlocked = false,Price = 1_000_000_000},--Rebirths
		["FoodMultipliedByLevel"] = {Unlocked = false,Price = 1_500_000_000},--Rebirths
	},
	
	RestaurantSkillTree = {
		["UnlockRestaurant"] = {Unlocked = false,Price = 10_000_000},--Cash
		["BuildWalls"] = {Unlocked = false,Price = 2_500_000},--Cash
		["BuildKitchen"] = {Unlocked = false,Price = 5_000_000},--Cash
		["BuildCeiling"] = {Unlocked = false,Price = 2_000_000},--Cash
		["PurchaseFurniture"] = {Unlocked = false,Price = 6_000_000},--Cash
		["BuildDoors"] = {Unlocked = false,Price = 3_000_000},--Cash
		["x5Food"] = {Unlocked = false,Price = 2_000_000_000},--Food
		["x1.5GourmetFood"] = {Unlocked = false,Price = 500_000},--GourmetFood
		["x3GourmetFood"] = {Unlocked = false,Price = 2_500_000},--GourmetFood
		["x5Cash"] = {Unlocked = false,Price = 1_000_000_000},--Cash
		["GourmetFoodBoostedByPlayTime"] = {Unlocked = false,Price = 750_000_000},--GourmetFood
		["GourmetFoodMultipliedByLevel"] = {Unlocked = false,Price = 1_500_000_000},--Cash
		["10FoodPerGourmetFood"] = {Unlocked = false,Price = 2_000_000},--Gourmet Food
		["5FoodPerGourmetFood"] = {Unlocked = false,Price = 250_000_000},--Gourmet Food
		["5GourmetFoodPerSale"] = {Unlocked = false,Price = 100_000_000},--Cash
		["2GourmetFoodPerSale"] = {Unlocked = false,Price = 500_000_000},--Cash
	},
	--Inventory = {
	--},
}

local DataDebounce = {}
local Connections = {}
local function StateChanged(state, dataStore, Plr)
	local function LoadInfo(Char)
		if not Char:FindFirstChild("CharacterInfo") then
			
			print(Plr.Name .. " Inside CharacterInfo if-Statement")
			
			local PlayerStats = Plr:WaitForChild("PlayerStats")
			local HRP = Char:WaitForChild("HumanoidRootPart")
			local Humanoid = Char:WaitForChild("Humanoid")
			
			local CharacterInfo = Instance.new("Folder")
			CharacterInfo.Parent = Char
			CharacterInfo.Name = "CharacterInfo"
			
			local MyPlringredients = Instance.new("Folder")
			MyPlringredients.Parent = workspace.PlayerIngredients
			MyPlringredients.Name = Plr.UserId
			
			local PlrFoodBoxes = Instance.new("Folder")
			PlrFoodBoxes.Parent = workspace.PlayerFoodBoxes
			PlrFoodBoxes.Name = Plr.UserId
			
			local ToolFolder = Instance.new("Folder")
			ToolFolder.Parent = Char
			ToolFolder.Name = "ToolFolder"
			
			local CharDebris = Instance.new("Folder")
			CharDebris.Parent = Char
			CharDebris.Name = "CharDebris"
			
			Char:SetAttribute("CookingSpotOccupying","None")
			Char:SetAttribute("UsingCooker",false)
			Char:SetAttribute("InCollectionZone",false)
			Char:SetAttribute("UsingAutoCollecter",false)
			Char:SetAttribute("FoodInCurrentBox",0)
			Char:SetAttribute("ClaimedPeriodicGift",false)

			for i,v in pairs(Char:GetDescendants()) do
				if v:IsA("BasePart") then
					v.CollisionGroup = "Players"
				end
			end			
			Char.Parent = workspace.Characters
			print("Character LOADED!!")	
		end
		if not Plr:FindFirstChild("PlayerInfo") then
			--PLAYERINFO-->>
			----->>>
			local PlayerInfo = Instance.new("Folder")
			PlayerInfo.Parent = Plr
			PlayerInfo.Name = "PlayerInfo"
			
			local LuckValue = Instance.new("NumberValue")
			LuckValue.Parent = PlayerInfo
			LuckValue.Name = "Luck"
			LuckValue.Value = 1
			
			local IngredientMultiplierEventValue = Instance.new("NumberValue")
			IngredientMultiplierEventValue.Parent = PlayerInfo
			IngredientMultiplierEventValue.Name = "IngredientMultiplierEventValue"
			IngredientMultiplierEventValue.Value = 1
			
			local RebirthMultiplierEventValue = Instance.new("NumberValue")
			RebirthMultiplierEventValue.Parent = PlayerInfo
			RebirthMultiplierEventValue.Name = "RebirthMultiplierEventValue"
			RebirthMultiplierEventValue.Value = 1
			
			local FoodMultiplierEventValue = Instance.new("NumberValue")
			FoodMultiplierEventValue.Parent = PlayerInfo
			FoodMultiplierEventValue.Name = "FoodMultiplierEventValue"
			FoodMultiplierEventValue.Value = 1
			
			local CashMultiplierEventValue = Instance.new("NumberValue")
			CashMultiplierEventValue.Parent = PlayerInfo
			CashMultiplierEventValue.Name = "CashMultiplierEventValue"
			CashMultiplierEventValue.Value = 1
			
			local GourmetFoodMultiplierEventValue = Instance.new("NumberValue")
			GourmetFoodMultiplierEventValue.Parent = PlayerInfo
			GourmetFoodMultiplierEventValue.Name = "GourmetFoodMultiplierEventValue"
			GourmetFoodMultiplierEventValue.Value = 1
			
			local Playtime = Instance.new("NumberValue")
			Playtime.Parent = PlayerInfo
			Playtime.Name = "Playtime"
			Playtime.Value = 1
			
			local Spot = Instance.new("StringValue")
			Spot.Parent = PlayerInfo
			Spot.Name = "PlayerSpot"
			Spot.Value = "None"
			
			local MarketSpot = Instance.new("StringValue")
			MarketSpot.Parent = PlayerInfo
			MarketSpot.Name = "MarketSpot"
			MarketSpot.Value = "None"
		
			--SET PLAYER'S PLOT
				for i = 1,8 do
					local Plot = workspace.Plots:FindFirstChild("Plot"..i)
					if Plot:IsA("Folder") then
						if Plot.Info.Occupant.Value ~= "None" then
							continue
						end
						Plot.Info.Occupant.Value = Plr.Name 
						local PlotNumber = string.gsub(Plot.Name,"%D","")
						Plr.RespawnLocation = Plot.Info.SpawnPosition
						local PlayerNameSign = Plot.Base.PlayerNamePost.Sign.SurfaceGui.TextLabel
						PlayerNameSign.Text = Plr.Name.."'s Restaurant"
						Spot.Value = Plot.Name
						break
					end
				end	
			
			local PlayerStats = Plr:WaitForChild("PlayerStats")
			local FarmersMarketSkillTree = PlayerStats.FarmersMarketSkillTree
			local RestaurantSkillTree = PlayerStats.RestaurantSkillTree

			local function SetupFarmersMarketSpot()
				if dataStore.Value.FarmersMarketSkillTree.UnlockFarmersMarket.Unlocked == true then
					local ChosenFarmersPlot = nil
					if MarketSpot.Value == "None" then
						for i,v in pairs(CashCollectionFolder.FarmerPlots:GetDescendants()) do
							if v:IsA("StringValue") and string.find(v.Parent.Name,"FarmersPlot") then
								if v.Value == "None" or v.Value == "Vacant" then
									v.Value = Plr.Name
									ChosenFarmersPlot = v.Parent
									MarketSpot.Value = ChosenFarmersPlot.Name 
									ChosenFarmersPlot.Name = Plr.Name..ChosenFarmersPlot.Name 
									print("Chosen Plot: "..ChosenFarmersPlot.Name)
									break
								end
							end
						end
					end	
					Plr.PlayerGui.HUD.NavigationButtons.Market.Visible = true
					if ChosenFarmersPlot then
						local PlayerHeadshot,IsReady = Players:GetUserThumbnailAsync(Plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
						ChosenFarmersPlot.SellerDisplay.NameDisplay.Frame.PlayerIcon.Image = PlayerHeadshot
						ChosenFarmersPlot.SellerDisplay.NameDisplay.Frame.PlayerName.Text = Plr.Name
						ChosenFarmersPlot.SellerDisplay.NameDisplay.Frame.PlayerName.TextColor3 = Color3.new(1, 1, 1)
						ChosenFarmersPlot.SellerDisplay.NameDisplay.Frame.Level.Text = "Level "..dataStore.Value.Level
						ChosenFarmersPlot.SellerDisplay.NameDisplay.Frame.Level.Visible = true
						
						for i,v in pairs(ChosenFarmersPlot.OccupiedFolder:GetDescendants()) do
							if v:IsA("BasePart") then
								if v.Parent.Name == "FoodSpots" or v.Name == "PromptPart" or v.Parent.Name == "Food" or v.Parent.Parent.Name == "Food" then
									print(v.Parent.Name)
									continue
								end
								v.Transparency = 0
								v.CanCollide = true
								v.CanQuery = true
								v.CanTouch = true
							end	
							if v:IsA("ProximityPrompt") then
								v.Enabled = true
							end	
							if v:IsA("BillboardGui") and v.Name == "StorageBoxDisplay" then
								v.Enabled = true
							end
						end
						
						if dataStore.Value.StoredMarketFood then
							for i = 1,math.clamp(dataStore.Value.StoredMarketFood,0,11) do
								local FoodSpot = ChosenFarmersPlot.OccupiedFolder.Counter.FoodSpots:FindFirstChild("Spot"..i)
								if FoodSpot:FindFirstChildWhichIsA("Model") then
									continue
								end
								local FoodFolder = FarmersMarketFoodStorage:FindFirstChild(ChosenFarmersPlot:GetAttribute("ProductForSale"))
								local RN = math.random(1,#FoodFolder:GetChildren())
								local ChosenFood:Model = FoodFolder:GetChildren()[RN]:Clone()
								ChosenFood.Parent = FoodSpot
								ChosenFood:PivotTo(FoodSpot.CFrame)
							end
						end	
					end	
					
				elseif dataStore.Value.FarmersMarketSkillTree.UnlockFarmersMarket.Unlocked == false then
					Plr.PlayerGui.HUD.NavigationButtons.Market.Visible = false
				end	
			end
			SetupFarmersMarketSpot()
			FarmersMarketSkillTree.UnlockFarmersMarket:GetPropertyChangedSignal("Value"):Connect(SetupFarmersMarketSpot)

			-- [[ FIX 2: Safely check if the plot exists before indexing the StorageBox! ]]
			if dataStore.Value.FarmersMarketSkillTree.UnlockFarmersMarket.Unlocked == true then
				local PlrFarmersPlot = CashCollectionFolder.FarmerPlots:FindFirstChild(Plr.Name..MarketSpot.Value)
				if PlrFarmersPlot then
					local StorageBox = PlrFarmersPlot.OccupiedFolder.StorageBox
					local StorageBoxDisplay = StorageBox.PromptPart.StorageBoxDisplay
					StorageBoxDisplay.Icon.Increment.Text = FrmtNum(PlayerStats.StoredMarketFood.Value,2)
				end
			end

			if dataStore.Value.RestaurantSkillTree.UnlockRestaurant.Unlocked == true then
				local PlayerPlot = workspace.Plots:FindFirstChild(PlayerInfo.PlayerSpot.Value)
				if PlayerPlot then
					local StorageBox = PlayerPlot.RestaurantBuild.Kitchen.StorageBox
					local StorageBoxDisplay = StorageBox.StorageBoxRoot.StorageBoxDisplay
					StorageBoxDisplay.Icon.Increment.Text = FrmtNum(PlayerStats.StoredRestaurantFood.Value,2)
				end
			end

			PlayerStats.StoredMarketFood:GetPropertyChangedSignal("Value"):Connect(function()
				if dataStore.Value.FarmersMarketSkillTree.UnlockFarmersMarket.Unlocked == true then
					local PlrFarmersPlot = CashCollectionFolder.FarmerPlots:FindFirstChild(Plr.Name..MarketSpot.Value)
					if PlrFarmersPlot then
						local StorageBox = PlrFarmersPlot.OccupiedFolder.StorageBox
						local StorageBoxDisplay = StorageBox.PromptPart.StorageBoxDisplay
						StorageBoxDisplay.Icon.Increment.Text = FrmtNum(PlayerStats.StoredMarketFood.Value,2)
					end
				end
			end)

			PlayerStats.StoredRestaurantFood:GetPropertyChangedSignal("Value"):Connect(function()
				if dataStore.Value.RestaurantSkillTree.UnlockRestaurant.Unlocked == true then
					local PlayerPlot = workspace.Plots:FindFirstChild(PlayerInfo.PlayerSpot.Value)
					if PlayerPlot then
						local StorageBox = PlayerPlot.RestaurantBuild.Kitchen.StorageBox
						local StorageBoxDisplay = StorageBox.StorageBoxRoot.StorageBoxDisplay
						StorageBoxDisplay.Icon.Increment.Text = FrmtNum(PlayerStats.StoredRestaurantFood.Value,2)
					end
				end
			end)
		end
		task.defer(function()
			local PlayerInfo = Plr:FindFirstChild("PlayerInfo")
			if PlayerInfo and PlayerInfo:FindFirstChild("PlayerSpot") and PlayerInfo.PlayerSpot.Value ~= "None" then
				local Plot = workspace.Plots:FindFirstChild(PlayerInfo.PlayerSpot.Value)

				if Plot and Plot:FindFirstChild("Info") and Plot.Info:FindFirstChild("SpawnPosition") then
					-- Add +3 to the Y axis so the player drops cleanly onto the pad
					local targetCFrame = Plot.Info.SpawnPosition.CFrame + Vector3.new(0, 3, 0)
					Char:PivotTo(targetCFrame)
					print(Plr.Name .. " successfully teleported to " .. Plot.Name)
				end
			end
		end)	
	end
	
	while dataStore.State == false and Plr do -- Keep trying to re-open if the state is closed
		if dataStore:Open(ValuesToSave) ~= "Success" then print("Trying To Open datastore"); task.wait(4) end
		print('Datastore Opened')		
		
		-- [[ OFFLINE EARNINGS CALCULATION ]]
		if dataStore.Value.TimePlrLeft > 0 then
			-- Calculate seconds away (Cap at 24 hours / 86400 seconds)
			local TimeAway = os.time() - dataStore.Value.TimePlrLeft
			if TimeAway > 86400 then TimeAway = 86400 end

			print("--- OFFLINE EARNINGS FOR " .. Plr.Name .. " ---")
			print("Time Away: " .. TimeAway .. " seconds (" .. math.floor(TimeAway/60) .. " minutes)")

			if TimeAway > 60 then -- Only calculate if they were gone for at least 1 minute
				local upgrades = dataStore.Value.Upgrades

				-- [[ EFFICIENCY NERF ]]
				-- 0.5 means they earn 50% of what they would normally earn while playing perfectly.
				-- Change this to 1 if you want them to earn 100%, or 0.25 for 25%.
				local OfflineEfficiency = 0.4 

				-- 1. INGREDIENTS (Needs Shopper)
				if dataStore.Value.HiredWorkers.Shopper.Unlocked then
					local ingRate = (upgrades.IngredientsPerCollect * upgrades.MultiplyIngredientsPerCollect) / upgrades.IngredientsSpawnSpeed
					local earnedIng = math.floor(TimeAway * ingRate * OfflineEfficiency)

					dataStore.Value.OfflineEarnings.IngredientsOffline += earnedIng
					print("Earned Ingredients: +" .. earnedIng .. " (Rate: " .. math.floor(ingRate) .. "/sec)")
				end

				-- 2. CASH (Needs Seller)
				if dataStore.Value.HiredWorkers.Seller.Unlocked then
					local cashRate = (upgrades.CashPerFood * upgrades.MultiplyCashPerFood) / upgrades.SaleSpeed
					local earnedCash = math.floor(TimeAway * cashRate * OfflineEfficiency)

					dataStore.Value.OfflineEarnings.CashOffline += earnedCash
					print("Earned Cash: +" .. earnedCash .. " (Rate: " .. math.floor(cashRate) .. "/sec)")
				end

				-- 3. GOURMET FOOD (Needs Chef)
				if dataStore.Value.RestaurantUnlocks.ChefUnlocked then
					local gfRate = (upgrades.GourmetFoodPerFood * upgrades.MultiplyGourmetFoodPerFood) / upgrades.GourmetCookingSpeed
					local earnedGf = math.floor(TimeAway * gfRate * OfflineEfficiency)

					dataStore.Value.OfflineEarnings["Gourmet FoodOffline"] += earnedGf
					print("Earned Gourmet Food: +" .. earnedGf .. " (Rate: " .. math.floor(gfRate) .. "/sec)")
				end
			else
				print("Player was away for less than 60 seconds. No earnings awarded.")
			end
			print("-----------------------------------")
		end
		-- Reset time so they don't double dip!
		dataStore.Value.TimePlrLeft = 0
		-- [[ END OFFLINE EARNINGS ]]
		
		for i,v in LeaderStatsKeys do
			dataStore.LeaderStats[v].Value = dataStore.Value[v]
		end	
		for i,v in LeaderStatsValuesKeys do
			dataStore.LeaderStatValues[v].Value = dataStore.Value[v]
		end
		for i,v in PlayerStatsKeys do
			dataStore.playerstats[v].Value = dataStore.Value[v]
		end	
		for i,v in UpgradesKeys do
			dataStore.upgrades[v].Value = dataStore.Value.Upgrades[v]
		end	
		for i,v in FarmersMarketSkillKeys do
			dataStore.farmersmarketskilltree[v].Value = dataStore.Value.FarmersMarketSkillTree[v].Unlocked
			dataStore.farmersmarketskilltree[v]:SetAttribute("Price",dataStore.Value.FarmersMarketSkillTree[v].Price)
		end	
		for i,v in RestaurantSkillKeys do
			dataStore.restaurantskilltree[v].Value = dataStore.Value.RestaurantSkillTree[v].Unlocked
			dataStore.restaurantskilltree[v]:SetAttribute("Price",dataStore.Value.RestaurantSkillTree[v].Price)
		end	
		for i,v in MilestoneKeys do
			dataStore.milestones[v].Value = dataStore.Value.Milestones[v].Unlocked
			dataStore.milestones[v]:SetAttribute("Equipped",dataStore.Value.Milestones[v].Equipped)
		end	
		for i,v in RestaurantUnlocksKeys do
			dataStore.restaurantunlocks[v].Value = dataStore.Value.RestaurantUnlocks[v]
		end	
		for i,v in OfflineEarningsKeys do
			dataStore.offlineearnings[v].Value = dataStore.Value.OfflineEarnings[v]
		end	
		for i, v in HiredWorkersKeys do
			local savedTable = dataStore.Value.HiredWorkers[v]
			if savedTable then
				dataStore.hiredworkers[v].Value = savedTable.Unlocked
				dataStore.hiredworkers[v]:SetAttribute("Active",savedTable.Active)
			end
		end
		for i, v in RestaurantCustomizationKeys do
			local savedTable = dataStore.Value.RestaurantCustomization[v]
			if savedTable then
				-- Convert the {R, G, B} table back into a Color3 for the ValueObject
				dataStore.restaurantcustomization[v].Value = Color3.new(savedTable[1], savedTable[2], savedTable[3])
			end
		end
		for i, v in ExtendedTutorialKeys do
			local savedTable = dataStore.Value.ExtendedTutorial[v]
			if savedTable then
				dataStore.extendedtutorial[v].Value = savedTable.Complete
				dataStore.extendedtutorial[v]:SetAttribute("SubStepComplete",savedTable.SubStepComplete)
			end
		end
		task.spawn(function()
			if dataStore.Value.FirstGame == true then
				print("Players First Game!")

				-- 1. Award 'K' (Last letter, appears furthest right)
				if BadgeService:UserHasBadgeAsync(Plr.UserId, 3810125976319382) == false then
					BadgeService:AwardBadgeAsync(Plr.UserId, 3810125976319382)
					task.wait(0.25) -- Small wait ensures Roblox registers the timestamp order correctly
				end

				-- 2. Award 'O' (Second 'O')
				if BadgeService:UserHasBadgeAsync(Plr.UserId, 2411734504999605) == false then
					BadgeService:AwardBadgeAsync(Plr.UserId, 2411734504999605)
					task.wait(0.25)
				end

				-- 3. Award 'O' (First 'O')
				if BadgeService:UserHasBadgeAsync(Plr.UserId, 3426114361396724) == false then
					BadgeService:AwardBadgeAsync(Plr.UserId, 3426114361396724)
					task.wait(0.25)
				end

				-- 4. Award 'C' (First letter, appears furthest left)
				if BadgeService:UserHasBadgeAsync(Plr.UserId, 1555512502015647) == false then
					BadgeService:AwardBadgeAsync(Plr.UserId, 1555512502015647)
				end
			end	
		end)
		
				
	end
	--CHARACTER LOADING
	if Plr and dataStore.State == true and not DataDebounce[Plr] then
		DataDebounce[Plr] = true
		task.wait(0.5)
		print("CHARACTER IS LOADED")
		repeat task.wait(0.5) until Plr.Character
		local Char = Plr.Character 
		LoadInfo(Char)
		task.wait(0.05)
		print(dataStore.Value)
		DataDebounce[Plr] = nil
	end
end

local function CharacterAdded(char)
	print("Character Added MAINDATA!")
	local Player = Players:GetPlayerFromCharacter(char)
	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
	--print(DataStore.Value)
	StateChanged(DataStore.State, DataStore,Player)
end

local function PlayerAdded(Player)
	local DataStore = DataStoreModule.new(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)	----->>>
	--PLAYERSTATS-->>
	----->>>
	--PLAYERSTATS ALL SAVE
	local PlayerStats = Instance.new("Folder")
	PlayerStats.Parent = Player
	PlayerStats.Name = "PlayerStats"
	DataStore.playerstats = PlayerStats
	
	local TutorialComplete = Instance.new("BoolValue")
	TutorialComplete.Parent = PlayerStats
	TutorialComplete.Name = "TutorialComplete"
	TutorialComplete.Value = false
	
	local FirstGame = Instance.new("BoolValue")
	FirstGame.Parent = PlayerStats
	FirstGame.Name = "FirstGame"
	FirstGame.Value = false
	
	local EquippedTool = Instance.new("StringValue")
	EquippedTool.Parent = PlayerStats
	EquippedTool.Name = "EquippedTool"
	EquippedTool.Value = ""
	
	local MaxExperience = Instance.new("NumberValue")
	MaxExperience.Parent = PlayerStats
	MaxExperience.Name = "MaxExperience"
	
	local Experience = Instance.new("NumberValue")
	Experience.Parent = PlayerStats
	Experience.Name = "Experience"
	
	local GourmetFood = Instance.new("NumberValue")
	GourmetFood.Parent = PlayerStats
	GourmetFood.Name = "Gourmet Food"
	
	local Ingredients = Instance.new("NumberValue")
	Ingredients.Parent = PlayerStats
	Ingredients.Name = "Ingredients"
	
	local Rebirths = Instance.new("NumberValue")
	Rebirths.Parent = PlayerStats
	Rebirths.Name = "Rebirths"
	
	local Mastery = Instance.new("NumberValue")
	Mastery.Parent = PlayerStats
	Mastery.Name = "Mastery"
	
	local StoredMarketFood = Instance.new("NumberValue")
	StoredMarketFood.Parent = PlayerStats
	StoredMarketFood.Name = "StoredMarketFood"
	
	local StoredRestaurantFood = Instance.new("NumberValue")
	StoredRestaurantFood.Parent = PlayerStats
	StoredRestaurantFood.Name = "StoredRestaurantFood"
	
	local CurrentFoodBoxes = Instance.new("NumberValue")
	CurrentFoodBoxes.Parent = PlayerStats
	CurrentFoodBoxes.Name = "CurrentFoodBoxes"
	
	local FoodBoxesValue = Instance.new("NumberValue")
	FoodBoxesValue.Parent = PlayerStats
	FoodBoxesValue.Name = "FoodBoxesValue"
	
	
	local OfflineEarnings = Instance.new("Folder")
	OfflineEarnings.Parent = PlayerStats
	OfflineEarnings.Name = "OfflineEarnings"
	DataStore.offlineearnings = OfflineEarnings

	for i,v in pairs(ValuesToSave.OfflineEarnings) do
		local Value = Instance.new("NumberValue")
		Value.Parent = OfflineEarnings
		Value.Value = v
		Value.Name = i
	end

	local HiredWorkers = Instance.new("Folder")
	HiredWorkers.Parent = PlayerStats
	HiredWorkers.Name = "HiredWorkers"
	DataStore.hiredworkers = HiredWorkers

	for i,v in pairs(ValuesToSave.HiredWorkers) do
		local Value = Instance.new("BoolValue")
		Value.Parent = HiredWorkers
		Value.Value = v.Unlocked
		Value.Name = i
		Value:SetAttribute("Active",v.Active)

		Value:GetPropertyChangedSignal("Value"):Connect(function()
			DataStore.Value.HiredWorkers[Value.Name].Unlocked = Value.Value
		end)
	end
	
	local ExtendedTutorial = Instance.new("Folder")
	ExtendedTutorial.Parent = PlayerStats
	ExtendedTutorial.Name = "ExtendedTutorial"
	DataStore.extendedtutorial = ExtendedTutorial

	for i,v in pairs(ValuesToSave.ExtendedTutorial) do
		local Value = Instance.new("BoolValue")
		Value.Parent = ExtendedTutorial
		Value.Value = v.Complete
		Value.Name = i
		Value:SetAttribute("SubStepComplete",v.SubStepComplete)

		Value:GetPropertyChangedSignal("Value"):Connect(function()
			DataStore.Value.ExtendedTutorial[Value.Name].Complete = Value.Value
		end)
	end
	
	local RestaurantUnlocks = Instance.new("Folder")
	RestaurantUnlocks.Parent = PlayerStats
	RestaurantUnlocks.Name = "RestaurantUnlocks"
	DataStore.restaurantunlocks = RestaurantUnlocks
	
	for i,v in pairs(ValuesToSave.RestaurantUnlocks) do
		local Value = Instance.new("BoolValue")
		Value.Parent = RestaurantUnlocks
		Value.Value = v
		Value.Name = i

		Value:GetPropertyChangedSignal("Value"):Connect(function()
			DataStore.Value.RestaurantUnlocks[Value.Name] = Value.Value
		end)
	end
	
	local RestaurantCustomization = Instance.new("Folder")
	RestaurantCustomization.Parent = PlayerStats
	RestaurantCustomization.Name = "RestaurantCustomization"
	DataStore.restaurantcustomization = RestaurantCustomization

	for i,v in pairs(ValuesToSave.RestaurantCustomization) do
		local Value = Instance.new("Color3Value")
		Value.Parent = RestaurantCustomization
		-- Use Color3.new to rebuild the color from the 3 numbers in the table
		Value.Value = Color3.new(v[1], v[2], v[3])
		Value.Name = i

		Value:GetPropertyChangedSignal("Value"):Connect(function()
			-- When saving, convert the Color3 back into a simple table of {R, G, B}
			DataStore.Value.RestaurantCustomization[Value.Name] = {Value.Value.R, Value.Value.G, Value.Value.B}
		end)
	end
	
	--Milestones-->>
	---->>
	local Milestones = Instance.new("Folder")
	Milestones.Parent = PlayerStats
	Milestones.Name = "Milestones"
	DataStore.milestones = Milestones

	for i,v in pairs(ValuesToSave.Milestones) do
		local Value = Instance.new("BoolValue")
		Value.Parent = Milestones
		Value.Value = v.Unlocked
		Value.Name = i

		Value:GetPropertyChangedSignal("Value"):Connect(function()
			DataStore.Value.Milestones[Value.Name].Unlocked = Value.Value
		end)
	end
	
	--UPGRADES-->>
	---->>
	local Upgrades = Instance.new("Folder")
	Upgrades.Parent = PlayerStats
	Upgrades.Name = "Upgrades"
	DataStore.upgrades = Upgrades
	
	for i,v in pairs(ValuesToSave.Upgrades) do
		local Value = Instance.new("NumberValue")
		Value.Parent = Upgrades
		Value.Value = v
		Value.Name = i
		
		Value:GetPropertyChangedSignal("Value"):Connect(function()
			DataStore.Value.Upgrades[Value.Name] = Value.Value
		end)
	end
	--SKILL TREES-->>
	----->>
	local FarmersMarketSkillTree = Instance.new("Folder")
	FarmersMarketSkillTree.Parent = PlayerStats
	FarmersMarketSkillTree.Name = "FarmersMarketSkillTree"
	DataStore.farmersmarketskilltree = FarmersMarketSkillTree

	for i,v in pairs(ValuesToSave.FarmersMarketSkillTree) do
		local Value = Instance.new("BoolValue")
		Value.Parent = FarmersMarketSkillTree
		Value.Value = v.Unlocked
		Value.Name = i
		Value:SetAttribute("Price",v.Price)
		if SkillTreeDict.FarmersMarketSkillTree[i].ValueType == "Variable" then
			Value:SetAttribute("CurrentValue",1)
		end
	end
	
	local RestaurantSkillTree = Instance.new("Folder")
	RestaurantSkillTree.Parent = PlayerStats
	RestaurantSkillTree.Name = "RestaurantSkillTree"
	DataStore.restaurantskilltree = RestaurantSkillTree

	for i,v in pairs(ValuesToSave.RestaurantSkillTree) do
		local Value = Instance.new("BoolValue")
		Value.Parent = RestaurantSkillTree
		Value.Value = v.Unlocked
		Value.Name = i
		Value:SetAttribute("Price",v.Price)
		if SkillTreeDict.RestaurantSkillTree[i].ValueType == "Variable" then
			Value:SetAttribute("CurrentValue",1)
		end
	end
	
	--LEADERSTATS-->>
	----->>>
	--LEADERSTATS ALL SAVE
	local leaderstats = Instance.new("Folder")
	leaderstats.Parent = Player
	leaderstats.Name = "leaderstats"
	DataStore.LeaderStats = leaderstats

	local Level = Instance.new("StringValue")
	Level.Parent = leaderstats
	Level.Name = "⬆Level"
	
	local Food = Instance.new("StringValue")
	Food.Parent = leaderstats
	Food.Name = "🍲Food"
	
	local Cash = Instance.new("StringValue")
	Cash.Parent = leaderstats
	Cash.Name = "💰Cash"
	
	
	local LeaderstatVals = Instance.new("Folder")
	LeaderstatVals.Parent = Player
	LeaderstatVals.Name = "leaderstatValues"
	DataStore.LeaderStatValues = LeaderstatVals
	
	local LevelValue = Instance.new("NumberValue")
	LevelValue.Parent = LeaderstatVals
	LevelValue.Name = "Level"
	
	local FoodValue = Instance.new("NumberValue")
	FoodValue.Parent = LeaderstatVals
	FoodValue.Name = "Food"
	
	local CashValue = Instance.new("NumberValue")
	CashValue.Parent = LeaderstatVals
	CashValue.Name = "Cash"
	
	Connections[Player] = {}
	
	Connections[Player].LevelConnection = LevelValue:GetPropertyChangedSignal("Value"):Connect(function()
		local Val = LevelValue.Value
		DataStore.Value["Level"] = Val 
		DataStore.Value["⬆Level"] = DataStore.Value["Level"] 
		DataStore.Value["⬆Level"] = FrmtNum(DataStore.Value["⬆Level"] ,2)
		DataStore.LeaderStats["⬆Level"].Value = DataStore.Value["⬆Level"]

		LevelValue.Value = Val
	end)
	
	Connections[Player].FoodConnection = FoodValue:GetPropertyChangedSignal("Value"):Connect(function()
		local Val = FoodValue.Value
		DataStore.Value["Food"] = Val 
		DataStore.Value["🍲Food"] = DataStore.Value["Food"] 
		DataStore.Value["🍲Food"] = FrmtNum(DataStore.Value["🍲Food"] ,2)
		DataStore.LeaderStats["🍲Food"].Value = DataStore.Value["🍲Food"]

		FoodValue.Value = Val
	end)
	
	Connections[Player].CashConnection = CashValue:GetPropertyChangedSignal("Value"):Connect(function()
		local Val = CashValue.Value
		DataStore.Value["Cash"] = Val 
		DataStore.Value["💰Cash"] = DataStore.Value["Cash"] 
		DataStore.Value["💰Cash"] = "$"..FrmtNum(DataStore.Value["💰Cash"] ,2)
		DataStore.LeaderStats["💰Cash"].Value = DataStore.Value["💰Cash"]
		
		CashValue.Value = Val
	end)
	
	Connections[Player].IngredientsConnection = Ingredients:GetPropertyChangedSignal("Value"):Connect(function()
		DataStore.Value["Ingredients"] = Ingredients.Value
	end)

	Connections[Player].RebirthsConnection = Rebirths:GetPropertyChangedSignal("Value"):Connect(function()
		DataStore.Value["Rebirths"] = Rebirths.Value
	end)

	Connections[Player].GourmetFoodConnection = GourmetFood:GetPropertyChangedSignal("Value"):Connect(function()
		DataStore.Value["Gourmet Food"] = GourmetFood.Value
	end)
	
	
	print("Leaderstats LOADED!!")			
	---
	--DATASTORE STATE CHANGED--
	---
	DataStore.StateChanged:Connect(StateChanged)
	StateChanged(DataStore.State, DataStore,Player)
	
	--Connect the event
	Player.CharacterAdded:Connect(CharacterAdded)

	--Take care of when it already exists
	local char = Player.Character
	if char then
		CharacterAdded(char)
	end
end

local ADMIN_NAMES = {
	"kaosgamess7",
	"kaosgamess9", 
	"kaosworker223"
}

local function IsAdmin(player)
	for _, name in ADMIN_NAMES do
		if player.Name == name then return true end
	end
	return false
end
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if not IsAdmin(player) then return end

		local args = message:lower():split(" ")
		
		if args[1] ~= "/resetdata" then return end

		local targetName = args[2]
		if not targetName then
			warn("[RESET] Uso: /resetdata [nome do jogador]")
			return
		end

		local targetPlayer = Players:FindFirstChild(targetName) 
			or (function()
				for _, p in Players:GetPlayers() do
					if p.Name:lower():find(targetName) then return p end
				end
			end)()

		if not targetPlayer then
			warn("[RESET] Jogador '" .. targetName .. "' não encontrado online.")
			return
		end

		local dataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, targetPlayer.UserId)
		if not dataStore then
			warn("[RESET] DataStore de " .. targetPlayer.Name .. " não encontrado.")
			return
		end

		-- Reseta todos os valores para o padrão
		for k, v in pairs(ValuesToSave) do
			dataStore.Value[k] = v
		end

		dataStore:Save()
		print("[RESET] ✅ Dados de " .. targetPlayer.Name .. " resetados com sucesso!")
	end)
end)

--Connect the event
game.Players.PlayerAdded:Connect(PlayerAdded)

--Take care of when it already exists
for i,v in pairs(game.Players:GetPlayers()) do
	PlayerAdded(v)
end


game.Players.PlayerRemoving:Connect(function(player)
	local dataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, player.UserId)
	--dataStore.Value.Upgrades = ValuesToSave.Upgrades
	--dataStore.Value.FarmersMarketSkillTree = ValuesToSave.FarmersMarketSkillTree
	--dataStore.Value = nil
	--dataStore:Reconcile(ValuesToSave)
	--dataStore.Value.ActivePorts = 0
	if dataStore then
		dataStore.Value.TimePlrLeft = os.time()
	end
	print(Connections)
	print(Connections[player])
	
	if Connections[player] then
		for _,Connection in Connections[player] do
			Connection:Disconnect()
		end
		Connections[player] = nil
	end
	print(Connections)
	print(dataStore.Value)
	if dataStore ~= nil then dataStore:Destroy() end -- If the player leaves datastore object is destroyed allowing the retry loop to stop
end)

LoadRemote.OnServerEvent:Connect(function(Plr,Action)
	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Plr.UserId)

	if Action == "ClosedLoadScreen" and Plr then
		if DataStore.Value.FirstGame == true then
			if DataStore.Value.TutorialComplete == false then
				print("Sent To Client To Start Tutorial!")
				TutorialRemote:FireClient(Plr,"StartTutorial")
			end
		end
	end
end)

TutorialRemote.OnServerEvent:Connect(function(Plr,Action)
	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Plr.UserId)

	if Action == "TutorialComplete" and Plr then
		if DataStore.Value.FirstGame == true then
			if DataStore.Value.TutorialComplete == false then
				print("Tutorial Now Officially Complete!")
				DataStore.Value.TutorialComplete = true
				DataStore.playerstats.TutorialComplete.Value = true

				DataStore.Value.FirstGame = false
				DataStore.playerstats.FirstGame.Value = false
				if BadgeService:UserHasBadgeAsync(Plr.UserId,2156879421600225) == false then
					BadgeService:AwardBadgeAsync(Plr.UserId,2156879421600225)
				end
			end
		end
	end
end)