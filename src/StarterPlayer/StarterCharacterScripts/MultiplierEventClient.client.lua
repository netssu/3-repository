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
local PlayerInfo = Player:FindFirstChild("PlayerInfo")

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

local ActiveBoostFrame = HUD.ActiveBoostsCorner

for i,EventMultiplier in pairs(PlayerInfo:GetChildren()) do
	if EventMultiplier:IsA("NumberValue") then
		if not string.find(EventMultiplier.Name,"Multiplier") then
			continue
		end
		local function EventTracker()
			if EventMultiplier.Value > 1 then
				local EventStatName = string.gsub(EventMultiplier.Name,"MultiplierEventValue","")
				ActiveBoostFrame[EventStatName].Visible = true
				ActiveBoostFrame[EventStatName].Boost.Text = "x"..EventMultiplier.Value
			end
		end
		EventTracker()
		EventMultiplier:GetPropertyChangedSignal("Value"):Connect(EventTracker)
	end
end

