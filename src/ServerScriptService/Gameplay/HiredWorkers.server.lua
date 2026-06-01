-- [[ HIRED WORKERS SERVER SCRIPT ]] --
local CS = game:GetService("CollectionService")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local TS = game:GetService("TweenService")

--MODULES
local DataStoreModule = require(SS:WaitForChild("Modules").MainDataModule)
local UpgradesDictionary = require(RS:WaitForChild("Modules").UpgradesDictionary)
local NPCHandler = require(SS:WaitForChild("Modules").MarketCustomerHandler)

local HiredWorkersFolder = RS:WaitForChild("HiredWorkers")
local Assets = RS:WaitForChild("Assets")
local SFX = Assets:WaitForChild("SFX")
local PlayerIngredients = workspace:WaitForChild("PlayerIngredients")

local IngredientsStorage = SS:WaitForChild("Assets").Ingredients
local IngredientCollection = workspace.Map.CenterPoint.IngredientCollection
local IngredientsCollectionZone = IngredientCollection:WaitForChild("CollectionZone")
local CashCollectionFolder = workspace.Map.CenterPoint.CashCollection

local HiredWorkerRem = RS:WaitForChild("Remotes").HiredWorkerRemote

local ActiveShoppers = {} -- Tracks Shopper NPCs
local ActiveSellers = {}  -- Tracks Seller NPCs

-- [[ HELPER FUNCTIONS ]]

local function GetRandomSurfaceCFrame(TargetPart)
	local Size = TargetPart.Size
	local CF = TargetPart.CFrame
	local RandX = (math.random() - 0.5) * Size.X
	local RandZ = (math.random() - 0.5) * Size.Z
	local TopY = Size.Y / 2 
	return CF * CFrame.new(RandX, TopY, RandZ)
end

HiredWorkerRem.OnServerEvent:Connect(function(Player, Action, Data)
	local Character = Player.Character
	if not Character then return end

	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)

	if Action == "Deploy" and Data then
		if DataStore.Value.HiredWorkers[Data].Active == false then
			DataStore.Value.HiredWorkers[Data].Active = true
			DataStore.hiredworkers[Data]:SetAttribute("Active",DataStore.Value.HiredWorkers[Data].Active)
		else
			DataStore.Value.HiredWorkers[Data].Active = false
			DataStore.hiredworkers[Data]:SetAttribute("Active",DataStore.Value.HiredWorkers[Data].Active)
		end
	end

	if Action == "PurchaseWorker" and Data then
		if Data == "HireShopper" then
			if DataStore.Value.Ingredients >= 150_000 and DataStore.Value.HiredWorkers.Shopper.Unlocked == false then
				DataStore.Value.Ingredients -= 150_000
				DataStore.playerstats.Ingredients.Value = DataStore.Value.Ingredients

				DataStore.Value.HiredWorkers.Shopper.Unlocked = true
				DataStore.hiredworkers.Shopper.Value = DataStore.Value.HiredWorkers.Shopper.Unlocked

				DataStore.Value.HiredWorkers.Shopper.Active = true
				DataStore.hiredworkers.Shopper:SetAttribute("Active",DataStore.Value.HiredWorkers.Shopper.Active)
			end
		elseif Data == "HireSeller" then
			if DataStore.Value.Cash >= 250_000 and DataStore.Value.HiredWorkers.Seller.Unlocked == false then
				DataStore.LeaderStatValues.Cash.Value -= 250_000

				DataStore.Value.HiredWorkers.Seller.Unlocked = true
				DataStore.hiredworkers.Seller.Value = DataStore.Value.HiredWorkers.Seller.Unlocked

				DataStore.Value.HiredWorkers.Seller.Active = true
				DataStore.hiredworkers.Seller:SetAttribute("Active",DataStore.Value.HiredWorkers.Seller.Active)
			end
		end
	end
end)

-- ================================================================= --
-- [[ 1. SHOPPER NPC LOGIC ]]                                        --
-- ================================================================= --

local function SpawnIngredientsForShopper(deltaTime, ShopperData, Player)
	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
	if not DataStore then return end

	local MyIngredients = PlayerIngredients:FindFirstChild(tostring(Player.UserId))
	if not MyIngredients then return end

	local Upgrades = DataStore.Value.Upgrades
	local IngredientsSpawnSpeed = Upgrades.IngredientsSpawnSpeed
	local MaxAmountofIngredients = Upgrades.MaxAmountofIngredients
	local ChanceOfGoldenIngredients = Upgrades.ChanceOfGoldenIngredients

	ShopperData.SpawnTimer = (ShopperData.SpawnTimer or 0) + deltaTime
	if ShopperData.SpawnTimer >= IngredientsSpawnSpeed then
		if #MyIngredients:GetChildren() < MaxAmountofIngredients then
			ShopperData.SpawnTimer = 0 

			local AvailableIngredients = IngredientsStorage:GetChildren()
			if #AvailableIngredients > 0 then
				local RandIngredient = AvailableIngredients[math.random(1, #AvailableIngredients)]:Clone()
				local IsGolden = false

				local CheckGoldBuffBindable = SS:WaitForChild("Modules"):FindFirstChild("CheckGoldBuff")
				local HasBuffActive = false
				if CheckGoldBuffBindable then
					HasBuffActive = CheckGoldBuffBindable:Invoke(Player, "Ingredients")
				end

				if HasBuffActive == true or (math.random(1, 100) <= ChanceOfGoldenIngredients) then
					IsGolden = true
					RandIngredient.Name = "Golden" .. RandIngredient.Name 

					local Vfx1 = Assets.VFX.BigSpark:Clone()
					Vfx1.Parent = RandIngredient.PrimaryPart
					local Vfx2 = Assets.VFX.BlackSpark:Clone()
					Vfx2.Parent = RandIngredient.PrimaryPart
				end

				for i, v in pairs(RandIngredient:GetChildren()) do
					if v:IsA("BasePart") then
						v.CollisionGroup = "Items"
						v.Anchored = true
						if IsGolden == true then
							v.Color = Color3.fromRGB(172, 139, 42) 
							v.Material = Enum.Material.Neon    
						end
					end
				end

				RandIngredient:ScaleTo(math.random(10, 14) / 10) 
				local TargetZone = IngredientsCollectionZone
				local SpawnCF = GetRandomSurfaceCFrame(TargetZone)
				local HeightOffset = RandIngredient.PrimaryPart.Size.Y / 2
				RandIngredient:PivotTo(SpawnCF * CFrame.new(0, HeightOffset, 0) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0))
				RandIngredient.Parent = MyIngredients
			end
		end
	end
end

local function ProcessShopperIncrement(Player, DataStore, IsGolden)
	local PlayerStats = Player:FindFirstChild("PlayerStats")
	local PlayerInfo = Player:WaitForChild("PlayerInfo")
	if not PlayerStats or not PlayerInfo then return end

	local Experience = PlayerStats:FindFirstChild("Experience")
	local Upgrades = DataStore.Value.Upgrades

	local IngredientsPerCollect = Upgrades.IngredientsPerCollect
	local MultiIngredientsPerCollect = Upgrades.MultiplyIngredientsPerCollect
	local TotalSkillTreeMultiplier = 1

	if DataStore.Value.FarmersMarketSkillTree["x1.5Ingredients"].Unlocked == true then TotalSkillTreeMultiplier = 1.5 end
	if DataStore.Value.FarmersMarketSkillTree["x3Ingredients"].Unlocked == true then
		if TotalSkillTreeMultiplier == 1 then TotalSkillTreeMultiplier = 3 else TotalSkillTreeMultiplier += 3 end
	end
	if DataStore.Value.FarmersMarketSkillTree["IngredientsBoostedByPlayTime"].Unlocked == true then
		if TotalSkillTreeMultiplier == 1 then TotalSkillTreeMultiplier = PlayerInfo.Playtime.Value else TotalSkillTreeMultiplier += PlayerInfo.Playtime.Value end
	end

	local TotalAddedIngredients = 0
	if IsGolden then
		TotalAddedIngredients = (IngredientsPerCollect * 3) * MultiIngredientsPerCollect
		DataStore.Value.Experience += math.random(2, 3)
	else
		TotalAddedIngredients = IngredientsPerCollect * MultiIngredientsPerCollect
		DataStore.Value.Experience += math.random(1, 2)
	end

	TotalAddedIngredients *= TotalSkillTreeMultiplier
	if Player:GetAttribute("x2Ingredients") == true then TotalAddedIngredients *= 2 end
	
	TotalAddedIngredients *= PlayerInfo.IngredientMultiplierEventValue.Value

	DataStore.Value.Ingredients += TotalAddedIngredients
	DataStore.playerstats.Ingredients.Value = DataStore.Value.Ingredients
	Experience.Value = DataStore.Value.Experience
end

local function ProcessAndAnimate(Player, ShopperData, IngredientModel)
	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
	if not DataStore then ShopperData.IsBusy = false; return end

	local NPC = ShopperData.Model
	local HRP = NPC:FindFirstChild("HumanoidRootPart")
	local LeftHand = NPC:FindFirstChild("LeftHand")
	local CharDebrisFolder = NPC:FindFirstChild("CharDebris")
	if not HRP or not LeftHand or not CharDebrisFolder then ShopperData.IsBusy = false; return end

	local IngredientType = string.find(IngredientModel.Name, "Golden") and "Golden" or "Normal"
	local IngredientName = string.gsub(IngredientModel.Name, "Golden", "")
	Debris:AddItem(IngredientModel, 0)

	for _, v in pairs(ShopperData.Connections) do if v then v:Disconnect() end end
	ShopperData.Connections = {}

	if IngredientName == "Rice" or IngredientName == "Spaghetti" or IngredientName == "Potato" then
		local Pot = Assets.Pot:Clone()
		Pot.Parent = NPC
		local CopiedIngredient = Assets.Ingredients[IngredientName]:Clone()
		CopiedIngredient.Parent = CharDebrisFolder
		CopiedIngredient:PivotTo(LeftHand.CFrame)

		if IngredientType == "Golden" then
			for i, v in pairs(CopiedIngredient:GetDescendants()) do
				if v:IsA("BasePart") then v.Color = Color3.fromRGB(172, 139, 42); v.Material = Enum.Material.Neon end
			end
			local Vfx1 = Assets.VFX.BigSpark:Clone(); Vfx1.Parent = CopiedIngredient.PrimaryPart
			local Vfx2 = Assets.VFX.BlackSpark:Clone(); Vfx2.Parent = CopiedIngredient.PrimaryPart
		end

		local Weld = Instance.new("Weld")
		Weld.Parent = CopiedIngredient.PrimaryPart; Weld.Part1 = CopiedIngredient.PrimaryPart; Weld.Part0 = LeftHand; Weld.C0 = CFrame.new(0, -0.35, 0)

		ShopperData.Animations.PutIngredientsInPot:Play()

		ShopperData.Connections["PutIn"] = ShopperData.Animations.PutIngredientsInPot:GetMarkerReachedSignal("PutIn"):Once(function()
			Weld:Destroy()
			CopiedIngredient:PivotTo(Pot.IngredientPosition.CFrame)
			local Weld2 = Instance.new("Weld")
			Weld2.Parent = CopiedIngredient.PrimaryPart; Weld2.Part1 = CopiedIngredient.PrimaryPart; Weld2.Part0 = Pot.IngredientPosition
			if IngredientName == "Spaghetti" then Weld2.C0 = CFrame.new(0, 0.3, 0); Weld2.C1 = CFrame.Angles(math.rad(30), 0, 0) else Weld2.C0 = CFrame.new(0, 0.25, 0) end
			local WaterBoilSFX = SFX.WaterBoilShort:Clone(); WaterBoilSFX.Parent = Pot.PrimaryPart; WaterBoilSFX:Play(); Debris:AddItem(WaterBoilSFX, 1)
		end)

		ShopperData.Connections["Toss"] = ShopperData.Animations.PutIngredientsInPot:GetMarkerReachedSignal("Toss"):Once(function()
			Pot.Parent = CharDebrisFolder
			local BV = Instance.new("BodyVelocity")
			BV.Parent = Pot.PrimaryPart; BV.MaxForce = Vector3.new(9999, 9999, 9999); BV.Velocity = HRP.CFrame.RightVector * 25 + Vector3.new(0, 15, 5)
			Debris:AddItem(BV, 0.15); Debris:AddItem(CopiedIngredient, 0.85); Debris:AddItem(Pot, 1)
		end)

		ShopperData.Connections["EndedPot"] = ShopperData.Animations.PutIngredientsInPot.Ended:Once(function()
			if NPC:FindFirstChild("Pot") then NPC:FindFirstChild("Pot"):Destroy() end
			for i, v in pairs(CharDebrisFolder:GetChildren()) do v:Destroy() end
			ProcessShopperIncrement(Player, DataStore, IngredientType == "Golden")
			ShopperData.IsBusy = false
		end)
	else
		local Knife = Assets.Knife:Clone()
		Knife.Parent = NPC
		local ChoppingBoard = Assets.ChoppingBoard:Clone()
		ChoppingBoard.Parent = CharDebrisFolder
		ChoppingBoard:PivotTo(LeftHand.CFrame)

		local BoardWeld = Instance.new("Weld")
		BoardWeld.Parent = ChoppingBoard.PrimaryPart; BoardWeld.Part1 = ChoppingBoard.PrimaryPart; BoardWeld.Part0 = LeftHand; BoardWeld.C0 = CFrame.new(0, -0.25, 0); BoardWeld.C1 = CFrame.Angles(0, math.rad(180), 0)

		local CopiedIngredient = Assets.Ingredients[IngredientName]:Clone()
		CopiedIngredient.Parent = CharDebrisFolder
		CopiedIngredient:PivotTo(ChoppingBoard.PrimaryPart.CFrame)

		if IngredientType == "Golden" then
			for i, v in pairs(CopiedIngredient:GetDescendants()) do
				if v:IsA("BasePart") then v.Color = Color3.fromRGB(172, 139, 42); v.Material = Enum.Material.Neon end
			end
			local Vfx1 = Assets.VFX.BigSpark:Clone(); Vfx1.Parent = CopiedIngredient.PrimaryPart
			local Vfx2 = Assets.VFX.BlackSpark:Clone(); Vfx2.Parent = CopiedIngredient.PrimaryPart
		end

		local IngWeld = Instance.new("Weld")
		IngWeld.Parent = CopiedIngredient.PrimaryPart; IngWeld.Part1 = CopiedIngredient.PrimaryPart; IngWeld.Part0 = ChoppingBoard.PrimaryPart; IngWeld.C0 = CFrame.new(0, 0.55, 2.25)

		local ChopIngredientSFX = SFX.ChopIngredient:Clone(); ChopIngredientSFX.Parent = ChoppingBoard.PrimaryPart; ChopIngredientSFX:Play(); Debris:AddItem(ChopIngredientSFX, 1)

		ShopperData.Animations.ChopIngredients:Play()

		ShopperData.Connections["Chop"] = ShopperData.Animations.ChopIngredients:GetMarkerReachedSignal("Chop"):Once(function()
			for i, v in pairs(CopiedIngredient:GetDescendants()) do
				if v:IsA("Weld") then v:Destroy() end
				if v:IsA("BasePart") then
					local BV = Instance.new("BodyVelocity"); BV.Parent = v; BV.MaxForce = Vector3.new(5, 5, 5); BV.Velocity = Vector3.new(math.random(-90, 90), 7.5, math.random(-90, 90)); Debris:AddItem(BV, 0.025)
				end
			end
		end)

		ShopperData.Connections["TossKnife"] = ShopperData.Animations.ChopIngredients:GetMarkerReachedSignal("TossKnife"):Once(function()
			Knife.Parent = CharDebrisFolder
			local BV = Instance.new("BodyVelocity"); BV.Parent = Knife.PrimaryPart; BV.MaxForce = Vector3.new(9999, 9999, 9999); BV.Velocity = HRP.CFrame.RightVector * 25 + Vector3.new(0, 15, 5); Debris:AddItem(BV, 0.15)
			local TossknifeSFX = SFX.TossKnife:Clone(); TossknifeSFX.Parent = ChoppingBoard.PrimaryPart; TossknifeSFX:Play(); Debris:AddItem(TossknifeSFX, 1)
		end)

		ShopperData.Connections["TossChopBoard"] = ShopperData.Animations.ChopIngredients:GetMarkerReachedSignal("TossChopBoard"):Once(function()
			BoardWeld:Destroy()
			local BV = Instance.new("BodyVelocity"); BV.Parent = ChoppingBoard.PrimaryPart; BV.MaxForce = Vector3.new(9999, 9999, 9999); BV.Velocity = HRP.CFrame.RightVector * -25 + Vector3.new(0, 15, 5); Debris:AddItem(BV, 0.15)
		end)

		ShopperData.Connections["EndedChopping"] = ShopperData.Animations.ChopIngredients.Ended:Once(function()
			if NPC:FindFirstChild("Knife") then NPC:FindFirstChild("Knife"):Destroy() end
			for i, v in pairs(CharDebrisFolder:GetChildren()) do v:Destroy() end
			ProcessShopperIncrement(Player, DataStore, IngredientType == "Golden")
			ShopperData.IsBusy = false
		end)
	end
end

local function StartShopperNPC(Player)
	if ActiveShoppers[Player.UserId] then return end 
	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
	if not DataStore then return end

	local ShopperRig = HiredWorkersFolder:WaitForChild("Shopper"):Clone()
	ShopperRig.Name = Player.Name .. "_Shopper"
	ShopperRig.Head.HeadDisplay.Title.Text = Player.Name .. "'s_Shopper" 
	ShopperRig.Parent = workspace.HiredWorkers
	local CharDebris = Instance.new("Folder"); CharDebris.Name = "CharDebris"; CharDebris.Parent = ShopperRig

	local TargetZone = workspace.Map.CenterPoint.IngredientCollection.CollectionZone
	ShopperRig:PivotTo(TargetZone.CFrame * CFrame.new(math.random(-5, 5), 3, math.random(-5, 5)))

	for _, part in pairs(ShopperRig:GetDescendants()) do
		if part:IsA("BasePart") then part.CollisionGroup = "Players"; part.Anchored = false end
	end

	local Humanoid = ShopperRig:FindFirstChild("Humanoid")
	local Animator = Humanoid and Humanoid:FindFirstChild("Animator")
	local LoadedAnims = {}
	if Animator then
		LoadedAnims.ChopIngredients = Animator:LoadAnimation(Assets.Animations.Ingredients.ChopIngredients)
		LoadedAnims.PutIngredientsInPot = Animator:LoadAnimation(Assets.Animations.Ingredients.PutIngredientsInPot)
	end

	ActiveShoppers[Player.UserId] = {
		Model = ShopperRig, IsWorking = true, IsBusy = false, Animations = LoadedAnims, Connections = {}, SpawnTimer = 0
	}

	task.spawn(function()
		local ShopperData = ActiveShoppers[Player.UserId]
		local MyIngredientsFolder = PlayerIngredients:WaitForChild(tostring(Player.UserId))

		while ShopperData and ShopperData.IsWorking do
			task.wait(0.2)
			if not Player or not Player.Parent or not ShopperData.IsWorking then break end
			if ShopperData.IsBusy then continue end 

			local closestIngredient = nil
			local closestDist = math.huge
			local HRP = ShopperRig:FindFirstChild("HumanoidRootPart")

			if HRP and MyIngredientsFolder then
				for _, ingredient in pairs(MyIngredientsFolder:GetChildren()) do
					if ingredient:IsA("Model") and ingredient.PrimaryPart and ingredient.Parent then
						-- The fix: Calculate ONLY horizontal distance, ignore Y-axis height differences
						local pos1 = HRP.Position
						local pos2 = ingredient:GetPivot().Position
						local dist = Vector3.new(pos1.X - pos2.X, 0, pos1.Z - pos2.Z).Magnitude

						if dist < closestDist then closestDist = dist; closestIngredient = ingredient end
					end
				end
			end

			if closestIngredient and closestIngredient.Parent and HRP then
				Humanoid:MoveTo(closestIngredient:GetPivot().Position)

				-- Increased acceptable radius to 5 to account for walking overshoot
				if closestDist <= 5 then
					ShopperData.IsBusy = true
					Humanoid:MoveTo(HRP.Position)
					ProcessAndAnimate(Player, ShopperData, closestIngredient)
				end
			end
		end
	end)
end

local function StopShopperNPC(Player)
	if ActiveShoppers[Player.UserId] then
		local ShopperData = ActiveShoppers[Player.UserId]
		ShopperData.IsWorking = false 
		for _, v in pairs(ShopperData.Connections) do if v then v:Disconnect() end end
		if ShopperData.Animations then for _, anim in pairs(ShopperData.Animations) do anim:Stop() end end
		if ShopperData.Model then ShopperData.Model:Destroy() end
		ActiveShoppers[Player.UserId] = nil
	end
end

-- ================================================================= --
-- [[ 2. SELLER NPC LOGIC ]]                                         --
-- ================================================================= --

local function SimulateSaleButton(Player, Plot, DataStore)
	local Upgrades = DataStore.Value.Upgrades
	local SpeedVal = Upgrades.SaleSpeed

	-- Use your exact hierarchy for the button!
	local ButtonPart = Plot.OccupiedFolder.Button.Button
	local DebounceTimer = Plot.OccupiedFolder.Button.Debounce

	-- [[ DEBOUNCE LOGIC ]]
	local currentTime = os.clock()
	if (currentTime - DebounceTimer.Value) < SpeedVal then return end

	-- [[ FOOD BOXES CHECK ]]
	local FoodPerCashCost = math.random(20, 30)
	if DataStore.Value.StoredMarketFood < FoodPerCashCost then return end

	DebounceTimer.Value = currentTime

	-- [[ STABLE BUTTON ANIMATION ]]
	if not ButtonPart:GetAttribute("OriginalPosition") then
		ButtonPart:SetAttribute("OriginalPosition", ButtonPart.Position)
	end

	local originalPos = ButtonPart:GetAttribute("OriginalPosition")
	local pressedPos = originalPos - Vector3.new(0, 0.25, 0)

	if ButtonPart:FindFirstChild("DownTween") then ButtonPart.DownTween:Cancel() end
	if ButtonPart:FindFirstChild("UpTween") then ButtonPart.UpTween:Cancel() end

	local downTween = TS:Create(ButtonPart, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Color = Color3.new(1, 0, 0), Position = pressedPos})
	downTween.Name = "DownTween"
	downTween.Parent = ButtonPart
	downTween:Play()

	task.delay(SpeedVal, function()
		local upTween = TS:Create(ButtonPart, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Color = Color3.new(0, 1, 0), Position = originalPos})
		upTween.Name = "UpTween"
		upTween.Parent = ButtonPart
		upTween:Play()
		Debris:AddItem(upTween, 1) 
	end)

	Debris:AddItem(downTween, SpeedVal + 1) 

	local ButtonClickSFX = SFX.FarmersButtonClick:Clone()
	ButtonClickSFX.Parent = ButtonPart
	ButtonClickSFX:Play()
	Debris:AddItem(ButtonClickSFX, 0.75)

	-- [[ CUSTOMER SPAWNING / INTERCEPTION ]]
	local CustomerPath = Plot.Parent.CustomerPath
	local CustomersFolder = CashCollectionFolder.FarmerPlots.Customers
	local ChosenCustomer = nil

	for i,v in pairs(CustomersFolder:GetChildren()) do
		if v:IsA("Model") and v:FindFirstChildWhichIsA("Humanoid") then
			if v:GetAttribute("TargetPlot") == "None" and v:GetAttribute("State") ~= "Despawning" then
				local custData = NPCHandler.ActiveCustomers[v]
				local visited = custData and custData.VisitedPlots or {}
				if not table.find(visited, Plot.Name) then
					if v:GetAttribute("State") == "Sitting" then continue end
					v:SetAttribute("TargetPlot", Plot.Name)
					ChosenCustomer = v
					break
				end
			end
		end
	end

	if ChosenCustomer == nil and #CustomersFolder:GetChildren() < 30 then
		local CustomerNPC = Assets.CustomerRig:Clone()
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
		ChosenCustomer.Name = "Customer_Seller_" .. math.random(1000, 9999)
		for i,v in pairs(ChosenCustomer:GetDescendants()) do
			if v:IsA("BasePart") then
				if v.Name == "HumanoidRootPart" then continue end
				v.Transparency = 1
			end
			if v:IsA("Decal") then v.Transparency = 1 end
		end	
		task.delay(0.4,function()
			for i,v in pairs(ChosenCustomer:GetDescendants()) do
				if v:IsA("BasePart") then
					if v.Name == "HumanoidRootPart" then continue end
					TS:Create(v,TweenInfo.new(1),{Transparency = 0}):Play()
					v.CollisionGroup = "Customers"
				end
				if v:IsA("Decal") then v.Transparency = 0 end
			end	
		end)	
	end

	if ChosenCustomer == nil then return end

	local CustomerHum:Humanoid = ChosenCustomer:WaitForChild("Humanoid")
	local CustomerHrp = ChosenCustomer:WaitForChild("HumanoidRootPart")
	if CustomerHum == nil or CustomerHrp == nil then return end

	task.spawn(function()
		pcall(function()
			local FriendsPages = Players:GetFriendsAsync(Player.UserId)
			local Friends = {}
			local currentPage = FriendsPages:GetCurrentPage()
			local JolrFriend = {Id = 2460575279}
			while currentPage do
				for _, friend in pairs(currentPage) do table.insert(Friends, friend) end
				if FriendsPages.IsFinished then break end
				FriendsPages:AdvanceToNextPageAsync()
				currentPage = FriendsPages:GetCurrentPage()
			end
			local ChosenFriend = (#Friends <= 0) and JolrFriend or Friends[math.random(1,#Friends)]

			local FriendDescription = Players:GetHumanoidDescriptionFromUserIdAsync(ChosenFriend.Id) 
			FriendDescription.WidthScale = 1; FriendDescription.DepthScale = 1; FriendDescription.HeightScale = 1
			CustomerHum:ApplyDescriptionAsync(FriendDescription)

			pcall(function() if CustomerHrp and CustomerHrp:CanSetNetworkOwnership() then CustomerHrp:SetNetworkOwner(nil) end end)

			for i,v in pairs(ChosenCustomer:GetDescendants()) do
				if v:IsA("BasePart") then v.CollisionGroup = "Customers" end
			end
		end)
	end)

	-- Hand off to the Farmers Market Heartbeat Loop!
	if NPCHandler.ActiveCustomers[ChosenCustomer] then
		NPCHandler.ActiveCustomers[ChosenCustomer].Plr = Player
		NPCHandler.ActiveCustomers[ChosenCustomer].TargetPlot = Plot
		NPCHandler.ActiveCustomers[ChosenCustomer].State = "Intercepted"
		table.insert(NPCHandler.ActiveCustomers[ChosenCustomer].VisitedPlots, Plot.Name)
	else
		local StartPoint = Plot:GetAttribute("ConnectedPath") - 2
		if StartPoint < 1 then StartPoint = 1 end
		NPCHandler.SetupNPC(ChosenCustomer, Plot, StartPoint, Player)
	end
end

local function StartSellerNPC(Player)
	if ActiveSellers[Player.UserId] then return end 
	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
	if not DataStore then return end

	-- [[ EXPLICIT UNLOCK CHECK: Don't spawn if they haven't bought the market ]]
	if DataStore.Value.FarmersMarketSkillTree["UnlockFarmersMarket"].Unlocked == false then 
		return 
	end

	-- Find the player's Farmers Market Plot
	local ChosenFarmersPlot = nil
	for i,v in pairs(CashCollectionFolder.FarmerPlots:GetDescendants()) do
		if v:IsA("StringValue") then
			if v.Value == Player.Name then
				ChosenFarmersPlot = v.Parent
				break
			end
		end
	end

	if not ChosenFarmersPlot then return end -- They haven't claimed a plot yet

	-- Grab exact button using your hierarchy path to spawn NPC
	local ButtonPart = ChosenFarmersPlot.OccupiedFolder.Button.Button

	-- Spawn Seller Rig
	local SellerRig = HiredWorkersFolder:WaitForChild("Seller"):Clone()
	SellerRig.Name = Player.Name .. "_Seller"
	SellerRig.Head.HeadDisplay.Title.Text = Player.Name .. "'s_Seller" 
	SellerRig.Parent = workspace.HiredWorkers

	-- Pivot to button location
	SellerRig:PivotTo(ButtonPart.CFrame * CFrame.new(-3.5, 1.25, 0))

	-- Orient NPC to look at button
	local SellerHRP = SellerRig:FindFirstChild("HumanoidRootPart")

	for _, part in pairs(SellerRig:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = "Players" 
			part.Anchored = false 
		end
	end

	ActiveSellers[Player.UserId] = {
		Model = SellerRig,
		IsWorking = true,
		Plot = ChosenFarmersPlot
	}

	task.spawn(function()
		local SellerData = ActiveSellers[Player.UserId]
		while SellerData and SellerData.IsWorking do
			-- Check Speed
			local CurrentDS = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
			if not CurrentDS then break end

			local SpeedVal = CurrentDS.Value.Upgrades.SaleSpeed
			task.wait(SpeedVal)

			if not Player or not Player.Parent or not SellerData.IsWorking then break end

			-- Simulate the button press
			SimulateSaleButton(Player, SellerData.Plot, CurrentDS)
		end
	end)
end

local function StopSellerNPC(Player)
	if ActiveSellers[Player.UserId] then
		local SellerData = ActiveSellers[Player.UserId]
		SellerData.IsWorking = false 
		if SellerData.Model then SellerData.Model:Destroy() end
		ActiveSellers[Player.UserId] = nil
	end
end

-- ================================================================= --
-- [[ 3. MAIN HOOKS & LOOPS ]]                                       --
-- ================================================================= --

Players.PlayerAdded:Connect(function(Player)
	-- Give the server 2.5 seconds to fully load the Player's Data and assign their Market Plot
	task.delay(10, function()
		if not Player or not Player.Parent then return end

		local PlayerStats = Player:FindFirstChild("PlayerStats")
		if not PlayerStats then return end

		local HiredWorkersStats = PlayerStats:FindFirstChild("HiredWorkers")
		if not HiredWorkersStats then return end

		-- [[ SHOPPER SETUP ]]
		local ShopperStat = HiredWorkersStats:FindFirstChild("Shopper")
		if ShopperStat then
			-- 1. Initial Check: Is it already active when they join?
			if ShopperStat:GetAttribute("Active") == true then
				StartShopperNPC(Player)
			end

			-- 2. Listen for future manual toggles
			ShopperStat:GetAttributeChangedSignal("Active"):Connect(function()
				if ShopperStat:GetAttribute("Active") then 
					StartShopperNPC(Player) 
				else 
					StopShopperNPC(Player) 
				end
			end)
		end

		-- [[ SELLER SETUP ]]
		local SellerStat = HiredWorkersStats:FindFirstChild("Seller")
		if SellerStat then
			-- 1. Initial Check: Is it already active when they join?
			if SellerStat:GetAttribute("Active") == true then
				StartSellerNPC(Player)
			end

			-- 2. Listen for future manual toggles
			SellerStat:GetAttributeChangedSignal("Active"):Connect(function()
				if SellerStat:GetAttribute("Active") then 
					StartSellerNPC(Player) 
				else 
					StopSellerNPC(Player) 
				end
			end)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(Player)
	StopShopperNPC(Player)
	StopSellerNPC(Player)
end)

-- Run Service Loop to constantly spawn ingredients for Active Shoppers
RunService.Heartbeat:Connect(function(deltaTime)
	for userId, ShopperData in pairs(ActiveShoppers) do
		if ShopperData.IsWorking then
			local Player = Players:GetPlayerByUserId(userId)
			if Player then
				SpawnIngredientsForShopper(deltaTime, ShopperData, Player)
			end
		end
	end
end)