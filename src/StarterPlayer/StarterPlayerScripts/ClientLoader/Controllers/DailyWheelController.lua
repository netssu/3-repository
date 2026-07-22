local dailyWheelManager = {}

function dailyWheelManager.Init()
	--//Services
	local Ts = game:GetService("TweenService")
	local Rs = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local SoundService = game:GetService("SoundService")
	local MarketplaceService = game:GetService("MarketplaceService")
	
	--//Player
	local Player = game.Players.LocalPlayer
	local Camera = workspace.CurrentCamera
	local playerGui = Player.PlayerGui
	
	--//Remotes
	local Remotes = Rs:WaitForChild("Remotes")
	local CheckDailyRewardFunc = Remotes:WaitForChild("CheckDailyReward")
	local SpinPurchase = Remotes:WaitForChild("SpinPurchase")
	--local UpdatePerkFunc = Remotes:WaitForChild("UpdatePerk")
	
	--//Modules
	local ModulesFolder = Rs:WaitForChild("Modules")
	local ShopModule = require(ModulesFolder:WaitForChild("ShopModule"))
	local DataHandler = require(ModulesFolder:WaitForChild("DataHandler"))
	local wheelRewards = require(script.WheelRewards)
	
	--//UI
	local DailyWheelGui = playerGui:WaitForChild("DailyWheelGui")
	local MainFrame = DailyWheelGui:FindFirstChild("MainFrame")
	local RewardFrame = MainFrame:FindFirstChild("RewardFrame")
	local ConfirmButton = RewardFrame:FindFirstChild("ConfirmButton")
	local ClaimButton = MainFrame:FindFirstChild("ClaimButton")
	local CloseButton = MainFrame:FindFirstChild("CloseButton")
	local SpinBuyButton = MainFrame:FindFirstChild("SpinBuyButton")
	
	--//Wheel Stuff
	local Map = workspace:WaitForChild("Map")
	local InteractStuff = Map and Map:WaitForChild("InteractStuff")
	local DailyWheelModel = InteractStuff and InteractStuff:WaitForChild("Daily_Wheel")
	local RotateWheelParts = DailyWheelModel and DailyWheelModel:WaitForChild("RotateWheel")
	local rotateMainPart = RotateWheelParts and RotateWheelParts:WaitForChild("BasePart")
	local prox = DailyWheelModel and DailyWheelModel:WaitForChild("InteractPart"):FindFirstChild("ProximityPrompt")
	local camPart = DailyWheelModel:WaitForChild("CamPart")
	local DetectPart1 = DailyWheelModel:WaitForChild("Detection1")
	local DetectPart2 = DailyWheelModel:WaitForChild("Detection2")
	
	--//Values
	local onInspect = false
	local ignoreGuis = {}
	local rotatingConnection: RBXScriptConnection = nil
	
	SpinBuyButton.MouseButton1Click:Connect(function()
		MarketplaceService:PromptProductPurchase(Player, 3491931922)
	end)
	
	local function changeGuis(state: boolean)
		for _, v in playerGui:GetChildren() do
			if v:IsA("ScreenGui") and not table.find(ignoreGuis, v) then
				if ignoreGuis[v] or (not state and not v.Enabled) or v == DailyWheelGui then
					ignoreGuis[v] = true
					continue
				end
				v.Enabled = state
			end
		end
	end
	
	local function joinToWheel(state: boolean)
		if state then
			MainFrame.Visible = true
			prox.Enabled = false
			changeGuis(false)
			onInspect = true
			Camera.CameraType = Enum.CameraType.Scriptable
			Ts:Create(Camera, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {CFrame = camPart.CFrame}):Play()
		else
			prox.Enabled = true
			Camera.CameraType = Enum.CameraType.Custom
			onInspect = false
			MainFrame.Visible = false
			changeGuis(true)
		end
	end
	
	local defaultRewardFrameSize = RewardFrame.Size
	
	local function changeRewardFrame(state: boolean, reward: {})
		if state then -- show
			local rewardName = reward.Name
			local rewardImg = reward.Img
			local rewardType = nil
			
			local RewardText = RewardFrame.RewardText
			local RewardImage = RewardFrame.RewardImage
			local textClone = nil :: TextLabel
			
			RewardImage.Image = rewardImg
			RewardText.Text = rewardName
			
			for rewardType, rewardValue in reward.Rewards do
				if rewardType == "Coins" then
					RewardText.Text = "+"..rewardValue
					RewardText.Visible = true
				elseif rewardType == "Titles" then
					local titleStyle = ShopModule:GetTitle(rewardValue)
					local titleText = titleStyle and titleStyle.TextStyle
					textClone = titleText:Clone()
					textClone.Visible = true
					textClone.Size = RewardText.Size
					textClone.LayoutOrder = RewardText.LayoutOrder
					textClone.Position = RewardText.Position
					textClone.Parent = RewardText.Parent
					textClone.TextXAlignment = Enum.TextXAlignment.Left
					
					RewardText.Text = "Title"
					RewardText.Visible = false
				end
			end
			
			SoundService.Effects.ClickSound:Play()
			RewardFrame.Size = UDim2.new(0, 0, 0, 0)
			RewardFrame.Visible = true
			Ts:Create(RewardFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Size = defaultRewardFrameSize}):Play()
			
			ConfirmButton.MouseButton1Click:Wait()
			SoundService.Effects.ClickSound:Play()
			if textClone then
				textClone:Destroy()
			end
			
			joinToWheel(false)
			changeRewardFrame(false)
		else -- unshow
			local tween = Ts:Create(RewardFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.fromScale(0, 0)})
			tween:Play()
			tween.Completed:Wait()
			RewardFrame.Visible = false
			ClaimButton.Visible = true
			SpinBuyButton.Visible = true
			CloseButton.Visible = true
			MainFrame.TimeText.Visible = true
		end
	end
	
	local function setupWheelUI()
		for i, v in wheelRewards do
			local partToGo = DailyWheelModel:FindFirstChild("RotateWheel"):FindFirstChild("Reward"..tostring(i))
			if partToGo then
				local gui = partToGo:FindFirstChild("SurfaceGui")
				if gui then
					local mainFrame = gui:FindFirstChild("MainFrame")
					local RewardIcon = mainFrame:FindFirstChild("RewardIcon") :: ImageLabel
					local RewardText = mainFrame:FindFirstChild("RewardText") :: TextLabel
					RewardText.Text = v.Name
					RewardIcon.Image = v.Img
					
					local rewardType = nil
					for rewardType, rewardValue in v.Rewards do
						if rewardType == "Coins" then
							RewardText.Text = "+"..rewardValue
						elseif rewardType == "Titles" then
							RewardText.Text = "Title"
							local titleStyle = ShopModule:GetTitle(rewardValue)
							local titleText = titleStyle and titleStyle.TextStyle
							local textClone = titleText:Clone() :: TextLabel
							textClone.Visible = true
							textClone.Size = RewardText.Size
							textClone.LayoutOrder = RewardText.LayoutOrder
							textClone.Position = RewardText.Position
							textClone.Parent = RewardText.Parent
							
							RewardText.Visible = false
						end
					end
				end
			end
		end
	end
	
	setupWheelUI()
	
	prox.Triggered:Connect(function(plr)
		if plr ~= Player then return end -- not the correct player
		if onInspect then
			joinToWheel(false)
			return
		end
		joinToWheel(true)
	end)
	
	local function getIndexUnderPointer()
		local ray = Ray.new(DetectPart1.Position, (DetectPart2.Position - DetectPart1.Position).Unit * 100)
		local hit = workspace:FindPartOnRay(ray, Player.Character)
		if not hit then return nil end
		local number = tonumber(hit.Name and hit.Name:match("%d+"))
		return number
	end
	
	local function mod(a, b)
		local r = a % b
		if r < 0 then r = r + b end
		return r
	end
	
	local function trySpin(purchased: boolean)
		local canClaimDailyReward = CheckDailyRewardFunc:InvokeServer()
		if not canClaimDailyReward and not purchased then print(Player.Name, "not able to claim wheel reward.") return end
		if not rotateMainPart then print("Can't give wheel reward, no rotate part found.") return end
		
		if rotatingConnection then
			rotatingConnection:Disconnect()
			rotatingConnection = nil
		end
		
		ClaimButton.Visible = false
		CloseButton.Visible = false
		SpinBuyButton.Visible = false
		MainFrame.TimeText.Visible = false
		
		local segmentCount = #wheelRewards
		if segmentCount < 1 then return end
		
		--//Get a random reward from wheel
		local selectedIndex = math.random(1, segmentCount)
		local selectedReward = wheelRewards[selectedIndex]
		if not selectedReward then return end
		
		local currIndex = getIndexUnderPointer()
		if not currIndex then
			currIndex = 1
		end
		
		local baseCF = rotateMainPart.CFrame
		local epsilonDeg = 2
		rotateMainPart.CFrame = baseCF * CFrame.Angles(0, 0, math.rad(epsilonDeg))
		local nextIndex = getIndexUnderPointer() or currIndex
		rotateMainPart.CFrame = baseCF
		
		local forwardStep = mod(nextIndex - currIndex, segmentCount)
		local directionSign = (forwardStep == 1) and 1 or -1
		
		local segmentAngle = 360 / segmentCount
		local deltaSegments
		if directionSign == 1 then
			deltaSegments = mod(selectedIndex - currIndex, segmentCount)
		else
			deltaSegments = mod(currIndex - selectedIndex, segmentCount)
		end
		
		local extraSpins = math.random(8, 12)
		local finalAngleDeg = (extraSpins * 360) + (deltaSegments * segmentAngle)
		finalAngleDeg = finalAngleDeg * directionSign
		
		local duration = 2.4
		local startTime = tick()
		
		SoundService.Effects.WheelSound.Looped = true
		SoundService.Effects.WheelSound:Play()
		
		rotatingConnection = RunService.Heartbeat:Connect(function()
			local t = tick() - startTime
			local alpha = math.clamp(t / duration, 0, 1)
			
			local eased = 1 - (1 - alpha)^3
			
			local currentAngle = finalAngleDeg * eased
			rotateMainPart.CFrame = baseCF * CFrame.Angles(0, 0, math.rad(currentAngle))
			
			if alpha >= 1 then
				rotatingConnection:Disconnect()
				rotatingConnection = nil
				SoundService.Effects.WheelSound:Stop()
				SoundService.Effects.PurchaseSound:Play()
				
				local awarded = CheckDailyRewardFunc:InvokeServer("GiveReward", selectedReward, purchased)
				if awarded then
					changeRewardFrame(true, selectedReward)
				else
					joinToWheel(false)
					changeRewardFrame(false)
				end
			end
		end)
	end
	
	ClaimButton.MouseButton1Click:Connect(function()
		SoundService.Effects.ClickSound:Play()
		trySpin()
	end)
	
	CloseButton.MouseButton1Click:Connect(function()
		SoundService.Effects.ClickSound:Play()
		joinToWheel(false)
	end)
	
	SpinPurchase.OnClientEvent:Connect(function(purchased: boolean)
		trySpin(purchased)
	end)
	
	local function UpdateDailyTimer()
		local plrData = DataHandler:GetProfileData(Player)
		if not plrData then
			return
		end
		
		local timeText = MainFrame:FindFirstChild("TimeText")
		if not timeText then
			return
		end
		
		local totalTime = 24 * 60 * 60 -- 24 hours in seconds
		
		while true do
			task.wait(1)
			plrData = DataHandler:GetProfileData(Player)
			
			if not timeText or not timeText.Parent then
				continue
			end
			
			local timePassed = plrData.DailyTime or 0
			local timeRemaining = math.max(0, totalTime - timePassed)
			
			if timeRemaining <= 0 or plrData.DailyReward then
				--print("TIME: ", timeRemaining, "REWARD ENABLED: ", plrData.DailyReward)
				timeText.Text = "Claim your reward!"
				continue
			end
			
			local hours = math.floor(timeRemaining / 3600)
			local minutes = math.floor((timeRemaining % 3600) / 60)
			local seconds = timeRemaining % 60
			
			timeText.Text = string.format("Next Reward in: %02dh %02dm %02ds", hours, minutes, seconds)
		end
	end
	
	task.wait(0.5)
	
	coroutine.wrap(UpdateDailyTimer)()
end

return dailyWheelManager