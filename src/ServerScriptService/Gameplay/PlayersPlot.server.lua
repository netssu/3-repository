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
local NPCHandler = require(SS:WaitForChild("Modules").RestaurantCustomerHandler)
local NotifModule = require(RS:WaitForChild("Modules").NotifModule)

local PlayerPlotRem = RS:WaitForChild("Remotes").PlayerPlotRemote

local PlayerIngredients = workspace.PlayerIngredients
local PlayerFoodBoxes = workspace.PlayerFoodBoxes

local SFX = RS:WaitForChild("Assets").SFX

local Plots = workspace.Plots
local CashCollectionFolder = workspace.Map.CenterPoint.CashCollection

local FoodStorage = SS:WaitForChild("Assets").Foods
local RestaurantFoodStorage = SS:WaitForChild("Assets").RestaurantFoods

local FoodCollection = workspace.Map.CenterPoint.FoodCollection
local CookingSpots = FoodCollection.CookingPot.CookingSpots
local FoodPerCashCost = 300

local RestaurantInfo = {}

local CustomerChances = {
	EatIn = 750, -- 75 %
	TakeOut = 250, --25 %
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

-- [[ REBUILT: PlaceGourmetPlates (Ghost Plate Fail-Safe added) ]]
local function PlaceGourmetPlates(Plot,Character,Plr,DataStore)
	local PlayerStats = Plr.PlayerStats
	local Kitchen = Plot.RestaurantBuild.Kitchen
	local FoodSpots = Kitchen.FoodSpots

	local ToolFolder = Character:FindFirstChild("ToolFolder")

	local FreeFoodSpot = nil
	for i = 1,12 do
		if FoodSpots:FindFirstChild("FoodSpot"..i).Occupied.Value == false and not FoodSpots:FindFirstChild("FoodSpot"..i):FindFirstChild("GourmetPlate") then
			FreeFoodSpot = FoodSpots:FindFirstChild("FoodSpot"..i)
			break
		end
	end
	if FreeFoodSpot == nil then return end

	local GourmetPlate = nil
	if ToolFolder:FindFirstChild("GourmetPlate1") then
		GourmetPlate = ToolFolder:FindFirstChild("GourmetPlate1")
		if Character.Name == "Chef" and NPCHandler.ActiveRestaurants[Plr.UserId].Chefs[Character].Animations then
			NPCHandler.ActiveRestaurants[Plr.UserId].Chefs[Character].Animations.RHandHeldUp:Stop()
		else
			RestaurantInfo[Plr.UserId].Animations.RHandHeldUp:Stop()
		end
	elseif ToolFolder:FindFirstChild("GourmetPlate2") then
		GourmetPlate = ToolFolder:FindFirstChild("GourmetPlate2")
		if Character.Name == "Chef" and NPCHandler.ActiveRestaurants[Plr.UserId].Chefs[Character].Animations then
			NPCHandler.ActiveRestaurants[Plr.UserId].Chefs[Character].Animations.LHandHeldUp:Stop()
		else
			RestaurantInfo[Plr.UserId].Animations.LHandHeldUp:Stop()
		end
	end
	if GourmetPlate == nil then
		return
	end
	if GourmetPlate.PrimaryPart:FindFirstChild("HandWeld") then
		GourmetPlate.PrimaryPart:FindFirstChild("HandWeld"):Destroy()
	end

	for i,v in pairs(GourmetPlate:GetDescendants()) do
		if v:IsA("BasePart") then
			if v.Name == "PlateRoot" then
				v.Anchored = true
				v.CollisionGroup = "Items"
				continue
			end
			v.CollisionGroup = "Items"
			v.Anchored = false
		end
	end	

	local Angles = {-25,25}
	local ChosenAngle = Angles[math.random(1,2)]

	GourmetPlate:PivotTo(FreeFoodSpot.CFrame * CFrame.new(0,2.5,0) * CFrame.Angles(0,0,math.rad(ChosenAngle)))
	GourmetPlate.Parent = FreeFoodSpot
	GourmetPlate.Name = "GourmetPlate"
	TS:Create(GourmetPlate.PrimaryPart,TweenInfo.new(0.75,Enum.EasingStyle.Bounce,Enum.EasingDirection.Out,0,false,0.05),{CFrame = FreeFoodSpot.CFrame * CFrame.Angles(0,math.rad(180),0)}):Play()
	FreeFoodSpot.Occupied.Value = true 

	DataStore.Value.PlatesInHand -= 1
	DataStore.Value.PlatesPlaced += 1
end

-- [[ REBUILT: CookGourmetFood (Ghost Pot Fail-Safe added) ]]
local function CookGourmetFood(Plr,Plot,DataStore)
	local PlayerStats = Plr.PlayerStats
	local Upgrades = DataStore.Value.Upgrades
	local RestaurantSkillTree = DataStore.Value.RestaurantSkillTree
	local StoredFood = DataStore.Value.StoredRestaurantFood
	local StoredFoodVal= PlayerStats.StoredRestaurantFood
	local Stove = Plot.RestaurantBuild.Kitchen.Stove
	local Pots = Plot.RestaurantBuild.Kitchen.Pots
	local PlayerInfo = Plr.PlayerInfo
	local Ports = Stove.Ports
	local FoodCost = 15

	if DataStore.Value.RestaurantSkillTree["10FoodPerGourmetFood"].Unlocked == true then
		FoodCost = 10
	end
	if DataStore.Value.RestaurantSkillTree["5FoodPerGourmetFood"].Unlocked == true then
		FoodCost = 5
	end

	if StoredFood < FoodCost then
		if Plr.Character then NotifModule.Notify(Plr,"Not Enough Food In Storage Box!") end
		return
	end

	local FreePort = nil
	local TargetPotNum = nil

	-- [[ THE CHEF FIX: Ensure we don't accidentally target a pot that is already cooking! ]]
	for i = 1,12 do
		if Ports:FindFirstChild("PortFrame"..i).InUse.Value == false then
			local potCheck = Pots:FindFirstChild("Pot"..i)
			if potCheck and potCheck:GetAttribute("CookingState") ~= "Cooking" and potCheck:GetAttribute("CookingState") ~= "Cooked" then
				FreePort = Ports:FindFirstChild("PortFrame"..i)
				TargetPotNum = i
				break
			end
		end
	end

	if FreePort == nil then 
		-- Emergency Recalculate if it desyncs
		local active = 0
		for i=1,12 do if Ports:FindFirstChild("PortFrame"..i).InUse.Value then active += 1 end end
		DataStore.Value.ActivePorts = active
		return 
	end

	local Pot = Pots:FindFirstChild("Pot"..TargetPotNum)
	local NextFreePort = Ports:FindFirstChild("PortFrame"..TargetPotNum+1)

	local OrigPotPos = FreePort.PotPos.CFrame * CFrame.new(0,(FreePort.PotPos.Size.Y/2+Pot.PrimaryPart.Size.Y/2),0)
	local Angles = {-25,25}
	local ChosenAngle = Angles[math.random(1,2)]
	Pot.PrimaryPart.CFrame = Pot.PrimaryPart.CFrame * CFrame.new(0,2,0) * CFrame.Angles(0,0,math.rad(ChosenAngle))
	for i,v in pairs(Pot:GetDescendants()) do
		if v.Name == "Handle" then continue end
		if v:IsA("BasePart") then
			v.Transparency = 0
			v.Anchored = false
		end
	end

	TS:Create(Pot.PrimaryPart,TweenInfo.new(0.75,Enum.EasingStyle.Bounce,Enum.EasingDirection.Out,0,false,0),{CFrame = OrigPotPos}):Play()
	local CookingTime = Pot:WaitForChild("CookingTime")
	CookingTime.Value = 10 * Upgrades.GourmetCookingSpeed

	DataStore.Value.StoredRestaurantFood -= FoodCost
	StoredFoodVal.Value = DataStore.Value.StoredRestaurantFood

	FreePort.InUse.Value = true 
	DataStore.Value.ActivePorts += 1
	NPCHandler.ActiveRestaurants[Plr.UserId].ActivePotTimers[CookingTime] = Pot
	Pot:SetAttribute("CookingState", "Cooking")

	local CookGourmetFoodSFX = SFX.CookGourmetFood:Clone()
	CookGourmetFoodSFX.Parent = Pot.PrimaryPart
	CookGourmetFoodSFX:Play()
	Debris:AddItem(CookGourmetFoodSFX,1.5)

	local GourmetFoodPerFood = Upgrades.GourmetFoodPerFood
	local MultiplyGourmetFoodPerFood = Upgrades.MultiplyGourmetFoodPerFood
	local TotalGourmet = (GourmetFoodPerFood * MultiplyGourmetFoodPerFood)

	if RestaurantSkillTree["x1.5GourmetFood"].Unlocked == true then
		TotalGourmet *= 1.5
	end
	if RestaurantSkillTree["x3GourmetFood"].Unlocked == true then
		TotalGourmet *= 3
	end
	if RestaurantSkillTree["GourmetFoodBoostedByPlayTime"].Unlocked == true then
		TotalGourmet *= math.floor(PlayerInfo.Playtime.Value)
	end
	if RestaurantSkillTree["GourmetFoodMultipliedByLevel"].Unlocked == true then
		TotalGourmet *= DataStore.Value.Level
	end
	if Plr:GetAttribute("x2GourmetFood") == true then
		TotalGourmet *= 2
	end

	TotalGourmet *= PlayerInfo.GourmetFoodMultiplierEventValue.Value


	DataStore.Value["Gourmet Food"] += TotalGourmet
	DataStore.playerstats["Gourmet Food"].Value = DataStore.Value["Gourmet Food"]

	for i,v in pairs(Stove:GetDescendants()) do
		if v:IsA("Highlight") and v.Name == "StoveHighlight" then v.Enabled = false end
		if v:IsA("BillboardGui") and v.Name == "NextPotDisplay" then v.Enabled = false end
	end	

	if NextFreePort then
		for i,v in pairs(Stove:GetDescendants()) do
			if v:IsA("Highlight") and v.Name == "StoveHighlight" then
				v.Enabled = true
				v.Parent = NextFreePort
			end
			if v:IsA("BillboardGui") and v.Name == "NextPotDisplay" then
				v.Enabled = true
				v.Parent = NextFreePort
			end
		end	
	end
end

-- [[ REBUILT: CollectCookedGourmetFood works for Player & Chef ]]
local function CollectCookedGourmetFood(Player,Pot,Character,Plot,DataStore,CookingTimer)
	local PotInfoDisplay = Pot.PotInformation
	local Ports = Pot.Parent.Parent.Stove.Ports
	local PotNum = string.gsub(Pot.Name,"Pot","")

	local PlayerInfo = Player.PlayerInfo
	local Upgrades = DataStore.Value.Upgrades
	local RestaurantSkillTree = DataStore.Value.RestaurantSkillTree

	local ClickedPort = Ports:FindFirstChild("PortFrame"..PotNum)
	ClickedPort.InUse.Value = false 

	DataStore.Value.ActivePorts -= 1	
	if Pot:FindFirstChildWhichIsA("Highlight") then Pot:FindFirstChildWhichIsA("Highlight"):Destroy() end
	if Pot:FindFirstChild("ClickPromptDisplay") then Pot:FindFirstChild("ClickPromptDisplay"):Destroy() end
	PotInfoDisplay.Enabled = false

	local Angles = {-25,25}
	local ChosenAngle = Angles[math.random(1,2)]
	local ExitPotPos = Pot.PrimaryPart.CFrame * CFrame.new(0,3,0) * CFrame.Angles(0,0,math.rad(ChosenAngle))
	local ExitTween = TS:Create(Pot.PrimaryPart,TweenInfo.new(1.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{CFrame = ExitPotPos})
	ExitTween:Play()

	for i,v in pairs(Pot:GetDescendants()) do
		if v.Name == "Handle" then continue end
		if v:IsA("BasePart") then
			TS:Create(v,TweenInfo.new(2),{Transparency = 1}):Play()
			v.Anchored = false
		end
	end	

	local RHand = Character:FindFirstChild("RightHand")
	local LHand = Character:FindFirstChild("LeftHand")
	local GourmetPlate = RS:WaitForChild("Assets").GourmetPlate:Clone()

	-- Fallback for Chef
	local ToolFolder = Character:FindFirstChild("ToolFolder")
	GourmetPlate.Parent = ToolFolder

	local PlateRoot = GourmetPlate.PrimaryPart
	local GourmetTableTop = GourmetPlate.TableTop
	PlateRoot.TableTopRoot.C0 = CFrame.new(0,2.5,0)

	for i,v in pairs(GourmetPlate:GetDescendants()) do
		if v:IsA("BasePart") and v.Parent.Name == "TableTop" then
			if v.Name == "TableTopRoot" then
				v.CanCollide = false
				continue
			end
			v.Transparency = 1
			v.CanCollide = false
		end
	end

	task.delay(0.25,function()
		for i,v in pairs(GourmetPlate:GetDescendants()) do
			if v:IsA("BasePart") and v.Parent.Name == "TableTop" then
				if v.Name == "TableTopRoot" then continue end
				TS:Create(v,TweenInfo.new(0.5),{Transparency = 0}):Play()
				v.CanCollide = false
			end
		end
		TS:Create(PlateRoot.TableTopRoot,TweenInfo.new(0.5,Enum.EasingStyle.Bounce,Enum.EasingDirection.Out,0,false,0),{C0 = CFrame.new(0,0.365,0)}):Play()
	end)

	if DataStore.Value.PlatesInHand <= 0 then
		GourmetPlate:PivotTo(RHand.CFrame)
		GourmetPlate.Name = "GourmetPlate1"

		local Weld = Instance.new("Weld")
		Weld.Parent = GourmetPlate.PrimaryPart
		Weld.Name = "HandWeld"
		Weld.Part0 = RHand
		Weld.Part1 = GourmetPlate.PrimaryPart
		Weld.C0 = CFrame.new(0,0,-0.55)
		Weld.C1 = CFrame.Angles(math.rad(90),0,0)

		if Character.Name == "Chef" then
			if NPCHandler.ActiveRestaurants[Player.UserId].Chefs[Character].Animations then
				NPCHandler.ActiveRestaurants[Player.UserId].Chefs[Character].Animations.RHandHeldUp:Play()
			end
		else
			RestaurantInfo[Player.UserId].Animations.RHandHeldUp:Play()
		end
		DataStore.Value.PlatesInHand = 1

	elseif DataStore.Value.PlatesInHand >= 1 then
		GourmetPlate:PivotTo(LHand.CFrame)
		GourmetPlate.Name = "GourmetPlate2"

		local Weld = Instance.new("Weld")
		Weld.Parent = GourmetPlate.PrimaryPart
		Weld.Name = "HandWeld"
		Weld.Part0 = LHand
		Weld.Part1 = GourmetPlate.PrimaryPart
		Weld.C0 = CFrame.new(0,0,-0.55)
		Weld.C1 = CFrame.Angles(math.rad(90),0,0)

		if Character.Name == "Chef" then
			if NPCHandler.ActiveRestaurants[Player.UserId].Chefs[Character].Animations then
				NPCHandler.ActiveRestaurants[Player.UserId].Chefs[Character].Animations.LHandHeldUp:Play()
			end
		else
			RestaurantInfo[Player.UserId].Animations.LHandHeldUp:Play()
		end
		DataStore.Value.PlatesInHand = 2
	end	
	local GourmetFoodPerFood = Upgrades.GourmetFoodPerFood
	local MultiplyGourmetFoodPerFood = Upgrades.MultiplyGourmetFoodPerFood
	local TotalGourmet = (GourmetFoodPerFood * MultiplyGourmetFoodPerFood)

	if RestaurantSkillTree["x1.5GourmetFood"].Unlocked == true then
		TotalGourmet *= 1.5
	end
	if RestaurantSkillTree["x3GourmetFood"].Unlocked == true then
		TotalGourmet *= 3
	end
	if RestaurantSkillTree["GourmetFoodBoostedByPlayTime"].Unlocked == true then
		TotalGourmet *= math.floor(PlayerInfo.Playtime.Value)
	end
	if RestaurantSkillTree["GourmetFoodMultipliedByLevel"].Unlocked == true then
		TotalGourmet *= DataStore.Value.Level
	end
	if Player:GetAttribute("x2GourmetFood") == true then
		TotalGourmet *= 2
	end

	TotalGourmet *= PlayerInfo.GourmetFoodMultiplierEventValue.Value

	DataStore.Value["Gourmet Food"] += TotalGourmet
	DataStore.playerstats["Gourmet Food"].Value = DataStore.Value["Gourmet Food"]

	local FoodsRN = math.random(1,#RS:WaitForChild("Assets").GourmetFoods:GetChildren())
	local ChosenGourmetFood = RS:WaitForChild("Assets").GourmetFoods:GetChildren()[FoodsRN]:Clone()
	ChosenGourmetFood.Parent = GourmetPlate
	ChosenGourmetFood:PivotTo(PlateRoot.CFrame * CFrame.new(0,(PlateRoot.Size.Y/2+ChosenGourmetFood.PrimaryPart.Size.Y/2),0))

	local WeldCons = Instance.new("WeldConstraint")
	WeldCons.Parent = ChosenGourmetFood.PrimaryPart
	WeldCons.Part0 = ChosenGourmetFood.PrimaryPart
	WeldCons.Part1 = PlateRoot

	task.delay(0.1,function()
		for i,v in pairs(GourmetPlate:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CollisionGroup = "Items"
			end
		end	
	end)

	-- [[ THE FIX: Properly reset the attribute! ]]
	Pot:SetAttribute("CookingState","NotOnStove")
	NPCHandler.ActiveRestaurants[Player.UserId].ActivePotTimers[CookingTimer] = nil
end


for i,v in pairs(Plots:GetDescendants()) do
	if v:IsA("ProximityPrompt") then
		v.Enabled = false
	end
	if v:IsA("BillboardGui") then
		v.Enabled = false
	end
	if v:IsA("Seat") then
		v.Transparency = 1
		v.CanCollide = false
		v.CanQuery = false
		v.CanTouch = false
	end	
	if v:IsA("Decal") then
		v.Transparency = 1
	end
	if v:IsA("Texture") then
		if v.Parent.Name == "Base" or v.Parent.Parent.Name == "Base" or v.Parent.Parent.Parent.Name == "Base" or v.Parent.Parent.Name == "RestaurantSkillTree"  or v.Parent.Parent.Parent.Name == "RestaurantSkillTree" then
			continue
		end
		v.Transparency = 1
	end

	if v:IsA("SurfaceGui") then
		if v.Parent.Parent.Name == "PlayerNamePost" or v.Parent.Parent.Parent.Name == "RestaurantSkillTree" then
			continue
		end
		v.Enabled = false
	end
	if v:IsA("BasePart") then
		if v:FindFirstAncestor("Workers") or v.Parent:FindFirstChildWhichIsA("Humanoid") then
			v.CollisionGroup = "Workers"
			v.Transparency = 1
			v.CanQuery = false
			v.CanTouch = false
			--print(v.Parent," Is Hidden Now!")
		end
	end
	if v:IsA("BasePart") then
		if v.Parent:IsA("Accessory") and v.Parent.Parent:FindFirstChildWhichIsA("Humanoid") then--LITERALLY JUST HIDES WORKER ACCESSORIES
			v.Transparency = 1
			v.CanCollide = false
			v.CanQuery = false
			v.CanTouch = false
		end
		if v.Parent.Name == "Base" or v.Parent.Parent.Name == "Base" or v.Parent.Parent.Parent.Name == "Base" or v.Parent.Parent.Name == "RestaurantSkillTree"  or v.Parent.Parent.Parent.Name == "RestaurantSkillTree" or v.Parent:FindFirstChildWhichIsA("Humanoid") or v.Parent:IsA("Accessory") then
			continue
		end
		v.Transparency = 1
		v.CanCollide = false
		v.CanQuery = false
		v.CanTouch = false
		--print(v)
	end	

end


for i,StoragePrompt in pairs(CS:GetTagged("RestaurantStorageBoxPrompt")) do
	if StoragePrompt:IsA("ProximityPrompt") then
		StoragePrompt.ActionText = "Interact"
		StoragePrompt.ObjectText = "Restock!"
		StoragePrompt.Triggered:Connect(function(Plr)
			if StoragePrompt.Parent.Parent.Parent.Parent.Parent.Info.Occupant.Value ~= Plr.Name then
				return
			end
			local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Plr.UserId)
			if not DataStore then return end

			if DataStore.Value.CurrentFoodBoxes > 0 then
				PlayerPlotRem:FireClient(Plr,"OpenStorageBoxRestockMenu")
			elseif DataStore.Value.CurrentFoodBoxes <= 0 then
				PlayerPlotRem:FireClient(Plr,"OpenStorageBoxNoFoodBoxesMenu")
			end
		end)
	end
end

for i,PlaceGourmetPrompt in pairs(CS:GetTagged("PlaceGourmetFoodPrompt")) do
	if PlaceGourmetPrompt:IsA("ProximityPrompt") then
		PlaceGourmetPrompt.ActionText = "Interact"
		PlaceGourmetPrompt.ObjectText = "Place Plates!"
		PlaceGourmetPrompt.Triggered:Connect(function(Plr)
			if PlaceGourmetPrompt.Parent.Parent.Parent.Parent.Info.Occupant.Value ~= Plr.Name then return end
			local Character = Plr.Character
			local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Plr.UserId)
			if not DataStore.Value then return end
			if DataStore.Value.PlatesInHand <= 0 or DataStore.Value.PlatesPlaced >= 12 then return end

			local Plot = PlaceGourmetPrompt.Parent.Parent.Parent.Parent
			PlaceGourmetPlates(Plot,Character,Plr,DataStore)
		end)
	end
end

for i,CookGourmetPrompt in pairs(CS:GetTagged("CookGourmetFoodPrompt")) do
	if CookGourmetPrompt:IsA("ProximityPrompt") then
		CookGourmetPrompt.ActionText = "Interact"
		CookGourmetPrompt.ObjectText = "Cook Gourmet!"
		CookGourmetPrompt.Triggered:Connect(function(Plr)
			if CookGourmetPrompt.Parent.Parent.Parent.Parent.Parent.Info.Occupant.Value ~= Plr.Name then return end
			local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Plr.UserId)
			if not DataStore.Value then return end

			local Plot = CookGourmetPrompt.Parent.Parent.Parent.Parent.Parent
			CookGourmetFood(Plr,Plot,DataStore)
		end)
	end
end

for i,ManagerPrompt in pairs(CS:GetTagged("ManagerPrompt")) do
	if ManagerPrompt:IsA("ProximityPrompt") then
		ManagerPrompt.ActionText = "Interact"
		ManagerPrompt.ObjectText = "Manage Restaurant"
		ManagerPrompt.Triggered:Connect(function(Plr)
			if ManagerPrompt.Parent.Parent.Parent.Parent.Parent.Info.Occupant.Value ~= Plr.Name then return end
			local Character = Plr.Character
			local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Plr.UserId)
			if not DataStore.Value then return end
			local Plot = ManagerPrompt.Parent.Parent.Parent.Parent.Parent
			PlayerPlotRem:FireClient(Plr,"OpenManagerFrame")
		end)
	end
end

PlayerPlotRem.OnServerEvent:Connect(function(Plr,Action,Data)
	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Plr.UserId)
	if not DataStore then return end
	local PlayerInfo = Plr.PlayerInfo
	local PlayerStats = Plr.PlayerStats

	if Action == "ChangeBuildingColor" and Data then
		local ColorString = Data[1]
		local PartToBeColored = Data[2]
		local SectionOfPartToBeColored = Data[3]
		local Color = nil
		local PlayerPlot = nil
		if DataStore.Value.RestaurantUnlocks.CustomizationUnlocked == false then
			return
		end
		for i,Plot in pairs(workspace.Plots:GetDescendants()) do
			if Plot:IsA("StringValue") and Plot.Name == "Occupant" and Plot.Value == Plr.Name then
				PlayerPlot = Plot.Parent.Parent
			end
		end
		if not PlayerPlot or not PlayerPlot:IsA("Folder") then return end
		if ColorString == "Green" then
			ColorString = "Forest green"
		elseif ColorString == "Blue" then
			ColorString = "Deep blue"	
		elseif ColorString == "Red" then
			ColorString = "Crimson"	
		end
		for i,v in pairs(PlayerPlot:GetDescendants()) do
			if v:IsA("BasePart") and v.Name == SectionOfPartToBeColored..PartToBeColored.."Part" then
				v.BrickColor = BrickColor.new(tostring(ColorString))
				Color = v.Color
			end
		end
		if Color == nil then return end
		if SectionOfPartToBeColored == "Primary" then
			DataStore.Value.RestaurantCustomization.PrimaryBuildingColor[1] = Color.R
			DataStore.Value.RestaurantCustomization.PrimaryBuildingColor[2] = Color.G
			DataStore.Value.RestaurantCustomization.PrimaryBuildingColor[3] = Color.B
			DataStore.restaurantcustomization["PrimaryBuildingColor"].Value = Color3.new(Color.R,  Color.G,  Color.B)

		elseif SectionOfPartToBeColored == "Secondary" then
			DataStore.Value.RestaurantCustomization.SecondaryBuildingColor[1] = Color.R
			DataStore.Value.RestaurantCustomization.SecondaryBuildingColor[2] = Color.G
			DataStore.Value.RestaurantCustomization.SecondaryBuildingColor[3] = Color.B
			DataStore.restaurantcustomization["SecondaryBuildingColor"].Value = Color3.new(Color.R,  Color.G,  Color.B)
		end
		print(DataStore.Value,"New Data!")
	elseif Action == "ChangeFurnitureColor" and Data then
		local ColorString = Data[1]
		local PartToBeColored = Data[2]
		local SectionOfPartToBeColored = Data[3]
		local Color = nil
		local PlayerPlot = nil
		if DataStore.Value.RestaurantUnlocks.CustomizationUnlocked == false then
			return
		end
		for i,Plot in pairs(workspace.Plots:GetDescendants()) do
			if Plot:IsA("StringValue") and Plot.Name == "Occupant" and Plot.Value == Plr.Name then
				PlayerPlot = Plot.Parent.Parent
			end
		end
		if not PlayerPlot or not PlayerPlot:IsA("Folder") then return end

		if ColorString == "Green" then
			ColorString = "Forest green"
		elseif ColorString == "Blue" then
			ColorString = "Deep blue"	
		elseif ColorString == "Red" then
			ColorString = "Crimson"	
		end
		for i,v in pairs(PlayerPlot:GetDescendants()) do
			if v:IsA("BasePart") and v.Name == SectionOfPartToBeColored.."Part" then
				v.BrickColor = BrickColor.new(tostring(ColorString))
				Color = v.Color
			end
		end
		if Color == nil then return end
		if SectionOfPartToBeColored == "ChairColor" then
			DataStore.Value.RestaurantCustomization.ChairColor[1] = Color.R
			DataStore.Value.RestaurantCustomization.ChairColor[2] = Color.G
			DataStore.Value.RestaurantCustomization.ChairColor[3] = Color.B
			DataStore.restaurantcustomization["ChairColor"].Value = Color3.new(Color.R,  Color.G,  Color.B)

		elseif SectionOfPartToBeColored == "TableColor" then
			DataStore.Value.RestaurantCustomization.TableColor[1] = Color.R
			DataStore.Value.RestaurantCustomization.TableColor[2] = Color.G
			DataStore.Value.RestaurantCustomization.TableColor[3] = Color.B
			DataStore.restaurantcustomization["TableColor"].Value = Color3.new(Color.R,  Color.G,  Color.B)

		end
	end


	if Action == "PlayerHiring" and Data then
		if Data == "HireChef" and DataStore.Value.RestaurantUnlocks.ChefUnlocked == false and DataStore.Value.Cash >= 250_000 then
			DataStore.LeaderStatValues.Cash.Value -= 250_000
			DataStore.Value.RestaurantUnlocks.ChefUnlocked = true
			DataStore.restaurantunlocks.ChefUnlocked.Value = true
		end
	elseif Action == "UnlockCustomization" then
		if DataStore.Value.RestaurantUnlocks.CustomizationUnlocked == false and DataStore.Value.Cash >= 75_000 then
			DataStore.LeaderStatValues.Cash.Value -= 75_000
			DataStore.Value.RestaurantUnlocks.CustomizationUnlocked = true
			DataStore.restaurantunlocks.CustomizationUnlocked.Value = true
		end
	end

	if Action == "RestockStorageBox" and Plr and Data.InRestaurant == true then
		if DataStore.Value.CurrentFoodBoxes > 0 and DataStore.Value.FoodBoxesValue > 0 then
			local TotalAdded = DataStore.Value.FoodBoxesValue
			local Remainder = 0
			if Data.Percent == "100" then TotalAdded *= 1
			elseif Data.Percent == "50" then TotalAdded *= 0.5
			elseif Data.Percent == "25" then TotalAdded *= 0.25 end

			Remainder = DataStore.Value.FoodBoxesValue - math.ceil(TotalAdded)
			if TotalAdded > DataStore.Value.FoodBoxesValue then return end

			DataStore.Value.StoredRestaurantFood += math.ceil(TotalAdded)
			DataStore.playerstats.StoredRestaurantFood.Value = DataStore.Value.StoredRestaurantFood
			DataStore.LeaderStatValues.Food.Value += math.ceil(Remainder)

			DataStore.Value.FoodBoxesValue = 0
			DataStore.playerstats.FoodBoxesValue.Value = DataStore.Value.FoodBoxesValue
			DataStore.Value.CurrentFoodBoxes = 0
			DataStore.playerstats.CurrentFoodBoxes.Value = DataStore.Value.CurrentFoodBoxes

			local PlrsFoodBoxFolder = PlayerFoodBoxes:WaitForChild(Plr.UserId):FindFirstChild("FoodBoxes")
			if PlrsFoodBoxFolder then PlrsFoodBoxFolder:Destroy() end
			PlayerPlotRem:FireClient(Plr,"CloseStorageBoxRestockMenu")
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
			PlayerPlotRem:FireClient(Plr,"CloseStorageBoxRestockMenu")
		end
	end
end)

local function GetAvailableTable(Plot, GroupSize)
	local Furniture = Plot.RestaurantBuild:FindFirstChild("Furniture")
	if not Furniture then return nil end

	local ValidTables = {}
	for _, tbl in pairs(Furniture:GetChildren()) do
		local IsValidSize = false
		if GroupSize <= 2 then 
			if (string.find(tbl.Name, "TwoMan") or string.find(tbl.Name, "FourMan")) then IsValidSize = true end
		elseif GroupSize > 2 and string.find(tbl.Name, "FourMan") then
			IsValidSize = true
		end

		if IsValidSize then
			local isOccupied = tbl:GetAttribute("Occupied")
			if not isOccupied then table.insert(ValidTables, tbl) end
		end
	end

	if #ValidTables > 0 then
		local chosen = ValidTables[math.random(1, #ValidTables)]
		chosen:SetAttribute("Occupied", true) 
		return chosen
	end
	return nil
end

local function GetTableFromSeat(seat)
	local current = seat
	while current and current.Parent do
		if current.Parent.Name == "Furniture" then return current end
		current = current.Parent
	end
	return seat
end

local function GetAislePosition(targetSeat, hrp)
	if not targetSeat or not hrp then return Vector3.zero end
	-- Move 3.5 studs backwards from the chair (into the walking aisle)
	local rawPos = (targetSeat.CFrame * CFrame.new(0, 0, 3.5)).Position
	-- FORCE the Y value to the floor (NPC's feet)
	return Vector3.new(rawPos.X, hrp.Position.Y, rawPos.Z)
end

local function GetTableAislePosition(targetTable, hrp)
	if not targetTable or not hrp then return Vector3.zero end
	-- Find any seat to act as our aisle reference
	local firstSeat = targetTable:FindFirstChildWhichIsA("Seat", true)
	if firstSeat then
		local rawPos = (firstSeat.CFrame * CFrame.new(0, 0, 4)).Position
		return Vector3.new(rawPos.X, hrp.Position.Y, rawPos.Z)
	end
	-- Fallback if no seat is found
	local rawPos = (targetTable:GetPivot() * CFrame.new(4.5, 0, 0)).Position
	return Vector3.new(rawPos.X, hrp.Position.Y, rawPos.Z)
end


-- [[ REBUILT: Lag-Free Chef State Machine! ]]
local function ChefHandling(deltaTime, Chef, ChefData, UserId)
	if not Chef or not Chef.Parent then
		if NPCHandler.ActiveRestaurants[UserId] and NPCHandler.ActiveRestaurants[UserId].Chefs then
			NPCHandler.ActiveRestaurants[UserId].Chefs[Chef] = nil
		end
		return
	end

	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, ChefData.Plr.UserId)
	if not DataStore or not DataStore.Value then return end

	local Plot = ChefData.TargetPlot
	local StoredFood = DataStore.Value.StoredRestaurantFood
	local Pots = Plot.RestaurantBuild.Kitchen.Pots
	local hrp = Chef.PrimaryPart
	if not hrp then return end

	-- [[ Visibility / Collisions ]]

	if DataStore.Value.RestaurantUnlocks.ChefUnlocked == true and hrp.Anchored == true then
		hrp.Anchored = false
		hrp.CanCollide = true
		hrp.CanTouch = false
		for _, v in pairs(Chef:GetDescendants()) do
			if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
				v.Transparency = 0
				v.CanTouch = false -- Stop accidental sitting

				if v.Name == "Torso" or v.Name == "UpperTorso" or v.Name == "LowerTorso" or v.Name == "Head" then
					v.CanCollide = true
				else
					v.CanCollide = false
				end
			elseif v:IsA("Decal") then v.Transparency = 0
			elseif v:IsA("BillboardGui") then v.Enabled = true end
		end
	elseif DataStore.Value.RestaurantUnlocks.ChefUnlocked == false and hrp.Anchored == false then
		hrp.Anchored = true
		for _, v in pairs(Chef:GetDescendants()) do
			if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
				v.Transparency = 1
				v.CanCollide = false
			elseif v:IsA("Decal") then v.Transparency = 1
			elseif v:IsA("BillboardGui") then v.Enabled = false end
		end
	end



	if DataStore.Value.RestaurantUnlocks.ChefUnlocked == false then return end

	local FlatIdlePos = Vector3.new(ChefData.IdlePosition.X, hrp.Position.Y, ChefData.IdlePosition.Z)
	local FlatCookPos = Vector3.new(ChefData.CookingPosition.X, hrp.Position.Y, ChefData.CookingPosition.Z)

	if ChefData.State == "Idle" then
		local DistToIdle = (hrp.Position - FlatIdlePos).Magnitude
		ChefData.StuckTimer = (ChefData.StuckTimer or 0) + deltaTime
		if DistToIdle > 2 or ChefData.StuckTimer >= 4 then
			NPCHandler.Go(Chef, FlatIdlePos, ChefData.Plr)
			if DataStore.Value.PlatesPlaced < 12 and StoredFood >= 15 and DataStore.Value.PlatesInHand <= 0 then
				ChefData.State = "GoingToStove"
			elseif DataStore.Value.PlatesPlaced < 12 and StoredFood >= 15 and DataStore.Value.PlatesInHand > 0 then
				PlaceGourmetPlates(Plot, Chef, ChefData.Plr, DataStore)
			else
				ChefData.State = "Idle"	
			end
		else
			NPCHandler.Stop(Chef, ChefData.Plr)
			ChefData.StuckTimer = 0 

			if DistToIdle > 1.5 then hrp.CFrame = CFrame.new(FlatIdlePos) end 

			if DataStore.Value.PlatesPlaced < 12 and StoredFood >= 15 and DataStore.Value.PlatesInHand <= 0 then
				ChefData.State = "GoingToStove"
			elseif DataStore.Value.PlatesPlaced < 12 and StoredFood >= 15 and DataStore.Value.PlatesInHand > 0 then
				PlaceGourmetPlates(Plot, Chef, ChefData.Plr, DataStore)
			else
				ChefData.State = "Idle"	
			end
		end

	elseif ChefData.State == "GoingToStove" then
		-- [[ FIX: Compare Y=0 to Y=0 ]]
		local DistToStove = (hrp.Position - FlatCookPos).Magnitude
		ChefData.StuckTimer = (ChefData.StuckTimer or 0) + deltaTime

		if DistToStove > 1.5 or ChefData.StuckTimer >= 4 then
			print("Chef Currently Cooking!")
			NPCHandler.Go(Chef, FlatCookPos, ChefData.Plr)
			ChefData.State = "CurrentlyCooking"
			ChefData.ActionTimer = 0
		else
			NPCHandler.Stop(Chef, ChefData.Plr)

			ChefData.StuckTimer = 0

			if DistToStove > 1.5 then hrp.CFrame = CFrame.new(FlatCookPos) end 

			if StoredFood < 15 then
				ChefData.State = "Idle"
				return
			end

			ChefData.State = "CurrentlyCooking"
			ChefData.ActionTimer = 0
		end

	elseif ChefData.State == "CurrentlyCooking" then
		-- [[ FIX: Compare Y=0 to Y=0 ]]
		local DistToStove = (hrp.Position - FlatCookPos).Magnitude
		if DistToStove > 1.25 then
			NPCHandler.Go(Chef, FlatCookPos, ChefData.Plr)
			return
		end

		ChefData.ActionTimer = (ChefData.ActionTimer or 0) + deltaTime
		if ChefData.ActionTimer >= 0.25 then
			ChefData.ActionTimer = 0

			if DataStore.Value.PlatesInHand < 2 then
				for _, Pot in pairs(Pots:GetChildren()) do
					if Pot:IsA("Model") and Pot:GetAttribute("CookingState") == "Cooked" then
						local CookingTimer = Pot:FindFirstChild("CookingTime")
						CollectCookedGourmetFood(ChefData.Plr, Pot, Chef, Plot, DataStore, CookingTimer)
						return 
					end
				end
			end

			if DataStore.Value.ActivePorts < 12 and StoredFood >= 15 and  DataStore.Value.PlatesInHand < 2 then
				CookGourmetFood(ChefData.Plr, Plot, DataStore)
				return
			end

			if DataStore.Value.PlatesInHand >= 2 or (DataStore.Value.PlatesInHand > 0 and DataStore.Value.ActivePorts == 0) then
				ChefData.State = "PlacingPlates"
			end
		end

	elseif ChefData.State == "PlacingPlates" then
		local DistToIdle = (hrp.Position - FlatIdlePos).Magnitude
		ChefData.StuckTimer = (ChefData.StuckTimer or 0) + deltaTime
		if DistToIdle > 1.5 or ChefData.StuckTimer >= 4 then
			NPCHandler.Go(Chef, FlatIdlePos, ChefData.Plr)
		else
			NPCHandler.Stop(Chef, ChefData.Plr)
			ChefData.StuckTimer = 0

			if DistToIdle > 1.5 then hrp.CFrame = CFrame.new(FlatIdlePos) end 

			ChefData.ActionTimer = (ChefData.ActionTimer or 0) + deltaTime
			if ChefData.ActionTimer >= 0.25 then
				ChefData.ActionTimer = 0
				if DataStore.Value.PlatesInHand > 0 and DataStore.Value.PlatesPlaced < 12 then
					print("Chef Placing Plates!")
					PlaceGourmetPlates(Plot, Chef, ChefData.Plr, DataStore)
				else
					ChefData.State = "Idle"
				end
			end
		end
	end
end

local function HostHandling(deltaTime, HostModel, HostData, UserId)
	if not HostModel or not HostModel.Parent then
		if NPCHandler.ActiveRestaurants[UserId] and NPCHandler.ActiveRestaurants[UserId].Hosts then
			NPCHandler.ActiveRestaurants[UserId].Hosts[HostModel] = nil
		end
		return
	end

	local hrp = HostModel.HumanoidRootPart

	if HostData.State == "Idle" then
		local DistToIdle = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(HostData.IdlePosition.X, 0, HostData.IdlePosition.Z)).Magnitude
		if DistToIdle > 3 then
			NPCHandler.Go(HostModel, HostData.IdlePosition, HostData.Plr)
		else
			local PathFolder = HostData.TargetPlot:FindFirstChild("CustomerPath")
			if PathFolder and PathFolder:FindFirstChild("10") then
				local Node10 = PathFolder:FindFirstChild("10")
				hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(Node10.Position.X, hrp.Position.Y, Node10.Position.Z))
			end
		end

	elseif HostData.State == "LeadingToTable" then
		if not HostData.TargetTable then 
			HostData.State = "Returning" 
			return 
		end

		-- [[ SURE-FIRE FIX: Use the Floor Helper ]]
		local StandPos = GetTableAislePosition(HostData.TargetTable, hrp)

		NPCHandler.Go(HostModel, StandPos, HostData.Plr)

		local Dist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(StandPos.X, 0, StandPos.Z)).Magnitude
		HostData.StuckTimer = (HostData.StuckTimer or 0) + deltaTime

		if Dist < 4 or HostData.StuckTimer > 8 then
			NPCHandler.Stop(HostModel, HostData.Plr)
			HostData.StuckTimer = 0 

			if HostData.TargetGroupData then
				HostData.TargetGroupData.State = "Seating"
			end

			if not HostData.WaitAtTableTimer then HostData.WaitAtTableTimer = 3 end
			HostData.WaitAtTableTimer -= deltaTime

			if HostData.WaitAtTableTimer <= 0 then
				HostData.TargetTable = nil
				HostData.TargetGroupData = nil
				HostData.State = "Returning"
				HostData.WaitAtTableTimer = 3 
			end
		end

	elseif HostData.State == "Returning" then
		NPCHandler.Go(HostModel, HostData.IdlePosition, HostData.Plr)

		local Dist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(HostData.IdlePosition.X, 0, HostData.IdlePosition.Z)).Magnitude
		if Dist < 4 then
			NPCHandler.Stop(HostModel, HostData.Plr)
			HostData.State = "Idle"
		end
	end
end

local function WaiterHandling(deltaTime, Waiter, WaiterData, UserId)
	if not Waiter or not Waiter.Parent then
		if NPCHandler.ActiveRestaurants[UserId] and NPCHandler.ActiveRestaurants[UserId].Waiters then
			NPCHandler.ActiveRestaurants[UserId].Waiters[Waiter] = nil
		end
		return
	end

	local Plot = WaiterData.TargetPlot
	local RestaurantData = NPCHandler.ActiveRestaurants[UserId]
	local hrp = Waiter.HumanoidRootPart
	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, WaiterData.Plr.UserId)

	if WaiterData.State == "Idle" then
		-- Reset stuck timer completely
		WaiterData.StuckTimer = 0

		local FoodSpots = Plot.RestaurantBuild.Kitchen:FindFirstChild("FoodSpots")
		local ReadyPlates = {}
		if FoodSpots then
			for _, spot in pairs(FoodSpots:GetChildren()) do
				if spot:IsA("BasePart") then
					local plate = spot:FindFirstChildWhichIsA("Model")
					if plate and not plate:GetAttribute("ClaimedByWaiter") then
						table.insert(ReadyPlates, plate)
						if #ReadyPlates == 2 then break end 
					end
				end
			end
		end

		local HungryCustomers = {}
		if RestaurantData.Customers then
			for custModel, custData in pairs(RestaurantData.Customers) do
				if custData.State == "WaitingForFood" and not custData.BeingServed then
					table.insert(HungryCustomers, {Model = custModel, Data = custData})
				end
			end
		end

		if #HungryCustomers > 0 and #ReadyPlates > 0 then
			local PlatesToTake = math.min(#HungryCustomers, #ReadyPlates, 2)
			WaiterData.HeldPlates = {}
			WaiterData.TargetCustomers = {}

			for i = 1, PlatesToTake do
				local plate = ReadyPlates[i]
				plate:SetAttribute("ClaimedByWaiter", true)
				table.insert(WaiterData.HeldPlates, plate)

				local cust = HungryCustomers[i]
				cust.Data.BeingServed = true
				table.insert(WaiterData.TargetCustomers, cust)
			end

			WaiterData.State = "GoingToKitchen"
			local WorkerSpots = Plot.RestaurantBuild.Workers.WorkerSpots
			local TargetKitchenSpots = {}
			for _, v in pairs(WorkerSpots:GetChildren()) do
				if string.find(v.Name, "WaiterKitchenSpot") then
					table.insert(TargetKitchenSpots, v)
				end
			end

			-- [[ FIX: ONLY walk to the designated Waiter spots. NO plate fallback! ]]
			if #TargetKitchenSpots > 0 then
				local ChosenKitchenSpot = TargetKitchenSpots[math.random(1, #TargetKitchenSpots)]
				WaiterData.TargetKitchenSpot = ChosenKitchenSpot.Position
				NPCHandler.Go(Waiter, WaiterData.TargetKitchenSpot, WaiterData.Plr)
			else
				-- If your spots are missing, drop the plates so it doesn't break
				for _, plate in ipairs(WaiterData.HeldPlates) do
					plate:SetAttribute("ClaimedByWaiter", nil)
				end
				for _, cust in ipairs(WaiterData.TargetCustomers) do
					cust.Data.BeingServed = false
				end
				WaiterData.State = "Idle"
				return
			end
		else
			local DistToIdle = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(WaiterData.IdlePosition.X, 0, WaiterData.IdlePosition.Z)).Magnitude
			if DistToIdle > 1.5 then
				NPCHandler.Go(Waiter, WaiterData.IdlePosition, WaiterData.Plr)
			else
				NPCHandler.Stop(Waiter, WaiterData.Plr)
				hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(WaiterData.IdlePosition.X, hrp.Position.Y, WaiterData.IdlePosition.Z))
			end
		end

	elseif WaiterData.State == "GoingToKitchen" then
		local hasValidPlate = false
		for _, plate in ipairs(WaiterData.HeldPlates) do
			if plate and plate.Parent then hasValidPlate = true break end
		end

		if not hasValidPlate then
			for _, cust in ipairs(WaiterData.TargetCustomers) do
				cust.Data.BeingServed = false
			end
			WaiterData.State = "Idle"
			return
		end

		-- Flatten the Kitchen Spot coordinate
		local FlatKitchenPos = Vector3.new(WaiterData.TargetKitchenSpot.X, hrp.Position.Y, WaiterData.TargetKitchenSpot.Z)
		local Dist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(FlatKitchenPos.X, 0, FlatKitchenPos.Z)).Magnitude

		WaiterData.StuckTimer = (WaiterData.StuckTimer or 0) + deltaTime

		-- [[ FIX: Tight distance check (1.5) so they stop exactly on your marker! ]]
		if Dist < 1.5 or WaiterData.StuckTimer > 5 then
			NPCHandler.Stop(Waiter, WaiterData.Plr)
			WaiterData.StuckTimer = 0

			-- Force them to the spot if they got stuck
			if Dist > 1.5 then hrp.CFrame = CFrame.new(FlatKitchenPos) end 

			for i, GourmetPlate in ipairs(WaiterData.HeldPlates) do
				if GourmetPlate.Parent and GourmetPlate.Parent:FindFirstChild("Occupied") then
					GourmetPlate.Parent.Occupied.Value = false
				end

				GourmetPlate.Parent = Waiter
				if GourmetPlate:IsA("BasePart") then
					GourmetPlate.Anchored = false
					GourmetPlate.Massless = true
					GourmetPlate.CanCollide = false
				end
				for _, v in pairs(GourmetPlate:GetDescendants()) do
					if v:IsA("BasePart") then
						v.Anchored = false
						v.Massless = true
						v.CanCollide = false
					end
				end

				local Hand = (i == 1) and Waiter:FindFirstChild("RightHand") or Waiter:FindFirstChild("LeftHand")
				GourmetPlate:PivotTo(Hand.CFrame * CFrame.new(0, -0.5, 0))

				local Weld = Instance.new("Weld")
				Weld.Name = "WaiterHandWeld"
				Weld.Part0 = Hand
				Weld.Part1 = GourmetPlate.PrimaryPart
				Weld.C0 = CFrame.new(0,0,-0.55)
				Weld.C1 = CFrame.Angles(math.rad(90),0,0)
				Weld.Parent = GourmetPlate.PrimaryPart

				if WaiterData.Animations then
					if i == 1 and WaiterData.Animations.RHandHeldUp then 			
						if DataStore.Value then DataStore.Value.PlatesPlaced -= 1 end
						WaiterData.Animations.RHandHeldUp:Play()
					end
					if i == 2 and WaiterData.Animations.LHandHeldUp then 
						if DataStore.Value then DataStore.Value.PlatesPlaced -= 1 end
						WaiterData.Animations.LHandHeldUp:Play() 
					end
				end
			end

			WaiterData.State = "DeliveringFood"

			if WaiterData.TargetCustomers[1] and WaiterData.TargetCustomers[1].Data.TargetSeat then
				local SafeApproachPos = GetAislePosition(WaiterData.TargetCustomers[1].Data.TargetSeat, hrp)
				NPCHandler.Go(Waiter, SafeApproachPos, WaiterData.Plr)
			end
		else
			-- Ensure they keep walking to the spot if they haven't arrived
			NPCHandler.Go(Waiter, FlatKitchenPos, WaiterData.Plr)
		end

	elseif WaiterData.State == "DeliveringFood" then
		if not WaiterData.TargetCustomers or #WaiterData.TargetCustomers == 0 then
			for _, plate in ipairs(WaiterData.HeldPlates) do 
				if plate then plate:Destroy() end 
			end
			WaiterData.HeldPlates = {}
			WaiterData.State = "Idle"
			if WaiterData.Animations then
				if WaiterData.Animations.RHandHeldUp then WaiterData.Animations.RHandHeldUp:Stop() end
				if WaiterData.Animations.LHandHeldUp then WaiterData.Animations.LHandHeldUp:Stop() end
			end
			return
		end

		local CurrentCust = WaiterData.TargetCustomers[1]

		if not CurrentCust.Model or not CurrentCust.Model.Parent then
			table.remove(WaiterData.TargetCustomers, 1)
			local plateToDrop = table.remove(WaiterData.HeldPlates,1)
			if plateToDrop then plateToDrop:Destroy() end

			if #WaiterData.TargetCustomers > 0 then
				local NextSafePos = GetAislePosition(WaiterData.TargetCustomers[1].Data.TargetSeat, hrp)
				NPCHandler.Go(Waiter, NextSafePos, WaiterData.Plr)
			else
				WaiterData.State = "Idle"
				if WaiterData.Animations then
					if WaiterData.Animations.RHandHeldUp then WaiterData.Animations.RHandHeldUp:Stop() end
					if WaiterData.Animations.LHandHeldUp then WaiterData.Animations.LHandHeldUp:Stop() end
				end
			end
			return
		end

		local SafeApproachPos = GetAislePosition(CurrentCust.Data.TargetSeat, hrp)
		local Dist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(SafeApproachPos.X, 0, SafeApproachPos.Z)).Magnitude

		WaiterData.StuckTimer = (WaiterData.StuckTimer or 0) + deltaTime

		-- Use a snug distance check here so they walk directly up to the table
		if Dist < 2.5 or WaiterData.StuckTimer > 8 then
			NPCHandler.Stop(Waiter, WaiterData.Plr)
			WaiterData.StuckTimer = 0

			if Dist > 2.5 then hrp.CFrame = CFrame.new(Vector3.new(SafeApproachPos.X, hrp.Position.Y, SafeApproachPos.Z)) end 

			local Plate = table.remove(WaiterData.HeldPlates, 1)
			table.remove(WaiterData.TargetCustomers, 1)

			if Plate and Plate.PrimaryPart then
				local Weld = Plate.PrimaryPart:FindFirstChild("WaiterHandWeld")
				if Weld then Weld:Destroy() end

				if Plate:FindFirstChild("TableTop") then
					Plate:FindFirstChild("TableTop"):Destroy()
				end

				local TargetSeat = CurrentCust.Data.TargetSeat
				Plate.Parent = TargetSeat.Parent
				local PlateSpot = TargetSeat.Parent:FindFirstChild("FoodSpot")
				if PlateSpot then
					Plate.PrimaryPart.Anchored = true
					Plate:PivotTo(PlateSpot.CFrame * CFrame.new(0,-0.075,0))
					local GourmetFoodCost = 10
					if DataStore.Value.RestaurantSkillTree["5GourmetFoodPerSale"].Unlocked == true then
						GourmetFoodCost = 5
					end
					if DataStore.Value.RestaurantSkillTree["2GourmetFoodPerSale"].Unlocked == true then
						GourmetFoodCost = 2
					end
					if DataStore.Value["Gourmet Food"] >= GourmetFoodCost then
						DataStore.Value["Gourmet Food"] -= GourmetFoodCost
						DataStore.playerstats["Gourmet Food"].Value = DataStore.Value["Gourmet Food"]
					end

				end
				CurrentCust.Data.MyPlate = Plate
			end

			CurrentCust.Data.State = "Eating"
			CurrentCust.Data.WaitTimer = math.random(15, 20)

			if #WaiterData.TargetCustomers > 0 and #WaiterData.HeldPlates > 0 then
				local NextSafePos = GetAislePosition(WaiterData.TargetCustomers[1].Data.TargetSeat, hrp)
				NPCHandler.Go(Waiter, NextSafePos, WaiterData.Plr)
			else
				if WaiterData.Animations then
					if WaiterData.Animations.RHandHeldUp then WaiterData.Animations.RHandHeldUp:Stop() end
					if WaiterData.Animations.LHandHeldUp then WaiterData.Animations.LHandHeldUp:Stop() end
				end
				WaiterData.State = "Idle" 
			end
		else
			NPCHandler.Go(Waiter, SafeApproachPos, WaiterData.Plr)
		end
	end
end

local function CustomerHandling(deltaTime, Customer, CustomerData, UserId)
	if not Customer or not Customer.Parent then
		if NPCHandler.ActiveRestaurants[UserId] and NPCHandler.ActiveRestaurants[UserId].Customers then
			NPCHandler.ActiveRestaurants[UserId].Customers[Customer] = nil
		end
		return
	end

	if Customer:GetAttribute("State") ~= CustomerData.State then
		Customer:SetAttribute("State", CustomerData.State)
	end

	local Player = CustomerData.Plr
	local humanoid = Customer.Humanoid
	local hrp = Customer.HumanoidRootPart
	local Plot = CustomerData.TargetPlot
	local PathFolder = Plot:FindFirstChild("CustomerPath") 
	local GroupData = NPCHandler.ActiveRestaurants[UserId].Groups[CustomerData.GroupId]
	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
	local Upgrades = DataStore.Value.Upgrades
	local RestaurantSkillTree = DataStore.Value.RestaurantSkillTree
	local FarmersMarketSkillTree = DataStore.Value.FarmersMarketSkillTree

	local PlayerInfo = Player:FindFirstChild("PlayerInfo")
	if not PlayerInfo then
		CustomerData.State = "Leaving"
		return 
	end

	if not Plot or Plot.Info.Occupant.Value == "Vacant" then
		CustomerData.State = "Leaving"
	end

	if CustomerData.State == "WalkingToHost" then
		if not PathFolder then return end

		local HostQueue = NPCHandler.ActiveRestaurants[UserId].HostQueue or {}
		local LineIndex = table.find(HostQueue, CustomerData.GroupId) or 1

		local TargetNodeNum = math.max(1, 12 - LineIndex)
		local TargetNode = PathFolder:FindFirstChild(tostring(TargetNodeNum))

		if TargetNode then
			local Dest = TargetNode.Position + CustomerData.GroupOffset
			local FlatDest = Vector3.new(Dest.X, hrp.Position.Y, Dest.Z)

			local dist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(Dest.X, 0, Dest.Z)).Magnitude

			if dist < 3.5 then
				NPCHandler.Stop(Customer, CustomerData.Plr)
				if LineIndex == 1 then
					CustomerData.State = "AtHost"
				else
					local NextNode = PathFolder:FindFirstChild(tostring(TargetNodeNum + 1))
					if NextNode then
						hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(NextNode.Position.X, hrp.Position.Y, NextNode.Position.Z))
					end
				end
			else
				-- [[ FIX: ONLY tell them to Go if they aren't already there! ]]
				NPCHandler.Go(Customer, FlatDest, CustomerData.Plr)
			end
		end

	elseif CustomerData.State == "AtHost" then
		if CustomerData.IsLeader and not GroupData.HasOrdered then
			local RestaurantData = NPCHandler.ActiveRestaurants[UserId]
			local MyHost, HostData = nil, nil

			if RestaurantData.Hosts then
				for hModel, hData in pairs(RestaurantData.Hosts) do
					MyHost, HostData = hModel, hData
					break 
				end
			end

			if HostData and HostData.State ~= "Idle" then return end

			if not GroupData.DiscussionTimer then
				GroupData.DiscussionTimer = math.random(3, 5)
			end

			GroupData.DiscussionTimer -= deltaTime

			if GroupData.DiscussionTimer <= 0 then
				GroupData.HasOrdered = true

				local HostQueue = NPCHandler.ActiveRestaurants[UserId].HostQueue
				local queuePos = table.find(HostQueue, CustomerData.GroupId)
				if queuePos then
					table.remove(HostQueue, queuePos)
				end

				local Decision = RandomFromWeightedTable(CustomerChances)

				if Decision == "TakeOut" then
					GroupData.State = "Leaving"
					print("Customer Takeout! ",CustomerData)
					local CashPerGourmet = Upgrades.CashPerGourmetFood
					local MultiplyCashPerGourmet = Upgrades.MultiplyCashPerGourmetFood
					local TotalPayment = (CashPerGourmet * MultiplyCashPerGourmet)

					local ChaChingMoney = RS:WaitForChild("Assets").SFX.ChaChing:Clone()
					ChaChingMoney.Parent = hrp
					ChaChingMoney.Volume = 0.4
					ChaChingMoney:Play()
					Debris:AddItem(ChaChingMoney,0.9)

					if FarmersMarketSkillTree["x1.5Cash"].Unlocked == true then
						TotalPayment *= 1.5
					end
					if FarmersMarketSkillTree["x3Cash"].Unlocked == true then
						TotalPayment *= 3
					end
					if RestaurantSkillTree["x5Cash"].Unlocked == true then
						TotalPayment *= 5
					end
					if Player:GetAttribute("x2Cash") == true then
						TotalPayment *= 2
					end

					TotalPayment *= PlayerInfo.CashMultiplierEventValue.Value

					DataStore.LeaderStatValues.Cash.Value += TotalPayment
					PlayerPlotRem:FireAllClients("MoneySplash",{Customer,false})

					local IncDecDisplay = RS:WaitForChild("UIAssets").IncDecCashDisplay:Clone()
					IncDecDisplay.Parent = Customer.HumanoidRootPart
					IncDecDisplay.Icon.Increment.Text = "+"..FrmtNum(TotalPayment,2)
					IncDecDisplay.StudsOffset = Vector3.new(0,0,0)
					TS:Create(IncDecDisplay,TweenInfo.new(4.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{Brightness = 5,StudsOffset = Vector3.new(0,7.5,0)}):Play()
					TS:Create(IncDecDisplay.Icon.Increment,TweenInfo.new(5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{TextTransparency = 1}):Play()
					Debris:AddItem(IncDecDisplay,3.5)

				else
					local Table = GetAvailableTable(Plot, GroupData.Size)
					if Table then
						GroupData.TargetTable = Table
						if HostData then
							HostData.TargetTable = Table
							HostData.TargetGroupData = GroupData
							HostData.State = "LeadingToTable"
							GroupData.State = "WaitingForHostToLead"
						else
							GroupData.State = "Seating" 
						end
					else
						GroupData.State = "Leaving"
					end
				end
			end
		end

		if GroupData.State == "Leaving" then
			CustomerData.State = "Leaving"
		elseif GroupData.State == "WaitingForHostToLead" then
			CustomerData.State = "WaitingForHostToLead"
		elseif GroupData.State == "Seating" then
			CustomerData.State = "WalkingToTable"
		end

	elseif CustomerData.State == "WaitingForHostToLead" then
		if GroupData.State == "Seating" then
			CustomerData.State = "WalkingToTable"
		end

	elseif CustomerData.State == "WalkingToTable" then
		local TargetTable = GroupData.TargetTable
		if not TargetTable then CustomerData.State = "Leaving" return end

		if not CustomerData.TargetSeat then
			for _, seat in pairs(TargetTable:GetDescendants()) do
				if seat:IsA("Seat") and seat.Occupant == nil and not seat:GetAttribute("ClaimedBy") then
					seat:SetAttribute("ClaimedBy", Customer.Name)
					CustomerData.TargetSeat = seat
					break
				end
			end
		end

		if CustomerData.TargetSeat then
			local SafeApproachPos = GetAislePosition(CustomerData.TargetSeat, hrp)

			local DistToApproach = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(SafeApproachPos.X, 0, SafeApproachPos.Z)).Magnitude
			local DistToSeat = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(CustomerData.TargetSeat.Position.X, 0, CustomerData.TargetSeat.Position.Z)).Magnitude

			if DistToApproach > 5 then
				NPCHandler.Go(Customer, SafeApproachPos, CustomerData.Plr)
			else
				humanoid:MoveTo(CustomerData.TargetSeat.Position)
			end

			if DistToSeat < 3 then
				-- [[ FIX 2: Do NOT turn CanTouch back on! This stops accidental seating! ]]
				NPCHandler.Stop(Customer, CustomerData.Plr)

				-- Teleport them cleanly to the seat position before forcing the sit
				hrp.CFrame = CustomerData.TargetSeat.CFrame + Vector3.new(0, 1.5, 0)

				CustomerData.TargetSeat:Sit(humanoid)
				CustomerData.State = "WaitingForFood"
			end
		else
			CustomerData.State = "Leaving"
		end

	elseif CustomerData.State == "WaitingForFood" then
		-- Handled by waiter!

	elseif CustomerData.State == "Eating" then
		CustomerData.WaitTimer = CustomerData.WaitTimer - deltaTime

		if CustomerData.WaitTimer <= 0 then
			local CashPerGourmet = Upgrades.CashPerGourmetFood
			local MultiplyCashPerGourmet = Upgrades.MultiplyCashPerGourmetFood
			local TotalPayment = (CashPerGourmet * MultiplyCashPerGourmet)

			local ChaChingMoney = RS:WaitForChild("Assets").SFX.ChaChing:Clone()
			ChaChingMoney.Parent = hrp
			ChaChingMoney.Volume = 0.4
			ChaChingMoney:Play()
			Debris:AddItem(ChaChingMoney,0.9)

			if FarmersMarketSkillTree["x1.5Cash"].Unlocked == true then
				TotalPayment *= 1.5
			end
			if FarmersMarketSkillTree["x3Cash"].Unlocked == true then
				TotalPayment *= 3
			end
			if RestaurantSkillTree["x5Cash"].Unlocked == true then
				TotalPayment *= 5
			end
			if Player:GetAttribute("x2Cash") == true then
				TotalPayment *= 2
			end

			TotalPayment *= PlayerInfo.CashMultiplierEventValue.Value

			DataStore.LeaderStatValues.Cash.Value += TotalPayment
			PlayerPlotRem:FireAllClients("MoneySplash",{Customer,false})

			local IncDecDisplay = RS:WaitForChild("UIAssets").IncDecCashDisplay:Clone()
			IncDecDisplay.Parent = Customer.HumanoidRootPart
			IncDecDisplay.Icon.Increment.Text = "+"..FrmtNum(TotalPayment,2)
			IncDecDisplay.StudsOffset = Vector3.new(0,0,0)
			TS:Create(IncDecDisplay,TweenInfo.new(4.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{Brightness = 5,StudsOffset = Vector3.new(0,7.5,0)}):Play()
			TS:Create(IncDecDisplay.Icon.Increment,TweenInfo.new(5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{TextTransparency = 1}):Play()
			Debris:AddItem(IncDecDisplay,3.5)


			if CustomerData.MyPlate then
				CustomerData.MyPlate:Destroy()
			end

			if GroupData.TargetTable then
				GroupData.TargetTable:SetAttribute("Occupied", false)
			end

			if CustomerData.TargetSeat then
				local seat = CustomerData.TargetSeat
				seat:SetAttribute("ClaimedBy", nil)
				for i,v in pairs(seat.Parent:GetChildren()) do
					if v:IsA("Model") and string.find(v.Name,"GourmetPlate") then
						v:Destroy()
					end
				end

				seat.Disabled = true
				if seat:FindFirstChildWhichIsA("Weld") then
					seat:FindFirstChildWhichIsA("Weld"):Destroy()
				end

				-- [[ FIX 3: Increased the timer to 3 seconds to ensure they walk away before the chair resets ]]
				task.delay(1, function()
					if seat then
						seat.Disabled = false
					end
				end)

				hrp.CFrame = seat.CFrame * CFrame.new(0, 1.5, 3)
				hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) 
			end
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
			humanoid.Sit = false
			humanoid.Jump = true 

			CustomerData.StuckTimer = 0
			CustomerData.State = "Leaving"
		end

	elseif CustomerData.State == "Leaving" then
		if not PathFolder then 
			CustomerData.State = "Despawning" 
			return 
		end

		local ExitNode = PathFolder:FindFirstChild("1")
		if ExitNode then
			local Dest = ExitNode.Position + CustomerData.GroupOffset
			local FlatDest = Vector3.new(Dest.X, hrp.Position.Y, Dest.Z)
			local Distance = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(Dest.X, 0, Dest.Z)).Magnitude

			CustomerData.StuckTimer = (CustomerData.StuckTimer or 0) + deltaTime

			-- If they reach the door OR they have been stuck trying to leave for over 15 seconds
			if Distance < 4 or CustomerData.StuckTimer > 15 then
				NPCHandler.Stop(Customer, CustomerData.Plr)
				CustomerData.StuckTimer = 0
				CustomerData.State = "Despawning"
			else
				NPCHandler.Go(Customer, FlatDest, CustomerData.Plr)
			end
		else
			CustomerData.State = "Despawning"
		end

	elseif CustomerData.State == "Despawning" then
		NPCHandler.CleanupNPC(Customer, CustomerData.Plr)

		if NPCHandler.ActiveRestaurants[UserId] and NPCHandler.ActiveRestaurants[UserId].Customers then
			NPCHandler.ActiveRestaurants[UserId].Customers[Customer] = nil
		end

		for _, v in pairs(Customer:GetDescendants()) do
			if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
				TS:Create(v, TweenInfo.new(0.75), {Transparency = 1}):Play()
			elseif v:IsA("Decal") then
				v.Transparency = 1
			end
		end	
		task.delay(0.5, function() 
			if Customer then Customer:Destroy() end
		end)
	end
end

local function SpawnCustomerGroup(Player, UserId, RestaurantData)
	local ChosenPlot = RestaurantData.Plot
	if not ChosenPlot then return end

	local CustomerPath = ChosenPlot:FindFirstChild("CustomerPath")
	local CustomersFolder = ChosenPlot:FindFirstChild("Customers")
	if not CustomerPath then return end

	local StartNodePart = CustomerPath:FindFirstChild("1")
	if not StartNodePart then return end

	-- [[ LIMITE DE NPCs ATIVOS ]]
	local currentCount = 0
	for _ in pairs(NPCHandler.ActiveRestaurants[UserId].Customers or {}) do
		currentCount += 1
	end
	local MAX_NPCS_TOTAL = 8

	-- [[ GROUP LOGIC ]]
	local GroupSize = math.random(1, 4)

	-- Limita o grupo baseado no espaço disponível
	GroupSize = math.min(GroupSize, math.max(1, MAX_NPCS_TOTAL - currentCount))
	if GroupSize <= 0 then return end -- sem espaço, cancela o spawn

	local GroupId = "Group_" .. math.random(100000, 999999)

	if not NPCHandler.ActiveRestaurants[UserId].Groups then
		NPCHandler.ActiveRestaurants[UserId].Groups = {}
	end

	if not NPCHandler.ActiveRestaurants[UserId].HostQueue then
		NPCHandler.ActiveRestaurants[UserId].HostQueue = {}
	end

	NPCHandler.ActiveRestaurants[UserId].Groups[GroupId] = {
		Size = GroupSize,
		Members = {},
		TargetTable = nil,
		HasOrdered = false
	}
	table.insert(NPCHandler.ActiveRestaurants[UserId].HostQueue, GroupId)

	for i = 1, GroupSize do
		local CustomerNPC = RS:WaitForChild("Assets").CustomerRig:Clone()
		CustomerNPC.Name = GroupId .. "_Member_" .. i
		CustomerNPC.Parent = CustomersFolder
		local CustomerHum:Humanoid = CustomerNPC:WaitForChild("Humanoid")
		local CustomerHrp = CustomerNPC:WaitForChild("HumanoidRootPart")
		if CustomerHum == nil or CustomerHrp == nil then return end

		local groupOffset = Vector3.new(0, 0, 0)
		if i == 2 then groupOffset = Vector3.new(-2.5, 0, -2.5) end
		if i == 3 then groupOffset = Vector3.new(2.5, 0, -2.5) end
		if i == 4 then groupOffset = Vector3.new(0, 0, -4.5) end

		task.spawn(function()
			local success, err = pcall(function()
				local FriendsPages = Players:GetFriendsAsync(Player.UserId)
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

				CustomerHrp:SetNetworkOwner(nil)
				for i,v in pairs(CustomerNPC:GetDescendants()) do
					if v:IsA("BasePart") then
						v.CollisionGroup = "Customers"
					end
				end
			end)
		end)		

		CustomerNPC:PivotTo(CustomerPath:FindFirstChild("1").CFrame * CFrame.new(groupOffset))
		CustomerNPC:SetAttribute("TargetPlot", ChosenPlot.Name)

		CustomerHrp:SetNetworkOwner(nil)

		for _, v in pairs(CustomerNPC:GetDescendants()) do
			if v:IsA("BasePart") then 
				v.CollisionGroup = "Customers" 
				v.CanTouch = false
			end
		end

		table.insert(NPCHandler.ActiveRestaurants[UserId].Groups[GroupId].Members, CustomerNPC)

		local IsLeader = (i == 1)
		NPCHandler.SetupNPC(CustomerNPC, ChosenPlot, "1", Player, GroupId, IsLeader, groupOffset)
	end
end

local function UpdatePotTimers(PotTimer,deltaTime,DataStore)
	if PotTimer and PotTimer:IsA("NumberValue") and PotTimer.Value > 0 and DataStore.Value.ActivePorts > 0 then 
		PotTimer.Value -= deltaTime
	end
end

RunService.Heartbeat:Connect(function(deltaTime)
	-- Loop through every active player's restaurant
	for _, Player in ipairs(Players:GetPlayers()) do
		local UserId = Player.UserId
		local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, UserId)

		if DataStore and DataStore.Value and DataStore.Value.RestaurantSkillTree["UnlockRestaurant"].Unlocked == true and DataStore.Value.RestaurantSkillTree["PurchaseFurniture"].Unlocked == true then

			if not NPCHandler.ActiveRestaurants[UserId] then
				NPCHandler.ActiveRestaurants[UserId] = {}
			end

			local RestData = NPCHandler.ActiveRestaurants[UserId]

			if not RestData.Customers then RestData.Customers = {} end
			if not RestData.Waiters then RestData.Waiters = {} end
			if not RestData.Hosts then RestData.Hosts = {} end
			if not RestData.Chefs then RestData.Chefs = {} end
			if not RestData.Groups then RestData.Groups = {} end
			if not RestData.ActivePotTimers then RestData.ActivePotTimers = {} end

			if RestData.CustomerSpawnTimer == nil then RestData.CustomerSpawnTimer = 0 end
			if RestData.KitchenCookTimer == nil then RestData.KitchenCookTimer = 0 end
			if RestData.ChefStartupTimer == nil then RestData.ChefStartupTimer = 0 end

			for PotTimer, Pot in pairs(RestData.ActivePotTimers) do
				UpdatePotTimers(PotTimer, deltaTime, DataStore)
			end

			local RestaurantData = NPCHandler.ActiveRestaurants[UserId]

			if not RestaurantData.Plot then
				for _, StrVal in pairs(Plots:GetDescendants()) do 
					if StrVal:IsA("StringValue") and StrVal.Name == "Occupant" and StrVal.Value == Player.Name then
						RestaurantData.Plot = StrVal.Parent.Parent
						break
					end
				end
			end

			local Plot = RestaurantData.Plot
			if not Plot then continue end

			if not Plot:GetAttribute("PlotBuilt") then continue end

			-- [[ FIX 2: CONTINUOUS WORKER INITIALIZATION CHECK ]]
			local WorkersFolder = Plot.RestaurantBuild:FindFirstChild("Workers")
			if WorkersFolder then
				local WorkerSpots = WorkersFolder:FindFirstChild("WorkerSpots")
				if WorkerSpots then
					local HostIdleSpot = WorkerSpots:FindFirstChild("HostIdleSpot")
					local WaiterIdleSpot = WorkerSpots:FindFirstChild("WaiterIdleSpot")
					local ChefIdleSpot = WorkerSpots:FindFirstChild("ChefIdleSpot")
					local ChefCookingSpot = WorkerSpots:FindFirstChild("ChefCookingSpot")

					for _, worker in pairs(WorkersFolder:GetChildren()) do
						if worker:IsA("Model") and worker:FindFirstChild("Humanoid") then
							-- Check if this specific worker is already tracked
							local isInitialized = false
							if string.find(worker.Name, "Host") and RestData.Hosts[worker] then isInitialized = true end
							if string.find(worker.Name, "Waiter") and RestData.Waiters[worker] then isInitialized = true end
							if string.find(worker.Name, "Chef") and RestData.Chefs[worker] then isInitialized = true end

							-- Don't setup the Manager via pathfinding if it's just an idle NPC
							if string.find(worker.Name, "Manager") then isInitialized = true end

							if not isInitialized then
								local HRP = worker:FindFirstChild("HumanoidRootPart")
								if HRP then
									HRP.Anchored = false
									-- Safely set network owner
									pcall(function() HRP:SetNetworkOwner(nil) end)
								end

								if string.find(worker.Name, "Host") and HostIdleSpot then
									NPCHandler.SetupHost(worker, Plot, HostIdleSpot.Position, Player)
								elseif string.find(worker.Name, "Waiter") and WaiterIdleSpot then
									NPCHandler.SetupWaiter(worker, Plot, WaiterIdleSpot.Position, Player)
								elseif string.find(worker.Name, "Chef") and ChefIdleSpot and ChefCookingSpot then
									NPCHandler.SetupChef(worker, Plot, ChefIdleSpot.Position,ChefCookingSpot.Position, Player)
								end

								for _, v in pairs(worker:GetDescendants()) do
									if v:IsA("BasePart") then v.CollisionGroup = "Workers" end
								end
							end
						end
					end
				end
			end
			-- Remove RestaurantData.WorkersInitialized = true

			local CustomerPower = DataStore.Value.Upgrades.CustomerRate or 1
			local MaxCustomers = math.floor(2 + (CustomerPower * 0.36))
			local SpawnSpeed = math.max(2, 10 - (CustomerPower * 0.15))

			RestaurantData.CustomerSpawnTimer = (RestaurantData.CustomerSpawnTimer or 0) + deltaTime

			if RestaurantData.CustomerSpawnTimer >= SpawnSpeed then
				local currentCustomerCount = 0
				if RestaurantData.Customers then
					for _, _ in pairs(RestaurantData.Customers) do
						currentCustomerCount += 1
					end
				end

				local MAX_NPCS_TOTAL = 8 -- teto absoluto de NPCs simultâneos
				if currentCustomerCount < MaxCustomers and currentCustomerCount < MAX_NPCS_TOTAL then
					RestaurantData.CustomerSpawnTimer = 0
					SpawnCustomerGroup(Player, UserId, RestaurantData)
				end
			end

			if RestaurantData.Customers then
				RestaurantData.CustomerProcessIndex = RestaurantData.CustomerProcessIndex or {}
				local customerList = {}
				for model, data in pairs(RestaurantData.Customers) do
					table.insert(customerList, {model, data})
				end
				local maxPerFrame = 3
				local startIdx = (RestaurantData.CustomerFrameOffset or 0) % math.max(#customerList, 1)
				for i = 1, math.min(maxPerFrame, #customerList) do
					local idx = (startIdx + i - 1) % #customerList + 1
					local entry = customerList[idx]
					if entry then
						CustomerHandling(deltaTime, entry[1], entry[2], UserId)
					end
				end
				RestaurantData.CustomerFrameOffset = (RestaurantData.CustomerFrameOffset or 0) + maxPerFrame
			end

			if RestaurantData.ChefStartupTimer < 4 then
				RestaurantData.ChefStartupTimer += deltaTime
			else
				if RestaurantData.Chefs then
					for ChefModel, ChefData in pairs(RestaurantData.Chefs) do
						ChefHandling(deltaTime, ChefModel, ChefData, UserId)
					end
				end
			end

			if RestaurantData.Waiters then
				for WaiterModel, WaiterData in pairs(RestaurantData.Waiters) do
					WaiterHandling(deltaTime, WaiterModel, WaiterData, UserId)
				end
			end

			if RestaurantData.Hosts then
				for HostModel, HostData in pairs(RestaurantData.Hosts) do
					HostHandling(deltaTime, HostModel, HostData, UserId)
				end
			end

		end
	end
end)


local function OnCharacterAdded(Player, Character)
	print("INSIDE PLAYER ADDED FUNC")

	repeat task.wait(1) until Player:FindFirstChild("PlayerInfo") and Character:FindFirstChild("ToolFolder")

	task.delay(3,function()
		local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
		local HRP = Character:FindFirstChild("HumanoidRootPart")
		local Humanoid = Character:FindFirstChild("Humanoid")
		local Animator = Humanoid:WaitForChild("Animator")
		local LeaderstatValues = Player:WaitForChild("leaderstatValues")
		local PlayerStats = Player:WaitForChild("PlayerStats")
		local PlayerInfo = Player:WaitForChild("PlayerInfo")
		local Upgrades = DataStore.Value.Upgrades
		local FarmersMarketSkillTree = DataStore.Value.FarmersMarketSkillTree
		local RestaurantSkillTree = DataStore.Value.RestaurantSkillTree

		local StoredRestaurantFood = PlayerStats.StoredRestaurantFood
		local PlayerInfo = Player.PlayerInfo
		if not RestaurantInfo[Player.UserId] then
			RestaurantInfo[Player.UserId] = {
				Connections = {},
			}	
		end
		RestaurantInfo[Player.UserId].Animations = {
			RHandHeldUp = Animator:LoadAnimation(RS:WaitForChild("Assets").Animations["Gourmet Food"].RHandIdle),
			LHandHeldUp = Animator:LoadAnimation(RS:WaitForChild("Assets").Animations["Gourmet Food"].LHandIdle),
		}

		NPCHandler.ActiveRestaurants[Player.UserId] = {}

		local RestaurantInfoData = RestaurantInfo[Player.UserId]
		local StoredRestaurantFoodValue = PlayerStats.StoredRestaurantFood.Value
		local PlayersSpotVal = PlayerInfo.PlayerSpot
		if PlayersSpotVal.Value == "None" or PlayersSpotVal.Value == "" then
			PlayersSpotVal:GetPropertyChangedSignal("Value"):Wait()
		end
		local PlayersPlot = Plots:FindFirstChild(PlayersSpotVal.Value)

		local MarketSpot = PlayerInfo.MarketSpot
		local RestaurantSkillTreeVal = PlayerStats.RestaurantSkillTree

		local ManagerIdle = nil
		if PlayersPlot then
			local build = PlayersPlot:FindFirstChild("RestaurantBuild")
			if build then
				local workers = build:FindFirstChild("Workers")
				if workers then
					local managerNPC = workers:FindFirstChild("Manager")
					if managerNPC then
						local hum = managerNPC:FindFirstChild("Humanoid")
						if hum then
							local animator = hum:FindFirstChild("Animator")
							if animator then
								ManagerIdle = animator:LoadAnimation(RS:WaitForChild("Assets").Animations["Gourmet Food"].JaneJulietIdle)
							end
						end
					end
				end
			end
		end

		if PlayersPlot then
			print("RAN PLAYER PLOT!!! and LOADING IN")
			if #PlayersPlot.Customers:GetChildren() > 0 then
				for i, v:Model in pairs(PlayersPlot.Customers:GetChildren()) do
					if v:IsA("Model") and v:FindFirstChildWhichIsA("Humanoid") then
						v:Destroy()
						print(v, "Is a CUSTOMER NPC THAT WAS LEFT HERE BY THE PREVIOUS PLAYER AND WAS DESTROYED JUST NOW!")
					end
				end
			end
			local function TrackRestaurant(v)
				if DataStore.Value.RestaurantSkillTree["UnlockRestaurant"].Unlocked == true then

					if v.Value == true then	
						-- When a node is unlocked, find the corresponding pad and enable the NEXT pads:
						local RestaurantSkillPads = PlayersPlot:FindFirstChild("RestaurantSkillTree")
						if RestaurantSkillPads then
							local SkillPad = RestaurantSkillPads:FindFirstChild(v.Name, true)

							if SkillPad then
								local SKillPadOwnerFolder = SkillPad.Parent

								for i, padPart in pairs(RestaurantSkillPads:GetDescendants()) do
									if padPart:IsA("BasePart") then
										if padPart.Parent.Name == "Seed" or padPart.Parent.Parent.Name == "Seed" then
											continue
										end

										-- If this part belongs to the node that was just unlocked, make it touchable!
										if padPart:GetAttribute("Owner") == SKillPadOwnerFolder.Name or padPart.Parent:GetAttribute("Owner") == SKillPadOwnerFolder.Name then
											padPart.CanTouch = true 
										end
									end
								end
							end
						end

						local RestaurantSectionName = nil
						local RestaurantSection = nil
						if (string.find(v.Name,"Build")) then
							RestaurantSectionName = string.gsub(v.Name,"Build","")	
						elseif (string.find(v.Name,"Unlock")) then
							RestaurantSectionName = string.gsub(v.Name,"Unlock","")	
						elseif (string.find(v.Name,"Purchase")) then
							RestaurantSectionName = string.gsub(v.Name,"Purchase","")	
						end
						if type(RestaurantSectionName) == "string" and RestaurantSectionName ~= nil then
							RestaurantSection = PlayersPlot.RestaurantBuild:FindFirstChild(RestaurantSectionName)
							if RestaurantSectionName == "Restaurant" then
								PlayersPlot.Base.Base.RestaurantBase.BaseTexture.Transparency = 0.25
								RestaurantSection = PlayersPlot.RestaurantBuild.SkillTreeGlassWalls
							end

							if RestaurantSectionName == "Furniture" then
								for i,v in pairs(PlayersPlot:GetDescendants()) do
									if DataStore.Value.RestaurantUnlocks.ChefUnlocked == false and v:FindFirstAncestor("Chef") and v:FindFirstAncestor("Chef"):FindFirstChildWhichIsA("Humanoid") then
										print("HIDING CHEFF")
										--continue
									end
									if v:IsA("BasePart") and v.Parent:FindFirstChildWhichIsA("Humanoid") then
										if v.Name == "HumanoidRootPart" then
											if v.Parent.Name == "Manager" then
												v.Anchored = true
											end
											continue
										end
										v.Transparency = 0
										v.CanCollide = true
										v.CanQuery = true
										v.CanTouch = false
										print(v.Parent)
									end
									if v:IsA("BasePart") and v.Parent:IsA("Accessory") then
										v.Transparency = 0
										v.CanCollide = true
										v.CanQuery = true
										v.CanTouch = false
									end
									if v:IsA("Decal") and v:FindFirstAncestorWhichIsA("Model") and v:FindFirstAncestorWhichIsA("Model"):FindFirstChildWhichIsA("Humanoid") then
										v.Transparency = 0
									end
									if v:IsA("BillboardGui") and v:FindFirstAncestorWhichIsA("Model") and v:FindFirstAncestorWhichIsA("Model"):FindFirstChildWhichIsA("Humanoid") then
										v.Enabled = true
									end
									if v:IsA("ProximityPrompt") and v:FindFirstAncestorWhichIsA("Model") and v:FindFirstAncestorWhichIsA("Model"):FindFirstChildWhichIsA("Humanoid") then
										v.Enabled = true
									end
								end
							end
							if ManagerIdle and ManagerIdle.IsPlaying == false then
								ManagerIdle:Play()
							end
						--[[
						if RestaurantSection then
						for i,Part in pairs(RestaurantSection:GetDescendants()) do
							local RSRestaurantSect = RS:WaitForChild("Assets").RestaurantBuild:FindFirstChild(RestaurantSection.Name)
							for _,v in pairs(RSRestaurantSect:GetDescendants()) do
								if Part.Name == v.Name then
									if Part:IsA("BasePart") and v:IsA("BasePart") then
										if Part.Parent.Parent.Name == "Pots" or Part.Parent.Parent.Parent.Name == "Pots" or v.Parent:IsA("Accessory") or v.Parent:FindFirstChildWhichIsA("Humanoid") then
											continue
										end
										Part.Transparency = v.Transparency
										Part.CanCollide = v.CanCollide
										Part.CanQuery = false
										Part.CanTouch = v.CanTouch
									end
									if Part:IsA("Texture") and v:IsA("Texture") then
										Part.Transparency = v.Transparency
									end
									if Part:IsA("Decal") and v:IsA("Decal") then
										Part.Transparency = v.Transparency
									end
									if Part:IsA("BillboardGui") then
										Part.Enabled = true
									end
									if Part:IsA("SurfaceGui") then
										Part.Enabled = true
									end
									if Part:IsA("ProximityPrompt") then
										Part.Enabled = true
									end
								end
							end
						end
						end
						]]--
							if RestaurantSection then
								local RSRestaurantSect = RS:WaitForChild("Assets").RestaurantBuild:FindFirstChild(RestaurantSection.Name)
								if RSRestaurantSect then

									-- [[ FIX: Build a lightning-fast dictionary that groups parts by name AND type ]]
									local rsCache = {}
									for _, v in ipairs(RSRestaurantSect:GetDescendants()) do
										if not rsCache[v.Name] then rsCache[v.Name] = {} end
										table.insert(rsCache[v.Name], v)
									end

									for i, Part in pairs(RestaurantSection:GetDescendants()) do
										local potentialMatches = rsCache[Part.Name]

										if potentialMatches then
											local v = nil
											-- Find the match that is actually the same type of object (Part vs Model)
											for _, match in ipairs(potentialMatches) do
												if match.ClassName == Part.ClassName or (Part:IsA("BasePart") and match:IsA("BasePart")) then
													v = match
													break
												end
											end

											if v then
												if Part:IsA("BasePart") and v:IsA("BasePart") then
													if (Part.Parent and Part.Parent.Parent and Part.Parent.Parent.Name == "Pots") or 
														(v.Parent and v.Parent:IsA("Accessory")) or 
														(v.Parent and v.Parent:FindFirstChildWhichIsA("Humanoid")) then
														continue
													end
													Part.Transparency = v.Transparency
													Part.CanCollide = v.CanCollide
													Part.CanQuery = false
													Part.CanTouch = v.CanTouch
												elseif Part:IsA("Texture") and v:IsA("Texture") then
													Part.Transparency = v.Transparency
												elseif Part:IsA("Decal") and v:IsA("Decal") then
													Part.Transparency = v.Transparency
												elseif Part:IsA("BillboardGui") or Part:IsA("SurfaceGui") or Part:IsA("ProximityPrompt") then
													Part.Enabled = true
												end
											end
										end
									end
								end
							end
						end
					end
				end

			end

			for i,v in pairs(RestaurantSkillTreeVal:GetChildren()) do
				if (string.find(v.Name,"Build") or string.find(v.Name,"Unlock") or string.find(v.Name,"Purchase")) then
					TrackRestaurant(v)
					if RestaurantInfoData.Connections[v.Name.."Connect"] then
						RestaurantInfoData.Connections[v.Name.."Connect"]:Disconnect()
					end
					RestaurantInfoData.Connections[v.Name.."Connect"] = v:GetPropertyChangedSignal("Value"):Connect(function()
						TrackRestaurant(v)	
					end)
				end					
			end

			PlayersPlot:SetAttribute("PlotBuilt", true)

			if DataStore.Value.RestaurantSkillTree["UnlockRestaurant"].Unlocked == true and DataStore.Value.RestaurantSkillTree["BuildKitchen"].Unlocked == true then
				local FoodFolder = RestaurantFoodStorage
				local StorageBox = PlayersPlot.RestaurantBuild.Kitchen.StorageBox
				local function SpawnFoodProduct(amount)
					if #StorageBox.Food:GetChildren() < 50 then
						for i = 1,amount do
							local RN = math.random(1,#FoodFolder:GetChildren())
							local regionPart = StorageBox.StorageBoxRoot
							local randomPos = regionPart.CFrame * CFrame.new(math.random(-1,1)*regionPart.Size.X/2.5 , 2 , math.random(-1,1)*regionPart.Size.Z/2.5)

							local ChosenFood = FoodFolder:GetChildren()[RN]:Clone()
							ChosenFood.Parent = StorageBox.Food

							for i,v in pairs(StorageBox:GetChildren()) do
								if v:IsA("BasePart") then
									v.CanCollide = true
									if v == StorageBox.StorageBoxRoot then
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
							local regionPart = StorageBox.StorageBoxRoot
							local randomPos = regionPart.CFrame * CFrame.new(math.random(-1,1)*regionPart.Size.X/2 , 2 , math.random(-1,1)*regionPart.Size.Z/2)

							local ChosenFood = FoodFolder:GetChildren()[RN]:Clone()
							ChosenFood.Parent = StorageBox.Food

							for i,v in pairs(StorageBox:GetChildren()) do
								if v:IsA("BasePart") then
									v.CanCollide = true
									if v == StorageBox.StorageBoxRoot then
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
				if #StorageBox.Food:GetChildren() < 50 then
					if StoredRestaurantFood.Value > 0 and StoredRestaurantFood.Value < 10000 then
						SpawnFoodProduct(12)
					elseif StoredRestaurantFood.Value >= 10000 and StoredRestaurantFood.Value < 1000000 then
						SpawnFoodProduct(30)
					elseif StoredRestaurantFood.Value >= 1000000 then
						SpawnFoodProduct(50)
					end
				end
			end

			for i,v in pairs(PlayersPlot:GetDescendants()) do
				if v:IsA("BasePart") and v.Name == "PrimaryBuildingColorPart" then
					local ColorData = DataStore.Value.RestaurantCustomization.PrimaryBuildingColor
					v.Color = Color3.new(ColorData[1],ColorData[2],ColorData[3])
				elseif v:IsA("BasePart") and v.Name == "SecondaryBuildingColorPart" then
					local ColorData = DataStore.Value.RestaurantCustomization.SecondaryBuildingColor
					v.Color = Color3.new(ColorData[1],ColorData[2],ColorData[3])
				elseif v:IsA("BasePart") and v.Name == "TableColorPart" then
					local ColorData = DataStore.Value.RestaurantCustomization.TableColor
					v.Color = Color3.new(ColorData[1],ColorData[2],ColorData[3])
				elseif v:IsA("BasePart") and v.Name == "ChairColorPart" then
					local ColorData = DataStore.Value.RestaurantCustomization.ChairColor
					v.Color = Color3.new(ColorData[1],ColorData[2],ColorData[3])
				end
			end	

		end

		RestaurantInfoData.Connections.StoredRestaurantFoodConnect = StoredRestaurantFood:GetPropertyChangedSignal("Value"):Connect(function()
			local Difference = StoredRestaurantFood.Value - StoredRestaurantFoodValue

			local FoodFolder = RestaurantFoodStorage
			local StorageBox = PlayersPlot.RestaurantBuild.Kitchen.StorageBox
			local function SpawnFoodProduct(amount)
				if #StorageBox.Food:GetChildren() < 50 then
					for i = 1,amount do
						local RN = math.random(1,#FoodFolder:GetChildren())
						local regionPart = StorageBox.StorageBoxRoot
						local randomPos = regionPart.CFrame * CFrame.new(math.random(-1,1)*regionPart.Size.X/2.5 , 2 , math.random(-1,1)*regionPart.Size.Z/2.5)

						local ChosenFood = FoodFolder:GetChildren()[RN]:Clone()
						ChosenFood.Parent = StorageBox.Food

						for i,v in pairs(StorageBox:GetChildren()) do
							if v:IsA("BasePart") then
								v.CanCollide = true
								if v == StorageBox.StorageBoxRoot then
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
						local regionPart = StorageBox.StorageBoxRoot
						local randomPos = regionPart.CFrame * CFrame.new(math.random(-1,1)*regionPart.Size.X/2 , 2 , math.random(-1,1)*regionPart.Size.Z/2)

						local ChosenFood = FoodFolder:GetChildren()[RN]:Clone()
						ChosenFood.Parent = StorageBox.Food

						for i,v in pairs(StorageBox:GetChildren()) do
							if v:IsA("BasePart") then
								v.CanCollide = true
								if v == StorageBox.StorageBoxRoot then
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
				if StoredRestaurantFood.Value > 0 and StoredRestaurantFood.Value < 10000 then
					SpawnFoodProduct(10)
				elseif StoredRestaurantFood.Value >= 10000 and StoredRestaurantFood.Value < 1000000 then
					SpawnFoodProduct(15)
				elseif StoredRestaurantFood.Value >= 1000000 then
					SpawnFoodProduct(20)
				end
				local IncDecDisplay = RS:WaitForChild("UIAssets").IncDecStorageBoxDisplay:Clone()
				IncDecDisplay.Parent = StorageBox.StorageBoxRoot
				IncDecDisplay.Icon.Increment.Text = "+"..FrmtNum(Difference,2)
				IncDecDisplay.StudsOffset = Vector3.new(0,2,0)
				TS:Create(IncDecDisplay,TweenInfo.new(3.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{Brightness = 5,StudsOffset = Vector3.new(0,6,0)}):Play()
				TS:Create(IncDecDisplay.Icon.Increment,TweenInfo.new(4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{TextTransparency = 1}):Play()
				Debris:AddItem(IncDecDisplay,2.25)
			elseif Difference < 0 then
				local IncDecDisplay = RS:WaitForChild("UIAssets").IncDecStorageBoxDisplay:Clone()
				IncDecDisplay.Parent = StorageBox.StorageBoxRoot
				IncDecDisplay.Icon.Increment.Text = "-"..FrmtNum(Difference,2)
				IncDecDisplay.Icon.Increment.OrangeGradient.Enabled = false
				IncDecDisplay.Icon.Increment.TextColor3 = Color3.fromRGB(255, 0, 0)
				IncDecDisplay.StudsOffset = Vector3.new(0,2,0)
				TS:Create(IncDecDisplay,TweenInfo.new(3.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{Brightness = 5,StudsOffset = Vector3.new(0,6,0)}):Play()
				TS:Create(IncDecDisplay.Icon.Increment,TweenInfo.new(4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{TextTransparency = 1}):Play()
				Debris:AddItem(IncDecDisplay,2.25)
			end	

			StoredRestaurantFoodValue = StoredRestaurantFood.Value
		end)	

		-----<<
		--KITCHEN POTS AND PORT AND PLATES
		----->>

		local ActivePorts = DataStore.Value.ActivePorts
		if ActivePorts > 0 then
			for i = 1, ActivePorts do
				local Pots = PlayersPlot.RestaurantBuild.Kitchen.Pots 
				local Ports = PlayersPlot.RestaurantBuild.Kitchen.Stove.Ports
				local FreePort = nil
				for i = 1,12 do
					if Ports:FindFirstChild("PortFrame"..i).InUse.Value == false then
						FreePort = Ports:FindFirstChild("PortFrame"..i)
						break
					end
				end
				if FreePort == nil then break end

				local PortNum = string.gsub(FreePort.Name,"PortFrame","")
				local Pot = Pots:FindFirstChild("Pot"..PortNum)
				local CookingTime = Pot:FindFirstChild("CookingTime")
				FreePort.InUse.Value = true 
				CookingTime.Value = 10 * DataStore.Value.Upgrades.GourmetCookingSpeed

				-- [[ FIX: Initialize CookingState so it triggers cooked updates! ]]
				Pot:SetAttribute("CookingState", "Cooking")

				if not NPCHandler.ActiveRestaurants[Player.UserId].ActivePotTimers then
					NPCHandler.ActiveRestaurants[Player.UserId].ActivePotTimers = {}
				end
				NPCHandler.ActiveRestaurants[Player.UserId].ActivePotTimers[CookingTime] = Pot
				print(Pot.Name)
				for i,v in pairs(Pot:GetDescendants()) do
					if v.Name == "Handle" then
						continue
					end
					if v:IsA("BasePart") then
						v.Transparency = 0
						v.Anchored = false
					end
				end

			end	
		end
		local PlatesInHand = DataStore.Value.PlatesInHand
		if PlatesInHand > 0 then
			for i = 1, PlatesInHand do
				local RHand = Character:FindFirstChild("RightHand")
				local LHand = Character:FindFirstChild("LeftHand")
				local GourmetPlate = RS:WaitForChild("Assets").GourmetPlate:Clone()
				GourmetPlate.Parent = Character.ToolFolder
				local PlateRoot = GourmetPlate.PrimaryPart
				local GourmetTableTop = GourmetPlate.TableTop

				for i,v in pairs(GourmetPlate:GetDescendants()) do
					if v:IsA("BasePart") and v.Parent.Name == "TableTop" then
						if v.Name == "TableTopRoot" then
							v.CanCollide = false
							v.Massless = true
							continue
						end
						v.Transparency = 0
						v.Massless = true
						v.CanCollide = false
					end
				end

				if i == 1 then
					GourmetPlate:PivotTo(RHand.CFrame)
					GourmetPlate.Name = "GourmetPlate1"
					local Weld = Instance.new("Weld")
					Weld.Parent = GourmetPlate.PrimaryPart
					Weld.Name = "HandWeld"
					Weld.Part0 = RHand
					Weld.Part1 = GourmetPlate.PrimaryPart
					Weld.C0 = CFrame.new(0,0,-0.55)
					Weld.C1 = CFrame.Angles(math.rad(90),0,0)
					DataStore.Value.PlatesInHand = 1
					RestaurantInfo[Player.UserId].Animations.RHandHeldUp:Play()

				elseif i == 2 then
					GourmetPlate:PivotTo(LHand.CFrame)
					GourmetPlate.Name = "GourmetPlate2"
					local Weld = Instance.new("Weld")
					Weld.Parent = GourmetPlate.PrimaryPart
					Weld.Name = "HandWeld"
					Weld.Part0 = LHand
					Weld.Part1 = GourmetPlate.PrimaryPart
					Weld.C0 = CFrame.new(0,0,-0.55)
					Weld.C1 = CFrame.Angles(math.rad(90),0,0)
					DataStore.Value.PlatesInHand = 2
					RestaurantInfo[Player.UserId].Animations.LHandHeldUp:Play()
				end
				local FoodsRN = math.random(1,#RS:WaitForChild("Assets").GourmetFoods:GetChildren())
				local ChosenGourmetFood = RS:WaitForChild("Assets").GourmetFoods:GetChildren()[FoodsRN]:Clone()
				ChosenGourmetFood.Parent = GourmetPlate
				ChosenGourmetFood:PivotTo(PlateRoot.CFrame * CFrame.new(0,(PlateRoot.Size.Y/2+ChosenGourmetFood.PrimaryPart.Size.Y/2),0))

				local WeldCons = Instance.new("WeldConstraint")
				WeldCons.Parent = ChosenGourmetFood.PrimaryPart
				WeldCons.Part0 = ChosenGourmetFood.PrimaryPart
				WeldCons.Part1 = PlateRoot

			end
		end
		local PlatesPlaced = DataStore.Value.PlatesPlaced
		if PlatesPlaced > 0 then
			for i = 1, PlatesPlaced do	
				local Kitchen = PlayersPlot.RestaurantBuild.Kitchen
				local Pots = PlayersPlot.RestaurantBuild.Kitchen.Pots
				local FoodSpots = Kitchen.FoodSpots

				local FreeFoodSpot = nil
				for k = 1,12 do
					if FoodSpots:FindFirstChild("FoodSpot"..k).Occupied.Value == false and not FoodSpots:FindFirstChild("FoodSpot"..k):FindFirstChild("GourmetPlate") then
						FreeFoodSpot = FoodSpots:FindFirstChild("FoodSpot"..k)
						break
					end
				end
				if FreeFoodSpot == nil then
					return
				end
				local GourmetPlate = RS:WaitForChild("Assets").GourmetPlate:Clone()
				GourmetPlate.Parent = FreeFoodSpot
				GourmetPlate:PivotTo(FreeFoodSpot.CFrame * CFrame.Angles(0,math.rad(180),0))

				local PlateRoot = GourmetPlate.PrimaryPart
				local GourmetTableTop = GourmetPlate.TableTop

				local FoodsRN = math.random(1,#RS:WaitForChild("Assets").GourmetFoods:GetChildren())
				local ChosenGourmetFood = RS:WaitForChild("Assets").GourmetFoods:GetChildren()[FoodsRN]:Clone()
				ChosenGourmetFood.Parent = GourmetPlate
				ChosenGourmetFood:PivotTo(PlateRoot.CFrame * CFrame.new(0,(PlateRoot.Size.Y/2+ChosenGourmetFood.PrimaryPart.Size.Y/2),0))

				local WeldCons = Instance.new("WeldConstraint")
				WeldCons.Parent = ChosenGourmetFood.PrimaryPart
				WeldCons.Part0 = ChosenGourmetFood.PrimaryPart
				WeldCons.Part1 = PlateRoot

				FreeFoodSpot.Occupied.Value = true 

			end
		end

		local Pots = PlayersPlot.RestaurantBuild.Kitchen.Pots 
		for i,CookingTimer in pairs(Pots:GetDescendants()) do
			if CookingTimer:IsA("NumberValue") and CookingTimer.Name == "CookingTime" then
				if not CookingTimer then
					continue
				end
				local Pot = CookingTimer.Parent
				local PotInfoDisplay = Pot.PotInformation
				local Spot = Pot.Parent.Parent.Parent.Parent
				local Occupant = Spot.Info.Occupant


				local function UpdateCookPots()
					if not(DataStore or DataStore.Value) then return end
					if DataStore.Value.ActivePorts <= 0 then return end

					-- [[ FIX: Correctly check state! ]]
					local currentState = Pot:GetAttribute("CookingState")
					if currentState ~= "Cooking" and currentState ~= "Cooked" then
						return
					end

					if not NPCHandler.ActiveRestaurants[Player.UserId] or not NPCHandler.ActiveRestaurants[Player.UserId].ActivePotTimers then
						return
					end
					if not NPCHandler.ActiveRestaurants[Player.UserId].ActivePotTimers[CookingTimer] then
						return
					end

					if CookingTimer.Value > 0 then
						PotInfoDisplay.Enabled = true
						PotInfoDisplay.Time.Text = math.round(CookingTimer.Value).."s"
						PotInfoDisplay.Time.TextColor3 = Color3.fromRGB(245, 245, 245)

					elseif CookingTimer.Value <= 0 then
						PotInfoDisplay.Enabled = true
						PotInfoDisplay.Time.Text = "Cooked!"
						PotInfoDisplay.Time.TextColor3 = Color3.fromRGB(255, 191, 0)

						local GourmetFoodPerFood = Upgrades.GourmetFoodPerFood
						local MultiplyGourmetFoodPerFood = Upgrades.MultiplyGourmetFoodPerFood
						local TotalGourmet = (GourmetFoodPerFood * MultiplyGourmetFoodPerFood)

						if RestaurantSkillTree["x1.5GourmetFood"].Unlocked == true then
							TotalGourmet *= 1.5
						end
						if RestaurantSkillTree["x3GourmetFood"].Unlocked == true then
							TotalGourmet *= 3
						end
						if RestaurantSkillTree["GourmetFoodBoostedByPlayTime"].Unlocked == true then
							TotalGourmet *= math.floor(PlayerInfo.Playtime.Value)
						end
						if RestaurantSkillTree["GourmetFoodMultipliedByLevel"].Unlocked == true then
							TotalGourmet *= DataStore.Value.Level
						end
						if Player:GetAttribute("x2GourmetFood") == true then
							TotalGourmet *= 2
						end
						DataStore.Value["Gourmet Food"] += TotalGourmet
						DataStore.playerstats["Gourmet Food"].Value = DataStore.Value["Gourmet Food"]

						local IncDecDisplay = RS:WaitForChild("UIAssets").IncDecGourmetDisplay:Clone()
						IncDecDisplay.Parent = Pot.PrimaryPart
						IncDecDisplay.Icon.Increment.Text = "+"..FrmtNum(TotalGourmet,2)
						IncDecDisplay.StudsOffset = Vector3.new(0,0,0)
						TS:Create(IncDecDisplay,TweenInfo.new(3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{Brightness = 5,StudsOffset = Vector3.new(0,5,0)}):Play()
						TS:Create(IncDecDisplay.Icon.Increment,TweenInfo.new(4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{TextTransparency = 1}):Play()
						Debris:AddItem(IncDecDisplay,2.25)

						Pot:SetAttribute("CookingState", "Cooked")

						local Highlight = Instance.new("Highlight")
						Highlight.Parent = Pot
						Highlight.FillTransparency = 0.5
						Highlight.FillColor = Color3.fromRGB(254, 255, 192)
						Highlight.OutlineColor = Color3.fromRGB(0, 0, 0)

						local ClickUi = RS:WaitForChild("UIAssets").ClickPromptDisplay:Clone()
						ClickUi.AlwaysOnTop = true
						ClickUi.Parent = Pot

						if not RestaurantInfo[Player.UserId] then RestaurantInfo[Player.UserId] = {} end
						if not RestaurantInfo[Player.UserId].Connections then RestaurantInfo[Player.UserId].Connections = {} end

						for i,v in pairs(Pot:GetDescendants()) do
							if v:IsA("BasePart") then
								v.CanQuery = true
							end
						end
						local ClickDetector:ClickDetector = Pot:FindFirstChild("ClickDetector") 
						ClickDetector.MaxActivationDistance = 15

						if RestaurantInfo[Player.UserId].Connections[ClickDetector] then
							RestaurantInfo[Player.UserId].Connections[ClickDetector]:Disconnect()
							RestaurantInfo[Player.UserId].Connections[ClickDetector] = nil
							print("ClickDetector Connection Disconnected")
						end

						RestaurantInfo[Player.UserId].Connections[ClickDetector] = ClickDetector.MouseClick:Connect(function(Plr)
							if PlayersPlot.Info.Occupant.Value ~= Player.Name then return end
							if PlayersPlot.Info.Occupant.Value == Player.Name then 
								print(Plr.Name.." Is Clicking on "..Pot.Name)
								if DataStore.Value.PlatesInHand >= 2 then
									NotifModule.Notify(Player,"Drop The Plates in Hand First!")
									return
								end
								CollectCookedGourmetFood(Plr,Pot,Character,PlayersPlot,DataStore,CookingTimer)	
							end
						end)
					end	
				end
				UpdateCookPots()
				if RestaurantInfoData.Connections[Pot.Name.."Timer"] then
					RestaurantInfoData.Connections[Pot.Name.."Timer"]:Disconnect()
				end
				RestaurantInfoData.Connections[Pot.Name.."Timer"] = CookingTimer:GetPropertyChangedSignal("Value"):Connect(UpdateCookPots)
			end
		end	

	end)
end

local function OnPlayerAdded(Player)
	print("SUCCESS: PlayerAdded fired for " .. Player.Name)

	Player.CharacterAdded:Connect(function(Character)
		OnCharacterAdded(Player, Character)



	end)

	-- If they already have a character when this connects, run it manually!
	if Player.Character then
		OnCharacterAdded(Player, Player.Character)
	end
end

-- Connect to new players joining
Players.PlayerAdded:Connect(OnPlayerAdded)

-- Catch anyone who loaded in before the script (Studio Play Solo fix)
for _, player in ipairs(Players:GetPlayers()) do
	OnPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(Player)
	-- [[ 1. CLEAN UP NPCs & WORKERS ]]
	local success, result = pcall(function()
		if NPCHandler.ActiveRestaurants[Player.UserId] then
			local RestData = NPCHandler.ActiveRestaurants[Player.UserId]
			if RestData.Waiters then for Waiter, _ in pairs(RestData.Waiters) do NPCHandler.Stop(Waiter, Player) end end
			if RestData.Hosts then for Host, _ in pairs(RestData.Hosts) do NPCHandler.Stop(Host, Player) end end
			if RestData.Chefs then for Chef, _ in pairs(RestData.Chefs) do NPCHandler.Stop(Chef, Player) end end

			if RestData.Customers then 
				for Customer, CustomerData in pairs(RestData.Customers) do
					if Customer then
						NPCHandler.CleanupNPC(Customer, Player) 
					end
				end 
			end
			NPCHandler.ActiveRestaurants[Player.UserId] = nil
		end	
	end)
	if success then
		print(success, "Cleared Npc Stuff")
	else
		print(result, "Failed to completely clear Npc Stuff Due to Error")
	end


	-- [[ 2. CLEAR MEMORY LEAKS ]]
	if RestaurantInfo[Player.UserId] then
		for i, v in pairs(RestaurantInfo[Player.UserId].Connections) do
			if v then v:Disconnect() end
		end
		RestaurantInfo[Player.UserId] = nil
	end

	-- [[ 3. BULLETPROOF PLOT RESET ]]
	-- We loop through ALL plots to find the one this player owns, bypassing DataStore delays
	for _, plot in pairs(Plots:GetChildren()) do
		if (plot:IsA("Folder") or plot:IsA("Model")) and plot:FindFirstChild("Info") then
			if plot.Info.Occupant.Value == Player.Name then

				-- A. Evict the Player
				plot.Info.Occupant.Value = "None"

				-- B. Reset the Sign Safely
				local SignPost = plot:FindFirstChild("Base") and plot.Base:FindFirstChild("PlayerNamePost")
				if SignPost and SignPost:FindFirstChild("Sign") and SignPost.Sign:FindFirstChild("SurfaceGui") and SignPost.Sign.SurfaceGui:FindFirstChild("TextLabel") then
					SignPost.Sign.SurfaceGui.TextLabel.Text = "Vacant"
				end

				-- C. Reset Tables & Kitchen Spots Safely
				local Furniture = plot.RestaurantBuild:FindFirstChild("Furniture")
				if Furniture then
					for _, tbl in pairs(Furniture:GetChildren()) do tbl:SetAttribute("Occupied", false) end
				end

				local Kitchen = plot.RestaurantBuild:FindFirstChild("Kitchen")
				if Kitchen and Kitchen:FindFirstChild("FoodSpots") then
					for _, spot in pairs(Kitchen.FoodSpots:GetChildren()) do
						if spot:FindFirstChild("Occupied") then spot.Occupied.Value = false end
					end
				end

				-- D. Reset Pots and Stove Ports Safely
				local Stove = Kitchen and Kitchen:FindFirstChild("Stove")
				local Pots = Kitchen and Kitchen:FindFirstChild("Pots")
				if Stove and Pots then
					if Stove:FindFirstChild("Ports") then
						for _, port in pairs(Stove.Ports:GetChildren()) do
							if port:IsA("Model") and port:FindFirstChild("InUse") then port.InUse.Value = false end
						end
					end
					for _, pot in pairs(Pots:GetChildren()) do
						if pot:IsA("Model") then
							pot:SetAttribute("CookingState", "NotOnStove")
							if pot:FindFirstChild("PotInformation") then pot.PotInformation.Enabled = false end

							local hl = pot:FindFirstChildWhichIsA("Highlight")
							if hl then hl:Destroy() end

							local cp = pot:FindFirstChild("ClickPromptDisplay")
							if cp then cp:Destroy() end
						end
					end
				end

				-- E. Visual & Dynamic Object Cleanup
				for i,v in pairs(plot:GetDescendants()) do
					if not v.Parent then continue end

					if v:IsA("ProximityPrompt") then v.Enabled = false end
					if v:IsA("Seat") then
						v:SetAttribute("ClaimedBy", nil)
						v.Transparency = 1
						v.CanCollide = false
						v.CanQuery = false
						v.CanTouch = false
					end	

					if v:IsA("Texture") or v:IsA("Decal") or v:IsA("BasePart") then
						-- Skip the static base and the SkillTree (we handle SkillTree below)
						if v.Parent.Name == "Base" or (v.Parent.Parent and v.Parent.Parent.Name == "Base") or (v.Parent.Parent and v.Parent.Parent.Parent and v.Parent.Parent.Parent.Name == "Base") or (v:FindFirstAncestor("RestaurantSkillTree")) then
							continue
						end
						v.Transparency = 1
						if v:IsA("BasePart") then
							v.CanCollide = false
							v.CanQuery = false
							v.CanTouch = false
						end
					end

					if v:IsA("SurfaceGui") then
						if not v:FindFirstAncestor("PlayerNamePost") and not v:FindFirstAncestor("RestaurantSkillTree") then
							v.Enabled = false
						end
					end
					if v:IsA("BillboardGui") then v.Enabled = false end

					-- Destroy leftover dynamic objects
					if v:IsA("Model") then
						if string.find(v.Name, "GourmetPlate") or (v.Parent:IsA("Folder") and v.Parent.Name == "Food") then
							v:Destroy()
						end
					end
				end

				-- F. RESTAURANT SKILL TREE CLEANUP (Keeping Seed Visible)
				local SkillTree = plot:FindFirstChild("RestaurantSkillTree")
				if SkillTree then
					for _, v in pairs(SkillTree:GetDescendants()) do
						if v:IsA("BasePart") then
							-- If the part is inside the "Seed" folder, leave it alone!
							if v.Parent.Name == "Seed" or (v.Parent.Parent and v.Parent.Parent.Name == "Seed") then
								continue
							end
							v.Transparency = 1
							v.CanCollide = false
							v.CanQuery = false
							v.CanTouch = false
						elseif v:IsA("SurfaceGui") or v:IsA("BillboardGui") or v:IsA("ProximityPrompt") then
							-- Ensure GUi's hide as well
							if v.Parent.Name ~= "Seed" and (v.Parent.Parent and v.Parent.Parent.Name ~= "Seed") then
								v.Enabled = false
							end
						end
					end
				end

				-- G. RESET OFFLINE EARNINGS BOARD SAFELY
				local OfflineReward = plot:FindFirstChild("Base") and plot.Base:FindFirstChild("OfflineReward")
				if OfflineReward and OfflineReward:FindFirstChild("SecondaryBuildingColorPart") then
					local SurfaceGui = OfflineReward.SecondaryBuildingColorPart:FindFirstChild("SurfaceGui")
					if SurfaceGui then
						-- Hide the stats and title
						if SurfaceGui:FindFirstChild("Stats") then SurfaceGui.Stats.Visible = false end
						if SurfaceGui:FindFirstChild("Title") then SurfaceGui.Title.Visible = false end

						-- Reset the info text to the default starting state
						if SurfaceGui:FindFirstChild("Info") then
							SurfaceGui.Info.Visible = true
							SurfaceGui.Info.Text = "Unlock Workers To Start Earning Offline!"
						end
					end
				end

				for i,v in pairs(OfflineReward:GetDescendants()) do
					if v:IsA("BasePart") and v.Name == "PrimaryBuildingColorPart" then
						v.Color = Color3.new(0.533333, 0.329412, 0.152941)
					end
					if v:IsA("BasePart") and v.Name == "SecondaryBuildingColorPart" then
						v.Color = Color3.new(0.580392, 0.54902, 0.388235)
					end
				end

				print("CLEANED UP PLAYERS SPOT/RESTAURANT: "..plot.Name.." "..Player.Name)
			end
		end
	end
end)