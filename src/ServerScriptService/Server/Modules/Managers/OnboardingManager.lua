local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GameRemotes = Remotes:WaitForChild("Game")

local DEFAULT_STAGE = "spawn"
local COMPLETED_STAGE = "completed"

local function ensureOnboardingObjects(userData: Folder): (BoolValue?, StringValue?, BoolValue?)
	if not userData then
		return nil, nil, nil
	end

	local completedTutorial = userData:FindFirstChild("CompletedTutorial")
	if not completedTutorial then
		completedTutorial = Instance.new("BoolValue")
		completedTutorial.Name = "CompletedTutorial"
		completedTutorial.Value = false
		completedTutorial.Parent = userData
	end

	local onboardingFolder = userData:FindFirstChild("Onboarding")
	if not onboardingFolder then
		onboardingFolder = Instance.new("Folder")
		onboardingFolder.Name = "Onboarding"
		onboardingFolder.Parent = userData
	end

	local stage = onboardingFolder:FindFirstChild("Stage")
	if not stage then
		stage = Instance.new("StringValue")
		stage.Name = "Stage"
		stage.Value = DEFAULT_STAGE
		stage.Parent = onboardingFolder
	end

	local completed = onboardingFolder:FindFirstChild("Completed")
	if not completed then
		completed = Instance.new("BoolValue")
		completed.Name = "Completed"
		completed.Value = false
		completed.Parent = onboardingFolder
	end

	if stage.Value == "" then
		stage.Value = DEFAULT_STAGE
	end

	return completedTutorial, stage, completed
end

local function syncOnboarding(userData: Folder)
	local completedTutorial, stage, completed = ensureOnboardingObjects(userData)
	if not completedTutorial or not stage or not completed then
		return
	end

	local isCompleted = completedTutorial.Value or completed.Value or stage.Value == COMPLETED_STAGE

	completedTutorial.Value = isCompleted
	completed.Value = isCompleted

	if isCompleted then
		stage.Value = COMPLETED_STAGE
	elseif stage.Value == "" or stage.Value == COMPLETED_STAGE then
		stage.Value = DEFAULT_STAGE
	end
end

local function markTutorialAsCompleted(player: Player, reason: string?)
	local userData = player:FindFirstChild("UserData") or player:WaitForChild("UserData", 10)
	if not userData then
		return
	end

	local completedTutorial, stage, completed = ensureOnboardingObjects(userData)
	if not completedTutorial or not stage or not completed then
		return
	end

	completedTutorial.Value = true
	completed.Value = true
	stage.Value = COMPLETED_STAGE

	if reason == "skip" then
		Remotes.Notification.SendNotification:FireClient(player, "Tutorial skipped. Daily Rewards unlocked.", "Success")
	end
end

local function updateOnboardingStage(player: Player, stageName: any)
	if type(stageName) ~= "string" then
		return
	end

	local cleanedStage = stageName:lower():gsub("^%s*(.-)%s*$", "%1")
	if cleanedStage == "" then
		return
	end

	local userData = player:FindFirstChild("UserData") or player:WaitForChild("UserData", 10)
	if not userData then
		return
	end

	local completedTutorial, stage, completed = ensureOnboardingObjects(userData)
	if not completedTutorial or not stage or not completed then
		return
	end

	stage.Value = cleanedStage

	if cleanedStage == COMPLETED_STAGE then
		completed.Value = true
		completedTutorial.Value = true
	end
end

local function bindPlayer(player: Player)
	local userData = player:FindFirstChild("UserData")
	while not userData and player.Parent == Players do
		task.wait(0.1)
		userData = player:FindFirstChild("UserData")
	end

	if not userData then
		return
	end

	local completedTutorial, stage, completed = ensureOnboardingObjects(userData)
	if not completedTutorial or not stage or not completed then
		return
	end

	local syncing = false
	local function guardedSync()
		if syncing then
			return
		end

		syncing = true
		syncOnboarding(userData)
		syncing = false
	end

	completedTutorial:GetPropertyChangedSignal("Value"):Connect(guardedSync)
	stage:GetPropertyChangedSignal("Value"):Connect(guardedSync)
	completed:GetPropertyChangedSignal("Value"):Connect(guardedSync)

	guardedSync()
end

local skipTutorialRemote = GameRemotes:FindFirstChild("SkipTutorial")
if skipTutorialRemote and skipTutorialRemote:IsA("RemoteEvent") then
	skipTutorialRemote.OnServerEvent:Connect(function(player: Player)
		markTutorialAsCompleted(player, "skip")
	end)
else
	warn("[OnboardingManager] Game.SkipTutorial remote not found; skip tutorial button will not update progress.")
end

local updateStageRemote = GameRemotes:FindFirstChild("UpdateOnboardingStage")
if updateStageRemote and updateStageRemote:IsA("RemoteEvent") then
	updateStageRemote.OnServerEvent:Connect(function(player: Player, stageName: any)
		updateOnboardingStage(player, stageName)
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(bindPlayer, player)
end

Players.PlayerAdded:Connect(bindPlayer)

return {}
