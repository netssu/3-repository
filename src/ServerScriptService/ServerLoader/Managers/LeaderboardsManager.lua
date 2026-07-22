local leaderboardsModule = {}

function leaderboardsModule.Init()
	--//Services
	local DataStoreService = game:GetService("DataStoreService")
	local ServerStorage = game:GetService("ServerStorage")
	local Players = game:GetService("Players")
	local Rs = game:GetService("ReplicatedStorage")
	
	--//Data
	local PlayerWins = DataStoreService:GetOrderedDataStore("PlayerWins")
	local PlayerCoins = DataStoreService:GetOrderedDataStore("PlayerCoins")
	local PlayerKills = DataStoreService:GetOrderedDataStore("PlayerKills")
	local PlayerTimeChap1 = DataStoreService:GetOrderedDataStore("PlayerTimeChap1")
	
	--//Modules
	local ModulesFolder = Rs:FindFirstChild("Modules")
	local Utils = ModulesFolder:FindFirstChild("Utils")
	
	local DataHandler = require(ModulesFolder:FindFirstChild("DataHandler"))
	local FormatString = require(Utils:FindFirstChild("FormatString"))
	
	--//UI
	local BoardsStuff = ServerStorage:FindFirstChild("BoardsStuff")
	local ColocationFrameExample = BoardsStuff:FindFirstChild("ColocationExample")
	local LeaderBoardsFolder = workspace:FindFirstChild("Map"):FindFirstChild("LeaderBoards")
	
	local WinsLeaderboard = LeaderBoardsFolder:FindFirstChild("WinsLeaderboard")
	local WinsLeaderBoardFrame = WinsLeaderboard.Screen.WinsLeaderboardScreen.MainFrame.LeaderboardWins
	
	local CoinsLeaderboard = LeaderBoardsFolder:FindFirstChild("CoinsLeaderboard")
	local CoinsLeaderBoardFrame = CoinsLeaderboard.Screen.CoinsLeaderboardScreen.MainFrame.LeaderboardCoins
	
	local KillsLeaderboard = LeaderBoardsFolder:FindFirstChild("KillsLeaderboard")
	local KillsLeaderBoardFrame = KillsLeaderboard.Screen.KillsLeaderboardScreen.MainFrame.LeaderboardKills
	
	local Chap1Leaderboard = LeaderBoardsFolder:FindFirstChild("Chap1Leaderboard")
	local Chap1LeaderBoardFrame = Chap1Leaderboard.Screen.Chap1TimeLeaderboardScreen.MainFrame.LeaderboardChap1Time
	
	--//Rank Effects
	local Rank1Effect = BoardsStuff:FindFirstChild("Rank1")
	local Rank2Effect = BoardsStuff:FindFirstChild("Rank2")
	local Rank3Effect = BoardsStuff:FindFirstChild("Rank3")
	
	--//Values
	local UpdateCooldown = 60
	local LastUpdateTime = {}
	local nameCache = {}
	local thumbnailCache = {}
	local valueCache = {}
	
	--//Check if can update player leaderboard value
	local function CanUpdateStat(userId: number, statName: string)
		local now = tick()
		LastUpdateTime[tostring(userId)] = LastUpdateTime[tostring(userId)] or {}
		
		if now - (LastUpdateTime[tostring(userId)][statName] or 0) >= UpdateCooldown then
			LastUpdateTime[tostring(userId)][statName] = now
			return true
		end
		return false
	end
	
	--//Check if player value really changed
	local function CheckIfValueChanged(userId: number, statName: string, newValue: number)
		local currentValue = valueCache[userId] and valueCache[userId][statName] or 0
		valueCache[userId] = valueCache[userId] or {}
		newValue = newValue or 0
		
		if newValue ~= valueCache[userId][statName] then
			valueCache[userId][statName] = newValue
			return true
		end
		return false
	end
	
	--//Update coins value in OrderedDataStore
	local function UpdateCoinsInLeaderboard(userId, value)
		if typeof(userId) ~= "number" or typeof(value) ~= "number" then return end
		local success, errmsg = pcall(function()
			PlayerCoins:UpdateAsync(userId, function(oldValue)
				return value
			end)
		end)
		if not success then
			warn("Error to update [COINS] leaderboard of player "..userId..": ", errmsg)
		end
	end
	
	--//Update wins value in OrderedDataStore
	local function UpdateWinsLeaderboard(userId, value)
		if typeof(userId) ~= "number" or typeof(value) ~= "number" then return end
		local success, errmsg = pcall(function()
			PlayerWins:UpdateAsync(userId, function(oldValue)
				return value
			end)
		end)
		if not success then
			warn("Error to update [WINS] leaderboard of player "..userId..": ", errmsg)
		end
	end
	
	--//Update kills value in OrderedDataStore
	local function UpdateKillsLeaderboard(userId, value)
		if typeof(userId) ~= "number" or typeof(value) ~= "number" then return end
		local success, errmsg = pcall(function()
			PlayerKills:UpdateAsync(userId, function(oldValue)
				return value
			end)
		end)
		if not success then
			warn("Error to update [KILLS] leaderboard of player "..userId..": ", errmsg)
		end
	end
	
	--//Update Chap1Time value in OrderedDataStore
	local function UpdateChap1TimeLeaderboard(userId, value) -- should be a string
		if typeof(userId) ~= "number" or typeof(value) ~= "number" then return end
		local success, errmsg = pcall(function()
			PlayerTimeChap1:UpdateAsync(userId, function(oldValue)
				return math.floor(value * 1000)
			end)
		end)
		if not success then
			warn("Error to update [Chap1Time] leaderboard of player "..userId..": ", errmsg)
		end
	end
	
	Players.PlayerAdded:Connect(function(plr)
		local userId = plr.UserId
		LastUpdateTime[userId] = 0
		
		local leaderstats = plr:WaitForChild("leaderstats", 10)
		if not leaderstats then return end
		
		--//COINS
		
		local coins = leaderstats:WaitForChild("Coins", 10) :: IntValue
		if not coins then return end
		
		coins:GetPropertyChangedSignal("Value"):Connect(function()
			local canUpdate = CanUpdateStat(userId, "Coins")
			local valueChanged = CheckIfValueChanged(userId, "Coins", coins.Value)
			if canUpdate and valueChanged then
				UpdateCoinsInLeaderboard(userId, coins.Value)
			end
		end)
		
		local canUpdate = CanUpdateStat(userId, "Coins")
		local valueChanged = CheckIfValueChanged(userId, "Coins", coins.Value)
		if canUpdate and valueChanged then
			UpdateCoinsInLeaderboard(userId, coins.Value)
		end
		
		--//WINS
		
		local wins = leaderstats:WaitForChild("Wins", 10) :: IntValue
		if not wins then return end
		
		wins:GetPropertyChangedSignal("Value"):Connect(function()
			local canUpdate = CanUpdateStat(userId, "Wins")
			local valueChanged = CheckIfValueChanged(userId, "Wins", wins.Value)
			if canUpdate and valueChanged then
				UpdateWinsLeaderboard(userId, wins.Value)
			end
		end)
		
		local canUpdate = CanUpdateStat(userId, "Wins")
		local valueChanged = CheckIfValueChanged(userId, "Wins", wins.Value)
		if canUpdate and valueChanged then
			UpdateWinsLeaderboard(userId, wins.Value)
		end
		
		--//KILLS
		
		local kills = leaderstats:WaitForChild("Kills", 10) :: IntValue
		if not kills then return end
		
		kills:GetPropertyChangedSignal("Value"):Connect(function()
			local canUpdate = CanUpdateStat(userId, "Kills")
			local valueChanged = CheckIfValueChanged(userId, "Kills", kills.Value)
			if canUpdate and valueChanged then
				UpdateKillsLeaderboard(userId, kills.Value)
			end
		end)
		
		local canUpdate = CanUpdateStat(userId, "Kills")
		local valueChanged = CheckIfValueChanged(userId, "Kills", kills.Value)
		if canUpdate and valueChanged then
			UpdateKillsLeaderboard(userId, kills.Value)
		end
		
		--//CHAP1TIME
		
		local canUpdate = CanUpdateStat(userId, "Chap1Time")
		local plrData = DataHandler:GetProfileData(plr)
		
		if not plrData then return end
		
		local speedrunTime = plrData.Speedruns["Chapter1"]
		if not speedrunTime then return end
		
		local valueChanged = CheckIfValueChanged(userId, "Chap1Time", speedrunTime)
		if canUpdate and valueChanged then
			UpdateChap1TimeLeaderboard(userId, tonumber(speedrunTime))
		end
	end)
	
	Players.PlayerRemoving:Connect(function(plr)
		local userId = plr.UserId
		local leaderstats = plr:FindFirstChild("leaderstats")
		local coins = leaderstats and leaderstats:WaitForChild("Coins")
		local wins = leaderstats and leaderstats:WaitForChild("Wins")
		local kills = leaderstats and leaderstats:WaitForChild("Kills")
		
		local changedVal1 = coins and CheckIfValueChanged(plr.UserId, "Coins", coins.Value)
		if coins and typeof(coins.Value) == "number" and changedVal1 then
			UpdateCoinsInLeaderboard(userId, coins.Value)
		end
		
		local changedVal2 = wins and CheckIfValueChanged(plr.UserId, "Wins", wins.Value)
		if wins and typeof(wins.Value) == "number" and changedVal2 then
			UpdateWinsLeaderboard(userId, wins.Value)
		end
		
		local changedVal3 = kills and CheckIfValueChanged(plr.UserId, "Kills", kills.Value)
		if kills and typeof(kills.Value) == "number" and changedVal3 then
			UpdateKillsLeaderboard(userId, kills.Value)
		end
		
		local plrData = DataHandler:GetProfileData(plr)
		
		if plrData then
			local speedrunTime = plrData.Speedruns["Chapter1"]
			if not speedrunTime then return end
			local valueChanged = CheckIfValueChanged(plr.UserId, "Chap1Time", speedrunTime)
			if valueChanged then
				UpdateChap1TimeLeaderboard(userId, tonumber(speedrunTime))
			end
		end
		
		nameCache[plr.UserId] = nil
		thumbnailCache[plr.UserId] = nil
		valueCache[plr.UserId] = nil
		LastUpdateTime[userId] = nil
	end)
	
	local function getPlrName(entry)
		local plrname = nil
		if not nameCache[entry.key] then
			local success, name = pcall(function()
				return Players:GetNameFromUserIdAsync(entry.key)
			end)
			if success and name then
				nameCache[entry.key] = name
			else
				warn("Can't get name of the player with id:", entry.key, "|", name)
			end
		end
		plrname = nameCache[entry.key]
		return plrname
	end
	
	local function getPlrThumbnail(entry)
		local thumb = nil
		if not thumbnailCache[entry.key] then
			local success, thumbnail = pcall(function()
				return Players:GetUserThumbnailAsync(entry.key, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
			end)
			if success and thumbnail then
				thumbnailCache[entry.key] = thumbnail
			else
				warn("Can't get thumbnail of the player with id:", entry.key, "|", thumbnail)
			end
		end
		thumb = thumbnailCache[entry.key]
		return thumb
	end
	
	local function UpdateLeaderboardUI(entry, rank, leaderboard, leaderboardFrame)
		local colocation = ColocationFrameExample:Clone()
		local username = getPlrName(entry)
		
		if rank == 1 then
			local Rank1Gradient = Rank1Effect:Clone()
			Rank1Gradient.Parent = colocation.PlrName
			leaderboard.R15Loader.Configuration.userId.Value = entry.key
		elseif rank == 2 then
			local Rank2Gradient = Rank2Effect:Clone()
			Rank2Gradient.Parent = colocation.PlrName
		elseif rank == 3 then
			local Rank3Gradient = Rank3Effect:Clone()
			Rank3Gradient.Parent = colocation.PlrName
		end
		
		local plrHeadshotIcon = getPlrThumbnail(entry)
		
		colocation.Place.Text = tostring(rank)
		colocation.PlrName.Text = username and username or "Unknown"
		
		if leaderboard:GetAttribute("TimeLeaderboard") then
			local formatedString = FormatString:TimeString(entry.value/1000, true)
			colocation.InstanceText.Text = formatedString
		else
			colocation.InstanceText.Text = entry.value
		end
		
		colocation.PlrImage.Image = plrHeadshotIcon and plrHeadshotIcon or "rbxassetid://0"
		colocation.Parent = leaderboardFrame
	end
	
	local function checkValidyEntry(entry): boolean
		if typeof(entry.key) ~= "number" and typeof(entry.value) ~= "number" then return false end
		return true
	end
	
	local function UpdateLeaderboard(dataStore, boardModel, frameHolder, ascending: boolean)
		local success, pages = pcall(function()
			return dataStore:GetSortedAsync(ascending, 50, 1)
		end)
		if success then
			local entries = pages:GetCurrentPage()
			
			for _, v in frameHolder:GetChildren() do
				if v:IsA("Frame") then
					v:Destroy()
				end
			end
			
			for rank, entry in ipairs(entries) do
				if not checkValidyEntry(entry) then continue end
				pcall(function()
					UpdateLeaderboardUI(entry, rank, boardModel, frameHolder)
				end)
			end
		end
	end
	
	--//Player Coins LeaderBoard
	coroutine.wrap(function()
		while true do
			UpdateLeaderboard(PlayerCoins, CoinsLeaderboard, CoinsLeaderBoardFrame, false)
			task.wait(UpdateCooldown)
		end
	end)()
	
	--//Player Wins LeaderBoard
	coroutine.wrap(function()
		while true do
			UpdateLeaderboard(PlayerWins, WinsLeaderboard, WinsLeaderBoardFrame, false)
			task.wait(UpdateCooldown)
		end
	end)()
	
	--//Player Kills LeaderBoard
	coroutine.wrap(function()
		while true do
			UpdateLeaderboard(PlayerKills, KillsLeaderboard, KillsLeaderBoardFrame, false)
			task.wait(UpdateCooldown)
		end
	end)()
	
	--//Player run times - Chapter 1 LeaderBoard
	coroutine.wrap(function()
		while true do
			UpdateLeaderboard(PlayerTimeChap1, Chap1Leaderboard, Chap1LeaderBoardFrame, true)
			task.wait(UpdateCooldown)
		end
	end)()
end

return leaderboardsModule