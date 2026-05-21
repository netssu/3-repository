local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local DataStoreModule = require(SS:WaitForChild("Modules").MainDataModule)
local TimedGiftRem = RS:WaitForChild("Remotes"):WaitForChild("TimedGiftRem")

local GROUP_ID = 35501365 -- Replace with your actual Group ID!

TimedGiftRem.OnServerEvent:Connect(function(Player, Action)
	local Char = Player.Character
	if Action == "ClaimGift" then
		if Char:GetAttribute("ClaimedPeriodicGift") == true then
			return
		end
		-- 1. Check if they are in the group
		if not Player:IsInGroupAsync(GROUP_ID) then
			-- Tell client they failed the group check
			TimedGiftRem:FireClient(Player, "NotInGroup")
			return
		end

		-- 2. Verify DataStore
		local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
		local PlayerStats = Player:FindFirstChild("PlayerStats")
		local Leaderstats = Player:FindFirstChild("leaderstatValues")
		if not DataStore or not PlayerStats or not Leaderstats then return end

		-- 3. Give Rewards (2k Food, 2k Ingredients, 5 Rebirths)

		-- Food
		Char:SetAttribute("ClaimedPeriodicGift",true)

		DataStore.Value.Food += 5000
		Leaderstats.Food.Value = DataStore.Value.Food

		-- Ingredients
		DataStore.Value.Ingredients += 7000
		PlayerStats.Ingredients.Value = DataStore.Value.Ingredients

		-- Rebirths
		DataStore.Value.Rebirths += 10
		PlayerStats.Rebirths.Value = DataStore.Value.Rebirths

		print(Player.Name .. " successfully claimed the Timed Group Gift!")

		-- 4. Tell client it was successful to start the cooldown
		TimedGiftRem:FireClient(Player, "ClaimSuccess")
		elseif Action == "ReadyToBeClaimed" and Char:GetAttribute("ClaimedPeriodicGift") == true then
			Char:SetAttribute("ClaimedPeriodicGift",false)
	end		
end)