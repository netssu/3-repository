local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage.Remotes
local QuestRemotes = Remotes.Quests
local QuestData = require(ReplicatedStorage.Modules.StoredData.QuestsData)

local function getQuest(player: Player, categoryName: string?, questName: string)
	local userData = player:FindFirstChild("UserData")
	if not userData then
		return nil
	end

	local questsFolder = userData:FindFirstChild("Quests")
	if not questsFolder then
		return nil
	end

	if categoryName and categoryName ~= "" then
		local categoryFolder = questsFolder:FindFirstChild(categoryName)
		local activeFolder = categoryFolder and categoryFolder:FindFirstChild("Active")
		local questFolder = activeFolder and activeFolder:FindFirstChild(questName)

		if questFolder and questFolder:IsA("Folder") then
			return questFolder
		end
	end

	for _, data in ipairs(questsFolder:GetDescendants()) do
		if data:IsA("Folder") and data.Name == questName and data:FindFirstChild("Progress") then
			return data
		end
	end

	return nil
end

local function getQuestDataFromConfig(categoryName, questName)
	local categoryData = QuestData[categoryName]
	if not categoryData then
		return nil
	end

	for _, data in ipairs(categoryData) do
		if data.Name == questName then
			return data
		end
	end

	return nil
end

local function redeemQuest(player: Player, quest: Instance)
	local userData = player:FindFirstChild("UserData")
	if not userData then
		return
	end

	local completedValue = quest:FindFirstChild("Completed")
	local category = quest.Parent and quest.Parent.Parent and quest.Parent.Parent.Name
	local questConfig = category and getQuestDataFromConfig(category, quest.Name) or nil

	if not completedValue or not completedValue:IsA("BoolValue") then
		return
	end

	if completedValue.Value == true then
		Remotes.Notification.SendNotification:FireClient(player, "Already claimed this quest.", "Error")
		return
	end

	if not questConfig then
		return
	end

	local expValue = userData:FindFirstChild("EXP")
	if expValue then
		expValue.Value += questConfig.XP
	end

	local rewardParts = {}

	for rewardType, amount in pairs(questConfig.Rewards or {}) do
		if rewardType == "Cash" or rewardType == "Money" then
			local moneyValue = userData:FindFirstChild("Money")
			if moneyValue then
				moneyValue.Value += amount
			end

			table.insert(rewardParts, "$" .. tostring(amount))
		else
			table.insert(rewardParts, tostring(amount) .. " " .. tostring(rewardType))

			for _, data in ipairs(userData:GetDescendants()) do
				if data:IsA("ValueBase") and data.Name == rewardType and type(data.Value) == "number" then
					data.Value += amount
				end
			end
		end
	end

	completedValue.Value = true

	Remotes.Notification.SendNotification:FireClient(player, "Claimed " .. tostring(questConfig.XP) .. " EXP!", "Success")
	if #rewardParts > 0 then
		Remotes.Notification.SendNotification:FireClient(player, "Claimed " .. table.concat(rewardParts, ", "), "Success")
	end
end

local function checkProgress(player: Player, quest: Instance)
	local progressValue = quest:FindFirstChild("Progress", true)
	local goalAmount = quest:FindFirstChild("Target", true)

	if not progressValue or not goalAmount then
		return false
	end

	if progressValue.Value >= goalAmount.Value then
		redeemQuest(player, quest)
		return true
	end

	return false
end

QuestRemotes.claimQuest.OnServerEvent:Connect(function(player: Player, categoryOrQuestName, maybeQuestName)
	local categoryName = nil
	local questName = nil

	if type(maybeQuestName) == "string" then
		categoryName = categoryOrQuestName
		questName = maybeQuestName
	else
		questName = categoryOrQuestName
	end

	if type(questName) ~= "string" or questName == "" then
		return
	end

	local foundQuest = getQuest(player, categoryName, questName)
	if not foundQuest then
		warn("Cannot find quest " .. questName)
		return
	end

	local isCompleted = checkProgress(player, foundQuest)
	if not isCompleted then
		warn("Cannot claim")
	end
end)

return {}
