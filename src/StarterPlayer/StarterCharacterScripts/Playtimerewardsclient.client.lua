-- PlaytimeClockClient (LocalScript -> StarterCharacterScripts)
-- So o relogio de sessao e o tempo para a proxima recompensa. Nada mais.

local RS         = game:GetService("ReplicatedStorage")
local TS         = game:GetService("TweenService")
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player    = Players.LocalPlayer
repeat task.wait(0.5) until Player:FindFirstChild("PlayerInfo")
	and Player.Character
	and Player.Character:FindFirstChild("ToolFolder")

local PlayerGui             = Player:WaitForChild("PlayerGui")
local HUD                   = PlayerGui:WaitForChild("HUD")
local PlaytimeRewardsRemote = RS:WaitForChild("Remotes").PlaytimeRewardsRemote

-- ============================================================
-- ESTADO
-- ============================================================
local SessionStart   = nil
local MilestonesData = {}
local CompletedSet   = {}

-- ============================================================
-- HELPER
-- ============================================================
local function fmtTime(n)
	n = math.max(0, math.floor(n))
	local h = math.floor(n / 3600)
	local m = math.floor((n % 3600) / 60)
	local s = n % 60
	if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
	return string.format("%02d:%02d", m, s)
end

local function getNext()
	for _, m in ipairs(MilestonesData) do
		if not CompletedSet[m.Label] then return m end
	end
	return nil
end

local function addStroke(obj, thickness, alpha)
	local s = Instance.new("UIStroke", obj)
	s.Color        = Color3.fromRGB(0, 0, 0)
	s.Thickness    = thickness or 1.5
	s.Transparency = alpha or 0.4
end

-- ============================================================
-- UI  —  canto superior direito, transparente
-- ============================================================
local Frame = Instance.new("Frame")
Frame.Name                   = "PlaytimeClock"
Frame.AnchorPoint            = Vector2.new(1, 0)
Frame.Position               = UDim2.new(1, -10, 0, 10)
Frame.Size                   = UDim2.fromOffset(180, 52)
Frame.BackgroundTransparency = 1
Frame.BorderSizePixel        = 0
Frame.ZIndex                 = 20
Frame.Parent                 = HUD

-- Tag "SESSÃO"
local TagLabel = Instance.new("TextLabel", Frame)
TagLabel.AnchorPoint            = Vector2.new(1, 0)
TagLabel.Position               = UDim2.new(1, 0, 0, 0)
TagLabel.Size                   = UDim2.fromOffset(180, 12)
TagLabel.BackgroundTransparency = 1
TagLabel.Font                   = Enum.Font.GothamBold
TagLabel.Text                   = "SESSÃO"
TagLabel.TextColor3             = Color3.fromRGB(255, 210, 60)
TagLabel.TextTransparency       = 0.35
TagLabel.TextSize               = 9
TagLabel.TextXAlignment         = Enum.TextXAlignment.Right
TagLabel.TextScaled             = false
TagLabel.ZIndex                 = 21
addStroke(TagLabel, 1.2, 0.45)

-- Relogio principal
local ClockLabel = Instance.new("TextLabel", Frame)
ClockLabel.AnchorPoint            = Vector2.new(1, 0)
ClockLabel.Position               = UDim2.new(1, 0, 0, 11)
ClockLabel.Size                   = UDim2.fromOffset(180, 28)
ClockLabel.BackgroundTransparency = 1
ClockLabel.Font                   = Enum.Font.FredokaOne
ClockLabel.Text                   = "00:00"
ClockLabel.TextColor3             = Color3.fromRGB(255, 210, 60)
ClockLabel.TextSize               = 26
ClockLabel.TextXAlignment         = Enum.TextXAlignment.Right
ClockLabel.TextScaled             = false
ClockLabel.ZIndex                 = 21
addStroke(ClockLabel, 2, 0.4)

-- Linha da proxima recompensa
local RewardLabel = Instance.new("TextLabel", Frame)
RewardLabel.AnchorPoint            = Vector2.new(1, 0)
RewardLabel.Position               = UDim2.new(1, 0, 0, 39)
RewardLabel.Size                   = UDim2.fromOffset(180, 13)
RewardLabel.BackgroundTransparency = 1
RewardLabel.Font                   = Enum.Font.Gotham
RewardLabel.Text                   = ""
RewardLabel.TextColor3             = Color3.fromRGB(190, 190, 215)
RewardLabel.TextTransparency       = 0.1
RewardLabel.TextSize               = 10
RewardLabel.TextXAlignment         = Enum.TextXAlignment.Right
RewardLabel.TextScaled             = false
RewardLabel.ZIndex                 = 21
addStroke(RewardLabel, 1, 0.4)

-- ============================================================
-- HEARTBEAT
-- ============================================================
RunService.Heartbeat:Connect(function()
	if not SessionStart then return end
	local sessionSec = os.time() - SessionStart
	ClockLabel.Text  = fmtTime(sessionSec)

	local next = getNext()
	if next then
		local rem = math.max(0, next.Time - sessionSec)
		-- Pisca vermelho nos ultimos 10s
		if rem <= 10 and rem > 0 then
			ClockLabel.TextColor3 = (math.floor(os.clock() * 2) % 2 == 0)
				and Color3.fromRGB(255, 70, 70) or Color3.fromRGB(255, 210, 60)
		else
			ClockLabel.TextColor3 = Color3.fromRGB(255, 210, 60)
		end
		RewardLabel.Text      = "🏆 " .. next.Label .. "  " .. fmtTime(rem)
		RewardLabel.TextColor3 = rem <= 60
			and Color3.fromRGB(255, 170, 40)
			or Color3.fromRGB(190, 190, 215)
	else
		ClockLabel.TextColor3  = Color3.fromRGB(100, 230, 130)
		RewardLabel.Text       = "✓ Todas as recompensas coletadas"
		RewardLabel.TextColor3 = Color3.fromRGB(100, 220, 130)
	end
end)

-- ============================================================
-- REMOTE
-- ============================================================
PlaytimeRewardsRemote.OnClientEvent:Connect(function(action, data)
	if action == "Init" then
		SessionStart   = data.StartTime
		MilestonesData = data.Milestones or {}
		CompletedSet   = {}
	elseif action == "MilestoneReached" then
		if data and data.Label then
			CompletedSet[data.Label] = true
		end
	elseif action == "Reset" then
		CompletedSet = {}
		if data and data.StartTime then
			SessionStart = data.StartTime
		end
	end
end)