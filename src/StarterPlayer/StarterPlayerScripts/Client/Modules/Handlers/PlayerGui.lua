------------------//SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")

------------------//VARIABLES
local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local replicatedStorage = game.ReplicatedStorage
local modules = replicatedStorage:WaitForChild("Modules")
local storedData = modules:WaitForChild("StoredData")

local Digits = require(replicatedStorage.Modules.Utility.Digits)
local GuiManager = require(script.Parent.Parent.Managers.GuiManager)
local TowerData = require(storedData:WaitForChild("TowerData"))

local mainGui = playerGui:WaitForChild("TD")
local leftGui = mainGui:WaitForChild("Left")

local requestGui = mainGui:WaitForChild("Request")
local playerIcon = requestGui:WaitForChild("PlayerIcon")
local usernameText = requestGui:WaitForChild("Username")
local acceptButton = requestGui:WaitForChild("Accept")
local rejectButton = requestGui:WaitForChild("Reject")

local remotes = replicatedStorage:WaitForChild("Remotes")

------------------//FUNCTIONS
local function getUserData(): Folder
	return player:WaitForChild("UserData")
end

local function getSavedDifficulty(): string
	local userData = getUserData()
	local mapFolder = userData:FindFirstChild("Map")
	if mapFolder then
		local diff = mapFolder:FindFirstChild("Difficulty")
		if diff and diff:IsA("StringValue") then
			return diff.Value
		end
		if diff and (diff:IsA("IntValue") or diff:IsA("NumberValue")) then
			return tostring(diff.Value)
		end
	end

	local attr = player:GetAttribute("Difficulty")
	if attr ~= nil then
		return tostring(attr)
	end

	return "Easy"
end

local function handleZone(): ()
	local level10Gate = workspace:WaitForChild("Level10Gate")
	local userData = getUserData()
	local level = userData:WaitForChild("Level")

	if level.Value >= 5 then
		playerGui.TD.Frames.GameModes.Holder.Pvp.Locked.Visible = false
		playerGui.TD.Frames.GameModes.Holder.Pvp.Interactable = true
	end

	if level.Value >= 10 then
		level10Gate:Destroy()
		playerGui.TD.Frames.GameModes.Holder.Endless.Locked.Visible = false
		playerGui.TD.Frames.GameModes.Holder.Endless.Interactable = true
	end
end

local function sendNotification(text: string, type: string): ()
	local notification = mainGui:WaitForChild("Notifications")
	local template = notification:WaitForChild("Template"):Clone()
	local targetSize = UDim2.new(1, 0, 0.75, 0)
	local startingSize = UDim2.new(0, 0, 0, 0)

	template.Text = text

	if type == "Error" then
		template.TextColor3 = Color3.fromRGB(255, 0, 0)
	elseif type == "Normal" then
		template.TextColor3 = Color3.fromRGB(255, 255, 255)
	elseif type == "Success" then
		template.TextColor3 = Color3.fromRGB(0, 255, 0)
	end

	template.Size = startingSize

	local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Back)
	local tweenIn = TweenService:Create(template, tweenInfo, { Size = targetSize })
	local tweenOut = TweenService:Create(template, tweenInfo, { Size = startingSize })

	template.Parent = notification
	template.Visible = true

	tweenIn:Play()

	task.spawn(function()
		task.wait(5)
		tweenOut:Play()
		tweenOut.Completed:Connect(function()
			template:Destroy()
		end)
	end)
end

local function getSavedMap(): string
	local userData = getUserData()
	local mapFolder = userData:FindFirstChild("Map")

	if mapFolder then
		local lvl = mapFolder:FindFirstChild("Level")
		if lvl and lvl:IsA("StringValue") then
			return lvl.Value
		end
	end

	local attr = player:GetAttribute("MapLevel")
	if attr ~= nil then
		return tostring(attr)
	end

	return "Tutorial"
end

local function preloadUI(): ()
	local assets = {}

	for _, descendant in ipairs(mainGui:GetDescendants()) do
		if descendant:IsA("ImageLabel") or descendant:IsA("ImageButton") then
			if descendant.Image and descendant.Image ~= "" then
				table.insert(assets, descendant.Image)
			end
		elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
			if descendant.Texture and descendant.Texture ~= "" then
				table.insert(assets, descendant.Texture)
			end
		elseif descendant:IsA("Sound") then
			if descendant.SoundId and descendant.SoundId ~= "" then
				table.insert(assets, descendant.SoundId)
			end
		end
	end

	if #assets > 0 then
		local success, err = pcall(function()
			ContentProvider:PreloadAsync(assets)
		end)
		if not success then
			warn("UI preload failed:", err)
		end
	end
end

local function setupButtonTween(button: GuiButton): ()
	local icon = button:FindFirstChild("Icon")

	local userData = getUserData()
	local sfxEnabled = userData:FindFirstChild("Settings"):FindFirstChild("SFXEnabled")

	local rotationOnEnter = 15
	local rotationOnLeave = 0
	local enterScale = 1.05
	local downScale = 0.9

	if button.Name == "Untouchable" or CollectionService:HasTag(button, "Untouchable") then
		return
	end

	local uiScale = button:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Scale = 1
		uiScale.Parent = button
	end

	local function tweenScale(toScale: number): ()
		TweenService:Create(uiScale, TweenInfo.new(0.1), { Scale = toScale }):Play()
	end

	local function rotateIcon(degrees: number): ()
		if icon then
			TweenService:Create(icon, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Rotation = degrees,
			}):Play()
		end
	end

	button.MouseEnter:Connect(function()
		if sfxEnabled.Value == true then
			game.SoundService.SFX.UI.Hover:Play()
		end
		rotateIcon(rotationOnEnter)
		tweenScale(enterScale)
	end)

	button.MouseLeave:Connect(function()
		rotateIcon(rotationOnLeave)
		tweenScale(1)
	end)

	button.MouseButton1Down:Connect(function()
		tweenScale(downScale)
	end)

	button.MouseButton1Up:Connect(function()
		tweenScale(enterScale)
	end)
end

local function updateStats(): ()
	local userData = getUserData()
	local money = userData:FindFirstChild("Money")
	local moneyGui = leftGui:WaitForChild("Container"):WaitForChild("Cash")
	local moneyAmountText = moneyGui:WaitForChild("Amount")

	money:GetPropertyChangedSignal("Value"):Connect(function()
		moneyAmountText.Text = Digits.AddCommas(money.Value)
	end)

	moneyAmountText.Text = Digits.AddCommas(money.Value)
end

local function setupButtons(): ()
	for _, button in ipairs(mainGui:GetDescendants()) do
		if button:IsA("ImageButton") or button:IsA("TextButton") then
			setupButtonTween(button)

			button.Activated:Connect(function()
				if button.Name == "Level9" then
					sendNotification("You must be level 10 to unlock.", "Error")
				elseif button.Name == "Level15" then
					sendNotification("You must be level 15 to unlock.", "Error")
				end

				local userData = getUserData()
				local sfxEnabled = userData:FindFirstChild("Settings"):FindFirstChild("SFXEnabled")

				if sfxEnabled.Value == true then
					game.SoundService.SFX.UI.ClickSoundEffect:Play()
				end

				local frameName = button:GetAttribute("FrameName")
				if not frameName then
					return
				end

				GuiManager.ToggleUi(frameName)
			end)
		end
	end
end

local function hideAllCore(): ()
	for _, frame in ipairs(mainGui:GetChildren()) do
		if frame:IsA("Frame") then
			frame.Visible = false
		end
	end
end

local function showAllCore(): ()
	for _, frame in ipairs(mainGui:GetChildren()) do
		if frame:IsA("Frame") and frame.Name ~= "Request" and frame.Name ~= "Searching" then
			frame.Visible = true
		end
	end
end

local activeFrame: Frame? = nil
local currentAnimationId = 0

local function popupFrame(frame: Frame): ()
	currentAnimationId += 1
	local thisAnimationId = currentAnimationId

	GuiManager.ToggleUi("")

	if activeFrame and activeFrame ~= frame then
		activeFrame.Visible = false
	end

	local holder = frame:FindFirstChild("Holder")
	if not holder then
		return
	end

	if frame.Name == "GameModes" then
		task.spawn(function()
			local callback = remotes.Matchmaking.GetPlayerCount:InvokeServer()
			if callback and frame.Visible then
				local pvpButton = holder:FindFirstChild("Pvp")
				local survivalButton = holder:FindFirstChild("Survival")
				if pvpButton then
					pvpButton.PlayCount.Text = callback.PVP .. " Playing"
				end
				if survivalButton then
					survivalButton.PlayCount.Text = callback.Survival .. " Playing"
				end
			end
		end)
	end

	for _, button in ipairs(holder:GetChildren()) do
		if button:IsA("ImageButton") then
			local uiScale = button:FindFirstChildOfClass("UIScale")
			if not uiScale then
				uiScale = Instance.new("UIScale")
				uiScale.Parent = button
			end
			uiScale.Scale = 0.001
		end
	end

	frame.Visible = true
	activeFrame = frame

	task.spawn(function()
		task.wait(0.05)
		for _, button in ipairs(holder:GetChildren()) do
			if thisAnimationId ~= currentAnimationId then
				return
			end

			if button:IsA("ImageButton") then
				local uiScale = button:FindFirstChildOfClass("UIScale")
				if uiScale then
					TweenService:Create(uiScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
					task.wait(0.05)
				end
			end
		end
	end)
end

local function updateSoloLowerText(squadFrame: Frame): ()
	local holder = squadFrame:FindFirstChild("Holder")
	if not holder then return end

	local soloButton = holder:FindFirstChild("Solo")
	if not soloButton then return end

	local lowerText = soloButton:FindFirstChild("LowerText")
	if not lowerText or not lowerText:IsA("TextLabel") then return end

	local userData = getUserData()
	local levelValue = userData:FindFirstChild("Level")
	local playerLevel = (levelValue and levelValue:IsA("NumberValue") and levelValue.Value) or 0

	local mapName = getSavedMap()
	lowerText.Text = mapName .. " - Level " .. tostring(playerLevel)
end

local selectedData = {}

local function handlePlayButton(): ()
	local playButton = mainGui:WaitForChild("Bottom"):WaitForChild("Frame"):WaitForChild("Play")
	local frames = mainGui:WaitForChild("Frames")

	local gamemodeFrame = frames:WaitForChild("GameModes")
	local squadFrame = frames:WaitForChild("Squad")
	local pvpSquadFrame = frames:WaitForChild("PVPSquad")

	local closeGamemode = gamemodeFrame:WaitForChild("Back")
	local closeSquad = squadFrame:WaitForChild("Back")
	local closePVPSquad = pvpSquadFrame:WaitForChild("Back")

	local function getSavedDifficulty(): string
		local userData = getUserData()
		local mapFolder = userData:FindFirstChild("Map")

		if mapFolder then
			local diff = mapFolder:FindFirstChild("Difficulty")
			if diff and diff:IsA("StringValue") then
				return diff.Value
			end
			if diff and (diff:IsA("IntValue") or diff:IsA("NumberValue")) then
				return tostring(diff.Value)
			end
		end

		local attr = player:GetAttribute("Difficulty")
		if attr ~= nil then
			return tostring(attr)
		end

		return "Easy"
	end

	local function getSavedMap(): string
		local userData = getUserData()
		local mapFolder = userData:FindFirstChild("Map")

		if mapFolder then
			local lvl = mapFolder:FindFirstChild("Level")
			if lvl and lvl:IsA("StringValue") then
				return lvl.Value
			end
		end

		local attr = player:GetAttribute("MapLevel")
		if attr ~= nil then
			return tostring(attr)
		end

		return "Tutorial"
	end

	local function updateSurvivalLowerText(): ()
		local holder = gamemodeFrame:FindFirstChild("Holder")
		if not holder then return end

		local survivalButton = holder:FindFirstChild("Survival")
		if not survivalButton then return end

		local lowerText = survivalButton:FindFirstChild("LowerText")
		if not lowerText or not lowerText:IsA("TextLabel") then return end

		local userData = getUserData()
		local levelValue = userData.Map:FindFirstChild("Difficulty")
		local playerLevel = levelValue and levelValue.Value or ""

		local mapName = getSavedMap()
		lowerText.Text = mapName .. " - Level " .. tostring(playerLevel)
	end

	updateSurvivalLowerText()

	do
		local userData = getUserData()
		local levelValue = userData:FindFirstChild("Level")
		if levelValue and (levelValue:IsA("IntValue") or levelValue:IsA("NumberValue")) then
			levelValue:GetPropertyChangedSignal("Value"):Connect(updateSurvivalLowerText)
		end

		local mapFolder = userData:FindFirstChild("Map")
		if mapFolder then
			local mapLevel = mapFolder:FindFirstChild("Level")
			if mapLevel and mapLevel:IsA("StringValue") then
				mapLevel:GetPropertyChangedSignal("Value"):Connect(updateSurvivalLowerText)
			end
		end
	end

	local function requestQueue(): ()
		selectedData.Difficulty = getSavedDifficulty()
		selectedData.Map = getSavedMap()
		remotes.Matchmaking.RequestQueue:FireServer(selectedData)
		activeFrame = nil
		showAllCore()
	end

	closeGamemode.Activated:Connect(function()
		currentAnimationId += 1
		gamemodeFrame.Visible = false
		activeFrame = nil
		showAllCore()
	end)

	closeSquad.Activated:Connect(function()
		squadFrame.Visible = false
		hideAllCore()
		popupFrame(gamemodeFrame)
	end)

	closePVPSquad.Activated:Connect(function()
		pvpSquadFrame.Visible = false
		hideAllCore()
		popupFrame(gamemodeFrame)
	end)

	playButton.Activated:Connect(function()
		hideAllCore()
		updateSurvivalLowerText()
		popupFrame(gamemodeFrame)
	end)

	local modeHolder = gamemodeFrame:WaitForChild("Holder")
	for _, modeButton in ipairs(modeHolder:GetChildren()) do
		if modeButton:IsA("ImageButton") then
			modeButton.Activated:Connect(function()
				selectedData.Gamemode = modeButton.Name
				gamemodeFrame.Visible = false

				if selectedData.Gamemode == "Pvp" then
					popupFrame(pvpSquadFrame)
				else
					popupFrame(squadFrame)
				end
			end)
		end
	end

	local squadHolder = squadFrame:WaitForChild("Holder")
	for _, squadButton in ipairs(squadHolder:GetChildren()) do
		if squadButton:IsA("ImageButton") then
			squadButton.Activated:Connect(function()
				selectedData.Squad = squadButton.Name
				squadFrame.Visible = false
				requestQueue()
			end)
		end
	end

	local pvpSquadHolder = pvpSquadFrame:WaitForChild("Holder")
	for _, pvpButton in ipairs(pvpSquadHolder:GetChildren()) do
		if pvpButton:IsA("ImageButton") then
			pvpButton.Activated:Connect(function()
				selectedData.Squad = pvpButton.Name
				pvpSquadFrame.Visible = false
				requestQueue()
			end)
		end
	end
end
local function updateHotbarSlot(slot, hotBar, towerData): ()
	local slotNumber = slot.Name
	local uiSlot = hotBar:FindFirstChild(slotNumber)

	if slot.Value == "" then
		local unitIcon = uiSlot:FindFirstChild("UnitIcon")
		if unitIcon then
			unitIcon.Image = ""
			uiSlot.Holder.Visible = false
		end
		return
	end

	local imageId = towerData[slot.Value] and towerData[slot.Value].ImageId
	local unitIcon = uiSlot:FindFirstChild("UnitIcon")

	uiSlot.Holder.Price.Text = `${towerData[slot.Value].Price}`
	uiSlot.Holder.Visible = true
	unitIcon.Image = "rbxassetid://" .. imageId
end

local function setupHotbar(): ()
	local towerData = require(replicatedStorage:WaitForChild("Modules"):WaitForChild("StoredData"):WaitForChild("TowerData"))
	local userData = getUserData()
	local level = userData:WaitForChild("Level")
	local inventoryFolder = userData:WaitForChild("Hotbar")
	local hotBar = mainGui:WaitForChild("Bottom"):WaitForChild("Hotbar")

	if level.Value >= 15 then
		local level15 = hotBar:WaitForChild("Level15")
		local level9 = hotBar:WaitForChild("Level9")
		local slot5 = hotBar:WaitForChild("5")
		local slot6 = hotBar:WaitForChild("6")
		level15.Visible = false
		level9.Visible = false
		slot5.Visible = true
		slot6.Visible = true
	elseif level.Value >= 10 then
		local level9 = hotBar:WaitForChild("Level9")
		local slot5 = hotBar:WaitForChild("5")
		level9.Visible = false
		slot5.Visible = true
	end

	for _, slot in ipairs(inventoryFolder:GetChildren()) do
		updateHotbarSlot(slot, hotBar, towerData)
	end

	for _, slot in ipairs(inventoryFolder:GetChildren()) do
		slot.Changed:Connect(function()
			updateHotbarSlot(slot, hotBar, towerData)
		end)
	end
end

local function promptTutorial(): ()
	local userData = getUserData()
	local completedTutorial = userData:FindFirstChild("CompletedTutorial")
	local tutorialGui = mainGui:WaitForChild("Frames"):WaitForChild("Tutorial")
	local yesButton = tutorialGui:WaitForChild("Yes")
	local noButton = tutorialGui:WaitForChild("No")

	local tutorialData = {
		["Difficulty"] = getSavedDifficulty(),
		["Gamemode"] = "Survival",
		["Map"] = "Tutorial",
		["Squad"] = "Solo",
	}

	yesButton.Activated:Connect(function()
		tutorialGui.Visible = false
		remotes.Matchmaking.RequestQueue:FireServer(tutorialData)
	end)

	noButton.Activated:Connect(function()
		tutorialGui.Visible = false
		remotes.Game.SkipTutorial:FireServer()
	end)

	if completedTutorial.Value == true then
		return
	end

	task.spawn(function()
		tutorialGui.Visible = true
	end)
end

local function handleBottomVisibility(): ()
	local bottom = mainGui:WaitForChild("Bottom")
	local frames = mainGui:WaitForChild("Frames")

	local function updateBottom(): ()
		local anyVisible = false
		for _, frame in ipairs(frames:GetChildren()) do
			if frame:IsA("Frame") and frame.Visible then
				anyVisible = true
				break
			end
		end
		bottom.Frame.Visible = not anyVisible
	end

	for _, frame in ipairs(frames:GetChildren()) do
		if frame:IsA("Frame") and frame.Name ~= "Searching" then
			frame:GetPropertyChangedSignal("Visible"):Connect(updateBottom)
		end
	end

	updateBottom()
end

local function handleInteractiveZones(): ()
	local touchParts = workspace.TouchParts
	if not touchParts then
		return
	end

	local level10Gate = workspace:FindFirstChild("Level10Gate")
	local cooldowns = {}
	local cooldownTime = 2

	for _, part in ipairs(touchParts:GetChildren()) do
		if part:IsA("UnionOperation") or part:IsA("BasePart") then
			part.Touched:Connect(function(hit)
				local character = hit.Parent
				if not character then
					return
				end

				local touchingPlayer = Players:GetPlayerFromCharacter(character)
				if not touchingPlayer then
					return
				end

				if touchingPlayer == player then
					if cooldowns[part] and tick() - cooldowns[part] < cooldownTime then
						return
					end

					cooldowns[part] = tick()

					if part.Name == "Play" then
						hideAllCore()
						popupFrame(mainGui:WaitForChild("Frames"):WaitForChild("GameModes"))
						return
					elseif part.Name == "Endless" then
						hideAllCore()
						popupFrame(mainGui:WaitForChild("Frames"):WaitForChild("Squad"))
						return
					elseif part.Name == "AFK" then
						playerGui.TD.Frames.AFK.Reward.Text = "Nothing yet!"
						remotes.AFK.BeginAFK:FireServer()
					end

					local target = playerGui.TD.Frames:FindFirstChild(part.Name)
					if target and not target.Visible then
						GuiManager.ToggleUi(part.Name)
					end
				end
			end)
		end
	end

	if level10Gate then
		level10Gate.Touched:Connect(function(hit)
			local character = hit.Parent
			if not character then
				return
			end

			local touchingPlayer = Players:GetPlayerFromCharacter(character)
			if not touchingPlayer then
				return
			end

			if touchingPlayer == player and level10Gate then
				if cooldowns[level10Gate] and tick() - cooldowns[level10Gate] < cooldownTime then
					return
				end

				cooldowns[level10Gate] = tick()
				sendNotification("You must be level 10 to access Endless Mode", "Error")
			end
		end)
	end
end

local function handleLevels(): ()
	local levelData = require(replicatedStorage.Modules.StoredData.LevelData)

	local userData = getUserData()
	local exp = userData:WaitForChild("EXP")
	local level = userData:WaitForChild("Level")

	local levelBarContainer = mainGui:WaitForChild("Bottom"):WaitForChild("ProgressBar")
	local levelLabel = levelBarContainer:WaitForChild("Level")
	local levelBar = levelBarContainer:WaitForChild("Bar")

	local function updateUI(): ()
		local currentLevel = level.Value
		local currentXP = exp.Value
		local maxXP = levelData[tostring(currentLevel)] and levelData[tostring(currentLevel)].MaxXP or 100
		levelLabel.Text = string.format("Level %d [%d/%d]", currentLevel, currentXP, maxXP)
		levelBar.Size = UDim2.new(math.clamp(currentXP / maxXP, 0, 1), 0, 1, 0)
	end

	local function checkLevelUp(): ()
		local currentLevel = level.Value
		local currentXP = exp.Value
		local maxXP = levelData[tostring(currentLevel)] and levelData[tostring(currentLevel)].MaxXP
		if not maxXP then
			return
		end

		while currentXP >= maxXP and currentLevel < 50 do
			currentXP -= maxXP
			currentLevel += 1
			maxXP = levelData[tostring(currentLevel)] and levelData[tostring(currentLevel)].MaxXP
		end

		exp.Value = currentXP
		level.Value = currentLevel
		updateUI()
	end

	exp:GetPropertyChangedSignal("Value"):Connect(function()
		checkLevelUp()
	end)

	level:GetPropertyChangedSignal("Value"):Connect(function()
		updateUI()
	end)

	updateUI()
end

local function handleShop(): ()
	local shopFrame = mainGui:WaitForChild("Frames"):WaitForChild("Shop")
	local categoryButtons = shopFrame:WaitForChild("Holder")
	local moneySection = categoryButtons:WaitForChild("Money")
	local gamepassSection = categoryButtons:WaitForChild("Gamepass")
	local towersSection = categoryButtons:WaitForChild("Towers")
	local scrollingFrame = shopFrame:FindFirstChildOfClass("ScrollingFrame")

	local function scrollTo(positionY: number): ()
		TweenService:Create(scrollingFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CanvasPosition = Vector2.new(0, positionY),
		}):Play()
	end

	moneySection.Activated:Connect(function()
		scrollTo(600)
	end)

	towersSection.Activated:Connect(function()
		scrollTo(0)
	end)

	gamepassSection.Activated:Connect(function()
		scrollTo(200)
	end)
end

local function handleSettings(): ()
	local userData = getUserData()
	local settings = userData:WaitForChild("Settings", 60)
	local settingsFrame = mainGui:WaitForChild("Frames"):WaitForChild("Settings")
	local settingsScroll = settingsFrame:WaitForChild("ScrollingFrame")

	for _, toggleButton in ipairs(settingsScroll:GetDescendants()) do
		if toggleButton:IsA("ImageButton") and toggleButton.Name == "OnOff" then
			local dataName = toggleButton.Parent.Name
			local targetData = settings:FindFirstChild(dataName)
			local mainText = toggleButton:FindFirstChild("MainText")
			local uiStroke = toggleButton:FindFirstChild("UIStroke")

			local function setOff(): ()
				toggleButton.ImageColor3 = Color3.fromRGB(255, 42, 0)
				uiStroke.Color = Color3.fromRGB(107, 16, 0)
				mainText.UIStroke.Color = Color3.fromRGB(107, 16, 0)
				mainText.Text = "Off"

				if dataName == "MusicEnabled" then
					game.SoundService.SFX.BackgroundMusic.Lobby.Volume = 0
				end
			end

			local function setOn(): ()
				toggleButton.ImageColor3 = Color3.fromRGB(89, 255, 0)
				uiStroke.Color = Color3.fromRGB(0, 103, 15)
				mainText.UIStroke.Color = Color3.fromRGB(0, 103, 15)
				mainText.Text = "On"

				if dataName == "MusicEnabled" then
					game.SoundService.SFX.BackgroundMusic.Lobby.Volume = 0.5
				end
			end

			if targetData.Value == true then
				setOn()
			else
				setOff()
			end

			toggleButton.Activated:Connect(function()
				if mainText.Text == "On" then
					setOff()
					remotes.Settings.changeSetting:FireServer(toggleButton.Parent.Name, false)
				else
					setOn()
					remotes.Settings.changeSetting:FireServer(toggleButton.Parent.Name, true)
				end
			end)
		end
	end
end

local function handleDailyRewards(): ()
	local dailyFrame = mainGui:WaitForChild("Frames"):WaitForChild("Daily")
	local streakText = dailyFrame:WaitForChild("Streak")
	local claimButton = dailyFrame:WaitForChild("Claim")

	local days = {
		[1] = dailyFrame:FindFirstChild("Day1"),
		[2] = dailyFrame:FindFirstChild("Day2"),
		[3] = dailyFrame:FindFirstChild("Day3"),
		[4] = dailyFrame:FindFirstChild("Day4"),
		[5] = dailyFrame:FindFirstChild("Day5"),
		[6] = dailyFrame:FindFirstChild("Day6"),
		[7] = dailyFrame:FindFirstChild("Day7"),
	}

	local function updateStreak(): ()
		local userData = getUserData()
		local streakData = userData:WaitForChild("Streak")
		streakText.Text = streakData.Value

		for i = 1, #days do
			if days[i] and days[i]:FindFirstChild("Claimed") then
				days[i].Claimed.Visible = i <= streakData.Value
			end
		end
	end

	claimButton.Activated:Connect(function()
		remotes.Daily.claimReward:FireServer()
		task.spawn(function()
			task.wait(0.5)
			updateStreak()
		end)
	end)

	updateStreak()
end

local function handleBox(): ()
	local goldCrate = workspace:FindFirstChild("Crate")
	local uiPart = goldCrate:FindFirstChild("UIPart")
	local billboard = uiPart:FindFirstChild("BillboardGui")
	local timerLabel = billboard:FindFirstChild("Timer")
	local userData = getUserData()
	local remainingTimer = userData:FindFirstChild("RemainingTimer")

	local function updateLabel(value: number): ()
		if value <= 0 then
			timerLabel.Text = "CLAIM!"
			return
		end

		local hours = math.floor(value / 3600)
		local minutes = math.floor((value % 3600) / 60)
		local seconds = value % 60

		if hours > 0 then
			timerLabel.Text = string.format("%02d:%02d:%02d", hours, minutes, seconds)
		else
			timerLabel.Text = string.format("%02d:%02d", minutes, seconds)
		end
	end

	updateLabel(remainingTimer.Value)
	remainingTimer.Changed:Connect(updateLabel)
end

local function handleAFK(): ()
	local afk = mainGui:WaitForChild("Frames"):WaitForChild("AFK")
	local leaveAFK = afk:WaitForChild("Close")
	local timerText = afk:FindFirstChild("Timer")
	local rewardLabel = afk:FindFirstChild("Reward")

	local currentCountdownId = 0
	local counting = false
	local remainingTime = 0

	local function formatTime(num: number): string
		num = math.floor(num)
		local hours = math.floor(num / 3600)
		local minutes = math.floor((num % 3600) / 60)
		local seconds = num % 60

		if hours > 0 then
			return string.format("%dh %dm %ds", hours, minutes, seconds)
		elseif minutes > 0 then
			return string.format("%dm %ds", minutes, seconds)
		else
			return string.format("%ds", seconds)
		end
	end

	leaveAFK.Activated:Connect(function()
		counting = false
		currentCountdownId += 1
		remotes.AFK.EndAFK:FireServer()
	end)

	remotes.AFK.sendTimer.OnClientEvent:Connect(function(timeValue: number)
		remainingTime = timeValue
		counting = true
		currentCountdownId += 1
		local countdownId = currentCountdownId

		task.spawn(function()
			while counting and remainingTime > 0 and countdownId == currentCountdownId do
				if timerText then
					timerText.Text = formatTime(remainingTime)
				end
				task.wait(1)
				remainingTime -= 1
			end

			if countdownId == currentCountdownId and timerText then
				timerText.Text = "0s"
			end
		end)
	end)

	remotes.AFK.updateRewards.OnClientEvent:Connect(function(rewardText: string)
		if not rewardLabel then
			return
		end

		local currentText = rewardLabel.Text
		if currentText == "Nothing yet!" or currentText == "" then
			rewardLabel.Text = rewardText
			return
		end

		local rewards = {}
		for part in string.gmatch(currentText, "[^,]+") do
			table.insert(rewards, part:match("^%s*(.-)%s*$"))
		end

		local updated = false

		local moneyAmount = rewardText:match("%+%$(%d+)")
		if moneyAmount then
			local newAmount = tonumber(moneyAmount)
			for i, entry in ipairs(rewards) do
				local existingAmount = entry:match("%+%$(%d+)")
				if existingAmount then
					rewards[i] = "+$" .. (tonumber(existingAmount) + newAmount)
					updated = true
					break
				end
			end
			if not updated then
				table.insert(rewards, rewardText)
			end
		else
			local count, name = rewardText:match("(%d+)x%s+(.*)")
			if count and name then
				for i, entry in ipairs(rewards) do
					local existingCount, existingName = entry:match("(%d+)x%s+(.*)")
					if existingName == name then
						rewards[i] = (tonumber(existingCount) + tonumber(count)) .. "x " .. existingName
						updated = true
						break
					end
				end
				if not updated then
					table.insert(rewards, rewardText)
				end
			else
				table.insert(rewards, rewardText)
			end
		end

		rewardLabel.Text = table.concat(rewards, ", ")
	end)
end

local function getLeaderboardRank(): ()
	local leaderboards = workspace.Leaderboards

	local function getRank(leaderboardName: string): string?
		local leaderboard = leaderboards:FindFirstChild(leaderboardName)
		if not leaderboard then
			return nil
		end

		local scrollingFrame = leaderboard:FindFirstChild("Screen"):FindFirstChild("SurfaceGui"):FindFirstChild("ScrollingFrame")
		if not scrollingFrame then
			return nil
		end

		for _, frame in ipairs(scrollingFrame:GetChildren()) do
			if frame.Name == player.Name then
				return frame.Rank.Text
			end
		end

		return nil
	end

	local function handleScrollButtons(leaderboard: Model): ()
		local scrollingFrame = leaderboard:FindFirstChild("Screen"):FindFirstChild("SurfaceGui"):FindFirstChild("ScrollingFrame")
		if not scrollingFrame then
			return
		end

		local upButton = nil
		local downButton = nil

		for _, basePart in ipairs(leaderboard:GetDescendants()) do
			if basePart:IsA("BasePart") then
				if basePart.Name == "ScrollUp" then
					upButton = basePart
				elseif basePart.Name == "ScrollDown" then
					downButton = basePart
				end
			end
		end

		if upButton and not upButton:FindFirstChildOfClass("ClickDetector") then
			local cd = Instance.new("ClickDetector")
			cd.Parent = upButton
			cd.MouseClick:Connect(function()
				scrollingFrame.CanvasPosition = Vector2.new(0, math.max(0, scrollingFrame.CanvasPosition.Y - 1 * scrollingFrame.Template.AbsoluteSize.Y))
			end)
		end

		if downButton and not downButton:FindFirstChildOfClass("ClickDetector") then
			local cd = Instance.new("ClickDetector")
			cd.Parent = downButton
			cd.MouseClick:Connect(function()
				scrollingFrame.CanvasPosition = Vector2.new(0, scrollingFrame.CanvasPosition.Y + 1 * scrollingFrame.Template.AbsoluteSize.Y)
			end)
		end
	end

	local function applyLeaderboards(): ()
		for _, leaderboard in ipairs(leaderboards:GetChildren()) do
			local namePlate = leaderboard:FindFirstChild("NamePlate")
			if not namePlate then
				return
			end

			local textLabel = namePlate:FindFirstChild("SurfaceGui"):FindFirstChild("TextLabel")
			if not textLabel then
				return
			end

			local rankData = getRank(leaderboard.Name)
			if not rankData then
				return
			end

			handleScrollButtons(leaderboard)
			textLabel.Text = "You - #" .. rankData
		end
	end

	task.spawn(function()
		task.wait(5)
		applyLeaderboards()
	end)
end

------------------//INIT
task.spawn(handleZone)
task.spawn(getLeaderboardRank)
task.spawn(handleAFK)
task.spawn(handleBox)
task.spawn(handleDailyRewards)
task.spawn(handleSettings)
task.spawn(handleShop)
task.spawn(handleLevels)
--task.spawn(preloadUI)
task.spawn(setupHotbar)
task.spawn(handlePlayButton)
task.spawn(updateStats)
task.spawn(promptTutorial)
task.spawn(handleInteractiveZones)
task.spawn(handleBottomVisibility)

remotes.Notification.SendNotification.OnClientEvent:Connect(function(notificationText: string, notifType: string)
	sendNotification(notificationText, notifType)
end)

local frames = mainGui:WaitForChild("Frames")
local squad = frames:WaitForChild("Squad")

squad.Holder.Duo.Locked.Visible = true
squad.Holder.Trio.Locked.Visible = true
squad.Holder.Squad.Locked.Visible = true
squad.Holder.Squad.Interactable = false
squad.Holder.Trio.Interactable = false
squad.Holder.Duo.Interactable = false

player:GetAttributeChangedSignal("inParty"):Connect(function()
	local party = player:GetAttribute("inParty")

	if party then
		squad.Holder.Duo.Locked.Visible = false
		squad.Holder.Trio.Locked.Visible = false
		squad.Holder.Squad.Locked.Visible = false
		squad.Holder.Squad.Interactable = true
		squad.Holder.Trio.Interactable = true
		squad.Holder.Duo.Interactable = true
	else
		squad.Holder.Duo.Locked.Visible = true
		squad.Holder.Trio.Locked.Visible = true
		squad.Holder.Squad.Locked.Visible = true
		squad.Holder.Squad.Interactable = false
		squad.Holder.Trio.Interactable = false
		squad.Holder.Duo.Interactable = false
	end
end)

return {}