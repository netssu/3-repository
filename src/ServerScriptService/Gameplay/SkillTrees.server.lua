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
-- Changed this to pull from ReplicatedStorage so you only need one Module!
local SkillTreeDict = require(SS:WaitForChild("Modules").SkillTreeDict)

local SkillTreeRem = RS:WaitForChild("Remotes").SkillTreeRemote

local PlayerIngredients = workspace.PlayerIngredients
local IngredientsStorage = SS:WaitForChild("Assets").Ingredients
local IngredientCollection = workspace.Map.CenterPoint.IngredientCollection
local IngredientUpgradeBoards = IngredientCollection:WaitForChild("UpgradeBoards")
local IngredientsDetectionZone = IngredientCollection:WaitForChild("DetectionZone")
local IngredientsCollectionZone = IngredientCollection:WaitForChild("CollectionZone")

local FoodCollection = workspace.Map.CenterPoint.FoodCollection
local CookingSpots = FoodCollection.CookingPot.CookingSpots
local FarmersMarketSkillTree = workspace.Map.SkillTrees.FarmersMarketSkillTree

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

for i,SkillTreePad in pairs(CS:GetTagged("SkillTreePad")) do
	if SkillTreePad:IsA("BasePart") then
		local SkillName = SkillTreePad.Name
		local SkillTreeType = SkillTreePad.Parent.Parent.Name
		local SkillData = SkillTreeDict[SkillTreeType][SkillName]
		local SurfaceGui = SkillTreePad.SurfaceGui.UpgradeFrame
		local CurrencyGradient = RS:WaitForChild("UIAssets")[SkillData.Currency.."Gradient"]:Clone()

		if SurfaceGui.Cost:FindFirstChildWhichIsA("UIGradient") then
			SurfaceGui.Cost:FindFirstChildWhichIsA("UIGradient"):Destroy()
		end

		CurrencyGradient.Parent = SurfaceGui.Cost
		SurfaceGui.Cost.Text = FrmtNum(SkillData.Cost,2) .." "..SkillData.Currency
		SurfaceGui.SkillDescription.Text = SkillData.Description

		if SkillData.ValueType == "Variable" then
			local CurrentValue = SurfaceGui.CostTitle:Clone()
			CurrentValue.Parent = SurfaceGui
			CurrentValue.Text = "Current: x1.0"
			CurrentValue.Size = UDim2.fromScale(0.9,0.125)
			CurrentValue.Position = UDim2.fromScale(0.5,0.6)
			CurrentValue.TextColor3 = Color3.new(0.145098, 0.647059, 0.882353)
			SurfaceGui.SkillDescription.Position = UDim2.fromScale(0.5,0.28)
			SurfaceGui.SkillDescription.Size = UDim2.fromScale(0.975,0.55)
		end

		-- [[ DEBOUNCE ADDED HERE ]] --
		local padDebounce = false 

		SkillTreePad.Touched:Connect(function(OtherPart)
			-- Stop the script immediately if it's on cooldown
			if padDebounce then return end 

			if OtherPart.Parent:IsA("Model") and OtherPart.Parent:FindFirstChildWhichIsA("Humanoid") then
				local Character = OtherPart.Parent
				local Player = Players:GetPlayerFromCharacter(Character)

				if Player then
					-- Lock the pad
					padDebounce = true

					-- Automatically unlock it after 1 second, no matter what happens below
					task.delay(1, function()
						padDebounce = false
					end)

					local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
					local LeaderstatValues = Player:FindFirstChild("leaderstatValues")
					local PlayerStats = Player:FindFirstChild("PlayerStats")
					
					-- Find the Currency Object
					local CurrencyVal = nil

					if LeaderstatValues:FindFirstChild(SkillData.Currency) then
						CurrencyVal = LeaderstatValues:FindFirstChild(SkillData.Currency)
					elseif PlayerStats:FindFirstChild(SkillData.Currency)  then
						CurrencyVal = PlayerStats:FindFirstChild(SkillData.Currency)
					end

					-- Guard clause: Stop if we somehow can't find the currency
					if not CurrencyVal then return end

					-- Check if already unlocked
					if DataStore.Value[SkillTreePad.Parent.Parent.Name][SkillTreePad.Name].Unlocked == true then 
						return 
					end

					-- [[ THE FIX: USE THE SECURE DATASTORE VALUE INSTEAD OF THE LIVE CURRENCY ]]
					if DataStore.Value[SkillData.Currency] < SkillData.Cost then
						SkillTreeRem:FireClient(Player,"Decline",SkillTreePad)
						return 
					end
					
					-- If we have enough money, approve the transaction!
					SkillTreeRem:FireClient(Player,"Success",SkillTreePad)

					-- Update the unlocks
					DataStore.Value[SkillTreePad.Parent.Parent.Name][SkillTreePad.Name].Unlocked = true
					PlayerStats[SkillTreePad.Parent.Parent.Name][SkillTreePad.Name].Value = true
					
					-- Deduct the exact cost securely from the DataStore, then sync to the live value
					DataStore.Value[SkillData.Currency] -= SkillData.Cost
					CurrencyVal.Value = DataStore.Value[SkillData.Currency]

					print("Player Bought Skill!")
				end
			end
		end)
	end
end

Players.PlayerAdded:Connect(function(Player)
	-- Wait for Data to Load
	repeat task.wait(0.5) until Player:FindFirstChild("PlayerInfo")
	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)

	-- Grab Stats (Defined here so the loop can use them)
	local LeaderstatValues = Player:WaitForChild("leaderstatValues")
	local PlayerStats = Player:WaitForChild("PlayerStats")
		
	local Char = Player.Character or Player.CharacterAdded:Wait()

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