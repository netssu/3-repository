--[[
	TUTORIAL CLIENT SCRIPT  (LocalScript inside Character)
	=======================================================
	showInfo modes:
	  • mode = "ok"        → yields until OkButton is clicked
	  • mode = "timed"     → disappears after `extra` seconds (default 3)
	  • mode = "condition" → yields until extra() returns true (no OkButton)
	
	Multiple beams: pointBeamsTo(targets, r, g, b)
	  targets can be BasePart or { BasePart, ... }
	clearBeams() clears all active beams.
	
	GetAnchor accepts Model, Folder or BasePart.
]]

-- ─────────────────────────────────────────────────────────
-- SERVICES
-- ─────────────────────────────────────────────────────────
local RS                     = game:GetService("ReplicatedStorage")
local TS                     = game:GetService("TweenService")
local Players                = game:GetService("Players")
local RunService             = game:GetService("RunService")
local AvatarEditorService    = game:GetService("AvatarEditorService")
local ExperienceNotifService = game:GetService("ExperienceNotificationService")

-- ─────────────────────────────────────────────────────────
-- REFERENCES
-- ─────────────────────────────────────────────────────────
local Player            = Players.LocalPlayer
local UpgradeRem        = RS:WaitForChild("Remotes").UpgradeRemote
local TutorialRemote    = RS:WaitForChild("Remotes").TutorialRemote
local TutorialBindable  = RS:WaitForChild("Remotes").TutorialBindable
local LayoutBtnBindable = RS:WaitForChild("Remotes").LayoutBtnBindable

-- ─────────────────────────────────────────────────────────
-- MODULES
-- ─────────────────────────────────────────────────────────
local UpgradesDictionary     = require(RS:WaitForChild("Modules").UpgradesDictionary)
local NotifModule            = require(RS:WaitForChild("Modules").NotifModule)
local ExtendedTutorialModule = require(RS:WaitForChild("Modules").ExtendedTutorialSteps)

-- ─────────────────────────────────────────────────────────
-- CHARACTER / PLAYER
-- ─────────────────────────────────────────────────────────
local Character = script.Parent
repeat task.wait(1) until Player:FindFirstChild("PlayerInfo") and Player.Character:FindFirstChild("ToolFolder")

local PlayerGui   = Player:WaitForChild("PlayerGui")
local HUD         = PlayerGui:WaitForChild("HUD")
local TutorialUI  = HUD:WaitForChild("TutorialUI")

local HRP      = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

local LeaderstatValues = Player:FindFirstChild("leaderstatValues")
local PlayerStats      = Player:FindFirstChild("PlayerStats")
local PlayerInfo       = Player:WaitForChild("PlayerInfo")

local Upgrades               = PlayerStats.Upgrades
local FarmersMarketSkillTree = PlayerStats.FarmersMarketSkillTree

local Rebirths    = PlayerStats.Rebirths
local Ingredients = PlayerStats.Ingredients
local CashVal     = LeaderstatValues.Cash
local FoodVal     = LeaderstatValues.Food

local Plots         = workspace.Plots
local PlayerSpotVal = PlayerInfo:WaitForChild("PlayerSpot")

if PlayerSpotVal.Value == "None" or PlayerSpotVal.Value == "" then
	PlayerSpotVal:GetPropertyChangedSignal("Value"):Wait()
end

local PlayerPlot          = Plots:WaitForChild(PlayerSpotVal.Value)
local RestaurantSkillTree = PlayerStats:WaitForChild("RestaurantSkillTree")

-- ─────────────────────────────────────────────────────────
-- WORLD REFERENCES
-- ─────────────────────────────────────────────────────────
local CenterPoint          = workspace:WaitForChild("Map"):WaitForChild("CenterPoint")
local IngredientCollection = CenterPoint:WaitForChild("IngredientCollection")
local FoodCollection       = CenterPoint:WaitForChild("FoodCollection")
local CookingPot           = FoodCollection:WaitForChild("CookingPot"):WaitForChild("Pot"):WaitForChild("PotBody")
local IngUpgradeBoards     = IngredientCollection:WaitForChild("UpgradeBoards")
local FoodUpgradeBoards    = FoodCollection:WaitForChild("UpgradeBoards")
local FMSkillTreeFolder    = workspace.Map.SkillTrees:FindFirstChild("FarmersMarketSkillTree")
local PlayerIngredients    = workspace:WaitForChild("PlayerIngredients")

-- ─────────────────────────────────────────────────────────
-- EXTENDED TUTORIAL STEPS
-- ─────────────────────────────────────────────────────────
local ExtendedTutorialSteps = PlayerStats:WaitForChild("ExtendedTutorial")
local StepObjects = {
	First  = ExtendedTutorialSteps:WaitForChild("FirstStep"),
	Second = ExtendedTutorialSteps:WaitForChild("SecondStep"),
	Third  = ExtendedTutorialSteps:WaitForChild("ThirdStep"),
	Fourth = ExtendedTutorialSteps:WaitForChild("FourthStep"),
	Fifth  = ExtendedTutorialSteps:WaitForChild("FifthStep"),
}

-- ─────────────────────────────────────────────────────────
-- RESUME HELPER
-- ─────────────────────────────────────────────────────────
local function getResumePhase()
	local S = StepObjects
	if S.Fifth.Value and S.Fifth:GetAttribute("SubStepComplete") then return 15 end
	if S.Fourth.Value and not S.Fourth:GetAttribute("SubStepComplete") then return 13 end
	if S.Third.Value and S.Third:GetAttribute("SubStepComplete") and not S.Fourth.Value then return 12 end
	if S.Third.Value and not S.Third:GetAttribute("SubStepComplete") then return 11 end
	if S.Second.Value and S.Second:GetAttribute("SubStepComplete") and not S.Third.Value then return 10 end
	if S.Second.Value and not S.Second:GetAttribute("SubStepComplete") then return 9 end
	if S.First.Value and S.First:GetAttribute("SubStepComplete") and not S.Second.Value then return 7 end
	if S.First.Value and not S.First:GetAttribute("SubStepComplete") then return 5 end
	return 1
end

-- ─────────────────────────────────────────────────────────
-- FORMATTING
-- ─────────────────────────────────────────────────────────
local names = {"K","M","B","T","Qa","Qi","Sx","Sp","Oc","No","Dd","Ud","Dd","Td","Qad","Qid",
	"Sxd","Spd","Ocd","Nod","Vg","Uvg","Dvg","Tvg","Qavg","Qivg","Sxvg","Spvg","Ocvg"}
local Nums = {}
for i = 1, #names do table.insert(Nums, 1000^i) end
local function FrmtNum(x, dp)
	local function rnd(n, d) return tonumber(string.format("%."..d.."f", n)) end
	local ab = math.abs(x)
	if ab < 1000 then return rnd(x, dp) end
	local p = math.min(math.floor(math.log10(ab) / 3), #names)
	return rnd(ab / Nums[p], dp) * math.sign(x) .. names[p]
end

-- ─────────────────────────────────────────────────────────
-- GetAnchor — accepts BasePart, Model (with or without PrimaryPart) or Folder
-- ─────────────────────────────────────────────────────────
local function GetAnchor(obj)
	if not obj then return nil end
	if obj:IsA("BasePart") then return obj end
	-- Only try PrimaryPart if it's a Model (Folder doesn't have that property)
	if obj:IsA("Model") and obj.PrimaryPart then return obj.PrimaryPart end
	-- Fallback: first descendant BasePart (works for Model without PP and Folder)
	for _, v in ipairs(obj:GetDescendants()) do
		if v:IsA("BasePart") then return v end
	end
	return nil
end

-- ─────────────────────────────────────────────────────────
-- SERVER NOTIFIERS
-- ─────────────────────────────────────────────────────────
local function completeStep(stepObj, stepName)
	stepObj.Value = true
	TutorialRemote:FireServer("CompleteStep", stepName)
end

local function completeSubStep(stepObj, stepName)
	stepObj:SetAttribute("SubStepComplete", true)
	TutorialRemote:FireServer("CompleteSubStep", stepName)
end

local foldButtonOpenedImage = "rbxassetid://129288474218695"
local foldButtonClosedImage = "rbxassetid://116331095020917"
local foldButtonOpenedPosition = UDim2.new(1,0,0,0)
local foldButtonClosedPosition = UDim2.fromScale(0.55,0.2)

-- ─────────────────────────────────────────────────────────
-- QUEST BAR
-- ─────────────────────────────────────────────────────────
local ExtendedTutorialUI = HUD.Tips.TipsFrame
local FoldButton         = HUD.Tips.Fold
local ExtendedTutOpen    = true
local TutorialStats = {
	Rebirths    = PlayerStats.Rebirths,
	Ingredients = PlayerStats.Ingredients,
	Cash        = LeaderstatValues.Cash,
	Food        = LeaderstatValues.Food,
}

local StepOrder             = {"FirstStep","SecondStep","ThirdStep","FourthStep","FifthStep"}
local EndingTipTimer        = 0
local CurrentEndingTip      = ""
local ExtendedTutStarted    = false
local StartExtendedTutorial = false
if PlayerStats.TutorialComplete.Value == true then
	StartExtendedTutorial = true
end

FoldButton.MouseButton1Click:Connect(function()
	if ExtendedTutOpen then
		TS:Create(ExtendedTutorialUI, TweenInfo.new(0.3,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out),{Position=UDim2.fromScale(0.5,0.15)}):Play()
		TS:Create(ExtendedTutorialUI, TweenInfo.new(0.3,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out),{Size=UDim2.fromScale(1,0)}):Play()
		TS:Create(FoldButton, TweenInfo.new(0.3,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out),{Position=foldButtonClosedPosition}):Play()
		TS:Create(FoldButton, TweenInfo.new(0.2,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out),{Rotation=0}):Play()
		TS:Create(FoldButton.Parent.Title,TweenInfo.new(0.3,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out),{Position=UDim2.fromScale(0.5,0)}):Play()
		FoldButton.Image = foldButtonClosedImage
		FoldButton.Parent.Title.Visible = true
		ExtendedTutOpen = false
	else
		TS:Create(ExtendedTutorialUI,TweenInfo.new(0.3,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out),{Position=UDim2.fromScale(0.5,0.5)}):Play()
		TS:Create(ExtendedTutorialUI,TweenInfo.new(0.3,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out),{Size=UDim2.fromScale(1,1)}):Play()
		TS:Create(FoldButton,TweenInfo.new(0.3,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out),{Position=foldButtonOpenedPosition}):Play()
		TS:Create(FoldButton,TweenInfo.new(0.2,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out),{Rotation=180}):Play()
		TS:Create(FoldButton.Parent.Title,TweenInfo.new(0.3,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out),{Position=UDim2.fromScale(0.5,0.148)}):Play()
		FoldButton.Image = foldButtonOpenedImage
		FoldButton.Parent.Title.Visible = false
		ExtendedTutOpen = true
	end
end)

local function ExtendedTutorialSetup(DeltaTime)
	if not StartExtendedTutorial then return end
	if not ExtendedTutStarted then
		HUD.Tips.Visible  = true
		HUD.Tips.Position = UDim2.fromScale(1.3, 0.233)
		TS:Create(HUD.Tips,TweenInfo.new(0.25,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out),{Position=UDim2.fromScale(0.76,0.233)}):Play()
		ExtendedTutStarted = true
	end
	if EndingTipTimer > 0 then
		EndingTipTimer -= DeltaTime
		ExtendedTutorialUI.Title.Visible     = false
		ExtendedTutorialUI.ExtraTip.Visible  = false
		ExtendedTutorialUI.StatsList.Visible = false
		ExtendedTutorialUI.EndingTip.Visible = true
		ExtendedTutorialUI.EndingTip.Text    = CurrentEndingTip
		if EndingTipTimer <= 0 then
			ExtendedTutorialUI.EndingTip.Visible = false
			if StepObjects.Fifth:GetAttribute("SubStepComplete") == true then
				ExtendedTutorialUI.Visible = false
				return "TutorialFinished"
			end
			ExtendedTutorialUI.Title.Visible     = true
			ExtendedTutorialUI.ExtraTip.Visible  = true
			ExtendedTutorialUI.StatsList.Visible = true
			ExtendedTutorialUI.Position = UDim2.fromScale(1.35, 0.233)
			local tx = ExtendedTutorialUI:GetAttribute("Shifted") and 0.45 or 0.76
			TS:Create(ExtendedTutorialUI,TweenInfo.new(0.3,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out),{Position=UDim2.fromScale(tx,0.233)}):Play()
		end
		return
	end
	local ActiveStepName, IsSubStep, AllCompleted = nil, false, true
	for _, stepName in ipairs(StepOrder) do
		local obj = ExtendedTutorialSteps:FindFirstChild(stepName)
		if not obj then continue end
		if obj.Value == false then
			ActiveStepName = stepName ; IsSubStep = false ; AllCompleted = false ; break
		elseif obj:GetAttribute("SubStepComplete") ~= true then
			ActiveStepName = stepName ; IsSubStep = true  ; AllCompleted = false ; break
		end
	end
	if AllCompleted then
		ExtendedTutorialUI.Parent.Visible = false
		return "TutorialFinished"
	end
	local StepDetails = ExtendedTutorialModule.Steps[ActiveStepName]
	local Icon2 = ExtendedTutorialUI.StatsList.Icon2
	Icon2.Visible = false
	if not IsSubStep then
		local StatVal = TutorialStats[StepDetails.Currency]
		ExtendedTutorialUI.StatsList.Icon.Image       = StepDetails.Icon
		ExtendedTutorialUI.StatsList.Icon.Amount.Text = FrmtNum(StatVal.Value,2).."/"..FrmtNum(StepDetails.ValueGoal,2)
		ExtendedTutorialUI.Title.Text    = StepDetails.Description
		ExtendedTutorialUI.ExtraTip.Text = StepDetails.Tip
	else
		local StatVal = TutorialStats[StepDetails.SubStepCurrency]
		ExtendedTutorialUI.StatsList.Icon.Image       = StepDetails.SubStepIcon
		ExtendedTutorialUI.StatsList.Icon.Amount.Text = FrmtNum(StatVal.Value,2).."/"..FrmtNum(StepDetails.SubStepValueGoal,2)
		ExtendedTutorialUI.Title.Text    = StepDetails.SubStep
		ExtendedTutorialUI.ExtraTip.Text = StepDetails.Tip
	end
end

local ExtendedTutConnection
if StepObjects.Fifth:GetAttribute("SubStepComplete") == true then
	ExtendedTutorialUI.Parent.Visible = false
else
	ExtendedTutConnection = RunService.Heartbeat:Connect(function(dt)
		local status = ExtendedTutorialSetup(dt)
		if status == "TutorialFinished" then
			if ExtendedTutConnection then ExtendedTutConnection:Disconnect() ExtendedTutConnection = nil end
		end
	end)
end

-- ─────────────────────────────────────────────────────────
-- MAIN TUTORIAL
-- ─────────────────────────────────────────────────────────
TutorialRemote.OnClientEvent:Connect(function(Action, Data)
	if Action ~= "StartTutorial" or not TutorialUI then return end

	local DimFrame = TutorialUI.DimFrame
	local Info     = TutorialUI.Info
	local BeamTemplate = TutorialUI.Beam   -- used only as a template for Clone
	local OkButton = TutorialUI.OkButton

	-- ═══════════════════════════════════════════════════════
	-- BEAM HELPERS
	-- ═══════════════════════════════════════════════════════
	local activeBeams = {} -- list of { beam=Beam, att1=Attachment }

	local function getHRPAtt()
		local att = HRP:FindFirstChild("TutBeamAtt0")
		if not att then
			att = Instance.new("Attachment", HRP)
			att.Name = "TutBeamAtt0"
		end
		return att
	end

	local function clearBeams()
		for _, data in ipairs(activeBeams) do
			if data.beam and data.beam.Parent then
				data.beam:Destroy()
			end
		end
		activeBeams = {}
	end

	--[[
		pointBeamsTo(targets, r, g, b)
		  targets: BasePart  OR  { BasePart, ... }  OR  Instance (GetAnchor is applied)
		Creates a Beam from HRP to each target simultaneously.
	]]
	local function pointBeamsTo(targets, r, g, b)
		clearBeams()
		if not targets then return end

		-- Normalize to table
		local list = {}
		if typeof(targets) == "Instance" then
			local anchor = GetAnchor(targets)
			if anchor then table.insert(list, anchor) end
		elseif type(targets) == "table" then
			for _, t in ipairs(targets) do
				local anchor = GetAnchor(t)
				if anchor then table.insert(list, anchor) end
			end
		end

		local hrpAtt = getHRPAtt()
		local col    = ColorSequence.new(Color3.fromRGB(r or 100, g or 230, b or 100))

		for i, anchor in ipairs(list) do
			local attName = "TutBeamAtt1_" .. i
			local att1 = anchor:FindFirstChild(attName)
			if not att1 then
				att1 = Instance.new("Attachment", anchor)
				att1.Name = attName
			end
			local newBeam       = BeamTemplate:Clone()
			newBeam.Parent      = HRP
			newBeam.Attachment0 = hrpAtt
			newBeam.Attachment1 = att1
			newBeam.Color       = col
			newBeam.Enabled     = true
			table.insert(activeBeams, { beam = newBeam, att1 = att1 })
		end
	end

	-- ═══════════════════════════════════════════════════════
	-- INFO / showInfo
	-- ═══════════════════════════════════════════════════════
	--[[
		showInfo(text, r, g, b, scale, posY, mode, extra)

		mode = "ok"        → yields until OkButton is clicked        (extra ignored)
		mode = "timed"     → disappears after `extra` seconds (default 3)  (extra = number)
		mode = "condition" → yields until extra() == true            (extra = function, no OkButton)
	]]
	local function showInfo(text, r, g, b, scale, posY, mode, extra)
		mode = mode or "ok"

		Info.Text       = text
		Info.TextColor3 = Color3.fromRGB(r, g, b)
		Info.Position   = UDim2.fromScale(0.5, posY or 0.38)
		Info.Size       = UDim2.fromScale(0.05, 0.05)
		Info.Visible    = true

		TS:Create(Info, TweenInfo.new(0.3, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
			{Size = UDim2.fromScale(scale or 0.46, scale or 0.46)}):Play()

		if mode == "ok" then
			OkButton.Visible = true
			OkButton.MouseButton1Click:Wait()
			OkButton.Visible = false

		elseif mode == "timed" then
			OkButton.Visible = false
			task.wait(type(extra) == "number" and extra or 3)

		elseif mode == "condition" then
			OkButton.Visible = false
			repeat task.wait(0.2) until type(extra) == "function" and extra()
		end

		TS:Create(Info, TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
			{Size = UDim2.fromScale(0, 0)}):Play()
		task.wait(0.25)
		Info.Visible = false
		task.wait(0.1)
	end

	--[[

	local function showDim(show)
		DimFrame.Visible = show
		if show then
			DimFrame.Size = UDim2.fromScale(0.05, 0.05)
			TS:Create(DimFrame, TweenInfo.new(0.15, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
				{Size = UDim2.fromScale(1, 1)}):Play()
		else
			TS:Create(DimFrame, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
				{Size = UDim2.fromScale(0, 0)}):Play()
			task.wait(0.55)
			DimFrame.Visible = false
		end
	end
	
	]]

	-- ═══════════════════════════════════════════════════════
	-- CONDITION HELPERS
	-- ═══════════════════════════════════════════════════════

	-- Total sum of all purchased upgrades
	local function totalUpgrades()
		local total = 0
		for _, val in ipairs(Upgrades:GetChildren()) do
			if val:IsA("IntValue") or val:IsA("NumberValue") then
				total += val.Value
			end
		end
		return total
	end

	-- Returns list of BaseParts from the player's ingredients in the world
	local function getPlayerIngredientParts()
		local folder = PlayerIngredients:FindFirstChild(tostring(Player.UserId))
		if not folder then return {} end
		local parts = {}
		for _, model in ipairs(folder:GetChildren()) do
			local anchor = GetAnchor(model)
			if anchor then table.insert(parts, anchor) end
		end
		return parts
	end

	-- ═══════════════════════════════════════════════════════
	-- LINEAR FLOW WITH RESUME
	-- ═══════════════════════════════════════════════════════
	task.spawn(function()

		OkButton.Visible = false

		local resumePhase = getResumePhase()

		if resumePhase >= 15 then
			TutorialUI.Visible = false
			return
		end

		TutorialUI.Visible = true
		DimFrame.Visible   = false
		Info.Visible       = false

		-- ──────────────────────────────────────────────────
		-- PHASE 1  Welcome + teleport to ingredients
		-- ──────────────────────────────────────────────────
		if resumePhase <= 1 then

			task.wait(0.5)
			showInfo("Welcome!\nCollect Ingredients, cook in the Pot and earn Money!",
				255, 255, 255, 0.25, 0.38, "ok")
			showInfo("Spend your Money on Upgrades\nto grow faster!",
				255, 255, 255, 0.25, 0.42, "ok")


			-- Teleport to the ingredient zone
			local ingZone = GetAnchor(IngredientCollection:WaitForChild("DetectionZone"))
			if ingZone then
				Character:PivotTo(ingZone.CFrame * CFrame.new(0, 0, 15))
				workspace.CurrentCamera.CFrame = HRP.CFrame
			end

			-- Beam points to DetectionZone; disappears when the player arrives
			pointBeamsTo(ingZone, 100, 230, 100)
			showInfo("Go to the INGREDIENTS!\nFollow the light beam.",
				255, 255, 255, 0.25, 0.28,
				"condition",
				function()
					if not ingZone then return true end
					return (HRP.Position - ingZone.Position).Magnitude < 30
				end)
			clearBeams()

			task.wait(0.2)
			local ingBefore = Ingredients.Value
			local ingConditionDone = false

			-- Parallel loop: updates beams whenever new ingredients appear in the folder
			task.spawn(function()
				local lastCount = 0
				while not ingConditionDone do
					local ingParts = getPlayerIngredientParts()
					-- Only recreate beams if the count changed (new item appeared or one disappeared)
					if #ingParts ~= lastCount then
						lastCount = #ingParts
						if #ingParts > 0 then
							pointBeamsTo(ingParts, 100, 255, 150)
						else
							clearBeams()
						end
					end
					task.wait(0.3)
				end
			end)

			showInfo("Collect the Ingredients from the ground!\nThey disappear on touch.",
				255, 255, 255, 0.25, 0.30,
				"condition",
				function()
					return Ingredients.Value >= ingBefore + 5
				end)

			ingConditionDone = true
			clearBeams()

			-- Beams to all ingredient upgrade boards
			local boardParts = {}
			for _, board in ipairs(IngUpgradeBoards:GetChildren()) do
				local anchor = GetAnchor(board)
				if anchor then table.insert(boardParts, anchor) end
			end
			pointBeamsTo(boardParts, 255, 220, 80)
			local upgradeBefore = totalUpgrades()
			showInfo("Use the BOARDS around you!\nBuy upgrades to collect faster.",
				255, 255, 255, 0.25, 0.32,
				"condition",
				function() return totalUpgrades() > upgradeBefore end)
			clearBeams()

			StartExtendedTutorial = true
		else
			StartExtendedTutorial = true
		end

		-- ──────────────────────────────────────────────────
		-- PHASE 2  Polling: 1,000 ingredients
		-- ──────────────────────────────────────────────────
		if resumePhase <= 2 then
			showInfo("Great! Now Collect 1,000 Ingredients.",
				255, 255, 255, 0.25, 0.38, "ok")

			repeat task.wait(0.5) until Ingredients.Value >= 1000
			completeStep(StepObjects.First, "FirstStep")
		end

		-- ──────────────────────────────────────────────────
		-- PHASE 3  Teach Rebirth (ingredients)
		-- ──────────────────────────────────────────────────
		if resumePhase <= 3 then		
			local rebirthAnchor = GetAnchor(IngUpgradeBoards:FindFirstChild("RebirthsForIngredients"))
			pointBeamsTo(rebirthAnchor, 100, 220, 255)
			local rebirthsBefore = Rebirths.Value
			showInfo("REBIRTH: spend Ingredients to gain permanent bonuses!\nGo to the REBIRTH board and click 'Buy'.",
				255, 255, 255, 0.25, 0.38,
				"condition",
				function() return Rebirths.Value > rebirthsBefore end)
			clearBeams()
		end

		-- ──────────────────────────────────────────────────
		-- PHASE 4  Teach Multiplier
		-- ──────────────────────────────────────────────────
		if resumePhase <= 4 then
			local multiAnchor = GetAnchor(IngUpgradeBoards:FindFirstChild("MultiplyIngredientsPerCollect"))
			pointBeamsTo(multiAnchor, 255, 220, 80)
			local multiObj    = Upgrades:FindFirstChild("MultiplyIngredientsPerCollect")
			local multiBefore = multiObj and multiObj.Value or 0
			showInfo("Buy the MULTIPLIER!\n'Multiply Ingredients Per Collect' — board nearby.",
				255, 255, 255, 0.25, 0.32,
				"condition",
				function() return multiObj and multiObj.Value > multiBefore end)
			clearBeams()

			showInfo("Multiplier purchased!\nNow collect 1,500 Ingredients.",
				255, 255, 255, 0.25, 0.38, "ok")
		end

		-- ──────────────────────────────────────────────────
		-- PHASE 5  Polling: 1,500 ingredients (SubStep First)
		-- ──────────────────────────────────────────────────
		if resumePhase <= 5 then
			if resumePhase == 5 then
				showInfo("Great! Now Collect 1,500 Ingredients.",
					255, 255, 255, 0.25, 0.38, "ok")
			end

			repeat task.wait(0.5) until Ingredients.Value >= 1500

			completeSubStep(StepObjects.First, "FirstStep")
			CurrentEndingTip = ExtendedTutorialModule.Steps.FirstStep.EndingTip
			EndingTipTimer   = 8

			-- Beam points to the Pot; yields until the player gets close
			pointBeamsTo(CookingPot, 255, 180, 60)
			showInfo("Great! Now head to the Big Pot!\nFollow the beam.",
				255, 255, 255, 0.48, 0.38,
				"condition",
				function()
					return (HRP.Position - CookingPot.Position).Magnitude < 20
				end)
			clearBeams()
		end

		-- ──────────────────────────────────────────────────
		-- PHASE 6  Teleport + teach cooking
		-- ──────────────────────────────────────────────────
		if resumePhase <= 6 then

			-- Explain the pot
			-- Beams to all SpotIndication parts inside CookingSpots
			local CookingSpots = FoodCollection:WaitForChild("CookingPot"):WaitForChild("CookingSpots")
			local spotParts = {}
			for _, desc in ipairs(CookingSpots:GetDescendants()) do
				if desc:IsA("UnionOperation") and desc.Name == "SpotIndication" then
					table.insert(spotParts, desc)
				end
			end
			pointBeamsTo(spotParts, 255, 180, 60)

			showInfo("This is the BIG POT!\nStay nearby to cook automatically.",
				255, 255, 255, 0.25, 0.38,
				"condition",
				function()
					return (Character:GetAttribute("UsingCooker") == true)
						and (Character:GetAttribute("CookingSpotOccupying") ~= "None")
				end)
			clearBeams()

			repeat task.wait(0.5) until FoodVal.Value >= 10

			-- Beams to all Pot boards; yields until any upgrade is purchased
			local potBoardParts = {}
			for _, board in ipairs(FoodUpgradeBoards:GetChildren()) do
				local anchor = GetAnchor(board)
				if anchor then table.insert(potBoardParts, anchor) end
			end
			clearBeams()
			pointBeamsTo(potBoardParts, 255, 255, 255)
			local potUpgradeBefore = totalUpgrades()
			showInfo("Buy 'Food Per Ingredients' and 'Cooking Speed'\nfrom the boards around you!",
				255, 255, 255, 0.25, 0.40,
				"condition",
				function() return totalUpgrades() > potUpgradeBefore end)
			clearBeams()
		end

		-- ──────────────────────────────────────────────────
		-- PHASE 7  Polling: 1,000 food
		-- ──────────────────────────────────────────────────
		if resumePhase <= 7 then
			if resumePhase == 7 then
				showInfo("Cook 1,000 Food in the Pot!\nCheck the Quest Bar above.",
					255, 255, 255, 0.25, 0.38, "ok")
			end
			repeat task.wait(0.5) until FoodVal.Value >= 1000
			completeStep(StepObjects.Second, "SecondStep")
		end

		-- ──────────────────────────────────────────────────
		-- PHASE 8  Teach Food Rebirth
		-- ──────────────────────────────────────────────────
		if resumePhase <= 8 then

			local foodRebirthAnchor = GetAnchor(FoodUpgradeBoards:FindFirstChild("RebirthsForFood"))
			pointBeamsTo(foodRebirthAnchor, 100, 220, 255)
			local rebirthsBeforeFood = Rebirths.Value
			showInfo("FOOD REBIRTH: spend Food to gain more bonuses!\nGo to the REBIRTH board near the Pot.",
				255, 255, 255, 0.25, 0.38,
				"condition",
				function() return Rebirths.Value > rebirthsBeforeFood end)
			clearBeams()

			showInfo("Now cook 45,000 Food!\nCheck the Quest Bar above.",
				255, 255, 255, 0.48, 0.38, "ok")
		end

		-- ──────────────────────────────────────────────────
		-- PHASE 9  Polling: 45,000 food (SubStep Second)
		-- ──────────────────────────────────────────────────
		if resumePhase <= 9 then
			if resumePhase == 9 then
				showInfo("Cook 45,000 Food!\nCheck the Quest Bar above.",
					255, 255, 255, 0.25, 0.38, "ok")
			end
			repeat task.wait(0.5) until FoodVal.Value >= 45000
			completeSubStep(StepObjects.Second, "SecondStep")
			CurrentEndingTip = ExtendedTutorialModule.Steps.SecondStep.EndingTip
			EndingTipTimer   = 8
		end

		-- ──────────────────────────────────────────────────
		-- PHASE 10  Popup → buy Farmers Market
		-- ──────────────────────────────────────────────────
		if resumePhase <= 10 then

			local fmAnchor    = GetAnchor(FMSkillTreeFolder)
			local fmUnlockVal = FarmersMarketSkillTree:WaitForChild("UnlockFarmersMarket")
			pointBeamsTo(fmAnchor, 255, 230, 80)
			showInfo("Go to the SKILL TREE and buy 'Unlock Farmers Market'!\nFollow the light beam.",
				255, 255, 255, 0.52, 0.40,
				"condition",
				function() return fmUnlockVal.Value == true end)
			clearBeams()
		end

		-- ──────────────────────────────────────────────────
		-- PHASE 11  Farmers Market unlocked (SubStep Third)
		-- ──────────────────────────────────────────────────
		if resumePhase <= 11 then
			-- Resume directly at this phase: still needs to wait for unlock
			if resumePhase == 11 then
				local fmAnchor    = GetAnchor(FMSkillTreeFolder)
				local fmUnlockVal = FarmersMarketSkillTree:WaitForChild("UnlockFarmersMarket")
				pointBeamsTo(fmAnchor, 255, 230, 80)
				showInfo("Go to the SKILL TREE and buy 'Unlock Farmers Market'!\nFollow the light beam.",
					255, 255, 255, 0.1, 0.40,
					"condition",
					function() return fmUnlockVal.Value == true end)
				clearBeams()
			end

			completeStep(StepObjects.Third, "ThirdStep")

			task.wait(0.3)
			showInfo("FARMERS MARKET UNLOCKED!\nBuy powerful multipliers here.",
				255, 255, 255, 0.25, 0.40, "ok")
			showInfo("Step on the Skill Tree nodes\nto unlock bonuses for Ingredients, Food and Money!",
				255, 255, 255, 0.25, 0.42, "ok")

			completeSubStep(StepObjects.Third, "ThirdStep")
			CurrentEndingTip = ExtendedTutorialModule.Steps.ThirdStep.EndingTip
			EndingTipTimer   = 8
		end

		-- ──────────────────────────────────────────────────
		-- PHASE 12  Polling: 250,000 Cash
		-- ──────────────────────────────────────────────────
		if resumePhase <= 12 then
			showInfo("Sell Food at the Farmers Market!\nGoal: 250,000 Money.",
				255, 255, 255, 0.25, 0.38, "ok")
			repeat task.wait(0.5) until CashVal.Value >= 250000
			completeStep(StepObjects.Fourth, "FourthStep")
		end

		-- ──────────────────────────────────────────────────
		-- PHASE 13  Popup + polling → UnlockRestaurant (SubStep Fourth)
		-- ──────────────────────────────────────────────────
		if resumePhase <= 13 then

			local restSkillTree = PlayerPlot:FindFirstChild("RestaurantSkillTree")
			local restAnchor    = GetAnchor(restSkillTree)
			local restUnlockVal = PlayerStats.RestaurantSkillTree:WaitForChild("UnlockRestaurant")
			pointBeamsTo(restAnchor, 255, 150, 50)
			showInfo("250,000 Money!\nUnlock the RESTAURANT on your Plot — follow the beam.",
				255, 255, 255, 0.25, 0.40,
				"condition",
				function() return restUnlockVal.Value == true end)
			clearBeams()

			completeSubStep(StepObjects.Fourth, "FourthStep")
		end

		-- ──────────────────────────────────────────────────
		-- PHASE 14  Conclusion
		-- ──────────────────────────────────────────────────
		task.wait(0.3)
		showInfo("RESTAURANT UNLOCKED!\nTutorial complete!",
			255, 255, 255, 0.25, 0.40, "ok")
		showInfo("The loop: Ingredients → Pot → Food → Money → Upgrades",
			255, 255, 255, 0.25, 0.44, "ok")
		showInfo("Use the Farmers Market and the Restaurant\nto multiply everything!",
			255, 255, 255, 0.25, 0.44, "ok")

		StepObjects.Fifth.Value = true
		TutorialRemote:FireServer("CompleteStep", "FifthStep")
		task.wait(0.2)
		StepObjects.Fifth:SetAttribute("SubStepComplete", true)
		TutorialRemote:FireServer("CompleteSubStep", "FifthStep")

		CurrentEndingTip = ExtendedTutorialModule.Steps.FifthStep.EndingTip
		EndingTipTimer   = 8

		StartExtendedTutorial = true
		Info.Visible          = false
		OkButton.Visible      = false
		TutorialUI.Visible    = false

		AvatarEditorService:PromptSetFavorite(78981149061226, Enum.AvatarItemType.Asset, true)
		task.delay(2, function()
			if ExperienceNotifService:CanPromptOptInAsync() then
				ExperienceNotifService:PromptOptIn()
			end
		end)

		TutorialRemote:FireServer("TutorialComplete")

	end) -- end task.spawn
end)    -- end OnClientEvent