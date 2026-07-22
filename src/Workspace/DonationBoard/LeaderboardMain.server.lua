local boardsetting = require(script.Parent.Settings)

local Datastore = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")

local DonationLeaderboard = Datastore:GetOrderedDataStore("TotalDonationLeaderboard")
local MonthlyDonationLeaderboard = Datastore:GetOrderedDataStore("TotalDonationLeaderboard"..os.date("*t").month..os.date("*t").year)
local AllTimePage = nil
local MonthlyPage = nil
local MarketplaceService = game:GetService("MarketplaceService")
local Frame = script.Parent.DonationLeaderboard.SurfaceGui.Frame
Frame.MainTitle.Text = os.date("%B"):lower().."'s donation"

local DonationButton = boardsetting.DonateButton
local DonateAnnouncement = game.ReplicatedStorage.DonateAnnouncement

local monthlystatue = script.Parent.MonthlyStatue
local alltimestatue = script.Parent.AllTimeStatue

local function aberviate(num)
	local decAcc = 2
	if num < 1000 then
		return num
	else
		local number = math.floor(num)
		local abreviations = {
			[3] = "K",
			[6] = "M",
			[9] = "B",
			[12] = "T",
			[15] = "Qa"
		}
		local show = #tostring(number) % 3
		if show == 0 then
			show = 3
		end
		local trueLength = #tostring(number) - show
		if abreviations[trueLength] then
			number = tostring(number)
			return string.sub(number,1,show)..".".. string.sub(number,show + 1,show+decAcc) ..   abreviations[trueLength]
		else
			return num
		end
	end
end

MessagingService:SubscribeAsync("DonateAnnouncement",function(Data)
	local Data = Data.Data
	script.Donated:Play()
	DonateAnnouncement:FireAllClients(Data.PlayerName,Data.RobuxAmount)
	
	local player = Players:GetPlayerByUserId(Players:GetUserIdFromNameAsync(Data.PlayerName))
	
	if player then
		local particle = script.RobuxParticle:Clone()
		particle.Parent = player.Character.HumanoidRootPart
		particle:Emit(100)
	end
end)

MarketplaceService.PromptProductPurchaseFinished:Connect(function(userid,id,purchased)
	if not purchased then return end
	
	local player = Players:GetPlayerByUserId(userid)
	
	for _,Options in pairs(DonationButton) do
		if Options.Id == id then
			local Amount = Options.Amount
			player.DonationData.TotalDonation.Value += Amount
			player.DonationData.MonthlyTotalDonation.Value += Amount
			
			MessagingService:PublishAsync("DonateAnnouncement",{PlayerName = player.Name,RobuxAmount = Amount})
		end
	end
	
	return Enum.ProductPurchaseDecision.PurchaseGranted
end)

function UpdateAllTime()
	for _, player in pairs(Players:GetPlayers()) do
		local leaderstats = player:FindFirstChild("DonationData")
		
		if not leaderstats then
			break
		end

		local statsValue = leaderstats:FindFirstChild("TotalDonation")

		if not statsValue then
			break
		end
		
		pcall(function()
			DonationLeaderboard:UpdateAsync(player.UserId, function()
				return tonumber(statsValue.Value)
			end)
		end)
	end
	
	for _,v in pairs(Frame.AllTimeBoard:GetChildren()) do
		if v:IsA("Frame") then
			v:Destroy()
		end
	end
	
	local data = DonationLeaderboard:GetSortedAsync(false, 100, 1, 10e15)
	AllTimePage = data:GetCurrentPage()
	
	for position, v in ipairs(AllTimePage) do
		task.spawn(function()
			local userId = v.key
			local value = v.value
			local username = "[Not Available]"

			local success, err = pcall(function()
				username = Players:GetNameFromUserIdAsync(userId)
			end)

			local item = script:WaitForChild("Layout"):Clone()
			item.Name = username
			item.LayoutOrder = position
			item.PName.Text = username
			item.Value.Text = aberviate(value)
			item.Rank.Text = "#"..position
			item.Avatar.Image = Players:GetUserThumbnailAsync(userId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size420x420)
			
			local statue = alltimestatue:FindFirstChild(tostring(position))
			
			if statue then
				statue.Humanoid:ApplyDescription(Players:GetHumanoidDescriptionFromUserId(userId))
				statue.Title.PlayerName.Text = username
				
				statue.Title.Adornee = statue.Head
				
				local framecolor = boardsetting.RanksColor[position]
				
				if framecolor then
					item.BackgroundColor3 = framecolor
				else
					item.BackgroundColor3 = boardsetting.RanksColor.Default
				end
			end

			item.Parent = Frame.AllTimeBoard
		end)
	end
end

function UpdateMonthly()
	for _, player in pairs(Players:GetPlayers()) do
		local leaderstats = player:FindFirstChild("DonationData")

		if not leaderstats then
			warn("Couldn't find leaderstats!")
			break
		end

		local statsValue = leaderstats:FindFirstChild("MonthlyTotalDonation")

		if not statsValue then
			break
		end

		pcall(function()
			MonthlyDonationLeaderboard:UpdateAsync(player.UserId, function()
				return tonumber(statsValue.Value)
			end)
		end)
	end

	for _,v in pairs(Frame.MonthlyBoard:GetChildren()) do
		if v:IsA("Frame") then
			v:Destroy()
		end
	end

	local data = MonthlyDonationLeaderboard:GetSortedAsync(false, 100, 1, 10e15)
	MonthlyPage = data:GetCurrentPage()

	for position, v in ipairs(MonthlyPage) do
		task.spawn(function()
			local userId = v.key
			local value = v.value
			local username = "[Not Available]"

			local success, err = pcall(function()
				username = Players:GetNameFromUserIdAsync(userId)
			end)

			local item = script:WaitForChild("Layout"):Clone()
			item.Name = username
			item.LayoutOrder = position
			item.PName.Text = username
			item.Value.Text = aberviate(value)
			item.Rank.Text = "#"..position
			item.Avatar.Image = Players:GetUserThumbnailAsync(userId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size420x420)

			local statue = monthlystatue:FindFirstChild(tostring(position))

			if statue then
				statue.Humanoid:ApplyDescription(Players:GetHumanoidDescriptionFromUserId(userId))
				statue.Title.PlayerName.Text = username
				
				statue.Title.Adornee = statue.Head

				local framecolor = boardsetting.RanksColor[position]
				
				if framecolor then
					item.BackgroundColor3 = framecolor
				else
					item.BackgroundColor3 = boardsetting.RanksColor.Default
				end
			end

			item.Parent = Frame.MonthlyBoard
		end)
	end
end

Players.PlayerAdded:Connect(function(player)
	local Data = player:WaitForChild("DonationData")
	local LastDate = Data:WaitForChild("LastDate")
	local MonthlyTotalDonation = Data:WaitForChild("MonthlyTotalDonation")
	local CurrentDate = os.date("*t").month..os.date("*t").year
	
	if LastDate.Value ~= CurrentDate then
		MonthlyTotalDonation.Value = 0
	end
	
	LastDate.Value = CurrentDate
end)

while true do
	UpdateAllTime()
	UpdateMonthly()
	
	for i = 1,boardsetting.RefreshRate do
		script.Parent.DonationLeaderboard.SurfaceGui.Frame["Refresh Rate"].Text = "refreshing in "..(60-i).." seconds"
		task.wait(1)
	end
end