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
local AvatarService = game:GetService("AvatarEditorService")

--REFERENCES
local Player = Players.LocalPlayer
local IncrementalRem = RS:WaitForChild("Remotes").IncrementalRemote
local Camera = workspace.CurrentCamera

game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local Character = script.Parent
repeat task.wait(1) until Player:FindFirstChild("PlayerInfo") and Player.Character:FindFirstChild("ToolFolder")

local PlayerGui = Player:WaitForChild("PlayerGui")
local HUD = PlayerGui:WaitForChild("HUD")

local PlayerStats = Player.PlayerStats
local Upgrades = PlayerStats.Upgrades
local FarmersMarketSkillTree = PlayerStats.FarmersMarketSkillTree

--CHARACTER
local HRP = Character:WaitForChild("HumanoidRootPart")
local Humanoid:Humanoid = Character:WaitForChild("Humanoid") 

local LeaderstatValues = Player:FindFirstChild("leaderstatValues")
local PlayerStats = Player:FindFirstChild("PlayerStats")

local Rebirths:NumberValue = PlayerStats.Rebirths
local CashVal:NumberValue = LeaderstatValues.Cash
local FoodVal:NumberValue = LeaderstatValues.Food
local LevelVal:NumberValue = LeaderstatValues.Level
local FoodBoxesVal:NumberValue = PlayerStats.FoodBoxesValue

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

local FoodCollection = workspace.Map.CenterPoint.FoodCollection
local CookingPot = FoodCollection.CookingPot
local FoodUpgradeBoards = FoodCollection.UpgradeBoards
local UpgradeBoardsOriginalPos = FoodCollection:WaitForChild("UpgradeBoardsOriginalPos")

--VARIABLES
local InIngredientCollectionZone = false
local UsingCooker = false

local CurrentCollectorRadius = nil 
local CurrentSpot = nil
local HoverTime = 0 

-- [[ GAMEPASS CACHING & MAGNET SETTINGS ]]
local OwnsRadiusGamepass = false
local OwnsMagnetGamepass = false

local RADIUS_GAMEPASS_ID = 1683505672
local MAGNET_GAMEPASS_ID = 1683645969

local MAGNET_RADIUS = 20  -- How close the player needs to be to pull ingredients
local MAGNET_SPEED = 5    -- Speed of the pull (Easily adjust this! Higher = Faster)

-- 1. Check initially when they load in
task.spawn(function()
	local success1, ownsRadius = pcall(function()
		return MS:UserOwnsGamePassAsync(Player.UserId, RADIUS_GAMEPASS_ID)
	end)
	if success1 then OwnsRadiusGamepass = ownsRadius end

	local success2, ownsMagnet = pcall(function()
		return MS:UserOwnsGamePassAsync(Player.UserId, MAGNET_GAMEPASS_ID)
	end)
	if success2 then OwnsMagnetGamepass = ownsMagnet end
end)

-- 2. NEW: Listen for in-game purchases to update instantly!
MS.PromptGamePassPurchaseFinished:Connect(function(purchasingPlayer, gamePassId, wasPurchased)
	if wasPurchased and purchasingPlayer == Player then
		if gamePassId == RADIUS_GAMEPASS_ID then
			OwnsRadiusGamepass = true
			print("Radius Gamepass instantly activated!")
		elseif gamePassId == MAGNET_GAMEPASS_ID then
			OwnsMagnetGamepass = true
			print("Magnet Gamepass instantly activated!")
		end
	end
end)

-- INGREDIENT VARIABLES
local PlayerFoodBoxes = workspace.PlayerFoodBoxes
local PlayerIngredients = workspace.PlayerIngredients
local MyIngredients = PlayerIngredients:WaitForChild(Player.UserId)

local CollectedLocalIngredientFolder = Instance.new("Folder", workspace)
CollectedLocalIngredientFolder.Name = "CollectedLocalIngredients"

local DetectorRadius = Instance.new("Folder", workspace)
DetectorRadius.Name = "DetectorRadius"

local CookingOParams = OverlapParams.new()
CookingOParams.FilterType = Enum.RaycastFilterType.Include
CookingOParams.FilterDescendantsInstances = {Character}
CookingOParams.MaxParts = 1

local CollectionOParams = OverlapParams.new()
CollectionOParams.FilterType = Enum.RaycastFilterType.Include
CollectionOParams.FilterDescendantsInstances = {MyIngredients}
CollectionOParams.MaxParts = 50

-- Disable prompts initially
for i,v in pairs(CS:GetTagged("CookingSpot")) do
	if v:IsA("ProximityPrompt") then v.Enabled = false end
end

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

-- [[ AUTO COLLECTOR SETUP START ]] --
local AutoButton = HUD.IngredientCollectionHUD.Auto
local AutoBool = AutoButton.OnorOff

local function UpdateAutoVisuals()
	if AutoBool.Value then
		AutoButton.Title.Text = "Auto: ON"
		TS:Create(AutoButton, TweenInfo.new(0.3), {ImageColor3 = Color3.fromRGB(75, 225, 75)}):Play()
	else
		AutoButton.Title.Text = "Auto: OFF"
		TS:Create(AutoButton, TweenInfo.new(0.3), {ImageColor3 = Color3.fromRGB(225, 75, 75)}):Play()
	end
end

-- Initialize State
UpdateAutoVisuals()

-- Toggle Button Logic
AutoButton.MouseButton1Click:Connect(function()
	AutoBool.Value = not AutoBool.Value
	UpdateAutoVisuals()
end)

-- The Movement Logic Function
local function AutoCollectMovement()
	-- Basic Checks
	if not InIngredientCollectionZone then return end
	if not AutoBool.Value then return end
	if Humanoid.Health <= 0 then return end

	local ClosestIng = nil
	local MinDist = math.huge
	local HRPPos = HRP.Position

	-- Scan MyIngredients Folder efficiently
	local Ingredients = MyIngredients:GetChildren()
	if #Ingredients == 0 then return end -- No ingredients to collect

	for _, ing in ipairs(Ingredients) do
		-- Only check valid ingredients with a PrimaryPart
		if ing:IsA("Model") and ing.PrimaryPart then
			local Dist = (ing.PrimaryPart.Position - HRPPos).Magnitude
			if Dist < MinDist then
				MinDist = Dist
				ClosestIng = ing
			end
		end
	end

	-- Move if target found
	if ClosestIng then
		Humanoid:MoveTo(ClosestIng.PrimaryPart.Position)
	end
end
-- [[ AUTO COLLECTOR SETUP END ]] --

-- 1. DETECTION (Same as before)
local function CookingSpotDetection(deltaTime)
	if not (Character and Character.Parent) then return end
	if not HRP or not HRP.Parent then return end
	if Character:GetAttribute("UsingCooker") == true and UsingCooker == true then return end
	if Character:GetAttribute("CookingSpotOccupying") ~= "None" then return end

	local foundSpot = nil

	for _, Spot in pairs(CookingPot.CookingSpots:GetDescendants()) do
		if Spot:IsA("BasePart") and Spot.Name == "CookingSpot" then
			local partsFound = workspace:GetPartsInPart(Spot, CookingOParams)
			if #partsFound >= CookingOParams.MaxParts then
				foundSpot = Spot
				break 
			end
		end
	end

	if foundSpot ~= CurrentSpot then
		if CurrentSpot then
			CurrentSpot.Prompt.Enabled = false
			UsingCooker = false
			IncrementalRem:FireServer("UnoccupyingSpot", {["CookingSpot"]=CurrentSpot.Parent})
			print(Player.Name.. " LEFT ".. CurrentSpot.Parent.Name)
		end

		if foundSpot then
			local Occupant = foundSpot.Parent.Occupant
			if Occupant.Value == "Vacant" then
				foundSpot.Prompt.Enabled = true
				UsingCooker = true 
				IncrementalRem:FireServer("OccupyingSpot", {["CookingSpot"]=foundSpot.Parent})
				print(Player.Name.. " ENTERED ".. foundSpot.Parent.Name)
				CurrentSpot = foundSpot 
			else
				CurrentSpot = nil
			end
		else
			CurrentSpot = nil
		end
	end
end

local function Cooking(deltaTime)
	local TargetCFrame

	-- CHECK: Are we currently cooking?
	local IsCooking = (Character:GetAttribute("UsingCooker") == true) and (Character:GetAttribute("CookingSpotOccupying") ~= "None")

	if IsCooking then
		-- A. If Cooking: Target is in front of Player + Bobbing
		HoverTime += deltaTime
		local BobbingY = math.sin(HoverTime * 1.5) * 0.25
		TargetCFrame = HRP.CFrame * CFrame.new(0, 12, -28) * CFrame.Angles(0, math.rad(180), 0) + Vector3.new(0, BobbingY, 0)
	else
		-- B. If NOT Cooking: Target is the Original Position
		HoverTime = 0
		TargetCFrame = UpgradeBoardsOriginalPos.CFrame
	end

	-- C. Smoothly Slide (Lerp) towards whichever Target we picked
	local CurrentPivot = FoodUpgradeBoards:GetPivot()

	-- Optimization: Only move if we aren't close enough (stops micro-movements at rest)
	if (CurrentPivot.Position - TargetCFrame.Position).Magnitude > 0.05 or IsCooking then
		FoodUpgradeBoards:PivotTo(CurrentPivot:Lerp(TargetCFrame, deltaTime * 4.5))
	end
end

local function IngredientsAreaDetectionAndSpawning(deltaTime)
	if not (Character and Character.Parent) then return end
	if not HRP or not HRP.Parent then return end
	if Character:GetAttribute("UsingCooker") == true and UsingCooker == true then return end
	if Character:GetAttribute("CookingSpotOccupying") ~= "None" then return end

	local partsFound = workspace:GetPartsInPart(IngredientsDetectionZone, CookingOParams)

	-- PLAYER IS INSIDE ZONE
	if #partsFound >= CookingOParams.MaxParts then

		-- CHECK: Only run this if we weren't already inside (Debounce)
		if InIngredientCollectionZone == false then
			InIngredientCollectionZone = true -- Set state to TRUE

			IncrementalRem:FireServer("EnteredDetectionZone")

			if not CurrentCollectorRadius then
				local NewRadius = RS.Assets.AutoCollectorRadius:Clone()
				NewRadius.Parent = DetectorRadius 

				HUD.IngredientCollectionHUD.Visible = true
				HUD.IngredientCollectionHUD.Position = UDim2.fromScale(0.5,1.25)
				TS:Create(HUD.IngredientCollectionHUD,TweenInfo.new(0.75,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,false),{Position = UDim2.fromScale(0.5,0.89)}):Play()

				local Weld = Instance.new("Weld")
				Weld.Part0 = HRP 
				Weld.Part1 = NewRadius.PrimaryPart
				Weld.C0 = CFrame.new(0,-2.9,0)
				Weld.C1 = CFrame.Angles(0,0,math.rad(-90))
				Weld.Parent = NewRadius.PrimaryPart

				CurrentCollectorRadius = NewRadius 
			end
		end

		-- PLAYER IS OUTSIDE ZONE
	else
		-- CHECK: Only run this if we WERE just inside (Debounce)
		if InIngredientCollectionZone == true then
			InIngredientCollectionZone = false -- Set state to FALSE

			local Tween = TS:Create(HUD.IngredientCollectionHUD,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.In,0,false),{Position = UDim2.fromScale(0.5,1.25)})
			Tween:Play()
			Tween.Completed:Once(function()
				HUD.IngredientCollectionHUD.Visible = false
			end)
			IncrementalRem:FireServer("LeftDetectionZone")

			if CurrentCollectorRadius then
				CurrentCollectorRadius:Destroy()
				CurrentCollectorRadius = nil
			end
		end
	end
end

local function IngredientsAreaCollection(deltaTime)
	if not (Character and Character.Parent) then return end
	if not HRP or not HRP.Parent then return end
	if Character:GetAttribute("UsingCooker") == true and UsingCooker == true then return end
	if Character:GetAttribute("CookingSpotOccupying") ~= "None" then return end

	-- Player IS inside the Detection Zone
	if InIngredientCollectionZone == true then
		local CollectionRadius = DetectorRadius.AutoCollectorRadius:FindFirstChild("RadiusDetector")
		local CollectionRadiusIndicator = DetectorRadius.AutoCollectorRadius:FindFirstChild("RadiusIndicator")

		if not CollectionRadius or not CollectionRadiusIndicator then return end

		-- [FIXED] x3 RADIUS GAMEPASS (Now uses the cached variable instead of a web call!)
	
		if OwnsRadiusGamepass == true then
			CollectionRadius.Size = Vector3.new(8.849,4,4) * 3 
			CollectionRadiusIndicator.Size = Vector3.new(0.15,CollectionRadius.Size.Y,CollectionRadius.Size.Z)
		else
			CollectionRadius.Size = Vector3.new(8.849,4,4) 
			CollectionRadiusIndicator.Size = Vector3.new(0.15,4,4)
		end
		CollectionRadiusIndicator.RadiusDetector.C0 = CFrame.new(3,0,0)
		
		-- [[ NEW: MAGNET GAMEPASS LOGIC ]]
		if OwnsMagnetGamepass == true then
			local TargetPos = CollectionRadius.Position -- Pulls toward the radius detector (feet)

			for _, Ingredient in pairs(MyIngredients:GetChildren()) do
				if Ingredient:IsA("Model") and Ingredient.PrimaryPart then
					local IngPos = Ingredient.PrimaryPart.Position
					local Distance = (IngPos - TargetPos).Magnitude

					-- If within 20 studs, smoothly pull it towards the player
					if Distance <= MAGNET_RADIUS and Distance > 0.5 then
						-- Lerp creates a smooth easing effect. Multiplying by deltaTime keeps it smooth across all framerates.
						local NewCFrame = Ingredient.PrimaryPart.CFrame:Lerp(CFrame.new(TargetPos), deltaTime * MAGNET_SPEED)
						Ingredient:PivotTo(NewCFrame)
					end
				end
			end
		end
		-- [[ END MAGNET LOGIC ]]

		local IngredientsFound = workspace:GetPartsInPart(CollectionRadius, CollectionOParams)
		if #IngredientsFound > 0 then
			if IngredientsFound[1].Parent:IsA("Model") and IngredientsFound[1].Parent.Parent == MyIngredients then
				local Ingredient:Model = IngredientsFound[1].Parent
				local IngredientType = "Normal"
				if string.find(Ingredient.Name,"Golden") then
					IngredientType = "Golden"
				end
				print("Ingredient Found: " .. Ingredient.Name)
				Ingredient.Parent = CollectedLocalIngredientFolder

				local IncrementDisplay = RS:WaitForChild("UIAssets").IncrementDisplay:Clone()
				IncrementDisplay.Parent = Ingredient.PrimaryPart
				IncrementDisplay.Icon.Increment.TextTransparency = 0
				TS:Create(IncrementDisplay,TweenInfo.new(1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{StudsOffset = Vector3.new(2,3.5,0)}):Play()
				TS:Create(IncrementDisplay.Icon.Increment,TweenInfo.new(3.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{TextTransparency = 1}):Play()
				Debris:AddItem(IncrementDisplay,2.1)
				if IngredientType == "Golden" then
					TS:Create(Character.Highlight,TweenInfo.new(0.75,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,false,0),{OutlineColor = Color3.new(1, 0.862745, 0.0901961),FillColor = Color3.new(1, 0.862745, 0.0901961),FillTransparency = 0.35}):Play()
					task.delay(0.5,function()
						TS:Create(Character.Highlight,TweenInfo.new(0.35,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{OutlineColor = Color3.new(0, 0, 0),FillColor = Color3.new(1, 1, 1),FillTransparency = 1}):Play()
					end)
					IncrementDisplay.Icon.Increment.OrangeGradient.Enabled= false
					IncrementDisplay.Icon.Increment.TextColor3 = Color3.new(1, 0.85098, 0)
					IncrementDisplay.Icon.Increment.Text = "+"..FrmtNum((IngredientsPerCollect.Value * 3) * MultiIngredientsPerCollect.Value,2)
				else
					IncrementDisplay.Icon.Increment.OrangeGradient.Enabled = true
					IncrementDisplay.Icon.Increment.TextColor3 = Color3.new(1, 1, 1)
					IncrementDisplay.Icon.Increment.Text = "+"..FrmtNum((IngredientsPerCollect.Value) * MultiIngredientsPerCollect.Value,2)
				end

				IncrementalRem:FireServer("CollectedIngredient",{["Ingredient"] = Ingredient})
				for i,v in pairs(Ingredient:GetChildren()) do
					if v:IsA("BasePart") then
						v.Material = Enum.Material.Neon
						if IngredientType == "Golden" then
							v.Color = Color3.fromRGB(255, 217, 2)
						else
							v.Color = Color3.fromRGB(255, 255, 255)
						end
						TS:Create(v,TweenInfo.new(0.75),{Transparency = 1}):Play()
					end
				end
				for i = 1,1.9,0.05 do
					if i >= 1.85 then
						if IncrementDisplay and IncrementDisplay.Parent then
							IncrementDisplay.Parent = workspace:FindFirstChild("Debris") or workspace
						end
						if Ingredient and Ingredient.Parent then
							Ingredient:Destroy()
						end
						break
					end
					if Ingredient and Ingredient.Parent then
						Ingredient:ScaleTo(i)
					end
					task.wait(deltaTime)
				end
			end
		end
	end
end


RunService.Heartbeat:Connect(function(deltaTime)
	IngredientsAreaDetectionAndSpawning(deltaTime)
	IngredientsAreaCollection(deltaTime)
	AutoCollectMovement() -- [[ ADDED AUTO COLLECT UPDATE ]] --
	--
	CookingSpotDetection(deltaTime)
	Cooking(deltaTime)
end)

local Food = FoodVal.Value
FoodVal:GetPropertyChangedSignal("Value"):Connect(function()
	local Difference = FoodVal.Value - Food
	if Difference > 0 then
		-- INCREASED
		local IncrementDisplay = RS:WaitForChild("UIAssets").FoodIncrementDisplay:Clone()
		IncrementDisplay.Parent = HRP
		IncrementDisplay.Icon.Increment.TextTransparency = 0
		TS:Create(IncrementDisplay,TweenInfo.new(1.5,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,false,0),{StudsOffset = Vector3.new(math.random(-2,4),3,0)}):Play()
		TS:Create(IncrementDisplay.Icon.Increment,TweenInfo.new(5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{TextTransparency = 1}):Play()
		TS:Create(IncrementDisplay.Icon,TweenInfo.new(3.75,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{ImageTransparency = 1}):Play()
		TS:Create(IncrementDisplay.Icon,TweenInfo.new(0.75,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,false,0),{Rotation = math.random(-35,35)}):Play()
		IncrementDisplay.Icon.Increment.Text = "+"..FrmtNum((Difference),2)
		Debris:AddItem(IncrementDisplay,math.random(2,3))

		local FoodType = "Normal"
		if Difference >= Difference * 3 then
			FoodType = "Golden"
		end
		if FoodType == "Golden" then
			TS:Create(Character.Highlight,TweenInfo.new(0.75,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,false,0),{OutlineColor = Color3.new(1, 0.862745, 0.0901961),FillColor = Color3.new(1, 0.862745, 0.0901961),FillTransparency = 0.35}):Play()
			task.delay(0.5,function()
				TS:Create(Character.Highlight,TweenInfo.new(0.35,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{OutlineColor = Color3.new(0, 0, 0),FillColor = Color3.new(1, 1, 1),FillTransparency = 1}):Play()
			end)
			IncrementDisplay.Icon.Increment.OrangeGradient.Enabled = false
			IncrementDisplay.Icon.Increment.TextColor3 = Color3.new(1, 0.85098, 0)
		else
			IncrementDisplay.Icon.Increment.OrangeGradient.Enabled = true
			IncrementDisplay.Icon.Increment.TextColor3 = Color3.new(1, 1, 1)
		end
	elseif Difference < 0 then
		-- REDUCED
	end
	Food = FoodVal.Value
end)

local FoodBoxesValue = FoodBoxesVal.Value
FoodBoxesVal:GetPropertyChangedSignal("Value"):Connect(function()
	if PlayerStats.FarmersMarketSkillTree.UnlockFarmersMarket.Value == false and Character:GetAttribute("UsingCooker") == false then
		return
	end
	local Difference = FoodBoxesVal.Value - FoodBoxesValue
	local CookingSpot = nil
	for i,v in pairs(CookingPot:GetDescendants()) do
		if v:IsA("StringValue") and v.Value == Player.Name then
			CookingSpot = v.Parent
		end
	end
	if CookingSpot == nil then
		return
	end
	if Difference > 0 then
		-- INCREASED
		local IncrementDisplay = RS:WaitForChild("UIAssets").FoodIncrementDisplay:Clone()
		IncrementDisplay.Parent = CookingSpot.CookingLadder:FindFirstChild("FoodBoxes").PrimaryPart
		IncrementDisplay.Icon.Increment.TextTransparency = 0
		TS:Create(IncrementDisplay,TweenInfo.new(1.5,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,false,0),{StudsOffset = Vector3.new(math.random(1,2),3,0)}):Play()
		TS:Create(IncrementDisplay.Icon.Increment,TweenInfo.new(5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{TextTransparency = 1}):Play()
		TS:Create(IncrementDisplay.Icon,TweenInfo.new(3.75,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{ImageTransparency = 1}):Play()
		TS:Create(IncrementDisplay.Icon,TweenInfo.new(0.75,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,false,0),{Rotation = math.random(-35,35)}):Play()
		IncrementDisplay.Icon.Increment.Text = "+"..FrmtNum((Difference),2)
		Debris:AddItem(IncrementDisplay,math.random(2,3))

		local FoodType = "Normal"
		if Difference >= Difference * 3 then
			FoodType = "Golden"
		end
		if FoodType == "Golden" then
			TS:Create(Character.Highlight,TweenInfo.new(0.75,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,false,0),{OutlineColor = Color3.new(1, 0.862745, 0.0901961),FillColor = Color3.new(1, 0.862745, 0.0901961),FillTransparency = 0.35}):Play()
			task.delay(0.5,function()
				TS:Create(Character.Highlight,TweenInfo.new(0.35,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{OutlineColor = Color3.new(0, 0, 0),FillColor = Color3.new(1, 1, 1),FillTransparency = 1}):Play()
			end)
			IncrementDisplay.Icon.Increment.OrangeGradient.Enabled = false
			IncrementDisplay.Icon.Increment.TextColor3 = Color3.new(1, 0.85098, 0)
		else
			IncrementDisplay.Icon.Increment.OrangeGradient.Enabled = true
			IncrementDisplay.Icon.Increment.TextColor3 = Color3.new(1, 1, 1)
		end
	elseif Difference < 0 then
		-- REDUCED
	end
	FoodBoxesValue = FoodBoxesVal.Value
end)

--INGREDIENTS FILTERING
local function HideOtherIngredients(Descendant)
	if Descendant and Descendant.Parent and Descendant:IsA("BasePart") and Descendant.Parent:IsA("Model") then
		local CollectionFolder = Descendant.Parent.Parent
		-- If it's NOT my folder, hide it
		if CollectionFolder.Name ~= tostring(Player.UserId) then
			Descendant.Transparency = 1
			Descendant.CanCollide = false
			Descendant.CanTouch = false
			Descendant.CanQuery = false
		end
	end
end

-- Check existing
for _, v in pairs(PlayerIngredients:GetDescendants()) do
	HideOtherIngredients(v)
end

-- Check new ones automatically
PlayerIngredients.DescendantAdded:Connect(HideOtherIngredients)

-- JUMP / CANCEL LOGIC
local ProcessJumpRequest = false
local CurrCookingSpot = nil

local Leavebtn:ImageButton = HUD.FoodCollectionHUD.Leave
Leavebtn.MouseButton1Click:Connect(function()
	Humanoid.Jump = true
end)

UIS.JumpRequest:Connect(function()
	if ProcessJumpRequest then return end
	ProcessJumpRequest = true

	if Character:GetAttribute("UsingCooker") == false or Character:GetAttribute("CookingSpotOccupying") == "None" then
		ProcessJumpRequest = false
		return
	end

	UsingCooker = false
	if CurrCookingSpot ~= nil then
		CurrCookingSpot.Parent.Parent.Pot.CookerBarrier.CanCollide = true
		CurrCookingSpot.Parent.Parent.Pot.CookerBarrier.CanQuery = false
		CurrCookingSpot.Parent.Parent.Pot.CookerBarrier.CollisionGroup = "Default"
	end
	IncrementalRem:FireServer("StopCooking")
	print("Player Trying to Jump")

	local ExitFoodHUDTween = TS:Create(HUD.FoodCollectionHUD,TweenInfo.new(0.75,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,false),{Position = UDim2.fromScale(0.5,1.25)})
	ExitFoodHUDTween:Play()
	ExitFoodHUDTween.Completed:Once(function()
		HUD.FoodCollectionHUD.Visible = false
	end)

	Player.CameraMinZoomDistance = 0.5
	for i,v in pairs(PlayerFoodBoxes:GetDescendants()) do
		if v:IsA("Folder") and v.Name == tostring(Player.UserId) then
			continue
		end
		if v:IsA("BasePart") then
			if v.Parent.Name == "FoodBoxes" or v.Parent.Parent.Name == "FoodBoxes" or v.Parent.Parent.Parent.Name == "FoodBoxes" then
				v.Transparency = 0
			end
		end
	end

	-- [[ THE FIX: CLEAR THE CACHED SPOTS SO LOCAL DETECTION RESTARTS! ]]
	CurrentSpot = nil
	CurrCookingSpot = nil

	task.wait(0.5)
	ProcessJumpRequest = false
end)

IncrementalRem.OnClientEvent:Connect(function(Action,CookingSpot)
	if Action == "StartedCooking" and CookingSpot then
		CurrCookingSpot = CookingSpot
		CookingSpot.Parent.Parent.Pot.CookerBarrier.CollisionGroup = "Default"
		TS:Create(Camera,TweenInfo.new(0.75),{FieldOfView = 75}):Play()
		Player.CameraMinZoomDistance = 5
		CurrCookingSpot.Parent.Parent.Pot.CookerBarrier.CanCollide = false
		CurrCookingSpot.Parent.Parent.Pot.CookerBarrier.CanQuery = false
		
		HUD.FoodCollectionHUD.Visible = true
		HUD.FoodCollectionHUD.Position = UDim2.fromScale(0.5,1.25)
		TS:Create(HUD.FoodCollectionHUD,TweenInfo.new(0.75,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,false),{Position = UDim2.fromScale(0.5,0.89)}):Play()

		for i,v in pairs(PlayerFoodBoxes:GetDescendants()) do
			if v:IsA("Folder") and v.Name == tostring(Player.UserId) then
				continue
			end
 			if v:IsA("BasePart") then
				if v.Parent.Name == "FoodBoxes" or v.Parent.Parent.Name == "FoodBoxes" or v.Parent.Parent.Parent.Name == "FoodBoxes" then
					v.Transparency = 0.75
				end
			end
		end
		
	end
end)