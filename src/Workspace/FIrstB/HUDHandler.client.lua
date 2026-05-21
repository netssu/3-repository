--SERVICES
local RS = game:GetService("ReplicatedStorage")
local CS = game:GetService("CollectionService")
local TS = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local AvatarEditorService = game:GetService("AvatarEditorService")
local ExperienceNotifService = game:GetService("ExperienceNotificationService")
--REFERENCES
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

--StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

--Delay For Better Loading
repeat task.wait(1.5) until Player:FindFirstChild("PlayerInfo") and Player.Character:FindFirstChild("ToolFolder")

local BackgroundMusic = RS:WaitForChild("Assets").SFX.BackgroundMusic
BackgroundMusic:Play()

local PromptedFavOnce = false


--MORE REFERENCES
local Character = Player.Character
local HRP = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

local CashCollectionFolder = workspace.Map.CenterPoint.CashCollection

local PlayerGui = Player.PlayerGui
local HUD = PlayerGui.HUD

local PlayerInfo = Player.PlayerInfo
local PlayerStats = Player.PlayerStats
local CenterPoint = Workspace.Map.CenterPoint

local PlayerSpotVal = PlayerInfo:WaitForChild("PlayerSpot")
if PlayerSpotVal.Value == "None" or PlayerSpotVal.Value == "" then
	PlayerSpotVal:GetPropertyChangedSignal("Value"):Wait()
end

local PlayersPlot = workspace.Plots:FindFirstChild(PlayerSpotVal.Value)
local FarmersMarketSkillTree = PlayerStats.FarmersMarketSkillTree

--REMOTES
local HUDRemote = RS:WaitForChild("Remotes").HUDRemote
local LayoutBtnBindable = RS:WaitForChild("Remotes").LayoutBtnBindable

local LeaderstatValues = Player:FindFirstChild("leaderstatValues")
local PlayerStats = Player:FindFirstChild("PlayerStats")

local Rebirths:NumberValue = PlayerStats.Rebirths
local CashVal:NumberValue = LeaderstatValues.Cash
local FoodVal:NumberValue = LeaderstatValues.Food
local LevelVal:NumberValue = LeaderstatValues.Level
local MaxExperience:NumberValue = PlayerStats.MaxExperience
local Experience:NumberValue = PlayerStats.Experience


local HUD = Player.PlayerGui.HUD
local StatsCornerUi = HUD.StatsCorner.Stats
local LevelFrame = HUD.LevelFrame
local Camera = workspace.CurrentCamera

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
	if ab < 1000 then
		return roundToDecimals(x, decimalPlaces)
	end 
	local num = roundToDecimals(ab / Nums[p], decimalPlaces)
	return num * math.sign(x) .. names[p]
end

local function IncAdded(Difference,StatName,TextColor)
	local Pos = UDim2.fromScale(4.25,0.65)
	local TweenPos = UDim2.fromScale(4.25,0.2)

	if Difference < 10 then
		Pos = UDim2.fromScale(3,0.65)
		TweenPos = UDim2.fromScale(3,0.2)
	elseif Difference < 100 then
		Pos = UDim2.fromScale(3.4,0.65)
		TweenPos = UDim2.fromScale(3.4,0.2)
	elseif Difference < 1000 then
		Pos = UDim2.fromScale(3.8,0.65)
		TweenPos = UDim2.fromScale(3.8,0.2)
	elseif Difference < 10000 then
		Pos = UDim2.fromScale(4.6,0.65)
		TweenPos = UDim2.fromScale(4.6,0.2)
	elseif Difference < 100000 then
		Pos = UDim2.fromScale(5.1,0.65)
		TweenPos = UDim2.fromScale(5.1,0.2)
	elseif Difference < 1000000 then
		Pos = UDim2.fromScale(5.2,0.65)
		TweenPos = UDim2.fromScale(5.2,0.2)
	elseif Difference < 10000000 then
		Pos = UDim2.fromScale(4.7,0.65)
		TweenPos = UDim2.fromScale(4.7,0.2)
	else
		Pos = UDim2.fromScale(4.75,0.65)
		TweenPos = UDim2.fromScale(4.75,0.2)
	end

	local IncAdded = RS:WaitForChild("UIAssets").IncAdded:Clone()
	IncAdded.UIScale.Scale = 0.8
	IncAdded.TextTransparency = 1
	IncAdded.Parent = StatsCornerUi[StatName]
	IncAdded.Position = Pos
	if TextColor == Color3.fromRGB(255, 255, 255) then
		IncAdded.Text = "+"..FrmtNum(Difference,2)
	elseif TextColor ==  Color3.fromRGB(255, 0, 0) then
		IncAdded.Text = "-"..FrmtNum(Difference,2)
	end
	IncAdded.TextColor3 = TextColor

	TS:Create(IncAdded.UIScale,TweenInfo.new(0.5,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,false,0),{Scale = 1}):Play()
	local Tween = TS:Create(IncAdded,TweenInfo.new(0.75,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{TextTransparency = 0,Position = TweenPos,Rotation = -30})
	Tween:Play()
	Tween.Completed:Once(function()
		IncAdded:Destroy()
	end)
end

--ALL BUTTONS HOVER AND CLICK EFFECTS--
local OpenPurchaseFrames = {}
local OrigBtnSizes = {}
for _,HoverBtn in pairs(HUD:GetDescendants()) do
	if HoverBtn:IsA("GuiButton") then
		-- Save the exact original size ONCE
		OrigBtnSizes[HoverBtn] = HoverBtn.Size

		if HoverBtn.Parent:IsA("Frame") and HoverBtn.Parent.Name == "SideButtons" then
			HoverBtn.MouseButton1Down:Connect(function()
				TS:Create(HoverBtn.UIScale,TweenInfo.new(0.15,Enum.EasingStyle.Back,Enum.EasingDirection.Out,0,false,0),{Scale = 0.9}):Play()
			end)	
			HoverBtn.MouseButton1Up:Connect(function()
				-- Return to hover size (1.1) when they let go of the click
				TS:Create(HoverBtn.UIScale,TweenInfo.new(0.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out,0,false,0),{Scale = 1.1}):Play()
			end)	
			HoverBtn.MouseEnter:Connect(function()
				TS:Create(HoverBtn.UIScale,TweenInfo.new(0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out,0,false,0),{Scale = 1.1}):Play()
				TS:Create(HoverBtn.Icon,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out,0,false,0),{Rotation = -30}):Play()
			end)	
			HoverBtn.MouseLeave:Connect(function()
				TS:Create(HoverBtn.UIScale,TweenInfo.new(0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out,0,false,0),{Scale = 1}):Play()
				TS:Create(HoverBtn.Icon,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out,0,false,0),{Rotation = 0}):Play()
			end)
			continue
		end

		-- [[ THE FIX: EVERY OTHER BUTTON ]]
		HoverBtn.MouseButton1Down:Connect(function()
			local OrigSize = OrigBtnSizes[HoverBtn]
			-- Fixed 'true' to 'false' so it doesn't reverse fight with other tweens
			TS:Create(HoverBtn,TweenInfo.new(0.15,Enum.EasingStyle.Back,Enum.EasingDirection.Out,0,false,0),{Size = UDim2.fromScale(OrigSize.X.Scale * 0.9, OrigSize.Y.Scale * 0.9)}):Play()
		end)	

		HoverBtn.MouseButton1Up:Connect(function()
			local OrigSize = OrigBtnSizes[HoverBtn]
			-- Returns to 1.1x size because their mouse is still hovering over it when they let go
			TS:Create(HoverBtn,TweenInfo.new(0.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out,0,false,0),{Size = UDim2.fromScale(OrigSize.X.Scale * 1.1, OrigSize.Y.Scale * 1.1)}):Play()
		end)	

		HoverBtn.MouseEnter:Connect(function()
			local OrigSize = OrigBtnSizes[HoverBtn]
			-- Always multiply from the ORIGINAL size, never the current size!
			TS:Create(HoverBtn,TweenInfo.new(0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out,0,false,0),{Size = UDim2.fromScale(OrigSize.X.Scale * 1.1, OrigSize.Y.Scale * 1.1)}):Play()
			if HoverBtn:FindFirstChild("Icon") then
				TS:Create(HoverBtn.Icon,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out,0,false,0),{Rotation = -30}):Play()
			end	
		end)	

		HoverBtn.MouseLeave:Connect(function()
			local OrigSize = OrigBtnSizes[HoverBtn]
			-- Return to the exact original size
			TS:Create(HoverBtn,TweenInfo.new(0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out,0,false,0),{Size = OrigSize}):Play()
			if HoverBtn:FindFirstChild("Icon") then
				TS:Create(HoverBtn.Icon,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out,0,false,0),{Rotation = 0}):Play()
			end
		end)	
	end
end

-- 1. Create simple lists of which frames block which UIs
local GiftBlockers = {"GamepassShop", "FarmersMarketUpgrades", "RestaurantUpgrades", "TutorialUI"}
local ShuffleBlockers = {"GamepassShop", "TutorialUI"}
local TipsHideBlockers = {"GamepassShop", "Daily", "ManagerFrame", "TutorialUI", "Items", "TimedGift", "Settings","OfflineReward"}
local TipsShiftBlockers = {"FarmersMarketUpgrades", "RestaurantUpgrades"}

-- 2. Helper function to check if ANY of the frames in a list are currently open
local function isAnyFrameVisible(namesList)
	for _, name in pairs(namesList) do
		local frame = HUD:FindFirstChild(name, true) -- Finds the frame anywhere in the HUD
		if frame and frame:IsA("Frame") and frame.Visible then
			return true -- We found an open frame!
		end
	end
	return false -- None of them are open!
end

-- 3. Your Main Loop
for _, BTN in pairs(HUD:GetDescendants()) do

	-- Button Click Sounds
	if BTN:IsA("GuiButton") then
		BTN.MouseButton1Click:Connect(function()
			local UiBtnClickSfx = RS:WaitForChild("Assets").SFX.UIButtonClick
			UiBtnClickSfx:Play()
		end)
	end

	-- Frame Visibility Logic
	if BTN:IsA("Frame") then

		-- Check if this frame is actually in one of our lists (Saves performance!)
		local isRelevant = table.find(GiftBlockers, BTN.Name) or table.find(ShuffleBlockers, BTN.Name) or table.find(TipsHideBlockers, BTN.Name) or table.find(TipsShiftBlockers, BTN.Name)

		if isRelevant then
			BTN:GetPropertyChangedSignal("Visible"):Connect(function()

				-- Handle the Whoosh Sound
				local UIFrameWhoosh = RS:WaitForChild("Assets").SFX.UIFrameWhoosh
				UIFrameWhoosh.PlaybackSpeed = BTN.Visible and 1 or 1.1
				UIFrameWhoosh:Play()

				-- =========================================
				-- BULLETPROOF VISIBILITY CHECKS
				-- =========================================

				-- 1. Update Gift Visibility
				if isAnyFrameVisible(GiftBlockers) or Character:GetAttribute("ClaimedPeriodicGift") == true then
					HUD.Gift.Visible = false
				else
					HUD.Gift.Visible = true
				end

				-- 2. Update GamepassShuffle Visibility
				if isAnyFrameVisible(ShuffleBlockers) then
					HUD.GamepassShuffle.Visible = false
				else
					HUD.GamepassShuffle.Visible = true
				end

				-- 3. Update Tips Visibility & Position
				if PlayerStats.ExtendedTutorial.FifthStep:GetAttribute("SubStepComplete") == false then

					if isAnyFrameVisible(TipsHideBlockers) then
						-- A hide blocker is open, hide it completely
						HUD.Tips.Visible = false
						HUD.Tips:SetAttribute("Shifted", false)

					elseif isAnyFrameVisible(TipsShiftBlockers) then
						-- A shift blocker is open, move it to the side
						HUD.Tips.Visible = true
						HUD.Tips:SetAttribute("Shifted", true) -- Tell the tutorial script we are shifted!
						TS:Create(HUD.Tips, TweenInfo.new(0.15, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.45, 0.233)}):Play()

					else
						-- No blockers are open, put it in the default spot
						HUD.Tips.Visible = true
						HUD.Tips:SetAttribute("Shifted", false) -- Coast is clear, back to normal!
						TS:Create(HUD.Tips, TweenInfo.new(0.15, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.76, 0.233)}):Play()
					end
				end

			end)
		end
	end
end

for _,BTN in pairs(HUD.NavigationButtons:GetDescendants()) do
	if BTN:IsA("GuiButton") then
		BTN.MouseButton1Click:Connect(function()
			if BTN.Name == "Center" then
				if Character:GetAttribute("UsingCooker") == true then
					return
				end
				Character:PivotTo(CenterPoint.TeleportPosition.CFrame * CFrame.new(0,1.25,0))
				Camera.CFrame  = HRP.CFrame * CFrame.new(0,1.2,0)
			elseif BTN.Name == "Home" then
				if Character:GetAttribute("UsingCooker") == true then
					return
				end
				local currentPlot = workspace.Plots:FindFirstChild(PlayerSpotVal.Value)
				if currentPlot and currentPlot:FindFirstChild("Info") then
					Character:PivotTo(currentPlot.Info:FindFirstChild("SpawnPosition").CFrame * CFrame.new(0,1.25,0))
					Camera.CFrame  = HRP.CFrame * CFrame.new(0,1.2,0)
				end
			elseif BTN.Name == "Market" and FarmersMarketSkillTree.UnlockFarmersMarket.Value == true then
				if Character:GetAttribute("UsingCooker") == true then
					return
				end
				local ChosenFarmersPlot = nil
				for i,v in pairs(CashCollectionFolder.FarmerPlots:GetDescendants()) do
					if v:IsA("StringValue") then
						if v.Value == Player.Name then
							ChosenFarmersPlot = v.Parent
							break
						end
					end
				end
				if ChosenFarmersPlot then
					local ButtonPart = ChosenFarmersPlot.OccupiedFolder.Button.Button
					Character:PivotTo(ButtonPart.CFrame * CFrame.new(-3.5,1.25,0))
					Camera.CFrame  = HRP.CFrame * CFrame.new(0,1.2,0)		
				end
			end
		end)
	end
end

for _,BTN in pairs(HUD.SideButtons:GetDescendants()) do
	if BTN:IsA("GuiButton") then
		BTN.MouseButton1Click:Connect(function()
			local BTNFrame = HUD:FindFirstChild(BTN.Name)
			if BTNFrame.Visible == false then
				BTNFrame.Visible = true
				TS:Create(BTNFrame,TweenInfo.new(0.65,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,false,0),{Position = UDim2.fromScale(0.5,0.5)}):Play()
			else
				local Tween = TS:Create(BTNFrame,TweenInfo.new(0.45,Enum.EasingStyle.Back,Enum.EasingDirection.In,0,false,0),{Position = UDim2.fromScale(1.5,0.5)})
				Tween:Play()
				Tween.Completed:Once(function()
					BTNFrame.Visible = false
				end)
			end
			for i,v in pairs(HUD:GetDescendants()) do
				if not v:IsA("Frame") then continue end
				for _,k in pairs(HUD.SideButtons:GetChildren()) do
					if v.Name ~= k.Name then
						continue
					end
					if v.Name == BTNFrame.Name then continue end
					local Tween = TS:Create(v,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.In,0,false,0),{Position = UDim2.fromScale(1.5,0.5)})
					Tween:Play()
					Tween.Completed:Once(function()
						v.Visible = false
					end)
					break	
				end
			end	
		end)
	end
end

LayoutBtnBindable.Event:Connect(function(BTN)
	OrigBtnSizes[BTN] = BTN.Size
end)

function Format(Int)
	return string.format("%02i", Int)
end

function convertToHMS(Seconds)
	local Minutes = (Seconds - Seconds%60)/60
	Seconds = Seconds - Minutes*60
	local Hours = (Minutes - Minutes%60)/60
	Minutes = Minutes - Hours*60
	return Format(Minutes)..":"..Format(Seconds)
end

local StatValues = {}
for i,Stat in pairs(LeaderstatValues:GetChildren()) do
	if Stat:IsA("NumberValue") then
		local StatName = string.gsub(Stat.Name,"Val","")
		if not StatsCornerUi:FindFirstChild(StatName) then
			continue
		end
		print(StatName)
		
		StatValues[StatName] = Stat.Value
		StatsCornerUi[StatName][StatName.."Amount"].Text = FrmtNum(Stat.Value,2)
		Stat:GetPropertyChangedSignal("Value"):Connect(function()
			StatsCornerUi[StatName][StatName.."Amount"].Text = FrmtNum(Stat.Value,2)
			local Difference = Stat.Value - StatValues[StatName]
			if Difference > 0 then
				-- INCREASED
				IncAdded(Difference, StatName, Color3.fromRGB(255, 255, 255)) 
			elseif Difference < 0 then
				-- REDUCED
				IncAdded(math.abs(Difference), StatName, Color3.fromRGB(255, 0, 0))
			end
			StatValues[StatName] = Stat.Value
		end)
	end
end

for i,Stat in pairs(PlayerStats:GetChildren()) do
	if Stat:IsA("NumberValue") then
		local StatName = string.gsub(Stat.Name,"Val","")
		if not StatsCornerUi:FindFirstChild(StatName) then
			continue
		end
		print(StatName)
		
		StatValues[StatName] = Stat.Value
		StatsCornerUi[StatName][StatName.."Amount"].Text = FrmtNum(Stat.Value,2)
		Stat:GetPropertyChangedSignal("Value"):Connect(function()
			if Stat.Name == "Ingredients" then
				if Stat.Value >= 1000 and PromptedFavOnce==false then
					PromptedFavOnce = true
					AvatarEditorService:PromptSetFavorite(78981149061226, Enum.AvatarItemType.Asset, true)
					task.delay(30,function()
						if ExperienceNotifService:CanPromptOptInAsync() == true then
							ExperienceNotifService:PromptOptIn()
						end
					end)
				end
			end
			StatsCornerUi[StatName][StatName.."Amount"].Text = FrmtNum(Stat.Value,2)
			local Difference = Stat.Value - StatValues[StatName]
			if Difference > 0 then
				-- INCREASED
				IncAdded(Difference, StatName, Color3.fromRGB(255, 255, 255)) 
			elseif Difference < 0 then
				-- REDUCED
				IncAdded(math.abs(Difference), StatName, Color3.fromRGB(255, 0, 0))
			end
			StatValues[StatName] = Stat.Value
		end)
	end
end

LevelFrame.Level.Text = "Level "..FrmtNum(LevelVal.Value,2)
LevelVal:GetPropertyChangedSignal("Value"):Connect(function()
	LevelFrame.Level.Text = "Level "..FrmtNum(LevelVal.Value,2)
end)

LevelFrame.ExpFrame.Experience.Text = FrmtNum(Experience.Value,2).."/"..FrmtNum(MaxExperience.Value,2)
MaxExperience:GetPropertyChangedSignal("Value"):Connect(function()
	LevelFrame.ExpFrame.Experience.Text = FrmtNum(Experience.Value,2).."/"..FrmtNum(MaxExperience.Value,2)
end)

LevelFrame.ExpFrame.ExpBar.Position = UDim2.fromScale(math.clamp(Experience.Value/MaxExperience.Value,0,0.989),0.5)
Experience:GetPropertyChangedSignal("Value"):Connect(function()
	TS:Create(LevelFrame.ExpFrame.ExpBar,TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false),{Position = UDim2.fromScale(math.clamp(Experience.Value/MaxExperience.Value,0,0.989),0.5)}):Play()
	LevelFrame.ExpFrame.Experience.Text = FrmtNum(Experience.Value,2).."/"..FrmtNum(MaxExperience.Value,2)
end)
