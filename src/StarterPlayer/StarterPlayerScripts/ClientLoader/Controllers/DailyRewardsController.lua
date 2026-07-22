local DailyRewardsController = {}

function DailyRewardsController.Init()
	--//Services
	local Players = game:GetService("Players")
	local Ts = game:GetService("TweenService")
	local Rs = game:GetService("ReplicatedStorage")
	local SoundService = game:GetService("SoundService")
	local MarketplaceService = game:GetService("MarketplaceService")
	
	--//Player
	local plr = Players.LocalPlayer
	local plrGui = plr.PlayerGui
	
	--//Wait for data loads
	local DataLoaded = plr:WaitForChild("DataLoaded")
	
	--//Modules
	local ModulesFolder = Rs:WaitForChild("Modules")
	local SoundPlayer = require(ModulesFolder.Utils:FindFirstChild("SoundPlayer"))
	local DailyRewards = require(ModulesFolder.Configs:FindFirstChild("DailyRewards"))
	local ShopModule = require(ModulesFolder.ShopModule)
	local DataHandler = require(ModulesFolder.DataHandler)
	local FormatString = require(ModulesFolder.Utils.FormatString)
	
	--//Remotes
	local Remotes = Rs:WaitForChild("Remotes")
	local ClaimDailyReward = Remotes:WaitForChild("ClaimDailyReward")
	
	--//UI
	local MenuGui = plrGui:WaitForChild("MenuGui")
	local DailyRewardFrame = MenuGui:FindFirstChild("InGameFrame"):FindFirstChild("DailyRewardsFrame")
	local ClaimButton = DailyRewardFrame:FindFirstChild("ClaimButton")
	local ClaimAllButton = DailyRewardFrame:FindFirstChild("ClaimAllButton")
	
	local profileData = DataHandler:GetProfileData(plr)
	
	local function updateRewardsUI()
		if not profileData then return end
		
		local function updateRewardFrame(rewardInfo: {}, dayNum: number)
			for rewardName, reward in pairs(rewardInfo) do
				local rewardFrame = DailyRewardFrame.listFrame:FindFirstChild("RewardFrame_"..dayNum)
				if not rewardFrame then
					warn("Can't find daily reward for day: ", dayNum)
					continue
				end
				
				if rewardName == "Coins" then
					rewardFrame.rewardIcon.Image = DailyRewards.Coins.Img
					rewardFrame.rewardName.Text = "+" .. reward .. " Coins"
				elseif rewardName == "Titles" then
					local titleObj = ShopModule:GetTitle(reward) :: TextLabel?
					if titleObj then
						titleObj = titleObj.TextStyle:Clone()
					end
					
					rewardFrame.rewardIcon.Visible = false
					rewardFrame.rewardName.Text = "New Title!"
					rewardFrame.rewardName.TextColor3 = Color3.fromRGB(25, 186, 255)
					
					titleObj.Size = rewardFrame.rewardIcon.Size
					titleObj.Position = rewardFrame.rewardIcon.Position
					titleObj.AnchorPoint = rewardFrame.rewardIcon.AnchorPoint
					titleObj.Visible = true
					titleObj.ZIndex = 0
					titleObj.Parent = rewardFrame
				elseif rewardName == "Perk" then
					local perk = ShopModule:GetPerk(reward)
					if perk then
						rewardFrame.rewardIcon.Image = perk.Img
						rewardFrame.rewardName.Text = perk.Name
					end
					rewardFrame.rewardName.TextColor3 = Color3.fromRGB(255, 255, 255)
				elseif rewardName == "Character" then
					rewardFrame.rewardIcon.Image = DailyRewards.Character[reward]
					rewardFrame.rewardName.Text = "New Character! [" .. reward .. "]"
					rewardFrame.rewardName.TextColor3 = Color3.fromRGB(255, 0, 251)
				end
				
				if profileData then
					local CurrentDay = profileData.CurrentDay
					if CurrentDay > dayNum or (CurrentDay == dayNum and profileData.ClaimedDailyReward) then --// already claimed
						rewardFrame.LockedFrame.Visible = false
						rewardFrame.ClaimText.Visible = true
						rewardFrame.ClaimText.Text = "Claimed."
						rewardFrame.ClaimText.TextColor3 = Color3.fromRGB(8, 177, 255)
					elseif CurrentDay == dayNum then --// can claim reward
						rewardFrame.LockedFrame.Visible = false
						rewardFrame.ClaimText.Visible = true
					else --// can't claim yet
						rewardFrame.LockedFrame.Visible = true
					end
				end
			end
		end
		
		if profileData.RewardType <= 1 then
			for dayNum, rewardInfo in pairs(DailyRewards.Rewards_1) do
				updateRewardFrame(rewardInfo, dayNum)
			end
		else
			for dayNum, rewardInfo in pairs(DailyRewards.Rewards_2) do
				updateRewardFrame(rewardInfo, dayNum)
			end
		end
		
		if profileData.CurrentDay >= 7 and profileData.ClaimedDailyReward then
			ClaimAllButton.Visible = false
		end
	end
	
	--[[
		TODO:
		- check player data to get the current day and already claimed rewards | DONE
		- if current day == 8 and already claimed day 7 reward, change the daily reward to type 2 and restart the timer
		- if player can claim reward, make the ClaimText of the reward frame visible | DONE
		- claim all rewards purchase button (24h delay time to reset the daily rewards)
	]]
	
	updateRewardsUI()
	
	local OtherValues = plr:WaitForChild("OtherValues")
	local RewardTime = OtherValues and OtherValues:WaitForChild("RewardTime") :: IntValue
	local dayTime = 24 * 60 * 60 -- 24 hours in seconds
	
	local function updateRewardTime()
		local newValue = RewardTime.Value
		if not profileData.ClaimedDailyReward then
			ClaimButton.TitleTX.Text = "Claim"
		else
			local timeRemain = math.max(0, dayTime - newValue)
			local hours = math.floor(timeRemain / 3600)
			local minutes = math.floor((timeRemain % 3600) / 60)
			local seconds = timeRemain % 60
			ClaimButton.TitleTX.Text = string.format("Next: %02dh %02dm %02ds", hours, minutes, seconds)
		end
	end
	
	if RewardTime then
		RewardTime:GetPropertyChangedSignal("Value"):Connect(function()
			updateRewardTime()
		end)
	end
	
	local function updateAllUI()
		SoundPlayer:PlaySound(SoundService.Effects.PurchaseSound)
		profileData = DataHandler:GetProfileData(plr)
		
		if profileData then
			for i = 1, profileData.CurrentDay do
				local rewardFrame = DailyRewardFrame.listFrame:FindFirstChild("RewardFrame_"..tostring(i))
				if rewardFrame then
					rewardFrame.LockedFrame.Visible = false
					rewardFrame.ClaimText.Visible = true
					rewardFrame.ClaimText.Text = "Claimed."
					rewardFrame.ClaimText.TextColor3 = Color3.fromRGB(8, 177, 255)
				end
			end
			
			if RewardTime then
				updateRewardTime()
			end
		end
	end
	
	ClaimButton.MouseButton1Click:Connect(function()
		local claimed = ClaimDailyReward:InvokeServer(profileData.CurrentDay)
		if claimed then
			updateAllUI()
		end
	end)
	
	ClaimAllButton.MouseButton1Click:Connect(function()
		local profileData = DataHandler:GetProfileData(plr)
		if not profileData then return end
		
		if profileData.CurrentDay >= 7 and profileData.ClaimedDailyReward then return end
		MarketplaceService:PromptProductPurchase(plr, 3441545085)
	end)
	
	ClaimDailyReward.OnClientInvoke = function(action: string)
		if action == "Update" then
			ClaimAllButton.Visible = false -- player already purchased the claim all product
			updateAllUI()
		end
	end
end

return DailyRewardsController