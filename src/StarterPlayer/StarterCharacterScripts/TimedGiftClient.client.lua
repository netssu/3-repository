local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TS = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local GroupService = game:GetService("GroupService")

local Player = Players.LocalPlayer
local TimedGiftRem = RS:WaitForChild("Remotes"):WaitForChild("TimedGiftRem")
local NotifModule = require(RS:WaitForChild("Modules"):WaitForChild("NotifModule"))

-- Wait for Character & GUI
local Character = script.Parent
local PlayerGui = Player:WaitForChild("PlayerGui")
local HUD = PlayerGui:WaitForChild("HUD")

-- UI References
local GiftBtn = HUD:WaitForChild("Gift")
local GiftIconBtn = GiftBtn.GiftIcon
local TimedGiftFrame = HUD:WaitForChild("TimedGift")
local ClaimBtn = TimedGiftFrame:WaitForChild("Claim")
local CloseBtn = TimedGiftFrame:WaitForChild("Close")

-- Find the Timer TextLabel inside the Gift Button (Assuming it's a TextLabel child)
local GiftTimerLabel = GiftBtn:FindFirstChildWhichIsA("TextLabel")

-- Time Variables (In Seconds)
local GIFT_TIME = 10 * 60 -- 15 Minutes
local COOLDOWN_TIME = 20 * 60 -- 20 Minutes

local CurrentState = "Counting" -- States: "Counting", "Ready", "Cooldown"
local TimeLeft = GIFT_TIME

local GROUPID = 35501365

-- [[ HELPER: FORMAT TIME TO MM:SS ]]
local function FormatTime(seconds)
	local minutes = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%02d:%02d", minutes, secs)
end

-- [[ MAIN TIMER LOOP ]]
task.spawn(function()
	-- Initial Setup
	GiftIconBtn.ImageColor3 = Color3.fromRGB(0, 0, 0) -- Blacked out

	while true do
		task.wait(1)

		if CurrentState == "Counting" then
			TimeLeft -= 1
			if GiftTimerLabel then GiftTimerLabel.Text = FormatTime(TimeLeft) end

			if TimeLeft <= 0 then
				CurrentState = "Ready"
				GiftIconBtn.ImageColor3 = Color3.fromRGB(255, 255, 255) -- Normal color
				if GiftTimerLabel then GiftTimerLabel.Text = "READY!" end
			end

		elseif CurrentState == "Cooldown" then
			TimeLeft -= 1

			if TimeLeft <= 0 then
				-- Cooldown over! Restart the 15 min timer.
				CurrentState = "Counting"
				TimeLeft = GIFT_TIME
				GiftBtn.Visible = true
				GiftIconBtn.ImageColor3 = Color3.fromRGB(0, 0, 0)
				TimedGiftRem:FireServer("ReadyToBeClaimed")
			end
		end
	end
end)

-- [[ BUTTON LISTENERS ]]

-- Click the Gift Icon to open/close menu
GiftIconBtn.MouseButton1Click:Connect(function()
	if Character:GetAttribute("ClaimedPeriodicGift") == true then
		return
	end
	if CurrentState == "Ready" then
		TimedGiftFrame.Visible = not TimedGiftFrame.Visible
	elseif CurrentState == "Counting" then
		TimedGiftFrame.Visible = not TimedGiftFrame.Visible
		NotifModule.Notify(Player,"Gift will be ready in " .. FormatTime(TimeLeft) .. "!")
	end
end)

-- Close Button
CloseBtn.MouseButton1Click:Connect(function()
	TimedGiftFrame.Visible = false
end)

-- Claim Button
ClaimBtn.MouseButton1Click:Connect(function()
	if CurrentState == "Ready" then
		TimedGiftRem:FireServer("ClaimGift")
	elseif CurrentState == "Counting" then
		if Player:IsInGroupAsync(GROUPID) == false then
			GroupService:PromptJoinAsync(GROUPID) 
		end
	end
end)

-- [[ SERVER RESPONSES ]]
TimedGiftRem.OnClientEvent:Connect(function(Action)
	if Action == "NotInGroup" then
		-- Prompt them using your NotifModule
		NotifModule.Notify(Player,"You must Join the Group and Like the game to claim this!")
		GroupService:PromptJoinAsync(GROUPID) 

	elseif Action == "ClaimSuccess" then
		-- Hide UI and start 20 min Cooldown
		TimedGiftFrame.Visible = false
		GiftBtn.Visible = false

		CurrentState = "Cooldown"
		TimeLeft = COOLDOWN_TIME

		NotifModule.Notify(Player,"Gift Claimed!")
		
	end
end)

-- [[ VISUAL EFFECTS: SUNBURST & WIGGLE ]]
local Sunburst = GiftBtn:WaitForChild("Sunburst")
local GiftIcon = GiftBtn:WaitForChild("GiftIcon")

-- 1. Continuous Sunburst Spin
-- RunService.RenderStepped runs every single frame, making it buttery smooth
RunService.RenderStepped:Connect(function(deltaTime)
	if GiftBtn.Visible then
		-- deltaTime ensures the spin speed stays exactly the same regardless of a player's FPS
		Sunburst.Rotation = Sunburst.Rotation + (deltaTime * 45) -- 45 degrees per second
	end
	if CurrentState == "Cooldown" then
		if GiftBtn.Visible == true then
			GiftBtn.Visible = false
		end
	end
end)

-- 2. Jump and Wiggle Sequence
task.spawn(function()
	-- Save the original state so it always returns to normal
	local origPos = GiftIcon.Position
	local origRot = GiftIcon.Rotation

	while true do
		task.wait(1.5) -- Wait 1.5 seconds between each jump

		if GiftBtn.Visible then
			-- A. Jump Up (Moves the Y Offset up by 15 pixels)
			TS:Create(GiftIcon, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				Position = UDim2.new(origPos.X.Scale, origPos.X.Offset, origPos.Y.Scale, origPos.Y.Offset - 15)
			}):Play()

			task.wait(0.15)

			-- B. Wiggle Left and Right
			TS:Create(GiftIcon, TweenInfo.new(0.05, Enum.EasingStyle.Sine), {Rotation = origRot - 15}):Play()
			task.wait(0.05)
			TS:Create(GiftIcon, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {Rotation = origRot + 15}):Play()
			task.wait(0.1)
			TS:Create(GiftIcon, TweenInfo.new(0.05, Enum.EasingStyle.Sine), {Rotation = origRot}):Play()

			-- C. Fall Back Down
			TS:Create(GiftIcon, TweenInfo.new(0.15, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
				Position = origPos
			}):Play()
		end
	end
end)