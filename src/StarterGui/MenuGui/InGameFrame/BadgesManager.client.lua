--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")
local BadgeService = game:GetService("BadgeService")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local ClaimBadgeEvent = Remotes:WaitForChild("ClaimBadge", 30) :: RemoteFunction
local CheckForBadge = Remotes:WaitForChild("CheckForBadge", 30) :: RemoteFunction
local RewardWarnEvent = Remotes:WaitForChild("RewardWarnEvent", 30)

--//Modules
local ModulesFolder = Rs:WaitForChild("Modules")
local BadgesModule = require(ModulesFolder:FindFirstChild("Badges"))

--//Player
local Plr = game.Players.LocalPlayer

--//UI
local InGameFrame = Plr.PlayerGui:WaitForChild("MenuGui"):WaitForChild("InGameFrame")
local BadgesButton = InGameFrame:WaitForChild("ButtonsFrame"):WaitForChild("BadgesButton")
local BadgesMainFrame = InGameFrame:WaitForChild("BadgesFrame")
local BadgesList = BadgesMainFrame:WaitForChild("BadgesList"):WaitForChild("ListFrame")
local BADGE_EXAMPLE = BadgesList:FindFirstChild("Badge_Example")
local InfoFrame = BadgesMainFrame:FindFirstChild("InfoFrame")
local InfoButton = BadgesMainFrame:FindFirstChild("InfoButton")
local INFOFRAME_EXAMPLE = InfoFrame:FindFirstChild("InfoListFrame"):FindFirstChild("ExampleInfo_Frame")
local COINEARNFRAME_EXAMPLE = InGameFrame:FindFirstChild("SpawnCoinsFrame"):FindFirstChild("CoinsEarnExample_Frame")
local CoinsFrame = InGameFrame:FindFirstChild("CoinsFrame")

--//Sounds
local SoundsFolder = script.Parent:FindFirstChild("Sounds")
local ClickSound = SoundsFolder:FindFirstChild("ClickSound")

--//Values
local updateDebounce = false
local plrCurrentCoins = Plr:WaitForChild("leaderstats", 30):WaitForChild("Coins", 30)

--//Setup
INFOFRAME_EXAMPLE.Parent = Rs
BADGE_EXAMPLE.Parent = Rs
COINEARNFRAME_EXAMPLE.Parent = Rs
if plrCurrentCoins then
	CoinsFrame.coins_amount.Text = "$"..tostring(plrCurrentCoins.Value)
end

--//Get the badge info by Id
local function GetBadgeInfo(badgeId: number)
	local success, result = pcall(function()
		return BadgeService:GetBadgeInfoAsync(badgeId)
	end)
	
	if success then
		return result
	else
		warn("Can't get data of the badge:", badgeId, "|", result)
		return nil
	end
end

local function animEarnCoin(amount: number)
	local mult = amount or 10
	local defaultSize = COINEARNFRAME_EXAMPLE.Size
	local first = true
	local plrCoins = Plr:WaitForChild("leaderstats"):WaitForChild("Coins")
	local hidingFrame = false
	
	--//Show coins frame
	Ts:Create(CoinsFrame, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(0.021, 0.93)}):Play()
	
	local function playCoinSnd(type2: boolean)
		local randomCoinSnd = math.random(800, 1200)/1000
		local snd
		if type2 then
			snd = SoundsFolder:FindFirstChild("CoinSound2"):Clone()
		else
			snd = SoundsFolder:FindFirstChild("CoinSound"):Clone()
		end
		snd.Parent = InGameFrame
		snd.PlaybackSpeed = randomCoinSnd
		snd:Play()
		game.Debris:AddItem(snd, snd.TimeLength + 1)
	end
	
	local function animCoin(text: boolean)
		local coinFrame = COINEARNFRAME_EXAMPLE:Clone()
		local randomStartPos = UDim2.fromScale(math.random(0, 100)/100, math.random(0, 100)/100)
		coinFrame.Parent = InGameFrame:FindFirstChild("SpawnCoinsFrame")
		coinFrame.Position = randomStartPos
		coinFrame.Visible = true
		coinFrame.Size = UDim2.fromScale(0, 0)
		coinFrame.ZIndex = -10
		
		if text then
			coinFrame.TextLabel.Text = "+"..amount
		else
			coinFrame.TextLabel.Visible = false
		end
		
		Ts:Create(coinFrame, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {Size = defaultSize}):Play()
		game.Debris:AddItem(coinFrame, 5)
		
		playCoinSnd()
		
		task.delay(0.4, function()
			local OffsetX = math.random(-10, 10)/100
			local OffsetY = math.random(-10, 10)/100
			local finalPos = UDim2.fromScale(-0.881 + OffsetX, 1.362 + OffsetY)
			local tween = Ts:Create(coinFrame, TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {Position = finalPos})
			tween:Play()
			
			tween.Completed:Connect(function()
				Ts:Create(coinFrame, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.fromScale(0, 0)}):Play()
				task.wait(0.1)
				
				local defaultSize = UDim2.fromScale(0.176, 0.049)
				local newSize = UDim2.fromScale(CoinsFrame.Size.X.Scale * 1.18, CoinsFrame.Size.Y.Scale * 1.15)
				local newSizeTween = Ts:Create(CoinsFrame, TweenInfo.new(0.1, Enum.EasingStyle.Back), {Size = newSize})
				newSizeTween:Play()
				
				newSizeTween.Completed:Connect(function()
					Ts:Create(CoinsFrame, TweenInfo.new(0.15, Enum.EasingStyle.Back), {Size = defaultSize}):Play()
				end)
				
				coinFrame.Visible = false
				playCoinSnd(true)
			end)
		end)
	end
	
	for i=1, 3 do
		if first then
			first = false
			animCoin(true)
		else
			animCoin()
		end
		task.wait(math.random(60, 120)/1000)
	end
	
	task.delay(1.2, function()
		if plrCoins then
			local currentCoins = tonumber(string.match(CoinsFrame.coins_amount.Text, "%d+"))
			local currentValue = currentCoins
			local addedCoins = 0
			
			while addedCoins < (plrCoins.Value - currentCoins) or not hidingFrame do
				task.wait(0.01)
				addedCoins += 1
				currentValue = currentCoins + addedCoins
				CoinsFrame.coins_amount.Text = "$"..currentValue
			end
			
			CoinsFrame.coins_amount.Text = "$"..tostring(plrCoins.Value)
		end
	end)
	
	for i=1, 50 do
		local num = math.random()
		local chance = amount/100
		if num <= chance then
			animCoin()
			task.wait(math.random(20, 80)/1000)
		end
	end
	
	task.wait(2)
	
	--//Hide Coins Frame
	hidingFrame = true
	Ts:Create(CoinsFrame, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), {Position = UDim2.fromScale(-0.3, 0.942)}):Play()
end

--//Coins animation when player redeem a code
RewardWarnEvent.OnClientEvent:Connect(function(reward, amount)
	if reward == "Coins" then
		animEarnCoin(amount)
	end
end)

local function createBadgeUI(info: { [string]: any }, badgeId, difficulty: string, order: number?)
	if not info then return warn("No badge info received.") end
	
	local badgeName = info.DisplayName -- 'DisplayName' and not 'Name' because it's translated.
	local badgeDesc = info.DisplayDescription
	local badgeIcon = info.IconImageId
	local badgeActive = info.IsEnabled
	
	if not badgeActive then print("Badge: "..info.Name.. ` ({badgeId}) is not active.`) return end
	
	local prevDiffOrder = BadgesModule.Badges[difficulty].Order - 1
	local prevDiff = nil
	local lastPrevDiff = nil
	local prevDiffLastBadgeOrder = 0
	local orderChanged = false
	
	for _, diff in pairs(BadgesModule.Badges) do
		if diff.Order == prevDiffOrder then
			prevDiff = diff.Name
			break
		end
	end
	
	while prevDiff and lastPrevDiff ~= prevDiff do
		prevDiffLastBadgeOrder = 0
		lastPrevDiff = prevDiff
		
		if prevDiff and prevDiff ~= difficulty then
			for _, badge in ipairs(BadgesModule.Badges[prevDiff]) do
				if badge.Order > prevDiffLastBadgeOrder then
					prevDiffLastBadgeOrder = badge.Order
				end
			end
		end
		
		order = order > 0 and prevDiffLastBadgeOrder + order or prevDiffLastBadgeOrder + 1
		prevDiffOrder = BadgesModule.Badges[prevDiff].Order - 1
		
		for _, diff in pairs(BadgesModule.Badges) do
			if diff.Order == prevDiffOrder then
				prevDiff = diff.Name
				break
			end
		end
		
		orderChanged = true
	end
	
	if not orderChanged then
		order = order > 0 and prevDiffLastBadgeOrder + order or prevDiffLastBadgeOrder + 1
	end
	
	local newBadgeFrame = BADGE_EXAMPLE:Clone()
	newBadgeFrame.Name = info.Name
	newBadgeFrame.Parent = BadgesList
	newBadgeFrame.TitleText.Text = badgeName
	newBadgeFrame.DescText.Text = badgeDesc
	newBadgeFrame.Badge_Icon.Image = "rbxassetid://"..badgeIcon
	newBadgeFrame.LayoutOrder = order or 0
	newBadgeFrame.ID.Value = badgeId
	newBadgeFrame.UIStroke.Color = BadgesModule.DiffColors[difficulty].MainColor
	
	--print("Created Badge: ", info.Name, "| Difficulty: ", difficulty, "| Order: ", order)
end

local function updateBadgeClaimButton(button)
	if not button then return end
	button.Text = "Already Claimed"
	button.BackgroundColor3 = Color3.fromRGB(100, 111, 129)
	button.UIStroke.Color = Color3.fromRGB(66, 68, 94)
end

local function updateBadgesList()
	for _, badgeFrame in BadgesList:GetChildren() do
		if badgeFrame:IsA("Frame") then
			local plrAwardedBadges = Plr:WaitForChild("OtherValues"):WaitForChild("AwardedBadges")
			local badgeID = badgeFrame.ID.Value
			local plrHasBadge = CheckForBadge:InvokeServer(tonumber(badgeID)) :: boolean
			
			game:GetService("RunService").RenderStepped:Wait()
			
			if plrHasBadge then
				if plrAwardedBadges:FindFirstChild(badgeID) then
					if plrAwardedBadges:FindFirstChild(badgeID).Value then
						updateBadgeClaimButton(badgeFrame.ClaimButton)
					end
				end
				
				local rewards = false
				local foundBadge = false
				badgeFrame.LockedFrame.Visible = false
				
				--//Check if the badge has any rewards
				for _, diff in pairs(BadgesModule.Badges) do
					if foundBadge then break end
					for _, badge in ipairs(diff) do
						if typeof(badge) ~= "table" then continue end
						if tonumber(badgeFrame.ID.Value) == badge.Id then
							local rewardTable = badge.Reward
							foundBadge = true
							
							if typeof(rewardTable) == "table" and next(rewardTable) ~= nil then
								rewards = true
							else
								rewards = false
							end
							
							break
						end
					end
				end
				
				--//If badge has no rewards, ClaimedValue is automatically changed to true
				if rewards then
					badgeFrame.ClaimButton.Visible = true
				else
					ClaimBadgeEvent:InvokeServer(badgeFrame.ID.Value, "Claim")
					badgeFrame.ClaimButton.Visible = false
				end
			else
				badgeFrame.ClaimButton.Visible = false
			end
		end
	end
end

local function connectClaimButtonsFunct()
	for _, badgeFrame in BadgesList:GetChildren() do
		if badgeFrame:IsA("Frame") and not badgeFrame:HasTag("connectedBadgeButton") then
			local plrAwardedBadges = Plr:WaitForChild("OtherValues"):WaitForChild("AwardedBadges")
			local ClaimButton = badgeFrame.ClaimButton :: TextButton
			local BadgeID = badgeFrame.ID.Value
			local isClaimed = false
			
			if plrAwardedBadges:FindFirstChild(BadgeID) then
				if plrAwardedBadges:FindFirstChild(BadgeID).Value then
					isClaimed = true
				end
			end
			
			if not ClaimButton.Visible then isClaimed = true continue end -- Already claimed
			
			ClaimButton.MouseButton1Click:Connect(function()
				if isClaimed then return end
				
				if plrAwardedBadges:FindFirstChild(BadgeID) then
					if plrAwardedBadges:FindFirstChild(BadgeID).Value then
						isClaimed = true
						return -- Already take badge reward
					end
				end
				
				local claimed, rewardTypes, rewardAmounts = ClaimBadgeEvent:InvokeServer(BadgeID, "Claim")
				local coinsReward = false
				local characterReward = false
				
				if claimed then
					isClaimed = true
					updateBadgeClaimButton(ClaimButton)
					if rewardTypes then
						for i, v in pairs(rewardTypes) do
							if i == "Coins" then
								coinsReward = true
							elseif i == "Character" then
								characterReward = true
							end
						end
					end
					if coinsReward then
						animEarnCoin(rewardAmounts.Coins)
					end
					if characterReward then
						--TODO: earn character reward
					end
				end
				--updateBadgesList()
			end)
			badgeFrame:AddTag("connectedBadgeButton")
		end
	end
end

local function clearBadgesUI()
	for i, v in BadgesList:GetChildren() do
		if v:IsA("Frame") then
			v:Destroy()
		end
	end
end

local function setupBadges()
	clearBadgesUI()
	
	local done = false
	task.spawn(function()
		BadgesMainFrame.LoadFrame.Visible = true
		for _, diff in pairs(BadgesModule.Badges) do
			if typeof(diff) ~= "table" then continue end
			for _, badge in ipairs(diff) do
				if not badge.Enabled then print("Badge: ", badge.Id, "are disabled.") continue end
				
				local badgeInfo = GetBadgeInfo(badge.Id)
				if badgeInfo then
					createBadgeUI(badgeInfo, badge.Id, diff.Name, badge.Order)
				end
			end
		end
		done = true
	end)
	
	repeat task.wait()
	until done
	
	updateBadgesList()
	connectClaimButtonsFunct()
	BadgesMainFrame.LoadFrame.Visible = false
end

local function setupInfoFrame()
	for _, diff in pairs(BadgesModule.Badges) do
		if typeof(diff) ~= "table" then continue end
		local diffName = diff.Name :: string
		local diffMainColor = BadgesModule.DiffColors[diffName].MainColor :: Color3
		local diffSecColor = BadgesModule.DiffColors[diffName].SecondaryColor :: Color3
		local diffOrder = diff.Order
		
		local newInfoFrame = INFOFRAME_EXAMPLE:Clone()
		newInfoFrame.Parent = InfoFrame:FindFirstChild("InfoListFrame")
		newInfoFrame.Visible = true
		newInfoFrame.InfoText.Text = diffName.." Badges"
		newInfoFrame.ColorFrame.BackgroundColor3 = diffMainColor
		newInfoFrame.ColorFrame.UIStroke.Color = diffSecColor
		newInfoFrame.LayoutOrder = diffOrder
	end
end

InfoButton.MouseButton1Click:Connect(function()
	ClickSound:Play()
	InfoFrame.Visible = not InfoFrame.Visible
end)

BadgesButton.MouseButton1Click:Connect(function()
	if updateDebounce then return end
	updateDebounce = true
	updateBadgesList()
	
	task.delay(5, function()
		updateDebounce = false
	end)
end)

setupBadges()
setupInfoFrame()