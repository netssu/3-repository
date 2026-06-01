--SERVICES
local SS = game:GetService("ServerStorage")
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--MODULES
local DataStoreModule = require(SS:WaitForChild("Modules").MainDataModule)

--REMOTES
local DailyRewardRem = RS:WaitForChild("Remotes"):WaitForChild("DailyRewardRem")

-- REWARDS CONFIGURATION (Matches your UI)
local DAILY_REWARDS = {
	[1] = {Type = "Rebirths", Amount = 5},
	[2] = {Type = "Ingredients", Amount = 50000},
	[3] = {Type = "Food", Amount = 75000},
	[4] = {Type = "Cash", Amount = 100000},
	[5] = {Type = "Food", Amount = 500000},
	[6] = {Type = "Cash", Amount = 600000},
	[7] = {Type = "Unlock", Item = "Red Chef Shirt"} -- Custom unlock
}

-- Helper: Get the current UTC Day
local function GetCurrentUTCDay()
	return math.floor(os.time() / 86400)
end

-- HELPER: Process the actual reward
local function GiveReward(Player, DataStore, Day)
	local Reward = DAILY_REWARDS[Day]
	if not Reward then return end

	local PlayerStats = Player:FindFirstChild("PlayerStats")
	local Leaderstats = Player:FindFirstChild("leaderstatValues")
	if not PlayerStats or not Leaderstats then return end

	if Reward.Type == "Rebirths" then
		DataStore.Value.Rebirths += Reward.Amount
		PlayerStats.Rebirths.Value = DataStore.Value.Rebirths

	elseif Reward.Type == "Ingredients" then
		DataStore.Value.Ingredients += Reward.Amount
		PlayerStats.Ingredients.Value = DataStore.Value.Ingredients

	elseif Reward.Type == "Food" then
		DataStore.Value.Food += Reward.Amount
		Leaderstats.Food.Value = DataStore.Value.Food

	elseif Reward.Type == "Cash" then
		DataStore.Value.Cash += Reward.Amount
		Leaderstats.Cash.Value = DataStore.Value.Cash

	elseif Reward.Type == "Unlock" then
		if DataStore.Value.Milestones and DataStore.Value.Milestones["Day7Reward"] then
			DataStore.Value.Cash += 800_000
			Leaderstats.Cash.Value = DataStore.Value.Cash
			DataStore.Value.Milestones["Day7Reward"].Unlocked = true
			PlayerStats.Milestones.Day7Reward.Value = true
		end
		print(Player.Name .. " Unlocked the Chef Red Shirt!")
	end

	--print(Player.Name .. " claimed Day " .. Day .. " reward: " .. Reward.Amount .. " " .. Reward.Type)
end


DailyRewardRem.OnServerEvent:Connect(function(Player, Action)
	local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
	if not DataStore then return end

	local CurrentDay = math.floor(os.time() / 86400)
	local LastDay = DataStore.Value.LastDailyDay
	local Streak = DataStore.Value.DailyStreak
	local CanClaim = false

	-- [[ REWRITTEN TO NEVER BREAK STREAK ]]
	if LastDay == 0 then
		-- FIRST TIME JOINING! Make Day 1 instantly claimable.
		CanClaim = true
		Streak = 1
		DataStore.Value.DailyStreak = Streak

	elseif CurrentDay > LastDay then
		-- A NEW DAY (No matter if it's 1 day later or 10 days later, they keep their progress)
		CanClaim = true

		-- If they finished Day 7 previously, reset to Day 1 today
		if Streak > 7 then
			Streak = 1
			DataStore.Value.DailyStreak = Streak
		end

	elseif CurrentDay == LastDay then
		-- They already claimed today.
		CanClaim = false
	end

	-- [[ HANDLE ACTIONS ]]
	if Action == "RequestInfo" then
		DailyRewardRem:FireClient(Player, "UpdateUI", {
			Streak = Streak,
			CanClaim = CanClaim
		})

	elseif Action == "Claim" then
		if CanClaim then
			GiveReward(Player, DataStore, Streak)
			
			DataStore.Value.LastDailyDay = CurrentDay
			DataStore.Value.DailyStreak = Streak + 1 -- Lock it in for tomorrow

			-- IMPORTANT FIX: We are now passing 'Streak' back to the client!
			DailyRewardRem:FireClient(Player, "ClaimSuccess", Streak)
		end
	end
end)