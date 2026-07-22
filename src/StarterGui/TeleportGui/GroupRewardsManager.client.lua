--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")
local GroupService = game:GetService("GroupService")
local SoundService = game:GetService("SoundService")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local ReceiveGroupRewards = Remotes:FindFirstChild("ReceiveGroupReward")

--//Modules
local GameConfig = require(Rs:FindFirstChild("GameConfig"))

--//Player
local Player = game.Players.LocalPlayer
local PlrGui = Player.PlayerGui

--//UI
local MenuGui = PlrGui:FindFirstChild("MenuGui")
local RewardFrame = MenuGui and MenuGui:FindFirstChild("InGameFrame"):FindFirstChild("RewardsFrame")
local claimButton = RewardFrame and RewardFrame:FindFirstChild("ClaimButton")
local closeButton = RewardFrame and RewardFrame:FindFirstChild("CloseButton")

--//Group Rewards Model
local Map = workspace:WaitForChild("Map")
local InteractStuff = Map:WaitForChild("InteractStuff")
local GroupRewardModel = InteractStuff:WaitForChild("ChatTag_Rewards")
local GroupUI = GroupRewardModel:WaitForChild("Screen"):WaitForChild("SurfaceGui"):WaitForChild("MainFrame")

--//Group Rewards (like the game)
local Medkit_RewardModel = InteractStuff:WaitForChild("Medkit_Reward")
local MedkitTrigger = Medkit_RewardModel:WaitForChild("Trigger")

--//Values
local GroupID = GameConfig.groupid or 35529401
local Debounce = true

local success, groupInfo = pcall(function()
	return GroupService:GetGroupInfoAsync(GroupID)
end)

if success and groupInfo then
	GroupUI.GroupIcon.Image = groupInfo.EmblemUrl
else
	print("Cannot take group info.")
end

local function showNotification(text: string, success: boolean?)
	local showText = script.Parent.MainFrame.WarnText:Clone()
	showText.Parent = script.Parent
	showText.Text = text
	showText.TextTransparency = 1
	
	if success then
		showText.TextColor3 = Color3.fromRGB(58, 255, 28)
	end
	
	Ts:Create(showText, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
	Ts:Create(showText, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Position = UDim2.new(0.272, 0, 0.812, 0)}):Play()
	
	task.wait(1.5)
	
	Ts:Create(showText, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
	Ts:Create(showText, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {Position = UDim2.new(0.272, 0, 0.862, 0)}):Play()
	
	game.Debris:AddItem(showText, 1)
end

local defaultRewardFrameSize = RewardFrame.Size

local function changeRewardFrame(state: boolean)
	if state then -- show
		SoundService.Effects.ClickSound:Play()
		RewardFrame.Size = UDim2.new(0, 0, 0, 0)
		RewardFrame.Visible = true
		Ts:Create(RewardFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Size = defaultRewardFrameSize}):Play()
	else -- unshow
		local tween = Ts:Create(RewardFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.fromScale(0, 0)})
		tween:Play()
		tween.Completed:Wait()
		RewardFrame.Visible = false
	end
end

--[[
	Check if player is in group, if is, give the
	group reward (medkit in this case).
]]
claimButton.MouseButton1Click:Connect(function()
	if not Debounce then return end
	Debounce = false
	
	local rewards = ReceiveGroupRewards:InvokeServer(nil, "Medkit")
	
	if not rewards then -- Player not in group
		script.IncorrectSound:Play()
		showNotification("Like the Game and Join our group first to receive your reward!")
	elseif rewards == true then
		script.AwardSound:Play()
		showNotification("+1 Medkit (Game Perk)", true)
	else
		script.SelectSound:Play()
		showNotification("Already claimed.")
	end
	
	task.wait(0.5)
	
	Debounce = true
end)

local rewardFrameState = false

MedkitTrigger.Touched:Connect(function(hit)
	if rewardFrameState then return end
	if not hit or not hit.Parent then return end
	local plr = game.Players:GetPlayerFromCharacter(hit.Parent)
	if plr ~= Player then return end
	
	rewardFrameState = true
	changeRewardFrame(true)
end)

closeButton.MouseButton1Click:Connect(function()
	SoundService.Effects.ClickSound:Play()
	changeRewardFrame(false)
	rewardFrameState = false
end)