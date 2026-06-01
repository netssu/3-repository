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



Players.PlayerAdded:Connect(function(Player)
	task.delay(8, function()
		if not Player or not Player.Parent then return end

		local PlayerStats = Player:FindFirstChild("PlayerStats")
		if not PlayerStats then return end
		local PlayerInfo = Player:WaitForChild("PlayerInfo")
		local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)

		if DataStore.Value.Upgrades.IngredientsSpawnSpeed > 2.755 then
			DataStore.Value.Upgrades.IngredientsSpawnSpeed = 2.75
			PlayerStats.Upgrades.IngredientsSpawnSpeed.Value = DataStore.Value.Upgrades.IngredientsSpawnSpeed
			print("UPDATED IngredientsSpawnSpeed to 2.75 For: "..Player.Name)
		end

		for i,EventMultiplier in pairs(PlayerInfo:GetChildren()) do
			if EventMultiplier:IsA("NumberValue") then
				if not string.find(EventMultiplier.Name,"Multiplier") then
					continue
				end
				local EventStatName = string.gsub(EventMultiplier.Name,"MultiplierEventValue","")
				if EventStatName == "Ingredient" or EventStatName == "Food" then
					if EventMultiplier.Value <= 1 then
						--EventMultiplier.Value = 2
					end
				end
			end
		end
		
	end)
end)

