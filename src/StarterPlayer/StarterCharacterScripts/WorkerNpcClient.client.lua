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
local HiredWorkerRem = RS:WaitForChild("Remotes").HiredWorkerRemote

--MODULES
local NotifModule = require(RS:WaitForChild("Modules").NotifModule)

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

local SellerPrompt = workspace.NPCSeller.AutoManager.HumanoidRootPart.ProximityPrompt

local PRODUCTS = {
	["HireShopper"] = 3579906145,
	["HireSeller"] = 3579906391,
}

local NPCSellerFrame = HUD.NPCSellerFrame


for i,WorkerVal:BoolValue in pairs(PlayerStats.HiredWorkers:GetChildren()) do
	if WorkerVal:IsA("BoolValue") then
		local function TrackWorkerUnlocked()
			if WorkerVal.Value == true then
				NPCSellerFrame.ScrollingFrame["Hire"..WorkerVal.Name].Purchase.GreenGradient.Enabled = false
				NPCSellerFrame.ScrollingFrame["Hire"..WorkerVal.Name].Purchase.RedGradient.Enabled = true
				NPCSellerFrame.ScrollingFrame["Hire"..WorkerVal.Name].Purchase.Price.Text = "Unlocked"
				NPCSellerFrame.ScrollingFrame["Hire"..WorkerVal.Name].Deploy.Visible = true
				NPCSellerFrame.ScrollingFrame["Hire"..WorkerVal.Name].Purchase.Visible = false
				NPCSellerFrame.ScrollingFrame["Hire"..WorkerVal.Name].RobuxPurchase.Visible = false

			elseif WorkerVal.Value == false then
				NPCSellerFrame.ScrollingFrame["Hire"..WorkerVal.Name].Purchase.GreenGradient.Enabled = true
				NPCSellerFrame.ScrollingFrame["Hire"..WorkerVal.Name].Purchase.RedGradient.Enabled = false
				NPCSellerFrame.ScrollingFrame["Hire"..WorkerVal.Name].Deploy.Visible = false
				
				NPCSellerFrame.ScrollingFrame["Hire"..WorkerVal.Name].Purchase.Visible = true
				NPCSellerFrame.ScrollingFrame["Hire"..WorkerVal.Name].RobuxPurchase.Visible = true

				if WorkerVal.Name == "Seller" then
					NPCSellerFrame.ScrollingFrame["Hire"..WorkerVal.Name].Purchase.Price.Text = "250k"
				elseif WorkerVal.Name == "Shopper" then
					NPCSellerFrame.ScrollingFrame["Hire"..WorkerVal.Name].Purchase.Price.Text = "150k"
				end
			end	
		end
		TrackWorkerUnlocked()
		
		local function TrackWorkerActive()
			if WorkerVal:GetAttribute("Active") == true  then
				NPCSellerFrame.ScrollingFrame["Hire"..WorkerVal.Name].Deploy.Title.Text = "Deployed"
				NPCSellerFrame.ScrollingFrame["Hire"..WorkerVal.Name].Deploy.RedGradient.Enabled = true
				NPCSellerFrame.ScrollingFrame["Hire"..WorkerVal.Name].Deploy.GreenGradient.Enabled = false
				HUD.WorkerActivityFrame[WorkerVal.Name].Visible = true
				NPCSellerFrame.ScrollingFrame["Hire"..WorkerVal.Name].Deploy.ButtonStroke.Color = Color3.new(0.509804, 0, 0)


				NPCSellerFrame.ScrollingFrame["Hire"..WorkerVal.Name].Deploy.Visible = true
				NPCSellerFrame.ScrollingFrame["Hire"..WorkerVal.Name].Purchase.Visible = false
				NPCSellerFrame.ScrollingFrame["Hire"..WorkerVal.Name].RobuxPurchase.Visible = false

			elseif WorkerVal:GetAttribute("Active") == false then
				HUD.WorkerActivityFrame[WorkerVal.Name].Visible = false
				NPCSellerFrame.ScrollingFrame["Hire"..WorkerVal.Name].Deploy.ButtonStroke.Color = Color3.new(0.0980392, 0.313725, 0)

				NPCSellerFrame.ScrollingFrame["Hire"..WorkerVal.Name].Deploy.Title.Text = "Deploy"
				NPCSellerFrame.ScrollingFrame["Hire"..WorkerVal.Name].Deploy.RedGradient.Enabled = false
				NPCSellerFrame.ScrollingFrame["Hire"..WorkerVal.Name].Deploy.GreenGradient.Enabled = true
			end	
		end
		
		TrackWorkerActive()
		
		WorkerVal:GetPropertyChangedSignal("Value"):Connect(TrackWorkerUnlocked)
			
		WorkerVal:GetAttributeChangedSignal("Active"):Connect(TrackWorkerActive)
			
	end
end

for i,Btn in pairs(NPCSellerFrame:GetDescendants()) do
	if Btn:IsA("GuiButton") then
		Btn.MouseButton1Click:Connect(function()
			if Btn.Name == "Purchase" then
				local PurchaseType = Btn.Parent.Name
				if PurchaseType == "HireShopper" then
					if PlayerStats.Ingredients.Value >= 150_000 and PlayerStats.HiredWorkers.Shopper.Value == false then
						HiredWorkerRem:FireServer("PurchaseWorker",PurchaseType)
					end
				elseif PurchaseType == "HireSeller" then
					if LeaderstatValues.Cash.Value >= 250_000 and PlayerStats.HiredWorkers.Seller.Value == false then
						HiredWorkerRem:FireServer("PurchaseWorker",PurchaseType)
					end
				end
			elseif Btn.Name == "Deploy" then
				local WorkerType = Btn.Parent.Name
				local WorkerName = string.gsub(WorkerType,"Hire","")
				HiredWorkerRem:FireServer("Deploy",WorkerName)
			elseif Btn.Name == "RobuxPurchase" then
				local PurchaseType = Btn.Parent.Name
				local WorkerName = string.gsub(PurchaseType,"Hire","")
				if PlayerStats.HiredWorkers[WorkerName].Value == false then
					--Prompt Gamepass Purchase
					MS:PromptProductPurchase(Player, PRODUCTS[PurchaseType])
				end
			elseif Btn.Name == "Close" then
				local Tween = TS:Create(NPCSellerFrame,TweenInfo.new(0.35,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,false,0),{Position = UDim2.fromScale(1.25,0.525)})
				Tween:Play()
				Tween.Completed:Once(function()
					NPCSellerFrame.Visible = false
				end)
			end
		end)
	end
end

SellerPrompt.Triggered:Connect(function(Plr)
	if NPCSellerFrame.Visible == false then
		NPCSellerFrame.Visible = true
		NPCSellerFrame.Position = UDim2.fromScale(1.25,0.525)
		TS:Create(NPCSellerFrame,TweenInfo.new(0.35,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,false,0),{Position = UDim2.fromScale(0.5,0.525)}):Play()
	elseif NPCSellerFrame.Visible == true then
		local Tween = TS:Create(NPCSellerFrame,TweenInfo.new(0.35,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,false,0),{Position = UDim2.fromScale(1.25,0.525)})
		Tween:Play()
		Tween.Completed:Once(function()
			NPCSellerFrame.Visible = false
		end)
	end
end)