local DSS = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local CS = game:GetService("CollectionService")
local SS = game:GetService("ServerStorage")

-- Require Suphi's Datastore Module to read active player data
local DataStoreModule = require(SS:WaitForChild("Modules").MainDataModule)

local BaseGui = script:WaitForChild("LeaderboardGui")

-- Define our OrderedDataStores for global sorting
local ODS = {
	["Cash"] = DSS:GetOrderedDataStore("GlobalLeaderboard_Cash_V1"),
	["Food"] = DSS:GetOrderedDataStore("GlobalLeaderboard_Food_V1"),
	["Level"] = DSS:GetOrderedDataStore("GlobalLeaderboard_Level_V1"),
	["Ingredients"] = DSS:GetOrderedDataStore("GlobalLeaderboard_Ingredients_V1"),
	["Rebirths"] = DSS:GetOrderedDataStore("GlobalLeaderboard_Rebirths_V1"),
	["TotalTimePlayed"] = DSS:GetOrderedDataStore("GlobalLeaderboard_TotalTimePlayed_V1")
}

-- [[ FORMATTING HELPERS ]]
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
	if ab < 1000 then return roundToDecimals(x, decimalPlaces) end 
	local num = roundToDecimals(ab / Nums[p], decimalPlaces)
	return num * math.sign(x) .. names[p]
end

-- Cache player names to prevent hitting Roblox API limits
local NameCache = {}
local function GetPlayerName(userId)
	if NameCache[userId] then return NameCache[userId] end
	local success, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	if success then
		NameCache[userId] = name
		return name
	end
	return "Unknown Player"
end

-- [[ LEADERBOARD CUSTOMIZATION CONFIG ]]
local LeaderboardConfig = {
	["Cash"] = {
		PrimaryColor = Color3.fromRGB(23, 200, 23),   -- Green
		SecondaryColor = Color3.fromRGB(130, 130, 130), -- Grey
		HeaderText = "Cash"
	},
	["Food"] = {
		PrimaryColor = Color3.fromRGB(255, 150, 20),  -- Orange
		SecondaryColor = Color3.fromRGB(130, 130, 130), -- Grey
		HeaderText = "Food"
	},
	["Level"] = {
		PrimaryColor = Color3.fromRGB(45, 150, 255),  -- Blue
		SecondaryColor = Color3.fromRGB(130, 130, 130), -- Grey
		HeaderText = "Level"
	},
	["Rebirths"] = {
		PrimaryColor = Color3.fromRGB(0, 255, 255),  -- Blue
		SecondaryColor = Color3.fromRGB(130, 130, 130), -- Grey
		HeaderText = "Rebirths"
	},
	["Ingredients"] = {
		PrimaryColor = Color3.fromRGB(161, 196, 140),  -- Blue
		SecondaryColor = Color3.fromRGB(130, 130, 130), -- Grey
		HeaderText = "Ingredients"
	},
	["TotalTimePlayed"] = {
		PrimaryColor = Color3.fromRGB(198, 198, 198),  -- Yellowish/Gold
		SecondaryColor = Color3.fromRGB(130, 130, 130), -- Grey
		HeaderText = "Mins"
	}
}

-- [[ CORE FUNCTIONS ]]

-- 1. Extract active stats from Suphi's Module and save to OrderedDataStores
local function SaveActivePlayersToLeaderboard()
	for _, plr in pairs(Players:GetPlayers()) do
		local ds = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, plr.UserId)

		if ds and ds.State == true then
			-- OrderedDataStores ONLY accept integers, so we use math.floor()
			pcall(function() ODS["Cash"]:SetAsync(plr.UserId, math.floor(ds.Value.Cash)) end)
			pcall(function() ODS["Food"]:SetAsync(plr.UserId, math.floor(ds.Value.Food)) end)
			pcall(function() ODS["Level"]:SetAsync(plr.UserId, math.floor(ds.Value.Level)) end)
			pcall(function() ODS["Ingredients"]:SetAsync(plr.UserId, math.floor(ds.Value.Ingredients)) end)
			pcall(function() ODS["Rebirths"]:SetAsync(plr.UserId, math.floor(ds.Value.Rebirths)) end)
			pcall(function() ODS["TotalTimePlayed"]:SetAsync(plr.UserId, math.floor(ds.Value.TotalTimePlayed)) end)
		end
	end
end

-- 2. Fetch Top 50 and update all tagged models
local function RefreshLeaderboardModels()
	for _, boardModel in pairs(CS:GetTagged("GlobalLeaderboard")) do
		local statVal = boardModel:FindFirstChild("StatDisplayed")
		local displayPart = boardModel:FindFirstChild("DisplayPart")

		if not statVal or not displayPart then continue end

		local statType = statVal.Value
		local store = ODS[statType]
		local config = LeaderboardConfig[statType] -- Pull the custom settings!

		if not store or not config then continue end

		-- Fetch top 50 players (Ascending = false means Highest to Lowest)
		local success, pages = pcall(function()
			return store:GetSortedAsync(false, 50)
		end)

		if success then
			local currentPage = pages:GetCurrentPage()

			-- Setup the GUI on the part
			local gui = displayPart:FindFirstChild("LeaderboardGui")
			if not gui then
				gui = BaseGui:Clone()
				gui.Parent = displayPart
			end

			-- [[ DYNAMIC HEADER TEXT ]]
			-- Looks for a TextLabel named "HeaderStatLabel" to change the "Time" text
			local headerStatLabel = gui:FindFirstChild("TopFrame").TimeLabel
			if headerStatLabel then
				headerStatLabel.Text = config.HeaderText
				headerStatLabel.TextColor3 = config.PrimaryColor 
			end

			-- Safely clear old frames
			for _, child in pairs(gui.PlayerFrame:GetChildren()) do
				if string.find(child.Name, "Rank_") then
					child:Destroy()
				end
			end

			-- Populate with new data
			for rank, data in ipairs(currentPage) do
				local userId = tonumber(data.key)
				local value = data.value
				local playerName = GetPlayerName(userId)

				local frame = gui.PlayerFrameTemplate:Clone()
				frame.Name = "Rank_" .. rank

				-- [[ ALTERNATING COLORS ]]
				if rank % 2 ~= 0 then
					-- Odd Ranks (1, 3, 5...) get the Primary Custom Color
					frame.BackgroundColor3 = config.PrimaryColor
				else
					-- Even Ranks (2, 4, 6...) get the Grey Secondary Color
					frame.BackgroundColor3 = config.SecondaryColor
				end

				frame.RankLabel.Text = "#" .. rank
				frame.PlayerLabel.Text = playerName

				-- Format specific stats differently if needed
				if statType == "TotalTimePlayed" then
					frame.TimeLabel.Text = FrmtNum(value, 0)
				elseif statType == "Cash" then
					frame.TimeLabel.Text = "$" .. FrmtNum(value, 2)
				else
					frame.TimeLabel.Text = FrmtNum(value, 2)
				end

				frame.Parent = gui.PlayerFrame
				frame.Visible = true
			end
		else
			warn("Failed to fetch leaderboard data for: " .. statType)
		end
	end
end

-- [[ LOOPS ]]

-- Main Leaderboard Refresh Loop
task.spawn(function()
	-- Give the server a few seconds to load before the first refresh
	task.wait(5) 
	while true do
		SaveActivePlayersToLeaderboard()
		RefreshLeaderboardModels()
		task.wait(60) -- Refreshes every 1 minute
	end
end)

-- Total Time Played Tracker (Adds 1 minute to the player's stat every 60 seconds)
task.spawn(function()
	while true do
		task.wait(60)
		for _, plr in pairs(Players:GetPlayers()) do
			local ds = DataStoreModule.find(require(game.ReplicatedStorage.Modules.CurrentDataStore).DataStore, plr.UserId)
			if ds and ds.State == true then
				ds.Value.TotalTimePlayed += 1
			end
		end
	end
end)