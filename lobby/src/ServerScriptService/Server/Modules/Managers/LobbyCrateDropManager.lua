local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local NotificationRemotes = Remotes:WaitForChild("Notification")
local CrateData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("StoredData"):WaitForChild("CrateData"))

local DROP_ATTEMPT_MIN_SECONDS = 35
local DROP_ATTEMPT_MAX_SECONDS = 55
local DROP_CHANCE = 0.35
local DROP_LIFETIME_SECONDS = 32
local DROP_FALL_SECONDS = 1.1
local MAX_ACTIVE_DROPS = 1

local DROP_POINT_FOLDER_NAMES = {
	"LobbyCrateDropPoints",
	"TemporaryCrateDropPoints",
	"CrateDropPoints",
}

local FALL_HEIGHT = 35
local FALL_SPIN_RADIANS = math.rad(360)
local rng = Random.new()
local activeDrops = {}

local function sendNotification(player, message, notificationType)
	if player then
		NotificationRemotes.SendNotification:FireClient(player, message, notificationType or "Info")
	else
		NotificationRemotes.SendNotification:FireAllClients(message, notificationType or "Info")
	end
end

local function getCurrentSeasonalCrateName()
	if type(CrateData.ResolveBannerName) == "function" then
		return CrateData.ResolveBannerName("Temporary", os.time())
	end

	local order = CrateData.TemporaryBannerOrder
	if type(order) == "table" and #order > 0 then
		return order[1]
	end

	return "Normal"
end

local function getFirstBasePart(root)
	if root:IsA("BasePart") then
		return root
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BasePart") then
			return descendant
		end
	end

	return nil
end

local function prepareCrateInstance(crate)
	for _, descendant in ipairs(crate:GetDescendants()) do
		if descendant:IsA("ClickDetector")
			or descendant:IsA("ProximityPrompt")
			or descendant:IsA("BillboardGui")
			or descendant:IsA("Highlight")
			or descendant:IsA("Script")
			or descendant:IsA("LocalScript")
			or descendant:IsA("ModuleScript") then
			descendant:Destroy()
			continue
		end

		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = true
			descendant.CanQuery = true
		end
	end

	if crate:IsA("BasePart") then
		crate.Anchored = true
		crate.CanCollide = false
		crate.CanTouch = true
		crate.CanQuery = true
	end
end

local function addDropHighlight(crate)
	local highlight = Instance.new("Highlight")
	highlight.Name = "LobbyDropHighlight"
	highlight.Adornee = crate
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = crate
end

local function findCrateTemplate(crateName)
	local cratesFolder = workspace:FindFirstChild("Crates")
	if cratesFolder then
		return cratesFolder:FindFirstChild(crateName)
			or cratesFolder:FindFirstChild("Normal")
			or cratesFolder:FindFirstChild("Golden")
			or cratesFolder:FindFirstChildWhichIsA("Model")
			or cratesFolder:FindFirstChildWhichIsA("BasePart")
	end

	local lobbyCrate = workspace:FindFirstChild("Crate")
	if lobbyCrate then
		return lobbyCrate:FindFirstChild("Crate") or lobbyCrate
	end

	return nil
end

local function collectDropPointCFrames()
	local points = {}

	for _, folderName in ipairs(DROP_POINT_FOLDER_NAMES) do
		local folder = workspace:FindFirstChild(folderName)
		if folder then
			for _, descendant in ipairs(folder:GetDescendants()) do
				if descendant:IsA("BasePart") then
					table.insert(points, descendant.CFrame)
				elseif descendant:IsA("Attachment") then
					table.insert(points, descendant.WorldCFrame)
				end
			end
		end
	end

	if #points > 0 then
		return points
	end

	local baseCFrame
	local spawnPos = workspace:FindFirstChild("SpawnPos")
	if spawnPos and spawnPos:IsA("BasePart") then
		baseCFrame = spawnPos.CFrame
	else
		local lobbyCrate = workspace:FindFirstChild("Crate")
		if lobbyCrate and lobbyCrate:IsA("Model") then
			baseCFrame = lobbyCrate:GetPivot()
		elseif lobbyCrate and lobbyCrate:IsA("BasePart") then
			baseCFrame = lobbyCrate.CFrame
		end
	end

	if baseCFrame then
		local offsets = {
			Vector3.new(16, 0, 0),
			Vector3.new(-16, 0, 0),
			Vector3.new(0, 0, 16),
			Vector3.new(0, 0, -16),
			Vector3.new(12, 0, 12),
			Vector3.new(-12, 0, 12),
		}

		for _, offset in ipairs(offsets) do
			table.insert(points, baseCFrame + offset)
		end
	end

	return points
end

local function getRandomDropCFrame()
	local points = collectDropPointCFrames()
	if #points == 0 then
		return nil
	end

	return points[rng:NextInteger(1, #points)]
end

local function getOrCreateActiveFolder()
	local folder = workspace:FindFirstChild("LobbyCrateDrops")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "LobbyCrateDrops"
		folder.Parent = workspace
	end

	return folder
end

local function animateDrop(crate, targetCFrame)
	local startCFrame = targetCFrame + Vector3.new(0, FALL_HEIGHT, 0)
	local elapsed = 0

	crate:PivotTo(startCFrame)

	while crate.Parent and elapsed < DROP_FALL_SECONDS do
		elapsed += RunService.Heartbeat:Wait()
		local alpha = math.clamp(elapsed / DROP_FALL_SECONDS, 0, 1)
		local eased = 1 - ((1 - alpha) ^ 3)
		local spin = CFrame.Angles(0, FALL_SPIN_RADIANS * (1 - eased), 0)

		crate:PivotTo(startCFrame:Lerp(targetCFrame, eased) * spin)
	end

	if crate.Parent then
		crate:PivotTo(targetCFrame)
	end
end

local function addBillboard(interactPart, crateName)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "LobbyDropBillboard"
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(260, 78)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	billboard.Parent = interactPart

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0.58, 0)
	title.Font = Enum.Font.GothamBlack
	title.Text = crateName
	title.TextColor3 = Color3.fromRGB(255, 235, 80)
	title.TextScaled = true
	title.TextStrokeTransparency = 0
	title.Parent = billboard

	local timer = Instance.new("TextLabel")
	timer.Name = "Timer"
	timer.BackgroundTransparency = 1
	timer.Position = UDim2.new(0, 0, 0.58, 0)
	timer.Size = UDim2.new(1, 0, 0.42, 0)
	timer.Font = Enum.Font.GothamBold
	timer.Text = "CLAIM"
	timer.TextColor3 = Color3.fromRGB(255, 255, 255)
	timer.TextScaled = true
	timer.TextStrokeTransparency = 0
	timer.Parent = billboard

	return timer
end

local function addPrompt(interactPart, crateName)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ClaimLobbyDropPrompt"
	prompt.ActionText = "Claim"
	prompt.ObjectText = crateName
	prompt.HoldDuration = 0.15
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 12
	prompt.Parent = interactPart

	local clickDetector = Instance.new("ClickDetector")
	clickDetector.Name = "ClaimLobbyDropClick"
	clickDetector.MaxActivationDistance = 24
	clickDetector.Parent = interactPart

	return prompt, clickDetector
end

local function giveSeasonalCrate(player, crateName)
	local userData = player:FindFirstChild("UserData")
	if not userData then
		return false
	end

	local crates = userData:FindFirstChild("Crates")
	if not crates then
		return false
	end

	local crateValue = crates:FindFirstChild(crateName)
	if not crateValue then
		crateValue = Instance.new("IntValue")
		crateValue.Name = crateName
		crateValue.Parent = crates
	end

	crateValue.Value += 1
	sendNotification(player, "You claimed 1x " .. crateName .. " from the lobby drop!", "Success")
	return true
end

local function spawnLobbyDrop()
	local seasonalCrateName = getCurrentSeasonalCrateName()
	local template = findCrateTemplate(seasonalCrateName)
	local targetCFrame = getRandomDropCFrame()

	if not template or not targetCFrame then
		warn("[LobbyCrateDropManager] Missing crate template or drop point.")
		return
	end

	local crate = template:Clone()
	crate.Name = "LobbyDrop_" .. seasonalCrateName
	prepareCrateInstance(crate)

	local interactPart = getFirstBasePart(crate)
	if not interactPart then
		crate:Destroy()
		warn("[LobbyCrateDropManager] Crate template has no BasePart:", template:GetFullName())
		return
	end

	local activeFolder = getOrCreateActiveFolder()
	crate.Parent = activeFolder
	addDropHighlight(crate)
	table.insert(activeDrops, crate)

	local timerLabel = addBillboard(interactPart, seasonalCrateName)
	local prompt, clickDetector = addPrompt(interactPart, seasonalCrateName)
	local claimed = false
	local connections = {}

	local function cleanup()
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end

		for index, activeDrop in ipairs(activeDrops) do
			if activeDrop == crate then
				table.remove(activeDrops, index)
				break
			end
		end

		if crate and crate.Parent then
			crate:Destroy()
		end
	end

	local function claim(player)
		if claimed or not player then
			return
		end

		if giveSeasonalCrate(player, seasonalCrateName) then
			claimed = true
			cleanup()
		end
	end

	table.insert(connections, prompt.Triggered:Connect(claim))
	table.insert(connections, clickDetector.MouseClick:Connect(claim))
	table.insert(connections, interactPart.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		claim(player)
	end))

	task.spawn(function()
		animateDrop(crate, targetCFrame)
	end)

	sendNotification(nil, "A seasonal supply crate dropped in the lobby!", "Info")

	task.spawn(function()
		local endTime = os.clock() + DROP_LIFETIME_SECONDS

		while crate.Parent and not claimed and os.clock() < endTime do
			local remaining = math.max(0, math.ceil(endTime - os.clock()))
			timerLabel.Text = tostring(remaining) .. "s"
			task.wait(1)
		end

		if not claimed then
			cleanup()
		end
	end)
end

task.spawn(function()
	task.wait(10)

	while true do
		task.wait(rng:NextInteger(DROP_ATTEMPT_MIN_SECONDS, DROP_ATTEMPT_MAX_SECONDS))

		if #Players:GetPlayers() == 0 then
			continue
		end

		if #activeDrops >= MAX_ACTIVE_DROPS then
			continue
		end

		if rng:NextNumber() <= DROP_CHANCE then
			spawnLobbyDrop()
		end
	end
end)

return {}
