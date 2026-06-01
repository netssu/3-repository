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

local LevelRem = RS:WaitForChild("Remotes").LevelRemote

local PlayerIngredients = workspace.PlayerIngredients
local IngredientsStorage = SS:WaitForChild("Assets").Ingredients
local IngredientCollection = workspace.Map.CenterPoint.IngredientCollection
local IngredientUpgradeBoards = IngredientCollection:WaitForChild("UpgradeBoards")
local IngredientsDetectionZone = IngredientCollection:WaitForChild("DetectionZone")
local IngredientsCollectionZone = IngredientCollection:WaitForChild("CollectionZone")

local FoodCollection = workspace.Map.CenterPoint.FoodCollection
local CookingSpots = FoodCollection.CookingPot.CookingSpots

-- [[ SCALING FORMULA FUNCTION ]] --
local function CalculateMaxExp(CurrentLevel)
	-- Formula: Base (100) * (Multiplier ^ Level)
	-- We use 1.25 as a multiplier for a steady curve
	local RawValue = 100 * (1.25 ^ (CurrentLevel - 1))
	local CleanValue = math.ceil(RawValue / 40) * 40

	-- Ensure it never goes below 100
	if CleanValue < 100 then CleanValue = 100 end

	return CleanValue
end

local PlayTimeConnections = {}

Players.PlayerAdded:Connect(function(Player)

	-- Wait for Data to Load
	repeat task.wait(0.5) until Player:FindFirstChild("PlayerInfo")
	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)

	-- Grab Stats (Defined here so the loop can use them)
	local LeaderstatValues = Player:WaitForChild("leaderstatValues")
	local PlayerStats = Player:WaitForChild("PlayerStats")
		
	local Char = Player.Character or Player.CharacterAdded:Wait()
	local LevelVal = LeaderstatValues:WaitForChild("Level")
	local Experience = PlayerStats:WaitForChild("Experience")
	local MaxExperience = PlayerStats:WaitForChild("MaxExperience")
	local PlayerInfo = Player:FindFirstChild("PlayerInfo")

	-- [[ INITIALIZE DATA ]] --
	-- Sync visuals with Datastore when player joins
	if DataStore.Value.MaxExperience < 100 then
		DataStore.Value.MaxExperience = 100 -- Enforce start at 100
	end
	Experience.Value = DataStore.Value.Experience
	MaxExperience.Value = DataStore.Value.MaxExperience

	Experience:GetPropertyChangedSignal("Value"):Connect(function()
		if DataStore.Value.Experience >= DataStore.Value.MaxExperience then
			DataStore.Value.Experience = 0 

			-- Increase Level
			LevelVal.Value += 1
			local NewMax = CalculateMaxExp(LevelVal.Value)
			DataStore.Value.MaxExperience = NewMax
			
			Experience.Value = DataStore.Value.Experience
			MaxExperience.Value = DataStore.Value.MaxExperience
			
			TS:Create(Char.Highlight,TweenInfo.new(0.65,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,false,0),{OutlineColor = Color3.new(0, 0.917647, 1),FillColor = Color3.new(0, 0.615686, 1),FillTransparency = 0.35}):Play()
			task.delay(0.5,function()
				TS:Create(Char.Highlight,TweenInfo.new(0.35,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{OutlineColor = Color3.new(0, 0, 0),FillColor = Color3.new(1, 1, 1),FillTransparency = 1}):Play()
			end)
			local LevelUpDisplay = RS:WaitForChild("UIAssets").LevelUpDisplay:Clone()
			LevelUpDisplay.Parent = Char:FindFirstChild("HumanoidRootPart")
			LevelUpDisplay.Increment.Text = "Level: "..LevelVal.Value
			Debris:AddItem(LevelUpDisplay,1.75)
			
			TS:Create(LevelUpDisplay,TweenInfo.new(2.5),{StudsOffset = Vector3.new(2,4.5,0)}):Play()
			TS:Create(LevelUpDisplay.Increment,TweenInfo.new(5),{TextTransparency = 1}):Play()

			local LevelUpSpark = RS:WaitForChild("Assets").VFX.LevelUpSpark:Clone()
			LevelUpSpark.Parent = Char:FindFirstChild("HumanoidRootPart")
			LevelUpSpark.Enabled = true
			local LevelUpBlackSpark = RS:WaitForChild("Assets").VFX.LevelupBlackSpark:Clone()
			LevelUpBlackSpark.Parent = Char:FindFirstChild("HumanoidRootPart")
			LevelUpBlackSpark.Enabled = true
			Debris:AddItem(LevelUpSpark,1.1)
			Debris:AddItem(LevelUpBlackSpark,1.2)
			
			print(Player.Name .. " Leveled Up to " .. LevelVal.Value .. "! Next XP: " .. NewMax)
			
		end
	end)
	
	task.spawn(function()
		while Player.Parent do
			task.wait(3) 

			DataStore.Value.Experience += 1

			Experience.Value = DataStore.Value.Experience
			MaxExperience.Value = DataStore.Value.MaxExperience
		end
	end)
	
	if not PlayTimeConnections[Player.UserId] then
		PlayTimeConnections[Player.UserId] = RunService.Heartbeat:Connect(function(DT)
			local Secs = 0
			Secs += DT

			if Secs >= 60 then
				PlayerInfo.Playtime.Value += 1
				
				Secs -= 60
			end
		end)
	end
	
	Player.CharacterAdded:Connect(function(Character)
		repeat task.wait(1.5) until Character:WaitForChild("ToolFolder")

		local HRP = Character:FindFirstChild("HumanoidRootPart")
		local Humanoid = Character:FindFirstChild("Humanoid")
		local Animator = Humanoid:WaitForChild("Animator")

		-- Character specific logic can go here
	end)
end)

Players.PlayerRemoving:Connect(function(Player)
	-- Data saving is likely handled by your MainDataModule on Close
end)