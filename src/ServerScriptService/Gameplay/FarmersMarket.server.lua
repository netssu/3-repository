local SS = game:GetService("ServerStorage")
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local CS = game:GetService("CollectionService")
local HTTPs = game:GetService("HttpService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")

--MODULES
local DataStoreModule = require(SS:WaitForChild("Modules").MainDataModule)
local BezierModule = require(RS:WaitForChild("Modules").BezierModule)
local PathfinderModule = require(RS:WaitForChild("Modules").NoobPath)
local NPCHandler = require(SS:WaitForChild("Modules").MarketCustomerHandler)
local NotifModule = require(RS:WaitForChild("Modules").NotifModule)

local FarmersMarketRem = RS:WaitForChild("Remotes").FarmersMarketRemote

local PlayerIngredients = workspace.PlayerIngredients
local PlayerFoodBoxes = workspace.PlayerFoodBoxes
local IngredientsStorage = SS:WaitForChild("Assets").Ingredients
local IngredientCollection = workspace.Map.CenterPoint.IngredientCollection
local IngredientUpgradeBoards = IngredientCollection:WaitForChild("UpgradeBoards")
local IngredientsDetectionZone = IngredientCollection:WaitForChild("DetectionZone")
local IngredientsCollectionZone = IngredientCollection:WaitForChild("CollectionZone")

local CashCollectionFolder = workspace.Map.CenterPoint.CashCollection

local FoodStorage = SS:WaitForChild("Assets").Foods
local FarmersMarketFoodStorage = SS:WaitForChild("Assets").FarmersMarketFoods

local FoodCollection = workspace.Map.CenterPoint.FoodCollection
local CookingSpots = FoodCollection.CookingPot.CookingSpots
local FoodPerCashCost = 1

local CustomerChances = {
	GoSitdown = 350, -- 35 %
	Leaving = 650, --65 %
}

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

local FarmersMarketInfo = {}

local function RandomFromWeightedTable(OrderedTable)
	local TotalWeight = 0

	for Piece, Weight in pairs(OrderedTable) do
		TotalWeight += Weight
	end

	local Chance = Random.new():NextInteger(1, TotalWeight)

	local Counter = 0

	for Piece, Weight in pairs(OrderedTable) do
		Counter += Weight

		if Chance <= Counter then
			return Piece
		end
	end
end

local ActiveIncrementals = {}

for i,v in pairs(CashCollectionFolder.FarmerPlots:GetDescendants()) do
	if v:IsA("BasePart")  then
		if v.Parent.Name == "OccupiedFolder" or v.Parent.Parent.Name == "OccupiedFolder" then
			v.Transparency = 1
			v.CanCollide = false
			v.CanQuery = false
			v.CanTouch = false
		end
	end	
	if v:IsA("ProximityPrompt") then
		v.Enabled = false
	end	
	if v:IsA("BillboardGui") and v.Name == "NameDisplay" then
		v.Frame.Level.Visible = false
		v.Frame.PlayerName.Text = "Vacant"
		v.Frame.PlayerName.TextColor3 = Color3.new(1, 0, 0)
	end
	if v:IsA("BillboardGui") and v.Name == "StorageBoxDisplay" then
		v.Enabled = false
	end
end

local CustomerCount = 0
for i,SalePrompt in pairs(CS:GetTagged("FarmerButtonPrompt")) do
	if SalePrompt:IsA("ProximityPrompt") then
		SalePrompt.ActionText = "Make a Sale!"
		SalePrompt.ObjectText = "Interact"
		SalePrompt.Triggered:Connect(function(Plr)
			if SalePrompt.Parent.Parent.Parent.Parent.Occupant.Value ~= Plr.Name then
				return
			end
			local Plot = SalePrompt.Parent.Parent.Parent.Parent
			local DebounceTimer:NumberValue = Plot.OccupiedFolder.Button.Debounce
			local CustomerPath = Plot.Parent.CustomerPath
			local CustomersFolder = CashCollectionFolder.FarmerPlots.Customers
			local ButtonPart = SalePrompt.Parent 
			local PlayerStats = Plr.PlayerStats
			local StoredFood = PlayerStats.StoredMarketFood

			local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Plr.UserId)
			if not DataStore then return end

			local Upgrades = DataStore.Value.Upgrades
			local SpeedVal = Upgrades.SaleSpeed 

			-- [[ DEBOUNCE LOGIC ]] --
			local currentTime = os.clock()
			if (currentTime - DebounceTimer.Value) < SpeedVal then
				return
			end
			DebounceTimer.Value = currentTime
			FoodPerCashCost = math.random(20,30)

			if DataStore.Value.StoredMarketFood < FoodPerCashCost then
				print("You dont have Enough food in Storage!")
				FarmersMarketRem:FireClient(Plr,"NotEnoughFood")
				return
			end
			print(Plr.Name.." Attempted to Make a Sale! At Plot "..Plot.Name)

			local PlayerStats = Plr.PlayerStats
			local Experience = PlayerStats.Experience
			local MaxExperience = PlayerStats.MaxExperience

			local CashPerFoodVal = Upgrades.CashPerFood
			local MultiCashPerFood = Upgrades.MultiplyCashPerFood
			local GoldenChanceVal = Upgrades.ChanceOfGoldenSale
			local FarmersMarketSkillTree = PlayerStats.FarmersMarketSkillTree

			-- [[ FIX: STABLE BUTTON ANIMATION ]] --
			-- Store the original position as an attribute the first time it's clicked
			if not ButtonPart:GetAttribute("OriginalPosition") then
				ButtonPart:SetAttribute("OriginalPosition", ButtonPart.Position)
			end

			local originalPos = ButtonPart:GetAttribute("OriginalPosition")
			local pressedPos = originalPos - Vector3.new(0, 0.25, 0)

			-- Cancel any existing tweens to prevent fighting
			if ButtonPart:FindFirstChild("DownTween") then ButtonPart.DownTween:Cancel() end
			if ButtonPart:FindFirstChild("UpTween") then ButtonPart.UpTween:Cancel() end

			-- Create and play the Down tween
			local downTween = TS:Create(ButtonPart, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Color = Color3.new(1, 0, 0), Position = pressedPos})
			downTween.Name = "DownTween"
			downTween.Parent = ButtonPart
			downTween:Play()

			-- Schedule the Up tween
			task.delay(SpeedVal, function()
				-- Only play the up tween if the down tween is finished/exists
				local upTween = TS:Create(ButtonPart, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Color = Color3.new(0, 1, 0), Position = originalPos})
				upTween.Name = "UpTween"
				upTween.Parent = ButtonPart
				upTween:Play()
				Debris:AddItem(upTween, 1) -- clean up the tween instance
			end)

			Debris:AddItem(downTween, SpeedVal + 1) -- clean up the tween instance
			-- [[ END STABLE BUTTON ANIMATION FIX ]] --

			local ButtonClickSFX = RS:WaitForChild("Assets").SFX.FarmersButtonClick:Clone()
			ButtonClickSFX.Parent = ButtonPart
			ButtonClickSFX:Play()
			Debris:AddItem(ButtonClickSFX,0.75)

			local ChosenCustomer:Model = nil

			-- Find an available customer who HAS NOT visited this plot yet
			for i,v in pairs(CustomersFolder:GetChildren()) do
				if v:IsA("Model") and v:FindFirstChildWhichIsA("Humanoid") then
					if v:GetAttribute("TargetPlot") == "None" and v:GetAttribute("State") ~= "Despawning" then
						local custData =  NPCHandler.ActiveCustomers[v]
						local visited = custData and custData.VisitedPlots or {}
						if not table.find(visited, Plot.Name) then
							if v:GetAttribute("State") == "Sitting" then
								continue
							end
							v:SetAttribute("TargetPlot", Plot.Name)
							ChosenCustomer = v
							break
						end
					end
				end
			end

			-- Spawn a new one if none available
			if ChosenCustomer == nil and #CustomersFolder:GetChildren() < 30 then
				local CustomerNPC = RS:WaitForChild("Assets").CustomerRig:Clone()
				CustomerNPC.Parent = CustomersFolder
				CustomerNPC:PivotTo(CustomerPath[tostring(Plot:GetAttribute("ConnectedPath")-2)].CFrame)
				CustomerNPC:SetAttribute("TargetPlot",Plot.Name)
				local Highlight = Instance.new("Highlight")
				Highlight.Parent = CustomerNPC
				Highlight.FillTransparency = 1
				Highlight.OutlineTransparency = 0.5
				Highlight.OutlineColor = Color3.new(1,1,1)
				Highlight.DepthMode = Enum.HighlightDepthMode.Occluded

				ChosenCustomer = CustomerNPC
				ChosenCustomer.Name = "Customer"..CustomerCount
				CustomerCount += 1
				for i,v in pairs(ChosenCustomer:GetDescendants()) do
					if v:IsA("BasePart") then
						if v.Name == "HumanoidRootPart" then continue end
						v.Transparency = 1
					end
					if v:IsA("Decal") then
						v.Transparency = 1
					end
				end	
				task.delay(0.4,function()
					for i,v in pairs(ChosenCustomer:GetDescendants()) do
						if v:IsA("BasePart") then
							if v.Name == "HumanoidRootPart" then continue end
							TS:Create(v,TweenInfo.new(1),{Transparency = 0}):Play()
							v.CollisionGroup = "Customers"
						end
						if v:IsA("Decal") then
							v.Transparency = 0
						end
					end	
				end)	
			end

			if ChosenCustomer == nil then
				print("No Customers Available")
				return
			end

			local CustomerHum:Humanoid = ChosenCustomer:WaitForChild("Humanoid")
			local CustomerHrp = ChosenCustomer:WaitForChild("HumanoidRootPart")
			if CustomerHum == nil or CustomerHrp == nil then return end

			task.spawn(function()
				local success, err = pcall(function()
					local FriendsPages = Players:GetFriendsAsync(Plr.UserId)
					local Friends = {}
					local currentPage = FriendsPages:GetCurrentPage()
					local JolrFriend = {Id = 2460575279}
					while currentPage do
						for _, friend in pairs(currentPage) do
							table.insert(Friends, friend)
						end
						if FriendsPages.IsFinished then break end
						FriendsPages:AdvanceToNextPageAsync()
						currentPage = FriendsPages:GetCurrentPage()
					end
					local ChosenFriend 
					if #Friends <= 0 then
						ChosenFriend = JolrFriend
					else
						local RN = math.random(1,#Friends)
						ChosenFriend = Friends[RN]
					end

					local FriendDescription:HumanoidDescription = Players:GetHumanoidDescriptionFromUserIdAsync(ChosenFriend.Id) 
					FriendDescription.WidthScale = 1
					FriendDescription.DepthScale = 1
					FriendDescription.HeightScale = 1

					CustomerHum:ApplyDescriptionAsync(FriendDescription)

					-- FIX: Wrap SetNetworkOwner in a pcall and CanSet check to prevent crashing!
					pcall(function()
						if CustomerHrp and CustomerHrp:CanSetNetworkOwnership() then
							CustomerHrp:SetNetworkOwner(nil)
						end
					end)

					for i,v in pairs(ChosenCustomer:GetDescendants()) do
						if v:IsA("BasePart") then
							v.CollisionGroup = "Customers"
						end
					end
				end)
			end)

			-- [[ ASSIGN/INTERCEPT CUSTOMER ]] --
			if  NPCHandler.ActiveCustomers[ChosenCustomer] then
				-- They were leaving, intercept them!
				NPCHandler.ActiveCustomers[ChosenCustomer].Plr = Plr
				NPCHandler.ActiveCustomers[ChosenCustomer].TargetPlot = Plot
				NPCHandler.ActiveCustomers[ChosenCustomer].State = "Intercepted"
				table.insert(NPCHandler.ActiveCustomers[ChosenCustomer].VisitedPlots, Plot.Name)
			else
				-- Brand new customer
				local StartPoint = Plot:GetAttribute("ConnectedPath") - 2
				if StartPoint < 1 then StartPoint = 1 end
				NPCHandler.SetupNPC(ChosenCustomer,Plot,StartPoint,Plr)

			end

		end)	
	end
end

for i,StoragePrompt in pairs(CS:GetTagged("StorageBoxPrompt")) do
	if StoragePrompt:IsA("ProximityPrompt") then
		StoragePrompt.ActionText = "Interact"
		StoragePrompt.ObjectText = "Restock!"
		StoragePrompt.Triggered:Connect(function(Plr)
			if StoragePrompt.Parent.Parent.Parent.Parent.Occupant.Value ~= Plr.Name then
				return
			end
			local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Plr.UserId)
			if not DataStore then return end

			local Plot = StoragePrompt.Parent.Parent.Parent.Parent
			local PlayerStats = Plr.PlayerStats
			local StoredFood = PlayerStats.StoredMarketFood

			if DataStore.Value.CurrentFoodBoxes > 0 then
				FarmersMarketRem:FireClient(Plr,"OpenStorageBoxRestockMenu")
			elseif DataStore.Value.CurrentFoodBoxes <= 0 then
				NotifModule.Notify(Plr,"Get Some FoodBoxes From the Big Pot!")
				FarmersMarketRem:FireClient(Plr,"OpenStorageBoxNoFoodBoxesMenu")
			end
		end)
	end
end

FarmersMarketRem.OnServerEvent:Connect(function(Plr,Action,Data)
	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Plr.UserId)
	if not DataStore then return end
	local PlayerStats = Plr.PlayerStats
	local StoredFood = PlayerStats.StoredMarketFood

	if Action == "RestockStorageBox" and Plr and Data.InFarmersMarket == true then
		if DataStore.Value.CurrentFoodBoxes > 0 and DataStore.Value.FoodBoxesValue > 0 then
			local TotalAdded = DataStore.Value.FoodBoxesValue
			local Remainder = 0
			if Data.Percent == "100" then
				TotalAdded *= 1
			elseif Data.Percent == "50" then
				TotalAdded *= 0.5
			elseif Data.Percent == "25" then
				TotalAdded *= 0.25
			end
			Remainder = DataStore.Value.FoodBoxesValue - math.ceil(TotalAdded)

			if TotalAdded > DataStore.Value.FoodBoxesValue then
				return
			end

			DataStore.Value.StoredMarketFood += math.ceil(TotalAdded)
			DataStore.playerstats.StoredMarketFood.Value = DataStore.Value.StoredMarketFood

			DataStore.LeaderStatValues.Food.Value += math.ceil(Remainder)

			DataStore.Value.FoodBoxesValue = 0
			DataStore.playerstats.FoodBoxesValue.Value = DataStore.Value.FoodBoxesValue

			DataStore.Value.CurrentFoodBoxes = 0
			DataStore.playerstats.CurrentFoodBoxes.Value = DataStore.Value.CurrentFoodBoxes

			local PlrsFoodBoxFolder = PlayerFoodBoxes:WaitForChild(Plr.UserId):FindFirstChild("FoodBoxes")
			if PlrsFoodBoxFolder then
				PlrsFoodBoxFolder:Destroy()
			end
			FarmersMarketRem:FireClient(Plr,"CloseStorageBoxRestockMenu")
		end
	elseif Action == "GivePlayerFoodFromFoodBoxes" and Plr and Data == true then
		if DataStore.Value.CurrentFoodBoxes > 0 and DataStore.Value.FoodBoxesValue > 0 then
			local TotalAdded = DataStore.Value.FoodBoxesValue

			DataStore.LeaderStatValues.Food.Value += math.ceil(TotalAdded)

			DataStore.Value.FoodBoxesValue = 0
			DataStore.playerstats.FoodBoxesValue.Value = DataStore.Value.FoodBoxesValue

			DataStore.Value.CurrentFoodBoxes = 0
			DataStore.playerstats.CurrentFoodBoxes.Value = DataStore.Value.CurrentFoodBoxes

			local PlrsFoodBoxFolder = PlayerFoodBoxes:WaitForChild(Plr.UserId):FindFirstChild("FoodBoxes")
			if PlrsFoodBoxFolder then
				PlrsFoodBoxFolder:Destroy()
			end
			FarmersMarketRem:FireClient(Plr,"CloseStorageBoxRestockMenu")
		end
	end
end)

-- [[ CUSTOMER PATHFINDING LOGIC ]] --
local function CustomerPathfinding(deltaTime, Customer, CustomerData)
	if not Customer or not Customer.Parent then
		if NPCHandler.ActiveCustomers then NPCHandler.ActiveCustomers[Customer] = nil end
		return
	end

	if Customer:GetAttribute("State") ~= CustomerData.State then
		Customer:SetAttribute("State", CustomerData.State)
	end

	--CUSTOMER INFORMATION
	local humanoid = Customer:FindFirstChild("Humanoid")
	local hrp = Customer:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return end

	local Plot = CustomerData.TargetPlot
	local PathFolder = nil

	if typeof(Plot) == "Instance" and Plot.Parent then
		PathFolder = Plot.Parent:FindFirstChild("CustomerPath")
	end

	local Player = CustomerData.Plr

	-- FIX: Check if player's parent is nil. Checking Player.Character can cause bugs if they reset!
	local isPlayerValid = false
	if Player and Player.Parent ~= nil then
		isPlayerValid = true
	end

	if not isPlayerValid then
		if CustomerData.State ~= "Leaving" and CustomerData.State ~= "FollowingExitPath" and CustomerData.State ~= "Despawning" then
			Customer:SetAttribute("TargetPlot", "None")
			CustomerData.State = "Leaving"
		end
	end

	-- Check if plot became vacant while walking/intercepted
	if CustomerData.State == "Walking" or CustomerData.State == "Intercepted" or CustomerData.State == "FollowingInterceptPath" or CustomerData.State == "Waiting" then
		-- FIX: Added "None" check to ensure it handles the exact clear string
		if not Plot or not Plot:FindFirstChild("Occupant") or Plot.Occupant.Value == "Vacant" or Plot.Occupant.Value == "None" then
			Customer:SetAttribute("TargetPlot", "None")
			CustomerData.State = "Leaving"
		end
	end

	-- [[ STATE MACHINE ]]
	if CustomerData.State == "Walking" then
		if not PathFolder then return end
		local TargetNodePart = PathFolder:FindFirstChild(tostring(CustomerData.CurrentNode))

		if not TargetNodePart then
			CustomerData.State = "Leaving"
			return
		end

		if CustomerData.LastWalkNode ~= CustomerData.CurrentNode then
			CustomerData.LastWalkNode = CustomerData.CurrentNode
			humanoid:MoveTo(TargetNodePart.Position)
		end

		local dist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(TargetNodePart.Position.X, 0, TargetNodePart.Position.Z)).Magnitude

		if dist < 3.5 then
			if tonumber(CustomerData.CurrentNode) == tonumber(Plot:GetAttribute("ConnectedPath")) then
				CustomerData.State = "Waiting"
				CustomerData.WaitTimer = 2.25
			else
				CustomerData.CurrentNode = CustomerData.CurrentNode + 1
			end
		end

	elseif CustomerData.State == "Waiting" then
		if not CustomerData.Stopped then
			CustomerData.Stopped = true
			humanoid:MoveTo(hrp.Position)
		end

		CustomerData.WaitTimer = CustomerData.WaitTimer - deltaTime

		if CustomerData.WaitTimer <= 0 then
			CustomerData.Stopped = false 
			Customer:SetAttribute("TargetPlot", "None")

			local ChosenBehavior = RandomFromWeightedTable(CustomerChances)
			if ChosenBehavior == "GoSitdown" then 
				local Decorations = CashCollectionFolder:WaitForChild("Decorations")
				local PicnicTablesFolder = Decorations and Decorations:WaitForChild("PicnicTables")

				if PicnicTablesFolder then
					CustomerData.ValidSeats = {}
					for i,Seat in pairs(PicnicTablesFolder:GetDescendants()) do
						if Seat:IsA("Seat") and Seat.Occupant == nil then
							table.insert(CustomerData.ValidSeats, Seat)
						end
					end

					if #CustomerData.ValidSeats > 0 then
						local rng = Random.new()
						CustomerData.TargetSeat = CustomerData.ValidSeats[rng:NextInteger(1, #CustomerData.ValidSeats)]
						CustomerData.State = "ComputingPicnic"
						CustomerData.ValidSeats = nil
					else
						CustomerData.State = "Leaving"
					end
				else
					CustomerData.State = "Leaving"
				end
			else
				CustomerData.State = "Leaving"
			end	

			if isPlayerValid then
				local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
				local PlayerStats = Player:FindFirstChild("PlayerStats")
				local LeaderstatValues = Player:FindFirstChild("leaderstatValues")
				local PlayerInfo = Player:FindFirstChild("PlayerInfo")

				if DataStore and DataStore.Value and PlayerStats and LeaderstatValues and PlayerInfo then
					local Upgrades = DataStore.Value.Upgrades
					local FarmersMarketSkillTree = PlayerStats:FindFirstChild("FarmersMarketSkillTree")
					local CashVal = LeaderstatValues:FindFirstChild("Cash")
					local StoredFood = PlayerStats:FindFirstChild("StoredMarketFood")

					local IsGoldenSale = false
					FoodPerCashCost = math.random(20,30)
					if DataStore.Value.StoredMarketFood >= FoodPerCashCost then
						local TotalSkillTreeMultiplier = 1
						local EarnedExp = math.random(1,2)
						local CashPerFood = Upgrades.CashPerFood
						local GoldenChanceVal = Upgrades.ChanceOfGoldenSale
						local MultiCashVal = Upgrades.MultiplyCashPerFood
						local TotalReward = CashPerFood * MultiCashVal

						local ChaChingMoney = RS:WaitForChild("Assets").SFX.ChaChing:Clone()
						ChaChingMoney.Parent = hrp
						ChaChingMoney.Volume = 0.4
						ChaChingMoney:Play()
						Debris:AddItem(ChaChingMoney,0.9)

						if DataStore.Value.FarmersMarketSkillTree["x1.5Cash"].Unlocked == true then
							TotalSkillTreeMultiplier = 1.5
						end
						if DataStore.Value.FarmersMarketSkillTree["x3Cash"].Unlocked == true then
							if TotalSkillTreeMultiplier == 1 then
								TotalSkillTreeMultiplier = 3
							else
								TotalSkillTreeMultiplier += 3
							end
						end
						if DataStore.Value.RestaurantSkillTree["x5Cash"].Unlocked == true then
							if TotalSkillTreeMultiplier == 1 then
								TotalSkillTreeMultiplier = 5
							else
								TotalSkillTreeMultiplier += 5
							end
						end

						if math.random(1, 100) <= GoldenChanceVal then
							TotalReward = (CashPerFood * 3) * MultiCashVal
							EarnedExp = math.random(3,4)
							IsGoldenSale = true
						end
						TotalReward *= TotalSkillTreeMultiplier

						if Player:GetAttribute("x2Cash") == true then
							TotalReward *= 2
						end
						TotalReward *= PlayerInfo.CashMultiplierEventValue.Value

						DataStore.Value.StoredMarketFood -= FoodPerCashCost
						if StoredFood then StoredFood.Value = DataStore.Value.StoredMarketFood end

						if CashVal then CashVal.Value += TotalReward end

						DataStore.Value.Experience += EarnedExp
						if PlayerStats:FindFirstChild("Experience") then 
							PlayerStats.Experience.Value = DataStore.Value.Experience 
						end
						FarmersMarketRem:FireAllClients("MoneySplash",{Customer,IsGoldenSale})

						if Plot.OccupiedFolder.Counter.FoodSpots.Spot6:FindFirstChildWhichIsA("Model") then
							local SpotFood = Plot.OccupiedFolder.Counter.FoodSpots.Spot6:FindFirstChildWhichIsA("Model")
							for i,v in pairs(SpotFood:GetChildren()) do
								if v:IsA("BasePart") then
									v.Material = "Neon"
									v.Color = Color3.fromRGB(255, 255, 255)
								end
							end
							task.spawn(function()
								for i = 1,1.75,0.05 do
									if i >= 1.7 then
										SpotFood:Destroy()
										break
									end
									SpotFood:ScaleTo(i)
									task.wait(deltaTime)
								end
							end)
							Debris:AddItem(SpotFood,3)	
						else
							for i,v in pairs(Plot.OccupiedFolder.Counter.FoodSpots:GetDescendants()) do
								if v:IsA("Model") then
									for i,V in pairs(v:GetChildren()) do
										if V:IsA("BasePart") then
											V.Material = "Neon"
											V.Color = Color3.fromRGB(255, 255, 255)
										end
									end
									task.spawn(function()
										for i = 1,1.75,0.05 do
											if i >= 1.7 then
												v:Destroy()
												break
											end
											v:ScaleTo(i)
											task.wait(deltaTime)
										end	
									end)
									Debris:AddItem(v,3)
									break
								end
							end
						end

						local IncdecCashDisplay = RS:WaitForChild("UIAssets").IncDecCashDisplay:Clone()
						IncdecCashDisplay.Parent = Plot.OccupiedFolder.Counter.CustomerSpawnPos
						IncdecCashDisplay.Icon.Increment.Text = "+"..FrmtNum(TotalReward,2)
						IncdecCashDisplay.StudsOffset = Vector3.new(0,0.5,-1.5)
						TS:Create(IncdecCashDisplay.Icon.Increment,TweenInfo.new(5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{TextTransparency = 0.9}):Play()
						local PosTween = TS:Create(IncdecCashDisplay,TweenInfo.new(2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{Brightness = 5,StudsOffset = Vector3.new(0,6,0)})
						PosTween:Play()
						PosTween.Completed:Once(function()
							if IncdecCashDisplay and IncdecCashDisplay:FindFirstChild("Icon") and IncdecCashDisplay.Icon:FindFirstChild("Increment") then
								TS:Create(IncdecCashDisplay.Icon.Increment,TweenInfo.new(1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{TextTransparency = 1}):Play()
								TS:Create(IncdecCashDisplay.Icon,TweenInfo.new(1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{ImageTransparency = 1}):Play()
							end
						end)
						Debris:AddItem(IncdecCashDisplay,3)
					end

					if IsGoldenSale == true then
						TS:Create(Customer.Highlight,TweenInfo.new(0.65,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,false,0),{OutlineColor = Color3.new(1, 0.917647, 0),FillColor = Color3.new(1, 0.917647, 0),FillTransparency = 0.35}):Play()
						task.delay(0.85,function()
							TS:Create(Customer.Highlight,TweenInfo.new(0.35,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{OutlineColor = Color3.new(1, 1, 1),FillColor = Color3.new(1, 1, 1),FillTransparency = 1}):Play()
						end)
						local LevelUpSpark = RS:WaitForChild("Assets").VFX.BigSpark:Clone()
						LevelUpSpark.Parent = hrp
						LevelUpSpark.Enabled = true
						local LevelUpBlackSpark = RS:WaitForChild("Assets").VFX.BlackSpark:Clone()
						LevelUpBlackSpark.Parent = hrp
						LevelUpBlackSpark.Enabled = true
						Debris:AddItem(LevelUpSpark,1.5)
						Debris:AddItem(LevelUpBlackSpark,1.55)
					end
				end
			end
		end

	elseif CustomerData.State == "ComputingPicnic" then
		if CustomerData.TargetSeat then
			NPCHandler.Go(Customer, CustomerData.TargetSeat.Position)
			CustomerData.State = "FollowingPicnicPath"
		else
			CustomerData.State = "Leaving"
		end

	elseif CustomerData.State == "FollowingPicnicPath" then
		if humanoid.Sit == true then
			CustomerData.State = "Sitting"
			CustomerData.WaitTimer = math.random(25, 30)
			CustomerData.StuckTimer = 0 -- Reset timer
			return
		end

		if CustomerData.TargetSeat and CustomerData.TargetSeat.Occupant ~= nil then
			NPCHandler.Stop(Customer)
			CustomerData.State = "Leaving"
			CustomerData.StuckTimer = 0 -- Reset timer
			return
		end

		local Distance = (hrp.Position - CustomerData.TargetSeat.Position).Magnitude

		-- [[ FIX: Added a Stuck Timer so they don't freeze on tables! ]]
		CustomerData.StuckTimer = (CustomerData.StuckTimer or 0) + deltaTime

		if Distance < 3.5 then
			NPCHandler.Stop(Customer)
			if CustomerData.TargetSeat then
				CustomerData.TargetSeat:Sit(humanoid)
			end
			CustomerData.State = "Sitting"
			CustomerData.WaitTimer = math.random(25, 30)
			CustomerData.StuckTimer = 0 -- Reset timer

		elseif CustomerData.StuckTimer > 15 then
			-- If they are stuck for 15 seconds trying to sit, give up and leave
			NPCHandler.Stop(Customer)
			CustomerData.State = "Leaving"
			CustomerData.StuckTimer = 0
		end

	elseif CustomerData.State == "Sitting" then
		CustomerData.WaitTimer = CustomerData.WaitTimer - deltaTime

		if CustomerData.WaitTimer <= 0 then
			if CustomerData.TargetSeat then
				CustomerData.TargetSeat.Disabled = true
				if CustomerData.TargetSeat:FindFirstChildWhichIsA("Weld") then
					CustomerData.TargetSeat:FindFirstChildWhichIsA("Weld"):Destroy()
				end
				task.delay(0.25,function()
					if CustomerData.TargetSeat then
						CustomerData.TargetSeat.Disabled = false
					end
				end)
			end
			humanoid.Sit = false
			humanoid.Jump = true 
			CustomerData.State = "Leaving"
		end

	elseif CustomerData.State == "Leaving" or CustomerData.State == "ComputingExit" then
		if not PathFolder then
			PathFolder = CashCollectionFolder.FarmerPlots.CustomerPath
		end

		local ExitNode = PathFolder:FindFirstChild("25")
		if ExitNode then
			NPCHandler.Go(Customer, ExitNode.Position)
			CustomerData.State = "FollowingExitPath"
		else
			CustomerData.State = "Despawning"
		end

	elseif CustomerData.State == "FollowingExitPath" then
		if not PathFolder then
			PathFolder = CashCollectionFolder.FarmerPlots.CustomerPath
		end

		local ExitNode = PathFolder:FindFirstChild("25")
		if ExitNode then
			local Distance = (hrp.Position - ExitNode.Position).Magnitude
			CustomerData.StuckTimer = (CustomerData.StuckTimer or 0) + deltaTime

			if Distance < 3.5 or CustomerData.StuckTimer > 15 then
				NPCHandler.Stop(Customer)
				CustomerData.State = "Despawning"
				CustomerData.StuckTimer = 0
			end
		else
			-- FIX: Make sure they despawn if the exit node gets removed.
			NPCHandler.Stop(Customer)
			CustomerData.State = "Despawning"
		end

	elseif CustomerData.State == "Intercepted" or CustomerData.State == "ComputingIntercept" then
		if not PathFolder then 
			CustomerData.State = "Leaving" 
			return 
		end

		local TargetNodePart = PathFolder:FindFirstChild(tostring(Plot:GetAttribute("ConnectedPath")))
		if TargetNodePart then
			NPCHandler.Intercepted(Customer, TargetNodePart.Position)
			CustomerData.State = "FollowingInterceptPath"
		else
			CustomerData.State = "Leaving"
		end

	elseif CustomerData.State == "FollowingInterceptPath" then
		if not PathFolder then return end
		local TargetNodePart = PathFolder:FindFirstChild(tostring(Plot:GetAttribute("ConnectedPath")))

		if TargetNodePart then
			local Distance = (hrp.Position - TargetNodePart.Position).Magnitude

			-- [[ FIX: Added Stuck Timer to the Intercept Path ]]
			CustomerData.StuckTimer = (CustomerData.StuckTimer or 0) + deltaTime

			if Distance < 3.5 then
				NPCHandler.Stop(Customer)
				CustomerData.State = "Waiting"
				CustomerData.WaitTimer = 2.25
				CustomerData.StuckTimer = 0 -- Reset timer

			elseif CustomerData.StuckTimer > 15 then
				-- If they get stuck trying to walk back to the plot, just leave
				NPCHandler.Stop(Customer)
				CustomerData.State = "Leaving"
				CustomerData.StuckTimer = 0
			end
		else
			CustomerData.State = "Leaving"
		end

	elseif CustomerData.State == "Despawning" then
		NPCHandler.CleanupNPC(Customer)
		for i,v in pairs(Customer:GetDescendants()) do
			if v:IsA("BasePart") then
				if v.Name == "HumanoidRootPart" then continue end
				TS:Create(v,TweenInfo.new(0.75),{Transparency = 1}):Play()
			end
			if v:IsA("Decal") then
				v.Transparency = 1
			end
		end	
		task.delay(0.5,function()
			if Customer then Customer:Destroy() end
		end)
	end
end

RunService.Heartbeat:Connect(function(deltaTime)
	for Customer, CustomerData in pairs(NPCHandler.ActiveCustomers) do
		CustomerPathfinding(deltaTime, Customer, CustomerData)
	end
end)

Players.PlayerAdded:Connect(function(Player)
	Player.CharacterAdded:Connect(function(Character)
		repeat task.wait(1.5) until Player:FindFirstChild("PlayerInfo") and Character:FindFirstChild("ToolFolder")

		local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
		local HRP = Character:FindFirstChild("HumanoidRootPart")
		local Humanoid = Character:FindFirstChild("Humanoid")
		local Animator = Humanoid:WaitForChild("Animator")
		local LeaderstatValues = Player:WaitForChild("leaderstatValues")
		local PlayerStats = Player:WaitForChild("PlayerStats")
		local PlayerInfo = Player:WaitForChild("PlayerInfo")
		local Upgrades = PlayerStats.Upgrades
		local FarmersMarketSkillTree = PlayerStats.FarmersMarketSkillTree
		local StoredMarketFood = PlayerStats.StoredMarketFood

		FarmersMarketInfo[Player.UserId] = {
			Connections = {},
		}
		local FarmersMarKetData = FarmersMarketInfo[Player.UserId]

		if DataStore.Value.FarmersMarketSkillTree["UnlockFarmersMarket"].Unlocked == true then
			local MarketSpot = PlayerInfo.MarketSpot
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
				local FoodFolder = FarmersMarketFoodStorage:FindFirstChild(ChosenFarmersPlot:GetAttribute("ProductForSale"))
				local StorageBox = ChosenFarmersPlot.OccupiedFolder.StorageBox
				local function SpawnFoodProduct(amount)
					for i = 1,amount do
						local RN = math.random(1,#FoodFolder:GetChildren())
						local regionPart = StorageBox.PromptPart
						local randomPos = regionPart.CFrame * CFrame.new(math.random(-1,1)*regionPart.Size.X/2.5, 1.25, math.random(-1,1)*regionPart.Size.Z/2.5)

						local ChosenFood = FoodFolder:GetChildren()[RN]:Clone()
						ChosenFood.Parent = StorageBox.Food
						for i,v in pairs(StorageBox:GetChildren()) do
							if v:IsA("BasePart") then
								v.CanCollide = true
								if v == StorageBox.PromptPart then
									v.CanCollide = false
								end
							end
						end
						for i,v in pairs(ChosenFood:GetDescendants()) do
							if v:IsA("BasePart") then
								v.Anchored = false
								v.CollisionGroup = "Items"
								if v == ChosenFood.PrimaryPart then
									v.CanCollide = false
								end
							end
						end		
						ChosenFood:PivotTo(randomPos) 
					end
				end
				if #StorageBox.Food:GetChildren() < 50 then
					if StoredMarketFood.Value > 0 and StoredMarketFood.Value < 10000 then
						SpawnFoodProduct(12)
					elseif StoredMarketFood.Value >= 10000 and StoredMarketFood.Value < 1000000 then
						SpawnFoodProduct(30)
					elseif StoredMarketFood.Value >= 1000000 then
						SpawnFoodProduct(50)
					end
				end
			end
		end
		local FoodLeftTable = {}
		local StoredMarketFoodValue = PlayerStats.StoredMarketFood.Value
		FarmersMarKetData.Connections.StoredMarketFoodConnect = StoredMarketFood:GetPropertyChangedSignal("Value"):Connect(function()
			local MarketSpot = PlayerInfo.MarketSpot
			local Difference = StoredMarketFood.Value - StoredMarketFoodValue
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
				local FoodFolder = FarmersMarketFoodStorage:FindFirstChild(ChosenFarmersPlot:GetAttribute("ProductForSale"))
				local StorageBox = ChosenFarmersPlot.OccupiedFolder.StorageBox
				local function SpawnFoodProduct(amount)
					if #StorageBox.Food:GetChildren() < 50 then
						for i = 1,amount do
							local RN = math.random(1,#FoodFolder:GetChildren())
							local regionPart = StorageBox.PromptPart
							local randomPos = regionPart.CFrame * CFrame.new(math.random(-1,1)*regionPart.Size.X/2.5 , 2 , math.random(-1,1)*regionPart.Size.Z/2.5)

							local ChosenFood = FoodFolder:GetChildren()[RN]:Clone()
							ChosenFood.Parent = StorageBox.Food

							for i,v in pairs(StorageBox:GetChildren()) do
								if v:IsA("BasePart") then
									v.CanCollide = true
									if v == StorageBox.PromptPart then
										v.CanCollide = false
									end
								end
							end
							for i,v in pairs(ChosenFood:GetDescendants()) do
								if v:IsA("BasePart") then
									v.Anchored = false
									v.CollisionGroup = "Items"
									if v == ChosenFood.PrimaryPart then
										v.CanCollide = false
									end
								end
							end		
							ChosenFood:PivotTo(randomPos) 
						end
					elseif #StorageBox.Food:GetChildren() > 50 then
						for i = 1,amount do
							local RN = math.random(1,#FoodFolder:GetChildren())
							local regionPart = StorageBox.PromptPart
							local randomPos = regionPart.CFrame * CFrame.new(math.random(-1,1)*regionPart.Size.X/2 , 2 , math.random(-1,1)*regionPart.Size.Z/2)

							local ChosenFood = FoodFolder:GetChildren()[RN]:Clone()
							ChosenFood.Parent = StorageBox.Food

							for i,v in pairs(StorageBox:GetChildren()) do
								if v:IsA("BasePart") then
									v.CanCollide = true
									if v == StorageBox.PromptPart then
										v.CanCollide = false
									end
								end
							end
							for i,v in pairs(ChosenFood:GetDescendants()) do
								if v:IsA("BasePart") then
									v.CanCollide = false
									v.Anchored = false
								end
							end		
							ChosenFood:PivotTo(randomPos) 
							Debris:AddItem(ChosenFood,0.6)	
						end
					end	
				end

				if Difference > 0 then
					if StoredMarketFood.Value > 0 and StoredMarketFood.Value < 10000 then
						SpawnFoodProduct(8)
					elseif StoredMarketFood.Value >= 10000 and StoredMarketFood.Value < 1000000 then
						SpawnFoodProduct(12)
					elseif StoredMarketFood.Value >= 1000000 then
						SpawnFoodProduct(15)
					end
					local IncDecDisplay = RS:WaitForChild("UIAssets").IncDecStorageBoxDisplay:Clone()
					IncDecDisplay.Parent = StorageBox.PromptPart
					IncDecDisplay.Icon.Increment.Text = "+"..FrmtNum(Difference,2)
					IncDecDisplay.StudsOffset = Vector3.new(0,2,0)
					TS:Create(IncDecDisplay,TweenInfo.new(3.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{Brightness = 5,StudsOffset = Vector3.new(0,6,0)}):Play()
					TS:Create(IncDecDisplay.Icon.Increment,TweenInfo.new(4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{TextTransparency = 1}):Play()
					Debris:AddItem(IncDecDisplay,2.25)
					local FoodSpots = ChosenFarmersPlot.OccupiedFolder.Counter.FoodSpots
					if StoredMarketFood.Value >= 11 then
						for i,v in pairs(FoodSpots:GetDescendants()) do
							if v:IsA("BasePart") and v.Parent.Name == "FoodSpots" then
								if v:FindFirstChildWhichIsA("Model") then
									continue	
								end
								local FoodFolder = FarmersMarketFoodStorage:FindFirstChild(ChosenFarmersPlot:GetAttribute("ProductForSale"))
								local RN = math.random(1,#FoodFolder:GetChildren())
								local NewFoodModel:Model = FoodFolder:GetChildren()[RN]:Clone()
								NewFoodModel.Parent = v
								NewFoodModel:PivotTo(v.CFrame * CFrame.new(0,1.25,0))
								TS:Create(NewFoodModel.PrimaryPart,TweenInfo.new(0.75,Enum.EasingStyle.Bounce,Enum.EasingDirection.Out,0,false,0),{CFrame = v.CFrame}):Play()
							end
						end
					end 
				elseif Difference < 0 then
					local IncDecDisplay = RS:WaitForChild("UIAssets").IncDecStorageBoxDisplay:Clone()
					IncDecDisplay.Parent = StorageBox.PromptPart
					IncDecDisplay.Icon.Increment.Text = "-"..FrmtNum(Difference,2)
					IncDecDisplay.Icon.Increment.OrangeGradient.Enabled = false
					IncDecDisplay.Icon.Increment.TextColor3 = Color3.fromRGB(255, 0, 0)
					IncDecDisplay.StudsOffset = Vector3.new(0,2,0)
					TS:Create(IncDecDisplay,TweenInfo.new(3.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{Brightness = 5,StudsOffset = Vector3.new(0,6,0)}):Play()
					TS:Create(IncDecDisplay.Icon.Increment,TweenInfo.new(4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{TextTransparency = 1}):Play()
					Debris:AddItem(IncDecDisplay,2.25)

					local FoodSpots = ChosenFarmersPlot.OccupiedFolder.Counter.FoodSpots
					if StoredMarketFood.Value >= 11 then
						if FoodSpots.Spot11:FindFirstChildWhichIsA("Model") then
							FoodSpots.Spot11:FindFirstChildWhichIsA("Model"):Destroy()
						end

						--THIS FOR LOOP KEEPS TRACK OF EMPTY SPACES ON THE COUNTER--
						for i,v in pairs(FoodSpots:GetChildren()) do
							if v:IsA("BasePart") and v.Parent then
								if v:FindFirstChildWhichIsA("Model") then
									continue
								end
								if not FoodLeftTable[Player.UserId] then
									FoodLeftTable[Player.UserId] = {}
								end
								if table.find(FoodLeftTable[Player.UserId],v) then
									continue
								end
								if #FoodLeftTable[Player.UserId] < 7 then
									table.insert(FoodLeftTable[Player.UserId],v)
								end
							end
						end
						----

						for i,v in pairs(FoodSpots:GetDescendants()) do
							if v:IsA("Model") and v.Parent and string.find(v.Parent.Name,"Spot") then
								local CurrentSpot = v.Parent
								local SpotNum = string.gsub(CurrentSpot.Name,"Spot","")
								local NextSpot = FoodSpots:FindFirstChild("Spot"..tonumber(SpotNum)+1)

								if v.Parent == FoodSpots.Spot5 then
									NextSpot = FoodSpots:FindFirstChild("Spot"..tonumber(SpotNum)+2)
								end

								if not NextSpot then
									continue
								end

								v.Parent = NextSpot

								if v.PrimaryPart then
									TS:Create(v.PrimaryPart, TweenInfo.new(0.65), {CFrame = NextSpot.CFrame}):Play()
								else
									-- If the PrimaryPart is missing, instantly move it so the server doesn't crash
									v:PivotTo(NextSpot.CFrame)
									warn("WARNING: Missing PrimaryPart on Farmers Market Food Model: " .. v.Name)
								end
							end
						end
						local EmptySpotsCount = #FoodLeftTable[Player.UserId]

						if EmptySpotsCount >= 7 then
							for i,v in pairs(FoodSpots:GetDescendants()) do
								if v:IsA("BasePart") and v.Parent.Name == "FoodSpots" then
									if v:FindFirstChildWhichIsA("Model") then
										continue	
									end
									local FoodFolder = FarmersMarketFoodStorage:FindFirstChild(ChosenFarmersPlot:GetAttribute("ProductForSale"))
									local RN = math.random(1,#FoodFolder:GetChildren())
									local NewFoodModel:Model = FoodFolder:GetChildren()[RN]:Clone()
									NewFoodModel.Parent = v
									NewFoodModel:PivotTo(v.CFrame * CFrame.new(0,1.25,0))
									if NewFoodModel and NewFoodModel.PrimaryPart then
										TS:Create(NewFoodModel.PrimaryPart,TweenInfo.new(1,Enum.EasingStyle.Bounce,Enum.EasingDirection.Out,0,false,0),{CFrame = v.CFrame}):Play()
									end
								end
							end
							FoodLeftTable[Player.UserId] = {}
							return	
						end

						local FoodFolder = FarmersMarketFoodStorage:FindFirstChild(ChosenFarmersPlot:GetAttribute("ProductForSale"))
						local RN = math.random(1,#FoodFolder:GetChildren())
						local NewFoodModel:Model = FoodFolder:GetChildren()[RN]:Clone()
						NewFoodModel.Parent = FoodSpots.Spot1
						NewFoodModel:PivotTo(FoodSpots.Spot1.CFrame)
					elseif StoredMarketFood.Value <= 11 and StoredMarketFood.Value > 0 then
						if #StorageBox.Food:GetChildren() > 0 then
							for i,v in pairs(StorageBox.Food:GetChildren()) do
								if v:IsA("Model") then
									v:Destroy()
									break
								end
							end
						end
					end 
				end	
			end
			StoredMarketFoodValue = StoredMarketFood.Value
		end)
	end)
end)

Players.PlayerRemoving:Connect(function(Player)
	if FarmersMarketInfo[Player.UserId] then
		for _, connection in pairs(FarmersMarketInfo[Player.UserId].Connections) do
			if connection then connection:Disconnect() end
		end
		FarmersMarketInfo[Player.UserId] = nil
	end

	local PlayerStats = Player:FindFirstChild("PlayerStats")
	if not PlayerStats then return end

	local FarmersMarketSkillTree = PlayerStats:FindFirstChild("FarmersMarketSkillTree")

	if FarmersMarketSkillTree and FarmersMarketSkillTree.UnlockFarmersMarket.Value == true then
		local ChosenFarmersPlot = nil
		local OwnerStringValue = nil 

		for i,v in pairs(CashCollectionFolder.FarmerPlots:GetDescendants()) do
			if v:IsA("StringValue") then
				if v.Value == Player.Name then
					ChosenFarmersPlot = v.Parent
					OwnerStringValue = v
					break
				end
			end
		end

		if ChosenFarmersPlot then
			if OwnerStringValue then
				OwnerStringValue.Value = "Vacant" -- FIX: Set to "Vacant" so the NPC checks can properly clear it!
			end
			ChosenFarmersPlot.Name = string.gsub(ChosenFarmersPlot.Name, Player.Name, "")

			ChosenFarmersPlot.SellerDisplay.NameDisplay.Frame.Level.Visible = false
			ChosenFarmersPlot.SellerDisplay.NameDisplay.Frame.PlayerName.Text = "Vacant"
			ChosenFarmersPlot.SellerDisplay.NameDisplay.Frame.PlayerName.TextColor3 = Color3.new(1, 0, 0)
			ChosenFarmersPlot.SellerDisplay.NameDisplay.Frame.PlayerIcon.Image = ""
			ChosenFarmersPlot.SellerDisplay.NameDisplay.Frame.Level.Text = ""
			ChosenFarmersPlot.OccupiedFolder.StorageBox.PromptPart.StorageBoxDisplay.Icon.Increment.Text = "0"
			
			for i,v in pairs(ChosenFarmersPlot.OccupiedFolder:GetDescendants()) do
				if not v.Parent then continue end

				if v:IsA("BasePart") then
					if v.Parent.Name == "OccupiedFolder" or (v.Parent.Parent and v.Parent.Parent.Name == "OccupiedFolder") then
						v.Transparency = 1
						v.CanCollide = false
						v.CanQuery = false
						v.CanTouch = false
					end
				end	

				if v:IsA("Model") then
					if (v.Parent:IsA("Folder") and v.Parent.Name == "Food") or string.find(v.Parent.Name, "Spot") then
						v:Destroy()
					end
				end

				if v:IsA("BillboardGui") or v:IsA("ProximityPrompt") then
					v.Enabled = false
				end	
			end
			print("CLEANED UP PLAYERS MARKET AND FREED PLOT: "..Player.Name.." "..ChosenFarmersPlot.Name)
		end	
	end
end)