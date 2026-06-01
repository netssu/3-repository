local SS = game:GetService("ServerStorage")
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local CS = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local HTTPs = game:GetService("HttpService")
local Players = game:GetService("Players")

--MODULES
local DataStoreModule = require(SS:WaitForChild("Modules").MainDataModule)
local BezierModule = require(RS:WaitForChild("Modules").BezierModule)
local NotifModule = require(RS:WaitForChild("Modules").NotifModule)

local IncrementalRem = RS:WaitForChild("Remotes").IncrementalRemote

local PlayerIngredients = workspace.PlayerIngredients
local PlayerFoodBoxes = workspace.PlayerFoodBoxes

local SFX = RS:WaitForChild("Assets").SFX
local IngredientsStorage = SS:WaitForChild("Assets").Ingredients
local IngredientCollection = workspace.Map.CenterPoint.IngredientCollection
local IngredientUpgradeBoards = IngredientCollection:WaitForChild("UpgradeBoards")
local IngredientsDetectionZone = IngredientCollection:WaitForChild("DetectionZone")
local IngredientsCollectionZone = IngredientCollection:WaitForChild("CollectionZone")

local FoodStorage = SS:WaitForChild("Assets").Foods
local FoodCollection = workspace.Map.CenterPoint.FoodCollection
local CookingSpots = FoodCollection.CookingPot.CookingSpots
local CookerActive = false
local BoilingTimer = 0
local BoilingRate = 0.06 -- Spawn a bubble every 0.1 seconds (adjust for density)

local ActiveIncrementals = {}
-- [[ HELPER FUNCTIONS ]]

-- HELPER: Get Random CFrame on top of a Part

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

local function GetRandomSurfaceCFrame(TargetPart)
	local Size = TargetPart.Size
	local CF = TargetPart.CFrame

	-- Random X and Z within the bounds of the part
	local RandX = (math.random() - 0.5) * Size.X
	local RandZ = (math.random() - 0.5) * Size.Z
	local TopY = Size.Y / 2 -- Top surface

	return CF * CFrame.new(RandX, TopY, RandZ)
end

local function GetRandomSurfaceCFrameCircle(TargetPart)
	local Size = TargetPart.Size
	local CF = TargetPart.CFrame


	local MaxRadius = (Size.X / 2) * 0.9 

	-- 2. Pick a random Angle (0 to 360 degrees in radians)
	local Theta = math.random() * 2 * math.pi
	local Radius = math.sqrt(math.random()) * MaxRadius

	-- 4. Convert Polar coordinates (Angle/Radius) back to X/Z
	local RandX = Radius * math.cos(Theta)
	local RandZ = Radius * math.sin(Theta)

	local TopY = Size.Y / 2 -- Top surface

	return CF * CFrame.new(RandX, TopY, RandZ)
end

-- [[ BOILING VFX FUNCTION ]]
local function SpawnBoilingBubble()
	local CookerSoupPos = FoodCollection.CookingPot.Pot.CookerSoupPosition

	-- 1. Create the Bubble Part
	local Bubble = Instance.new("Part")
	Bubble.Name = "BoilingBubble"
	Bubble.Shape = Enum.PartType.Ball
	Bubble.Material = Enum.Material.SmoothPlastic
	Bubble.Color = FoodCollection.CookingPot.Pot.CookerSoup.Color -- Match soup color or slightly lighter
	Bubble.Transparency = 0.2
	Bubble.Anchored = true
	Bubble.CanCollide = false
	Bubble.CastShadow = false
	Bubble.Size = Vector3.new(0.1, 0.1, 0.1) -- Start small

	-- 2. Position it on the soup surface
	-- We want the *center* of the ball to be at the top surface level initially
	-- GetRandomSurfaceCFrame returns a CFrame at the exact top surface
	local SpawnCF = GetRandomSurfaceCFrameCircle(CookerSoupPos)
	Bubble.CFrame = SpawnCF

	Bubble.Parent = workspace.Debris -- Or a dedicated VFX folder

	-- 3. Randomize final size and duration
	local FinalSizeVal = math.random(15, 35) / 10 -- Random size between 1.5 and 3.5
	local FinalSize = Vector3.new(FinalSizeVal, FinalSizeVal, FinalSizeVal)
	local PopDuration = math.random(5, 10) / 10 -- Random duration 0.5s - 1.0s

	local TweenInfoGrowth = TweenInfo.new(PopDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	-- Tween Size
	TS:Create(Bubble, TweenInfoGrowth, {Size = FinalSize}):Play()

	-- Tween Transparency (Pop effect at the end)
	-- You might want it to fade out quickly near the end
	task.delay(PopDuration * 0.7, function()
		if Bubble.Parent then
			TS:Create(Bubble, TweenInfo.new(PopDuration * 0.3), {Transparency = 1}):Play()
		end
	end)

	-- 5. Cleanup
	Debris:AddItem(Bubble, PopDuration + 0.1)
end

local function RecalculateSpotsOccupied()
	local activeCookers = 0
	for _, spot in pairs(FoodCollection.CookingPot.CookingSpots:GetChildren()) do
		local occ = spot:FindFirstChild("Occupant")
		if occ and occ.Value ~= "Vacant" and occ.Value ~= "" then
			activeCookers += 1
		end
	end
	FoodCollection.CookingPot.CookingSpots:SetAttribute("SpotsOccupied", activeCookers)
end

for i,v in pairs(CS:GetTagged("CookingSpot")) do
	if v:IsA("ProximityPrompt") then
		v.Triggered:Connect(function(Plr)
			local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Plr.UserId)
			local Character = Plr.Character
			local HRP = Character:FindFirstChild("HumanoidRootPart")
			local Humanoid = Character:FindFirstChild("Humanoid")
			local CookingSpot = v.Parent.Parent
			local Occupant = CookingSpot.Occupant
			local Occupied = CookingSpot.Occupied

			if Occupant.Value ~= Plr.Name then
				return
			end
			if Character:GetAttribute("UsingCooker") == true or Character:GetAttribute("CookingSpotOccupying") ~= "None" then
				return
			end
			v.Enabled = false
			local SpotIndicator = CookingSpot.SpotIndication
			SpotIndicator.Color = Color3.fromRGB(255, 43, 43)
			Occupant.Value = Plr.Name
			Occupied.Value = true
			Character:SetAttribute("UsingCooker",true)
			Character:SetAttribute("CookingSpotOccupying",CookingSpot.Name)
			Humanoid.WalkSpeed = 0
			--Humanoid.JumpPower = 0
			local Ladder = CookingSpot.CookingLadder
			for _, v in pairs(Ladder:GetChildren()) do
				if v:IsA("BasePart") then
					if v.Name == "Root" then
						v.CanCollide = true
						v.CollisionGroup = "Items"
						continue
					end
					v.CanCollide = true
					v.CollisionGroup = "Items"
					v.Transparency = 0
				end
			end
			for _, v in pairs(Character:GetDescendants()) do
				if v:IsA("BasePart") then
					v.CollisionGroup = "Items"
				end
			end
			Character:PivotTo(CookingSpot.CookingPosition.CFrame * CFrame.new(0,2.5,0))
			HRP.Anchored = true
			IncrementalRem:FireClient(Plr,"StartedCooking",CookingSpot)
			ActiveIncrementals[Plr.UserId].FoodCollection.Player = Plr
			ActiveIncrementals[Plr.UserId].FoodCollection.CookingSpot = CookingSpot
			ActiveIncrementals[Plr.UserId].FoodCollection.InCookingSpot = true

			local Spoon = RS:WaitForChild("Assets").Spoon:Clone()
			Spoon.Parent = Character

			local StirVFX = RS:WaitForChild("Assets").VFX.StirCircleVFX:Clone()
			StirVFX.Name = Plr.Name.."StirVFX"
			StirVFX.Parent = workspace.Debris
			StirVFX.CFrame = HRP.CFrame * CFrame.new(0,-2.05,-3.5) * CFrame.Angles(0,math.rad(180),0)
			StirVFX.Attachment.SplashSpla.Enabled = true
			StirVFX.Attachment.Swirl.Enabled = true

			if DataStore.Value.FarmersMarketSkillTree.UnlockFarmersMarket.Unlocked == true and DataStore.Value.CurrentFoodBoxes <= 0 and not PlayerFoodBoxes[Plr.UserId]:FindFirstChild("FoodBoxes") then
				local CurrentFoodBoxes:NumberValue = DataStore.playerstats.CurrentFoodBoxes
				local FoodBoxesValue = DataStore.playerstats.FoodBoxesValue
				
				local FoodBoxPlatform = Ladder.TopSeat:Clone()
				FoodBoxPlatform.Parent = Ladder
				FoodBoxPlatform.Name = "FoodBoxPlatform"
				FoodBoxPlatform.Size = Vector3.new(FoodBoxPlatform.Size.X,FoodBoxPlatform.Size.Y*0.75,FoodBoxPlatform.Size.Z)
				FoodBoxPlatform.CFrame = FoodBoxPlatform.CFrame * CFrame.new(FoodBoxPlatform.Size.X,0,0)

				local FoodBoxesFolderModel = Instance.new("Model")
				FoodBoxesFolderModel.Parent = Ladder
				FoodBoxesFolderModel.Name = "FoodBoxes"
				FoodBoxesFolderModel:SetAttribute("FoodBoxCount",0)

				local FoodBoxOrigPosPart = Instance.new("Part")
				FoodBoxOrigPosPart.Parent = FoodBoxesFolderModel
				FoodBoxOrigPosPart.Name = "FoodBoxOrigPos"
				FoodBoxOrigPosPart.Size = RS:WaitForChild("Assets").FoodBox.PrimaryPart.Size
				FoodBoxOrigPosPart.Transparency = 1
				FoodBoxOrigPosPart.CanCollide = false
				FoodBoxOrigPosPart.Anchored = true
				FoodBoxOrigPosPart.CFrame = FoodBoxPlatform.CFrame * CFrame.new(0,(FoodBoxPlatform.Size.Y/2+FoodBoxOrigPosPart.Size.Y/2),0)
				
				local FoodBoxDisplay = RS:WaitForChild("UIAssets").FoodBoxDisplay:Clone()
				FoodBoxDisplay.Parent = FoodBoxOrigPosPart
				FoodBoxDisplay.BoxCountFrame.BarValue.Position = UDim2.fromScale(0,0.5)
				FoodBoxDisplay.BoxCountFrame.WhitePart.Position = UDim2.fromScale(0,0.5)
				FoodBoxDisplay.Icon.Increment.Text = "Boxes: "..FrmtNum(CurrentFoodBoxes.Value,2)..", Value:"..FrmtNum(FoodBoxesValue.Value,2)
				ActiveIncrementals[Plr.UserId].Connections.CharFoodInCurrBox = Character:GetAttributeChangedSignal("FoodInCurrentBox"):Connect(function()
					if FoodBoxDisplay and FoodBoxDisplay:FindFirstChild("Icon") and FoodBoxDisplay.Parent then
						local BoxCount = Character:GetAttribute("FoodInCurrentBox")
						local ProgressVal = math.clamp(BoxCount/10,0,0.989)
						TS:Create(FoodBoxDisplay.BoxCountFrame.BarValue,TweenInfo.new(0.3,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,false,0),{Position = UDim2.fromScale(ProgressVal,0.5)}):Play()
						TS:Create(FoodBoxDisplay.BoxCountFrame.WhitePart,TweenInfo.new(0.3,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,false,0),{Position = UDim2.fromScale(ProgressVal,0.5)}):Play()
					end		
				end)
				ActiveIncrementals[Plr.UserId].Connections.FoodBoxVal = FoodBoxesValue:GetPropertyChangedSignal("Value"):Connect(function()
					if FoodBoxDisplay and FoodBoxDisplay:FindFirstChild("Icon") and FoodBoxDisplay.Parent then
						FoodBoxDisplay.Icon.Increment.Text = "Boxes: "..FrmtNum(CurrentFoodBoxes.Value,2)..", Value:"..FrmtNum(FoodBoxesValue.Value,2)
					end
				end)
				ActiveIncrementals[Plr.UserId].Connections.CurrentFoodBoxesCount = CurrentFoodBoxes:GetPropertyChangedSignal("Value"):Connect(function()
					if FoodBoxDisplay and FoodBoxDisplay:FindFirstChild("Icon") and FoodBoxDisplay.Parent then
						FoodBoxDisplay.Icon.Increment.Text = "Boxes: "..FrmtNum(CurrentFoodBoxes.Value,2)..", Value:"..FrmtNum(FoodBoxesValue.Value,2)
					end		
				end)
			elseif DataStore.Value.FarmersMarketSkillTree.UnlockFarmersMarket.Unlocked == true and DataStore.Value.CurrentFoodBoxes > 0 and PlayerFoodBoxes[Plr.UserId]:FindFirstChild("FoodBoxes") then
				local FoodBoxPlatform = Ladder.TopSeat:Clone()
				FoodBoxPlatform.Parent = Ladder
				FoodBoxPlatform.Name = "FoodBoxPlatform"
				FoodBoxPlatform.Size = Vector3.new(FoodBoxPlatform.Size.X,FoodBoxPlatform.Size.Y*0.75,FoodBoxPlatform.Size.Z)
				FoodBoxPlatform.CFrame = FoodBoxPlatform.CFrame * CFrame.new(FoodBoxPlatform.Size.X,0,0)

				local FoodBoxesFolderModel = PlayerFoodBoxes[Plr.UserId]:FindFirstChild("FoodBoxes")
				FoodBoxesFolderModel.Parent = Ladder
				FoodBoxesFolderModel.PrimaryPart:FindFirstChild("FoodBoxCharweld"):Destroy()
				FoodBoxesFolderModel.PrimaryPart.Anchored = true
				FoodBoxesFolderModel:PivotTo(FoodBoxPlatform.CFrame * CFrame.new(0,(FoodBoxPlatform.Size.Y/2+FoodBoxesFolderModel.PrimaryPart.Size.Y/2),0))
				
				local FoodBoxOrigPosPart = FoodBoxesFolderModel.PrimaryPart
				local FakeFoodBox = FoodBoxesFolderModel:FindFirstChild("FakeFoodBox")
				FakeFoodBox.PrimaryPart.Anchored = true
				FakeFoodBox:PivotTo(FoodBoxOrigPosPart.CFrame * CFrame.new(0,(FoodBoxOrigPosPart.Size.Y/2+FakeFoodBox.PrimaryPart.Size.Y/2)-FoodBoxOrigPosPart.Size.Y,0))
				if FakeFoodBox.PrimaryPart:FindFirstChild("RootWeld") then
					FakeFoodBox.PrimaryPart:FindFirstChild("RootWeld"):Destroy()	
				end
				local FoodBoxCover = FoodBoxesFolderModel:FindFirstChild("FoodBoxCover")
				if FoodBoxCover.PrimaryPart:FindFirstChild("CoverWeld") then
					FoodBoxCover.PrimaryPart:FindFirstChild("CoverWeld"):Destroy()
					FoodBoxCover.PrimaryPart.Anchored = true
				end
				FoodBoxCover:PivotTo(FakeFoodBox.PrimaryPart.CFrame * CFrame.new(0,(FakeFoodBox.PrimaryPart.Size.Y/2+FoodBoxCover.PrimaryPart.Size.Y/2),0))
			end

			ActiveIncrementals[Plr.UserId].Animations.StirringFood:Play()
			ActiveIncrementals[Plr.UserId].Animations.StirringFood:AdjustSpeed(0.2)
			task.wait(0.4)
			ActiveIncrementals[Plr.UserId].Animations.StirringFood:AdjustSpeed(1)

			--FoodCollection.CookingPot.CookingSpots:SetAttribute("SpotsOccupied",FoodCollection.CookingPot.CookingSpots:GetAttribute("SpotsOccupied")+1)
			RecalculateSpotsOccupied()
		end)
	end
end
local BoilingCookingPotSFX = SFX.BoilingCookingPot:Clone()
BoilingCookingPotSFX.Parent = FoodCollection.CookingPot.Pot.CookerSoup
local function UpdateCooker()
	local CookerSoup = FoodCollection.CookingPot.Pot.CookerSoup
	local CookerSoupPos = FoodCollection.CookingPot.Pot.CookerSoupPosition
	local StoveFire = FoodCollection.CookingPot.Stove.MainStoveFire
	if CookingSpots:GetAttribute("SpotsOccupied") > 0 then	
		if CookerActive == false then
			CookerActive = true
			BoilingCookingPotSFX:Play()
			for i,v in pairs(StoveFire:GetDescendants()) do
				if v:IsA("ParticleEmitter") then
					v.Enabled = true
				end
			end
			CookerSoup.Transparency = 0
			TS:Create(CookerSoup,TweenInfo.new(1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{Size = Vector3.new(24.069, 3.183, 24.069),CFrame = CookerSoupPos.CFrame}):Play()
		end
	elseif CookingSpots:GetAttribute("SpotsOccupied") <= 0 then
		BoilingCookingPotSFX:Stop()
		for i,v in pairs(StoveFire:GetDescendants()) do
			if v:IsA("ParticleEmitter") then
				v.Enabled = false
			end
		end
		if CookerActive == true then
			CookerActive = false
			TS:Create(CookerSoup,TweenInfo.new(1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{Transparency = 1,Size = Vector3.new(23.569, 3.117, 23.569),CFrame = CookerSoupPos.CFrame  * CFrame.new(0,-8,0)}):Play()
		end
	end
end
UpdateCooker()
CookingSpots:GetAttributeChangedSignal("SpotsOccupied"):Connect(UpdateCooker)
	

-- [[ 2. SERVER EVENT HANDLER (RESTORED) ]]
IncrementalRem.OnServerEvent:Connect(function(Player, Action, Data)
	local Character = Player.Character
	if not Character then return end

	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
	local HRP = Character:FindFirstChild("HumanoidRootPart")
	local Humanoid = Character:FindFirstChild("Humanoid")
	local CharDebrisFolder = Character:FindFirstChild("CharDebris")
	local MyPlrIngredients = PlayerIngredients:FindFirstChild(Player.UserId)

	local LeaderstatValues = Player:WaitForChild("leaderstatValues")
	local PlayerStats = Player:WaitForChild("PlayerStats")
	local Experience = PlayerStats:WaitForChild("Experience")
	local MaxExperience = PlayerStats:WaitForChild("MaxExperience")
	local PlayerInfo = Player:WaitForChild("PlayerInfo")

	if Action == "EnteredDetectionZone" then
		ActiveIncrementals[Player.UserId].IngredientsCollection.SpawnTimer = 0
		ActiveIncrementals[Player.UserId].IngredientsCollection.Player = Player
		ActiveIncrementals[Player.UserId].IngredientsCollection.InDetectionZone = true
	elseif Action == "LeftDetectionZone" then
		ActiveIncrementals[Player.UserId].IngredientsCollection.SpawnTimer = nil
		ActiveIncrementals[Player.UserId].IngredientsCollection.Player = nil
		ActiveIncrementals[Player.UserId].IngredientsCollection.InDetectionZone = false
	elseif Action == "CollectedIngredient" and Data.Ingredient then
		if ActiveIncrementals[Player.UserId].IngredientsCollection.InDetectionZone == false then
			return
		end
		if Data.Ingredient.Parent ~= MyPlrIngredients then
			return
		end

		local DistFromZone = (HRP.Position - IngredientsCollectionZone.Position).Magnitude
		if DistFromZone > 60 then 
			warn(Player.Name .. " is too far from Collection Zone!")
			return 
		end

		local IngPos = Data.Ingredient:GetPivot().Position
		local DistFromItem = (HRP.Position - IngPos).Magnitude

		if DistFromItem > 45 then
			warn(Player.Name .. " tried to collect item from too far away (Exploit?)")
			return
		end

		local Ingredient = nil
		for i,v in pairs(MyPlrIngredients:GetChildren()) do
			if v == Data.Ingredient then
				Ingredient = v
				break
			end
		end
		if Ingredient == nil then
			print("Ingredient Not Found in Server!")
			return
		end

		local IngredientType = "Normal"
		if string.find(Ingredient.Name,"Golden") then
			IngredientType = "Golden"
		end
		local IngredientName = string.gsub(Ingredient.Name,"Golden","")

		--UpgradeValues
		local IngredientsPerCollect = DataStore.Value.Upgrades.IngredientsPerCollect
		local MultiIngredientsPerCollect = DataStore.Value.Upgrades.MultiplyIngredientsPerCollect
		local TotalAddedIngredients = 0
		local TotalSkillTreeMultiplier = 1
		if DataStore.Value.FarmersMarketSkillTree["x1.5Ingredients"].Unlocked == true then
			TotalSkillTreeMultiplier = 1.5
		end
		if DataStore.Value.FarmersMarketSkillTree["x3Ingredients"].Unlocked == true then
			if TotalSkillTreeMultiplier == 1 then
				TotalSkillTreeMultiplier = 3
			else
				TotalSkillTreeMultiplier += 3
			end
		end
		if DataStore.Value.FarmersMarketSkillTree["IngredientsBoostedByPlayTime"].Unlocked == true then
			if TotalSkillTreeMultiplier == 1 then
				TotalSkillTreeMultiplier = PlayerInfo.Playtime.Value
			else
				TotalSkillTreeMultiplier += PlayerInfo.Playtime.Value
			end
		end
		
		if IngredientType == "Golden" then
			TotalAddedIngredients = (IngredientsPerCollect * 3) * MultiIngredientsPerCollect

			DataStore.Value.Experience += math.random(2,3)
			Experience.Value = DataStore.Value.Experience
		else
			TotalAddedIngredients = IngredientsPerCollect * MultiIngredientsPerCollect

			DataStore.Value.Experience += math.random(1,2)
			Experience.Value = DataStore.Value.Experience
		end
		TotalAddedIngredients *= TotalSkillTreeMultiplier

		if Player:GetAttribute("x2Ingredients") == true then
			TotalAddedIngredients *= 2
		end
		TotalAddedIngredients *= PlayerInfo.IngredientMultiplierEventValue.Value

		DataStore.Value.Ingredients += TotalAddedIngredients
		DataStore.playerstats.Ingredients.Value = DataStore.Value.Ingredients

		Debris:AddItem(Ingredient,3)

		if IngredientName == "Rice" or IngredientName == "Spaghetti" or IngredientName == "Potato" then
			if ActiveIncrementals[Player.UserId].Animations.PutIngredientsInPot.IsPlaying == true or ActiveIncrementals[Player.UserId].Animations.ChopIngredients.IsPlaying == true  then
				if Character:FindFirstChild("Pot") then
					Character:FindFirstChild("Pot"):Destroy()
				end
				if Character:FindFirstChild("Knife") then
					Character:FindFirstChild("Knife"):Destroy()
				end
				for i,v in pairs(CharDebrisFolder:GetChildren()) do
					v:Destroy()
				end
				ActiveIncrementals[Player.UserId].Animations.PutIngredientsInPot:Stop()
				ActiveIncrementals[Player.UserId].Animations.ChopIngredients:Stop()
				for _,v in pairs(ActiveIncrementals[Player.UserId].Connections) do
					if v then
						v:Disconnect()
						v = nil
					end
				end
				ActiveIncrementals[Player.UserId].Connections = {}
			end

			local Pot = RS:WaitForChild("Assets").Pot:Clone()
			Pot.Parent = Character

			local CopiedIngredient = RS:WaitForChild("Assets").Ingredients[IngredientName]:Clone()
			CopiedIngredient.Parent = CharDebrisFolder
			CopiedIngredient:PivotTo(Character:FindFirstChild("LeftHand").CFrame)

			if IngredientType == "Golden" then
				for i,v in pairs(CopiedIngredient:GetDescendants()) do
					if v:IsA("BasePart") then
						v.Color = Color3.fromRGB(172, 139, 42) -- Golden Yellow
						v.Material = Enum.Material.Neon    -- Make it Glow
					end
				end
				local Vfx1 =RS:WaitForChild("Assets").VFX.BigSpark:Clone()
				Vfx1.Parent = CopiedIngredient.PrimaryPart
				local Vfx2 =RS:WaitForChild("Assets").VFX.BlackSpark:Clone()
				Vfx2.Parent = CopiedIngredient.PrimaryPart
			end

			local Weld = Instance.new("Weld")
			Weld.Parent = CopiedIngredient.PrimaryPart
			Weld.Part1 = CopiedIngredient.PrimaryPart
			Weld.Part0 = Character:FindFirstChild("LeftHand")
			Weld.C0 = CFrame.new(0,-0.35,0)

			ActiveIncrementals[Player.UserId].Animations.PutIngredientsInPot:Play()
			ActiveIncrementals[Player.UserId].Connections["PutIn"] = ActiveIncrementals[Player.UserId].Animations.PutIngredientsInPot:GetMarkerReachedSignal("PutIn"):Once(function()
				Weld:Destroy()
				CopiedIngredient:PivotTo(Pot.IngredientPosition.CFrame)
				local Weld2 = Instance.new("Weld")
				Weld2.Parent = CopiedIngredient.PrimaryPart
				Weld2.Part1 = CopiedIngredient.PrimaryPart
				Weld2.Part0 = Pot.IngredientPosition
				if IngredientName == "Spaghetti" then
					Weld2.C0 = CFrame.new(0,0.3,0)
					Weld2.C1 = CFrame.Angles(math.rad(30),0,0)
				else
					Weld2.C0 = CFrame.new(0,0.25,0)
				end
				local WaterBoilSFX = SFX.WaterBoilShort:Clone()
				WaterBoilSFX.Parent = Pot.PrimaryPart
				WaterBoilSFX:Play()
				Debris:AddItem(WaterBoilSFX,1)

			end)
			ActiveIncrementals[Player.UserId].Connections["Shake"] = ActiveIncrementals[Player.UserId].Animations.PutIngredientsInPot:GetMarkerReachedSignal("Shake"):Once(function()
				print("Shake it.")
			end)
			ActiveIncrementals[Player.UserId].Connections["Toss"] = ActiveIncrementals[Player.UserId].Animations.PutIngredientsInPot:GetMarkerReachedSignal("Toss"):Once(function()
				Pot.Parent = CharDebrisFolder
				local BV = Instance.new("BodyVelocity")
				BV.Parent = Pot.PrimaryPart
				BV.MaxForce = Vector3.new(9999,9999,9999)
				BV.Velocity = HRP.CFrame.RightVector * 25 + Vector3.new(0,15,5)
				Debris:AddItem(BV,0.15)
				Debris:AddItem(CopiedIngredient,0.85)
				Debris:AddItem(Pot,1)
			end)
			ActiveIncrementals[Player.UserId].Connections["EndedPot"] = ActiveIncrementals[Player.UserId].Animations.PutIngredientsInPot.Ended:Once(function()
				print("Animation Ended")
				if Character:FindFirstChild("Pot") then
					Character:FindFirstChild("Pot"):Destroy()
				end
				if Character:FindFirstChild("Knife") then
					Character:FindFirstChild("Knife"):Destroy()
				end
				for i,v in pairs(CharDebrisFolder:GetChildren()) do
					v:Destroy()
				end
				for _,v in pairs(ActiveIncrementals[Player.UserId].Connections) do
					if v then
						v:Disconnect()
						v = nil
					end
				end
				ActiveIncrementals[Player.UserId].Connections = {}
			end)

		else
			if ActiveIncrementals[Player.UserId].Animations.PutIngredientsInPot.IsPlaying == true or ActiveIncrementals[Player.UserId].Animations.ChopIngredients.IsPlaying == true  then
				if Character:FindFirstChild("Pot") then
					Character:FindFirstChild("Pot"):Destroy()
				end
				if Character:FindFirstChild("Knife") then
					Character:FindFirstChild("Knife"):Destroy()
				end
				for i,v in pairs(CharDebrisFolder:GetChildren()) do
					v:Destroy()
				end
				ActiveIncrementals[Player.UserId].Animations.PutIngredientsInPot:Stop()
				ActiveIncrementals[Player.UserId].Animations.ChopIngredients:Stop()
				for _,v in pairs(ActiveIncrementals[Player.UserId].Connections) do
					if v then
						v:Disconnect()
						v = nil
					end
				end
				ActiveIncrementals[Player.UserId].Connections = {}
			end

			local Knife = RS:WaitForChild("Assets").Knife:Clone()
			Knife.Parent = Character
			local ChoppingBoard = RS:WaitForChild("Assets").ChoppingBoard:Clone()
			ChoppingBoard.Parent = CharDebrisFolder
			ChoppingBoard:PivotTo(Character:FindFirstChild("LeftHand").CFrame)

			local BoardWeld = Instance.new("Weld")
			BoardWeld.Parent = ChoppingBoard.PrimaryPart
			BoardWeld.Part1 = ChoppingBoard.PrimaryPart
			BoardWeld.Part0 = Character:FindFirstChild("LeftHand")
			BoardWeld.C0 = CFrame.new(0,-0.25,0)
			BoardWeld.C1 = CFrame.Angles(0,math.rad(180),0)

			local CopiedIngredient = RS:WaitForChild("Assets").Ingredients[IngredientName]:Clone()
			CopiedIngredient.Parent = CharDebrisFolder
			CopiedIngredient:PivotTo(ChoppingBoard.PrimaryPart.CFrame)

			if IngredientType == "Golden" then
				for i,v in pairs(CopiedIngredient:GetDescendants()) do
					if v:IsA("BasePart") then
						v.Color = Color3.fromRGB(172, 139, 42) -- Golden Yellow
						v.Material = Enum.Material.Neon    -- Make it Glow
					end
				end
				local Vfx1 =RS:WaitForChild("Assets").VFX.BigSpark:Clone()
				Vfx1.Parent = CopiedIngredient.PrimaryPart
				local Vfx2 =RS:WaitForChild("Assets").VFX.BlackSpark:Clone()
				Vfx2.Parent = CopiedIngredient.PrimaryPart
			end

			local IngWeld = Instance.new("Weld")
			IngWeld.Parent = CopiedIngredient.PrimaryPart
			IngWeld.Part1 = CopiedIngredient.PrimaryPart
			IngWeld.Part0 = ChoppingBoard.PrimaryPart
			IngWeld.C0 = CFrame.new(0, 0.55, 2.25)
			
			local ChopIngredientSFX = SFX.ChopIngredient:Clone()
			ChopIngredientSFX.Parent = ChoppingBoard.PrimaryPart
			ChopIngredientSFX:Play()
			Debris:AddItem(ChopIngredientSFX,1)

			ActiveIncrementals[Player.UserId].Animations.ChopIngredients:Play()
			ActiveIncrementals[Player.UserId].Connections["Chop"] = ActiveIncrementals[Player.UserId].Animations.ChopIngredients:GetMarkerReachedSignal("Chop"):Once(function()
				
				for i,v in pairs(CopiedIngredient:GetDescendants()) do
					if v:IsA("Weld") then
						v:Destroy()
					end
					if v:IsA("BasePart") then
						local BV = Instance.new("BodyVelocity")
						BV.Parent = v
						BV.MaxForce = Vector3.new(5,5,5)
						BV.Velocity = Vector3.new(math.random(-90,90),7.5,math.random(-90,90))
						Debris:AddItem(BV,0.025)
					end
				end
				
				--ActiveIncrementals[Player.UserId].Animations.ChopIngredients:AdjustSpeed(0)
			end)
			ActiveIncrementals[Player.UserId].Connections["TossKnife"] = ActiveIncrementals[Player.UserId].Animations.ChopIngredients:GetMarkerReachedSignal("TossKnife"):Once(function()
				Knife.Parent = CharDebrisFolder
				local BV = Instance.new("BodyVelocity")
				BV.Parent = Knife.PrimaryPart
				BV.MaxForce = Vector3.new(9999,9999,9999)
				BV.Velocity = HRP.CFrame.RightVector * 25 + Vector3.new(0,15,5)
				Debris:AddItem(BV,0.15)
				
				local TossknifeSFX = SFX.TossKnife:Clone()
				TossknifeSFX.Parent = ChoppingBoard.PrimaryPart
				TossknifeSFX:Play()
				Debris:AddItem(TossknifeSFX,1)
			end)
			ActiveIncrementals[Player.UserId].Connections["TossChopBoard"] = ActiveIncrementals[Player.UserId].Animations.ChopIngredients:GetMarkerReachedSignal("TossChopBoard"):Once(function()
				BoardWeld:Destroy()
				local BV = Instance.new("BodyVelocity")
				BV.Parent = ChoppingBoard.PrimaryPart
				BV.MaxForce = Vector3.new(9999,9999,9999)
				BV.Velocity = HRP.CFrame.RightVector * -25 + Vector3.new(0,15,5)
				Debris:AddItem(BV,0.15)
			end)
			ActiveIncrementals[Player.UserId].Connections["EndedChopping"] = ActiveIncrementals[Player.UserId].Animations.ChopIngredients.Ended:Once(function()
				print("Animation Ended")
				if Character:FindFirstChild("Pot") then
					Character:FindFirstChild("Pot"):Destroy()
				end
				if Character:FindFirstChild("Knife") then
					Character:FindFirstChild("Knife"):Destroy()
				end
				for i,v in pairs(CharDebrisFolder:GetChildren()) do
					v:Destroy()
				end
				for _,v in pairs(ActiveIncrementals[Player.UserId].Connections) do
					if v then
						v:Disconnect()
						v = nil
					end
				end
				ActiveIncrementals[Player.UserId].Connections = {}

			end)
		end

	elseif Action == "OccupyingSpot" and Data.CookingSpot  then
		local CookingSpot = Data.CookingSpot
		local OccupantValue = CookingSpot.Occupant
		OccupantValue.Value = Player.Name
		local SpotIndicator = CookingSpot.SpotIndication
		SpotIndicator.Color = Color3.fromRGB(255, 147, 53)

	elseif Action == "UnoccupyingSpot" and Data.CookingSpot then
		local CookingSpot = Data.CookingSpot
		local OccupantValue = CookingSpot:FindFirstChild("Occupant")

		-- SECURITY: Only let them unoccupy if THEY own it
		if OccupantValue and OccupantValue.Value == Player.Name then
			OccupantValue.Value = "Vacant"
			local SpotIndicator = CookingSpot:FindFirstChild("SpotIndication")
			if SpotIndicator then
				SpotIndicator.Color = Color3.fromRGB(143, 142, 145)
			end
		end

	elseif Action == "StopCooking" then
		-- 1. SAFELY FIND THE COOKING SPOT
		local spotName = Character:GetAttribute("CookingSpotOccupying")
		if not spotName or spotName == "None" then return end -- Abort if already cleaned up

		local CookingSpot = FoodCollection.CookingPot.CookingSpots:FindFirstChild(spotName)
		if not CookingSpot then return end

		local CookingLadder = CookingSpot:FindFirstChild("CookingLadder")

		-- 2. SAFELY HANDLE FOOD BOXES
		if CookingLadder then
			task.spawn(function()
				local FoodBoxes = CookingLadder:FindFirstChild("FoodBoxes")
				if FoodBoxes then
					if FoodBoxes:FindFirstChild("CurrentFoodBox") then
						FoodBoxes:FindFirstChild("CurrentFoodBox"):Destroy()		
					end

					if not (FoodBoxes:FindFirstChild("FakeFoodBox") or FoodBoxes:FindFirstChild("FoodBoxCover")) then
						FoodBoxes:Destroy()
						-- Safely disconnect
						if ActiveIncrementals[Player.UserId] and ActiveIncrementals[Player.UserId].Connections then
							local conn = ActiveIncrementals[Player.UserId].Connections
							if conn.FoodBoxVal then conn.FoodBoxVal:Disconnect(); conn.FoodBoxVal = nil end
							if conn.CurrentFoodBoxesCount then conn.CurrentFoodBoxesCount:Disconnect(); conn.CurrentFoodBoxesCount = nil end
							if conn.CharFoodInCurrBox then conn.CharFoodInCurrBox:Disconnect(); conn.CharFoodInCurrBox = nil end
						end
						return
					end		

					-- [[ THE FIX: Fallback to Torso or HRP if UpperTorso is missing ]]
					local Torso = Character:FindFirstChild("UpperTorso") or Character:FindFirstChild("Torso") or Character:FindFirstChild("HumanoidRootPart")

					if Torso then
						local FakeFoodBox = FoodBoxes:FindFirstChild("FakeFoodBox")
						local FoodBoxOrigPosPart = FoodBoxes.PrimaryPart

						FoodBoxes:PivotTo(Torso.CFrame)
						FoodBoxes.Parent = PlayerFoodBoxes[Player.UserId]

						local Weld2 = Instance.new("Weld")
						Weld2.Name = "FoodBoxCharweld"
						Weld2.Parent = FoodBoxes.PrimaryPart
						Weld2.Part0 = Torso
						Weld2.Part1 = FoodBoxes.PrimaryPart
						Weld2.C0 = CFrame.new(0,3,0)

						if FakeFoodBox then
							for i,v in pairs(FakeFoodBox:GetChildren()) do
								if v:IsA("BasePart") then
									v.Size = Vector3.new(v.Size.X,2*DataStore.Value.CurrentFoodBoxes,v.Size.Z)
								end
							end
							FakeFoodBox:PivotTo(FoodBoxOrigPosPart.CFrame * CFrame.new(0,(FoodBoxOrigPosPart.Size.Y/2+FakeFoodBox.PrimaryPart.Size.Y/2)-FoodBoxOrigPosPart.Size.Y,0))

							local Weld = Instance.new("WeldConstraint")
							Weld.Name = "RootWeld"
							Weld.Parent = FakeFoodBox.PrimaryPart
							Weld.Part0 = FoodBoxOrigPosPart
							Weld.Part1 = FakeFoodBox.PrimaryPart

							local FoodBoxCover = FoodBoxes:FindFirstChild("FoodBoxCover")
							if FoodBoxCover then
								FoodBoxCover:PivotTo(FakeFoodBox.PrimaryPart.CFrame * CFrame.new(0,(FakeFoodBox.PrimaryPart.Size.Y/2+FoodBoxCover.PrimaryPart.Size.Y/2),0))
								local Weld3 = Instance.new("WeldConstraint")
								Weld3.Name = "CoverWeld"
								Weld3.Parent = FoodBoxCover.PrimaryPart
								Weld3.Part0 = FakeFoodBox.PrimaryPart
								Weld3.Part1 = FoodBoxCover.PrimaryPart
							end
						end

						for i,v in pairs(FoodBoxes:GetDescendants()) do
							if v:IsA("BasePart") then
								v.Anchored = false
								v.Massless = true
							end
						end
					else
						-- If the player's body was completely destroyed, just delete the box to prevent errors
						-- (It will automatically regenerate next time they spawn anyway)
						FoodBoxes:Destroy()
					end
				end		
			end)
		end

		-- 3. SAFELY FREE THE SPOT
		local OccupantValue = CookingSpot:FindFirstChild("Occupant")
		if OccupantValue and OccupantValue.Value == Player.Name then
			OccupantValue.Value = "Vacant"
			CookingSpot.Occupied.Value = false
			CookingSpot.SpotIndication.Color = Color3.fromRGB(143, 142, 145)

			RecalculateSpotsOccupied()
		end

		-- 4. CLEANUP CHARACTER & STATE
		Character:SetAttribute("UsingCooker", false)
		Character:SetAttribute("CookingSpotOccupying", "None")

		-- Ensure ActiveIncrementals still exists before trying to stop animations
		if ActiveIncrementals[Player.UserId] then
			if ActiveIncrementals[Player.UserId].Animations.StirringFood then
				ActiveIncrementals[Player.UserId].Animations.StirringFood:Stop()
			end
			if ActiveIncrementals[Player.UserId].Animations.CookingIdle then
				ActiveIncrementals[Player.UserId].Animations.CookingIdle:Stop()
			end

			ActiveIncrementals[Player.UserId].FoodCollection.Player = nil
			ActiveIncrementals[Player.UserId].FoodCollection.CookingSpot = nil
			ActiveIncrementals[Player.UserId].FoodCollection.InCookingSpot = false
		end

		if Character:FindFirstChild("Spoon") then
			Character:FindFirstChild("Spoon"):Destroy()
		end
		if workspace.Debris:FindFirstChild(Player.Name.."StirVFX") then
			workspace.Debris:FindFirstChild(Player.Name.."StirVFX"):Destroy()
		end

		if HRP then HRP.Anchored = false end
		if Humanoid then
			local savedSpeed = DataStore.Value.Upgrades.SpeedWithRebirths
			Humanoid.WalkSpeed = (savedSpeed and savedSpeed > 16) and savedSpeed or 16
			Humanoid.JumpPower = 50
		end

		task.wait(0.1)

		if CookingSpot:FindFirstChild("CookingSpot") and CookingSpot.CookingSpot:FindFirstChild("Prompt") then
			CookingSpot.CookingSpot.Prompt.Enabled = true
		end

		for _, v in pairs(Character:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CollisionGroup = "Players"
			end
		end

		-- [[ THE FIX: Instantly hide the ladder instead of tweening it ]]
		if CookingLadder then
			for _,v in pairs(CookingLadder:GetChildren()) do
				if v:IsA("BasePart") then
					if v.Name == "FoodBoxPlatform" then
						v:Destroy()
					else
						v.CanCollide = false
						v.CollisionGroup = "Items"
						v.Transparency = 1
					end
				end
			end
		end
	end
end)

-- [[ 3. MAIN INCREMENTAL LOOPS ]]
local function SpawnFoodVisual(Player, CookingSpot,FoodType)
	local Character = Player.Character
	if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)

	-- 1. Get Random Food Model
	local AvailableFoods = FoodStorage:GetChildren()
	if #AvailableFoods == 0 then return end
	local FoodModel = AvailableFoods[math.random(1, #AvailableFoods)]:Clone()
	for i,v in pairs(FoodModel:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = false
			v.CanQuery = false
			v.CanTouch = false
		end
	end
	local WaterDropSFX = SFX.WaterDrop:Clone()
	WaterDropSFX.Parent = FoodModel.PrimaryPart
	WaterDropSFX:Play()
	Debris:AddItem(WaterDropSFX,1)
	
	local CheckGoldBuffBindable = SS:WaitForChild("Modules"):FindFirstChild("CheckGoldBuff")
	local HasBuffActive = false
	if CheckGoldBuffBindable then
		HasBuffActive = CheckGoldBuffBindable:Invoke(Player,"Food")
	end
	if HasBuffActive == true then
		FoodType = "Golden"
	end
	

	if FoodType == "Golden" then
		FoodModel.Name = "Golden" .. FoodModel.Name 

		-- Add VFX (Sparkles)
		local Vfx1 =RS:WaitForChild("Assets").VFX.BigSpark:Clone()
		Vfx1.Parent = FoodModel.PrimaryPart
		local Vfx2 =RS:WaitForChild("Assets").VFX.BlackSpark:Clone()
		Vfx2.Parent = FoodModel.PrimaryPart
	end

	local StartPos = CookingSpot.CookingPosition.Position
	local StirVFX = workspace.Debris:FindFirstChild(Player.Name.."StirVFX")

	if StirVFX then
		StartPos = StirVFX.Position
	else
		-- Approximate location if VFX is missing for some reason
		StartPos = Character.HumanoidRootPart.CFrame * CFrame.new(0,-2.05,-3.5).Position
	end

	-- Setup Model
	FoodModel.Parent = workspace.Debris
	FoodModel:PivotTo(CFrame.new(StartPos))

	-- 3. ANIMATION COROUTINE
	-- Run this in a spawn so it doesn't yield the main script
	task.spawn(function()
		local t = 0
		local Duration = 0.7 -- How fast it flies to player (seconds)
		local StartTime = os.clock()

		-- Randomize the arch height slightly so they don't all look identical
		local ArchHeight = math.random(11, 14) 
		local BendLength = math.random(-5,5)
		-- Loop until t reaches 1
		while t < 1 do
			local HRP = Character:FindFirstChild("HumanoidRootPart")
			if not HRP then break end

			local CurrentTime = os.clock() - StartTime
			t = CurrentTime / Duration
			if t > 1 then t = 1 end

			-- [[ BEZIER CALCULATION ]]
			local P0 = StartPos -- Start
			local P2 = HRP.Position -- Target (Updated every frame to track player)
			if DataStore.Value.FarmersMarketSkillTree["UnlockFarmersMarket"].Unlocked == true then
				if CookingSpot.CookingLadder:FindFirstChild("FoodBoxPlatform") then
					P2 = CookingSpot.CookingLadder.FoodBoxPlatform.Position
				end
			end

			-- Calculate P1 (Control Point)
			-- We put P1 between P0 and P2, but raised up by ArchHeight
			local MidPoint = P0:Lerp(P2, 0.5)
			local P1 = MidPoint + Vector3.new(BendLength, ArchHeight, 5)

			-- Get Position
			local NextPos = BezierModule:quadBezier(t, P0, P1, P2)

			-- Move and Rotate the food
			-- Adding rotation makes it look more dynamic
			FoodModel:PivotTo(CFrame.new(NextPos) * CFrame.Angles(t * 10, t * 5, 0))

			RunService.Heartbeat:Wait()
		end

		-- 4. Cleanup
		-- Optional: Play a small particle or sound here when it hits the player
		local WhooshSwish = SFX.WhooshSwish:Clone()
		WhooshSwish.Parent = FoodModel.PrimaryPart
		WhooshSwish:Play()
		Debris:AddItem(WhooshSwish,0.75)

		for i,v in pairs(FoodModel:GetChildren()) do
			if v:IsA("BasePart") then
				v.Material = Enum.Material.Neon
				if FoodType == "Golden" then
					v.Color = Color3.fromRGB(255, 217, 2)
				else
					v.Color = Color3.fromRGB(255, 255, 255)
				end
				TS:Create(v,TweenInfo.new(0.75),{Transparency = 1}):Play()
			end
		end
		for i = 1,1.9,0.05 do
			if i >= 1.85 then
				FoodModel:Destroy()
				break
			end
			FoodModel:ScaleTo(i)
			RunService.Heartbeat:Wait()
		end
	end)
end

local function UpdateFoodBoxes(DataStore, Incremental)
	if not (Incremental.CookingSpot or Incremental) then
		return
	end
	if DataStore.Value.FarmersMarketSkillTree["UnlockFarmersMarket"].Unlocked == false then
		return
	end
	if not (Incremental.CookingSpot.CookingLadder.FoodBoxPlatform or Incremental.CookingSpot.CookingLadder.FoodBoxes) then
		return	
	end
	local Player = Incremental.Player
	local Character = Player.Character
	if not Player or not Character then
		return
	end
	
	local FoodBoxes = Incremental.CookingSpot.CookingLadder.FoodBoxes
	local FoodBoxPlatform = Incremental.CookingSpot.CookingLadder.FoodBoxPlatform
	local CurrentFoodBox:Model = nil
	local FoodBoxCover:Model = nil 
	local OrigPosBox = FoodBoxes.FoodBoxOrigPos
	local CurrentFoodBoxes:NumberValue = DataStore.playerstats.CurrentFoodBoxes

	if FoodBoxes:FindFirstChild("CurrentFoodBox") then
		CurrentFoodBox = FoodBoxes.CurrentFoodBox
		if Character:GetAttribute("FoodInCurrentBox") < CurrentFoodBox:GetAttribute("AmountStorable") then
			return
		end
		Character:SetAttribute("FoodInCurrentBox",0)
		CurrentFoodBox:SetAttribute("AmountStorable",10)
		
		print("Added To CurrentBoxes")
		DataStore.Value.CurrentFoodBoxes += 1
		DataStore.playerstats.CurrentFoodBoxes.Value = DataStore.Value.CurrentFoodBoxes
		FoodBoxes:SetAttribute("FoodBoxCount",DataStore.Value.CurrentFoodBoxes)
		
		if not FoodBoxes:FindFirstChild("FakeFoodBox") then
			local FakeFoodBox = RS:WaitForChild("Assets").FakeFoodBox:Clone()
			FakeFoodBox.Parent = FoodBoxes
			FakeFoodBox:PivotTo(CurrentFoodBox:GetPivot())

			FoodBoxCover = RS:WaitForChild("Assets").FoodBoxCover:Clone()
			FoodBoxCover.Parent = FoodBoxes

			OrigPosBox.CFrame = FoodBoxPlatform.CFrame * CFrame.new(0,(FoodBoxPlatform.Size.Y/2+OrigPosBox.Size.Y/2),0)
			FoodBoxes.PrimaryPart = OrigPosBox

			--Stores Original Sizes Once.-->
		else
			local BoxCount = DataStore.Value.CurrentFoodBoxes
			local FakeFoodBox = FoodBoxes:FindFirstChild("FakeFoodBox")
			for i,v in pairs(FakeFoodBox:GetChildren()) do
				if v:IsA("BasePart") then
					v.Size = Vector3.new(v.Size.X,2*BoxCount,v.Size.Z)
				end
			end
			FoodBoxCover = FoodBoxes:FindFirstChild("FoodBoxCover")
			FakeFoodBox:PivotTo(FoodBoxPlatform.CFrame * CFrame.new(0,FoodBoxPlatform.Size.Y/2+FakeFoodBox.PrimaryPart.Size.Y/2,0))
		end
	end
	local NewCurrentFoodBox = RS:WaitForChild("Assets").FoodBox:Clone()
	NewCurrentFoodBox.Parent = FoodBoxes
	NewCurrentFoodBox.Name = "CurrentFoodBox"
	NewCurrentFoodBox.Root.RightCover.C1 = CFrame.new(-0.7,0.8,0) * CFrame.Angles(math.rad(0),math.rad(0),math.rad(-120))
	NewCurrentFoodBox.Root.LeftCover.C1 = CFrame.new(-0.7,-0.8,0) * CFrame.Angles(math.rad(0),math.rad(0),math.rad(120))
	
	local FakeFoodBox = FoodBoxes:FindFirstChild("FakeFoodBox")
	local FoodBoxCover = FoodBoxes:FindFirstChild("FoodBoxCover")
	
	if CurrentFoodBox and FakeFoodBox then
		print("Current Food Box Tweened")
		local FakeRoot = FakeFoodBox.PrimaryPart or FakeFoodBox:FindFirstChild("Root")
		local NewRoot = NewCurrentFoodBox.PrimaryPart

		-- Start position for the tween (high up)
		NewCurrentFoodBox:PivotTo(FakeRoot.CFrame * CFrame.new(0, (FakeRoot.Size.Y / 2) + (NewRoot.Size.Y / 2) + 7.5, 0))

		-- Tween target (flush against the top of the FakeFoodBox)
		local TargetCFrame = FakeRoot.CFrame * CFrame.new(0, (FakeRoot.Size.Y / 2) + (NewRoot.Size.Y / 2), 0)
		TS:Create(NewRoot, TweenInfo.new(0.75, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {CFrame = TargetCFrame}):Play()

		-- Adjust Cover
		if FoodBoxCover then
			local CoverRoot = FoodBoxCover.PrimaryPart
			FoodBoxCover:PivotTo(FakeRoot.CFrame * CFrame.new(0, (FakeRoot.Size.Y / 2) + (CoverRoot.Size.Y / 2), 0))
		end

		CurrentFoodBox:Destroy()

	elseif FakeFoodBox then
		print("Fake Food Box Tweened")
		local FakeRoot = FakeFoodBox.PrimaryPart or FakeFoodBox:FindFirstChild("Root")
		local NewRoot = NewCurrentFoodBox.PrimaryPart

		NewCurrentFoodBox:PivotTo(FakeRoot.CFrame * CFrame.new(0, (FakeRoot.Size.Y / 2) + (NewRoot.Size.Y / 2) + 7.5, 0))

		local TargetCFrame = FakeRoot.CFrame * CFrame.new(0, (FakeRoot.Size.Y / 2) + (NewRoot.Size.Y / 2), 0)
		TS:Create(NewRoot, TweenInfo.new(0.6, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {CFrame = TargetCFrame}):Play()
	else
		-- Very first box ever spawned on the empty platform
		local NewRoot = NewCurrentFoodBox.PrimaryPart
		NewCurrentFoodBox:PivotTo(FoodBoxPlatform.CFrame * CFrame.new(0, (FoodBoxPlatform.Size.Y / 2) + (NewRoot.Size.Y / 2) + 7.5, 0))

		local TargetCFrame = FoodBoxPlatform.CFrame * CFrame.new(0, (FoodBoxPlatform.Size.Y / 2) + (NewRoot.Size.Y / 2), 0)
		TS:Create(NewRoot, TweenInfo.new(0.6, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {CFrame = TargetCFrame}):Play()
	end
end

local function UpdateFoodIncremental(deltaTime, Incremental)
	-- 1. VALIDATION
	if not Incremental.CookingSpot or not Incremental.Player or not Incremental.InCookingSpot then 
		return 
	end

	local Player = Incremental.Player
	local Character = Player.Character
	if not Character or not Character.Parent then return end

	-- 2. GET DATA
	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
	if not DataStore then return end

	local Upgrades = DataStore.Value.Upgrades

	local PlayerStats = Player.PlayerStats
	local Experience = PlayerStats.Experience
	local MaxExperience = PlayerStats.MaxExperience
	local PlayerInfo = Player.PlayerInfo
	-- 3. GET STATS & UPGRADES
	local SpeedVal = Upgrades.CookingSpeed 
	local FoodPerIngVal = Upgrades.FoodPerIngredients
	local MultiFoodVal = Upgrades.MultiplyFoodPerIngredients
	local GoldenChanceVal = Upgrades.ChanceOfGoldenFood
	local FarmersMarketSkillTree = PlayerStats.FarmersMarketSkillTree
	local IngredientCost = 25

	if DataStore.Value.FarmersMarketSkillTree["20IngredientsPerFood"].Unlocked == true then
		IngredientCost = 20
	end
	if DataStore.Value.FarmersMarketSkillTree["10IngredientsPerFood"].Unlocked == true then
		IngredientCost = 10
	end
	if DataStore.Value.FarmersMarketSkillTree["2IngredientsPerFood"].Unlocked == true then
		IngredientCost = 2
	end
	-- 4. TIMER LOGIC
	Incremental.CookTimer = (Incremental.CookTimer or 0) + deltaTime

	-- [[ ANIMATION & STATE LOGIC ]] --
	local CurrentIngredients = DataStore.Value.Ingredients
	local MyAnimations = ActiveIncrementals[Player.UserId].Animations
	local StirAnim = MyAnimations.StirringFood
	local IdleAnim = MyAnimations.CookingIdle

	-- If less than 25 ingredients
	if CurrentIngredients < IngredientCost then
		-- Check if we need to switch state to Idle
		if not IdleAnim.IsPlaying then
			StirAnim:Stop()
			IdleAnim:Play()
			NotifModule.Notify(Player,"You Need More Ingredients!")
			IdleAnim.Priority = Enum.AnimationPriority.Action
			print("NOT ENOUGH INCGREDIENTS!")

			local StirVFX = workspace.Debris:FindFirstChild(Player.Name.."StirVFX")
			if StirVFX then 
				StirVFX.Attachment.SplashSpla.Enabled = false  
				StirVFX.Attachment.Swirl.Enabled = false  
			end
		end

		-- RETURN early so we don't process cooking logic
		return 
	else
		if IdleAnim.IsPlaying then
			IdleAnim:Stop()
			StirAnim:Play()
			print("YOU GOT ENOUGH INCGREDIENTS!")

			-- Restore VFX if needed
			local StirVFX = workspace.Debris:FindFirstChild(Player.Name.."StirVFX")
			if StirVFX then 
				StirVFX.Attachment.SplashSpla.Enabled = true  
				StirVFX.Attachment.Swirl.Enabled = true  
			end
		end
	end

	UpdateFoodBoxes(DataStore,Incremental)
	-- 5. CONVERSION LOGIC (Only runs if ingredients >= 25)
	if Incremental.CookTimer >= SpeedVal then
		Incremental.CookTimer = 0 -- Reset Timer

		-- Deduct Cost
		DataStore.Value.Ingredients -= IngredientCost
		DataStore.playerstats.Ingredients.Value = DataStore.Value.Ingredients

		-- Calculate Reward
		local EarnedExp = math.random(1,2)
		local BaseReward = FoodPerIngVal
		local TotalSkillTreeMultiplier = 1
		local TotalReward = BaseReward * MultiFoodVal
		local IsGolden = false
		local FoodType = "Normal"
		if DataStore.Value.FarmersMarketSkillTree["x1.5Food"].Unlocked == true then
			TotalSkillTreeMultiplier = 1.5
		end
		if DataStore.Value.FarmersMarketSkillTree["x3Food"].Unlocked == true then
			if TotalSkillTreeMultiplier == 1 then
				TotalSkillTreeMultiplier = 3
			else
				TotalSkillTreeMultiplier += 3
			end
		end
		if DataStore.Value.RestaurantSkillTree["x5Food"].Unlocked == true then
			if TotalSkillTreeMultiplier == 1 then
				TotalSkillTreeMultiplier = 5
			else
				TotalSkillTreeMultiplier += 5
			end
		end
		if DataStore.Value.FarmersMarketSkillTree["FoodBoostedByPlayTime"].Unlocked == true then
			if TotalSkillTreeMultiplier == 1 then
				TotalSkillTreeMultiplier = PlayerInfo.Playtime.Value
			else
				TotalSkillTreeMultiplier += PlayerInfo.Playtime.Value
			end
		end
		if DataStore.Value.FarmersMarketSkillTree["FoodMultipliedByLevel"].Unlocked == true then
			if TotalSkillTreeMultiplier == 1 then
				TotalSkillTreeMultiplier = DataStore.Value.Level
			else
				TotalSkillTreeMultiplier += DataStore.Value.Level
			end
		end
		
		local CheckGoldBuffBindable = SS:WaitForChild("Modules"):FindFirstChild("CheckGoldBuff")
		local HasBuffActive = false
		if CheckGoldBuffBindable then
			HasBuffActive = CheckGoldBuffBindable:Invoke(Player,"Food")
		end

		-- If they have the buff, it's 100% golden. Otherwise, roll the normal chance.
		-- Golden Chance Check
		if HasBuffActive == true or math.random(1, 100) <= GoldenChanceVal then
			IsGolden = true
			TotalReward = (BaseReward * 3) * MultiFoodVal
			EarnedExp = math.random(3,4)
		end
		if IsGolden == true  then
			FoodType = "Golden"
		end
		TotalReward *= TotalSkillTreeMultiplier
		if Player:GetAttribute("x2Food") == true then
			TotalReward *= 2
		end
		TotalReward *= PlayerInfo.FoodMultiplierEventValue.Value

		-- Add Food
		if Player:FindFirstChild("leaderstatValues") and Player.leaderstatValues:FindFirstChild("Food") then
			if DataStore.Value.FarmersMarketSkillTree["UnlockFarmersMarket"].Unlocked == false then
				Player.leaderstatValues.Food.Value += TotalReward
			end
			DataStore.Value.Experience += EarnedExp
			Experience.Value = DataStore.Value.Experience

			if DataStore.Value.FarmersMarketSkillTree["UnlockFarmersMarket"].Unlocked == true then
				DataStore.Value.FoodBoxesValue += TotalReward
				DataStore.playerstats.FoodBoxesValue.Value = DataStore.Value.FoodBoxesValue
				
				if Incremental.CookingSpot.CookingLadder.FoodBoxes.CurrentFoodBox then
					local CurrentFoodBox:Model = Incremental.CookingSpot.CookingLadder.FoodBoxes.CurrentFoodBox
					Character:SetAttribute("FoodInCurrentBox",Character:GetAttribute("FoodInCurrentBox")+1)
				end
				
			end
			SpawnFoodVisual(Player, Incremental.CookingSpot,FoodType)
		end
	end
end

local function SpawnIngredientsIncremental(deltaTime, Incremental)
	if Incremental.InDetectionZone == false then
		return
	end
	if not Incremental.MyPlrIngredients then
		return
	end
	if not Incremental.SpawnTimer then
		return
	end
	if not Incremental.Player or not Incremental.Player.Parent then
		return
	end
	local Player = Incremental.Player
	local Character = Player.Character
	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
	if not Character or not Character.Parent then return end
	local Humanoid = Character.Humanoid
	if not Humanoid then return end
	if Humanoid.Health <= 0 then return end
	local HRP = Character.HumanoidRootPart
	if not HRP then return end
	local MyIngredients = Incremental.MyPlrIngredients

	local Upgrades = DataStore.Value.Upgrades
	local IngredientsSpawnSpeed = Upgrades.IngredientsSpawnSpeed
	local MaxAmountofIngredients = Upgrades.MaxAmountofIngredients
	local ChanceOfGoldenIngredients = Upgrades.ChanceOfGoldenIngredients

	Incremental.SpawnTimer += deltaTime
	if Incremental.SpawnTimer >= IngredientsSpawnSpeed then
		if #MyIngredients:GetChildren() < MaxAmountofIngredients then
			Incremental.SpawnTimer = 0 

			local AvailableIngredients = IngredientsStorage:GetChildren()
			if #AvailableIngredients > 0 then
				local RandIngredient = AvailableIngredients[math.random(1, #AvailableIngredients)]:Clone()

				local IsGolden = false

				-- NEW: Check if the player bought the 5-minute buff
				local CheckGoldBuffBindable = SS:WaitForChild("Modules"):FindFirstChild("CheckGoldBuff")
				local HasBuffActive = false
				if CheckGoldBuffBindable then
					HasBuffActive = CheckGoldBuffBindable:Invoke(Player,"Ingredients")
				end

				-- If they have the buff, it's 100% golden. Otherwise, roll the normal chance.
				if HasBuffActive == true or (math.random(1, 100) <= ChanceOfGoldenIngredients) then
					IsGolden = true
					-- Add identifier for server/client detection
					RandIngredient.Name = "Golden" .. RandIngredient.Name 

					-- Add VFX (Sparkles)
					local Vfx1 =RS:WaitForChild("Assets").VFX.BigSpark:Clone()
					Vfx1.Parent = RandIngredient.PrimaryPart
					local Vfx2 =RS:WaitForChild("Assets").VFX.BlackSpark:Clone()
					Vfx2.Parent = RandIngredient.PrimaryPart
				end

				for i,v in pairs(RandIngredient:GetChildren()) do
					if v:IsA("BasePart") then
						v.CollisionGroup = "Items"
						v.Anchored = true

						-- Visual Change for Golden Items
						if IsGolden == true then
							v.Color = Color3.fromRGB(172, 139, 42) -- Golden Yellow
							v.Material = Enum.Material.Neon    -- Make it Glow
						end
					end
				end

				RandIngredient:ScaleTo(math.random(10,14)/10) 

				local TargetZone = IngredientsCollectionZone
				local SpawnCF = GetRandomSurfaceCFrame(TargetZone)
				local HeightOffset = RandIngredient.PrimaryPart.Size.Y / 2

				RandIngredient:PivotTo(SpawnCF * CFrame.new(0, HeightOffset, 0) * CFrame.Angles(0, math.rad(math.random(0,360)), 0))
				RandIngredient.Parent = MyIngredients
			end
		end
	end
	--print(Incremental)

end

RunService.Heartbeat:Connect(function(deltaTime)
	if CookerActive then
		task.wait(1.5)
		BoilingTimer = BoilingTimer + deltaTime
		if BoilingTimer >= BoilingRate then
			BoilingTimer = 0
			-- Spawn a bubble (or multiple for intensity)
			SpawnBoilingBubble()
			-- Optional: Spawn another for more density
			if math.random() > 0.5 then
				SpawnBoilingBubble()
			end
		end
	end
	for userId, Incremental in pairs(ActiveIncrementals) do
		if Incremental.FoodCollection and Incremental.FoodCollection.InCookingSpot == true then
			UpdateFoodIncremental(deltaTime, Incremental.FoodCollection)
		end
		if Incremental.IngredientsCollection and Incremental.IngredientsCollection.SpawnTimer and Incremental.IngredientsCollection.InDetectionZone == true then
			SpawnIngredientsIncremental(deltaTime, Incremental.IngredientsCollection)
		end
	end
	
	task.spawn(function()
		while true do
			task.wait(30) -- Verifica a cada 30 segundos
			for _, spot in pairs(FoodCollection.CookingPot.CookingSpots:GetChildren()) do
				local occupant = spot:FindFirstChild("Occupant")
				if occupant and occupant.Value ~= "Vacant" and occupant.Value ~= "" then
					-- Verifica se o player ainda está no jogo
					local playerStillInGame = Players:FindFirstChild(occupant.Value)
					if not playerStillInGame then
						warn("Spot fantasma encontrado: ".. spot.Name .." ocupado por ".. occupant.Value .." que já saiu!")
						occupant.Value = "Vacant"
						if spot:FindFirstChild("Occupied") then spot.Occupied.Value = false end
						if spot:FindFirstChild("SpotIndication") then
							spot.SpotIndication.Color = Color3.fromRGB(143, 142, 145)
						end
						if spot:FindFirstChild("CookingSpot") and spot.CookingSpot:FindFirstChild("Prompt") then
							spot.CookingSpot.Prompt.Enabled = true
						end
						local ladder = spot:FindFirstChild("CookingLadder")
						if ladder then
							if ladder:FindFirstChild("FoodBoxes") then
								ladder:FindFirstChild("FoodBoxes"):Destroy()
							end
							if ladder:FindFirstChild("FoodBoxPlatform") then
								ladder:FindFirstChild("FoodBoxPlatform"):Destroy()
							end
							for _, v in pairs(ladder:GetChildren()) do
								if v:IsA("BasePart") then
									v.CanCollide = false
									v.Transparency = 1
								end
							end
						end
					end
				end
			end
			RecalculateSpotsOccupied()
		end
	end)

end)

local function CleanupCookingSpot(Player, Character)
	-- 1. BULLETPROOF SWEEP: Iterate through ALL spots and free any owned by this player.
	for _, spot in pairs(FoodCollection.CookingPot.CookingSpots:GetChildren()) do
		local occupant = spot:FindFirstChild("Occupant")

		if occupant and occupant.Value == Player.Name then
			-- Forcefully Vacate the Spot
			occupant.Value = "Vacant"
			if spot:FindFirstChild("Occupied") then spot.Occupied.Value = false end
			if spot:FindFirstChild("SpotIndication") then spot.SpotIndication.Color = Color3.fromRGB(143, 142, 145) end

			-- Reset the prompt so others can use it
			if spot:FindFirstChild("CookingSpot") and spot.CookingSpot:FindFirstChild("Prompt") then
				spot.CookingSpot.Prompt.Enabled = true
			end

			-- Clean up the ladder and boxes
			local CookingLadder = spot:FindFirstChild("CookingLadder")
			if CookingLadder then
				if CookingLadder:FindFirstChild("FoodBoxes") then
					CookingLadder:FindFirstChild("FoodBoxes"):Destroy()
				end
				for _, v in pairs(CookingLadder:GetChildren()) do
					if v:IsA("BasePart") then
						if v.Name == "FoodBoxPlatform" then
							v:Destroy()
						else
							v.CanCollide = false
							v.CollisionGroup = "Items"
							v.Transparency = 1
						end
					end
				end
			end

			print("Ghost Spot Forcefully Cleaned Up For: " .. Player.Name)
		end
	end

	-- 2. RECALCULATE GLOBAL SPOTS (Fixes the permanent boiling bug)
	RecalculateSpotsOccupied()

	-- 3. Standard VFX and State Cleanup
	local stirVFX = workspace.Debris:FindFirstChild(Player.Name.."StirVFX")
	if stirVFX then stirVFX:Destroy() end

	if Character then
		Character:SetAttribute("UsingCooker", false)
		Character:SetAttribute("CookingSpotOccupying", "None")
		local spoon = Character:FindFirstChild("Spoon")
		if spoon then spoon:Destroy() end
	end

	-- Clean up memory
	if ActiveIncrementals[Player.UserId] and ActiveIncrementals[Player.UserId].FoodCollection then
		ActiveIncrementals[Player.UserId].FoodCollection.Player = nil
		ActiveIncrementals[Player.UserId].FoodCollection.CookingSpot = nil
		ActiveIncrementals[Player.UserId].FoodCollection.InCookingSpot = false
	end
end

Players.PlayerAdded:Connect(function(Player)
	Player.CharacterAdded:Connect(function(Character)

		repeat task.wait(1.5) until Player:FindFirstChild("PlayerInfo") and Character:FindFirstChild("ToolFolder")

		local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
		local HRP = Character:FindFirstChild("HumanoidRootPart")
		local Humanoid = Character:FindFirstChild("Humanoid")
		local Animator = Humanoid:WaitForChild("Animator")
		local CurrentFoodBoxes = DataStore.Value.CurrentFoodBoxes
		local CurrentFoodBoxesVal = DataStore.playerstats.CurrentFoodBoxes
		local FoodBoxesValue = DataStore.playerstats.FoodBoxesValue
		
		local savedSpeed = DataStore.Value.Upgrades.SpeedWithRebirths
		if savedSpeed and savedSpeed > 16 then
			Humanoid.WalkSpeed = savedSpeed
		end
		
		print(ActiveIncrementals)
		ActiveIncrementals[Player.UserId] = {
			IngredientsCollection = {
				["MyPlrIngredients"] = PlayerIngredients[Player.UserId],
				InDetectionZone = false
			},
			FoodCollection = {
				InCookingSpot = false,
			},
			Connections = {},
			Animations = {
				ChopIngredients = Animator:LoadAnimation(RS:WaitForChild("Assets").Animations.Ingredients.ChopIngredients),
				PutIngredientsInPot = Animator:LoadAnimation(RS:WaitForChild("Assets").Animations.Ingredients.PutIngredientsInPot),
				StirringFood = Animator:LoadAnimation(RS:WaitForChild("Assets").Animations.Food.StirringFood),
				CookingIdle = Animator:LoadAnimation(RS:WaitForChild("Assets").Animations.Food.CookingIdle),
			},
		}
		print(ActiveIncrementals)
		if CurrentFoodBoxes > 0 then
			if DataStore.Value.FarmersMarketSkillTree.UnlockFarmersMarket.Unlocked == true then

				local FoodBoxesFolderModel = Instance.new("Model")
				FoodBoxesFolderModel.Parent = PlayerFoodBoxes[Player.UserId]
				FoodBoxesFolderModel.Name = "FoodBoxes"
				FoodBoxesFolderModel:SetAttribute("FoodBoxCount",CurrentFoodBoxes)

				local FoodBoxOrigPosPart = Instance.new("Part")
				FoodBoxOrigPosPart.Parent = FoodBoxesFolderModel
				FoodBoxOrigPosPart.Name = "FoodBoxOrigPos"
				FoodBoxOrigPosPart.Size = RS:WaitForChild("Assets").FoodBox.PrimaryPart.Size
				FoodBoxOrigPosPart.Transparency = 1
				FoodBoxOrigPosPart.CanCollide = false
				FoodBoxOrigPosPart.Anchored = false

				FoodBoxesFolderModel.PrimaryPart = FoodBoxOrigPosPart
				FoodBoxesFolderModel:PivotTo(Character:FindFirstChild("UpperTorso").CFrame)

				local Weld = Instance.new("Weld")
				Weld.Name = "FoodBoxCharweld"
				Weld.Parent = FoodBoxesFolderModel.PrimaryPart
				Weld.Part0 = Character:FindFirstChild("UpperTorso")
				Weld.Part1 = FoodBoxesFolderModel.PrimaryPart
				Weld.C0 = CFrame.new(0,3,0)

				local FakeFoodBox = RS:WaitForChild("Assets").FakeFoodBox:Clone()
				FakeFoodBox.Parent = FoodBoxesFolderModel
				for i,v in pairs(FakeFoodBox:GetChildren()) do
					if v:IsA("BasePart") then
						v.Size = Vector3.new(v.Size.X,2*CurrentFoodBoxes,v.Size.Z)
					end
				end
				FakeFoodBox:PivotTo(FoodBoxOrigPosPart.CFrame * CFrame.new(0,(FoodBoxOrigPosPart.Size.Y/2+FakeFoodBox.PrimaryPart.Size.Y/2)-FoodBoxOrigPosPart.Size.Y,0))
				local Weld2 = Instance.new("WeldConstraint")
				Weld2.Name = "RootWeld"
				Weld2.Parent = FakeFoodBox.PrimaryPart
				Weld2.Part0 = FoodBoxesFolderModel.PrimaryPart
				Weld2.Part1 = FakeFoodBox.PrimaryPart

				local FoodBoxCover = RS:WaitForChild("Assets").FoodBoxCover:Clone()
				FoodBoxCover.Parent = FoodBoxesFolderModel
				FoodBoxCover:PivotTo(FakeFoodBox.PrimaryPart.CFrame * CFrame.new(0,(FakeFoodBox.PrimaryPart.Size.Y/2+FoodBoxCover.PrimaryPart.Size.Y/2),0))

				local Weld2 = Instance.new("WeldConstraint")
				Weld2.Name = "CoverWeld"
				Weld2.Parent = FoodBoxCover.PrimaryPart
				Weld2.Part0 = FakeFoodBox.PrimaryPart
				Weld2.Part1 = FoodBoxCover.PrimaryPart
				
				local FoodBoxDisplay = RS:WaitForChild("UIAssets").FoodBoxDisplay:Clone()
				FoodBoxDisplay.Parent = FoodBoxOrigPosPart
				FoodBoxDisplay.Icon.Increment.Text = "Boxes: "..FrmtNum(CurrentFoodBoxes,2)..", Value:"..FrmtNum(FoodBoxesValue.Value,2)
				
				FoodBoxDisplay.BoxCountFrame.BarValue.Position = UDim2.fromScale(0,0.5)
				FoodBoxDisplay.BoxCountFrame.WhitePart.Position = UDim2.fromScale(0,0.5)
				ActiveIncrementals[Player.UserId].Connections.CharFoodInCurrBox = Character:GetAttributeChangedSignal("FoodInCurrentBox"):Connect(function()
					if FoodBoxDisplay and FoodBoxDisplay:FindFirstChild("Icon") and FoodBoxDisplay.Parent then
						local BoxCount = Character:GetAttribute("FoodInCurrentBox")
						local ProgressVal = math.clamp(BoxCount/10,0,0.989)
						TS:Create(FoodBoxDisplay.BoxCountFrame.BarValue,TweenInfo.new(0.3,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,false,0),{Position = UDim2.fromScale(ProgressVal,0.5)}):Play()
						TS:Create(FoodBoxDisplay.BoxCountFrame.WhitePart,TweenInfo.new(0.3,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,false,0),{Position = UDim2.fromScale(ProgressVal,0.5)}):Play()
					end	
				end)
				ActiveIncrementals[Player.UserId].Connections.FoodBoxVal = FoodBoxesValue:GetPropertyChangedSignal("Value"):Connect(function()
					if FoodBoxDisplay and FoodBoxDisplay:FindFirstChild("Icon") and FoodBoxDisplay.Parent then
						FoodBoxDisplay.Icon.Increment.Text = "Boxes: "..FrmtNum(CurrentFoodBoxesVal.Value,2)..", Value:"..FrmtNum(FoodBoxesValue.Value,2)
					end
				end)
				ActiveIncrementals[Player.UserId].Connections.CurrentFoodBoxesCount = CurrentFoodBoxesVal:GetPropertyChangedSignal("Value"):Connect(function()
					if FoodBoxDisplay and FoodBoxDisplay:FindFirstChild("Icon") and FoodBoxDisplay.Parent then
						FoodBoxDisplay.Icon.Increment.Text = "Boxes: "..FrmtNum(CurrentFoodBoxesVal.Value,2)..", Value:"..FrmtNum(FoodBoxesValue.Value,2)
					end		
				end)
				for i,v in pairs(FoodBoxesFolderModel:GetDescendants()) do
					if v:IsA("BasePart") then
						v.Anchored = false
						v.Massless = true
					end
				end

			end
		end

	end)
	Player.CharacterRemoving:Connect(function(Character)
		task.spawn(function()
			-- CLEANING UP IF PLAYER WAS COOKING AND DIED/RESET
			CleanupCookingSpot(Player, Character)
		end)
	end)
end)

Players.PlayerRemoving:Connect(function(Player)
	-- Cleanup cooking spot PRIMEIRO, antes de qualquer outra coisa
	task.defer(function() -- task.defer garante que roda no fim do frame atual
		CleanupCookingSpot(Player, Player.Character)
		RecalculateSpotsOccupied() -- força recalcular depois

		local Folder = PlayerIngredients:FindFirstChild(tostring(Player.UserId))
		if Folder then Folder:Destroy() end

		if ActiveIncrementals[Player.UserId] then
			for i, v in pairs(ActiveIncrementals[Player.UserId].Connections) do
				if v then v:Disconnect() end
			end
			ActiveIncrementals[Player.UserId] = nil
		end
	end)
end)