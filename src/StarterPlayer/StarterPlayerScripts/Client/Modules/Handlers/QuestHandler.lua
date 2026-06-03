local Handler = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui
local MainGui = PlayerGui:WaitForChild("TD")

local UserData = Player:WaitForChild("UserData")
local QuestsFolder = UserData:WaitForChild("Quests", 5)

local QuestData = require(ReplicatedStorage.Modules.StoredData.QuestsData)
local QuestRemotes = ReplicatedStorage.Remotes:WaitForChild("Quests")

local SelectedCategory = "Daily"

local function isTextObject(obj)
	return obj and (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox"))
end

local function setText(obj, value)
	if isTextObject(obj) then
		obj.Text = tostring(value)
	end
end

local function findByName(root, names, recursive, className)
	if not root then
		return nil
	end

	for _, name in ipairs(names) do
		local found = root:FindFirstChild(name, recursive == true)
		if found then
			if not className or found:IsA(className) then
				return found
			end
		end
	end

	return nil
end

local function resolveQuestUi()
	local frames = MainGui:WaitForChild("Frames")
	local questsFrame = frames:WaitForChild("Quests")
	local questsBg = questsFrame:FindFirstChild("QuestsBG") or questsFrame
	local listScrolling = questsBg:FindFirstChild("ListScrollingFrame")
		or questsBg:FindFirstChild("ScrollingFrame")
		or questsFrame:FindFirstChild("ListScrollingFrame", true)
		or questsFrame:FindFirstChild("ScrollingFrame", true)
	local template = listScrolling and listScrolling:FindFirstChild("Template")
	local questTypeFr = questsBg:FindFirstChild("QuestTypeFR")
		or questsFrame:FindFirstChild("QuestTypeFR", true)
		or questsFrame:FindFirstChild("Holder", true)

	return {
		Frame = questsFrame,
		ListScrolling = listScrolling,
		Template = template,
		DailyButton = questTypeFr and findByName(questTypeFr, { "Daily" }, false, "GuiButton") or nil,
		WeeklyButton = questTypeFr and findByName(questTypeFr, { "Weekly" }, false, "GuiButton") or nil,
		MonthlyButton = questTypeFr and findByName(questTypeFr, { "Monthly", "Montly" }, false, "GuiButton") or nil,
		CloseButton = findByName(questsFrame, { "Close", "CloseBT", "CloseButtonBT" }, true, "GuiButton"),
	}
end

local UI = resolveQuestUi()

local function getQuestConfig(categoryName, questName)
	local categoryData = QuestData[categoryName]
	if not categoryData then
		return nil
	end

	for _, quest in ipairs(categoryData) do
		if quest.Name == questName then
			return quest
		end
	end

	return nil
end

local function formatRewardText(categoryName, questName)
	local questConfig = getQuestConfig(categoryName, questName)
	if not questConfig then
		return ""
	end

	local rewardParts = {}

	for rewardType, amount in pairs(questConfig.Rewards or {}) do
		if rewardType == "Cash" or rewardType == "Money" then
			table.insert(rewardParts, "$" .. tostring(amount))
		else
			table.insert(rewardParts, tostring(amount) .. " " .. tostring(rewardType))
		end
	end

	if questConfig.XP and questConfig.XP > 0 then
		table.insert(rewardParts, tostring(questConfig.XP) .. " XP")
	end

	return table.concat(rewardParts, " + ")
end

local function clearList()
	if not UI.ListScrolling then
		return
	end

	if UI.Template and UI.Template:IsA("GuiObject") then
		UI.Template.Visible = false
	end

	for _, child in ipairs(UI.ListScrolling:GetChildren()) do
		if child == UI.Template then
			continue
		end

		if child:IsA("UIListLayout")
			or child:IsA("UIGridLayout")
			or child:IsA("UIPadding")
			or child:IsA("UICorner")
			or child:IsA("UIStroke")
			or child:IsA("UIAspectRatioConstraint")
			or child:IsA("UISizeConstraint")
		then
			continue
		end

		child:Destroy()
	end
end

local function updateClaimButtonVisual(button, claimable, claimed)
	if not button then
		return
	end

	button.Visible = claimable and not claimed
	button.Active = claimable and not claimed
	button.AutoButtonColor = claimable and not claimed

	local textLabel = findByName(button, { "MainText", "TextLabel", "TX", "ClaimTX" }, true)
	if textLabel then
		if claimed then
			textLabel.Text = "Claimed!"
		else
			textLabel.Text = "Claim"
		end
	elseif button:IsA("TextButton") then
		if claimed then
			button.Text = "Claimed!"
		else
			button.Text = "Claim"
		end
	end

	if button:IsA("ImageButton") then
		if claimed then
			button.ImageColor3 = Color3.fromRGB(125, 125, 125)
		elseif claimable then
			button.ImageColor3 = Color3.fromRGB(0, 255, 127)
		else
			button.ImageColor3 = Color3.fromRGB(255, 255, 255)
		end
	end

	local buttonStroke = button:FindFirstChild("UIStroke")
	if buttonStroke and buttonStroke:IsA("UIStroke") then
		if claimed then
			buttonStroke.Color = Color3.fromRGB(75, 75, 75)
		elseif claimable then
			buttonStroke.Color = Color3.fromRGB(0, 115, 56)
		end
	end

	if textLabel then
		local textStroke = textLabel:FindFirstChild("UIStroke")
		if textStroke and textStroke:IsA("UIStroke") then
			if claimed then
				textStroke.Color = Color3.fromRGB(75, 75, 75)
			elseif claimable then
				textStroke.Color = Color3.fromRGB(0, 115, 56)
			end
		end
	end
end

local function addQuestEntry(questFolder, categoryName)
	if not UI.Template or not UI.ListScrolling then
		return
	end

	local newEntry = UI.Template:Clone()
	newEntry.Name = questFolder.Name
	newEntry.Visible = true
	newEntry.Parent = UI.ListScrolling

	local claimButton = findByName(newEntry, { "Claim" }, true, "GuiButton")
	local questDescription = findByName(newEntry, { "QuestDescriptionTX", "QuestDescription", "DescriptionTX", "Desc" }, true)
	local questName = findByName(newEntry, { "QuestNameTX", "QuestName", "Title", "NameTX" }, true)
	local questProgress = findByName(newEntry, { "QuestProgress", "QuestProgressTX", "QuestProgresssTX", "ProgressTX" }, true)
	local rewardBg = findByName(newEntry, { "RewardBG" }, true)
	local rewardText = (rewardBg and findByName(rewardBg, { "RewardTX", "RewardsTX", "TX", "TextLabel" }, true))
		or findByName(newEntry, { "RewardTX", "RewardsTX" }, true)
	local barBg = findByName(newEntry, { "BarBG", "ProgressBar" }, true)
	local greenBar = (barBg and findByName(barBg, { "GreenBarBG", "Bar", "Fill" }, true))
		or findByName(newEntry, { "GreenBarBG" }, true)

	local progressValue = questFolder:FindFirstChild("Progress")
	local targetValue = questFolder:FindFirstChild("Target")
	local completedValue = questFolder:FindFirstChild("Completed")
	local descriptionValue = questFolder:FindFirstChild("Description")

	setText(questName, questFolder.Name)
	setText(questDescription, descriptionValue and descriptionValue.Value or "")
	setText(rewardText, formatRewardText(categoryName, questFolder.Name))

	if barBg and barBg:IsA("GuiObject") then
		barBg.ClipsDescendants = true
	end

	if greenBar and greenBar:IsA("GuiObject") then
		greenBar.AnchorPoint = Vector2.new(0, 0.5)
		greenBar.Position = UDim2.new(0, 0, 0.5, 0)
	end

	if claimButton and not CollectionService:HasTag(claimButton, "Button") then
		CollectionService:AddTag(claimButton, "Button")
	end

	local function updateProgress()
		local progress = progressValue and progressValue.Value or 0
		local target = targetValue and math.max(targetValue.Value, 1) or 1
		local claimed = completedValue and completedValue.Value or false
		local percent = math.clamp(progress / target, 0, 1)

		if claimed then
			percent = 1
		end

		setText(questProgress, string.format("%d%%", math.floor(percent * 100 + 0.5)))

		if greenBar then
			greenBar.AnchorPoint = Vector2.new(0, 0.5)
			greenBar.Position = UDim2.new(0, 0, 0.5, 0)

			TweenService:Create(
				greenBar,
				TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Size = UDim2.new(percent, 0, greenBar.Size.Y.Scale, greenBar.Size.Y.Offset),
				}
			):Play()
		end

		updateClaimButtonVisual(claimButton, progress >= target, claimed)
	end

	if progressValue then
		progressValue:GetPropertyChangedSignal("Value"):Connect(updateProgress)
	end

	if targetValue then
		targetValue:GetPropertyChangedSignal("Value"):Connect(updateProgress)
	end

	if completedValue then
		completedValue:GetPropertyChangedSignal("Value"):Connect(updateProgress)
	end

	updateProgress()

	if claimButton then
		claimButton.Activated:Connect(function()
			QuestRemotes.claimQuest:FireServer(categoryName, questFolder.Name)
		end)
	end
end

local function gatherAllQuestFolders(parent)
	local quests = {}

	if not parent then
		return quests
	end

	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("Folder") and child:FindFirstChild("Progress") then
			table.insert(quests, child)
		elseif child:IsA("Folder") then
			for _, subQuest in ipairs(gatherAllQuestFolders(child)) do
				table.insert(quests, subQuest)
			end
		end
	end

	return quests
end

local function refreshQuests()
	clearList()

	local categoryFolder = QuestsFolder and QuestsFolder:FindFirstChild(SelectedCategory)
	if not categoryFolder then
		return
	end

	local activeFolder = categoryFolder:FindFirstChild("Active")
	if not activeFolder then
		return
	end

	local quests = gatherAllQuestFolders(activeFolder)
	table.sort(quests, function(a, b)
		local aCompleted = a:FindFirstChild("Completed")
		local bCompleted = b:FindFirstChild("Completed")

		if aCompleted and bCompleted and aCompleted.Value ~= bCompleted.Value then
			return not aCompleted.Value
		end

		return a.Name < b.Name
	end)

	for _, questFolder in ipairs(quests) do
		addQuestEntry(questFolder, SelectedCategory)
	end
end

local ConnectedFolders = {}

local function connectFolder(folder)
	if not folder or ConnectedFolders[folder] then
		return
	end

	ConnectedFolders[folder] = true

	folder.ChildAdded:Connect(function(child)
		if child:IsA("Folder") then
			connectFolder(child)
		end

		task.wait(0.05)
		refreshQuests()
	end)

	folder.ChildRemoved:Connect(function()
		refreshQuests()
	end)

	for _, sub in ipairs(folder:GetChildren()) do
		if sub:IsA("Folder") then
			connectFolder(sub)
		end
	end
end

local function switchCategory(category)
	if SelectedCategory == category then
		refreshQuests()
		return
	end

	SelectedCategory = category
	refreshQuests()
end

if QuestsFolder then
	connectFolder(QuestsFolder)
end

if UI.DailyButton then
	UI.DailyButton.Activated:Connect(function()
		switchCategory("Daily")
	end)
end

if UI.WeeklyButton then
	UI.WeeklyButton.Activated:Connect(function()
		switchCategory("Weekly")
	end)
end

if UI.MonthlyButton then
	UI.MonthlyButton.Activated:Connect(function()
		switchCategory("Monthly")
	end)
end

if UI.CloseButton and not UI.CloseButton:GetAttribute("FrameName") then
	UI.CloseButton.Activated:Connect(function()
		if UI.Frame.Visible then
			UI.Frame.Visible = false
		end
	end)
end

if UI.Frame then
	UI.Frame:GetPropertyChangedSignal("Visible"):Connect(function()
		if UI.Frame.Visible then
			refreshQuests()
		end
	end)
end

refreshQuests()

return Handler
