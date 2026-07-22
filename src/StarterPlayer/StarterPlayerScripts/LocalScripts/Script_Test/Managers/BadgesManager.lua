local BadgesManager = {}

function BadgesManager.Init()
	--//Services
	local Rs = game:GetService("ReplicatedStorage")
	local BadgeService = game:GetService("BadgeService")
	
	--//Remotes
	local Remotes = Rs:WaitForChild("Remotes")
	local ClaimBadgeEvent = Remotes:WaitForChild("ClaimBadge")
	
	--//Modules
	local ModulesFolder = Rs:WaitForChild("Modules")
	local BadgesModule = require(ModulesFolder:FindFirstChild("Badges"))
	
	--//Player
	local Plr = game.Players.LocalPlayer
	local plrAwardedBadges = Plr:WaitForChild("OtherValues"):WaitForChild("AwardedBadges")
	
	--//UI
	local InGameFrame = Plr.PlayerGui:WaitForChild("MenuGui"):WaitForChild("InGameFrame")
	local BadgesButton = InGameFrame:WaitForChild("ButtonsFrame"):WaitForChild("BadgesButton")
	local BadgesMainFrame = InGameFrame:WaitForChild("BadgesFrame")
	local BadgesList = BadgesMainFrame:WaitForChild("BadgesList"):WaitForChild("ListFrame")
	local BADGE_EXAMPLE = BadgesList:FindFirstChild("Badge_Example")
	
	--//Values
	local updateDebounce = false
	
	--//Setup
	BADGE_EXAMPLE.Parent = Rs
	
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
	
	local function createBadgeUI(info: { [string]: any }, badgeId, difficulty: string, order: number?)
		if not info then return warn("No badge info received.") end
		
		local badgeName = info.DisplayName -- 'DisplayName' and not 'Name' because it's translated.
		local badgeDesc = info.DisplayDescription
		local badgeIcon = info.IconImageId
		local badgeActive = info.IsEnabled
		
		if not badgeActive then print("Badge: "..info.Name.. ` ({badgeId}) is not active.`) return end
		
		local newBadgeFrame = BADGE_EXAMPLE:Clone()
		newBadgeFrame.Name = info.Name
		newBadgeFrame.Parent = BadgesList
		newBadgeFrame.TitleText.Text = badgeName
		newBadgeFrame.DescText.Text = badgeDesc
		newBadgeFrame.Badge_Icon.Image = "rbxassetid://"..badgeIcon
		newBadgeFrame.LayoutOrder = order or 5
		newBadgeFrame.ID.Value = badgeId
		newBadgeFrame.UIStroke.Color = BadgesModule.DiffColors[difficulty].MainColor
		
		--print("Created Badge: ", info.Name, "| Difficulty: ", difficulty)
	end
	
	local function updateBadgesList()
		for _, badgeFrame in BadgesList:GetChildren() do
			if badgeFrame:IsA("Frame") then
				if plrAwardedBadges:FindFirstChild(badgeFrame.ID.Value) then
					badgeFrame.LockedFrame.Visible = false
					if plrAwardedBadges:FindFirstChild(badgeFrame.ID.Value).Value then
						badgeFrame.ClaimButton.Text = "Already Claimed"
						badgeFrame.ClaimButton.BackgroundColor3 = Color3.fromRGB(194, 194, 194)
						badgeFrame.ClaimButton.UIStroke.Color = Color3.fromRGB(118, 118, 118)
					end
					
					local rewards = true
					
					for _, diff in pairs(BadgesModule.Badges) do
						for _, badge in ipairs(diff) do
							if tonumber(badgeFrame.ID.Value) == badge.Id then
								if #badge.Reward <= 0 then
									rewards = false
								end
								break
							end
						end
					end
					
					--//If badge has no rewards, claimed value is automatically changed to true
					if not rewards then
						ClaimBadgeEvent:FireServer(badgeFrame.ID.Value, "Claim")
						badgeFrame.ClaimButton.Visible = false
					end
				end
			end
		end
	end
	
	local function connectClaimButtonsFunct()
		for _, badgeFrame in BadgesList:GetChildren() do
			if badgeFrame:IsA("Frame") and not badgeFrame:HasTag("connectedBadgeButton") then
				local ClaimButton = badgeFrame.ClaimButton :: TextButton
				local BadgeID = badgeFrame.ID.Value
				
				if not ClaimButton.Visible then continue end -- Already claimed
				
				ClaimButton.MouseButton1Click:Connect(function()
					ClaimBadgeEvent:FireServer(BadgeID, "Claim")
					updateBadgesList()
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
		updateBadgesList()
		connectClaimButtonsFunct()
	end
	
	BadgesButton.MouseButton1Click:Connect(function()
		if updateDebounce then return end
		updateDebounce = true
		setupBadges()
		
		task.delay(1, function()
			updateDebounce = false
		end)
	end)
	
	setupBadges()
end

return BadgesManager