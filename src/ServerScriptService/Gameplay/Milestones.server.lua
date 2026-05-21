local SS = game:GetService("ServerStorage")
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--MODULES
local DataStoreModule = require(SS:WaitForChild("Modules").MainDataModule)
local MilestonesDictionary = require(SS:WaitForChild("Modules").MilestonesDictionary)
local NotifModule = require(RS:WaitForChild("Modules").NotifModule)

local MilestonesRem = RS:WaitForChild("Remotes").MilestonesRemote

-- [[ HELPER: GET ITEM CATEGORY ]]
local function GetCategory(ItemName)
	if string.find(ItemName, "Hat") then return "Hat"
	elseif string.find(ItemName, "Apron") then return "Apron"
	elseif string.find(ItemName, "Shirt") or string.find(ItemName, "Jacket") then return "Shirt"
	else return "Unknown" end
end

-- [[ HELPER: UNEQUIP CATEGORY ]]
local function UnequipCategory(Player, Character, Category, DataStore)
	local MilestonesFolder = Player:FindFirstChild("PlayerStats") and Player.PlayerStats:FindFirstChild("Milestones")
	if not MilestonesFolder then return end

	-- 1. Visually remove items in this category from the Character
	for _, child in pairs(Character:GetChildren()) do
		if child:GetAttribute("MilestoneCategory") == Category then
			child:Destroy()
		end
	end

	-- 2. Update Datastore and Attributes to "Equipped = false" for this category
	for msName, msData in pairs(MilestonesDictionary.Milestones) do
		if GetCategory(msData.Reward) == Category then
			if DataStore.Value.Milestones[msName] then
				DataStore.Value.Milestones[msName].Equipped = false
			end
			local msValue = MilestonesFolder:FindFirstChild(msName)
			if msValue then
				msValue:SetAttribute("Equipped", false)
			end
		end
	end
end

-- [[ HELPER: EQUIP REWARD ]]
local function EquipReward(Player, Character, MilestoneName, DataStore)
	local MilestoneData = MilestonesDictionary.Milestones[MilestoneName]
	if not MilestoneData then return end

	local ItemName = MilestoneData.Reward
	local RewardType = MilestoneData.RewardType
	local Category = GetCategory(ItemName)

	-- 1. Unequip any existing item in this category first to prevent overlapping
	UnequipCategory(Player, Character, Category, DataStore)

	-- 2. Update Datastore and Attributes for the newly equipped item
	DataStore.Value.Milestones[MilestoneName].Equipped = true
	local MilestonesFolder = Player.PlayerStats.Milestones
	if MilestonesFolder:FindFirstChild(MilestoneName) then
		MilestonesFolder[MilestoneName]:SetAttribute("Equipped", true)
	end

	-- 3. Visually Apply to Character
	local RewardPrefab = RS:WaitForChild("MilestoneRewards"):FindFirstChild(ItemName)
	if not RewardPrefab then warn("Could not find prefab for", ItemName) return end

	local RewardClone = RewardPrefab:Clone()
	RewardClone:SetAttribute("MilestoneCategory", Category) -- Tag it so we can easily remove it later!

	if RewardType == "Accessory" then
		RewardClone.Parent = Character
		local Humanoid = Character:FindFirstChild("Humanoid")
		if Humanoid then
			Humanoid:AddAccessory(RewardClone)
		end

	elseif RewardType == "Model" then
		RewardClone.Parent = Character
		for _, part in pairs(RewardClone:GetChildren()) do
			if part:IsA("BasePart") and string.sub(part.Name, 1, 4) == "Main" then
				part.CollisionGroup = "Players"
				part.Transparency = 1
				part.CanCollide = false

				-- Match "MainUpperTorso" -> "UpperTorso"
				local charPartName = string.gsub(part.Name, "Main", "") 
				local charPart = Character:FindFirstChild(charPartName)

				if charPart then
					-- CFrame and Weld type shi
					part.CFrame = charPart.CFrame
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = charPart
					weld.Part1 = part
					weld.Parent = part
				end
			end
		end
	end
	for i,v in pairs(Character:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CollisionGroup = "Players"
		end
	end
end

-- [[ REMOTE EVENT LISTENERS ]]
MilestonesRem.OnServerEvent:Connect(function(Player, Action, Data)
	local Character = Player.Character
	if not Character then return end

	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
	if not DataStore then return end

	if Action == "EquipItem" and Data then
		local msName = Data.MilestoneName
		-- Verify they actually unlocked it to prevent exploiters
		if DataStore.Value.Milestones[msName] and DataStore.Value.Milestones[msName].Unlocked == true then
			EquipReward(Player, Character, msName, DataStore)
		end

	elseif Action == "UnEquipItem" and Data then
		local msName = Data.MilestoneName
		local MilestoneData = MilestonesDictionary.Milestones[msName]
		if MilestoneData then
			local Category = GetCategory(MilestoneData.Reward)
			UnequipCategory(Player, Character, Category, DataStore)
		end
	end
end)

-- [[ PLAYER ADDED & DATA LOAD ]]
Players.PlayerAdded:Connect(function(Player)
	Player.CharacterAdded:Connect(function(Character)
		repeat task.wait(1) until Player:FindFirstChild("PlayerInfo") and Character:FindFirstChild("ToolFolder")

		local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
		if not DataStore then return end

		local Milestones = Player:WaitForChild("PlayerStats"):WaitForChild("Milestones")

		-- 1. STAT TRACKER LOOP
		for _, MilestoneVal in pairs(Milestones:GetChildren()) do
			for _, Stat in pairs(Player:GetDescendants()) do
				if Stat:IsA("NumberValue") then
					if Stat.Name == MilestonesDictionary.Milestones[MilestoneVal.Name].Stat and MilestoneVal.Value == false then

						local StatConnection -- Variable for the server connection

						local function UpdateMilestone()
							if Stat.Value >= MilestonesDictionary.Milestones[MilestoneVal.Name].Value then
								MilestoneVal.Value = true
								DataStore.Value.Milestones[MilestoneVal.Name].Unlocked = true

								-- FIX: Stop the server from continuously checking this finished milestone
								if StatConnection then
									StatConnection:Disconnect()
								end
							end
						end

						UpdateMilestone()
						StatConnection = Stat:GetPropertyChangedSignal("Value"):Connect(UpdateMilestone)
					end
				end	
			end
		end

		-- 2. AUTO-EQUIP SAVED ITEMS ON SPAWN
		task.delay(1, function()
			for msName, msData in pairs(DataStore.Value.Milestones) do
				if msData.Unlocked and msData.Equipped then
					EquipReward(Player, Character, msName, DataStore)
				end
			end
		end)

	end)
end)