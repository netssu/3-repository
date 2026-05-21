-- [[ HIRED WORKERS / OFFLINE EARNINGS SERVER SCRIPT ]] --
local CS = game:GetService("CollectionService")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

--MODULES
local DataStoreModule = require(SS:WaitForChild("Modules").MainDataModule)

--REMOTES
local OfflineEarningsRem = RS:WaitForChild("Remotes"):WaitForChild("OfflineEarningsRem")


-- Number Formatter Helper
local names = {"K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dd"}
local Nums = {}
for i = 1, #names do table.insert(Nums, 1000^i) end
local function FrmtNum(x: number, decimalPlaces: number)
	local function roundToDecimals(num, decimals)
		local formatString = string.format("%%.%df", decimals)
		return tonumber(string.format(formatString, num))
	end
	local ab = math.abs(x)
	local p = math.min(math.floor(math.log10(ab)/3), #names)
	if ab < 1000 then return roundToDecimals(x, decimalPlaces) end 
	local num = roundToDecimals(ab / Nums[p], decimalPlaces)
	return num * math.sign(x) .. names[p]
end

local ClaimDebounce = {}

-- UI UPDATE FUNCTION
local function UpdateOfflineUI(DataStore, Plot)
	local SurfaceGui = Plot.Base.OfflineReward.SecondaryBuildingColorPart.SurfaceGui
	local InfoText = SurfaceGui.Info
	local StatsFrame = SurfaceGui.Stats
	local TitleText = SurfaceGui.Title

	local hasShopper = DataStore.Value.HiredWorkers.Shopper.Unlocked
	local hasSeller = DataStore.Value.HiredWorkers.Seller.Unlocked
	local hasChef = DataStore.Value.RestaurantUnlocks.ChefUnlocked

	local ingOff = DataStore.Value.OfflineEarnings.IngredientsOffline
	local cashOff = DataStore.Value.OfflineEarnings.CashOffline
	local gfOff = DataStore.Value.OfflineEarnings["Gourmet FoodOffline"]

	-- IF THEY HAVE EARNINGS WAITING
	if ingOff > 0 or cashOff > 0 or gfOff > 0 then
		InfoText.Visible = false
		StatsFrame.Visible = true
		TitleText.Visible = true

		-- [[ 1. Cash ]]
		if cashOff > 0 then
			StatsFrame.Cash.Visible = true
			StatsFrame.Cash.CashAmount.Text = "+" .. FrmtNum(cashOff, 2)
		else
			StatsFrame.Cash.Visible = false
		end

		-- [[ 2. Gourmet Food ]]
		if gfOff > 0 then
			StatsFrame["Gourmet Food"].Visible = true
			StatsFrame["Gourmet Food"]["Gourmet FoodAmount"].Text = "+" .. FrmtNum(gfOff, 2)
		else
			StatsFrame["Gourmet Food"].Visible = false
		end

		-- [[ 3. Ingredients ]]
		if ingOff > 0 then
			StatsFrame.Ingredients.Visible = true
			StatsFrame.Ingredients.IngredientsAmount.Text = "+" .. FrmtNum(ingOff, 2)
		else
			StatsFrame.Ingredients.Visible = false
		end

		-- IF THEY HAVE 0 EARNINGS WAITING
	else
		StatsFrame.Visible = false
		TitleText.Visible = false
		InfoText.Visible = true

		-- Check if they have ANY worker unlocked
		if hasShopper or hasSeller or hasChef then
			InfoText.Text = "Come Back Tomorrow for your Offline Earnings!"
		else
			InfoText.Text = "Unlock Workers To Start Earning Offline!"
		end
	end
end


Players.PlayerAdded:Connect(function(Player)
	task.delay(6, function()
		if not Player or not Player.Parent then return end
		local Plots = workspace.Plots
		local PlayerStats = Player:FindFirstChild("PlayerStats")
		if not PlayerStats then return end

		local PlayerInfo = Player:WaitForChild("PlayerInfo")
		local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
		local PlayersSpotVal = PlayerInfo.PlayerSpot

		if PlayersSpotVal.Value == "None" or PlayersSpotVal.Value == "" then
			PlayersSpotVal:GetPropertyChangedSignal("Value"):Wait()
		end

		local PlayersPlot = Plots:FindFirstChild(PlayersSpotVal.Value)
		local OfflineEarningTouchPart:BasePart = PlayersPlot:WaitForChild("Base").OfflineReward.TouchPart
		OfflineEarningTouchPart.SurfaceGui.Enabled = true
		OfflineEarningTouchPart.Parent.SecondaryBuildingColorPart.SurfaceGui.Enabled = true


		-- 1. UPDATE UI ON JOIN
		UpdateOfflineUI(DataStore, PlayersPlot)

		-- 2. TOUCH EVENT (OPENS UI)
		OfflineEarningTouchPart.Touched:Connect(function(OtherPart)
			local Character = OtherPart.Parent
			local Plr = Players:GetPlayerFromCharacter(Character)

			if not Plr or PlayersPlot.Info.Occupant.Value ~= Plr.Name then return end

			-- Spam Prevention
			if ClaimDebounce[Plr.UserId] then return end
			ClaimDebounce[Plr.UserId] = true

			local ingOff = DataStore.Value.OfflineEarnings.IngredientsOffline
			local cashOff = DataStore.Value.OfflineEarnings.CashOffline
			local gfOff = DataStore.Value.OfflineEarnings["Gourmet FoodOffline"]

			-- Only prompt UI if they actually have something!
			if ingOff > 0 or cashOff > 0 or gfOff > 0 then
				OfflineEarningsRem:FireClient(Plr, "OpenUI", {
					Ing = ingOff,
					Cash = cashOff,
					GF = gfOff
				})
			end

			task.wait(1.5)
			ClaimDebounce[Plr.UserId] = false
		end)

	end)
end)

-- HANDLE STANDARD CLAIMING
OfflineEarningsRem.OnServerEvent:Connect(function(Player, Action)
	if Action == "StandardClaim" then
		local DataStore = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, Player.UserId)
		local PlayerStats = Player:FindFirstChild("PlayerStats")
		local leaderstatValues = Player:FindFirstChild("leaderstatValues")

		if not DataStore or not PlayerStats or not leaderstatValues then return end

		local ingOff = DataStore.Value.OfflineEarnings.IngredientsOffline
		local cashOff = DataStore.Value.OfflineEarnings.CashOffline
		local gfOff = DataStore.Value.OfflineEarnings["Gourmet FoodOffline"]

		if ingOff > 0 or cashOff > 0 or gfOff > 0 then
			DataStore.Value.Ingredients += ingOff
			PlayerStats.Ingredients.Value = DataStore.Value.Ingredients

			DataStore.Value.Cash += cashOff
			leaderstatValues.Cash.Value = DataStore.Value.Cash

			DataStore.Value["Gourmet Food"] += gfOff
			PlayerStats["Gourmet Food"].Value = DataStore.Value["Gourmet Food"]

			DataStore.Value.OfflineEarnings.IngredientsOffline = 0
			DataStore.Value.OfflineEarnings.CashOffline = 0
			DataStore.Value.OfflineEarnings["Gourmet FoodOffline"] = 0

			PlayerStats.OfflineEarnings.IngredientsOffline.Value = 0
			PlayerStats.OfflineEarnings.CashOffline.Value = 0
			PlayerStats.OfflineEarnings["Gourmet FoodOffline"].Value = 0

			OfflineEarningsRem:FireClient(Player, "StandardSuccess", {
				Ing = ingOff,
				Cash = cashOff,
				GF = gfOff
			})

			-- Update the Plot Billboard
			local PlayerInfo = Player:FindFirstChild("PlayerInfo")
			if PlayerInfo and PlayerInfo.PlayerSpot.Value ~= "None" then
				local Plot = workspace.Plots:FindFirstChild(PlayerInfo.PlayerSpot.Value)
				if Plot then UpdateOfflineUI(DataStore, Plot) end
			end
		end
	end
end)