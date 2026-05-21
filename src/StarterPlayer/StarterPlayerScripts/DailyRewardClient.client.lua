--SERVICES
local RS = game:GetService("ReplicatedStorage")
local MS = game:GetService("MarketplaceService")
local TS = game:GetService("TweenService")
local Players = game:GetService("Players")

--REFERENCES
local Player = Players.LocalPlayer
local DailyRewardRem = RS:WaitForChild("Remotes"):WaitForChild("DailyRewardRem")

--MODULES
local NotifModule = require(RS:WaitForChild("Modules").NotifModule)

repeat task.wait(1) until Player:FindFirstChild("PlayerInfo") and Player.Character:FindFirstChild("ToolFolder")

-- [[ UI REFERENCES ]]
local PlayerGui = Player:WaitForChild("PlayerGui")
local HUD = PlayerGui:WaitForChild("HUD")
local DailyUI = HUD:WaitForChild("Daily") 
local DailyFrame = DailyUI:WaitForChild("DailyFrame") 
local ClaimButton = DailyUI:WaitForChild("ClaimAll") 
local CloseButton = DailyUI:WaitForChild("Close")

local CLAIM_ALL_PRODUCT_ID = 3571641377
local PlayerStats = Player.PlayerStats

local DailyRewardPopup = HUD:WaitForChild("DailyRewardPopup")

-- VARIABLES
local CanClaimToday = false

-- [[ HELPER: GET DAY FRAME ]]
local function GetDayFrame(DayNum)
	if DayNum == 7 then
		return DailyUI:FindFirstChild("Day7") 
	else
		return DailyFrame:FindFirstChild("Day" .. DayNum) 
	end
end

-- [[ UI UPDATE FUNCTION ]]
local function UpdateDailyUI(Streak, CanClaim)
	CanClaimToday = CanClaim

	for i = 1, 7 do
		local DayFrame = GetDayFrame(i)
		if not DayFrame then continue end

		local Checkmark = DayFrame:FindFirstChild("Checkmark")
		local DimScreen = i == 7 and DayFrame:FindFirstChild("DimScreen") or nil

		-- 1. PAST DAYS (Already Claimed)
		if i < Streak then
			if Checkmark then Checkmark.Visible = true end
			if DimScreen then DimScreen.Visible = true end

			-- 2. CURRENT DAY (Ready to claim or waiting)
		elseif i == Streak then
			if Checkmark then Checkmark.Visible = false end
			if DimScreen then DimScreen.Visible = false end

			local UIStroke = DayFrame:FindFirstChildWhichIsA("UIStroke")
			if CanClaim and UIStroke then
				TS:Create(UIStroke, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.2, Thickness = 4}):Play()
			elseif UIStroke then
				TS:Create(UIStroke, TweenInfo.new(0.5), {Transparency = 0, Thickness = 2}):Play()
			end

			-- 3. FUTURE DAYS (Locked)
		elseif i > Streak then
			if Checkmark then Checkmark.Visible = false end
			if DimScreen then DimScreen.Visible = false end
		end
	end

	-- [[ SMART BUTTON LOGIC ]]
	local ButtonText = ClaimButton:FindFirstChildWhichIsA("TextLabel")

	if CanClaimToday then
		-- State 1: Free Daily Claim is Ready
		ClaimButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Green
		if ButtonText then ButtonText.Text = "Claim Free Reward" end
	else
		-- State 2: Already claimed today, show the DevProduct Skip
		ClaimButton.BackgroundColor3 = Color3.fromRGB(255, 170, 0) -- Gold/Orange to show it costs Robux
		if ButtonText then ButtonText.Text = "Skip & Claim All" end
	end
end

-- Listen for Server Responses
-- Listen for Server Responses
DailyRewardRem.OnClientEvent:Connect(function(Action, Data)
	if Action == "UpdateUI" and Data then
		UpdateDailyUI(Data.Streak, Data.CanClaim)

		local FirstGameVal = PlayerStats:FindFirstChild("FirstGame")

		-- If they have a reward waiting AND it is NOT their first game...
		if Data.CanClaim == true and (FirstGameVal and FirstGameVal.Value == false) then
			DailyUI.Visible = true

			-- [[ 100% AUTOMATIC CLAIM FEATURE ]]
			task.spawn(function()
				task.wait(5) -- Wait the 5 seconds you requested

				-- If they haven't manually clicked the button yet, auto-claim it for them!
				if CanClaimToday then
					DailyRewardRem:FireServer("Claim")
				end
			end)
		else
			DailyUI.Visible = false 
		end

	elseif Action == "ClaimSuccess" then
		-- 'Data' is now the Streak number passed from the Server
		local ClaimedDay = Data 
		CanClaimToday = false

		NotifModule.Notify(Player, "Daily Reward Claimed!")
		DailyRewardRem:FireServer("RequestInfo")

		-- Hide the main daily menu immediately so it isn't in the way
		DailyUI.Visible = false

		-- [[ DOPAMINE ANIMATION SEQUENCE ]]
		-- 1. Tween the PopUp on screen with a flashy Elastic bounce
		DailyRewardPopup.Position = UDim2.new(0.5, 0, -0.5, 0) -- Start off screen (top)
		DailyRewardPopup.Visible = true

		local TweenIn = TS:Create(DailyRewardPopup, TweenInfo.new(0.8, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0.15, 0) -- Adjust '0.15' if you want it higher or lower on the screen
		}) 
		TweenIn:Play()

		-- 2. Find the exact Day and Explode the Lock
		task.delay(1, function() -- Wait for the menu to drop down first
			local DayFrame = DailyRewardPopup.ProgressBar.Progress.ScrollingFrame:FindFirstChild("Day" .. tostring(ClaimedDay))

			if DayFrame and DayFrame:FindFirstChild("Lock") then
				local Lock = DayFrame.Lock

				-- Setup Explode Tween (Grows massive, spins, and fades out)
				local ExplodeInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In)
				local ExplodeTween = TS:Create(Lock, ExplodeInfo, {
					Size = UDim2.new(Lock.Size.X.Scale * 2.5, 0, Lock.Size.Y.Scale * 2.5, 0), 
					ImageTransparency = 1,
					Rotation = 45
				})

				ExplodeTween:Play()
				local ITemNotifSound = RS:WaitForChild("Assets").SFX.ItemNotifSound:Play()
			end
		end)

		-- 3. Wait 7 seconds, then hide the popup automatically
		task.delay(10, function()
			local TweenOut = TS:Create(DailyRewardPopup, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, 0, -0.5, 0)
			})
			TweenOut:Play()

			TweenOut.Completed:Once(function()
				DailyRewardPopup.Visible = false
			end)
		end)
	elseif Action == "ClaimAllSuccess" then
		-- DEV PRODUCT PURCHASE SUCCESS!
		CanClaimToday = false

		-- Visually check off ALL days instantly for maximum satisfaction
		for i = 1, 7 do
			local DayFrame = GetDayFrame(i)
			if DayFrame then
				if DayFrame:FindFirstChild("Checkmark") then DayFrame.Checkmark.Visible = true end
				if DayFrame:FindFirstChild("DimScreen") then DayFrame.DimScreen.Visible = true end
			end
		end

		-- Fire Notifications
		task.spawn(function()
			if Data and Data.Rewards then
				for _, rewardName in ipairs(Data.Rewards) do
					NotifModule.Notify(Player, "You've been rewarded: " .. rewardName .. "!")
					task.wait(0.2) 
				end
			end	
		end)

		-- Wait 3 seconds so they can see all the checkmarks, then close the UI and refresh data
		task.delay(3, function()
			local Tween = TS:Create(DailyUI, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.fromScale(1.5, 0.5)})
			Tween:Play()
			Tween.Completed:Once(function()
				DailyUI.Visible = false
				DailyUI.Position = UDim2.fromScale(0.5, 0.5)
				DailyRewardRem:FireServer("RequestInfo") -- Resets UI back to Day 1 visually
			end)
		end)
	end
end)

-- Claim Button Click (Smart Detection)
ClaimButton.MouseButton1Click:Connect(function()
	-- Button bounce animation
	local UIScale = ClaimButton:FindFirstChild("UIScale") or Instance.new("UIScale", ClaimButton)
	TS:Create(UIScale, TweenInfo.new(0.1, Enum.EasingStyle.Bounce), {Scale = 0.9}):Play()
	task.delay(0.1, function()
		TS:Create(UIScale, TweenInfo.new(0.1, Enum.EasingStyle.Bounce), {Scale = 1}):Play()
	end)

	if CanClaimToday then
		-- They have a free reward pending, let them claim it normally!
		DailyRewardRem:FireServer("Claim")
	else
		-- They don't have a free reward, prompt the DevProduct to skip the wait!
		MS:PromptProductPurchase(Player, CLAIM_ALL_PRODUCT_ID)
	end
end)

CloseButton.MouseButton1Click:Connect(function()
	local Tween = TS:Create(CloseButton.Parent, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.fromScale(1.5, 0.5)})
	Tween:Play()
	Tween.Completed:Once(function()
		CloseButton.Parent.Visible = false
		CloseButton.Parent.Position = UDim2.fromScale(0.5, 0.5) 
	end)
end)

-- [[ INITIALIZATION ]]
task.delay(2, function()
	DailyRewardRem:FireServer("RequestInfo")
end)